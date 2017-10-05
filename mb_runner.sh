#!/bin/bash

# This is just a little helper-script to enable ConnectIQ-development on
# UNIX-systems.
#
# Based on the (Windows) ConnectIQ SDK 2.2.5
#
# The following tasks can be invoked:
#   * compiling (re)sources and building a PRG-file for testing
#   * run unit-tests (requires a running simulator)
#   * creating a signed IQ-file package for publishing
#   * cleaning up previously built files
#   * starting the ConnectIQ-simulator (using wine)
#   * pushing the generated PRG-file to the running simulator
#
# This script requires the following tools/packages:
#   * wine
#   * dos2unix
#   (sudo apt-get install wine dos2unix)
#
# Usage:
#   mb_runner.sh {build|test|package|clean|simulator|push} [full-path-to-ciq-project-root] [relative-resources-folder-path] [relative-source-folder-path]
#
# Example (using default-values):
#   mb_runner.sh package
#
# Example (using custom paths/folders):
#   mb_runner.sh package /home/achim/projects/HueCIQ resources source

# **********
# env checks
# **********

if [[ ! ${MB_HOME} ]]; then
    echo "MB_HOME not set!"
    exit 1
fi

if [[ ! ${MB_PRIVATE_KEY} ]]; then
    echo "MB_PRIVATE_KEY not set!"
    exit 1
fi

# ***********
# param check
# ***********

case "${1}" in
   build)
      ;;
   test)
      ;;
   package)
      ;;
   clean)
      ;;
   simulator)
      ;;
   push)
      ;;
   *)
      echo "Usage: `basename ${0}` {build|test|package|clean|simulator|push} [full-path-to-ciq-project-root] [relative-resources-folder-path] [relative-source-folder-path]"
      exit 1
      ;;
esac

if [ ! -n ${2} ]; then
   PROJECT_HOME="${2}"
else
   PROJECT_HOME="${PWD}"
fi

if [ ! -n ${3} ]; then
   RESOURCES_FOLDER="${3}"
else
   RESOURCES_FOLDER="resources"
fi

if [ ! -n ${4} ]; then
   SOURCE_FOLDER="${4}"
else
   SOURCE_FOLDER="source"
fi

# **************
# other settings
# **************

# config-file ...

CONFIG_FILE="${PROJECT_HOME}/mb_runner.cfg"

if [ ! -e "${CONFIG_FILE}" ] ; then
    echo "Config file \"${CONFIG_FILE}\" not found!"
    exit 1
else
    source "${CONFIG_FILE}"
fi

# *************
# project stuff
# *************

# manifest ...

MANIFEST_FILE="${PROJECT_HOME}/manifest.xml"

if [ ! -e "${MANIFEST_FILE}" ] ; then
    echo "Manifest file \"${MANIFEST_FILE}\" not found!"
    exit 1
fi

# (re)sources ...

RESOURCES="`cd /; find \"${PROJECT_HOME}/${RESOURCES_FOLDER}\"* -iname '*.xml' | tr '\n' ':'`"
SOURCES="`cd /; find \"${PROJECT_HOME}/${SOURCE_FOLDER}\" -iname '*.mc' | tr '\n' ' '`"

# sdk-specific ...

API_DB="${MB_HOME}/bin/api.db"
PROJECT_INFO="${MB_HOME}/bin/projectInfo.xml"
API_DEBUG="${MB_HOME}/bin/api.debug.xml"
DEVICES="${MB_HOME}/bin/devices.xml"

# **********
# processing
# **********

# prepare sdk executables and apply "wine-ification", if not already done so ...

if [ ! -e "${MB_HOME}/bin/monkeydo.bak" ] ; then
    cp -a "${MB_HOME}/bin/monkeydo" "${MB_HOME}/bin/monkeydo.bak"
    dos2unix "${MB_HOME}/bin/monkeydo"
    chmod +x "${MB_HOME}/bin/monkeydo"
    sed -i -e 's/"\$MB_HOME"\/shell/wine "\$MB_HOME"\/shell.exe/g' "${MB_HOME}/bin/monkeydo"
fi

if [ ! -e "${MB_HOME}/bin/monkeyc.bak" ] ; then
    cp -a "${MB_HOME}/bin/monkeyc" "${MB_HOME}/bin/monkeyc.bak"
    chmod +x "${MB_HOME}/bin/monkeyc"
    dos2unix "${MB_HOME}/bin/monkeyc"
