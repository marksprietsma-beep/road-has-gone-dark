#!/usr/bin/env node
// Compare the canonical seeded world against the same world with increased
// Azgaar marker density. All non-marker world data and sidecars must match.
import assert from "node:assert/strict";
import {readFileSync} from "node:fs";

const [normalFile, stressFile] = process.argv.slice(2);
if (!normalFile || !stressFile) {
  throw new Error("Usage: node tools/worldgen/check-landmark-stress.mjs <normal.json> <stress.json>");
}
const read = p => JSON.parse(readFileSync(p, "utf8"));
const normal = read(normalFile);
const stress = read(stressFile);

assert.equal(normal.seed, stress.seed, "The two preview seeds must match");
assert.equal(normal.schemaVersion, 1, "Unexpected canonical schema");
assert.equal(stress.schemaVersion, 1, "Stress test should not change canonical schema");
assert.ok(stress.markers.length > normal.markers.length,
  "Stress preview did not add landmarks");
assert.deepEqual({...normal, markers: []}, {...stress, markers: []},
  "Geography, settlements, water, cultures, zones or other canonical data changed");
for (const suffix of [".relief.svg", ".vegetation.svg"]) {
  const n = readFileSync(normalFile.replace(/\.json$/, suffix));
  const s = readFileSync(stressFile.replace(/\.json$/, suffix));
  assert.deepEqual(s, n, "Azgaar sidecar changed: " + suffix);
}
const histogram = records => {
  const count = {};
  for (const marker of records) count[marker.type] = (count[marker.type] ?? 0) + 1;
  return count;
};
console.log("Normal: ", normal.markers.length, "markers", Object.keys(histogram(normal.markers)).length, "types");
console.log("Stress: ", stress.markers.length, "markers", Object.keys(histogram(stress.markers)).length, "types");
console.log("PASS: higher landmark count, unchanged canonical geography and relief/vegetation sidecars");
