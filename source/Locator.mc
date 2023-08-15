import Toybox.Activity;
import Toybox.Position;
import Toybox.Weather;
import Toybox.Lang;
import Toybox.Application.Storage;

(:background)
class Locator {
    private var lastSeenLocationGeoString as String or Null;

    function initialize() {
        lastSeenLocationGeoString = Storage.getValue("lastSeenLocationGeoString") != null ? Storage.getValue("lastSeenLocationGeoString") : Locator.locationToGeoString(getNewLocation());
    }

    function getNewLocation() as Position.Location {
        var location = Activity.getActivityInfo().currentLocation;
        if (isIncorrectLocation(location)) {
            location = Toybox.Position.getInfo().position;
            if (Toybox has :Weather && isIncorrectLocation(location)) {
                var weatherConditions = Weather.getCurrentConditions();
                if (weatherConditions != null) {
                    location = weatherConditions.observationLocationPosition;
                }
            }
        }
        return isIncorrectLocation(location) ? null : location;
    }

    static function locationToGeoString(location as Position.Location) {
        return location.toGeoString(Position.GEO_DEG);
    }

    function isPositionChanged() as Boolean {
        var newLocation = getNewLocation();
        if (newLocation != null) {
            var newLocationGeoString = Locator.locationToGeoString(newLocation);
            if (!newLocationGeoString.equals(lastSeenLocationGeoString)) {
                return true;
            }
        }
        return false;
    }

    /** Returns true if position was change since last check */
    function updatePositionIfChanged() as Boolean {
        var newLocation = getNewLocation();
        if (newLocation != null) {
            var newLocationGeoString = Locator.locationToGeoString(newLocation);
            if (!newLocationGeoString.equals(lastSeenLocationGeoString)) {
                Storage.setValue("lastSeenLocationGeoString", newLocationGeoString);
                lastSeenLocationGeoString = newLocationGeoString;
                return true;
            }
        }
        return false;
    }


    private function isIncorrectLocation(location as Position.Location) {
        if (location == null) {
            return true;
        }

        var degrees = location.toDegrees();
        return degrees[0] > 90 || degrees[0] < -90 || degrees[1] > 180 || degrees[1] < -180;
    }
}