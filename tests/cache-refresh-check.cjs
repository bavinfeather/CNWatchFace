// Execute source-derived cache logic; this is not a device power benchmark.
const fs = require('node:fs');
const assert = require('node:assert/strict');
const source = fs.readFileSync(`${__dirname}/../source/CNWatchFaceView.mc`, 'utf8');
const sun = source.split('private function sunMoment(')[1].split('var moment = null;')[0];
const invalidation = sun.slice(sun.indexOf('var date =')).split('if (rising &&')[0].replaceAll(' as Lang.Array','');
const updateSun = new Function('state', 'conditions', 'now', `
    var { _sunCacheTick, _sunWeatherTick, _weatherCacheTick, _sunLocation,
          _sunriseCached, _sunsetCached, _cachedSunrise, _cachedSunset } = state;
    var Gregorian = { info: value => value }, Time = { FORMAT_SHORT: 0 };
    ${invalidation}
    return { _sunCacheTick, _sunWeatherTick, _weatherCacheTick, _sunLocation,
             _sunriseCached, _sunsetCached, _cachedSunrise, _cachedSunset };
`);
const day = {year:2026, month:10, day:7};
const location = (lat, lon) => ({observationLocationPosition:{toDegrees:()=>[lat,lon]}});
let state = {_sunCacheTick:-1, _sunWeatherTick:-1, _weatherCacheTick:100,
    _sunLocation:null, _sunriseCached:false, _sunsetCached:false,
    _cachedSunrise:null, _cachedSunset:null};
state = updateSun(state, location(30,120), day);
Object.assign(state, {_sunriseCached:true, _sunsetCached:true, _cachedSunrise:600, _cachedSunset:1800});
state._weatherCacheTick++;
state = updateSun(state, location(30,120), day);
assert.equal(state._cachedSunrise,600); // same location: keep despite weather refresh
state._weatherCacheTick++;
state = updateSun(state, location(31,120), day);
assert.equal(state._cachedSunrise,null);
assert.equal(state._sunriseCached,false);
Object.assign(state, {_sunriseCached:true, _sunsetCached:true, _cachedSunrise:600, _cachedSunset:1800});
state = updateSun(state, location(31,120), {...day,day:8});
assert.equal(state._cachedSunset,null); // never show yesterday's sun time
state._sunriseCached = true; // a prior unsuccessful attempt
state._weatherCacheTick++;
state = updateSun(state, location(31,120), {...day,day:8});
assert.equal(state._sunriseCached,false); // retry when weather arrives
Object.assign(state, {_cachedSunrise:600, _cachedSunset:1800});
state._weatherCacheTick++;
state = updateSun(state, null, {...day,day:8});
assert.equal(state._cachedSunrise,null); // missing location cannot retain old location's result

class Dict {
    constructor(data) { this.data=data; }
    size() { return Object.keys(this.data).length; }
    keys() { return Object.keys(this.data); }
    get(key) { return this.data[key] ?? null; }
}
const body = source.split('private function sameWeatherSnapshot(')[1]
    .split('\n    private function readWeatherCache')[0];
const same = new Function('data', '_storedWeatherSnapshot', `
    ${body.slice(body.indexOf('{')+1,body.lastIndexOf('}'))
        .replaceAll('data[key]','data.get(key)')
        .replaceAll('instanceof Lang.Array','instanceof Array')
        .replaceAll('value instanceof Lang.String',"typeof value === 'string'")
        .replaceAll('previous instanceof Lang.String',"typeof previous === 'string'")
        .replaceAll('value.equals(previous)','(value === previous)')
        .replaceAll('keys.size()','keys.length')
        .replaceAll('value.size()','value.length')
        .replaceAll('previous.size()','previous.length')}
`);
const snapshot = {observationTime:100, temperature:20, location:[30,120], observationLocationName:'杭州'};
assert.equal(same(new Dict(snapshot),null),false);
assert.equal(same(new Dict({...snapshot,location:[30,120]}),new Dict(snapshot)),true);
for (const changed of [{temperature:21},{observationTime:101},{location:[31,120]},
                      {observationLocationName:'上海'},{relativeHumidity:60}]) {
    assert.equal(same(new Dict({...snapshot,...changed}),new Dict(snapshot)),false);
}
assert.equal(same(new Dict({observationTime:100,temperature:20}),new Dict(snapshot)),false);
const settings = source.split('function onSettingsChanged() as Void {')[1].split('\n    }')[0];
for (const preserved of ['_profileCacheTick = -1','_sunCacheTick = -1','_activityDistanceCacheKey = -1']) {
    assert(!settings.includes(preserved));
}
assert(source.includes('numberProperty("AodLeftField", FIELD_HIDDEN) == FIELD_HEART'));
assert(source.includes('dc.clear();'));
console.log('PASS: sun daily/location invalidation and missing-data retry; weather write dedup; independent caches preserved; AOD HR retained.');
