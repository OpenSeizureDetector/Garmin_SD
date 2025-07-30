# DevContainer README

## This DevContainer is based on https://github.com/matco/connectiq-tester

The first time you open the project in the devcontainer it will install a lot of libraries, download the garmin sdkmanager and install a default SDK and set of watch simulators.   

In a terminal on your computer, type 'xhost +' to disable access restrictions, otherwise the simulator will not run.

You will need to configure the MonkeyC vscode extension to tell it which .der certificate file to use to sign the compiled code.
You should then be able to open one of the .mc source files in the source directory then click on the Run and Debug icon in the sidebar (Ctrl-Shift-D).  
Select a device such as ForeRunner 245 from the popup menu and the code should compile and run in the ForeRunner 245 simulator.


## Other SDKs

You can set up an alternative Garmin SDK as follows:

  - Click on the Remote Explorer icon in the left hand side of vscode and will stop with a non-interactive terminal at the bottom of the screen.
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



## Copyright

All the resources contained in the archives `devices.zip` and `fonts.zip` are the property of Garmin. These resources have been fetched from the Garmin website and have been included in this repository to facilitate the creation of the Docker image.
