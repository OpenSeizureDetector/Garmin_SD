using Toybox.Sensor;
using Toybox.System;
using Toybox.WatchUi as Ui;

class DataHandler
{
    var mSamplesX = [0];
    var mSamplesY = [0];
    var mSamplesZ = [0];

    var nSamp = 0;
    var mHR = 0;

    ///////////////
    // Constructor
    function initialize() {
      System.println("DataHandler.initialize()");
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

    function heartrate_callback(sensorInfo) {
      System.println("Heart Rate: " + sensorInfo.heartRate);
      mHR = sensorInfo.heartRate;
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
	    System.println("Registered for Sensor Data");
        }
        catch(e) {
            System.println(e.getErrorMessage());
        }

	// Intialise heart rate monitoring.
	Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
	Sensor.enableSensorEvents(method(:heartrate_callback));
    }


    function onStop() {
	System.println("DataHandler.onStop()");
        Sensor.unregisterSensorDataListener();
	Sensor.setEnabledSensors([]);
    }
}
