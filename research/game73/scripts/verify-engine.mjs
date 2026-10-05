// Read-only verification of public pinned sources; neither persist nor execute engine code.
import{readFile}from'node:fs/promises';import{createHash}from'node:crypto';
const m=JSON.parse(await readFile('research/game73/evidence/engine-source-verification.json'));
await Promise.all(m.files.map(async f=>{const response=await fetch(f.url);if(!response.ok)throw Error(f.path+': HTTP '+response.status);const bytes=Buffer.from(await response.arrayBuffer()),sha=createHash('sha256').update(bytes).digest('hex');if(sha!==f.sha256)throw Error('Pinned source mismatch '+f.path)}));
console.log('PASS seven pinned Settlemaker source/license hashes; read only, no engine execution or vendoring');
