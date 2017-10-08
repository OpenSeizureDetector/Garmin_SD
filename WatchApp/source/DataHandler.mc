using Toybox.Sensor;
using Toybox.System;
using Toybox.WatchUi as Ui;

class DataHandler {
  const ANALYSIS_PERIOD = 5;
  const SAMPLE_PERIOD = 1;
  const SAMPLE_FREQUENCY = 25;

  var mSamplesX = new [ANALYSIS_PERIOD*SAMPLE_FREQUENCY];
  var mSamplesY = new [ANALYSIS_PERIOD*SAMPLE_FREQUENCY];
  var mSamplesZ = new [ANALYSIS_PERIOD*SAMPLE_FREQUENCY];

  var nSamp = 0;
  var mHR = 0;

  var mComms = null;

  ///////////////
  // Constructor
  function initialize() {
    System.println("DataHandler.initialize()");
    mComms = new GarminSDComms(self);
    mComms.onStart();
      
  }

  // Prints acclerometer data that is recevied from the system
  function accel_callback(sensorData) {
    System.println("accel_callback()");

    var iStart = nSamp*SAMPLE_PERIOD*SAMPLE_FREQUENCY;
    System.println(Lang.format("iStart=$1$, ns=$2$, nSamp=$3$",[iStart,SAMPLE_PERIOD*SAMPLE_FREQUENCY,nSamp]));
    for (var i = 0; i<SAMPLE_PERIOD*SAMPLE_FREQUENCY; i=i+1) {
      mSamplesX[iStart+i] = sensorData.accelerometerData.x[i];
      mSamplesY[iStart+i] = sensorData.accelerometerData.y[i];
      mSamplesZ[iStart+i] = sensorData.accelerometerData.z[i];
    }
    nSamp = nSamp + 1;

    Toybox.System.println("Raw samples, X axis: " + mSamplesX);
    Toybox.System.println("Raw samples, Y axis: " + mSamplesY);
    Toybox.System.println("Raw samples, Z axis: " + mSamplesZ);
    Ui.requestUpdate();
    
    if (nSamp*SAMPLE_PERIOD == ANALYSIS_PERIOD) {
      System.println("Doing Analysis....");
      mComms.sendAccelData();
      nSamp = 0;
    }
  }

  function heartrate_callback(sensorInfo) {
    System.println("HeartRate: " + sensorInfo.heartRate);
    mHR = sensorInfo.heartRate;
  }
    
    
  // Initializes the view and registers for accelerometer data
  function onStart() {
    System.println("DataHandler.onStart()");
    var maxSampleRate = Sensor.getMaxSampleRate();
    System.print("maxSampleRate = ");
    System.println(maxSampleRate);
    
    // initialize accelerometer to request the maximum amount of
    // data possible
    var options = {
      :period => SAMPLE_PERIOD,
      :sampleRate => SAMPLE_FREQUENCY,
      :enableAccelerometer => true
    };
    try {
      Sensor.registerSensorDataListener(method(:accel_callback),
					options);
      System.println("Registered for Sensor Data");
    } catch(e) {
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
