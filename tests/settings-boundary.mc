    private function auditSettingsBoundary(dc as Graphics.Dc) {
        var keys = ["FieldTopLeft", "FieldTopRight", "FieldLeft", "FieldCenter", "FieldRight"];
        var defaults = [FIELD_SUNRISE, FIELD_SUNSET, FIELD_STEPS, FIELD_BATTERY, FIELD_HEART];
        var removed = [27, 42, 44, 46, 47];
        for (var i = 0; i < keys.size(); i += 1) {
            for (var r = 0; r < removed.size(); r += 1) {
                Application.Properties.setValue(keys[i], removed[r]);
                auditAssert(fieldProperty(keys[i], defaults[i]) == defaults[i], "removed field falls back");
            }
        }
        Application.Properties.setValue("TopLabelFont", 99);
        var menu = new CNWatchFaceSettingsMenu();
        var descriptors = menu.DESCRIPTORS;
        for (var row = 0; row < descriptors.size(); row += 1) {
            var id = descriptors[row][0];
            auditAssert(menu.subLabel(id) instanceof Lang.String, "settings sublabel " + row);
            var options = menu.optionsFor(id);
            auditAssert(options != null && options.size() > 0, "settings options " + row);
            for (var o = 0; o < options.size(); o += 1) {
                auditAssert(menu.optionLabel(id, options[o]) instanceof Lang.String, "settings option resource " + row + ":" + o);
            }
            menu.refreshItem(id);
        }
        Application.Properties.setValue("FieldTopLeft", FIELD_HEART);
        Application.Properties.setValue("FieldTopRight", FIELD_STRESS);
        Application.Properties.setValue("FieldLeft", FIELD_HEART);
        Application.Properties.setValue("FieldCenter", FIELD_BATTERY);
        Application.Properties.setValue("FieldRight", FIELD_STRESS);
        Application.Properties.setValue("TopLabelFont", (auditFrames / 20).toNumber() % 5);
        Application.getApp().onSettingsChanged();
        onLayout(dc);
        System.println("SETTINGS_CHECK frame=" + auditFrames + " rows=" + descriptors.size());
    }

    private function auditHeartBoundary(dc as Graphics.Dc) {
        var savedHeart = _cachedHeartRate;
        var savedStress = _cachedStress;
        var savedHeartFlag = _heartRateCached;
        var savedStressFlag = _stressCached;
        var savedTick = _dataMinute;
        var values = [null, 0, 80, 80.5];
        var clock = System.getClockTime();
        var now = Time.now();
        var date = Gregorian.info(now, Time.FORMAT_SHORT);
        for (var i = 0; i < values.size(); i += 1) {
            _cachedHeartRate = values[i]; _cachedStress = values[i];
            _heartRateCached = true; _stressCached = true;
            _dataMinute = (now.value() / 60).toNumber();
            var expected = values[i] == null ? "--" : values[i].toNumber().format("%d");
            auditAssert(fieldValue(FIELD_HEART, 50, _cachedActivityInfo, clock, date, _cachedConditions, now).equals(expected), "heart null/zero/number");
            auditAssert(fieldValue(FIELD_STRESS, 50, _cachedActivityInfo, clock, date, _cachedConditions, now).equals(expected), "stress null/zero/number");
        }
        _cachedHeartRate = savedHeart; _cachedStress = savedStress;
        _heartRateCached = savedHeartFlag; _stressCached = savedStressFlag; _dataMinute = savedTick;
    }
