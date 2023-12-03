import Toybox.Activity;
import Toybox.Position;
import Toybox.Weather;
import Toybox.Lang;
import Toybox.Application.Storage;
import Toybox.Math;

(:background)
class Locator {
    private var lastSeenLocationHolder as LocationHolder or Null;
    private var logEnabled = false;
    private var lastSource = null;
    private var lastSourcExact = null;

    function enableLog() {
        logEnabled = true;
    }

    function getNewLocation() as Position.Location {
        printLog("getting location...");
        var storedActivityLocation = Storage.getValue("locator_lastSeenActivityLocation");
        var storedPositionLocation = Storage.getValue("locator_lastSeenPositionLocation");
        var actualActivityLocation = Activity.getActivityInfo().currentLocation;
        var actualPositionLocation = Toybox.Position.getInfo().position;

        var activityLocationHolder = createLocationHolder(actualActivityLocation, storedActivityLocation);
        var positionLocationHolder = createLocationHolder(actualPositionLocation, storedPositionLocation);
        
        var now = Time.now().value();

        updateStoredLocation(activityLocationHolder, now, "locator_lastSeenActivityLocation");
        updateStoredLocation(positionLocationHolder, now, "locator_lastSeenPositionLocation");
        

        var mostRecentLocationHolder = getMostRecentLocation(activityLocationHolder, positionLocationHolder);
        if (mostRecentLocationHolder == activityLocationHolder && !"activityLocationHolder".equals(lastSourcExact)) {
            printLog("Most recent location: activityLocationHolder");
            lastSourcExact = "activityLocationHolder";
        } else if (mostRecentLocationHolder == positionLocationHolder && !"positionLocationHolder".equals(lastSourcExact)) {
            printLog("Most recent location: positionLocationHolder");
            lastSourcExact = "positionLocationHolder";
        } else {
            printLog("Most recent location: unknown");
            lastSourcExact = null;
        }
        var location = null;

        
        if (mostRecentLocationHolder.locationDegrees != null) {
            if (!"mostRecentLocationHolder".equals(lastSource)) {
                printLog("location got from mostRecentLocationHolder");
                lastSource = "mostRecentLocationHolder";
            }
            if (lastSeenLocationHolder == null || !mostRecentLocationHolder.locationDegrees.equals(lastSeenLocationHolder.locationDegrees)) {
                getOrInitHolderPosition(mostRecentLocationHolder);
                printLog("lastSeenLocationHolder is updated");
                printLog(locationToGeoString(mostRecentLocationHolder.location));
                lastSeenLocationHolder = mostRecentLocationHolder;
            }
            location = lastSeenLocationHolder.location;
        } 
        
        if (Toybox has :Weather && isIncorrectLocation(location)) {
            var weatherConditions = Weather.getCurrentConditions();
            if (weatherConditions != null) {
                if (!"Weather.CurrentConditions".equals(lastSource)) {
                    printLog("location got from Weather.CurrentConditions");
                    lastSource = "Weather.CurrentConditions";
                }
                location = weatherConditions.observationLocationPosition;
            }
        }

        if (isIncorrectLocation(location)) {
            printLog("location was incorrect: " + location);
        }

        return isCorrectLocation(location) ? location : null;
    }

    private function getMostRecentLocation(activityLocationHolder as LocationHolder, positionLocationHolder as LocationHolder) as LocationHolder {
        var activityHolderDegrees = activityLocationHolder.locationDegrees;
        var positionHolderDegrees = positionLocationHolder.locationDegrees;

        if (activityHolderDegrees == null || positionHolderDegrees == null) {
            return activityHolderDegrees == null ? positionLocationHolder : activityLocationHolder;
        }

        return activityLocationHolder.locationUTCTime >= positionLocationHolder.locationUTCTime ? activityLocationHolder : positionLocationHolder;
    }

    function createLocationHolder(actualPosition as Position.Location or Null, storedLocation as Dictionary or Null) as LocationHolder {
        return storedLocation == null ? new LocationHolder(actualPosition, null, null) : new LocationHolder(actualPosition, storedLocation.get("coords"), storedLocation.get("time"));
    }

    function updateStoredLocation(locationHolder as LocationHolder, now as Number, storageKey as String) {
        var actualLocation = locationHolder.location;
        var actualLocationDegreesString = locationToDegreesString(actualLocation);
        
        if (isCorrectLocation(actualLocation) && (locationHolder.locationDegrees == null || !locationHolder.locationDegrees.equals(actualLocationDegreesString))) {
            printLog("stored location was updated and saved into storage");
            locationHolder.locationDegrees = actualLocationDegreesString;
            locationHolder.locationUTCTime = now;
            saveToStorage(storageKey, locationHolder);
        }
    }

    private function saveToStorage(itemKey as String, locationHolder as LocationHolder) {
        if (locationHolder.locationDegrees != null) {
            Storage.setValue(itemKey, {
                "coords" => locationHolder.locationDegrees,
                "time" => locationHolder.locationUTCTime
            });
        }
    }

    private function parseCoordinates(location as String) as Dictionary<String, Number> {
        var delimeterIndex = location.find("_");
        var lat = location.substring(0, delimeterIndex).toFloat() as Number;
        var lon = location.substring(delimeterIndex + 1, location.length()).toFloat() as Number;
        return {
            "latitude" => lat,
            "longitude" => lon
        };
    }

    private function createLocation(latitude as Number, longitude as Number) as Position.Location {
        return new Position.Location({
            :latitude => latitude,
            :longitude => longitude,
            :format => :degrees
        });
    }

    private function locationToDegreesString(location as Position.Location or Null) as String or Null {
        if (location == null) {
            return null;
        }
        var degrees = location.toDegrees();
        return degrees[0] + "_" + degrees[1];
    }

    private function isCorrectLocation(location as Position.Location or Null) {
        return !isIncorrectLocation(location);
    }

    private function isIncorrectLocation(location as Position.Location or Null) {
        if (location == null) {
            return true;
        }

        var degrees = location.toDegrees();
        return degrees[0] > 90 || degrees[0] < -90 || degrees[1] > 180 || degrees[1] < -180;
    }

    private function getOrInitHolderPosition(holder as LocationHolder) as Position.Location {
        if (holder.location == null && holder.locationDegrees != null) {
            var coords = parseCoordinates(holder.locationDegrees);
            holder.location = createLocation(coords.get("latitude"), coords.get("longitude"));
        }
        return holder.location;
    }

    static function locationToGeoString(location as Position.Location) {
        return location != null ? location.toGeoString(Position.GEO_DEG) : null;
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

    function printLog(text as String) {
        if (logEnabled) {
            System.println(TimeUtil.getCurrentTimeString() + ": " + text);
        }
    }

    class LocationHolder {
        var location as Position.Location or Null;
        var locationDegrees as String or Null;
        var locationUTCTime as Number or Null;

        function initialize(_location as Position.Location or Null, _locationDegrees as String or Null, _locationUTCTime as Number or Null) {
           location = _location;
           locationDegrees = _locationDegrees;
           locationUTCTime = _locationUTCTime;
        }
    }
}
