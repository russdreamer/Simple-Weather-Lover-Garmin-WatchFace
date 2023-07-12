import Toybox.Application;
import Toybox.Graphics;
import Toybox.Time.Gregorian;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Timer;
import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Weather;
import Toybox.Background;

class IgafaceView extends WatchUi.WatchFace {
    var timeLabel;
    var dateLabel;
    var weatherLabel;
    var detailedWeatherLabel;
    var weatherTimeLabel;
    var stepsLabel;
    var errorMessageTitleLabel;
    var errorMessageBodyLabel;
    var timeFont;
    var dataFont;
    var accentColor;
    var wasSleepMode;
    var isSleepMode;
    var isShiftingWeatherVisible;
    var isStaticWeatherVisible;
    var isStepsVisible;
    var lastWeatherChangeSeconds;
    var nextForecastIndex;
    var iconSize;
    var previousUpdateTime;
    var prevWeatherTriggerTime;
    var weatherPreviousUpdateTime;
    var lastSeenLocation as String or Null;
    var cachedWeatherForecast;
    var weatherConditions;
    var hourlyForecast as Array or Null;
    var isStaticWeatherAvailable;
    var isShiftingWeatherAvailable;
    var previousObservationLocationName;
    var cachedCityName;
    var externalWeather;

    var ClearDayIcon;
    var ClearNightIcon;
    var CloudyIcon;
    var LiteRainIcon;
    var RainIcon;
    var SnowIcon;
    var SnowRainIcon;
    var WindIcon;
    var ThunderIcon;
    var MistIcon;
    var HailIcon;
    var MostlyCloudyDayIcon;
    var MostlyCloudyNightIcon;
    var TornadoIcon;
    var UnknownPrecipitationIcon;
    var stepsIcon;

    const SUPPORTED_SYMBOLS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-?%/:° ms";
    const MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"] as Array<String>;
    const DAYS_OF_WEEK = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"] as Array<String>;
    const FIVE_MINUTES = new Time.Duration(5 * 60);
    const ONE_HOUR = new Time.Duration(60 * 60);

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
        timeFont = WatchUi.loadResource(Rez.Fonts.time_font);
        dataFont = WatchUi.loadResource(Rez.Fonts.data_font);
        ClearDayIcon = WatchUi.loadResource(Rez.Drawables.ClearDayIcon);
        ClearNightIcon = WatchUi.loadResource(Rez.Drawables.ClearNightIcon);
        CloudyIcon = WatchUi.loadResource(Rez.Drawables.CloudyIcon);
        LiteRainIcon = WatchUi.loadResource(Rez.Drawables.LiteRainIcon);
        RainIcon = WatchUi.loadResource(Rez.Drawables.RainIcon);
        SnowIcon = WatchUi.loadResource(Rez.Drawables.SnowIcon);
        SnowRainIcon = WatchUi.loadResource(Rez.Drawables.SnowRainIcon);
        WindIcon = WatchUi.loadResource(Rez.Drawables.WindIcon);
        ThunderIcon = WatchUi.loadResource(Rez.Drawables.ThunderIcon);
        MistIcon = WatchUi.loadResource(Rez.Drawables.MistIcon);
        HailIcon = WatchUi.loadResource(Rez.Drawables.HailIcon);
        MostlyCloudyDayIcon = WatchUi.loadResource(Rez.Drawables.MostlyCloudyDayIcon);
        MostlyCloudyNightIcon = WatchUi.loadResource(Rez.Drawables.MostlyCloudyNightIcon);
        TornadoIcon = WatchUi.loadResource(Rez.Drawables.TornadoIcon);
        UnknownPrecipitationIcon = WatchUi.loadResource(Rez.Drawables.UnknownPrecipitationIcon);
        stepsIcon = WatchUi.loadResource(Rez.Drawables.StepsIcon);
        timeLabel = View.findDrawableById("TimeLabel") as Text;
        dateLabel = View.findDrawableById("DateLabel") as Text;
        errorMessageTitleLabel = View.findDrawableById("ErrorMessageTitleLabel") as Text;
        errorMessageBodyLabel = View.findDrawableById("ErrorMessageBodyLabel") as Text;
        weatherLabel = View.findDrawableById("WeatherLabel") as Text;
        detailedWeatherLabel = View.findDrawableById("DetailedWeatherLabel") as Text;
        weatherTimeLabel = View.findDrawableById("WeatherTimeLabel") as Text;
        stepsLabel = View.findDrawableById("StepsLabel") as Text;
        iconSize = WatchUi.loadResource(Rez.Strings.IconSize).toNumber();
        timeLabel.setFont(timeFont);
        weatherLabel.setFont(dataFont);
        weatherTimeLabel.setFont(dataFont);
        detailedWeatherLabel.setFont(dataFont);
        stepsLabel.setFont(dataFont);
        dateLabel.setFont(dataFont);
        isSleepMode = false;
        isShiftingWeatherVisible = false;
        isStaticWeatherVisible = false;
        isStepsVisible = false;
        lastWeatherChangeSeconds = 0;
        nextForecastIndex = -1;
        previousUpdateTime = null;
        prevWeatherTriggerTime = null;
        weatherPreviousUpdateTime = null;
        lastSeenLocation = null;
        cachedWeatherForecast = null;
        weatherConditions = null;
        hourlyForecast = null;
        isStaticWeatherAvailable = false;
        isShiftingWeatherAvailable = false;
        previousObservationLocationName = null;
        cachedCityName = null;
        externalWeather = null;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var now = Time.now();

