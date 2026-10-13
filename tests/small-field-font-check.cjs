// Source-derived checks for reuse, fallback and identical temperature metrics.
const fs = require('node:fs');
const assert = require('node:assert/strict');
const source = fs.readFileSync(`${__dirname}/../source/CNWatchFaceView.mc`, 'utf8');
function body(name) {
    const start = source.indexOf(`private function ${name}(`);
    const open = source.indexOf('{', start);
    let depth = 1, end = open + 1;
    for (; depth; end++) {
        if (source[end] === '{') depth++;
        if (source[end] === '}') depth--;
    }
    return source.slice(open + 1, end - 1)
        .replace(/:(\w+)\s*=>/g, '$1:')
        .replace(/\(Graphics has :getVectorFont\)/g, '(typeof Graphics.getVectorFont === "function")')
        .replace(/\(dc.getFontHeight\(Graphics.FONT_XTINY\) \* 0.95\).toNumber\(\)/g,
            'Math.trunc(dc.getFontHeight(Graphics.FONT_XTINY) * 0.95)')
        .replace(/\.length\(\)/g, '.length');
}
// Monkey C returns null, rather than -1, for an absent substring.
const value = text => ({
    find: marker => text.includes(marker) ? text.indexOf(marker) : null,
    substring: (...args) => text.substring(...args), length: text.length,
    toString: () => text
});
function harness(amoled, fail = false) {
    let loads = 0, drawn = null;
    const Graphics = {FONT_XTINY: 0, FONT_TINY: 1, getVectorFont: options => {
        loads++; if (fail) throw Error('unavailable font'); return options;
    }};
    const dc = {getFontHeight: () => 30,
        getTextWidthInPixels: text => String(text).length,
        drawText: (x, y, font, text) => { drawn = String(text); }};
    const api = new Function('Graphics', 'isAmoledLayout', `
        var _smallFieldFont = null, _smallFieldFontChecked = false;
        var TEMPERATURE_DEGREE_MARKER = "^";
        function scalePx(value) { return value; }
        function smallFieldFont(dc) { ${body('smallFieldFont')} }
        function temperatureTextWidth(dc, value) { ${body('temperatureTextWidth')} }
        function drawTemperatureText(dc,x,y,value,justification) { ${body('drawTemperatureText')} }
        return {smallFieldFont, temperatureTextWidth, drawTemperatureText};
    `)(Graphics, () => amoled);
    return {api, dc, loads: () => loads, drawn: () => drawn};
}
const smooth = harness(true);
for (let i = 0; i < 100; i++) smooth.api.smallFieldFont(smooth.dc);
assert.equal(smooth.loads(), 1);
assert.equal(smooth.api.smallFieldFont(smooth.dc).size, 28);
assert.equal(smooth.api.temperatureTextWidth(smooth.dc, value('14^C')), 4);
smooth.api.drawTemperatureText(smooth.dc, 0, 0, value('14^C'), 0);
assert.equal(smooth.drawn(), '14°C');
const mip = harness(false);
for (let i = 0; i < 100; i++) assert.equal(mip.api.smallFieldFont(mip.dc).size, 16);
assert.equal(mip.loads(), 1);
const unavailable = harness(true, true);
for (let i = 0; i < 100; i++) assert.equal(unavailable.api.smallFieldFont(unavailable.dc), 0);
assert.equal(unavailable.loads(), 1);
console.log('PASS: one cached smooth font, MIP and missing-font fallback, matching degree metrics/drawing');
