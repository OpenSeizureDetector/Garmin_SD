#!/bin/bash

#retrieve parameters
PATH=$1
VERSION=$2

#check parameters
if [[ -z $PATH ]]
then
	echo "Usage: path [version]"
	exit 1
fi

CONNECTIQ_SDK_URL="https://developer.garmin.com/downloads/connect-iq/sdks"
CONNECTIQ_SDK_INFO_URL="${CONNECTIQ_SDK_URL}/sdks.json"

#retrieve latest version if no version is specified
if [[ -z $VERSION ]]
then
	VERSION=$(/usr/bin/curl -s "${CONNECTIQ_SDK_INFO_URL}" | /usr/bin/jq -r '.[].version' | /usr/bin/sort | /usr/bin/tail -1)
	echo "Using the latest version ($VERSION)"
fi

#retrieve SDK file name from the version
filename=$(/usr/bin/curl -s "${CONNECTIQ_SDK_INFO_URL}" | /usr/bin/jq -r --arg version "$VERSION" '.[] | select(.version==$version) | .linux')
url="${CONNECTIQ_SDK_URL}/${filename}"
echo "Downloading from $url"

/usr/bin/wget -q "${url}" -O /tmp/connectiq.zip;
/usr/bin/unzip /tmp/connectiq.zip -d "${PATH}"

/usr/bin/wget -q "https://developer.garmin.com/downloads/connect-iq/sdk-manager/connectiq-sdk-manager-linux.zip" -O /tmp/sdkmanager.zip
/usr/bin/unzip /tmp/sdkmanager.zip -d "${PATH}"

echo "$VERSION"
