/*
  Garmin_sd - a data source for OpenSeizureDetector that runs on a
  Garmin ConnectIQ watch.

  See http://openseizuredetector.org for more information.

  Copyright Graham Jones, 2019.

  This file is part of Garmin_sd.

  Garmin_sd is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Garmin_sd is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Garmin_sd.  If not, see <http://www.gnu.org/licenses/>.

*/
using Toybox.Communications as Comm;
using Toybox.Attention as Attention;
using Toybox.WatchUi as Ui;
import Toybox.Application.Storage;

class GarminSDComms {
  var listener;
  var mTimer;
  var mAccelHandler = null;
  var lastOnReceiveResponse = -1;
  var lastOnReceiveData = "";
  var lastOnSdStatusReceiveResponse = -1;
  var mDataRequestInProgress = 0;
  var mDataSendStartTime = 0;
  var mSettingsRequestInProgress = 0;
  var mStatusRequestInProgress = 0;
  var mDataReadyToSend = 0;
  //var serverUrl = "http:192.168.43.1:8080";
  var serverUrl = "http://127.0.0.1:8080";

  function initialize(accelHandler) {
    //listener = new CommListener();
    mAccelHandler = accelHandler;
    mDataRequestInProgress = 0;
    mSettingsRequestInProgress = 0;
    mStatusRequestInProgress = 0;

    // Start a timer that calls timerCallback every half second
    mTimer = new Timer.Timer();
    mTimer.start(method(:onTick), 500, true);

  }

  function onStart() {
    // We use http communications not phone app messages.
    //Comm.registerForPhoneAppMessages(method(:onMessageReceived));
    //Comm.transmit("Hello World.", null, listener);
  }

  function sendAccelData() {
    var tagStr = "SDComms.sendAccelData()";
    if (mDataRequestInProgress) {
      // Don't start another one.
      writeLog(tagStr,"mDataRequestInProgress="+mDataRequestInProgress+", "+ mSettingsRequestInProgress+ ", " + mStatusRequestInProgress);
      mDataReadyToSend = 1;   // Set a flag so that onTick knows to re-try this send.
    } else {
      //writeLog(tagStr, "sendAccelData Start");
      var dataObj = mAccelHandler.getDataJson();
      mDataRequestInProgress = 1;
      mDataSendStartTime = Time.now();
      mDataReadyToSend = 0;
      Comm.makeWebRequest(
        serverUrl + "/data",
        { "dataObj" => dataObj },
        {
          :method => Communications.HTTP_REQUEST_METHOD_POST,
          :headers => {
            "Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED,
          },
        },
        method(:onDataReceive)
      );
    }
  }

  function sendSettings() {
    var dataObj = mAccelHandler.getSettingsJson();
    writeLog("SDComms.sendSettings()", "");
    mSettingsRequestInProgress = 1;
    Comm.makeWebRequest(
      serverUrl + "/settings",
      { "dataObj" => dataObj },
      {
        :method => Communications.HTTP_REQUEST_METHOD_POST,
        :headers => {
          "Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED,
        },
      },
      method(:onSettingsReceive)
    );
  }

  function getSdStatus() {
    writeLog("SDComms.getSdStatus()", "");
    mStatusRequestInProgress = 1;
    Comm.makeWebRequest(
      serverUrl + "/data",
      {},
      {
        :method => Communications.HTTP_REQUEST_METHOD_GET,
        :headers => {
          "Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED,
        },
        :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
      },
      method(:onSdStatusReceive)
    );
    //System.println("getSdStatus Exiting");
  }

