#!/usr/bin/env node
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {resolve} from 'node:path';
import {generateCellRegion,publicRegion,developerRegion,renderRegion} from './generator-v1.mjs';
import {hash} from './cell-region.mjs';
const args=process.argv.slice(2),idx=args.indexOf('--output');
const output=resolve(idx<0?'review/local-region-v1':args[idx+1]);await mkdir(output,{recursive:true});
const manifest=[];
for(const [stem,geometry,seed] of [['game-11-determinism','game-11','game-11-determinism'],['atlas-showcase','atlas','atlas-showcase-06']]){
 const fixture=resolve(`tests/worldgen/fixtures/${stem}.json`),bytes=await readFile(fixture,'utf8'),world=JSON.parse(bytes),fingerprint=hash(bytes);
 const sidecarPath=resolve(`tools/regiongen/.tmp/geography-${geometry}.json`);
 if(!args.includes('--reuse-geography')){
  const replay=resolve(`tools/regiongen/.tmp/replay-${geometry}.json`);
  const result=spawnSync(process.execPath,['tools/worldgen/generate-azgaar.mjs','--seed',seed,'--output',replay,'--geometry-output',sidecarPath],{encoding:'utf8',timeout:120000});
  if(result.status!==0)throw Error(result.stderr);
  if(await readFile(replay,'utf8')!==bytes)throw Error('Canonical world replay changed');
 }
 const sidecar=JSON.parse(await readFile(sidecarPath,'utf8')),ix=id=>world.cells.ids.indexOf(id);
 const candidates=world.settlements.filter(b=>b?.i>0&&!b.hidden&&!b.removed&&ix(b.cell)>=0);
 const tests=[['shore',b=>world.cells.terrain[ix(b.cell)]===1],['river',b=>world.cells.river[ix(b.cell)]>0&&world.cells.terrain[ix(b.cell)]!==1],['highland',b=>world.cells.heights[ix(b.cell)]>=68&&world.cells.terrain[ix(b.cell)]!==1]];
 for(const [kind,test] of tests){
  const home=candidates.find(test);if(!home)throw Error('No original '+kind+' burg');
  const full=await generateCellRegion(world,home.cell,fingerprint,sidecar),pub=publicRegion(full),dev=developerRegion(full),name=`${stem}-${kind}`;
  for(const [suffix,data] of [['',pub],['.developer',dev]]){await writeFile(resolve(output,name+suffix+'.json'),JSON.stringify(data)+'\n');await writeFile(resolve(output,name+suffix+'.svg'),renderRegion(data))}
  manifest.push({name,world:stem,context:kind,burg_id:home.i,cell_id:home.cell,source_sha256:fingerprint,scale:full.scale,minor_sites:full.local_sites_v2.sites.length-1,public_minor_sites:pub.local_sites_v2.sites.length-1,rumours:pub.local_sites_v2.rumours.length,source_routes:full.source_context.source_routes.length,source_rivers:full.source_context.source_rivers.length,provider_trees:full.landscape.trees.length});
  console.log(name+' cell '+home.cell+' | sites '+(full.local_sites_v2.sites.length-1)+' | owned hexes '+full.scale.owned_dry_hex_centres);
 }
}
await writeFile(resolve(output,'manifest.json'),JSON.stringify({schema_version:1,cases:manifest},null,2)+'\n');
console.log('PASS six genuine one-cell regions; public/developer exports separated');
