import assert from "node:assert/strict";
import test from "node:test";
import {JSDOM} from "../../vendor/azgaar/node_modules/jsdom/lib/api.js";
import {buildReliefSidecar, defaultReliefPath} from "../../tools/worldgen/relief-sidecar.mjs";

test("relief sidecar expands illustrated Azgaar mountains, hills and vegetation into direct geometry", () => {
  const document = new JSDOM(`<svg><defs>
    <symbol id="relief-mount-1-illustrated" viewBox="0 0 40 40"><path d="M0 0 L40 40"/></symbol>
    <symbol id="relief-hill-1-illustrated" viewBox="0 0 40 40"><path d="M1 1 L20 20"/></symbol>
    <symbol id="relief-deciduous-1-illustrated" viewBox="0 0 40 40"><path d="M2 2 L18 18"/></symbol>
    <symbol id="relief-conifer-1-illustrated" viewBox="0 0 40 40"><path d="M3 3 L17 17"/></symbol>
  </defs></svg>`).window.document;

  const svg = buildReliefSidecar({width: 100, height: 50, sourceDocument: document, relief: [
    {icon: "relief-mount-1-illustrated", x: 1, y: 2, s: 20},
    {icon: "relief-deciduous-1-illustrated", x: 4, y: 5, s: 6},
    {icon: "relief-conifer-1-illustrated", x: 5, y: 6, s: 7},
    {icon: "relief-grass-1-illustrated", x: 6, y: 7, s: 8},
    {icon: "relief-hill-1-illustrated", x: 7, y: 8, s: 10}
  ]});

  assert.match(svg, /viewBox="0 0 100 50"/);
  assert.match(svg, /data-icon="relief-mount-1-illustrated"/);
  assert.match(svg, /data-icon="relief-hill-1-illustrated"/);
  assert.match(svg, /data-icon="relief-deciduous-1-illustrated"/);
  assert.match(svg, /data-icon="relief-conifer-1-illustrated"/);
  assert.match(svg, /translate\(1 2\) scale\(0\.5 0\.5\)/);
  assert.match(svg, /M0 0 L40 40/);
  assert.doesNotMatch(svg, /relief-grass-1-illustrated/);
  assert.doesNotMatch(svg, /<use\b/);
  assert.doesNotMatch(svg, /<symbol\b/);
});

test("default sidecar path stays next to canonical JSON", () => {
  assert.equal(defaultReliefPath("fixtures/world.json"), "fixtures/world.relief.svg");
});
