using Toybox.ActivityMonitor;
using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.UserProfile;
using Toybox.WatchUi;

class CNWatchFaceLegacyView extends WatchUi.WatchFace {
    private var _w = 240;
    private var _sleeping = false;
    private var _dataMinute = -1;
    private var _cachedInfo = null;
    private var _cachedStats = null;
    private var _cachedHeartRate = null;
    private var _cachedDeviceSettings = null;
    private var _trendCacheTick = -1;
    private var _cachedTrendValues as Lang.Array = [];
    private var _bmrCacheTick = -1;
    private var _cachedBmr = null;
    private var _fieldCacheDay = -1;
    private var _cachedFieldValues = {};

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        _w = dc.getWidth();
    }

    function onEnterSleep() {
        _sleeping = true;
    }

    function onExitSleep() {
        _sleeping = false;
    }

    function onSettingsChanged() {
        _dataMinute = -1;
        _trendCacheTick = -1;
        _bmrCacheTick = -1;
        WatchUi.requestUpdate();
    }

    private function px(value) {
        return ((value * _w) / 240.0).toNumber();
    }

    // The profile owns the clock slot; differences in actual device fonts are
    // handled by measuring them, not by adding a device-specific Y offset.
    private function legacyTimeTop() {
        return px(34);
    }

    private function property(key, fallback) {
        var value = Application.getApp().getProperty(key);
        return value == null ? fallback : value;
    }

    private function numberProperty(key, fallback) {
        var value = property(key, fallback);
        return value instanceof Number ? value : fallback;
    }

    private function fieldProperty(key, fallback) {
        var value = numberProperty(key, fallback);
        return value == 27 ? fallback : value;
    }

    private function mipColor(color) {
        // Segment34mkII soft AMOLED tones use their paired RGB222 colors.
        if (color == 0xF5E6D3) { return 0xFFFFAA; }
        if (color == 0xC7CBCB) { return 0xAAAAAA; }
        if (color == 0xFF6633 || color == 0xFF5500) { return 0xFF5500; }
        if (color == 0xFBCB77) { return 0xFFFF00; }
        if (color == 0x89EFD2) { return 0x00FFFF; }
        if (color == 0x96E0AC) { return 0x00FF00; }
        if (color == 0xFF9161) { return 0xFF5500; }
        if (color == 0x3DA855) { return 0x55AA55; }
        if (color == 0xFFCC33) { return 0xFFAA00; }
        var r = (color >> 16) & 0xFF;
        var g = (color >> 8) & 0xFF;
        var b = color & 0xFF;
        r = r < 0x2B ? 0x00 : (r < 0x80 ? 0x55 : (r < 0xD5 ? 0xAA : 0xFF));
        g = g < 0x2B ? 0x00 : (g < 0x80 ? 0x55 : (g < 0xD5 ? 0xAA : 0xFF));
        b = b < 0x2B ? 0x00 : (b < 0x80 ? 0x55 : (b < 0xD5 ? 0xAA : 0xFF));
        return (r << 16) | (g << 8) | b;
    }

    private function stringProperty(key, fallback) {
        var value = property(key, fallback);
        return value instanceof String ? value : fallback;
    }

    private function text(resource) {
        return WatchUi.loadResource(resource).toString();
    }

    private function weekday(day) {
        if (day == 1) { return text(Rez.Strings.DAY_OF_WEEK_SUN); }
        if (day == 2) { return text(Rez.Strings.DAY_OF_WEEK_MON); }
        if (day == 3) { return text(Rez.Strings.DAY_OF_WEEK_TUE); }
        if (day == 4) { return text(Rez.Strings.DAY_OF_WEEK_WED); }
        if (day == 5) { return text(Rez.Strings.DAY_OF_WEEK_THU); }
        if (day == 6) { return text(Rez.Strings.DAY_OF_WEEK_FRI); }
        return text(Rez.Strings.DAY_OF_WEEK_SAT);
    }

    private function heartRate() {
        if (!(ActivityMonitor has :getHeartRateHistory)) { return null; }
        try {
            var iterator = ActivityMonitor.getHeartRateHistory(1, true);
            var sample = iterator.next();
            if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                return sample.heartRate;
            }
        } catch (e) {
        }
        return null;
    }

    private function compactMetric(value) {
        if (value >= 100000) { return (value / 1000.0).format("%.0f") + "k"; }
        return value.format("%d");
    }

    private function retainFieldValue(field, value) {
        if (value != null) {
            _cachedFieldValues.put(field, value);
            return value;
        }
        return _cachedFieldValues.hasKey(field) ? _cachedFieldValues.get(field) : "--";
    }

    private function fieldValue(field, info, battery, hr) {
        if (info == null && field != 5 && field != 7) { return retainFieldValue(field, null); }
        if (field == 1) {
            return retainFieldValue(field, !(info has :steps) || info.steps == null ? null : compactMetric(info.steps));
        }
        if (field == 2) {
            return retainFieldValue(field, !(info has :floorsClimbed) || info.floorsClimbed == null ? null : compactMetric(info.floorsClimbed));
        }
        if (field == 3) {
            var active = activeCalories(info);
            return retainFieldValue(field, active == null ? null : compactMetric(active));
        }
        if (field == 23) {
            return retainFieldValue(field, !(info has :calories) || info.calories == null ? null : compactMetric(info.calories));
        }
        if (field == 24) {
            var active = activeCalories(info);
            if (active == null || !(info has :calories) || info.calories == null) { return retainFieldValue(field, null); }
            var resting = info.calories - active;
            return retainFieldValue(field, compactMetric(resting < 0 ? 0 : resting));
        }
        if (field == 25) {
            return retainFieldValue(field, !(info has :floorsDescended) || info.floorsDescended == null ? null : compactMetric(info.floorsDescended));
        }
        if (field == 26) {
            return retainFieldValue(field, !(info has :activeMinutesWeek) || info.activeMinutesWeek == null ? null : compactMetric(info.activeMinutesWeek.total));
        }
        if (field == 28) {
            if (!(info has :activeMinutesWeek) || !(info has :activeMinutesWeekGoal) || info.activeMinutesWeek == null || info.activeMinutesWeekGoal == null || info.activeMinutesWeekGoal == 0) { return retainFieldValue(field, null); }
            return retainFieldValue(field, ((info.activeMinutesWeek.total * 100) / info.activeMinutesWeekGoal).format("%d") + "%");
        }
        if (field == 4) {
            return retainFieldValue(field, !(info has :distance) || info.distance == null ? null : (info.distance / 100000.0).format("%.1f"));
        }
        if (field == 5) { return battery.format("%d") + "%"; }
        if (field == 7) { return retainFieldValue(field, hr == null ? null : hr.format("%d")); }
        return "--";
    }

    private function estimateBmr() {
        var cacheTick = (Time.now().value() / 21600).toNumber();
        if (cacheTick == _bmrCacheTick) { return _cachedBmr; }
        _bmrCacheTick = cacheTick;
        try {
            var profile = UserProfile.getProfile();
            if (profile != null && (profile has :weight) && (profile has :height) && (profile has :birthYear) && profile.weight != null && profile.height != null && profile.birthYear != null && profile.weight > 0 && profile.height > 0) {
                var kg = profile.weight / 1000.0;
                var year = Gregorian.info(Time.now(), Time.FORMAT_SHORT).year;
                var age = year - profile.birthYear;
                if (age >= 10 && age <= 100) {
                    var bmr = 5.2 - 6.116 * age + 7.628 * profile.height + 12.2 * kg;
                    if ((profile has :gender) && profile.gender == UserProfile.GENDER_FEMALE) { bmr -= 202.8; }
                    _cachedBmr = bmr;
                }
            }
        } catch (e) {
        }
        return _cachedBmr;
    }

    private function activeCalories(info) {
        if (info == null || !(info has :calories) || info.calories == null) { return null; }
        var bmr = estimateBmr();
        if (bmr == null || bmr <= 0) { return null; }
        var date = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var minutesElapsed = date.hour * 60 + date.min;
        var resting = (bmr * minutesElapsed / 1440.0 + 0.5).toNumber();
        var active = info.calories - resting;
        return active < 0 ? 0 : active.toNumber();
    }

    private function drawMountains(dc, sky, far, mid, near) {
        var endY = px(119);
        dc.setColor(sky, Graphics.COLOR_TRANSPARENT);
        // Legacy targets use round displays.  Keep the landscape panel
        // visibly rounded instead of leaving a rectangular sky block.
        dc.fillRoundedRectangle(px(19), px(36), px(202), px(84), px(14));

        dc.setColor(far, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[px(19),endY],[px(19),px(95)],[px(35),px(88)],[px(51),px(77)],[px(66),px(73)],[px(80),px(62)],[px(88),px(65)],[px(97),px(76)],[px(116),px(84)],[px(133),px(76)],[px(144),px(72)],[px(157),px(79)],[px(175),px(87)],[px(193),px(81)],[px(209),px(83)],[px(221),px(90)],[px(221),endY]]);
        dc.setColor(mid, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[px(19),endY],[px(19),px(104)],[px(39),px(94)],[px(55),px(90)],[px(74),px(95)],[px(94),px(91)],[px(112),px(86)],[px(130),px(84)],[px(140),px(82)],[px(156),px(87)],[px(173),px(95)],[px(195),px(92)],[px(221),px(99)],[px(221),endY]]);
        dc.setColor(near, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[px(19),endY],[px(19),px(112)],[px(43),px(106)],[px(65),px(102)],[px(82),px(105)],[px(106),px(111)],[px(130),px(108)],[px(154),px(101)],[px(168),px(103)],[px(189),px(110)],[px(207),px(107)],[px(221),px(105)],[px(221),endY]]);
        // Continue the near-mountain color through the lower MIP background.
        dc.fillRectangle(0, endY, dc.getWidth(), dc.getHeight() - endY);
    }

    private function drawHeart(dc, cx, cy, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - px(3), cy - px(1), px(3));
        dc.fillCircle(cx + px(3), cy - px(1), px(3));
        dc.fillPolygon([[cx-px(6),cy],[cx+px(6),cy],[cx,cy+px(7)]]);
    }

    private function drawBattery(dc, cx, cy, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRectangle(cx-px(7), cy-px(4), px(13), px(8));
        dc.fillRectangle(cx+px(6), cy-px(2), px(2), px(4));
    }

    private function drawFieldIcon(dc, field, cx, cy, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        if (field == 1) {
            // Steps / shoe
            dc.drawLine(cx-px(6), cy-px(3), cx-px(1), cy+px(3));
            dc.drawLine(cx-px(1), cy+px(3), cx+px(6), cy+px(3));
            dc.drawLine(cx-px(6), cy-px(3), cx-px(6), cy+px(1));
            return;
        }
        if (field == 2 || field == 25) {
            // Floors / stairs
            dc.drawLine(cx-px(6), cy+px(5), cx-px(2), cy+px(5));
            dc.drawLine(cx-px(2), cy+px(5), cx-px(2), cy+px(1));
            dc.drawLine(cx-px(2), cy+px(1), cx+px(2), cy+px(1));
            dc.drawLine(cx+px(2), cy+px(1), cx+px(2), cy-px(3));
            dc.drawLine(cx+px(2), cy-px(3), cx+px(6), cy-px(3));
            return;
        }
        if (field == 3 || field == 23 || field == 24) {
            // Active calories / flame
            dc.fillPolygon([[cx,cy-px(6)],[cx+px(5),cy],[cx+px(2),cy+px(6)],[cx-px(3),cy+px(6)],[cx-px(5),cy+px(1)]]);
            return;
        }
        if (field == 5) { drawBattery(dc, cx, cy, color); return; }
        if (field == 7) { drawHeart(dc, cx, cy, color); return; }
        // Distance / generic location marker
        dc.drawCircle(cx, cy-px(2), px(4));
        dc.drawLine(cx-px(3), cy+px(1), cx, cy+px(6));
        dc.drawLine(cx+px(3), cy+px(1), cx, cy+px(6));
    }

    private function drawCompactField(dc, cx, field, info, battery, hr, labelColor, valueColor, fieldTop) {
        drawFieldIcon(dc, field, cx-px(20), fieldTop + px(8), labelColor);
        dc.setColor(valueColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx-px(11), fieldTop, Graphics.FONT_SMALL, fieldValue(field, info, battery, hr), Graphics.TEXT_JUSTIFY_LEFT);
    }

    private function drawTrend(dc, color, baseY) {
        var trendTick = (Time.now().value() / 300).toNumber();
        if (trendTick != _trendCacheTick) {
            var freshValues = [];
            if (ActivityMonitor has :getHeartRateHistory) {
                try {
                    var iterator = ActivityMonitor.getHeartRateHistory(12, true);
                    var sample = iterator.next();
                    while (sample != null) {
                        if (sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) { freshValues.add(sample.heartRate); }
                        sample = iterator.next();
                    }
                } catch (e) {
                }
            }
            if (freshValues.size() > 0) { _cachedTrendValues = freshValues; }
            _trendCacheTick = trendTick;
        }
        var values = _cachedTrendValues;

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(px(29), baseY, px(211), baseY);
        if (values.size() == 0) { return; }
        var barW = px(7);
        var gap = px(2);
        var x = px(31);
        for (var i = values.size() - 1; i >= 0; i -= 1) {
            var height = px(4) + ((values[i] % 17) * px(1));
            dc.fillRectangle(x, baseY - height, barW, height);
            x += barW + gap;
            if (x > px(205)) { break; }
        }
    }

    function onUpdate(dc) {
        var clock = System.getClockTime();
        var now = Time.now();
        var date = Gregorian.info(now, Time.FORMAT_SHORT);
        var fieldDay = (date.year * 13 + date.month) * 32 + date.day;
        if (_fieldCacheDay != fieldDay) {
            _fieldCacheDay = fieldDay;
            _cachedInfo = null;
            _cachedFieldValues = {};
        }
        var minuteTick = (now.value() / 60).toNumber();
        var showSeconds = numberProperty("ShowSecondsActive", 0) == 1 && !_sleeping;
        if (minuteTick != _dataMinute) {
            _dataMinute = minuteTick;
            try {
                var latestInfo = ActivityMonitor.getInfo();
                if (latestInfo != null) { _cachedInfo = latestInfo; }
            } catch (e) {
            }
            try {
                var latestStats = System.getSystemStats();
                if (latestStats != null) { _cachedStats = latestStats; }
            } catch (e) {
            }
            var latestHeartRate = heartRate();
            if (latestHeartRate != null) { _cachedHeartRate = latestHeartRate; }
            try {
                var latestDeviceSettings = System.getDeviceSettings();
                if (latestDeviceSettings != null) { _cachedDeviceSettings = latestDeviceSettings; }
            } catch (e) {
            }
        }

        var background = Graphics.COLOR_BLACK;
        var timeColor = mipColor(numberProperty("TimeColor", Graphics.COLOR_WHITE));
        var dateColor = mipColor(numberProperty("DateColor", Graphics.COLOR_WHITE));
        var secondsColor = mipColor(numberProperty("SecondsColor", Graphics.COLOR_RED));
        var amPmColor = mipColor(numberProperty("AmPmColor", Graphics.COLOR_RED));
        var fieldTextColor = mipColor(numberProperty("FieldTextColor", Graphics.COLOR_RED));
        var fieldValueColor = mipColor(numberProperty("FieldValueColor", Graphics.COLOR_WHITE));
        var sky = mipColor(numberProperty("SkyColor", Graphics.COLOR_DK_BLUE));
        var far = mipColor(numberProperty("MountainFarColor", Graphics.COLOR_LT_GRAY));
        var mid = mipColor(numberProperty("MountainMidColor", Graphics.COLOR_DK_GRAY));
        var near = mipColor(numberProperty("MountainNearColor", Graphics.COLOR_BLACK));

        dc.setColor(background, background);
        dc.clear();

        var settings = _cachedDeviceSettings;
        var is24Hour = settings == null ? true : settings.is24Hour;
        var hour = clock.hour;
        if (!is24Hour) {
            hour = hour % 12;
            if (hour == 0) { hour = 12; }
        }

        dc.setColor(dateColor, Graphics.COLOR_TRANSPARENT);
        var topLabelText = stringProperty("TopLabel", "");
        if (numberProperty("TopLabelBold", 0) == 1) {
            dc.drawText(_w/2 - 1, px(12), Graphics.FONT_SMALL, topLabelText, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(_w/2 + 1, px(12), Graphics.FONT_SMALL, topLabelText, Graphics.TEXT_JUSTIFY_CENTER);
        }
        dc.drawText(_w/2, px(12), Graphics.FONT_SMALL, topLabelText, Graphics.TEXT_JUSTIFY_CENTER);
        drawMountains(dc, sky, far, mid, near);

        // One measured clock component: a fixed worst-case time slot plus an
        // optional two-line side slot. Only the F5/Chronos font profile uses
        // FONT_HOT; other 240 devices have different system font metrics.
        var isFenix5Layout = numberProperty("LegacyFenix5Layout", 0) == 1;
        var timeFont = isFenix5Layout ? Graphics.FONT_NUMBER_HOT : Graphics.FONT_NUMBER_MEDIUM;
        var sideFont = Graphics.FONT_XTINY;
        var timeText = hour.format("%02d") + ":" + clock.min.format("%02d");
        var reserveSeconds = numberProperty("ShowSecondsActive", 0) == 1;
        var reserveAmPm = !is24Hour && numberProperty("ShowAmPm", 1) == 1;
        var reserveSide = reserveSeconds || reserveAmPm;
        var worstTimeText = is24Hour ? "23:59" : "12:59";
        var timeSlotWidth = dc.getTextWidthInPixels(worstTimeText, timeFont);
        var sideWidth = dc.getTextWidthInPixels("59", sideFont);
        var pmWidth = dc.getTextWidthInPixels("PM", sideFont);
        if (pmWidth > sideWidth) { sideWidth = pmWidth; }
        var sideGap = px(3);
        var componentWidth = timeSlotWidth;
        if (reserveSide) { componentWidth += sideGap + sideWidth; }
        var componentLeft = (_w - componentWidth) / 2;
        var timeCenterX = componentLeft + timeSlotWidth / 2;
        var timeTop = isFenix5Layout ? px(38) : legacyTimeTop();
        dc.setColor(timeColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(timeCenterX, timeTop, timeFont, timeText, Graphics.TEXT_JUSTIFY_CENTER);

        var timeFontH = dc.getFontHeight(timeFont);
        var sideFontH = dc.getFontHeight(sideFont);
        var sideLineGap = px(2);
        var sideLineCount = (reserveSeconds ? 1 : 0) + (reserveAmPm ? 1 : 0);
        var sideBlockH = sideLineCount > 1 ? sideFontH * 2 + sideLineGap : sideFontH;
        var timeCenter = timeTop + timeFontH / 2;
        var firstSideTop = timeCenter - sideBlockH / 2;
        var secondSideTop = firstSideTop + sideFontH + sideLineGap;
        var sideCenterX = componentLeft + timeSlotWidth + sideGap + sideWidth / 2;
        if (showSeconds) {
            dc.setColor(secondsColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(sideCenterX, firstSideTop, sideFont, clock.sec.format("%02d"), Graphics.TEXT_JUSTIFY_CENTER);
        }
        if (reserveAmPm) {
            dc.setColor(amPmColor, Graphics.COLOR_TRANSPARENT);
            dc.drawText(sideCenterX, reserveSeconds ? secondSideTop : firstSideTop, sideFont, clock.hour < 12 ? "AM" : "PM", Graphics.TEXT_JUSTIFY_CENTER);
        }

        dc.setColor(dateColor, Graphics.COLOR_TRANSPARENT);
        var dateText = date.month.format("%d") + "/" + date.day.format("%d") + "  " + weekday(date.day_of_week);
        var dateFont = isFenix5Layout ? Graphics.FONT_SMALL : Graphics.FONT_XTINY;
        var dateFontH = dc.getFontHeight(dateFont);
        var clockComponentH = timeFontH > sideBlockH ? timeFontH : sideBlockH;
        var dateTop = timeTop + clockComponentH + px(2);
        if (isFenix5Layout && dateTop + dateFontH > px(119)) {
            dateTop = px(119) - dateFontH;
        }
        dc.drawText(_w/2, dateTop, dateFont, dateText, Graphics.TEXT_JUSTIFY_CENTER);

        var info = _cachedInfo;
        var stats = _cachedStats;
        var battery = stats == null ? 0 : stats.battery.toNumber();
        var hr = _cachedHeartRate;
        var statusTop = dateTop + dateFontH + px(1);
        if (isFenix5Layout && statusTop < px(123)) { statusTop = px(123); }
        var statusFontH = dc.getFontHeight(Graphics.FONT_SMALL);
        var statusCenterY = statusTop + statusFontH / 2;
        drawHeart(dc, px(42), statusCenterY, fieldTextColor);
        dc.setColor(fieldValueColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(px(54), statusTop, Graphics.FONT_SMALL, hr == null ? "--" : hr.format("%d"), Graphics.TEXT_JUSTIFY_LEFT);
        drawBattery(dc, px(164), statusCenterY, fieldTextColor);
        dc.drawText(px(177), statusTop, Graphics.FONT_SMALL, battery.format("%d") + "%", Graphics.TEXT_JUSTIFY_LEFT);

        var trendBaseY = px(174);
        var minimumTrendY = statusTop + statusFontH + px(2);
        if (trendBaseY < minimumTrendY) { trendBaseY = minimumTrendY; }
        drawTrend(dc, fieldTextColor, trendBaseY);

        var fieldTop = trendBaseY + px(7);
        drawCompactField(dc, px(52), fieldProperty("FieldLeft", 2), info, battery, hr, fieldTextColor, fieldValueColor, fieldTop);
        drawCompactField(dc, px(120), fieldProperty("FieldCenter", 1), info, battery, hr, fieldTextColor, fieldValueColor, fieldTop);
        drawCompactField(dc, px(188), fieldProperty("FieldRight", 3), info, battery, hr, fieldTextColor, fieldValueColor, fieldTop);
    }
}
