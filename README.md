Garmin_SD
=========

This is an OpenSeizureDetector data source that uses a Garmin IQ enabled
watch such as a Vivoactive HR - it needs a ConnectIQ SDK Level 2 or higher
device - it has been tested on a VivoActive HR and a ForeRunner 735xt.

The watch app is relatively simple, as processing is now carried out on the
phone.
The watch collects 5 seconds worth of acceleromater and heart rate data
and sends it to the phone.   The seizure detector processing is carried out
on the phone using the web server built into the OpenSeizureDetector Android 
App.

The testing that has been carried out so far suggests that seizure detection
reliability is comparable to the Pebble, and the connection reliability
between the watch and the phone is good.   Battery life is also better than
the pebble - about 24 hours.

There are a few features of the Pebble Watch app that are missing from
this Garmin one:
 * The results of the analysis (OK, ALARM etc)  are not displayed on the watch
 * The 'mute' and 'manual alarm' functions are not present.
 * The display on the screen is a bit messy because it was used to display
   debugging information during testing.
   
   

