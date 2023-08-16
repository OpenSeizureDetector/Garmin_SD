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
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Timer;
using Toybox.Lang;
using Toybox.Application as App;
import Toybox.Application.Storage;

// FIXME:  Move this to a common include file.
enum {
  MENUITEM_MUTE,
  MENUITEM_BENMODE,
  MENUITEM_VIBRATION,
  MENUITEM_SOUND,
  MENUITEM_LIGHT,
}

class GarminSDView extends Ui.View {
  var accelHandler;
  var width;
  var height;

  function initialize() {
    System.println("GarminSDView.initialize()");
    View.initialize();
    accelHandler = new GarminSDDataHandler(
      Ui.loadResource(Rez.Strings.VersionId)
    );
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
    var heightScale = height / 240.0; // Nominal height of display for positioning text - values are for a 240px high display.
    //System.print("height = ");
    //System.println(height);
    //System.print("heightScale = ");
    //System.println(heightScale);
    var dateTime = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
    var timeString = Lang.format("$1$:$2$:$3$", [
      dateTime.hour.format("%02d"),
      dateTime.min.format("%02d"),
      dateTime.sec.format("%02d"),
    ]);
    var sysStats = System.getSystemStats();
    var hrO2Str = Lang.format("$1$ $2$ / $3$% Ox", [
      accelHandler.mHR,
      Ui.loadResource(Rez.Strings.Beats_per_minute_abbrev),
      accelHandler.mO2sat,
    ]);

    var hrBatStr = Lang.format("$1$: $2$%", [
      Ui.loadResource(Rez.Strings.Battery_abbrev),
      sysStats.battery.format("%02.0f"),
    ]);

    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
    dc.clear();
    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);
    dc.drawText(
      width / 2,
      0,
      Gfx.FONT_MEDIUM,
      "OpenSeizure",
      Gfx.TEXT_JUSTIFY_CENTER
    );
    dc.drawText(
      width / 2,
      20 * heightScale,
      Gfx.FONT_MEDIUM,
      "Detector",
      Gfx.TEXT_JUSTIFY_CENTER
    );
    // There is an issue with some devices having different font sizes, so
    // we check the width of the text for our preferred font size, and if it is too long
    // we use a smaller font.
    var timeTextDims = dc.getTextDimensions(
      timeString,
      Gfx.FONT_SYSTEM_NUMBER_HOT
    );
    if (timeTextDims[0] < width) {
      dc.drawText(
        width / 2,
        45 * heightScale,
        Gfx.FONT_SYSTEM_NUMBER_HOT,
        timeString,
        Gfx.TEXT_JUSTIFY_CENTER
      );
    } else {
      dc.drawText(
        width / 2,
        45 * heightScale,
        Gfx.FONT_SYSTEM_NUMBER_MEDIUM,
        timeString,
        Gfx.TEXT_JUSTIFY_CENTER
      );
    }
    var hrTextDims = dc.getTextDimensions(hrO2Str, Gfx.FONT_LARGE);
    if (hrTextDims[0] < width) {
      dc.drawText(
        width / 2,
        120 * heightScale,
        Gfx.FONT_LARGE,
        hrO2Str,
        Gfx.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        width / 2,
        150 * heightScale,
        Gfx.FONT_LARGE,
        hrBatStr,
        Gfx.TEXT_JUSTIFY_CENTER
      );
    } else {
      dc.drawText(
        width / 2,
        120 * heightScale,
        Gfx.FONT_SMALL,
        hrO2Str,
        Gfx.TEXT_JUSTIFY_CENTER
      );
      dc.drawText(
        width / 2,
        150 * heightScale,
        Gfx.FONT_SMALL,
        hrBatStr,
        Gfx.TEXT_JUSTIFY_CENTER
      );
    }
    if (accelHandler.mMute) {
      dc.drawText(
        width / 2,
        180 * heightScale,
        Gfx.FONT_LARGE,
        Ui.loadResource(Rez.Strings.Mute_label),
        Gfx.TEXT_JUSTIFY_CENTER
      );
    } else {
      dc.drawText(
        width / 2,
        180 * heightScale,
        Gfx.FONT_LARGE,
        accelHandler.mStatusStr,
        Gfx.TEXT_JUSTIFY_CENTER
      );
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
    var menu = new GarminSDSettingsMenu();
    //var boolean = Storage.getValue(1) ? true : false;
    var boolean = mSdView.accelHandler.mMute ? true : false;
    menu.addItem(
      new Ui.ToggleMenuItem("Mute Alarms", null, MENUITEM_MUTE, boolean, null)
    );

    boolean = Storage.getValue(MENUITEM_BENMODE) ? true : false;
    menu.addItem(
      new Ui.ToggleMenuItem("Ben Mode", null, MENUITEM_BENMODE, boolean, null)
    );

    boolean = Storage.getValue(MENUITEM_VIBRATION) ? true : false;
    menu.addItem(
      new Ui.ToggleMenuItem(
        "Vibration",
        null,
        MENUITEM_VIBRATION,
        boolean,
        null
      )
    );

    boolean = Storage.getValue(MENUITEM_SOUND) ? true : false;
    menu.addItem(
      new Ui.ToggleMenuItem("Sound", null, MENUITEM_SOUND, boolean, null)
    );

    boolean = Storage.getValue(MENUITEM_LIGHT) ? true : false;
    menu.addItem(
      new Ui.ToggleMenuItem("Light", null, MENUITEM_LIGHT, boolean, null)
    );

    Ui.pushView(
      menu,
      new GarminSDSettingsMenuDelegate(mSdView.accelHandler),
      Ui.SLIDE_IMMEDIATE
    );
    return true;

    //System.println("SdDelegate.onMenu() - Showing confirm dialog");
    //var msgStr = Ui.loadResource(Rez.Strings.Mute_alarms_confirmation);
    //var cd = new Ui.Confirmation( msgStr );
    //Ui.pushView( cd,
    //		 new MuteDelegate(mSdView.accelHandler),
    //		 Ui.SLIDE_IMMEDIATE );
    //return true;
  }

