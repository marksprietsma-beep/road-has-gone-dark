import {createHash} from 'node:crypto';
import {centroid,pointInPolygon,validateModel} from './model.mjs';
export const canonical = value => JSON.stringify(value, (_,v) => v && typeof v === 'object' && !Array.isArray(v) ? Object.fromEntries(Object.entries(v).sort(([a],[b])=>a.localeCompare(b))) : v);
export const digest = value => createHash('sha256').update(canonical(value)).digest('hex');
const identity = (namespace,...parts) => `${namespace}:v1:${digest(parts)}`;
const finitePoint = p => Array.isArray(p) && p.length===2 && p.every(Number.isFinite);
const functions = {inn:'Lodging',tavern:'Hospitality',shop:'Retail premises',smithy:'Metalworking',guildhall:'Guild meeting premises',chapel:'Worship',manor:'Manorial residence',guardhouse:'Guard premises',stable:'Animal shelter',warehouse:'Storage',pier:'Waterfront access',well:'Water source',mill:'Milling'};
export function adapt(source) {
  const {request,name,geojson,backdrop}=source;
  if (!request || !/^[a-f0-9]{64}$/.test(request.fixtureSha256) || !Number.isSafeInteger(request.burgId) || request.burgId<=0 || typeof request.worldSeed!=='string' || geojson?.type!=='FeatureCollection') throw Error('Invalid immutable source identity');
  const features=structuredClone(geojson.features), rawBuildings=features.filter(f=>f.properties.layer==='building');
  const layoutDigest=digest(rawBuildings.map(f=>[f.properties.building_id,f.geometry]).sort(([a],[b])=>String(a).localeCompare(String(b))));
  const sid=identity('settlement',request.fixtureSha256,request.burgId), buildings=[], byProvider=new Map(), establishments=[], diagnostics=[];
  for (const f of rawBuildings) {
    const pid=f.properties.building_id;
    if (typeof pid!=='string' || byProvider.has(pid) || f.geometry.type!=='Polygon') throw Error('Duplicate or invalid provider building');
    const b={id:identity('building',sid,layoutDigest,pid),providerId:pid,polygon:f.geometry.coordinates,district:f.properties.wardType||'unclassified village',provenance:{providerRevision:request.upstreamCommit,evidence:'original GeoJSON polygon'}};
    buildings.push(b);byProvider.set(pid,b);
  }
  const add = ({key,type,providerPoiId=null,providerBuildingId=null,position,district,evidence}) => {
    if (!finitePoint(position) || typeof type!=='string') throw Error('Invalid POI position or kind');
    const b=providerBuildingId===null?null:byProvider.get(providerBuildingId);
    if (providerBuildingId!==null && !b) throw Error('Orphan provider building reference: '+providerBuildingId);
    let anchor=position, binding='source-point';
    if (b && !pointInPolygon(anchor,b.polygon)) {
      diagnostics.push({code:'POI_POINT_OUTSIDE_REFERENCED_ROOF',providerPoiId,providerBuildingId});
      anchor=centroid(b.polygon[0]);binding='explicit-provider-reference / interior fallback';
      if (!pointInPolygon(anchor,b.polygon)) throw Error('No valid interior anchor');
    }
    establishments.push({id:identity('establishment',sid,layoutDigest,key),type,function:functions[type]||'Unclassified source facility',label:type.charAt(0).toUpperCase()+type.slice(1),name:null,nameStatus:'unnamed source facility',buildingId:b?.id||null,locationType:b?'building':'outdoor',position:anchor,sourcePosition:position,district:district||b?.district||'unclassified village',knowledge:'discovered',availability:'unknown; no operating hours or gameplay services inferred',provenance:{provider:'settlemaker',providerRevision:request.upstreamCommit,providerPoiId,providerBuildingId,evidence,binding,truth:'provider-generated, source-backed'}});
  };
  const poiIds=new Set();
  for (const f of features.filter(f=>f.properties.layer==='poi')) {
    const p=f.properties;
    if (typeof p.poi_id!=='string' || poiIds.has(p.poi_id) || f.geometry.type!=='Point') throw Error('Duplicate or invalid provider POI');
    poiIds.add(p.poi_id);
    add({key:['poi',p.poi_id],type:p.kind,providerPoiId:p.poi_id,providerBuildingId:p.building_id??null,position:f.geometry.coordinates,district:p.ward_type,evidence:'GeoJSON POI kind and explicit building_id (null means outdoor)'});
  }
  if (request.role==='village') {
    for (const f of rawBuildings) {
      const p=f.properties;
      const type={'sm-chapel':'chapel','sm-inn':'inn','sm-house-large-tiled':'manor'}[p.glyph];
      if (type && p.building_id.startsWith('bld:landmark:')) add({key:['landmark',p.building_id],type,providerBuildingId:p.building_id,position:centroid(f.geometry.coordinates[0]),evidence:'explicit village landmark building_id and glyph; not a fabricated POI'});
    }
  }
  return validateModel({schemaVersion:1,audience:'developer',settlement:{id:sid,worldIdentity:request.fixtureSha256,worldSeed:request.worldSeed,burgId:request.burgId,name},layout:{revision:layoutDigest,providerRevision:request.upstreamCommit,units:geojson.metadata.coordinate_units,axes:'x-right-y-down',bounds:geojson.metadata.local_bounds,geography:'provider-generated; not authoritative Azgaar geography',scaleEvidence:geojson.metadata.scale},buildings,establishments,geometry:{features:features.filter(f=>!['building','poi','entrance'].includes(f.properties.layer)).map(f=>({layer:f.properties.layer,geometry:f.geometry})),fields:backdrop.fields,water:backdrop.water},diagnostics,sourceInventory:{buildingCount:buildings.length,poiCount:poiIds.size,establishmentCount:establishments.length}});
}
