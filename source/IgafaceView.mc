import Toybox.Application;
import Toybox.Graphics;
import Toybox.Time.Gregorian;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.Weather;
import Toybox.Background;
import Toybox.Time;
import Toybox.Position;

class IgafaceView extends WatchUi.WatchFace {
    var screenHeight;
    var screenWidth;
    var timeFont;
    var timeThinFont;
    var dataFont;
    var accentColor;
    var textColor;
    var backgroundColor;
    var wasSleepMode;
    var isSleepMode;
    var isShiftingWeatherVisible;
    var isStaticWeatherVisible;
    var isStepsVisible;
    var isErrorVisible;
    var lastWeatherChangeSeconds;
    var nextForecastIndex;
    var iconSize;
    var previousScreenUpdateTime;
    var previousExtWeatherTriggerAttempt;
    var weatherPreviousUpdateTime;
    var internalWeatherConditions as CurrentConditions or Null;
    var internalHourlyForecast as Array<HourlyForecast> or Null;
    var externalHourlyForecast as Array<Dictionary> or Null;
    var cachedHourlyForecast as Array or Null;
    var currentExternalWeather as Dictionary or Null;
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
    var cachedWeatherTime;
    var cachedDetailedWeatherData;
    var cachedWeatherData;
    var requiresBurnInProtection;
    var isEvenMinuteTime;
    var isCityNameSupportedWithCustomFont;
    var isCityNameSupportedWithGarminFont;
    var toShowCityName;
    var externalForecastLocationGeoString as String or Null;
    var externalForecastLocation as Position.Location or Null;
    var precipitationInMilimeters;
    var useImperialFormat;

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
    var cachedDetailedWeatherIcon;
    var stepsIcon;

    const SUPPORTED_SYMBOLS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-?%/.,:° ms";
    const MONTHS = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"] as Array<String>;
    const DAYS_OF_WEEK = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"] as Array<String>;
    const FIVE_MINUTES = new Time.Duration(5 * 60);
    const ONE_HOUR = new Time.Duration(60 * 60);

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        screenHeight = dc.getHeight();
        screenWidth = dc.getWidth();
        timeThinFont = WatchUi.loadResource(Rez.Fonts.time_thin_font);
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
        cachedDetailedWeatherIcon = null;
        stepsIcon = WatchUi.loadResource(Rez.Drawables.StepsIcon);
        iconSize = screenWidth / 8;

        locator = new Locator();
        isSleepMode = false;
        isShiftingWeatherVisible = false;
        isStaticWeatherVisible = false;
        isStepsVisible = false;
        isErrorVisible = false;
        lastWeatherChangeSeconds = 0;
        nextForecastIndex = -1;
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
        cachedWeatherTime = null;
        cachedDetailedWeatherData = null;
        cachedWeatherData = null;
        isEvenMinuteTime = false;
        requiresBurnInProtection = System.getDeviceSettings().requiresBurnInProtection;
        isCityNameSupportedWithCustomFont = false;
        isCityNameSupportedWithGarminFont = false;
        toShowCityName = false;
        externalForecastLocationGeoString = null;
        externalForecastLocation = null;
        precipitationInMilimeters = 0;
        useImperialFormat = false;

