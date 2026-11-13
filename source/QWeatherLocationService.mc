using Toybox.Application;
using Toybox.Background;
using Toybox.Communications;
using Toybox.Lang;
using Toybox.Position;
using Toybox.System;
using Toybox.Time;
using Toybox.Weather;

(:background, :QWeatherEnabled)
class QWeatherLocationService extends System.ServiceDelegate {
    private var _config as Lang.Array<Lang.String> or Null = null;
    private var _coordinates = null;
    private var _requestCoordinates = null;
    private var _result = null;
    function initialize() { ServiceDelegate.initialize(); }
    private function coordinates() {
        var result = null;
        var weatherTime = 0;
        try {
            var weather = Weather.getCurrentConditions();
            if (weather != null && weather.observationLocationPosition != null) {
                result = weather.observationLocationPosition.toDegrees();
                if (weather.observationTime != null) { weatherTime = weather.observationTime.value(); }
            }
        } catch (e) {}
        try {
            var gps = Position.getInfo();
            if (gps.position != null && gps.when != null && gps.when.value() >= weatherTime) {
                var latest = gps.position.toDegrees();
                if (QWeatherLocation.validCoordinates(latest)) { result = latest; }
            }
        } catch (e) {}
        if (QWeatherLocation.validCoordinates(result)) { return result; }
        return cachedCoordinates();
    }

    private function cachedCoordinates() {
        var config = QWeatherLocation.getConfig();
        if (config != null) {
            var weather = QWeatherWeather.readCache(config[0]);
            var city = QWeatherLocation.readCache(config[0]);
            if (weather != null && (city == null || weather["time"] >= city["time"])) { return weather["coordinates"]; }
            if (city != null) { return city["coordinates"]; }
        }
        try {
            var stored = Application.Storage.getValue("CNWatchFaceWeather");
            if (stored instanceof Lang.Dictionary && QWeatherLocation.validCoordinates(stored.get("location"))) {
                return stored["location"];
            }
        } catch (e) {}
        return null;
    }


