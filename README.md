Garmin_SD
=========

This is an app that runs on a ConnectIQ V2 or higher Garmin Smart Watch,
such as a Vivoactive 3, Vivoactive 4/4s, Vivoactive HR or ForRunner 735xt.

The app collects accelerometer and heart rate data, and sends it to the 
[OpenSeizureDetector phone app](https://github.com/OpenSeizureDetector/Android_Pebble_SD) that runs on a connected Android Phone.

The watch collects 5 seconds worth of acceleromater and heart rate data
and sends it to the phone.   The seizure detector processing is carried out
on the phone using the web server built into the OpenSeizureDetector Android 
App.  The proprietary [Garmin Connect App](https://play.google.com/store/apps/details?id=com.garmin.android.apps.connectmobile&hl=en_GB) is used to provide the link between the watch and the OpenSeizureDetector phone app.

The watch displays either the results of the seizure analysis (OK, ALARM etc.) or an [error code](https://developer.garmin.com/connect-iq/api-docs/Toybox/Communications.html) that is generated from the garmin software.

If the user is doing an activity that is likely to result in a false alarm he/she can press one of the watch buttons or screen to mute the system for 5 minutes to avoid a false alarm.

# Build Instructions
Clone this repository.
Change to the watch app directory.
execute ./mb_runner.sh build   (requires the Garmin SDK to be installed).

It should generate a GarminSD.pkg file.


# Installation Instructions
Copy GarminSD.pkg into the folder GARMIN/APS on the watch.   GarminSD should appear as an app on the watch (like Running, Bike etc.).

# Contact
Email graham@openseizuredetector.org.uk 


   
   

