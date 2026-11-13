using Toybox;
using Toybox.Activity;
using Toybox.ActivityMonitor;
using Toybox.Application;
using Toybox.Complications;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;
using Toybox.Weather;

// Data and settings for the shared AMOLED renderer. Call from full AOD updates.
module SharedAodFields {
    const HIDDEN = 0;
    const STEPS = 1;
    const FLOORS = 2;
    const DISTANCE = 4;
    const BATTERY = 5;
    const STRESS = 6;
    const HEART = 7;
    const BODY_BATTERY = 8;
    const DATE = 10;
    const WEEKDAY = 11;
    const TEMPERATURE = 12;
    const ACTIVE_MINUTES = 14;
    const STEP_GOAL = 15;
    const CALORIES = 23;
    const WEEKLY_MINUTES = 26;
    const BATTERY_DAYS = 29;
    const NOTIFICATIONS = 35;
    const ALARMS = 48;
    var _lastMinute = -1;
    var _lastSelection = -1;
    var _lastFields = [] as Lang.Array<Lang.Array<Lang.String>>;
    var _labels = null;

    // AodLabels stores the language marker, then these labels in index order.
    const LABEL_INDEX = {
        STEPS => 1, FLOORS => 2, DISTANCE => 3, BATTERY => 4,
        STRESS => 5, HEART => 6, BODY_BATTERY => 7, DATE => 8,
        WEEKDAY => 9, TEMPERATURE => 10, ACTIVE_MINUTES => 11, STEP_GOAL => 12,
        CALORIES => 13, WEEKLY_MINUTES => 14, BATTERY_DAYS => 15, NOTIFICATIONS => 16,
        ALARMS => 17
    };

    function setting(key as Lang.String, fallback as Lang.Number) as Lang.Number {
        var value = Application.Properties.getValue(key);
        return value instanceof Lang.Number ? value : fallback;
    }

    function hasSettings() as Lang.Boolean {
        try { return Application.Properties.getValue("LowPowerStyle") instanceof Lang.Number; }
        catch (e) { return false; }
    }

    function labels() as Lang.Array<Lang.String> {
        if (_labels == null) {
            var parts = [] as Lang.Array<Lang.String>;
            var rest = WatchUi.loadResource(Rez.Strings.AodLabels) as Lang.String;
            var splitAt = rest.find("|");
            while (splitAt != null) {
                parts.add(rest.substring(0, splitAt));
                rest = rest.substring(splitAt + 1, rest.length());
                splitAt = rest.find("|");
            }
            parts.add(rest);
            _labels = parts;
        }
        return _labels;
    }

