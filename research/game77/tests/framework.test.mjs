import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync, mkdtempSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {resolve, dirname, join} from 'node:path';
import {fileURLToPath} from 'node:url';
import {ContentSeed,loadPack,canonical,sha,writeImmutable,verify} from '../src/core.mjs';
import {loadWorld,context,eligible} from '../src/context.mjs';
import {generate,envelope,validateRecord} from '../src/generator.mjs';
import {render,renderingArtifact} from '../src/text.mjs';
import {project,originPayload} from '../src/visibility.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../../..');
const fixture=resolve(root,'tests/worldgen/fixtures/game-11-determinism.json');
const w=loadWorld(fixture),p=loadPack(resolve(root,'research/game77/packs/trhgd-original-v1.json'));
const c=context(w,'settlements',771),site=context(w,'markers',51);
const make=(type,instance='0')=>generate(type,type==='site'?site:c,p,{instance,playthrough_id:'qa-playthrough'});
const snapshot=sha(readFileSync(fixture));

test('hierarchical seeds: no path ambiguity, independent fields and siblings',()=>{
 const s=new ContentSeed(w.base.id,'world','v1',p.digest);
 assert.notEqual(s.child('a/b').digest('x'),s.child('a').child('b').digest('x'));
 const value=s.child('item:17').pick('material',[1,2,3,4,5]);
 s.child('item:18').pick('material',[1,2,3]);s.child('item:17').pick('unused',[0,1]);
 assert.equal(value,s.child('item:17').pick('material',[1,2,3,4,5]));
 assert.throws(()=>s.child(''));assert.throws(()=>s.pick('x',[]));
 assert.throws(()=>canonical({x:undefined}));assert.throws(()=>canonical(NaN));
});
test('five domains byte-repeat, order-independent record envelopes',()=>{
 const types=['site','origin','mundane-item','rare-item'];
 const a=types.map(t=>make(t)),b=[...types].reverse().map(t=>make(t));
 assert.equal(canonical(envelope(w.base,p,a)),canonical(envelope(w.base,p,b)));
 for(const r of a){assert.equal(canonical(r),canonical(make(r.type)));assert.equal(render(r),render(make(r.type)));}
 assert.notEqual(make('character').seed,generate('character',c,p,{playthrough_id:'another-game'}).seed);
 assert.throws(()=>generate('character',c,p));
 assert.throws(()=>envelope(w.base,p,[make('origin'),make('character')]));
 assert.equal(envelope(w.base,p,[make('character')],{scope:'playthrough:qa-playthrough'}).scope,'playthrough:qa-playthrough');
 const existing=make('rare-item','17');make('rare-item','18');assert.deepEqual(existing,make('rare-item','17'));
 assert.notEqual(make('origin','1').seed,make('origin','2').seed);
});
test('both genuine fixtures and all eligible towns: coherence and stable source IDs',()=>{
 let count=0;
 for(const key of ['game-11-determinism','atlas-showcase']){
  const path=resolve(root,`tests/worldgen/fixtures/${key}.json`), world=loadWorld(path), before=sha(readFileSync(path));
  for(const b of world.source.settlements.filter(eligible)){
   const ctx=context(world,'settlements',b.i);
   for(const n of ['0','1','2']){
    const r=generate('character',ctx,p,{playthrough_id:'batch',instance:n});
    assert.equal(r.source.cell_id,b.cell);assert.equal(r.source.world_id,world.base.id);
    assert.equal(r.facts.birthplace.burg_id,b.i);validateRecord(r);
    assert.equal(render(r).includes('undefined'),false);assert.equal(render(r).includes('null'),false);
    if(!(ctx.port.value>0)) assert.doesNotMatch(r.facts.formative_role,/harbour|dock|sailor/);
    const town=generate('origin',ctx,p,{instance:n});assert.equal(originPayload(envelope(world.base,p,[town]),b.i).world_id,world.base.id);
    count++;
   }
  }
  assert.equal(sha(readFileSync(path)),before);
 }
 console.log(JSON.stringify({batch_character_contexts:count,fixtures:2}));assert.ok(count>1000);
});
test('explicit negative contradictions rejected; unknown stays unknown',()=>{
 const r=make('character');r.facts.formative_role='lifelong dockworker';r.context.port.value=null;assert.throws(()=>validateRecord(r));
 const opposed=make('character');opposed.facts.dominant_trait=['cowardly','fearless'];assert.throws(()=>validateRecord(opposed));
 const item=make('mundane-item');item.facts.material='paper';assert.throws(()=>validateRecord(item));
 const anchored=make('site');anchored.source.cell_id++;assert.throws(()=>validateRecord(anchored));
 assert.equal(c.coast.value,null);assert.equal(c.coast.status,'unknown');
 assert.throws(()=>generate('site',c,p));assert.throws(()=>generate('origin',site,p));
});
test('source visibility: hidden/removed sources blocked; dungeon only existence/provenance',()=>{
 const copy=loadWorld(fixture);copy.record('settlements',771).hidden=true;assert.throws(()=>context(copy,'settlements',771));
 copy.record('settlements',771).hidden=false;copy.record('settlements',771).removed=true;assert.throws(()=>context(copy,'settlements',771));
 const d=context(w,'markers',32);assert.equal(d.source_visibility,'hidden');assert.match(d.source_flavour.note,/iframe/);assert.equal(d.source_flavour.dungeon_seed,'game-11-determinism5901');
 const r=generate('site',d,p);assert.equal(project(r),null);assert.doesNotMatch(render(r),/https:|iframe|watabou/i);
});
test('knowledge projections: rumours hide verdict, secrets need exact reveal token',()=>{
 const r=make('site');assert.equal(project(r),null);
 const publicView=project(r,{known_entities:[r.id]});assert.deepEqual(publicView.rumours,[]);assert.equal(publicView.discoveries,undefined);
 const rumoured=project(r,{known_entities:[r.id],heard_rumours:[r.rumours[0].id]});assert.equal(rumoured.rumours.length,1);assert.equal(rumoured.rumours[0].verdict,undefined);
 assert.equal(rumoured.rumours[0].truth_fields,undefined);
 assert.doesNotMatch(canonical(publicView),/damaged tally|repair materials|lower_room|source_flavour|verdict|underground/);
 const discovered=project(r,{known_entities:[r.id],discovered_tokens:[r.secret.reveal_token]});assert.equal(discovered.discoveries.lower_room,true);
 assert.equal(project(make('character')),null);
 assert.ok(project(make('character'),{playthrough_id:'qa-playthrough'}));
});
test('origin allowlist cannot leak injected secret or hidden POI names',()=>{
 const origin=make('origin'), hidden=make('site');hidden.context.display_name='HIDDEN_POI_SENTINEL';origin.secret={text:'SECRET_SENTINEL'};
 const payload=originPayload(envelope(w.base,p,[hidden,origin]),771);
 assert.doesNotMatch(canonical(payload),/HIDDEN_POI_SENTINEL|SECRET_SENTINEL|rumour|source_flavour|secret/);
 assert.equal(payload.label,'Local memory');assert.equal(originPayload(envelope(w.base,p,[origin]),999999),null);
});
test('version, tamper and immutable sidecar collision boundaries',()=>{
 const data=envelope(w.base,p,[make('origin')]);verify(data,w.base);
 const altered=structuredClone(data);altered.records[0].facts.local_memory='tampered';assert.throws(()=>verify(altered,w.base));
 assert.throws(()=>verify(data,{...w.base,id:'other-world'}));
 const crossed=make('origin');crossed.source.world_id='other-world';assert.throws(()=>envelope(w.base,p,[crossed]));
 const newPack={pack:{...p.pack,version:'research-2'},digest:sha(canonical({...p.pack,version:'research-2'}))};
 const upgrade=envelope(w.base,newPack,[generate('origin',c,newPack)]);
 assert.notEqual(data.enrichment_sha,upgrade.enrichment_sha);assert.equal(data.base_world.id,upgrade.base_world.id);
 const beforeRender=canonical(data);const prose=renderingArtifact(data);const displayEdit=renderingArtifact(data,{rendererVersion:'future',renderRecord:r=>'Local memory: '+render(r)});assert.equal(canonical(data),beforeRender);assert.notEqual(prose.rendering_sha,displayEdit.rendering_sha);assert.equal(data.base_world.id,w.base.id);assert.equal(data.enrichment_sha,envelope(w.base,p,[make('origin')]).enrichment_sha);assert.notEqual(canonical(prose),canonical(displayEdit));
 const badVersion=structuredClone(data);badVersion.generator_version='unknown';const {enrichment_sha,...payload}=badVersion;badVersion.enrichment_sha=sha(canonical(payload));assert.throws(()=>verify(badVersion,w.base));
 const tmp=mkdtempSync(join(tmpdir(),'game77-sidecar-')),path=join(tmp,'enrichment.json');assert.throws(()=>writeImmutable(path,altered));writeImmutable(path,data);writeImmutable(path,data);assert.throws(()=>writeImmutable(path,upgrade));assert.equal(readFileSync(path,'utf8'),canonical(data)+'\n');
 assert.equal(sha(readFileSync(fixture)),snapshot);
});
test('display-name edits preserve seed paths and structured fictional facts',()=>{
 const renamed={...c,display_name:'Another display label'};
 const a=generate('character',c,p,{playthrough_id:'x'}),b=generate('character',renamed,p,{playthrough_id:'x'});
 assert.equal(a.id,b.id);assert.equal(a.seed,b.seed);assert.deepEqual(a.facts,b.facts);
 assert.notEqual(render(a),render(b));
});
