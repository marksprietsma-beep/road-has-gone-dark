// Developer-only generation; players load a pinned public projection, not Node.
import {resolve,join,dirname} from 'node:path';
import {pathToFileURL,fileURLToPath} from 'node:url';
import {readFileSync,writeFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
const pin='746369f278ef009ba6f589e84e508c2bd3ed3e9c';
const core=resolve(process.argv[2]??'');
if(execFileSync('git',['rev-parse','HEAD'],{cwd:core,encoding:'utf8'}).trim()!==pin)throw Error('Use pinned published GAME-78 core '+pin);
const load=path=>import(pathToFileURL(join(core,'research/game78',path)));
const {loadWorld,context,eligible}=await load('src/context.mjs');
const {generate,envelope,writeSidecar,packSha}=await load('src/framework.mjs');
const {originPayload}=await load('src/text.mjs');
const {sha}=await import(pathToFileURL(join(core,'research/game77/src/core.mjs')));
const dir=dirname(fileURLToPath(import.meta.url)),root=resolve(dir,'../..'),entries=[],world_sidecars={},facts=[];
for(const key of ['game-11-determinism','atlas-showcase']){
 const w=loadWorld(join(root,'tests/worldgen/fixtures',key+'.json'));
 const ids=key==='game-11-determinism'?[771,25]:[760];
 if(ids.some(id=>!eligible(w.source.settlements.find(x=>x?.i===id))))throw Error('Invalid hometown');
 const records=ids.map(id=>generate(context(w,'settlements',id),'origin','onboarding-demo'));
 const e=envelope(w.base,records),file=key+'-'+e.enrichment_sha+'.json';
 writeSidecar(join(dir,'data',file),e);world_sidecars[key]=file;
 for(const r of records){const row=originPayload(r,e.enrichment_sha,{compact:true});entries.push(row);facts.push({world_id:r.source.world_id,burg_id:r.source.id,memory_event:r.public.memory.event,tradition:r.public.tradition.practice,expected_text:row.text});}
}
const bytes=JSON.stringify({schema_version:1,entries},null,2)+'\n';writeFileSync(join(dir,'data/public-origins.json'),bytes);
const manifest={core_commit:pin,pack_sha:packSha,public_sha256:sha(bytes),renderer:'trhgd-game78-rant-1/compact-origin',world_sidecars,facts,source_module_sha256:Object.fromEntries(['context','compatibility','framework','text'].map(n=>[n,sha(readFileSync(join(core,'research/game78/src',n+'.mjs')))])),limits:'Three real preset hometowns. Other towns and generated worlds fall back to unchanged GAME-75 factual context.'};
writeFileSync(join(dir,'data/manifest.json'),JSON.stringify(manifest,null,2)+'\n');console.log(JSON.stringify({sha256:sha(bytes),entries},null,2));
