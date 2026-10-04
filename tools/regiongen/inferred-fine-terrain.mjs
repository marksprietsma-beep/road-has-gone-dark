/**
 * GAME-51 — optional *illustrative* fine detail, never walkable terrain.
 *
 * Values are derived from source cell height/biome plus world-coordinate
 * noise. NO extra roads, rivers, bridges, coastlines or source facts.
 * Every field sample uses the global Azgaar coordinate frame, never the
 * chosen burg as a random origin: overlapping views agree at equal points.
 */
import {createHash} from "node:crypto";
import {sourceDryLand} from "./compose-local-region.mjs";
export const INFERENCE_VERSION=1;
const GRID=32;
const round=x=>Math.round(x*1e5)/1e5;
const finite=x=>Number.isFinite(x);
const digest=s=>createHash("sha256").update(s).digest("hex");
function lattice(seed,i,j,octave){
 let h=2166136261;
 const s=seed.slice(0,16)+":"+i+":"+j+":"+octave;
 for(let k=0;k<s.length;k++){h^=s.charCodeAt(k);h=Math.imul(h,16777619);}
 return (h>>>0)/4294967295;
}
const smooth=x=>x*x*(3-2*x);
function noise(seed,x,y,scale,layer){
 const tx=x/scale,ty=y/scale,ix=Math.floor(tx),iy=Math.floor(ty);
 const u=smooth(tx-ix),v=smooth(ty-iy);
 const a=lattice(seed,ix,iy,layer),b=lattice(seed,ix+1,iy,layer);
 const c=lattice(seed,ix,iy+1,layer),d=lattice(seed,ix+1,iy+1,layer);
 return (a+(b-a)*u)*(1-v)+(c+(d-c)*u)*v;
}
function coarse(world,wx,wy){
 const positions=world.cells?.points,heights=world.cells?.heights,biomes=world.cells?.biome;
 if(!Array.isArray(positions)||!Array.isArray(heights)||!Array.isArray(biomes)||
    positions.length!==heights.length||positions.length!==biomes.length)
  throw Error("Macro biome/height samples missing or misaligned");
 // Four-nearest source Voronoi cell centres. This smoothly approximates
 // the macro tendency; it does NOT create physically measured local slopes.
 const nearest=[];
 for(let i=0;i<positions.length;i++){
  const p=positions[i];if(!Array.isArray(p)||p.length!==2||!p.every(finite))throw Error("Malformed original source point");
  const d=(wx-p[0])**2+(wy-p[1])**2;
  if(nearest.length===4 && d>=nearest[3].d)continue;
  const node={i,d};let j=0;
  while(j<nearest.length&&nearest[j].d<=d)j++;
  nearest.splice(j,0,node);
  if(nearest.length>4)nearest.pop();
 }
 if(!nearest.length)throw Error("No actual Azgaar sample");
 let weight=0,h=0,forest=0;
 for(const n of nearest){
  const w=1/(n.d+0.001);
  if(!finite(heights[n.i]))throw Error("Malformed height in world source");
  h+=heights[n.i]*w;
  forest+=([5,6,7,8,9].includes(biomes[n.i])?1:
    [1,2,10,11].includes(biomes[n.i])?0.1:0.46)*w;
  weight+=w;
 }
 return {height:h/weight,forest:forest/weight,nearest_source_cell:nearest[0].i};
}
export function sampleInferredFineTerrain(world,context,fingerprint,worldPoint) {
 if(!/^[a-f0-9]{64}$/.test(fingerprint)||
  context?.parent_source_world_sha256!==fingerprint)
  throw Error("Wrong source world fingerprint for inference");
 if(!Array.isArray(worldPoint)||worldPoint.length!==2||!worldPoint.every(finite))
  throw Error("Invalid global source position");
 const [x,y]=worldPoint;
 if(x<0||x>world.map.width||y<0||y>world.map.height)throw Error("Inference source point off world");
 const a=coarse(world,x,y),n1=noise(fingerprint,x,y,0.42,1);
 const n2=noise(fingerprint,x,y,0.13,2),n3=noise(fingerprint,x,y,0.035,3);
 const ridge=(1-Math.abs(n2*2-1))*.12 + (n1-.5)*.14;
 const height=Math.max(0,Math.min(100,a.height+ridge*32+(n3-.5)*7));
 const canopy=Math.max(0,Math.min(1,
  // Offset is a rendering-density calibration, not measured tree cover.
  // Without it, forest-biome worlds show >80% dark-green saturation.
  a.forest*.48+n1*.26+n2*.2+n3*.12 -0.22 -Math.max(0,height-69)*.009));
 return {source_position:worldPoint.map(round),inferred_height:round(height),
  inferred_canopy:round(canopy),nearest_macro_cell_index:a.nearest_source_cell,
  authority:"INFERRED_ONLY",walkable:"UNKNOWN"};
}

