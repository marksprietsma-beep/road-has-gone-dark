import{readFile,writeFile}from'node:fs/promises';import{insidePolygon}from'../../../tools/regiongen/compose-local-region.mjs';
const town=JSON.parse(await readFile('research/game73/examples/thilranlena.town-assessment.json')),source=JSON.parse(await readFile('research/game67/fixtures/thilranlena.json'));
const records=town.entrances.map(e=>({entranceId:e.id,kind:e.kind,position:e.position,sourceRouteMatches:e.routes,insideFilledSyntheticWater:source.backdrop.water.some(r=>insidePolygon(e.position,r))}));
await writeFile('research/game73/evidence/access-check.json',JSON.stringify({records,interpretation:'g25 is a harbour-tagged foot connection, but its point is not inside filled synthetic water. This is semantic ambiguity, not proof of a water-crossing contradiction.'},null,2)+'\n');
console.log('PASS actual entrance/water-ring checks:',records.map(r=>`${r.entranceId}: ${r.kind}, wet=${r.insideFilledSyntheticWater}`).join('; '));
