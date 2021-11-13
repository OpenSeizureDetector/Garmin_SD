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
using Toybox.Timer;
using Toybox.Lang;

class GarminSDView extends Ui.View {
  var accelHandler;
  var width;
  var height;
  
  function initialize() {
    System.println("GarminSDView.initialize()");
    View.initialize();
    accelHandler = new GarminSDDataHandler(Ui.loadResource(Rez.Strings.VersionId));
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
    System.println("GarminSDView.onShow() - finishing");
  }
  
  // Update the view
  function onUpdate(dc) {
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
    //var batString = Lang.format("%s = $1$%",[Ui.loadResource(Rez.Strings.Battery_abbrev),sysStats.battery.format("%02.0f")]);
    //var hrString = Lang.format("%s = $1$ %s",[
    //					      Ui.loadResource(Rez.Strings.HR_abbrev), accelHandler.mHR, Ui.loadResource(Rez.Strings.Beats_per_minute_abbrev)]);
    //var hrBatStr = Lang.format("$1$ $2$ / $3$%",[accelHandler.mHR,
		//				Ui.loadResource(Rez.Strings.Beats_per_minute_abbrev),
		//				 sysStats.battery.format("%02.0f")]);
    var hrO2Str = Lang.format("$1$ $2$ / $3$% Ox" ,[accelHandler.mHR,
						Ui.loadResource(Rez.Strings.Beats_per_minute_abbrev), accelHandler.mO2Sat]);
    var batStr = Lang.format("$1$% bat",[sysStats.battery.format("%02.0f")]);
    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
    dc.clear();
    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    dc.drawText(width / 2,  0, Gfx.FONT_MEDIUM, "OpenSeizure",
		Gfx.TEXT_JUSTIFY_CENTER);
    dc.drawText(width / 2,  20, Gfx.FONT_MEDIUM, "Detector",
		Gfx.TEXT_JUSTIFY_CENTER);
    dc.drawText(width / 2,  45, Gfx.FONT_SYSTEM_NUMBER_HOT, timeString,
		Gfx.TEXT_JUSTIFY_CENTER);
    //dc.drawText(width / 2,  180, Gfx.FONT_LARGE, batString,
    //	Gfx.TEXT_JUSTIFY_CENTER);
    dc.drawText(width / 2,  120, Gfx.FONT_LARGE, hrO2Str, Gfx.TEXT_JUSTIFY_CENTER);
    dc.drawText(width / 2,  150, Gfx.FONT_LARGE, batStr, Gfx.TEXT_JUSTIFY_CENTER);
    if (accelHandler.mMute) {
      dc.drawText(width / 2,  180, Gfx.FONT_LARGE, Ui.loadResource(Rez.Strings.Mute_label),
		  Gfx.TEXT_JUSTIFY_CENTER);
    } else {
      dc.drawText(width / 2,  180, Gfx.FONT_LARGE, accelHandler.mStatusStr,
		  Gfx.TEXT_JUSTIFY_CENTER);
    }
  }
  
  

  // Called when this View is removed from the screen. Save the
  // state of your app here.
  function onHide() {
    System.println("GarminSDView.onHide");
    accelHandler.onStop();
  }
  
}


class SdDelegate extends Ui.BehaviorDelegate {
  var mSdView;
  
  function initialize(sdView) {
    System.println("SdDelegate.initialize()");
    mSdView = sdView;
    BehaviorDelegate.initialize();
  }

  function onMenu() {
    System.println("SdDelegate.onMenu() - Showing confirm dialog");
    var msgStr = Ui.loadResource(Rez.Strings.Mute_alarms_confirmation);			
    var cd = new Ui.Confirmation( msgStr );
    Ui.pushView( cd,
    		 new MuteDelegate(mSdView.accelHandler),
    		 Ui.SLIDE_IMMEDIATE );
    return true;
  }


  // When a back behavior occurs, onBack() is called.
    // @return [Boolean] true if handled, false otherwise
  function onBack() {
    System.println("SdDelegate.onBack()");
    var quitString = Ui.loadResource(Rez.Strings.Exit_app_confirmation);
    var cd = new Ui.Confirmation( quitString );
    Ui.pushView( cd, new QuitDelegate(), Ui.SLIDE_IMMEDIATE );
    return true;
  }

  // Detect Menu button input
  function onKey(keyEvent) {
    if (keyEvent.getKey() == KEY_START) {
      var quitString = Ui.loadResource(Rez.Strings.Exit_app_confirmation);
      var cd = new Ui.Confirmation( quitString );
      Ui.pushView( cd, new QuitDelegate(), Ui.SLIDE_IMMEDIATE );
      return true;
    } else if (keyEvent.getKey() == KEY_ENTER) {
      var quitString = Ui.loadResource(Rez.Strings.Exit_app_confirmation);
      var cd = new Ui.Confirmation( quitString );
      Ui.pushView( cd, new QuitDelegate(), Ui.SLIDE_IMMEDIATE );
      return true;
    }
    System.println(keyEvent.getKey()); // e.g. KEY_MENU = 7
    return true;
  }
}

class QuitDelegate extends Ui.ConfirmationDelegate
{
  const QUIT_TIMEOUT = 10 * 1000;  // Milliseconds
  var mTimer;
  var mResponseReceived;

  function initialize()
    {
      System.println("QuitDelegate.initialize()");
      Ui.ConfirmationDelegate.initialize();
      
      // Start a timer to timeout this dialog - calls timerCallback
      mTimer = new Timer.Timer();
      mTimer.start(method(:timerCallback),QUIT_TIMEOUT,false);
      mResponseReceived = false;
    }

  function timerCallback() {
    System.println("timerCallback()");
    if (mResponseReceived == false) {
      System.println("Response has not been received - closing dialog");      
      // Dismiss the dialog
      Ui.popView(Ui.SLIDE_IMMEDIATE);
    } else {
      System.println("Response has been received - doing nothing");
    }
  }
    
    function onResponse(value)
    {
      System.println("QuitDelegate.onResponse() - "+value);
      mResponseReceived = true;
      if( value == CONFIRM_YES )
        {
	  // pop the confirmation dialog associated with this delegate
	  Ui.popView(Ui.SLIDE_IMMEDIATE);    		    	
	  // the system will automatically pop the top level dialog
        }
      
      return true;
    }
}

class MuteDelegate extends Ui.ConfirmationDelegate
{
  const DIALOG_TIMEOUT = 10 * 1000;  // Milliseconds
  var mTimer;
  var mAccelHandler;
  var mResponseReceived;
    function initialize(accelHandler)
    {
      System.println("MuteDelegate.initialize()");
      Ui.ConfirmationDelegate.initialize();
      mAccelHandler = accelHandler;
      
      // Start a timer to timeout this dialog - calls timerCallback
      mTimer = new Timer.Timer();
      mTimer.start(method(:muteTimerCallback),DIALOG_TIMEOUT,false);
      mResponseReceived = false;
    }

    function muteTimerCallback() {
      // Dismiss the dialog
      System.println("muteDelegate.muteTimerCallback()");
      //Ui.popView(Ui.SLIDE_IMMEDIATE);    		    	
      if (mResponseReceived == false) {
	System.println("Response has not been received - closing dialog");      
	// Dismiss the dialog
	Ui.popView(Ui.SLIDE_IMMEDIATE);
      } else {
	System.println("Response has been received - doing nothing");
	
      }
    }

    
    function onResponse(value)
    {
      System.println("MuteDelegate.onResponse() - "+value);
      mResponseReceived = true;
      if( value == CONFIRM_YES )
        {
	  mAccelHandler.muteAlarms();
        }
      return true;
    }
}

