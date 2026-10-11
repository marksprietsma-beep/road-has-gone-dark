// GAME-99: derived cache only. Never write a campaign or canonical source world.
import {readFileSync,writeFileSync,mkdirSync,existsSync,mkdtempSync,renameSync,rmSync} from 'node:fs';
import {join} from 'node:path';
import {execFileSync} from 'node:child_process';
import {sha} from '../world_enrichment/core.mjs';
import {checkGeographySidecar} from '../worldgen/geography-sidecar.mjs';
export const GEOGRAPHY_REPAIR_VERSION=1;
export function ensureGeography(world,fingerprint,cache) {
 mkdirSync(cache,{recursive:true});
 const geo=join(cache,fingerprint+'.geography.json');
 if(existsSync(geo)){
  if(!existsSync(geo+'.sha')||readFileSync(geo+'.sha','utf8')!==sha(readFileSync(geo)))throw Error('Unverified/corrupt geography cache; campaign preserved');
  const sidecar=JSON.parse(readFileSync(geo));checkGeographySidecar(world,sidecar,fingerprint);return sidecar;
 }
 // Older bounds-check failures left only a replay file. Reconstruct from the
 // same seed in a private staging directory, and require exact canonical bytes.
 // Both schema v1 and all successful cache bytes remain unchanged.
 const stage=mkdtempSync(join(cache,'.geography-repair-v'+GEOGRAPHY_REPAIR_VERSION+'-'));
 try{
  const replay=join(stage,'world.json'),pending=join(stage,'geography.json');
  execFileSync(process.execPath,['tools/worldgen/offline-generate.mjs','--seed',world.seed,'--output',replay,'--geometry-output',pending],{timeout:125000});
  if(sha(readFileSync(replay))!==fingerprint)throw Error('Original geography replay did not match canonical world; campaign preserved');
  const bytes=readFileSync(pending),sidecar=JSON.parse(bytes);checkGeographySidecar(world,sidecar,fingerprint);
  writeFileSync(join(stage,'geography.sha'),sha(bytes),{flag:'wx'});
  // The sidecar is the final commit boundary: interruption before it publishes
  // leaves a missing cache, safely retried. Existing corrupt caches are rejected.
  if(existsSync(geo))return ensureGeography(world,fingerprint,cache);
  renameSync(join(stage,'geography.sha'),geo+'.sha');renameSync(pending,geo);
  return sidecar;
 }finally{rmSync(stage,{recursive:true,force:true});}
}
