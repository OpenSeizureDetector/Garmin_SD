/*
  Garmin_sd - a data source for OpenSeizureDetector that runs on a
  Garmin ConnectIQ watch.

  See http://openseizuredetector.org for more information.

  Copyright Graham Jones, 2019, 2022

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
using Toybox.System;
using Toybox.Time;
using Toybox.Lang;
using Toybox.Application as App;
import Toybox.Application.Storage;


class GarminSDView extends Ui.View {
  var accelHandler;
  var width;
  var halfWidth;
  var height;
  var mSdState;
  var beatsPerMinuteAbbrev;
  var batteryAbbrev;
  var muteLabel;
  var fontSizeClock;
  var fontHrO2Str;
  var heightScaleLine1;
  var heightScaleLine2;
  var heightScaleLine3;
  var heightScaleLine4;
  var heightScaleLine5;
  var lastUpdatedMinute = -1;

  function initialize(sdState) {
    writeLog("GarminSDView.initialize()", "");
    View.initialize();
    mSdState = sdState;
    accelHandler = new GarminSDDataHandler(
      Ui.loadResource(Rez.Strings.VersionId)
    );
    //loading resources locally
    beatsPerMinuteAbbrev = Ui.loadResource(Rez.Strings.Beats_per_minute_abbrev);
    batteryAbbrev = Ui.loadResource(Rez.Strings.Battery_abbrev);
    muteLabel = Ui.loadResource(Rez.Strings.Mute_label);
    writeLog("GarminSDView.initialize()", "Complete");
  }

  function onTick() {
    /**
    Called by GarminSDView every second in case we need to do anything timed.
    */
    //writeLog("GarminSDView.onTick()", "Start");
    accelHandler.onTick();
    var currentMinute = System.getClockTime().min;
    if ((accelHandler.mComms.needs_update == 1)||(currentMinute != lastUpdatedMinute)){
      writeLog("GarminSDView.onTick()", "update view");
      Ui.requestUpdate();
      lastUpdatedMinute = currentMinute;
      accelHandler.mComms.needs_update = 0;
    }
  }

  // Load your resources here
  function onLayout(dc) {
    writeLog("GarminSDView.onLayout()", "");
    width = dc.getWidth();
    halfWidth = width/2;
    height = dc.getHeight();
    // Nominal height of display for positioning text - values are for a 240px high display.
    var heightScale = height / 240.0;
    heightScaleLine1=heightScale*20;
    heightScaleLine2=heightScale*45;
    heightScaleLine3=heightScale*120;
    heightScaleLine4=heightScale*150;
    heightScaleLine5=heightScale*180;
    //precalculate font size
    // There is an issue with some devices having different font sizes, so
    // we check the width of the text for our preferred font size, and if it is too long
    // we use a smaller font.
    var timeTextDims = dc.getTextDimensions(
      "23:59:52",
      Gfx.FONT_SYSTEM_NUMBER_HOT
    );
    if (timeTextDims[0] < width) {
      fontSizeClock = Gfx.FONT_SYSTEM_NUMBER_HOT;
    }
    else{
      fontSizeClock = Gfx.FONT_SYSTEM_NUMBER_MEDIUM;
    }
    //precalculate HRO2 string size from dummy values
    var hrO2Str = "";
    if (accelHandler.mO2SensorIsEnabled == true){
        hrO2Str = Lang.format("150 $1$ / 100% Ox", [beatsPerMinuteAbbrev]);
    }
    else {
        hrO2Str = Lang.format("150 $1$", [beatsPerMinuteAbbrev]);
    }
    var hrTextDims = dc.getTextDimensions(hrO2Str, Gfx.FONT_LARGE);
    if (hrTextDims[0] < width) {
      fontHrO2Str = Gfx.FONT_LARGE;
    }
    else{
      fontHrO2Str = Gfx.FONT_SMALL;
    }
    writeLog("GarminSDView.on_layout()", "Start accelHandler");
    accelHandler.onStart();
  }

  // Restore the state of the app and prepare the view to be shown
  function onShow() {
  }

  // Update the view
  function onUpdate(dc) {
    var myTime = System.getClockTime();
    var timeString = Lang.format("$1$:$2$", [
        myTime.hour.format("%02d"),
        myTime.min.format("%02d")
    ]);
    var sysStats = System.getSystemStats();
    var hrO2Str = "";
    if (accelHandler.mO2SensorIsEnabled == true){
        hrO2Str = Lang.format("$1$ $2$ / $3$% Ox", [
          accelHandler.mHR,
          beatsPerMinuteAbbrev,
          accelHandler.mO2sat,
        ]);
    }
    else {
        hrO2Str = Lang.format("$1$ $2$", [
          accelHandler.mHR,
          beatsPerMinuteAbbrev,
        ]);
    }

    var hrBatStr = Lang.format("$1$: $2$%", [
      batteryAbbrev,
      sysStats.battery.format("%02.0f"),
    ]);

    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
    dc.clear();
    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    dc.drawText(
      halfWidth,
      0,
      Gfx.FONT_MEDIUM,
      "OpenSeizure",
      Gfx.TEXT_JUSTIFY_CENTER
    );
    dc.drawText(
      halfWidth,
      heightScaleLine1,
      Gfx.FONT_MEDIUM,
      "Detector",
      Gfx.TEXT_JUSTIFY_CENTER
    );
    dc.drawText(
      halfWidth,
      heightScaleLine2,
      fontSizeClock,
      timeString,
      Gfx.TEXT_JUSTIFY_CENTER
    );
    dc.drawText(
      halfWidth,
      heightScaleLine3,
      fontHrO2Str,
      hrO2Str,
      Gfx.TEXT_JUSTIFY_CENTER
    );
    dc.drawText(
      halfWidth,
      heightScaleLine4,
      fontHrO2Str,
      hrBatStr,
      Gfx.TEXT_JUSTIFY_CENTER
    );
    if (accelHandler.mMute) {
      dc.drawText(
        halfWidth,
        heightScaleLine5,
        Gfx.FONT_LARGE,
        muteLabel,
        Gfx.TEXT_JUSTIFY_CENTER
      );
    } else {
      dc.drawText(
        halfWidth,
        heightScaleLine5,
        Gfx.FONT_LARGE,
        accelHandler.mStatusStr,
        Gfx.TEXT_JUSTIFY_CENTER
      );
    }
  }

  // Called when this View is removed from the screen. Save the
  // state of your app here.
  function onHide() {
  }
}

