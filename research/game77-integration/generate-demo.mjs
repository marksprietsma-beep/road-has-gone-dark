// Developer-only reproducibility: requires a separate pinned GAME-77 checkout.
// Player runtime reads only the precomputed digest-pinned projection.
import {resolve,dirname,join} from 'node:path';
import {pathToFileURL,fileURLToPath} from 'node:url';
import {readFileSync,writeFileSync} from 'node:fs';
import {execFileSync} from 'node:child_process';
const core=resolve(process.argv[2]??'');
if(execFileSync('git',['rev-parse','HEAD'],{cwd:core,encoding:'utf8'}).trim()!=='325799cca5d082d6c05d3c589c13c18fc91cd4e1')throw Error('Use verified core research milestone 325799c');
const load=path=>import(pathToFileURL(join(core,'research/game77',path)));
const {loadWorld,context,eligible}=await load('src/context.mjs');
const {loadPack,sha,canonical,writeImmutable}=await load('src/core.mjs');
const {generate,envelope}=await load('src/generator.mjs');
const {originPayload}=await load('src/visibility.mjs');
const dir=dirname(fileURLToPath(import.meta.url)),root=resolve(dir,'../..');
const pack=loadPack(join(core,'research/game77/packs/trhgd-original-v1.json')),entries=[];
for(const key of ['game-11-determinism','atlas-showcase']){
 const world=loadWorld(join(root,'tests/worldgen/fixtures',key+'.json'));
 const candidates=world.source.settlements.filter(eligible).sort((a,b)=>a.population-b.population||a.i-b.i);
 const ids=key==='game-11-determinism'?[771,25]:[candidates[0].i];
 const records=ids.map(id=>generate('origin',context(world,'settlements',id),pack));
 const data=envelope(world.base,pack,records);
 writeImmutable(join(dir,'data',key+'-enrichment.json'),data);
 for(const r of records){const row=originPayload(data,r.source.id);row.text=r.facts.local_memory;entries.push(row);}
}
const publicBytes=JSON.stringify({schema_version:1,entries},null,2)+'\n';
writeFileSync(join(dir,'data/public-origins.json'),publicBytes);
writeFileSync(join(dir,'data/manifest.json'),JSON.stringify({core_commit:'325799cca5d082d6c05d3c589c13c18fc91cd4e1',public_sha256:sha(publicBytes),renderer:'memory-only-1',source_module_sha256:Object.fromEntries(['core','context','generator','text','visibility'].map(n=>[n,sha(readFileSync(join(core,'research/game77/src',n+'.mjs')))])),note:'Three actual eligible preset hometowns; other towns/generated worlds deliberately have no demonstration lore.'},null,2)+'\n');
console.log(JSON.stringify({public_sha256:sha(publicBytes),entries:entries.map(r=>({world_id:r.world_id,burg_id:r.burg_id,text:r.text}))},null,2));
