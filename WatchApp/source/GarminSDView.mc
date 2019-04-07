//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Lang;

class GarminSDView extends Ui.View {
  var accelHandler;
  var accel;
  var width;
  var height;
  
  function initialize() {
    System.println("GarminSDView.initialize()");
    View.initialize();
    accelHandler = new GarminSDDataHandler();
    System.println("GarminSDView.initialize() - complete");    
  }
  
  // Load your resources here
  function onLayout(dc) {
    System.println("GarminSDView.onLayout()");
    width = dc.getWidth();
    height = dc.getHeight();
    System.println("GarminSDView.onLayout() - complete");
  }
  
  // Restore the state of the app and prepare the view to be shown
  function onShow() {
    System.println("GarminSDView.onShow()");
    accelHandler.onStart();
    //Ui.requestUpdate();
    System.println("GarminSDView.onShow() - finishing");
  }
  
  // Update the view
  function onUpdate(dc) {
    System.println("GarminSDView.onUpdate()");
    //var clockTime = System.getClockTime();
    // Format current time for display
    // see https://developer.garmin.com/downloads/connect-iq/monkey-c/doc/Toybox/Time.html
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
    var hrString = Lang.format("HR = $1$ bpm",[accelHandler.mHR]);
    var memStr = Lang.format("Mem = $1$",[sysStats.freeMemory]);
    //System.println(sysStats.battery);
    //System.println(sysStats.totalMemory);
    //System.println(timeString); // e.g. "16:28:32 Wed 1 Mar 2017"
    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
    dc.clear();
    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    dc.drawText(width / 2,  0, Gfx.FONT_MEDIUM, "OpenSeizure",
		Gfx.TEXT_JUSTIFY_CENTER);
    dc.drawText(width / 2,  20, Gfx.FONT_MEDIUM, "Detector",
		Gfx.TEXT_JUSTIFY_CENTER);
    dc.drawText(width / 2,  40, Gfx.FONT_SYSTEM_NUMBER_HOT, timeString,
		Gfx.TEXT_JUSTIFY_CENTER);
    dc.drawText(width / 2,  85, Gfx.FONT_LARGE, batString,
		Gfx.TEXT_JUSTIFY_CENTER);
    dc.drawText(width / 2,  110, Gfx.FONT_LARGE, hrString,
		Gfx.TEXT_JUSTIFY_CENTER);
    dc.drawText(width / 2,  130, Gfx.FONT_LARGE, accelHandler.nSamp,
		Gfx.TEXT_JUSTIFY_CENTER);
    dc.drawText(width / 2,  160, Gfx.FONT_LARGE, memStr,
		Gfx.TEXT_JUSTIFY_CENTER);
  }
  
  

  // Called when this View is removed from the screen. Save the
  // state of your app here.
  function onHide() {
    System.println("GarminSDView.onHide");
    accelHandler.onStop();
    System.println("GarminSDView.onHide - Complete");
  }
  
}


class SdDelegate extends Ui.BehaviorDelegate {
  function initialize() {
    System.println("SdDelegate.initialize()");
    BehaviorDelegate.initialize();
  }

  // When a back behavior occurs, onBack() is called.
    // @return [Boolean] true if handled, false otherwise
  function onBack() {
    System.println("SdDelegate.onBack()");
    var quitString = "Exit OSD App?";			
    var cd = new Ui.Confirmation( quitString );
    Ui.pushView( cd, new QuitDelegate(), Ui.SLIDE_IMMEDIATE );
    return true;
  }

  // Detect Menu button input
  function onKey(keyEvent) {
    System.println(keyEvent.getKey()); // e.g. KEY_MENU = 7
    return true;
  }
}


class QuitDelegate extends Ui.ConfirmationDelegate
{	
    function initialize()
    {
      System.println("QuitDelegate.initialize()");
      Ui.ConfirmationDelegate.initialize();
    }
    
    function onResponse(value)
    {
      System.println("QuitDelegate.onResponse()"+value);
        if( value == CONFIRM_YES )
        {
            // pop the confirmation dialog associated with this delegate
            Ui.popView(Ui.SLIDE_IMMEDIATE);    		    	

            // the system will automatically pop the top level dialog
        }

        return true;
    }
}

