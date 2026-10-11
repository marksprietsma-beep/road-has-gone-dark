import {readFileSync,writeFileSync,mkdirSync,existsSync} from 'node:fs';
import {resolve,join} from 'node:path';
import {execFileSync} from 'node:child_process';
const base=resolve(process.env.GAME101_TEST_ROOT),helper=resolve(process.env.GAME76_HELPER_ROOT),node=join(helper,process.platform==='win32'?'node.exe':'node');
const corpus=JSON.parse(readFileSync(join(base,'corpus/corpus.json'))),selected=[...corpus.specs.slice(0,3),...corpus.specs.slice(4,7)],rows=[];
for(const spec of selected){
 const folder=join(base,'review-packets',String(specsWorld(spec)));mkdirSync(folder,{recursive:true});
 const packet=join(folder,'home-'+spec.home_id+'.json');
 if(!existsSync(packet))execFileSync(node,[join(helper,'tools/expedition/entry.mjs'),'--world',spec.world,'--home',String(spec.home_id),'--cache',join(folder,'cache'),'--output',packet],{stdio:'inherit',timeout:180000});
 const original=JSON.parse(readFileSync(spec.content)),actual=JSON.parse(readFileSync(packet));if(original.sha!==actual.content.sha)throw Error('source placements changed');
 rows.push({...spec,packet,seed:specsWorld(spec)});
}
writeFileSync(join(base,'review-contexts.json'),JSON.stringify(rows,null,2)+'\n');
function specsWorld(spec){return JSON.parse(readFileSync(spec.world)).seed;}
console.log('Six real V2 review hometowns ready');
