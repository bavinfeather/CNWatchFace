using Toybox.Application;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;

// Each row in the menu maps to one of these descriptors.  Keeping the
// metadata in one place stops the title, the property key and the option
// list from drifting apart over time.
class CNWatchFaceSettingsMenu extends WatchUi.Menu2 {

    // Accent colors from Chef5/Wildward-face and ludw/Segment34mkII (MIT).
    // AMOLED keeps the source RGB while MIP uses the matching RGB222-safe
    // color in displayColor() and mipColor().
    const COLORS_DISPLAY = [
        [Rez.Strings.ColorPurple, 0xB77CFF],
        [Rez.Strings.ColorBlue, 0x55AAFF],
        [Rez.Strings.ColorCyan, 0x00DDCC],
        [Rez.Strings.ColorGreen, 0x55FF99],
        [Rez.Strings.ColorFieldGreen, 0x3DA855],
        [Rez.Strings.ColorYellow, 0xFFEE44],
        [Rez.Strings.ColorGold, 0xFFCC33],
        [Rez.Strings.ColorOrange, 0xFFAA55],
        [Rez.Strings.ColorRed, 0xFF5566],
        [Rez.Strings.ColorPink, 0xFF77BB],
        [Rez.Strings.ColorWhite, 0xFFFFFF],
        [Rez.Strings.ColorBlack, 0x000000],
        [Rez.Strings.ColorSoftAmber, 0xFBCB77],
        [Rez.Strings.ColorMint, 0x89EFD2],
        [Rez.Strings.ColorSpringGreen, 0x96E0AC],
        [Rez.Strings.ColorPeach, 0xFF9161]
    ];
    const COLORS_SKY = [
        [Rez.Strings.ColorSunset, 0xA63E32],
        [Rez.Strings.ColorSoftAmber, 0xFBCB77],
        [Rez.Strings.ColorMint, 0x89EFD2],
        [Rez.Strings.ColorSpringGreen, 0x96E0AC],
        [Rez.Strings.ColorPeach, 0xFF9161],
        [Rez.Strings.ColorAmberDusk, 0xC45A3C],
        [Rez.Strings.ColorDuskPurple, 0x3A2A4A],
        [Rez.Strings.ColorNightNavy, 0x1A2A4A],
        [Rez.Strings.ColorTealDusk, 0x1E1E1A],
        [Rez.Strings.ColorBlack, 0x000000],
        [Rez.Strings.ColorWhite, 0xFFFFFF]
    ];
    const COLORS_FAR = [
        [Rez.Strings.ColorFarBlue, 0x4A6A7A],
        [Rez.Strings.ColorSoftAmber, 0xFBCB77],
        [Rez.Strings.ColorMint, 0x89EFD2],
        [Rez.Strings.ColorSpringGreen, 0x96E0AC],
        [Rez.Strings.ColorPeach, 0xFF9161],
        [Rez.Strings.ColorBlueGray, 0x304A5A],
        [Rez.Strings.ColorFarSage, 0x507258],
        [Rez.Strings.ColorFarRose, 0x6A4242],
        [Rez.Strings.ColorOlive, 0x555000],
        [Rez.Strings.ColorBlack, 0x000000],
        [Rez.Strings.ColorWhite, 0xFFFFFF]
    ];
    const COLORS_MID = [
        [Rez.Strings.ColorMidSlate, 0x243747],
        [Rez.Strings.ColorSoftAmber, 0xFBCB77],
        [Rez.Strings.ColorMint, 0x89EFD2],
        [Rez.Strings.ColorSpringGreen, 0x96E0AC],
        [Rez.Strings.ColorPeach, 0xFF9161],
        [Rez.Strings.ColorDarkGreen, 0x005500],
        [Rez.Strings.ColorMidForest, 0x223344],
        [Rez.Strings.ColorMidWine, 0x4A1018],
        [Rez.Strings.ColorBlueGray, 0x304A5A],
        [Rez.Strings.ColorBlack, 0x000000],
        [Rez.Strings.ColorWhite, 0xFFFFFF]
    ];
    const COLORS_NEAR = [
        [Rez.Strings.ColorNearInk, 0x152532],
        [Rez.Strings.ColorSoftAmber, 0xFBCB77],
        [Rez.Strings.ColorMint, 0x89EFD2],
        [Rez.Strings.ColorSpringGreen, 0x96E0AC],
        [Rez.Strings.ColorPeach, 0xFF9161],
        [Rez.Strings.ColorNearPine, 0x101510],
        [Rez.Strings.ColorNearPlum, 0x261226],
        [Rez.Strings.ColorBlack, 0x000000],
        [Rez.Strings.ColorDarkBlue, 0x000055],
        [Rez.Strings.ColorWhite, 0xFFFFFF]
    ];
    const ON_OFF = [
        [Rez.Strings.Yes, 1],
        [Rez.Strings.No,  0]
    ];
    const TEMPERATURE_UNIT_OPTIONS = [
        [Rez.Strings.TemperatureUnitCelsius,    0],
        [Rez.Strings.TemperatureUnitFahrenheit, 1]
    ];
    const CALENDAR_LAYOUT_OPTIONS = [
        [Rez.Strings.CalendarLayoutSpread,  0],
        [Rez.Strings.CalendarLayoutCompact, 1],
        [Rez.Strings.CalendarLayoutWide,    2]
    ];
    const BOTTOM_FIELD_COUNT_OPTIONS = [
        [Rez.Strings.FieldCountTwo, 2],
        [Rez.Strings.FieldCountThree, 3]
    ];
    const WEATHER_FIELD_COUNT_OPTIONS = [
        [Rez.Strings.FieldCountOne, 1],
        [Rez.Strings.FieldCountTwo, 2]
    ];
    const RING_OPTIONS = [
        [Rez.Strings.FieldBattery,     0],
        [Rez.Strings.FieldBodyBattery, 1],
        [Rez.Strings.FieldStress,      2]
    ];
    const TREND_OPTIONS = [
        [Rez.Strings.TrendHeartRate,  0],
        [Rez.Strings.TrendElevation,  1],
        [Rez.Strings.TrendStress,     2],
        [Rez.Strings.TrendBodyBattery,3],
        [Rez.Strings.TrendPressure,   4],
        [Rez.Strings.TrendSpo2,       5],
        [Rez.Strings.TrendSensorTemperature,6]
    ];
    const TREND_STYLE = [
        [Rez.Strings.TrendStyleLine, 0],
        [Rez.Strings.TrendStyleBars, 1]
    ];
    const WEATHER_OPTIONS = [
        [Rez.Strings.FieldHidden,    0],
        [Rez.Strings.WeatherTemp,    1],
        [Rez.Strings.WeatherWind,    2],
        [Rez.Strings.WeatherHighLow, 3],
        [Rez.Strings.WeatherCondition, 4],
        [Rez.Strings.WeatherPrecip,  5],
        [Rez.Strings.WeatherFeelsLike, 6]
    ];
    const FIELD_OPTIONS = [
        [Rez.Strings.FieldHidden, 0],
        [Rez.Strings.FieldSteps, 1],
        [Rez.Strings.FieldFloors, 2],
        [Rez.Strings.FieldActiveCalories, 3],
        [Rez.Strings.FieldTotalCalories, 23],
        [Rez.Strings.FieldRestingCalories, 24],
        [Rez.Strings.FieldFloorsDescended, 25],
        [Rez.Strings.FieldActiveMinutesWeek, 26],
        [Rez.Strings.FieldActiveMinutesWeekGoal, 28],
        [Rez.Strings.FieldBatteryDays, 29],
        [Rez.Strings.FieldHumidity, 30],
        [Rez.Strings.FieldVo2MaxRunning, 31],
        [Rez.Strings.FieldSolarIntensity, 32],
        [Rez.Strings.FieldDistance, 4],
        [Rez.Strings.FieldBattery, 5],
        [Rez.Strings.FieldStress, 6],
        [Rez.Strings.FieldHeartRate, 7],
        [Rez.Strings.FieldBodyBattery, 8],
        [Rez.Strings.FieldSeconds, 9],
        [Rez.Strings.FieldDate, 10],
        [Rez.Strings.FieldWeekday, 11],
        [Rez.Strings.FieldTemperature, 12],
        [Rez.Strings.FieldRecovery, 13],
        [Rez.Strings.FieldActiveMinutes, 14],
        [Rez.Strings.FieldStepGoal, 15],
        [Rez.Strings.FieldSunrise, 16],
        [Rez.Strings.FieldSunset, 17],
        [Rez.Strings.FieldRestingHr, 18],
        [Rez.Strings.FieldElevation, 19],
        [Rez.Strings.FieldPressure, 20],
        [Rez.Strings.FieldSpo2, 21],
        [Rez.Strings.FieldLunar, 22]
    ];
    // AOD is deliberately limited to values available without a live sensor
    // read.  The renderer only uses clock data and values cached while active.
    const AOD_FIELD_OPTIONS = [
        [Rez.Strings.FieldHidden, 0],
        [Rez.Strings.FieldBattery, 5],
        [Rez.Strings.FieldHeartRate, 7],
        [Rez.Strings.FieldDate, 10],
        [Rez.Strings.FieldWeekday, 11]
    ];
    const FREQUENCY_OPTIONS = [
        [Rez.Strings.EveryMinute, 60],
        [Rez.Strings.Every30Seconds, 30],
        [Rez.Strings.Every5Seconds, 5],
        [Rez.Strings.EverySecond, 1]
    ];
    const LOW_POWER_OPTIONS = [
        [Rez.Strings.LowPowerSimple, 1],
        [Rez.Strings.LowPowerFull,   0]
    ];
    const TIME_FONT_OPTIONS = [
        [0, 1],
        [1, 2],
        [2, 3],
        [3, 4],
        [4, 5],
        [5, 6]
    ];

