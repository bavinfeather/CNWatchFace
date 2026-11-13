using Toybox.Lang;
using Toybox.Position;
using Toybox.Time;

// Foreground conversion stays outside the older devices' full renderer class.
(:QWeatherEnabled)
module QWeatherAdapter {
    function conditions(nowSeconds as Lang.Number) {
        var cache = QWeatherWeather.snapshot;
        if (!(cache instanceof Lang.Dictionary)) { return null; }
        var current = cache["current"];
        var stored = new CNWatchFaceStoredWeather();
        stored.observationTime = new Time.Moment(cache["time"]);
        stored.temperature = QWeatherWeather.number(current.get("temperature"), -100, 70);
        var feels = QWeatherWeather.number(current.get("feelsLikeTemperature"), -120, 100);
        stored.feelsLikeTemperature = feels == null ? null : feels.toFloat();
        var humidity = QWeatherWeather.number(current.get("relativeHumidity"), 0, 100);
        stored.relativeHumidity = humidity == null ? null : humidity.toNumber();
        var speed = QWeatherWeather.number(current.get("windSpeed"), 0, 150);
        stored.windSpeed = speed == null ? null : speed.toFloat();
        var bearing = QWeatherWeather.number(current.get("windBearing"), 0, 365);
        stored.windBearing = bearing == null ? null : bearing.toNumber();
        var uv = QWeatherWeather.number(current.get("uvIndex"), 0, 30);
        stored.uvIndex = uv == null ? null : uv.toFloat();
        var description = QWeatherLocation.clean(current.get("conditionText"));
        stored.conditionText = description.length() > 0 && description.length() <= 32 ? description : null;
        var coords = cache["coordinates"];
        stored.observationLocationPosition = new Position.Location({
            :latitude => coords[0], :longitude => coords[1], :format => :degrees});
        stored.observationLocationName = QWeatherLocation.name;
        var forecast = cache.get("daily");
        if (forecast instanceof Lang.Dictionary) {
            var probability = QWeatherWeather.number(forecast.get("precipitationChance"), 0, 100);
            var start = forecast.get("precipitationStart");
            if (probability != null && forecast.get("precipitationEnd") instanceof Lang.Number && nowSeconds < forecast["precipitationEnd"] &&
                (!(start instanceof Lang.Number) || nowSeconds >= start)) {
                stored.precipitationChance = probability.toNumber();
            }
        }
        if (forecast instanceof Lang.Dictionary && forecast.get("start") instanceof Lang.Number &&
            forecast.get("end") instanceof Lang.Number && nowSeconds >= forecast["start"] && nowSeconds < forecast["end"]) {
            stored.highTemperature = QWeatherWeather.number(forecast.get("highTemperature"), -100, 70);
            stored.lowTemperature = QWeatherWeather.number(forecast.get("lowTemperature"), -100, 70);
            var sunrise = QWeatherWeather.number(forecast.get("sunrise"), 0, 2147483647);
            var sunset = QWeatherWeather.number(forecast.get("sunset"), 0, 2147483647);
            var nextSunrise = QWeatherWeather.number(forecast.get("nextSunrise"), 0, 2147483647);
            stored.qSunrise = sunrise == null ? null : new Time.Moment(sunrise.toNumber());
            stored.qSunset = sunset == null ? null : new Time.Moment(sunset.toNumber());
            stored.qNextSunrise = nextSunrise == null ? null : new Time.Moment(nextSunrise.toNumber());
        }
        return stored;
    }

}
