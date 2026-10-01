import assert from "node:assert/strict";
import test from "node:test";
import {JSDOM} from "../../vendor/azgaar/node_modules/jsdom/lib/api.js";
import {buildReliefSidecar, defaultReliefPath} from "../../tools/worldgen/relief-sidecar.mjs";

test("relief sidecar contains only illustrated mountains and hills in provider order", () => {
  const document = new JSDOM(`<svg><defs>
    <symbol id="relief-mount-1-illustrated" viewBox="0 0 40 40"><path d="M0 0"/></symbol>
    <symbol id="relief-hill-1-illustrated" viewBox="0 0 40 40"><path d="M1 1"/></symbol>
  </defs></svg>`).window.document;
  const svg = buildReliefSidecar({width: 100, height: 50, sourceDocument: document, relief: [
    {icon: "relief-mount-1-illustrated", x: 1, y: 2, s: 3},
    {icon: "relief-deciduous-1-illustrated", x: 4, y: 5, s: 6},
    {icon: "relief-hill-1-illustrated", x: 7, y: 8, s: 9}
  ]});
  assert.match(svg, /viewBox="0 0 100 50"/);
  assert.match(svg, /relief-mount-1-illustrated/);
  assert.match(svg, /relief-hill-1-illustrated/);
  assert.doesNotMatch(svg, /deciduous/);
  assert.ok(svg.indexOf('x="1"') < svg.indexOf('x="7"'));
});

test("default sidecar path stays next to canonical JSON", () => {
  assert.equal(defaultReliefPath("fixtures/world.json"), "fixtures/world.relief.svg");
});
