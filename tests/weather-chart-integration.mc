using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;

module AuditIntegration {
    var frames = 0;
    var phase = 0;
    var clocks = 0;
    var aod = 0;
    var minimum = 2147483647;
    var oldMinimum = 0;
    var callbacks = 0;
    var chartAvailable = false;
    var options = null;
    var seen = null;
    var drawn = 0;
    const FIELDS = [1, 4, 7, 12, 20, 22, 30, 31, 36, 37, 38, 40, 43, 45, 49, 50, 51, 53, 54, 55, 56, 57, 58, 59, 73, 0];

    function seed() {
        var now = Time.now().value();
        Application.Storage.setValue(QWeatherLocation.STORAGE_KEY, {
            "host" => "test.re.qweatherapi.com", "region" => "mainland", "name" => "北京",
            "time" => now, "coordinates" => [39.92, 116.41]});
        Application.Storage.setValue(QWeatherWeather.STORAGE_KEY, {
            "host" => "test.re.qweatherapi.com", "region" => "mainland", "time" => now,
            "coordinates" => [39.92, 116.41],
            "current" => {"temperature" => 0, "feelsLikeTemperature" => -2.5, "relativeHumidity" => 72,
                "windSpeed" => 3.0, "windBearing" => 123, "conditionText" => "小雪", "uvIndex" => 0},
            "daily" => {"start" => now - 600, "end" => now + 86400, "highTemperature" => 5.5,
                "lowTemperature" => -3.0, "precipitationChance" => 35, "precipitationEnd" => now + 3600,
                "sunrise" => now - 1800, "sunset" => now + 7200}});
    }

    function prepare() {
        frames += 1;
        if (frames == 1) {
            try { chartAvailable = Application.Properties.getValue("ChartCustomData") != null; } catch (e) {}
            if (chartAvailable) {
                options = CNFieldOptions.options();
                seen = [];
                for (var i = 0; i < options.size(); i += 1) { seen.add(false); }
            }
        }
        if (frames % 40 == 1) {
            phase = ((frames - 1) / 40).toNumber() % 6;
            Application.Properties.setValue("QWeatherHost", phase == 0 ? "" : "test.re.qweatherapi.com");
            Application.Properties.setValue("QWeatherKey", phase == 0 ? "" : "fixture-key");
            Application.Properties.setValue("QWeatherRegion", 1);
            Application.Properties.setValue("WeatherSource", phase == 1 ? 0 : 1);
            Application.Properties.setValue("LowPowerStyle", (phase % 2));
            if (chartAvailable) {
                Application.Properties.setValue("ChartCustomData", phase % 2);
                Application.Properties.setValue("ChartDataField", FIELDS[((frames - 1) / 40).toNumber() % FIELDS.size()]);
                Application.Properties.setValue("ChartDataFieldBottom", FIELDS[(((frames - 1) / 40).toNumber() + 1) % FIELDS.size()]);
            }
            Application.Properties.setValue("FieldRight", 53);
            Application.Properties.setValue("FieldTopLeft", FIELDS[((frames - 1) / 40).toNumber() % FIELDS.size()]);
            seed();
            if (phase == 3) {
                Application.Storage.setValue(QWeatherWeather.STORAGE_KEY, {"current" => "damaged"});
                Application.Storage.setValue(QWeatherLocation.STORAGE_KEY, "damaged");
            }
            if (phase == 4) {
                Application.Storage.setValue(QWeatherWeather.STORAGE_KEY, {
                    "host" => "test.re.qweatherapi.com", "region" => "mainland", "time" => Time.now().value(),
                    "coordinates" => [0, 0], "current" => {"temperature" => 5, "relativeHumidity" => "bad", "windSpeed" => "bad"},
                    "daily" => {"start" => "bad", "end" => []}});
            }
            Application.getApp().onSettingsChanged();
            System.println("INTEGRATION_PHASE " + phase);
        }
        if (frames % 40 == 16) {
            Application.getApp().onBackgroundData(true);
            callbacks += 1;
        }
        if (chartAvailable) {
            var index = (frames - 1) % options.size();
            Application.Properties.setValue("ChartDataField", options[index][1]);
            Application.Properties.setValue("ChartDataFieldBottom", options[(index + 1) % options.size()][1]);
        }
    }

    function finish(lowPower as Lang.Boolean, conditions) {
        if (chartAvailable && !lowPower && phase % 2 == 1) {
            var index = (frames - 1) % options.size();
            if (!seen[index]) { seen[index] = true; drawn += 1; }
            index = (index + 1) % options.size();
            if (!seen[index]) { seen[index] = true; drawn += 1; }
        }
        if (!lowPower && phase != 1) {
            if (phase == 0 || phase == 3) {
                if (conditions != null) { throw new Lang.InvalidValueException("invalid weather cache was displayed"); }
            } else {
                var expected = phase == 4 ? 5 : 0;
                if (conditions == null || conditions.temperature != expected) { throw new Lang.InvalidValueException("weather source mismatch"); }
            }
        }
        if (clocks + aod != frames) { throw new Lang.InvalidValueException("clock missing from frame"); }
        var free = System.getSystemStats().freeMemory;
        if (free < minimum) { minimum = free; }
        if (frames % 100 == 0) { System.println("INTEGRATION_MEMORY frame=" + frames + " free=" + free + " min=" + minimum); }
        if (frames < 600) { WatchUi.requestUpdate(); }
        else {
            if (chartAvailable && drawn != options.size()) { throw new Lang.InvalidValueException("incomplete chart field coverage"); }
            System.println("AUDIT_COMPLETE integration frames=" + frames + " clocks=" + clocks + " aod=" + aod + " callbacks=" + callbacks + " minFree=" + minimum + " chartFields=" + drawn);
        }
    }
}
