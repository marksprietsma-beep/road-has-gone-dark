// Pinned golden corpus: detect silent rerolls under an unchanged generator/pack.
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {gunzipSync} from 'node:zlib';
import {loadWorld,context} from '../src/context.mjs';
import {generate,project} from '../src/framework.mjs';
import {render} from '../src/text.mjs';
import {canonical} from '../../game77/src/core.mjs';
const root='research/game78/evidence/',metrics=JSON.parse(readFileSync(root+'batch-metrics.json')).metrics;
const w=loadWorld('tests/worldgen/fixtures/game-11-determinism.json'),town=context(w,'settlements',771),site=context(w,'markers',51);let checked=0;
for(const key of Object.keys(metrics)){
 const [provider,domain]=key.split('/'),rows=gunzipSync(readFileSync(root+'batches/'+key.replace('/','-')+'.jsonl.gz')).toString().trim().split('\n').map(s=>JSON.parse(s));
 assert.equal(rows.length,metrics[key].count);
 for(const row of rows){
  const record=generate(domain==='site'?site:town,domain,String(row.index),{provider,playthrough_id:'batch-78'});
  assert.equal(canonical(record),canonical(row.record),key+':'+row.index+' silently rerolled facts');
  const p=project(record,{world_id:w.base.id,playthrough_id:'batch-78',known_entities:[record.id],heard_rumours:record.rumours.map(x=>record.id+':'+x.id)});
  assert.equal(canonical(p),canonical(row.public));
  assert.equal(render(p,{extended:domain==='character'}).text,row.render.text);
  assert.equal(render(p,{style:'fixed'}).text,row.fixed_control);
  assert.equal(render(p,{style:'lexicon'}).text,row.lexicon_control);checked++;
 }
}
console.log('PASS: '+checked+' pinned fact/projection records and '+checked*3+' rendered texts replay exactly');
