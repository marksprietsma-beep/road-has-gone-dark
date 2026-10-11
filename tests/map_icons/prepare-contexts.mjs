import {readFileSync,writeFileSync,mkdirSync,existsSync} from 'node:fs';
import {resolve,join} from 'node:path';
import {execFileSync} from 'node:child_process';
import assert from 'node:assert/strict';
import {sha} from '../../tools/world_enrichment/core.mjs';
const base=resolve(process.env.GAME98_TEST_ROOT),helper=resolve(process.env.GAME76_HELPER_ROOT);
const node=join(helper,process.platform==='win32'?'node.exe':'node');
const regions=JSON.parse(readFileSync('tests/map_icons/contexts.json')).regions;
mkdirSync(base,{recursive:true});
const rows=[];
for(const spec of regions){
 const folder=join(base,spec.seed);mkdirSync(folder,{recursive:true});
 const world=join(folder,'world.json');
 if(!existsSync(world))execFileSync(node,[join(helper,'tools/worldgen/helper-entry.mjs'),'--seed',spec.seed,'--output',world],{stdio:'inherit',timeout:150000});
 assert.equal(sha(readFileSync(world)),spec.world_sha,'retained canonical world');
 const output=join(folder,'home-'+spec.home_id+'.json');
 if(!existsSync(output))execFileSync(node,[join(helper,'tools/expedition/entry.mjs'),'--world',world,'--home',String(spec.home_id),'--cache',join(folder,'cache'),'--output',output],{stdio:'inherit',timeout:180000});
 const packet=JSON.parse(readFileSync(output));
 assert.equal(packet.content.sha,spec.content_sha,'GAME-99 content/placements unchanged');
 rows.push({...spec,world,packet:output});
}
writeFileSync(join(base,'contexts.json'),JSON.stringify(rows,null,2)+'\n');
console.log('Six existing regions prepared; original world/content SHA values preserved');
