// Ten real generated worlds; original-cell-owned placements, not synthetic maps.
import {readFileSync,writeFileSync,mkdirSync,existsSync} from 'node:fs';
import {resolve,join} from 'node:path';
import {execFileSync} from 'node:child_process';
import assert from 'node:assert/strict';
import {loadWorld,eligible} from '../../tools/world_enrichment/source.mjs';
import {generateCellRegion} from '../../tools/regiongen/generator-v1.mjs';
import {isOwnedDryLand} from '../../tools/regiongen/cell-region.mjs';
import {localContent} from '../../tools/expedition/content.mjs';
const output=resolve(process.env.GAME101_TEST_ROOT),specs=[],worlds=[],unsupported=[];mkdirSync(output,{recursive:true});
for(let index=0;index<10;index++){
 const seed='game101-variety-'+String(index).padStart(2,'0'),directory=join(output,seed);mkdirSync(directory,{recursive:true});
 const path=join(directory,'world.json'),geo=join(directory,'geography.json');
 if(!existsSync(path)||!existsSync(geo))execFileSync(process.execPath,['tools/worldgen/offline-generate.mjs','--seed',seed,'--output',path,'--geometry-output',geo],{stdio:'inherit',timeout:180000});
 const replay=join(directory,'replay.json'),replayGeo=join(directory,'replay.geography.json');
 if(!existsSync(replay)||!existsSync(replayGeo))execFileSync(process.execPath,['tools/worldgen/offline-generate.mjs','--seed',seed,'--output',replay,'--geometry-output',replayGeo],{stdio:'inherit',timeout:180000});
 assert.deepEqual(readFileSync(path),readFileSync(replay),'exact independently regenerated world bytes');
 assert.deepEqual(readFileSync(geo),readFileSync(replayGeo),'exact independently regenerated geometry bytes');
 const w=loadWorld(path),geometry=JSON.parse(readFileSync(geo));worlds.push({seed,sha:w.base.sha256,replay_sha:loadWorld(replay).base.sha256});
 const homes=w.source.settlements.filter(eligible).filter(b=>w.cell(b.cell).state>0),chosen=[],biomes=new Set();
 const pending=[...homes].sort((a,b)=>w.cell(a.cell).biome-w.cell(b.cell).biome);
 // Try a different supported hometown if source geometry cannot fit eight safe sites.
 while(chosen.length<4&&pending.length){
  const next=pending.findIndex(home=>!biomes.has(w.record('biomes',w.cell(home.cell).biome)?.name));
  const home=pending.splice(next<0?0:next,1)[0];
  const region=await generateCellRegion(w.source,home.cell,w.base.sha256,geometry);let content;
  try{content=localContent(w,home,region);}catch(error){if(!String(error.message).includes('No supported dry-land placement'))throw error;unsupported.push({seed,home_id:home.i,error:error.message});continue;}
  assert(content.sites.every(s=>isOwnedDryLand(region.source_context,s.position)));
  assert.equal(JSON.stringify(content),JSON.stringify(localContent(w,home,region)),'exact source placement replay');
  chosen.push(home);biomes.add(w.record('biomes',w.cell(home.cell).biome)?.name);
  const contentPath=join(directory,'home-'+home.i+'.json');writeFileSync(contentPath,JSON.stringify(content)+'\n');
  specs.push({world:path,home_id:home.i,home_name:home.name,content:contentPath,cell:home.cell,biome:w.record('biomes',w.cell(home.cell).biome)?.name,source_owned_dry_land:true});
 }
 writeFileSync(join(output,'corpus.json'),JSON.stringify({worlds,specs,unsupported},null,2)+'\n');
 console.log('GAME101 checkpoint',worlds.length,'worlds',specs.length,'contexts');
}
assert.equal(new Set(worlds.map(w=>w.sha)).size,10);assert(specs.length>=30);