        var needScreenUpdate = previousUpdateTime == null || now.compare(previousUpdateTime) != 0 || isSleepMode;
        if (!needScreenUpdate) {
            return;
        }
        previousUpdateTime = now;

        var currentTime = Gregorian.info(now, Time.FORMAT_SHORT);
        accentColor = Application.Properties.getValue("AccentColor");
        var switchForecast = Application.Properties.getValue("SwitchForecast");
        var isWeatherField = Application.Properties.getValue("LowPowerMode") == 0;

        timeLabel.setText(getTime(currentTime));
        dateLabel.setText(getDateInfo(currentTime));

        var steps = null;
        var toShowStaticWeather = false;
        var toShowShiftingWeather = false;

        if (!isSleepMode || isWeatherField) {
            if (prevWeatherTriggerTime == null || now.compare(prevWeatherTriggerTime).abs() > 5 * 60) {
                triggerExternalWeather(now);
                prevWeatherTriggerTime = now;
            }

            var isNewHour = currentTime.min == 0 && currentTime.sec == 0;
            var isSourceChanged = isWeatherSourceChanged();
            var needWeatherUpdate = isSourceChanged || weatherPreviousUpdateTime == null || now.compare(weatherPreviousUpdateTime).abs() > 60 || isNewHour;
            weatherConditions = needWeatherUpdate || weatherConditions == null ? getCurrentWeather(now) : weatherConditions;
            hourlyForecast = needWeatherUpdate || hourlyForecast == null ? getWeatherForecast(now) : hourlyForecast;
            
            // update once per minute if the weather is available
            if (needWeatherUpdate && (hourlyForecast != null || weatherConditions != null || isStaticWeatherAvailable || isShiftingWeatherAvailable)) {
                weatherPreviousUpdateTime = now;
                var isCachedForecastExpired = isCachedForecastExpired(cachedWeatherForecast, now);
                var isObservationPosAvailable = isObservationPosAvailable(weatherConditions);
                var isHourlyForecastAvailable = isHourlyForecastAvailable(hourlyForecast, now);
                var isCurrentTemperatureAvailable = isCurrentTemperatureAvailable(weatherConditions, now);
                isStaticWeatherAvailable = isObservationPosAvailable && getWeatherCondition(weatherConditions) != null && (isCurrentTemperatureAvailable || isHourlyForecastAvailable);
                isShiftingWeatherAvailable = isObservationPosAvailable && isHourlyForecastAvailable;
                
                var mostActualForecast = null;
                if (isStaticWeatherAvailable || isShiftingWeatherAvailable) {
                    if (isStaticWeatherAvailable && isShiftingWeatherAvailable) {
                        if (now.compare(getWeatherTime(hourlyForecast[0])).abs() < now.compare(getWeatherTime(weatherConditions)).abs()) {
                            mostActualForecast = hourlyForecast[0];
                        } else {
                            mostActualForecast = weatherConditions;
                        }
                    } else {
                        mostActualForecast = isStaticWeatherAvailable ? weatherConditions : hourlyForecast[0];
                    }
                }

                var needCacheForecast = mostActualForecast != null && (isCachedForecastExpired || isSourceChanged || now.compare(getWeatherTime(mostActualForecast)).abs() < now.compare(getWeatherTime(cachedWeatherForecast)).abs());
                if (needCacheForecast)  {
                    cachedWeatherForecast = mostActualForecast;
                } else if (isCachedForecastExpired) {
                    cachedWeatherForecast = null;
                }
            }

            toShowStaticWeather = isStaticWeatherAvailable && isWeatherField && (isSleepMode || (!isSleepMode && !switchForecast));
            toShowShiftingWeather = isShiftingWeatherAvailable && !isSleepMode && switchForecast;
        }

