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
  * copy monkey.jungle.template to monkey.jungle
  * copy manifest.xml.template to manifest.xml
  * Create a developer key if necessary by typing CTRL-SHIFT-P in VS Code and typing "generate a developer key"
  * In the Monkey C extension settings, set Monkey C: Type Check Level to 'INFORMATIVE' ('Strict' typechecking results in an error).)
  * Press the Run and Debug (triangle) icon on the left hand side of the screen).   This opens an extra panel with a Run (triangle) icon at the top of the screen.
  * Select Run (Triange Icon)
  * A popup window should appear showing your installed watches - select one of them (e.g. VenuSQ).
  * Check the terminal output - sometimes if the manifest.xml contains a watch which you do not have installed it will fail with an error.
  * If it works, the watch emulator should shart, showing the app running.
  * It will also have produced a GarminSD.prg file.

# VS Code Devcontainer Quick Start (recommended)

Use this workflow if you want a reproducible Linux build + emulator environment directly in VS Code.

## 1) Open in Dev Container
  * Open this repository in VS Code.
  * Run: `Dev Containers: Reopen in Container`.
  * Wait for post-create setup to finish (it runs `.devcontainer/install_garmin.sh`).
  * When you see `Done. Press any key to close the terminal`, close that terminal.
  * Open a fresh container terminal: `Terminal -> New Terminal`.

## 2) Install SDK and emulator devices with Garmin SDK Manager
  * Start the SDK manager from the container terminal:
    * `~/sdkmanager/sdkmanager`
  * In SDK Manager, install:
    * a Connect IQ SDK version (6.4.2+ recommended)
    * at least one emulator device profile (for example VenuSQ)

## 3) Configure project files and signing key
  * Create working config files from templates:
    * `cp monkey.jungle.template monkey.jungle`
    * `cp manifest.xml.template manifest.xml`
    * `cp mb_runner.cfg.template mb_runner.cfg`
  * Generate a developer key (if you do not already have one):
    * Open Command Palette and run `Monkey C: Generate a Developer Key`.
  * Set `MB_PRIVATE_KEY` to your key file path in the terminal session, for example:
    * `export MB_PRIVATE_KEY="$HOME/.Garmin/ConnectIQ/developer_key.der"`

## 4) Set MB_HOME to your installed SDK
The build helper script needs `MB_HOME` to point to one SDK install folder (the folder that contains `bin/monkeyc`).

Example helper command to set `MB_HOME` to the newest installed SDK:

```bash
export MB_HOME="$(find "$HOME/.Garmin/ConnectIQ/Sdks" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -n 1)"
echo "MB_HOME=$MB_HOME"
test -x "$MB_HOME/bin/monkeyc" && echo "monkeyc found"
```

## 5) Build from terminal
  * Build app PRG:
    * `./mb_runner.sh build`
  * Output file:
    * `GarminSD.prg` in the repository root.

## 6) Build and run in emulator from VS Code
This repository already includes a VS Code launch config (`.vscode/launch.json`).

  * Open `Run and Debug` in VS Code.
  * Select `Run App`.
  * Press Start (triangle).
  * Choose your emulator device when prompted.
  * VS Code will compile and launch in the Garmin emulator.

## 7) Run tests in emulator from VS Code
  * In `Run and Debug`, select `Run Tests`.
  * Press Start and choose a device.

## Troubleshooting
  * `MB_HOME not set!`:
    * Export `MB_HOME` as shown above.
  * `MB_PRIVATE_KEY not set!`:
    * Export `MB_PRIVATE_KEY` to your developer key file.
  * SDK manager exists but fails to launch with shared library errors:
    * Re-run `.devcontainer/install_garmin.sh` or rebuild container so required libs are installed.
  * Terminal closed after container setup:
    * This is normal for post-create tasks. Open a new terminal via `Terminal -> New Terminal`.
  


# Installation Instructions
  * Copy GarminSD.prg into the folder GARMIN/APS on the watch.   
  * GarminSD should appear as an app on the watch (like Running, Bike etc.).
  * To be able to see the debug output, create an empty file GARMIN/APPS/LOGS/GarminSD.Log - this file will be populated when the app runs.

# Contact
Email graham@openseizuredetector.org.uk 


   
   