class SdDelegate extends Ui.BehaviorDelegate {
  var mSdView;
  var mSdState;
  var mMode;
  var mMuteDlgOpenTime;
  var mQuitDlgOpenTime;
  const QUIT_TIMEOUT = 10; // Seconds
  const QUIT_TIMEOUT_BENMODE = 1; // Second
  const MUTE_TIMEOUT = 10; // Seconds


  function initialize(sdView, sdState) {
    writeLog("SdDelegate.initialize()", "");
    mSdView = sdView;
    mSdState = sdState;
    mSdState.setMode(MODE_RUNNING);

    // Set default values for settings if necessary
    if (Storage.getValue(MENUITEM_BENMODE) == null) {
      Storage.setValue(MENUITEM_BENMODE, 0);
    }
    if (Storage.getValue(MENUITEM_SOUND) == null) {
      Storage.setValue(MENUITEM_SOUND, 0);
    }
    if (Storage.getValue(MENUITEM_VIBRATION) == null) {
      Storage.setValue(MENUITEM_VIBRATION, 0);
    }
    if (Storage.getValue(MENUITEM_LIGHT) == null) {
      Storage.setValue(MENUITEM_LIGHT, 0);
    }
    if (Storage.getValue(MENUITEM_O2SENSOR) == null) {
      Storage.setValue(MENUITEM_O2SENSOR, 1);
    }

    BehaviorDelegate.initialize();
  }

  function onTick() {
    //System.println("SdDelegate.timerCallback()");
    // Handle Timeout of Quit Dialog
    if (mSdState.getMode() == MODE_QUITDLG) {
      //System.println("SdDelegate.timerCalback - Quit Dialog Displayed");
      var timeoutSecs = Storage.getValue(MENUITEM_BENMODE)
        ? QUIT_TIMEOUT_BENMODE
        : QUIT_TIMEOUT;
      var dlgOpenSecs = Time.now().value() - mQuitDlgOpenTime;
      //System.println("dlgOpenMs="+dlgOpenSecs);
      if (dlgOpenSecs > timeoutSecs) {
        writeLog("timerCallback()" , "Quit Dialog Timedout - closing");
        mSdState.setMode(MODE_RUNNING);
        Ui.popView(Ui.SLIDE_IMMEDIATE);
      }
    }
    //mSdView.accelHandler.onTick();
  }

