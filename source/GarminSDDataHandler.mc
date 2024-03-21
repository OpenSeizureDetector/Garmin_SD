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
import Toybox.Application.Storage;


class GarminSDDataHandler {
  const ANALYSIS_PERIOD = 5;
  const SAMPLE_PERIOD = 1;
  const SAMPLE_FREQUENCY = 25;
  const MUTE_TIMER_PERIOD = 5 * 60 * 1000; // 5 min in ms
  //const MUTE_TIMER_PERIOD = 20 * 1000;   // 20 sec in ms

  var mSamplesX = new [ANALYSIS_PERIOD * SAMPLE_FREQUENCY];
  var mSamplesY = new [ANALYSIS_PERIOD * SAMPLE_FREQUENCY];
  var mSamplesZ = new [ANALYSIS_PERIOD * SAMPLE_FREQUENCY];

  var nSamp = 0;
  var mHR = 0;
  var mO2sat = 0;
  var mMute = 0;
  var mMuteTimer;
  var mStatusStr = "---";
  var mComms = null;
  var mVersionStr = "";
  var mO2SensorIsEnabled = true;

  ///////////////
  // Constructor
  function initialize(versionStr) {
    var tagStr = "DataHandler.initialize()";
    writeLog(tagStr, "");
    mVersionStr = versionStr;
    // On Start-up we show the app version number in place of satus.
    mStatusStr = versionStr;
    mComms = new GarminSDComms(self);
    mComms.onStart();
  }

  // Return the current set of data as a JSON String
  function getDataJson() {
    var i;
    var lowDataMode = Storage.getValue(MENUITEM_LOWDATAMODE) ? true : false;

    var jsonStr = "{ dataType: 'raw', ";

    jsonStr = jsonStr + " data3D: [";
    for (i = 0; i < ANALYSIS_PERIOD * SAMPLE_FREQUENCY; i = i + 1) {
        if (i > 0) {
          jsonStr = jsonStr + ", ";
        }
        jsonStr = jsonStr + mSamplesX[i] + ", ";
        jsonStr = jsonStr + mSamplesY[i] + ", ";
        jsonStr = jsonStr + mSamplesZ[i];
    }
    jsonStr = jsonStr + "],";

    jsonStr = jsonStr + " HR:" + mHR;
    jsonStr = jsonStr + ", O2sat:" + mO2sat;
    jsonStr = jsonStr + ", Mute:" + mMute;
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
    jsonStr = jsonStr + ", analysisPeriod: " + ANALYSIS_PERIOD;
    jsonStr = jsonStr + ", sampleFreq: " + SAMPLE_FREQUENCY;
    jsonStr = jsonStr + ", battery: " + sysStats.battery;
    jsonStr = jsonStr + ", watchPartNo: " + deviceSettings.partNumber;
    jsonStr = jsonStr + ", watchFwVersion: " + ciqVerStr;
    jsonStr = jsonStr + ", sdVersion: " + mVersionStr;
    jsonStr = jsonStr + ", sdName: GarminSD";
    jsonStr = jsonStr + "}";
    return jsonStr;
  }

  function muteTimerCallback() {
    writeLog("muteTimerCallback()", "");
    mMute = 0;
  }

  function muteAlarms() {
    writeLog("muteAlarms()","");
    // If the timer is already running, stop it then re-start it.
    if (mMute == 1) {
      mMuteTimer.stop();
    }
    mMuteTimer = new Timer.Timer();
    mMuteTimer.start(method(:muteTimerCallback), MUTE_TIMER_PERIOD, false);
    mMute = 1;
  }

  // Prints acclerometer data that is recevied from the system
  function accel_callback(sensorData as Toybox.Sensor.AccelerometerData) {
    //var tagStr = "DataHandler.accel_callback()";
    //System.println("accel_callback()");

    var iStart = nSamp * SAMPLE_PERIOD * SAMPLE_FREQUENCY;
    //System.println(Lang.format("iStart=$1$, ns=$2$, nSamp=$3$",[iStart,SAMPLE_PERIOD*SAMPLE_FREQUENCY,nSamp]));
    for (var i = 0; i < SAMPLE_PERIOD * SAMPLE_FREQUENCY; i = i + 1) {
      mSamplesX[iStart + i] = sensorData.accelerometerData.x[i];
      mSamplesY[iStart + i] = sensorData.accelerometerData.y[i];
      mSamplesZ[iStart + i] = sensorData.accelerometerData.z[i];
    }
    nSamp = nSamp + 1;

    //Toybox.System.println("Raw samples, X axis: " + mSamplesX);
    //Toybox.System.println("Raw samples, Y axis: " + mSamplesY);
    //Toybox.System.println("Raw samples, Z axis: " + mSamplesZ);

    if (nSamp * SAMPLE_PERIOD == ANALYSIS_PERIOD) {
      //System.println("Doing Analysis....");
      // Force reading of current heart rate and o2sat values in case the heart rate
      // freezing issue
      mHR = Sensor.getInfo().heartRate;
      if ((Sensor.getInfo() has :oxygenSaturation) && (mO2SensorIsEnabled == true)) {
        //writeLog(tagStr,"reading o2sat value ");
        mO2sat = Sensor.getInfo().oxygenSaturation;
      } else {
        //writeLog(tagStr,"setting mO2sat to zero");
        mO2sat = 0;
      }
      nSamp = 0;
      //System.println("DataHandler - sending Accel Data");
      //writeLog("DataHandler.accelCallback()","Sending accel Data");
      mComms.sendAccelData();
    }
    Ui.requestUpdate();
  }


  // Initializes the view and registers for accelerometer data
  function onStart() {
    mO2SensorIsEnabled = Storage.getValue(MENUITEM_O2SENSOR) ? true : false;
    var tagStr = "DataHandler.onStart()";
    var maxSampleRate = Sensor.getMaxSampleRate();
    writeLog(tagStr, "maxSampleRate = "+maxSampleRate);

    // initialize accelerometer to request the maximum amount of
    // data possible
    var options = {
        :period => SAMPLE_PERIOD,
        :accelerometer => {
            :enabled => true,
            :sampleRate => SAMPLE_FREQUENCY
        }
    };
    try {
      Sensor.registerSensorDataListener(method(:accel_callback), options);
      writeLog(tagStr, "Registered for Accelerometer Data");
    } catch (e) {
      writeLog("*** ERROR - "+ tagStr, e.getErrorMessage());
    }

    // Intialise heart rate monitoring.
    // But only initialise O2sat sensor if enabled in settings (default is true)
    writeLog(tagStr,"mO2SensorIsEnabled = " + mO2SensorIsEnabled);
    if ((Sensor has :SENSOR_PULSE_OXYMETRY) && (mO2SensorIsEnabled == true)) {
      writeLog(tagStr,"Enabling HR and O2SAT Sensors");
      Sensor.setEnabledSensors([
        Sensor.SENSOR_HEARTRATE,
        Sensor.SENSOR_PULSE_OXIMETRY,
      ]);
    } else {
      writeLog(tagStr,"Enabling HR Sensor only");
      Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
    }
  }

  function onTick() {
    /**
    Called by GarminSDView every second in case we need to do anything timed.
    */
    //System.println("GarminSDDataHandler.onTick()");

    mComms.onTick();
  }

  function onStop() {
    writeLog("DataHandler.onStop()", "");
    Sensor.unregisterSensorDataListener();
    Sensor.setEnabledSensors([]);
  }
}
