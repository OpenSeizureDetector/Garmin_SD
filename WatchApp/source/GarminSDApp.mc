//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Application as App;
using Toybox.System;
using Toybox.Communications as Comm;

class GarminSDApp extends App.AppBase {

  class CommListener extends Comm.ConnectionListener {
    function initialize() {
      Comm.ConnectionListener.initialize();
    }
    
    function onComplete() {
      System.println("Transmit Complete");
    }
    
    function onError() {
      System.println("Transmit Failed");
    }
  }


  function initialize() {
    	System.println("GarminSdApp.initialize");
        AppBase.initialize();

	var listener = new CommListener();
	Comm.registerForPhoneAppMessages(method(:onPhoneMsg));
	Comm.transmit("Hello World.", null, listener);

    }
    
    // onStart() is called on application start up
    function onStart(state) {
      System.println("GarminSDApp.onStart");
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    	System.println("GarminSDApp.onStop");
    }

    // Return the initial view of your application here
    function getInitialView() {
    	System.println("GarminSDApp.getInitialView");
        var mainView = new AccelMagView();
        var viewDelegate = new AccelMagDelegate( mainView );
        return [mainView, viewDelegate];
    }

    function onPhoneMsg(msg) {
      var i;
      System.println("GarminSdApp.onPhoneMsg %s",msg.data.toString());
    }

}
