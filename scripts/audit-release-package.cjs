// Read the exported IQ, not loose debug builds, to verify device-specific phone settings.
const fs = require('node:fs');
const path = require('node:path');
const cp = require('node:child_process');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const version = fs.readFileSync(path.join(root, 'VERSION'), 'utf8').trim();
const release = path.join(root, 'releases', version);
const iq = path.join(release, `CNWatchFace-${version}.iq`);
const unpacked = path.join(root, 'work', `package-audit-${version}`);
if (fs.existsSync(unpacked)) {
    const currentManifest = cp.execFileSync('tar', ['-xOf', iq, 'manifest.xml']);
    if (!currentManifest.equals(fs.readFileSync(path.join(unpacked, 'manifest.xml')))) {
        throw new Error('Audit output belongs to a different package; preserve that evidence.');
    }
} else {
    fs.mkdirSync(unpacked, {recursive:true});
    cp.execFileSync('tar', ['-xf', iq, '-C', unpacked]);
}
const assert = (ok, text) => { if (!ok) throw new Error(text); };
const sourceManifest = fs.readFileSync(path.join(root, 'manifest.xml'), 'utf8');
const products = [...sourceManifest.matchAll(/<iq:product id="([^"]+)"/g)].map(m => m[1]);
assert(new Set(products).size === products.length, 'Duplicate manifest products');
const packagedManifest = fs.readFileSync(path.join(unpacked, 'manifest.xml'), 'utf8');
const appId = sourceManifest.match(/<iq:application id="([^"]+)"/)[1].replaceAll('-', '');
assert(packagedManifest.includes(`id="${appId}"`), 'Application ID mismatch');
const packagedParts = [...packagedManifest.matchAll(/<iq:product\s[^>]*partNumber="([^"]+)"/g)].map(m=>m[1]);
const expectedParts = new Set();
const support = JSON.parse(fs.readFileSync(path.join(root, 'work/top-font-support.json'), 'utf8'));
const jungle = fs.readFileSync(path.join(root, 'monkey.jungle'), 'utf8');
const audit = [];
for (const device of products) {
    const metadata = JSON.parse(fs.readFileSync(path.join(process.env.APPDATA, 'Garmin/ConnectIQ/Devices', device, 'compiler.json'), 'utf8'));
    const legacy = new RegExp(`^${device}\\.sourcePath = source-legacy`, 'm').test(jungle);
    for (const part of metadata.partNumbers) {
        expectedParts.add(part.number);
        assert(packagedParts.includes(part.number), `${device}: missing ${part.number}`);
        const dir = path.join(unpacked, part.number);
        assert(fs.existsSync(path.join(dir, `CNWatchFace-${version}.prg`)), `${device}: missing PRG`);
        const settings = JSON.parse(fs.readFileSync(path.join(dir, `${part.number}-settings.json`), 'utf8'));
        const rows = settings.settings;
        const lowMemory = metadata.appTypes.find(a=>a.type==='watchFace').memoryLimit < 131072;
        const chart = rows.filter(s=>s.key.startsWith('Chart'));
        const weather = rows.filter(s=>s.key.startsWith('QWeather') || s.key==='WeatherSource');
        assert(chart.length === (!legacy && metadata.displayType==='amoled' ? 3 : 0), `${device}: chart settings isolation`);
        assert(weather.length === (!legacy && !lowMemory ? 5 : 0), `${device}: QWeather settings isolation`);
        if (weather.length > 0) {
            assert(weather.find(s=>s.key==='QWeatherHost').defaultValue === '', `${device}: API Host must be user supplied`);
            assert(weather.find(s=>s.key==='QWeatherKey').defaultValue === '', `${device}: API Key must be user supplied`);
            assert(weather.find(s=>s.key==='WeatherSource').defaultValue === 0, `${device}: default Garmin weather`);
        }
        if (chart.length > 0) {
            assert(chart.find(s=>s.key==='ChartCustomData').defaultValue === 0, `${device}: default chart mode`);
            for (const key of ['ChartDataField','ChartDataFieldBottom']) {
                const choices = rows.find(s=>s.key===key).configOptions.map(o=>o.value);
                assert(new Set(choices).size === choices.length, `${device}: duplicate chart choices in ${key}`);
                assert(choices.includes(1) && choices.includes(4) && choices.includes(53), `${device}: chart field choices`);
            }
        }
        assert(new Set(rows.map(s=>s.key)).size === rows.length, `${device}: duplicate settings`);
        const font = rows.find(s=>s.key === 'TopLabelFont');
        const weight = rows.find(s=>s.key === 'TopLabelBold');
        assert(font && font.defaultValue === 0, `${device}: font default`);
        assert(JSON.stringify(font.configOptions.map(o=>o.value)) === JSON.stringify(support[device]), `${device}: unsupported/missing font option`);
        assert(weight && weight.defaultValue === 0 && JSON.stringify(weight.configOptions.map(o=>o.value)) === '[1,0]', `${device}: regular default and bold/regular options`);
        assert(!rows.some(s=>s.key === 'BackgroundColor'), `${device}: deleted background setting restored`);
        const english = settings.languages.eng || settings.languages.valyrian;
        const nameProfile = jungle.match(new RegExp(`^${device}\\.resourcePath = .*;resources-top-font-names/([^;\\r\\n]+)`, 'm'));
        assert(nameProfile, `${device}: missing actual title font name profile`);
        const expectedTitleFont = fs.readFileSync(path.join(root, 'resources-top-font-names', nameProfile[1], 'strings/strings.xml'), 'utf8')
            .match(/<string id="TopLabelFontDefault">([^<]+)<\/string>/)[1];
        assert(english && english.TopLabelFontDefault === expectedTitleFont &&
            settings.languages.zhs.TopLabelFontDefault === expectedTitleFont, `${device}: actual font name mismatch`);
        assert(english && english.SettingTopLabelFont === 'Top label font', `${device}: English/default title`);
        assert(settings.languages.zhs.SettingTopLabelFont === '顶部文字字体', `${device}: Chinese title`);
        for (const language of Object.keys(settings.languages)) {
            assert(settings.languages[language].TopLabelFontAvailable === support[device].join(''), `${device}: ${language} font capability mismatch`);
        }
        if (!legacy) {
            assert(!rows.some(s=>s.key === "ShowTopMoon"), `${device}: removed moon toggle restored`);
            for (const key of ["FieldTopLeft","FieldTopRight","FieldLeft","FieldCenter","FieldRight"]) {
                assert(!rows.find(s=>s.key===key).configOptions.some(o=>o.value===42), `${device}: removed moon field restored`);
            }
            for (const key of ['FieldTopLeft','FieldTopRight','FieldLeft','FieldCenter','FieldRight']) {
                assert(rows.find(s=>s.key===key).configOptions.some(o=>o.value===73), `${device}: UV field missing from ${key}`);
            }
        }
        audit.push({device, partNumber:part.number, legacy, fontOptions:support[device], settings:rows.length});
    }
}
assert(packagedParts.length === expectedParts.size && new Set(packagedParts).size === expectedParts.size, 'Package target coverage mismatch');
assert(fs.statSync(path.join(unpacked, 'manifest.sig2')).size > 0, 'Missing package signature');
// The public signing identity must remain the same as the previous store release.
const previousPub = cp.execFileSync('tar', ['-xOf', path.join(root,'releases/1.5.3/CNWatchFace-1.5.3.iq'), 'dev_key.pub']);
assert(previousPub.equals(fs.readFileSync(path.join(unpacked, 'dev_key.pub'))), 'Store signing identity changed');
const sha256 = crypto.createHash('sha256').update(fs.readFileSync(iq)).digest('hex');
const summary = {version, appId, products:products.length, targets:packagedParts.length, bytes:fs.statSync(iq).size, sha256, signingIdentityUnchanged:true, settingsPassed:true};
fs.writeFileSync(path.join(release, 'PACKAGE_AUDIT.json'), JSON.stringify({summary, checks:audit}, null, 2)+'\n');
const inputs = [];
function fingerprint(input) {
    const fullPath = path.join(root, input);
    if (fs.statSync(fullPath).isDirectory()) {
        for (const name of fs.readdirSync(fullPath)) fingerprint(path.join(input, name));
    } else {
        inputs.push({path:input.replaceAll('\\','/'), sha256:crypto.createHash('sha256').update(fs.readFileSync(fullPath)).digest('hex')});
    }
}
for (const name of fs.readdirSync(root)) {
    if (/^(source|resources)(-|$)/.test(name) && fs.statSync(path.join(root,name)).isDirectory()) fingerprint(name);
}
for (const name of ['manifest.xml','monkey.jungle','VERSION','RELEASE_NOTES.md']) fingerprint(name);
fs.writeFileSync(path.join(release, 'SOURCE_SHA256.json'), JSON.stringify(inputs, null, 2)+'\n');
console.log(JSON.stringify(summary, null, 2));