  // Receive the data from the web request - should be a json string
  function onSdStatusReceive(responseCode, data) {
    var tagStr = "SDComms.onSdStatusReceive";
    writeLog(tagStr, "ResponseCode="+responseCode);
    if (responseCode == 200) {
      if (responseCode != lastOnSdStatusReceiveResponse) {
        #writeLog(tagStr, "success - data =" + data);
        writeLog(tagStr, "Status =" + data.get("alarmPhrase"));
      }
      mAccelHandler.mStatusStr = data.get("alarmPhrase");
      if (data.get("alarmState") != 0) {
        try {
          var lightEnabled = Storage.getValue(MENUITEM_LIGHT) ? true : false;
          if (Attention has :backlight && lightEnabled) {
            Attention.backlight(true);
          }
        } catch (ex) {
          // We might get a Toybox.Attention.BacklightOnTooLongException
        }
        var soundEnabled = Storage.getValue(MENUITEM_SOUND) ? true : false;
        if (Attention has :playTone && soundEnabled) {
          Attention.playTone(Attention.TONE_ALERT_HI);
        }
      }
      if (data.get("alarmState") == 2) {
        // ALARM
        var vibrationEnabled = Storage.getValue(MENUITEM_VIBRATION)
          ? true
          : false;
        if (Attention has :vibrate && vibrationEnabled) {
          var vibeData = [
            new Attention.VibeProfile(50, 500),
            new Attention.VibeProfile(0, 500),
            new Attention.VibeProfile(50, 500),
            new Attention.VibeProfile(0, 500),
            new Attention.VibeProfile(50, 500),
          ];
          Attention.vibrate(vibeData);
        }
      }
    } else {
      mAccelHandler.mStatusStr =
        Ui.loadResource(Rez.Strings.Error_abbrev) + ": " + responseCode.toString();
      if (responseCode != lastOnSdStatusReceiveResponse) {
        writeLog(tagStr, "Failue - code =" + responseCode);
        writeLog(tagStr, "Failure - data =" + data);
      } else {
        // Don't write repeated log entries to save filling up the log file.
      }
    }
    lastOnSdStatusReceiveResponse = responseCode;
    mStatusRequestInProgress = 0;
  }

  // Receive the response from the sendAccelData web request.
  function onDataReceive(responseCode, data) {
    var tagStr = "SDComms.onDataReceive()";
    var sendDuration = Time.now().subtract(mDataSendStartTime);
    writeLog(tagStr, "sendAccelData End - Send Duration = " + sendDuration.value());
    if (responseCode == 200) {
      if (responseCode != lastOnReceiveResponse || data != lastOnReceiveData) {
        writeLog(tagStr, "Success - data =" + data);
      } else {
        // Don't write repeated log entries.
      }
      if (data.equals("sendSettings")) {
        //System.println("Sending Settings");
        sendSettings();
      } else {
        //System.println("getting sd status");
        getSdStatus();
      }
    } else {
      mAccelHandler.mStatusStr = "ERR: " + responseCode.toString();
      var soundEnabled = Storage.getValue(MENUITEM_SOUND) ? true : false;
      if (Attention has :playTone && soundEnabled) {
        Attention.playTone(Attention.TONE_LOUD_BEEP);
      }
      var vibrationEnabled = Storage.getValue(MENUITEM_VIBRATION) ? true : false;
      if (Attention has :vibrate && vibrationEnabled) {
        var vibeData = [
          new Attention.VibeProfile(50, 200),
        ];
        Attention.vibrate(vibeData);
      }

      if (responseCode != lastOnReceiveResponse) {
        writeLog(tagStr, "Failue - code =" + responseCode);
      } else {
        //
      }
    }
    lastOnReceiveResponse = responseCode;
    lastOnReceiveData = data;
    mDataRequestInProgress = 0;
  }

  // Receive the response from the sendSettings web request.
  function onSettingsReceive(responseCode, data) {
    writeLog("SDComms.onSettingsReceive()", "");
    mSettingsRequestInProgress = 0;
  }

  //function onMessageReceived(msg) {
  //  System.print("GarminSdApp.onMessageReceived - ");
  //  System.println(msg.data.toString());
  //}

  /////////////////////////////////////////////////////////////////////
  // Connection listener class that is used to log success and failure
  // of message transmissions.
  //class CommListener extends Comm.ConnectionListener {
  //  function initialize() {
  //   Comm.ConnectionListener.initialize();
  // }

    //function onComplete() {
    //  System.println("Transmit Complete");
    //}

    //function onError() {
    //  System.println("Transmit Failed");
    //}
  //}

  function onTick() {
    /** Called every second (by GarminSDDataHandler)
    in case we need to do anything timed.
    */
    var tagStr = "SDComms.onTick()";
    //System.println("GarminSDComms.onTick()");
    if (mDataReadyToSend) {
      writeLog(tagStr, "Re-sending accelData");
            mAccelHandler.mStatusStr =
        Ui.loadResource(Rez.Strings.Error_abbrev) + ": " + Ui.loadResource(Rez.Strings.Error_request_in_progress);
      var retryWarningEnabled = Storage.getValue(MENUITEM_RETRY_WARNING) ? true : false;
      if (Attention has :vibrate && retryWarningEnabled) {
        var vibeData = [
          new Attention.VibeProfile(50, 200),
        ];
        Attention.vibrate(vibeData);
      }
      sendAccelData();
    }
  }
}
