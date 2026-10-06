// Adapter over GAME-78 facts and compatibility, not a replacement character generator.
import {readFileSync} from 'node:fs';
import {ContentSeed,canonical,sha} from '../world_enrichment/core.mjs';
import {context} from '../world_enrichment/context.mjs';
import {withProfiles} from '../world_enrichment/profile-context.mjs';
import {generate,validateRecord,pack as foundation,find} from '../world_enrichment/framework.mjs';
import {compatible,contextTags,choose} from '../world_enrichment/compatibility.mjs';
import {createContext,weightedList} from '../../vendor/content/lexicon/core/index.js';
import {generateWord} from '../../vendor/content/lexicon/language/index.js';
import {compile} from '../../vendor/content/rant/engine.js';
import {pack,packSha,VERSION,lookup} from './pack.mjs';

const seedFor=(out,campaign,slot,variant=0)=>new ContentSeed(out.world.base.id,'playthrough:'+campaign.playthrough_id,VERSION,packSha).child('party').child('slot:'+slot).child('background:'+variant);
export function partyContext(out,campaign){
 if(campaign.world_ref?.id!==out.world.base.id)throw Error('Party world identity mismatch');
 const bid=campaign.origin?.home_burg_id,home=out.profiles.hometowns[bid];
 if(!home||home.source.state_id!==campaign.origin.state_id||home.source.province_id!==campaign.origin.province_id)throw Error('Party origin mismatch');
 if(campaign.origin_profiles&&campaign.origin_profiles.enrichment_sha!==out.profiles_descriptor.enrichment_sha)throw Error('Pinned profiles mismatch');
 const ctx=withProfiles(out.world,bid,out.profiles),tags=new Set([...contextTags(ctx),...home.source_context.tags]);
 const region=out.profiles.regions[home.parents.region];
 if(region.source_context.tags.includes('mine'))tags.add('regional-mine');
 return {ctx,tags,home,region,state:out.profiles.states[String(home.source.state_id)]};
}
function occupations(ctx,tags){
 const basics=foundation.occupations.filter(r=>compatible(r,contextTags(ctx))).map(r=>({id:r.id,label:r.key,foundation:r.id,requires:r.requires,economies:[]}));
 return [...basics,...pack.occupations].filter(r=>compatible(r,tags)&&compatible(find('occupations',r.foundation),contextTags(ctx)));
}
function occupation(seed,ctx,tags,economies,used){
 const rows=occupations(ctx,tags),fresh=rows.filter(r=>!used.includes(r.id)),candidates=fresh.length?fresh:rows;
 const groups={forestry:['woodworker','charcoal-burner','cartwright-helper'],pastoral:['herder','stable-worker'],mining:['ore-sorter','mine-cart-handler','metalworker'],fishing:['fisher','net-maker'],'river-crafts':['river-carrier','basket-maker'],boatbuilding:['ship-carpenter','rope-maker'],'maritime-commerce':['harbour-worker','sailmaker-apprentice'], 'grain-crafts':['baker','carter']};
 const preferred=new Set(economies.flatMap(id=>groups[id]??[]));
 const id=weightedList(Object.fromEntries(candidates.map(r=>[r.id,preferred.has(r.id)||r.economies.some(e=>economies.includes(e))?7:1]))).generate(createContext({seed:seed.digest('occupation')}));
 return candidates.find(r=>r.id===id);
}
export function renderBiography(member){
 const f=member.generated_facts,p=f.background;
 const values={person:member.name,home:p.birthplace.name,family:find('family',p.family).label,occupation:lookupOccupation(f.occupation_id).label,training:find('training',p.training).label,motivation:find('motivation',p.motivation).label,keepsake:find('keepsake',p.keepsake).label,livelihood:f.origin_identity.livelihood};
 const tables=Object.fromEntries(Object.entries(values).map(([name,value])=>[name,{name,subs:['default'],entries:[{forms:[value],classes:[]}]}]));
 const text=compile('[case:sentence]'+pack.biography_patterns[f.biography_form]).run({seed:member.background_id,dictionary:{tables}}).replace(/\s+/g,' ').trim();
 if(!text||/undefined|<iframe|https?:|[<>]/i.test(text))throw Error('Invalid biography');return text;
}
export function lookupOccupation(id){const row=pack.occupations.find(r=>r.id===id)??foundation.occupations.find(r=>r.id===id);if(!row)throw Error('Unknown occupation');return {...row,label:row.label??row.key};}
function member(out,campaign,slot,peopleId,roleId,variant,previous=null,others=[]){
 lookup('peoples',peopleId);lookup('roles',roleId);
 const {ctx,tags,home,region,state}=partyContext(out,campaign),root=seedFor(out,campaign,slot,variant),seed=root.child('people:'+peopleId).child('role:'+roleId);
 const job=occupation(seed,ctx,tags,[...home.public.economy.specialisms,...region.public.economy.specialisms],others.map(r=>r.generated_facts.occupation_id));
 const r=generate(ctx,'character','party:slot:'+slot+':variant:'+variant+':people:'+peopleId+':role:'+roleId,{provider:'lexicon-staged',playthrough_id:campaign.playthrough_id,role:job.foundation});
 // GAME-78 compatible tables, with a party-level preference for different lives.
 for(const field of ['family','motivation','keepsake']){
  const existing=others.map(m=>m.generated_facts.background[field]);const rows=foundation[field].filter(x=>!existing.includes(x.id));
  r.public[field]=choose(seed,field,rows.length?rows:foundation[field],tags).id;
 }
 validateRecord(r,ctx);
 const consonants=[['b','d','g','k','l','m','n','r','s','t'],['br','d','f','h','k','l','n','r','th','v'],['d','g','l','m','n','r','s','sh','t','z']][Number.parseInt(sha(canonical([ctx.culture_id,peopleId])).slice(0,8),16)%3];
 const name=generateWord({classes:{C:consonants,V:['a','e','i','o','u']},syllables:pack.name_shapes[peopleId].map(s=>[s,1]),wordShapes:[['2',3],['3',1]],joiner:''},createContext({seed:seed.digest('personal-name')}));
 const identity=campaign.characters[slot-1].id;
 const result={character_id:identity,slot,name:previous?.name_edited?previous.name:name,name_edited:previous?.name_edited??false,people_id:peopleId,role_id:roleId,background_variant:variant,background_id:identity+':background:'+sha(canonical([VERSION,packSha,variant,peopleId,roleId])).slice(0,20),origin_refs:{world_id:ctx.world.id,world_sha:ctx.world.sha256,state_id:ctx.state_id,province_id:ctx.province_id,burg_id:ctx.source_id,cell_id:ctx.cell_id,culture_id:ctx.culture_id,religion_id:ctx.religion_id},generated_facts:{schema_version:1,people_id:peopleId,occupation_id:job.id,foundation_occupation_id:job.foundation,background:r.public,origin_identity:{state_profile_id:state.id,region_profile_id:region.id,hometown_profile_id:home.id,posture:state.public.posture,livelihood:home.public.prose_facts.activity,regional_contribution:home.public.regional_dependency.contribution,local_memory:home.public.local_memory,tradition:home.public.tradition},public_relationship:{kind:'hometown-neighbours',other_character_ids:campaign.characters.filter((_,i)=>i!==slot-1).map(c=>c.id)},biography_form:slot-1,provenance:{generator:'GAME-78 production character adapter',foundation_versions:r.versions,context_tags:[...tags].sort(),naming:'Lexicon original phonotactics conditioned by independent people and source culture IDs',visibility:'character-owned public; no private generator facts'}},biography:''};
 result.generated_facts.background.name=name;
 result.generated_facts.background.naming={model:'TRHGD people/culture phonotactics',culture_id:ctx.culture_id,people_id:peopleId};
 result.biography=renderBiography(result);return result;
}
export function createParty(out,campaign,peoplesDescriptor){
 if(campaign.characters?.length!==3||new Set(campaign.characters.map(c=>c.id)).size!==3||!campaign.playthrough_id)throw Error('Exactly three existing stable adventurers required');
 const root=seedFor(out,campaign,'defaults'),roles=[...pack.roles],members=[];
 const local=out.records.hometowns[String(campaign.origin.home_burg_id)];if(!local)throw Error('Missing people presence');
 for(let slot=1;slot<=3;slot++){
  const role=root.pick('role:'+slot,roles);roles.splice(roles.findIndex(r=>r.id===role.id),1);
  const people=weightedList(Object.fromEntries(local.peoples.map(p=>[p.people_id,p.presence_weight]))).generate(createContext({seed:root.digest('people:'+slot)}));
  members.push(member(out,campaign,slot,people,role.id,0,null,members));
 }
 const party={schema_version:1,status:'draft',generator_version:VERSION,content_pack_sha:packSha,runtime_manifest_sha:sha(readFileSync(new URL('../../data/world_enrichment/runtime-party-v1.json',import.meta.url))),peoples_pin:peoplesDescriptor,members};
 validateParty(party,out,campaign);return party;
}
export function editParty(out,campaign,slot,changes){
 const party=structuredClone(campaign.party);validateParty(party,out,campaign);
 if(!Number.isInteger(slot)||slot<1||slot>3)throw Error('Invalid party slot');
 if(Object.keys(changes).some(k=>!['name','people_id','role_id','regenerate'].includes(k)))throw Error('Unsupported edit');
 let m=party.members[slot-1];
 const people=changes.people_id??m.people_id,role=changes.role_id??m.role_id;
 if(changes.regenerate||people!==m.people_id||role!==m.role_id)m=member(out,campaign,slot,people,role,m.background_variant+1,m,party.members.filter(x=>x.slot!==slot));
 if(Object.hasOwn(changes,'name')){const name=String(changes.name).trim();if(!name||name.length>48||/[\x00-\x1f<>]/.test(name))throw Error('Name must contain 1–48 readable characters');m.name=name;m.name_edited=true;}
 m.biography=renderBiography(m);party.members[slot-1]=m;party.status='draft';validateParty(party,out,campaign);return party;
}
export function validateParty(party,out,campaign){
 const {ctx,tags,home}=partyContext(out,campaign);
 if(party.schema_version!==1||!['draft','ready'].includes(party.status)||party.generator_version!==VERSION||party.content_pack_sha!==packSha||party.runtime_manifest_sha!==sha(readFileSync(new URL('../../data/world_enrichment/runtime-party-v1.json',import.meta.url)))||party.members?.length!==3||canonical(party.peoples_pin)!==canonical(out.descriptor))throw Error('Invalid party schema or pins');
 const identities=new Set();
 for(const[i,m]of party.members.entries()){
  lookup('peoples',m.people_id);lookup('roles',m.role_id);
  if(m.slot!==i+1||m.character_id!==campaign.playthrough_id+':adventurer:'+(i+1)||m.character_id!==campaign.characters[i].id||identities.has(m.character_id)||typeof m.name!=='string'||!m.name.trim()||m.name.length>48||/[\x00-\x1f<>]/.test(m.name)||!Number.isInteger(m.background_variant)||m.background_variant<0||typeof m.name_edited!=='boolean')throw Error('Invalid character identity');identities.add(m.character_id);
  const expected=m.character_id+':background:'+sha(canonical([VERSION,packSha,m.background_variant,m.people_id,m.role_id])).slice(0,20);if(m.background_id!==expected)throw Error('Invalid background identity');
  if(m.origin_refs.world_id!==ctx.world.id||m.origin_refs.burg_id!==ctx.source_id||m.origin_refs.cell_id!==ctx.cell_id||m.origin_refs.state_id!==ctx.state_id||m.origin_refs.province_id!==ctx.province_id||m.origin_refs.culture_id!==ctx.culture_id||m.origin_refs.religion_id!==ctx.religion_id)throw Error('Character source mismatch');
  const f=m.generated_facts,job=lookupOccupation(f.occupation_id);
  const fields=['name','naming','birthplace','age_band','occupation','training','family','childhood','value','habit','concern','contact','traits','keepsake','local_knowledge','first_failure','first_success','motivation','hometown_relationship'];
  if(Object.keys(f).length!==9||Object.keys(f.background).length!==fields.length||fields.some(k=>!Object.hasOwn(f.background,k)))throw Error('Unsupported public background fields');
  if(!compatible(job,tags)||f.foundation_occupation_id!==(job.foundation??job.id)||f.origin_identity.hometown_profile_id!==home.id||f.background.birthplace.id!==ctx.source_id||f.background.local_knowledge.hidden_pois.length||f.provenance.visibility!=='character-owned public; no private generator facts'||f.secret||f.background.secret)throw Error('Background contradiction or visibility leak');
  validateRecord({schema_version:2,domain:'character',scope:'playthrough:'+campaign.playthrough_id,source:{world_id:ctx.world.id,world_sha:ctx.world.sha256,cell_id:ctx.cell_id,id:ctx.source_id,kind:'settlements',state_id:ctx.state_id,province_id:ctx.province_id,culture_id:ctx.culture_id,religion_id:ctx.religion_id},versions:f.provenance.foundation_versions,public:f.background},ctx);
  if(m.biography!==renderBiography(m))throw Error('Biography/facts mismatch');
 }
 return true;
}
