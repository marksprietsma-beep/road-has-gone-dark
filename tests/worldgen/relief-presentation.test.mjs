import assert from "node:assert/strict";
import test from "node:test";
import {createSlopeHachures, projectRelief} from "../../tools/worldgen/relief-presentation.mjs";

const icons = [
  {icon: "relief-mount-3", x: 10, y: 20, s: 12},
  {icon: "relief-hill-2", x: 5, y: 6, s: 8},
  {icon: "relief-conifer-4", x: 30, y: 40, s: 5}
];

test("projects provider relief without provider icon ids", () => {
  assert.deepEqual(projectRelief(icons)[0], {kind: "mount", variant: 3, x: 10, y: 20, size: 12, order: 0});
  assert.equal(JSON.stringify(projectRelief(icons)).includes("relief-mount"), false);
});

test("hachures are deterministic, ordered, and mountain-only", () => {
  const relief = projectRelief(icons);
  assert.deepEqual(createSlopeHachures(relief), createSlopeHachures(relief));
  assert.equal(createSlopeHachures(relief).length, 4);
  assert.ok(createSlopeHachures(relief).every(line => line.strength > 0 && line.x1 !== line.x2));
});
