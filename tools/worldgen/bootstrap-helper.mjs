#!/usr/bin/env node
// Development-only offline-helper provisioning. Players receive the completed distribution.
import{existsSync,readFileSync,writeFileSync,mkdirSync,renameSync,rmSync}from'node:fs';import{join,resolve,dirname}from'node:path';import{execFileSync}from'node:child_process';import{createHash}from'node:crypto';
import{root,assertHelper,expectedRuntimes}from'./helper-contract.mjs';
const args=process.argv.slice(2),value=key=>args.includes(key)?args[args.indexOf(key)+1]:null;
const output=resolve(value('--output')??join(root,'worldgen-helper'));
const known=new Set(['--output','--runtime-license']);for(let i=0;i<args.length;i+=2)if(!known.has(args[i])||!args[i+1])throw Error('Use --output <directory> and optionally --runtime-license <Node LICENSE>');
if(process.version!=='v24.19.0')throw Error('Development bootstrap requires Node v24.19.0; players use bundled Node only');
try{assertHelper(output);console.log('Matching helper already provisioned:',output);process.exit(0);}catch{}
const pin=expectedRuntimes()['profiles-v2'].slice(0,12),candidate=output+'.pending-'+process.pid,backup=output+'.previous-'+pin;
if(existsSync(output)){
 let owned;try{owned=JSON.parse(readFileSync(join(output,'runtime.json'))).helperVersion===1;}catch{}
 if(!owned)throw Error('Existing output is not an owned world helper; nothing was replaced');
 if(existsSync(backup))throw Error('Preserved helper backup already exists: '+backup);
}
let license=value('--runtime-license');
if(!license){
 const cache=join(root,'.local/worldgen-bootstrap');mkdirSync(cache,{recursive:true});license=join(cache,'NODE-LICENSE');
 if(!existsSync(license)){const response=await fetch('https://raw.githubusercontent.com/nodejs/node/v24.19.0/LICENSE');if(!response.ok)throw Error('Cannot obtain official Node license');writeFileSync(license,Buffer.from(await response.arrayBuffer()));}
}
if(createHash('sha256').update(readFileSync(license)).digest('hex')!=='148eacf7863ef4329224a29398623077200a27194aa075569faf4a0a85566ca5')throw Error('Official Node license checksum mismatch');
if(!existsSync(join(root,'vendor/azgaar/node_modules/vite')))execFileSync(process.platform==='win32'?'npm.cmd':'npm',['ci','--ignore-scripts','--prefix','vendor/azgaar'],{cwd:root,stdio:'inherit',shell:process.platform==='win32'});
try{
 execFileSync(process.execPath,[join(root,'tools/worldgen/package-helper.mjs'),'--output',candidate,'--runtime-license',resolve(license)],{cwd:root,stdio:'inherit'});
 assertHelper(candidate);
 if(existsSync(output))renameSync(output,backup);
 renameSync(candidate,output);
 console.log('Provisioned verified helper:',output);
 if(existsSync(backup))console.log('Previous helper preserved:',backup);
}catch(e){if(existsSync(candidate))rmSync(candidate,{recursive:true,force:true});if(!existsSync(output)&&existsSync(backup))renameSync(backup,output);throw e;}
