# Azgaar headless world generation

## Architecture and usage

The development harness runs the real vendored Azgaar `GenerationPipeline` in Node, with jsdom providing browser primitives. `headless-entry.ts` is the boundary: it initializes only Azgaar's model/data modules, applies Azgaar's own seeded PRNG, selects the built-in `continents` template (so no canvas image loader is needed), and invokes the canonical pipeline. It then maps the result into project-owned JSON. No renderer or world-map UI is part of this work.

Azgaar requires Node 24 or newer. Install its locked dependencies and generate a world:

```sh
npm ci --ignore-scripts --prefix vendor/azgaar
tools/worldgen/generate-world.sh --seed example-seed --output /tmp/world.json
tools/worldgen/verify-worldgen.sh game-11-determinism
```

The verifier generates twice, compares canonical JSON byte-for-byte, prints its SHA-256 hash, and checks the required top-level data sets. Generated temporary files are ignored. A generated fixture should be checked in under `tests/worldgen/fixtures/` once the locked dependencies can be installed and the pipeline verified.

## Provenance and licence

`vendor/azgaar` is Fantasy Map Generator 1.153.1, from upstream commit `cc5dbac5db12ba4a7c47e647f6bef8bd7bf930c6`. It is MIT licensed; the vendored copyright and permission notice remains in `vendor/azgaar/LICENSE` and must accompany distributions containing this source.

## Canonical data boundary

The output is provider-neutral schema version 1. It includes map dimensions and geographic bounds; cell coordinates, adjacency, height and ownership/geography indices; geographic features; states; provinces; settlements; cultures; religions; biomes; rivers; routes; and markers/points of interest. Typed arrays become JSON arrays and non-data functions are removed. Provider identity is metadata, not an instruction for consumers to deserialize Azgaar classes.

The intended production boundary is a packaged standalone helper or equivalent generator service. Players must not need to install Node or a browser, and Godot save data must never depend on Azgaar's in-memory classes.

## Limitations and next step

jsdom does not render or perform layout. The harness deliberately supports a built-in procedural template only; imported image heightmaps, map rendering, editor/UI state, and gameplay concepts such as races, factions, secrets, and dungeons are out of scope. Generator upgrades require deliberate fixture/hash review because upstream implementation changes can alter seeded output.

The next integration step is a Godot `GameWorld` adapter that validates `schemaVersion`, converts canonical records into game-owned resources, assigns stable game identifiers, and reports unsupported schema versions. That adapter should consume only this JSON contract rather than vendored module shapes.
