// Sequential, reproducible cross-world review; no lucky-seed sampling.
import{readFileSync,writeFileSync,mkdirSync}from'node:fs';import{compileProfileWorld}from'../../tools/world_enrichment/profiles-world.mjs';import{canonical,sha}from'../../tools/world_enrichment/core.mjs';
import{profileIndex}from'../../tools/world_enrichment/profile-context.mjs';
const paths=process.argv.slice(2);if(paths.length<7)throw Error('Two presets and five genuine generated paths required');
const groups={states:[],regions:[],hometowns:[]},metrics=[], worlds=[];
for(const path of paths){const before=sha(readFileSync(path)),start=performance.now(),out=compileProfileWorld(path),ms=performance.now()-start;
 const idx=profileIndex(out.world);let maritime=0;
 for(const group of Object.values(out.profiles))for(const r of Object.values(group))if(r.public.economy.specialisms.includes('maritime-commerce')||r.domain==='state'&&r.public.external_orientation==='maritime'){
  if(!r.source_context.settlement_ids.some(id=>{const b=out.world.record('settlements',id);return b.port>0&&idx.water(b.cell)==='coast';}))throw Error('No co-located source coastal port: '+r.id);maritime++;
 }
 for(const r of Object.values(out.profiles.hometowns)){const b=out.world.record('settlements',r.source.burg_id);if(r.source_context.settlement_class!==b.group||b.group!=='village'&&/\bvillage\b/.test(r.public.settlement_role))throw Error('Source settlement class mismatch: '+r.id);}
 for(const key of Object.keys(groups))groups[key].push(Object.values(out.profiles[key]));
 worlds.push({path,world_id:out.world.base.id,descriptor:out.descriptor,milliseconds:ms,storage_bytes:Buffer.byteLength(out.enrichment)+Buffer.byteLength(out.publicBytes),co_located_maritime_profiles_checked:maritime});if(sha(readFileSync(path))!==before)throw Error('Source mutated');}
function roundRobin(batches){const result=[];for(let n=0;batches.some(a=>a.length>n);n++)for(const a of batches)if(a[n])result.push(a[n]);return result;}
const review={};
for(const[key,batches]of Object.entries(groups)){
 const rows=roundRobin(batches),signature=r=>canonical({economy:r.public.economy,posture:r.public.posture,orientation:r.public.external_orientation,role:r.public.regional_role??r.public.settlement_role??null,custom:r.public.public_custom??r.public.institutional_character??null,social:r.public.social_character??null});
 const counts=new Map();for(const r of rows){const sig=signature(r);counts.set(sig,(counts.get(sig)??0)+1);}
 const normalized=r=>r.public.full_summary.replaceAll(r.name,'PLACE').replaceAll(r.public.prose_facts.parent??'\u0000','PARENT').replaceAll(r.public.prose_facts.culture??'\u0000','CULTURE');
 metrics.push({domain:key,records:rows.length,distinct_fact_signatures:counts.size,distinct_prose:new Set(rows.map(normalized)).size,largest_duplicate_signature:Math.max(...counts.values()),top_repeated_signature:[...counts].sort((a,b)=>b[1]-a[1]).slice(0,3)});
 review[key]=rows.slice(0,{states:50,regions:100,hometowns:200}[key]);
 if(review[key].length<{states:50,regions:100,hometowns:200}[key])throw Error('Insufficient sequential review coverage');
}
mkdirSync('docs/implementation/game80',{recursive:true});
writeFileSync('docs/implementation/game80/batch-quality.json',JSON.stringify({worlds,metrics,review},null,2)+'\n');
const lines=['# Sequential cross-world quality review','','Round-robin source-ID order across both presets and five fresh worlds. No examples omitted for aesthetic reasons. Source-supported facts and generated identities are stored separately. This file is generated, not evidence of human acceptance.',''];
for(const[group,rows]of Object.entries(review)){lines.push('## '+group,'');for(const r of rows)lines.push(`### ${r.source.world_id.split(':')[2]} / ${r.id} / ${r.name}`,'',`Source: ${r.source_context.dominant_biome}; ${r.source_context.tags.join(', ')}. Culture IDs: ${r.source_context.cultures.map(c=>c.id).join(', ')||'unknown'}.`,'',r.public.full_summary,'');}
writeFileSync('docs/implementation/game80/SEQUENTIAL-REVIEW.md',lines.join('\n')+'\n');console.log(JSON.stringify({worlds:worlds.map(w=>({world:w.world_id,milliseconds:w.milliseconds,bytes:w.storage_bytes})),metrics},null,2));
