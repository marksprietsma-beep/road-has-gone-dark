// Release/build action, never a player-side repair of mismatched runtime files.
import {readFileSync,writeFileSync,readdirSync} from 'node:fs';
import {join} from 'node:path';
import {sha,canonical} from './core.mjs';
import {VERSION,pack,packSha} from './framework.mjs';
import {RENDERER} from './text.mjs';
const files={};
function walk(path){for(const e of readdirSync(path,{withFileTypes:true})){const p=join(path,e.name).replaceAll('\\','/');if(e.isDirectory())walk(p);else if(!p.endsWith('runtime.json'))files[p]=sha(readFileSync(p));}}
for(const path of ['tools/world_enrichment','vendor/content'])walk(path);
for(const p of ['data/world_enrichment/trhgd-expanded-v1.json','data/world_enrichment/curated-corpora-vocabulary.json'])files[p]=sha(readFileSync(p));
writeFileSync('data/world_enrichment/runtime.json',canonical({schema_version:1,generator_version:VERSION,content_pack_version:pack.version,content_pack_sha:packSha,renderer_version:RENDERER,files})+'\n');
