const fs = require('node:fs');
const assert = require('node:assert/strict');
const read = file => fs.readFileSync(`${__dirname}/../${file}`, 'utf8');
// Exercise the actual application entry points, not just the view handler.
for (const folder of ['source', 'source-legacy']) {
    let notified = 0, updates = 0;
    class View { onSettingsChanged() { notified++; } }
    const text = read(`${folder}/CNWatchFaceApp.mc`);
    const header = 'class CNWatchFaceApp extends Application.AppBase {';
    const body = text.slice(text.indexOf(header) + header.length, text.lastIndexOf('}'))
        .replaceAll('private var ', 'var ');
    const make = new Function('AppBase', 'WatchUi', 'CNWatchFaceView', 'CNWatchFaceLegacyView',
        `${body}; return {initialize,getInitialView,onSettingsChanged};`);
    const app = make({initialize(){}}, {requestUpdate(){updates++;}}, View, View);
    app.initialize();
    app.onSettingsChanged(); // notification before view creation must be safe
    assert.equal(updates, 1);
    app.getInitialView();
    app.onSettingsChanged();
    assert.equal(notified, 1, `${folder}: settings must reach the actual view`);
}

const text = read('source/CNWatchFaceView.mc');
const body = text.split('private function sleepScore() {')[1].split('\n    private function elevationHistory')[0];
const run = new Function('state','now','score','supported', `
    var {_sleepScoreCacheDay,_sleepScoreCached,_cachedSleepScore,_sleepScoreUpdatedSeconds}=state;
    const Time={FORMAT_SHORT:0,now:()=>({value:()=>now})};
    const Gregorian={info:moment=>{
        const d=new Date((moment.value()+8*3600)*1000);
        return {year:d.getUTCFullYear(),month:d.getUTCMonth()+1,day:d.getUTCDate()};
    }};
    const supportsSleepScore=()=>supported,complicationValue=()=>score;
    const COMPLICATION_TYPE_SLEEP_SCORE=79,SLEEP_SCORE_CACHE_SECONDS=129600;
    const isNumberInRange=v=>typeof v==='number' && v>=0 && v<=100;
    const isFresh=(t,ttl,now)=>t>0 && now>=t && now-t<=ttl;
    function value(){${body.slice(0,body.lastIndexOf('}')).replaceAll('score.toNumber()','Math.trunc(score)')}}
    const result=value();
    return {result,state:{_sleepScoreCacheDay,_sleepScoreCached,_cachedSleepScore,_sleepScoreUpdatedSeconds}};
`);
const before = Date.UTC(2026,9,7,15,59)/1000;
let state = {_sleepScoreCacheDay:-1,_sleepScoreCached:false,_cachedSleepScore:null,_sleepScoreUpdatedSeconds:0};
let result=run(state,before,88,true);
assert.equal(result.result,88);
state={...result.state,_sleepScoreCached:false};
result=run(state,before+30,null,true);
assert.equal(result.result,88); // same-day transient null still falls back
result=run(result.state,before+120,null,true);
assert.equal(result.result,null); // also clear an already-true per-interval flag
assert.equal(result.state._sleepScoreUpdatedSeconds,0);
state={...result.state,_sleepScoreCached:false};
result=run(state,before+180,0,true);
assert.equal(result.result,0); // zero is valid
result=run({...result.state,_sleepScoreCached:false},before+240,null,false);
assert.equal(result.result,null);
const settings=read('source/CNWatchFaceSettings.mc');
assert(settings.includes('Application.getApp().onSettingsChanged();'), 'watch menu must notify the app');
const selector=settings.split('class CNWatchFaceSubMenuDelegate')[1]
    .split('function onSelect(')[1].split('function onBack()')[0];
const events=[];
new Function('Application','WatchUi','item','_key','_id','_menu',
    selector.slice(selector.indexOf('{')+1,selector.lastIndexOf('}')))(
    {Properties:{setValue:(key,value)=>events.push(['save',key,value])},
     getApp:()=>({onSettingsChanged:()=>events.push(['notify'])})},
    {SLIDE_IMMEDIATE:0,popView:()=>events.push(['back'])},
    {getId:()=>7},'FieldLeft','left',{refreshItem:()=>events.push(['label'])});
assert.deepEqual(events,[['save','FieldLeft',7],['notify'],['back'],['label']]);
console.log('PASS: modern/legacy settings forwarding, pre-view callback, watch menu notification, midnight sleep expiry, same-day fallback, zero and unsupported score.');
