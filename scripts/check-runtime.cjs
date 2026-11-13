// Isolated simulator probe. Does not modify production sources or sibling projects.
const fs = require('node:fs');
const path = require('node:path');
const cp = require('node:child_process');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const uncached = process.env.CNWATCH_UNCACHED === '1';
const styleAudit = process.env.CNWATCH_STYLE_AUDIT === '1';
const fontAudit = process.env.CNWATCH_FONT_AUDIT === '1';
const wakeAudit = process.env.CNWATCH_WAKE_AUDIT === '1';
const startupAudit = process.env.CNWATCH_STARTUP_AUDIT === '1';
const finalFontAudit = process.env.CNWATCH_FINAL_FONT_AUDIT === '1';
const boundaryCase = process.env.CNWATCH_BOUNDARY_CASE;
const compatibilityBaseline = boundaryCase === 'compatibility' && process.env.CNWATCH_COMPATIBILITY_BASELINE === '1';
if (boundaryCase && !['calendar', 'weather', 'qweather', 'qweather-display', 'chart', 'chart-width', 'integration', 'smoke', 'activity', 'settings', 'compatibility'].includes(boundaryCase)) throw new Error('Unknown boundary case');
const out = path.join(root, 'work', compatibilityBaseline ? 'boundary-compatibility-before-release-20261013' : boundaryCase ? `boundary-${boundaryCase}-20261013` : finalFontAudit ? 'final-font-runtime-audit-20261012' : startupAudit ? (fs.existsSync(path.join(root, 'source/TopMoon.mc')) ? 'startup-runtime-audit-20261012' : 'startup-no-moon-audit-20261012') : wakeAudit ? 'wake-runtime-audit-20261007' : fontAudit ? 'font-runtime-audit-20261001' : styleAudit ? 'style-runtime-audit-20261001' : uncached ? 'runtime-audit-baseline-20261001' : Number(process.env.CNWATCH_AUDIT_FRAMES || 600)>600 ? 'runtime-stress-20261001' : 'runtime-audit-20261001');
const sdk = path.join(process.env.APPDATA, 'Garmin/ConnectIQ/Sdks/connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2/bin');
const java = 'C:/Program Files/Java/jdk-26.0.2.1/bin/java.exe';
const devices = process.argv.slice(2);
const frameCount=Number(process.env.CNWATCH_AUDIT_FRAMES || 600);
if (!Number.isInteger(frameCount) || frameCount<600 || frameCount%20!==0) throw new Error('Frame count must be a multiple of 20, at least 600.');
if (!devices.length) throw new Error('Supply device IDs to check.');
if (devices.some(d=>!/^\w+$/.test(d))) throw new Error('Invalid device ID.');
const deviceRoutes = fs.readFileSync(path.join(root, 'monkey.jungle'), 'utf8');
if (devices.some(d => new RegExp(`^${d}\\.sourcePath = source-legacy`, 'm').test(deviceRoutes))) {
  throw new Error('This runtime probe instruments the modern renderer only; use a separate legacy probe.');
}
fs.mkdirSync(path.join(out, 'source'), {recursive:true});
for (const name of fs.readdirSync(path.join(root, 'source'))) {
  if (name.endsWith('.mc')) fs.copyFileSync(path.join(root,'source',name), path.join(out,'source',name));
}
let view = fs.readFileSync(path.join(out,'source/CNWatchFaceView.mc'),'utf8');
view = view.replace('class CNWatchFaceView extends WatchUi.WatchFace {',
  'class CNWatchFaceView extends WatchUi.WatchFace {\n' + fs.readFileSync(path.join(root,'tests/runtime-probe-methods.mc'),'utf8').replaceAll('600',String(frameCount)));