        retrieveSavedWeather();
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
        isEvenMinuteTime = currentTime.min % 2;
        accentColor = requiresBurnInProtection && isSleepMode ? Graphics.COLOR_WHITE : Application.Properties.getValue("AccentColor");
        textColor = requiresBurnInProtection && isSleepMode ? Graphics.COLOR_WHITE : Application.Properties.getValue("TextColor");
        backgroundColor = requiresBurnInProtection && isSleepMode ? Graphics.COLOR_BLACK : Application.Properties.getValue("BackgroundColor");
        var isWeatherDefaultField = Application.Properties.getValue("LowPowerMode") == 0;
        var toShowSeconds = Application.Properties.getValue("ShowSecondsCircle");
        var toShowWeatherBg = Application.Properties.getValue("ShowWeatherBg");
        var dataOnWristTurn = Application.Properties.getValue("DataOnWristTurn");
        useImperialFormat = Application.Properties.getValue("UseImperialFormat");
        precipitationInMilimeters = Application.Properties.getValue("PrecipitationFormat") == 0;
        var showStaticDetailedWeather = dataOnWristTurn == 1;
        var showSwitchindDetailedForecast = dataOnWristTurn == 2;
        var switchingForecast = showStaticDetailedWeather || showSwitchindDetailedForecast;

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
                        currentWeatherSource = isExternalWeaherAvailable ? EXTERNAL : INTERNAL_HOURLY;
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
                switchAllVisibilitiesOff();
            }
            isStaticWeatherVisible = true;
        } else if (toShowShiftingWeather) {
            if (!isShiftingWeatherVisible) {
                switchAllVisibilitiesOff();
            }
            isShiftingWeatherVisible = true;
        } else if (toShowWeather) {
            if (!isErrorVisible) {
                switchAllVisibilitiesOff();
            }
            isErrorVisible = true;
        } else {
            if (!isStepsVisible) {
                switchAllVisibilitiesOff();
            }
            steps = getSteps();
            if (steps != null) {
                isStepsVisible = true;
            }
        }

        View.onUpdate(dc);
        dc.setColor(backgroundColor, backgroundColor);
        dc.clear();
        if (Dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        if (isStaticWeatherVisible) { 
            setWeatherInfo(getCurrentWeatherTemperature(currentWeatherSource));
        } else if (isShiftingWeatherVisible) {  
            if (showStaticDetailedWeather) {
                setDetailedWeatherInfo(currentWeatherSource);
            } else if (showSwitchindDetailedForecast) {
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
            }
            lastWeatherChangeSeconds = lastWeatherChangeSeconds == 1? 0 : lastWeatherChangeSeconds + 1;
        } else if (isStepsVisible) {
            drawSteps(dc, steps);
        } else if (isErrorVisible) {
            drawError(dc, "no weather data", getNoWeatherErrorText());
        }

        if (isStaticWeatherVisible) {
            drawWeatherInfo(dc, now, toShowWeatherBg);
        } else if (isShiftingWeatherVisible) {
             if (showStaticDetailedWeather) {
                cachedDetailedWeatherIcon = getCurrentWeatherIcon(currentWeatherSource, now);
            } else if (showSwitchindDetailedForecast) {
                if (nextForecastIndex == 0) {
                    cachedDetailedWeatherIcon = getCurrentWeatherIcon(currentWeatherSource, now);
                } else {
                    cachedDetailedWeatherIcon = getDetailedForecastIcon(cachedHourlyForecast[nextForecastIndex - 1], now);
                }
            }
            drawDetailedWeatherInfo(dc, toShowWeatherBg);
        } else if (isStepsVisible) {
            drawStepsIcon(dc);
        }

        if (!isSleepMode && toShowSeconds) {
            drawSeconds(dc, currentTime);
        }

        drawTime(dc, getTime(currentTime));
        drawDate(dc, getDateInfo(currentTime));
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
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
        isSleepMode = true;
    }

    function getNoWeatherErrorText() as String {
        if (System has :ServiceDelegate && !System.getDeviceSettings().connectionAvailable) {
            return "connect to garmin app";
        } else {
            return "run GPS activity";
        }
    }

    function retrieveSavedWeather() {
        var weatherData = Storage.getValue("igaface_weatherData");
        if (weatherData != null) {
            onExternalWeatherUpdated(weatherData);
        }
    }

    function onExternalWeatherUpdated(data) {
        if (data != null && data instanceof Dictionary) {
            Storage.setValue("igaface_weatherData", data);

            var forecast = data.get("forecast");
            addForecastTime(forecast);
            externalWeather = forecast;
            var locationDict = data.get("location");
            externalForecastLocation = new Position.Location({
                    :latitude => locationDict.get("lat"),
                    :longitude => locationDict.get("lon"),
                    :format => :degrees
                }
            );
            externalForecastLocationGeoString = Locator.locationToGeoString(externalForecastLocation);
            var cityName = data.get("locationName");
            externalCity = cityName != null ? cityName : "";
            isExternalWeatherUpdated = true;
        }
    }

    function addForecastTime(data as Array<Dictionary>) {
        for (var i = 0; i < data.size(); i++) {
            data[i].put("forecastTime", TimeUtil.parseTime(data[i].get("time").toString()));
        }
    }

    function isWeatherDataUpdated() as Boolean {
        return isExternalWeatherUpdated;
    }

    function switchAllVisibilitiesOff() {
        isShiftingWeatherVisible = false;
        isStaticWeatherVisible = false;
        isStepsVisible = false;
        isErrorVisible = false;
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
        var cx = screenWidth / 2 - 1;
        var cy = screenHeight / 2 - 1;
        var radius = screenWidth / 2 - (penWidth - 2);

        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        if (seconds > 0) {
            dc.setPenWidth(penWidth);
            dc.drawArc(cx, cy, radius, Graphics.ARC_CLOCKWISE, START_ARC_DEGREE, endDegree);
        }
    }

    function drawTime(dc as Dc, time as String) {
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        var font = requiresBurnInProtection && isSleepMode ? timeThinFont : timeFont;

        if (requiresBurnInProtection && isSleepMode && isEvenMinuteTime) {
            dc.drawText(screenWidth * 0.5, screenHeight * 0.62, font, time, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(screenWidth * 0.5, screenHeight * 0.20, font, time, Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function drawDate(dc as Dc, date as String) {
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);

        if (requiresBurnInProtection && isSleepMode && isEvenMinuteTime) {
            dc.drawText(screenWidth * 0.15, screenHeight * 0.43, dataFont, date, Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            dc.drawText(screenWidth * 0.85, screenHeight * 0.55, dataFont, date, Graphics.TEXT_JUSTIFY_RIGHT);
        }
    }

    function drawSteps(dc as Dc, stepsNumber as String) {
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth * 0.5, screenHeight * 0.8, dataFont, stepsNumber, Graphics.TEXT_JUSTIFY_LEFT);
    }

    function drawError(dc as Dc, tittle as String, errorBody as String) {
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth * 0.5, screenHeight * 0.7, Graphics.FONT_XTINY, tittle, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(screenWidth * 0.5, screenHeight * 0.78, Graphics.FONT_XTINY, errorBody, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawDetailedWeatherInfo(dc as Dc, drawBackground as Boolean) {
        if (cachedDetailedWeatherIcon != null)  {
            drawDetailedWeatherIcon(dc, cachedDetailedWeatherIcon, drawBackground);
        }
        if (cachedWeatherTime != null && !cachedWeatherTime.equals("")) {
            drawDetailedWeatherTime(dc, cachedWeatherTime);
        }
        if (cachedDetailedWeatherData != null && !cachedDetailedWeatherData.equals("")) {
            drawDetailedWeatherData(dc, cachedDetailedWeatherData);
        }
    }

    function drawWeatherInfo(dc as Dc, now as Time.Moment, drawBackground as Boolean) {
        drawWeatherIcon(dc, now, drawBackground);
        if (cachedWeatherData != null && !cachedWeatherData.equals("")) {
            drawWeatherData(dc, cachedWeatherData);
        }
    }

    function drawDetailedWeatherTime(dc as Dc, weatherTime as String) {
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        var font = toShowCityName && !isCityNameSupportedWithCustomFont ? Graphics.FONT_XTINY : dataFont;
        dc.drawText(screenWidth * 0.5, screenHeight * 0.7, font, weatherTime, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawDetailedWeatherData(dc as Dc, weatherData as String) {
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(screenWidth * 0.5, screenHeight * 0.78, dataFont, weatherData, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawWeatherData(dc as Dc, weatherData as String) {
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);

        if (requiresBurnInProtection && isSleepMode) {
            if (isEvenMinuteTime) {
                dc.drawText(screenWidth * 0.5, screenHeight * 0.10, dataFont, weatherData, Graphics.TEXT_JUSTIFY_RIGHT);
            } else {
                dc.drawText(screenWidth * 0.5, screenHeight * 0.90, dataFont, weatherData, Graphics.TEXT_JUSTIFY_RIGHT);
            }
        } else {
            dc.drawText(screenWidth * 0.5, screenHeight * 0.80, dataFont, weatherData, Graphics.TEXT_JUSTIFY_RIGHT);
        }
    }

    function drawWeatherIcon(dc as Dc, now as Time.Moment, drawBackground as Boolean) {
        var weatherIcon = getCurrentWeatherIcon(currentWeatherSource, now);
        if (weatherIcon != null) {
            var iconXPos = screenWidth * 0.5 + iconSize / 8;

            if (requiresBurnInProtection && isSleepMode) {
                if (isEvenMinuteTime) {
                    var iconYPos = screenHeight * 0.1 - iconSize / 4;
                    dc.drawBitmap(iconXPos, iconYPos, weatherIcon);
                } else {
                    var iconYPos = screenHeight * 0.9 - iconSize / 4;
                    dc.drawBitmap(iconXPos, iconYPos, weatherIcon);
                }
            } else {
                var iconYPos = screenHeight * 0.8 - iconSize / 4;
                if (drawBackground) {
                    drawWeatherBackgroundCircle(dc, iconXPos + iconSize / 2, iconYPos + iconSize / 2);
                }
                dc.drawBitmap(iconXPos, iconYPos, weatherIcon);
            }
        }
    }

    function drawDetailedWeatherIcon(dc as Dc, weatherIcon as Graphics.BitmapType, drawBackground as Boolean) {
        if (drawBackground) {
            drawWeatherBackgroundCircle(dc, screenWidth * 0.5, screenHeight * 0.85 + iconSize / 2);
        }
        dc.drawBitmap(screenWidth * 0.5 - iconSize / 2, screenHeight * 0.85, weatherIcon);
    }

    function drawWeatherBackgroundCircle(dc as Dc, xPos as Number, yPos as Number) {
        var radius = iconSize / 2;
        dc.setColor(getWeatherBgColor(), Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(xPos, yPos, radius);
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawCircle(xPos, yPos, radius);
    }

    function drawStepsIcon(dc) {
        dc.drawBitmap(screenWidth * 0.5 - iconSize, screenHeight * 0.8 - iconSize / 8, stepsIcon);
    }

    function drawBatteryStatus(dc as Dc) {
        var batteryPercentage = System.getSystemStats().battery;
        var cx;
        var cy;
        if (requiresBurnInProtection && isSleepMode && isEvenMinuteTime) {
            cx = screenWidth  * 0.15;
            cy = screenHeight * 0.545;
        } else {
            cx = screenWidth / 2 - 1;
            cy = screenHeight / 2 - 1;
        }
        var lineLength = screenWidth * 0.85 - screenWidth / 2;
        var penWidth = 4;
        dc.setPenWidth(penWidth / 2);
        dc.setColor(getBatteryBgColor(), Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, cy + penWidth / 4, cx + lineLength, cy + penWidth / 4);
        dc.setPenWidth(penWidth);
        dc.setColor(accentColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, cy, cx + lineLength * batteryPercentage / 100, cy);
    }

    function setWeatherInfo(temperature) {
        var weatherInfo = temperature != null ? getTemperatureWithUnits(temperature) : null;
        if (weatherInfo != null) {
            cachedWeatherData = weatherInfo;
        }
    }

    function setDetailedWeatherInfo(currentSource) {
        var locationName = getCurrentLocationName(currentSource);
        cachedWeatherTime = locationName == null || locationName.length() == 0 || !isCityNameSupportedWithGarminFont ? "NOW" : locationName;
        var forecast = null;
        if (currentSource == INTERNAL_CONDITION) {
            forecast = internalWeatherConditions;
        } else if (currentSource == INTERNAL_HOURLY) {
            forecast = internalHourlyForecast[0];
        } else if (currentSource == EXTERNAL) {
            forecast = currentExternalWeather;
        } else {
            cachedDetailedWeatherData = "NO DATA";
            return;
        }
        var weatherInfo = Lang.format("$1$ $2$ $3$", [getTemperature(forecast), getWind(forecast), getPrecipitationInfo(forecast)]);
        toShowCityName = !cachedWeatherTime.equals("NOW");
        cachedDetailedWeatherData = weatherInfo;
    }

    function setDetailedForecastInfo(forecast) {
        cachedWeatherTime = getTime(Gregorian.info(getWeatherTime(forecast), Time.FORMAT_SHORT));
        var weatherInfo = Lang.format("$1$ $2$ $3$", [getTemperature(forecast), getWind(forecast), getPrecipitationInfo(forecast)]);
        toShowCityName = false;
        cachedDetailedWeatherData = weatherInfo;
    }

    function isCurrentInternalWeatherAvailable(internalWeatherConditions, now) {
        return internalWeatherConditions != null && isWeatherConditionAvailable(internalWeatherConditions) && isCurrentTemperatureAvailable(internalWeatherConditions, now);
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

    function triggerExternalWeather(now) {
        var minorDistanceChangeMeters = 200;
        var newLocation = null;

        if (System has :ServiceDelegate && System.getDeviceSettings().connectionAvailable) {
            var needToRegister = false;
            var lastExternalWeatherTime = Background.getLastTemporalEventTime();
            if (lastExternalWeatherTime != null) {
                var elapsedTime = now.compare(lastExternalWeatherTime);
                if (elapsedTime > 5 * 60) {
                    if (externalWeather != null) {
                        newLocation = locator.getNewLocation();
                        if (newLocation != null) {
                            var isLocationChanged = !Locator.locationToGeoString(newLocation).equals(externalForecastLocationGeoString);
                            var isLocChangeSignificant = false; // by default
                            if (isLocationChanged) {
                                isLocChangeSignificant = Locator.calculateDistance(newLocation, externalForecastLocation) > minorDistanceChangeMeters;
                            }
                            if (isLocChangeSignificant || elapsedTime > 60 * 60) {
                                needToRegister = true;
                            }
                        }
                    } else {
                        needToRegister = true;
                    }
                }
            } else {
                needToRegister = true;
            }

            if (needToRegister && (newLocation != null || locator.getNewLocation() != null)) {
                Background.registerForTemporalEvent(now);
            }
        }
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

    function getDetailedForecastIcon(forecast, now) as Graphics.BitmapType {
        var weatherIcon = null;

        var isInternalForecast = Toybox has :Weather && forecast instanceof HourlyForecast;
        if (isInternalForecast) {
            var condition = forecast.condition;
            var isDay = isDayTime(internalWeatherConditions, getWeatherTime(forecast));
            if (isDay != null) {
                weatherIcon = getWeatherIcon(condition, isDay);
            }
        } else if (forecast instanceof Dictionary) {
            var weatherCode = forecast["weatherCode"];
            var isDay = forecast["isDay"];
            if (weatherCode != null && isDay != null) {
                weatherIcon = getWMOWeatherIcon(weatherCode, isDay);
            }
        }

        return weatherIcon;
    }

    function getTemperature(hourlyForecast as HourlyForecast or CurrentConditions or Object) {
        return getTemperatureWithUnits(getWeatherTemperature(hourlyForecast));
    }

    function getTemperatureWithUnits(temperature as Number) {
        if (useImperialFormat) {
            return Lang.format("$1$°", [((temperature * (9.0 / 5)) + 32).toNumber()]);
        } else {
            return Lang.format("$1$°", [temperature]);
        }
    }

    function getWind(hourlyForecast as HourlyForecast or CurrentConditions) {
        if (useImperialFormat) {
            return Lang.format("$1$mph", [(getWeatherWindSpeed(hourlyForecast) * 2.237).format("%d")]);
        } else {
            return Lang.format("$1$m/s", [getWeatherWindSpeed(hourlyForecast).format("%d")]);
        }
    }

    function getSteps() {
        return Lang.format("$1$", [ActivityMonitor.getInfo().steps]);
    }

    function getWeatherBgColor() {
        switch (backgroundColor) {
            case 0xFFAA00: return 0x550000; // orange
            case 0xFF0000: return 0x550000; // red
            case 0xff0099: return 0x550000; // pink
            case 0xAA00FF: return 0x550000; // purple
            case 0x00AAFF: return 0x000055; // blue
            case 0x00ffff: return 0x000055; // aqua
            case 0x00AA00: return 0x005500; // green
            case 0x55FF00: return 0x555500; // lime
            case 0xffff00: return 0x555500; // yellow
            case 0xffffff: return 0x555555; // white
            case 0xAAAAAA: return 0x555555; // grey
            case 0x000000: return 0x000000; // black
            default: return 0x000000;
        }
    }

    function getBatteryBgColor() {
        if (isDarkColor(backgroundColor)) {
            if (accentColor == Graphics.COLOR_LT_GRAY) {
                return 0x555555;
            } else {
                return 0xAAAAAA;
            }
        } else {
            return 0x555555;
        }
    }

    function isDarkColor(color) {
        switch (color) {
            case 0xFFAA00: return false; // orange
            case 0xFF0000: return true; // red
            case 0xff0099: return true; // pink
            case 0xAA00FF: return true; // purple
            case 0x00AAFF: return false; // blue
            case 0x00ffff: return false; // aqua
            case 0x00AA00: return true; // green
            case 0x55FF00: return false; // lime
            case 0xffff00: return false; // yellow
            case 0xffffff: return false; // white
            case 0xAAAAAA: return false; // grey
            case 0x000000: return true; // black
            default: return false;
        }
    }

    function getCurrentLocationName(currentSource) {
        var locationName = null;
        var isInternalSource = (currentSource == INTERNAL_CONDITION || currentSource == INTERNAL_HOURLY) && isWeatherConditionAvailable(internalWeatherConditions);
        if (isInternalSource) {
            if (externalCity != null && !externalCity.equals("")) {
                locationName = getFormatedExternalCityName(externalCity);
            } else {
                locationName = getFormatedCityName(internalWeatherConditions.observationLocationName);
            }

        } else if (currentSource == EXTERNAL) {
            locationName = externalCity != null && !externalCity.equals("") ? getFormatedExternalCityName(externalCity) : null;
        }

        return locationName;
    }

    function getFormatedCityName(locationName) {
        var cityName = null;
        if (locationName != null) {
            if (locationName.equals(previousObservationLocationName)) {
                cityName = cachedCityName;
            } else {
                previousObservationLocationName = locationName;
                var lengthLimit = 17;
                var commaIndex = locationName.find(",");
                if (commaIndex != null) {
                    if (commaIndex >= lengthLimit) {
                        cityName = locationName.substring(0, lengthLimit - 2).toUpper() + "...";
                    } else {
                        cityName = locationName.substring(0, commaIndex).toUpper();
                    }
                }
                cachedCityName = cityName;
                isCityNameSupportedWithCustomFont = isSupportedWithCustomFontString(cityName);
                isCityNameSupportedWithGarminFont = isSupportedWithGarminFontString(cityName);
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
                cityName = locationName.toUpper();
                
                var lengthLimit = 17;
                if (cityName.length() > lengthLimit) {
                    cityName = cityName.substring(0, lengthLimit - 2) + "...";
                }
                previousObservationLocationName = locationName;
                cachedCityName = cityName;
                isCityNameSupportedWithCustomFont = isSupportedWithCustomFontString(cityName);
                isCityNameSupportedWithGarminFont = isSupportedWithGarminFontString(cityName);
            }
        }
        return cityName;
    }

    function isSupportedWithCustomFontString(stringToCheck) {
        if (stringToCheck == null) {
            return true;
        }
        var stringToCheckArray = stringToCheck.toCharArray() as Array;
        for (var i = 0; i < stringToCheckArray.size(); i++) {
            var isSupported = SUPPORTED_SYMBOLS.find(stringToCheckArray[i].toString()) != null;
            if (!isSupported) {
                return false;
            }
        }
        return true;
    }

    function isSupportedWithGarminFontString(stringToCheck) {
        if (stringToCheck == null) {
            return true;
        }
        var stringToCheckArray = stringToCheck.toCharArray() as Array;
        for (var i = 0; i < stringToCheckArray.size(); i++) {
            var charCode = stringToCheckArray[i].toNumber();
            var isSupported = (charCode > 31 && charCode < 127) || (charCode > 159 && charCode < 382) || (charCode > 899 && charCode < 939) || (charCode > 1024 && charCode < 1072);
            if (!isSupported) {
                return false;
            }
        }
        return true;
    }

    function getCurrentWeatherIcon(currentSource, now) as Graphics.BitmapType {
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

    function getWeatherTime(weather as Dictionary or CurrentConditions or HourlyForecast) {
        if (Toybox has :Weather && weather instanceof CurrentConditions) {
            return weather.observationTime;
        } else if (Toybox has :Weather && weather instanceof HourlyForecast) {
            return weather.forecastTime;
        } else if (weather instanceof Dictionary){
            return weather["forecastTime"];
        }
        return null;
    }

    function getPrecipitationInfo(weather as Dictionary or HourlyForecast or CurrentConditions) {
        if (Toybox has :Weather && (weather instanceof CurrentConditions || weather instanceof HourlyForecast)) {
            return Lang.format("$1$%", [weather.precipitationChance]);
        } else if (weather instanceof Dictionary) {
            if (precipitationInMilimeters) {
                var precipitation = weather["precipitation"].format("%.1f");
                var precipLength = precipitation.length();
                var canBeDecimal = precipitation.substring(precipLength - 1, precipLength).equals("0");
                return Lang.format("$1$mm", [canBeDecimal ? precipitation.substring(0, precipLength - 2) : precipitation]);
            } else {
                return Lang.format("$1$%", [weather["precipitationChance"]]);
            }
        }
        return null;
    }

    function getWeatherWindSpeed(weather as Dictionary or HourlyForecast or CurrentConditions) {
        if (Toybox has :Weather && weather instanceof CurrentConditions) {
            return weather.windSpeed;
        } else if (Toybox has :Weather && weather instanceof HourlyForecast) {
            return weather.windSpeed;
        } else if (weather instanceof Dictionary) {
            return weather["windSpeed"];
        }
        return null;
    }

    function getCurrentWeatherTemperature(currentSource) {
        if (currentSource == INTERNAL_CONDITION) {
            return Math.round(internalWeatherConditions.temperature).toNumber();
        } else if (currentSource == INTERNAL_HOURLY) {
            return Math.round(internalHourlyForecast[0].temperature).toNumber();
        } else if (currentSource == EXTERNAL) {
            return currentExternalWeather["temperature"];
        } else {
            return null;
        }
    }

    function getWeatherTemperature(weather as Dictionary or HourlyForecast or CurrentConditions) {
        if (Toybox has :Weather && (weather instanceof CurrentConditions || weather instanceof HourlyForecast)) {
            return Math.round(weather.temperature).toNumber();
        } else if (weather instanceof Dictionary) {
            return weather["temperature"];
        }
        return null;
    }

    function getWeatherCondition(weather as Dictionary or HourlyForecast or CurrentConditions) as Number or Null {
        if (Toybox has :Weather && (weather instanceof CurrentConditions || weather instanceof HourlyForecast)) {
            return weather.condition;
        } else if (weather instanceof Dictionary) {
            return weather["weatherCode"].toNumber();
        }
        return null;
    }

    function getCurrentInternalWeather(now) {
        if (Toybox has :Weather) {
            return Weather.getCurrentConditions();
        } else {
            return null;
        }
    }
    function getCurrentExternalWeather(currentTime) as Dictionary or Null {
        if (externalHourlyForecast != null && externalHourlyForecast.size() > 1) {    
            return {
                "time" => currentTime.min < 30 ? externalHourlyForecast[0]["time"] : externalHourlyForecast[1]["time"],
                "forecastTime" => currentTime.min < 30 ? externalHourlyForecast[0]["forecastTime"] : externalHourlyForecast[1]["forecastTime"],
                "isDay" => currentTime.min < 30 ? externalHourlyForecast[0]["isDay"] : externalHourlyForecast[1]["isDay"],
                "weatherCode" => currentTime.min < 30 ? externalHourlyForecast[0]["weatherCode"] : externalHourlyForecast[1]["weatherCode"],
                "temperature" => Math.round(calculateCurrentTimeExternalWeatherParam(externalHourlyForecast, "temperature",  currentTime.min)).toNumber(),
                "precipitation" => calculateCurrentTimeExternalWeatherParam(externalHourlyForecast, "precipitation",  currentTime.min),
                "precipitationChance" => calculateCurrentTimeExternalWeatherParam(externalHourlyForecast, "precipitationChance",  currentTime.min).toNumber(),
                "windSpeed" => Math.round(calculateCurrentTimeExternalWeatherParam(externalHourlyForecast, "windSpeed",  currentTime.min)).toNumber()
            };
        } else {
            return null;
        }
    }

    function calculateCurrentTimeExternalWeatherParam(weatherForecast as Array<Dictionary>, weatherParam as String, currentMins as Number) as Float{
        var currentMinsInHours = currentMins / 60.0;
        return weatherForecast[0][weatherParam] + currentMinsInHours * (weatherForecast[1][weatherParam] - weatherForecast[0][weatherParam]);
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
}
