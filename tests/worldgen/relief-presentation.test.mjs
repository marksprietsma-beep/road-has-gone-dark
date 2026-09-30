import assert from "node:assert/strict";
import test from "node:test";
import {generateSlopeHachures, projectReliefIcons} from "../../tools/worldgen/relief-presentation.mjs";

test("relief projection exposes neutral fields and preserves bottom-edge ordering", () => {
  const projected = projectReliefIcons([
    {icon: "relief-hill-4", x: 8, y: 12, s: 4},
    {icon: "relief-mountSnow-2-illustrated", x: 1, y: 2, s: 10},
    {icon: "not-a-relief-icon", x: 0, y: 0, s: 1}
  ]);
  assert.deepEqual(projected, [
    {kind: "mountSnow", variant: 2, x: 6, y: 7, size: 10},
    {kind: "hill", variant: 4, x: 10, y: 14, size: 4}
  ]);
});

test("slope hachures are deterministic, seed-sensitive presentation strokes", () => {
  const terrain = {
    points: [[5, 5], [10, 5], [5, 10], [10, 10]],
    heights: [80, 62, 44, 20],
    neighbors: [[1, 2], [0, 3], [0, 3], [1, 2]]
  };
  const first = generateSlopeHachures({seed: "atlas-a", ...terrain});
  assert.deepEqual(first, generateSlopeHachures({seed: "atlas-a", ...terrain}));
  assert.notDeepEqual(first, generateSlopeHachures({seed: "atlas-b", ...terrain}));
  assert.ok(first.every(stroke => Object.keys(stroke).sort().join() === "dx,dy,strength,x,y"));
});
