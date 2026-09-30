#!/usr/bin/env node
import {spawnSync} from "node:child_process";
import {readFile, writeFile, mkdir, copyFile} from "node:fs/promises";
import {resolve, dirname} from "node:path";
import {fileURLToPath} from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../..");
const generator = resolve(root, "tools/worldgen/generate-azgaar.mjs");
const tmpDir = resolve(root, ".tmp/atlas-showcase");
const output = resolve(root, "tests/worldgen/fixtures/atlas-showcase.json");
const meta = resolve(root, "tests/worldgen/fixtures/atlas-showcase.meta.json");

const countArg = process.argv.indexOf("--count");
const candidateCount = countArg >= 0 ? Math.max(3, Number(process.argv[countArg + 1] || 12)) : 12;
const prefixArg = process.argv.indexOf("--prefix");
const prefix = prefixArg >= 0 ? String(process.argv[prefixArg + 1] || "atlas-showcase") : "atlas-showcase";
const threshold = 62;

await mkdir(tmpDir, {recursive: true});

function mountainScore(world) {
  const heights = world.cells?.heights ?? [];
  const neighbors = world.cells?.neighbors ?? [];
  const visited = new Uint8Array(heights.length);
  const clusters = [];
  let highCells = 0;

  for (let start = 0; start < heights.length; start++) {
    if (Number(heights[start]) < threshold) continue;
    highCells++;
    if (visited[start]) continue;

    let size = 0;
    const stack = [start];
    visited[start] = 1;
    while (stack.length) {
      const cell = stack.pop();
      size++;
      for (const raw of neighbors[cell] ?? []) {
        const next = Number(raw);
        if (next < 0 || next >= heights.length || visited[next]) continue;
        if (Number(heights[next]) < threshold) continue;
        visited[next] = 1;
        stack.push(next);
      }
    }
    clusters.push(size);
  }

  clusters.sort((a, b) => b - a);
  const largest = clusters[0] ?? 0;
  const second = clusters[1] ?? 0;
  const third = clusters[2] ?? 0;
  // Prefer worlds with at least one substantial chain plus some secondary relief.
  const score = largest * 8 + second * 4 + third * 2 + highCells * 0.35;
  return {score, highCells, clusters: clusters.slice(0, 8)};
}

const results = [];
for (let index = 1; index <= candidateCount; index++) {
  const seed = `${prefix}-${String(index).padStart(2, "0")}`;
  const path = resolve(tmpDir, `${seed}.json`);
  const run = spawnSync(process.execPath, [generator, "--seed", seed, "--output", path], {
    cwd: root,
    stdio: "inherit"
  });
  if (run.status !== 0) {
    console.error(`Generation failed for ${seed}`);
    process.exit(run.status ?? 1);
  }
  const world = JSON.parse(await readFile(path, "utf8"));
  const metrics = mountainScore(world);
  results.push({seed, path, ...metrics});
  console.log(`score=${metrics.score.toFixed(1)} high=${metrics.highCells} top=${metrics.clusters.join(",")} seed=${seed}`);
}

results.sort((a, b) => b.score - a.score);
const winner = results[0];
await copyFile(winner.path, output);
await writeFile(meta, JSON.stringify({
  purpose: "visual atlas review fixture; not the canonical determinism fixture",
  seed: winner.seed,
  mountainThreshold: threshold,
  score: winner.score,
  highCells: winner.highCells,
  topMountainClusters: winner.clusters,
  candidates: results.map(({seed, score, highCells, clusters}) => ({seed, score, highCells, clusters}))
}, null, 2) + "\n");

console.log("\nSelected atlas showcase fixture:");
console.log(`  seed: ${winner.seed}`);
console.log(`  score: ${winner.score.toFixed(1)}`);
console.log(`  fixture: ${output}`);
console.log(`  metadata: ${meta}`);
console.log("Canonical game-11-determinism fixture was not modified.");
