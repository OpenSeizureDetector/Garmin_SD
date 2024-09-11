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
import Toybox.Lang;
using Toybox.Timer;
using Toybox.Communications as Comm;

class MemTestApp extends App.AppBase {
  function initialize() {
    AppBase.initialize();
  }
    
  function onStart(state as Dictionary or Null) {
  }

  function onStop(state as Dictionary or Null) {
  }

  function getInitialView() as Array<Toybox.WatchUi.Views or Toybox.WatchUi.InputDelegates> or Null {
    var mainView = new MemTestView();
    return [mainView] as Array<Toybox.WatchUi.InputDelegates or Toybox.WatchUi.Views>;
  }

}


class MemTestView extends Ui.View {
  var width as Number = 0;
  var height as Number = 0;
  var myTimer as Timer.Timer;
  var listener as Comm.ConnectionListener;
  
  function initialize() {
    View.initialize();
    listener = new Comm.ConnectionListener();
    myTimer = new Timer.Timer();
  }
  
  // Receive the data from the web request
  function onReceive(responseCode as Number, data as String) as Void {
    if (responseCode == 200) {
      System.println("onReceive() success - data =");
      System.println(data);
    } else {
      System.println("onReceive() Failue - code =");
      System.println(responseCode.toString());
    }
  }
  
  function timerCallback() as Void {
    var dataObj = {
      "HR"=> 60,
      "X" => 0,
      "Y" => 0,
      "Z" => 0
    };
    // FIXME - THIS CRASHED WITH OUT OF MEMORY ERROR AFTER 5 or 10 minutes.
    Comm.transmit(dataObj,null,listener);
    dataObj = null;

    // Try makeWebRequest instead to see if that avoids the memory leak
    /*Comm.makeWebRequest(
			"http:192.168.0.84:8080/data",
			{
			  "dataType" => "raw",
			    "data" => [1,2,3,4,5,6,7,8,9,10]
			    },
			{
			  "Content-Type" => Comm.REQUEST_CONTENT_TYPE_URL_ENCODED
			    },
			method(:onReceive));
    */
    Ui.requestUpdate(); 
  }

  // Load your resources here
  function onLayout(dc) as Void {
    width = dc.getWidth();
    height = dc.getHeight();
    myTimer.start(method(:timerCallback), 1000, true);
  }
  
  // Restore the state of the app and prepare the view to be shown
  function onShow() as Void {
  }
  
  // Update the view
  function onUpdate(dc) as Void {
    System.println("GarminSDView.onUpdate()");
    var dateTime = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
    var timeString = format(
				 "$1$:$2$:$3$",
				 [
				  dateTime.hour.format("%02d"),
				  dateTime.min.format("%02d"),
				  dateTime.sec.format("%02d")
				  ]
				 );
    var sysStats = System.getSystemStats();
    var batString = format("Bat = $1$%",[sysStats.battery.format("%02.0f")]);
    var memStr = format("Mem = $1$",[sysStats.freeMemory]);
    var usedMemStr = format("Used = $1$",[sysStats.usedMemory]);
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
  
  

  function onHide() as Void{
    myTimer.stop();
  }
}

