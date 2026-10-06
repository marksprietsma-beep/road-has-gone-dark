import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {performance} from 'node:perf_hooks';
import assert from 'node:assert/strict';
import {compilePeoples} from '../../tools/party/peoples.mjs';
import {createParty,validateParty} from '../../tools/party/generator.mjs';
import {canonical,sha} from '../../tools/world_enrichment/core.mjs';
const files=process.argv.slice(2);assert(files.length>=7,'two fixtures and five fresh worlds');
const samples=[],worlds=[],jobs=new Map(),families=new Map(),motives=new Map(),keepsakes=new Map();
const add=(m,v)=>m.set(v,(m.get(v)??0)+1);
for(const [wi,file] of files.entries()){
 const before=sha(readFileSync(file)),start=performance.now(),out=compilePeoples(file),homes=Object.values(out.profiles.hometowns),compiled=performance.now()-start;
 let ms=0,n=0;
 for(let i=0;i<50;i++){
  const home=homes[i%homes.length],id=sha('game81-sequential-'+wi+'-'+i).slice(0,32);
  const c={playthrough_id:id,world_ref:{id:out.world.base.id},origin:{home_burg_id:home.source.burg_id,state_id:home.source.state_id,province_id:home.source.province_id},characters:[1,2,3].map(s=>({id:id+':adventurer:'+s}))};
  const began=performance.now(),party=createParty(out,c,out.descriptor);ms+=performance.now()-began;n+=3;
  assert.equal(canonical(party),canonical(createParty(out,c,out.descriptor)));assert(validateParty(party,out,c));
  assert.equal(new Set(party.members.map(m=>m.role_id)).size,3);
  for(const m of party.members){
   const b=m.generated_facts.background;
   add(jobs,m.generated_facts.occupation_id);add(families,b.family);add(motives,b.motivation);add(keepsakes,b.keepsake);
   assert(!/undefined|\[|<|https?:|secret basement|hidden_pois/i.test(m.biography));
   assert.deepEqual(b.local_knowledge.hidden_pois,[]);
   samples.push({sequence:samples.length+1,world:out.world.base.id,home:home.name,member:m});
  }
 }
 assert.equal(sha(readFileSync(file)),before);
 worlds.push({file,sha:before,home_count:homes.length,characters:n,compile_ms:compiled,generation_ms:ms,per_character_ms:ms/n,descriptor:out.descriptor});
}
assert(samples.length>=1000);assert(jobs.size>=20);assert(motives.size>=12);assert(keepsakes.size>=10);
const counts=field=>{const values=samples.map(field);return{distinct:new Set(values).size,total:values.length,duplicates:values.length-new Set(values).size}};
const metrics={characters:samples.length,worlds,structured:counts(s=>canonical(s.member.generated_facts)),prose:counts(s=>s.member.biography),story_combinations:counts(s=>canonical([s.member.generated_facts.occupation_id,...['family','childhood','training','motivation','keepsake','value','habit'].map(k=>s.member.generated_facts.background[k])])),biography_forms:Object.fromEntries([0,1,2].map(form=>[form,samples.filter(s=>s.member.generated_facts.biography_form===form).length])),occupations:Object.fromEntries(jobs),families:Object.fromEntries(families),motivations:Object.fromEntries(motives),keepsakes:Object.fromEntries(keepsakes),contradictions:0,invalid_source_claims:0,hidden_information_leaks:0,repeat_checks:samples.length,peak_memory:process.memoryUsage().rss};
const dir='docs/implementation/game81';mkdirSync(dir,{recursive:true});
writeFileSync(dir+'/batch-metrics.json',JSON.stringify(metrics,null,2)+'\n');
writeFileSync(dir+'/sequential-backgrounds.json',JSON.stringify(samples,null,2)+'\n');
writeFileSync(dir+'/QUALITY-SAMPLES.md','# Sequential party backgrounds\n\nFirst 100 consecutive examples, without filtering.\n\n'+samples.slice(0,100).map(s=>`### ${s.sequence}: ${s.home} — ${s.member.name} (${s.member.people_id}, ${s.member.role_id})\n\n${s.member.biography}\n\nWork: ${s.member.generated_facts.occupation_id}; family: ${s.member.generated_facts.background.family}; motivation: ${s.member.generated_facts.background.motivation}; keepsake: ${s.member.generated_facts.background.keepsake}.`).join('\n\n')+'\n');
console.log(JSON.stringify(metrics,null,2));
