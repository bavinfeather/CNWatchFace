using Toybox.ActivityMonitor;
using Toybox.Activity;
using Toybox.Application;
using Toybox.Complications;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Position;
using Toybox.SensorHistory;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.UserProfile;
using Toybox.WatchUi;
using Toybox.Weather;

class CNWatchFaceView extends WatchUi.WatchFace {
    const FIELD_HIDDEN = 0;
    const FIELD_STEPS = 1;
    const FIELD_FLOORS = 2;
    const FIELD_CALORIES = 3;
    const FIELD_DISTANCE = 4;
    const FIELD_BATTERY = 5;
    const FIELD_STRESS = 6;
    const FIELD_HEART = 7;
    const FIELD_BODY_BATTERY = 8;
    const FIELD_SECONDS = 9;
    const FIELD_DATE = 10;
    const FIELD_WEEKDAY = 11;
    const FIELD_TEMPERATURE = 12;
    const FIELD_RECOVERY = 13;
    const FIELD_ACTIVE_MINUTES = 14;
    const FIELD_STEP_GOAL = 15;
    const FIELD_SUNRISE = 16;
    const FIELD_SUNSET = 17;
    const FIELD_RESTING_HR = 18;
    const FIELD_ELEVATION = 19;
    const FIELD_PRESSURE = 20;
    const FIELD_SPO2 = 21;
    const FIELD_LUNAR = 22;
    const FIELD_TOTAL_CALORIES = 23;
    const FIELD_RESTING_CALORIES = 24;
    const FIELD_FLOORS_DESCENDED = 25;
    const FIELD_ACTIVE_MINUTES_WEEK = 26;
    const FIELD_ACTIVE_MINUTES_WEEK_GOAL = 28;
    const FIELD_BATTERY_DAYS = 29;
    const FIELD_HUMIDITY = 30;
    const FIELD_VO2MAX_RUNNING = 31;
    const FIELD_SOLAR_INTENSITY = 32;
    const FIELD_MONTHLY_RUNNING_DISTANCE = 33;
    const FIELD_WEEK_NUMBER = 34;
    const FIELD_NOTIFICATION_COUNT = 35;
    const FIELD_HIGH_TEMPERATURE = 36;
    const FIELD_LOW_TEMPERATURE = 37;
    const FIELD_PRECIPITATION_CHANCE = 38;
    const FIELD_DAY_NIGHT = 39;
    const FIELD_DAYLIGHT_REMAINING = 40;
    const FIELD_HEART_RATE_ZONE = 41;
    const FIELD_SOLAR_TERM = 43;
    const FIELD_AVG_RESTING_HR = 45;
    const FIELD_ALARM_COUNT = 48;
    const FIELD_RESPIRATION_RATE = 49;
    const FIELD_WEATHER_CONDITION = 50;
    const FIELD_NEXT_SUN_EVENT = 51;
    const FIELD_MONTHLY_CYCLING_DISTANCE = 52;
    const FIELD_LOCATION_NAME = 53;
    const FIELD_DAILY_RUNNING_DISTANCE = 54;
    const FIELD_WEEKLY_RUNNING_DISTANCE = 55;
    const FIELD_YEARLY_RUNNING_DISTANCE = 56;
    const FIELD_DAILY_CYCLING_DISTANCE = 57;
    const FIELD_WEEKLY_CYCLING_DISTANCE = 58;
    const FIELD_YEARLY_CYCLING_DISTANCE = 59;
    const FIELD_SLEEP_SCORE = 79;
    const FIELD_UV_INDEX = 73;

    const COMPLICATION_TYPE_SLEEP_SCORE = 42;

    const DISTANCE_PERIOD_DAY = 0;
    const DISTANCE_PERIOD_WEEK = 1;
    const DISTANCE_PERIOD_MONTH = 2;
    const DISTANCE_PERIOD_YEAR = 3;

    const RING_BATTERY = 0;
    const RING_BODY_BATTERY = 1;
    const RING_STRESS = 2;

    const TREND_HEART = 0;
    const TREND_ELEVATION = 1;
    const TREND_STRESS = 2;
    const TREND_BODY_BATTERY = 3;
    const TREND_PRESSURE = 4;
    const TREND_SPO2 = 5;
    const TREND_TEMPERATURE = 6;

    const TREND_STYLE_LINE = 0;
    const TREND_STYLE_BARS = 1;

    const WX_HIDDEN = 0;
    const WX_TEMP = 1;
    const WX_WIND = 2;
    const WX_HIGH_LOW = 3;
    const WX_CONDITION = 4;
    const WX_PRECIP = 5;
    const WX_FEELS = 6;

    const WEATHER_CACHE_SECONDS = 900;
    const WEATHER_RETRY_SECONDS = 60;
    const WEATHER_STORAGE_KEY = "CNWatchFaceWeather";
    const BODY_BATTERY_STORAGE_KEY = "CNWatchFaceBodyBattery";
    const TREND_CACHE_SECONDS = 300;
    const PROFILE_CACHE_SECONDS = 21600;
    const SLEEP_SCORE_CACHE_SECONDS = 129600;
    const STRESS_CACHE_SECONDS = 600;
    const RECOVERY_COMPLETE_CACHE_SECONDS = 3600;
    const TEMPERATURE_DEGREE_MARKER = "^";

    // --- Color palette & default constants (single source of truth) ---
    // properties.xml and settings.xml must stay in lock-step with these.
    // Update all three together when adding a default.
    const COLOR_BLACK        = 0x000000;
    const COLOR_NAVY_DEEP    = 0x000055;     // 85
    const COLOR_NIGHT_NAVY   = 0x1A2A4A;     // 1714762
    const COLOR_DARK_GREEN   = 0x005500;     // 21760
    const COLOR_DARK_RED     = 0x550000;     // 5570560
    const COLOR_WARM_WHITE   = 0xF5E6D3;     // 16115411
    const COLOR_WHITE        = 0xFFFFFF;     // 16777215
    const COLOR_CORAL        = 0xFF6633;     // 16737843
    const COLOR_ORANGE       = 0xFF5500;     // 16733440
    const COLOR_YELLOW       = 0xFFFF00;     // 16776960
    const COLOR_CYAN         = 0x00FFFF;     // 65535
    const COLOR_SOFT_GRAY    = 0xC7CBCB;
    const COLOR_LIGHT_GRAY   = 0xAAAAAA;     // 11184810
    const COLOR_SUNSET       = 0xA63E32;     // 10894898
    const COLOR_FAR_BLUE     = 0x4A6A7A;     // 4876922
    const COLOR_MID_SLATE    = 0x243747;     // 2373447
    const COLOR_NEAR_INK     = 0x152532;     // 1385778

    // Shared days-per-month table (non-leap).  Allocated once and reused by
    // dayOfYear() and lunarDate() so onUpdate never allocates it per frame.
    const MONTH_DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

    private var _lowPower = false;
    private var _aodRenderer = null;
    private var _width = 260;
    private var _height = 260;
    private var _cx = 130;
    // Screen-family layout profile. Fonts and slot spacing are selected once
    // in onLayout; actual text bounds are still measured on the target device.
    private var _profileTimeFont = Graphics.FONT_NUMBER_MEDIUM;
    private var _profileSideFont = Graphics.FONT_XTINY;
    private var _profileTopFieldY = 44;
    private var _profileTimeCenterY = 86;
    private var _profileSideGap = 3;
    private var _profileSideLineGap = 2;
    private var _profileCalendarCenterY = 130;
    private var _profileCalendarFontSize = 15;
    private var _profileCalendarFallbackFont = Graphics.FONT_XTINY;
    private var _profileVectorTimeScale = 0.30;
    private var _profileExpandVectorTime = false;
    private var _profileVectorSideGap = 0;
    private var _profileVectorCalendarOffset = 0;
    private var _profileTimeInset = 4;
    private var _profileCalendarInset = 14;
    private var _profileTrendGap = 3;
    private var _timeVectorFont = null;
    private var _timeVectorFontChecked = false;
    private var _timeVectorFontKey = -1;
    private var _degreeFont = null;
    private var _degreeFontHeight = -1;
    private var _smallFieldFont = null;
    private var _topLabelFont = null;
    private var _topLabelFontChecked = false;
    private var _topLabelFontChoice = -1;
    private var _topLabelFontText = "";
    private var _iconCache as Lang.Dictionary = {};
    private var _iconCacheOrder as Lang.Array = [];
    private var _lunarFont = null;
    private var _lunarFontChecked = false;
    private var _lunarFontKey = -1;
    private var _lunarDateCacheDay = -1;
    private var _lunarDateChinese = null;
    private var _lunarDateEnglish = null;
    private var _sunDiagnostic = -1;
    // AOD cache: filled during the regular onUpdate path.
    private var _cachedHeartRate = null;
    private var _cachedBatteryPercent = 0;
    private var _batteryKnown = false;
    // Per-minute cache: seconds must not trigger a complete set of data
    // requests every second.
    private var _dataMinute = -1;
    private var _wakeFramePending = false;
    private var _cachedActivityInfo = null;
    private var _cachedActivity = null;
    private var _cachedConditions = null;
    private var _nearFadeColors = null;
    private var _nearFadeColor = -1;
    private var _nearFadeHeight = -1;
    private var _cachedLocationName = "--";
    private var _cachedWeatherTemperature = null;
    private var _weatherStorageLoaded = false;
    private var _storedWeatherSnapshot = null;
    private var _weatherCacheTick = -1;
    private var _weatherNextAttemptSeconds = 0;
    private var _cachedStats = null;
    private var _cachedProfile = null;
    private var _cachedHeartRateZones = null;
    private var _profileCacheTick = -1;
    private var _cachedDeviceSettings = null;
    private var _cachedBodyBattery = null;
    private var _bodyBatteryCached = false;
    private var _bodyBatteryStorageLoaded = false;
    private var _cachedSleepScore = null;
    private var _sleepScoreCached = false;
    private var _sleepScoreCacheDay = -1;
    private var _sleepScoreUpdatedSeconds = 0;
    private var _cachedElevation = null;
    private var _elevationCached = false;
    private var _cachedPressure = null;
    private var _pressureCached = false;
    private var _cachedSpo2 = null;
    private var _spo2Cached = false;
    private var _cachedStress = null;
    private var _stressCached = false;
    private var _stressUpdatedSeconds = 0;
    private var _cachedRecoveryEndSeconds = null;
    private var _recoveryCached = false;
    private var _recoveryUpdatedSeconds = 0;
    private var _cachedSensorTemp = null;
    private var _sensorTempCached = false;
    private var _cachedRestingHeartRate = null;
    private var _restingHeartRateCached = false;
    private var _activityCacheDay = -1;
    private var _sunCacheTick = -1;
    private var _sunWeatherTick = -1;
    private var _sunLocation as Lang.Array or Null = null;
    private var _cachedSunrise = null;
    private var _cachedSunset = null;
    private var _sunriseCached = false;
    private var _sunsetCached = false;
    private var _heartHistoryCache = null;
    private var _heartRateCached = false;
    private var _trendCacheTick = -1;
    private var _trendCacheMode = -1;
    private var _trendCacheValues = null;
    private var _trendCurrentCacheMode = -1;
    private var _trendCurrentCached = false;
    private var _trendCurrentCache = null;
    // Activity history is comparatively expensive. Recompute all running and
    // cycling period totals together at most once per hour.
    private var _activityDistanceCacheKey = -1;
    private var _activityDistanceCacheDay = -1;
    private var _runningDistances as Lang.Array or Null = null;
    private var _cyclingDistances as Lang.Array or Null = null;
    // Chinese lunar-calendar data for 1900–2100.  Keeping this table local
    // makes the calendar available without a phone connection or web request.
    private var _lunarYears as Lang.Array = [
        0x04bd8,0x04ae0,0x0a570,0x054d5,0x0d260,0x0d950,0x16554,0x056a0,0x09ad0,0x055d2,
        0x04ae0,0x0a5b6,0x0a4d0,0x0d250,0x1d255,0x0b540,0x0d6a0,0x0ada2,0x095b0,0x14977,
        0x04970,0x0a4b0,0x0b4b5,0x06a50,0x06d40,0x1ab54,0x02b60,0x09570,0x052f2,0x04970,
        0x06566,0x0d4a0,0x0ea50,0x06e95,0x05ad0,0x02b60,0x186e3,0x092e0,0x1c8d7,0x0c950,
        0x0d4a0,0x1d8a6,0x0b550,0x056a0,0x1a5b4,0x025d0,0x092d0,0x0d2b2,0x0a950,0x0b557,
        0x06ca0,0x0b550,0x15355,0x04da0,0x0a5b0,0x14573,0x052b0,0x0a9a8,0x0e950,0x06aa0,
        0x0aea6,0x0ab50,0x04b60,0x0aae4,0x0a570,0x05260,0x0f263,0x0d950,0x05b57,0x056a0,
        0x096d0,0x04dd5,0x04ad0,0x0a4d0,0x0d4d4,0x0d250,0x0d558,0x0b540,0x0b5a0,0x195a6,
        0x095b0,0x049b0,0x0a974,0x0a4b0,0x0b27a,0x06a50,0x06d40,0x0af46,0x0ab60,0x09570,
        0x04af5,0x04970,0x064b0,0x074a3,0x0ea50,0x06b58,0x05ac0,0x0ab60,0x096d5,0x092e0,
        0x0c960,0x0d954,0x0d4a0,0x0da50,0x07552,0x056a0,0x0abb7,0x025d0,0x092d0,0x0cab5,
        0x0a950,0x0b4a0,0x0baa4,0x0ad50,0x055d9,0x04ba0,0x0a5b0,0x15176,0x052b0,0x0a930,
        0x07954,0x06aa0,0x0ad50,0x05b52,0x04b60,0x0a6e6,0x0a4e0,0x0d260,0x0ea65,0x0d530,
        0x05aa0,0x076a3,0x096d0,0x04afb,0x04ad0,0x0a4d0,0x1d0b6,0x0d250,0x0d520,0x0dd45,
        0x0b5a0,0x056d0,0x055b2,0x049b0,0x0a577,0x0a4b0,0x0aa50,0x1b255,0x06d20,0x0ada0,
        0x14b63,0x09370,0x049f8,0x04970,0x064b0,0x168a6,0x0ea50,0x06aa0,0x1a6c4,0x0aae0,
        0x0a2e0,0x0d2e3,0x0c960,0x0d557,0x0d4a0,0x0da50,0x05d55,0x056a0,0x0a6d0,0x055d4,
        0x052d0,0x0a9b8,0x0a950,0x0b4a0,0x0b6a6,0x0ad50,0x055a0,0x0aba4,0x0a5b0,0x052b0,
        0x0b273,0x06930,0x07337,0x06aa0,0x0ad50,0x14b55,0x04b60,0x0a570,0x054e4,0x0d160,
        0x0e968,0x0d520,0x0daa0,0x06aa6,0x056d0,0x04ae0,0x0a9d4,0x0a2d0,0x0d150,0x0f252,
        0x0d520
    ];

    function initialize() {
        WatchFace.initialize();
    }

    private function numberProperty(key as Lang.String, fallback as Lang.Number) as Lang.Number {
        var value = Application.Properties.getValue(key);
        return value instanceof Lang.Number ? value : fallback;
    }

    private function isFahrenheit() as Lang.Boolean {
        return numberProperty("TemperatureUnit", 0) == 1;
    }

    // Garmin sensor and weather APIs provide temperatures in Celsius. Keep all
    // cached values in that canonical unit and convert only at the display
    // boundary so changing the setting never corrupts persisted weather data.
    private function temperatureForDisplay(celsius) {
        if (celsius == null) { return null; }
        var value = celsius.toFloat();
        return isFahrenheit() ? (value * 9.0 / 5.0) + 32.0 : value;
    }

    private function temperatureUnitSuffix() as Lang.String {
        // The degree marker is rendered with the app's bundled bitmap font.
        // Several device-localized FONT_XTINY variants omit U+00B0.
        return TEMPERATURE_DEGREE_MARKER + (isFahrenheit() ? "F" : "C");
    }

    private function formatTemperature(celsius) as Lang.String {
        var value = temperatureForDisplay(celsius);
        return value == null ? "--" : value.format("%.0f") + temperatureUnitSuffix();
    }

    private function formatTemperatureRange(high, low) as Lang.String {
        var highValue = temperatureForDisplay(high);
        var lowValue = temperatureForDisplay(low);
        if (highValue == null && lowValue == null) { return "--~--"; }
        var highText = highValue == null ? "--" : highValue.format("%.0f");
        var lowText = lowValue == null ? "--" : lowValue.format("%.0f");
        return highText + "~" + lowText + temperatureUnitSuffix();
    }

    private function degreeFont(dc as Graphics.Dc) {
        var fontHeight = dc.getFontHeight(Graphics.FONT_XTINY);
        if (_degreeFont != null && _degreeFontHeight == fontHeight) { return _degreeFont; }
        var resourceId = Rez.Fonts.Degree20;
        if (fontHeight <= 17) { resourceId = Rez.Fonts.Degree16; }
        else if (fontHeight <= 23) { resourceId = Rez.Fonts.Degree20; }
        else if (fontHeight <= 29) { resourceId = Rez.Fonts.Degree28; }
        else { resourceId = Rez.Fonts.Degree34; }
        _degreeFont = WatchUi.loadResource(resourceId);
        _degreeFontHeight = fontHeight;
        return _degreeFont;
    }

    // Cache one shared font for active data rows; AOD keeps its renderer.
    private function smallFieldFont(dc as Graphics.Dc) {
        var fallback = isAmoledLayout() ? Graphics.FONT_XTINY : Graphics.FONT_TINY;
        if (!(Graphics has :getVectorFont)) { return fallback; }
        if (_smallFieldFont == null) {
            try {
                _smallFieldFont = Graphics.getVectorFont({
                    :face => "NotoSansSCMedium",
                    :size => isAmoledLayout() ?
                        (dc.getFontHeight(Graphics.FONT_XTINY) * 0.95).toNumber() : scalePx(16)
                });
            } catch (e) { _smallFieldFont = null; }
            if (_smallFieldFont == null) { _smallFieldFont = fallback; }
        }
        return _smallFieldFont != null ? _smallFieldFont : fallback;
    }


    private function temperatureTextWidth(dc as Graphics.Dc, value as Lang.String) as Lang.Number {
        var font = smallFieldFont(dc);
        if (_smallFieldFont != null && _smallFieldFont != Graphics.FONT_XTINY && _smallFieldFont != Graphics.FONT_TINY) {
            var degreeMarker = value.find(TEMPERATURE_DEGREE_MARKER);
            var smoothValue = degreeMarker == null ? value :
                value.substring(0, degreeMarker) + "°" + value.substring(degreeMarker + 1, value.length());
            return dc.getTextWidthInPixels(smoothValue, font);
        }
        var marker = value.find(TEMPERATURE_DEGREE_MARKER);
        if (marker == null) { return dc.getTextWidthInPixels(value, font); }
        var prefix = value.substring(0, marker);
        var suffix = value.substring(marker + 1, value.length());
        var degree = degreeFont(dc);
        return dc.getTextWidthInPixels(prefix, font) +
               dc.getTextWidthInPixels(TEMPERATURE_DEGREE_MARKER, degree) +
               dc.getTextWidthInPixels(suffix, font);
    }

    private function drawTemperatureText(dc as Graphics.Dc, x as Lang.Number, y as Lang.Number,
                                         value as Lang.String, justification as Lang.Number) as Void {
        var font = smallFieldFont(dc);
        if (_smallFieldFont != null && _smallFieldFont != Graphics.FONT_XTINY && _smallFieldFont != Graphics.FONT_TINY) {
            var degreeMarker = value.find(TEMPERATURE_DEGREE_MARKER);
            var smoothValue = degreeMarker == null ? value :
                value.substring(0, degreeMarker) + "°" + value.substring(degreeMarker + 1, value.length());
            dc.drawText(x, y, font, smoothValue, justification);
            return;
        }
        var marker = value.find(TEMPERATURE_DEGREE_MARKER);
        if (marker == null) {
            dc.drawText(x, y, font, value, justification);
            return;
        }
        var prefix = value.substring(0, marker);
        var suffix = value.substring(marker + 1, value.length());
        var degree = degreeFont(dc);
        dc.drawText(x, y, font, prefix, justification);
        var degreeX = x + dc.getTextWidthInPixels(prefix, font);
        dc.drawText(degreeX, y, degree, TEMPERATURE_DEGREE_MARKER, justification);
        var suffixX = degreeX + dc.getTextWidthInPixels(TEMPERATURE_DEGREE_MARKER, degree);
        dc.drawText(suffixX, y, font, suffix, justification);
    }

