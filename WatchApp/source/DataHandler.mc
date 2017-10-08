using Toybox.Sensor;
using Toybox.System;
using Toybox.SensorLogging as SensorLogging;
using Toybox.ActivityRecording as Fit;

class DataHandler
{
    hidden var mSamplesX = null;
    hidden var mSamplesY = null;
    hidden var mSamplesZ = null;

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

    // Initializes the view and registers for accelerometer data
    function enableAccel() {
        var maxSampleRate = Sensor.getMaxSampleRate();
	System.print("maxSampleRate = ");
	System.println(maxSampleRate);

         // initialize accelerometer to request the maximum amount of data possible
        var options = {:period => 4, :sampleRate => maxSampleRate, :enableAccelerometer => true};
        try {
            Sensor.registerSensorDataListener(method(:onAccelData), options);
	    System.println("Registered for Sensor Data");
        }
        catch(e) {
            System.println(e.getErrorMessage());
        }
	System.println("enableAccel() Complete");
    }

    // Prints acclerometer data that is recevied from the system
    function onAccelData(sensorData) {
      System.println("onAccelData()");
      nSamp = nSamp + 1;
      mSamplesX = sensorData.accelerometerData.x;
      mSamplesY = sensorData.accelerometerData.y;
      mSamplesZ = sensorData.accelerometerData.z;

      Toybox.System.println("Raw samples, X axis: " + mSamplesX);
      Toybox.System.println("Raw samples, Y axis: " + mSamplesY);
      Toybox.System.println("Raw samples, Z axis: " + mSamplesZ);
    }

    function disableAccel() {
        Sensor.unregisterSensorDataListener();
	mSession.stop();
    }
}
