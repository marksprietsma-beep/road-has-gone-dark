// Additive provider-neutral identity domains; GAME-78 records remain unchanged.
import {readFileSync} from 'node:fs';
import {ContentSeed,canonical,sha} from './core.mjs';
import {compatible,validateSelection} from './compatibility.mjs';
import {createContext,weightedList} from '../../vendor/content/lexicon/core/index.js';
import {areaContext,profileIndex} from './profile-context.mjs';
import {hometowns,compileWorld as compileOrigins} from './origin-world.mjs';
import {renderProfile,PROFILE_RENDERER} from './profile-text.mjs';
export const PROFILE_VERSION='trhgd-origin-profiles-2';
export const profilePack=JSON.parse(readFileSync(new URL('../../data/world_enrichment/trhgd-origin-profiles-v2.json',import.meta.url)));
export const profilePackSha=sha(canonical({pack:profilePack,base_runtime:sha(readFileSync(new URL('../../data/world_enrichment/runtime.json',import.meta.url))),renderer:PROFILE_RENDERER}));
// Cross-field source relationships supplement table prerequisites. Broad coast
// plus an unrelated river/lake port is not evidence of a maritime harbour.
const sourceRelationships={'maritime-commerce':'coastal-port',maritime:'coastal-port'};
export const profileCompatible=(row,tags,selected=[])=>compatible(row,tags,selected)&&(!sourceRelationships[row.id]||tags.has(sourceRelationships[row.id]));
function pick(seed,field,rows,tags,selected=[],preferred=[]){
 const candidates=rows.filter(r=>profileCompatible(r,tags,selected)&&!selected.some(x=>x.id===r.id||r.family&&x.family===r.family));
 if(!candidates.length)throw Error('No compatible profile choices: '+field);
 const g=weightedList(Object.fromEntries(candidates.map(r=>[r.id,(r.weight??1)*(preferred.includes(r.id)?4:1)])));
 return structuredClone(candidates.find(r=>r.id===g.generate(createContext({seed:seed.digest(field)}))));
}
const names=(rows)=>rows.map(r=>r.label).join(' and ');
function culture(ctx){
 const first=ctx.cultures[0];
 if(!first)return 'The mapped territory has no recorded cultural affiliation.';
 const next=ctx.cultures[1];
 return `${first.name} is the most widespread mapped culture${next?`; ${next.name} communities are also recorded`:''}.`;
}
function record(domain,id,name,ctx,seed,parents,publicFacts,selected){
 validateSelection(selected,new Set(ctx.tags));
 const publicRecord={...publicFacts,compact_summary:'',full_summary:''};
 const r={schema_version:2,id,domain,source:{world_id:ctx.world_id,state_id:ctx.state_id,province_id:ctx.province_id,burg_id:ctx.burg_id,cell_id:ctx.cell_id},parents,
  source_context:ctx,public:publicRecord,tags:[...new Set([...ctx.tags,...selected.map(x=>x.id)])].sort(),
  generation:{provider:'trhgd-hierarchical-lexicon',generator:PROFILE_VERSION,pack:profilePack.version,pack_sha:profilePackSha,renderer:PROFILE_RENDERER},
  provenance:{source:'source_context contains source-derived evidence and exact identities',generated:'public identity, economies, posture, customs and parent relationships are immutable TRHGD background; no mechanics'},name};
 const p={domain,id,name,public:publicRecord,render_seed:seed.digest('text')};
 publicRecord.full_summary=renderProfile(p,profilePack);
 publicRecord.compact_summary=renderProfile(p,profilePack,true);
 validateProfile(r);return r;
}
export function validateProfile(r){
 if(r.source.world_id!==r.source_context.world_id||r.generation.generator!==PROFILE_VERSION)throw Error('Profile source/version mismatch');
 const tags=new Set(r.source_context.tags),f=r.public;
 for(const id of f.economy.specialisms){const row=profilePack.economies.find(x=>x.id===id);if(!row||!profileCompatible(row,tags,f.posture?[profilePack.postures.find(x=>x.id===f.posture)]:[]))throw Error('Incompatible economy: '+id);}
 if(r.domain==='state'&&f.external_orientation==='maritime'&&!tags.has('coastal-port'))throw Error('Maritime outlook without a coastal port');
 if(r.domain==='hometown'&&/\bvillage\b/.test(f.settlement_role)&&r.source_context.settlement_class!=='village')throw Error('Village role contradicts source settlement class');
 if(r.domain==='region'){const role=profilePack.regions.find(x=>x.id===f.regional_role);if(role?.economies&&!f.economy.specialisms.every(id=>role.economies.includes(id)))throw Error('Region role/economy contradiction');}
 if(f.posture==='isolationist'&&(f.social_character==='cosmopolitan'||['welcoming','maritime'].includes(f.external_orientation)||f.economy.specialisms.includes('maritime-commerce')))throw Error('Isolationist contradiction');
 for(const row of r.source_context.cultures)if(!Number.isInteger(row.id)||row.id<=0||!row.name)throw Error('Invalid cultural source identity');
 if(/\b(?:km|kilometres?|bonus|discount|safe from|travel time)\b|<iframe|https?:/i.test(f.full_summary))throw Error('Mechanical/hidden claim');
 return true;
}
export function buildProfiles(world,origins){
 const states={},regions={},homes={},seeds=new Map();
 const root=new ContentSeed(world.base.id,'world',PROFILE_VERSION,profilePackSha);
 const stateRecords=world.source.states.filter(s=>s&&s.i>0&&!s.removed&&!s.hidden).sort((a,b)=>a.i-b.i);
 for(const s of stateRecords){
  const ctx=areaContext(world,s.i);if(!ctx.land_cells)continue;
  const seed=root.child('state:'+s.i),tags=new Set(ctx.tags);
  const posture=pick(seed,'posture',profilePack.postures,tags),social=pick(seed,'social',profilePack.social,tags,[posture]);
  const orientation=pick(seed,'orientation',profilePack.orientation,tags,[posture,social]);
  const economy=pick(seed,'economy',profilePack.economies,tags,[posture]),extra=pick(seed,'secondary-economy',profilePack.economies,tags,[posture,economy]);
  const institution=pick(seed,'institution',profilePack.institutions,tags);
  const selected=[posture,social,orientation,economy,extra,institution];
  const facts={posture:posture.id,social_character:social.id,external_orientation:orientation.id,economy:{specialisms:[economy.id,extra.id]},known_for:[institution.known],institutional_character:institution.id,
   cultural_presence:ctx.cultures.map(x=>({id:x.id,name:x.name,mapped_cells:x.mapped_cells})),religious_presence:ctx.religions,
   prose_facts:{placename:s.name,economy:names([economy,extra]),culture:culture(ctx),posture:posture.label,politics:posture.clause,social:social.clause,orientation:orientation.clause,custom:institution.label}};
  states[s.i]=record('state','state:'+s.i,s.name,ctx,seed,{world:world.base.id},facts,selected);seeds.set(s.i,seed);
 }
 for(const [key,state]of Object.entries(states)){
  const sId=Number(key),sourceProvinces=world.source.provinces.filter(p=>p&&p.i>0&&!p.removed&&!p.hidden&&p.state===sId).sort((a,b)=>a.i-b.i);
  const members=[...sourceProvinces,{i:0,name:'Unassigned districts'}];
  for(const p of members){
   const ctx=areaContext(world,sId,p.i);if(!ctx.land_cells)continue;
   const seed=seeds.get(sId).child('province:'+p.i),tags=new Set([...ctx.tags,state.public.posture]);
   const viableRoles=profilePack.regions.filter(r=>!r.economies||profilePack.economies.some(e=>r.economies.includes(e.id)&&profileCompatible(e,tags)));
   const role=pick(seed,'regional-role',viableRoles,tags),economy=pick(seed,'economy',profilePack.economies.filter(e=>!role.economies||role.economies.includes(e.id)),tags,[],state.public.economy.specialisms);
   const shared=state.public.economy.specialisms.includes(economy.id);
   const relationship={id:shared?'shared-specialism':'regional-supply',label:shared?`its ${economy.activity} gives the state’s ${economy.label} a local foundation`:`it contributes ${economy.product} to the state’s broader economy`};
   const institution=pick(seed,'institution',profilePack.institutions,tags,[],[state.public.institutional_character]);
   const regionKey=sId+':'+p.i;
   regions[regionKey]=record('region','province:'+regionKey,p.name,ctx,seed,{state:state.id},
    {regional_role:role.id,posture:state.public.posture,external_orientation:state.public.external_orientation,economy:{specialisms:[economy.id]},parent_relationship:relationship.id,institutional_character:institution.id,
     prose_facts:{placename:p.name,parent:state.name,role:role.label,economy:economy.label,relationship:relationship.label,custom:institution.label}},[role,economy,institution]);
  }
 }
 for(const b of hometowns(world)){
  const cell=world.cell(b.cell),regionKey=cell.state+':'+cell.province,state=states[cell.state],region=regions[regionKey];
  if(!state||!region)throw Error('Missing authoritative profile parent for burg '+b.i);
  const ctx=areaContext(world,cell.state,cell.province,b),tags=new Set([...ctx.tags,state.public.posture]);
  const seed=seeds.get(cell.state).child('province:'+cell.province).child('burg:'+b.i);
  const economy=pick(seed,'livelihood',profilePack.economies,tags,[],region.public.economy.specialisms),custom=pick(seed,'custom',profilePack['town-customs'],tags);
  const role=economy.role.replace(/\bvillage\b/g,ctx.settlement_class==='village'?'village':ctx.settlement_class==='town'?'town':'community');
  const social=profilePack.social.find(x=>x.id===state.public.social_character);
  // Parents describe social identity; geography remains local evidence, not inherited water/mines.
  const legacy=origins.projection.origins[b.i];
  homes[b.i]=record('hometown','burg:'+b.i,b.name,ctx,seed,{state:state.id,region:regionKey},
   {settlement_role:role,posture:state.public.posture,social_character:social.id,external_orientation:state.public.external_orientation,economy:{specialisms:[economy.id]},regional_dependency:{region_id:region.id,contribution:economy.product,status:'TRHGD-generated'},public_custom:custom.id,
    local_memory:legacy.memory,tradition:legacy.tradition,legacy_record_id:legacy.record_id,
    prose_facts:{placename:b.name,parent:region.name,role,activity:economy.activity,product:economy.product,custom:custom.label,social:social.clause}},[economy,custom]);
 }
 return {states,regions,hometowns:homes};
}
export function compileProfiles(worldPath){
 const origins=compileOrigins(worldPath),profiles=buildProfiles(origins.world,origins);
 return {world:origins.world,origins,profiles};
}