/** Separate art sampler. Legacy fine:v1/save/site inputs remain unchanged.
 * Wavelengths in original WORLD coordinates resolve at local-map zoom instead
 * of aliasing hundreds of noise cycles into 32 samples. Not terrain physics. */
export function sampleLandscapeArt(world,context,fingerprint,worldPoint) {
 if(context?.parent_source_world_sha256!==fingerprint||! /^[a-f0-9]{64}$/.test(fingerprint))
  throw Error("Landscape art requires the matching source fingerprint");
 const [x,y]=worldPoint;
 if(!worldPoint.every(finite)||x<0||y<0||x>world.map.width||y>world.map.height)
  throw Error("Landscape art outside source world");
 const macro=coarse(world,x,y);
 const artSeed=context.generation_world_seed??fingerprint;
 const broad=noise(artSeed,x,y,5.4,11);
 const middle=noise(artSeed,x,y,1.8,12);
 const detail=noise(artSeed,x,y,.6,13);
 const h=Math.max(0,Math.min(100,macro.height+(broad-.5)*8+(middle-.5)*4+(detail-.5)*1.5));
 const f=Math.max(0,Math.min(1,macro.forest*.42+broad*.32+middle*.23+detail*.09-.19-Math.max(0,h-72)*.013));
 return {h:round(h),f:round(f)};
}
export function buildInferredFineTerrain(world,context,fingerprint){
 if(context?.schema_version!==1||
  !["hypothetical_globe_reference_window","source_neighbourhood_window"].includes(context.space?.kind)||
  context.constraints?.shorelines!=="original_source_features"||
  context.parent_source_world_sha256!==fingerprint)
  throw Error("Need matching polygon-backed original source context");
 if(context.space.kind==="hypothetical_globe_reference_window"&&
  context.space.physical_km!=="ASSUMED_NOT_CANON")
  throw Error("Reference radius must be explicitly hypothetical");
 const b=context.space.source_bounds;
 if(!(b&&b.right>b.left&&b.bottom>b.top))throw Error("Missing source-space bounds");
 const vertices=[];
 // Scalar field evaluated in WORLD units, never re-seeded per village/tile.
 for(let j=0;j<=GRID;j++){
  for(let i=0;i<=GRID;i++){
   const x=1000*i/GRID,y=1000*j/GRID;
   const wx=b.left+(b.right-b.left)*i/GRID,wy=b.top+(b.bottom-b.top)*j/GRID;
   const v=sampleInferredFineTerrain(world,context,fingerprint,[wx,wy]);
   vertices.push({h:v.inferred_height,f:v.inferred_canopy,
    land:sourceDryLand(context,[x,y])});
  }
 }
 const id=digest(JSON.stringify([fingerprint,context.id,"fine:v1"]));
 return {schema_version:1,id:"inferred-fine:v1:"+id,
  source_context_id:context.id,source_world_sha256:fingerprint,
  source_bounds:b,grid_steps:GRID,vertices,
  truth:"INFERRED_VISUAL_FIELD_NOT_TRAVERSAL",
  origin:"SOURCED_COARSE_HEIGHT_BIOME_PLUS_GLOBAL_WORLD_COORDINATE_NOISE",
  source_cell_samples:context.space.source_cell_centres_in_window??null,
  reference_scale:context.space.physical_km,
  claims:{bridges:"UNKNOWN",walkable:"UNKNOWN",safe_routes:"UNKNOWN",
    accurate_fine_shorelines:false,verified_mountain_passes:false,
    validated_cross_tile_traversal:false},
  migration:"NOT_AUTOMATIC"};
}
