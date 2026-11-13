using Toybox.Application;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;

// Each row in the menu maps to one of these descriptors.  Keeping the
// metadata in one place stops the title, the property key and the option
// list from drifting apart over time.
(:QWeatherEnabled)
class CNWatchFaceSettingsMenu extends WatchUi.Menu2 {

    function makeOnOff() { return [
        [Rez.Strings.Yes, 1],
        [Rez.Strings.No,  0]
    ]; }
    function makeTemperatureUnitOptions() { return [
        [Rez.Strings.TemperatureUnitCelsius,    0],
        [Rez.Strings.TemperatureUnitFahrenheit, 1]
    ]; }
    function makeRingOptions() { return [
        [Rez.Strings.FieldBattery,     0],
        [Rez.Strings.FieldBodyBattery, 1],
        [Rez.Strings.FieldStress,      2]
    ]; }
    function makeTrendOptions() { return [
        [Rez.Strings.TrendHeartRate,  0],
        [Rez.Strings.TrendElevation,  1],
        [Rez.Strings.TrendStress,     2],
        [Rez.Strings.TrendBodyBattery,3],
        [Rez.Strings.TrendPressure,   4],
        [Rez.Strings.TrendSpo2,       5],
        [Rez.Strings.TrendSensorTemperature,6]
    ]; }
    function makeWeatherOptions() { return [
        [Rez.Strings.FieldHidden,    0],
        [Rez.Strings.WeatherTemp,    1],
        [Rez.Strings.WeatherWind,    2],
        [Rez.Strings.WeatherHighLow, 3],
        [Rez.Strings.WeatherCondition, 4],
        [Rez.Strings.WeatherPrecip,  5],
        [Rez.Strings.WeatherFeelsLike, 6]
    ]; }
    function makeWeatherSourceOptions() { return [
        ["Garmin", 0],
        ["QWeather", 1]
    ]; }
    // The phone settings expose the individual AMOLED field choices.
    function makeLowPowerOptions() { return [
        [Rez.Strings.LowPowerSimple, 1],
        [Rez.Strings.LowPowerFull,   0]
    ]; }

    // [identifier, title-resource, property-key, options]
    const DESCRIPTORS = [
        [:ampm,        Rez.Strings.SettingShowAmPm,         "ShowAmPm",         null],
        [:seconds,     Rez.Strings.SettingShowSecondsActive,"ShowSecondsActive",null],
        [:temperatureUnit, Rez.Strings.SettingTemperatureUnit, "TemperatureUnit", null],
        [:ring,        Rez.Strings.SettingRingField,        "RingField",        null],
        [:trend,       Rez.Strings.SettingTrendField,       "TrendField",       null],
        [:chartCustom, "Chart area custom data", "ChartCustomData", null],
        [:chartField, "Chart area upper field", "ChartDataField", CNFieldOptions.FIELD_OPTIONS],
        [:chartFieldBottom, "Chart area lower field", "ChartDataFieldBottom", CNFieldOptions.FIELD_OPTIONS],
        [:topLeft,     Rez.Strings.SettingFieldTopLeft,     "FieldTopLeft",     CNFieldOptions.FIELD_OPTIONS],
        [:topRight,    Rez.Strings.SettingFieldTopRight,    "FieldTopRight",    CNFieldOptions.FIELD_OPTIONS],
        [:left,        Rez.Strings.SettingFieldLeft,        "FieldLeft",        CNFieldOptions.FIELD_OPTIONS],
        [:center,      Rez.Strings.SettingFieldCenter,      "FieldCenter",      CNFieldOptions.FIELD_OPTIONS],
        [:right,       Rez.Strings.SettingFieldRight,       "FieldRight",       CNFieldOptions.FIELD_OPTIONS],
        [:weatherSource, "Weather source", "WeatherSource", null],
        [:wxLeft,      Rez.Strings.SettingWeatherLeft,      "WeatherLeft",      null],
        [:wxRight,     Rez.Strings.SettingWeatherRight,     "WeatherRight",     null],
        [:lowPower,    Rez.Strings.SettingLowPowerStyle,    "LowPowerStyle",    null]
    ];

    function initialize() {
        Menu2.initialize({:title => load(Rez.Strings.SettingsTitle)});
        for (var i = 0; i < DESCRIPTORS.size(); i += 1) {
            var d = DESCRIPTORS[i];
            var id = d[0];
            if (id == :lowPower && !SharedAodFields.hasSettings()) { continue; }
            if (id == :weatherSource && !CNWeatherProvider.available()) { continue; }
            if (id == :chartCustom || id == :chartField || id == :chartFieldBottom) {
                var available = false;
                try { available = Application.Properties.getValue("ChartCustomData") != null; } catch (e) {}
                if (!available) { continue; }
            }
            addItem(new WatchUi.MenuItem(load(d[1]), subLabel(id), id, null));
        }
    }

    private function load(id as Lang.ResourceId or Lang.String) as Lang.String {
        if (id instanceof Lang.String) {
            if ((WatchUi.loadResource(Rez.Strings.CalendarLanguage) as Lang.String).equals("zh")) {
                if (id.equals("Weather source")) { return "天气来源"; }
                if (id.equals("QWeather")) { return "和风天气"; }
                if (id.equals("Chart area custom data")) { return "图表区自定义数据"; }
                if (id.equals("Chart area upper field")) { return "图表区上排数据"; }
                if (id.equals("Chart area lower field")) { return "图表区下排数据"; }
            }
            return id;
        }
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
        return load(option[0] as Lang.ResourceId);
    }

    private function extendedFieldOptions() as Lang.Array { return CNFieldOptions.options(); }

    function optionsFor(id as Lang.Symbol) as Lang.Array or Null {
        if (id == :topLeft || id == :topRight || id == :left || id == :center || id == :right || id == :chartField || id == :chartFieldBottom) {
            return extendedFieldOptions();
        }
        if (id == :ampm || id == :seconds || id == :chartCustom) { return makeOnOff(); }
        if (id == :temperatureUnit) { return makeTemperatureUnitOptions(); }
        if (id == :ring) { return makeRingOptions(); }
        if (id == :trend) { return makeTrendOptions(); }
        if (id == :weatherSource) { return makeWeatherSourceOptions(); }
        if (id == :wxLeft || id == :wxRight) { return makeWeatherOptions(); }
        if (id == :lowPower) { return makeLowPowerOptions(); }
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

(:QWeatherEnabled)
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

(:QWeatherEnabled)
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
