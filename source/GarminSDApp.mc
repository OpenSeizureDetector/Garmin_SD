//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Application as App;
using Toybox.System;
using Toybox.Timer;
import Toybox.Lang;


class GarminSDApp extends App.AppBase {
  var mSdState as GarminSDState;
  var mTimer as Toybox.Timer.Timer;
  var mainView as GarminSDView or Null;
  var viewDelegate as SdDelegate or Null;

  function initialize() {
    writeLog("GarminSdApp.initialize", "");
    AppBase.initialize();
    mSdState = new GarminSDState();
    mTimer = new Timer.Timer();
  }

  // onStart() is called on application start up
  function onStart(state as Dictionary or Null) {
    if (state != null) {
      writeLog("GarminSDApp.onStart()", "State=" + state.toString());
    } else {
      writeLog("GarminSDApp.onStart()", "State= null");
    }
    // Start a timer that calls timerCallback every second
    mTimer.start(method(:onTick), 1000, true);
  }

  // onStop() is called when your application is exiting
  function onStop(state as Dictionary or Null) {
    if (state != null) {
      writeLog("GarminSDApp.onStop()", "State=" + state.toString());
    } else {
      writeLog("GarminSDApp.onStop()", "State= null");
    }
    mTimer.stop();
  }

  // Return the initial view of your application here
  function getInitialView() as Array<Toybox.WatchUi.Views or Toybox.WatchUi.InputDelegates> or Null {
    writeLog("GarminSDApp.getInitialView", "");
    mainView = new GarminSDView(mSdState);
    viewDelegate = new SdDelegate(mainView, mSdState);
    return [mainView, viewDelegate] as Array<Toybox.WatchUi.InputDelegates or Toybox.WatchUi.Views>;
  }

  function onTick() as Void {
    /**
    Called by GarminSDView every second in case we need to do anything timed.
    */
    //writeLog("GarminSDApp.onTick()", "Start");
    (mainView as GarminSDView).onTick();
    //(viewDelegate as SdDelegate).onTick();
  }
}