    private function fieldProperty(key as Lang.String, fallback as Lang.Number) as Lang.Number {
        var value = numberProperty(key, fallback);
        // Values retained by an older installation fall back to the slot's
        // normal default after their selector entries are removed.
        if (value == FIELD_SLEEP_SCORE && !supportsSleepScore()) { return fallback; }
        if (value == 27 || value == 42 || value == 44 || value == 46 || value == 47) {
            return fallback;
        }
        return value;
    }

    private function stringProperty(key as Lang.String, fallback as Lang.String) as Lang.String {
        var value = Application.Properties.getValue(key);
        return value instanceof Lang.String ? value : fallback;
    }

    private function text(resourceId as Lang.ResourceId) as Lang.String {
        return WatchUi.loadResource(resourceId) as Lang.String;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        _cx = _width / 2;
        loadLayoutProfile();
        _timeVectorFont = null;
        _timeVectorFontChecked = false;
        _timeVectorFontKey = -1;
        _degreeFont = null;
        _degreeFontHeight = -1;
        _smallFieldFont = null;
        _topLabelFont = null;
        _topLabelFontChecked = false;
        _iconCache = {};
        _iconCacheOrder = [];
        _lunarFont = null;
        _lunarFontChecked = false;
        _lunarFontKey = -1;
    }

    function onEnterSleep() as Void {
        _lowPower = true;
    }

    function onExitSleep() as Void {
        _lowPower = false;
        if (isAmoledLayout()) {
            // Reuse valid data for the first bright frame. A due refresh runs
            // on the next regular callback, without delaying wake-up drawing.
            _wakeFramePending = true;
        } else {
            _dataMinute = -1;
            _heartHistoryCache = null;
            _heartRateCached = false;
            _trendCurrentCached = false;
        }
        WatchUi.requestUpdate();
    }

    // When the user changes settings, drop the cached vector font so the
    // next onUpdate re-loads it with the current size, and force a redraw.
    function onSettingsChanged() as Void {
        _topLabelFont = null;
        _topLabelFontChecked = false;
        _iconCache = {};
        _iconCacheOrder = [];
        _timeVectorFont = null;
        _timeVectorFontChecked = false;
        _timeVectorFontKey = -1;
        _lunarFont = null;
        _lunarFontChecked = false;
        _lunarFontKey = -1;
        _dataMinute = -1;
        _bodyBatteryCached = false;
        _sleepScoreCached = false;
        _elevationCached = false;
        _pressureCached = false;
        _spo2Cached = false;
        _stressCached = false;
        _recoveryCached = false;
        _sensorTempCached = false;
        _restingHeartRateCached = false;
        _heartHistoryCache = null;
        _heartRateCached = false;
        _trendCacheTick = -1;
        _trendCacheMode = -1;
        _trendCacheValues = null;
        _trendCurrentCacheMode = -1;
        _trendCurrentCached = false;
        _trendCurrentCache = null;
        WatchUi.requestUpdate();
    }

    private function y(ratio as Lang.Float) as Lang.Number {
        return (_height * ratio).toNumber();
    }

    private function x(ratio as Lang.Float) as Lang.Number {
        return (_width * ratio).toNumber();
    }

    private function isRound280Layout() as Lang.Boolean {
        return _width >= 275 && _width <= 285;
    }

    // MIP layouts are designed per screen family.  The 280 px family keeps
    // the 280 px geometry as its own baseline instead of enlarging the 260 px
    // layout, leaving the extra diameter available for field spacing.
    private function scalePx(value as Lang.Number) as Lang.Number {
        var designWidth = isRound280Layout() ? 280.0 : 260.0;
        var scaled = ((value * _width / designWidth) + 0.5).toNumber();
        return scaled < 1 ? 1 : scaled;
    }

    private function isAmoledLayout() as Lang.Boolean {
        // Every AMOLED product enabled by this project is a round display of
        // 360 px or larger; all enabled MIP products are 260 px or smaller.
        return _width >= 350;
    }

    private function displayColor(color as Lang.Number) as Lang.Number {
        if (isAmoledLayout()) { return color; }
        if (color == COLOR_WARM_WHITE) { return 0xFFFFAA; }
        if (color == COLOR_SOFT_GRAY) { return COLOR_LIGHT_GRAY; }
        if (color == COLOR_CORAL || color == COLOR_ORANGE) { return 0xFF5500; }
        // Segment34mkII keeps these soft AMOLED tones vivid on RGB222 MIP.
        if (color == 0xFBCB77) { return 0xFFFF00; }
        if (color == 0x89EFD2) { return 0x00FFFF; }
        if (color == 0x96E0AC) { return 0x00FF00; }
        if (color == 0xFF9161) { return 0xFF5500; }
        if (color == 0x3DA855) { return 0x55AA55; }
        if (color == 0xFFCC33) { return 0xFFAA00; }
        var r = quantizeRgb222Channel((color >> 16) & 0xFF);
        var g = quantizeRgb222Channel((color >> 8) & 0xFF);
        var b = quantizeRgb222Channel(color & 0xFF);
        return (r << 16) | (g << 8) | b;
    }

    // Landscape colors are deliberately mapped by depth, not merely by their
    // nearest RGB222 value. This keeps muted red skies and the three mountain
    // planes readable on MIP screens.
    private function displayLandscapeColor(color as Lang.Number, layer as Lang.Number) as Lang.Number {
        if (isAmoledLayout()) { return color; }
        if (layer == 0) {
            if (color == COLOR_SUNSET || color == 0xA63E32 || color == 0xC45A3C) { return 0xAA5555; }
            if (color == 0x3A2A4A) { return 0x5555AA; }
            if (color == 0x1A2A4A) { return COLOR_NAVY_DEEP; }
            if (color == 0x1E1E1A) { return 0x005555; }
        } else if (layer == 1) {
            if (color == COLOR_FAR_BLUE || color == 0x4A6A7A) { return 0x55AAAA; }
            if (color == 0x304A5A) { return 0x0055AA; }
            if (color == 0x507258) { return 0x55AA55; }
            if (color == 0x6A4242) { return 0xAA5555; }
        } else if (layer == 2) {
            if (color == COLOR_MID_SLATE || color == 0x243747 || color == 0x304A5A) { return 0x0055AA; }
            if (color == 0x223344) { return 0x005555; }
            if (color == 0x4A1018) { return COLOR_DARK_RED; }
        } else {
            if (color == COLOR_NEAR_INK || color == 0x152532) { return COLOR_NAVY_DEEP; }
            if (color == 0x101510) { return COLOR_DARK_GREEN; }
            if (color == 0x261226) { return 0x550055; }
        }
        return displayColor(color);
    }

    private function quantizeRgb222Channel(channel as Lang.Number) as Lang.Number {
        if (channel < 0x2B) { return 0x00; }
        if (channel < 0x80) { return 0x55; }
        if (channel < 0xD5) { return 0xAA; }
        return 0xFF;
    }

    // Jungle keeps exactly one annotated profile in each modern-device PRG.
    // The renderer below owns no device-specific coordinates; each compiled
    // profile supplies visual row anchors and the renderer enforces measured
    // horizontal and vertical bounds inside those slots.
    (:Round240)
    private function loadLayoutProfile() as Void {
        _profileTimeFont = Graphics.FONT_NUMBER_HOT;
        _profileSideFont = Graphics.FONT_TINY;
        _profileTopFieldY = y(0.16);
        _profileTimeCenterY = y(0.34);
        _profileSideGap = 3;
        _profileSideLineGap = 1;
        _profileCalendarCenterY = y(0.50);
        _profileCalendarFontSize = 22;
        _profileVectorTimeScale = 0.36;
        _profileExpandVectorTime = true;
        _profileVectorSideGap = scalePx(12);
        _profileVectorCalendarOffset = scalePx(6);
        _profileTimeInset = 4;
        _profileCalendarInset = 4;
        _profileTrendGap = 2;
    }

    (:Round260)
    private function loadLayoutProfile() as Void {
        _profileTimeFont = Graphics.FONT_NUMBER_HOT;
        _profileSideFont = Graphics.FONT_TINY;
        _profileTopFieldY = y(0.16);
        _profileTimeCenterY = y(0.34);
        _profileSideGap = 3;
        _profileSideLineGap = 1;
        _profileCalendarCenterY = y(0.50);
        _profileCalendarFontSize = 24;
        _profileCalendarFallbackFont = Graphics.FONT_TINY;
        _profileVectorTimeScale = 0.36;
        _profileExpandVectorTime = true;
        _profileVectorSideGap = scalePx(12) + 3;
        _profileVectorCalendarOffset = scalePx(6);
        _profileTimeInset = 4;
        _profileCalendarInset = 4;
        _profileTrendGap = 3;
    }

    (:Round280)
    private function loadLayoutProfile() as Void {
        _profileTimeFont = Graphics.FONT_NUMBER_HOT;
        _profileSideFont = Graphics.FONT_TINY;
        _profileTopFieldY = y(0.16);
        _profileTimeCenterY = y(0.34);
        _profileSideGap = 4;
        _profileSideLineGap = 1;
        _profileCalendarCenterY = y(0.50);
        _profileCalendarFontSize = 26;
        _profileVectorCalendarOffset = -scalePx(4);
        _profileTimeInset = 4;
        _profileCalendarInset = 4;
        _profileTrendGap = 3;
    }

    (:Round390)
    private function loadLayoutProfile() as Void {
        _profileTimeFont = Graphics.FONT_NUMBER_HOT;
        _profileSideFont = Graphics.FONT_TINY;
        _profileTopFieldY = y(0.16);
        _profileTimeCenterY = y(0.34);
        _profileSideGap = 5;
        _profileSideLineGap = 4;
        _profileCalendarCenterY = y(0.50);
        _profileVectorCalendarOffset = -scalePx(4);
        _profileTimeInset = 12;
        _profileCalendarInset = 20;
        _profileTrendGap = 2;
        _profileCalendarFontSize = 34;
    }

    (:Round416)
    private function loadLayoutProfile() as Void {
        _profileTimeFont = Graphics.FONT_NUMBER_HOT;
        _profileSideFont = Graphics.FONT_TINY;
        _profileTopFieldY = y(0.16);
        _profileTimeCenterY = y(0.34);
        _profileSideGap = 5;
        _profileSideLineGap = 4;
        _profileCalendarCenterY = y(0.50);
        _profileCalendarFontSize = 44;
        _profileVectorTimeScale = 0.36;
        _profileExpandVectorTime = true;
        _profileVectorSideGap = scalePx(12) + 4;
        _profileVectorCalendarOffset = 0;
        _profileTimeInset = 12;
        _profileCalendarInset = 20;
        _profileTrendGap = 2;
    }

    (:Round454)
    private function loadLayoutProfile() as Void {
        _profileTimeFont = Graphics.FONT_NUMBER_HOT;
        _profileSideFont = Graphics.FONT_TINY;
        _profileTopFieldY = y(0.16);
        _profileTimeCenterY = y(0.34);
        _profileSideGap = 5;
        _profileSideLineGap = 4;
        _profileCalendarCenterY = y(0.50);
        _profileCalendarFontSize = 39;
        _profileVectorTimeScale = 0.36;
        _profileExpandVectorTime = true;
        _profileVectorSideGap = scalePx(12) + 5;
        _profileVectorCalendarOffset = scalePx(6);
        _profileTimeInset = 14;
        _profileCalendarInset = 20;
        _profileTrendGap = 2;
    }

    // Width of the round screen at a particular Y coordinate, minus a safe
    // inset on both sides. Calendar gaps are clamped to this slot width.
    private function roundContentWidthAt(yPos as Lang.Number, inset as Lang.Number) as Lang.Number {
        var diameter = _width < _height ? _width : _height;
        var radius = diameter / 2.0;
        var dy = yPos - (_height / 2.0);
        var squared = radius * radius - dy * dy;
        if (squared <= 0) { return 0; }
        var available = (Math.sqrt(squared) * 2).toNumber() - inset * 2;
        return available > 0 ? available : 0;
    }

    // A system font name does not imply the same pixel box on every device.
    // Test the complete time group against its row slot, then select the
    // largest system-number tier that fits. The top-field profile reserves the
    // separate vertical space needed by the selected number font.
    private function timeFontFits(dc as Graphics.Dc, font, worstTimeText as Lang.String,
                                  reserveSide as Lang.Boolean,
                                  extraSideGap as Lang.Number) as Lang.Boolean {
        var timeWidth = dc.getTextWidthInPixels(worstTimeText, font);
        var sideWidth = dc.getTextWidthInPixels("59", _profileSideFont);
        var pmWidth = dc.getTextWidthInPixels("PM", _profileSideFont);
        if (pmWidth > sideWidth) { sideWidth = pmWidth; }
        var componentWidth = timeWidth +
                             (reserveSide ? _profileSideGap + extraSideGap + sideWidth : 0);

        return componentWidth <= roundContentWidthAt(_profileTimeCenterY, _profileTimeInset);
    }

    private function fittedTimeFont(dc as Graphics.Dc, worstTimeText as Lang.String,
                                    reserveSide as Lang.Boolean) {
        var vectorFont = fittedVectorTimeFont(dc, worstTimeText, reserveSide);
        if (vectorFont != null) { return vectorFont; }
        if (timeFontFits(dc, _profileTimeFont, worstTimeText, reserveSide, 0)) {
            return _profileTimeFont;
        }
        if (_profileTimeFont == Graphics.FONT_NUMBER_HOT &&
            timeFontFits(dc, Graphics.FONT_NUMBER_MEDIUM, worstTimeText, reserveSide, 0)) {
            return Graphics.FONT_NUMBER_MEDIUM;
        }
        return Graphics.FONT_NUMBER_MILD;
    }

    // Vector fonts are present only on newer devices. Older devices keep the
    // existing system-number fonts even when the setting selects a vector style.
    private function fittedVectorTimeFont(dc as Graphics.Dc, worstTimeText as Lang.String,
                                          reserveSide as Lang.Boolean) {
        var style = numberProperty("TimeFont", 1);
        if (!(Graphics has :getVectorFont)) { return null; }
        if (style < 1 || style > 6) { style = 1; }

        var textKey = worstTimeText == "12:59" ? 1 : 0;
        var cacheKey = style * 100000 + _width * 10 + (reserveSide ? 1 : 0) + textKey;
        if (_timeVectorFontChecked && _timeVectorFontKey == cacheKey) {
            return _timeVectorFont;
        }

        _timeVectorFontChecked = true;
        _timeVectorFontKey = cacheKey;
        _timeVectorFont = null;
        var faces = ["RobotoCondensedBold", "NotoSansSCMedium", "KosugiRegular"];
        if (style == 2) {
            faces = ["RobotoCondensedRegular", "RobotoRegular", "KosugiRegular", "NotoSansSCMedium"];
        } else if (style == 3) {
            faces = ["BionicBold", "BionicSemiBold", "BionicMedium", "RobotoCondensedBold", "NotoSansSCMedium"];
        } else if (style == 4) {
            faces = ["NotoSansSCMedium", "RobotoRegular", "RobotoCondensedRegular", "KosugiRegular"];
        } else if (style == 5) {
            faces = ["NanumGothicRegular", "RobotoRegular", "RobotoCondensedRegular", "NotoSansSCMedium"];
        } else if (style == 6) {
            faces = ["RobotoItalic", "RobotoCondensedRegularItalic", "RobotoCondensedRegular", "KosugiRegular"];
        }
        for (var size = (_width * _profileVectorTimeScale).toNumber(); size >= 16; size -= 2) {
            var candidate = null;
            try {
                candidate = Graphics.getVectorFont({:face => faces, :size => size});
            } catch (e) {
                candidate = null;
            }
            if (candidate == null) { break; }
            var extraSideGap = _profileExpandVectorTime ? _profileVectorSideGap : 0;
            if (timeFontFits(dc, candidate, worstTimeText, reserveSide, extraSideGap)) {
                _timeVectorFont = candidate;
                break;
            }
        }
        return _timeVectorFont;
    }

    // AOD must not fetch live data. Keep its optional field restricted to
    // data already cached in the active path or available from the clock.
    private function aodFieldValue(field as Lang.Number, date) as Lang.String {
        if (field == FIELD_HIDDEN) { return ""; }
        if (field == FIELD_BATTERY) { return _batteryKnown ? _cachedBatteryPercent.format("%d") + "%" : "--"; }
        if (field == FIELD_HEART) {
            return _cachedHeartRate == null ? "--" : _cachedHeartRate.toNumber().format("%d");
        }
        if (field == FIELD_DATE) { return Lang.format(text(Rez.Strings.DatePattern), [date.month, date.day]); }
        if (field == FIELD_WEEKDAY) { return weekdayText(date.day_of_week); }
        return "--";
    }

    // Shared renderer receives only formatted time/date and cached values.
    // Keep the existing simple/compact setting and all three field choices.
    private function drawAmoledAod(dc as Graphics.Dc, clock as System.ClockTime, date, displayHour as Lang.Number, simple as Lang.Boolean) as Void {
        if (_aodRenderer == null) { _aodRenderer = new SharedAod(); }
        var fields = [];
        if (!simple) {
            // Refresh only the visible AOD battery; keep the last valid value.
            if (numberProperty("AodLeftField", FIELD_HEART) == FIELD_BATTERY ||
                numberProperty("AodCenterField", FIELD_BATTERY) == FIELD_BATTERY ||
                numberProperty("AodRightField", FIELD_BATTERY) == FIELD_BATTERY) {
                try {
                    var aodBattery = System.getSystemStats().battery;
                    if (aodBattery != null) { _cachedBatteryPercent = aodBattery.toNumber(); _batteryKnown = true; }
                } catch (e) {}
            }
            fields = [
                aodFieldValue(numberProperty("AodLeftField", FIELD_HEART), date),
                aodFieldValue(numberProperty("AodCenterField", FIELD_BATTERY), date),
                aodFieldValue(numberProperty("AodRightField", FIELD_BATTERY), date)
            ];
        }
        _aodRenderer.draw(dc, clock.hour * 60 + clock.min,
            displayHour.format("%02d") + ":" + clock.min.format("%02d"),
            Lang.format(text(Rez.Strings.DatePattern), [date.month, date.day]), fields);
    }
    // The scene deliberately occupies the whole upper half.  It is a backdrop,
    // not a rectangular panel behind only the time.
    // Linearly interpolate between two 0xRRGGBB colors. t in [0,1]: 0 -> a, 1 -> b.
    private function blendColor(a as Lang.Number, b as Lang.Number, t as Lang.Float) as Lang.Number {
        var ar = (a >> 16) & 0xFF;
        var ag = (a >> 8) & 0xFF;
        var ab = a & 0xFF;
        var br = (b >> 16) & 0xFF;
        var bg = (b >> 8) & 0xFF;
        var bb = b & 0xFF;
        var r = (ar + ((br - ar) * t)).toNumber();
        var g = (ag + ((bg - ag) * t)).toNumber();
        var bl = (ab + ((bb - ab) * t)).toNumber();
        return ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (bl & 0xFF);
    }

