import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import assert from 'node:assert/strict';
import {loadWorld,eligible} from '../../tools/world_enrichment/source.mjs';
import {generateCellRegion} from '../../tools/regiongen/generator-v1.mjs';
import {isOwnedDryLand} from '../../tools/regiongen/cell-region.mjs';
import {canonical} from '../../tools/world_enrichment/core.mjs';
import {localContent,initialLeads,publicView} from '../../tools/expedition/content.mjs';
const specs=JSON.parse(readFileSync(process.argv[2])),samples=[],cases=[],types=new Set(),prose=new Set(),goals=new Set(),start=performance.now();
let sites=0,leads=0,regions=0;
for(const spec of specs){
 const w=loadWorld(spec.world),geometry=JSON.parse(readFileSync(spec.geometry));
 const homes=w.source.settlements.filter(eligible).filter(b=>w.cell(b.cell).state>0).slice(0,Math.ceil(100/specs.length));
 for(const home of homes){
  const region=await generateCellRegion(w.source,home.cell,w.base.sha256,geometry);regions++;
  const content=localContent(w,home,region),again=localContent(w,home,region);assert.equal(canonical(content),canonical(again));
  const initial=initialLeads(w,home,content);assert.equal(canonical(initial),canonical(initialLeads(w,home,content)));
  const e={knowledge:Object.fromEntries(content.sites.map(s=>[s.id,'unknown'])),leads:initial};for(const l of initial)e.knowledge[l.site_id]=l.knowledge;
  const view=publicView(content,e),text=canonical(view),rumoured=content.sites[1];
  assert(!text.includes(rumoured.id)&&!text.includes(rumoured.name),'unknown names/IDs never enter projection');assert(!text.includes('repair tally'));
  assert.equal(view.sites.length,2);assert.equal(new Set(content.sites.map(s=>s.id)).size,8);
  for(const s of content.sites){assert(isOwnedDryLand(region.source_context,s.position));assert.equal(s.cell_id,home.cell);assert.equal(s.origin,'generated-local');assert.equal(s.source_marker_id,null);assert(!/boat|coastal|river|harbour|roadside|mine|ore-sorting/.test(s.kind));sites++;types.add(s.kind);prose.add(s.description);}
  for(const l of initial){assert(content.sites.some(s=>s.id===l.site_id));leads++;goals.add(l.goal);}
  samples.push({world:w.source.seed,home:home.name,sites:content.sites,leads:view.leads});
  for(const site of content.sites){cases.push({world:w.base.id,home:home.i,site:site.id,approaches:['survey','record','leave'],expected:{survey:'investigated; secondary rumour only if not already known',record:site.facts.purpose,leave:'unresolved'},history:site.history_description});}
 }
}
assert(sites>=500&&leads>=300&&cases.length>=300);
const docs='docs/implementation/game84';mkdirSync(docs,{recursive:true});writeFileSync(docs+'/batch-samples.json',JSON.stringify(samples,null,2)+'\n');writeFileSync(docs+'/choice-cases.json',JSON.stringify(cases,null,2)+'\n');
const m={worlds:specs.length,regions,sites,leads,choice_sets:cases.length,site_types:types.size,distinct_visible_prose:prose.size,duplicate_visible_prose:sites-prose.size,lead_goal_forms:goals.size,geographic_violations:0,knowledge_leaks:0,determinism_failures:0,elapsed_seconds:(performance.now()-start)/1000};writeFileSync(docs+'/batch-metrics.json',JSON.stringify(m,null,2)+'\n');
const list=samples.flatMap(x=>x.leads.map(l=>`${x.home}: ${l.title}. ${l.goal}. ${l.clue}`)).slice(0,50),descriptions=samples.flatMap(x=>x.sites.map(s=>`${s.name}: ${s.history_description}`)).slice(0,50),sequences=cases.slice(0,50).map(c=>`${c.site}: Survey → investigated; further rumour only if unknown; examine → ${c.expected.record}; leave → unresolved.`);
writeFileSync(docs+'/SEQUENTIAL-REVIEW.md','# Unfiltered sequential review corpus\n\n## First 50 leads\n\n'+list.map(x=>'- '+x).join('\n')+'\n\n## First 50 sites\n\n'+descriptions.map(x=>'- '+x).join('\n')+'\n\n## First 50 generated expectations (actual transactions are separately recorded)\n\n'+sequences.map(x=>'- '+x).join('\n')+'\n');console.log('PASS batch',JSON.stringify(m));
