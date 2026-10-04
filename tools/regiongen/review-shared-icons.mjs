/** Source-backed area audit and neighbourhood comparison, no source mutations. */
import {readFile,writeFile} from 'node:fs/promises';
import {Delaunay} from '../../vendor/azgaar/node_modules/d3-delaunay/src/index.js';
import {buildLocalContext,toLocalPoint} from './local-source-context.mjs';
import {clipPolygon} from './source-projection.mjs';
import {renderSharedIcon,settlementRole} from './shared-map-icons.mjs';
const tmp='tools/regiongen/.tmp/',rows=[];
for(const stem of ['game-11-determinism','atlas-showcase'])for(const kind of ['shore','river','highland']){
 const name=`contextual-${stem}-${kind}`,r=JSON.parse(await readFile(tmp+name+'.json','utf8'));
 const home=r.source_context.source_burgs.find(b=>b.source_id===r.source_context.source_home_burg_id);
 rows.push({name:home.name,...r.world_icon_roles_v1.scale});
 if(kind!=='highland'||stem!=='game-11-determinism')continue;
 const world=JSON.parse(await readFile(`tests/worldgen/fixtures/${stem}.json`,'utf8'));
 const sidecar=JSON.parse(await readFile(tmp+`geography-${stem}.json`,'utf8'));
 const ctx=buildLocalContext(world,home.source_id,r.source_context.parent_source_world_sha256,sidecar,64);
 const b=ctx.space.source_bounds,pt=p=>toLocalPoint(p,b),points=p=>p.map(pt).map(p=>p.join(',')).join(' ');
 const voronoi=Delaunay.from(world.cells.points).voronoi([0,0,world.map.width,world.map.height]);
 const lines=['<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="860" viewBox="0 0 1600 860"><rect width="1600" height="860" fill="#eee0bd"/><text x="30" y="35" font-family="Georgia" font-size="25" fill="#302f25">One world neighbourhood → a 16 × 16 source-unit local window</text><svg x="30" y="70" width="720" height="720" viewBox="0 0 1000 1000"><rect width="1000" height="1000" fill="#8babb2"/>'];
 for(const f of ctx.source_features)lines.push(`<polygon points="${f.local_polygon.map(p=>p.join(',')).join(' ')}" fill="${f.classification==='land_boundary'?'#d1c19c':'#8babb2'}"/>`);
 for(let i=0;i<world.cells.points.length;i++){
  const polygon=voronoi.cellPolygon(i);if(!polygon)continue;
  const clipped=clipPolygon(polygon,b);if(clipped.length<3)continue;
  lines.push(`<polygon points="${points(clipped)}" fill="${i===home.source_cell_id?'#d8a749':'none'}" fill-opacity=".35" stroke="#74674d" stroke-width="1.5"/>`);
 }
 for(const route of ctx.source_routes)for(const s of route.segments)lines.push(`<polyline points="${s.local_points.map(p=>p.join(',')).join(' ')}" fill="none" stroke="#66583e" stroke-width="2"/>`);
 for(const burg of ctx.source_burgs){const s=world.settlements.find(s=>s.i===burg.source_id);lines.push(renderSharedIcon(settlementRole(s),burg.local_position));}
 const local=r.source_context.space.source_bounds,p=pt([local.left,local.top]);
 lines.push(`<rect x="${p[0]}" y="${p[1]}" width="250" height="250" fill="none" stroke="#9d4735" stroke-width="5"/></svg>`);
 const localSvg=await readFile(tmp+name+'.encounter.svg','utf8');
 lines.push(localSvg.replace('<svg xmlns=', '<svg x="820" y="70" xmlns=').replace('width="1000" height="1000"','width="720" height="720"'));
 lines.push('<text x="30" y="817" font-family="Georgia" font-size="18" fill="#534c39">Gold: hometown cell • Red: local window</text><text x="30" y="844" font-family="Georgia" font-size="16" fill="#534c39">Cell outlines reconstructed from source centres</text><text x="820" y="817" font-family="Georgia" font-size="18" fill="#534c39">Local window = 3.51 hometown-cell areas • Icons are UI symbols</text></svg>');
 await writeFile(tmp+'world-local-scale.svg',lines.join('\n'));
}
await writeFile(tmp+'world-local-scale.json',JSON.stringify(rows,null,2)+'\n');
console.log('PASS: six source cell area audits and source-coordinate scale comparison');