    private function validRequest() {
        var current = QWeatherLocation.getConfig();
        if (current == null || _config == null) { return false; }
        if (!current[0].equals(_config[0])) { return false; }
        if (!current[1].equals(_config[1])) { return false; }
        if (!current[2].equals(_config[2])) { return false; }
        if (!(QWeatherLocation.isSelected() || QWeatherWeather.isSelected())) { return false; }
        return QWeatherLocation.validCoordinates(_coordinates);
    }
    private function ready(key as Lang.String, now as Lang.Number) {
        var retry = Application.Storage.getValue(key);
        return !(retry instanceof Lang.Number) || retry <= now || retry > now + 3600;
    }
    private function nextJob(now as Lang.Number) {
        if (!validRequest()) { return 0; }
        var weather = QWeatherWeather.readCache(_config[0]);
        if (QWeatherWeather.isSelected() && ready(QWeatherWeather.RETRY_KEY, now) &&
            QWeatherWeather.needsCurrent(weather, _config[0], _coordinates, now)) { return 1; }
        var location = QWeatherLocation.readCache(_config[0]);
        if (ready(QWeatherLocation.RETRY_KEY, now) &&
            QWeatherLocation.needsLookup(location, _coordinates, now)) { return 2; }
        if (QWeatherWeather.isSelected() && QWeatherWeather.sameLocation(weather, _config[0], _coordinates) && ready(QWeatherWeather.DAILY_RETRY_KEY, now) &&
            QWeatherWeather.needsDaily(weather, _config[0], _coordinates, now)) { return 3; }
        return 0;
    }
    private function finish() as Void {
        try {
            // One request per invocation stays inside Garmin's 30-second limit.
            QWeatherLocation.schedule(nextJob(Time.now().value()) != 0);
        } catch (e) {}
        Background.exit(_result);
    }
    private function send(path as Lang.String, params as Lang.Dictionary, callback as Lang.Method) as Void {
        Communications.makeWebRequest("https://" + _config[0] + path, params, {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {"X-QW-Api-Key" => _config[1], "Accept" => "application/json"},
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        }, callback);
    }
    function onTemporalEvent() as Void {
        _result = null;
        try {
            _config = QWeatherLocation.getConfig();
            if (_config == null || !(QWeatherLocation.isSelected() || QWeatherWeather.isSelected())) {
                Background.deleteTemporalEvent(); Background.exit(null); return;
            }
            QWeatherLocation.schedule(false);
            _coordinates = coordinates();
            _requestCoordinates = QWeatherCoordinates.requestCoordinates(_coordinates, _config[2].equals("mainland"));
            if (_requestCoordinates == null) { Background.exit(null); return; }
            var now = Time.now().value();
            var job = nextJob(now);
            if (job == 2) {
                Application.Storage.setValue(QWeatherLocation.RETRY_KEY, now + 3600);
                send("/geo/v2/city/lookup", {
                    "location" => _requestCoordinates[1].format("%.4f") + "," + _requestCoordinates[0].format("%.4f"),
                    "lang" => "zh", "number" => "1"
                }, method(:onResponse));
            } else if (job == 1 || job == 3) {
                Application.Storage.setValue(job == 1 ? QWeatherWeather.RETRY_KEY : QWeatherWeather.DAILY_RETRY_KEY, now + 3600);
                var path = job == 1 ? "/weather/v1/current/" : "/weather/v1/daily/";
                path += _requestCoordinates[0].format("%.2f") + "/" + _requestCoordinates[1].format("%.2f");
                if (job == 1) {
                    send(path, {"lang" => "zh", "localTime" => "false"}, method(:onCurrentResponse));
                } else {
                    send(path, {"days" => "2", "lang" => "zh", "localTime" => "false"}, method(:onDailyResponse));
                }
            } else { finish(); }
        } catch (e) { finish(); }
    }
    function onResponse(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        try {
            var city = QWeatherLocation.responseName(responseCode, data);
            if (validRequest() && city != null) {
                _result = {"host" => _config[0], "region" => _config[2], "name" => city,
                    "coordinates" => _coordinates, "time" => Time.now().value()};
                Application.Storage.setValue(QWeatherLocation.STORAGE_KEY, _result);
                Application.Storage.deleteValue(QWeatherLocation.RETRY_KEY);
            }
        } catch (e) {}
        finish();
    }
    function onCurrentResponse(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        try {
            var current = QWeatherWeather.current(responseCode, data);
            if (validRequest() && QWeatherWeather.isSelected() && current != null) {
                var cache = QWeatherWeather.readCache(_config[0]);
                if (!QWeatherWeather.sameLocation(cache, _config[0], _coordinates)) { cache = {}; }
                cache["host"] = _config[0]; cache["region"] = _config[2];
                cache["coordinates"] = _coordinates; cache["time"] = Time.now().value();
                cache["current"] = current;
                Application.Storage.setValue(QWeatherWeather.STORAGE_KEY, cache);
                Application.Storage.deleteValue(QWeatherWeather.RETRY_KEY);
                _result = true;
            }
        } catch (e) {}
        finish();
    }
    function onDailyResponse(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null) as Void {
        try {
            var forecast = QWeatherWeather.daily(responseCode, data, Time.now().value());
            var cache = QWeatherWeather.readCache(_config[0]);
            if (validRequest() && QWeatherWeather.isSelected() && forecast != null &&
                QWeatherWeather.sameLocation(cache, _config[0], _coordinates)) {
                // A night period can remain valid after its parent day expires.
                var previous = cache.get("daily");
                var now = Time.now().value();
                if (forecast.get("precipitationChance") == null && previous instanceof Lang.Dictionary &&
                    previous.get("precipitationStart") instanceof Lang.Number && previous.get("precipitationEnd") instanceof Lang.Number &&
                    now >= previous["precipitationStart"] && now < previous["precipitationEnd"]) {
                    forecast["precipitationChance"] = previous.get("precipitationChance");
                    forecast["precipitationStart"] = previous["precipitationStart"];
                    forecast["precipitationEnd"] = previous["precipitationEnd"];
                }
                cache["daily"] = forecast; cache["dailyTime"] = Time.now().value();
                Application.Storage.setValue(QWeatherWeather.STORAGE_KEY, cache);
                Application.Storage.deleteValue(QWeatherWeather.DAILY_RETRY_KEY);
                _result = true;
            }
        } catch (e) {}
        finish();
    }
}
