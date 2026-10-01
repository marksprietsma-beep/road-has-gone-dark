# Azgaar headless world generation

## Architecture and usage

The development harness runs the real vendored Azgaar `GenerationPipeline` in Node, with jsdom providing browser primitives. `headless-entry.ts` is the boundary: it initializes only Azgaar's model/data modules, applies Azgaar's own seeded PRNG, selects the built-in `continents` template (so no canvas image loader is needed), and invokes the canonical pipeline. It then maps the result into project-owned JSON. No renderer or world-map UI is part of this work.

Azgaar requires Node 24 or newer. Install its locked dependencies and generate a world:

```sh
npm ci --ignore-scripts --prefix vendor/azgaar
tools/worldgen/generate-world.sh --seed example-seed --output /tmp/world.json
tools/worldgen/verify-worldgen.sh game-11-determinism
```

The exporter recursively sorts object keys and sanitizes JSON at the project boundary for Godot compatibility. Valid Unicode, including surrogate pairs, is preserved; only unpaired UTF-16 surrogate code units are replaced with U+FFFD. The verifier generates twice, compares this canonical JSON byte-for-byte, rejects any remaining unpaired surrogates (including in object keys), prints its SHA-256 hash, checks the required top-level data sets, and for the acceptance seed verifies the result against the checked-in canonical fixture.

The verified regression fixture is `tests/worldgen/fixtures/game-11-determinism.json`, with metadata in `game-11-determinism.meta.json`. For Azgaar 1.153.1 at the pinned upstream commit, the acceptance seed `game-11-determinism` produces a 5,166,790-byte fixture with SHA-256 `2eb428e783101dc1c99213c31816dbd50f3a68370094917949a88bfbb5811fa5`. Generator upgrades require deliberate fixture/hash review.

## Godot fixture viewer

The development-only scene `res://scenes/debug/world_fixture_viewer.tscn` loads that fixture through a schema boundary and presents a baked pixel-art terrain map with relief, political borders, routes, rivers, settlements, labels, and selection as independent visual layers. Run it without changing the game's main scene:

```sh
godot --path . scenes/debug/world_fixture_viewer.tscn
```

Use the arrow keys to pan, the middle mouse button to drag, the mouse wheel to zoom around the cursor, click to inspect a cell, and `F` to fit the complete map. The layer panel independently toggles relief, political color, rivers, borders, routes, settlements, and labels. This is an inspection aid for the current fixture contract, deliberately isolated from New Game and not a canonical `GameWorld` implementation.

## Provenance and licence

`vendor/azgaar` is Fantasy Map Generator 1.153.1, from upstream commit `cc5dbac5db12ba4a7c47e647f6bef8bd7bf930c6`. It is MIT licensed; the vendored copyright and permission notice remains in `vendor/azgaar/LICENSE` and must accompany distributions containing this source.

## Canonical data boundary

The output is provider-neutral schema version 1. It includes map dimensions and geographic bounds; cell coordinates, adjacency, height and ownership/geography indices; geographic features; states; provinces; settlements; cultures; religions; biomes; rivers; routes; and markers/points of interest. Typed arrays become JSON arrays and non-data functions are removed. Provider identity is metadata, not an instruction for consumers to deserialize Azgaar classes.

The intended production boundary is a packaged standalone helper or equivalent generator service. Players must not need to install Node or a browser, and Godot save data must never depend on Azgaar's in-memory classes.

## Limitations and next step

jsdom does not render or perform layout. The harness deliberately supports a built-in procedural template only; imported image heightmaps, map rendering, editor/UI state, and gameplay concepts such as races, factions, secrets, and dungeons are out of scope.

The next integration step is a Godot `GameWorld` adapter that validates `schemaVersion`, converts canonical records into game-owned resources, assigns stable game identifiers, and reports unsupported schema versions. That adapter should consume only this JSON contract rather than vendored module shapes.