    const TOP_LABEL_WEIGHT_OPTIONS = [
        [Rez.Strings.TopLabelBold, 1],
        [Rez.Strings.TopLabelRegular, 0]
    ];
    // [identifier, title-resource, property-key, options]
    const DESCRIPTORS = [
        [:topLabelFont, Rez.Strings.SettingTopLabelFont, "TopLabelFont", null],
        [:topLabelWeight, Rez.Strings.SettingTopLabelWeight, "TopLabelBold", TOP_LABEL_WEIGHT_OPTIONS],
        [:time,        Rez.Strings.SettingTimeColor,        "TimeColor",        COLORS_DISPLAY],
        [:dateColor,   Rez.Strings.SettingDateColor,        "DateColor",        COLORS_DISPLAY],
        [:secondsColor,Rez.Strings.SettingSecondsColor,     "SecondsColor",     COLORS_DISPLAY],
        [:amPmColor,   Rez.Strings.SettingAmPmColor,        "AmPmColor",        COLORS_DISPLAY],
        [:fieldText,   Rez.Strings.SettingFieldTextColor,   "FieldTextColor",   COLORS_DISPLAY],
        [:fieldValue,  Rez.Strings.SettingFieldValueColor,  "FieldValueColor",  COLORS_DISPLAY],
        [:sky,         Rez.Strings.SettingSkyColor,         "SkyColor",         COLORS_SKY],
        [:far,         Rez.Strings.SettingMountainFarColor, "MountainFarColor", COLORS_FAR],
        [:mid,         Rez.Strings.SettingMountainMidColor, "MountainMidColor", COLORS_MID],
        [:near,        Rez.Strings.SettingMountainNearColor,"MountainNearColor",COLORS_NEAR],
        [:timeFont,    Rez.Strings.SettingTimeFont,         "TimeFont",         TIME_FONT_OPTIONS],
        [:ampm,        Rez.Strings.SettingShowAmPm,         "ShowAmPm",         ON_OFF],
        [:date,        Rez.Strings.SettingShowDate,         "ShowDate",         ON_OFF],
        [:weekday,     Rez.Strings.SettingShowWeekday,      "ShowWeekday",      ON_OFF],
        [:lunar,       Rez.Strings.SettingShowLunar,        "ShowLunar",        ON_OFF],
        [:solarTerm,   Rez.Strings.SettingShowSolarTerm,    "ShowSolarTerm",    ON_OFF],
        [:calendarLayout, Rez.Strings.SettingCalendarLayout,"CalendarLayout",   CALENDAR_LAYOUT_OPTIONS],
        [:seconds,     Rez.Strings.SettingShowSecondsActive,"ShowSecondsActive",ON_OFF],
        [:temperatureUnit, Rez.Strings.SettingTemperatureUnit, "TemperatureUnit", TEMPERATURE_UNIT_OPTIONS],
        [:ring,        Rez.Strings.SettingRingField,        "RingField",        RING_OPTIONS],
        [:trend,       Rez.Strings.SettingTrendField,       "TrendField",       TREND_OPTIONS],
        [:trendStyle,  Rez.Strings.SettingTrendStyle,       "TrendStyle",       TREND_STYLE],
        [:topLeft,     Rez.Strings.SettingFieldTopLeft,     "FieldTopLeft",     FIELD_OPTIONS],
        [:topRight,    Rez.Strings.SettingFieldTopRight,    "FieldTopRight",    FIELD_OPTIONS],
        [:bottomCount, Rez.Strings.SettingBottomFieldCount, "BottomFieldCount", BOTTOM_FIELD_COUNT_OPTIONS],
        [:bottomLayout,Rez.Strings.SettingBottomFieldLayout,"BottomFieldLayout",CALENDAR_LAYOUT_OPTIONS],
        [:left,        Rez.Strings.SettingFieldLeft,        "FieldLeft",        FIELD_OPTIONS],
        [:center,      Rez.Strings.SettingFieldCenter,      "FieldCenter",      FIELD_OPTIONS],
        [:right,       Rez.Strings.SettingFieldRight,       "FieldRight",       FIELD_OPTIONS],
        [:aodLeft,     Rez.Strings.SettingAodLeftField,     "AodLeftField",     AOD_FIELD_OPTIONS],
        [:aodCenter,   Rez.Strings.SettingAodCenterField,   "AodCenterField",   AOD_FIELD_OPTIONS],
        [:aodRight,    Rez.Strings.SettingAodRightField,    "AodRightField",    AOD_FIELD_OPTIONS],
        [:weatherCount, Rez.Strings.SettingWeatherFieldCount, "WeatherFieldCount", WEATHER_FIELD_COUNT_OPTIONS],
        [:wxLeft,      Rez.Strings.SettingWeatherLeft,      "WeatherLeft",      WEATHER_OPTIONS],
        [:wxRight,     Rez.Strings.SettingWeatherRight,     "WeatherRight",     WEATHER_OPTIONS],
        [:frequency,   Rez.Strings.SettingUpdateFrequency,  "UpdateFrequency",  FREQUENCY_OPTIONS],
        [:lowPower,    Rez.Strings.SettingLowPowerStyle,    "LowPowerStyle",    LOW_POWER_OPTIONS]
    ];

