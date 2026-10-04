/** Replaceable provider boundary, extracted from GAME-21's actual pinned invocation. */
import {readFile,mkdir,writeFile} from 'node:fs/promises';
import {createRequire} from 'node:module';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {sourceContext,geometryPoints} from './source-context.mjs';
const PIN='4b25a37c14c80970d2b66f0c587468c7493855d3';
let providerPromise;
async function provider(){
 if(!providerPromise)providerPromise=(async()=>{
  const ts=createRequire(resolve('vendor/azgaar/package.json'))('typescript');
  const dist=resolve('tools/regiongen/.tmp/townforge-dist');await mkdir(dist,{recursive:true});
  await writeFile(resolve(dist,'package.json'),'{"type":"module"}\n');
  for(const name of ['types','rng','geometry','roads','mountains','landscape','buildings','generate']){
   const original=await readFile(resolve('vendor/town-forge/src',name+'.ts'),'utf8');
   const imports=original.replace(/from ["'](\.\/[^"']+)["']/g,(_whole,relative)=>'from "'+relative+'.js"');
   await writeFile(resolve(dist,name+'.js'),ts.transpileModule(imports,{compilerOptions:{module:ts.ModuleKind.ESNext,target:ts.ScriptTarget.ES2022}}).outputText);
  }
  return (await import(pathToFileURL(resolve(dist,'generate.js')).href)).generateFull;
 })();return providerPromise;
}
export async function townForgeDecoration(world,context){
 const {terrain,waterSide,forestMul}=sourceContext(world,context.source_home_burg_id,context.parent_cell.source_id);
 const seed=`local-cell:v1|${context.generation_world_seed}|cell:${context.parent_cell.source_id}`;
 const scene=(await provider())(terrain,seed,{mode:'landscape',roughness:.46,octaves:5,seaSide:waterSide??undefined,overrides:{forestDensity:forestMul},showRoads:false,showForest:true});
 return {schema_version:1,id:seed,provider:{name:'town-forge',version:'1.2.4',commit:PIN,mode:'landscape'},source:{world_sha256:context.parent_source_world_sha256,burg_id:context.source_home_burg_id},geometry:{forests:(scene.forests||[]).map(f=>geometryPoints(f.polygon)).filter(p=>p.length>=3),ridges:(scene.ridges||[]).map(geometryPoints).filter(p=>p.length>=2)}};
}