  // When a back behavior occurs, onBack() is called.
  // @return [Boolean] true if handled, false otherwise
  function onBack() {
    System.println("SdDelegate.onBack()");
    var quitString = Ui.loadResource(Rez.Strings.Exit_app_confirmation);
    var cd = new Ui.Confirmation(quitString);
    Ui.pushView(cd, new QuitDelegate(), Ui.SLIDE_IMMEDIATE);
    return true;
  }

  // Detect Menu button input
  function onKey(keyEvent) {
    if (keyEvent.getKey() == KEY_START) {
      var quitString = Ui.loadResource(Rez.Strings.Exit_app_confirmation);
      var cd = new Ui.Confirmation(quitString);
      Ui.pushView(cd, new QuitDelegate(), Ui.SLIDE_IMMEDIATE);
      return true;
    } else if (keyEvent.getKey() == KEY_ENTER) {
      var quitString = Ui.loadResource(Rez.Strings.Exit_app_confirmation);
      var cd = new Ui.Confirmation(quitString);
      Ui.pushView(cd, new QuitDelegate(), Ui.SLIDE_IMMEDIATE);
      return true;
    }
    System.println(keyEvent.getKey()); // e.g. KEY_MENU = 7
    return true;
  }
}

class QuitDelegate extends Ui.ConfirmationDelegate {
  const QUIT_TIMEOUT = 10 * 1000; // Milliseconds
  const QUIT_TIMEOUT_BENMODE = 500; // Milliseconds
  var mTimer = new Timer.Timer();
  var mResponseReceived;

  function initialize() {
    System.println("QuitDelegate.initialize()");
    Ui.ConfirmationDelegate.initialize();

    // Start a timer to timeout this dialog - calls timerCallback
    mTimer.stop();
    var timeoutMs = Storage.getValue(MENUITEM_BENMODE)
      ? QUIT_TIMEOUT_BENMODE
      : QUIT_TIMEOUT;
    System.println("Quit Timeout Ms = " + timeoutMs);
    mTimer.start(method(:timerCallback), timeoutMs, false);
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

  function onResponse(value) {
    System.println("QuitDelegate.onResponse() - " + value);
    mResponseReceived = true;
    if (value == CONFIRM_YES) {
      // pop the confirmation dialog associated with this delegate
      Ui.popView(Ui.SLIDE_IMMEDIATE);
      // the system will automatically pop the top level dialog
    }

    return true;
  }
}

class MuteDelegate extends Ui.ConfirmationDelegate {
  const DIALOG_TIMEOUT = 10 * 1000; // Milliseconds
  var mTimer = new Timer.Timer();
  var mAccelHandler;
  var mResponseReceived;
  function initialize(accelHandler) {
    System.println("MuteDelegate.initialize()");
    Ui.ConfirmationDelegate.initialize();
    mAccelHandler = accelHandler;

    // Start a timer to timeout this dialog - calls timerCallback
    mTimer.stop();
    mTimer.start(method(:muteTimerCallback), DIALOG_TIMEOUT, false);
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

  function onResponse(value) {
    System.println("MuteDelegate.onResponse() - " + value);
    mResponseReceived = true;
    if (value == CONFIRM_YES) {
      mAccelHandler.muteAlarms();
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
      System.println("onSelect - id=" + menuItem.getId());
      if (menuItem.getId() == MENUITEM_MUTE) {
        System.println("Mute Selected");
        System.println("SdDelegate.onMenu() - Showing confirm dialog");
        var msgStr = Ui.loadResource(Rez.Strings.Mute_alarms_confirmation);
        var cd = new Ui.Confirmation(msgStr);
        Ui.pushView(cd, new MuteDelegate(mAccelHandler), Ui.SLIDE_IMMEDIATE);
      } else {
        System.println("Storing selected value");
        Storage.setValue(menuItem.getId() as Ui.Number, menuItem.isEnabled());
      }
      //Storage.setValue(menuItem.getId() as Ui.Number, menuItem.isEnabled());
    }
  }
}
