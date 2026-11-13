using Toybox.Lang;
using Toybox.System;

(:QWeatherEnabled)
module CNFieldOptions {
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
    function appendFieldOption(options, label, value) { options.add([label, value]); }
    function options() as Lang.Array {
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

    function supportsSleepScore() as Lang.Boolean {
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


}
