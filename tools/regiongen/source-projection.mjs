/**
 * GAME-39 v1: source-derived world-space and edge constraints.
 *
 * This does NOT replace Town Forge landscape interiors or claim a calibrated
 * physical-world scale. Azgaar canonical coordinates are one shared global
 * frame: every burg in the same square selects the same tile. Azgaar routes
 * carry actual [x,y,cell] points; rivers currently expose only cell IDs,
 * so lines joining their cell centres are explicitly APPROXIMATE.
 */
import {checkGeographySidecar} from "../worldgen/geography-sidecar.mjs";
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
  if(route.points.some(p=>!valid(p)))throw Error("Invalid Azgaar route points");
  const points=route.points.map(normalize);
  if(points.length>=2)result.push({id:"route:"+route.i,kind:"azgaar_route",
   source_id:route.i,group:route.group||"unknown",geometry:"original_azgaar_route_points",points});
 }
 for(const river of world.rivers) {
  if(!river||!Number.isSafeInteger(river.i)||!Array.isArray(river.cells))continue;
  const pts=[];
  for(const cellID of river.cells){
   const i=idIndex.get(cellID);
   if(i===undefined)throw Error("Azgaar river references missing source cell "+cellID);
   const p=normalize(world.cells.points[i]);
   if(!pts.length || pts.at(-1)[0]!==p[0]||pts.at(-1)[1]!==p[1])pts.push(p);
  }
  if(pts.length>=2)result.push({id:"river:"+river.i,kind:"azgaar_river",
   source_id:river.i,geometry:"approximation_from_source_river_cells_not_actual_course",points:pts});
 }
 return result.sort((a,b)=>a.id.localeCompare(b.id));
}
function segmentIntersections(points,index,bounds,tx,ty) {
 const a=points[index],z=points[index+1];
 const dx=z[0]-a[0],dy=z[1]-a[1],hits=[];
 const edges=[["W",bounds.left,"x"],["E",bounds.right,"x"],
              ["N",bounds.top,"y"],["S",bounds.bottom,"y"]];
 for(const [side,v,axis] of edges) {
  const along=axis==="x"?dx:dy,initial=axis==="x"?a[0]:a[1];
  if(Math.abs(along)<EPS)continue; // tangent/coincident is not a crossing
  const t=(v-initial)/along;
  if(t < -EPS||t>1+EPS)continue;
  // A point ending at a border and turning back is a tangent/contact, not
  // an inter-tile connection. Endpoint crossings require adjacent segments
  // on genuinely opposite sides of the same source boundary.
  if(t<=EPS || t>=1-EPS) {
   const prev=points[t<=EPS?index-1:index],next=points[t<=EPS?index+1:index+2];
   if(!prev||!next)continue;
   const before=(axis==="x"?prev[0]:prev[1])-v;
   const after=(axis==="x"?next[0]:next[1])-v;
   if(before*after>=-EPS || Math.abs(before)<EPS || Math.abs(after)<EPS)continue;
  }
  const point=[a[0]+dx*t,a[1]+dy*t];
  const other=axis==="x"?point[1]:point[0];
  const min=axis==="x"?bounds.top:bounds.left,max=axis==="x"?bounds.bottom:bounds.right;
  if(other<min-EPS||other>max+EPS)continue;
  // One canonical event on a corner may belong to two physical sides.
  hits.push({side,boundary:canonicalBoundary(tx,ty,side),
   // A vertex crossing on two consecutive segments has one identity, whereas
   // genuinely revisiting the same border coordinate on a later segment is
   // a distinct traversal and must NOT be collapsed.
   source_segment:t<=EPS?index-1:index,world_position:point.map(fixed)});
 }
 return hits;
}
/** Clip a closed original source polygon to one shared global tile.
 * Render fills from these clipped vertices, not independent tile polygons. */
export function clipPolygon(points,bounds) {
 let poly=points.map(normalize);
 for(const [axis,value,positive] of [
  [0,bounds.left,true],[0,bounds.right,false],
  [1,bounds.top,true],[1,bounds.bottom,false]]) {
  const inside=p=>positive?p[axis]>=value-EPS:p[axis]<=value+EPS;
  const result=[];
  for(let i=0;i<poly.length;i++) {
   const a=poly[i],b=poly[(i+1)%poly.length],ai=inside(a),bi=inside(b);
   if(ai!==bi){
    const k=(value-a[axis])/(b[axis]-a[axis]);
    result.push([fixed(a[0]+k*(b[0]-a[0])),fixed(a[1]+k*(b[1]-a[1]))]);
   }
   if(bi)result.push(b);
  }
  poly=result;
  if(!poly.length)break;
 }
 const cleaned=[];
 for(const p of poly)if(!cleaned.length || Math.hypot(p[0]-cleaned.at(-1)[0],p[1]-cleaned.at(-1)[1])>EPS)
  cleaned.push(p);
 if(cleaned.length>1&&Math.hypot(cleaned[0][0]-cleaned.at(-1)[0],cleaned[0][1]-cleaned.at(-1)[1])<EPS)cleaned.pop();
 return cleaned.length>=3?cleaned:[];
}

