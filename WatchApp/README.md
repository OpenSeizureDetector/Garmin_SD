Garmin_SD
=========

Development version of a seizure detector that will run on a Garmin Vivoactive HR smartwatch.

Useful info on command line complation is here: [https://developer.garmin.com/connect-iq/connect-iq-faq/how-do-i-integrate-connect-iq-and-travis-ci/](https://developer.garmin.com/connect-iq/connect-iq-faq/how-do-i-integrate-connect-iq-and-travis-ci/)

Compile with
./mb_runner.sh build

Package with
./mb_runner.sh package

Test on device by:
- Connect device using USB
- Copy GarminSD.pkg to GARMIN/APPS folder on device
- disconnect USB
(https://forums.garmin.com/forum/developers/connect-iq/96579-)

App should appear in Apps list on device.

To enable debug logging create a file GARMIN/APPS/GarminSD.TXT
Anything written using println will appear in the file.