view = view.replace('function onUpdate(dc as Graphics.Dc) as Void {\n        var', 'function auditDraw(dc as Graphics.Dc) as Void {\n        var');
// Match CRLF sources too, without changing the injected onUpdate.
view = view.replace(/function onUpdate\(dc as Graphics\.Dc\) as Void \{\r?\n(?!        if \(auditFrames)/,
  'function auditDraw(dc as Graphics.Dc) as Void {\n');
view = view.replace('_iconCache[resourceId] = WatchUi.loadResource(resourceId);',
  'auditIconLoads += 1; _iconCache[resourceId] = WatchUi.loadResource(resourceId);');
view = view.replace('_topLabelFont = Graphics.getVectorFont(', 'auditTopLoads += 1; _topLabelFont = Graphics.getVectorFont(');
view = view.replace('if (_lowPower && isAmoledLayout()) {', 'if (_lowPower && isAmoledLayout()) { auditAodFrames += 1;');
view = view.replace('if (amoledLowPower && isAmoledLayout()) {', 'if (amoledLowPower && isAmoledLayout()) { auditAodFrames += 1;');
view = view.replace('var showSeconds =', 'auditNormalFrames += 1; if (_lowPower) { auditSleepFrames += 1; }\n        var showSeconds =');
view = view.replace('private function calculateLunarDate(date, chinese as Lang.Boolean) as Lang.String {',
  'private function calculateLunarDate(date, chinese as Lang.Boolean) as Lang.String { auditLunarCalculations += 1;');
if (boundaryCase === 'calendar') {
  // Exercise fresh date calculations through the real field drawing stack,
  // including the 2025 leap month and the 2025/2026 year boundary.
  view = view.replace(/(var clock = System\.getClockTime\(\);\r?\n\s*)var now = Time\.now\(\);/,
    '$1var now = new Time.Moment(1735689600 + (auditFrames - 1) * 86400 + 43200);');
  view = view.replace('System.println("AUDIT_COMPLETE frames="',
    'auditAssert(auditLunarCalculations >= 300, "calendar date actually advanced");\n            System.println("AUDIT_COMPLETE frames="');
  view = view.replace('auditAssert(auditLunarCalculations <= 2, "lunar cache reused for both languages");', '');
  view = view.replace('if (auditFrames <= 400 && auditFrames % 20 == 1)', 'if (false)');
  view = view.replace('auditDraw(dc);\n            auditAssert',
    'Application.Properties.setValue("FieldTopLeft", 22);\n' +
    '            Application.Properties.setValue("FieldTopRight", 43);\n' +
    '            auditDraw(dc);\n            auditAssert');
}
if (boundaryCase === 'weather') {
  // Simulate invalid persisted coordinates at cold startup.
  // This is fault injection, not evidence that a real user's cache is corrupt.
  view = view.replace('class CNWatchFaceView extends WatchUi.WatchFace {',
    'class CNWatchFaceView extends WatchUi.WatchFace {\n' + fs.readFileSync(path.join(root,'tests/weather-cache-boundary.mc'),'utf8'));
  view = view.replace('auditWeather();',
    'auditWeatherCacheBoundary();\n' +
    '            _weatherStorageLoaded = false; _weatherNextAttemptSeconds = Time.now().value() + 3600;\n' +
    '            Application.Properties.setValue("WeatherLeft", 1);\n' +
    '            System.println("WEATHER_INVALID_LOCATION_STARTUP");');
  view = view.replace('auditDraw(dc);\n            auditAssert',
    'auditDraw(dc);\n            if (auditFrames == 1) { auditAssert(_cachedConditions != null && _cachedConditions.temperature == 22 && _cachedConditions.observationLocationPosition == null, "cold startup preserves valid weather"); }\n            auditAssert');
}
if (boundaryCase === 'chart') {
  // Weather cache fault injection has its own runner. Keeping its large
  // fixtures in the chart PRG changes the app's available memory materially.
  view = view.replace(/    private function auditWeather\(\) \{[\s\S]*?(?=    function onUpdate\()/, '');
  view += '\n' + fs.readFileSync(path.join(root,'tests/chart-localization.mc'),'utf8');
  view = view.replace('auditWeather();', 'ChartLocalizationAudit.run(); auditChartMapping(dc);');
  view = view.replace('class CNWatchFaceView extends WatchUi.WatchFace {', 'class CNWatchFaceView extends WatchUi.WatchFace {\n' + fs.readFileSync(path.join(root,'tests/chart-switching.mc'),'utf8'));
  view += '\nmodule AuditChart { var custom = 0; var charts = 0; var rows = 0; var enabled = false; var oldCustom = 0; var oldCharts = 0; var oldRows = 0; var fields = null; var index = 0; var rendered = []; var labels = [null, null]; var selected = [0, 0]; var seen = 0; var chartIcons = 0; }\n';
  view = view.replace('drawCompactField(dc, fieldProperty("ChartDataField",', 'AuditChart.rows += 1; drawCompactField(dc, fieldProperty("ChartDataField",');
  view = view.replace('drawCompactField(dc, fieldProperty("ChartDataFieldBottom",', 'AuditChart.rows += 1; drawCompactField(dc, fieldProperty("ChartDataFieldBottom",');
  view = view.replace('var resourceId = fieldIconResource(field);', 'if (px >= x(0.36) && py >= y(0.58) && py <= y(0.73)) { AuditChart.chartIcons += 1; } var resourceId = fieldIconResource(field);');
  const chartModulePath = path.join(out, 'source/CNChartData.mc');
  let chartModule = fs.readFileSync(chartModulePath, 'utf8').replace('var name = label(field);', 'if (!AuditChart.rendered[AuditChart.selected[row]]) { AuditChart.seen += 1; AuditChart.rendered[AuditChart.selected[row]] = true; } var name = label(field); if (!name.equals(WatchUi.loadResource(AuditChart.labels[row]))) { throw new Lang.InvalidValueException("chart field label mismatch"); }');
  fs.writeFileSync(chartModulePath, chartModule);
  view = view.replace('if (chartCustom && chartH > 0) {', 'if (chartCustom && chartH > 0) { AuditChart.custom += 1;');
  view = view.replace('drawTrend(dc, trendStyle, values,', 'AuditChart.charts += 1; drawTrend(dc, trendStyle, values,');
  view = view.replace('auditDraw(dc);\n            auditAssert', `
            AuditChart.enabled = (auditFrames / 20).toNumber() % 2 == 0;
            Application.Properties.setValue("ChartCustomData", AuditChart.enabled ? 1 : 0);
            if (!_lowPower && AuditChart.enabled && auditFrames <= 400) {
                AuditChart.selected[0] = AuditChart.index;
                AuditChart.selected[1] = (AuditChart.index + 1) % AuditChart.fields.size();
                AuditChart.labels[0] = AuditChart.fields[AuditChart.selected[0]][0];
                AuditChart.labels[1] = AuditChart.fields[AuditChart.selected[1]][0];
                Application.Properties.setValue("ChartDataField", AuditChart.fields[AuditChart.index][1]);
                Application.Properties.setValue("ChartDataFieldBottom", AuditChart.fields[(AuditChart.index + 1) % AuditChart.fields.size()][1]);
                AuditChart.index = (AuditChart.index + 1) % AuditChart.fields.size();
                _dataMinute = -1;
            }
            AuditChart.oldCustom = AuditChart.custom;
            AuditChart.chartIcons = 0;
            AuditChart.oldCharts = AuditChart.charts;
            AuditChart.oldRows = AuditChart.rows;
            auditDraw(dc);
            if (!_lowPower) {
                auditAssert(AuditChart.custom == AuditChart.oldCustom + (AuditChart.enabled ? 1 : 0), "custom field replaces chart only when enabled");
                auditAssert(AuditChart.rows == AuditChart.oldRows + (AuditChart.enabled ? 2 : 0), "both independent data rows are rendered");
                auditAssert(AuditChart.chartIcons == 0, "text-only chart area contains no field icons");
                auditAssert(AuditChart.charts == AuditChart.oldCharts + (AuditChart.enabled ? 0 : 1), "original chart restored when switch is off");
            } else {
                auditAssert(AuditChart.custom == AuditChart.oldCustom && AuditChart.charts == AuditChart.oldCharts, "AOD remains unchanged");
            }
            if (auditFrames == 600) {
                auditAssert(AuditChart.seen == AuditChart.fields.size() - 1, "all selectable non-hidden chart fields rendered");
                System.println("CHART_SWITCH_COMPLETE rendered=" + AuditChart.seen);
            }
            auditAssert`);
}
if (boundaryCase === 'qweather-display') {
  view = view.replace('auditWeather();', `auditWeather();
            Application.Properties.setValue("QWeatherHost", "test.re.qweatherapi.com");
            Application.Properties.setValue("QWeatherKey", "fixture-key");
            Application.Storage.setValue(QWeatherLocation.STORAGE_KEY, {
                "host" => "test.re.qweatherapi.com", "region" => "mainland", "name" => "北京",
                "coordinates" => [39.92, 116.41], "time" => Time.now().value() - 86400
            });
            QWeatherLocation.reload();
            Application.Properties.setValue("WeatherSource", 1);
            Application.Storage.setValue(QWeatherWeather.STORAGE_KEY, {
                "host" => "test.re.qweatherapi.com", "region" => "mainland", "coordinates" => [39.92, 116.41], "time" => Time.now().value(),
                "current" => {"temperature" => 0, "feelsLikeTemperature" => -2.5, "relativeHumidity" => 72,
                    "windSpeed" => 3.0, "conditionText" => "小雪", "uvIndex" => 0},
                "daily" => {"start" => Time.now().value() - 3600, "end" => Time.now().value() + 86400,
                    "highTemperature" => 5.5, "lowTemperature" => -3.0, "precipitationChance" => 35,
                    "precipitationEnd" => Time.now().value() + 43200,
                    "sunrise" => Time.now().value() - 1800, "sunset" => Time.now().value() + 7200}
            });
            QWeatherWeather.reload();
            _cachedLocationName = "--";
            auditAssert(extendedFieldValue(FIELD_LOCATION_NAME, null, null, null, Time.now()).equals("北京"),
                "Chinese city survives missing Garmin weather name and midnight expiry");
            Application.Properties.setValue("FieldRight", FIELD_LOCATION_NAME);
            System.println("QWEATHER_DISPLAY_COMPLETE");`);
  view = view.replace('auditAssert(auditLunarCalculations <= 2, "lunar cache reused for both languages");', '');
    view = view.replace('auditDraw(dc);\n            auditAssert', `auditDraw(dc);
            auditAssert(_cachedConditions != null && _cachedConditions.temperature == 0 &&
                _cachedConditions.highTemperature == 5.5 && _cachedConditions.relativeHumidity == 72 &&
                weatherValue(WX_CONDITION, _cachedConditions).equals("小雪") &&
                weatherValue(WX_PRECIP, _cachedConditions).equals("35%"), "selected QWeather data reaches real renderer");
            if (auditFrames <= 400 && auditFrames % 20 == 1) {
                Application.Properties.setValue("WeatherSource", 0); QWeatherWeather.reload(); onSettingsChanged(); auditDraw(dc);
                auditAssert(_cachedConditions == null || !(_cachedConditions has :conditionText) ||
                    _cachedConditions.conditionText == null, "Garmin source contains no QWeather text");
                Application.Properties.setValue("WeatherSource", 1); QWeatherWeather.reload(); onSettingsChanged(); auditDraw(dc);
                auditAssert(_cachedConditions != null && _cachedConditions.temperature == 0, "switching back restores independent QWeather cache");
            }
            auditAssert`);
}
if (boundaryCase === 'chart-width') {
  const stored = view.slice(view.indexOf('class CNWatchFaceStoredWeather'));
  view = fs.readFileSync(path.join(root,'tests/chart-width-boundary.mc'),'utf8') + '\n' + stored;
  const chartPath = path.join(out,'source/CNChartData.mc');
  let chart = fs.readFileSync(chartPath,'utf8');
  chart = chart.replace('if (!(Graphics has :getVectorFont))', 'if (AuditWidth.bitmapOnly || !(Graphics has :getVectorFont))');
  chart = chart.replace('dc.drawText(labelRight,', 'if (dc.getTextWidthInPixels(name, nameFont) > (dc.getWidth() * 0.25).toNumber()) { throw new Lang.InvalidValueException("chart label exceeds column"); } dc.drawText(labelRight,');
  chart = chart.replace('dc.drawText(valueLeft,', 'if (dc.getTextWidthInPixels(value, valueFont) > valueWidth) { throw new Lang.InvalidValueException("chart value exceeds column"); } dc.drawText(valueLeft,');
  fs.writeFileSync(chartPath,chart);
}
if (boundaryCase === 'qweather') {
  // A small runner avoids the old MIP class-member ceiling of the renderer probe.
  view = `using Toybox.Application;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Position;
using Toybox.System;
using Toybox.Time;
using Toybox.WatchUi;
class CNWatchFaceView extends WatchUi.WatchFace {
    private var auditStep = 0;
    function initialize() { WatchFace.initialize(); }
    function onSettingsChanged() {}
    private function auditAssert(ok, name) {
        if (!ok) { System.println("AUDIT_FAIL " + name); throw new Lang.InvalidValueException(name); }
    }
    ${fs.readFileSync(path.join(root,'tests/qweather-location-boundary.mc'),'utf8')}
    function onUpdate(dc as Graphics.Dc) as Void {
        if (auditStep >= 4) { return; }
        auditStep += 1;
        if (auditStep == 1) { auditQWeatherLocation(); }
        else if (auditStep == 2) { auditQWeatherWeather(); }
        else if (auditStep == 3) { auditQWeatherNightBoundary(); }
        else { auditQWeatherCoordinates(); }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Graphics.FONT_SMALL, "北京", Graphics.TEXT_JUSTIFY_CENTER);
        if (auditStep == 4) { System.println("AUDIT_COMPLETE qweather"); }
        else { WatchUi.requestUpdate(); }
    }
}`;
  const productionView = fs.readFileSync(path.join(root, 'source/CNWatchFaceView.mc'), 'utf8');
  view += '\n' + productionView.slice(productionView.indexOf('class CNWatchFaceStoredWeather'));
  view += '\n' + fs.readFileSync(path.join(root,'tests/qweather-request-fixture.mc'),'utf8');
  const servicePath = path.join(out, 'source/QWeatherLocationService.mc');
  let service = fs.readFileSync(servicePath, 'utf8')
    .replaceAll('Background.exit(', 'AuditQWeather.exit(')
    .replaceAll('Background.deleteTemporalEvent();', 'AuditQWeather.deleted += 1;')
    .replace('QWeatherLocation.schedule(false);', 'AuditQWeather.scheduled += 1;')
    .replace('QWeatherLocation.schedule(nextJob(Time.now().value()) != 0);', 'AuditQWeather.scheduled += 1;')
    .replace('_coordinates = coordinates();', '_coordinates = AuditQWeather.useCachedCoordinates ? cachedCoordinates() : AuditQWeather.coordinates;')
    .replaceAll('Communications.makeWebRequest(', 'AuditQWeather.request(');
  fs.writeFileSync(servicePath, service);
}
if (boundaryCase === 'activity') {
  view += '\n' + fs.readFileSync(path.join(root,'tests/activity-history-fixture.mc'),'utf8');
  view = view.replace('private var auditFrames = 0;', 'private var auditFrames = 0; private var auditHistoryReads = 0;');
  view = view.replace('var iterator = UserProfile.getUserActivityHistory();',
    'auditHistoryReads += 1; var iterator = new AuditHistoryIterator();');
  view = view.replace('if (auditFrames <= 400 && auditFrames % 20 == 1)', 'if (false)');
  view = view.replace('auditDraw(dc);\n            auditAssert',
    `Application.Properties.setValue("FieldLeft", 55);
            Application.Properties.setValue("UpdateFrequency", 60);
            var lateHistory = auditFrames % 20 == 1;
            var readsBefore = auditHistoryReads;
            if (lateHistory) {
                var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
                _activityDistanceCacheKey = -1;
                _dataMinute = (Time.now().value() / 60).toNumber();
                _activityCacheDay = (today.year * 13 + today.month) * 32 + today.day;
                onExitSleep();
            }
            auditDraw(dc);
            if (lateHistory && isAmoledLayout()) {
                auditAssert(auditHistoryReads == readsBefore, "wake drawing never reads activity history");
                _dataMinute = -1;
                auditDraw(dc);
                auditAssert(auditHistoryReads > readsBefore && _runningDistances != null &&
                    _runningDistances[DISTANCE_PERIOD_WEEK] == 5000.0, "next data refresh loads recent history");
            }
            auditAssert`);
}
if (boundaryCase === 'settings') {
  view = view.replace('class CNWatchFaceView extends WatchUi.WatchFace {',
    'class CNWatchFaceView extends WatchUi.WatchFace {\n' + fs.readFileSync(path.join(root,'tests/settings-boundary.mc'),'utf8'));
  view = view.replace('if (auditFrames <= 400 && auditFrames % 20 == 1)', 'if (false)');
  view = view.replace('private var auditFrames = 0;', 'private var auditFrames = 0; private var auditSettingsPending = false;');
  view = view.replace('if (auditFrames >= 600)',
    `if (auditFrames < 400 && auditFrames % 20 == 0 && !auditSettingsPending) {
            auditSettingsPending = true; auditSettingsBoundary(dc); WatchUi.requestUpdate(); return;
        }
        auditSettingsPending = false;
        if (auditFrames >= 600)`);
  view = view.replace('auditDraw(dc);\n            auditAssert',
    `auditDraw(dc);
            if (auditFrames <= 400 && auditFrames % 20 == 1) { auditHeartBoundary(dc); }
            auditAssert`);
}
if (startupAudit) {
  // Preserve the real first-frame path: no weather preflight and no settings
  // changes for the first 100 frames. Later exercise simultaneous resources.
  view = view.replace('auditWeather();', 'System.println("STARTUP_REAL_FIRST_FRAME");');
  view = view.replace('Application.Properties.setValue("TopLabel", "测试 TEST");', '');
  view = view.replace('Application.Properties.setValue("ShowSecondsActive", 1);', '');
  view = view.replace('auditFrames <= 400 && auditFrames % 20 == 1', 'auditFrames > 100 && auditFrames <= 400 && auditFrames % 20 == 1');
  view = view.replace('var first = ((auditFrames / 20).toNumber() % 15) * 4;',
    `Application.Properties.setValue("TopLabel", "测试 TEST");
                Application.Properties.setValue("TopLabelFont", (auditFrames / 20).toNumber() % 5);
                var first = ((auditFrames / 20).toNumber() % 15) * 4;`);
  view = view.replace('if (auditFrames % 100 == 0) { _dataMinute = -1; }',
    'if (auditFrames <= 400 && auditFrames % 100 == 0) { onLayout(dc); _dataMinute = -1; System.println("STARTUP_RELAYOUT " + auditFrames); }');
}
if (wakeAudit) {
  view = view.replace('auditDraw(dc);\n            auditAssert',
    `var wakeTest = isAmoledLayout() && auditFrames > 400 && auditFrames % 20 == 1;
            var wakeTick = (Time.now().value() / 60).toNumber();
            if (wakeTest) {
                Application.Properties.setValue("UpdateFrequency", 60);
                _dataMinute = wakeTick - 1;
                onExitSleep();
                auditAssert(_dataMinute == wakeTick - 1 && _wakeFramePending, "wake retains cache");
            }
            auditDraw(dc);
            if (wakeTest) {
                auditAssert(!_wakeFramePending && _dataMinute == wakeTick - 1, "first bright frame defers due refresh");
                auditDraw(dc);
                auditAssert(_dataMinute == (Time.now().value() / 60).toNumber(), "next frame refreshes due data");
                _activityCacheDay = -1;
                _dataMinute = -1;
                onExitSleep(); auditDraw(dc);
                auditAssert(_activityCacheDay != -1 && _dataMinute >= 0, "invalid day and cold cache refresh immediately");
                System.println("WAKE_CHECK frame=" + auditFrames);
            }
            auditAssert`);
  view = view.replace('System.println("AUDIT_COMPLETE frames="',
    'auditAssert(!isAmoledLayout() || auditAodFrames > 0, "AMOLED AOD was exercised");\n            System.println("AUDIT_COMPLETE frames="');
}
if (styleAudit) {
  view = view.replace('private var auditFrames = 0;', 'private var auditFrames = 0; private var auditTitleDraws = 0;');
  for (const x of ['_cx - 1','_cx + 1','_cx']) {
    const draw=`dc.drawText(${x}, y(0.08), topLabelFont, topLabelText,`;
    view = view.replace(draw, 'auditTitleDraws += 1; '+draw);
  }
  view = view.replace('auditDraw(dc);\n            auditAssert',
    'Application.Properties.setValue("TopLabelBold", auditFrames % 40 < 20 ? 1 : 0);\n'+
    '            Application.Properties.setValue("CalendarLayout", (auditFrames / 100).toNumber() % 3);\n'+
    '            Application.Properties.setValue("ShowWeekday", (auditFrames / 100).toNumber() % 2);\n'+
    '            Application.Properties.setValue("ShowSolarTerm", (auditFrames / 100).toNumber() % 2);\n'+
    '            var beforeTitle = auditTitleDraws; auditDraw(dc);\n'+
    '            var expectedTitle = (_lowPower && isAmoledLayout()) ? 0 : (auditFrames % 40 < 20 ? 3 : 1);\n'+
    '            auditAssert(auditTitleDraws - beforeTitle == expectedTitle, "title regular or bold draws");\n            auditAssert');
  view = view.replace('var chartH = sepY - chartTop;',
    'var chartH = sepY - chartTop; auditAssert(chartTop >= calendarBottom + scalePx(3), "chart calendar clearance");'+
    'auditAssert(sepY == y(0.74) + amoledJitterY, "chart baseline unchanged");');
}
if (fontAudit) {
  view = view.replace('auditWeather();',
    'auditWeather(); var fontOptions = CNTopLabelFonts.options(); var expectedOptions = 1;\n'+
    '            for (var f = 1; f <= 4; f += 1) { if (CNTopLabelFonts.supported(f)) { expectedOptions += 1; } }\n'+
    '            auditAssert(fontOptions.size() == expectedOptions, "menu only contains usable device fonts");\n'+
    '            System.println("FONT_OPTIONS count=" + fontOptions.size());');
  view = view.replace('auditDraw(dc);\n            auditAssert',
    'if (auditFrames <= 400) {\n'+
    '                var fontChoice = (auditFrames / 50).toNumber() % 6;\n'+
    '                Application.Properties.setValue("TopLabelFont", fontChoice == 5 ? 99 : fontChoice);\n'+
    '                Application.Properties.setValue("TopLabel", auditFrames % 50 < 25 ? "GARMIN" : "测试 TEST");\n'+
    '            }\n'+
    '            var previousFont = _topLabelFont; var previousChoice = _topLabelFontChoice; var previousText = _topLabelFontText;\n'+
    '            auditDraw(dc);\n'+
    '            if (!(_lowPower && isAmoledLayout())) {\n'+
    '                if (CNTopLabelFonts.supported(_topLabelFontChoice)) { auditAssert(_topLabelFont != null, "supported title font loads including Chinese fallback"); }\n'+
    '                if (previousChoice == _topLabelFontChoice && previousText.equals(_topLabelFontText) && previousFont != null) { auditAssert(previousFont == _topLabelFont, "unchanged title reuses font"); }\n'+
    '            }\n            auditAssert');
}
if (uncached) {
  // Control run: original resource-loading behavior; calendar code stays identical.
  view = view.replace(/if \(!_iconCache.hasKey\(resourceId\)\) \{[\s\S]*?var bitmap = _iconCache\[resourceId\];/,
    'auditIconLoads += 1; var bitmap = WatchUi.loadResource(resourceId);');
  view = view.replace('if (!_topLabelFontChecked || _topLabelFontChoice != choice || !_topLabelFontText.equals(text)) {', 'if (true) {');
  view = view.replace('auditAssert(auditStableLoads == auditIconLoads + auditTopLoads, "stable frames reuse resources");','');
}
if (boundaryCase === 'compatibility') {
  // Older VMs cap instance members at 253. Instrument the existing callback
  // in place, keeping counters outside the production class and its stack.
  view = fs.readFileSync(path.join(root, compatibilityBaseline ? 'work/invalid-value-20261013/CNWatchFaceView-1.5.7.mc' : 'source/CNWatchFaceView.mc'),'utf8');
  fs.writeFileSync(path.join(out, 'instrumented-input.json'), JSON.stringify({
    releaseMode:true, originalRelease157:compatibilityBaseline,
    viewSha256:crypto.createHash('sha256').update(view).digest('hex')
  }, null, 2));
  view = view.replace('function onUpdate(dc as Graphics.Dc) as Void {',
    `function onUpdate(dc as Graphics.Dc) as Void {
        AuditCompatibility.frames += 1;
        if (AuditCompatibility.frames % 20 == 1) {
            var auditFields = [FIELD_BODY_BATTERY, FIELD_RECOVERY, FIELD_ELEVATION, FIELD_SPO2, FIELD_STRESS];
            var auditField = auditFields[((AuditCompatibility.frames - 1) / 20).toNumber() % auditFields.size()];
            Application.Properties.setValue("FieldTopLeft", auditField);
            Application.Properties.setValue("FieldTopRight", auditField);
            Application.Properties.setValue("FieldLeft", auditField);
            Application.Properties.setValue("FieldCenter", auditField);
            Application.Properties.setValue("FieldRight", auditField);
            onSettingsChanged();
            System.println("COMPATIBILITY_FIELD " + auditField);
        }`);
  view = view.replace(/(\r?\n)    }\r?\n}\r?\n\r?\nclass CNWatchFaceStoredWeather/,
    `$1        var auditFree = System.getSystemStats().freeMemory;
        if (auditFree < AuditCompatibility.minFree) { AuditCompatibility.minFree = auditFree; }
        if (AuditCompatibility.frames < ${frameCount}) { WatchUi.requestUpdate(); }
        else { System.println("AUDIT_COMPLETE frames=" + AuditCompatibility.frames + " minFree=" + AuditCompatibility.minFree); }
    }
}

class CNWatchFaceStoredWeather`);
  view += '\nmodule AuditCompatibility { var frames = 0; var minFree = 99999999; }\n';
}
if (boundaryCase === 'smoke') {
  view = fs.readFileSync(path.join(root,'source/CNWatchFaceView.mc'),'utf8');
  view = view.replace('function onUpdate(dc as Graphics.Dc) as Void {', 'function onUpdate(dc as Graphics.Dc) as Void { System.println("SMOKE_START free=" + System.getSystemStats().freeMemory);');
  view = view.replace(/(\r?\n)    }\r?\n}\r?\n\r?\nclass CNWatchFaceStoredWeather/,
    '$1        System.println("' + (process.env.CNWATCH_SMOKE_MENU === '1' ? 'MENU_FIRST_FRAME' : 'AUDIT_COMPLETE smoke') + ' free=" + System.getSystemStats().freeMemory);\n    }\n}\n\nclass CNWatchFaceStoredWeather');
  if (process.env.CNWATCH_SMOKE_QW !== '1') {
    const appPath = path.join(out,'source/CNWatchFaceApp.mc');
    fs.writeFileSync(appPath,fs.readFileSync(appPath,'utf8').replace('function getInitialView() {', `function getInitialView() {
        Application.Properties.setValue("QWeatherHost", "");
        Application.Properties.setValue("QWeatherKey", "");
        Application.Properties.setValue("WeatherSource", 0);`));
  }
  if (process.env.CNWATCH_SMOKE_QW === '1') {
    const appPath = path.join(out,'source/CNWatchFaceApp.mc');
    let app = fs.readFileSync(appPath,'utf8').replace('function getInitialView() {', `function getInitialView() {
        Application.Properties.setValue("QWeatherHost", "test.re.qweatherapi.com");
        Application.Properties.setValue("QWeatherKey", "fixture-key");
        Application.Properties.setValue("QWeatherRegion", 1);
        Application.Properties.setValue("WeatherSource", 1);
        Application.Storage.setValue(QWeatherWeather.STORAGE_KEY, {"host" => "test.re.qweatherapi.com", "region" => "mainland",
            "time" => Toybox.Time.now().value(), "coordinates" => [39.92, 116.41], "current" => {"temperature" => 0}});`);
    fs.writeFileSync(appPath,app);
  }
}
if (boundaryCase === 'integration') {
  view = fs.readFileSync(path.join(root,'source/CNWatchFaceView.mc'),'utf8');
  view = view.replace('function onUpdate(dc as Graphics.Dc) as Void {', `function onUpdate(dc as Graphics.Dc) as Void {
        if (AuditIntegration.frames >= ${frameCount}) { return; }
        AuditIntegration.prepare();
        _dataMinute = -1;
        if (AuditIntegration.frames % 20 == 1) { onExitSleep(); }
        if (AuditIntegration.frames % 20 == 11) { onEnterSleep(); }`);
  view = view.replace('dc.drawText(clockCenterX, timeY, timeFont, timeText,', 'AuditIntegration.clocks += 1; dc.drawText(clockCenterX, timeY, timeFont, timeText,');
  view = view.replace('_aodRenderer.draw(dc, clock.hour', 'AuditIntegration.aod += 1; _aodRenderer.draw(dc, clock.hour');
  view = view.replace('drawAmoledAod(dc, clock, date, displayHour, numberProperty("LowPowerStyle", 1) == 1);',
    'drawAmoledAod(dc, clock, date, displayHour, numberProperty("LowPowerStyle", 1) == 1); AuditIntegration.finish(true, _cachedConditions);');
  view = view.replace(/(\r?\n)    }\r?\n}\r?\n\r?\nclass CNWatchFaceStoredWeather/,
    '$1        AuditIntegration.finish(false, _cachedConditions);\n    }\n}\n\nclass CNWatchFaceStoredWeather');
  view += '\n' + fs.readFileSync(path.join(root,'tests/weather-chart-integration.mc'),'utf8').replaceAll('600',String(frameCount));
  const modulePath = path.join(out,'source/QWeatherLocation.mc');
  const moduleSource = fs.readFileSync(modulePath,'utf8');
  const start = moduleSource.indexOf('    function schedule(');
  const end = moduleSource.indexOf('    function needsLookup(',start);
  fs.writeFileSync(modulePath,moduleSource.slice(0,start)+'    function schedule(initial as Lang.Boolean) as Void {}\n\n'+moduleSource.slice(end));
}
if (boundaryCase === 'smoke') {
  if (process.env.CNWATCH_SMOKE_MENU === 'fresh') {
    for (const file of ['CNWatchFaceApp.mc', 'CNWatchFaceAppLowMemory.mc']) {
      const appPath = path.join(out,'source',file);
      let app = fs.readFileSync(appPath,'utf8');
      app = app.replace('var menu = new CNWatchFaceSettingsMenu();', 'var started = Toybox.System.getTimer(); var menu = new CNWatchFaceSettingsMenu(); Toybox.System.println("MENU_BUILD ms=" + (Toybox.System.getTimer() - started));');
      app = app.replace(/function getInitialView\(\) \{[\s\S]*?\n    }/, 'function getInitialView() { getSettingsView(); return [new AuditSettingsDone()]; }');
      app = app.replace('return [menu, new CNWatchFaceSettingsDelegate(menu)];', `
        var count = 0;
        while (menu.getItem(count) != null) {
            var id = menu.getItem(count).getId();
            if (!CNWeatherProvider.available() && id == :weatherSource) { throw new Toybox.Lang.InvalidValueException("excluded weather menu"); }
            count += 1;
        }
        AuditSettingsEntry.count = count;
        AuditSettingsEntry.free = Toybox.System.getSystemStats().freeMemory;
        var delegate = new CNWatchFaceSettingsDelegate(menu);
        for (var i = 0; i < count; i += 1) {
            if (menu.getItem(i).getId() == :left) { delegate.onSelect(menu.getItem(i)); break; }
        }
        if (AuditSettingsEntry.submenu == 0) { throw new Toybox.Lang.InvalidValueException("field selector was not exercised"); }
        return [menu, new CNWatchFaceSettingsDelegate(menu)];`);
      fs.writeFileSync(appPath,app);
    }
    const menuPath = path.join(out,'source/CNWatchFaceSettings.mc');
    fs.writeFileSync(menuPath,fs.readFileSync(menuPath,'utf8')
      .replace('WatchUi.pushView(submenu, new CNWatchFaceSubMenuDelegate(key, id, _menu), WatchUi.SLIDE_IMMEDIATE);', 'AuditSettingsEntry.submenu = options.size(); Toybox.System.println("SUBMENU_CONSTRUCTED options=" + options.size() + " free=" + Toybox.System.getSystemStats().freeMemory);')
    );
    view += '\nmodule AuditSettingsEntry { var count = 0; var free = 0; var submenu = 0; }\nclass AuditSettingsDone extends Toybox.WatchUi.WatchFace {\n function initialize() { WatchFace.initialize(); }\n function onUpdate(dc) { Toybox.System.println("AUDIT_COMPLETE settings-construction items=" + AuditSettingsEntry.count + " free=" + AuditSettingsEntry.free + " options=" + AuditSettingsEntry.submenu); }\n}\n';
  }
  const modulePath = path.join(out,'source/QWeatherLocation.mc');
  const moduleSource = fs.readFileSync(modulePath,'utf8');
  const start = moduleSource.indexOf('    function schedule(');
  const end = moduleSource.indexOf('    function needsLookup(',start);
  fs.writeFileSync(modulePath,moduleSource.slice(0,start)+'    function schedule(initial as Lang.Boolean) as Void {}\n\n'+moduleSource.slice(end));
}
fs.writeFileSync(path.join(out,'source/CNWatchFaceView.mc'),view);
const manifest = fs.readFileSync(path.join(root,'manifest.xml'),'utf8').replace(/(<iq:application[^>]*\bid=")[^"]+/, '$1A0011001220033004400550066007700');
fs.writeFileSync(path.join(out,'manifest.xml'),manifest);
const abs = p => path.resolve(root,p).replaceAll('\\','/');
let jungle = fs.readFileSync(path.join(root,'monkey.jungle'),'utf8').replace(/^([^\n=]+(?:sourcePath|resourcePath|manifest|lang\.zhs))\s*=\s*([^\r\n]+)/gm,
  (_,key,value) => key.trim()+' = '+value.split(';').map(p => p.trim().startsWith('$(')?p.trim():abs(p.trim())).join(';'));