        if (toShowStaticWeather) {
            if (!isStaticWeatherVisible) {
                clearDataFields();
                switchAllVisibilitiesOff();
            }
            isStaticWeatherVisible = true;
        } else if (toShowShiftingWeather) {
            if (!isShiftingWeatherVisible) {
                clearDataFields();
                switchAllVisibilitiesOff();
            }
            isShiftingWeatherVisible = true;
        } else {
            if (!isStepsVisible) {
                clearDataFields();
                switchAllVisibilitiesOff();
            }
            steps = getSteps();
            if (steps != null) {
                isStepsVisible = true;
            }
        }

        if (isStaticWeatherVisible) {
            setWeatherInfo(getWeatherTemperature(cachedWeatherForecast));
        } else if (isShiftingWeatherVisible) {            
            if (lastWeatherChangeSeconds == 0) {
                nextForecastIndex = nextForecastIndex == 4? 0 : nextForecastIndex + 1;

                if (hourlyForecast.size() - 1 < nextForecastIndex) {
                    nextForecastIndex = 0;
                }

                if (nextForecastIndex == 0) {
                    setDetailedWeatherInfo(weatherConditions, cachedWeatherForecast);
                } else {
                    setDetailedForecastInfo(hourlyForecast[nextForecastIndex - 1]);
                }
            }
            lastWeatherChangeSeconds = lastWeatherChangeSeconds == 1? 0 : lastWeatherChangeSeconds + 1;
        } else if (isStepsVisible) {
            stepsLabel.setText(steps);
        } else {
            clearDataFields();
        }

        View.onUpdate(dc);
        dc.setAntiAlias(true);

        if (isStaticWeatherVisible) {
            drawWeatherIcon(weatherConditions, cachedWeatherForecast, now, dc);
        } else if (isShiftingWeatherVisible) {
            var forecastToShow = nextForecastIndex == 0 ? cachedWeatherForecast : hourlyForecast[nextForecastIndex - 1];
            drawDetailedWeatherIcon(weatherConditions, forecastToShow, dc);
        } else if (isStepsVisible) {
            drawStepsIcon(dc);
        }

        if (!isSleepMode) {
            drawSeconds(dc, currentTime);
        }
        drawBatteryStatus(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        isSleepMode = false;
        nextForecastIndex = -1;
        lastWeatherChangeSeconds = 0;
        clearDataFields();
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        isSleepMode = true;
        clearDataFields();
    }

    function onBackgroundData(data) {
        System.println("onBackgroundData Watch Face method");
        Toybox.Application.Storage.deleteValue("weatherData");
        if (data != null && data instanceof Array) {
            System.println("data is Array type");
            externalWeather = processBackgroundData(data);
            System.println("data added to external");
        }
    }

    function processBackgroundData(data as Array<Dictionary>) as Array<Dictionary> {
        for (var i = 0; i < data.size(); i++) {
            data[i].put("forecastTime", parseTime(data[i].get("time").toString()));
        }

        return data;
    }

    function parseTime(date as String) as Toybox.Time.Moment {
        return Gregorian.moment({
            :year => date.substring(0, 4).toNumber(),
            :month => date.substring(5, 7).toNumber(),
            :day => date.substring( 8, 10).toNumber(),
            :hour => date.substring(11, 13).toNumber(),
            :minute => date.substring(14, 16).toNumber(),
            :second => 0
        });
    }

