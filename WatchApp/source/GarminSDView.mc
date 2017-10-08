//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Sensor as Sensor;
using Toybox.Timer as Timer;
using Toybox.Math as Math;
using Toybox.Communications as Comm;


class GarminSDView extends Ui.View {
  var accelHandler;
  var accel;
  var mag;
  var dataTimer;
  var width;
  var height;
  
  function initialize() {
    View.initialize();
    accelHandler = new DataHandler();
    
    //var listener = new CommListener();
  }

    // Load your resources here
    function onLayout(dc) {
        dataTimer = new Timer.Timer();
        dataTimer.start(method(:timerCallback), 100, true);

        width = dc.getWidth();
        height = dc.getHeight();
    }

    // Restore the state of the app and prepare the view to be shown
    function onShow() {
      accelHandler.enableAccel();
      //Comm.registerForPhoneAppMessages(method(:onMessageReceived));
      //Comm.transmit("Hello World.", null, listener);
      System.println("GarminSDView.onShow() - finishing");

    }

    // Update the view
    function onUpdate(dc) {
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
        dc.clear();
	dc.drawText(width / 2,  height-20, Gfx.FONT_TINY, "OpenSeizureDetector", Gfx.TEXT_JUSTIFY_CENTER);

        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
        if (accel != null) {
	  //dc.drawText(width / 2,  3, Gfx.FONT_TINY, "Ax = " + accel[0], Gfx.TEXT_JUSTIFY_CENTER);
	  //dc.drawText(width / 2, 23, Gfx.FONT_TINY, "Ay = " + accel[1], Gfx.TEXT_JUSTIFY_CENTER);
	  //dc.drawText(width / 2, 43, Gfx.FONT_TINY, "Az = " + accel[2], Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(width / 2, 3, Gfx.FONT_TINY, "no Accel", Gfx.TEXT_JUSTIFY_CENTER);
        }

    }

    function timerCallback() {
      //var info = Sensor.getInfo();

      //if (info has :accel && info.accel != null) {
      //      accel = info.accel;
      //      var xAccel = accel[0];
      //      var yAccel = accel[1] * -1; // Cardinal Y direction is opposite the screen coordinates

      //  }

        Ui.requestUpdate();
    }

    // Called when this View is removed from the screen. Save the
    // state of your app here.
    function onHide() {
      System.println("GarminSDView.onStop");
      accelHandler.disableAccel();
    }


      function onMessageReceived(msg) {
    var i;
    System.print("GarminSdApp.onMessageReceived - ");
    System.println(msg.data.toString());
  }

  /////////////////////////////////////////////////////////////////////
  // Connection listener class that is used to log success and failure
  // of message transmissions.
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


}
