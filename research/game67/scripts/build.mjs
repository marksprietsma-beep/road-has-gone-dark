import {readFile,writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';
import {adapt,canonical} from '../adapter.mjs';
import {publicExport,setKnowledge} from '../model.mjs';
const root=fileURLToPath(new URL('..',import.meta.url));
for (const slug of ['batan','albanes','thilranlena']) {
  const source=JSON.parse(await readFile(resolve(root,'fixtures',slug+'.json'),'utf8'));
  let model=adapt(source);
  // A hypothetical research discovery scenario on REAL facilities, not a claim
  // about current game knowledge. Exactly one actual city shop is undiscovered.
  const hidden=model.establishments.find(e=>e.type==='shop');
  if (hidden) model=setKnowledge(model,hidden.id,'unknown');
  model.scenario='Hypothetical research knowledge state; facilities and geometry are original source data';
  for (const [audience,data] of [['developer',model],['public',publicExport(model)]]) await writeFile(resolve(root,'samples',`${slug}.${audience}.json`),canonical(data)+'\n');
  console.log(slug,model.sourceInventory,'outdoor',model.establishments.filter(e=>e.locationType==='outdoor').length,'diagnostics',model.diagnostics.length);
}
