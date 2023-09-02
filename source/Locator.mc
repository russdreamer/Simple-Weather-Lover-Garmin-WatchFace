import Toybox.Activity;
import Toybox.Position;
import Toybox.Weather;
import Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.Math;

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
        return location != null ? location.toGeoString(Position.GEO_DEG) : null;
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


    private function isIncorrectLocation(location as Position.Location) {
        if (location == null) {
            return true;
        }

        var degrees = location.toDegrees();
        return degrees[0] > 90 || degrees[0] < -90 || degrees[1] > 180 || degrees[1] < -180;
    }

    static function calculateDistance(location1 as Position.Location, location2 as Position.Location) {
        var earthRadius = 6371000; // Earth's radius in meters
        var radians1 = location1.toRadians();
        var radians2 = location2.toRadians();
        
        var lat1 = radians1[0];
        var lon1 = radians1[1];
        var lat2 = radians2[0];
        var lon2 = radians2[1];

        var dLat = lat2 - lat1;
        var dLon = lon2 - lon1;

        var a = Math.pow(Math.sin(dLat / 2), 2) + Math.cos(lat1) * Math.cos(lat2) * Math.pow(Math.sin(dLon / 2), 2);
        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        var distance = earthRadius * c;

        return distance;
    }
}
