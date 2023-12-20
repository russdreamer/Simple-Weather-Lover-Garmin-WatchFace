import Toybox.Lang;
import Toybox.Time;
import Toybox.Application.Storage;

(:background)
class ExternalWeatherService extends Toybox.System.ServiceDelegate {
    var locator as Locator;
    var newLocationGeoString = null as String;
    var locationDegrees as Array<Double> or Null = null;
    var weatherData as Dictionary or Null = null;

    (:background_method)
    function initialize() {
        locator = new Locator();
        ServiceDelegate.initialize();
    }

    (:background_method)
    function onTemporalEvent() {
        var newLocation = locator.getNewLocation();
        if (newLocation == null)  {
            Toybox.Background.exit(null);
            return;
        }
        newLocationGeoString = Locator.locationToGeoString(newLocation);
        locationDegrees = newLocation.toDegrees();
        getExternalWeather();
    }

    (:background_method)
    function getExternalWeather() {
        var url = "https://api.open-meteo.com/v1/forecast";
        var params = {
            "latitude" => locationDegrees[0],
            "longitude" => locationDegrees[1],
            "forecast_days" => 2,
            "hourly" => "temperature_2m,windspeed_10m,precipitation,weathercode,is_day,precipitation_probability"
        } as Dictionary<String, String or Number or Double>;
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
            weatherData = {
                "location" => {
                    "lat" => locationDegrees[0],
                    "lon" => locationDegrees[1]
                },
                "forecast" => forecast
            };

            var previousSeenExternalLocation = Storage.getValue("externalWeatherService_lastSeenLocationGeoString");
            if (!newLocationGeoString.equals(previousSeenExternalLocation)) {
                getExternalCityName();
            } else {
                var cityName = Storage.getValue("externalWeatherService_lastknownCityName");
                if (cityName == null) {
                    getExternalCityName();
                } else {
                    Storage.setValue("externalWeatherService_weatherData", weatherData);
                    Toybox.Background.exit("");
                }
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
            "format" => "jsonv2",
            "accept-language" => "en-US"
        };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {"Content-Type" => Communications.REQUEST_CONTENT_TYPE_URL_ENCODED},
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON,
        };
        Toybox.Communications.makeWebRequest(url, params, options, method(:cityResponseCallback));
    }

    (:background_method)
    function cityResponseCallback(responseCode as Number, data as String or Dictionary or Null) as Void {
        if (responseCode == 200 && data.get("address") != null) {
            var cityName = parseCityName(data);
            cityName = cityName != null ? cityName : "";
            Storage.setValue("externalWeatherService_lastSeenLocationGeoString", newLocationGeoString);
            Storage.setValue("externalWeatherService_lastknownCityName", cityName);
            weatherData.put("locationName", cityName);
        } else {
            Storage.deleteValue("externalWeatherService_lastknownCityName");
        }

        Storage.setValue("externalWeatherService_weatherData", weatherData);
        Toybox.Background.exit("");
    }

    function parseCityName(data as Dictionary) {
        var address = data.get("address") as Dictionary;
        var place = address.get("city");
        if (place == null) {
            place = address.get("town");
        }
        if (place == null) {
            place = address.get("borough");
        }
        if (place == null) {
            place = address.get("village");
        }
        if (place == null) {
            place = address.get("suburb");
        }
        if (place == null) {
            var addressType = data.get("addresstype") as String;
            place = address.get(addressType);
        }
        return place;
    }

    (:background_method)
    function getActualForecast(data as String or Dictionary) as Array<Dictionary> {
        var currentTime = getCurrentTimeString();
        var hourly = data.get("hourly") as Dictionary<String, Array<String or Number>>;
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
                    "precipitation" => hourly.get("precipitation")[i].toFloat(),
                    "precipitationChance" => hourly.get("precipitation_probability")[i].toNumber(),
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
