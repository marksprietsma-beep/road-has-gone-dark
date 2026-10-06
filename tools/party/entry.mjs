// Deliberate helper invocation. Godot alone owns campaign transactions.
import {readFileSync,writeFileSync,mkdirSync} from 'node:fs';
import {resolve,dirname,join} from 'node:path';
import {canonical} from '../world_enrichment/core.mjs';
import {compilePeoples,publishPeoples} from './peoples.mjs';
import {createParty,editParty,validateParty} from './generator.mjs';
const args=process.argv.slice(2),value=k=>args[args.indexOf(k)+1];
try{
 if(args.length!==8||args[0]!=='--world'||args[2]!=='--peoples'||args[4]!=='--request'||args[6]!=='--output')throw Error('Expected --world --peoples --request --output');
 const world=resolve(value('--world')),directory=resolve(value('--peoples')),request=JSON.parse(readFileSync(value('--request'),'utf8'));
 if(request.operation==='ensure'){
  publishPeoples(directory,world);
  mkdirSync(dirname(value('--output')),{recursive:true});writeFileSync(value('--output'),canonical({ok:true,descriptor:JSON.parse(readFileSync(join(directory,'descriptor.json')))}),{flag:'wx'});
 }else{
  const out=compilePeoples(world);
  if(readFileSync(join(directory,'enrichment.json'),'utf8')!==out.bytes||canonical(JSON.parse(readFileSync(join(directory,'descriptor.json'))))!==canonical(out.descriptor))throw Error('People package integrity failure');
  let party;
  if(request.operation==='generate')party=request.campaign.party??createParty(out,request.campaign,out.descriptor);
  else if(request.operation==='edit')party=editParty(out,request.campaign,request.slot,request.changes);
  else if(request.operation==='ready'){party=structuredClone(request.campaign.party);party.status='ready';}
  else throw Error('Unsupported party operation');
  validateParty(party,out,request.campaign);
  mkdirSync(dirname(value('--output')),{recursive:true});writeFileSync(value('--output'),canonical({ok:true,party}),{flag:'wx'});
 }
}catch(e){console.error(String(e.message));process.exitCode=1;}
