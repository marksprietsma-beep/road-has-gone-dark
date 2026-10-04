import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {generateCellRegion,publicRegion} from '../../../tools/regiongen/generator-v1.mjs';
import {hash} from '../../../tools/regiongen/cell-region.mjs';
const folder='research/game70', reuse=process.argv.includes('--reuse-geography');
const cases=[{slug:'albanes',world:'game-11-determinism',burgId:7,name:'Albanes',cellId:917},{slug:'batan',world:'atlas-showcase',burgId:760,name:'Batan',cellId:4354},{slug:'thilranlena',world:'atlas-showcase',burgId:68,name:'Thilranlena',cellId:1689}];
await mkdir(folder+'/regions',{recursive:true});
await mkdir(folder+'/world-art',{recursive:true});
const worldArt=[];
const worlds={};
for(const stem of ['game-11-determinism','atlas-showcase']){
 const geo=stem==='atlas-showcase'?'atlas':'game-11', fixture=`tests/worldgen/fixtures/${stem}.json`,bytes=await readFile(fixture,'utf8'),world=JSON.parse(bytes),sidecarPath=`tools/regiongen/.tmp/geography-${geo}.json`;
 if(!reuse){const result=spawnSync(process.execPath,['tools/worldgen/generate-azgaar.mjs','--seed',world.seed,'--output',`tools/regiongen/.tmp/game70-${geo}.json`,'--geometry-output',sidecarPath],{encoding:'utf8',timeout:120000});if(result.status!==0)throw Error(result.stderr);if(await readFile(`tools/regiongen/.tmp/game70-${geo}.json`,'utf8')!==bytes)throw Error('Canonical replay mismatch')}
 worlds[stem]={world,sidecar:JSON.parse(await readFile(sidecarPath)),fingerprint:hash(bytes)};
 const vegetation=await readFile(reuse ? `tests/worldgen/fixtures/${stem}.vegetation.svg` : `tools/regiongen/.tmp/game70-${geo}.vegetation.svg`);
 await writeFile(`${folder}/world-art/${stem}.vegetation.svg`,vegetation);
 worldArt.push({world:stem,fixtureSha256:hash(bytes),vegetationSha256:hash(vegetation),provenance:'Pinned accepted Azgaar generator; exact canonical world replay; presentation sidecar only'});
}
for(const c of cases){
 const {world,sidecar,fingerprint}=worlds[c.world],burg=world.settlements.find(b=>b?.i===c.burgId&&!b.removed&&!b.hidden);
 if(!burg||burg.name!==c.name||burg.cell!==c.cellId)throw Error('Source town identity mismatch');
 const town=JSON.parse(await readFile(`research/game67/samples/${c.slug}.public.json`));
 if(town.settlement.worldIdentity!==fingerprint||town.settlement.burgId!==burg.i||town.settlement.worldSeed!==world.seed)throw Error('Cross-world town data');
 const full=await generateCellRegion(world,burg.cell,fingerprint,sidecar),pub=publicRegion(full);
 const again=publicRegion(await generateCellRegion(world,burg.cell,fingerprint,sidecar));if(JSON.stringify(pub)!==JSON.stringify(again))throw Error('Nondeterministic region');
 const source=pub.source_context.source_burgs.find(b=>b.source_id===burg.i);if(!source)throw Error('Selected source burg absent');
 Object.assign(c,{fixtureSha256:fingerprint,worldSeed:world.seed,worldPosition:[burg.x,burg.y],localPosition:source.local_position,regionId:pub.id,regionFile:`${c.slug}.json`});
 await writeFile(`${folder}/regions/${c.slug}.json`,JSON.stringify(pub)+'\n');
 console.log(`PASS ${c.name}: ${c.world}, burg ${burg.i}, cell ${burg.cell}, position ${source.local_position}; deterministic public region`);
}
await writeFile(folder+'/journeys.json',JSON.stringify({schemaVersion:1,cases},null,2)+'\n');

await writeFile(folder+'/world-art/manifest.json',JSON.stringify(worldArt,null,2)+'\n');
