using Toybox.System;
using Toybox.Lang;


function writeLog(tagStr, msgStr) {
  var myTime = System.getClockTime();
  var timeString = Lang.format("$1$:$2$:$3$", [
      myTime.hour.format("%02d"),
      myTime.min.format("%02d"),
      myTime.sec.format("%02d")
  ]);
  System.println(timeString + " : " + tagStr + " : " + msgStr);
}

enum {
  MENUITEM_MUTE,
  MENUITEM_BENMODE,
  MENUITEM_VIBRATION,
  MENUITEM_SOUND,
  MENUITEM_LIGHT,
  MENUITEM_O2SENSOR,
}
