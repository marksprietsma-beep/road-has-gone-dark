// Offline Origin V1 compiler. The world bytes are read, never rewritten.
import {readFileSync, writeFileSync, mkdirSync, existsSync, readdirSync, renameSync, rmSync} from 'node:fs';
import {join, dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {canonical, sha} from './core.mjs';
import {loadWorld, context} from './context.mjs';
import {generate, validateRecord, pack, packSha, VERSION, envelope, verifySidecar} from './framework.mjs';
import {render, RENDERER} from './text.mjs';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
export const manifestPath = join(root, 'data/world_enrichment/runtime.json');
export function verifyRuntime() {
 const bytes = readFileSync(manifestPath), m = JSON.parse(bytes);
 if (m.generator_version !== VERSION || m.content_pack_sha !== packSha || m.renderer_version !== RENDERER) throw Error('Unsupported enrichment runtime');
 for (const [file, digest] of Object.entries(m.files)) if (sha(readFileSync(join(root,file))) !== digest) throw Error('Enrichment runtime integrity failure: '+file);
 return {...m, runtime_manifest_sha:sha(bytes)};
}
// Exact GAME-7 policy, including valid political membership; no parallel formula.
export function hometowns(world) {
 return world.source.settlements.filter(b => b && b.i > 0 && !b.hidden && !b.removed && !b.capital && b.population > 0 && b.population <= 5 && Number.isInteger(b.cell) && world.source.cells.state[b.cell] > 0 && world.record('states',world.source.cells.state[b.cell])) .sort((a,b)=>a.i-b.i);
}
export function compileWorld(path) {
 const runtime=verifyRuntime(), world=loadWorld(path), towns=hometowns(world);
 const records=towns.map(b=>{const ctx=context(world,'settlements',b.i), r=generate(ctx,'origin'); validateRecord(r,ctx); return r;});
 // A world with no eligible hometowns is still a valid reusable template.
 const sidecar=records.length ? envelope(world.base,records) : {schema_version:2,base_world:world.base,scope:'world',provider:'sha-staged',generator_version:VERSION,content_pack_version:pack.version,content_pack_sha:packSha,records:[]};
 const projection={schema_version:1,world_id:world.base.id,world_sha:world.base.sha256,origins:{}};
 for (const r of records) {
  const p={schema_version:r.schema_version,id:r.id,domain:r.domain,public:r.public,source:r.source,versions:r.versions};
  const full=render(p).text;
  // Concise memory sentence and tradition separately: the UI chooses presentation,
  // never grammar or facts. Both are compiled from these immutable public facts.
  const compact=render(p,{compact:true}).text;
  const split=compact.indexOf('. Local households ');
  projection.origins[r.source.id]={record_id:r.id,burg_id:r.source.id,cell_id:r.source.cell_id,state_id:r.source.state_id,province_id:r.source.province_id,memory:compact.slice(0,split+1),tradition:compact.slice(split+2),text:full};
 }
 const enrichment=canonical(sidecar)+'\n', publicBytes=canonical(projection)+'\n';
 const descriptor={schema_version:1,provider:'sha-staged',generator_version:VERSION,content_pack_version:pack.version,content_pack_sha:packSha,renderer_version:RENDERER,base_world_id:world.base.id,base_world_sha:world.base.sha256,enrichment_sha:sha(enrichment),public_projection_sha:sha(publicBytes),runtime_manifest_sha:runtime.runtime_manifest_sha,origin_count:records.length};
 return {world,sidecar,projection,descriptor,enrichment,publicBytes};
}
export function verifyDirectory(path, worldPath) {
 const expected=compileWorld(worldPath);
 for (const [name,bytes] of [['enrichment.json',expected.enrichment],['public.json',expected.publicBytes],['descriptor.json',canonical(expected.descriptor)+'\n']]) if (readFileSync(join(path,name),'utf8')!==bytes) throw Error('Enrichment validation failed: '+name);
 if(expected.sidecar.records.length)verifySidecar(expected.sidecar,expected.world.base,expected.sidecar.enrichment_sha);
 return expected.descriptor;
}
export function publish(path, worldPath) {
 if (existsSync(path)) return verifyDirectory(path,worldPath); // never rewrite history
 const out=compileWorld(worldPath), pending=path+'.pending-'+process.pid;
 mkdirSync(dirname(path),{recursive:true}); mkdirSync(pending);
 try {
  writeFileSync(join(pending,'enrichment.json'),out.enrichment,{flag:'wx'});
  writeFileSync(join(pending,'public.json'),out.publicBytes,{flag:'wx'});
  writeFileSync(join(pending,'descriptor.json'),canonical(out.descriptor)+'\n',{flag:'wx'});
  verifyDirectory(pending,worldPath);
  // Dedicated directory rename is the only publication boundary.
  if(existsSync(path)) {verifyDirectory(path,worldPath); rmSync(pending,{recursive:true});}
  else renameSync(pending,path);
 } catch(error) {rmSync(pending,{recursive:true,force:true});throw error;}
 return out.descriptor;
}
if (process.argv[1] && resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
 try {
  const args=process.argv.slice(2);
  if(args.length!==4 || args[0]!=='--world' || args[2]!=='--output')throw Error('Expected --world <path> --output <enrichment directory>');
  console.log(JSON.stringify(publish(resolve(args[3]),resolve(args[1]))));
 } catch(e){console.error(e.message);process.exitCode=1;}
}
