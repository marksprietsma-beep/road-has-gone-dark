/**
 * GAME-40: deterministic, game-owned local sites on a Town Forge landscape.
 * Never mutates upstream Azgaar/Town Forge, and never promotes invented sites
 * or Town Forge paths into authoritative world facts.
 */
import {createHash} from "node:crypto";

export const SITE_GENERATION_VERSION = 1;
const hash = text => createHash("sha256").update(text).digest("hex");
const number = text => Number.parseInt(hash(text).slice(0,8),16) >>> 0;
const rngFrom = text => {
 let seed=number(text);
 return () => {seed=(seed+0x6D2B79F5)|0; let t=Math.imul(seed^(seed>>>15),1|seed);
  t^=t+Math.imul(t^(t>>>7),61|t);return ((t^(t>>>14))>>>0)/4294967296};
};
const pick=(arr,rng)=>arr[Math.floor(rng()*arr.length)];
const types=[
 {kind:"farmstead",names:["Ashfield Farm","The Barley Croft","Lowfield Holding","Miller's Acre"],civil:3},
 {kind:"roadside_inn",names:["The Last Lantern","Old Toll House","The Grey Mare"],civil:4},
 {kind:"watchtower",names:["Ashen Watch","Broken Beacon","Eastward Lookout"],civil:3},
 {kind:"shrine",names:["Wayfarer's Shrine","The Weeping Saint","Old Stone Chapel"],civil:2},
 {kind:"ruins",names:["Fallen Priory","The Black Abbey","Shattered Hall"],wild:3},
 {kind:"cave",names:["Wolf's Maw","Coldstone Hollow","The Deep Cleft"],wild:3},
 {kind:"abandoned_camp",names:["The Silent Encampment","Burnt Wagons","Hunter's Last Rest"],wild:2},
 {kind:"ancient_stones",names:["The Nine Stones","Crow's Circle","The Ashen Cairn"],wild:2},
 {kind:"dangerous_woods",names:["The Bleak Thicket","Widow's Copse","The Hollow Woods"],wild:2},
 {kind:"old_mine",names:["Old Silver Mine","Drowned Shaft","Blackrock Mine"],wild:2}
];
export const SOURCE_KINDS = ["azgaar_burg","game_generated_local_site"];

function inside(point, polygon) {
 let yes=false;
 for(let i=0,j=polygon.length-1;i<polygon.length;j=i++){
  const a=polygon[i],b=polygon[j];
  if(!Array.isArray(a)||!Array.isArray(b)||a.length<2||b.length<2)continue;
  if(((a[1]>point[1])!==(b[1]>point[1])) &&
       point[0]<(b[0]-a[0])*(point[1]-a[1])/(b[1]-a[1])+a[0])yes=!yes;
 }
 return yes;
}
function clearLand(x,y,water) {
 if(x<95||x>905||y<130||y>900) return false;
 return water.length<3 || !inside([x,y],water);
}
const round=n=>Math.round(n*100)/100;
const distance=(a,b)=>Math.hypot(a[0]-b[0],a[1]-b[1]);

function location(rng,water,used,zone){
 for(let attempt=0;attempt<1200;attempt++){
  let x=95+rng()*810,y=130+rng()*770;
  const d=Math.hypot(x-500,y-515);
  if(zone==="civil"&&d>340)continue;
  if(zone==="wild"&&d<245)continue;
  if(!clearLand(x,y,water))continue;
  if(used.some(p=>distance(p,[x,y])<94))continue;
  return [round(x),round(y)];
 }
 // A region with little dry land legitimately has fewer local sites.
 return null;
}

function checkedWorld(world,region) {
 if(!world||world.schemaVersion!==1||world.generator?.provider!=="azgaar"||!world.seed)
  throw Error("GAME-40 needs a valid pinned Azgaar world");
 if(!region||region.schema_version!==1||region.provider?.name!=="town-forge"||!region.source?.world_sha256)
  throw Error("GAME-40 needs the versioned Town Forge output");
 if(world.seed!==region.source.world_seed)throw Error("Mismatched world seed");
 const burgId=Number(region.source.burg_id),cellId=Number(region.source.cell_id);
 const options=(world.settlements||[]).filter(b=>b&&b.i===burgId);
 if(options.length!==1||options[0].removed||options[0].hidden||options[0].cell!==cellId)
  throw Error("Hometown must be one real visible source burg in matching cell");
 return options[0];
}

