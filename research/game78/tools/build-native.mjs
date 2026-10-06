// Evaluation-only source compilation; no dictionaries are adopted by this build.
import {stripTypeScriptTypes} from 'node:module';
import {readFileSync,writeFileSync,mkdirSync,readdirSync,cpSync} from 'node:fs';
import {join,resolve} from 'node:path';
import {execFileSync} from 'node:child_process';
const root=resolve(process.argv[2]??'/tmp/game77-audit'),out=resolve(process.argv[3]??'/tmp/game78-native');
const pins={lexiconlang:'da0a823e275d9642731bdaed1f3006d2c9bfae74',Rantjs:'c62d5b21b9da9be561c15afdccd5f352cdb91e64','fantasy-content-generator':'323aca8d0e946420cae59a315fbb2a9ba7958ec8'};
for(const [repo,sha]of Object.entries(pins))if(execFileSync('git',['-C',join(root,repo),'rev-parse','HEAD'],{encoding:'utf8'}).trim()!==sha)throw Error('Pin mismatch '+repo);
function compile(from,to){mkdirSync(to,{recursive:true});for(const d of readdirSync(from,{withFileTypes:true})){const s=join(from,d.name),t=join(to,d.name);if(d.isDirectory())compile(s,t);else if(d.name.endsWith('.ts')&&!/\.test\.|\.d\.ts$/.test(d.name))writeFileSync(t.replace(/\.ts$/,'.js'),stripTypeScriptTypes(readFileSync(s,'utf8'),{mode:'transform'}).replace(/\.ts(["'])/g,'.js$1'));}}
for(const p of ['core','grammar','markov','language','glyphs','fantasy']){const target=join(out,'node_modules/@lexiconlang',p);compile(join(root,'lexiconlang/packages',p,'src'),target);writeFileSync(join(target,'package.json'),JSON.stringify({type:'module',exports:'./index.js'}));}
compile(join(root,'Rantjs/src'),join(out,'rant'));writeFileSync(join(out,'rant/package.json'),'{"type":"module"}');
// FCG's native Node API is CommonJS; transpile its source, retain original JSON
// for evaluation only, and resolve the pinned seedrandom runtime from build tools.
const tsRoot=resolve(process.env.GAME78_BUILD_TOOLS??'/tmp/game78-build');const ts=(await import(tsRoot+'/node_modules/typescript/lib/typescript.js')).default;if(ts.version!=='5.6.3')throw Error('TypeScript pin mismatch');
function fcg(from,to){mkdirSync(to,{recursive:true});for(const d of readdirSync(from,{withFileTypes:true})){const s=join(from,d.name),t=join(to,d.name);if(d.isDirectory())fcg(s,t);else if(d.name.endsWith('.json'))cpSync(s,t);else if(d.name.endsWith('.ts')&&!/\.test\./.test(d.name))writeFileSync(t.replace(/\.ts$/,'.js'),ts.transpileModule(readFileSync(s,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2019,esModuleInterop:true,resolveJsonModule:true}}).outputText);}}
fcg(join(root,'fantasy-content-generator/src'),join(out,'fcg'));cpSync(join(tsRoot,'node_modules/seedrandom'),join(out,'node_modules/seedrandom'),{recursive:true});
writeFileSync(join(out,'build-pins.json'),JSON.stringify({pins,node:process.version,typescript:ts.version,transforms:'Node stripTypeScriptTypes + TS CommonJS transpile; native APIs/data unchanged'},null,2));console.log(out);
