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

using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Lang;

const VERSION_STR = "V0.3";

class GarminSDView extends Ui.View {
  var accelHandler;
  //var accel;
  var width;
  var height;
  
  function initialize() {
    System.println("GarminSDView.initialize()");
    View.initialize();
    accelHandler = new GarminSDDataHandler(VERSION_STR);
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
    //System.println("GarminSDView.onUpdate()");

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
    if (accelHandler.mMute) {
      dc.drawText(width / 2,  140, Gfx.FONT_LARGE, "MUTE",
		  Gfx.TEXT_JUSTIFY_CENTER);
    } else {
      dc.drawText(width / 2,  140, Gfx.FONT_LARGE, accelHandler.mStatusStr,
		  Gfx.TEXT_JUSTIFY_CENTER);
    }
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
  const KEY_MUTE = 4; 
  var muteKeyDownTime;
  var mSdView;
  
  function initialize(sdView) {
    System.println("SdDelegate.initialize()");
    mSdView = sdView;
    BehaviorDelegate.initialize();
  }

  function onMenu() {
    System.println("SdDelegate.onMenu() - Sending Mute Signal");
    mSdView.accelHandler.muteAlarms();
    return true;
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
  //function onKey(keyEvent) {
  //  System.println(Lang.format("onKey() - key=$1$", [keyEvent.getKey()])); // e.g. KEY_MENU = 7
  //  return false;
  //}

  function onKeyPressed(evt) {
    var key = evt.getKey();
    System.println(Lang.format("onKeyPressed() - key=$1$", [key])); 
    if (key == KEY_MUTE) {
      System.println("Mute Key Pressed");
      muteKeyDownTime = Sys.getTimer();
      
    }
    return true;
  }

  function onKeyReleased(evt) {
    var key = evt.getKey();
    System.println(Lang.format("onKeyReleased() - key=$1$", [key])); 
    if (key == KEY_MUTE) {
      var now = Sys.getTimer();
      var delta = now - muteKeyDownTime;
      System.println(Lang.format("Key $1$ held for $2$ ms", [KEY_MUTE, delta]));
    }
    return true;
  }
}


class QuitDelegate extends Ui.ConfirmationDelegate
{
  const QUIT_TIMEOUT = 10 * 1000;  // Milliseconds
  var mTimer;
    function initialize()
    {
      System.println("QuitDelegate.initialize()");
      Ui.ConfirmationDelegate.initialize();

      // Start a timer to timeout this dialog - calls timerCallback
      mTimer = new Timer.Timer();
      mTimer.start(method(:timerCallback),QUIT_TIMEOUT,false);
    }

  function timerCallback() {
    // Dismiss the dialog
    System.println("timerCallback()");
    Ui.popView(Ui.SLIDE_IMMEDIATE);    		    	
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

