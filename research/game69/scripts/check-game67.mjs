// Execute every assertion in the existing GAME-67 browser runner unchanged,
// redirecting only module paths and output location to avoid parent-file edits.
import {readFile,writeFile,mkdtemp,rm,copyFile} from 'node:fs/promises';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
const here=fileURLToPath(new URL('..',import.meta.url)),root=resolve(here,'../..');
const source=await readFile(resolve(root,'research/game67/scripts/browser-check.mjs'),'utf8');
const temp=await mkdtemp(join(tmpdir(),'game69-game67-check-'));
const output=join(temp,'evidence');
const modified=source.replace("'../../../vendor/azgaar/node_modules/playwright/index.mjs'",JSON.stringify(pathToFileURL(resolve(root,'vendor/azgaar/node_modules/playwright/index.mjs')).href)).replace("const root=fileURLToPath(new URL('..',import.meta.url)),out=resolve(root,'evidence');",`const root=${JSON.stringify(resolve(root,'research/game67'))},out=${JSON.stringify(output)};`);
if(modified===source)throw Error('Inherited runner path redirection failed');
process.env.GAME67_URL=process.env.GAME69_PARENT_URL||'http://127.0.0.1:8769/game67/';
try{const executable=join(temp,'browser-check.mjs');await writeFile(executable,modified);await import(pathToFileURL(executable));await copyFile(join(output,'browser-results.json'),resolve(here,'evidence/game67-browser-results.json'));}finally{await rm(temp,{recursive:true,force:true})}
