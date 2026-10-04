#!/usr/bin/env node
import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import {hexAt,hexCentre,hexDistance,buildHexOverlay,measureHexDistance} from "../../tools/regiongen/hex-overlay.mjs";
for(let q=-30;q<=30;q++)for(let r=-30;r<=30;r++){
 const h=[q,r];assert.deepEqual(hexAt(hexCentre(h)),h);
 for(const [a,b] of [[1,0],[0,1],[-1,1],[-1,0],[0,-1],[1,-1]])assert.equal(hexDistance(h,[q+a,r+b]),1);
}
for(const stem of ["game-11-determinism","atlas-showcase"])for(const kind of ["shore","river","highland"]){
 const region=JSON.parse(await readFile(`tools/regiongen/.tmp/contextual-${stem}-${kind}.json`));
 const grid=region.hex_overlay_v1,context=region.source_context;
 assert.deepEqual(buildHexOverlay(context),grid);
 assert.equal(grid.physical_km,"UNCALIBRATED");
 assert.equal(grid.meaning,"GEOMETRIC_DISTANCE_NOT_TRAVEL_ROUTE");
 assert.equal(measureHexDistance(context,context.space.home_local),0);
 assert(grid.cells.length>200&&grid.cells.length<600);
 assert(new Set(grid.cells.map(c=>c.axial.join(','))).size===grid.cells.length);
 for(const c of grid.cells){
  const b=context.space.source_bounds;
  const w=[b.left+c.centre[0]*(b.right-b.left)/1000,b.top+c.centre[1]*(b.bottom-b.top)/1000];
  assert(Math.hypot(...w.map((n,i)=>n-hexCentre(c.axial)[i]))<1e-5);
 }
 const svg=await readFile(`tools/regiongen/.tmp/contextual-${stem}-${kind}.hex.svg`,'utf8');
 assert(svg.includes('hex-distance-grid'));
 for(const site of region.local_sites_v2.sites)
  if(!['discovered','visited'].includes(site.knowledge))assert(!svg.includes(site.label),"Hex ruler leaked hidden site");
}
console.log('PASS: GAME-58 world-anchored hex geometry, negative-coordinate round trips, six neighbours, hometown zero distance, six map overlays and hidden-site privacy');
