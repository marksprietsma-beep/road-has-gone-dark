#!/usr/bin/env node
import assert from "node:assert/strict";
import {readFile,writeFile} from "node:fs/promises";
import {resolve} from "node:path";
import {createHash} from "node:crypto";
import {spawnSync} from "node:child_process";
import {populateRegion,playerSiteView} from "../../tools/regiongen/local-sites.mjs";
import {registry} from "../../tools/regiongen/site-icons.mjs";
const hash=x=>createHash("sha256").update(x).digest("hex");
assert.equal(registry.schema_version,1);
for(const kind of ["hometown","farmstead","roadside_inn","watchtower","shrine","ruins","cave","abandoned_camp","ancient_stones","dangerous_woods","old_mine"]){
 assert(registry.symbols[kind]?.polygons?.length>=2,"Missing illustrated site glyph: "+kind);
}
const root=process.cwd(),tmp=resolve(root,"tools/regiongen/.tmp");
const fixture=resolve(root,"tests/worldgen/fixtures/game-11-determinism.json");
const secondFixture=resolve(root,"tests/worldgen/fixtures/atlas-showcase.json");
const original=await readFile(fixture),world=JSON.parse(original),show=JSON.parse(await readFile(secondFixture));
const sourceSHA=hash(original);
const inside=(p,pts)=>{let inPoly=false;for(let i=0,j=pts.length-1;i<pts.length;j=i++){
 const a=pts[i],b=pts[j];if(((a[1]>p[1])!==(b[1]>p[1]))&&(p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]))inPoly=!inPoly;
}return inPoly;};
const names=["first","coast","river","mountain","estuary","second-world"];
for(const name of names){
 const w=name==="second-world"?secondFixture:fixture;
 const regionPath=resolve(tmp,name+".json"),out=resolve(tmp,"populated-"+name+".json");
 const cmd=["tools/regiongen/generate-local-sites.mjs","--world",w,"--region",regionPath,"--output",out];
 const task=()=>spawnSync(process.execPath,cmd,{cwd:root,encoding:"utf8",timeout:40000});
 const run=task();
 assert.equal(run.status,0,name+" generation failed: "+run.stderr);
 assert.match(run.stdout,/PASS: GAME-40/);
 const first=await readFile(out,"utf8");
 assert.equal(task().status,0,name+" repeat CLI failed");
 assert.equal(first,await readFile(out,"utf8"),name+" preview not byte-identical");
 const data=JSON.parse(first),layer=data.local_sites;
 assert.equal(layer.region_id,data.id);
 assert.equal(layer.sites[0].id,"burg:"+data.source.burg_id);
 assert.equal(layer.sites[0].provenance,"azgaar_burg");
 assert.equal(layer.sites[0].knowledge,"discovered");
 assert(layer.sites.length>=5,name+": insufficient legible adventure sites");
 assert.equal(new Set(layer.sites.map(x=>x.id)).size,layer.sites.length);
 assert.equal(new Set(layer.sites.map(x=>x.label.toLowerCase())).size,layer.sites.length);
 const used=[];
 for(const site of layer.sites){
  assert(Array.isArray(site.position)&&site.position.length===2);
  assert(site.position.every(Number.isFinite));
  const [x,y]=site.position;
  assert(x>=95&&x<=905&&y>=130&&y<=900,name+": site outside map");
  assert(!inside(site.position,data.geometry.water),name+": site placed in water");
  assert(used.every(p=>Math.hypot(x-p[0],y-p[1])>=93),name+": sites collided");
  used.push(site.position);
  assert(["azgaar_burg","game_generated_local_site"].includes(site.provenance));
  assert(site.patrol_protection==="unverified");
 }
 const views=playerSiteView(layer);
 assert(views.visible.some(x=>x.kind==="hometown"));
 assert(views.visible.some(x=>x.kind==="ruins"||x.kind==="shrine"||x.kind==="watchtower"),name+": no meaningful POI visible");
 assert(views.visible.every(x=>x.knowledge!=="hidden"&&x.knowledge!=="rumoured"));
 const allHidden=layer.sites.filter(x=>x.knowledge==="hidden");
 for(const hidden of allHidden) {
  assert(!views.visible.some(v=>v.id===hidden.id));
  assert(!JSON.stringify(views).includes(hidden.label),name+": hidden name leaked");
 }
 for(const rumoured of layer.sites.filter(x=>x.knowledge==="rumoured")){
  assert(!JSON.stringify(views).includes(rumoured.id));
  assert(!JSON.stringify(views).includes(JSON.stringify(rumoured.position)));
 }
 assert.equal(playerSiteView(layer,{},true).visible.length,layer.sites.length);
 const target=layer.sites.find(x=>x.kind==="ruins");
 if(target)assert(playerSiteView(layer,{[target.id]:"visited"}).visible.some(x=>x.id===target.id&&x.knowledge==="visited"));
 assert.throws(()=>playerSiteView(layer,{"bogus":"discovered",[layer.sites[0].id]:"wrong_value"}));
 const svg=await readFile(out.replace(/\.json$/,".svg"),"utf8");
 assert(svg.startsWith("<svg")&&svg.includes("FRONTIER REGION")&&svg.includes(data.local_sites.sites[0].label));
 assert(svg.includes('class="region-site"')&&svg.includes('class="site-label"'),name+": artwork/label hierarchy absent");
 assert.equal((svg.match(/class="region-site"/g)||[]).length,views.visible.length,name+": site icons must respect discovery state");
 assert(!svg.includes('fill="#1e2221"'),name+": legacy black POI text boxes survived");
 for(const secret of layer.sites.filter(x=>x.knowledge==="hidden"||x.knowledge==="rumoured")){
  assert(!svg.includes(secret.label),name+": unrevealed name leaked into player SVG");
  assert(!svg.includes(secret.id),name+": unrevealed site ID leaked into player SVG");
 }
}
const region=JSON.parse(await readFile(resolve(tmp,"first.json")));
const renamed=structuredClone(world);renamed.settlements.find(x=>x&&x.i===region.source.burg_id).name="Renamed Hometown";
const first=populateRegion(world,region),after=populateRegion(renamed,region);
assert.deepEqual(first.sites.map(x=>x.position),after.sites.map(x=>x.position),"Burg rename moved sites");
assert.deepEqual(first.sites.map(x=>x.id),after.sites.map(x=>x.id),"Burg rename modified stable site IDs");
assert.notEqual(first.sites[0].label,after.sites[0].label);
assert.throws(()=>populateRegion({...world,seed:"wrong-seed"},region));
const other=JSON.parse(await readFile(resolve(tmp,"coast.json")));
assert.notEqual(populateRegion(world,other).region_id,first.region_id);
const malformed=structuredClone(world);
malformed.settlements.find(x=>x&&x.i===region.source.burg_id).removed=true;
assert.throws(()=>populateRegion(malformed,region));
assert.equal(hash(await readFile(fixture)),sourceSHA,"Upstream world source bytes changed");
console.log("PASS: GAME-40 six populated regions, distinct sites, stable IDs, biomes, dry land, collisions, privacy, SVG and immutable fixtures");