    function initialize() {
        Menu2.initialize({:title => load(Rez.Strings.SettingsTitle)});
        for (var i = 0; i < DESCRIPTORS.size(); i += 1) {
            var d = DESCRIPTORS[i];
            var id = d[0];
            addItem(new WatchUi.MenuItem(load(d[1]), subLabel(id), id, null));
        }
    }

    private function load(id as Lang.ResourceId) as Lang.String {
        return WatchUi.loadResource(id) as Lang.String;
    }

    // Look up the value label of a descriptor, with a sensible fallback.
    function subLabel(id as Lang.Symbol) as Lang.String {
        var options = optionsFor(id);
        if (options == null) { return ""; }
        var key = keyFor(id);
        var value = Application.Properties.getValue(key);
        for (var i = 0; i < options.size(); i += 1) {
            var option = options[i] as Lang.Array;
            if (option[1] == value) { return optionLabel(id, option); }
        }
        return "—";
    }

    function optionLabel(id as Lang.Symbol, option as Lang.Array) as Lang.String {
        if (id == :timeFont) {
            return timeFontLabel(option[0] as Lang.Number);
        }
        return load(option[0] as Lang.ResourceId);
    }

    private function timeFontLabel(index as Lang.Number) as Lang.String {
        var remaining = load(Rez.Strings.TimeFontMenuOptions);
        for (var i = 0; i < index; i += 1) {
            var separator = remaining.find("|");
            if (separator == null) { return "—"; }
            remaining = remaining.substring((separator as Lang.Number) + 1, null) as Lang.String;
        }
        var end = remaining.find("|");
        if (end == null) { return remaining; }
        return remaining.substring(0, end as Lang.Number) as Lang.String;
    }

