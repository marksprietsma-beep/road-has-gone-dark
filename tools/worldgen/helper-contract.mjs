// Build/development compatibility check shared with distribution packaging.
import{readFileSync,existsSync}from'node:fs';import{join,dirname,resolve}from'node:path';import{fileURLToPath}from'node:url';import{createHash}from'node:crypto';
export const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..');
const digest=p=>createHash('sha256').update(readFileSync(p)).digest('hex');
export const runtimePairs=[['origin-v1','runtime.json'],['profiles-v2','runtime-profiles-v2.json'],['party-v1','runtime-party-v1.json']];
export function expectedRuntimes(){return Object.fromEntries(runtimePairs.map(([key,file])=>[key,digest(join(root,'data/world_enrichment',file))]));}
export function assertHelper(path){
 const m=JSON.parse(readFileSync(join(path,'runtime.json')));
 if(m.helperVersion!==1||m.nodeVersion!=='v24.19.0'||m.platform!==process.platform||m.arch!==process.arch||m.upstreamCommit!=='cc5dbac5db12ba4a7c47e647f6bef8bd7bf930c6')throw Error('Incompatible native world helper');
 const binary=join(path,process.platform==='win32'?'node.exe':'node');if(!existsSync(binary)||digest(binary)!==m.runtimeSha256)throw Error('Invalid bundled runtime');
 const pins=expectedRuntimes();for(const[key,file]of runtimePairs){
  if(m.enrichmentRuntimes?.[key]!==pins[key]||digest(join(path,'data/world_enrichment',file))!==pins[key])throw Error('Helper does not match '+key);
 }
 const profiles=JSON.parse(readFileSync(join(path,'data/world_enrichment/runtime-party-v1.json')));
 for(const[file,sha]of Object.entries(profiles.files))if(digest(join(path,file))!==sha)throw Error('Helper content integrity failure: '+file);
 return m;
}
