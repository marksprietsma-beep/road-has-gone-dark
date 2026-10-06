// Compare renderers on exactly the same already-generated facts; no new sampling.
import {readFileSync,writeFileSync} from 'node:fs';
import {gunzipSync} from 'node:zlib';
const root='research/game78/evidence/',m=JSON.parse(readFileSync(root+'batch-metrics.json'));
const comparison={};
for(const [key,value]of Object.entries(m.metrics)){
 const rows=gunzipSync(readFileSync(root+'batches/'+key.replace('/','-')+'.jsonl.gz')).toString().trim().split('\n').map(x=>JSON.parse(x));
 if(rows.length!==value.count)throw Error('Incomplete batch');
 comparison[key]={records:rows.length,distinct_rant:new Set(rows.map(r=>r.render.text)).size,distinct_fixed:new Set(rows.map(r=>r.fixed_control)).size,distinct_lexicon:new Set(rows.map(r=>r.lexicon_control)).size,known_bad_token_matches:rows.filter(r=>/undefined|ancient evil|https:|<iframe|The a |A a |They (sets|keeps|counts|listens|pauses|folds|cleans)\b/.test(r.render.text)).length,limitations:'Exact text distinctness includes names; semantic name-independent counts are separate. Zero detected tokens/validated constraints is not a universal grammar or truth proof.'};
}
writeFileSync(root+'renderer-comparison.json',JSON.stringify(comparison,null,2)+'\n');console.log('Compared 11,200 existing fact records across three renderers');
