using Toybox.Sensor;
using Toybox.System;
using Toybox.SensorLogging as SensorLogging;
using Toybox.ActivityRecording as Fit;
using Toybox.WatchUi as Ui;

class DataHandler
{
    var mSamplesX = [0];
    var mSamplesY = [0];
    var mSamplesZ = [0];

    var mLogger;
    var mSession;
    var nSamp = 0;

    ///////////////
    // Constructor
    function initialize() {
      System.println("DataHandler.initialize()");
      try {
	mLogger = new SensorLogging.SensorLogger({:enableAccelerometer => true});
	mSession = Fit.createSession({:name=>"GarminSD",
	      :sport=>Fit.SPORT_GENERIC,
	      :sensorLogger => mLogger});
      } catch(e) {
	System.println(e.getErrorMessage());
      }
      System.println("DataHandler.initialize - complete");      
    }

    // Prints acclerometer data that is recevied from the system
    function accel_callback(sensorData) {
      System.println("accel_callback()");
      nSamp = nSamp + 1;
      mSamplesX = sensorData.accelerometerData.x;
      mSamplesY = sensorData.accelerometerData.y;
      mSamplesZ = sensorData.accelerometerData.z;

      Toybox.System.println("Raw samples, X axis: " + mSamplesX);
      Toybox.System.println("Raw samples, Y axis: " + mSamplesY);
      Toybox.System.println("Raw samples, Z axis: " + mSamplesZ);
      Ui.requestUpdate();

    }

    
    // Initializes the view and registers for accelerometer data
    function onStart() {
	System.println("DataHandler.onStart()");
        var maxSampleRate = Sensor.getMaxSampleRate();
	System.print("maxSampleRate = ");
	System.println(maxSampleRate);

         // initialize accelerometer to request the maximum amount of data possible
        var options = {:period => 1,
		       :sampleRate => 25,
		       :enableAccelerometer => true};
        try {
            Sensor.registerSensorDataListener(method(:accel_callback), options);
	    mSession.start();
	    System.println("Registered for Sensor Data");
        }
        catch(e) {
            System.println(e.getErrorMessage());
        }
	System.println("DataHandler.onStart() Complete");
    }


    function onStop() {
	System.println("DataHandler.onStop()");
        Sensor.unregisterSensorDataListener();
	mSession.stop();
    }
}
