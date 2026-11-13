const fs = require('node:fs');
const path = require('node:path');
const cp = require('node:child_process');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const out = path.join(root, 'work/device-matrix-final-memory-20261024');
fs.mkdirSync(out, {recursive:true});
const products = JSON.parse(cp.execFileSync('powershell.exe', ['-NoProfile', '-Command',
  '$m=[xml](Get-Content -LiteralPath manifest.xml -Raw); @($m.SelectNodes("//*[local-name()=\'product\']") | ForEach-Object { $_.id }) | ConvertTo-Json -Compress'], {cwd:root, encoding:'utf8'}));
const jungle = fs.readFileSync(path.join(root,'monkey.jungle'),'utf8');
const fingerprint = () => crypto.createHash('sha256').update(fs.readdirSync(path.join(root,'source')).filter(n=>n.endsWith('.mc')).sort().map(n=>n+fs.readFileSync(path.join(root,'source',n),'utf8')).join('\n')).digest('hex');
const inputHash = fingerprint();
const sdk = path.join(process.env.APPDATA,'Garmin/ConnectIQ/Sdks/connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2/bin');
const retryFailed = process.argv.includes('--retry-failed');
const previous = retryFailed ? JSON.parse(fs.readFileSync(path.join(out,'results.json'),'utf8')) : null;
if (previous && previous.inputHash !== inputHash) { throw new Error('Sources changed; run the complete matrix again.'); }
const results = previous ? previous.results : [];
async function check(device) {
  const build = await new Promise((resolve,reject)=>{
    const child = cp.spawn('C:/Program Files/Java/jdk-26.0.2.1/bin/java.exe', ['-Xmx2g','-jar',path.join(sdk,'monkeybrains.jar'),'-f',path.join(root,'monkey.jungle'),'-d',device,'-o',path.join(out,device+'.prg'),'-y',path.join(root,'keys/CNWatchFace-release.der'),'-w'], {cwd:root,windowsHide:true});
    let stdout='',stderr='';
    child.stdout.on('data',d=>{stdout+=d;}); child.stderr.on('data',d=>{stderr+=d;});
    child.on('error',reject); child.on('close',status=>resolve({status,stdout,stderr}));
  });
  fs.writeFileSync(path.join(out,device+'-build.log'),build.stdout+build.stderr);
  const legacy = new RegExp(`^${device}\\.sourcePath = source-legacy`, 'm').test(jungle);
  const metadata = JSON.parse(fs.readFileSync(path.join(process.env.APPDATA,'Garmin/ConnectIQ/Devices',device,'compiler.json'),'utf8'));
  let settingError = null;
  let chart = [], weather = [];
  if (build.status === 0) {
    const settings = JSON.parse(fs.readFileSync(path.join(out,device+'-settings.json'),'utf8')).settings;
    chart = settings.filter(s=>s.key.startsWith('Chart'));
    weather = settings.filter(s=>s.key.startsWith('QWeather') || s.key==='WeatherSource');
    if (chart.length !== (!legacy && metadata.displayType==='amoled' ? 3 : 0)) settingError = 'Chart settings isolation failed';
    const lowMemory = metadata.appTypes.find(a=>a.type==='watchFace').memoryLimit < 131072;
    if (weather.length !== (legacy || lowMemory ? 0 : 5)) settingError = 'Weather settings isolation failed';
    const symbols = fs.readFileSync(path.join(out,device+'.prg.debug.xml'),'utf8');
    if ((legacy || lowMemory) && /parent="globals\/QWeather|name="QWeather(?:Location|Weather|Adapter|Coordinates)/.test(symbols)) settingError = 'Excluded product includes QWeather code';
    if (!legacy && lowMemory && symbols.includes('parent="globals/CNWatchFaceSettingsMenu"')) settingError = 'Low-memory product includes native settings code';
  }
  const oldIndex = results.findIndex(r=>r.device===device);
  if (oldIndex >= 0) { results.splice(oldIndex,1); }
  results.push({device,passed:build.status===0 && !settingError,legacy,display:metadata.displayType,family:metadata.deviceFamily,chart:chart.length,weather:weather.length,error:settingError,exit:build.status});
  fs.writeFileSync(path.join(out,'results.json'),JSON.stringify({inputHash,sourceUnchanged:inputHash===fingerprint(),results},null,2));
  console.log(`${results.length}/${products.length} ${device} ${results.at(-1).passed?'PASS':'FAIL'}${settingError?' '+settingError:''}`);
}
let next = 0;
const queue = retryFailed ? products.filter(d=>!results.find(r=>r.device===d)?.passed) : products;
Promise.all(Array.from({length:retryFailed ? 1 : 3},async()=>{
  while (next < queue.length) { const device=queue[next++]; await check(device); }
})).then(async()=>{
  // SDK compiler failures can be transient when its caches are accessed in
  // parallel. Preserve the failed evidence and retry each failure once alone.
  if (!retryFailed) {
    fs.writeFileSync(path.join(out,'initial-results.json'),JSON.stringify({inputHash,results},null,2));
    for (const result of results.filter(r=>!r.passed)) {
      fs.copyFileSync(path.join(out,result.device+'-build.log'),path.join(out,result.device+'-initial-build.log'));
      await check(result.device);
    }
  }
  console.log(`MATRIX_COMPLETE passed=${results.filter(r=>r.passed).length}/${results.length} sourceUnchanged=${inputHash===fingerprint()}`);
  process.exitCode = results.every(r=>r.passed) && inputHash===fingerprint() ? 0 : 1;
}).catch(error=>{console.error(error);process.exitCode=1;});