function addSourceShorelines(world,vertices,tx,ty,bounds) {
 const polygons=[],segments=[],crossings=[],seen=new Set();
 for(const f of world.map.geography) {
  if(!f?.vertices?.length)continue;
  const coords=f.vertices.map(id=>vertices[id]);
  const kind=f.type==="lake"?"source_lake":f.type==="island"?"source_land_boundary":"source_feature_boundary";
  const clipped=clipPolygon(coords,bounds);
  if(clipped.length)polygons.push({source_feature:f.i,kind,subtype:f.subtype||null,
   world_points:clipped,local_points:clipped.map(p=>toLocal(p,tx,ty))});
  const closed=[...coords,coords[0]];
  for(let i=0;i<coords.length;i++){
   const cut=clipSegment(closed[i],closed[i+1],bounds);
   if(!cut || Math.hypot(cut[0][0]-cut[1][0],cut[0][1]-cut[1][1])<=EPS)continue;
   segments.push({source_feature:f.i,kind,source_segment:i,world_points:cut,
     local_points:cut.map(p=>toLocal(p,tx,ty)),geometry:"original_pack_feature_vertex_points"});
   for(const e of segmentIntersections(closed,i,bounds,tx,ty)){
    const id="feature:"+f.i+":"+e.boundary+":s"+e.source_segment+":"+e.world_position.join(",");
    if(seen.has(id))continue;
    seen.add(id);
    crossings.push({id,source_feature:f.i,kind,side:e.side,
      boundary:e.boundary,world_position:e.world_position,
      local_position:toLocal(e.world_position,tx,ty)});
   }
  }
 }
 polygons.sort((a,b)=>a.source_feature-b.source_feature);
 segments.sort((a,b)=>a.source_feature-b.source_feature||a.source_segment-b.source_segment);
 crossings.sort((a,b)=>a.id.localeCompare(b.id));
 return {polygons,segments,crossings};
}

export function buildTileConstraints(world,tx,ty,worldFingerprint,geographySidecar=null) {
 const index=validate(world),bounds=tileBounds(tx,ty);
 const vertexPositions=geographySidecar?checkGeographySidecar(world,geographySidecar,worldFingerprint):null;
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
  for(const e of segmentIntersections(path.points,i,bounds,tx,ty)){
   // Normalise "end of segment vs beginning of next" to a single event.
   const key=path.id+":"+e.boundary+":s"+e.source_segment+":"+e.world_position.join(",");
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
 const shore=vertexPositions?addSourceShorelines(world,vertexPositions,tx,ty,bounds):null;
 return {schema_version:1,projection_version:PROJECTION_VERSION,
  id:"source-tile:v1:"+worldFingerprint+":"+tx+","+ty,
  source_world_sha256:worldFingerprint,source:"azgaar",
  scale:{world_units_per_tile:WORLD_UNITS_PER_TILE,display_units:REGION_DISPLAY_UNITS,
    km_mapping:"NOT_CALIBRATED: the 30km Town Forge label cannot be inferred from Azgaar points"},
  tile:{x:tx,y:ty,bounds},
  constraints:{protection:"unknown",provider_interior_alignment:"NOT_IMPLEMENTED",
    river_geometry:"approximate_from_cell_centres",shoreline:shore?"exact_source_feature_vertices":"NOT_PROJECTED"},
  burgs,segments,crossings,
  ...(shore?{source_shoreline:{provenance:"original_pack_feature_vertex_points",
     polygons:shore.polygons,segments:shore.segments,crossings:shore.crossings}}:{})};
}
/** Identical intersection keys and source coordinates on opposite sides.
 * Caller must compare these separately from Town Forge's independent paths.
 */
export function sideCrossings(tile,side){
 return tile.crossings.filter(e=>e.side===side)
  .map(({id,boundary,world_position,source,kind})=>({id,boundary,world_position,source,kind}))
  .sort((a,b)=>a.id.localeCompare(b.id));
}

export function sideShorelineCrossings(tile,side) {
 return (tile.source_shoreline?.crossings||[]).filter(e=>e.side===side)
 .map(({id,boundary,world_position,source_feature,kind})=>({id,boundary,world_position,source_feature,kind}))
 .sort((a,b)=>a.id.localeCompare(b.id));
}

/** Deterministically choose a real original shoreline crossing of a shared
 * vertical world-tile boundary, preferring one near the selected burg.
 * This is a DIAGNOSTIC selector, never a generated/fake crossing. */
export function selectSourceShorelineSeam(world,sidecar,fingerprint,near=[world.map.width/2,world.map.height/2]) {
 const coordinates=checkGeographySidecar(world,sidecar,fingerprint);
 if(!valid(near))throw Error("Invalid geography focus position");
 const choices=[];
 for(const f of world.map.geography) {
  if(!f?.vertices?.length)continue;
  const vertices=f.vertices.map(i=>coordinates[i]);
  for(let i=0;i<vertices.length;i++) {
   const a=vertices[i],b=vertices[(i+1)%vertices.length],dx=b[0]-a[0];
   if(Math.abs(dx)<EPS)continue;
   const low=Math.min(a[0],b[0]),high=Math.max(a[0],b[0]);
   for(let n=Math.floor(low/WORLD_UNITS_PER_TILE)+1; n*WORLD_UNITS_PER_TILE<high-EPS;n++) {
    const x=n*WORLD_UNITS_PER_TILE,t=(x-a[0])/dx;
    if(t<=EPS||t>=1-EPS || x>=world.map.width-EPS)continue;
    const y=a[1]+t*(b[1]-a[1]);
    if(y<0||y>=world.map.height || Math.abs(y/WORLD_UNITS_PER_TILE-Math.round(y/WORLD_UNITS_PER_TILE))<EPS)continue;
    const tx=n-1,ty=Math.floor(y/WORLD_UNITS_PER_TILE);
    choices.push({tile_x:tx,tile_y:ty,source_feature:f.i,kind:f.type,
     source_segment:i,world_position:[fixed(x),fixed(y)],
     squared_distance:(x-near[0])**2+(y-near[1])**2});
   }
  }
 }
 if(!choices.length)throw Error("No real vertical source feature shoreline crossing found");
 choices.sort((a,b)=>a.squared_distance-b.squared_distance||
  a.source_feature-b.source_feature||a.source_segment-b.source_segment);
 const {squared_distance,...chosen}=choices[0];
 return chosen;
}
