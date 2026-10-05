// Audit-only. Supply two exact pinned source checkouts; nothing is installed or
// imported into the shipped game. Only TRHGD-authored dictionary/prose is used.
import {stripTypeScriptTypes} from 'node:module';
import {readdir,readFile,writeFile,mkdir,mkdtemp} from 'node:fs/promises';
import {join,resolve,dirname} from 'node:path';
import {tmpdir} from 'node:os';
import {execFileSync} from 'node:child_process';
import {pathToFileURL,fileURLToPath} from 'node:url';
import assert from 'node:assert/strict';
import {performance} from 'node:perf_hooks';
import {loadWorld,context} from '../src/context.mjs';
import {loadPack,canonical} from '../src/core.mjs';
import {generate} from '../src/generator.mjs';
import {render} from '../src/text.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../../..');
const [lexPath,rantPath,outPath]=process.argv.slice(2);
if(!lexPath||!rantPath||!outPath)throw Error('Usage: node provider-comparison.mjs PINNED_LEX_CHECKOUT PINNED_RANT_CHECKOUT OUTPUT_JSON');
for(const [path,sha] of [[lexPath,'da0a823e275d9642731bdaed1f3006d2c9bfae74'],[rantPath,'c62d5b21b9da9be561c15afdccd5f352cdb91e64']])assert.equal(execFileSync('git',['rev-parse','HEAD'],{cwd:path,encoding:'utf8'}).trim(),sha);
const temp=await mkdtemp(join(tmpdir(),'game77-provider-'));
async function compile(from,to){
 await mkdir(to,{recursive:true});let bytes=0;
 for(const e of await readdir(from,{withFileTypes:true})){
  if(e.isDirectory()){bytes+=await compile(join(from,e.name),join(to,e.name));continue;}
  if(!e.name.endsWith('.ts')||e.name.includes('.test.')||e.name.endsWith('.d.ts'))continue;
  const js=stripTypeScriptTypes(await readFile(join(from,e.name),'utf8'),{mode:'transform'}).replace(/\.ts(["'])/g,'.js$1');
  await writeFile(join(to,e.name.replace(/\.ts$/,'.js')),js);bytes+=Buffer.byteLength(js);
 }
 return bytes;
}
for(const p of ['core','grammar']){
 const target=join(temp,'node_modules/@lexiconlang',p);await compile(join(lexPath,'packages',p,'src'),target);
 await writeFile(join(target,'package.json'),JSON.stringify({type:'module',exports:'./index.js'}));
}
await compile(join(rantPath,'src'),join(temp,'rant'));
await writeFile(join(temp,'rant/package.json'),JSON.stringify({type:'module'}));
const L={...await import(pathToFileURL(join(temp,'node_modules/@lexiconlang/core/index.js'))),...await import(pathToFileURL(join(temp,'node_modules/@lexiconlang/grammar/index.js')))};
const R=await import(pathToFileURL(join(temp,'rant/engine.js')));
const w=loadWorld(join(root,'tests/worldgen/fixtures/game-11-determinism.json')),c=context(w,'markers',51),pack=loadPack(join(root,'research/game77/packs/trhgd-original-v2.json'));
const g=L.grammar({origin:'A #subtype# retains #condition#. Built as a #purpose# #period#, it later changed: #event#.',subtype:x=>x.data.subtype,condition:x=>x.data.condition,purpose:x=>x.data.original_purpose,period:x=>x.data.period,event:x=>x.data.later_event});
function rantRender(f,seed){
 const tables=Object.fromEntries(Object.entries(f).filter(([,v])=>typeof v==='string').map(([k,v])=>[k,{name:k,subs:[''],entries:[{forms:[v],classes:[]}]}]));
 return R.rant('A <subtype> retains <condition>. Built as a <original_purpose> <period>, it later changed: <later_event>.',{seed,dictionary:{tables}});
}
const samples=[];let checked=0;
const timers={lexicon_ms:0,rant_ms:0,trhgd_ms:0};
for(let i=0;i<1000;i++){
 const r=generate('site',c,pack,{instance:String(i)}),before=canonical(r.facts);
 const start=performance.now();const a=g.generate(L.createContext({seed:r.seed,data:r.facts}));timers.lexicon_ms+=performance.now()-start;
 const t=performance.now();const b=rantRender(r.facts,r.seed);timers.rant_ms+=performance.now()-t;
 const u=performance.now();const own=render(r);timers.trhgd_ms+=performance.now()-u;
 assert.equal(a,own);assert.equal(b,own);assert.equal(canonical(r.facts),before);
 assert.equal(a,g.generate(L.createContext({seed:r.seed,data:r.facts})));assert.equal(b,rantRender(r.facts,r.seed));
 if(i<12)samples.push({instance:i,structured_facts:r.facts,lexicon:a,rant:b,trhgd:own});checked++;
}
await writeFile(outPath,JSON.stringify({checked,protocol:'Same TRHGD staged facts, identical requested prose, real pinned Lexicon grammar/Rant dictionary renderers. Donor-inspired staging is implemented by TRHGD, not imported FCG/Venture runtime.',timings_ms:timers,samples,external_content_imported:false,runtime:'Node '+process.versions.node},null,2)+'\n');
console.log('PASS: 1000 equal-fact comparisons, repeatability and no fact mutation');
