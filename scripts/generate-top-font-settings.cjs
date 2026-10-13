// Device-specific phone selectors, using the installed SDK's official font inventory.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const devicesRoot = path.join(process.env.APPDATA, 'Garmin/ConnectIQ/Devices');
const faces = ['RobotoRegular', 'RobotoCondensedRegular', 'RobotoItalic', 'RobotoMedium'];
const labels = ['Default', 'Standard', 'Condensed', 'Italic', 'Medium'];
const junglePath = path.join(root, 'monkey.jungle');
let jungle = fs.readFileSync(junglePath, 'utf8').split('# BEGIN GENERATED TOP LABEL FONTS')[0].trimEnd();
const products = [...fs.readFileSync(path.join(root, 'manifest.xml'), 'utf8').matchAll(/<iq:product id="([^"]+)"/g)].map(m => m[1]);
const groups = new Map();
const report = {};
const routes = [];
const defaultNames = new Map();
for (const device of products) {
    const dir = path.join(devicesRoot, device);
    const simulator = JSON.parse(fs.readFileSync(path.join(dir, 'simulator.json'), 'utf8'));
    const compiler = JSON.parse(fs.readFileSync(path.join(dir, 'compiler.json'), 'utf8'));
    const sets = simulator.fonts;
    const api = fs.readFileSync(path.join(dir, `${device}.api.debug.xml`), 'utf8');
    const legacy = new RegExp(`^${device}\\.sourcePath = source-legacy`, 'm').test(jungle);
    const ids = [0];
    if (api.includes('getVectorFont') && !legacy) {
        faces.forEach((face, i) => {
            if (sets.length && sets.every(set => set.fonts.some(f => f.type === 'system_ttf' && f.name === face))) ids.push(i + 1);
        });
    }
    report[device] = ids;
    const nativeSet = sets.find(set => set.fontSet === 'ww') || sets[0];
    const nativeFont = nativeSet.fonts.find(font => font.name === (legacy ? 'small' : 'xtiny')).filename;
    let defaultName;
    if (!legacy && compiler.displayType === 'amoled' && api.includes('getVectorFont')) {
        defaultName = 'Noto Sans SC Medium';
    } else if (/ROBOTOCONDENSEDREGULAR/i.test(nativeFont)) {
        defaultName = 'Roboto Condensed Regular';
    } else if (/RobotoCondensed-Bold/i.test(nativeFont)) {
        defaultName = 'Roboto Condensed Bold';
    } else if (/ROBOTO/i.test(nativeFont)) {
        defaultName = /(?:B|BOLD)$/.test(nativeFont) ? 'Roboto Bold' : 'Roboto Regular';
    } else if (/NOTO_SANS_BOLD/i.test(nativeFont)) {
        defaultName = 'Noto Sans Bold';
    } else if (/TINY$/i.test(nativeFont)) {
        defaultName = 'Tiny';
    } else {
        throw new Error(`${device}: identify the native title font: ${nativeFont}`);
    }
    const nameGroup = defaultName.toLowerCase().replaceAll(' ', '-');
    defaultNames.set(nameGroup, defaultName);
    const namePath = `resources-top-font-names/${nameGroup}`;
    const existing = jungle.match(new RegExp(`^${device}\\.resourcePath = (.+)$`, 'm'));
    if (ids.length === 1) {
        routes.push(`${device}.resourcePath = ${existing ? existing[1].trim() : '$(base.resourcePath)'};${namePath}`);
        routes.push(`${device}.lang.zhs = resources-zhs;${namePath}/zhs`);
        continue;
    }
    const group = ids.join('');
    groups.set(group, ids);
    routes.push(`${device}.resourcePath = ${existing ? existing[1].trim() : '$(base.resourcePath)'};resources-top-fonts/${group};${namePath}`);
    routes.push(`${device}.lang.zhs = resources-zhs;resources-top-fonts/${group}/zhs;${namePath}/zhs`);
}
for (const [group, name] of defaultNames) {
    const dir = path.join(root, 'resources-top-font-names', group);
    for (const subdir of ['strings', 'zhs']) {
        fs.mkdirSync(path.join(dir, subdir), {recursive:true});
        fs.writeFileSync(path.join(dir, subdir, 'strings.xml'), `<strings>\n    <string id="TopLabelFontDefault">${name}</string>\n</strings>\n`);
    }
}
for (const [group, ids] of groups) {
    const dir = path.join(root, 'resources-top-fonts', group);
    fs.mkdirSync(path.join(dir, 'settings'), {recursive:true});
    fs.mkdirSync(path.join(dir, 'strings'), {recursive:true});
    fs.mkdirSync(path.join(dir, 'zhs'), {recursive:true});
    fs.writeFileSync(path.join(dir, 'settings/settings.xml'), `<?xml version="1.0" encoding="UTF-8"?>\n<settings>\n    <setting propertyKey="@Properties.TopLabelFont" title="@Strings.SettingTopLabelFont">\n        <settingConfig type="list">\n${ids.map(id=>`            <listEntry value="${id}">@Strings.TopLabelFont${labels[id]}</listEntry>`).join('\n')}\n        </settingConfig>\n    </setting>\n</settings>\n`);
    fs.writeFileSync(path.join(dir, 'strings/strings.xml'), `<strings>\n    <string id="TopLabelFontAvailable">${group}</string>\n</strings>\n`);
    fs.writeFileSync(path.join(dir, 'zhs/strings.xml'), `<strings>\n    <string id="TopLabelFontAvailable">${group}</string>\n</strings>\n`);
}
fs.writeFileSync(junglePath, `${jungle}\n\n# BEGIN GENERATED TOP LABEL FONTS\n# Regenerate with scripts/generate-top-font-settings.cjs after SDK device updates.\n${routes.join('\n')}\n# END GENERATED TOP LABEL FONTS\n`);
fs.mkdirSync(path.join(root, 'work'), {recursive:true});
fs.writeFileSync(path.join(root, 'work/top-font-support.json'), JSON.stringify(report, null, 2) + '\n');
console.log(`Verified ${products.length} products; ${groups.size} font option profiles and ${defaultNames.size} title font names.`);
