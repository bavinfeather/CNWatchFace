// Host-side control-flow and pixel checks; not a device speed benchmark.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const source = fs.readFileSync(path.join(__dirname, '../source/CNWatchFaceView.mc'), 'utf8');
const wake = source.split('function onExitSleep() as Void {')[1].split('\n    }')[0];
const wakeStep = new Function('amoled', `
    var _lowPower = true, _dataMinute = 100, _wakeFramePending = false;
    var _heartHistoryCache = [80], _heartRateCached = true, _trendCurrentCached = true;
    var requests = 0;
    var isAmoledLayout = () => amoled;
    var WatchUi = { requestUpdate: () => requests++ };
    ${wake}
    return { _lowPower, _dataMinute, _wakeFramePending, _heartHistoryCache,
             _heartRateCached, _trendCurrentCached, requests };
`);
assert.deepEqual(wakeStep(true), {
    _lowPower: false, _dataMinute: 100, _wakeFramePending: true,
    _heartHistoryCache: [80], _heartRateCached: true, _trendCurrentCached: true, requests: 1
});
assert.deepEqual(wakeStep(false), {
    _lowPower: false, _dataMinute: -1, _wakeFramePending: false,
    _heartHistoryCache: null, _heartRateCached: false, _trendCurrentCached: false, requests: 1
});
const predicate = source.match(/var deferWakeRefresh = ([^;]+);/)[1];
const defer = new Function('_wakeFramePending', '_dataMinute', '_activityCacheDay', 'activityDay', `return ${predicate};`);
assert.equal(defer(true, 100, 20261007, 20261007), true);
assert.equal(defer(false, 100, 20261007, 20261007), false); // next frame
assert.equal(defer(true, -1, 20261007, 20261007), false); // cold start/settings
assert.equal(defer(true, 100, 20261006, 20261007), false); // midnight
assert(source.includes('if (!deferWakeRefresh && dataTick != _dataMinute)'));
assert(source.includes('if (!deferWakeRefresh && profileTick != _profileCacheTick)'));
assert(source.includes('if (!deferWakeRefresh && nowSeconds >= _weatherNextAttemptSeconds)'));
assert(source.includes('_wakeFramePending = false;'));
assert(source.includes('dc.clear();')); // never skip the full frame
const due = source.match(/if \((!deferWakeRefresh && dataTick != _dataMinute)\)/)[1];
const shouldRefresh = new Function('deferWakeRefresh', 'dataTick', '_dataMinute', `return ${due};`);
for (const period of [1, 30, 60, 300]) {
    const previousTick = Math.trunc(100000 / period);
    const expiredTick = previousTick + 1;
    assert.equal(shouldRefresh(defer(true, previousTick, 7, 7), expiredTick, previousTick), false);
    assert.equal(shouldRefresh(defer(false, previousTick, 7, 7), expiredTick, previousTick), true);
    assert.equal(shouldRefresh(defer(false, previousTick, 7, 7), previousTick, previousTick), false);
}

const drawRun = source.split('var fadeColors = _nearFadeColors as Lang.Array;')[1].split('\n        }')[0];
const paint = new Function('_nearFadeColors', 'fadeTop', '_height', 'w', 'dc', `
    var fadeColors = _nearFadeColors;
    ${drawRun}
`);
function blend(a, t) {
    return (Math.trunc(((a >> 16) & 255) * (1 - t)) << 16)
         | (Math.trunc(((a >> 8) & 255) * (1 - t)) << 8)
         | Math.trunc((a & 255) * (1 - t));
}
let cases = 0;
for (const height of [240, 260, 280, 360, 390, 416, 454, 466]) {
    for (const near of [0, 0x152532, 0xffffff, 0xff0000, 0x123456, 0x010101]) {
        const top = Math.trunc(height * .53), span = height - 1 - top;
        const colors = Array.from({ length: span + 1 }, (_, i) => blend(near, i / span * .65));
        const pixels = new Array(colors.length);
        let color, calls = 0;
        const dc = {
            setColor: c => { color = c; },
            fillRectangle: (x, y, w, h) => {
                assert.equal(x, 0); assert(h > 0); calls++;
                for (let row = y; row < y + h; row++) {
                    assert.equal(pixels[row - top], undefined); // no overlap
                    pixels[row - top] = color;
                }
            }
        };
        global.Graphics = { COLOR_TRANSPARENT: -1 };
        paint(colors, top, height, height, dc);
        assert.deepEqual(pixels, colors); // no gaps or changed colors
        assert(calls <= colors.length);
        if (height === 416 && near === 0x152532) {
            console.log(`FR265 default near gradient: ${colors.length} -> ${calls} rectangle fills`);
        }
        cases++;
    }
}
console.log(`PASS: AMOLED/MIP wake, cold start, settings, midnight, next frame; ${cases} exact-color gradient cases.`);
