//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Application as App;
using Toybox.System;
using Toybox.Position;


class GarminSDApp extends App.AppBase {
  var mSdState;
  function initialize() {
    System.println("GarminSdApp.initialize");
    AppBase.initialize();

    mSdState = new GarminSDState();
    // Disable location tracking, in case that is causing battery drain
    // on Vivoactive 4.
    Position.enableLocationEvents(
      Position.LOCATION_DISABLE,
      method(:onPosition)
    );
  }

  // onStart() is called on application start up
  function onStart(state) {
    if (state != null) {
      System.println("GarminSDApp.onStart(): State=" + state.toString());
    } else {
      System.println("GarminSDApp.onStart(): State= null");
    }
    //System.println("benMode="+App.getApp().getProperty("benMode"));
    //System.println("benmode="+App.getApp().getProperty("benmode"));
    //System.println("prop2="+App.getApp().getProperty("prop2"));
  }

  // onStop() is called when your application is exiting
  function onStop(state) {
    if (state != null) {
      System.println("GarminSDApp.onStop(): State=" + state.toString());
    } else {
      System.println("GarminSDApp.onStop(): State= null");
    }
  }

  // Return the initial view of your application here
  function getInitialView() {
    System.println("GarminSDApp.getInitialView");
    var mainView = new GarminSDView(mSdState);
    var viewDelegate = new SdDelegate(mainView, mSdState);
    return [mainView, viewDelegate];
    //return [mainView];
  }

  function onPosition(info) {
    System.println("GarminSDApp.onPosition()");
    //var myLocation = info.position.toDegrees();
  }
}