jungle = jungle.replace(/^project.manifest = .*$/m,'project.manifest = '+path.join(out,'manifest.xml').replaceAll('\\','/'));
jungle = jungle.replace(/^base.sourcePath = .*$/m,'base.sourcePath = '+path.join(out,'source').replaceAll('\\','/'));
fs.writeFileSync(path.join(out,'probe.jungle'),jungle);
const results=[];
fs.writeFileSync(path.join(out,'source-fingerprints.json'),JSON.stringify(fs.readdirSync(path.join(root,'source')).filter(n=>n.endsWith('.mc')).map(name=>({name,sha256:crypto.createHash('sha256').update(fs.readFileSync(path.join(root,'source',name))).digest('hex')})),null,2));
const sleep = ms => new Promise(r=>setTimeout(r,ms));
let auditSimulatorPid = null;
const simulatorPath = path.join(sdk,'simulator.exe').replaceAll("'","''");
function closeAuditSimulator() {
  if (auditSimulatorPid === null) return;
  cp.spawnSync('powershell.exe',['-NoProfile','-Command',
    `Get-CimInstance Win32_Process -Filter "ProcessId=${auditSimulatorPid}" | Where-Object { $_.ExecutablePath -eq '${simulatorPath}' } | ForEach-Object { Stop-Process -Id $_.ProcessId }`],{windowsHide:true});
  auditSimulatorPid = null;
}
(async()=>{
  try {
  for (const device of devices) {
    // Each simulator run owns its settings/storage; sibling models and old
    // fault-injection cases must not contaminate cold-start measurements.
    const runManifest = manifest.replace(/(<iq:application[^>]*\bid=")[^"]+/, '$1'+crypto.randomBytes(16).toString('hex'));
    fs.writeFileSync(path.join(out,'manifest.xml'),runManifest);
    fs.writeFileSync(path.join(out,device+'-manifest.xml'),runManifest);
    const prg=path.join(out,device+'.prg');
    const build=cp.spawnSync(java,['-Xmx2g','-jar',path.join(sdk,'monkeybrains.jar'),'-f',path.join(out,'probe.jungle'),'-d',device,'-o',prg,'-y',path.join(root,'keys/CNWatchFace-release.der'),...(process.env.CNWATCH_OPTIMIZE ? ['-O', process.env.CNWATCH_OPTIMIZE] : []),...(['compatibility','integration','smoke'].includes(boundaryCase) ? ['-r'] : []),'-w'],{cwd:root,encoding:'utf8'});
    fs.writeFileSync(path.join(out,device+'-build.log'),build.stdout+build.stderr);
    if(build.status!==0){ console.log(device+' BUILD_FAILED');results.push({device,passed:false});continue; }
    // Do not interrupt a user's simulator/debug session. Own and close only the audit instance.
    const launched = cp.spawnSync('powershell.exe',['-NoProfile','-Command',
      `$existingAuditSimulator = Get-CimInstance Win32_Process -Filter "Name='simulator.exe'" | Where-Object { $_.ExecutablePath -eq '${simulatorPath}' }; if ($existingAuditSimulator) { Write-Error 'Close the simulator/debug session before running the audit.'; exit 1 }; (Start-Process -FilePath '${simulatorPath}' -WindowStyle Hidden -PassThru).Id`],{windowsHide:true,encoding:'utf8'});
    if (launched.status !== 0 || !/^\d+$/.test(launched.stdout.trim())) {
      throw new Error(launched.stderr || 'Unable to start the isolated audit simulator.');
    }
    auditSimulatorPid = Number(launched.stdout.trim());
    await sleep(2500);
    const run=cp.spawn(java,['-classpath',path.join(sdk,'monkeybrains.jar'),'com.garmin.monkeybrains.monkeydodeux.MonkeyDoDeux','-f',prg,'-d',device,'-s',path.join(sdk,'shell.exe')],{cwd:root,windowsHide:true});
    const logPath=path.join(out,device+'-runtime.log');
    fs.writeFileSync(logPath,'');
    let log=''; const record=d=>{log+=d;fs.appendFileSync(logPath,d);};
    run.stdout.on('data',record);run.stderr.on('data',record);
    const deadline=Date.now()+300000;
    while(Date.now()<deadline && !/AUDIT_COMPLETE|AUDIT_FAIL|Encountered an app crash/.test(log) && run.exitCode===null) await sleep(500);
    cp.spawnSync('taskkill',['/PID',String(run.pid),'/T','/F'],{windowsHide:true});
    fs.writeFileSync(path.join(out,device+'-runtime.log'),log);
    const passed=/AUDIT_COMPLETE/.test(log) && !/AUDIT_FAIL|Encountered an app crash/.test(log);
    results.push({device,passed}); console.log(device+' '+(passed?'PASS':'FAIL')+' '+log.slice(-300));
    fs.writeFileSync(path.join(out,'results.json'),JSON.stringify(results,null,2));
    closeAuditSimulator();
  }
  process.exitCode=results.every(r=>r.passed)?0:1;
  } finally { closeAuditSimulator(); }
})().catch(error => { console.error(error.message); process.exitCode = 1; });
