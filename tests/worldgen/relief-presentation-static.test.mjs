import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import test from "node:test";

const rulesPath = new URL("../../scripts/debug/map_renderer/relief_presentation.gd", import.meta.url);
const layerPath = new URL("../../scripts/debug/map_renderer/relief_layer.gd", import.meta.url);

test("overview suppresses individual relief symbols", async () => {
  const rules = await readFile(rulesPath, "utf8");
  assert.match(rules, /if zoom_band <= 0:\n\t\treturn \[\]/);
});

test("mountain selection and ridge chains are deterministic and presentation-only", async () => {
  const rules = await readFile(rulesPath, "utf8");
  assert.match(rules, /static func stable_key/);
  assert.match(rules, /static func ridge_segments/);
  assert.match(rules, /nearest_distance := maximum_distance/);
  assert.doesNotMatch(rules, /cell|voronoi/i);
});

test("medium and close LOD retain sparse generated mountains", async () => {
  const rules = await readFile(rulesPath, "utf8");
  assert.match(rules, /modulus := 4 if zoom_band == 1 else 5/);
  assert.match(rules, /keep_below := 1 if zoom_band == 1 else 3/);
  const layer = await readFile(layerPath, "utf8");
  assert.match(layer, /visible_icons\(model\.relief, zoom_band\)/);
});
