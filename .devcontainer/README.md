# This DevContainer is based on https://github.com/matco/connectiq-tester

The first time you open the project in the devcontainer it will install a lot of libraries
and download the garmin sdkmanager.   You then need to set up the Garmin SDK as follows:

  - Click on the Remote Explorer icon in the left hand side of vscode and will stop with a non-interactive terminal at the bottom of hte screen.
  - Press the '+' icon next to the terminal window and select 'new terminal'.  This should provide you with an interactive terminal in the devcontainer with a prompto of '/workspaces/Garmin_SD#'
  - type 'sdkmanager' - The Garmin SDK Manager should start.  
  - Accept the license agreement and log in with your garmin account.
  - press 'Next>' and tell it to automatically install updates and download new sdks, and automatically update the device library.  I deselect Bike Computers and Outdoor handelds because we are not interested in those for OSD.
  - Press 'Finish' - you will see a prompt that new devices are being downloaded.
  - Press 'OK'
  - A prompt that the latest SDK is being downloaded will appear - press ok, and then select 'Yes' to the prompt for setting that SDK to be your current SDK.
  - Select the 'Devices' tab and wait for it to finish downloading all the devieces (118 watches/wearables at the time of writing).

  in a terminal on your computer, type 'xhost +' to disable access restrictions, otherwise the simulator will not run.

  ...and now you should be able to open one of the .mc source files and press the 'run and debug' icon at the left hand side of the vscode screen, select a device and it should compile and run on the simulator for that device.


## Notes

  - There is probably a simpler way of doing this - the ConnectIQ Tester that I based this on downlaoded the SDK directly, but the MonkeyC vscode extension did not detect the SDK - it must be looking for a file created by SDK Manager.  If we work out what that is and create it ourselves we can probably bypass sdkmanager and get this working with vscode without all the interaction.



# ConnectIQ Tester README

ConnectIQ Tester is a Docker image that can be used to run the tests "Run No Evil" of a ConnectIQ application. The image contains the SDK, the device bits and the simulator.

The image currently contains ConnectIQ SDK version `7.3.0` and the device files retrieved on `2024-08-30`.

## Usage

The image requires to bind the code of your application to a folder in the container and to set the working directory of the container to the same folder.

The Docker command has 2 optional parameters:
* device_id: the id of one device supported by your application, as listed in your `manifest.xml` file, that will be used to run the tests. If you don't specify a device id, it will default to `fenix7`.
* certificate_path: the path of the certificate that will be used to compile the application relatively to the folder of your application. If you don't provide one, a temporary certificate will be generated automatically.


The simplest command is the following:
```
docker run -v /path/to/your/app:/app -w /app ghcr.io/matco/connectiq-tester:latest
```
The flag `-v` binds the folder containing your application to the `app` folder in the container. The flag `-w` tells the container to work in this repository (it is the working directory). It is required that the working directory matches the path where you bound your application in the container. With this command, a temporary certificate will be created, and the application will be tested using a Fenix 7.


If you want to specify a difference device, just run:
```
docker run -v /path/to/your/app:/app -w /app ghcr.io/matco/connectiq-tester:latest venu2
```
In this case, the application will be tested using a Venu 2.

To specify your own certificate, just run:
```
docker run -v /path/to/your/app:/app -w /app ghcr.io/matco/connectiq-tester:latest venu2 certificate/key.der
```
In this case, the application will be tested using a Venu 2 and the certificate used to compile the application will be `/path/to/your/app/certificate/key.der`.

## Copyright

All the resources contained in the archive `devices.zip` are the property of Garmin. These resources have been fetched from the Garmin website and have been included in this repository to facilitate the creation of the Docker image.
