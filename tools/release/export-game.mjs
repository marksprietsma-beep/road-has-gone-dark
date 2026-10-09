#!/usr/bin/env node
// One native game distribution, with its compatible helper included automatically.
// Requires official matching Godot export templates, Godot 4.6.3 and build Node 24.19.0.
import{mkdirSync,mkdtempSync,rmSync,existsSync,cpSync,writeFileSync,readFileSync}from'node:fs';import{resolve,join}from'node:path';import{tmpdir}from'node:os';import{execFileSync}from'node:child_process';import{createHash}from'node:crypto';
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
// Official templates disable scene overrides. Export identical source/resources
// from an owned temporary project whose entry point is the diagnostic scene.
// The checkout and production main scene are never changed.
const qaScene=get('--qa-scene')??'res://tests/origin_profiles/verify-distribution.tscn';
if(!['res://tests/origin_profiles/verify-distribution.tscn','res://tests/party/verify-distribution.tscn','res://tests/expedition/verify-distribution.tscn','res://tests/adventure/review-flow.tscn'].includes(qaScene))throw Error('Unapproved diagnostic entry point');
if(a.includes('--qa')){
 const stage=mkdtempSync(join(tmpdir(),'trhgd-export-proof-'));
 try{
  for(const dir of ['assets','data','scenes','scripts','tests','themes'])if(existsSync(join(root,dir)))cpSync(join(root,dir),join(stage,dir),{recursive:true});
  cpSync(join(root,'export_presets.cfg'),join(stage,'export_presets.cfg'));
  writeFileSync(join(stage,'project.godot'),readFileSync(join(root,'project.godot'),'utf8').replace(/run\/main_scene="[^"]+"/,'run/main_scene="'+qaScene+'"'));
  execFileSync(engine,['--headless','--editor','--path',stage,'--quit'],{stdio:'inherit'});
  execFileSync(engine,['--headless','--path',stage,'--export-release',preset,join(target,process.platform==='win32'?'road-has-gone-dark-qa.exe':'road-has-gone-dark-qa')],{stdio:'inherit'});
 }finally{rmSync(stage,{recursive:true,force:true});}
}
cpSync(helper,join(target,'worldgen-helper'),{recursive:true});
// Preserve original redistributable source layers and credits outside the PCK.
cpSync(join(root,'assets/combat'),join(target,'artwork'),{recursive:true,filter:source=>!source.endsWith('.import')});
cpSync(join(root,'data/art/sources.json'),join(target,'artwork/sources.json'));
cpSync(join(root,'data/art/styles.json'),join(target,'artwork/styles.json'));
assertHelper(join(target,'worldgen-helper'));
execFileSync(engine,['--headless','--path',root,'--script','tools/release/export-notices.gd','--','--output',target],{cwd:root,stdio:'inherit'});
writeFileSync(join(target,'REGIONAL-ART-NOTICE.txt'),'Regional illustrations use the pinned MIT Town Forge provider (copyright and licence in worldgen-helper/vendor/town-forge/LICENSE). Selected Game-icons artwork by Delapouite and Lorc, https://game-icons.net/, is licensed CC BY 3.0, https://creativecommons.org/licenses/by/3.0/. Source shapes were recoloured for parchment ink and their old square backings removed. Exact source revisions and artist mappings are retained in worldgen-helper/assets/map_icons/trials/game-icons/landmark_sources.json and the adjacent README.md. No endorsement is implied.\n');
writeFileSync(join(target,'distribution.json'),JSON.stringify({schema_version:1,godot:version,platform:process.platform,arch:process.arch,enrichmentRuntimes:manifest.enrichmentRuntimes,executable_sha256:createHash('sha256').update(readFileSync(executable)).digest('hex')},null,2)+'\n');
console.log('Complete native offline distribution:',target);
