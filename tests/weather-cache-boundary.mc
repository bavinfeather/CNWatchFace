    private function auditWeatherCacheBoundary() {
        var observed = Time.now().value();
        var rejected = ["bad", [], {"observationTime" => "bad"},
            {"observationTime" => observed, "temperature" => "bad"}];
        for (var i = 0; i < rejected.size(); i += 1) {
            Application.Storage.setValue(WEATHER_STORAGE_KEY, rejected[i]);
            auditAssert(readWeatherCache() == null, "invalid cache shape/type rejected " + i);
        }
        var locations = [[null, null], ["bad", 0], [91.0, 0.0], [0.0, 181.0], [], "bad"];
        for (var i = 0; i < locations.size(); i += 1) {
            Application.Storage.setValue(WEATHER_STORAGE_KEY,
                {"observationTime" => observed, "temperature" => 22, "location" => locations[i]});
            var restored = readWeatherCache();
            auditAssert(restored != null && restored.temperature == 22 &&
                restored.observationLocationPosition == null, "invalid location ignored " + i);
        }
        Application.Storage.setValue(WEATHER_STORAGE_KEY,
            {"observationTime" => observed, "temperature" => 0, "uvIndex" => 0.0,
             "location" => [0.0, 0.0], "observationLocationName" => 123});
        var restored = readWeatherCache();
        auditAssert(restored != null && restored.temperature == 0 && restored.uvIndex == 0.0 &&
            restored.observationLocationPosition != null && restored.observationLocationName == null,
            "zero values and zero coordinates retained; invalid name ignored");
        Application.Storage.setValue(WEATHER_STORAGE_KEY,
            {"observationTime" => observed, "temperature" => 22, "location" => [null, null]});
        System.println("WEATHER_BOUNDARY_COMPLETE cases=11");
    }
