/**
 * GAME-39: immutable Azgaar world-space constraints.
 * This is not a Town Forge adapter: it exposes what the source world actually
 * knows, and deliberately does not turn preview tracks into protected roads.
 */
export const PROJECTION_VERSION = 1;
export const WORLD_TILE_UNITS = 60; // Azgaar map Cartesian units, NOT km.
export const REGION_RENDER_UNITS = 1000;
const EPS = 1e-8;
const near = (a,b) => Math.abs(a-b) < EPS;
const finitePoint = p => Array.isArray(p) && p.length >= 2
  && Number.isFinite(p[0]) && Number.isFinite(p[1]);
const rounded = n => Math.round(n * 1e8) / 1e8;
const keypoint = n => rounded(n).toFixed(8);
const assertInt = n => {if(!Number.isSafeInteger(n))throw Error("Tile or source ID must be a safe integer");return n};
const point = p => [rounded(p[0]),rounded(p[1])];

function checkWorld(world) {
 if(world?.schemaVersion!==1 || world.generator?.provider!=="azgaar"
   || !Number.isFinite(world.map?.width)||!Number.isFinite(world.map?.height))
   throw Error("Expected a canonical Azgaar world with Cartesian map dimensions");
 if(!Array.isArray(world.cells?.ids) || !Array.isArray(world.cells.points)
   || world.cells.ids.length!==world.cells.points.length
   || !Array.isArray(world.routes)||!Array.isArray(world.rivers)
   || !Array.isArray(world.settlements))throw Error("Source world collections missing");
 const index=new Map();
 world.cells.ids.forEach((id,i)=>{
  if(!Number.isSafeInteger(id)||index.has(id)||!finitePoint(world.cells.points[i]))
   throw Error("Invalid/duplicate Azgaar cell position/ID");
  index.set(id,i);
 });
 return index;
}

/**
 * Absolute world grid. Do not confuse these with GAME-21's old per-cell
 * experimental --x/--y seeds. Tile identity is independent of entry burg.
 */
export function tileForPoint(world, p, side=WORLD_TILE_UNITS) {
 if(!finitePoint(p)||!Number.isFinite(side)||side<=0)throw Error("Invalid tile projection");
 if(p[0]<0||p[1]<0||p[0]>world.map.width||p[1]>world.map.height)
  throw Error("Point outside source world");
 // Last map-edge point belongs to its final cell, not a phantom next tile.
 return [Math.floor(Math.min(p[0],world.map.width-EPS)/side),
         Math.floor(Math.min(p[1],world.map.height-EPS)/side)];
}
export function tileForBurg(world, burgId, side=WORLD_TILE_UNITS) {
 const index=checkWorld(world);
 const burgs=world.settlements.filter(b=>b?.i===burgId&&!b.hidden&&!b.removed);
 if(burgs.length!==1||!index.has(burgs[0].cell))throw Error("Unknown active source burg");
 const b=burgs[0];
 const coords=Number.isFinite(b.x)&&Number.isFinite(b.y)?[b.x,b.y]:world.cells.points[index.get(b.cell)];
 return tileForPoint(world,coords,side);
}
export function tileForCell(world, cellId, side=WORLD_TILE_UNITS) {
 const index=checkWorld(world);
 if(!index.has(cellId))throw Error("Unknown source cell");
 return tileForPoint(world,world.cells.points[index.get(cellId)],side);
}
export function tileBounds(x,y,side=WORLD_TILE_UNITS) {
 assertInt(x);assertInt(y);
 if(!Number.isFinite(side)||side<=0)throw Error("Invalid world tile span");
 return {left:x*side,top:y*side,right:(x+1)*side,bottom:(y+1)*side};
}

