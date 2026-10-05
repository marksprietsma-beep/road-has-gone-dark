// Preserve original assertions; redirect only evidence paths and imports.
import {readFile,writeFile,mkdir,rm,copyFile} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
const root=process.cwd(),tmp=resolve('research/game71-72/.tmp'),evidence=resolve('research/game71-72/evidence');await mkdir(tmp,{recursive:true});
for(const task of ['game67','game69']){
 const original=resolve(`research/${task}/scripts/browser-check.mjs`),folder=resolve(`research/${task}`),output=resolve(tmp,task);await mkdir(output,{recursive:true});
 let source=await readFile(original,'utf8');source=source.replace("'../../../vendor/azgaar/node_modules/playwright/index.mjs'",JSON.stringify(pathToFileURL(resolve('vendor/azgaar/node_modules/playwright/index.mjs')).href));
 if(task==='game67')source=source.replace("const root=fileURLToPath(new URL('..',import.meta.url)),out=resolve(root,'evidence');",`const root=${JSON.stringify(folder)},out=${JSON.stringify(output)};`);
 else source=source.replace("const here=fileURLToPath(new URL('..',import.meta.url)),out=resolve(here,'evidence');",`const here=${JSON.stringify(folder)},out=${JSON.stringify(output)};`);
 const runner=resolve(tmp,`${task}.mjs`);await writeFile(runner,source);
 const result=spawnSync(process.execPath,[runner],{encoding:'utf8',env:{...process.env,GAME67_URL:'http://127.0.0.1:8769/game67/',GAME69_URL:'http://127.0.0.1:8769/game69/'}});
 await writeFile(resolve(evidence,task+'-browser-tests.txt'),result.stdout+result.stderr);if(result.status!==0)throw Error(task+' browser failed');
 await copyFile(resolve(output,'browser-results.json'),resolve(evidence,task+'-browser-results.json'));await rm(output,{recursive:true,force:true});console.log(result.stdout.trim());
}
