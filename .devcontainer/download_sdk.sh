#!/bin/bash

#retrieve parameters
PATH=$1

#check parameters
if [[ -z $PATH ]]
then
	echo "Usage: path"
	exit 1
fi


/usr/bin/wget -q "https://developer.garmin.com/downloads/connect-iq/sdk-manager/connectiq-sdk-manager-linux.zip" -O /tmp/sdkmanager.zip
/usr/bin/unzip /tmp/sdkmanager.zip -d "${PATH}"

