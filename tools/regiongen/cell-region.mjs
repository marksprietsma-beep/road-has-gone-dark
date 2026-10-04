/** GAME-62. Source-cell ownership and globally anchored coordinates. No game rules. */
import {createHash} from 'node:crypto';
import {checkGeographySidecar} from '../worldgen/geography-sidecar.mjs';
import {buildLocalContext,toLocalPoint} from './local-source-context.mjs';
import {insidePolygon,sourceDryLand} from './compose-local-region.mjs';
export const REGION_VERSION=1;
export const FRINGE_FRACTION=.2;
export const hash=s=>createHash('sha256').update(s).digest('hex');
export const polygonArea=p=>Math.abs(p.reduce((s,a,i)=>{const b=p[(i+1)%p.length];return s+a[0]*b[1]-b[0]*a[1]},0))/2;
export function sourceCellPolygon(world,sidecar,cellId){
 const index=world.cells.ids.indexOf(cellId);
 if(index<0||sidecar.cell_geometry!=='original_pack.cells.v'||sidecar.cell_vertex_ids?.length!==world.cells.ids.length)throw Error('Missing original Azgaar cell geometry');
 const ids=sidecar.cell_vertex_ids[index];
 if(!Array.isArray(ids)||ids.length<3||new Set(ids).size!==ids.length)throw Error('Malformed original cell polygon');
 const poly=ids.map(id=>{if(!Number.isSafeInteger(id)||!sidecar.vertices[id])throw Error('Unknown cell vertex');return sidecar.vertices[id]});
 if(polygonArea(poly)<1e-6||!insidePolygon(world.cells.points[index],poly))throw Error('Invalid original cell geometry');
 return poly;
}
export function buildCellContext(world,cellId,fingerprint,sidecar){
 checkGeographySidecar(world,sidecar,fingerprint);
 const index=world.cells.ids.indexOf(cellId);
 if(index<0||world.cells.heights[index]<20)throw Error('Selected cell must be source land');
 const polygon=sourceCellPolygon(world,sidecar,cellId);
 const homes=world.settlements.filter(b=>b?.i>0&&b.cell===cellId&&!b.removed&&!b.hidden).sort((a,b)=>a.i-b.i);
 const xs=polygon.map(p=>p[0]),ys=polygon.map(p=>p[1]);
 const extent=Math.max(Math.max(...xs)-Math.min(...xs),Math.max(...ys)-Math.min(...ys));
 const span=extent*(1+2*FRINGE_FRACTION),cx=(Math.max(...xs)+Math.min(...xs))/2,cy=(Math.max(...ys)+Math.min(...ys))/2;
 const left=Math.max(0,Math.min(world.map.width-span,cx-span/2)),top=Math.max(0,Math.min(world.map.height-span,cy-span/2));
 const bounds={left,top,right:left+span,bottom:top+span};
 const context=buildLocalContext(world,homes[0]?.i??null,fingerprint,sidecar,span,bounds,cellId);
 // Label-independent identity; immutable file SHA remains separate provenance.
 const stableWorld=hash(JSON.stringify([world.seed,world.generator,world.map.width,world.map.height,world.cells.ids,world.cells.points,world.cells.heights,world.cells.biome,sidecar.vertices]));
 context.generation_world_seed=stableWorld;
 context.id=`local-cell:v1:${stableWorld}:cell:${cellId}`;
 context.parent_cell={source_id:cellId,provenance:'source_exact',vertex_ids:sidecar.cell_vertex_ids[index],world_polygon:polygon,local_polygon:polygon.map(p=>toLocalPoint(p,bounds)),source_area:world.cells.area[index],polygon_area:polygonArea(polygon),burg_ids:homes.map(b=>b.i)};
 context.space.version=REGION_VERSION;
 context.space.ownership='one_original_azgaar_cell';
 context.space.fringe={fraction_of_longest_cell_extent:FRINGE_FRACTION,rule:'Square enclosing original cell bounds plus 20% longest extent on each side; shifted at world edges'};
 context.space.original_map_units=span;
 context.space.hex_pitch_source_units=1;
 context.constraints.provider_interior='SOURCE_FILTERED_DECORATION_ONLY';
 context.source_cells=[cellId,...world.cells.neighbors[index]].sort((a,b)=>a-b).map(id=>({source_id:id,world_polygon:sourceCellPolygon(world,sidecar,id),provenance:'source_exact'}));
 // Preserve macro landmarks in a separate developer truth list. No world knowledge
 // state exists in canonical Azgaar, so public landmarks need explicit discovery.
 context.source_landmarks=(world.markers||[]).filter(m=>Number.isFinite(m.x)&&Number.isFinite(m.y)&&m.x>=bounds.left&&m.x<=bounds.right&&m.y>=bounds.top&&m.y<=bounds.bottom).map(m=>({id:`macro:${stableWorld}:${m.i}`,source_id:m.i,kind:m.type,label:m.name,position:toLocalPoint([m.x,m.y],bounds),knowledge:['volcanoes','waterfalls','sacred-mountains','lighthouses'].includes(m.type)&&!m.hidden?'discovered':'hidden',provenance:'source_exact'}));
 return context;
}
export function isOwnedDryLand(context,p){return insidePolygon(p,context.parent_cell.local_polygon)&&sourceDryLand(context,p)}
