#!/usr/bin/env node
/** GAME-39 world-coordinate and boundary proof, independent of Town Forge. */
import assert from "node:assert/strict";
import {readFile,writeFile,mkdir} from "node:fs/promises";
import {createHash} from "node:crypto";
import {resolve} from "node:path";
import {tileForPoint,tileForCell,tileForBurg,tileBounds,clipSegment,projectSourceTile,
 WORLD_TILE_UNITS} from "../../tools/regiongen/world-space.mjs";
const fixturePaths=["tests/worldgen/fixtures/game-11-determinism.json",
 "tests/worldgen/fixtures/atlas-showcase.json"];
const SHA=bytes=>createHash("sha256").update(bytes).digest("hex");
const digest="f".repeat(64);
const synthetic={
 schemaVersion:1,generator:{provider:"azgaar"},
 map:{width:180,height:180},
 cells:{ids:[1,2,3,4],points:[[53,30],[63,30],[35,35],[70,70]]},
 settlements:[
  {i:1,cell:1,name:"Westmarch",x:55,y:28},
  {i:2,cell:2,name:"Westfort",x:58,y:30},
  {i:3,cell:4,name:"Eastfield",x:75,y:71}
 ],
 routes:[
  {i:10,group:"roads",points:[[50,35],[70,35]]},
  {i:11,group:"trails",points:[[35,50],[35,70]]},
  {i:12,group:"roads",points:[[50,50],[70,70]]},
  {i:13,group:"roads",points:[[50,20],[60,20],[50,25]]}, // tangent only
  {i:14,group:"roads",points:[[50,44],[70,44],[50,48]]} // two real crossings
 ],
 rivers:[{i:1,type:"River",cells:[1,2]}]
};
assert.deepEqual(tileForBurg(synthetic,1),[0,0]);
assert.deepEqual(tileForBurg(synthetic,2),[0,0]);
assert.deepEqual(tileForCell(synthetic,1),[0,0]);
assert.deepEqual(tileForPoint(synthetic,[70,70]),[1,1]);
assert.equal(tileBounds(1,0).left,60);
assert.deepEqual(clipSegment([50,35],[70,35],tileBounds(0,0)),{a:[50,35],b:[60,35]});
assert.equal(clipSegment([50,35],[70,35],tileBounds(3,0)),null);
assert.equal(clipSegment([50,50],[70,70],tileBounds(1,0)),null,"Corner-only touch should not create geometry");
const tile=(w,x,y,sha=digest)=>projectSourceTile(w,{x,y,world_sha256:sha});
const west=tile(synthetic,0,0),east=tile(synthetic,1,0);
const north=tile(synthetic,0,0),south=tile(synthetic,0,1);
assert.equal(west.tile_id,tile(synthetic,0,0).tile_id,"Order-independent tile identity");
assert.deepEqual(west,tile(synthetic,0,0),"Determinism failed");
assert.deepEqual(west.burgs.map(b=>b.id),[1,2],"Two towns in same tile must not create separate regions");
assert.deepEqual(east.burgs.map(b=>b.id),[],"Source burg located west of boundary incorrectly moved east");
function crossing(tile,sourceId,side){
 return tile.crossings.filter(c=>c.source_kind==="route"&&c.source_id===sourceId&&c.side===side).map(c=>c.boundary_key);
}
assert.deepEqual(crossing(west,10,"east"),crossing(east,10,"west"));
assert.equal(crossing(west,10,"east").length,1,"One real route crossing required");
assert.deepEqual(crossing(north,11,"south"),crossing(south,11,"north"));
assert.equal(crossing(north,11,"south").length,1,"One real vertical crossing required");
assert.deepEqual(crossing(west,12,"east"),crossing(tile(synthetic,1,1),12,"west"),"Corner crossing keys differ");
assert.deepEqual(crossing(north,12,"south"),crossing(tile(synthetic,1,1),12,"north"),"Corner north/south mismatch");
assert.equal(crossing(west,13,"east").length,0,"Tangency must not become a road exit");
assert.equal(crossing(west,14,"east").length,2,"Multiple crossings on one edge collapsed");
assert.deepEqual(crossing(west,14,"east"),crossing(east,14,"west"));
assert(west.segments.some(s=>s.source_kind==="river"&&s.source_precision==="source_cell_centres_approximation"));
assert(west.segments.every(s=>s.safety==="unverified"));
assert(west.crossings.every(c=>c.safety==="unverified"));
assert.throws(()=>tile(synthetic,0,0,"not-a-world-hash"));
assert.throws(()=>tileForBurg(synthetic,999));
assert.throws(()=>projectSourceTile({...synthetic,cells:{...synthetic.cells,ids:[1,1,3,4]}},{x:0,y:0,world_sha256:digest}));
const esc=s=>String(s).replaceAll("&","&amp;").replaceAll("<","&lt;");
const svglines=['<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="640" viewBox="0 0 1200 640">',
 '<rect width="1200" height="640" fill="#e9ddbc"/>',
 '<text x="30" y="31" font-family="sans-serif" font-size="19">GAME-39 • Source road/river boundary constraints, NOT terrain</text>'];
