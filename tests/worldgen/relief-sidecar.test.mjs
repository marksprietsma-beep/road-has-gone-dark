import assert from "node:assert/strict";
import test from "node:test";
import {JSDOM} from "../../vendor/azgaar/node_modules/jsdom/lib/api.js";
import {buildReliefSidecar, defaultReliefPath} from "../../tools/worldgen/relief-sidecar.mjs";

test("relief sidecar expands illustrated Azgaar mountains and hills into direct geometry", () => {
  const document = new JSDOM(`<svg><defs>
    <symbol id="relief-mount-1-illustrated" viewBox="0 0 40 40"><path d="M0 0 L40 40"/></symbol>
    <symbol id="relief-hill-1-illustrated" viewBox="0 0 40 40"><path d="M1 1 L20 20"/></symbol>
    <symbol id="relief-deciduous-1-illustrated" viewBox="0 0 40 40"><path d="M2 2 L18 18"/></symbol>
  </defs></svg>`).window.document;

  const svg = buildReliefSidecar({width: 100, height: 50, sourceDocument: document, relief: [
    {icon: "relief-mount-1-illustrated", x: 1, y: 2, s: 20},
    {icon: "relief-deciduous-1-illustrated", x: 4, y: 5, s: 6},
    {icon: "relief-hill-1-illustrated", x: 7, y: 8, s: 10}
  ]});

  assert.match(svg, /viewBox="0 0 100 50"/);
  assert.match(svg, /data-icon="relief-mount-1-illustrated"/);
  assert.match(svg, /data-icon="relief-hill-1-illustrated"/);
  assert.match(svg, /translate\(1 2\) scale\(0\.5 0\.5\)/);
  assert.match(svg, /translate\(7 8\) scale\(0\.25 0\.25\)/);
  assert.match(svg, /M0 0 L40 40/);
  assert.doesNotMatch(svg, /relief-deciduous-1-illustrated/);
  assert.doesNotMatch(svg, /<use\b/);
  assert.doesNotMatch(svg, /<symbol\b/);
});

test("default sidecar path stays next to canonical JSON", () => {
  assert.equal(defaultReliefPath("fixtures/world.json"), "fixtures/world.relief.svg");
});
