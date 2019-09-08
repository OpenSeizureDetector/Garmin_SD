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

class GarminSDComms {
  var listener;
  var mAccelHandler = null;
  //var serverUrl = "http:192.168.43.1:8080";
  var serverUrl = "http:127.0.0.1:8080";

  function initialize(accelHandler) {
    listener = new CommListener();
    mAccelHandler = accelHandler;
  }

  function onStart() {
    Comm.registerForPhoneAppMessages(method(:onMessageReceived));
    Comm.transmit("Hello World.", null, listener);

  }

  function sendAccelData() {
    var dataObj = mAccelHandler.getDataJson();
    
    Comm.makeWebRequest(
			serverUrl+"/data",
			{"dataObj"=>dataObj},
			{
			  :method => Communications.HTTP_REQUEST_METHOD_POST,
			    :headers => {
			    "Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED
			  }
			},
			method(:onReceive));
  }

  function sendSettings() {
    var dataObj = mAccelHandler.getSettingsJson();
    System.println("sendSettings() - dataObj="+dataObj);
    Comm.makeWebRequest(
			serverUrl+"/settings",
			{"dataObj"=>dataObj},
			{
			  :method => Communications.HTTP_REQUEST_METHOD_POST,
			    :headers => {
			    "Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED
			  }
			},
			method(:onReceive));    
  }

  function getSdStatus() {
    System.println("getStStatus()");
    Comm.makeJsonRequest(
			serverUrl+"/data",
			{},
			{
			  :method => Communications.HTTP_REQUEST_METHOD_GET,
			    :headers => {
			    "Content-Type" => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
			  }
			},
			method(:onSdStatusReceive));    
  }


  // Receive the data from the web request - should be a json string
  function onSdStatusReceive(responseCode, data) {
    if (responseCode == 200) {
      System.println("onSdDataReceive() success - data ="+data);
      System.println("onSdDataReceive() Status ="+data.get("alarmPhrase"));
      mAccelHandler.mStatusStr = data.get("alarmPhrase");
      if (data.get("alarmState") != 0) {
	if (Attention has :backlight) {
	  Attention.backlight(true);
	}
      }
    } else {
      System.println("onReceive() Failue - code =");
      System.println(responseCode);
      System.println(responseCode.toString());
      System.println(data);
    }
  }

  
  // Receive the response from the sendAccelData or sendSettings web request.
  function onReceive(responseCode, data) {
    if (responseCode == 200) {
      System.println("onReceive() success - data ="+data);
      if (data.equals("sendSettings")) {
	System.println("Sending Settings");
	sendSettings();
      } else {
	getSdStatus();
      }
    } else {
      System.println("onReceive() Failue - code =");
      System.println(responseCode);
      System.println(responseCode.toString());
      System.println(data);
    }
  }
  


  function onMessageReceived(msg) {
    var i;
    System.print("GarminSdApp.onMessageReceived - ");
    System.println(msg.data.toString());
  }
  
  /////////////////////////////////////////////////////////////////////
  // Connection listener class that is used to log success and failure
  // of message transmissions.
  class CommListener extends Comm.ConnectionListener {
    function initialize() {
      Comm.ConnectionListener.initialize();
    }
    
    function onComplete() {
      System.println("Transmit Complete");
    }
    
    function onError() {
      System.println("Transmit Failed");
    }
  }

}
