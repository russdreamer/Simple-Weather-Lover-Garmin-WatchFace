import Toybox.Application;
import Toybox.Graphics;
import Toybox.Time.Gregorian;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
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
    var externalCityUpdateTime;
    var previousScreenUpdateTime;
    var previousExtWeatherTriggerAttempt;
    var weatherPreviousUpdateTime;
    var internalWeatherConditions as Toybox.Weather.CurrentConditions or Null;
    var internalHourlyForecast as Array<Toybox.Weather.HourlyForecast> or Null;
    var externalHourlyForecast as Array or Null;
    var cachedHourlyForecast as Array or Null;
    var currentExternalWeather;
    var isStaticWeatherAvailable;
    var isShiftingWeatherAvailable;
    var previousObservationLocationName;
    var cachedCityName;
    var externalCity;
    var externalWeather;
    var locator;
    var currentWeatherSource;
    var isExternalWeatherUpdated;
    var previousHourVal;

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

        locator = new Locator();
        isSleepMode = false;
        isShiftingWeatherVisible = false;
        isStaticWeatherVisible = false;
        isStepsVisible = false;
        lastWeatherChangeSeconds = 0;
        nextForecastIndex = -1;
        externalCityUpdateTime = null;
        previousScreenUpdateTime = null;
        previousExtWeatherTriggerAttempt = null;
        weatherPreviousUpdateTime = null;
        internalWeatherConditions = null;
        internalHourlyForecast = null;
        externalHourlyForecast = null;
        cachedHourlyForecast = null;
        currentExternalWeather = null;
        isStaticWeatherAvailable = false;
        isShiftingWeatherAvailable = false;
        previousObservationLocationName = null;
        cachedCityName = null;
        externalCity = null;
        externalWeather = null;
        currentWeatherSource = NONE;
        isExternalWeatherUpdated = false;
        previousHourVal = null;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var now = Time.now();

        var needScreenUpdate = previousScreenUpdateTime == null || now.compare(previousScreenUpdateTime) != 0 || isSleepMode;
        if (!needScreenUpdate) {
            return;
        }
        previousScreenUpdateTime = now;

        var currentTime = Gregorian.info(now, Time.FORMAT_SHORT);
        accentColor = Application.Properties.getValue("AccentColor");
        var switchingForecast = Application.Properties.getValue("SwitchForecast");
        var isWeatherDefaultField = Application.Properties.getValue("LowPowerMode") == 0;

        timeLabel.setText(getTime(currentTime));
        dateLabel.setText(getDateInfo(currentTime));

        var steps = null;
        var toShowStaticWeather = false;
        var toShowShiftingWeather = false;

        var toShowWeather = isWeatherDefaultField || !isSleepMode && switchingForecast;
        if (toShowWeather) {
            if (previousExtWeatherTriggerAttempt == null || now.compare(previousExtWeatherTriggerAttempt).abs() > 3) {
                previousExtWeatherTriggerAttempt = now;
                triggerExternalWeather(now);
            }

            var isNewHour = isHourChanged(currentTime);
            var isNoWeatherSnown = externalHourlyForecast == null && internalHourlyForecast == null && internalWeatherConditions == null && cachedHourlyForecast == null;
            var needWeatherUpdate = isNoWeatherSnown || weatherPreviousUpdateTime == null || now.compare(weatherPreviousUpdateTime).abs() > 60 || isNewHour || isWeatherDataUpdated();
            
            if (needWeatherUpdate) {
                var needRefreshExternalForecast = isNewHour || isWeatherDataUpdated();
                if (needRefreshExternalForecast) {
                    isExternalWeatherUpdated = false;
                    externalHourlyForecast = getExternalWeatherForecast();
                }
                if (externalHourlyForecast == null) {
                    internalHourlyForecast = getInternalWeatherForecast(now);
                    cachedHourlyForecast = internalHourlyForecast;
                } else {
                    internalHourlyForecast = null;
                    cachedHourlyForecast = externalHourlyForecast.slice(1, null);
                }
                internalWeatherConditions = getCurrentInternalWeather(now);
            }

            var isInternalWeaherAvailable = internalHourlyForecast != null || internalWeatherConditions != null;
            var isExternalWeaherAvailable = externalHourlyForecast != null;

            // update once per minute if the weather is available
            if (needWeatherUpdate) {
                printLog("inside needWeatherUpdate block");
                weatherPreviousUpdateTime = now;
                if (isInternalWeaherAvailable || isExternalWeaherAvailable) {
                    var isCurrentInternalWeatherAvailable = isInternalWeaherAvailable && isCurrentInternalWeatherAvailable(internalWeatherConditions, now);
                    var isObservationPosAvailable = isInternalWeaherAvailable && isObservationPosAvailable(internalWeatherConditions);
                    
                    isShiftingWeatherAvailable = isExternalWeaherAvailable || (isObservationPosAvailable && internalHourlyForecast != null);
                    isStaticWeatherAvailable = isShiftingWeatherAvailable || isCurrentInternalWeatherAvailable;

                    if (!isShiftingWeatherAvailable)  {
                        currentWeatherSource = INTERNAL_CONDITION;
                    } else {
                        currentExternalWeather = getCurrentExternalWeather(currentTime);
                        if (internalWeatherConditions != null) {
                            var hourlyTime = isExternalWeaherAvailable ? getWeatherTime(currentExternalWeather) : getWeatherTime(internalHourlyForecast[0]);
                            if (now.compare(hourlyTime).abs() <= now.compare(getWeatherTime(internalWeatherConditions)).abs()) {
                                currentWeatherSource = isExternalWeaherAvailable ? EXTERNAL : INTERNAL_HOURLY;
                            } else {
                                currentWeatherSource = INTERNAL_CONDITION;
                            }
                        } else {
                            currentWeatherSource = isExternalWeaherAvailable ? EXTERNAL : INTERNAL_HOURLY;
                        }
                    }
                } else {
                    currentWeatherSource = NONE;
                    isShiftingWeatherAvailable = false;
                    isStaticWeatherAvailable = false;
                }
            }

            toShowStaticWeather = isStaticWeatherAvailable && isWeatherDefaultField && (isSleepMode || (!isSleepMode && !switchingForecast));
            toShowShiftingWeather = isShiftingWeatherAvailable && !isSleepMode && switchingForecast;
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
            setWeatherInfo(getCurrentWeatherTemperature(currentWeatherSource));
        } else if (isShiftingWeatherVisible) {            
            if (lastWeatherChangeSeconds == 0) {
                nextForecastIndex = nextForecastIndex == 4? 0 : nextForecastIndex + 1;

                if (cachedHourlyForecast.size() - 1 < nextForecastIndex) {
                    nextForecastIndex = 0;
                }

                if (nextForecastIndex == 0) {
                    setDetailedWeatherInfo(currentWeatherSource);
                } else {
                    setDetailedForecastInfo(cachedHourlyForecast[nextForecastIndex - 1]);
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
            drawWeatherIcon(currentWeatherSource, now, dc);
        } else if (isShiftingWeatherVisible) {
            if (nextForecastIndex == 0) {
                drawDetailedWeatherIcon(currentWeatherSource, now, dc);
            } else {
                drawDetailedForecastIcon(cachedHourlyForecast[nextForecastIndex - 1], now, dc);
            }
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

    function onExternalWeatherUpdated(data) {
        printLog("onExternalWeatherUpdated method");
        if (data != null && data instanceof Array) {
            externalWeather = processBackgroundData(data);
            isExternalWeatherUpdated = true;
        }
    }

    function onExternalCityUpdated(data) {
        printLog("onExternalCityUpdated method");
        if (data != null && data instanceof String) {
            externalCity = getFormatedExternalCityName(data);
            externalCityUpdateTime = Time.now();
        }
    }

    function processBackgroundData(data as Array<Dictionary>) as Array<Dictionary> {
        for (var i = 0; i < data.size(); i++) {
            data[i].put("forecastTime", TimeUtil.parseTime(data[i].get("time").toString()));
        }
        return data;
    }

    function isWeatherDataUpdated() as Boolean {
        return isExternalWeatherUpdated;
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

    function isHourChanged(currentTime) {
        var isChanged = currentTime.hour != previousHourVal;
        previousHourVal = currentTime.hour;
        return isChanged;
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

    function getTemperature(hourlyForecast as Toybox.Weather.HourlyForecast or Toybox.Weather.CurrentConditions or Object) {
        return Lang.format("$1$°", [getWeatherTemperature(hourlyForecast)]);
    }

    function getWind(hourlyForecast as Toybox.Weather.HourlyForecast or Toybox.Weather.CurrentConditions) {
        return Lang.format("$1$m/s", [getWeatherWindSpeed(hourlyForecast).format("%d")]);
    }

    function getSteps() {
        return Lang.format("$1$", [ActivityMonitor.getInfo().steps]);
    }

    function setDetailedWeatherInfo(currentSource) {
        var locationName = getCurrentLocationName(currentSource);
        weatherTimeLabel.setText(locationName == null || locationName.length() == 0 ? "NOW" : locationName);
        var forecast = null;
        if (currentSource == INTERNAL_CONDITION) {
            forecast = internalWeatherConditions;
        } else if (currentSource == INTERNAL_HOURLY) {
            forecast = internalHourlyForecast[0];
        } else if (currentSource == EXTERNAL) {
            forecast = currentExternalWeather;
        } else {
            detailedWeatherLabel.setText("NO DATA");
            return;
        }
        var weatherInfo = Lang.format("$1$ $2$ $3$", [getTemperature(forecast), getWind(forecast), getPrecipitationInfo(forecast)]);
        detailedWeatherLabel.setText(weatherInfo);
    }

    function setDetailedForecastInfo(forecast) {
        var forecastTime = getTime(Gregorian.info(getWeatherTime(forecast), Time.FORMAT_SHORT));
        weatherTimeLabel.setText(forecastTime);
        var weatherInfo = Lang.format("$1$ $2$ $3$", [getTemperature(forecast), getWind(forecast), getPrecipitationInfo(forecast)]);
        detailedWeatherLabel.setText(weatherInfo);
    }

    function getCurrentLocationName(currentSource) {
        var locationName = null;
        var isInternalSource = (currentSource == INTERNAL_CONDITION || currentSource == INTERNAL_HOURLY) && isWeatherConditionAvailable(internalWeatherConditions);
        if (isInternalSource) {
            var isExternalCityActual = externalCityUpdateTime != null && externalCityUpdateTime.compare(internalWeatherConditions.observationTime) >= 0;
            if (isExternalCityActual && externalCity != null && externalCity != "") {
                return externalCity;
            }
            locationName = internalWeatherConditions.observationLocationName;
        } else if (currentSource == EXTERNAL) {
            return externalCity != "" ? externalCity : null;
        }

        var cityName = getFormatedCityName(locationName);
        if (cityName != null) {
            cachedCityName = cityName;
        }
        return cityName;
    }

    function getFormatedCityName(locationName) {
        var cityName = null;
        if (locationName != null) {
            if (locationName.equals(previousObservationLocationName)) {
                cityName = cachedCityName;
            } else {
                printLog("getFormatedCityName method non-cached case");
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
        return cityName;
    }

    function getFormatedExternalCityName(locationName) {
        var cityName = null;
        if (locationName != null) {
            if (locationName.equals(previousObservationLocationName)) {
                cityName = cachedCityName;
            } else {
                printLog("getFormatedExternalCityName method non-cached case");
                previousObservationLocationName = locationName;
                var lengthLimit = 18;
                cityName = locationName.substring(null, lengthLimit).toUpper();
                cityName = getSupportedString(cityName);
            }
        }
        return cityName;
    }

    function getSupportedString(stringToTransform) {
        printLog("getSupportedString method");
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

    function setWeatherInfo(temperature) {
        var weatherInfo = temperature != null ? Lang.format("$1$°", [temperature]) : null;
        if (weatherInfo != null) {
            weatherLabel.setText(weatherInfo);
        }
    }

    function getCurrentWeatherIcon(currentSource, now) {
        var weatherIcon = null;
         var isInternalSource = (currentSource == INTERNAL_CONDITION || currentSource == INTERNAL_HOURLY) && isWeatherConditionAvailable(internalWeatherConditions);
        
        if (isInternalSource) {
            var condition = INTERNAL_CONDITION ? internalWeatherConditions.condition : internalHourlyForecast[0].condition;
            var isDay = isDayTime(internalWeatherConditions, now);
            if (isDay != null) {
                weatherIcon = getWeatherIcon(condition, isDay);
            }
        } else if (currentSource == EXTERNAL) {
            var weatherCode = currentExternalWeather["weatherCode"];
            var isDay = currentExternalWeather["isDay"];
            if (weatherCode != null && isDay != null) {
                weatherIcon = getWMOWeatherIcon(weatherCode, isDay);
            }
        }
        return weatherIcon;
    }

    function drawDetailedForecastIcon(forecast, now, dc) {
        var weatherIcon = null;

        var isInternalForecast = Toybox has :Weather && forecast instanceof Toybox.Weather.HourlyForecast;
        if (isInternalForecast) {
            var condition = forecast.condition;
            var isDay = isDayTime(internalWeatherConditions, getWeatherTime(forecast));
            if (isDay != null) {
                weatherIcon = getWeatherIcon(condition, isDay);
            }
        } else {
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

    function drawDetailedWeatherIcon(currentSource, now, dc) {
        var weatherIcon = getCurrentWeatherIcon(currentSource, now);
        if (weatherIcon != null) {
            dc.drawBitmap(dc.getWidth() * 0.5 - iconSize / 2, dc.getHeight() * 0.85, weatherIcon);
        }
    }

    function drawWeatherIcon(currentSource, now, dc) {
        var weatherIcon = getCurrentWeatherIcon(currentSource, now);
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

    function getPrecipitationInfo(weather as Toybox.Weather.HourlyForecast or Toybox.Weather.CurrentConditions) {
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

    function getCurrentWeatherTemperature(currentSource) {
        if (currentSource == INTERNAL_CONDITION) {
            return internalWeatherConditions.temperature;
        } else if (currentSource == INTERNAL_HOURLY) {
            return internalHourlyForecast[0].temperature;
        } else if (currentSource == EXTERNAL) {
            return currentExternalWeather["temperature"];
        } else {
            return null;
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

    function isCurrentInternalWeatherAvailable(internalWeatherConditions, now) {
        return isWeatherConditionAvailable(internalWeatherConditions) && isCurrentTemperatureAvailable(internalWeatherConditions, now);
    }

    function isWeatherConditionAvailable(internalWeatherConditions) {
        return internalWeatherConditions.condition != null;
    }

    function isObservationPosAvailable(weatherConditions) {
        if (weatherConditions == null) {
            return false;
        } else if (Toybox has :Weather) {
            return weatherConditions.observationLocationPosition != null;
        }
        return false;
    }

    function isCurrentTemperatureAvailable(weatherConditions, now) {
        var isCurrentConditionExpired = weatherConditions == null  || now.compare(weatherConditions.observationTime) >= 3600 || now.compare(weatherConditions.observationTime) < -1800;
        return !isCurrentConditionExpired && weatherConditions.temperature != null;
    }

    function getCurrentInternalWeather(now) {
        if (Toybox has :Weather) {
            return Weather.getCurrentConditions();
        } else {
            return null;
        }
    }
    function getCurrentExternalWeather(currentTime) {
        if (externalHourlyForecast != null && externalHourlyForecast.size() > 1) {
            if (currentTime.min < 30) {
                return externalHourlyForecast[0];
            } else {
                return externalHourlyForecast[1];
            }
        } else {
            return null;
        }
    }

    function getInternalWeatherForecast(now) {
        if (Toybox has :Weather) {
            return Weather.getHourlyForecast();
        } else {
            return null;
        }
    }

    function getExternalWeatherForecast() {
        if (externalWeather != null) {
            var trimmedWeather = getTrimmedExtWeather(externalWeather);
            return trimmedWeather != null && trimmedWeather.size() > 1 ? trimmedWeather : null;
        } else {
            return null;
        }
    }

    function getTrimmedExtWeather(weatherArray as Array<Dictionary>) as Array or Null {
        printLog("getTrimmedExtWeather method");
        var currentTime = TimeUtil.getCurrentUTCTimeString();
        var startIndex = null;
        for (var i = 0; i < weatherArray.size(); i++) {
             if (weatherArray[i]["time"].equals(currentTime)) {
                startIndex = i;
                break;
             }
        }
        if (startIndex != null) {
            return weatherArray.slice(startIndex, null);
        }
        return null;
    }

    function triggerExternalWeather(now) {
        if (Toybox.System has :ServiceDelegate) {
            var needToRegister = false;
            var lastExternalWeatherTime = Background.getLastTemporalEventTime();

            if (lastExternalWeatherTime != null) {
                var elapsedTime = now.compare(lastExternalWeatherTime);
                if (elapsedTime > 5 * 60) {
                    if (externalWeather != null) {
                        if (locator.updatePositionIfChanged() || elapsedTime > 60 * 60) {
                            needToRegister = true;
                        }
                    } else {
                        needToRegister = true;
                    }
                }
            } else {
                needToRegister = true;
            }

            if (needToRegister && locator.getNewLocation() != null) {
                printLog("Background.registerForTemporalEvent method");
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

    enum {
        NONE,
        INTERNAL_CONDITION,
        INTERNAL_HOURLY,
        EXTERNAL
    }

    function printLog(text as String) {
        System.println(TimeUtil.getCurrentTimeString() + ": " + text);
    }
}
