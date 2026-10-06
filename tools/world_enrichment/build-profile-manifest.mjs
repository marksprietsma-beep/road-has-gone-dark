// Release-only manifest builder; never rewrites the GAME-79 runtime.
import {readFileSync,writeFileSync,readdirSync}from'node:fs';
import{join}from'node:path';
import{sha,canonical}from'./core.mjs';
import{PROFILE_VERSION,profilePack,profilePackSha}from'./profile-framework.mjs';
import{PROFILE_RENDERER}from'./profile-text.mjs';
const files={};
function walk(path){for(const e of readdirSync(path,{withFileTypes:true})){const p=join(path,e.name).replaceAll('\\','/');if(e.isDirectory())walk(p);else files[p]=sha(readFileSync(p));}}
for(const path of ['tools/world_enrichment','vendor/content'])walk(path);
for(const p of ['data/world_enrichment/runtime.json','data/world_enrichment/trhgd-expanded-v1.json','data/world_enrichment/curated-corpora-vocabulary.json','data/world_enrichment/trhgd-origin-profiles-v2.json'])files[p]=sha(readFileSync(p));
writeFileSync('data/world_enrichment/runtime-profiles-v2.json',canonical({schema_version:2,generator_version:PROFILE_VERSION,content_pack_version:profilePack.version,content_pack_sha:profilePackSha,renderer_version:PROFILE_RENDERER,files})+'\n');
