import test from 'node:test';import assert from 'node:assert/strict';
import{readFileSync,mkdtempSync,rmSync,writeFileSync}from'node:fs';import{tmpdir}from'node:os';import{join}from'node:path';
import{canonical,sha}from'../../tools/world_enrichment/core.mjs';
import{compileProfileWorld,publishProfiles,verifyProfileDirectory}from'../../tools/world_enrichment/profiles-world.mjs';
import{profilePack,buildProfiles,validateProfile,profileCompatible}from'../../tools/world_enrichment/profile-framework.mjs';
import{withProfiles,areaContext,profileIndex}from'../../tools/world_enrichment/profile-context.mjs';
import{compatible}from'../../tools/world_enrichment/compatibility.mjs';
import{generate,validateRecord}from'../../tools/world_enrichment/framework.mjs';
import{context,loadWorld}from'../../tools/world_enrichment/context.mjs';
import{render}from'../../tools/world_enrichment/text.mjs';
import{renderProfile}from'../../tools/world_enrichment/profile-text.mjs';
const path='tests/worldgen/fixtures/game-11-determinism.json';
for(const key of ['game-11-determinism','atlas-showcase'])test(key+': exact replay, hierarchy, visibility and immutable geography',()=>{
 const file='tests/worldgen/fixtures/'+key+'.json',before=sha(readFileSync(file)),a=compileProfileWorld(file),b=compileProfileWorld(file);
 assert.equal(a.enrichment,b.enrichment);assert.equal(a.publicBytes,b.publicBytes);
 assert.deepEqual(verifyProfileDirectory('data/world_enrichment/presets-profiles-v2/'+key,file),a.descriptor);
 for(const r of Object.values(a.profiles.hometowns)){
  validateProfile(r);const s=a.profiles.states[r.source.state_id],p=a.profiles.regions[r.parents.region];
  assert.equal(r.public.posture,s.public.posture);assert.equal(p.public.posture,s.public.posture);
  assert.equal(r.public.external_orientation,s.public.external_orientation);
  assert.equal(r.public.local_memory,a.origins.projection.origins[r.source.burg_id].memory);
  for(const c of r.source_context.cultures)assert.equal(a.world.record('cultures',c.id).name,c.name);
 }
 for(const group of Object.values(a.projection).filter(x=>x&&typeof x==='object'))for(const row of Object.values(group)){
  assert(!row.secret&&!row.source_context&&!row.provenance);assert(!/<iframe|https?:|\b(?:km|bonus|discount|travel time)\b/i.test(row.full_summary));
  assert(!/\ba (?:ambitious|inward-looking|outward-looking)\b/i.test(row.full_summary));
 }
 assert.equal(sha(readFileSync(file)),before);
});
test('prerequisites and contradictions refuse unsupported economies and politics',()=>{
 const row=id=>profilePack.economies.find(x=>x.id===id),tags=new Set();
 for(const id of ['forestry','fishing','maritime-commerce','shipbuilding','mining'])assert.equal(compatible(row(id),tags),false);
 tags.add('port');tags.add('forest');assert.equal(compatible(row('shipbuilding'),tags),false);tags.add('lake');assert.equal(compatible(row('shipbuilding'),tags),true);
 tags.add('coast');assert.equal(compatible(row('maritime-commerce'),tags,[{id:'isolationist'}]),false);
 const a=compileProfileWorld(path),r=structuredClone(Object.values(a.profiles.hometowns)[0]);r.source_context.tags=[];r.public.economy.specialisms=['mining'];assert.throws(()=>validateProfile(r),/Incompatible economy/);
 r.public.economy.specialisms=['household-crafts'];r.public.posture='isolationist';r.public.social_character='cosmopolitan';assert.throws(()=>validateProfile(r),/Isolationist/);
 const region=structuredClone(Object.values(a.profiles.regions)[0]);region.source_context.tags=['river','farmland'];region.public.posture='peaceful';region.public.regional_role='farming-belt';region.public.economy.specialisms=['fishing'];assert.throws(()=>validateProfile(region),/Region role\/economy/);
});
test('source context ignores hidden mines and retains unknown religion/culture',()=>{
 const a=compileProfileWorld(path),home=Object.values(a.profiles.hometowns)[0],b=a.world.record('settlements',home.source.burg_id);
 const baseline=areaContext(a.world,home.source.state_id,home.source.province_id,b);
 const fresh=loadWorld(path);fresh.source.markers.push({i:999999,cell:b.cell,type:'mines',hidden:true,name:'secret mine'});
 const ctx=areaContext(fresh,home.source.state_id,home.source.province_id,fresh.record('settlements',b.i));
 assert.deepEqual(ctx.tags,baseline.tags);assert(ctx.provenance.cultures.includes('not population'));
 const unknown=loadWorld(path);unknown.source.cells.culture[b.cell]=999999;unknown.source.cells.religion[b.cell]=0;
 const missing=areaContext(unknown,home.source.state_id,home.source.province_id,unknown.record('settlements',b.i));assert.deepEqual(missing.cultures,[]);assert.deepEqual(missing.religions,[]);
});
test('ocean coast and inland port cannot combine into invented maritime commerce',()=>{
 const a=compileProfileWorld(path),idx=profileIndex(a.world),maritime=profilePack.economies.find(r=>r.id==='maritime-commerce');
 const tags=new Set(['coast','port']);assert.equal(compatible(maritime,tags),true);assert.equal(profileCompatible(maritime,tags),false);
 tags.add('coastal-port');assert.equal(profileCompatible(maritime,tags),true);
 for(const id of [5,14]){
  const r=a.profiles.states[id];assert(r.source_context.tags.includes('coast')&&r.source_context.tags.includes('port'));
  assert(!r.source_context.tags.includes('coastal-port'));assert(!r.public.economy.specialisms.includes('maritime-commerce'));
 }
 for(const group of Object.values(a.profiles))for(const r of Object.values(group))if(r.public.economy.specialisms.includes('maritime-commerce'))assert(r.source_context.settlement_ids.some(id=>{const b=a.world.record('settlements',id);return b.port>0&&idx.water(b.cell)==='coast';}));
});
test('hometown livelihood wording preserves recorded town, village and fort classes',()=>{
 const a=compileProfileWorld(path);let towns=0,forts=0;
 for(const r of Object.values(a.profiles.hometowns)){
  const b=a.world.record('settlements',r.source.burg_id);assert.equal(r.source_context.settlement_class,b.group);
  if(b.group!=='village')assert(!/\bvillage\b/.test(r.public.settlement_role));
  if(b.group==='town')towns++;if(b.group==='fort')forts++;
 }
 assert(towns>0&&forts>0);
 const r=structuredClone(Object.values(a.profiles.hometowns).find(r=>r.source_context.settlement_class==='town'));
 r.public.settlement_role='farming village';assert.throws(()=>validateProfile(r),/source settlement class/);
});
test('state order, sibling order and unrelated region addition do not reroll existing profiles',()=>{
 const a=compileProfileWorld(path);a.world.source.states.reverse();a.world.source.provinces.reverse();a.world.source.settlements.reverse();
 assert.equal(canonical(buildProfiles(a.world,a.origins)),canonical(a.profiles));
 // New uninhabited sibling record has no source cells; cannot alter another profile.
 a.world.source.provinces.push({i:999999,state:18,name:'Uninhabited test sibling'});
 assert.equal(canonical(buildProfiles(a.world,a.origins)),canonical(a.profiles));
});
test('immutable publication and retries never overwrite corrupt or historical packages',()=>{
 const temp=mkdtempSync(join(tmpdir(),'profiles immutable ')),dest=join(temp,'profiles-v2');
 try{const d=publishProfiles(dest,path);assert.deepEqual(publishProfiles(dest,path),d);writeFileSync(join(dest,'public.json'),'{}');assert.throws(()=>publishProfiles(dest,path),/validation failed/);assert.equal(readFileSync(join(dest,'public.json'),'utf8'),'{}');}finally{rmSync(temp,{recursive:true,force:true});}
});
test('all dormant GAME-78 domains remain functional with hierarchical context',()=>{
 const a=compileProfileWorld(path),id=Number(Object.keys(a.profiles.hometowns)[0]),ctx=withProfiles(a.world,id,a.profiles);
 assert(ctx.profile_context.state.economy.specialisms.length);assert(ctx.profile_context.hometown.economy.specialisms.length);
 assert(ctx.profile_tags.every(t=>/^(state|region|hometown):/.test(t)));assert(!ctx.profile_tags.some(t=>/:(coast|coastal-port|port|mine|river|lake)$/.test(t)),'parent geography is not inherited through profile tags');
 for(const domain of ['origin','character','npc','mundane','rare','contract','group']){
  const r=generate(ctx,domain,'game80-smoke',{playthrough_id:'game80-test'});validateRecord(r,ctx);
  const p={schema_version:r.schema_version,id:r.id,domain:r.domain,source:r.source,public:r.public,versions:r.versions};
  assert(render(p).text.length>30);if(['mundane','rare'].includes(domain))assert(r.public.ownership.length>=2);
 }
 const marker=a.world.source.markers.find(m=>m&&!m.hidden&&!m.removed&&m.type==='ruins');assert(marker);
 const c=context(a.world,'markers',marker.i),r=generate(c,'site');validateRecord(r,c);assert(r.public.history.length>=2);
 assert(render({schema_version:r.schema_version,id:r.id,domain:r.domain,source:r.source,public:r.public,versions:r.versions}).text.length>30);
});
test('profile renderer refuses private records and unknown templates',()=>{
 const a=compileProfileWorld(path),r=Object.values(a.profiles.states)[0];assert.throws(()=>renderProfile(r,profilePack),/allowlisted/);
 const p={domain:r.domain,id:r.id,name:r.name,public:{...r.public,secret:'hidden'},render_seed:'test'};assert.throws(()=>renderProfile(p,profilePack),/allowlisted/);
});
