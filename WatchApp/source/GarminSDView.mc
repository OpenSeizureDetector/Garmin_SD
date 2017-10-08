//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;

class GarminSDView extends Ui.View {
  var accelHandler;
  var accel;
  var width;
  var height;
  
  function initialize() {
    System.println("GarminSDView.initialize()");
    View.initialize();
    accelHandler = new DataHandler();
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
    System.println("GarminSDView.onUpdate()");
    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_RED);
    dc.clear();
    dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_WHITE);
    dc.drawText(width / 2,  height-20, Gfx.FONT_TINY, "OpenSeizureDetector",
		Gfx.TEXT_JUSTIFY_CENTER);
    dc.drawText(width / 2,  height-40, Gfx.FONT_LARGE, accelHandler.nSamp,
		Gfx.TEXT_JUSTIFY_CENTER);
    //View.onUpdate(dc);
    System.println("GarminSDView.onUpdate() - complete");
  }
  
  

  // Called when this View is removed from the screen. Save the
  // state of your app here.
  function onHide() {
    System.println("GarminSDView.onHide");
    accelHandler.onStop();
    System.println("GarminSDView.onHide - Complete");
  }
  
  

}
