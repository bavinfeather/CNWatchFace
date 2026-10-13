// Verify the shallower runtime path preserves every supported year's length.
const fs = require('node:fs');
const assert = require('node:assert/strict');
const source = fs.readFileSync(`${__dirname}/../source/CNWatchFaceView.mc`, 'utf8');
const tableText = source.match(/_lunarYears[^=]*=\s*(\[[\s\S]*?\]);/)[1];
const table = new Function(`return ${tableText};`)();
const body = source.split('private function lunarYearDays(')[1]
    .split('// Select the largest Chinese')[0];
const code = body.slice(body.indexOf('{') + 1, body.lastIndexOf('}'))
    .replace(/ as Lang\.Number/g, '').replace(/\.toNumber\(\)/g, '');
const yearDays = new Function('_lunarYears', 'year', code);
assert.equal(table.length, 201);
for (let year = 1900; year <= 2100; year += 1) {
    const info = table[year - 1900];
    let expected = 0;
    for (let month = 1; month <= 12; month += 1) {
        expected += (info & (0x10000 >> month)) ? 30 : 29;
    }
    if ((info & 15) !== 0) { expected += (info & 0x10000) ? 30 : 29; }
    assert.equal(yearDays(table, year), expected, `lunar year ${year}`);
}
console.log('PASS: lunar year lengths unchanged for 1900-2100');
