Garmin_SD
=========

This is an OpenSeizureDetector data source that uses a Garmin IQ enabled
watch such as a Vivoactive HR.

The watch simply collects 5 seconds worth of acceleromater and heart rate data
and sends it to the phone.   The seizure detector processing is carried out
on the phone.

This is a proof-of-concept at the moment.   It shows that we can:

  1  Collect accelerometer data at a high enough frequency (>=25Hz).
  2  Send and receive messages to/from the phone
  3  Write something to the watch screen so you know it is working.

To get it to be a viable replacement for Pebble for OpenSeizureDetector we
need to:
  1  Check the battery consumption when sending data to the phone every 5 seconds - we need at least 12 hours battery life for it to be useful.
  2  Send real data to the phone (not just 'hello world' to prove we can send
  something!).
  3  The phone app needs to do the seizure detection calculation, and send
     the output to the OpenSeizureDetector alarm system.
  4  Work out how to publish the watch app.
  5  Test the reliability.