// Liang-Barsky inclusive clipping, performed in world-space before converting
// to 1000-unit renderer coordinates. Drop point-only tangencies.
export function clipSegment(a,b,rect) {
 if(!finitePoint(a)||!finitePoint(b))throw Error("Invalid source segment");
 let low=0,high=1;
 const dx=b[0]-a[0],dy=b[1]-a[1];
 if(Math.hypot(dx,dy)<EPS)return null;
 for(const [p,q] of [[-dx,a[0]-rect.left],[dx,rect.right-a[0]],
                      [-dy,a[1]-rect.top],[dy,rect.bottom-a[1]]]){
  if(Math.abs(p)<EPS){if(q<-EPS)return null;continue}
  const t=q/p;
  if(p<0)low=Math.max(low,t);else high=Math.min(high,t);
  if(low>high+EPS)return null;
 }
 if(high-low<=EPS)return null;
 return {a:point([a[0]+dx*low,a[1]+dy*low]),
         b:point([a[0]+dx*high,a[1]+dy*high])};
}
function sourceLineRecords(world,index) {
 const output=[],add=(kind,id,group,points,precision)=>{
  if(!Number.isSafeInteger(id)||!Array.isArray(points))throw Error("Malformed source polyline");
  if(points.some(p=>!finitePoint(p)))throw Error("Nonfinite source polyline point");
  if(points.length>1)output.push({kind,id,group,precision,points});
 };
 const seen=new Set();
 for(const r of world.routes){
  if(!r)continue;
  if(seen.has("route:"+r.i))throw Error("Duplicate Azgaar route ID");
  seen.add("route:"+r.i);
  add("route",r.i,r.group||"unknown",r.points||[],"source_route_vertices");
 }
 for(const r of world.rivers){
  if(!r)continue;
  if(seen.has("river:"+r.i))throw Error("Duplicate Azgaar river ID");
  seen.add("river:"+r.i);
  if(!Array.isArray(r.cells))throw Error("River missing source cell chain");
  const positions=r.cells.map(c=>{
   if(!index.has(c))throw Error("River refers to unknown cell");
   return world.cells.points[index.get(c)];
  });
  // Original river record contains cell chain, not an exact surveyed path.
  add("river",r.i,r.type||"river",positions,"source_cell_centres_approximation");
 }
 return output;
}
const worldToLocal=(p,bounds,side)=>[
 rounded((p[0]-bounds.left)*REGION_RENDER_UNITS/side),
 rounded((p[1]-bounds.top)*REGION_RENDER_UNITS/side)
];
const crosses=(a,b,c)=>(a<c-EPS&&b>c+EPS)||(b<c-EPS&&a>c+EPS);
function segmentCrossings(originalA,originalB,clipped,rect,x,y,side,kind,id,segment) {
 const contacts=[];
 for(const p of [clipped.a,clipped.b]){
  for(const [axis,sideName,at,coordinate,cross] of [
   ["vertical","west",rect.left,p[1],crosses(originalA[0],originalB[0],rect.left)],
   ["vertical","east",rect.right,p[1],crosses(originalA[0],originalB[0],rect.right)],
   ["horizontal","north",rect.top,p[0],crosses(originalA[1],originalB[1],rect.top)],
   ["horizontal","south",rect.bottom,p[0],crosses(originalA[1],originalB[1],rect.bottom)]
  ]){
   const match=axis==="vertical"?near(p[0],at):near(p[1],at);
   if(!match||!cross)continue; // Exclude tangencies and collinear segments.
   const index=axis==="vertical"?sideName==="west"?x:x+1:sideName==="north"?y:y+1;
   const boundaryKey=[kind,id,segment,axis,index,keypoint(coordinate)].join(":");
   contacts.push({boundary_key:boundaryKey,side:sideName,axis,
    source_kind:kind,source_id:id,segment,world_point:p,
    local_point:worldToLocal(p,rect,side),safety:"unverified"});
  }
 }
 return [...new Map(contacts.map(c=>[c.boundary_key,c])).values()];
}
export function projectSourceTile(world,{x,y,world_sha256,side=WORLD_TILE_UNITS}={}) {
 const index=checkWorld(world);
 assertInt(x);assertInt(y);
 if(typeof world_sha256!=="string"||!/^[0-9a-f]{64}$/.test(world_sha256))
  throw Error("Full immutable source fingerprint required");
 const rect=tileBounds(x,y,side),segments=[],crossings=[],burgs=[];
 const ordered=sourceLineRecords(world,index);
 for(const source of ordered) for(let i=0;i<source.points.length-1;i++){
  const a=source.points[i],b=source.points[i+1],cut=clipSegment(a,b,rect);
  if(!cut)continue;
  const local=([u,v])=>worldToLocal([u,v],rect,side);
  segments.push({source_kind:source.kind,source_id:source.id,source_group:source.group,
   source_precision:source.precision,segment:i,world_points:[cut.a,cut.b],
   local_points:[local(cut.a),local(cut.b)],safety:"unverified"});
  crossings.push(...segmentCrossings(a,b,cut,rect,x,y,side,source.kind,source.id,i));
 }
 for(const b of world.settlements){
  if(!b||!Number.isSafeInteger(b.i)||b.hidden||b.removed)continue;
  if(!index.has(b.cell))throw Error("Source burg has unknown cell");
  const p=Number.isFinite(b.x)&&Number.isFinite(b.y)?[b.x,b.y]:world.cells.points[index.get(b.cell)];
  if(tileForPoint(world,p,side).join(",")!==[x,y].join(","))continue;
  burgs.push({id:b.i,label:b.name,source_cell_id:b.cell,world_point:point(p),
   local_point:worldToLocal(p,rect,side),provenance:"azgaar_burg"});
 }
 segments.sort((a,b)=>a.source_kind.localeCompare(b.source_kind)||a.source_id-b.source_id||a.segment-b.segment);
 crossings.sort((a,b)=>a.boundary_key.localeCompare(b.boundary_key)||a.side.localeCompare(b.side));
 burgs.sort((a,b)=>a.id-b.id);
 return {
  schema_version:1,projection_version:PROJECTION_VERSION,
  tile_id:"azgaar-rect:v1:"+world_sha256+":side:"+side+":"+x+","+y,
  world_sha256,grid:{x,y,source_units_per_side:side,render_units:REGION_RENDER_UNITS,
   physical_km:"UNCALIBRATED_AZGAAR_MAP_UNITS_NOT_KM"},
  bounds:rect,burgs,segments,crossings,
  coastline:{status:"UNSUPPORTED_NO_VERTEX_COORDINATES",note:"Feature vertex indices lack packed graph vertex coordinates in the canonical fixture. No coast shape is asserted."},
  river_geometry:"SOURCE_CELL_CENTRES_APPROXIMATION_NOT_EXACT_COURSE",
  protection:"NO_PATROL_OR_SAFE_ROAD_STATUS_IN_SOURCE"
 };
}
