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
using Toybox.Timer;
import Toybox.Application.Storage;
import Toybox.Lang;


class GarminSDDataHandler {
  const ANALYSIS_PERIOD as Number = 5;
  const SAMPLE_PERIOD as Number = 1;
  const SAMPLE_FREQUENCY as Number = 25;
  const MUTE_TIMER_PERIOD as Number = 5 * 60 * 1000; // 5 min in ms
  //const MUTE_TIMER_PERIOD = 20 * 1000;   // 20 sec in ms

  var mSamplesX as Array<Float or Number> = new Array<Float or Number>[ANALYSIS_PERIOD * SAMPLE_FREQUENCY];
  var mSamplesY as Array<Float or Number>  = new Array<Float or Number>[ANALYSIS_PERIOD * SAMPLE_FREQUENCY];
  var mSamplesZ as Array<Float or Number>  = new Array<Float or Number>[ANALYSIS_PERIOD * SAMPLE_FREQUENCY];

  var nSamp as Number = 0;
  var mHR as Number or Null = 0;
  var mO2sat as Number or Null = 0;
  var mMute as Boolean = false;
  var mMuteTimer as Toybox.Timer.Timer or Null;
  var mStatusStr as String = "---";
  var mComms as GarminSDComms;
  var mVersionStr as String = "";
  var mO2SensorIsEnabled as Boolean = true;

  ///////////////
  // Constructor
  function initialize(versionStr as String) {
    var tagStr = "DataHandler.initialize()";
    writeLog(tagStr, "");
    mO2SensorIsEnabled = Storage.getValue(MENUITEM_O2SENSOR) ? true : false;
    mVersionStr = versionStr;
    // On Start-up we show the app version number in place of satus.
    mStatusStr = versionStr;
    mComms = new GarminSDComms(self);
    mComms.onStart();
  }

  // Return the current set of data as a JSON String
  function getDataJson() as String {
    var i;
    var jsonStr = "{dataType:'raw',";

    jsonStr = jsonStr + "data3D:[";
    for (i = 0; i < ANALYSIS_PERIOD * SAMPLE_FREQUENCY; i = i + 1) {
        if (i > 0) {
          jsonStr = jsonStr +",";
        }
        jsonStr = jsonStr + mSamplesX[i] + ",";
        jsonStr = jsonStr + mSamplesY[i] + ",";
        jsonStr = jsonStr + mSamplesZ[i];
    }
    jsonStr = jsonStr +"],";

    jsonStr = jsonStr + "HR:" + mHR;
    jsonStr = jsonStr + ",O2sat:" + mO2sat;
    jsonStr = jsonStr + ",Mute:" + mMute.toString();
    jsonStr = jsonStr + "}";
    return jsonStr as String;
  }

  // Return the current set of data as a JSON String
  function getSettingsJson() as String {
    var sysStats = System.getSystemStats();
    var deviceSettings = System.getDeviceSettings();
    var ciqVer = deviceSettings.monkeyVersion;
    var ciqVerStr = format("$1$.$2$.$3$", ciqVer);
    var jsonStr = "{ dataType: 'settings'";
    jsonStr = jsonStr + ", analysisPeriod: " + ANALYSIS_PERIOD.toString();
    jsonStr = jsonStr + ", sampleFreq: " + SAMPLE_FREQUENCY.toString();
    jsonStr = jsonStr + ", battery: " + sysStats.battery.toString();
    jsonStr = jsonStr + ", watchPartNo: " + deviceSettings.partNumber.toString();
    jsonStr = jsonStr + ", watchFwVersion: " + ciqVerStr;
    jsonStr = jsonStr + ", sdVersion: " + mVersionStr;
    jsonStr = jsonStr + ", sdName: GarminSD";
    jsonStr = jsonStr + "}";
    return jsonStr as String;
  }

  function muteTimerCallback() as Void {
    writeLog("muteTimerCallback()", "");
    mMute = false;
  }

  function muteAlarms() as Void{
    writeLog("muteAlarms()","");
    // If the timer is already running, stop it then re-start it.
    if (mMute == true) {
      (mMuteTimer as Timer.Timer).stop();
    }
    mMuteTimer = new Timer.Timer();
    mMuteTimer.start(method(:muteTimerCallback), MUTE_TIMER_PERIOD, false);
    mMute = true;
  }

  // Prints acclerometer data that is recevied from the system
  function accel_callback(sensorData as Toybox.Sensor.SensorData) as Void {
    //var tagStr = "DataHandler.accel_callback()";
    //System.println("accel_callback()");

    var iStart = nSamp * SAMPLE_PERIOD * SAMPLE_FREQUENCY;
    //System.println(format("iStart=$1$, ns=$2$, nSamp=$3$",[iStart,SAMPLE_PERIOD*SAMPLE_FREQUENCY,nSamp]));
    var accelData = sensorData.accelerometerData;
    for (var i = 0; i < SAMPLE_PERIOD * SAMPLE_FREQUENCY; i = i + 1) {
      mSamplesX[iStart + i] = (accelData as Sensor.AccelerometerData).x[i];
      mSamplesY[iStart + i] = (accelData as Sensor.AccelerometerData).y[i];
      mSamplesZ[iStart + i] = (accelData as Sensor.AccelerometerData).z[i];
    }
    nSamp = nSamp + 1;

    // It should never be above analysis period, but in case it happens, greater would prevent infinite loop.
    if (nSamp * SAMPLE_PERIOD >= ANALYSIS_PERIOD) {
      //System.println("Doing Analysis....");
      mHR = Sensor.getInfo().heartRate;
      if ((Sensor.getInfo() has :oxygenSaturation) && (mO2SensorIsEnabled == true)) {
        //writeLog(tagStr,"reading o2sat value ");
        mO2sat = Sensor.getInfo().oxygenSaturation;
      } else {
        //writeLog(tagStr,"setting mO2sat to zero");
        mO2sat = 0;
      }
      nSamp = 0;
      //writeLog("DataHandler.accelCallback()","Sending accel Data");
      mComms.sendAccelData();
    }
  }


  // Initializes the view and registers for accelerometer data
  function onStart() as Void {
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
    var sensors = new Array<Sensor.SensorType>[2];
    sensors.add(Sensor.SENSOR_HEARTRATE);
    if ((Sensor has :SENSOR_PULSE_OXYMETRY) && (mO2SensorIsEnabled == true)) {
      writeLog(tagStr,"Enabling HR and O2SAT Sensors");
      sensors.add(Sensor.SENSOR_PULSE_OXIMETRY);
    }
    Sensor.setEnabledSensors(sensors);
  }
  function onTick() as Void {
    /**
    Called by GarminSDView every second in case we need to do anything timed.
    */
    //writeLog("GarminSDView.onTick()", "Start");
    mComms.onTick();
  }
  function onStop() as Void {
    writeLog("DataHandler.onStop()", "");
    Sensor.unregisterSensorDataListener();
    var sensors = new Array<Sensor.SensorType>[0];
    Sensor.setEnabledSensors(sensors);
    // this is NOT in the CIQ api and is a Garmin bug.
    // https://forums.garmin.com/developer/connect-iq/f/discussion/872/battery-drain-when-connectiq-app-is-not-running/1661071#1661071
    Sensor.enableSensorEvents(null);
  }
}
