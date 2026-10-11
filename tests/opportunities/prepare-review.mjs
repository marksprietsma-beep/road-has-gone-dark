import {readFileSync,writeFileSync,mkdirSync,existsSync} from 'node:fs';
import {resolve,join} from 'node:path';
import {execFileSync} from 'node:child_process';
const base=resolve(process.env.GAME101_TEST_ROOT),helper=resolve(process.env.GAME76_HELPER_ROOT),node=join(helper,process.platform==='win32'?'node.exe':'node');
const corpus=JSON.parse(readFileSync(join(base,'corpus/corpus.json'))),selected=[],rows=[];
for(const seed of ['game101-variety-00','game101-variety-01']){
 const candidates=corpus.specs.filter(s=>specsWorld(s)===seed),used=new Set();
 for(const original of candidates){
  if([...selected].filter(s=>s.seed===seed).length===3)break;
  const world=JSON.parse(readFileSync(original.world)),anchor=world.settlements.find(b=>b.i===original.home_id),state=world.cells.state[anchor.cell],province=world.cells.province[anchor.cell];
  const offered=world.settlements.filter(b=>b.i>0&&b.cell>=0&&world.cells.state[b.cell]===state&&(province<=0||world.cells.province[b.cell]===province)&&!b.capital&&!b.hidden&&!b.removed&&b.population>0&&b.population<=5).sort((a,b)=>a.population-b.population||a.i-b.i).slice(0,8);
  const home=offered.find(b=>b.i===original.home_id&&!used.has(b.i))??offered.find(b=>!used.has(b.i));
  if(!home)continue;used.add(home.i);
  const same=home.i===original.home_id;
  selected.push({...original,seed,home_id:home.i,home_name:home.name,cell:home.cell,biome:world.biomes.find(b=>b.i===world.cells.biome[home.cell])?.name,content:same?original.content:null});
 }
}
if(selected.length!==6)throw Error('Six genuinely offered source hometowns required');
for(const spec of selected){
 const folder=join(base,'review-packets',String(specsWorld(spec)));mkdirSync(folder,{recursive:true});
 const packet=join(folder,'home-'+spec.home_id+'.json');
 if(!existsSync(packet))execFileSync(node,[join(helper,'tools/expedition/entry.mjs'),'--world',spec.world,'--home',String(spec.home_id),'--cache',join(folder,'cache'),'--output',packet],{stdio:'inherit',timeout:180000});
 const actual=JSON.parse(readFileSync(packet));if(!actual.ok)throw Error('unsupported review hometown');
 if(spec.content&&JSON.parse(readFileSync(spec.content)).sha!==actual.content.sha)throw Error('source placements changed');
 rows.push({...spec,packet,seed:specsWorld(spec)});
}
writeFileSync(join(base,'review-contexts.json'),JSON.stringify(rows,null,2)+'\n');
function specsWorld(spec){return JSON.parse(readFileSync(spec.world)).seed;}
console.log('Six real V2 review hometowns ready');
