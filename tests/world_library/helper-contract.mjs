import assert from 'node:assert/strict';
import {readFile, mkdir, writeFile} from 'node:fs/promises';
import {resolve, join} from 'node:path';
import {execFileSync, spawnSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const helper = resolve(process.env.GAME76_HELPER_ROOT ?? 'worldgen-helper');
const out = resolve(process.env.GAME76_GENERATED_TEST_DIR ?? 'tools/worldgen/.tmp/game76-generated');
await mkdir(out,{recursive:true});
const binary = join(helper,process.platform === 'win32' ? 'node.exe' : 'node');
const entry = join(helper,'tools/worldgen/helper-entry.mjs');
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const manifest = JSON.parse(await readFile(join(helper,'runtime.json')));
assert.equal(manifest.nodeVersion,'v24.19.0');
assert.equal(digest(await readFile(binary)),manifest.runtimeSha256);
const fixtures = ['game-11-determinism','atlas-showcase'];
const fixtureHashes = await Promise.all(fixtures.map(async key=>digest(await readFile('tests/worldgen/fixtures/'+key+'.json'))));
const evidence = {platform:process.platform,runtime:manifest.nodeVersion,packages:manifest.packages.length,worlds:[]};
for (const seed of ['game-11-determinism','game76-library-a','game76-library-b']) {
 const hashes = [];
 for (let repeat=0;repeat<2;repeat++) {
  const path = join(out,seed+'-'+repeat,'world.json');
  // No PATH runtime fallback: helper dependencies/runtime only. Spaces in output exercised.
  execFileSync(binary,[entry,'--seed',seed,'--output',path],{timeout:120000,stdio:'pipe',env:{...process.env,PATH:'',NODE_PATH:'',NODE_OPTIONS:''}});
  const bytes = await readFile(path);
  const world = JSON.parse(bytes);
  assert.equal(world.schemaVersion,1);
  assert.equal(world.seed,seed);
  assert.deepEqual(world.generator,{provider:'azgaar',version:'1.153.1',upstreamCommit:'cc5dbac5db12ba4a7c47e647f6bef8bd7bf930c6'});
  hashes.push(digest(bytes));
 }
 assert.equal(hashes[0],hashes[1]);
 evidence.worlds.push({seed,sha256:hashes[0]});
}
assert.equal(evidence.worlds[0].sha256,fixtureHashes[0]);
assert.notEqual(evidence.worlds[1].sha256,evidence.worlds[2].sha256);
for(let i=0;i<fixtures.length;i++) assert.equal(digest(await readFile('tests/worldgen/fixtures/'+fixtures[i]+'.json')),fixtureHashes[i]);
const bad = spawnSync(binary,[entry,'--seed','bad; shell','--output',join(out,'bad.json')],{encoding:'utf8'});
assert.equal(bad.status,2);
await writeFile(join(out,'helper-evidence.json'),JSON.stringify(evidence,null,2)+'\n');
console.log('PASS: packaged offline helper, 6 genuine generations, same-seed determinism, distinct seeds, exact accepted SHA, safe argv, immutable fixtures');
console.log(JSON.stringify(evidence));
