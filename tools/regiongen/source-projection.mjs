/**
 * GAME-39 v1: source-derived world-space and edge constraints.
 *
 * This does NOT replace Town Forge landscape interiors or claim a calibrated
 * physical-world scale. Azgaar canonical coordinates are one shared global
 * frame: every burg in the same square selects the same tile. Azgaar routes
 * carry actual [x,y,cell] points; rivers currently expose only cell IDs,
 * so lines joining their cell centres are explicitly APPROXIMATE.
 */
export const PROJECTION_VERSION = 1;
export const WORLD_UNITS_PER_TILE = 64;
export const REGION_DISPLAY_UNITS = 1000;
const EPS = 1e-8;
const fixed = value => Math.round(value * 1e6) / 1e6;
const valid = p => Array.isArray(p) && p.length >= 2 &&
  Number.isFinite(p[0]) && Number.isFinite(p[1]);
const normalize = p => [Number(p[0]), Number(p[1])];

function validate(world) {
 if (world?.schemaVersion !== 1 || world.generator?.provider !== "azgaar") throw Error("Expected canonical Azgaar world");
 const {width,height} = world.map || {};
 if (!(Number.isFinite(width) && Number.isFinite(height) && width>0 && height>0)) throw Error("Invalid map coordinate dimensions");
 if (!Array.isArray(world.cells?.ids) || !Array.isArray(world.cells?.points) ||
     world.cells.ids.length !== world.cells.points.length) throw Error("Invalid canonical cell points");
 if (!Array.isArray(world.routes) || !Array.isArray(world.rivers) || !Array.isArray(world.settlements))
   throw Error("Missing canonical source routes/rivers/settlements");
 const ids=new Map();
 world.cells.ids.forEach((id,i)=>{
  if (!Number.isSafeInteger(id)||ids.has(id)||!valid(world.cells.points[i]))
   throw Error("Duplicate or invalid canonical source cell");
  ids.set(id,i);
 });
 return ids;
}
function validBurg(b) {return b && Number.isSafeInteger(b.i) && b.i>0 && !b.hidden && !b.removed && Number.isFinite(b.x) && Number.isFinite(b.y)}
function assertBounds(world,p) {
 if (!(p[0]>=-EPS && p[0]<=world.map.width+EPS && p[1]>=-EPS && p[1]<=world.map.height+EPS))
  throw Error("Source coordinates outside world bounds");
}
export function tileForPosition(x,y,world) {
 if (!Number.isFinite(x)||!Number.isFinite(y))throw Error("Invalid world point");
 assertBounds(world,[x,y]);
 // The extreme right/bottom boundary is a valid final point in its final tile.
 return [Math.floor(Math.min(x,world.map.width-EPS)/WORLD_UNITS_PER_TILE),
         Math.floor(Math.min(y,world.map.height-EPS)/WORLD_UNITS_PER_TILE)];
}
export function tileForBurg(world,burgId) {
 validate(world);
 const matches=world.settlements.filter(b=>b?.i===burgId);
 if(matches.length!==1 || !validBurg(matches[0]))throw Error("Unknown/hidden source burg");
 assertBounds(world,[matches[0].x,matches[0].y]);
 return tileForPosition(matches[0].x,matches[0].y,world);
}
export function tileBounds(tx,ty) {
 if(!Number.isSafeInteger(tx)||!Number.isSafeInteger(ty))throw Error("Tile indices must be integers");
 const x=tx*WORLD_UNITS_PER_TILE,y=ty*WORLD_UNITS_PER_TILE;
 return {left:x,right:x+WORLD_UNITS_PER_TILE,top:y,bottom:y+WORLD_UNITS_PER_TILE};
}
export function toLocal(worldPoint,tx,ty) {
 const b=tileBounds(tx,ty);
 return [fixed((worldPoint[0]-b.left)*REGION_DISPLAY_UNITS/WORLD_UNITS_PER_TILE),
         fixed((worldPoint[1]-b.top)*REGION_DISPLAY_UNITS/WORLD_UNITS_PER_TILE)];
}
export function fromLocal(local,tx,ty){
 const b=tileBounds(tx,ty);
 return [fixed(b.left+local[0]*WORLD_UNITS_PER_TILE/REGION_DISPLAY_UNITS),
         fixed(b.top+local[1]*WORLD_UNITS_PER_TILE/REGION_DISPLAY_UNITS)];
}
const inside = (p,b) => p[0]>=b.left-EPS && p[0]<=b.right+EPS && p[1]>=b.top-EPS && p[1]<=b.bottom+EPS;

