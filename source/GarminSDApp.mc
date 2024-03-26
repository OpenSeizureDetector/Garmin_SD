//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Application as App;
using Toybox.System;
using Toybox.Timer;


class GarminSDApp extends App.AppBase {
  var mSdState;
  var mTimer as Toybox.Timer;
  var mainView as GarminSDView;
  var viewDelegate as SdDelegate;

  function initialize() {
    writeLog("GarminSdApp.initialize", "");
    AppBase.initialize();

    mSdState = new GarminSDState();
    // Start a timer that calls timerCallback every second
  }

  // onStart() is called on application start up
  function onStart(state) {
    if (state != null) {
      writeLog("GarminSDApp.onStart()", "State=" + state.toString());
    } else {
      writeLog("GarminSDApp.onStart()", "State= null");
    }
    //System.println("benMode="+App.getApp().getProperty("benMode"));
    //System.println("benmode="+App.getApp().getProperty("benmode"));
    //System.println("prop2="+App.getApp().getProperty("prop2"));

    mTimer = new Timer.Timer();
    mTimer.start(method(:onTick), 1000, true);
  }

  // onStop() is called when your application is exiting
  function onStop(state) {
    if (state != null) {
      writeLog("GarminSDApp.onStop()", "State=" + state.toString());
    } else {
      writeLog("GarminSDApp.onStop()", "State= null");
    }
    mTimer.stop();
  }

  // Return the initial view of your application here
  function getInitialView() {
    writeLog("GarminSDApp.getInitialView", "");
    mainView = new GarminSDView(mSdState);
    viewDelegate = new SdDelegate(mainView, mSdState);
    return [mainView, viewDelegate];
    //return [mainView];
  }
  function onTick() {
    /**
    Called by GarminSDView every second in case we need to do anything timed.
    */
    //writeLog("GarminSDView.onTick()", "Start");
    mainView.onTick();
    viewDelegate.onTick();
  }
}