    function getCurrentUTCTimeString(now) as String {
        var newTime = now.subtract(new Time.Duration(System.getClockTime().timeZoneOffset));
        var currentTime = Gregorian.info(newTime, Time.FORMAT_SHORT);
        var month = currentTime.month.format("%02d");
        var day = currentTime.day.format("%02d");
        var hour = currentTime.hour.format("%02d");
        return Lang.format("$1$-$2$-$3$T$4$:00", [currentTime.year, month, day, hour]);
    }

    function isWeatherSourceChanged() as Boolean {
        var isCurrentWeatherNotExternal = weatherConditions == null || hourlyForecast == null || Toybox has :Weather && (weatherConditions instanceof Toybox.Weather.CurrentConditions || hourlyForecast[0] instanceof Toybox.Weather.HourlyForecast);
        return externalWeather != null && isCurrentWeatherNotExternal;
    }

    function showError(title, body) {
        errorMessageTitleLabel.setText(title != null ? title : "");
        errorMessageBodyLabel.setText(body != null ? body : "");
    }

    function switchAllVisibilitiesOff() {
        isShiftingWeatherVisible = false;
        isStaticWeatherVisible = false;
        isStepsVisible = false;
    }

    function clearDataFields() {
        detailedWeatherLabel.setText("");
        weatherTimeLabel.setText("");
        weatherLabel.setText("");
        stepsLabel.setText("");
        errorMessageTitleLabel.setText("");
        errorMessageBodyLabel.setText("");
    }

