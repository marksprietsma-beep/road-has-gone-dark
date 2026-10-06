// TRHGD world-derived local content. No campaign identity or knowledge in seeds.
import {ContentSeed,canonical,sha} from '../world_enrichment/core.mjs';
import {context} from '../world_enrichment/source.mjs';
import {pack,packSha,generate,find,VERSION,SCHEMA} from '../world_enrichment/framework.mjs';
import {choose,contextTags} from '../world_enrichment/compatibility.mjs';
import {render} from '../world_enrichment/text.mjs';
import {isOwnedDryLand} from '../regiongen/cell-region.mjs';
import {toLocalPoint} from '../regiongen/local-source-context.mjs';
export const LOCAL_VERSION='trhgd-expedition-v1';
export function localContent(w,home,region){
 const ctx=context(w,'settlements',home.i),cell=home.cell;
 if(region.source_context.parent_cell.source_id!==cell||region.source_context.parent_source_world_sha256!==w.base.sha256)throw Error('Mismatched local region');
 const seed=new ContentSeed(w.base.id,'world',LOCAL_VERSION,packSha,['cell:'+cell]);
 const tags=contextTags(ctx),sites=[];tags.delete("port");tags.delete("walls");
 // Parent-cell evidence does not prove a site itself is coastal, riverside or roadside.
 // Conservatively exclude geographic claims until proximity is actually supported.
 const safe=pack.purposes.filter(x=>!/(road|toll|bridge|water|cistern|mine|ore|beacon|harbour|fishing|charcoal|border|gatehouse|boat)/i.test(x.id));
 for(let slot=0;slot<8;slot++){
  const s=seed.child('site:'+slot);let p=null;
  for(let attempt=0;attempt<1000;attempt++){
   const a=[40+s.pick('x:'+attempt,Array.from({length:920},(_,i)=>i)),40+s.pick('y:'+attempt,Array.from({length:920},(_,i)=>i))];
   if(isOwnedDryLand(region.source_context,a)&&sites.every(x=>Math.hypot(x.position[0]-a[0],x.position[1]-a[1])>28)){p=a;break;}
  }
  if(!p)throw Error('No supported dry-land placement; source geometry preserved');
  const purpose=choose(s,'purpose',safe,tags),condition=choose(s,'condition',pack.conditions.filter(x=>x.facet==='walls'),tags),event=choose(s,'history',pack.events.filter(x=>['reuse','abandonment','repair'].includes(x.category)),tags);
  const id='site:'+sha(canonical([w.base.id,cell,LOCAL_VERSION,slot]));
  const f={purpose:purpose.id,conditions:[condition.id],history:[{index:0,event:'foundation-laid',state:'standing',years_before:150},{index:1,event:event.id,state:event.transition,years_before:40}],age_band:'several-generations',marker_type:'generated-local',source_name:null};
  const projection={schema_version:SCHEMA,id,domain:'site',source:{world_id:w.base.id,culture_id:ctx.culture_id},versions:{generator:VERSION,provider:'sha-staged',pack:pack.version,pack_sha:packSha},public:f};
  const history_description=render(projection,{compact:true}).text;
  const description=history_description.split(/(?<=\.) /)[0];
  sites.push({id,slot,kind:purpose.id,name:'Old '+purpose.label,position:p,world_position:[region.source_context.space.source_bounds.left+p[0]*(region.source_context.space.source_bounds.right-region.source_context.space.source_bounds.left)/1000,region.source_context.space.source_bounds.top+p[1]*(region.source_context.space.source_bounds.bottom-region.source_context.space.source_bounds.top)/1000],cell_id:cell,origin:'generated-local',source_marker_id:null,facts:f,description,history_description,secret:{record:'A repair tally remains beneath a loose stone.',truth_id:id+':tally'},provenance:{world_sha:w.base.sha256,cell_id:cell,version:LOCAL_VERSION,pack_sha:packSha,authorship:'TRHGD generated fiction; not Azgaar marker/history'}});
 }
 const homePosition=toLocalPoint([home.x,home.y],region.source_context.space.source_bounds);
 const body={schema_version:1,version:LOCAL_VERSION,world_id:w.base.id,world_sha:w.base.sha256,cell_id:cell,sites};
 return {...body,sha:sha(canonical(body)),home_id:home.i,home_position:homePosition};
}
export function initialLeads(w,home,content){
 const ctx=context(w,'settlements',home.i);
 return content.sites.slice(0,3).map((site,i)=>{
  const hook=generate(ctx,'contract','expedition:'+site.id);
  const goal=['Compare the surviving work with local accounts','Record what remains for the people at home','Look for evidence of its former use'][i];
  return {id:'lead:'+sha(canonical([content.sha,home.i,site.id])),site_id:site.id,knowledge:i===1?'rumoured':'discovered',goal,issuer:find('occupations',hook.public.issuer.role).key,hook:{generator:hook.versions,issuer:hook.public.issuer,evidence:hook.public.evidence},status:'available',origin:'generated-local'};
 });
}
export function publicView(content,progress){
 const visible=content.sites.filter(s=>['discovered','visited','investigated'].includes(progress.knowledge[s.id])).map(s=>({id:s.id,name:s.name,kind:s.kind,position:s.position,description:s.description,knowledge:progress.knowledge[s.id]}));
 const leads=progress.leads.map(l=>{const s=content.sites.find(s=>s.id===l.site_id);const known=progress.knowledge[s.id]!=='rumoured';return {id:l.id,title:known?s.name:'Rumour of old stonework',goal:l.goal,issuer:l.issuer,status:l.status,knowledge:progress.knowledge[s.id],site:known?s.id:null,clue:known?s.description:'Someone remembers old work somewhere outside the town. Its exact location is not known.'};});
 return {sites:visible,leads,home_position:content.home_position};
}
