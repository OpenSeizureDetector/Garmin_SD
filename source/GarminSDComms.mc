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
import Toybox.Application.Storage;

class GarminSDComms {
  var listener;
  // var mTimer;
  var mAccelHandler = null;
  var lastOnReceiveResponse = -1;
  var lastOnReceiveData = "";
  var mDataSendStartTime = Time.now();
  var mSettingsRequestInProgress = 0;
  //var serverUrl = "http:192.168.43.1:8080";
  var serverUrl = "http://127.0.0.1:8080";

  function initialize(accelHandler) {
    //listener = new CommListener();
    mAccelHandler = accelHandler;
    mSettingsRequestInProgress = 0;
  }

  function onStart() {
  }

  function sendAccelData() {
    //var tagStr = "SDComms.sendAccelData()";
    //writeLog(tagStr, "sendAccelData Start");
    var dataObj = mAccelHandler.getDataJson();
    mDataSendStartTime = Time.now();
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

  // Receive the response from the sendAccelData web request.
  function onDataReceive(responseCode, data) {
    var tagStr = "SDComms.onDataReceive()";
    var sendDuration = Time.now().subtract(mDataSendStartTime);
    writeLog(tagStr, "sendAccelData End - Send Duration = " + sendDuration.value());
    if (responseCode == 200) {
      mAccelHandler.mStatusStr = "OK";
      if (responseCode != lastOnReceiveResponse || !data.equals(lastOnReceiveData)) {
        writeLog(tagStr, "Success - data =" + data);
      } else {
        // Don't write repeated log entries.
      }
      if (data.equals("sendSettings")) {
        //System.println("Sending Settings");
        sendSettings();
      }
    } else {
      mAccelHandler.mStatusStr = "ERR: " + responseCode.toString();
    }
    lastOnReceiveResponse = responseCode;
    lastOnReceiveData = data;
  }

  // Receive the response from the sendSettings web request.
  function onSettingsReceive(responseCode, data) {
    writeLog("SDComms.onSettingsReceive()", "");
    mSettingsRequestInProgress = 0;
  }
}