    function weekdayText(day as Lang.Number) as Lang.String {
        var chinese = labels()[0].equals("zh");
        return chinese ? ["周日", "周一", "周二", "周三", "周四", "周五", "周六"][day - 1] :
            ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][day - 1];
    }

    function collect(simple as Lang.Boolean, defaults as Lang.Array, dateText as Lang.String,
                     day as Lang.Number, batteryFallback) as Lang.Array<Lang.Array<Lang.String>> {
        if (simple) { return []; }
        var left = selectedField("AodLeftField", defaults[0]);
        var center = selectedField("AodCenterField", defaults[1]);
        var right = selectedField("AodRightField", defaults[2]);
        var minute = (Time.now().value() / 60).toNumber();
        var selection = left * 4096 + center * 64 + right;
        if (minute == _lastMinute && selection == _lastSelection) { return _lastFields; }

        var fields = [] as Lang.Array<Lang.Array<Lang.String>>;
        var selected = [left, center, right];
        var sources = {};
        var rendered = {};
        for (var i = 0; i < selected.size(); i += 1) {
            var field = selected[i];
            if (field == HIDDEN) { continue; }
            if (!rendered.hasKey(field)) {
                var value = "--";
                try {
                    value = fieldText(field, dateText, day, batteryFallback, sources);
                } catch (e) {}
                var label = labels()[LABEL_INDEX[field]];
                rendered[field] = [value, label];
            }
            fields.add(rendered[field] as Lang.Array<Lang.String>);
        }
        _lastMinute = minute;
        _lastSelection = selection;
        _lastFields = fields;
        return fields;
    }

    function selectedField(key as Lang.String, fallback as Lang.Number) as Lang.Number {
        var value = setting(key, fallback);
        return LABEL_INDEX.hasKey(value) ? value : HIDDEN;
    }

    // Reuse each system snapshot within this frame, including unavailable sources.
    function activityInfo(sources as Lang.Dictionary) {
        if (!sources.hasKey(:activity)) {
            sources[:activity] = null;
            sources[:activity] = ActivityMonitor.getInfo();
        }
        return sources[:activity];
    }

    function deviceSettings(sources as Lang.Dictionary) {
        if (!sources.hasKey(:settings)) {
            sources[:settings] = null;
            sources[:settings] = System.getDeviceSettings();
        }
        return sources[:settings];
    }

    function systemStats(sources as Lang.Dictionary) {
        if (!sources.hasKey(:stats)) {
            sources[:stats] = null;
            try { sources[:stats] = System.getSystemStats(); } catch (e) {}
        }
        return sources[:stats];
    }

    function numberText(value) as Lang.String {
        return value == null ? "--" : value.format("%d");
    }

    function fieldText(field as Lang.Number, dateText as Lang.String, day as Lang.Number,
                       batteryFallback, sources as Lang.Dictionary) as Lang.String {
        switch (field) {
            case DATE: return dateText;
            case WEEKDAY: return weekdayText(day);
            case HEART: return heartRateText();
            case BATTERY:
                var stats = systemStats(sources);
                var battery = stats != null && stats.battery != null ? stats.battery : batteryFallback;
                return battery == null ? "--" : battery.toNumber().format("%d") + "%";
            case BATTERY_DAYS:
                var estimate = systemStats(sources);
                if (estimate != null && (estimate has :batteryInDays) && estimate.batteryInDays != null) {
                    return estimate.batteryInDays.format("%.1f") + "d";
                }
                return "--";
            case STRESS:
            case BODY_BATTERY:
                if ((Toybox has :Complications) && (Complications has :getComplication)) {
                    var type = field == STRESS ? Complications.COMPLICATION_TYPE_STRESS :
                        Complications.COMPLICATION_TYPE_BODY_BATTERY;
                    var item = Complications.getComplication(new Complications.Id(type));
                    if (item != null && item.value instanceof Lang.Number && item.value >= 0) {
                        return numberText(item.value);
                    }
                }
                return "--";
            case TEMPERATURE:
                return temperatureText(sources);
            case NOTIFICATIONS:
            case ALARMS:
                var device = deviceSettings(sources);
                if (device == null) { return "--"; }
                if (field == NOTIFICATIONS && (device has :notificationCount)) { return numberText(device.notificationCount); }
                if (field == ALARMS && (device has :alarmCount)) { return numberText(device.alarmCount); }
                return "--";
        }

        var info = activityInfo(sources);
        if (info == null) { return "--"; }
        switch (field) {
            case STEPS: return numberText(info.steps);
            case FLOORS: return (info has :floorsClimbed) ? numberText(info.floorsClimbed) : "--";
            case CALORIES: return numberText(info.calories);
            case STEP_GOAL:
                if (info.steps != null && info.stepGoal != null && info.stepGoal > 0) {
                    return (info.steps * 100.0 / info.stepGoal).format("%.0f") + "%";
                }
                return "--";
            case DISTANCE:
                if (info.distance == null) { return "--"; }
                var distanceDevice = deviceSettings(sources);
                var miles = distanceDevice != null && distanceDevice.distanceUnits == System.UNIT_STATUTE;
                return (info.distance / (miles ? 160934.4 : 100000.0)).format("%.1f") + (miles ? "mi" : "km");
            case ACTIVE_MINUTES:
                return (info has :activeMinutesDay) && info.activeMinutesDay != null ?
                    numberText(info.activeMinutesDay.total) : "--";
            case WEEKLY_MINUTES:
                return (info has :activeMinutesWeek) && info.activeMinutesWeek != null ?
                    numberText(info.activeMinutesWeek.total) : "--";
        }
        return "--";
    }

    function temperatureText(sources as Lang.Dictionary) as Lang.String {
        if (!(Toybox has :Weather) || !(Weather has :getCurrentConditions)) { return "--"; }
        var weather = Weather.getCurrentConditions();
        if (weather == null || weather.temperature == null || weather.observationTime == null) { return "--"; }
        var age = Time.now().value() - weather.observationTime.value();
        if (age < 0 || age > 7200) { return "--"; }
        var device = deviceSettings(sources);
        var fahrenheit = device != null && device.temperatureUnits == System.UNIT_STATUTE;
        var temperature = fahrenheit ? weather.temperature * 1.8 + 32 : weather.temperature;
        return temperature.format("%.0f") + (fahrenheit ? "°F" : "°C");
    }

    // Read the system's current value or one recent sample per AOD refresh.
    function heartRateText() as Lang.String {
        try {
            var info = Activity.getActivityInfo();
            if (info != null) {
                var rate = info.currentHeartRate;
                if (rate != null && rate > 0 && rate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    return rate.format("%d");
                }
            }
        } catch (e) {}

        if (ActivityMonitor has :getHeartRateHistory) {
            try {
                var history = ActivityMonitor.getHeartRateHistory(1, true);
                var sample = history == null ? null : history.next();
                if (sample != null) {
                    var rate = sample.heartRate;
                    var sampleTime = sample.when;
                    if (rate != null && rate > 0 && rate != ActivityMonitor.INVALID_HR_SAMPLE && sampleTime != null) {
                        var age = Time.now().value() - sampleTime.value();
                        if (age >= 0 && age <= 60) { return rate.format("%d"); }
                    }
                }
            } catch (e) {}
        }
        return "--";
    }
}
