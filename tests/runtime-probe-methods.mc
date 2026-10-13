    private var auditFrames = 0;
    private var auditMinFree = 99999999;
    private var auditIconLoads = 0;
    private var auditTopLoads = 0;
    private var auditStableLoads = -1;
    private var auditNormalFrames = 0;
    private var auditAodFrames = 0;
    private var auditSleepFrames = 0;
    private var auditLunarCalculations = 0;

    private function auditAssert(ok, name) {
        if (!ok) { System.println("AUDIT_FAIL " + name); throw new Lang.InvalidValueException(name); }
    }

    private function auditWeather() {
        var full = new CNWatchFaceStoredWeather();
        full.observationTime = Time.now();
        full.temperature = 22;
        full.relativeHumidity = 60;
        full.highTemperature = 25;
        full.lowTemperature = 18;
        full.windSpeed = 2.0;
        full.observationLocationName = "Test";
        _cachedConditions = mergeWeather(full);
        var partial = new CNWatchFaceStoredWeather();
        partial.observationTime = Time.now();
        partial.precipitationChance = 0;
        partial.uvIndex = 0.0;
        partial.temperature = 0;
        auditAssert(hasUsableWeather(partial), "partial accepts zero");
        _cachedConditions = mergeWeather(partial);
        auditAssert(_cachedConditions.temperature == 0 && _cachedConditions.relativeHumidity == 60,
                    "missing fields retained and zero replaces");
        auditAssert(_cachedConditions.observationLocationName.equals("Test"), "location retained");
        storeWeatherCache(_cachedConditions);
        var restored = readWeatherCache();
        auditAssert(restored.temperature == 0 && restored.relativeHumidity == 60 && restored.uvIndex == 0.0,
                    "storage round trip");
        full.observationTime = Time.today().subtract(new Time.Duration(1));
        _cachedConditions = full;
        auditAssert(!hasUsableWeather(full), "yesterday rejected");
        partial.temperature = null;
        _cachedConditions = mergeWeather(partial);
        auditAssert(_cachedConditions.temperature == null && _cachedConditions.relativeHumidity == null,
                    "yesterday not merged");
        storeWeatherCache(_cachedConditions);
        restored = readWeatherCache();
        auditAssert(restored != null && restored.temperature == null && restored.precipitationChance == 0,
                    "temperature missing restart");
        var empty = new CNWatchFaceStoredWeather();
        empty.observationTime = Time.now();
        auditAssert(!hasUsableWeather(empty) && !hasUsableWeather(null), "empty and null rejected");
        partial.observationTime = null;
        auditAssert(!hasUsableWeather(partial), "missing observation time rejected");
        _cachedConditions = null;
        System.println("WEATHER_COMPLETE");
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        if (auditFrames >= 600) { auditDraw(dc); return; }
        if (auditFrames == 0) {
            auditWeather();
            Application.Properties.setValue("TopLabel", "测试 TEST");
            Application.Properties.setValue("ShowSecondsActive", 1);
        }
        for (var i = 0; i < 1; i += 1) {
            auditFrames += 1;
            if (auditFrames % 20 == 1) { onExitSleep(); }
            if (auditFrames % 20 == 11) { onEnterSleep(); }
            if (auditFrames <= 400 && auditFrames % 20 == 1) {
                var first = ((auditFrames / 20).toNumber() % 15) * 4;
                Application.Properties.setValue("FieldTopLeft", first + 1);
                Application.Properties.setValue("FieldTopRight", first + 2);
                Application.Properties.setValue("FieldLeft", first + 3);
                Application.Properties.setValue("FieldCenter", first + 4);
                onSettingsChanged();
            }
            if (auditFrames % 100 == 0) { _dataMinute = -1; }
            auditDraw(dc);
            auditAssert(_iconCache.size() <= 12, "bounded icon cache");
            auditAssert(auditLunarCalculations <= 2, "lunar cache reused for both languages");
            if (auditFrames == 500) { auditStableLoads = auditIconLoads + auditTopLoads; }
            if (auditFrames % 100 == 0) {
                var free = System.getSystemStats().freeMemory;
                if (free < auditMinFree) { auditMinFree = free; }
                System.println("MEMORY frame=" + auditFrames + " free=" + free + " min=" + auditMinFree +
                    " icons=" + _iconCache.size() + " loads=" + auditIconLoads + " top=" + auditTopLoads + " lunar=" + auditLunarCalculations);
            }
        }
        if (auditFrames < 600) { WatchUi.requestUpdate(); }
        else {
            auditAssert(auditStableLoads == auditIconLoads + auditTopLoads, "stable frames reuse resources");
            System.println("AUDIT_COMPLETE frames=" + auditFrames + " normal=" + auditNormalFrames +
                " aod=" + auditAodFrames + " mipSleep=" + auditSleepFrames + " minFree=" + auditMinFree);
        }
    }
