// Build only the additive party manifest; historical V1/V2 manifests are frozen.
import {readFileSync,writeFileSync,readdirSync} from 'node:fs';
import {sha,canonical} from '../world_enrichment/core.mjs';
import {packSha,VERSION} from './pack.mjs';
const files={...JSON.parse(readFileSync('data/world_enrichment/runtime-profiles-v2.json')).files};
for(const name of readdirSync('tools/party'))if(name.endsWith('.mjs'))files['tools/party/'+name]=sha(readFileSync('tools/party/'+name));
for(const name of ['runtime-profiles-v2.json','trhgd-party-v1.json'])files['data/world_enrichment/'+name]=sha(readFileSync('data/world_enrichment/'+name));
writeFileSync('data/world_enrichment/runtime-party-v1.json',canonical({schema_version:1,generator_version:VERSION,content_pack_sha:packSha,files})+'\n');
