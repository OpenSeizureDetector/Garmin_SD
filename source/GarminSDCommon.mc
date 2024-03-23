using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.Lang;


function writeLog(tagStr, msgStr) {
  var dateTime = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
  var timeString = Lang.format("$1$:$2$:$3$", [
      dateTime.hour.format("%02d"),
      dateTime.min.format("%02d"),
      dateTime.sec.format("%02d"),
    ]);
  System.println(timeString + " : " + tagStr + " : " + msgStr);
}

enum {
  MENUITEM_MUTE,
  MENUITEM_BENMODE,
  MENUITEM_VIBRATION,
  MENUITEM_SOUND,
  MENUITEM_LIGHT,
  MENUITEM_RETRY_WARNING,
  MENUITEM_O2SENSOR,
}
