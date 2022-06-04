/*
  Garmin_sd - a data source for OpenSeizureDetector that runs on a
  Garmin ConnectIQ watch.

  See http://openseizuredetector.org for more information.

  Copyright Graham Jones, 2019, 2022.

  This file is part of Garmin_sd.

  Garmin_sd is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Garmin_sd is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Garmin_sd.  If not, see <http://www.gnu.org/licenses/>.

  November 2021 - Added support for blood oxygen saturation based on work
          by Steve Lee.

*/
using Toybox.Sensor;
using Toybox.System;
using Toybox.WatchUi as Ui;
using Toybox.Timer;
using Toybox.Math;

class GarminSDDataHandler {
  const ANALYSIS_PERIOD = 5;
  const SAMPLE_PERIOD = 1;
  const SAMPLE_FREQUENCY = 25;
  const MUTE_TIMER_PERIOD = 5 * 60 * 1000;   // 5 min in ms
  //const MUTE_TIMER_PERIOD = 20 * 1000;   // 20 sec in ms

  var mSamplesX = new [ANALYSIS_PERIOD*SAMPLE_FREQUENCY];
  var mSamplesY = new [ANALYSIS_PERIOD*SAMPLE_FREQUENCY];
  var mSamplesZ = new [ANALYSIS_PERIOD*SAMPLE_FREQUENCY];

  var nSamp = 0;
  var mHR = 0;
  var mO2sat = 0;
  var mMute = 0;
  var mMuteTimer;
  var mStatusStr = "---";
  var mComms = null;
  var mVersionStr = "";

  ///////////////
  // Constructor
  function initialize(versionStr) {
    System.println("DataHandler.initialize()");
    mVersionStr = versionStr;
    // On Start-up we show the app version number in place of satus.
    mStatusStr = versionStr;
    mComms = new GarminSDComms(self);
    mComms.onStart();
      
  }

  // Return the current set of data as a JSON String
  function getDataJson() {
    var i;
    var jsonStr = "{ dataType: 'raw', data: [";
    for (i = 0; i<ANALYSIS_PERIOD*SAMPLE_FREQUENCY; i=i+1) {
      if (i>0) {
	jsonStr = jsonStr + ", ";
      }
      jsonStr = jsonStr + Math.sqrt( mSamplesX[i] * mSamplesX[i]
      		   +mSamplesY[i] * mSamplesY[i]
      		   +mSamplesZ[i] * mSamplesZ[i]);
    }
    jsonStr = jsonStr + "], data3D: [";
    for (i = 0; i<ANALYSIS_PERIOD*SAMPLE_FREQUENCY; i=i+1) {
      if (i>0) {
	jsonStr = jsonStr + ", ";
      }
      jsonStr = jsonStr + mSamplesX[i] + ", ";
      jsonStr = jsonStr + mSamplesY[i] + ", ";
      jsonStr = jsonStr + mSamplesZ[i];
    }

    jsonStr = jsonStr + "], HR:"+mHR;
    jsonStr = jsonStr + ", O2sat:"+mO2sat;
    jsonStr = jsonStr + ", Mute:"+mMute;
    jsonStr = jsonStr + " }";
    return jsonStr;
  }


    // Return the current set of data as a JSON String
  function getSettingsJson() {
    var sysStats = System.getSystemStats();
    var deviceSettings = System.getDeviceSettings();
    var ciqVer = deviceSettings.monkeyVersion;
    var ciqVerStr = Lang.format("$1$.$2$.$3$", ciqVer);
    var jsonStr = "{ dataType: 'settings'";
    jsonStr = jsonStr + ", analysisPeriod: "+ANALYSIS_PERIOD;
    jsonStr = jsonStr + ", sampleFreq: "+SAMPLE_FREQUENCY;
    jsonStr = jsonStr + ", battery: "+sysStats.battery;
    jsonStr = jsonStr + ", watchPartNo: "+deviceSettings.partNumber;
    jsonStr = jsonStr + ", watchFwVersion: "+ciqVerStr;
    jsonStr = jsonStr + ", sdVersion: " + mVersionStr;
    jsonStr = jsonStr + ", sdName: GarminSD";
    jsonStr = jsonStr + "}";
    return jsonStr;
  }


  function muteTimerCallback() {
    System.println("muteTimerCallback()");
    mMute = 0;
  }

  function muteAlarms() {
    System.println("muteAlarms()");
    // If the timer is already running, stop it then re-start it.
    if (mMute == 1) {
      mMuteTimer.stop();
    }
    mMuteTimer = new Timer.Timer();
    mMuteTimer.start(method(:muteTimerCallback),MUTE_TIMER_PERIOD,false);
    mMute = 1;
  }

  
  // Prints acclerometer data that is recevied from the system
  function accel_callback(sensorData) {
    //System.println("accel_callback()");

    var iStart = nSamp*SAMPLE_PERIOD*SAMPLE_FREQUENCY;
    //System.println(Lang.format("iStart=$1$, ns=$2$, nSamp=$3$",[iStart,SAMPLE_PERIOD*SAMPLE_FREQUENCY,nSamp]));
    for (var i = 0; i<SAMPLE_PERIOD*SAMPLE_FREQUENCY; i=i+1) {
      mSamplesX[iStart+i] = sensorData.accelerometerData.x[i];
      mSamplesY[iStart+i] = sensorData.accelerometerData.y[i];
      mSamplesZ[iStart+i] = sensorData.accelerometerData.z[i];
    }
    nSamp = nSamp + 1;

    //Toybox.System.println("Raw samples, X axis: " + mSamplesX);
    //Toybox.System.println("Raw samples, Y axis: " + mSamplesY);
    //Toybox.System.println("Raw samples, Z axis: " + mSamplesZ);
    Ui.requestUpdate();
    
    if (nSamp*SAMPLE_PERIOD == ANALYSIS_PERIOD) {
      //System.println("Doing Analysis....");
      mComms.sendAccelData();
      //mHR = -1;
      nSamp = 0;
    }
  }

  function heartrate_callback(sensorInfo) {
    //System.println("HeartRate: " + sensorInfo.heartRate);
    //System.println("O2Sat: " + sensorInfo.oxygenSaturation);
    mHR = sensorInfo.heartRate;
    if (sensorInfo has :oxygenSaturation) {
      mO2sat = sensorInfo.oxygenSaturation;
    } else {
      mO2sat = 0;
    }
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
    // FIXME - does this drain the battery a lot?
    if (Sensor has :SENSOR_PULSE_OXYMETRY) {
      Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE,
				Sensor.SENSOR_PULSE_OXIMETRY]);
    } else {
      Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
    }

    Sensor.enableSensorEvents(method(:heartrate_callback));
  }
  

  function onStop() {
    System.println("DataHandler.onStop()");
    Sensor.unregisterSensorDataListener();
    Sensor.setEnabledSensors([]);
  }

}
