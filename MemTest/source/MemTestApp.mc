//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Application as App;
using Toybox.System;
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Lang;
using Toybox.Timer;
using Toybox.Communications as Comm;

class MemTestApp extends App.AppBase {
  function initialize() {
    AppBase.initialize();
  }
    
  function onStart(state) {
  }

  function onStop(state) {
  }

  function getInitialView() {
    var mainView = new MemTestView();
    return [mainView];
  }

}


class MemTestView extends Ui.View {
  var width;
  var height;
  var myTimer;
  var listener;
  
  function initialize() {
    View.initialize();
    listener = new Comm.ConnectionListener();
  }
  
  // Receive the data from the web request
  function onReceive(responseCode, data) {
    if (responseCode == 200) {
      System.println("onReceive() success - data =");
      System.println(data);
    } else {
      System.println("onReceive() Failue - code =");
      System.println(responseCode.toString());
    }
  }
  
  function timerCallback() {
    var dataObj = {
      "HR"=> 60,
      "X" => 0,
      "Y" => 0,
      "Z" => 0
    };
    // FIXME - THIS CRASHED WITH OUT OF MEMORY ERROR AFTER 5 or 10 minutes.
    //Comm.transmit(dataObj,null,listener);

    // Try makeWebRequest instead to see if that avoids the memory leak
    Comm.makeWebRequest(
			"http:192.168.0.84:8080/data",
			{
			  "dataType" => "raw",
			    "data" => [1,2,3,4,5,6,7,8,9,10]
			    },
			{
			  "Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED
			    },
			method(:onReceive));
    Ui.requestUpdate(); 
  }

  // Load your resources here
  function onLayout(dc) {
    width = dc.getWidth();
    height = dc.getHeight();
    myTimer = new Timer.Timer();
    myTimer.start(method(:timerCallback), 1000, true);
  }
  
  // Restore the state of the app and prepare the view to be shown
  function onShow() {
  }
  
  // Update the view
  function onUpdate(dc) {
    System.println("GarminSDView.onUpdate()");
    var dateTime = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
    var timeString = Lang.format(
				 "$1$:$2$:$3$",
				 [
				  dateTime.hour.format("%02d"),
				  dateTime.min.format("%02d"),
				  dateTime.sec.format("%02d")
				  ]
				 );
    var sysStats = System.getSystemStats();
    var batString = Lang.format("Bat = $1$%",[sysStats.battery.format("%02.0f")]);
    var memStr = Lang.format("Mem = $1$",[sysStats.freeMemory]);
    var usedMemStr = Lang.format("Used = $1$",[sysStats.usedMemory]);
    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
    dc.clear();
    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    dc.drawText(width / 2,  40, Gfx.FONT_SYSTEM_NUMBER_HOT, timeString,
		Gfx.TEXT_JUSTIFY_CENTER);
    dc.drawText(width / 2,  85, Gfx.FONT_LARGE, batString,
		Gfx.TEXT_JUSTIFY_CENTER);
    dc.drawText(width / 2,  130, Gfx.FONT_LARGE, usedMemStr,
		Gfx.TEXT_JUSTIFY_CENTER);
    dc.drawText(width / 2,  160, Gfx.FONT_LARGE, memStr,
		Gfx.TEXT_JUSTIFY_CENTER);
  }
  
  

  function onHide() {
    myTimer.stop();
  }
}

