#!/usr/bin/env node
// Build tool, not a player dependency. Run after npm ci --ignore-scripts --prefix vendor/azgaar.
import {cp, mkdir, readFile, writeFile, chmod, stat} from 'node:fs/promises';
import {resolve, dirname, join} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
const args = process.argv.slice(2);
const value = key => args[args.indexOf(key) + 1];
if (!args.includes('--output') || !args.includes('--runtime-license')) throw Error('Required --output <new directory> --runtime-license <Node LICENSE>');
const root = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const out = resolve(value('--output'));
try { await stat(out); throw Error('Output already exists; never overwrite a helper'); } catch (e) {if (e.code !== 'ENOENT') throw e;}
const vendor = join(root, 'vendor/azgaar');
const lock = JSON.parse(await readFile(join(vendor, 'package-lock.json'), 'utf8'));
const runtime = args.includes('--node-binary') ? resolve(value('--node-binary')) : process.execPath;
const version = execFileSync(runtime, ['--version'], {encoding:'utf8'}).trim();
if (version !== 'v24.19.0') throw Error('Recipe requires pinned Node v24.19.0');
const license = await readFile(resolve(value('--runtime-license')));
if (!license.toString().includes('Node.js') || !license.toString().includes('Permission')) throw Error('Full Node LICENSE required');
const included = new Set();
function locate(from, name) {
  let parent = from;
  while (true) {
    const candidate = (parent ? parent + '/' : '') + 'node_modules/' + name;
    if (lock.packages[candidate]) return candidate;
    const split = parent.lastIndexOf('/node_modules/');
    if (split >= 0) parent = parent.slice(0, split);
    else if (parent) parent = '';
    else return null;
  }
}
async function include(key, optional = false) {
  if (!key || included.has(key)) return;
  try {await stat(join(vendor,key));} catch(e) {if(optional && e.code === 'ENOENT')return; throw e;}
  included.add(key);
  const pkg = lock.packages[key];
  for (const name of Object.keys(pkg.dependencies ?? {})) await include(locate(key,name));
  for (const name of Object.keys(pkg.optionalDependencies ?? {})) await include(locate(key,name),true);
}
for (const name of [...Object.keys(lock.packages[''].dependencies), 'jsdom', 'vite']) await include(locate('',name));
await mkdir(join(out,'vendor/azgaar'),{recursive:true});
await writeFile(join(out,'.gdignore'),'');
for (const name of ['src','biome.json','vite.config.ts','tsconfig.json','package.json','package-lock.json','LICENSE'])
  await cp(join(vendor,name),join(out,'vendor/azgaar',name),{recursive:true});
for (const key of [...included].sort()) await cp(join(vendor,key),join(out,'vendor/azgaar',key),{
  recursive:true, filter: path => !path.slice(join(vendor,key).length).split(/[\\/]/).includes('node_modules')
});
await cp(join(root,'tools/worldgen'),join(out,'tools/worldgen'),{recursive:true, filter:path => !path.endsWith('package-helper.mjs') && !path.slice(join(root,'tools/worldgen').length).split(/[\\/]/).includes('.tmp')});
for (const path of ['tools/world_enrichment', 'vendor/content']) await cp(join(root,path),join(out,path),{recursive:true});
await mkdir(join(out,'data/world_enrichment'),{recursive:true});
for (const name of ['trhgd-expanded-v1.json','curated-corpora-vocabulary.json','runtime.json','runtime-profiles-v2.json','trhgd-origin-profiles-v2.json']) await cp(join(root,'data/world_enrichment',name),join(out,'data/world_enrichment',name));
const binary = process.platform === 'win32' ? 'node.exe' : 'node';
await cp(runtime,join(out,binary));
if (process.platform !== 'win32') await chmod(join(out,binary),0o755);
await writeFile(join(out,'NODE-LICENSE'),license);
const manifest = {helperVersion:1,nodeVersion:version,platform:process.platform,arch:process.arch,
 provider:'azgaar',version:'1.153.1',upstreamCommit:'cc5dbac5db12ba4a7c47e647f6bef8bd7bf930c6',
 runtimeSha256:createHash('sha256').update(await readFile(runtime)).digest('hex'),
 enrichmentRuntimes:Object.fromEntries(await Promise.all([['origin-v1','runtime.json'],['profiles-v2','runtime-profiles-v2.json']].map(async([key,file])=>[key,createHash('sha256').update(await readFile(join(root,'data/world_enrichment',file))).digest('hex')]))),
 lockSha256:createHash('sha256').update(await readFile(join(vendor,'package-lock.json'))).digest('hex'),
 packages:[...included].sort().map(key=>({path:key,version:lock.packages[key].version,integrity:lock.packages[key].integrity}))};
await writeFile(join(out,'runtime.json'),JSON.stringify(manifest,null,2)+'\n');
console.log('Packaged',included.size,'locked runtime packages with licences at',out);
