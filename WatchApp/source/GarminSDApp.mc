//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Application as App;
using Toybox.System;
using Toybox.Position;

class GarminSDApp extends App.AppBase {
  
  function initialize() {
    System.println("GarminSdApp.initialize");
    AppBase.initialize();
    // Disable location tracking, in case that is causing battery drain
    // on Vivoactive 4.
    Position.enableLocationEvents(
				  Position.LOCATION_DISABLE,
				  method(:onPosition));
  }
    
  // onStart() is called on application start up
  function onStart(state) {
    if (state != null) {
      System.println("GarminSDApp.onStart(): State=" + state.toString());
    } else {
      System.println("GarminSDApp.onStart(): State= null");
    }
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
    var mainView = new GarminSDView();
    var viewDelegate = new SdDelegate(mainView);
    return [mainView, viewDelegate];
    //return [mainView];
  }

  function onPosition(info) {
    System.println("GarminSDApp.onPosition()");
    var myLocation = info.position.toDegrees();
  }
  
}


