import {writeFileSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {loadWorld,context,eligible} from '../src/context.mjs';
import {loadPack,canonical} from '../src/core.mjs';
import {generate,validateRecord} from '../src/generator.mjs';
import {render} from '../src/text.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../../..');
const w=loadWorld(resolve(root,'tests/worldgen/fixtures/game-11-determinism.json'));
const c=context(w,'settlements',771),s=context(w,'markers',51),p=loadPack(resolve(root,'research/game77/packs/trhgd-original-v2.json'));
const types=['site','origin','character','mundane-item','rare-item'];
const evidence=[];const summary={};
for(const type of types){
 const texts=new Set(), facts=new Set();let bad=0;
 for(let i=0;i<1000;i++){
  const r=generate(type,type==='site'?s:c,p,{instance:String(i),playthrough_id:'quality'});
  validateRecord(r);const text=render(r);texts.add(text);facts.add(canonical(r.facts));
  if(/undefined|null|ancient evil|lifelong sailor|https:|<iframe/.test(text))bad++;
  if(i<20)evidence.push({type,instance:i,text});
 }
 summary[type]={iterations:1000,distinct_facts:facts.size,distinct_prose:texts.size,bad_token_matches:bad};
 if(bad)throw Error('Poor-quality token regression');
}
writeFileSync(resolve(root,'research/game77/evidence/quality-audit.json'),JSON.stringify({selection:'First 20 sequential IDs per domain, not selected lucky seeds',summary,samples:evidence,limitation:'Small original spike pack intentionally repeats. Variety counts describe actual output, not production authoring completeness.'},null,2)+'\n');
console.log(JSON.stringify(summary,null,2));
