import Toybox.Time;
import Toybox.Lang;

(:background)
class TimeUtil {

    static function getCurrentUTCTimeString() as String {
        var now = Time.now();
        var newTime = now.subtract(new Time.Duration(Toybox.System.getClockTime().timeZoneOffset));
        var currentTime = Gregorian.info(newTime, Time.FORMAT_SHORT);
        var month = currentTime.month.format("%02d");
        var day = currentTime.day.format("%02d");
        var hour = currentTime.hour.format("%02d");
        return Lang.format("$1$-$2$-$3$T$4$:00", [currentTime.year, month, day, hour]);
    }

    static function parseTime(date as String) as Toybox.Time.Moment {
        return Gregorian.moment({
            :year => date.substring(0, 4).toNumber(),
            :month => date.substring(5, 7).toNumber(),
            :day => date.substring( 8, 10).toNumber(),
            :hour => date.substring(11, 13).toNumber(),
            :minute => date.substring(14, 16).toNumber(),
            :second => 0
        });
    }

    static function getCurrentTimeString() {
        var now = Time.now();
        var currentTime = Gregorian.info(now, Time.FORMAT_SHORT);
        var month = currentTime.month.format("%02d");
        var day = currentTime.day.format("%02d");
        var hour = currentTime.hour.format("%02d");
        var min = currentTime.min.format("%02d");
        var sec = currentTime.sec.format("%02d");
        return Lang.format("$1$-$2$-$3$T$4$:$5$:$6$", [currentTime.year, month, day, hour, min, sec]);
    }

    static function momentToHumanReadableString(moment as Time.Moment) {
        var currentTime = Gregorian.info(moment, Time.FORMAT_SHORT);
        var month = currentTime.month.format("%02d");
        var day = currentTime.day.format("%02d");
        var hour = currentTime.hour.format("%02d");
        var min = currentTime.min.format("%02d");
        var sec = currentTime.sec.format("%02d");
        return Lang.format("$1$-$2$-$3$T$4$:$5$:$6$", [currentTime.year, month, day, hour, min, sec]);
    }
}