fi

# possible parameters ...

#PARAMS+="--apidb \"${API_DB}\" "
#PARAMS+="--buildapi "
#PARAMS+="--configs-dir <arg> "
#PARAMS+="--device \"${TARGET_DEVICE}\" "
#PARAMS+="--package-app "
#PARAMS+="--debug "
#PARAMS+="--excludes-map-file <arg> "
#PARAMS+="--import-dbg \"${API_DEBUG}\" "
#PARAMS+="--write-db "
#PARAMS+="--manifest \"${MANIFEST_FILE}\" "
#PARAMS+="--api-version <arg> "
#PARAMS+="--output \"${APP_NAME}.prg\" "
#PARAMS+="--project-info \"${PROJECT_INFO}\" "
#PARAMS+="--release "
#PARAMS+="--sdk-version \"${TARGET_SDK_VERSION}\" "
#PARAMS+="--unit-test "
#PARAMS+="--devices \"${DEVICES}\" "
#PARAMS+="--version "
#PARAMS+="--warn "
#PARAMS+="--excludes <arg> "
#PARAMS+="--private-key \"${MB_PRIVATE_KEY}\" "
#PARAMS+="--rez \"${RESOURCES}\" "

function concat_params_for_build
{
    PARAMS+="--apidb \"${API_DB}\" "
    PARAMS+="--device \"${TARGET_DEVICE}\" "
    PARAMS+="--import-dbg \"${API_DEBUG}\" "
    PARAMS+="--manifest \"${MANIFEST_FILE}\" "
    PARAMS+="--output \"${APP_NAME}.prg\" "
    PARAMS+="--project-info \"${PROJECT_INFO}\" "
    PARAMS+="--sdk-version \"${TARGET_SDK_VERSION}\" "
    PARAMS+="--unit-test "
    PARAMS+="--devices \"${DEVICES}\" "
    PARAMS+="--warn "
    PARAMS+="--private-key \"${MB_PRIVATE_KEY}\" "
    PARAMS+="--rez \"${RESOURCES}\" "
}

function concat_params_for_package
{
    PARAMS+="--package-app "
    PARAMS+="--manifest \"${MANIFEST_FILE}\" "
    PARAMS+="--output \"${APP_NAME}.iq\" "
    PARAMS+="--release "
    PARAMS+="--warn "
    PARAMS+="--private-key \"${MB_PRIVATE_KEY}\" "
    PARAMS+="--rez \"${RESOURCES}\" "
}

function run_mb_jar
{
    java -jar "${MB_HOME}/bin/monkeybrains.jar" ${PARAMS} ${SOURCES}
}

function run_tests
{
    "${MB_HOME}/bin/monkeydo" "${PROJECT_HOME}/${APP_NAME}.prg" -t
}

function clean
{
    cd ${PROJECT_HOME}

    rm -f "${PROJECT_HOME}/${APP_NAME}"*.prg*
    rm -f "${PROJECT_HOME}/${APP_NAME}"*.iq
    rm -f "${PROJECT_HOME}/${APP_NAME}"*.json
    rm -f "${PROJECT_HOME}/sys.nfm"
}

function start_simulator
{
    SIM_PID=$(ps aux | grep simulator.exe | grep -v "grep" | awk '{print $2}')

    if [[ ${SIM_PID} ]]; then
        kill ${SIM_PID}
    fi

    wine "${MB_HOME}/bin/simulator.exe" &
}

function push_prg
{
    if [ -e "${PROJECT_HOME}/${APP_NAME}.prg" ] ; then
        "${MB_HOME}/bin/monkeydo" "${PROJECT_HOME}/${APP_NAME}.prg" "${TARGET_DEVICE}"
    fi
}

###

cd ${PROJECT_HOME}

case "${1}" in
   build)
        concat_params_for_build
        run_mb_jar
        ;;
   test)
        concat_params_for_build
        run_mb_jar
        run_tests
        ;;
   package)
        concat_params_for_package
        run_mb_jar
        ;;
   clean)
        clean
        ;;
   simulator)
        start_simulator
        ;;
   push)
        push_prg
        ;;
esac
