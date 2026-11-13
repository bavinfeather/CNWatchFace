    private function auditQWeatherLocation() {
        var host = "test.re.qweatherapi.com";
        auditAssert(QWeatherLocation.normalizeHost("  https://TEST.re.qweatherapi.com/ \n").equals(host), "host normalization");
        var badHosts = [null, "", "http://test.re.qweatherapi.com", "qweatherapi.com",
            "test.re.qweatherapi.com.evil.com", "evil.com", "x@a.qweatherapi.com", "a.qweatherapi.com/path"];
        for (var i = 0; i < badHosts.size(); i += 1) {
            auditAssert(QWeatherLocation.normalizeHost(badHosts[i]) == null, "invalid host rejected " + i);
        }
        auditAssert(QWeatherLocation.validCoordinates([0, 0]), "zero coordinates valid");
        auditAssert(!QWeatherLocation.validCoordinates([91, 0]) &&
            !QWeatherLocation.validCoordinates([0, 181]) && !QWeatherLocation.validCoordinates(["39", 116]), "invalid coordinates");
        auditAssert(QWeatherLocation.responseName(200, AuditQWeather.data).equals("北京"), "Chinese parent city");
        auditAssert(QWeatherLocation.responseName(200, {"code" => "200", "location" => [{"name" => "东城"}]}).equals("东城"), "district fallback");
        var failures = [null, "bad", {}, {"code" => "401"}, {"code" => "200", "location" => []},
            {"code" => "200", "location" => [null]}, {"code" => "200", "location" => [{"name" => 12}]}];
        for (var i = 0; i < failures.size(); i += 1) {
            auditAssert(QWeatherLocation.responseName(200, failures[i]) == null, "invalid response rejected " + i);
        }
        auditAssert(QWeatherLocation.responseName(429, AuditQWeather.data) == null, "HTTP failure rejected");

        Application.Properties.setValue("QWeatherHost", host);
        Application.Properties.setValue("QWeatherKey", "fixture-key");
        Application.Properties.setValue("FieldLeft", 53);
        Application.Storage.deleteValue(QWeatherLocation.STORAGE_KEY);
        Application.Storage.deleteValue(QWeatherLocation.RETRY_KEY);
        var service = new QWeatherLocationService();
        service.onTemporalEvent();
        auditAssert(AuditQWeather.requests == 1 && AuditQWeather.result != null, "background response delivered");
        auditAssert(AuditQWeather.url.equals("https://" + host + "/geo/v2/city/lookup"), "correct GeoAPI path");
        auditAssert(AuditQWeather.params["location"].equals("116.4162,39.9214") &&
            AuditQWeather.params["lang"].equals("zh") && AuditQWeather.params["number"].equals("1"), "coordinate order and Chinese query");
        auditAssert(AuditQWeather.options[:headers]["X-QW-Api-Key"].equals("fixture-key") &&
            AuditQWeather.params.get("key") == null, "credentials sent only in header");
        QWeatherLocation.reload();
        auditAssert(QWeatherLocation.name.equals("北京"), "persisted Chinese cache restored");
        var cache = QWeatherLocation.readCache(host);
        Application.Properties.setValue("QWeatherRegion", 0);
        auditAssert(QWeatherLocation.readCache(host) == null, "city cache invalidated on coordinate region change");
        Application.Properties.setValue("QWeatherRegion", 1);
        var now = Time.now().value();
        auditAssert(!QWeatherLocation.needsLookup(cache, [39.921, 116.411], now), "jitter does not request");
        auditAssert(QWeatherLocation.needsLookup(cache, [40, 116.41], now), "movement requests");
        auditAssert(QWeatherLocation.needsLookup(cache, [39.92, 116.41], now + 86400), "daily refresh");
        auditAssert(QWeatherLocation.readCache("other.qweatherapi.com") == null, "cache bound to host");
        service.onTemporalEvent();
        auditAssert(AuditQWeather.requests == 1, "unchanged position makes no request");

        AuditQWeather.coordinates = [40, 116.41];
        AuditQWeather.responseCode = 429;
        service.onTemporalEvent();
        QWeatherLocation.reload();
        auditAssert(AuditQWeather.requests == 2 && QWeatherLocation.name.equals("北京"), "failure retains city");
        service.onTemporalEvent();
        auditAssert(AuditQWeather.requests == 2, "failure cooldown");
        Application.Storage.deleteValue(QWeatherLocation.RETRY_KEY);
        AuditQWeather.coordinates = null;
        service.onTemporalEvent();
        auditAssert(AuditQWeather.requests == 2, "no coordinates makes no request");

        AuditQWeather.coordinates = [40, 116.41];
        AuditQWeather.responseCode = 200;
        AuditQWeather.changeCredentials = true;
        service.onTemporalEvent();
        auditAssert(QWeatherLocation.readCache(host)["coordinates"][0] == 39.92, "inflight old credentials rejected");
        Application.Properties.setValue("QWeatherKey", "");
        QWeatherLocation.reload();
        auditAssert(!QWeatherLocation.configured && QWeatherLocation.name == null, "empty config restores Garmin fallback");
        var before = AuditQWeather.requests;
        service.onTemporalEvent();
        auditAssert(AuditQWeather.requests == before && AuditQWeather.deleted == 1, "disabled service stops");
        Application.Properties.setValue("QWeatherHost", "");
        Application.Properties.setValue("FieldLeft", 2);
        Application.Storage.deleteValue(QWeatherLocation.STORAGE_KEY);
        Application.Storage.deleteValue(QWeatherLocation.RETRY_KEY);
        System.println("QWEATHER_BOUNDARY_COMPLETE");
    }

    private function auditQWeatherWeather() {
        var host = "test.re.qweatherapi.com";
        var now = Time.now().value();
        AuditQWeather.prepareDaily();
        auditAssert(QWeatherWeather.utcSeconds("2026-10-14T00:00Z") == 1791936000, "UTC minute format");
        auditAssert(QWeatherWeather.utcSeconds("2026-10-14T00:00:00Z") == 1791936000, "UTC second format");
        auditAssert(QWeatherWeather.utcSeconds("2026-10-14T00:00+08:00") == null &&
            QWeatherWeather.utcSeconds("not-a-date") == null, "unsupported timestamps rejected");
        auditAssert(QWeatherWeather.utcSeconds("2026-02-30T00:00Z") == null &&
            QWeatherWeather.utcSeconds("2026-10-14T24:00Z") == null &&
            QWeatherWeather.utcSeconds("2026-13-14T00:00Z") == null, "invalid calendar dates and time rejected");
        var current = QWeatherWeather.current(200, AuditQWeather.currentData);
        auditAssert(current["temperature"] == 0 && current["uvIndex"] == 0 &&
            current["relativeHumidity"] == 72 && current["windSpeed"] == 3.0 &&
            current["conditionText"].equals("小雪"), "metric current weather and zero values");
        auditAssert(QWeatherWeather.current(401, AuditQWeather.currentData) == null &&
            QWeatherWeather.current(200, {"temperature" => {"value" => 32, "unit" => "°F"}}) == null &&
            QWeatherWeather.current(200, {}) == null, "invalid realtime data rejected");
        var forecast = QWeatherWeather.daily(200, AuditQWeather.dailyData, now);
        auditAssert(forecast["highTemperature"] == 5.5 && forecast["lowTemperature"] == -3.0 &&
            forecast["precipitationChance"] == 35 && forecast["nextSunrise"] > now, "forecast units and probability, not rainfall");
        auditAssert(QWeatherWeather.daily(200, AuditQWeather.dailyData, now + 86401) == null, "expired forecast rejected");

        Application.Properties.setValue("QWeatherHost", host);
        Application.Properties.setValue("QWeatherKey", "fixture-key");
        Application.Properties.setValue("WeatherSource", 1);
        AuditQWeather.changeCredentials = false;
        AuditQWeather.responseCode = 200;
        AuditQWeather.coordinates = [39.92, 116.41];
        AuditQWeather.urls = [];
        Application.Storage.deleteValue(QWeatherLocation.RETRY_KEY);
        Application.Storage.deleteValue(QWeatherWeather.RETRY_KEY);
        Application.Storage.deleteValue(QWeatherWeather.DAILY_RETRY_KEY);
        Application.Storage.deleteValue(QWeatherWeather.STORAGE_KEY);
        var service = new QWeatherLocationService();
        service.onTemporalEvent();
        auditAssert(AuditQWeather.urls.size() == 1, "one HTTP request per background invocation");
        service.onTemporalEvent();
        service.onTemporalEvent();
        auditAssert(AuditQWeather.urls.size() == 3 &&
            AuditQWeather.urls[0].equals("https://" + host + "/weather/v1/current/39.92/116.42") &&
            AuditQWeather.urls[2].equals("https://" + host + "/weather/v1/daily/39.92/116.42"), "weather selected without location field completes scheduled jobs");
        QWeatherWeather.reload();
        var conditions = QWeatherAdapter.conditions(now);
        auditAssert(conditions.temperature == 0 && conditions.highTemperature == 5.5 &&
            conditions.lowTemperature == -3.0 && conditions.precipitationChance == 35 &&
            conditions.windSpeed == 3.0 && conditions.feelsLikeTemperature == -2.5 &&
            conditions.relativeHumidity == 72 && conditions.conditionText.equals("小雪") &&
            conditions.qSunset != null, "foreground adapter feeds all weather fields");
        service.onTemporalEvent();
        auditAssert(AuditQWeather.urls.size() == 3, "fresh weather makes no requests");
        conditions = QWeatherAdapter.conditions(now + 86401);
        auditAssert(conditions.temperature == 0 && conditions.highTemperature == null &&
            conditions.precipitationChance == null, "expired forecast removed without erasing current cache");
        auditAssert(QWeatherWeather.readCache("other.qweatherapi.com") == null, "weather host isolation");
        Application.Properties.setValue("QWeatherRegion", 0);
        auditAssert(QWeatherWeather.readCache(host) == null, "weather cache invalidated on coordinate region change");
        Application.Properties.setValue("QWeatherRegion", 1);


        var cache = QWeatherWeather.readCache(host);
        cache["time"] = now - 1801;
        Application.Storage.setValue(QWeatherWeather.STORAGE_KEY, cache);
        AuditQWeather.useCachedCoordinates = true;
        var beforeFallback = AuditQWeather.requests;
        service.onTemporalEvent();
        auditAssert(AuditQWeather.requests == beforeFallback + 1 &&
            AuditQWeather.url.find("/weather/v1/current/") != null, "own cached coordinates keep refreshing without GPS or Garmin weather");
        AuditQWeather.useCachedCoordinates = false;
        cache = QWeatherWeather.readCache(host);
        cache["time"] = now - 1801;
        Application.Storage.setValue(QWeatherWeather.STORAGE_KEY, cache);
        AuditQWeather.currentResponseCode = 429;
        service.onTemporalEvent();
        var requests = AuditQWeather.requests;
        QWeatherWeather.reload();
        auditAssert(QWeatherWeather.snapshot["current"]["temperature"] == 0, "failed refresh retains current weather");
        service.onTemporalEvent();
        auditAssert(AuditQWeather.requests == requests, "weather failure cooldown");

        Application.Storage.deleteValue(QWeatherWeather.RETRY_KEY);
        AuditQWeather.currentResponseCode = 200;
        AuditQWeather.dailyResponseCode = 403;
        AuditQWeather.coordinates = [40, 116.41];
        service.onTemporalEvent();
        service.onTemporalEvent();
        service.onTemporalEvent();
        QWeatherWeather.reload();
        auditAssert(QWeatherWeather.snapshot.get("daily") == null &&
            QWeatherWeather.snapshot["current"]["temperature"] == 0, "new location never merges old forecast on daily failure");
        cache = QWeatherWeather.readCache(host);
        cache["time"] = now - 1801;
        Application.Storage.setValue(QWeatherWeather.STORAGE_KEY, cache);
        requests = AuditQWeather.requests;
        service.onTemporalEvent();
        auditAssert(AuditQWeather.requests == requests + 1 && AuditQWeather.url.find("/weather/v1/current/") != null,
            "daily failure never blocks current weather refresh");
        requests = AuditQWeather.requests;
        service.onTemporalEvent();
        auditAssert(AuditQWeather.requests == requests, "daily cooldown survives successful current refresh");
        Application.Storage.deleteValue(QWeatherWeather.RETRY_KEY);
        Application.Storage.deleteValue(QWeatherWeather.DAILY_RETRY_KEY);
        AuditQWeather.coordinates = [41, 116.41];
        AuditQWeather.currentResponseCode = 429;
        requests = AuditQWeather.requests;
        service.onTemporalEvent();
        service.onTemporalEvent();
        service.onTemporalEvent();
        auditAssert(AuditQWeather.requests == requests + 2 && AuditQWeather.url.find("/geo/v2/city/lookup") != null,
            "failed realtime at new location does not request unusable daily forecast");
        AuditQWeather.currentResponseCode = 200;
        Application.Properties.setValue("WeatherSource", 0);
        QWeatherWeather.reload();
        auditAssert(QWeatherWeather.snapshot == null, "Garmin selection never loads QWeather cache");
        Application.Properties.setValue("QWeatherHost", "");
        Application.Properties.setValue("QWeatherKey", "");
        Application.Storage.deleteValue(QWeatherWeather.STORAGE_KEY);
        Application.Storage.deleteValue(QWeatherWeather.RETRY_KEY);
        Application.Storage.deleteValue(QWeatherWeather.DAILY_RETRY_KEY);
        Application.Storage.deleteValue(QWeatherLocation.STORAGE_KEY);
        Application.Storage.deleteValue(QWeatherLocation.RETRY_KEY);
        System.println("QWEATHER_WEATHER_COMPLETE");
    }

    private function auditQWeatherNightBoundary() {
        var now = Time.now().value();
        var host = "test.re.qweatherapi.com";
        Application.Properties.setValue("QWeatherHost", host);
        Application.Properties.setValue("QWeatherKey", "fixture-key");
        Application.Properties.setValue("WeatherSource", 1);
        Application.Properties.setValue("QWeatherRegion", 1);
        AuditQWeather.coordinates = [39.92, 116.41];
        AuditQWeather.dailyResponseCode = 200;
        var original = {"host" => host, "region" => "mainland", "coordinates" => AuditQWeather.coordinates,
            "time" => now, "current" => QWeatherWeather.current(200, AuditQWeather.currentData)};
        Application.Storage.setValue(QWeatherWeather.STORAGE_KEY, original);
        Application.Storage.setValue(QWeatherLocation.STORAGE_KEY, {"host" => host, "region" => "mainland",
            "coordinates" => AuditQWeather.coordinates, "time" => now, "name" => "北京"});
        var originalData = AuditQWeather.dailyData;
        var data = {"days" => [
            {"forecastStartTime" => AuditQWeather.utcText(now - 86401), "forecastEndTime" => AuditQWeather.utcText(now - 1),
                "temperatureMax" => {"value" => 10, "unit" => "°C"}, "temperatureMin" => {"value" => 1, "unit" => "°C"},
                "nighttime" => {"forecastStartTime" => AuditQWeather.utcText(now - 3600), "forecastEndTime" => AuditQWeather.utcText(now + 3600),
                    "precipitation" => {"probability" => 0.8}}},
            {"forecastStartTime" => AuditQWeather.utcText(now - 1), "forecastEndTime" => AuditQWeather.utcText(now + 86400),
                "temperatureMax" => {"value" => 5, "unit" => "°C"}, "temperatureMin" => {"value" => -3, "unit" => "°C"},
                "daytime" => {"forecastStartTime" => AuditQWeather.utcText(now + 3600), "forecastEndTime" => AuditQWeather.utcText(now + 43200),
                    "precipitation" => {"probability" => 0.35}}}]};
        var parsed = QWeatherWeather.daily(200, data, now);
        auditAssert(parsed["highTemperature"] == 5 && parsed["precipitationChance"] == 80,
            "previous day night period selected by its own validity interval");
        var cache = QWeatherWeather.readCache(host);
        cache["daily"] = {"start" => now - 86401, "end" => now - 1, "highTemperature" => 10, "lowTemperature" => 1,
            "precipitationChance" => 80, "precipitationStart" => now - 3600, "precipitationEnd" => now + 3600};
        Application.Storage.setValue(QWeatherWeather.STORAGE_KEY, cache);
        QWeatherWeather.reload();
        var conditions = QWeatherAdapter.conditions(now);
        auditAssert(conditions.highTemperature == null && conditions.precipitationChance == 80,
            "night probability outlives expired daily high and low");
        conditions = QWeatherAdapter.conditions(now + 3601);
        auditAssert(conditions.precipitationChance == null, "night probability expires at its own end");
        AuditQWeather.dailyData = {"days" => [data["days"][1]]};
        new QWeatherLocationService().onTemporalEvent();
        QWeatherWeather.reload();
        conditions = QWeatherAdapter.conditions(now);
        auditAssert(conditions.highTemperature == 5 && conditions.precipitationChance == 80,
            "new daily response preserves still valid cached night probability");
        Application.Storage.setValue(QWeatherWeather.STORAGE_KEY, original);
        QWeatherWeather.reload();
        AuditQWeather.dailyData = originalData;
        var invalidCoordinates = [null, [], ["bad", 116.41], [91, 0]];
        for (var i = 0; i < invalidCoordinates.size(); i += 1) {
            original["coordinates"] = invalidCoordinates[i];
            Application.Storage.setValue(QWeatherWeather.STORAGE_KEY, original);
            QWeatherWeather.reload();
            auditAssert(QWeatherWeather.snapshot == null, "damaged cached coordinates must not reach the renderer");
        }
        original["coordinates"] = AuditQWeather.coordinates;
        Application.Storage.setValue(QWeatherWeather.STORAGE_KEY, original);
        QWeatherWeather.reload();
        Application.Properties.setValue("QWeatherHost", "");
        Application.Properties.setValue("QWeatherKey", "");
        Application.Properties.setValue("WeatherSource", 0);
        Application.Storage.deleteValue(QWeatherWeather.STORAGE_KEY);
        Application.Storage.deleteValue(QWeatherLocation.STORAGE_KEY);
        System.println("QWEATHER_NIGHT_BOUNDARY_COMPLETE");
    }

    private function auditQWeatherCoordinates() {
        var beijing = QWeatherCoordinates.requestCoordinates([39.92, 116.41], true);
        auditAssert(auditNear(beijing[0], 39.92140333568901d) &&
            auditNear(beijing[1], 116.41624327147515d), "Beijing matches upstream conversion");
        var shanghai = QWeatherCoordinates.requestCoordinates([31.2304, 121.4737], true);
        auditAssert(auditNear(shanghai[0], 31.228457704689244d) &&
            auditNear(shanghai[1], 121.47822313586518d), "Shanghai matches upstream conversion");
        var hk = QWeatherCoordinates.requestCoordinates([22.3, 114.17], false);
        var taiwan = QWeatherCoordinates.requestCoordinates([25.03, 121.56], false);
        var london = QWeatherCoordinates.requestCoordinates([51.5, -0.1], true);
        auditAssert(hk[0] == 22.3 && hk[1] == 114.17 && taiwan[0] == 25.03 && taiwan[1] == 121.56 &&
            london[0] == 51.5 && london[1] == -0.1, "other regions and out-of-bounds coordinates unchanged");
        auditAssert(QWeatherCoordinates.requestCoordinates([91, 0], true) == null, "invalid coordinates rejected");
        auditAssert(!AuditQWeather.options[:headers].hasKey("Accept-Encoding"), "let Garmin negotiate and decode response compression");
    }

    private function auditNear(value, expected) {
        var difference = value - expected;
        return difference > -0.000005d && difference < 0.000005d;
    }
