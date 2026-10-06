// Independent integrity validation; no generator/runtime dependency.
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
const root='research/game78-integration/data/',read=p=>JSON.parse(readFileSync(p,'utf8'));
const hash=b=>createHash('sha256').update(b).digest('hex');
// Same canonical serialization contract as GAME-77; not a competing world model.
const canonical=v=>v===null||typeof v!=='object'?JSON.stringify(v):Array.isArray(v)?'['+v.map(canonical).join(',')+']':'{'+Object.keys(v).sort().map(k=>JSON.stringify(k)+':'+canonical(v[k])).join(',')+'}';
const m=read(root+'manifest.json'),p=read(root+'public-origins.json');
assert.equal(hash(readFileSync(root+'public-origins.json')),m.public_sha256);
assert.equal(p.entries.length,3);
let checks=2;
for(const [key,file]of Object.entries(m.world_sidecars)){
 const side=read(root+file),{enrichment_sha,...payload}=side;
 const raw=hash(readFileSync('tests/worldgen/fixtures/'+key+'.json'));
 assert.equal(side.base_world.sha256,raw);assert.equal(hash(canonical(payload)),enrichment_sha);
 assert.equal(side.schema_version,2);assert.equal(side.scope,'world');assert.equal(side.content_pack_sha,m.pack_sha);checks+=5;
 for(const r of side.records){
  assert.equal(r.source.world_id,side.base_world.id);assert.equal(r.source.world_sha,raw);assert.equal(r.domain,'origin');assert.equal(r.versions.pack_sha,m.pack_sha);assert.equal(r.scope,'world');
  const fact=m.facts.find(f=>f.world_id===r.source.world_id&&f.burg_id===r.source.id),row=p.entries.find(f=>f.world_id===r.source.world_id&&f.burg_id===r.source.id);
  assert.equal(fact.memory_event,r.public.memory.event);assert.equal(fact.tradition,r.public.tradition.practice);assert.equal(row.enrichment_sha,enrichment_sha);assert.equal(row.record_id,r.id);assert.equal(row.text,fact.expected_text);assert.equal(Object.keys(row).length,8);assert.ok(!JSON.stringify(row).includes(r.secret.memory_detail));checks+=12;
 }
}
console.log('PASS: GAME-78 independent sidecar/public integrity '+checks+' assertions');
