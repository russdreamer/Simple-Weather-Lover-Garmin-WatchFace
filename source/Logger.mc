import Toybox.Lang;
import Toybox.System;

(:background)
class Logger {
    static public function log(text as String) {
        System.println(TimeUtil.getCurrentTimeString() + ": " + text);
    }
}