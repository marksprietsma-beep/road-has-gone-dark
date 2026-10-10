import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,writeFileSync,mkdirSync,mkdtempSync,rmSync,existsSync,readdirSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {createHash} from 'node:crypto';
import {ensureGeography,GEOGRAPHY_REPAIR_VERSION} from '../../tools/expedition/geography-cache.mjs';
const root=process.env.GAME99_REPRO_ROOT;
if(!root)throw Error('GAME99_REPRO_ROOT must contain the real original failing source and repaired sidecar');
const bytes=readFileSync(join(root,'world.json')),world=JSON.parse(bytes),fp=createHash('sha256').update(bytes).digest('hex'),original=readFileSync(join(root,'geography.json'));
const sha=b=>createHash('sha256').update(b).digest('hex');
const base=mkdtempSync(join(tmpdir(),'game99-cache-'));
try{
 await test('failed old replay recovers unchanged source, deterministic/idempotent v1 cache',()=>{
  const cache=join(base,'failed-old');mkdirSync(cache);writeFileSync(join(cache,fp+'.replay.json'),bytes);
  const s=ensureGeography(world,fp,cache),path=join(cache,fp+'.geography.json');
  assert.equal(GEOGRAPHY_REPAIR_VERSION,1);assert.equal(s.source_world_sha256,fp);assert.equal(sha(readFileSync(path)),sha(original));
  assert.deepEqual(readFileSync(join(cache,fp+'.replay.json')),bytes,'old source leftovers preserved');
  const before=readFileSync(path);assert.deepEqual(ensureGeography(world,fp,cache),s);assert.deepEqual(readFileSync(path),before);
  assert(!readdirSync(cache).some(n=>n.startsWith('.geography-repair-')));
 });
 await test('interruption before sidecar publication retries a missing cache safely',()=>{
  const cache=join(base,'interrupted');mkdirSync(cache);writeFileSync(join(cache,fp+'.geography.json.sha'),'orphaned precommit hash');
  assert.equal(ensureGeography(world,fp,cache).source_world_sha256,fp);assert.equal(readFileSync(join(cache,fp+'.geography.json.sha'),'utf8'),sha(original));
 });
 await test('canonical mismatch publishes nothing and never changes source bytes',()=>{
  const cache=join(base,'wrong-world'),wrong='0'.repeat(64);assert.throws(()=>ensureGeography(world,wrong,cache),/did not match/);
  assert(!existsSync(join(cache,wrong+'.geography.json')));assert(!existsSync(join(cache,wrong+'.geography.json.sha')));
  assert.deepEqual(readFileSync(join(root,'world.json')),bytes);
 });
 await test('existing corrupt and unverified caches fail closed without overwriting them',()=>{
  for(const mode of ['missing-checksum','wrong-checksum','invalid-ring']){
   const cache=join(base,mode);mkdirSync(cache);const path=join(cache,fp+'.geography.json');
   let content=original;if(mode==='invalid-ring'){const s=JSON.parse(original);s.cell_vertex_ids[0]=[0,0,0];content=Buffer.from(JSON.stringify(s));}
   writeFileSync(path,content);if(mode!=='missing-checksum')writeFileSync(path+'.sha',mode==='wrong-checksum'?'wrong':sha(content));
   assert.throws(()=>ensureGeography(world,fp,cache));assert.deepEqual(readFileSync(path),content);
  }
 });
}finally{rmSync(base,{recursive:true,force:true});}
