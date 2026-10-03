/**
 * GAME-48: HYPOTHETICAL globe reference, not a claim about our fantasy world.
 *
 * Azgaar exports geographic angular coordinates via src/generators/coordinates.ts.
 * It does NOT establish a canon planetary radius; supplying a radius explicitly
 * is the only way to make a distance-based diagnostic. Never use this reference
 * in playthrough travel, saves or legacy 16-unit map identity automatically.
 */
export const REFERENCE_VERSION=2;
const DEG=Math.PI/180;
const clamp=(x,a,b)=>Math.max(a,Math.min(b,x));
const f=x=>Math.round(x*1e6)/1e6;
export function sourceGeographicReference(world,position,referenceRadiusKm){
 if(!Number.isFinite(referenceRadiusKm)||referenceRadiusKm<100||referenceRadiusKm>100000)
  throw Error("Must explicitly supply a hypothetical globe radius (km)");
 if(!Array.isArray(position)||position.length!==2||position.some(x=>!Number.isFinite(x)))
  throw Error("Invalid original Azgaar map position");
 const map=world?.map,b=map?.bounds;
 if(!(Number.isFinite(map?.width)&&Number.isFinite(map?.height)&&map.width>0&&map.height>0))
  throw Error("Missing original Azgaar pixel canvas");
 for(const k of ["latN","latS","latT","lonW","lonE","lonT"])
  if(!Number.isFinite(b?.[k]))throw Error("Missing original Azgaar coordinate "+k);
 if(b.latT<=0||b.lonT<=0||b.latT>180||b.lonT>360||
    Math.abs(b.latN-b.latS-b.latT)>0.11||Math.abs(b.lonE-b.lonW-b.lonT)>0.11)
  throw Error("Inconsistent original angular bounds");
 if(position[0]<0||position[0]>map.width||position[1]<0||position[1]>map.height)
  throw Error("Original map position out of bounds");
 const latitude=b.latN-position[1]*b.latT/map.height;
 const longitude=b.lonW+position[0]*b.lonT/map.width;
 // Horizontal equirectangular scaling is highly unstable near poles;
 // refuse to represent polar neighbourhoods as a normal square map.
 if(Math.abs(latitude)>=80)throw Error("Source latitude too close to pole for local rectangular reference");
 const perY=referenceRadiusKm*DEG*b.latT/map.height;
 const perX=referenceRadiusKm*DEG*b.lonT/map.width*Math.cos(latitude*DEG);
 if(!Number.isFinite(perY)||!Number.isFinite(perX)||perX<=0)
  throw Error("Invalid approximate globe calibration");
 return {
  schema_version:REFERENCE_VERSION,
  provenance:"AZGAAR_ANGULAR_COORDINATES_PLUS_EXPLICIT_HYPOTHETICAL_RADIUS",
  certainty:"ASSUMED_WORLD_RADIUS_NOT_GAME_CANON",
  reference_radius_km:referenceRadiusKm,
  original_position:position.map(f),
  angular_position:{lat:f(latitude),lon:f(longitude)},
  hypothetical_km_per_source_unit:{east_west:f(perX),north_south:f(perY)}
 };
}
export function referenceNeighbourhoodBounds(world,position,spanKm,referenceRadiusKm){
 if(!Number.isFinite(spanKm)||spanKm<1||spanKm>200)
  throw Error("Reference neighbourhood span must be 1–200 hypothetical kilometres");
 const reference=sourceGeographicReference(world,position,referenceRadiusKm);
 const b=reference.hypothetical_km_per_source_unit;
 const width=spanKm/b.east_west,height=spanKm/b.north_south;
 if(width>=world.map.width||height>=world.map.height)
  throw Error("Reference-sized source window exceeds world canvas");
 // Keep full requested rectangle even at boundaries. A clamp near the map
 // edge shifts its centre instead of silently shrinking its source scale.
 const x=clamp(position[0]-width/2,0,world.map.width-width);
 const y=clamp(position[1]-height/2,0,world.map.height-height);
 const bounds={left:f(x),right:f(x+width),top:f(y),bottom:f(y+height)};
 if(!(bounds.left<=position[0]&&position[0]<=bounds.right&&
      bounds.top<=position[1]&&position[1]<=bounds.bottom))
  throw Error("Selected source burg lies outside its reference window");
 return {...reference,hypothetical_square_km:spanKm,
  source_window_units:{width:f(width),height:f(height)},
  bounds,
  endpoint_shifted_for_world_edge:Math.abs((x+width/2)-position[0])>0.001||
    Math.abs((y+height/2)-position[1])>0.001};
}
