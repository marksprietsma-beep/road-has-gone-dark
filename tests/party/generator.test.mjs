import test from 'node:test';import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {canonical,sha} from '../../tools/world_enrichment/core.mjs';
import {compilePeoples,presence} from '../../tools/party/peoples.mjs';
import {createParty,editParty,validateParty} from '../../tools/party/generator.mjs';
import {pack} from '../../tools/party/pack.mjs';
const file='tests/worldgen/fixtures/game-11-determinism.json',before=sha(readFileSync(file)),out=compilePeoples(file);
const home=Object.values(out.profiles.hometowns)[0];
const campaign=(id='test-campaign')=>({playthrough_id:id,world_ref:{id:out.world.base.id},origin:{home_burg_id:home.source.burg_id,state_id:home.source.state_id,province_id:home.source.province_id},characters:[1,2,3].map(n=>({id:id+':adventurer:'+n}))});
test('presence is deterministic, all peoples selectable, culture is independent',()=>{
 assert.equal(canonical(presence(out.world,out.profiles)),canonical(out.records));
 const cultured=Object.values(out.records.hometowns).filter(r=>r.source_culture_ids.length);
 assert(cultured.length>1);assert(cultured.every(r=>r.peoples.length===8));
 assert(new Set(cultured.map(r=>r.source_culture_ids.join(','))).size>1);
 assert.equal(new Set(cultured.flatMap(r=>r.peoples.map(p=>p.people_id))).size,8);
 assert(new Set(cultured.map(r=>canonical(r.peoples.map(p=>[p.people_id,p.status])))).size>1);
 const profiles=structuredClone(out.profiles);for(const group of Object.values(profiles))for(const r of Object.values(group)){r.name='RENAMED';r.source_context.cultures.forEach(c=>c.name='RENAMED');}
 assert.equal(canonical(presence(out.world,profiles)),canonical(out.records));
 for(const key of Object.keys(profiles))profiles[key]=Object.fromEntries(Object.entries(profiles[key]).reverse());
 assert.equal(canonical(presence(out.world,profiles)),canonical(out.records));
});
test('three stable members, repeated generation, different roles/lives/forms',()=>{
 const c=campaign(),p=createParty(out,c,out.descriptor);
 assert.equal(canonical(p),canonical(createParty(out,c,out.descriptor)));assert.equal(p.members.length,3);
 for(const field of ['role_id','character_id'])assert.equal(new Set(p.members.map(m=>m[field])).size,3);
 for(const field of ['occupation_id','biography_form'])assert.equal(new Set(p.members.map(m=>m.generated_facts[field])).size,3);
 for(const field of ['family','motivation','keepsake'])assert.equal(new Set(p.members.map(m=>m.generated_facts.background[field])).size,3);
 assert(p.members.every(m=>m.origin_refs.burg_id===home.source.burg_id&&!m.generated_facts.secret));
});
test('name edits preserve identity; deterministic reroll retains manual name and siblings',()=>{
 const c=campaign();c.party=createParty(out,c,out.descriptor);
 let p=editParty(out,c,2,{name:'Marked Name'});assert.equal(p.members[1].character_id,c.party.members[1].character_id);assert.equal(p.members[1].background_id,c.party.members[1].background_id);assert(p.members[1].biography.includes('Marked Name'));
 c.party=p;const a=editParty(out,c,2,{regenerate:true}),b=editParty(out,c,2,{regenerate:true});assert.equal(canonical(a),canonical(b));assert.equal(a.members[1].background_variant,1);assert.equal(a.members[1].name,'Marked Name');
 const ancestry=editParty(out,c,2,{people_id:c.party.members[1].people_id==='human'?'dwarf':'human'});assert.equal(ancestry.members[1].name,'Marked Name');
 assert.equal(canonical(a.members[0]),canonical(c.party.members[0]));assert.equal(canonical(a.members[2]),canonical(c.party.members[2]));
});
test('all eight people and four role IDs accepted without rarity restrictions',()=>{
 const c=campaign();c.party=createParty(out,c,out.descriptor);
 for(const people of pack.peoples)for(const role of pack.roles){const p=editParty(out,c,1,{people_id:people.id,role_id:role.id});assert.equal(p.members[0].people_id,people.id);assert(validateParty(p,out,c));}
});
test('invalid identities, versions, incomplete party, secret leak and unsupported IDs refused',()=>{
 const c=campaign(),p=createParty(out,c,out.descriptor);
 for(const change of [p=>p.members.pop(),p=>p.secret='unsupported',p=>p.members[0].secret='unsupported',p=>p.members[0].origin_refs.world_sha='bad',p=>p.members[0].background_variant=Number.MAX_SAFE_INTEGER+1,p=>p.members[0].character_id='bad',p=>p.members[0].people_id='bad',p=>p.members[0].role_id='bad',p=>p.members[0].generated_facts.background.local_knowledge.hidden_pois.push('secret'),p=>p.members[0].origin_refs.burg_id=99999,p=>p.members[0].biography='wrong',p=>p.peoples_pin.enrichment_sha='bad']){const q=structuredClone(p);change(q);assert.throws(()=>validateParty(q,out,c));}
 assert.equal(sha(readFileSync(file)),before);
});
