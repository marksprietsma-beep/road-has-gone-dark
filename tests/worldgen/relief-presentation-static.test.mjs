import assert from "node:assert/strict";
import {readFile} from "node:fs/promises";
import test from "node:test";

const rulesPath = new URL("../../scripts/debug/map_renderer/relief_presentation.gd", import.meta.url);
const layerPath = new URL("../../scripts/debug/map_renderer/relief_layer.gd", import.meta.url);
const viewerPath = new URL("../../scripts/debug/world_fixture_viewer.gd", import.meta.url);
const rendererPath = new URL("../../scripts/debug/world_fixture_renderer.gd", import.meta.url);

test("overview keeps only a sparse deterministic mountain subset", async () => {
  const rules = await readFile(rulesPath, "utf8");
  assert.match(rules, /modulus = 12/);
  assert.match(rules, /keep_below = 1/);
  assert.match(rules, /separation = 56\.0/);
  assert.match(rules, /if zoom_band <= 0:\n\t\t\t\tcontinue/);
});

test("mountain selection and ridge chains are deterministic and presentation-only", async () => {
  const rules = await readFile(rulesPath, "utf8");
  assert.match(rules, /static func stable_key/);
  assert.match(rules, /static func ridge_segments/);
  assert.match(rules, /nearest_distance := maximum_distance/);
  assert.doesNotMatch(rules, /cell|voronoi/i);
});

test("LOD is relative to each fixture fit zoom", async () => {
  const viewer = await readFile(viewerPath, "utf8");
  const renderer = await readFile(rendererPath, "utf8");
  assert.match(viewer, /limited \/ maxf\(_fit_zoom, 0\.001\)/);
  assert.match(renderer, /value < 1\.35/);
  assert.match(renderer, /value < 2\.5/);
});

test("overview ridges are thick enough to survive fit-to-map scale", async () => {
  const layer = await readFile(layerPath, "utf8");
  assert.match(layer, /ridge_width: float = 3\.4/);
  assert.match(layer, /segment_stride: int = 3/);
  assert.match(layer, /size = clampf\(size \* 1\.7, 18\.0, 34\.0\)/);
});
