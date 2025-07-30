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

SDK_PATH="${PATH}/Sdks/${filename}"
/usr/bin/mkdir -p ${SDK_PATH}
/usr/bin/unzip /tmp/connectiq.zip -d ${SDK_PATH} 

# Create the current-sdk.cfg file to trick vscode into thinking that we have used sdkmanager to download the sdk so it picks it up.
CURR_SDK_CFG_FNAME="${PATH}/current-sdk.cfg"
echo "Creating sdk configuration file: ${CURR_SDK_CFG_FNAME}"
if [[ -e ${CURR_SDK_CFG_FNAME} ]]
then
	rm ${CURR_SDK_CFG_FNAME}
fi
echo "${SDK_PATH}" > ${CURR_SDK_CFG_FNAME}

echo "Set current sdk to "`/usr/bin/cat ${CURR_SDK_CFG_FNAME}`