    private function appendFieldOption(options as Lang.Array, label as Lang.ResourceId, value as Lang.Number) as Void {
        var option = [];
        option.add(label);
        option.add(value);
        options.add(option);
    }

    private function colorOptionsWithDefault(label as Lang.ResourceId, value as Lang.Number) as Lang.Array {
        var options = [];
        appendFieldOption(options, label, value);
        for (var i = 0; i < COLORS_DISPLAY.size(); i += 1) { options.add(COLORS_DISPLAY[i]); }
        return options;
    }

    private function extendedFieldOptions() as Lang.Array {
        // Keep the rarely opened, extended entries as runtime rows.  This
        // avoids overflowing the compiler's fixed constant-container table
        // on older MIP targets while preserving the same full selector.
        var options = [];
        for (var i = 0; i < FIELD_OPTIONS.size(); i += 1) { options.add(FIELD_OPTIONS[i]); }
        appendFieldOption(options, Rez.Strings.FieldDailyRunningDistance, 54);
        appendFieldOption(options, Rez.Strings.FieldWeeklyRunningDistance, 55);
        appendFieldOption(options, Rez.Strings.FieldMonthlyRunningDistance, 33);
        appendFieldOption(options, Rez.Strings.FieldYearlyRunningDistance, 56);
        appendFieldOption(options, Rez.Strings.FieldDailyCyclingDistance, 57);
        appendFieldOption(options, Rez.Strings.FieldWeeklyCyclingDistance, 58);
        appendFieldOption(options, Rez.Strings.FieldMonthlyCyclingDistance, 52);
        appendFieldOption(options, Rez.Strings.FieldYearlyCyclingDistance, 59);
        appendFieldOption(options, Rez.Strings.FieldWeekNumber, 34);
        appendFieldOption(options, Rez.Strings.FieldNotificationCount, 35);
        appendFieldOption(options, Rez.Strings.FieldHighTemperature, 36);
        appendFieldOption(options, Rez.Strings.FieldLowTemperature, 37);
        appendFieldOption(options, Rez.Strings.FieldPrecipitationChance, 38);
        appendFieldOption(options, Rez.Strings.FieldDayNight, 39);
        appendFieldOption(options, Rez.Strings.FieldDaylightRemaining, 40);
        appendFieldOption(options, Rez.Strings.FieldHeartRateZone, 41);
        appendFieldOption(options, Rez.Strings.FieldSolarTerm, 43);
        appendFieldOption(options, Rez.Strings.FieldAverageRestingHr, 45);
        appendFieldOption(options, Rez.Strings.FieldAlarmCount, 48);
        appendFieldOption(options, Rez.Strings.FieldRespirationRate, 49);
        appendFieldOption(options, Rez.Strings.FieldWeatherCondition, 50);
        appendFieldOption(options, Rez.Strings.FieldNextSunEvent, 51);
        appendFieldOption(options, Rez.Strings.FieldLocationName, 53);
        appendFieldOption(options, Rez.Strings.FieldUvIndex, 73);
        if (supportsSleepScore()) { appendFieldOption(options, Rez.Strings.FieldSleepScore, 79); }
        return options;
    }

