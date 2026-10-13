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
if (boundaryCase && !['calendar', 'weather', 'activity', 'settings', 'compatibility'].includes(boundaryCase)) throw new Error('Unknown boundary case');
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
    const prg=path.join(out,device+'.prg');
    const build=cp.spawnSync(java,['-Xmx2g','-jar',path.join(sdk,'monkeybrains.jar'),'-f',path.join(out,'probe.jungle'),'-d',device,'-o',prg,'-y',path.join(root,'keys/CNWatchFace-release.der'),...(boundaryCase === 'compatibility' ? ['-r'] : []),'-w'],{cwd:root,encoding:'utf8'});
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
