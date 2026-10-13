const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
const source = fs.readFileSync(path.join(root, 'source/CNWatchFaceView.mc'), 'utf8');
const documentation = fs.readFileSync(path.join(process.env.APPDATA,
    'Garmin/ConnectIQ/Sdks/connectiq-sdk-win-9.2.0-2026-06-09-92a1605b2/doc/Toybox/Complications.html'), 'utf8');
const names = {
    bodyBattery:'BODY_BATTERY', currentElevation:'ALTITUDE', currentSpo2:'PULSE_OX',
    currentStress:'STRESS', recoveryHours:'RECOVERY_TIME'
};
for (const [method, name] of Object.entries(names)) {
    const documentedId = Number(documentation.match(new RegExp(
        `id="COMPLICATION_TYPE_${name}-const">[\\s\\S]*?<td[^>]*>COMPLICATION_TYPE_${name}</td>\\s*<td[^>]*>(\\d+)</td>`))[1]);
    const methodBody = source.split(`private function ${method}(`)[1].split('\n    private function ')[0];
    const call = methodBody.match(/complicationValue\((\d+)\)/);
    assert(call, `${method}: unsupported enums must not be resolved before the availability check`);
    assert.equal(Number(call[1]), documentedId, `${method}: type ID must match official SDK documentation`);
}
console.log('Five complication type IDs match SDK documentation; callers reach the availability guard.');
