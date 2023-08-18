/**
* GarminSDState class manages the operating state of the watch app - whether we are in normal
* running mode, showing mute dialog, or showing quit dialog.
*
* Copyright Graham Jones, 2023
*/
enum {
    MODE_RUNNING,
    MODE_MUTEDLG,
    MODE_QUITDLG,
  }


class GarminSDState  {
    var mMode;
  function initialize() {
    System.println("GarminSdState.initialize");
    mMode = MODE_RUNNING;
  }

  // onStart() is called on application start up
  function getMode() {
    return mMode;
  }

  function setMode(newMode) {
    mMode = newMode;
    System.println("GarminSdState.setMode - mMode="+mMode);
  }
}