using Toybox.Application;
using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;

(:background, :QWeatherEnabled)
module QWeatherWeather {
    const STORAGE_KEY = "CNWatchFaceQWeatherWeather";
    const RETRY_KEY = "CNWatchFaceQWeatherWeatherRetry";
    const DAILY_RETRY_KEY = "CNWatchFaceQWeatherDailyRetry";
    var snapshot = null;

    function isSelected() { return Application.Properties.getValue("WeatherSource") == 1; }

    function number(value, low, high) {
        if ((value instanceof Lang.Number || value instanceof Lang.Float || value instanceof Lang.Double) &&
            value >= low && value <= high) { return value; }
        return null;
    }

    function measure(value, unit, low, high) {
        if (!(value instanceof Lang.Dictionary) || !(value.get("unit") instanceof Lang.String) ||
            !value["unit"].equals(unit)) { return null; }
        return number(value.get("value"), low, high);
    }

    function percent(value) {
        var n = number(value, 0, 1);
        return n == null ? null : (n * 100 + 0.5).toNumber();
    }

    function current(responseCode, data) as Lang.Dictionary or Null {
        if (responseCode != 200 || !(data instanceof Lang.Dictionary)) { return null; }
        var temperature = measure(data.get("temperature"), "°C", -100, 70);
        if (temperature == null) { return null; }
        var result = {"temperature" => temperature,
            "feelsLikeTemperature" => measure(data.get("feelsLike"), "°C", -120, 100),
            "relativeHumidity" => percent(data.get("humidity")),
            "uvIndex" => number(data.get("uvIndex"), 0, 30)};
        var condition = data.get("condition");
        if (condition instanceof Lang.Dictionary) {
            var text = QWeatherLocation.clean(condition.get("text"));
            if (text.length() > 0 && text.length() <= 32) { result["conditionText"] = text; }
        }
        var wind = data.get("wind");
        if (wind instanceof Lang.Dictionary) {
            var speed = measure(wind.get("speed"), "m/s", 0, 150);
            result["windSpeed"] = speed == null ? null : speed.toFloat();
            var direction = wind.get("direction");
            if (direction instanceof Lang.Dictionary) {
                var bearing = number(direction.get("degree"), 0, 365);
                result["windBearing"] = bearing == null ? null : bearing.toNumber();
            }
        }
        return result;
    }

    // The v1 requests explicitly use UTC. Accept only that documented format.
    function utcSeconds(value) {
        if (!(value instanceof Lang.String) || (value.length() != 17 && value.length() != 20) ||
            !value.substring(value.length() - 1, value.length()).equals("Z") ||
            !value.substring(4, 5).equals("-") || !value.substring(7, 8).equals("-") ||
            !value.substring(10, 11).equals("T") || !value.substring(13, 14).equals(":")) { return null; }
        var digitPositions = [0, 1, 2, 3, 5, 6, 8, 9, 11, 12, 14, 15];
        if (value.length() == 20) {
            if (!value.substring(16, 17).equals(":")) { return null; }
            digitPositions.add(17); digitPositions.add(18);
        }
        for (var i = 0; i < digitPositions.size(); i += 1) {
            var pos = digitPositions[i];
            if ("0123456789".find(value.substring(pos, pos + 1)) == null) { return null; }
        }
        try {
            var year = value.substring(0, 4).toNumber();
            var month = value.substring(5, 7).toNumber();
            var day = value.substring(8, 10).toNumber();
            var hour = value.substring(11, 13).toNumber();
            var minute = value.substring(14, 16).toNumber();
            var second = value.length() == 20 ? value.substring(17, 19).toNumber() : 0;
            if (year < 1970 || year > 2037) { return null; }
            if (month < 1 || month > 12 || day < 1 || day > 31 || hour > 23 || minute > 59 || second > 59) { return null; }
            var monthDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
            if (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) { monthDays[1] = 29; }
            if (day > monthDays[month - 1]) { return null; }
            var moment = Gregorian.moment({:year => year, :month => month, :day => day,
                :hour => hour, :minute => minute, :second => second});
            var check = Gregorian.utcInfo(moment, Time.FORMAT_SHORT);
            if (check.year != year || check.month != month || check.day != day) { return null; }
            return moment.value();
        } catch (e) { return null; }
    }

