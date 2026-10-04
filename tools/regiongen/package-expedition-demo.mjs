#!/usr/bin/env node
import {readFile, writeFile, mkdir} from 'node:fs/promises';
import {createHash} from 'node:crypto';

// A deliberately pinned review slice, never a release seed selector.
const input = 'tools/regiongen/.tmp/contextual-atlas-showcase-highland.json';
const output = 'assets/demo/kindum-region.json';
const bytes = await readFile(input);
const region = JSON.parse(bytes);
const sha = createHash('sha256').update(await readFile('tests/worldgen/fixtures/atlas-showcase.json')).digest('hex');
if (region.source_context.parent_source_world_sha256 !== sha || region.source_context.source_home_burg_id !== 554)
  throw Error('Pinned Kindum example/source mismatch');
// Keep scenery, grid and source icons; developer mock combat/routes are not gameplay.
delete region.encounter_demo_v1;
delete region.hex_route_preview_v1;
await mkdir('assets/demo', {recursive:true});
const packed = JSON.stringify(region) + '\n';
await writeFile(output, packed);
await writeFile('assets/demo/manifest.json', JSON.stringify({
  schema_version:1, meaning:'PINNED_SESSION_ONLY_EXPEDITION_DEMO',
  path:'res://' + output, region_id:region.id, source_context_id:region.source_context.id,
  source_world_sha256:sha, source_home_burg_id:554,
  region_sha256:createHash('sha256').update(packed).digest('hex')
},null,2) + '\n');
console.log('PASS: packaged pinned source-matched Kindum expedition demo');
