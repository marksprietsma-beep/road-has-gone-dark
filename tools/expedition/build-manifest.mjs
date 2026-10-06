import {readFileSync,writeFileSync,readdirSync} from 'node:fs';
import {sha,canonical} from '../world_enrichment/core.mjs';
const files={...JSON.parse(readFileSync('data/world_enrichment/runtime-party-v1.json')).files};
for(const dir of ['tools/expedition','tools/regiongen','vendor/town-forge/src'])for(const f of readdirSync(dir))if(/\.(mjs|ts)$/.test(f))files[dir+'/'+f]=sha(readFileSync(dir+'/'+f));
for(const f of readdirSync('assets/map_icons/trials/game-icons'))if(f.endsWith('.svg'))files['assets/map_icons/trials/game-icons/'+f]=sha(readFileSync('assets/map_icons/trials/game-icons/'+f));
for(const path of ['vendor/town-forge/LICENSE','data/world_enrichment/runtime-party-v1.json','tools/worldgen/geography-sidecar.mjs'])files[path]=sha(readFileSync(path));
writeFileSync('data/world_enrichment/runtime-expedition-v1.json',canonical({schema_version:1,generator_version:'trhgd-expedition-v1',files})+'\n');
