import Toybox.Activity;
import Toybox.Position;
import Toybox.Weather;
import Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.Math;

(:background)
class Locator {
    private var lastSeenLocationDegreesString as String or Null;
    private var lastSeenLatitude as Number or Null;
    private var lastSeenLongitude as Number or Null;

    function initialize() {
        lastSeenLocationDegreesString = Storage.getValue("locator_lastSeenLocationDegrees") != null ? Storage.getValue("locator_lastSeenLocationDegrees") : Locator.locationToDegreesString(getNewLocation());
        if (lastSeenLocationDegreesString != null) {
            updateCoordinates();
        }
    }

    function getNewLocation() as Position.Location {
        var location = Activity.getActivityInfo().currentLocation;
        if (isIncorrectLocation(location)) {
            location = Toybox.Position.getInfo().position;
            if (isIncorrectLocation(location)) {
                var storedLocation = Storage.getValue("locator_lastSeenLocationDegrees");
                if (storedLocation != null) {
                    if (storedLocation.equals(lastSeenLocationDegreesString)) {
                        location = createLocation(lastSeenLatitude, lastSeenLongitude);
                    } else {
                        lastSeenLocationDegreesString = storedLocation;
                        updateCoordinates();
                        location = createLocation(lastSeenLatitude, lastSeenLongitude);
                    }
                }
                if (Toybox has :Weather && isIncorrectLocation(location)) {
                    var weatherConditions = Weather.getCurrentConditions();
                    if (weatherConditions != null) {
                        location = weatherConditions.observationLocationPosition;
                    }
                }
            } else {
                saveToStorage(location);
            }
        } else {
            saveToStorage(location);
        }
        return isIncorrectLocation(location) ? null : location;
    }

    private function saveToStorage(location as Position.Location) {
        Storage.setValue("locator_lastSeenLocationDegrees", locationToDegreesString(location));
    }

    private function parseCoordinates(location as String) as Dictionary {
        var delimeterIndex = location.find("_");
        var lat = location.substring(0, delimeterIndex).toNumber();
        var lon = location.substring(delimeterIndex + 1, location.length()).toNumber();
        return {
            "latitude" => lat,
            "longitude" => lon
        };
    }

    private function createLocation(latitude as Number, longitude as Number) {
        return new Position.Location({
            :latitude => latitude,
            :longitude => longitude,
            :format => :degrees
        });
    }

    private function updateCoordinates() {
        var coords = parseCoordinates(lastSeenLocationDegreesString);
        lastSeenLatitude = coords.get("latitude");
        lastSeenLongitude = coords.get("longitude");
    }

    static function locationToGeoString(location as Position.Location) {
        return location != null ? location.toGeoString(Position.GEO_DEG) : null;
    }

    private function locationToDegreesString(location as Position.Location) as String {
        var degrees = location.toDegrees();
        return degrees[0] + "_" + degrees[1];
    }

    private function isIncorrectLocation(location as Position.Location or Null) {
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
