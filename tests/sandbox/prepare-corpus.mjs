// Real Azgaar worlds + GAME-62 owned placement corpus; no fabricated geography.
import {readFileSync,writeFileSync,mkdirSync,existsSync} from 'node:fs';
import {resolve,join} from 'node:path';
import {execFileSync} from 'node:child_process';
import assert from 'node:assert/strict';
import {loadWorld,eligible} from '../../tools/world_enrichment/source.mjs';
import {generateCellRegion} from '../../tools/regiongen/generator-v1.mjs';
import {isOwnedDryLand} from '../../tools/regiongen/cell-region.mjs';
import {localContent} from '../../tools/expedition/content.mjs';
const output=resolve(process.env.GAME96_TEST_ROOT||'/tmp/game96-corpus');mkdirSync(output,{recursive:true});
const specs=[],worlds=[];
for(const source of ['tests/worldgen/fixtures/game-11-determinism.json','tests/worldgen/fixtures/atlas-showcase.json',null,null,null]){
 const index=worlds.length,seed=source?JSON.parse(readFileSync(source)).seed:['game96-thorn-v1','game96-grey-v1','game96-ashen-v1'][index-2];
 const directory=join(output,'world-'+index);mkdirSync(directory,{recursive:true});
 const path=join(directory,'world.json'),geo=join(directory,'geography.json');
 if(!existsSync(path)||!existsSync(geo))execFileSync(process.execPath,['tools/worldgen/offline-generate.mjs','--seed',seed,'--output',path,'--geometry-output',geo],{stdio:'inherit',timeout:180000});
 if(source)assert.equal(loadWorld(path).base.sha256,loadWorld(source).base.sha256,'exact preset replay');
 const w=loadWorld(path),geometry=JSON.parse(readFileSync(geo));
 worlds.push({seed:w.source.seed,sha:w.base.sha256});
 const homes=w.source.settlements.filter(eligible).filter(b=>w.cell(b.cell).state>0);
 const chosen=[],biomes=new Set();
 for(const home of homes){const name=w.record('biomes',w.cell(home.cell).biome)?.name;if(!biomes.has(name)){chosen.push(home);biomes.add(name);}if(chosen.length===6)break;}
 for(const home of homes){if(chosen.length>=8)break;if(!chosen.includes(home))chosen.push(home);}
 const upland=homes.filter(b=>w.cell(b.cell).heights>=60&&!/forest|desert|savanna/i.test(w.record('biomes',w.cell(b.cell).biome)?.name)).sort((a,b)=>w.cell(b.cell).heights-w.cell(a.cell).heights)[0];
 if(upland&&!chosen.includes(upland))chosen.push(upland);
 for(const home of chosen){
  const region=await generateCellRegion(w.source,home.cell,w.base.sha256,geometry);
  const content=localContent(w,home,region);assert(content.sites.every(s=>isOwnedDryLand(region.source_context,s.position)));
  assert.equal(JSON.stringify(content),JSON.stringify(localContent(w,home,region)),'source placement repeatability');
  const contentPath=join(directory,'home-'+home.i+'.json');writeFileSync(contentPath,JSON.stringify(content)+'\n');
  specs.push({world:path,home_id:home.i,home_name:home.name,content:contentPath,cell:home.cell,biome:w.record('biomes',w.cell(home.cell).biome)?.name,source_owned_dry_land:true});
 }
}
writeFileSync(join(output,'corpus.json'),JSON.stringify({worlds,specs},null,2)+'\n');
console.log('GAME96 GEOGRAPHIC CORPUS',JSON.stringify({worlds:worlds.length,contexts:specs.length,source_sites:specs.length*8,biomes:[...new Set(specs.map(s=>s.biome))],owned_dry_land:true}));
