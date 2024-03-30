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
import Toybox.Lang;
using Toybox.Time;

class GarminSDComms {
  var mAccelHandler as GarminSDDataHandler;
  var lastOnReceiveResponse as Number = -1;
  var lastOnReceiveData as String = "";
  var lastOnSdStatusReceiveResponse as Number = -1;
  var mDataRequestInProgress as Boolean = false;
  var mDataSendStartTime as Time.Moment = Time.now();
  var mSettingsRequestInProgress as Boolean = false;
  var mStatusRequestInProgress as Boolean = false;
  var TIMEOUT as Time.Duration = new Time.Duration(4);
  //var serverUrl = "http:192.168.43.1:8080";
  var serverUrl as String = "http://127.0.0.1:8080";
  var needs_update as Boolean = true;

  function initialize(accelHandler as GarminSDDataHandler) {
    mAccelHandler = accelHandler;
  }

  function onStart() as Void {
  }

  function sendAccelData() as Void {
    //var tagStr = "SDComms.sendAccelData()";
    //writeLog(tagStr, "sendAccelData Start");
    var dataObj = mAccelHandler.getDataJson();
    mDataSendStartTime = Time.now();
    mDataRequestInProgress = true;
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

  function sendSettings() as Void {
    var dataObj = mAccelHandler.getSettingsJson();
    writeLog("SDComms.sendSettings()", "");
    mSettingsRequestInProgress = true;
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

  function getSdStatus() as Void {
    writeLog("SDComms.getSdStatus()", "");
    mStatusRequestInProgress = true;
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
  function onSdStatusReceive(responseCode as Number, data as Dictionary<String, String>) as Void {
    var tagStr = "SDComms.onSdStatusReceive";
    // writeLog(tagStr, "ResponseCode="+responseCode);
    if (responseCode == 200) {
      if (responseCode != lastOnSdStatusReceiveResponse) {
        needs_update = true;
        // writeLog(tagStr, "needs update 1");
        writeLog(tagStr, "Status =" + data.get("alarmPhrase"));
      }
      if (!mAccelHandler.mStatusStr.equals(data.get("alarmPhrase"))){
        mAccelHandler.mStatusStr = (data.get("alarmPhrase") as String);

        writeLog(tagStr, data.get("alarmPhrase"));
        needs_update = true;
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
          var vibeData = new Array<Attention.VibeProfile>[1];
          vibeData.add(new Attention.VibeProfile(50, 500));
          vibeData.add(new Attention.VibeProfile(0, 500));
          vibeData.add(new Attention.VibeProfile(50, 500));
          vibeData.add(new Attention.VibeProfile(0, 500));
          vibeData.add(new Attention.VibeProfile(50, 500));
          Attention.vibrate(vibeData);
        }
      }
    } else {
      // writeLog(tagStr, "needs update 3");
      needs_update = true;
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
    mStatusRequestInProgress = false;
  }

  // Receive the response from the sendAccelData web request.
  function onDataReceive(responseCode as Number, data as String) as Void  {
    var tagStr = "SDComms.onDataReceive()";
    var sendDuration = Time.now().subtract(mDataSendStartTime);
    writeLog(tagStr, "sendAccelData End - Send Duration = " + sendDuration.value());
    if (responseCode == 200) {
      if (responseCode != lastOnReceiveResponse || !data.equals(lastOnReceiveData)) {

        // writeLog(tagStr, "needs update 4");
        needs_update = true;
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
      needs_update = true;
      mAccelHandler.mStatusStr = "ERR: " + responseCode.toString();
      var soundEnabled = Storage.getValue(MENUITEM_SOUND) ? true : false;
      if (Attention has :playTone && soundEnabled) {
        Attention.playTone(Attention.TONE_LOUD_BEEP);
      }
      var vibrationEnabled = Storage.getValue(MENUITEM_VIBRATION) ? true : false;
      if (Attention has :vibrate && vibrationEnabled) {
        var vibeData = new Array<Attention.VibeProfile>[1];
        vibeData.add(new Attention.VibeProfile(50, 200));
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
    mDataRequestInProgress = false;
  }

  // Receive the response from the sendSettings web request.
  function onSettingsReceive(responseCode as Number, data as String) as Void {
    writeLog("SDComms.onSettingsReceive()", "");
    mSettingsRequestInProgress = false;
  }


  function onTick() as Void {
    /** Called every second (by GarminSDDataHandler)
    in case we need to do anything timed.
    */
    //System.println("GarminSDComms.onTick()");
    writeLog("GarminSDComms.onTick()", "");
    if (mDataRequestInProgress==true){
        var waitingTime = Time.now().subtract(mDataSendStartTime);
        if ((waitingTime as Time.Duration).greaterThan(TIMEOUT)){
          mDataRequestInProgress = false;
          var tagStr = "SDComms.onTick()";
          writeLog(tagStr, "Sending accelData failed");
          mAccelHandler.mStatusStr = Ui.loadResource(Rez.Strings.Error_abbrev).toString() + ": " + Ui.loadResource(Rez.Strings.Error_request_in_progress).toString();
          if (Attention has :vibrate) {
            var vibeData = new Array<Attention.VibeProfile>[1];
            vibeData.add(new Attention.VibeProfile(50, 200));
            Attention.vibrate(vibeData);
          }
        }
    }
  }
}