    function getTime(currentTime) {
        var hours = currentTime.hour;
        var format = "$1$:$2$";

        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
        } else {
            if (Application.Properties.getValue("UseMilitaryFormat")) {
                format = "$1$$2$";
            }
        }
        return Lang.format(format, [hours.format("%02d"), currentTime.min.format("%02d")]);
    }

    function getDateInfo(currentTime) {
        var dayOfWeek = DAYS_OF_WEEK[currentTime.day_of_week - 1];
        var day = currentTime.day;
        var month = MONTHS[currentTime.month - 1];
        return Lang.format("$1$ $2$ $3$", [month, day, dayOfWeek]);
    }

    function getCurrentTemperatureInfo(hourlyForecast as Array) {
        var weatherInfo = null;
        if (hourlyForecast != null && hourlyForecast.size != 0) {
            weatherInfo = Lang.format("$1$°", [hourlyForecast[0].temperature]);
        }
        return weatherInfo;
    }

    function isDayTime(weatherCondition, forecastTime) {
        if (weatherCondition == null || weatherCondition.observationLocationPosition == null) {
            return null;
        }
        var toSunset = weatherCondition.getSunset(weatherCondition.observationLocationPosition, forecastTime).compare(forecastTime);
        var toSunrise = weatherCondition.getSunrise(weatherCondition.observationLocationPosition, forecastTime).compare(forecastTime);
        return toSunrise < 0 && toSunset > 0;
    }

    function drawSeconds(dc, currentTime) {
        var START_ARC_DEGREE = 90;
        var MAX_DEGREES = 360;
        var MAX_SECONDS = 60;
        var seconds = currentTime.sec;
        var endDegree = (((60 - seconds) * MAX_DEGREES) / MAX_SECONDS + START_ARC_DEGREE) % MAX_DEGREES;
        var penWidth = 4;
        var cx = dc.getWidth() / 2 - 1;
        var cy = dc.getHeight() / 2 - 1;
        var radius = dc.getWidth() / 2 - (penWidth - 2);

        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        if (seconds > 0) {
            dc.setPenWidth(penWidth);
            dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, START_ARC_DEGREE, endDegree);
        }
    }

    function drawBatteryStatus(dc) {
        var batteryPercentage = System.getSystemStats().battery;
        var cx = dc.getWidth() / 2 - 1;
        var cy = dc.getHeight() / 2 - 1;
        var lineLength = dc.getWidth() * 0.85 - cx;
        var penWidth = 4;
        dc.setPenWidth(penWidth / 2);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, cy + penWidth / 4, cx + lineLength, cy + penWidth / 4);
        dc.setPenWidth(penWidth);
        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, cy, cx + lineLength * batteryPercentage / 100, cy);
    }

    function getTemperature(hourlyForecast as Toybox.Weather.HourlyForecast or Toybox.Weather.CurrentConditions) {
        return Lang.format("$1$°", [getWeatherTemperature(hourlyForecast)]);
    }

    function getWind(hourlyForecast as Toybox.Weather.HourlyForecast or Toybox.Weather.CurrentConditions) {
        return Lang.format("$1$m/s", [getWeatherWindSpeed(hourlyForecast).format("%d")]);
    }

    function getPrecipitationChance(hourlyForecast as Toybox.Weather.HourlyForecast or Toybox.Weather.CurrentConditions) {
        return getPrecipitationInfo(hourlyForecast);
    }

    function getSteps() {
        return Lang.format("$1$", [ActivityMonitor.getInfo().steps]);
    }

    function setDetailedWeatherInfo(weatherConditions, forecast) {
        var locationName = null;
        if (Toybox has :Weather && weatherConditions instanceof Toybox.Weather.CurrentConditions) {
            locationName = getCurrentLocationName(weatherConditions);
        } else {
            locationName = getCurrentLocationName(null);
        }

        weatherTimeLabel.setText(locationName == null || locationName.length() == 0 ? "NOW" : locationName);
        var weatherInfo = Lang.format("$1$ $2$ $3$", [getTemperature(forecast), getWind(forecast), getPrecipitationChance(forecast)]);
        detailedWeatherLabel.setText(weatherInfo);
    }

    function getCurrentLocationName(weatherConditions) {
        var cityName = null;

        if (Toybox has :Weather) {
            if (weatherConditions == null || ! (Toybox has :Weather && weatherConditions instanceof Toybox.Weather.CurrentConditions)) {
                weatherConditions = Weather.getCurrentConditions();
            }
            if (weatherConditions != null) {
                var locationName = weatherConditions.observationLocationName;
                if (locationName != null) {
                    if (locationName.equals(previousObservationLocationName)) {
                        cityName = cachedCityName;
                    } else {
                        previousObservationLocationName = locationName;
                        var lengthLimit = 18;
                        var commaIndex = locationName.find(",");
                        if (commaIndex != null) {
                            if (commaIndex >= lengthLimit) {
                                cityName = locationName.substring(null, lengthLimit).toUpper();
                            } else {
                                cityName = locationName.substring(null, commaIndex).toUpper();
                            }
                            cityName = getSupportedString(cityName);
                        }
                    }
                }
            }
        }
        if (cityName != null) {
            cachedCityName = cityName;
        }
        return cityName;
    }

    function getSupportedString(stringToTransform) {
        var stringToTransformArray = stringToTransform.toCharArray() as Array;
        var i = 0;
        while(i < stringToTransformArray.size()) {
            var isSupported = SUPPORTED_SYMBOLS.find(stringToTransformArray[i].toString()) != null;
            if (!isSupported) {
                stringToTransformArray.removeAll(stringToTransformArray[i]);
            } else {
                i++;
            }
        }
        return Toybox.StringUtil.charArrayToString(stringToTransformArray);
    }

    function setDetailedForecastInfo(forecast) {
        var forecastTime = getTime(Gregorian.info(getWeatherTime(forecast), Time.FORMAT_SHORT));
        weatherTimeLabel.setText(forecastTime);
        var weatherInfo = Lang.format("$1$ $2$ $3$", [getTemperature(forecast), getWind(forecast), getPrecipitationChance(forecast)]);
        detailedWeatherLabel.setText(weatherInfo);
    }

    function setWeatherInfo(temperature) {
        var weatherInfo = temperature != null ? Lang.format("$1$°", [temperature]) : null;
        if (weatherInfo != null) {
            weatherLabel.setText(weatherInfo);
        }
    }

    function drawDetailedWeatherIcon(weatherConditions, forecast, dc) {
        var weatherIcon = null;
        if (Toybox has :Weather && weatherConditions instanceof Toybox.Weather.CurrentConditions && (forecast instanceof Toybox.Weather.CurrentConditions || forecast instanceof Toybox.Weather.HourlyForecast)) {
            var isDay = isDayTime(weatherConditions, getWeatherTime(forecast));
            if (isDay != null) {
                weatherIcon = getWeatherIcon(getWeatherCondition(forecast), isDay);
            }
        }  else {
            var weatherCode = forecast["weatherCode"];
            var isDay = forecast["isDay"];
            if (weatherCode != null && isDay != null) {
                weatherIcon = getWMOWeatherIcon(weatherCode, isDay);
            }
        }

        if (weatherIcon != null) {
            dc.drawBitmap(dc.getWidth() * 0.5 - iconSize / 2, dc.getHeight() * 0.85, weatherIcon);
        }
    }

    function drawWeatherIcon(weatherConditions, forecast, now, dc) {
        var weatherIcon = null;
        if (Toybox has :Weather && weatherConditions instanceof Toybox.Weather.CurrentConditions && (forecast instanceof Toybox.Weather.CurrentConditions || forecast instanceof Toybox.Weather.HourlyForecast)) {
            var condition = getWeatherCondition(forecast);
            var isDay = isDayTime(weatherConditions, now);
            if (isDay != null) {
                weatherIcon = getWeatherIcon(condition, isDay);
            }
        } else {
            var weatherCode = weatherConditions["weatherCode"];
            var isDay = weatherConditions["isDay"];
            if (weatherCode != null && isDay != null) {
                weatherIcon = getWMOWeatherIcon(weatherCode, isDay);
            }
        }

        if (weatherIcon != null) {
            dc.drawBitmap(dc.getWidth() * 0.5 + iconSize / 8, dc.getHeight() * 0.8 - iconSize / 4, weatherIcon);
        }
    }

    function drawStepsIcon(dc) {
        dc.drawBitmap(dc.getWidth() * 0.5 - iconSize, dc.getHeight() * 0.8 - iconSize / 8, stepsIcon);
    }

    function getWeatherTime(weather) {
        if (Toybox has :Weather && weather instanceof Toybox.Weather.CurrentConditions) {
            return weather.observationTime;
        } else if (Toybox has :Weather && weather instanceof Toybox.Weather.HourlyForecast) {
            return weather.forecastTime;
        } else {
            return weather["forecastTime"];
        }
    }

    function getPrecipitationInfo(weather) {
        if (Toybox has :Weather && (weather instanceof Toybox.Weather.CurrentConditions || weather instanceof Toybox.Weather.HourlyForecast)) {
            return Lang.format("$1$%", [weather.precipitationChance]);
        } else {
            return Lang.format("$1$mm", [weather["precipitation"]]);
        }
    }

    function getWeatherWindSpeed(weather) {
        if (Toybox has :Weather && weather instanceof Toybox.Weather.CurrentConditions) {
            return weather.windSpeed;
        } else if (Toybox has :Weather && weather instanceof Toybox.Weather.HourlyForecast) {
            return weather.windSpeed;
        } else {
            return weather["windSpeed"];
        }
    }

    function getWeatherTemperature(weather) {
        if (Toybox has :Weather && weather instanceof Toybox.Weather.CurrentConditions) {
            return weather.temperature;
        } else if (Toybox has :Weather && weather instanceof Toybox.Weather.HourlyForecast) {
            return weather.temperature;
        } else {
            return weather["temperature"];
        }
    }

    function getWeatherCondition(weather) as Number or Null {
        if (Toybox has :Weather && (weather instanceof Toybox.Weather.CurrentConditions || weather instanceof Toybox.Weather.HourlyForecast)) {
            return weather.condition;
        } else {
            return weather["weatherCode"].toNumber();
        }
    }

    function isObservationPosAvailable(weatherConditions) {
        if (weatherConditions == null) {
            return false;
        } else if (Toybox has :Weather && weatherConditions instanceof Toybox.Weather.CurrentConditions) {
            return weatherConditions.observationLocationPosition != null;
        } else {
            return weatherConditions["isDay"] != null;
        }
    }

    function isHourlyForecastAvailable(hourlyForecast, now) {
        if (hourlyForecast == null) {
            return false;
        } else {
            return hourlyForecast.size() > 0 && now.compare(getWeatherTime(hourlyForecast[0])) < 1800 && now.compare(getWeatherTime(hourlyForecast[0])) > -3600;
        }
    }

    function isCurrentTemperatureAvailable(weatherConditions, now) {
        var isCurrentConditionExpired = weatherConditions == null  || now.compare(getWeatherTime(weatherConditions)) >= 3600 || now.compare(getWeatherTime(weatherConditions)) < -1800;
        return !isCurrentConditionExpired && getWeatherTemperature(weatherConditions) != null;
    }

    function isCachedForecastExpired(cachedWeatherForecast, now) {
        if (cachedWeatherForecast == null) {
            return true;
        } else {
            return now.compare(getWeatherTime(cachedWeatherForecast)) >= 3600 || now.compare(getWeatherTime(cachedWeatherForecast)) < -1800;
        }
    }

    function getCurrentWeather(now) {
        if (externalWeather != null) {
            return getCurrentWeatherFromExternal(externalWeather, now);
        } else if (Toybox has :Weather) {
            return Weather.getCurrentConditions();
        } else {
            return null;
        }
    }

    function getWeatherForecast(now) {
        if (externalWeather != null) {
            var trimmedExternalWeather = getTrimmedExtWeather(externalWeather, now);
            return trimmedExternalWeather;
        } else if (Toybox has :Weather) {
            return Weather.getHourlyForecast();
        } else {
            return null;
        }
    }

    function getCurrentWeatherFromExternal(weatherArray as Array<Dictionary>, now) {
        var currentTime = getCurrentUTCTimeString(now);
        for (var i = 0; i < weatherArray.size(); i++) {
             if (weatherArray[i]["time"].equals(currentTime)) {
                return weatherArray[i];
             }
        }
        
        return null;
    }

    function getTrimmedExtWeather(weatherArray as Array<Dictionary>, now) as Array {
        var currentTime = getCurrentUTCTimeString(now);
        var startIndex = null;
        for (var i = 0; i < weatherArray.size(); i++) {
             if (weatherArray[i]["time"].equals(currentTime)) {
                startIndex = i;
                break;
             }
        }
        if (startIndex != null) {
            return weatherArray.slice(startIndex + 1, null);
        }
        return weatherArray;
    }

    function getNewLocation() {
        var location = Activity.getActivityInfo().currentLocation;
        if (location == null) {
            location = Toybox.Position.getInfo().position;
            if (location == null && Toybox has :Weather) {
                var weatherConditions = Weather.getCurrentConditions();
                if (weatherConditions != null) {
                    location = weatherConditions.observationLocationPosition;
                }
            }
        }
        return location;
    }

    function isPositionChanged() as Boolean {
        var newLocation = getNewLocation().toGeoString(Position.GEO_DEG);
        if (newLocation != null && !newLocation.equals(lastSeenLocation)) {
            lastSeenLocation = newLocation;
            return true;
        }
        return false;
    }

    function triggerExternalWeather(now) {
        var needToregister = false;
        var lastExternalWeatherTime = Background.getLastTemporalEventTime();
        if (Toybox.System has :ServiceDelegate) {
            if (lastExternalWeatherTime != null) {
                if (now.compare(lastExternalWeatherTime) > 0) {
                    if (externalWeather != null) {
                        if ((isPositionChanged() && now.compare(lastExternalWeatherTime) > 5 * 60) || now.compare(lastExternalWeatherTime) > 60 * 60) {
                            needToregister = true;
                        }
                    } else {
                        if (now.compare(lastExternalWeatherTime) > 5 * 60) {
                            needToregister = true;
                        } 
                    }
                }
            } else {
                needToregister = true;
            }
            if (needToregister) {
                Background.registerForTemporalEvent(now);
            }
        }
    }

    function getWeatherIcon(condition, isDay) {
        var icon;
        switch (condition) {
            case 0: icon = isDay? ClearDayIcon : ClearNightIcon; break;
            case 1: icon = isDay? MostlyCloudyDayIcon : MostlyCloudyNightIcon; break;
            case 2: icon = CloudyIcon; break;
            case 3: icon = RainIcon; break;
            case 4: icon = SnowIcon; break;
            case 5: icon = WindIcon; break;
            case 6: icon = ThunderIcon; break;
            case 7: icon = SnowRainIcon; break;
            case 8: icon = MistIcon; break;
            case 9: icon = MistIcon; break;
            case 10: icon = HailIcon; break;
            case 11: icon = RainIcon; break;
            case 12: icon = ThunderIcon; break;
            case 13: icon = UnknownPrecipitationIcon; break;
            case 14: icon = LiteRainIcon; break;
            case 15: icon = RainIcon; break;
            case 16: icon = SnowIcon; break;
            case 17: icon = SnowIcon; break;
            case 18: icon = SnowRainIcon; break;
            case 19: icon = SnowRainIcon; break;
            case 20: icon = CloudyIcon; break;
            case 21: icon = SnowRainIcon; break;
            case 22: icon = isDay? MostlyCloudyDayIcon : MostlyCloudyNightIcon; break;
            case 23: icon = isDay? ClearDayIcon : ClearNightIcon; break;
            case 24: icon = LiteRainIcon; break;
            case 25: icon = RainIcon; break;
            case 26: icon = RainIcon; break;
            case 27: icon = LiteRainIcon; break;
            case 28: icon = ThunderIcon; break;
            case 29: icon = MistIcon; break;
            case 30: icon = MistIcon; break;
            case 31: icon = LiteRainIcon; break;
            case 32: icon = TornadoIcon; break;
            case 33: icon = MistIcon; break;
            case 34: icon = HailIcon; break;
            case 35: icon = WindIcon; break;
            case 36: icon = WindIcon; break;
            case 37: icon = TornadoIcon; break;
            case 38: icon = HailIcon; break;
            case 39: icon = MistIcon; break;
            case 40: icon = UnknownPrecipitationIcon; break;
            case 41: icon = TornadoIcon; break;
            case 42: icon = TornadoIcon; break;
            case 43: icon = SnowIcon; break;
            case 44: icon = SnowRainIcon; break;
            case 45: icon = LiteRainIcon; break;
            case 46: icon = SnowIcon; break;
            case 47: icon = SnowRainIcon; break;
            case 48: icon = SnowIcon; break;
            case 49: icon = SnowRainIcon; break;
            case 50: icon = SnowRainIcon; break;
            case 51: icon = HailIcon; break;
            case 52: icon = isDay? ClearDayIcon : ClearNightIcon; break;
            case 53: icon = UnknownPrecipitationIcon; break;
            default: icon = UnknownPrecipitationIcon;
        }
        return icon;
    }

    function getWMOWeatherIcon(weatherCode, isDay) {
        var icon;
        switch (weatherCode) {
            case 0: icon = isDay? ClearDayIcon : ClearNightIcon; break;
            case 1: icon = isDay? ClearDayIcon : ClearNightIcon; break;
            case 2: icon = isDay? MostlyCloudyDayIcon : MostlyCloudyNightIcon; break;
            case 3: icon = CloudyIcon; break;
            case 45: icon = MistIcon; break;
            case 48: icon = MistIcon; break;
            case 51: icon = LiteRainIcon; break;
            case 53: icon = LiteRainIcon; break;
            case 55: icon = RainIcon; break;
            case 56: icon = SnowRainIcon; break;
            case 57: icon = SnowRainIcon; break;
            case 61: icon = LiteRainIcon; break;
            case 63: icon = RainIcon; break;
            case 65: icon = RainIcon; break;
            case 66: icon = SnowRainIcon; break;
            case 67: icon = SnowRainIcon; break;
            case 71: icon = SnowIcon; break;
            case 73: icon = SnowIcon; break;
            case 75: icon = SnowIcon; break;
            case 77: icon = HailIcon; break;
            case 80: icon = LiteRainIcon; break;
            case 81: icon = RainIcon; break;
            case 82: icon = ThunderIcon; break;
            case 85: icon = SnowIcon; break;
            case 86: icon = SnowIcon; break;
            case 95: icon = ThunderIcon; break;
            case 96: icon = ThunderIcon; break;
            case 99: icon = HailIcon; break;
            default: icon = UnknownPrecipitationIcon;
        }
        return icon;
    }
}
