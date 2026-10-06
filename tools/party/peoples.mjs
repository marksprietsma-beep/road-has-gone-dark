import {readFileSync,mkdirSync,writeFileSync,existsSync,renameSync,rmSync} from 'node:fs';
import {join,dirname} from 'node:path';
import {ContentSeed,canonical,sha} from '../world_enrichment/core.mjs';
import {compileProfileWorld} from '../world_enrichment/profiles-world.mjs';
import {pack,packSha,VERSION} from './pack.mjs';

export function presence(world,profiles){
 const seed=new ContentSeed(world.base.id,'world',VERSION,packSha).child('peoples');
 const all={world:{},states:{},regions:{},hometowns:{}};
 function make(key,ctx,parent=null){
  const cultures=(ctx.cultures??[]).map(c=>c.id).sort((a,b)=>a-b),tags=new Set(ctx.tags??[]);
  const root=seed.child(key).child('cultures:'+cultures.join(','));
  return {id:key,source_culture_ids:cultures,status_origin:'TRHGD-generated qualitative presence, not a census',peoples:pack.peoples.map(p=>{
   const inherited=parent?.peoples.find(x=>x.people_id===p.id)?.presence_weight??50;
   let weight=Math.round(inherited*.45)+root.pick('weight:'+p.id,Array.from({length:60},(_,i)=>i));
   if(tags.has(p.affinity)||p.affinity==='settled'&&ctx.settlement_ids?.length)weight+=12;
   weight=Math.min(100,Math.max(1,weight));
   return {people_id:p.id,presence_weight:weight,status:weight>=65?'common':weight>=30?'present':'uncommon',source_culture_ids:cultures};
  })};
 }
 const contexts=Object.values(profiles.states).map(r=>r.source_context);
 all.world[world.base.id]=make('world',{cultures:[...new Map(contexts.flatMap(c=>c.cultures).map(c=>[c.id,c])).values()],tags:[],settlement_ids:[]});
 for(const[key,r]of Object.entries(profiles.states))all.states[key]=make(r.id,r.source_context,all.world[world.base.id]);
 for(const[key,r]of Object.entries(profiles.regions))all.regions[key]=make(r.id,r.source_context,all.states[String(r.source.state_id)]);
 for(const[key,r]of Object.entries(profiles.hometowns))all.hometowns[key]=make(r.id,r.source_context,all.regions[r.parents.region]);
 return all;
}
export function compilePeoples(worldPath){
 const out=compileProfileWorld(worldPath),records=presence(out.world,out.profiles);
 const runtime=sha(readFileSync(new URL('../../data/world_enrichment/runtime-party-v1.json',import.meta.url)));
 const sidecar={schema_version:1,base_world:out.world.base,generator_version:VERSION,pack_sha:packSha,profile_enrichment_sha:out.descriptor.enrichment_sha,records};
 const bytes=canonical(sidecar)+'\n';
 const descriptor={schema_version:1,provider:'trhgd-peoples',generator_version:VERSION,content_pack_version:pack.version,content_pack_sha:packSha,base_world_id:out.world.base.id,base_world_sha:out.world.base.sha256,profiles_sha:out.descriptor.enrichment_sha,runtime_manifest_sha:runtime,enrichment_sha:sha(bytes)};
 return {...out,profiles_descriptor:out.descriptor,records,sidecar,bytes,descriptor};
}
export function publishPeoples(target,worldPath){
 const out=compilePeoples(worldPath),files={'enrichment.json':out.bytes,'descriptor.json':canonical(out.descriptor)+'\n'};
 if(existsSync(target)){for(const[name,bytes]of Object.entries(files))if(readFileSync(join(target,name),'utf8')!==bytes)throw Error('Existing peoples package is corrupt or pinned differently');return out.descriptor;}
 const pending=target+'.pending-'+process.pid;mkdirSync(dirname(target),{recursive:true});mkdirSync(pending);
 try{for(const[name,bytes]of Object.entries(files))writeFileSync(join(pending,name),bytes,{flag:'wx'});renameSync(pending,target);}catch(e){rmSync(pending,{recursive:true,force:true});throw e;}
 return out.descriptor;
}
