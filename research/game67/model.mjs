// Provider-neutral research model. No game-save imports or provider runtime.
export function pointInPolygon(point, rings) {
  const inside = ring => {
    let hit = false;
    for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      const [x, y] = point, [ax, ay] = ring[j], [bx, by] = ring[i];
      const cross = (x-ax)*(by-ay)-(y-ay)*(bx-ax);
      if (Math.abs(cross) < 1e-8 && x >= Math.min(ax,bx)-1e-8 && x <= Math.max(ax,bx)+1e-8 && y >= Math.min(ay,by)-1e-8 && y <= Math.max(ay,by)+1e-8) return true;
      if ((ay > y) !== (by > y) && x < (bx-ax)*(y-ay)/(by-ay)+ax) hit = !hit;
    }
    return hit;
  };
  return inside(rings[0]) && !rings.slice(1).some(inside);
}
export const centroid = ring => {
  const open = ring.slice(0,-1);
  return [0,1].map(axis => open.reduce((sum,p) => sum+p[axis],0)/open.length);
};
export function validateModel(model) {
  if (model.schemaVersion !== 1 || !model.settlement?.id || !Array.isArray(model.buildings) || !Array.isArray(model.establishments)) throw Error('Unsupported or malformed facility model');
  const ids = new Set();
  for (const item of [...model.buildings,...model.establishments]) {
    if (typeof item.id !== 'string' || ids.has(item.id)) throw Error('Duplicate or invalid canonical identity');
    ids.add(item.id);
  }
  const buildings = new Map(model.buildings.map(b => [b.id,b]));
  const point = p => Array.isArray(p) && p.length === 2 && p.every(Number.isFinite);
  for (const b of model.buildings) {
    if (!Array.isArray(b.polygon) || !b.polygon.length || b.polygon.some(r => !Array.isArray(r) || r.length < 4 || r.some(p => !point(p)) || JSON.stringify(r[0]) !== JSON.stringify(r.at(-1)))) throw Error('Invalid building polygon');
  }
  for (const e of model.establishments) {
    if (!point(e.position) || !['building','outdoor'].includes(e.locationType) || !['unknown','discovered','visited'].includes(e.knowledge)) throw Error('Invalid establishment');
    if (e.locationType === 'building' && (!buildings.has(e.buildingId) || !pointInPolygon(e.position,buildings.get(e.buildingId).polygon))) throw Error('Invalid building association');
    if (e.locationType === 'outdoor' && e.buildingId !== null) throw Error('Outdoor establishment has a building');
  }
  return model;
}
export function publicExport(model) {
  validateModel(model);
  const result = structuredClone(model);
  result.audience = 'public';
  result.establishments = result.establishments.filter(e => e.knowledge !== 'unknown');
  // Anonymous physical roofs remain; provider IDs, semantic glyphs and hidden
  // associations are never sent to the public renderer.
  result.buildings = result.buildings.map(({id,polygon,district}) => ({id,polygon,district}));
  delete result.diagnostics;
  delete result.sourceInventory;
  return result;
}
export function setKnowledge(model,id,status) {
  if (!['unknown','discovered','visited'].includes(status)) throw Error('Invalid knowledge status');
  const copy = structuredClone(model), item = copy.establishments.find(e => e.id === id);
  if (!item) throw Error('Unknown establishment identity');
  item.knowledge = status;
  return validateModel(copy);
}
export function reload(text) { return validateModel(JSON.parse(text)); }
export function declutter(items, project, {size=26, labels=true, selectedId=null}={}) {
  const reserved=[], visible=[];
  const priority = {guildhall:100,chapel:95,warehouse:90,manor:85,pier:80,inn:75,smithy:70};
  const ordered = [...items].sort((a,b) => (b.id===selectedId)-(a.id===selectedId) || (priority[b.type]||40)-(priority[a.type]||40) || a.id.localeCompare(b.id));
  for (const item of ordered) {
    const [x,y] = project(item.position), width=labels ? size+Math.max(50,item.label.length*6.5) : size;
    const box={x:x-size/2,y:y-size/2,w:width,h:size};
    if (reserved.some(r => box.x < r.x+r.w+5 && box.x+box.w+5 > r.x && box.y < r.y+r.h+5 && box.y+box.h+5 > r.y)) continue;
    visible.push({item,box});reserved.push(box);
  }
  return visible;
}
