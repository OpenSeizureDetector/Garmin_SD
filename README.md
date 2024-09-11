Garmin_SD
=========

This is an app that runs on a ConnectIQ V2 or higher Garmin Smart Watch,
such as a VenuSQ, Vivoactive 3, Vivoactive 4/4s, Vivoactive HR or ForeRunner 735xt.

The app collects accelerometer, heart rate and O2 saturation data (if available on the watch), and sends it to the 
[OpenSeizureDetector phone app](https://github.com/OpenSeizureDetector/Android_Pebble_SD) that runs on a connected Android Phone.

The basic operation is:
  * The watch collects 5 seconds worth of acceleromater, heart rate and O2 saturation data
  * It converts the data to a JSON string, which is sent to the web server which is part of the [OpenSeizureDetector phone app](https://github.com/OpenSeizureDetector/Android_Pebble_SD). 
  * Although it appears on the watch that this is a http POST request, in reality bluetooth (BLE) is used to send the data to the The proprietary [Garmin Connect App](https://play.google.com/store/apps/details?id=com.garmin.android.apps.connectmobile&hl=en_GB), which in turn sents the http request - so the Garmin Connect app is essential for operation of this watch app.
  * The seizure detection analysis is carried out on the phone using the [OpenSeizureDetector phone app](https://github.com/OpenSeizureDetector/Android_Pebble_SD).
  * The OpenSeizureDetector Phone App web server sends a response, which includes the alarm status (OK, WARNING, ALARM)
  * If the http request completes successfully, the received response is displayed on the phone screen, if not the garmin [error code](https://developer.garmin.com/connect-iq/api-docs/Toybox/Communications.html) is displayed.
and sends it to the phone.

If the user is doing an activity that is likely to result in a false alarm he/she can press one of the watch buttons or screen to mute the system for 5 minutes to avoid a false alarm.

# Build Environment
  * Install the latest stable release of the Garmin ConnectIQ Software Developmetn Kit (SDK) from (https://developer.garmin.com/connect-iq/sdk/).  This installs the Garmin SDK Manager.
  * Use the SDK manager to install the latest stable SDK.   **SDK version 6.4.2 or higher is required** to avoid type checking errors.
  * Use the SDK manager to install some watch emulators (in particular the VenuSQ which is the current 'reference' device).

# Build Instructions (command line)
Note, this used to be easy until Garmin introduced the SDK manager - now you need to find out where Garmin SDK Manager has installed your SDK as you do it yourself.
  * Clone this repository.
  * Change to the watch app directory.
  * Set the MB_HOME environment variable to point to the SDK (see (https://developer.garmin.com/connect-iq/connect-iq-faq/how-do-i-integrate-connect-iq-and-travis-ci/)) for more information.
  * Set the MB_PRIVATE_KEY environment variable to point to your developer key.
  * Copy the template file to the same location, but remove the extension. They will be your own configuration.
  * You might want to edit mb_runner.cfg to set the TARGET_DEVICE and TARGET_SDK_VERSION to match your device (like maybe venusq and current SDK version)
  * You might want to use Garmin SDK Manager to install device definitions (or remove products from manifest.xml)
  * execute ./mb_runner.sh build   (requires the Garmin SDK to be installed).
  * It should generate a GarminSD.prg file.

# Build Instructions (Visual Studio Code)
  * Clone this repository
  * Install [Visual Studio Code](https://code.visualstudio.com/), and start it, opening the WatchApp folder of this repository
  * Install the Monkey C extension from within vscode.
  * Set up the Monkey C extension to use the installed SDK.
  * In the Monkey C extension settings, set Monkey C: Type Check Level to 'INFORMATIVE' ('Srict' typechecking results in an error).)
  * Press the Run and Debug (triangle) icon on the left hand side of the screen).   This opens an extra panel with a Run (triangle) icon at the top of the screen.
  * Select Run (Triange Icon)
  * A popup window should appear showing your installed watches - select one of them (e.g. VenuSQ).
  * Check the terminal output - sometimes if the manifest.xml contains a watch which you do not have installed it will fail with an error.
  * If it works, the watch emulator should shart, showing the app running.
  * It will also have produced a GarminSD.prg file.
  


# Installation Instructions
  * Copy GarminSD.prg into the folder GARMIN/APS on the watch.   
  * GarminSD should appear as an app on the watch (like Running, Bike etc.).
  * To be able to see the debug output, create an empty file GARMIN/APPS/LOGS/GarminSD.Log - this file will be populated when the app runs.

# Contact
Email graham@openseizuredetector.org.uk 


   
   

