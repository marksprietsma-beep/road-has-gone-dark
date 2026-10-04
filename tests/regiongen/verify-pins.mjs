import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const pins=JSON.parse(await readFile('tests/regiongen/town-forge-pins.json'));
for(const [path,sha] of Object.entries(pins)){
 const bytes=await readFile(path),actual=createHash('sha1').update('blob '+bytes.length+'\0').update(bytes).digest('hex');
 assert.equal(actual,sha,'Pinned Town Forge changed: '+path);
}
console.log('PASS: genuine Town Forge source blobs unchanged from audited upstream pin');
