// One existing packaged runtime. Original geography replay is verified, never substituted.
import {writeFileSync} from 'node:fs';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {loadWorld} from '../world_enrichment/source.mjs';
import {canonical} from '../world_enrichment/core.mjs';
import {generateCellRegion,renderRegion} from '../regiongen/generator-v1.mjs';
import {localContent,initialLeads} from './content.mjs';
import {ensureGeography} from './geography-cache.mjs';
process.chdir(resolve(dirname(fileURLToPath(import.meta.url)),'../..'));
const a=process.argv.slice(2);if(a.length!==8||a[0]!=='--world'||a[2]!=='--home'||a[4]!=='--cache'||a[6]!=='--output')throw Error('Expected world home cache output');
try{
 const w=loadWorld(a[1]),home=w.record('settlements',Number(a[3]));if(!home||home.hidden||home.removed)throw Error('Invalid hometown');
 const geometry=ensureGeography(w.source,w.base.sha256,resolve(a[5]));
 const region=await generateCellRegion(w.source,home.cell,w.base.sha256,geometry);
 const content=localContent(w,home,region),leads=initialLeads(w,home,content);
 // No hidden source or inferred-site labels/icons in base artwork. Gameplay markers
 // are a separate public-only Control layer; never rasterize secrets into a texture.
 region.local_sites_v2={schema_version:2,sites:[],rumours:[]};region.source_context.source_landmarks=[];region.export_scope='PUBLIC_KNOWN_ONLY';
 const svg=renderRegion(region).replace(/<text x="24" y="925"[\s\S]*?<\/text>/,'').replace(/<text x="20" y="978"[\s\S]*?<\/text>/,'');
 writeFileSync(a[7],canonical({ok:true,content,leads,svg}),{flag:'wx'});
}catch(e){console.error(e.stack);process.exitCode=1;}