    private function supportsSleepScore() as Lang.Boolean {
        try {
            var settings = System.getDeviceSettings();
            if (settings == null || !(settings has :monkeyVersion) || settings.monkeyVersion == null) { return false; }
            var version = settings.monkeyVersion;
            return version.size() >= 3 &&
                (version[0] > 6 || (version[0] == 6 &&
                (version[1] > 0 || (version[1] == 0 && version[2] >= 2))));
        } catch (e) {
            return false;
        }
    }

    function optionsFor(id as Lang.Symbol) as Lang.Array or Null {
        if (id == :topLabelFont) { return CNTopLabelFonts.options(); }
        if (id == :time || id == :dateColor || id == :fieldValue) {
            return colorOptionsWithDefault(Rez.Strings.ColorWarmWhite, 0xF5E6D3);
        }
        if (id == :secondsColor || id == :amPmColor || id == :fieldText) {
            return colorOptionsWithDefault(Rez.Strings.ColorCoral, 0xFF6633);
        }
        if (id == :topLeft || id == :topRight || id == :left || id == :center || id == :right) {
            return extendedFieldOptions();
        }
        for (var i = 0; i < DESCRIPTORS.size(); i += 1) {
            if (DESCRIPTORS[i][0] == id) { return DESCRIPTORS[i][3]; }
        }
        return null;
    }

