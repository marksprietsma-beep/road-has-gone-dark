#!/usr/bin/env node
// GAME-31: align source-derived atlas POIs with the pinned Azgaar marker taxonomy.
// Offline, no dependency installs; does not regenerate the fixture.
import assert from "node:assert/strict";
import {existsSync, readFileSync} from "node:fs";
import {fileURLToPath} from "node:url";
import {resolve, dirname} from "node:path";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const read = rel => readFileSync(resolve(root, rel), "utf8");
const iconBase = "assets/map_icons/trials/game-icons/";
const generator = read("vendor/azgaar/src/generators/markers-generator.ts");
const provider = read("scripts/debug/map_renderer/map_icon_provider.gd");
const renderer = read("scripts/debug/map_renderer/landmark_layer.gd");
const manifest = JSON.parse(read(iconBase + "landmark_sources.json"));

const start = generator.indexOf("private getDefaultConfig()");
const end = generator.indexOf("private generateTypes()", start);
assert.ok(start >= 0 && end > start, "Pinned Azgaar marker config moved");
const upstream = [...generator.slice(start, end).matchAll(/^\s*type:\s*"([^"]+)",/gm)]
  .map(match => match[1]);

const providerBlock = provider.match(/const MARKER_TYPES: Array\[String\] = \[([\s\S]*?)\]/);
assert.ok(providerBlock, "MapIconProvider.MARKER_TYPES is missing");
const actual = [...providerBlock[1].matchAll(/"([^"]+)"/g)].map(match => match[1]);
assert.equal(upstream.length, 36, "Unexpected pinned Azgaar marker count");
assert.deepEqual([...new Set(actual)].sort(), [...new Set(upstream)].sort(), "Marker taxonomy differs from upstream");

const aliasesBlock = renderer.match(/const EXISTING_ROLE_ALIASES := \{([\s\S]*?)\}/);
assert.ok(aliasesBlock, "Existing role aliases missing");
const aliases = Object.fromEntries([...aliasesBlock[1].matchAll(/"([^"]+)":\s*"([^"]+)"/g)]
  .map(match => [match[1], match[2]]));
assert.deepEqual(Object.keys(aliases).sort(), ["caves", "lighthouses", "mines", "ruins"]);
assert.ok(renderer.includes('else "unidentified"'), "Unknown marker fallback missing");
assert.ok(!renderer.includes("_draw_volcano") && !renderer.includes("_draw_marker("), "Procedural POIs remain");
assert.ok(provider.includes('var family := "Game-icons"'), "Game-icons must remain the default");

const covered = new Set();
for (const type of upstream) {
  const role = aliases[type] ?? type;
  const icon = resolve(root, iconBase, role + ".svg");
  assert.ok(existsSync(icon), "Missing authored SVG for " + type);
  const svg = readFileSync(icon, "utf8");
  assert.match(svg, /^<svg /);
  assert.match(svg, /fill="#28221b"/);
  assert.ok(!svg.includes('<path d="M0 0h512v512H0z"/>'), "Opaque background " + role);
  assert.ok(!svg.includes('fill="#fff"'), "White ink not normalised " + role);
  if (!aliases[type]) {
    const item = manifest.newRoles[type];
    assert.ok(item && ["delapouite", "lorc"].includes(item.author), "Unknown source for " + type);
    assert.equal(item.prepared, type + ".svg");
  }
  covered.add(type);
}
assert.equal(Object.keys(manifest.newRoles).length, 33, "32 new official marker types plus fallback required");
assert.ok(existsSync(resolve(root, iconBase, "unidentified.svg")));
assert.ok(!covered.has("unidentified"), "Fallback should never override a built-in");

for (const file of [
  "tests/worldgen/fixtures/game-11-determinism.json",
  "tests/worldgen/fixtures/atlas-showcase.json"
]) {
  if (!existsSync(resolve(root, file))) continue;
  const world = JSON.parse(read(file));
  const unknown = [...new Set((world.markers ?? []).map(m => m.type))]
    .filter(type => !covered.has(type));
  assert.deepEqual(unknown, [], "Fixture contains unknown marker kinds in " + file);
  console.log(file + ": " + (world.markers ?? []).length + " existing markers covered");
}
console.log("PASS: all 36 Azgaar macro types have sourced SVGs plus neutral fallback");