/** Exact segment clipping in the source frame; coincident boundary segments
 * are reported as line geometry, not invented "crossing ports". */
export function clipSegment(a,b,bounds) {
 if(!valid(a)||!valid(b))throw Error("Invalid source polyline segment");
 const dx=b[0]-a[0],dy=b[1]-a[1];let lo=0,hi=1;
 const tests=[[-dx,a[0]-bounds.left],[dx,bounds.right-a[0]],[-dy,a[1]-bounds.top],[dy,bounds.bottom-a[1]]];
 for(const [p,q] of tests) {
  if(Math.abs(p)<EPS){if(q<-EPS)return null;continue}
  const r=q/p;
  if(p<0){if(r>hi+EPS)return null;lo=Math.max(lo,r)}
  else {if(r<lo-EPS)return null;hi=Math.min(hi,r)}
 }
 if(lo>hi+EPS)return null;
 return [[fixed(a[0]+dx*lo),fixed(a[1]+dy*lo)],
         [fixed(a[0]+dx*hi),fixed(a[1]+dy*hi)]];
}
export function canonicalBoundary(tx,ty,side) {
 const b=tileBounds(tx,ty);
 if(side==="W")return "V:"+b.left+":"+ty;
 if(side==="E")return "V:"+b.right+":"+ty;
 if(side==="N")return "H:"+tx+":"+b.top;
 if(side==="S")return "H:"+tx+":"+b.bottom;
 throw Error("Unknown boundary side");
}
function sourcePaths(world,idIndex) {
 const result=[];
 for(const route of world.routes) {
  if(!route || !Number.isSafeInteger(route.i) || !Array.isArray(route.points))continue;
  const points=route.points.filter(valid).map(normalize);
  if(points.length>=2)result.push({id:"route:"+route.i,kind:"azgaar_route",
   source_id:route.i,group:route.group||"unknown",geometry:"original_azgaar_route_points",points});
 }
 for(const river of world.rivers) {
  if(!river||!Number.isSafeInteger(river.i)||!Array.isArray(river.cells))continue;
  const pts=[];
  for(const cellID of river.cells){
   const i=idIndex.get(cellID);
   if(i===undefined)continue;
   const p=normalize(world.cells.points[i]);
   if(!pts.length || pts.at(-1)[0]!==p[0]||pts.at(-1)[1]!==p[1])pts.push(p);
  }
  if(pts.length>=2)result.push({id:"river:"+river.i,kind:"azgaar_river",
   source_id:river.i,geometry:"approximation_from_source_river_cells_not_actual_course",points:pts});
 }
 return result.sort((a,b)=>a.id.localeCompare(b.id));
}
function segmentIntersections(a,z,bounds,tx,ty) {
 const dx=z[0]-a[0],dy=z[1]-a[1],hits=[];
 const edges=[["W",bounds.left,"x"],["E",bounds.right,"x"],
              ["N",bounds.top,"y"],["S",bounds.bottom,"y"]];
 for(const [side,v,axis] of edges) {
  const along=axis==="x"?dx:dy,initial=axis==="x"?a[0]:a[1];
  if(Math.abs(along)<EPS)continue; // tangent/coincident is not a crossing
  const t=(v-initial)/along;
  if(t < -EPS||t>1+EPS)continue;
  const point=[a[0]+dx*t,a[1]+dy*t];
  const other=axis==="x"?point[1]:point[0];
  const min=axis==="x"?bounds.top:bounds.left,max=axis==="x"?bounds.bottom:bounds.right;
  if(other<min-EPS||other>max+EPS)continue;
  // One canonical event on a corner may belong to two physical sides.
  hits.push({side,boundary:canonicalBoundary(tx,ty,side),world_position:point.map(fixed)});
 }
 return hits;
}
export function buildTileConstraints(world,tx,ty,worldFingerprint) {
 const index=validate(world),bounds=tileBounds(tx,ty);
 if(bounds.left>=world.map.width||bounds.top>=world.map.height||bounds.right<=0||bounds.bottom<=0)
  throw Error("Region tile outside the Azgaar map");
 if(!worldFingerprint || typeof worldFingerprint!=="string")throw Error("Need immutable world fingerprint");
 const burgs=world.settlements.filter(validBurg).filter(b=>inside([b.x,b.y],bounds))
  .filter(b=>{const t=tileForPosition(b.x,b.y,world);return t[0]===tx&&t[1]===ty})
  .map(b=>({source_id:b.i,label:b.name,cell_id:b.cell,world_position:[b.x,b.y].map(fixed),
            local_position:toLocal([b.x,b.y],tx,ty),provenance:"azgaar_burg"}))
  .sort((a,b)=>a.source_id-b.source_id);
 const segments=[],crossings=[],observed=new Set(),features=sourcePaths(world,index);
 for(const path of features)for(let i=0;i<path.points.length-1;i++){
  const a=path.points[i],z=path.points[i+1],cut=clipSegment(a,z,bounds);
  if(!cut)continue;
  segments.push({source:path.id,kind:path.kind,group:path.group,
    geometry: path.geometry,source_segment:i,world_points:cut,
    local_points:cut.map(p=>toLocal(p,tx,ty))});
  for(const e of segmentIntersections(a,z,bounds,tx,ty)){
   // Normalise "end of segment vs beginning of next" to a single event.
   const key=path.id+":"+e.boundary+":"+e.world_position.join(",");
   if(observed.has(key))continue;
   observed.add(key);
   crossings.push({id:key,source:path.id,kind:path.kind,side:e.side,
     boundary:e.boundary,world_position:e.world_position,
     local_position:toLocal(e.world_position,tx,ty),
     geometry:path.geometry,protected_status:"unverified"});
  }
 }
 segments.sort((a,b)=>a.source.localeCompare(b.source)||a.source_segment-b.source_segment);
 crossings.sort((a,b)=>a.id.localeCompare(b.id));
 return {schema_version:1,projection_version:PROJECTION_VERSION,
  id:"source-tile:v1:"+worldFingerprint+":"+tx+","+ty,
  source_world_sha256:worldFingerprint,source:"azgaar",
  scale:{world_units_per_tile:WORLD_UNITS_PER_TILE,display_units:REGION_DISPLAY_UNITS,
    km_mapping:"NOT_CALIBRATED: the 30km Town Forge label cannot be inferred from Azgaar points"},
  tile:{x:tx,y:ty,bounds},
  constraints:{protection:"unknown",provider_interior_alignment:"NOT_IMPLEMENTED",
    river_geometry:"approximate_from_cell_centres",shoreline:"NOT_PROJECTED"},
  burgs,segments,crossings};
}
/** Identical intersection keys and source coordinates on opposite sides.
 * Caller must compare these separately from Town Forge's independent paths.
 */
export function sideCrossings(tile,side){
 return tile.crossings.filter(e=>e.side===side)
  .map(({id,boundary,world_position,source,kind})=>({id,boundary,world_position,source,kind}))
  .sort((a,b)=>a.id.localeCompare(b.id));
}