    private function drawMountains(dc as Graphics.Dc, sky as Lang.Number, far as Lang.Number, mid as Lang.Number, near as Lang.Number) as Void {
        var w = _width;
        var startY = 0;
        var endY = y(0.57);

        // Sky: a vertical gradient from the configured SkyColor at the top
        // fading toward a darker horizon tone. Monkey C has no native gradient
        // fill, so we paint thin horizontal strips, each one step darker. This
        // keeps the single SkyColor setting but reads more refined. (Normal
        // display only — AOD never calls drawMountains, so no burn-in risk.)
        if (!isAmoledLayout()) {
            dc.setColor(sky, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(0, startY, w, endY - startY);
        } else if (sky != 0) {
            var strips = 48;
            var span = endY - startY;
            for (var i = 0; i < strips; i++) {
                var yTop = startY + (((span * i).toFloat() / strips).toNumber());
                var yNext = startY + (((span * (i + 1)).toFloat() / strips).toNumber());
                var t = (i + 0.5) / strips;
                var col = blendColor(sky, 0x000000, t * 0.45);
                dc.setColor(col, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(0, yTop, w, (yNext - yTop) + 1);
            }
        }

        {
            // Asymmetric ridges with shoulders and broad valleys; keep the
            // same three fills and colors without adding texture or buffers.
            dc.setColor(far, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon([
                [0, y(0.47)], [x(0.08), y(0.435)],
                [x(0.16), y(0.39)], [x(0.235), y(0.372)],
                [x(0.30), y(0.325)], [x(0.34), y(0.338)],
                [x(0.385), y(0.385)], [x(0.48), y(0.422)],
                [x(0.565), y(0.385)], [x(0.62), y(0.37)],
                [x(0.685), y(0.397)], [x(0.77), y(0.433)],
                [x(0.86), y(0.408)], [x(0.94), y(0.418)],
                [w, y(0.445)], [w, endY], [0, endY]
            ]);
            dc.setColor(mid, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon([
                [0, y(0.495)], [x(0.10), y(0.455)],
                [x(0.18), y(0.44)], [x(0.27), y(0.462)],
                [x(0.37), y(0.445)], [x(0.46), y(0.424)],
                [x(0.55), y(0.415)], [x(0.60), y(0.405)],
                [x(0.68), y(0.425)], [x(0.76), y(0.458)],
                [x(0.87), y(0.445)], [w, y(0.465)],
                [w, endY], [0, endY]
            ]);
            dc.setColor(near, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon([
                [0, y(0.53)], [x(0.12), y(0.505)],
                [x(0.23), y(0.487)], [x(0.31), y(0.498)],
                [x(0.43), y(0.525)], [x(0.55), y(0.512)],
                [x(0.67), y(0.485)], [x(0.74), y(0.493)],
                [x(0.84), y(0.518)], [x(0.93), y(0.508)],
                [w, y(0.50)], [w, _height], [0, _height]
            ]);
        }

        // Below the lowest ridge point, fade continuously toward a darker
        // shade of the same color. MIP keeps the solid fill above.
        if (isAmoledLayout()) {
            var fadeTop = y(0.53);
            var fadeSpan = _height - 1 - fadeTop;
            if (_nearFadeColors == null || _nearFadeColor != near || _nearFadeHeight != _height) {
                _nearFadeColors = [];
                for (var offset = 0; offset <= fadeSpan; offset++) {
                    _nearFadeColors.add(blendColor(near, 0x000000, offset.toFloat() / fadeSpan * 0.65));
                }
                _nearFadeColor = near;
                _nearFadeHeight = _height;
            }
            // Adjacent rows often round to the same RGB color. Draw each
            // identical-color run once, preserving every original pixel.
            var fadeColors = _nearFadeColors as Lang.Array;
            var row = fadeTop;
            while (row < _height) {
                var color = fadeColors[row - fadeTop];
                var nextRow = row + 1;
                while (nextRow < _height && fadeColors[nextRow - fadeTop] == color) {
                    nextRow += 1;
                }
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(0, row, w, nextRow - row);
                row = nextRow;
            }
        }
    }

    private function drawSunEventIcon(dc as Graphics.Dc, px as Lang.Number, py as Lang.Number, color as Lang.Number, rising as Lang.Boolean) as Void {
        var u1 = scalePx(1);
        var u2 = scalePx(2);
        var u3 = scalePx(3);
        var u4 = scalePx(4);
        var u6 = scalePx(6);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(u1);
        dc.drawLine(px - u6, py + u3, px + u6, py + u3);
        dc.drawArc(px, py + u3, u4, Graphics.ARC_COUNTER_CLOCKWISE, 0, 180);
        dc.drawLine(px, py - u4, px, py - u1);
        dc.drawLine(px - u4, py - u2, px - u2, py);
        dc.drawLine(px + u4, py - u2, px + u2, py);
        if (rising) {
            dc.drawLine(px, py + u6, px, py + u3);
        } else {
            dc.drawLine(px, py + u3, px, py + u6);
        }
    }

    private function formatMoment(moment) as Lang.String {
        if (moment == null) { return "--:--"; }
        var info = Gregorian.info(moment, Time.FORMAT_SHORT);
        return info.hour.format("%02d") + ":" + info.min.format("%02d");
    }

    private function latestHeartRates() as Lang.Array {
        if (_heartHistoryCache != null) { return _heartHistoryCache; }
        var values = [];
        try {
            var iterator = ActivityMonitor.getHeartRateHistory(20, true);
            var sample = iterator.next();
            while (sample != null) {
                if (sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    values.add(sample.heartRate.toFloat());
                }
                sample = iterator.next();
            }
        } catch (e) {
        }
        _heartHistoryCache = reverseArray(values);
        return _heartHistoryCache;
    }

    private function reverseArray(values as Lang.Array) as Lang.Array {
        var out = [];
        for (var i = values.size() - 1; i >= 0; i -= 1) {
            out.add(values[i]);
        }
        return out;
    }

    private function currentHeartRate() {
        if (_heartRateCached) { return _cachedHeartRate; }
        var info = _cachedActivityInfo;
        if (info != null && info.currentHeartRate != null) {
            _cachedHeartRate = info.currentHeartRate;
            _heartRateCached = true;
            return _cachedHeartRate;
        }
        var values = latestHeartRates();
        if (values.size() > 0) { _cachedHeartRate = values[values.size() - 1]; }
        _heartRateCached = true;
        return _cachedHeartRate;
    }

    private function restingHeartRate() {
        if (_restingHeartRateCached) { return _cachedRestingHeartRate; }
        _restingHeartRateCached = true;
        var profile = _cachedProfile;
        if (profile != null && profile.restingHeartRate != null) {
            _cachedRestingHeartRate = profile.restingHeartRate;
        }
        return _cachedRestingHeartRate;
    }

    private function appendHistory(iterator, values as Lang.Array) as Void {
        if (iterator == null) { return; }
        var sample = iterator.next();
        while (sample != null) {
            if (sample.data != null) {
                values.add(sample.data.toFloat());
            }
            sample = iterator.next();
        }
    }

    private function historyOptions(count as Lang.Number) as Lang.Dictionary {
        return {
            :period => count,
            :order => SensorHistory.ORDER_OLDEST_FIRST
        };
    }

    private function latestOptions() as Lang.Dictionary {
        return {
            :period => 1,
            :order => SensorHistory.ORDER_NEWEST_FIRST
        };
    }

    private function complicationValue(complicationType) {
        // Pass numeric type IDs: resolving a newer module's enum at the
        // call site would fail before this availability check on older VMs.
        try {
            if (!(Toybox has :Complications)) { return null; }
            var complication = Complications.getComplication(new Complications.Id(complicationType));
            return complication == null ? null : complication.value;
        } catch (e) {
            return null;
        }
    }

    private function isFresh(updatedSeconds as Lang.Number, maxAgeSeconds as Lang.Number, nowSeconds as Lang.Number) as Lang.Boolean {
        return updatedSeconds > 0 && nowSeconds >= updatedSeconds &&
            nowSeconds - updatedSeconds <= maxAgeSeconds;
    }

    private function isNumberInRange(value, minimum as Lang.Number, maximum as Lang.Number) as Lang.Boolean {
        return (value instanceof Lang.Number || value instanceof Lang.Float) &&
            value >= minimum && value <= maximum;
    }

    private function supportsSleepScore() as Lang.Boolean {
        try {
            var settings = _cachedDeviceSettings;
            if (settings == null || !(settings has :monkeyVersion) || settings.monkeyVersion == null) {
                return false;
            }
            var version = settings.monkeyVersion;
            return version.size() >= 3 &&
                (version[0] > 6 || (version[0] == 6 &&
                (version[1] > 0 || (version[1] == 0 && version[2] >= 2))));
        } catch (e) {
            return false;
        }
    }

    private function sleepScore() {
        var now = Time.now();
        var date = Gregorian.info(now, Time.FORMAT_SHORT);
        var day = (date.year * 13 + date.month) * 32 + date.day;
        if (_sleepScoreCacheDay != day) {
            _sleepScoreCacheDay = day;
            _sleepScoreCached = false;
            _cachedSleepScore = null;
            _sleepScoreUpdatedSeconds = 0;
        }
        if (_sleepScoreCached) { return _cachedSleepScore; }
        _sleepScoreCached = true;
        if (!supportsSleepScore()) {
            _cachedSleepScore = null;
            _sleepScoreUpdatedSeconds = 0;
            return null;
        }
        var nowSeconds = now.value();
        var score = complicationValue(COMPLICATION_TYPE_SLEEP_SCORE);
        if (isNumberInRange(score, 0, 100)) {
            _cachedSleepScore = score.toNumber();
            _sleepScoreUpdatedSeconds = nowSeconds;
            return _cachedSleepScore;
        }
        if (isFresh(_sleepScoreUpdatedSeconds, SLEEP_SCORE_CACHE_SECONDS, nowSeconds)) {
            return _cachedSleepScore;
        }
        _cachedSleepScore = null;
        _sleepScoreUpdatedSeconds = 0;
        return null;
    }

    private function elevationHistory() as Lang.Array {
        var values = [];
        try {
            if (SensorHistory has :getElevationHistory) {
                appendHistory(SensorHistory.getElevationHistory(historyOptions(16)), values);
            }
        } catch (e) {
        }
        return values;
    }

    private function stressHistory() as Lang.Array {
        var values = [];
        try {
            if (SensorHistory has :getStressHistory) {
                appendHistory(SensorHistory.getStressHistory(historyOptions(16)), values);
            }
        } catch (e) {
        }
        return values;
    }

    private function bodyBatteryHistory() as Lang.Array {
        var values = [];
        try {
            if (SensorHistory has :getBodyBatteryHistory) {
                appendHistory(SensorHistory.getBodyBatteryHistory(historyOptions(16)), values);
            }
        } catch (e) {
        }
        return values;
    }

    private function pressureHistory() as Lang.Array {
        var values = [];
        try {
            if (SensorHistory has :getPressureHistory) {
                appendHistory(SensorHistory.getPressureHistory(historyOptions(16)), values);
            }
        } catch (e) {
        }
        return values;
    }

    private function spo2History() as Lang.Array {
        var values = [];
        try {
            if (SensorHistory has :getOxygenSaturationHistory) {
                appendHistory(SensorHistory.getOxygenSaturationHistory(historyOptions(16)), values);
            }
        } catch (e) {
        }
        return values;
    }

    private function temperatureHistory() as Lang.Array {
        var values = [];
        try {
            if (SensorHistory has :getTemperatureHistory) {
                appendHistory(SensorHistory.getTemperatureHistory(historyOptions(16)), values);
            }
        } catch (e) {
        }
        return values;
    }

    private function loadBodyBatteryCache() as Void {
        if (_bodyBatteryStorageLoaded) { return; }
        _bodyBatteryStorageLoaded = true;
        try {
            var stored = Application.Storage.getValue(BODY_BATTERY_STORAGE_KEY);
            if (stored != null) {
                var value = stored.toNumber();
                if (value >= 0 && value <= 100) { _cachedBodyBattery = value; }
            }
        } catch (e) {
        }
    }

    private function cacheBodyBattery(value) as Void {
        if (value == null) { return; }
        var normalized = value.toNumber();
        if (normalized < 0 || normalized > 100) { return; }
        if (_cachedBodyBattery == normalized) { return; }
        _cachedBodyBattery = normalized;
        try {
            Application.Storage.setValue(BODY_BATTERY_STORAGE_KEY, normalized);
        } catch (e) {
            // Storage is optional; retain the valid in-memory value either way.
        }
    }

    private function bodyBattery() {
        if (_bodyBatteryCached) { return _cachedBodyBattery; }
        _bodyBatteryCached = true;
        loadBodyBatteryCache();
        var current = complicationValue(23); // Body battery
        if (current != null) {
            cacheBodyBattery(current);
            return _cachedBodyBattery;
        }
        try {
            if (SensorHistory has :getBodyBatteryHistory) {
                var sample = SensorHistory.getBodyBatteryHistory(latestOptions()).next();
                if (sample != null && sample.data != null) { cacheBodyBattery(sample.data); }
            }
        } catch (e) {
        }
        return _cachedBodyBattery;
    }

    private function currentElevation() {
        if (_elevationCached) { return _cachedElevation; }
        _elevationCached = true;
        var elevation = complicationValue(15); // Altitude
        if (elevation != null) {
            _cachedElevation = elevation;
            return _cachedElevation;
        }
        try {
            if (SensorHistory has :getElevationHistory) {
                var sample = SensorHistory.getElevationHistory(latestOptions()).next();
                if (sample != null && sample.data != null) { _cachedElevation = sample.data; }
            }
        } catch (e) {
        }
        if (_cachedElevation == null) {
            var info = _cachedActivityInfo;
            if (info != null && info.altitude != null) { _cachedElevation = info.altitude; }
        }
        return _cachedElevation;
    }

    private function currentPressure() {
        if (_pressureCached) { return _cachedPressure; }
        _pressureCached = true;
        try {
            if (SensorHistory has :getPressureHistory) {
                var sample = SensorHistory.getPressureHistory(latestOptions()).next();
                if (sample != null && sample.data != null) { _cachedPressure = sample.data; }
            }
        } catch (e) {
        }
        if (_cachedPressure == null) {
            var info = _cachedActivityInfo;
            if (info != null && (info has :rawAmbientPressure) && info.rawAmbientPressure != null) {
                _cachedPressure = info.rawAmbientPressure;
            }
        }
        return _cachedPressure;
    }

    private function currentSpo2() {
        if (_spo2Cached) { return _cachedSpo2; }
        _spo2Cached = true;
        var spo2 = complicationValue(35); // Pulse oximetry
        if (spo2 != null) {
            _cachedSpo2 = spo2;
            return _cachedSpo2;
        }
        try {
            if (SensorHistory has :getOxygenSaturationHistory) {
                var sample = SensorHistory.getOxygenSaturationHistory(latestOptions()).next();
                if (sample != null && sample.data != null) { _cachedSpo2 = sample.data; }
            }
        } catch (e) {
        }
        return _cachedSpo2;
    }

    private function currentStress(activity) {
        if (_stressCached) { return _cachedStress; }
        _stressCached = true;
        var nowSeconds = Time.now().value();
        var stress = complicationValue(22); // Stress
        if (!isNumberInRange(stress, 0, 100) && activity != null &&
            (activity has :stressScore) && isNumberInRange(activity.stressScore, 0, 100)) {
            stress = activity.stressScore;
        }
        if (!isNumberInRange(stress, 0, 100)) {
            try {
                if (SensorHistory has :getStressHistory) {
                    var sample = SensorHistory.getStressHistory(latestOptions()).next();
                    if (sample != null && isNumberInRange(sample.data, 0, 100)) { stress = sample.data; }
                }
            } catch (e) {
            }
        }
        if (isNumberInRange(stress, 0, 100)) {
            _cachedStress = stress.toNumber();
            _stressUpdatedSeconds = nowSeconds;
            return _cachedStress;
        }
        if (isFresh(_stressUpdatedSeconds, STRESS_CACHE_SECONDS, nowSeconds)) { return _cachedStress; }
        _cachedStress = null;
        _stressUpdatedSeconds = 0;
        return null;
    }

    private function recoveryHours(activity) {
        var nowSeconds = Time.now().value();
        if (_recoveryCached) { return cachedRecoveryHours(nowSeconds); }
        _recoveryCached = true;
        var minutes = complicationValue(21); // Recovery time
        var hours = null;
        if ((minutes instanceof Lang.Number || minutes instanceof Lang.Float) && minutes >= 0) {
            hours = minutes / 60.0;
        } else if (activity != null && (activity has :timeToRecovery) &&
            (activity.timeToRecovery instanceof Lang.Number || activity.timeToRecovery instanceof Lang.Float) &&
            activity.timeToRecovery >= 0) {
            hours = activity.timeToRecovery;
        }
        if (hours != null) {
            _cachedRecoveryEndSeconds = nowSeconds + (hours * 3600).toNumber();
            _recoveryUpdatedSeconds = nowSeconds;
        }
        return cachedRecoveryHours(nowSeconds);
    }

    private function cachedRecoveryHours(nowSeconds as Lang.Number) {
        if (_cachedRecoveryEndSeconds == null) { return null; }
        if (_cachedRecoveryEndSeconds > nowSeconds) {
            return (_cachedRecoveryEndSeconds - nowSeconds) / 3600.0;
        }
        if (isFresh(_recoveryUpdatedSeconds, RECOVERY_COMPLETE_CACHE_SECONDS, nowSeconds)) { return 0; }
        _cachedRecoveryEndSeconds = null;
        _recoveryUpdatedSeconds = 0;
        return null;
    }

    private function currentSensorTemp() {
        if (_sensorTempCached) { return _cachedSensorTemp; }
        _sensorTempCached = true;
        try {
            if (SensorHistory has :getTemperatureHistory) {
                var sample = SensorHistory.getTemperatureHistory(latestOptions()).next();
                if (sample != null && sample.data != null) { _cachedSensorTemp = sample.data; }
            }
        } catch (e) {
        }
        return _cachedSensorTemp;
    }

    private function trendValues(mode as Lang.Number) as Lang.Array {
        var trendTick = (Time.now().value() / TREND_CACHE_SECONDS).toNumber();
        if (_trendCacheTick == trendTick && _trendCacheMode == mode && _trendCacheValues != null) {
            return _trendCacheValues;
        }
        var previousValues = _trendCacheMode == mode ? _trendCacheValues : null;
        var values = null;
        if (mode == TREND_ELEVATION) { values = elevationHistory(); }
        else if (mode == TREND_STRESS) { values = stressHistory(); }
        else if (mode == TREND_BODY_BATTERY) { values = bodyBatteryHistory(); }
        else if (mode == TREND_PRESSURE) { values = pressureHistory(); }
        else if (mode == TREND_SPO2) { values = spo2History(); }
        else if (mode == TREND_TEMPERATURE) { values = temperatureHistory(); }
        else { values = latestHeartRates(); }
        if ((values == null || values.size() == 0) && previousValues != null && previousValues.size() > 0) {
            values = previousValues;
        }
        _trendCacheTick = trendTick;
        _trendCacheMode = mode;
        _trendCacheValues = values;
        return values;
    }

    private function formatTrendValue(mode as Lang.Number, raw) as Lang.String {
        if (raw == null) { return "--"; }
        if (mode == TREND_ELEVATION) { return raw.toNumber().format("%d") + "m"; }
        if (mode == TREND_STRESS) { return raw.toNumber().format("%d"); }
        if (mode == TREND_BODY_BATTERY) { return raw.toNumber().format("%d") + "%"; }
        if (mode == TREND_PRESSURE) { return (raw.toFloat() / 100.0).format("%.0f"); }
        if (mode == TREND_SPO2) { return raw.toNumber().format("%d") + "%"; }
        if (mode == TREND_TEMPERATURE) { return formatTemperature(raw); }
        return raw.toNumber().format("%d");
    }

    private function trendCurrentValue(mode as Lang.Number, activity) {
        if (_trendCurrentCached && _trendCurrentCacheMode == mode) { return _trendCurrentCache; }
        var value = null;
        if (mode == TREND_ELEVATION) { value = currentElevation(); }
        else if (mode == TREND_STRESS) { value = currentStress(activity); }
        else if (mode == TREND_BODY_BATTERY) { value = bodyBattery(); }
        else if (mode == TREND_PRESSURE) { value = currentPressure(); }
        else if (mode == TREND_SPO2) { value = currentSpo2(); }
        else if (mode == TREND_TEMPERATURE) { value = currentSensorTemp(); }
        else { value = currentHeartRate(); }
        _trendCurrentCacheMode = mode;
        _trendCurrentCache = value;
        _trendCurrentCached = true;
        return value;
    }

    // For each trend mode, the minimum visual range used to scale the chart.
    // Without this, a heart rate of 60..80 bpm looks like a 0..100% ramp
    // because the chart scales to the actual range.  These baselines make
    // the chart show "this is what a normal 30-unit swing looks like"
    // regardless of the actual data spread.
    private function trendMinRange(mode as Lang.Number) as Lang.Float {
        if (mode == TREND_HEART)        { return 30.0; }
        if (mode == TREND_STRESS)       { return 30.0; }
        if (mode == TREND_BODY_BATTERY) { return 30.0; }
        if (mode == TREND_PRESSURE)     { return 5.0;  }
        if (mode == TREND_SPO2)         { return 10.0; }
        if (mode == TREND_TEMPERATURE)  { return 5.0;  }
        if (mode == TREND_ELEVATION)    { return 50.0; }
        return 1.0;
    }

    private function rangeOf(values as Lang.Array) as Lang.Array {
        if (values == null || values.size() == 0) { return [0, 1]; }
        var minValue = values[0].toFloat();
        var maxValue = values[0].toFloat();
        for (var i = 1; i < values.size(); i += 1) {
            var v = values[i].toFloat();
            if (v < minValue) { minValue = v; }
            if (v > maxValue) { maxValue = v; }
        }
        var range = maxValue - minValue;
        if (range < 1.0) { range = 1.0; }
        return [minValue, range];
    }

    private function drawTrendLine(dc as Graphics.Dc, values as Lang.Array, color as Lang.Number, left as Lang.Number, top as Lang.Number, width as Lang.Number, height as Lang.Number, mode as Lang.Number) as Void {
        if (values.size() < 2) { return; }
        var rr = rangeOf(values);
        var minValue = rr[0];
        var range = rr[1];
        var minRange = trendMinRange(mode);
        if (range < minRange) {
            // Expand the visual range so a tight cluster (e.g. heart rate
            // 60-80) doesn't draw as if it spanned 0-100%.
            minValue = minValue - (minRange - range) / 2.0;
            range = minRange;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(scalePx(2));
        var previousX = left;
        var previousY = top + height - (((values[0].toFloat() - minValue) * height) / range).toNumber();
        for (var j = 1; j < values.size(); j += 1) {
            var px = left + (j * width / (values.size() - 1));
            var py = top + height - (((values[j].toFloat() - minValue) * height) / range).toNumber();
            dc.drawLine(previousX, previousY, px, py);
            previousX = px;
            previousY = py;
        }
    }

    private function drawTrendBars(dc as Graphics.Dc, values as Lang.Array, color as Lang.Number, left as Lang.Number, top as Lang.Number, width as Lang.Number, height as Lang.Number, mode as Lang.Number) as Void {
        if (values.size() == 0) { return; }
        var rr = rangeOf(values);
        var minValue = rr[0];
        var range = rr[1];
        // Bars use the observed range so the maximum reaches the chart top.
        var n = values.size();
        var gap = scalePx(1);
        var barW = (width / n) - gap;
        if (barW < 1) { barW = 1; }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        for (var i = 0; i < n; i += 1) {
            var h = (((values[i].toFloat() - minValue) * height) / range).toNumber();
            if (h < 1) { h = 1; }
            var bx = left + (i * width / n);
            var by = top + height - h;
            dc.fillRectangle(bx, by, barW, h);
        }
    }

    private function drawTrend(dc as Graphics.Dc, style as Lang.Number, values as Lang.Array, color as Lang.Number, left as Lang.Number, top as Lang.Number, width as Lang.Number, height as Lang.Number, mode as Lang.Number) as Void {
        if (style == TREND_STYLE_BARS) {
            drawTrendBars(dc, values, color, left, top, width, height, mode);
        } else {
            drawTrendLine(dc, values, color, left, top, width, height, mode);
        }
    }

    private function ringValue(mode as Lang.Number, battery as Lang.Number, activity) {
        if (mode == RING_BODY_BATTERY) { return bodyBattery(); }
        if (mode == RING_STRESS) { return currentStress(activity); }
        return battery;
    }

    // The setting keeps its original property name for backwards compatibility,
    // but the visual is a compact status capsule rather than a circular gauge.
    private function statusField(mode as Lang.Number) as Lang.Number {
        if (mode == RING_BODY_BATTERY) { return FIELD_BODY_BATTERY; }
        if (mode == RING_STRESS) { return FIELD_STRESS; }
        return FIELD_BATTERY;
    }

    private function activeMinutesTotal(activity) {
        if (activity == null || !(activity has :activeMinutesDay) || activity.activeMinutesDay == null) { return null; }
        return activity.activeMinutesDay.total;
    }

    private function activeMinutesWeekTotal(activity) {
        if (activity == null || !(activity has :activeMinutesWeek) || activity.activeMinutesWeek == null) { return null; }
        return activity.activeMinutesWeek.total;
    }

    private function activeMinutesWeekGoalPercent(activity) {
        var active = activeMinutesWeekTotal(activity);
        if (activity == null || !(activity has :activeMinutesWeekGoal) || active == null ||
            activity.activeMinutesWeekGoal == null || activity.activeMinutesWeekGoal == 0) { return null; }
        return ((active * 100) / activity.activeMinutesWeekGoal).toNumber();
    }

    private function isCurrentWeek(activityDate, date) as Lang.Boolean {
        var daysSinceMonday = date.day_of_week == Gregorian.DAY_SUNDAY ? 6 : date.day_of_week - Gregorian.DAY_MONDAY;
        var currentDay = dayOfYear(date.month, date.day, date.year);
        var weekStartDay = currentDay - daysSinceMonday;
        var activityDay = dayOfYear(activityDate.month, activityDate.day, activityDate.year);
        if (weekStartDay >= 1) {
            return activityDate.year == date.year && activityDay >= weekStartDay && activityDay <= currentDay;
        }
        if (activityDate.year == date.year) { return activityDay <= currentDay; }
        return activityDate.year == date.year - 1 && activityDay >= daysInYear(activityDate.year) + weekStartDay;
    }

    private function updateActivityDistanceCache(date) as Void {
        var cacheKey = (((date.year * 12 + date.month) * 31 + date.day) * 24 + date.hour);
        if (_activityDistanceCacheKey == cacheKey) { return; }
        _activityDistanceCacheKey = cacheKey;
        var cacheDay = (date.year * 13 + date.month) * 32 + date.day;
        if (_activityDistanceCacheDay != cacheDay) {
            _activityDistanceCacheDay = cacheDay;
            _runningDistances = null;
            _cyclingDistances = null;
        }
        try {
            if (!(UserProfile has :getUserActivityHistory)) { return; }
            var running = [0.0, 0.0, 0.0, 0.0];
            var cycling = [0.0, 0.0, 0.0, 0.0];
            var iterator = UserProfile.getUserActivityHistory();
            var activity = iterator.next();
            while (activity != null) {
                if (activity.startTime != null && activity.distance != null) {
                    var info = Gregorian.info(activity.startTime, Time.FORMAT_SHORT);
                    var totals = null;
                    if (activity.type == Activity.SPORT_RUNNING) { totals = running; }
                    else if (activity.type == Activity.SPORT_CYCLING) { totals = cycling; }
                    if (totals != null && info.year == date.year) {
                        totals[DISTANCE_PERIOD_YEAR] += activity.distance;
                        if (info.month == date.month) {
                            totals[DISTANCE_PERIOD_MONTH] += activity.distance;
                            if (info.day == date.day) { totals[DISTANCE_PERIOD_DAY] += activity.distance; }
                        }
                    }
                    if (totals != null && isCurrentWeek(info, date)) {
                        totals[DISTANCE_PERIOD_WEEK] += activity.distance;
                    }
                }
                activity = iterator.next();
            }
            _runningDistances = running;
            _cyclingDistances = cycling;
        } catch (e) {
            // Retain the last successful totals for this day and retry next hour.
        }
    }

    private function activityDistance(date, cycling as Lang.Boolean, period as Lang.Number) {
        // Drawing may run before a due wake refresh. Consume its snapshot;
        // history reads belong to refreshFieldData's shallower call stack.
        var day = (date.year * 13 + date.month) * 32 + date.day;
        if (_activityDistanceCacheDay != day) { return null; }
        if (cycling) {
            return _cyclingDistances == null ? null : (_cyclingDistances as Lang.Array)[period];
        }
        return _runningDistances == null ? null : (_runningDistances as Lang.Array)[period];
    }

    private function distanceFieldValue(field as Lang.Number, date) {
        var cycling = field == FIELD_DAILY_CYCLING_DISTANCE || field == FIELD_WEEKLY_CYCLING_DISTANCE ||
                      field == FIELD_MONTHLY_CYCLING_DISTANCE || field == FIELD_YEARLY_CYCLING_DISTANCE;
        var period = DISTANCE_PERIOD_MONTH;
        if (field == FIELD_DAILY_RUNNING_DISTANCE || field == FIELD_DAILY_CYCLING_DISTANCE) { period = DISTANCE_PERIOD_DAY; }
        else if (field == FIELD_WEEKLY_RUNNING_DISTANCE || field == FIELD_WEEKLY_CYCLING_DISTANCE) { period = DISTANCE_PERIOD_WEEK; }
        else if (field == FIELD_YEARLY_RUNNING_DISTANCE || field == FIELD_YEARLY_CYCLING_DISTANCE) { period = DISTANCE_PERIOD_YEAR; }
        return activityDistance(date, cycling, period);
    }

    private function heartRateZone() as Lang.String {
        var heartRate = _cachedHeartRate;
        if (heartRate == null) { return "--"; }
        var zones = _cachedHeartRateZones;
        if (zones == null || zones.size() < 6) { return "--"; }
        if (heartRate < zones[0]) { return "Z0"; }
        for (var i = 1; i < zones.size(); i += 1) {
            if (heartRate <= zones[i]) { return "Z" + i.format("%d"); }
        }
        return "Z5";
    }

    private function daylightValue(conditions, now as Time.Moment, dayOnly as Lang.Boolean) as Lang.String {
        var sunrise = sunMoment(conditions, now, true);
        var sunset = sunMoment(conditions, now, false);
        if (sunrise == null || sunset == null) { return "--"; }
        var isDay = now.value() >= sunrise.value() && now.value() < sunset.value();
        if (dayOnly) { return isDay ? text(Rez.Strings.ValueDay) : text(Rez.Strings.ValueNight); }
        if (!isDay) { return text(Rez.Strings.ValueNight); }
        var minutes = ((sunset.value() - now.value()) / 60).toNumber();
        var hours = (minutes / 60).toNumber();
        return hours.format("%d") + "h" + (minutes % 60).format("%02d");
    }

    private function nextSunEvent(conditions, now as Time.Moment) {
        var sunrise = sunMoment(conditions, now, true);
        var sunset = sunMoment(conditions, now, false);
        if (sunrise == null || sunset == null) { return null; }
        if (now.value() < sunrise.value()) { return sunrise; }
        if (now.value() < sunset.value()) { return sunset; }
        try {
            if (conditions == null || conditions.observationLocationPosition == null || !(Weather has :getSunrise)) { return null; }
            return Weather.getSunrise(conditions.observationLocationPosition, Time.today().add(new Time.Duration(86401)));
        } catch (e) {
            return null;
        }
    }


    private function cachedAverageRestingHeartRate() {
        if (_cachedProfile == null || !(_cachedProfile has :averageRestingHeartRate) || _cachedProfile.averageRestingHeartRate == null) { return null; }
        return _cachedProfile.averageRestingHeartRate;
    }

    // Garmin's observed daily resting-calorie model, reverse-engineered by
    // Connect IQ watch-face developers. It aligns more closely with the
    // Calories Glance than the generic Mifflin-St Jeor BMR formula.
    private function estimateBmr(activity) {
        try {
            var profile = _cachedProfile;
            if (profile == null || !(profile has :weight) || !(profile has :height) || !(profile has :birthYear) || profile.weight == null || profile.height == null || profile.birthYear == null) { return null; }
            var weight = profile.weight;          // grams in CIQ
            if (weight <= 0 || profile.height <= 0) { return null; }
            var kg = weight / 1000.0;
            var age = Gregorian.info(Time.now(), Time.FORMAT_SHORT).year - profile.birthYear;
            if (age < 10 || age > 100) { return null; }
            var bmr = 5.2 - 6.116 * age + 7.628 * profile.height + 12.2 * kg;
            if ((profile has :gender) && profile.gender == UserProfile.GENDER_FEMALE) { bmr -= 202.8; }
            return bmr;
        } catch (e) {
            return null;
        }
    }

    // Returns today's active calories: total - Garmin-style resting calories
    // accrued through the current minute.
    // Never negative; returns 0 when no profile is available so the user
    // sees a real value rather than "--".
    private function activeCalories(activity) {
        if (activity == null || !(activity has :calories) || activity.calories == null) { return null; }
        var total = activity.calories;
        var bmr = estimateBmr(activity);
        if (bmr == null || bmr <= 0) { return null; }
        var now = Time.now();
        var info = Gregorian.info(now, Time.FORMAT_SHORT);
        var minutesElapsed = info.hour * 60 + info.min;
        var burnedSoFar = (bmr * minutesElapsed / 1440.0 + 0.5).toNumber();
        var active = total - burnedSoFar;
        if (active < 0) { active = 0; }
        return active.toNumber();
    }

    private function restingCalories(activity) {
        if (activity == null || !(activity has :calories) || activity.calories == null) { return null; }
        var active = activeCalories(activity);
        if (active == null) { return null; }
        var resting = activity.calories - active;
        return resting < 0 ? 0 : resting.toNumber();
    }

    private function batteryDaysRemaining() {
        if (_cachedStats == null || !(_cachedStats has :batteryInDays) || _cachedStats.batteryInDays == null) { return null; }
        return _cachedStats.batteryInDays;
    }

    private function cachedSolarIntensity() {
        if (_cachedStats == null || !(_cachedStats has :solarIntensity) || _cachedStats.solarIntensity == null) { return null; }
        return _cachedStats.solarIntensity;
    }

    private function cachedVo2maxRunning() {
        if (_cachedProfile == null || !(_cachedProfile has :vo2maxRunning) || _cachedProfile.vo2maxRunning == null) { return null; }
        return _cachedProfile.vo2maxRunning;
    }

    private function stepGoalPercent(activity) {
        if (activity == null || !(activity has :steps) || !(activity has :stepGoal) || activity.steps == null || activity.stepGoal == null || activity.stepGoal == 0) {
            return null;
        }
        var pct = (activity.steps * 100) / activity.stepGoal;
        if (pct > 999) { pct = 999; }
        return pct;
    }

    private function gregorianLeapYear(year as Lang.Number) as Lang.Boolean {
        return ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    private function lunarYearInfo(year as Lang.Number) as Lang.Number {
        return _lunarYears[(year - 1900).toNumber()] as Lang.Number;
    }

    private function lunarLeapMonth(year as Lang.Number) as Lang.Number {
        return lunarYearInfo(year) & 0x0f;
    }

    private function lunarLeapDays(year as Lang.Number) as Lang.Number {
        var month = lunarLeapMonth(year);
        if (month == 0) { return 0; }
        return (lunarYearInfo(year) & 0x10000) != 0 ? 30 : 29;
    }

    private function lunarMonthDays(year as Lang.Number, month as Lang.Number) as Lang.Number {
        return (lunarYearInfo(year) & (0x10000 >> month)) != 0 ? 30 : 29;
    }

    private function lunarYearDays(year as Lang.Number) as Lang.Number {
        // This also runs from a data slot's deeper drawing stack. Read the
        // year's flags once and avoid nested leap-day helper calls.
        var info = _lunarYears[(year - 1900).toNumber()] as Lang.Number;
        var days = 348;
        for (var mask = 0x8000; mask > 0x8; mask >>= 1) {
            if ((info & mask) != 0) { days += 1; }
        }
        if ((info & 0x0f) != 0) { days += (info & 0x10000) != 0 ? 30 : 29; }
        return days;
    }

    // Select the largest Chinese vector-font size whose complete row fits the
    // center chord without entering the status row. The calendar has its own
    // profile anchor because Garmin number fonts can contain large internal
    // leading that does not match the visible digit bounds.
    private function fittedCalendarFont(dc as Graphics.Dc, items as Lang.Array,
                                        itemCount as Lang.Number, cacheKey as Lang.Number) {
        if (!(Graphics has :getVectorFont) || itemCount == 0) { return null; }
        if (_lunarFontChecked && _lunarFontKey == cacheKey) { return _lunarFont; }
        _lunarFontChecked = true;
        _lunarFontKey = cacheKey;
        _lunarFont = null;

        // Venu 3 has a tight watch-face memory budget. Probe in two-pixel
        // steps so the first calendar render does not allocate dozens of
        // short-lived vector-font objects.
        for (var size = _profileCalendarFontSize; size >= 8; size -= 2) {
            var candidate = null;
            try {
                candidate = Graphics.getVectorFont({:face => "NotoSansSCMedium", :size => size});
            } catch (e) {
                candidate = null;
            }
            if (candidate == null) { break; }

            var contentWidth = 0;
            for (var i = 0; i < items.size(); i += 1) {
                contentWidth += dc.getTextWidthInPixels(items[i], candidate);
            }
            var fontH = dc.getFontHeight(candidate);
            var dateBottom = _profileCalendarCenterY + (fontH / 2).toNumber();
            var statusTop = y(0.61) -
                            (dc.getFontHeight(Graphics.FONT_XTINY) / 2).toNumber();
            var availableWidth = roundContentWidthAt(_profileCalendarCenterY, _profileCalendarInset);
            var minimumGapWidth = itemCount > 1 ? itemCount - 1 : 0;
            if (contentWidth + minimumGapWidth <= availableWidth &&
                dateBottom + _profileTrendGap <= statusTop) {
                _lunarFont = candidate;
                break;
            }
        }
        return _lunarFont;
    }

    // Converts the local Gregorian calendar date to a compact Chinese lunar
    // date.  The table's supported range is 1900–2100.

    private function lunarDate(date, chinese as Lang.Boolean) as Lang.String {
        var day = (date.year * 13 + date.month) * 32 + date.day;
        if (_lunarDateCacheDay != day) {
            _lunarDateCacheDay = day;
            _lunarDateChinese = null;
            _lunarDateEnglish = null;
        }
        if (chinese) {
            if (_lunarDateChinese == null) { _lunarDateChinese = calculateLunarDate(date, true); }
            return _lunarDateChinese;
        }
        if (_lunarDateEnglish == null) { _lunarDateEnglish = calculateLunarDate(date, false); }
        return _lunarDateEnglish;
    }

    private function calculateLunarDate(date, chinese as Lang.Boolean) as Lang.String {
        var year = date.year;
        if (year < 1900 || year > 2100) { return chinese ? "--" : "L--"; }
        // 1900-01-01..1900-01-30 fall in lunar year 1899, which the table
        // does not cover.  Without this guard the offset becomes negative
        // and dayNames[offset] would read past the start of the array.
        if (year == 1900 && date.month == 1 && date.day < 31) {
            return chinese ? "--" : "L--";
        }

        var solarMonthDays = MONTH_DAYS;
        var offset = date.day - 31;
        for (var solarYear = 1900; solarYear < year; solarYear += 1) {
            offset += gregorianLeapYear(solarYear) ? 366 : 365;
        }
        for (var solarMonth = 1; solarMonth < date.month; solarMonth += 1) {
            offset += solarMonthDays[solarMonth - 1];
            if (solarMonth == 2 && gregorianLeapYear(year)) { offset += 1; }
        }

        var lunarYear = 1900;
        var yearDays = lunarYearDays(lunarYear);
        while (offset >= yearDays && lunarYear < 2101) {
            offset -= yearDays;
            lunarYear += 1;
            if (lunarYear <= 2100) { yearDays = lunarYearDays(lunarYear); }
        }

        var leap = lunarLeapMonth(lunarYear);
        var lunarMonth = 1;
        var isLeap = false;
        var monthDays = lunarMonthDays(lunarYear, lunarMonth);
        while (offset >= monthDays) {
            offset -= monthDays;
            if (leap != 0 && lunarMonth == leap && !isLeap) {
                isLeap = true;
                monthDays = lunarLeapDays(lunarYear);
            } else {
                if (isLeap) { isLeap = false; }
                lunarMonth += 1;
                monthDays = lunarMonthDays(lunarYear, lunarMonth);
            }
        }

        if (chinese) {
            var monthNames = ["正","二","三","四","五","六","七","八","九","十","冬","腊"];
            var dayNames = ["初一","初二","初三","初四","初五","初六","初七","初八","初九","初十",
                            "十一","十二","十三","十四","十五","十六","十七","十八","十九","二十",
                            "廿一","廿二","廿三","廿四","廿五","廿六","廿七","廿八","廿九","三十"];
            return (isLeap ? "闰" : "") + monthNames[lunarMonth - 1] + "月" + dayNames[offset];
        }

        // Fallback for devices that do not provide the Chinese vector font.
        return (isLeap ? "R" : "L") + lunarMonth.format("%02d") + "/" + (offset + 1).format("%02d");
    }

    // --- 24 solar terms (节气) -------------------------------------------------
    // Names in calendar order, starting from 小寒 (early January).
    private var _solarTermNames as Lang.Array = [
        "小寒","大寒","立春","雨水","惊蛰","春分","清明","谷雨",
        "立夏","小满","芒种","夏至","小暑","大暑","立秋","处暑",
        "白露","秋分","寒露","霜降","立冬","小雪","大雪","冬至"
    ];
    private var _solarTermNamesEnglish as Lang.Array = [
        "Min Cold","Maj Cold","Spring","Rain Water","Insects","Spring Eq","Clear","Grain Rain",
        "Summer","Grain Full","Grain Ear","Summer Sol","Min Heat","Maj Heat","Autumn","End Heat",
        "White Dew","Autumn Eq","Cold Dew","Frost","Winter","Min Snow","Maj Snow","Winter Sol"
    ];
    // 寿星天文公式 century constants (C) for each term (accurate ~1901-2100, ±1 day).
    private var _solarTermC as Lang.Array = [
        5.4055, 20.12, 3.87, 18.73, 5.63, 20.646, 4.81, 20.1,
        5.52, 20.888, 5.678, 21.37, 7.108, 22.83, 7.5, 23.13,
        7.646, 23.042, 8.318, 23.438, 7.438, 22.36, 7.18, 21.94
    ];

    // Day of the month for solar term `index` in `year`, via the 寿星 formula:
    //   day = floor(Y * 0.2422 + C) - floor((Y-1) / 4),  Y = year % 100
    private function solarTermDay(year as Lang.Number, index as Lang.Number) as Lang.Number {
        var y = year % 100;
        var c = _solarTermC[index] as Lang.Float;
        return ((y * 0.2422 + c).toNumber() - ((y - 1) / 4).toNumber());
    }

    // Calendar month (1-12) that solar term `index` falls in.
    private function solarTermMonth(index as Lang.Number) as Lang.Number {
        return (index / 2).toNumber() + 1;   // Monkey C integer division
    }

    private function dayOfYear(month as Lang.Number, day as Lang.Number, year as Lang.Number) as Lang.Number {
        var monthDays = MONTH_DAYS;
        var doy = day;
        for (var m = 1; m < month; m += 1) {
            doy += monthDays[m - 1];
        }
        if (month > 2 && gregorianLeapYear(year)) { doy += 1; }
        return doy;
    }

    private function isoWeekNumber(year as Lang.Number, month as Lang.Number, day as Lang.Number) as Lang.Number {
        var firstDay = julianDay(year, 1, 1);
        var givenDay = julianDay(year, month, day);
        var dayOfWeek = (firstDay + 3) % 7;
        var week = (givenDay - firstDay + dayOfWeek + 4) / 7;
        if (week == 53) {
            if (dayOfWeek == 6 || (dayOfWeek == 5 && gregorianLeapYear(year))) { return week; }
            return 1;
        }
        if (week != 0) { return week; }
        firstDay = julianDay(year - 1, 1, 1);
        dayOfWeek = (firstDay + 3) % 7;
        return (givenDay - firstDay + dayOfWeek + 4) / 7;
    }

    private function julianDay(year as Lang.Number, month as Lang.Number, day as Lang.Number) as Lang.Number {
        var a = (14 - month) / 12;
        var y = year + 4800 - a;
        var m = month + 12 * a - 3;
        return day + ((153 * m + 2) / 5) + 365 * y + y / 4 - y / 100 + y / 400 - 32045;
    }

    private function daysInYear(year as Lang.Number) as Lang.Number {
        return gregorianLeapYear(year) ? 366 : 365;
    }

    // Returns [daysUntil, nameIndex]; daysUntil is 0 on a term day. Rolls over
    // to 小寒 of the next year when no term remains in the current year.
    private function nextSolarTerm(date) as Lang.Array {
        var year = date.year;
        var todayDoy = dayOfYear(date.month, date.day, year);
        for (var i = 0; i < 24; i += 1) {
            var m = solarTermMonth(i);
            var d = solarTermDay(year, i);
            if (dayOfYear(m, d, year) >= todayDoy) {
                return [dayOfYear(m, d, year) - todayDoy, i];
            }
        }
        var d0 = solarTermDay(year + 1, 0);
        return [(daysInYear(year) - todayDoy) + dayOfYear(solarTermMonth(0), d0, year + 1), 0];
    }

    private function solarTermText(date) as Lang.String {
        var res = nextSolarTerm(date);
        var days = res[0] as Lang.Number;
        var names = isChineseCalendar() ? _solarTermNames : _solarTermNamesEnglish;
        var name = names[res[1] as Lang.Number];
        if (days == 0) {
            return Lang.format(text(Rez.Strings.SolarTermTodayPattern), [name]);
        }
        return Lang.format(text(Rez.Strings.SolarTermFuturePattern), [name, days]);
    }

    private function reportSunDiagnostic(status as Lang.Number, message as Lang.String) as Void {
        // Report only when the failure state changes. This keeps second-by-second
        // watch-face updates from flooding the simulator log.
        if (_sunDiagnostic != status) {
            _sunDiagnostic = status;
            System.println(message);
        }
    }

    private function sunMoment(conditions, now as Time.Moment, rising as Lang.Boolean) {
        var date = Gregorian.info(now, Time.FORMAT_SHORT);
        var day = (date.year * 13 + date.month) * 32 + date.day;
        var locationChanged = false;
        if (_sunWeatherTick != _weatherCacheTick) {
            _sunWeatherTick = _weatherCacheTick;
            // Retry unavailable sun data when fresh weather/location arrives.
            if (_cachedSunrise == null) { _sunriseCached = false; }
            if (_cachedSunset == null) { _sunsetCached = false; }
            var location = null;
            if (conditions != null && conditions.observationLocationPosition != null) {
                location = conditions.observationLocationPosition.toDegrees();
            }
            locationChanged = (location == null) != (_sunLocation == null);
            if (location != null && _sunLocation != null) {
                var coordinates = location as Lang.Array;
                locationChanged = coordinates[0] != _sunLocation[0] || coordinates[1] != _sunLocation[1];
            }
            _sunLocation = location;
        }
        if (_sunCacheTick != day || locationChanged) {
            _sunCacheTick = day;
            _sunriseCached = false;
            _sunsetCached = false;
            _cachedSunrise = null;
            _cachedSunset = null;
        }
        if (rising && _sunriseCached) { return _cachedSunrise; }
        if (!rising && _sunsetCached) { return _cachedSunset; }

        var moment = null;
        try {
            if (conditions == null) {
                reportSunDiagnostic(1, "Sun data: weather conditions are unavailable");
            } else if (conditions.observationLocationPosition == null) {
                reportSunDiagnostic(2, "Sun data: weather location is unavailable; check Positioning permission and weather sync");
            } else if (rising) {
                if (!(Weather has :getSunrise)) {
                    reportSunDiagnostic(3, "Sun data: Weather.getSunrise is unsupported");
                } else {
                    moment = Weather.getSunrise(conditions.observationLocationPosition, Time.today());
                    if (moment == null) {
                        reportSunDiagnostic(4, "Sun data: Weather.getSunrise returned null");
                    } else {
                        _sunDiagnostic = 0;
                    }
                }
            } else if (!(Weather has :getSunset)) {
                reportSunDiagnostic(5, "Sun data: Weather.getSunset is unsupported");
            } else {
                moment = Weather.getSunset(conditions.observationLocationPosition, Time.today());
                if (moment == null) {
                    reportSunDiagnostic(6, "Sun data: Weather.getSunset returned null");
                } else {
                    _sunDiagnostic = 0;
                }
            }
        } catch (e) {
            reportSunDiagnostic(7, "Sun data: calculation raised an exception");
        }
        if (rising) {
            if (moment != null) { _cachedSunrise = moment; }
            _sunriseCached = true;
        } else {
            if (moment != null) { _cachedSunset = moment; }
            _sunsetCached = true;
        }
        return rising ? _cachedSunrise : _cachedSunset;
    }

    private function extendedFieldValue(field as Lang.Number, activity, date, conditions, now as Time.Moment) {
        if (field == FIELD_DAILY_RUNNING_DISTANCE || field == FIELD_WEEKLY_RUNNING_DISTANCE ||
            field == FIELD_MONTHLY_RUNNING_DISTANCE || field == FIELD_YEARLY_RUNNING_DISTANCE ||
            field == FIELD_DAILY_CYCLING_DISTANCE || field == FIELD_WEEKLY_CYCLING_DISTANCE ||
            field == FIELD_MONTHLY_CYCLING_DISTANCE || field == FIELD_YEARLY_CYCLING_DISTANCE) {
            var distance = distanceFieldValue(field, date);
            return distance == null ? "--" : (distance / 1000.0).format("%.1f");
        }
        if (field == FIELD_WEEK_NUMBER) { return isoWeekNumber(date.year, date.month, date.day).format("%d"); }
        if (field == FIELD_NOTIFICATION_COUNT) {
            return _cachedDeviceSettings == null || !(_cachedDeviceSettings has :notificationCount) || _cachedDeviceSettings.notificationCount == null ? "--" : _cachedDeviceSettings.notificationCount.format("%d");
        }
        if (field == FIELD_HIGH_TEMPERATURE) {
            return conditions == null || !(conditions has :highTemperature) ? "--" : formatTemperature(conditions.highTemperature);
        }
        if (field == FIELD_LOW_TEMPERATURE) {
            return conditions == null || !(conditions has :lowTemperature) ? "--" : formatTemperature(conditions.lowTemperature);
        }
        if (field == FIELD_PRECIPITATION_CHANCE) {
            return conditions == null || !(conditions has :precipitationChance) || conditions.precipitationChance == null ? "--" : conditions.precipitationChance.format("%d") + "%";
        }
        if (field == FIELD_DAY_NIGHT) { return daylightValue(conditions, now, true); }
        if (field == FIELD_DAYLIGHT_REMAINING) { return daylightValue(conditions, now, false); }
        if (field == FIELD_HEART_RATE_ZONE) { return heartRateZone(); }
        if (field == FIELD_SOLAR_TERM) { return solarTermText(date); }
        if (field == FIELD_AVG_RESTING_HR) {
            var averageRest = cachedAverageRestingHeartRate();
            return averageRest == null ? "--" : averageRest.format("%d");
        }
        if (field == FIELD_ALARM_COUNT) {
            return _cachedDeviceSettings == null || !(_cachedDeviceSettings has :alarmCount) || _cachedDeviceSettings.alarmCount == null ? "--" : _cachedDeviceSettings.alarmCount.format("%d");
        }
        if (field == FIELD_RESPIRATION_RATE) {
            return activity == null || !(activity has :respirationRate) || activity.respirationRate == null ? "--" : activity.respirationRate.format("%.0f");
        }
        if (field == FIELD_WEATHER_CONDITION) { return conditions == null ? "--" : weatherText(conditions.condition); }
        if (field == FIELD_NEXT_SUN_EVENT) { return formatMoment(nextSunEvent(conditions, now)); }
        if (field == FIELD_LOCATION_NAME) { return _cachedLocationName; }
        if (field == FIELD_UV_INDEX) {
            return conditions == null || !(conditions has :uvIndex) || conditions.uvIndex == null ? "--" : conditions.uvIndex.format("%.0f");
        }
        return null;
    }

    private function fieldValue(field as Lang.Number, battery as Lang.Number, activity, clock as System.ClockTime, date, conditions, now as Time.Moment) as Lang.String {
        // A small number of fields need ActivityMonitor.Info; if the system
        // has not made it available, return "--" instead of dereferencing null.
        if (activity == null) {
            if (field == FIELD_STEPS || field == FIELD_FLOORS || field == FIELD_DISTANCE ||
                field == FIELD_ACTIVE_MINUTES || field == FIELD_STEP_GOAL || field == FIELD_CALORIES ||
                field == FIELD_TOTAL_CALORIES || field == FIELD_RESTING_CALORIES ||
                field == FIELD_FLOORS_DESCENDED || field == FIELD_ACTIVE_MINUTES_WEEK ||
                field == FIELD_ACTIVE_MINUTES_WEEK_GOAL || field == FIELD_RESPIRATION_RATE) {
                return "--";
            }
        }
        var extended = extendedFieldValue(field, activity, date, conditions, now);
        if (extended != null) { return extended; }
        if (field == FIELD_STEPS) {
            return (!(activity has :steps) || activity.steps == null) ? "--" : activity.steps.format("%d");
        }
        if (field == FIELD_FLOORS) {
            return (!(activity has :floorsClimbed) || activity.floorsClimbed == null) ? "--" : activity.floorsClimbed.format("%d");
        }
        if (field == FIELD_CALORIES) {
            var active = activeCalories(activity);
            return active == null ? "--" : active.format("%d");
        }
        if (field == FIELD_DISTANCE) {
            return (!(activity has :distance) || activity.distance == null) ? "--" : (activity.distance / 100000.0).format("%.1f");
        }
        if (field == FIELD_BATTERY) { return _batteryKnown ? battery.format("%d") + "%" : "--"; }
        if (field == FIELD_STRESS) {
            var stress = _cachedStress;
            return stress == null ? "--" : stress.toNumber().format("%d");
        }
        if (field == FIELD_HEART) {
            var hr = _cachedHeartRate;
            return hr == null ? "--" : hr.toNumber().format("%d");
        }
        if (field == FIELD_BODY_BATTERY) {
            var bb = _cachedBodyBattery;
            return bb == null ? "--" : bb.toNumber().format("%d") + "%";
        }
        if (field == FIELD_SLEEP_SCORE) {
            return _cachedSleepScore == null ? "--" : _cachedSleepScore.format("%d");
        }
        if (field == FIELD_SECONDS) { return clock.sec.format("%02d"); }
        if (field == FIELD_DATE) {
            return Lang.format(text(Rez.Strings.DatePattern), [date.month, date.day]);
        }
        if (field == FIELD_WEEKDAY) { return weekdayText(date.day_of_week); }
        if (field == FIELD_TEMPERATURE) {
            var temperature = weatherTemperature(conditions);
            return formatTemperature(temperature);
        }
        if (field == FIELD_RECOVERY) {
            var recovery = cachedRecoveryHours(now.value());
            if (recovery == null) { return "--"; }
            if (recovery < 9.9 && recovery != 0) { return recovery.format("%.1f") + "h"; }
            return Math.round(recovery).format("%d") + "h";
        }
        if (field == FIELD_ACTIVE_MINUTES) {
            var mins = activeMinutesTotal(activity);
            return mins == null ? "--" : mins.format("%d");
        }
        if (field == FIELD_STEP_GOAL) {
            var goal = stepGoalPercent(activity);
            return goal == null ? "--" : goal.format("%d") + "%";
        }
        if (field == FIELD_SUNRISE) { return formatMoment(sunMoment(conditions, now, true)); }
        if (field == FIELD_SUNSET) { return formatMoment(sunMoment(conditions, now, false)); }
        if (field == FIELD_RESTING_HR) {
            var rest = _cachedRestingHeartRate;
            return rest == null ? "--" : rest.format("%d");
        }
        if (field == FIELD_ELEVATION) {
            var elev = _cachedElevation;
            return elev == null ? "--" : elev.toNumber().format("%d") + "m";
        }
        if (field == FIELD_PRESSURE) {
            var press = _cachedPressure;
            return press == null ? "--" : (press.toFloat() / 100.0).format("%.0f");
        }
        if (field == FIELD_SPO2) {
            var spo2 = _cachedSpo2;
            return spo2 == null ? "--" : spo2.toNumber().format("%d") + "%";
        }
        if (field == FIELD_LUNAR) { return lunarDate(date, false); }
        if (field == FIELD_TOTAL_CALORIES) {
            return (!(activity has :calories) || activity.calories == null) ? "--" : activity.calories.format("%d");
        }
        if (field == FIELD_RESTING_CALORIES) {
            var resting = restingCalories(activity);
            return resting == null ? "--" : resting.format("%d");
        }
        if (field == FIELD_FLOORS_DESCENDED) {
            return (!(activity has :floorsDescended) || activity.floorsDescended == null) ? "--" : activity.floorsDescended.format("%d");
        }
        if (field == FIELD_ACTIVE_MINUTES_WEEK) {
            var weekMinutes = activeMinutesWeekTotal(activity);
            return weekMinutes == null ? "--" : weekMinutes.format("%d");
        }
        if (field == FIELD_ACTIVE_MINUTES_WEEK_GOAL) {
            var weekGoal = activeMinutesWeekGoalPercent(activity);
            return weekGoal == null ? "--" : weekGoal.format("%d") + "%";
        }
        if (field == FIELD_BATTERY_DAYS) {
            var days = batteryDaysRemaining();
            return days == null ? "--" : days.format("%.1f") + "d";
        }
        if (field == FIELD_HUMIDITY) {
            return conditions == null || !(conditions has :relativeHumidity) || conditions.relativeHumidity == null ? "--" : conditions.relativeHumidity.format("%d") + "%";
        }
        if (field == FIELD_VO2MAX_RUNNING) {
            var vo2max = cachedVo2maxRunning();
            return vo2max == null ? "--" : vo2max.format("%.0f");
        }
        if (field == FIELD_SOLAR_INTENSITY) {
            var solar = cachedSolarIntensity();
            return solar == null ? "--" : solar.format("%d");
        }
        return "--";
    }

    private function weatherTemperature(conditions) {
        if (conditions != null && (conditions has :temperature) && conditions.temperature != null) {
            return conditions.temperature;
        }
        return _cachedWeatherTemperature;
    }

    private function cacheWeatherTemperature(conditions) as Lang.Boolean {
        if (conditions == null || !(conditions has :temperature) || conditions.temperature == null) {
            return false;
        }
        var temperature = conditions.temperature;
        if (_cachedWeatherTemperature == null || _cachedWeatherTemperature != temperature) {
            _cachedWeatherTemperature = temperature;
        }
        return true;
    }

    private function hasUsableWeather(conditions) as Lang.Boolean {
        if (conditions == null ||
            !(conditions has :observationTime) || conditions.observationTime == null) { return false; }
        var observed = Gregorian.info(conditions.observationTime, Time.FORMAT_SHORT);
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        if (observed.year != today.year || observed.month != today.month || observed.day != today.day) { return false; }
        if (conditions has :temperature && conditions.temperature != null) { return true; }
        if (conditions has :highTemperature && conditions.highTemperature != null) { return true; }
        if (conditions has :lowTemperature && conditions.lowTemperature != null) { return true; }
        if (conditions has :condition && conditions.condition != null) { return true; }
        if (conditions has :relativeHumidity && conditions.relativeHumidity != null) { return true; }
        if (conditions has :windSpeed && conditions.windSpeed != null) { return true; }
        if (conditions has :feelsLikeTemperature && conditions.feelsLikeTemperature != null) { return true; }
        if (conditions has :precipitationChance && conditions.precipitationChance != null) { return true; }
        if (conditions has :uvIndex && conditions.uvIndex != null) { return true; }
        if (conditions has :observationLocationPosition && conditions.observationLocationPosition != null) { return true; }
        return false;
    }

    // Missing fields do not erase valid values from the same local day.
    // Never merge yesterday's snapshot into a new observation.
    private function mergeWeather(conditions) {
        var merged = hasUsableWeather(_cachedConditions) ? _cachedConditions : new CNWatchFaceStoredWeather();
        merged.observationTime = conditions.observationTime;
        if (conditions has :temperature && conditions.temperature != null) { merged.temperature = conditions.temperature; }
        if (conditions has :condition && conditions.condition != null) { merged.condition = conditions.condition; }
        if (conditions has :highTemperature && conditions.highTemperature != null) { merged.highTemperature = conditions.highTemperature; }
        if (conditions has :lowTemperature && conditions.lowTemperature != null) { merged.lowTemperature = conditions.lowTemperature; }
        if (conditions has :precipitationChance && conditions.precipitationChance != null) { merged.precipitationChance = conditions.precipitationChance; }
        if (conditions has :relativeHumidity && conditions.relativeHumidity != null) { merged.relativeHumidity = conditions.relativeHumidity; }
        if (conditions has :feelsLikeTemperature && conditions.feelsLikeTemperature != null) { merged.feelsLikeTemperature = conditions.feelsLikeTemperature; }
        if (conditions has :windBearing && conditions.windBearing != null) { merged.windBearing = conditions.windBearing; }
        if (conditions has :windSpeed && conditions.windSpeed != null) { merged.windSpeed = conditions.windSpeed; }
        if (conditions has :uvIndex && conditions.uvIndex != null) { merged.uvIndex = conditions.uvIndex; }
        if (conditions has :observationLocationPosition && conditions.observationLocationPosition != null) { merged.observationLocationPosition = conditions.observationLocationPosition; }
        if (conditions has :observationLocationName && conditions.observationLocationName != null && conditions.observationLocationName.length() > 0) { merged.observationLocationName = conditions.observationLocationName; }
        return merged;
    }

    private function updateLocationNameCache(conditions) as Void {
        if (conditions == null || !(conditions has :observationLocationName) ||
            conditions.observationLocationName == null || conditions.observationLocationName.length() == 0) {
            return;
        }
        var locationName = conditions.observationLocationName as Lang.String;
        if (_cachedLocationName.equals(locationName)) { return; }
        _cachedLocationName = locationName;
    }

    private function storeWeatherCache(conditions) as Void {
        if (!hasUsableWeather(conditions)) { return; }
        var data = {};
        data["observationTime"] = conditions.observationTime.value();
        data["temperature"] = conditions.temperature;
        if (conditions has :condition && conditions.condition != null) { data["condition"] = conditions.condition; }
        if (conditions has :highTemperature && conditions.highTemperature != null) { data["highTemperature"] = conditions.highTemperature; }
        if (conditions has :lowTemperature && conditions.lowTemperature != null) { data["lowTemperature"] = conditions.lowTemperature; }
        if (conditions has :precipitationChance && conditions.precipitationChance != null) { data["precipitationChance"] = conditions.precipitationChance; }
        if (conditions has :relativeHumidity && conditions.relativeHumidity != null) { data["relativeHumidity"] = conditions.relativeHumidity; }
        if (conditions has :feelsLikeTemperature && conditions.feelsLikeTemperature != null) { data["feelsLikeTemperature"] = conditions.feelsLikeTemperature; }
        if (conditions has :windBearing && conditions.windBearing != null) { data["windBearing"] = conditions.windBearing; }
        if (conditions has :windSpeed && conditions.windSpeed != null) { data["windSpeed"] = conditions.windSpeed; }
        if (conditions has :uvIndex && conditions.uvIndex != null) { data["uvIndex"] = conditions.uvIndex; }
        if (conditions has :observationLocationPosition && conditions.observationLocationPosition != null) {
            data["location"] = conditions.observationLocationPosition.toDegrees();
        }
        if (_cachedLocationName != "--") {
            data["observationLocationName"] = _cachedLocationName;
        }
        if (sameWeatherSnapshot(data)) { return; }
        try {
            Application.Storage.setValue(WEATHER_STORAGE_KEY, data);
            _storedWeatherSnapshot = data;
        } catch (e) {
            // Storage is an enhancement; the live cache remains usable.
        }
    }

    private function sameWeatherSnapshot(data as Lang.Dictionary) as Lang.Boolean {
        if (_storedWeatherSnapshot == null || data.size() != _storedWeatherSnapshot.size()) { return false; }
        var keys = data.keys();
        for (var i = 0; i < keys.size(); i += 1) {
            var key = keys[i];
            var value = data[key];
            var previous = _storedWeatherSnapshot.get(key);
            if (value instanceof Lang.Array) {
                if (!(previous instanceof Lang.Array) || value.size() != previous.size()) { return false; }
                for (var j = 0; j < value.size(); j += 1) {
                    if (value[j] != previous[j]) { return false; }
                }
            } else if (value instanceof Lang.String) {
                if (!(previous instanceof Lang.String) || !value.equals(previous)) { return false; }
            } else if (value != previous) { return false; }
        }
        return true;
    }

    private function readWeatherCache() {
        try {
            var data = Application.Storage.getValue(WEATHER_STORAGE_KEY);
            if (!(data instanceof Lang.Dictionary) ||
                !(data.get("observationTime") instanceof Lang.Number)) { return null; }
            // Treat persisted cache data as optional input. Invalid fields
            // must not prevent the face from starting after an update.
            var numericKeys = ["temperature", "condition", "highTemperature", "lowTemperature",
                "precipitationChance", "relativeHumidity", "feelsLikeTemperature", "windBearing", "windSpeed", "uvIndex"];
            for (var i = 0; i < numericKeys.size(); i += 1) {
                var value = data.get(numericKeys[i]);
                if (value != null && !(value instanceof Lang.Number || value instanceof Lang.Float ||
                    value instanceof Lang.Long || value instanceof Lang.Double)) { return null; }
            }
            var stored = new CNWatchFaceStoredWeather();
            stored.observationTime = new Time.Moment(data.get("observationTime") as Lang.Number);
            stored.temperature = data.get("temperature") as Lang.Numeric;
            stored.condition = data.get("condition") as Lang.Number;
            stored.highTemperature = data.get("highTemperature") as Lang.Numeric;
            stored.lowTemperature = data.get("lowTemperature") as Lang.Numeric;
            stored.precipitationChance = data.get("precipitationChance") as Lang.Number;
            stored.relativeHumidity = data.get("relativeHumidity") as Lang.Number;
            stored.feelsLikeTemperature = data.get("feelsLikeTemperature") as Lang.Float;
            stored.windBearing = data.get("windBearing") as Lang.Number;
            stored.windSpeed = data.get("windSpeed") as Lang.Float;
            stored.uvIndex = data.get("uvIndex") as Lang.Float;
            var location = data.get("location");
            if (location instanceof Lang.Array && location.size() >= 2 &&
                isNumberInRange(location[0], -90, 90) && isNumberInRange(location[1], -180, 180)) {
                stored.observationLocationPosition = new Position.Location({
                    :latitude => location[0], :longitude => location[1], :format => :degrees
                });
            }
            var locationName = data.get("observationLocationName");
            stored.observationLocationName = locationName instanceof Lang.String ? locationName : null;
            if (hasUsableWeather(stored)) { _storedWeatherSnapshot = data; }
            return stored;
        } catch (e) {
            return null;
        }
    }

    private function weatherValue(kind as Lang.Number, conditions) as Lang.String {
        if (kind == WX_HIDDEN) { return ""; }
        if (kind == WX_TEMP) {
            var temperature = weatherTemperature(conditions);
            return formatTemperature(temperature);
        }
        if (conditions == null) { return "--"; }
        if (kind == WX_WIND) {
            if (conditions.windSpeed == null) { return "--"; }
            // m/s -> km/h
            return (conditions.windSpeed * 3.6).format("%.0f") + " km/h";
        }
        if (kind == WX_HIGH_LOW) {
            return formatTemperatureRange(conditions.highTemperature, conditions.lowTemperature);
        }
        if (kind == WX_CONDITION) {
            return weatherText(conditions.condition);
        }
        if (kind == WX_PRECIP) {
            if (conditions.precipitationChance == null) { return "--"; }
            return conditions.precipitationChance.format("%d") + "%";
        }
        if (kind == WX_FEELS) {
            return formatTemperature(conditions.feelsLikeTemperature);
        }
        return "--";
    }

    private function weatherText(condition) as Lang.String {
        if (condition == null) { return text(Rez.Strings.WEATHER_NA); }
        if (condition == 0) { return text(Rez.Strings.WEATHER_0); }
        if (condition == 1) { return text(Rez.Strings.WEATHER_1); }
        if (condition == 2) { return text(Rez.Strings.WEATHER_2); }
        if (condition == 3) { return text(Rez.Strings.WEATHER_3); }
        if (condition == 4) { return text(Rez.Strings.WEATHER_4); }
        if (condition == 5) { return text(Rez.Strings.WEATHER_5); }
        if (condition == 6) { return text(Rez.Strings.WEATHER_6); }
        if (condition == 7) { return text(Rez.Strings.WEATHER_7); }
        if (condition == 8) { return text(Rez.Strings.WEATHER_8); }
        if (condition == 9) { return text(Rez.Strings.WEATHER_9); }
        if (condition == 10) { return text(Rez.Strings.WEATHER_10); }
        if (condition == 11) { return text(Rez.Strings.WEATHER_11); }
        if (condition == 12) { return text(Rez.Strings.WEATHER_12); }
        if (condition == 13) { return text(Rez.Strings.WEATHER_13); }
        if (condition == 14) { return text(Rez.Strings.WEATHER_14); }
        if (condition == 15) { return text(Rez.Strings.WEATHER_15); }
        if (condition == 16) { return text(Rez.Strings.WEATHER_16); }
        if (condition == 17) { return text(Rez.Strings.WEATHER_17); }
        if (condition == 18) { return text(Rez.Strings.WEATHER_18); }
        if (condition == 19) { return text(Rez.Strings.WEATHER_19); }
        if (condition == 20) { return text(Rez.Strings.WEATHER_20); }
        if (condition == 21) { return text(Rez.Strings.WEATHER_21); }
        if (condition == 22) { return text(Rez.Strings.WEATHER_22); }
        if (condition == 23) { return text(Rez.Strings.WEATHER_23); }
        if (condition == 24) { return text(Rez.Strings.WEATHER_24); }
        if (condition == 25) { return text(Rez.Strings.WEATHER_25); }
        if (condition == 26) { return text(Rez.Strings.WEATHER_26); }
        if (condition == 27) { return text(Rez.Strings.WEATHER_27); }
        if (condition == 28) { return text(Rez.Strings.WEATHER_28); }
        if (condition == 29) { return text(Rez.Strings.WEATHER_29); }
        if (condition == 30) { return text(Rez.Strings.WEATHER_30); }
        if (condition == 31) { return text(Rez.Strings.WEATHER_31); }
        if (condition == 32) { return text(Rez.Strings.WEATHER_32); }
        if (condition == 33) { return text(Rez.Strings.WEATHER_33); }
        if (condition == 34) { return text(Rez.Strings.WEATHER_34); }
        if (condition == 35) { return text(Rez.Strings.WEATHER_35); }
        if (condition == 36) { return text(Rez.Strings.WEATHER_36); }
        if (condition == 37) { return text(Rez.Strings.WEATHER_37); }
        if (condition == 38) { return text(Rez.Strings.WEATHER_38); }
        if (condition == 39) { return text(Rez.Strings.WEATHER_39); }
        if (condition == 40) { return text(Rez.Strings.WEATHER_40); }
        if (condition == 41) { return text(Rez.Strings.WEATHER_41); }
        if (condition == 42) { return text(Rez.Strings.WEATHER_42); }
        if (condition == 43) { return text(Rez.Strings.WEATHER_43); }
        if (condition == 44) { return text(Rez.Strings.WEATHER_44); }
        if (condition == 45) { return text(Rez.Strings.WEATHER_45); }
        if (condition == 46) { return text(Rez.Strings.WEATHER_46); }
        if (condition == 47) { return text(Rez.Strings.WEATHER_47); }
        if (condition == 48) { return text(Rez.Strings.WEATHER_48); }
        if (condition == 49) { return text(Rez.Strings.WEATHER_49); }
        if (condition == 50) { return text(Rez.Strings.WEATHER_50); }
        if (condition == 51) { return text(Rez.Strings.WEATHER_51); }
        if (condition == 52) { return text(Rez.Strings.WEATHER_52); }
        if (condition == 53) { return text(Rez.Strings.WEATHER_53); }
        return text(Rez.Strings.WEATHER_53);
    }

    private function weekdayText(day as Lang.Number) as Lang.String {
        if (day == 1) { return text(Rez.Strings.DAY_OF_WEEK_SUN); }
        if (day == 2) { return text(Rez.Strings.DAY_OF_WEEK_MON); }
        if (day == 3) { return text(Rez.Strings.DAY_OF_WEEK_TUE); }
        if (day == 4) { return text(Rez.Strings.DAY_OF_WEEK_WED); }
        if (day == 5) { return text(Rez.Strings.DAY_OF_WEEK_THU); }
        if (day == 6) { return text(Rez.Strings.DAY_OF_WEEK_FRI); }
        return text(Rez.Strings.DAY_OF_WEEK_SAT);
    }

    private function isChineseCalendar() as Lang.Boolean {
        return text(Rez.Strings.CalendarLanguage).equals("zh");
    }

    private function drawMdiIcon(dc as Graphics.Dc, resourceId as Lang.ResourceId, px as Lang.Number, py as Lang.Number, color as Lang.Number) as Lang.Boolean {
        if (!(Graphics has :AffineTransform)) { return false; }
        try {
            if (!_iconCache.hasKey(resourceId)) {
                // Five custom fields, two status icons and two weather icons
                // must fit together without evicting one another every frame.
                if (_iconCacheOrder.size() >= 12) {
                    _iconCache.remove(_iconCacheOrder[0]);
                    _iconCacheOrder = _iconCacheOrder.slice(1, null);
                }
                _iconCache[resourceId] = WatchUi.loadResource(resourceId);
                _iconCacheOrder.add(resourceId);
            }
            var bitmap = _iconCache[resourceId];
            var size = scalePx(16);
            var transform = new Graphics.AffineTransform();
            var scale = size / 24.0;
            transform.scale(scale, scale);
            var options = {:tintColor => color, :transform => transform};
            if (isAmoledLayout() && (Graphics has :FILTER_MODE_BILINEAR)) {
                options[:filterMode] = Graphics.FILTER_MODE_BILINEAR;
            }
            dc.drawBitmap2(px - (size / 2).toNumber(), py - (size / 2).toNumber(), bitmap, options);
            return true;
        } catch (e) {
            return false;
        }
    }

    private function fieldIconResource(field as Lang.Number) as Lang.ResourceId or Null {
        if (field == FIELD_STEPS) { return Rez.Drawables.MdiShoePrint; }
        if (field == FIELD_FLOORS || field == FIELD_FLOORS_DESCENDED) { return Rez.Drawables.MdiStairs; }
        if (field == FIELD_CALORIES || field == FIELD_TOTAL_CALORIES || field == FIELD_RESTING_CALORIES) { return Rez.Drawables.MdiFire; }
        if (field == FIELD_DAILY_CYCLING_DISTANCE || field == FIELD_WEEKLY_CYCLING_DISTANCE ||
            field == FIELD_MONTHLY_CYCLING_DISTANCE || field == FIELD_YEARLY_CYCLING_DISTANCE) { return Rez.Drawables.MdiBike; }
        if (field == FIELD_DISTANCE || field == FIELD_DAILY_RUNNING_DISTANCE || field == FIELD_WEEKLY_RUNNING_DISTANCE ||
            field == FIELD_MONTHLY_RUNNING_DISTANCE || field == FIELD_YEARLY_RUNNING_DISTANCE) { return Rez.Drawables.MdiMapMarkerDistance; }
        if (field == FIELD_BODY_BATTERY) { return Rez.Drawables.BodyBatteryIcon; }
        if (field == FIELD_SLEEP_SCORE) { return Rez.Drawables.MdiWeatherNight; }
        if (field == FIELD_BATTERY || field == FIELD_BATTERY_DAYS) { return Rez.Drawables.MdiBattery; }
        if (field == FIELD_HEART || field == FIELD_RESTING_HR || field == FIELD_AVG_RESTING_HR || field == FIELD_HEART_RATE_ZONE) { return Rez.Drawables.MdiHeart; }
        if (field == FIELD_STRESS) { return Rez.Drawables.MdiBrain; }
        if (field == FIELD_SUNRISE) { return Rez.Drawables.MdiSunrise; }
        if (field == FIELD_SUNSET) { return Rez.Drawables.MdiSunset; }
        if (field == FIELD_TEMPERATURE || field == FIELD_HIGH_TEMPERATURE || field == FIELD_LOW_TEMPERATURE) { return Rez.Drawables.MdiThermometer; }
        if (field == FIELD_HUMIDITY) { return Rez.Drawables.MdiWaterPercent; }
        if (field == FIELD_ELEVATION) { return Rez.Drawables.MdiTerrain; }
        if (field == FIELD_PRESSURE) { return Rez.Drawables.MdiGauge; }
        if (field == FIELD_SPO2) { return Rez.Drawables.MdiMolecule; }
        if (field == FIELD_SECONDS) { return Rez.Drawables.MdiClock; }
        if (field == FIELD_DATE || field == FIELD_WEEKDAY || field == FIELD_LUNAR || field == FIELD_WEEK_NUMBER || field == FIELD_SOLAR_TERM) { return Rez.Drawables.MdiCalendar; }
        if (field == FIELD_RECOVERY || field == FIELD_VO2MAX_RUNNING) { return Rez.Drawables.MdiHeartPulse; }
        if (field == FIELD_ACTIVE_MINUTES || field == FIELD_ACTIVE_MINUTES_WEEK || field == FIELD_STEP_GOAL || field == FIELD_ACTIVE_MINUTES_WEEK_GOAL) { return Rez.Drawables.MdiTarget; }
        if (field == FIELD_SOLAR_INTENSITY || field == FIELD_NEXT_SUN_EVENT) { return Rez.Drawables.MdiSunny; }
        if (field == FIELD_DAY_NIGHT || field == FIELD_DAYLIGHT_REMAINING) { return Rez.Drawables.MdiWeatherNight; }
        if (field == FIELD_RESPIRATION_RATE) { return Rez.Drawables.MdiWaves; }
        if (field == FIELD_NOTIFICATION_COUNT) { return Rez.Drawables.MdiBell; }
        if (field == FIELD_ALARM_COUNT) { return Rez.Drawables.MdiAlarm; }
        if (field == FIELD_PRECIPITATION_CHANCE) { return Rez.Drawables.MdiWeatherRainy; }
        if (field == FIELD_WEATHER_CONDITION) { return Rez.Drawables.MdiWeatherPartlyCloudy; }
        if (field == FIELD_LOCATION_NAME) { return Rez.Drawables.MdiMapMarker; }
        if (field == FIELD_UV_INDEX) { return Rez.Drawables.MdiSunny; }
        return null;
    }

    private function weatherIconResource(kind as Lang.Number) as Lang.ResourceId or Null {
        if (kind == WX_TEMP || kind == WX_FEELS) { return Rez.Drawables.MdiThermometer; }
        if (kind == WX_WIND) { return Rez.Drawables.MdiWeatherWindy; }
        if (kind == WX_HIGH_LOW) { return Rez.Drawables.MdiArrowExpandVertical; }
        if (kind == WX_CONDITION) { return Rez.Drawables.MdiWeatherPartlyCloudy; }
        if (kind == WX_PRECIP) { return Rez.Drawables.MdiWeatherRainy; }
        return null;
    }

    private function drawHeartIcon(dc as Graphics.Dc, px as Lang.Number, py as Lang.Number, color as Lang.Number) as Void {
        if (drawMdiIcon(dc, Rez.Drawables.MdiHeart, px, py, color)) { return; }
        var u1 = scalePx(1);
        var u3 = scalePx(3);
        var u6 = scalePx(6);
        var u7 = scalePx(7);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(px - u3, py - u1, u3);
        dc.fillCircle(px + u3, py - u1, u3);
        dc.fillPolygon([
            [px - u6, py],
            [px + u6, py],
            [px, py + u7]
        ]);
    }

    // Compact-device fallback for the Apache-2.0 MDI body-battery icon.
    private function drawBodyBatteryIcon(dc as Graphics.Dc, px as Lang.Number, py as Lang.Number, color as Lang.Number) as Void {
        var u1 = scalePx(1);
        var u2 = scalePx(2);
        var u3 = scalePx(3);
        var u4 = scalePx(4);
        var u5 = scalePx(5);
        var u6 = scalePx(6);
        var u7 = scalePx(7);
        var u8 = scalePx(8);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(u1);
        dc.drawLine(px - u5, py - u7, px + u5, py - u7);
        dc.fillRectangle(px - u5, py - u8, u1, u1);
        dc.fillRectangle(px - u2, py - u8, u1, u2);
        dc.fillRectangle(px + u1, py - u8, u1, u3);
        dc.fillRectangle(px + u4, py - u8, u1, u4);
        dc.drawCircle(px, py - u3, u2);
        dc.drawLine(px, py - u1, px, py + u3);
        dc.drawLine(px, py, px - u4, py - u6);
        dc.drawLine(px, py, px + u4, py - u6);
        dc.drawLine(px, py + u3, px - u3, py + u6);
        dc.drawLine(px, py + u3, px + u3, py + u6);
    }

    private function drawFieldIcon(dc as Graphics.Dc, field as Lang.Number, px as Lang.Number, py as Lang.Number, color as Lang.Number) as Void {
        var resourceId = fieldIconResource(field);
        if (resourceId != null && drawMdiIcon(dc, resourceId, px, py, color)) { return; }
        var u1 = scalePx(1);
        var u2 = scalePx(2);
        var u3 = scalePx(3);
        var u4 = scalePx(4);
        var u5 = scalePx(5);
        var u6 = scalePx(6);
        var u8 = scalePx(8);
        var u9 = scalePx(9);
        var u10 = scalePx(10);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(u1);
        if (field == FIELD_STEPS) {
            dc.drawEllipse(px, py, u5, u3);
            dc.drawLine(px - u3, py + u2, px + u4, py + u2);
        } else if (field == FIELD_FLOORS || field == FIELD_FLOORS_DESCENDED) {
            dc.drawLine(px - u4, py + u4, px, py - u4);
            dc.drawLine(px, py - u4, px + u4, py + u4);
            dc.drawLine(px - u2, py + u1, px + u2, py + u1);
        } else if (field == FIELD_CALORIES || field == FIELD_TOTAL_CALORIES || field == FIELD_RESTING_CALORIES) {
            dc.drawEllipse(px, py, u3, u5);
            dc.fillCircle(px, py - u2, u1);
        } else if (field == FIELD_DAILY_CYCLING_DISTANCE || field == FIELD_WEEKLY_CYCLING_DISTANCE ||
                   field == FIELD_MONTHLY_CYCLING_DISTANCE || field == FIELD_YEARLY_CYCLING_DISTANCE) {
            dc.drawCircle(px - u4, py + u2, u3);
            dc.drawCircle(px + u4, py + u2, u3);
            dc.drawLine(px - u4, py + u2, px - u1, py - u3);
            dc.drawLine(px - u1, py - u3, px + u2, py + u2);
            dc.drawLine(px + u2, py + u2, px - u4, py + u2);
            dc.drawLine(px - u1, py - u3, px + u4, py - u3);
            dc.drawLine(px + u4, py - u3, px + u4, py + u2);
        } else if (field == FIELD_DISTANCE || field == FIELD_DAILY_RUNNING_DISTANCE ||
                   field == FIELD_WEEKLY_RUNNING_DISTANCE || field == FIELD_MONTHLY_RUNNING_DISTANCE ||
                   field == FIELD_YEARLY_RUNNING_DISTANCE) {
            dc.drawLine(px - u5, py + u3, px + u5, py - u3);
            dc.fillCircle(px - u5, py + u3, u1);
            dc.fillCircle(px + u5, py - u3, u1);
        } else if (field == FIELD_BODY_BATTERY) {
            drawBodyBatteryIcon(dc, px, py, color);
        } else if (field == FIELD_BATTERY || field == FIELD_BATTERY_DAYS) {
            dc.drawRectangle(px - u5, py - u3, u9, u6);
            dc.fillRectangle(px + u4, py - u1, u2, u2);
            dc.fillRectangle(px - u3, py - u1, u5, u2);
        } else if (field == FIELD_HEART || field == FIELD_RESTING_HR || field == FIELD_AVG_RESTING_HR || field == FIELD_HEART_RATE_ZONE) {
            drawHeartIcon(dc, px, py, color);
        } else if (field == FIELD_STRESS) {
            dc.drawCircle(px, py, u4);
            dc.drawLine(px - u2, py, px, py + u2);
            dc.drawLine(px, py + u2, px + u2, py - u2);
        } else if (field == FIELD_SUNRISE) {
            drawSunEventIcon(dc, px, py, color, true);
        } else if (field == FIELD_SUNSET) {
            drawSunEventIcon(dc, px, py, color, false);
        } else if (field == FIELD_TEMPERATURE || field == FIELD_HIGH_TEMPERATURE || field == FIELD_LOW_TEMPERATURE) {
            dc.drawCircle(px, py + u2, u3);
            dc.drawLine(px, py - u5, px, py);
        } else if (field == FIELD_HUMIDITY) {
            dc.fillCircle(px, py - u2, u3);
            dc.fillPolygon([[px - u3, py], [px + u3, py], [px, py + u5]]);
        } else if (field == FIELD_ELEVATION) {
            dc.drawLine(px - u5, py + u3, px - u1, py - u4);
            dc.drawLine(px - u1, py - u4, px + u2, py + u1);
            dc.drawLine(px + u2, py + u1, px + u5, py - u2);
            dc.drawLine(px - u5, py + u3, px + u5, py + u3);
        } else if (field == FIELD_PRESSURE) {
            dc.drawCircle(px, py, u5);
            dc.drawLine(px, py, px + u3, py - u3);
        } else if (field == FIELD_SPO2) {
            dc.drawCircle(px, py, u4);
        } else if (field == FIELD_SECONDS) {
            dc.drawCircle(px, py, u5);
            dc.drawLine(px, py, px, py - u3);
            dc.drawLine(px, py, px + u3, py + u1);
        } else if (field == FIELD_DATE || field == FIELD_WEEKDAY || field == FIELD_LUNAR || field == FIELD_WEEK_NUMBER || field == FIELD_SOLAR_TERM) {
            dc.drawRectangle(px - u5, py - u4, u10, u8);
            dc.drawLine(px - u5, py - u1, px + u5, py - u1);
        } else if (field == FIELD_RECOVERY) {
            dc.drawArc(px, py, u5, Graphics.ARC_COUNTER_CLOCKWISE, 40, 320);
        } else if (field == FIELD_ACTIVE_MINUTES || field == FIELD_ACTIVE_MINUTES_WEEK ||
                   field == FIELD_STEP_GOAL || field == FIELD_ACTIVE_MINUTES_WEEK_GOAL) {
            dc.drawCircle(px, py, u5);
            dc.fillRectangle(px - u1, py - u3, u2, u4);
        } else if (field == FIELD_VO2MAX_RUNNING) {
            drawHeartIcon(dc, px, py, color);
            dc.fillCircle(px, py - u5, u1);
        } else if (field == FIELD_SOLAR_INTENSITY) {
            drawSunEventIcon(dc, px, py, color, true);
        } else if (field == FIELD_NEXT_SUN_EVENT) {
            dc.drawCircle(px, py, u4);
            dc.drawLine(px, py - u6, px, py - u4);
            dc.drawLine(px - u6, py, px - u4, py);
            dc.drawLine(px + u4, py, px + u6, py);
        } else if (field == FIELD_DAY_NIGHT || field == FIELD_DAYLIGHT_REMAINING) {
            drawSunEventIcon(dc, px, py, color, true);
        } else if (field == FIELD_RESPIRATION_RATE) {
            dc.drawCircle(px, py, u5);
            dc.drawLine(px - u3, py, px + u3, py);
        } else if (field == FIELD_NOTIFICATION_COUNT) {
            dc.drawRectangle(px - u5, py - u4, u10, u8);
            dc.fillCircle(px + u4, py - u4, u2);
        } else if (field == FIELD_ALARM_COUNT) {
            dc.drawCircle(px, py, u5);
            dc.drawLine(px, py, px, py - u3);
            dc.drawLine(px, py, px + u3, py + u1);
        } else if (field == FIELD_PRECIPITATION_CHANCE) {
            dc.fillCircle(px, py - u2, u3);
            dc.fillPolygon([[px - u3, py], [px + u3, py], [px, py + u5]]);
        } else if (field == FIELD_WEATHER_CONDITION) {
            dc.fillCircle(px + u3, py - u2, u3);
            dc.fillCircle(px - u2, py, u4);
            dc.fillRectangle(px - u5, py, u10, u3);
        } else if (field == FIELD_LOCATION_NAME) {
            dc.drawCircle(px, py - u2, u3);
            dc.drawLine(px - u3, py, px, py + u5);
            dc.drawLine(px + u3, py, px, py + u5);
        } else if (field == FIELD_UV_INDEX) {
            dc.drawCircle(px, py, u4);
            dc.drawLine(px, py - u6, px, py - u4);
            dc.drawLine(px - u6, py, px - u4, py);
            dc.drawLine(px + u4, py, px + u6, py);
        } else {
            dc.fillCircle(px, py, u2);
        }
    }

    private function drawWeatherIcon(dc as Graphics.Dc, kind as Lang.Number, px as Lang.Number, py as Lang.Number, color as Lang.Number) as Void {
        var resourceId = weatherIconResource(kind);
        if (resourceId != null && drawMdiIcon(dc, resourceId, px, py, color)) { return; }
        var u1 = scalePx(1);
        var u2 = scalePx(2);
        var u3 = scalePx(3);
        var u4 = scalePx(4);
        var u5 = scalePx(5);
        var u12 = scalePx(12);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(u1);
        if (kind == WX_TEMP || kind == WX_FEELS) {
            dc.drawCircle(px, py + u2, u3);
            dc.drawLine(px, py - u5, px, py);
        } else if (kind == WX_WIND) {
            dc.drawLine(px - u5, py, px + u5, py);
            dc.drawLine(px + u2, py - u3, px + u5, py);
            dc.drawLine(px + u2, py + u3, px + u5, py);
        } else if (kind == WX_HIGH_LOW) {
            dc.drawLine(px, py - u5, px, py + u5);
            dc.drawLine(px - u3, py - u2, px, py - u5);
            dc.drawLine(px + u3, py - u2, px, py - u5);
            dc.drawLine(px - u3, py + u2, px, py + u5);
            dc.drawLine(px + u3, py + u2, px, py + u5);
        } else if (kind == WX_CONDITION) {
            dc.fillCircle(px + u3, py - u2, u3);
            dc.fillCircle(px - u2, py, u4);
            dc.fillRectangle(px - u5, py, u12, u3);
        } else if (kind == WX_PRECIP) {
            dc.drawLine(px - u2, py - u4, px - u3, py + u3);
            dc.drawLine(px + u2, py - u3, px + u1, py + u4);
            dc.drawLine(px + u5, py - u2, px + u4, py + u3);
        }
        // WX_HIDDEN never reaches here; the caller (drawWeatherSlot) returns
        // early, so an "else" branch would be unreachable dead code.
    }

    private function drawTrendIcon(dc as Graphics.Dc, mode as Lang.Number, px as Lang.Number, py as Lang.Number, color as Lang.Number) as Void {
        if (mode == TREND_ELEVATION) {
            drawFieldIcon(dc, FIELD_ELEVATION, px, py, color);
        } else if (mode == TREND_STRESS) {
            drawFieldIcon(dc, FIELD_STRESS, px, py, color);
        } else if (mode == TREND_BODY_BATTERY) {
            drawFieldIcon(dc, FIELD_BODY_BATTERY, px, py, color);
        } else if (mode == TREND_PRESSURE) {
            drawFieldIcon(dc, FIELD_PRESSURE, px, py, color);
        } else if (mode == TREND_SPO2) {
            drawFieldIcon(dc, FIELD_SPO2, px, py, color);
        } else if (mode == TREND_TEMPERATURE) {
            if (drawMdiIcon(dc, Rez.Drawables.MdiThermometer, px, py, color)) { return; }
            // Sensor/body temperature (SensorHistory), not outdoor weather
            // temperature: same thermometer glyph plus a small sensor node so
            // it is not mistaken for the weather temp row.
            var u1 = scalePx(1);
            var u2 = scalePx(2);
            var u3 = scalePx(3);
            var u4 = scalePx(4);
            var u5 = scalePx(5);
            dc.drawCircle(px, py + u2, u3);
            dc.drawLine(px, py - u5, px, py);
            dc.fillCircle(px + u5, py - u4, u1);
        } else {
            drawHeartIcon(dc, px, py, color);
        }
    }

    // Monkey C supports a limited number of method arguments on older devices.
    // Keep the runtime data together so this helper remains portable.
    private function fitLocationValue(dc as Graphics.Dc, value as Lang.String) as Lang.String {
        var maxWidth = scalePx(48);
        if (dc.getTextWidthInPixels(value, smallFieldFont(dc)) <= maxWidth) { return value; }
        var suffix = "..";
        var end = value.length();
        while (end > 1) {
            var candidate = value.substring(0, end) + suffix;
            if (dc.getTextWidthInPixels(candidate, smallFieldFont(dc)) <= maxWidth) { return candidate; }
            end -= 1;
        }
        return value.substring(0, 1);
    }

    private function drawCompactField(dc as Graphics.Dc, field as Lang.Number, cx as Lang.Number, cy as Lang.Number, color as Lang.Number, textColor as Lang.Number, battery as Lang.Number, context as Lang.Array) as Void {
        if (field == FIELD_HIDDEN) { return; }
        var value = fieldValue(field, battery, context[0], context[1], context[2], context[3], context[4]);
        if (field == FIELD_LOCATION_NAME) { value = fitLocationValue(dc, value); }
        var iconSpace = scalePx(14);
        var textWidth = temperatureTextWidth(dc, value);
        var left = cx - ((iconSpace + textWidth) / 2).toNumber();
        drawFieldIcon(dc, field, left + scalePx(6), cy, color);
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        drawTemperatureText(dc, left + iconSpace, cy, value,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // The right-most AMOLED field sits on the narrowest part of the round
    // screen. Put its text toward the center and the icon toward the rim so
    // long values cannot be clipped by the circular display mask.
    private function drawRightCompactField(dc as Graphics.Dc, field as Lang.Number, cx as Lang.Number, cy as Lang.Number, color as Lang.Number, textColor as Lang.Number, battery as Lang.Number, context as Lang.Array) as Void {
        if (field == FIELD_HIDDEN) { return; }
        var value = fieldValue(field, battery, context[0], context[1], context[2], context[3], context[4]);
        if (field == FIELD_LOCATION_NAME) { value = fitLocationValue(dc, value); }
        var iconSpace = scalePx(14);
        var textWidth = temperatureTextWidth(dc, value);
        var left = cx - ((iconSpace + textWidth) / 2).toNumber();
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        drawTemperatureText(dc, left, cy, value,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        drawFieldIcon(dc, field, left + textWidth + scalePx(8), cy, color);
    }

    private function drawWeatherSlot(dc as Graphics.Dc, kind as Lang.Number, cx as Lang.Number, cy as Lang.Number, color as Lang.Number, textColor as Lang.Number, conditions) as Void {
        if (kind == WX_HIDDEN) { return; }
        // This row sits near the bottom of a round display, where the usable
        // horizontal chord is much narrower than the full screen width. Keep
        // the icon close to its value so both remain inside that safe chord.
        var value = weatherValue(kind, conditions);
        var iconSpace = scalePx(14);
        var textWidth = temperatureTextWidth(dc, value);
        var left = cx - ((iconSpace + textWidth) / 2).toNumber();
        drawWeatherIcon(dc, kind, left + scalePx(6), cy, color);
        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        drawTemperatureText(dc, left + iconSpace, cy, value,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function refreshFieldData(field as Lang.Number, activity, date) as Void {
        if (field == FIELD_HEART || field == FIELD_HEART_RATE_ZONE) { currentHeartRate(); }
        else if (field == FIELD_BODY_BATTERY) { bodyBattery(); }
        else if (field == FIELD_SLEEP_SCORE) { sleepScore(); }
        else if (field == FIELD_STRESS) { currentStress(activity); }
        else if (field == FIELD_RECOVERY) { recoveryHours(activity); }
        else if (field == FIELD_RESTING_HR) { restingHeartRate(); }
        else if (field == FIELD_ELEVATION) { currentElevation(); }
        else if (field == FIELD_PRESSURE) { currentPressure(); }
        else if (field == FIELD_SPO2) { currentSpo2(); }
        else if (field == FIELD_DAILY_RUNNING_DISTANCE || field == FIELD_WEEKLY_RUNNING_DISTANCE ||
            field == FIELD_MONTHLY_RUNNING_DISTANCE || field == FIELD_YEARLY_RUNNING_DISTANCE ||
            field == FIELD_DAILY_CYCLING_DISTANCE || field == FIELD_WEEKLY_CYCLING_DISTANCE ||
            field == FIELD_MONTHLY_CYCLING_DISTANCE || field == FIELD_YEARLY_CYCLING_DISTANCE) {
            updateActivityDistanceCache(date);
        }
    }

    private function refreshTrendData(mode as Lang.Number, activity) as Void {
        trendValues(mode);
        trendCurrentValue(mode, activity);
    }

    private function refreshRingData(mode as Lang.Number, activity) as Void {
        if (mode == RING_BODY_BATTERY) { bodyBattery(); }
        else if (mode == RING_STRESS) { currentStress(activity); }
    }

    private function topLabelFontFor(dc, text) {
        var choice = numberProperty("TopLabelFont", 0);
        if (!_topLabelFontChecked || _topLabelFontChoice != choice || !_topLabelFontText.equals(text)) {
            _topLabelFontChecked = true;
            _topLabelFontChoice = choice;
            _topLabelFontText = text;
            _topLabelFont = null;
            if (Graphics has :getVectorFont) {
                var selectedFace = null;
                if (CNTopLabelFonts.supported(choice)) {
                    selectedFace = CNTopLabelFonts.face(choice);
                    // Use the CJK fallback for non-ASCII titles to avoid missing glyphs.
                    var chars = text.toCharArray();
                    for (var c = 0; c < chars.size(); c += 1) {
                        if (chars[c].toNumber() > 127) { selectedFace = "NotoSansSCMedium"; break; }
                    }
                } else if (isAmoledLayout()) {
                    selectedFace = "NotoSansSCMedium";
                }
                if (selectedFace != null) {
                    var size = isAmoledLayout() ? scalePx(25) : dc.getFontHeight(Graphics.FONT_XTINY);
                    try {
                        _topLabelFont = Graphics.getVectorFont({:face => selectedFace, :size => size});
                    } catch (e) { _topLabelFont = null; }
                }
            }
        }
        return _topLabelFont != null ? _topLabelFont : Graphics.FONT_XTINY;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        _width = dc.getWidth();
        _height = dc.getHeight();
        _cx = _width / 2;

        var clock = System.getClockTime();
        var now = Time.now();
        var date = Gregorian.info(now, Time.FORMAT_SHORT);
        var showAmPm = numberProperty("ShowAmPm", 1) == 1;
        var displayHour = clock.hour;
        if (showAmPm) {
            if (displayHour == 0) { displayHour = 12; }
            else if (displayHour > 12) { displayHour -= 12; }
        }

        // AOD only consumes values captured while the watch face was active.
        // Do this before any sensor, weather, or profile request.
        var amoledLowPower = _lowPower;
        if (isAmoledLayout() && (System has :getDisplayMode)) {
            amoledLowPower = amoledLowPower || System.getDisplayMode() == System.DISPLAY_MODE_LOW_POWER;
        }
        if (amoledLowPower && isAmoledLayout()) {
            drawAmoledAod(dc, clock, date, displayHour, numberProperty("LowPowerStyle", 1) == 1);
            return;
        }

        // Health and sensor APIs are read only at the selected data interval.
        // Second-by-second frames consume the resulting caches.
        var dataPeriod = numberProperty("UpdateFrequency", 60);
        if (dataPeriod < 1) { dataPeriod = 60; }
        var nowSeconds = now.value();
        var dataTick = (nowSeconds / dataPeriod).toNumber();
        var profileTick = (nowSeconds / PROFILE_CACHE_SECONDS).toNumber();
        var showSeconds = numberProperty("ShowSecondsActive", 0) == 1 && !_lowPower;
        var activityDay = (date.year * 13 + date.month) * 32 + date.day;
        var deferWakeRefresh = _wakeFramePending && _dataMinute >= 0 && _activityCacheDay == activityDay;
        _wakeFramePending = false;
        if (!deferWakeRefresh && profileTick != _profileCacheTick) {
            _profileCacheTick = profileTick;
            try {
                var latestProfile = UserProfile.getProfile();
                if (latestProfile != null) {
                    _cachedProfile = latestProfile;
                    _restingHeartRateCached = false;
                }
            } catch (e) {
            }
            try {
                if (UserProfile has :getHeartRateZones) {
                    var latestZones = UserProfile.getHeartRateZones(UserProfile.HR_ZONE_SPORT_GENERIC);
                    if (latestZones != null && latestZones.size() >= 6) { _cachedHeartRateZones = latestZones; }
                }
            } catch (e) {
            }
        }
        // Every onUpdate callback owns a full-screen frame. Even when its data
        // is unchanged, redraw it; some devices do not preserve the previous
        // frame buffer between high-power updates.
        if (!deferWakeRefresh && dataTick != _dataMinute) {
            _dataMinute = dataTick;
            _heartHistoryCache = null;
            _heartRateCached = false;
            _bodyBatteryCached = false;
            _sleepScoreCached = false;
            _elevationCached = false;
            _pressureCached = false;
            _spo2Cached = false;
            _stressCached = false;
            _recoveryCached = false;
            _sensorTempCached = false;
            _restingHeartRateCached = false;
            _trendCurrentCached = false;
            try {
                var latestStats = System.getSystemStats();
                if (latestStats != null) { _cachedStats = latestStats; }
            } catch (e) {
            }
            var stats = _cachedStats;
            if (stats != null && stats.battery != null) { _cachedBatteryPercent = stats.battery.toNumber(); _batteryKnown = true; }
            if (_activityCacheDay != activityDay) {
                _activityCacheDay = activityDay;
                _cachedActivity = null;
            }
            try {
                var latestActivity = ActivityMonitor.getInfo();
                if (latestActivity != null) { _cachedActivity = latestActivity; }
            } catch (e) {
            }
            try {
                var latestActivityInfo = Activity.getActivityInfo();
                if (latestActivityInfo != null) { _cachedActivityInfo = latestActivityInfo; }
            } catch (e) {
            }
            try {
                var latestDeviceSettings = System.getDeviceSettings();
                if (latestDeviceSettings != null) { _cachedDeviceSettings = latestDeviceSettings; }
            } catch (e) {
            }
            var currentActivity = _cachedActivity;
            refreshFieldData(fieldProperty("FieldTopLeft", FIELD_SUNRISE), currentActivity, date);
            refreshFieldData(fieldProperty("FieldTopRight", FIELD_SUNSET), currentActivity, date);
            refreshFieldData(fieldProperty("FieldLeft", FIELD_STEPS), currentActivity, date);
            refreshFieldData(fieldProperty("FieldCenter", FIELD_BATTERY), currentActivity, date);
            refreshFieldData(fieldProperty("FieldRight", FIELD_HEART), currentActivity, date);
            refreshTrendData(numberProperty("TrendField", TREND_HEART), currentActivity);
            refreshRingData(numberProperty("RingField", RING_BATTERY), currentActivity);
            // Normal fields/trend already request HR when needed. Keep a
            // reading for an independently selected AOD heart-rate field.
            if (numberProperty("AodLeftField", FIELD_HIDDEN) == FIELD_HEART ||
                numberProperty("AodCenterField", FIELD_HIDDEN) == FIELD_HEART ||
                numberProperty("AodRightField", FIELD_HIDDEN) == FIELD_HEART) { currentHeartRate(); }
        }
        if (!_weatherStorageLoaded) {
            _weatherStorageLoaded = true;
            var storedWeather = readWeatherCache();
            if (hasUsableWeather(storedWeather)) {
                _cachedConditions = storedWeather;
                _cachedWeatherTemperature = storedWeather.temperature;
                _weatherCacheTick = nowSeconds;
                updateLocationNameCache(storedWeather);
            }
        }
        if (_cachedConditions != null && !hasUsableWeather(_cachedConditions)) {
            _cachedConditions = null;
            _cachedWeatherTemperature = null;
            _cachedLocationName = "--";
            _weatherCacheTick = nowSeconds;
            _weatherNextAttemptSeconds = 0;
        }
        if (!deferWakeRefresh && nowSeconds >= _weatherNextAttemptSeconds) {
            _weatherNextAttemptSeconds = nowSeconds + WEATHER_RETRY_SECONDS;
            var latestConditions = null;
            try {
                latestConditions = Weather.getCurrentConditions();
            } catch (e) {
                // Keep the last known conditions and retry soon.
            }
            if (hasUsableWeather(latestConditions)) {
                latestConditions = mergeWeather(latestConditions);
                updateLocationNameCache(latestConditions);
                _cachedConditions = latestConditions;
                _weatherCacheTick = nowSeconds;
                cacheWeatherTemperature(latestConditions);
                storeWeatherCache(latestConditions);
                _weatherNextAttemptSeconds = nowSeconds + WEATHER_CACHE_SECONDS;
            }
        }
        var batteryPercent = _cachedBatteryPercent;
        var activity = _cachedActivity;
        var conditions = _cachedConditions;

        var background = COLOR_BLACK;
        var timeColor = displayColor(numberProperty("TimeColor", COLOR_WARM_WHITE));
        var dateColor = displayColor(numberProperty("DateColor", COLOR_WARM_WHITE));
        var secondsColor = displayColor(numberProperty("SecondsColor", COLOR_CORAL));
        var amPmColor = displayColor(numberProperty("AmPmColor", COLOR_CORAL));
        var fieldTextColor = displayColor(numberProperty("FieldTextColor", COLOR_CORAL));
        var fieldValueColor = displayColor(numberProperty("FieldValueColor", COLOR_WARM_WHITE));
        var sky = displayLandscapeColor(numberProperty("SkyColor", COLOR_SUNSET), 0);
        var far = displayLandscapeColor(numberProperty("MountainFarColor", COLOR_FAR_BLUE), 1);
        var mid = displayLandscapeColor(numberProperty("MountainMidColor", COLOR_MID_SLATE), 2);
        var near = displayLandscapeColor(numberProperty("MountainNearColor", COLOR_NEAR_INK), 3);
        // This setting owns the complete clock format: 12-hour with AM/PM,
        // or 24-hour without it. Do not inherit the device's clock setting.
        // onEnterSleep() is the watch-face indication that the wrist is down
        // or the device is in AOD/low-power state. Never draw stale seconds
        // there, regardless of the selected low-power layout.
        dc.setColor(background, background);
        dc.clear();

        // AMOLED burn-in mitigation: when the display is OLED, nudge the
        // time, date, status and bottom-field blocks by ±1 px on a slow
        // cycle (10 minutes per shift).  The user won't notice the change
        // but no single pixel stays bright for the full day.  MIP devices
        // are unaffected because the offset is always 0.
        var amoledJitterX = 0;
        var amoledJitterY = 0;
        if (isAmoledLayout() && !_lowPower) {
            amoledJitterX = ((((clock.min + clock.hour * 60) / 10).toNumber()) % 3) - 1;
            amoledJitterY = ((((clock.min + clock.hour * 60) / 30).toNumber()) % 3) - 1;
        }

        drawMountains(dc, sky, far, mid, near);

        // Top label — render only when set, otherwise the row stays empty
        // instead of showing a leftover "MOUNTAIN" placeholder from the
        // pre-i18n draft.
        var topLabelText = stringProperty("TopLabel", "");
        if (topLabelText.length() > 0) {
            dc.setColor(dateColor, Graphics.COLOR_TRANSPARENT);
            var topLabelFont = topLabelFontFor(dc, topLabelText);
            if (numberProperty("TopLabelBold", 0) == 1) {
                dc.drawText(_cx - 1, y(0.08), topLabelFont, topLabelText,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.drawText(_cx + 1, y(0.08), topLabelFont, topLabelText,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
            dc.drawText(_cx, y(0.08), topLabelFont, topLabelText,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Top custom fields
        var topY = _profileTopFieldY;
        var fieldContext = [activity, clock, date, conditions, now];
        drawCompactField(dc, fieldProperty("FieldTopLeft", FIELD_SUNRISE), x(0.30), topY, fieldTextColor, fieldValueColor, batteryPercent, fieldContext);
        drawCompactField(dc, fieldProperty("FieldTopRight", FIELD_SUNSET), x(0.70), topY, fieldTextColor, fieldValueColor, batteryPercent, fieldContext);

        // Time, seconds and AM/PM form one measured component. Reserve the
        // configured side slot even while seconds are suppressed in sleep, so
        // waking the watch cannot make the main time jump horizontally.
        var timeText = displayHour.format("%02d") + ":" + clock.min.format("%02d");
        var secondsText = clock.sec.format("%02d");
        var amPmText = clock.hour < 12 ? "AM" : "PM";
        var reserveSeconds = numberProperty("ShowSecondsActive", 0) == 1;
        var reserveSide = reserveSeconds || showAmPm;
        var worstTimeText = showAmPm ? "12:59" : "23:59";
        var sideLineCount = (reserveSeconds ? 1 : 0) + (showAmPm ? 1 : 0);
        var timeFont = fittedTimeFont(dc, worstTimeText, reserveSide);
        var timeSlotWidth = dc.getTextWidthInPixels(worstTimeText, timeFont);
        var sideWidth = dc.getTextWidthInPixels("59", _profileSideFont);
        var amPmWidth = dc.getTextWidthInPixels("PM", _profileSideFont);
        if (amPmWidth > sideWidth) { sideWidth = amPmWidth; }
        var vectorDevice = Graphics has :getVectorFont;
        var vectorTime = _timeVectorFont != null;
        var expandedVectorTime = _profileExpandVectorTime && vectorTime;
        var sideGap = _profileSideGap;
        if (expandedVectorTime) {
            sideGap += _profileVectorSideGap;
        }
        var componentWidth = timeSlotWidth;
        if (reserveSide) { componentWidth += sideGap + sideWidth; }
        var componentLeft = _cx - (componentWidth / 2).toNumber() + amoledJitterX;
        var clockCenterX = componentLeft + (timeSlotWidth / 2).toNumber();
        var targetCalendarY = _profileCalendarCenterY + _profileVectorCalendarOffset;
        var timeY = vectorTime ?
                    ((_profileTopFieldY + targetCalendarY) / 2).toNumber() + amoledJitterY :
                    _profileTimeCenterY + amoledJitterY;
        dc.setColor(timeColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(clockCenterX, timeY, timeFont, timeText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var sideFontH = dc.getFontHeight(_profileSideFont);
        var timeFontH = dc.getFontHeight(timeFont);
        var sideBlockH = sideLineCount == 0 ? 0 :
                         (sideLineCount > 1 ? sideFontH * 2 + _profileSideLineGap : sideFontH);
        var blockCenterX = componentLeft + timeSlotWidth + sideGap +
                           (sideWidth / 2).toNumber() -
                           (expandedVectorTime ? scalePx(7) : 0);
        var firstSideY = timeY;
        var secondSideY = timeY;
        if (sideLineCount > 1) {
            firstSideY = timeY - (sideBlockH / 2).toNumber() + (sideFontH / 2).toNumber();
            secondSideY = firstSideY + sideFontH + _profileSideLineGap;
        }
        if (showSeconds) {
            dc.setColor(secondsColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(blockCenterX, firstSideY, _profileSideFont, secondsText,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // The calendar owns the center row. Using the number font's full line
        // height here would include device-specific internal leading and push
        // the date and every following row too far down.
        var showDate = numberProperty("ShowDate", 1) == 1;
        var showWeekday = numberProperty("ShowWeekday", 1) == 1;
        var showLunar = numberProperty("ShowLunar", 1) == 1;
        var showSolarTerm = numberProperty("ShowSolarTerm", 1) == 1;
        var timeComponentH = timeFontH > sideBlockH ? timeFontH : sideBlockH;
        var timeComponentBottom = timeY + (timeComponentH / 2).toNumber();
        var dateText = showDate ? Lang.format(text(Rez.Strings.DatePattern), [date.month, date.day]) : "";
        var weekday = showWeekday ? weekdayText(date.day_of_week) : "";
        var vectorCalendar = isChineseCalendar() && vectorDevice;
        var lunarText = showLunar ? lunarDate(date, vectorCalendar) : "";
        var solarText = showSolarTerm ? solarTermText(date) : "";
        var calendarItemCount = (showDate ? 1 : 0) + (showWeekday ? 1 : 0) +
                                (showLunar ? 1 : 0) + (showSolarTerm ? 1 : 0);
        var calendarItems = [];
        if (showDate) { calendarItems.add(dateText); }
        if (showWeekday) { calendarItems.add(weekday); }
        if (showLunar) { calendarItems.add(lunarText); }
        if (showSolarTerm) { calendarItems.add(solarText); }
        var calendarOptions = (showDate ? 1 : 0) | (showWeekday ? 2 : 0) |
                              (showLunar ? 4 : 0) | (showSolarTerm ? 8 : 0);
        var calendarCacheKey = (((date.year * 13 + date.month) * 32 + date.day) * 16) + calendarOptions;
        var sharedCalendarFont = vectorCalendar ?
            fittedCalendarFont(dc, calendarItems, calendarItemCount, calendarCacheKey) : null;
        if (sharedCalendarFont == null && showLunar && vectorCalendar) {
            lunarText = lunarDate(date, false);
            calendarItems = [];
            if (showDate) { calendarItems.add(dateText); }
            if (showWeekday) { calendarItems.add(weekday); }
            calendarItems.add(lunarText);
            if (showSolarTerm) { calendarItems.add(solarText); }
        }
        var calendarFont = sharedCalendarFont == null ? _profileCalendarFallbackFont : sharedCalendarFont;
        var calendarFontH = calendarItemCount > 0 ? dc.getFontHeight(calendarFont) : 0;
        var dateY = _profileCalendarCenterY +
                    (vectorDevice ? _profileVectorCalendarOffset : 0) + amoledJitterY;
        var dateWidth = showDate ? dc.getTextWidthInPixels(dateText, calendarFont) : 0;
        var weekdayWidth = showWeekday ? dc.getTextWidthInPixels(weekday, calendarFont) : 0;
        var lunarWidth = showLunar ? dc.getTextWidthInPixels(lunarText, calendarFont) : 0;
        var solarWidth = showSolarTerm ? dc.getTextWidthInPixels(solarText, calendarFont) : 0;
        dc.setColor(dateColor, Graphics.COLOR_TRANSPARENT);
        // Every layout stays centered; the setting only controls the space
        // between enabled calendar items.
        var calendarLayout = numberProperty("CalendarLayout", 1);
        var calendarGap = scalePx(8); // centered standard
        if (calendarLayout == 1) { calendarGap = scalePx(2); } // compact
        else if (calendarLayout == 2) { calendarGap = scalePx(12); } // wide
        var calendarContentWidth = dateWidth + weekdayWidth + lunarWidth + solarWidth;
        var calendarWidth = calendarContentWidth;
        if (calendarItemCount > 1) {
            var calendarAvailableWidth = roundContentWidthAt(dateY, _profileCalendarInset);
            var fittedGap = ((calendarAvailableWidth - calendarContentWidth) / (calendarItemCount - 1)).toNumber();
            if (calendarGap > fittedGap) { calendarGap = fittedGap > 0 ? fittedGap : 0; }
            calendarWidth = calendarContentWidth + calendarGap * (calendarItemCount - 1);
        }
        var calendarX = _cx - (calendarWidth / 2).toNumber();
        if (showDate) {
            dc.drawText(calendarX, dateY, calendarFont, dateText,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            calendarX += dateWidth + calendarGap;
        }
        if (showWeekday) {
            dc.drawText(calendarX, dateY, calendarFont, weekday,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            calendarX += weekdayWidth + calendarGap;
        }
        if (showLunar) {
            dc.drawText(calendarX, dateY, calendarFont, lunarText,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            calendarX += lunarWidth + calendarGap;
        }
        if (showSolarTerm) {
            dc.drawText(calendarX, dateY, calendarFont, solarText,
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
        if (showAmPm) {
            dc.setColor(amPmColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(blockCenterX, reserveSeconds ? secondSideY : firstSideY, _profileSideFont, amPmText,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Keep the left status column clear while the chart uses the right
        // side. Its top edge is exactly the lower edge of the mountain band.
        var trendMode = numberProperty("TrendField", TREND_HEART);
        var trendStyle = numberProperty("TrendStyle", TREND_STYLE_BARS);
        var values = trendValues(trendMode);
        var current = trendCurrentValue(trendMode, activity);
        if (current == null && values.size() > 0) {
            current = values[values.size() - 1];
        }

        // The current value and graph remain one visual component, with the
        // current value in the left status column.
        var calendarBottom = calendarItemCount > 0 ?
                             dateY + (calendarFontH / 2).toNumber() : timeComponentBottom;
        var midY = y(0.62) + amoledJitterY;
        var minimumTrendY = calendarBottom + _profileTrendGap +
                            (dc.getFontHeight(Graphics.FONT_XTINY) / 2).toNumber();
        if (midY < minimumTrendY) { midY = minimumTrendY; }
        var statusIconX = x(0.14);
        var statusValueX = x(0.19);
        drawTrendIcon(dc, trendMode, statusIconX, midY, fieldTextColor);
        dc.setColor(fieldValueColor, Graphics.COLOR_TRANSPARENT);
        drawTemperatureText(dc, statusValueX, midY, formatTrendValue(trendMode, current),
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        var chartLeft = x(0.40);
        var chartTop = y(0.57) + amoledJitterY;
        var minimumChartTop = calendarBottom + scalePx(3);
        if (chartTop < minimumChartTop) { chartTop = minimumChartTop; }
        var chartW = x(0.52);
        // Keep the chart baseline at a fixed pixel coordinate above the bottom fields.
        var sepY = y(0.74) + amoledJitterY;
        var chartH = sepY - chartTop;
        if (chartH > 0) {
            drawTrend(dc, trendStyle, values, fieldTextColor, chartLeft, chartTop, chartW, chartH, trendMode);
        }

        // Status field: compact icon + value, leaving the trend graph unobstructed.
        var ringMode = numberProperty("RingField", RING_BATTERY);
        var ring = ringValue(ringMode, batteryPercent, activity);
        var statusCx = statusIconX;
        var statusCy = midY + scalePx(22);
        drawFieldIcon(dc, statusField(ringMode), statusCx, statusCy, fieldTextColor);
        dc.setColor(fieldValueColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(statusValueX, statusCy, smallFieldFont(dc),
            ring == null ? "--" : ring.format("%d") + "%",
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Bottom data fields — icon + value only
        var fields = [
            fieldProperty("FieldLeft", FIELD_FLOORS),
            fieldProperty("FieldCenter", FIELD_STEPS),
            fieldProperty("FieldRight", FIELD_CALORIES)
        ];
        var fieldY = y(0.79) + amoledJitterY;
        var bottomCount = numberProperty("BottomFieldCount", 3);
        var bottomLayout = numberProperty("BottomFieldLayout", 0);
        var outerX = 0.25;
        if (bottomLayout == 1) { outerX = 0.28; }
        else if (bottomLayout == 2) { outerX = 0.22; }
        if (bottomCount == 2) {
            drawCompactField(dc, fields[0], x(outerX), fieldY, fieldTextColor, fieldValueColor, batteryPercent, fieldContext);
            drawCompactField(dc, fields[2], x(1.0 - outerX), fieldY, fieldTextColor, fieldValueColor, batteryPercent, fieldContext);
        } else {
            drawCompactField(dc, fields[0], x(outerX), fieldY, fieldTextColor, fieldValueColor, batteryPercent, fieldContext);
            drawCompactField(dc, fields[1], _cx, fieldY, fieldTextColor, fieldValueColor, batteryPercent, fieldContext);
            drawCompactField(dc, fields[2], x(1.0 - outerX), fieldY, fieldTextColor, fieldValueColor, batteryPercent, fieldContext);
        }

        // Weather: two customizable slots in one compact row
        var weatherTop = y(0.88);

        var wxLeft = numberProperty("WeatherLeft", WX_TEMP);
        var wxRight = numberProperty("WeatherRight", WX_HIGH_LOW);
        var weatherCount = numberProperty("WeatherFieldCount", 2);
        if (conditions == null && wxLeft == WX_HIDDEN && (weatherCount == 1 || wxRight == WX_HIDDEN)) {
            // nothing
        } else {
            if (weatherCount == 1) {
                drawWeatherSlot(dc, wxLeft, _cx, weatherTop, fieldTextColor, fieldValueColor, conditions);
            } else if (!isAmoledLayout()) {
                var leftWidth = wxLeft == WX_HIDDEN ? 0 : scalePx(14) +
                    temperatureTextWidth(dc, weatherValue(wxLeft, conditions));
                var rightWidth = wxRight == WX_HIDDEN ? 0 : scalePx(14) +
                    temperatureTextWidth(dc, weatherValue(wxRight, conditions));
                var weatherGap = leftWidth > 0 && rightWidth > 0 ? scalePx(5) : 0;
                var rowLeft = _cx - ((leftWidth + rightWidth + weatherGap) / 2).toNumber();
                drawWeatherSlot(dc, wxLeft, rowLeft + (leftWidth / 2).toNumber(), weatherTop,
                    fieldTextColor, fieldValueColor, conditions);
                drawWeatherSlot(dc, wxRight, rowLeft + leftWidth + weatherGap + (rightWidth / 2).toNumber(), weatherTop,
                    fieldTextColor, fieldValueColor, conditions);
            } else {
                drawWeatherSlot(dc, wxLeft, x(0.36), weatherTop, fieldTextColor, fieldValueColor, conditions);
                drawWeatherSlot(dc, wxRight, x(0.64), weatherTop, fieldTextColor, fieldValueColor, conditions);
            }
        }
    }
}

class CNWatchFaceStoredWeather {
    public var observationTime as Time.Moment or Null;
    public var observationLocationPosition as Position.Location or Null;
    public var observationLocationName as Lang.String or Null;
    public var precipitationChance as Lang.Number or Null;
    public var temperature as Lang.Numeric or Null;
    public var windBearing as Lang.Number or Null;
    public var windSpeed as Lang.Float or Null;
    public var highTemperature as Lang.Numeric or Null;
    public var lowTemperature as Lang.Numeric or Null;
    public var feelsLikeTemperature as Lang.Float or Null;
    public var relativeHumidity as Lang.Number or Null;
    public var condition as Lang.Number or Null;
    public var uvIndex as Lang.Float or Null;
}