export function populateRegion(world,region) {
 const burg=checkedWorld(world,region);
 const water=region.geometry?.water||[];
 if(!Array.isArray(water))throw Error("Malformed region water geometry");
 const seed=["site:v1",world.seed,region.source.cell_id,region.region?.x,region.region?.y].join("|");
 const rng=rngFrom(seed);
 const used=[];
 const home=location(rng,water,used,"civil");
 if(home===null)throw Error("No valid source hometown dry-land location in region preview");
 used.push(home);
 const homeSite={
  id:"burg:"+burg.i,kind:"hometown",label:String(burg.name||"Unnamed Burg"),
  position:home,provenance:"azgaar_burg",source_id:burg.i,
  knowledge:"discovered",detail_hook:{provider:"settlemaker",burg_id:burg.i},
  description:"Source-backed frontier settlement. Detailed layout is not yet generated.",
  patrol_protection:"unverified"
 };
 const full=[homeSite],labels=new Set([homeSite.label.toLowerCase()]);
 const climate=String(region.region?.terrain||"inland");
 const available=types.filter(t=>climate==="mountain"||climate==="coastal"?
   t.kind!=="dangerous_woods" || climate!=="coastal":true);
 // Ordered jobs guarantee a readable, contextual mix even when the
 // game world has sparse source settlements.
 const desired=["farmstead","roadside_inn","watchtower","shrine","ruins","cave",
  "abandoned_camp","ancient_stones","dangerous_woods","old_mine"];
 if(climate==="mountain")desired.splice(desired.indexOf("farmstead"),1);
 if(climate==="coastal")desired.splice(desired.indexOf("old_mine"),1);
 let ordinal=0;
 for(const kind of desired){
  const def=available.find(x=>x.kind===kind);
  if(!def)continue;
  const zone=def.civil?"civil":"wild";
  const pos=location(rng,water,used,zone);
  if(!pos)continue;
  used.push(pos);
  let name=pick(def.names,rng);
  if(labels.has(name.toLowerCase()))name+=" "+String(ordinal+1);
  labels.add(name.toLowerCase());
  const knowledge=ordinal<6?"discovered":ordinal<8?"rumoured":"hidden";
  full.push({
   id:region.id+":site:v"+SITE_GENERATION_VERSION+":"+kind+":"+ordinal,
   kind,label:name,position:pos,provenance:"game_generated_local_site",
   source_id:null,knowledge,
   description:{
    farmstead:"Remote fields on the frontier; help or trouble might await.",
    roadside_inn:"A lonely stop for travellers beyond the settled roads.",
    watchtower:"An old signal point. Current defenders and patrols are unknown.",
    shrine:"A weathered monument whose story may lead elsewhere.",
    ruins:"Abandoned stonework, now claimed by wilderness.",
    cave:"An entrance whose interior has not yet been generated.",
    abandoned_camp:"A trail of events that warrants investigation.",
    ancient_stones:"Older than nearby settlements, purpose unknown.",
    dangerous_woods:"A suspicious wilderness tract with rumours of danger.",
    old_mine:"A disused extraction site with an unknown interior."
   }[kind],
   detail_hook:{provider:kind==="cave"||kind==="ruins"||kind==="old_mine"?"dungeongen":"local_event",
    site_id:region.id+":site:v"+SITE_GENERATION_VERSION+":"+kind+":"+ordinal},
   patrol_protection:"unverified"
  });
  ordinal++;
 }
 return {
  schema_version:1,site_generation_version:SITE_GENERATION_VERSION,
  region_id:region.id,world_sha256:region.source.world_sha256,
  source_cell_id:region.source.cell_id,
  placement:"PROVISIONAL_CONCEPTUAL_NOT_SOURCE_WORLD_COORDINATES",
  roads:"Town Forge roads are illustrative, not authoritative safe routes",
  sites:full
 };
}
/**
 * A player-facing view never contains the actual coordinates, ID or name
 * of undiscovered sites. Rumours are intentionally non-positional hints.
 * Debug reveal is separate and never written into a playthrough save.
 */
export function playerSiteView(layer,knowledgeOverrides={},revealForDeveloper=false) {
 const known=new Set(["discovered","visited","rumoured","hidden"]);
 const visible=[],rumours=[];
 for(const site of layer.sites||[]){
  const state=knowledgeOverrides[site.id]??site.knowledge;
  if(!known.has(state))throw Error("Invalid local-site knowledge state");
  if(revealForDeveloper) {visible.push({...site,knowledge:state,debug_only:state==="hidden"});continue}
  if(state==="discovered"||state==="visited") visible.push({...site,knowledge:state});
  else if(state==="rumoured") rumours.push({hint:"A "+site.kind.replaceAll("_"," ")+" is rumoured in the region.",knowledge:"rumoured"});
 }
 return {visible,rumours};
}
