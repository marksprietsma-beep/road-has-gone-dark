import assert from 'node:assert/strict';
import {readFile,writeFile} from 'node:fs/promises';
import {estimateRouteTime,formatMovingTime} from '../../tools/regiongen/route-time-scenario.mjs';
const route={status:'PREVIEW_ROUTE',route_steps:5,effort:6.875,river_crossings:[]};
const before=JSON.stringify(route);
assert.equal(estimateRouteTime(route).status,'UNSET');
for(const [preset,raw,minutes] of [[15,103.125,105],[30,206.25,210],[60,412.5,415]]){
 const result=estimateRouteTime(route,preset);assert.equal(result.raw_moving_minutes,raw);assert.equal(result.moving_minutes,minutes);
 assert.equal(result.total_journey_minutes,null);assert.equal(result.physical_km,'UNCALIBRATED');
}
assert.equal(formatMovingTime(105),'1h 45m');assert.equal(formatMovingTime(210),'3h 30m');assert.equal(formatMovingTime(60),'1h');assert.equal(formatMovingTime(5),'5m');
assert.equal(JSON.stringify(route),before);
assert.equal(estimateRouteTime({...route,river_crossings:[{}]},30).crossing_delay,'UNKNOWN');
for(const status of ['HOME_HEX_BLOCKED','TARGET_HEX_BLOCKED','DISCONNECTED_IN_WINDOW'])assert.equal(estimateRouteTime({status},30).moving_minutes,null);
assert.equal(estimateRouteTime({...route,route_steps:0,effort:0},30).status,'WITHIN_HEX_TIME_UNKNOWN');
assert.throws(()=>estimateRouteTime(route,NaN));assert.throws(()=>estimateRouteTime(route,-15));assert.throws(()=>estimateRouteTime(route,20));
assert.throws(()=>estimateRouteTime({...route,effort:Infinity},30));
assert.throws(()=>estimateRouteTime({...route,effort:0},30));
const fixtures=[];let count=0;
for(const stem of ['game-11-determinism','atlas-showcase'])for(const kind of ['shore','river','highland']){
 const name=`tools/regiongen/.tmp/contextual-${stem}-${kind}`,r=JSON.parse(await readFile(name+'.json','utf8'));
 const original=JSON.stringify(r);
 for(const route of r.hex_route_preview_v1.routes)for(const preset of [0,15,30,60]){
  fixtures.push({route,minutes_per_effort:preset,expected:estimateRouteTime(route,preset)});count++;
 }
 assert.equal(JSON.stringify(r),original);
 assert.equal(r.hex_route_preview_v1.hours,'UNCALIBRATED');
 const svg=await readFile(name+'.timing.svg','utf8');assert.ok(svg.includes('scenario timing'));assert.ok(svg.includes('crossing delays and rests excluded'));
 for(const site of r.local_sites_v2.sites)if(['hidden','rumoured'].includes(site.knowledge))assert.ok(!svg.includes(site.label));
}
for(const sample of [{...route,route_steps:0,effort:0},{status:'HOME_HEX_BLOCKED'}, {...route,river_crossings:[{}]}])for(const preset of [0,15,30,60])fixtures.push({route:sample,minutes_per_effort:preset,expected:estimateRouteTime(sample,preset)});
await writeFile('tools/regiongen/.tmp/route-time-fixtures.json',JSON.stringify(fixtures,null,2));
assert.equal(count,48);
console.log('PASS: 48 known-route timing scenarios, rounding, unset/blocked/within-hex guards, no source mutation or hidden labels; shared native parity fixtures');
