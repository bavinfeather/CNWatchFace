using Toybox.Application;
using Toybox.Background;
using Toybox.Lang;
using Toybox.Time;

(:background, :QWeatherEnabled)
module QWeatherLocation {
    const STORAGE_KEY = "CNWatchFaceQWeatherLocation";
    const RETRY_KEY = "CNWatchFaceQWeatherRetry";
    const CHECK_SECONDS = 900;
    const REFRESH_SECONDS = 86400;
    var configured = false;
    var name = null;

    function clean(value) {
        if (!(value instanceof Lang.String)) { return ""; }
        var start = 0;
        var end = value.length();
        while (start < end && " \r\n\t".find(value.substring(start, start + 1)) != null) { start += 1; }
        while (end > start && " \r\n\t".find(value.substring(end - 1, end)) != null) { end -= 1; }
        return value.substring(start, end);
    }

    function normalizeHost(value) {
        var host = clean(value).toLower();
        if (host.find("https://") == 0) { host = host.substring(8, host.length()); }
        if (host.length() > 0 && host.substring(host.length() - 1, host.length()).equals("/")) {
            host = host.substring(0, host.length() - 1);
        }
        var suffix = ".qweatherapi.com";
        if (host.length() <= suffix.length() || host.length() > 100 ||
            !host.substring(host.length() - suffix.length(), host.length()).equals(suffix)) { return null; }
        var allowed = "abcdefghijklmnopqrstuvwxyz0123456789-.";
        for (var i = 0; i < host.length(); i += 1) {
            if (allowed.find(host.substring(i, i + 1)) == null) { return null; }
        }
        if (host.find("..") != null || host.find(".") == 0 || host.find("-") == 0) { return null; }
        return host;
    }

    function getConfig() as Lang.Array<Lang.String> or Null {
        var host = normalizeHost(Application.Properties.getValue("QWeatherHost"));
        var key = clean(Application.Properties.getValue("QWeatherKey"));
        if (host == null || key.length() == 0 || key.find("\r") != null || key.find("\n") != null) { return null; }
        var region = Application.Properties.getValue("QWeatherRegion") == 0 ? "other" : "mainland";
        return [host, key, region];
    }

    function isSelected() {
        try {
            if (Application.Properties.getValue("ChartCustomData") == 1 &&
                (Application.Properties.getValue("ChartDataField") == 53 ||
                Application.Properties.getValue("ChartDataFieldBottom") == 53)) { return true; }
        } catch (e) {}
        var fields = ["FieldTopLeft", "FieldTopRight", "FieldLeft", "FieldRight"];
        for (var i = 0; i < fields.size(); i += 1) {
            if (Application.Properties.getValue(fields[i]) == 53) { return true; }
        }
        return Application.Properties.getValue("BottomFieldCount") != 2 &&
            Application.Properties.getValue("FieldCenter") == 53;
    }

    function validCoordinates(value) {
        return value instanceof Lang.Array && value.size() == 2 &&
            (value[0] instanceof Lang.Number || value[0] instanceof Lang.Float || value[0] instanceof Lang.Double) &&
            (value[1] instanceof Lang.Number || value[1] instanceof Lang.Float || value[1] instanceof Lang.Double) &&
            value[0] >= -90 && value[0] <= 90 && value[1] >= -180 && value[1] <= 180;
    }

    function readCache(host as Lang.String) as Lang.Dictionary or Null {
        try {
            var cache = Application.Storage.getValue(STORAGE_KEY);
            if (!(cache instanceof Lang.Dictionary) || !(cache.get("region") instanceof Lang.String)) { return null; }
            if (!cache["region"].equals(Application.Properties.getValue("QWeatherRegion") == 0 ? "other" : "mainland")) { return null; }
            if (cache instanceof Lang.Dictionary && cache.get("host") instanceof Lang.String &&
                cache["host"].equals(host) && cache.get("name") instanceof Lang.String &&
                cache["name"].length() > 0 && cache.get("time") instanceof Lang.Number &&
                validCoordinates(cache.get("coordinates"))) { return cache; }
        } catch (e) {}
        return null;
    }

    function reload() as Void {
        var config = getConfig();
        configured = config != null;
        name = null;
        if (configured) {
            var cache = readCache(config[0]);
            if (cache != null) { name = cache["name"]; }
        }
    }

    function schedule(initial as Lang.Boolean) as Void {
        if (getConfig() == null || !(isSelected() || QWeatherWeather.isSelected())) {
            Background.deleteTemporalEvent();
            return;
        }
        var last = Background.getLastTemporalEventTime();
        var next = Time.now();
        if (last != null) { next = last.add(new Time.Duration(initial ? 300 : CHECK_SECONDS)); }
        Background.registerForTemporalEvent(next);
    }

    function needsLookup(cache, coordinates, now) {
        if (!validCoordinates(coordinates)) { return false; }
        if (cache == null) { return true; }
        var old = cache["coordinates"];
        // Ignore small coordinate jitter; check again daily even without movement.
        return now < cache["time"] || now - cache["time"] >= REFRESH_SECONDS ||
            coordinates[0] - old[0] > 0.02 || old[0] - coordinates[0] > 0.02 ||
            coordinates[1] - old[1] > 0.02 || old[1] - coordinates[1] > 0.02;
    }

    function responseName(responseCode, data) {
        if (responseCode != 200 || !(data instanceof Lang.Dictionary) ||
            !(data.get("code") instanceof Lang.String) || !data["code"].equals("200")) { return null; }
        var locations = data.get("location");
        if (!(locations instanceof Lang.Array) || locations.size() == 0 ||
            !(locations[0] instanceof Lang.Dictionary)) { return null; }
        // GeoAPI may return a district. Prefer its parent city for the compact slot.
        var city = clean(locations[0].get("adm2"));
        if (city.length() == 0) { city = clean(locations[0].get("name")); }
        return city.length() > 0 && city.length() <= 64 ? city : null;
    }
}
