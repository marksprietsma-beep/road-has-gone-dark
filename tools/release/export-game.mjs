#!/usr/bin/env node
// One native game distribution, with its compatible helper included automatically.
// Requires official matching Godot export templates, Godot 4.6.3 and build Node 24.19.0.
import{mkdirSync,existsSync,cpSync,writeFileSync,readFileSync}from'node:fs';import{resolve,join}from'node:path';import{execFileSync}from'node:child_process';import{createHash}from'node:crypto';
import{root,assertHelper}from'../worldgen/helper-contract.mjs';
const a=process.argv.slice(2),get=k=>a.includes(k)?a[a.indexOf(k)+1]:null;
const output=get('--output');if(!output)throw Error('Required --output <new distribution directory>; optional --helper <directory> --godot <executable>');
const target=resolve(output),helper=resolve(get('--helper')??join(root,'worldgen-helper')),engine=get('--godot')??'godot';
if(existsSync(target))throw Error('Output exists; existing distribution was not overwritten');
if(!get('--helper'))execFileSync(process.execPath,[join(root,'tools/worldgen/bootstrap-helper.mjs')],{cwd:root,stdio:'inherit'});
const manifest=assertHelper(helper);const version=execFileSync(engine,['--version'],{encoding:'utf8'}).trim();if(!version.startsWith('4.6.3.'))throw Error('Godot 4.6.3 required');
mkdirSync(target,{recursive:true});
const preset=process.platform==='win32'?'Windows Desktop':'Linux';
const executable=join(target,process.platform==='win32'?'road-has-gone-dark.exe':'road-has-gone-dark');
execFileSync(engine,['--headless','--path',root,'--export-release',preset,executable],{cwd:root,stdio:'inherit'});
if(!existsSync(executable))throw Error('Export did not produce the game executable');
// Official release templates deliberately disable scene overrides. A temporary
// debug export exercises the same exported resources and adjacent native helper.
if(a.includes('--qa'))execFileSync(engine,['--headless','--path',root,'--export-debug',preset,join(target,process.platform==='win32'?'road-has-gone-dark-qa.exe':'road-has-gone-dark-qa')],{cwd:root,stdio:'inherit'});
cpSync(helper,join(target,'worldgen-helper'),{recursive:true});
assertHelper(join(target,'worldgen-helper'));
writeFileSync(join(target,'distribution.json'),JSON.stringify({schema_version:1,godot:version,platform:process.platform,arch:process.arch,enrichmentRuntimes:manifest.enrichmentRuntimes,executable_sha256:createHash('sha256').update(readFileSync(executable)).digest('hex')},null,2)+'\n');
console.log('Complete native offline distribution:',target);
