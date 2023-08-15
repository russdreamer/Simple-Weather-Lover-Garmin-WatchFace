import Toybox.Lang;
import Toybox.Time;
import Toybox.Application.Storage;

(:background)
class ExternalWeatherService extends Toybox.System.ServiceDelegate {
    var locator;
    var newLocationGeoString = null;
    var locationDegrees = null;

    (:background_method)
    function initialize() {
        locator = new Locator();
        ServiceDelegate.initialize();
    }

    (:background_method)
    function onTemporalEvent() {
       // read from Storage.getValue previous location
       // if it's new one - get new city name, remove from storage current one and set new one
       // if it's the same - leave the same location in storage
        
        var newLocation = locator.getNewLocation();
        if (newLocation == null)  {
            Toybox.Background.exit(null);
            return;
        }
        newLocationGeoString = locator.locationToGeoString(newLocation);

        if (newLocation != null) {
            locationDegrees = newLocation.toDegrees() as Array<Double>;
            getExternalWeather();
        }
    }

    (:background_method)
    function getExternalWeather() {
        var url = "https://api.open-meteo.com/v1/forecast";
        var params = {
            "latitude" => locationDegrees[0],
            "longitude" => locationDegrees[1],
            "forecast_days" => 2,
            "hourly" => "temperature_2m,windspeed_10m,precipitation,weathercode,is_day"
        };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };
        Toybox.Communications.makeWebRequest(url, params, options, method(:weatherResponseCallback));
    }

    (:background_method)
    function weatherResponseCallback(responseCode as Number, data as String or Dictionary or Null) as Void {
        if (responseCode == 200) {
            var forecast = getActualForecast(data) as Array<Dictionary>;
            Storage.setValue("weatherData", forecast);

            var previousSeenExternalLocation = Storage.getValue("externalWeatherService_lastSeenLocationGeoString");
            if (!newLocationGeoString.equals(previousSeenExternalLocation)) {
                getExternalCityName();
            }
        } else {
            Toybox.Background.exit(null);
        }
    }

    (:background_method)
    function getExternalCityName() {
        var url = "https://nominatim.openstreetmap.org/reverse";
        var params = {
            "lat" => locationDegrees[0],
            "lon" => locationDegrees[1],
            "zoom" => "10",
            "format" => "jsonv2"
        };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED, "accept-language" => "en-US,en;q=0.9",},
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };
        Toybox.Communications.makeWebRequest(url, params, options, method(:cityResponseCallback));
    }

    (:background_method)
    function cityResponseCallback(responseCode as Number, data as String or Dictionary or Null) as Void {
        if (responseCode == 200) {
            var cityName = parseCityName(data);
            Storage.setValue("externalWeatherService_lastSeenLocationGeoString", newLocationGeoString);
            Storage.setValue("cityData", cityName);
            Toybox.Background.exit("");
        } else {
            Storage.setValue("cityData", "");
            Toybox.Background.exit(null);
        }
    }

    function parseCityName(data as Dictionary) {
        var address = data.get("address") as Dictionary;
        var addressType = data.get("addresstype") as String;
        return address.get(addressType);
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
                    "temperature" => Toybox.Math.round(hourly.get("temperature_2m")[i].toFloat()).toNumber(),
                    "precipitation" => hourly.get("precipitation")[i].toFloat().format("%.1f"),
                    "isDay" => hourly.get("is_day")[i].equals(1),
                });
            }
        }
        return array;
    }

    (:background_method)
    function getCurrentTimeString() as String {
        return TimeUtil.getCurrentUTCTimeString();
    }
}