    function daily(responseCode, data, now) as Lang.Dictionary or Null {
        if (responseCode != 200 || !(data instanceof Lang.Dictionary)) { return null; }
        var days = data.get("days");
        if (!(days instanceof Lang.Array)) { return null; }
        var result = null;
        var nextSunrise = null;
        var probability = null;
        var probabilityStart = null;
        var probabilityEnd = null;
        for (var i = 0; i < days.size(); i += 1) {
            var day = days[i];
            if (!(day instanceof Lang.Dictionary)) { continue; }
            var astro = day.get("astro");
            var sunrise = astro instanceof Lang.Dictionary ? utcSeconds(astro.get("sunrise")) : null;
            if (sunrise != null && sunrise > now && (nextSunrise == null || sunrise < nextSunrise)) { nextSunrise = sunrise; }
            var periods = [day.get("daytime"), day.get("nighttime")];
            for (var j = 0; j < periods.size(); j += 1) {
                var period = periods[j];
                if (!(period instanceof Lang.Dictionary)) { continue; }
                var periodStart = utcSeconds(period.get("forecastStartTime"));
                var periodEnd = utcSeconds(period.get("forecastEndTime"));
                var precipitation = period.get("precipitation");
                if (periodStart != null && periodEnd != null && now >= periodStart && now < periodEnd &&
                    precipitation instanceof Lang.Dictionary) {
                    probability = percent(precipitation.get("probability"));
                    probabilityStart = periodStart;
                    probabilityEnd = periodEnd;
                }
            }
            var start = utcSeconds(day.get("forecastStartTime"));
            var end = utcSeconds(day.get("forecastEndTime"));
            if (start == null || end == null || now < start || now >= end) { continue; }
            var high = measure(day.get("temperatureMax"), "°C", -100, 70);
            var low = measure(day.get("temperatureMin"), "°C", -100, 70);
            if (high == null || low == null || high < low) { continue; }
            result = {"start" => start, "end" => end, "highTemperature" => high,
                "lowTemperature" => low, "uvIndex" => number(day.get("uvIndexMax"), 0, 30),
                "sunrise" => sunrise,
                "sunset" => astro instanceof Lang.Dictionary ? utcSeconds(astro.get("sunset")) : null};
        }
        if (result != null) {
            result["nextSunrise"] = nextSunrise;
            result["precipitationChance"] = probability;
            result["precipitationStart"] = probabilityStart;
            result["precipitationEnd"] = probabilityEnd;
        }
        return result;
    }

    function sameLocation(cache, host, coordinates) {
        return QWeatherLocation.validCoordinates(coordinates) && cache instanceof Lang.Dictionary && cache.get("host") instanceof Lang.String &&
            cache["host"].equals(host) && QWeatherLocation.validCoordinates(cache.get("coordinates")) &&
            !QWeatherLocation.needsLookup({"time" => 0, "coordinates" => cache["coordinates"]}, coordinates, 0);
    }

    function readCache(host as Lang.String) as Lang.Dictionary or Null {
        try {
            var cache = Application.Storage.getValue(STORAGE_KEY);
            if (!(cache instanceof Lang.Dictionary)) { return null; }
            if (!(cache.get("region") instanceof Lang.String)) { return null; }
            if (!cache["region"].equals(Application.Properties.getValue("QWeatherRegion") == 0 ? "other" : "mainland")) { return null; }
            var current = cache.get("current");
            if (!(current instanceof Lang.Dictionary)) { return null; }
            if (cache.get("host") instanceof Lang.String &&
                cache["host"].equals(host) && QWeatherLocation.validCoordinates(cache.get("coordinates")) &&
                cache.get("time") instanceof Lang.Number &&
                number(current.get("temperature"), -100, 70) != null) { return cache; }
        } catch (e) {}
        return null;
    }

    function reload() as Void {
        snapshot = null;
        var config = QWeatherLocation.getConfig();
        if (isSelected() && config != null) { snapshot = readCache(config[0]); }
    }

    function needsCurrent(cache, host, coordinates, now) {
        return !sameLocation(cache, host, coordinates) || now < cache["time"] || now - cache["time"] >= 1800;
    }

    function needsDaily(cache, host, coordinates, now) {
        if (!sameLocation(cache, host, coordinates)) { return true; }
        var forecast = cache.get("daily");
        var updated = cache.get("dailyTime");
        if (!(forecast instanceof Lang.Dictionary) || !(forecast.get("end") instanceof Lang.Number) ||
            !(updated instanceof Lang.Number)) { return true; }
        return now < updated || now - updated >= 10800 || now >= forecast["end"] ||
            (forecast.get("precipitationEnd") instanceof Lang.Number && now >= forecast["precipitationEnd"]);
    }
}
