import assert from 'node:assert/strict';
import {readFile, mkdir, writeFile, mkdtemp, rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
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
// Exercise the identical supervisor with a shortened test deadline and a stuck
// synchronous worker. A timer inside the generator alone could never fire here.
const probe = await mkdtemp(join(tmpdir(), 'game76-timeout-'));
try {
 await writeFile(join(probe,'helper-entry.mjs'), (await readFile(entry,'utf8')).replace('}, 120000);','}, 500);'));
 await writeFile(join(probe,'offline-generate.mjs'), "console.log('WORKER_STARTED'); while(true) {}\n");
 const result = spawnSync(binary,[join(probe,'helper-entry.mjs'),'--seed','timeout-test','--output',join(probe,'world.json')],{encoding:'utf8',timeout:5000,env:{...process.env,PATH:'',NODE_PATH:'',NODE_OPTIONS:''}});
 assert.equal(result.status,124);
 assert.ok(result.stdout.includes('WORKER_STARTED'));
 assert.ok(result.stderr.includes('exceeded 120 seconds'));
 evidence.wall_clock_timeout = true;
} finally {await rm(probe,{recursive:true,force:true});}
await writeFile(join(out,'helper-evidence.json'),JSON.stringify(evidence,null,2)+'\n');
console.log('PASS: packaged offline helper, 6 genuine generations, same-seed determinism, distinct seeds, exact accepted SHA, safe argv, immutable fixtures');
console.log(JSON.stringify(evidence));