  function onMenu() {
    // Display a menu of configurable options
    var menu = new GarminSDSettingsMenu();
    var boolean;
    //var boolean = Storage.getValue(1) ? true : false;
    /*var boolean = mSdView.accelHandler.mMute ? true : false;
    menu.addItem(
      new Ui.ToggleMenuItem(
        Ui.loadResource(Rez.Strings.Mute_title),
        Ui.loadResource(Rez.Strings.Mute_desc),
        MENUITEM_MUTE,
        boolean,
        null
      )
    );
    */


    boolean = Storage.getValue(MENUITEM_VIBRATION) ? true : false;
    menu.addItem(
      new Ui.ToggleMenuItem(
        Ui.loadResource(Rez.Strings.Vibration_title),
        Ui.loadResource(Rez.Strings.Vibration_desc),
        MENUITEM_VIBRATION,
        boolean,
        null
      )
    );

    boolean = Storage.getValue(MENUITEM_SOUND) ? true : false;
    menu.addItem(
      new Ui.ToggleMenuItem(
        Ui.loadResource(Rez.Strings.Sound_title),
        Ui.loadResource(Rez.Strings.Sound_desc),
        MENUITEM_SOUND,
        boolean,
        null
      )
    );

    boolean = Storage.getValue(MENUITEM_LIGHT) ? true : false;
    menu.addItem(
      new Ui.ToggleMenuItem(
        Ui.loadResource(Rez.Strings.Light_title),
        Ui.loadResource(Rez.Strings.Light_desc),
        MENUITEM_LIGHT,
        boolean,
        null
      )
    );

    boolean = Storage.getValue(MENUITEM_O2SENSOR) ? true : false;
    menu.addItem(
      new Ui.ToggleMenuItem(
        Ui.loadResource(Rez.Strings.O2_sensor_title),
        Ui.loadResource(Rez.Strings.O2_sensor_desc),
        MENUITEM_O2SENSOR,
        boolean,
        null
      )
    );

    boolean = Storage.getValue(MENUITEM_BENMODE) ? true : false;
    menu.addItem(
      new Ui.ToggleMenuItem(
        Ui.loadResource(Rez.Strings.BenMode_title),
        Ui.loadResource(Rez.Strings.BenMode_desc),
        MENUITEM_BENMODE,
        boolean,
        null
      )
    );

    Ui.pushView(
      menu,
      new GarminSDSettingsMenuDelegate(mSdView.accelHandler),
      Ui.SLIDE_IMMEDIATE
    );
    return true;
  }

  function onBack() {
    // Display a quit confirmation dialog, which times out after a given period
    // Handled by setting mMode to MODE_QUITDLG and initialising the time that we open the dialog.
    // timeout is handled in the timerCallback function.
    writeLog("SdDelegate.onBack()", "");
    var quitString = Ui.loadResource(Rez.Strings.Exit_app_confirmation);
    var cd = new Ui.Confirmation(quitString);
    mSdState.setMode(MODE_QUITDLG);
    mQuitDlgOpenTime = Time.now().value();
    Ui.pushView(cd, new QuitDelegate(mSdView, mSdState), Ui.SLIDE_IMMEDIATE);
    return true;
  }

  // Detect Menu button input
  function onKey(keyEvent) {
    writeLog("onKey()", " key="+keyEvent.getKey()); // e.g. KEY_MENU = 7
    if (keyEvent.getKey() == KEY_ENTER) {
        if (mSdView.accelHandler.mMute) {
          mSdView.accelHandler.mMute = false;
          writeLog( "onKey()", "Mute="+mSdView.accelHandler.mMute);
        } else {
          mSdView.accelHandler.mMute = true;
          writeLog("onKey()", "Mute="+mSdView.accelHandler.mMute);
        }
        Ui.requestUpdate();
      return true;
    } 
    return true;
  }

}

class QuitDelegate extends Ui.ConfirmationDelegate {
  // Handles user response to the quit confirmation dialog.
  var mResponseReceived;
  var mSdView;
  var mSdState;

  function initialize(sdView, sdState) {
    writeLog("QuitDelegate.initialize()", "");
    mSdView = sdView;
    mSdState = sdState;
    Ui.ConfirmationDelegate.initialize();

    mResponseReceived = false;
  }

  function onResponse(value) {
    writeLog("QuitDelegate.onResponse()", "Resonse = " + value);
    mResponseReceived = true;
    if (value == CONFIRM_YES) {
      // pop the confirmation dialog associated with this delegate
      writeLog("quitDelegate.onResponse()", "Exiting app");
      Ui.popView(Ui.SLIDE_IMMEDIATE);
    } else {
      // the system will automatically pop the top level dialog so we do not have to close it ourselves
      writeLog("quitDelegate.onResponse()", "Closing quit dalog and returning to running state");
      mSdState.setMode(MODE_RUNNING);
    }

    return true;
  }
}


//! The app settings menu
class GarminSDSettingsMenu extends Ui.Menu2 {
  //! Constructor
  public function initialize() {
    Menu2.initialize({ :title => "Settings" });
  }
}

//! Input handler for the app settings menu
class GarminSDSettingsMenuDelegate extends Ui.Menu2InputDelegate {
  var mAccelHandler;
  //! Constructor
  public function initialize(accelHandler) {
    Menu2InputDelegate.initialize();
    mAccelHandler = accelHandler;
  }

  //! Handle a menu item being selected
  //! @param menuItem The menu item selected
  public function onSelect(menuItem as Ui.MenuItem) as Void {
    if (menuItem instanceof ToggleMenuItem) {
        writeLog("menuDelegate.onSelect()", "id=" + menuItem.getId());
        Storage.setValue(menuItem.getId() as Ui.Number, menuItem.isEnabled());
    }
  }
}