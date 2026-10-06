import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,mkdtempSync,rmSync,writeFileSync,cpSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {compileWorld,verifyDirectory,publish,verifyRuntime,hometowns} from '../../tools/world_enrichment/origin-world.mjs';
import {ContentSeed,canonical,sha} from '../../tools/world_enrichment/core.mjs';
import {context} from '../../tools/world_enrichment/context.mjs';
import {generate,validateRecord} from '../../tools/world_enrichment/framework.mjs';
import {render} from '../../tools/world_enrichment/text.mjs';
const fixtures=['game-11-determinism','atlas-showcase'];
for(const key of fixtures)test(key+': exhaustive eligible coverage and immutable preset replay',()=>{
 const path='tests/worldgen/fixtures/'+key+'.json',before=sha(readFileSync(path));
 const a=compileWorld(path),b=compileWorld(path);
 assert.equal(canonical(a.descriptor),canonical(b.descriptor));
 assert.equal(a.enrichment,b.enrichment);assert.equal(a.publicBytes,b.publicBytes);
 assert.deepEqual(verifyDirectory('data/world_enrichment/presets/'+key,path),a.descriptor);
 const ids=hometowns(a.world).map(b=>b.i);
 assert.equal(a.sidecar.records.length,ids.length);
 assert.deepEqual(Object.keys(a.projection.origins).map(Number),ids);
 for(const r of a.sidecar.records){
  const ctx=context(a.world,'settlements',r.source.id);assert.equal(validateRecord(r,ctx),true);
  assert.equal(r.source.world_id,a.world.base.id);assert.equal(r.source.cell_id,a.world.record('settlements',r.source.id).cell);
  const p=a.projection.origins[r.source.id];
  assert.deepEqual(Object.keys(p).sort(),['record_id','burg_id','cell_id','state_id','province_id','memory','tradition','text'].sort());
  assert(p.memory.length && p.tradition.length);assert(!/undefined|[<>]/.test(p.text));
  for(const value of Object.values(r.secret))if(typeof value==='string')assert(!p.text.includes(value));
 }
 assert.equal(sha(readFileSync(path)),before);
});
test('SHA field seeds and origin child generation remain order independent',()=>{
 const a=compileWorld('tests/worldgen/fixtures/'+fixtures[0]+'.json');
 for(const r of a.sidecar.records.slice(0,20).reverse())assert.equal(canonical(generate(context(a.world,'settlements',r.source.id),'origin')),canonical(r));
 const s=new ContentSeed('world','world','v1','pack');assert.equal(s.child('a').digest('x'),s.child('a').digest('x'));assert.notEqual(s.child('a').digest('x'),s.child('b').digest('x'));
});
test('immutable publication, deterministic retries and corruption refusal',()=>{
 const dir=mkdtempSync(join(tmpdir(),'origin transaction ')),dest=join(dir,'origin-v1'),path='tests/worldgen/fixtures/'+fixtures[0]+'.json';
 try{const first=publish(dest,path);assert.deepEqual(publish(dest,path),first);writeFileSync(join(dest,'public.json'),'{}');assert.throws(()=>publish(dest,path),/validation failed/);assert.equal(readFileSync(join(dest,'public.json'),'utf8'),'{}');}finally{rmSync(dir,{recursive:true,force:true});}
});
test('vendor and production runtime pins are exact',()=>{
 verifyRuntime();
 const provenance=JSON.parse(readFileSync('vendor/content/provenance.json'));
 for(const row of provenance)assert.equal(sha(readFileSync('vendor/content/'+row.file)),row.compiled_sha256);
});
test('renderer refuses secret records and unsupported pack versions',()=>{
 const a=compileWorld('tests/worldgen/fixtures/'+fixtures[0]+'.json'),r=a.sidecar.records[0];
 assert.throws(()=>render(r),/public projection/);
 const p={schema_version:2,id:r.id,domain:r.domain,source:r.source,public:r.public,versions:{...r.versions,pack:'future'}};
 assert.throws(()=>render(p),/exact pinned/);
 assert.equal(a.world.base.id,a.descriptor.base_world_id);
});
