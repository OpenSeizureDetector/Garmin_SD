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
  var mAccelHandler = null;
  var lastOnReceiveResponse = -1;
  var lastOnReceiveData = "";
  var lastOnSdStatusReceiveResponse = -1;
  var mDataRequestInProgress = 0;
  var mDataSendStartTime = Time.now();
  var mSettingsRequestInProgress = 0;
  var mStatusRequestInProgress = 0;
  var TIMEOUT = new Time.Duration(4);
  //var serverUrl = "http:192.168.43.1:8080";
  var serverUrl = "http://127.0.0.1:8080";
  var needs_update = 1;

  function initialize(accelHandler) {
    mAccelHandler = accelHandler;
    mDataRequestInProgress = 0;
    mSettingsRequestInProgress = 0;
    mStatusRequestInProgress = 0;
  }

  function onStart() {
  }

  function sendAccelData() {
    //var tagStr = "SDComms.sendAccelData()";
    //writeLog(tagStr, "sendAccelData Start");
    var dataObj = mAccelHandler.getDataJson();
    mDataSendStartTime = Time.now();
    mDataRequestInProgress = 1;
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
    // writeLog(tagStr, "ResponseCode="+responseCode);
    if (responseCode == 200) {
      if (responseCode != lastOnSdStatusReceiveResponse) {
        needs_update = 1;
        // writeLog(tagStr, "needs update 1");
        writeLog(tagStr, "Status =" + data.get("alarmPhrase"));
      }
      if (!mAccelHandler.mStatusStr.equals(data.get("alarmPhrase"))){
        mAccelHandler.mStatusStr = data.get("alarmPhrase");

        writeLog(tagStr, data.get("alarmPhrase"));
        needs_update = 1;
      }
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
      // writeLog(tagStr, "needs update 3");
      needs_update = 1;
      mAccelHandler.mStatusStr =
        Ui.loadResource(Rez.Strings.Error_abbrev) + ": " + responseCode.toString();
      if (responseCode != lastOnSdStatusReceiveResponse) {
        writeLog(tagStr, "Failure - code =" + responseCode);
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
      if (responseCode != lastOnReceiveResponse || !data.equals(lastOnReceiveData)) {

        // writeLog(tagStr, "needs update 4");
        needs_update = 1;
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
      // writeLog(tagStr, "needs update 5");
      needs_update = 1;
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
        writeLog(tagStr, "Failure - code =" + responseCode);
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


  function onTick() {
    /** Called every second (by GarminSDDataHandler)
    in case we need to do anything timed.
    */
    //System.println("GarminSDComms.onTick()");
    writeLog("GarminSDComms.onTick()", "");
    if (mDataRequestInProgress==1){
        var waitingTime = Time.now().subtract(mDataSendStartTime);
        if (waitingTime.greaterThan(TIMEOUT)){
          mDataRequestInProgress = 0;
          var tagStr = "SDComms.onTick()";
          writeLog(tagStr, "Sending accelData failed");
          mAccelHandler.mStatusStr = Ui.loadResource(Rez.Strings.Error_abbrev) + ": " + Ui.loadResource(Rez.Strings.Error_request_in_progress);
          if (Attention has :vibrate) {
            var vibeData = [
              new Attention.VibeProfile(50, 200),
            ];
            Attention.vibrate(vibeData);
          }
        }
    }
  }
}