function display(tile,xoff,yoff=38,size=570){
 const b=tile.bounds,side=b.right-b.left,scalar=size/side;
 svglines.push('<rect x="'+xoff+'" y="'+yoff+'" width="'+size+'" height="'+size+'" fill="#e3d4ae" stroke="#40392d" stroke-width="2"/>');
 const coord=p=>[xoff+(p[0]-b.left)*scalar,yoff+(p[1]-b.top)*scalar];
 for(const s of tile.segments){
  const a=coord(s.world_points[0]),c=coord(s.world_points[1]);
  const color=s.source_kind==="river"?"#387c96":"#614a35";
  svglines.push('<path d="M'+a.join(" ")+' L'+c.join(" ")+'" fill="none" stroke="'+color+'" stroke-width="'+(s.source_kind==="river"?2:1.4)+'" opacity=".78"/>');
 }
 for(const s of tile.burgs){
  const p=coord(s.world_point);
  svglines.push('<circle cx="'+p[0]+'" cy="'+p[1]+'" r="5" fill="#a84c2c"/><text x="'+(p[0]+7)+'" y="'+(p[1]-7)+'" font-family="sans-serif" font-size="12">'+esc(s.label)+'</text>');
 }
 for(const c of tile.crossings) {
  const p=coord(c.world_point);
  svglines.push('<circle cx="'+p[0]+'" cy="'+p[1]+'" r="3.7" fill="#cf7b11" stroke="#171815"/>');
 }
 svglines.push('<text x="'+(xoff+8)+'" y="'+(yoff+20)+'" font-family="sans-serif" font-size="14">World tile '+tile.grid.x+','+tile.grid.y+'</text>');
}
const files=[];
for(const [i,filename] of fixturePaths.entries()){
 const bytes=await readFile(resolve(filename)),w=JSON.parse(bytes),sha=SHA(bytes);
 const routes=w.routes.filter(r=>r?.points?.length>=2);
 const crossings=[];
 for(const route of routes) for(let j=0;j<route.points.length-1;j++){
  const [a,b]=[route.points[j],route.points[j+1]];
  const minx=Math.min(a[0],b[0]),maxx=Math.max(a[0],b[0]);
  const boundaryX=Math.ceil(minx/WORLD_TILE_UNITS)*WORLD_TILE_UNITS;
  if(boundaryX<=minx||boundaryX>=maxx)continue;
  const y=a[1]+(boundaryX-a[0])/(b[0]-a[0])*(b[1]-a[1]);
  const yTile=Math.floor(y/WORLD_TILE_UNITS),xTile=boundaryX/WORLD_TILE_UNITS-1;
  if(xTile>=0&&yTile>=0&&yTile*WORLD_TILE_UNITS<w.map.height)
    crossings.push({xTile,yTile,routeId:route.i});
 }
 assert(crossings.length>0,"No source road segment crosses any e/w tile in world "+w.seed);
 const target=crossings[0],a=tile(w,target.xTile,target.yTile,sha),b=tile(w,target.xTile+1,target.yTile,sha);
 const check=sideTile=>sideTile.crossings.filter(c=>c.source_kind==="route"&&c.source_id===target.routeId).map(c=>c.boundary_key);
 const onWest=check(a).filter(key=>a.crossings.some(c=>c.boundary_key===key&&c.side==="east"));
 const onEast=check(b).filter(key=>b.crossings.some(c=>c.boundary_key===key&&c.side==="west"));
 assert(onWest.length>0,"No source crossing detected in west tile");
 assert.deepEqual(onWest,onEast,"Boundary mismatch in actual source fixture");
 // Search also for a real north/south crossing in the same world.
 let nsVerified=false;
 for(const r of routes) {
  if(nsVerified)break;
  for(let k=0;k<r.points.length-1;k++){
   const [p,q]=[r.points[k],r.points[k+1]];
   const miny=Math.min(p[1],q[1]),maxy=Math.max(p[1],q[1]);
   const boundaryY=Math.ceil(miny/WORLD_TILE_UNITS)*WORLD_TILE_UNITS;
   if(boundaryY<=miny||boundaryY>=maxy)continue;
   const x=p[0]+(boundaryY-p[1])/(q[1]-p[1])*(q[0]-p[0]);
   const ix=Math.floor(x/WORLD_TILE_UNITS),iy=boundaryY/WORLD_TILE_UNITS-1;
   if(ix<0||iy<0||ix*WORLD_TILE_UNITS>=w.map.width)continue;
   const t=tile(w,ix,iy,sha),u=tile(w,ix,iy+1,sha);
   const c=t.crossings.filter(v=>v.source_kind==="route"&&v.source_id===r.i&&v.side==="south").map(v=>v.boundary_key);
   const d=u.crossings.filter(v=>v.source_kind==="route"&&v.source_id===r.i&&v.side==="north").map(v=>v.boundary_key);
   assert(c.length>0&&JSON.stringify(c)===JSON.stringify(d),"Real north/south source crossing mismatch");
   nsVerified=true;break;
  }
 }
 assert(nsVerified,"No real north/south road crossing in fixture");
 // Same grid area, regardless of entry burg; no arbitrary centre-anchored grid.
 const first=a.burgs[0];if(first)assert.deepEqual(tileForBurg(w,first.id),[a.grid.x,a.grid.y]);
 assert.equal(a.grid.physical_km,"UNCALIBRATED_AZGAAR_MAP_UNITS_NOT_KM");
 assert.equal(a.coastline.status,"UNSUPPORTED_NO_VERTEX_COORDINATES");
 assert.equal(a.river_geometry,"SOURCE_CELL_CENTRES_APPROXIMATION_NOT_EXACT_COURSE");
 if(i===0){display(a,18);display(b,612);}
 files.push({seed:w.seed,sha,west:a.tile_id,east:b.tile_id,matching_crossings:onWest.length,
   river_segments:a.segments.filter(s=>s.source_kind==="river").length});
 assert.equal(SHA(await readFile(resolve(filename))),sha,"Source fixture mutated");
}
svglines.push('</svg>');
await mkdir("tools/regiongen/.tmp",{recursive:true});
await writeFile("tools/regiongen/.tmp/game-39-source-two-tile.svg",svglines.join("\n")+"\n");
await writeFile("tools/regiongen/.tmp/game-39-source-proof.json",JSON.stringify(files,null,2)+"\n");
console.log("PASS: GAME-39 shared source-world grid, paired E/W + N/S crossings, corners/tangencies/multiple crossings, two burgs, two Azgaar worlds, untouched fixtures, source-only two-tile SVG");
