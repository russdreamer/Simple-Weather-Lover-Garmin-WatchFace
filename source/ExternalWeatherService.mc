import Toybox.Lang;
import Toybox.Time.Gregorian;
import Toybox.Application.Storage;

(:background)
class ExternalWeatherService extends Toybox.System.ServiceDelegate {
    var lastSeenLocation = null;
    var lastSeenLocationGeoString = null;

    (:background_method)
    function initialize() {
        lastSeenLocation = Storage.getValue("lastSeenLocation");
        lastSeenLocationGeoString = Storage.getValue("lastSeenLocationGeoString");
        ServiceDelegate.initialize();
    }

    (:background_method)
    function onTemporalEvent() {
        //if (isPositionChanged()) {
            // get new city name;
        //}
        
        var newLocation = getNewLocation();

        if (newLocation != null) {
            var degrees = newLocation.toDegrees() as Array<Double>;
            getExternalWeather(degrees[0], degrees[1]);
        }
    }

    (:background_method)
    function isPositionChanged() as Boolean {
        var newLocation = getNewLocation();
        if (newLocation != null) {
            var newLocationGeoString = newLocation.toGeoString(Position.GEO_DEG);
            if (!newLocationGeoString.equals(lastSeenLocationGeoString)) {
                Storage.setValue("lastSeenLocation", newLocation); // not possible to serialize
                Storage.setValue("lastSeenLocationGeoString", newLocationGeoString);
                return true;
            }
        }
        return false;
    }

    (:background_method)
    function isIncorrectLocation(location) {
        if (location == null) {
            return true;
        }

        var degrees = location.toDegrees();
        return degrees[0] > 90 || degrees[0] < -90 || degrees[1] > 180 || degrees[1] < -180;
    }

    (:background_method)
    function getNewLocation() {
        var location = Activity.getActivityInfo().currentLocation;
        System.println("location from  Activity.getActivityInfo().currentLocation");
        if (isIncorrectLocation(location)) {
            location = Toybox.Position.getInfo().position;
            System.println("location from  Position.getInfo().position");
            if (Toybox has :Weather && isIncorrectLocation(location)) {
                System.println("all above were null");
                var weatherConditions = Weather.getCurrentConditions();
                if (weatherConditions != null) {
                    System.println("location from Weather.getCurrentConditions().observationLocationPosition");
                    location = weatherConditions.observationLocationPosition;
                }
            }
        }
        return isIncorrectLocation(location) ? null : location;
    }

    (:background_method)
    function getExternalWeather(latitude as Double, longitude as Double) {
        var url = "https://api.open-meteo.com/v1/forecast";
        var params = {
            "latitude" => latitude,
            "longitude" => longitude,
            "forecast_days" => 2,
            "hourly" => "temperature_2m,windspeed_10m,precipitation,weathercode,is_day"
        };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };
        Toybox.Communications.makeWebRequest(url, params, options, method(:responseCallback));
    }

    (:background_method)
    function responseCallback(responseCode as Number, data as String or Dictionary or Null) as Void {
        if (responseCode == 200) {
            System.println("Got success response");
            var forecast = getActualForecast(data) as Array<Dictionary>;
            System.println("Response processed");
            Storage.setValue("weatherData", forecast);
            Toybox.Background.exit("");
        } else {
            System.println("Bad Response: " + responseCode + " : " + data);
            Toybox.Background.exit(null);
        }
    }

    (:background_method)
    function getActualForecast(data as String or Dictionary) as Array<Dictionary> {
        var currentTime = getCurrentTimeString();
        var hourly = data.get("hourly") as Dictionary;
        var toCollectItems = false;
        var timeArray = hourly.get("time") as Array<String>;
        var array = [] as Array<Dictionary>;
        var numOfForecastsAdded = 0;
        for (var i = 0; numOfForecastsAdded < 12 && i < timeArray.size(); i++) {
            if (timeArray[i].equals(currentTime)) {
                toCollectItems = true;
            }
            if (toCollectItems) {
                numOfForecastsAdded = numOfForecastsAdded + 1;
                array.add({
                    "time" => hourly.get("time")[i],
                    "windSpeed" => (hourly.get("windspeed_10m")[i] * 1000 / 3600).toNumber(),
                    "weatherCode" => hourly.get("weathercode")[i],
                    "temperature" => hourly.get("temperature_2m")[i].toNumber(),
                    "precipitation" => hourly.get("precipitation")[i].toFloat().format("%.1f"),
                    "isDay" => hourly.get("is_day")[i].equals(1),
                });
            }
        }
        return array;
    }

    (:background_method)
    function getCurrentTimeString() as String {
        var now = Time.now();
        return getCurrentUTCTimeString(now);
    }

    (:background_method)
    function getCurrentUTCTimeString(now) as String {
        var newTime = now.subtract(new Time.Duration(System.getClockTime().timeZoneOffset));
        var currentTime = Gregorian.info(newTime, Time.FORMAT_SHORT);
        var month = currentTime.month.format("%02d");
        var day = currentTime.day.format("%02d");
        var hour = currentTime.hour.format("%02d");
        return Lang.format("$1$-$2$-$3$T$4$:00", [currentTime.year, month, day, hour]);
    }
}