    function keyFor(id as Lang.Symbol) as Lang.String {
        for (var i = 0; i < DESCRIPTORS.size(); i += 1) {
            if (DESCRIPTORS[i][0] == id) { return DESCRIPTORS[i][2]; }
        }
        return "";
    }

    // Refresh the on-screen sublabel for a single row after the user picks
    // a new value in the pushView sub-menu.  Idempotent.  Menu2 does not
    // expose a public lookup-by-id, so we walk the visible items.
    function refreshItem(id as Lang.Symbol) as Void {
        var i = 0;
        while (true) {
            var mi = getItem(i);
            if (mi == null) { return; }
            if (mi.getId() == id) {
                mi.setSubLabel(subLabel(id));
                updateItem(mi, i);
                return;
            }
            i += 1;
        }
    }
}

class CNWatchFaceSettingsDelegate extends WatchUi.Menu2InputDelegate {
    private var _menu as CNWatchFaceSettingsMenu;

    function initialize(menu as CNWatchFaceSettingsMenu) {
        Menu2InputDelegate.initialize();
        _menu = menu;
    }

    // Opens a native-looking sub-menu listing every available value for the
    // chosen setting, with a check mark next to the active one.  This
    // replaces the legacy "press SELECT to cycle" behaviour, which forced
    // users to tap many times without seeing the alternatives.
    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId() as Lang.Symbol;
        var options = _menu.optionsFor(id);
        if (options == null) { return; }
        var key = _menu.keyFor(id);
        var current = Application.Properties.getValue(key);

        var submenu = new WatchUi.Menu2({:title => _menu.subLabel(id)});
        for (var i = 0; i < options.size(); i += 1) {
            var option = options[i] as Lang.Array;
            var value = option[1];
            var isCurrent = (value == current);
            var mi = new WatchUi.MenuItem(
                _menu.optionLabel(id, option),
                isCurrent ? CNWatchFaceSettingsDelegate.loadString(Rez.Strings.MarkCurrent) : null,
                value,
                null
            );
            submenu.addItem(mi);
        }
        WatchUi.pushView(submenu, new CNWatchFaceSubMenuDelegate(key, id, _menu), WatchUi.SLIDE_IMMEDIATE);
    }

    static function loadString(id as Lang.ResourceId) as Lang.String {
        return WatchUi.loadResource(id) as Lang.String;
    }
}

class CNWatchFaceSubMenuDelegate extends WatchUi.Menu2InputDelegate {
    private var _key as Lang.String;
    private var _id as Lang.Symbol;
    private var _menu as CNWatchFaceSettingsMenu;

    function initialize(key as Lang.String, id as Lang.Symbol, menu as CNWatchFaceSettingsMenu) {
        Menu2InputDelegate.initialize();
        _key = key;
        _id = id;
        _menu = menu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        Application.Properties.setValue(_key, item.getId());
        Application.getApp().onSettingsChanged();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        _menu.refreshItem(_id);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
