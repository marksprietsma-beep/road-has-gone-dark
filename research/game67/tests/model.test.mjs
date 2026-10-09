import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {adapt,canonical,digest} from '../adapter.mjs';
import {publicExport,setKnowledge,reload,pointInPolygon,declutter} from '../model.mjs';
const load=async slug=>JSON.parse(await readFile(new URL(`../fixtures/${slug}.json`,import.meta.url)));
const counts={batan:[77,4,1],albanes:[463,32,5],thilranlena:[537,29,8]};
for (const [slug,[buildings,facilities,outdoor]] of Object.entries(counts)) {
 test(`${slug}: original counts, all explicit bindings and interior anchors`,async()=>{
  const input=await load(slug),before=canonical(input),m=adapt(input);
  assert.equal(m.buildings.length,buildings);assert.equal(m.establishments.length,facilities);
  assert.equal(m.establishments.filter(e=>e.locationType==='outdoor').length,outdoor);assert.equal(m.diagnostics.length,0);
  for(const b of m.buildings) assert.deepEqual(b.polygon,input.geojson.features.find(f=>f.properties.building_id===b.providerId).geometry.coordinates);
  for(const e of m.establishments) {
   if(e.locationType==='building') {
    const b=m.buildings.find(b=>b.id===e.buildingId);assert.equal(b.providerId,e.provenance.providerBuildingId);assert(pointInPolygon(e.sourcePosition,b.polygon));
   } else {assert.equal(e.buildingId,null);assert.equal(e.provenance.providerBuildingId,null)}
  }
  assert.equal(canonical(input),before); // adapter does not mutate original input
 });
 test(`${slug}: replay, seed input, rename independence, burg identity`,async()=>{
  const input=await load(slug),a=adapt(input),b=adapt(structuredClone(input));assert.equal(canonical(a),canonical(b));
  const renamed=structuredClone(input);renamed.name='Renamed';const c=adapt(renamed);
  assert.equal(c.settlement.id,a.settlement.id);assert.deepEqual(c.buildings,a.buildings);assert.deepEqual(c.establishments,a.establishments);
  const other=structuredClone(input);other.request.burgId++;const d=adapt(other);
  assert.notEqual(a.settlement.id,d.settlement.id);assert(!a.establishments.some(e=>d.establishments.some(f=>f.id===e.id)));
  assert.deepEqual(a.buildings.map(b=>b.polygon),d.buildings.map(b=>b.polygon));
 });
 test(`${slug}: unique IDs and serialized associations/knowledge`,async()=>{
  const m=adapt(await load(slug)),ids=[...m.buildings,...m.establishments].map(x=>x.id);assert.equal(new Set(ids).size,ids.length);
  const changed=setKnowledge(m,m.establishments[0].id,'visited');assert.deepEqual(reload(canonical(changed)),changed);
  assert.equal(m.establishments[0].knowledge,'discovered');assert.throws(()=>setKnowledge(m,'missing','visited'));
 });
 test(`${slug}: public export removes hidden facility identity, position and provider associations`,async()=>{
  const m=adapt(await load(slug)),e=m.establishments[0],hidden=setKnowledge(m,e.id,'unknown'),pub=publicExport(hidden),text=canonical(pub);
  assert(!text.includes(e.id));assert.equal(pub.establishments.length,m.establishments.length-1);
  assert(pub.buildings.every(b=>!('providerId'in b)&&!('provenance'in b)));
  assert(!('diagnostics'in pub));assert.equal(hidden.establishments[0].knowledge,'unknown');
  assert.deepEqual(pub.buildings.map(b=>b.polygon),m.buildings.map(b=>b.polygon));
  assert.equal(publicExport(setKnowledge(hidden,e.id,'visited')).establishments.length,m.establishments.length);
 });
 test(`${slug}: invalid geometry, duplicate buildings and malformed identity rejected`,async()=>{
  const s=await load(slug),building=s.geojson.features.find(f=>f.properties.layer==='building');
  let bad=structuredClone(s);bad.geojson.features.push(structuredClone(building));assert.throws(()=>adapt(bad),/Duplicate/);
  bad=structuredClone(s);bad.geojson.features.find(f=>f.properties.layer==='building').geometry.coordinates[0][0][0]=null;assert.throws(()=>adapt(bad));
  bad=structuredClone(s);bad.request.burgId=-1;assert.throws(()=>adapt(bad));
 });
}
test('actual capital guildhall, no village guildhall and real harbour facilities',async()=>{
 const b=adapt(await load('batan')),a=adapt(await load('albanes')),t=adapt(await load('thilranlena'));
 assert.deepEqual(b.establishments.map(e=>e.type).sort(),['chapel','inn','manor','well']);
 assert.equal(a.establishments.filter(e=>e.type==='guildhall').length,1);
 assert.equal(t.establishments.filter(e=>e.type==='warehouse').length,1);
 assert.equal(t.establishments.filter(e=>e.type==='pier').length,2);
 assert.equal(t.geometry.features.filter(f=>f.layer==='water').length,0);assert(t.geometry.water.length>0);
});
test('duplicate POIs, orphan references, invalid point and kind rejected explicitly',async()=>{
 const s=await load('albanes'),poi=s.geojson.features.find(f=>f.properties.layer==='poi');
 let bad=structuredClone(s);bad.geojson.features.push(poi);assert.throws(()=>adapt(bad),/Duplicate/);
 bad=structuredClone(s);bad.geojson.features.find(f=>f.properties.layer==='poi').properties.building_id='orphan';assert.throws(()=>adapt(bad),/Orphan/);
 bad=structuredClone(s);bad.geojson.features.find(f=>f.properties.layer==='poi').geometry.coordinates=[Infinity,0];assert.throws(()=>adapt(bad));
 bad=structuredClone(s);bad.geojson.features.find(f=>f.properties.layer==='poi').properties.kind=null;assert.throws(()=>adapt(bad));
});
test('point-in-polygon boundary, holes, exterior; explicit-reference fallback',async()=>{
 const rings=[[[0,0],[10,0],[10,10],[0,10],[0,0]],[[4,4],[6,4],[6,6],[4,6],[4,4]]];
 assert(pointInPolygon([1,1],rings));assert(pointInPolygon([0,3],rings));assert(!pointInPolygon([5,5],rings));assert(!pointInPolygon([-1,3],rings));
 const s=await load('albanes'),f=s.geojson.features.find(f=>f.properties.layer==='poi'&&f.properties.building_id);f.geometry.coordinates=[9999,9999];
 const m=adapt(s);assert.equal(m.diagnostics.length,1);assert.match(m.establishments.find(e=>e.provenance.providerPoiId===f.properties.poi_id).provenance.binding,/fallback/);
});
test('decluttering is deterministic, collision free, zoom-sensitive; landmark wins',async()=>{
 const m=adapt(await load('albanes')),project=p=>p.map(x=>x*3+300);
 const a=declutter(m.establishments,project),b=declutter([...m.establishments].reverse(),project);assert.deepEqual(a,b);
 for(let i=0;i<a.length;i++)for(let j=i+1;j<a.length;j++){
  const x=a[i].box,y=a[j].box;assert(!(x.x<y.x+y.w&&x.x+x.w>y.x&&x.y<y.y+y.h&&x.y+x.h>y.y));
 }
 const same=m.establishments.map(e=>({...e,position:[0,0]}));assert.equal(declutter(same,project)[0].item.type,'guildhall');
 assert(declutter(m.establishments,p=>p.map(x=>x*40)).length>=a.length);
});
test('committed samples reproduce exactly and carry explicit research knowledge scenario',async()=>{
 for(const slug of Object.keys(counts)){
  let m=adapt(await load(slug)),hidden=m.establishments.find(e=>e.type==='shop');if(hidden)m=setKnowledge(m,hidden.id,'unknown');
  m.scenario='Hypothetical research knowledge state; facilities and geometry are original source data';
  for(const [audience,data]of [['developer',m],['public',publicExport(m)]])assert.equal(await readFile(new URL(`../samples/${slug}.${audience}.json`,import.meta.url),'utf8'),canonical(data)+'\n');
 }
});
test('layout upgrade changes building namespace; unsupported model versions rejected',async()=>{
 const source=await load('batan'),old=adapt(source),changed=structuredClone(source);changed.geojson.features[0].geometry.coordinates[0][1][0]+=0.1;
 const next=adapt(changed);assert.notEqual(old.layout.revision,next.layout.revision);assert.notEqual(old.buildings[0].id,next.buildings[0].id);
 assert.throws(()=>reload('{"schemaVersion":2}'));assert.equal(digest({b:1,a:2}),digest({a:2,b:1}));
});
