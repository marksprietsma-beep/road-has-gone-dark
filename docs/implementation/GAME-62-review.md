# GAME-62 — Local Region Generator V1 review

**Status: Awaiting Mark visual acceptance.** Generator proof only; no gameplay integration. Baseline main: `3c06cf81e46c7ce9edd4e9ebf20a9940c0ca6f23`. Full PR extraction audit: `docs/implementation/GAME-62-audit.md`.

## What to inspect

Open `six-map-godot-montage.jpg` first. It combines actual Godot-rendered developer views, explicitly showing undiscovered sites for review. Each case also has a full-resolution `.developer.godot.png` and an ordinary `.godot.png`. The ordinary public maps show terrain, original burgs and source routes, with minor sites still undiscovered. `cell-hex-scale.godot.png` shows the source cell, neighbouring cells and anchored hex overlay. `adjacent-cell-godot-comparison.jpg` and `continuity.json` record two neighbouring-cell checks.

There are separate public `.json`/`.svg` and full `.developer.json`/`.developer.svg` files. Developer artifacts are intentionally secret-bearing diagnostics. They are never the public export model; D explicitly switches the isolated viewer to a different file. No scouting or discovery gameplay is implemented.

## Single review matrix

The selected original irregular cell owns generated sites. View bounds enclose its bounding box, enlarged by 20% of the longest cell extent on each side, shifted inside the world at edges. The enclosing square therefore includes contextual neighbours and is larger than the owned cell. Sizes below are original Azgaar canvas units, **not kilometres**. Hex pitch is globally fixed at one source unit; one hex area is √3/2 source square units.

| Case | Parent cell | View span | View / cell area | Cell-area hexes / dry owned centres | Minor sites / initially visible | Route / river records |
|---|---:|---:|---:|---:|---:|---:|
| game-11-determinism-shore | 2796 | 17.04 | 4.59 | 73.0 / 74 | 6 / 0 | 4 / 1 |
| game-11-determinism-river | 1856 | 24.59 | 4.16 | 167.8 / 168 | 8 / 0 | 5 / 1 |
| game-11-determinism-highland | 4268 | 18.92 | 4.85 | 85.3 / 84 | 6 / 0 | 2 / 0 |
| atlas-showcase-shore | 3426 | 18.50 | 4.42 | 89.5 / 90 | 5 / 0 | 3 / 1 |
| atlas-showcase-river | 1235 | 19.21 | 2.89 | 147.3 / 149 | 2 / 0 | 2 / 1 |
| atlas-showcase-highland | 3710 | 20.64 | 3.18 | 154.4 / 154 | 7 / 0 | 1 / 0 |

**All six:** original indexed coast/lake polygons and original burg/route IDs preserved; rivers remain labelled approximate cell-centre chains; generated sites pass source dry-land and parent-polygon tests; hidden names/IDs/positions absent from public output; shared approved Game-icons; inspected real Godot images and deterministic repeat rendering. Coast cases show actual shore polygons; river/highland cases use genuine river/height source predicates. No generated bridges, protected routes or physical scale claims.

## Visual judgement

The two coasts differ in water exposure and woodland distribution. River cases read as mixed woodland and clear ground with schematic cultivated edges. Both highlands have distinct conifer patches and open ground, with subtle contour relief; the second has broader rocky slopes. Density is moderate (2–8 minor locations per owned cell), with substantial empty ground. Shared markers retain constant screen size; minor labels appear at medium/close zoom, and inspection supplies detail. The gold boundary is a diagnostic ownership guide, not a terrain feature.

This is a coherent first atlas-style generator proof. Ground colour transitions remain visibly stylised and the highland relief is subtle rather than a finished mountain illustration. Mark's visual acceptance is still required; no claim that the art is final.

## Source versus provider

**Azgaar:** immutable parent polygon, neighbour geometry, original coast/lakes, burgs, route polylines, macro markers and coarse height/biome. The optional sidecar exports `pack.vertices.p` and `pack.cells.v` without adding fields to canonical world JSON. Both pinned worlds replay byte-identically. Region/provider/site/hex generation identities use a separately versioned hash of source seed, provider, canvas and spatial/biome tables, excluding display names; the full canonical file SHA remains provenance. Renaming a burg in a newly serialised source file does not reroll the cell terrain or minor sites. Existing GameWorld/save identities are not changed.

**Genuine Town Forge 1.2.4**, pinned commit `4b25a37c14c80970d2b66f0c587468c7493855d3`: actual `generateFull` in landscape mode produces forest polygons and ridge paths. The replaceable adapter retains these as source-filtered decoration. Provider-generated water, roads and settlement layouts are excluded. It is a landscape decorator here, not the authority for geography or a complete seamless map engine.

**Our systems:** globally sampled biome/elevation illustration, forest canopies, contour/hillshade primitives, schematic fields, source-filtered provider tree marks, minor-site candidates and knowledge filtering. Metadata distinguishes source exact, source approximation, inferred visual and generated local. No settlement or dungeon interiors are generated.

Macro landmark policy: clearly physical volcano/mountain/waterfall/lighthouse landmarks may be broadly visible from source; other canonical markers lack authoritative discovery state and remain hidden until supplied knowledge marks them discovered. Full developer truth retains their original identity/position. Unknown markers never silently become public.

## Continuity and limitations

- **game-11-determinism: cells 2796 ↔ 2795**: 230 shared hex IDs, 5 matching route segments, 0 matching approximate river segments, 1 common original geography features; shared original vertex IDs [8668, 8675]; 20 identical global terrain-field samples.

- **atlas-showcase: cells 3426 ↔ 3534**: 311 shared hex IDs, 3 matching route segments, 2 matching approximate river segments, 1 common original geography features; shared original vertex IDs [9371, 9397]; 20 identical global terrain-field samples.

Original features and globally anchored hexes/field samples agree independently of generation order. Full decorative seams are **not proven**: Town Forge decorations seed per cell, schematic fields and edge clipping depend on the visible crop, and render-grid tessellation can differ between views. This is not a fine collision mesh or a proof of safe crossings. Azgaar's macro polygon resolution is retained rather than disguised as measured micro geography. No physical planet radius, walking speed, ETA, passability or river-mouth reconstruction is asserted.

## Verification

Passed locally: six-case byte-identical JSON replay; stable identities/terrain after burg rename; distinct cell identities/seeds; malformed source/sidecar rejection; source coordinate and hex conversion; dry owned-site placement; public privacy; two neighbour overlaps; original source projection and coast/lake suites; eight canonical JSON/relief tests; pinned Town Forge blob integrity; GAME-7 world/save smoke; Godot viewer loading/inspection/overlay/failed-load smoke; actual OpenGL renderer captures and repeat pixel equality.

Renderer: Godot 4.7.2, OpenGL 4.5 compatibility, Mesa llvmpipe. Logs are included. CI workflow is supplied but **has not run on this unpublished commit**. No remote green-CI claim is made.

Existing canonical worlds, Azgaar vendor, approved world atlas, main menu, gameplay, campaign stores and v1 saves are unchanged. Original experimental branches remain intact.

## Windows / PowerShell review

After publishing the draft PR, use a separate review checkout. If the publication assigns a different remote branch name, use the branch shown on that PR for the `git switch` line.

```powershell
$ReviewDir = Join-Path $env:USERPROFILE "Games\road-has-gone-dark-game62-review"
New-Item -ItemType Directory -Force (Split-Path $ReviewDir) | Out-Null
git clone https://github.com/marksprietsma-beep/road-has-gone-dark.git $ReviewDir
Set-Location $ReviewDir
git fetch origin
git switch --track origin/codex/game-62-local-region-v1
npm ci --prefix vendor/azgaar --ignore-scripts --no-audit --no-fund
node tests/regiongen/verify-pins.mjs
node tools/regiongen/prove-generator-v1.mjs
node tests/regiongen/verify-v1.mjs
node tests/regiongen/verify-source-projection.mjs
node tests/regiongen/verify-geography-sidecar.mjs
node --test tests/worldgen/canonical-json.test.mjs tests/worldgen/relief-sidecar.test.mjs
```

Expected: six source contexts in `review/local-region-v1`, separate public/developer JSON and SVG, manifest, continuity report and PASS results. The generation command replays both pinned worlds and refuses a changed canonical output. No unexplained `.tmp` download is needed; sidecars/compiler files are generated disposable intermediates.

Set `$GodotExe` to your actual Godot 4.7.2 executable, then paste:

```powershell
$GodotExe = "C:\Path\To\Godot_v4.7.2-stable_win64.exe"
& $GodotExe --headless --editor --path . --quit
& $GodotExe --headless --path . --script res://tests/regiongen/smoke-v1.gd
& $GodotExe --headless --path . --script res://tests/game_world/smoke-game-world.gd
& $GodotExe --path . --script res://tests/regiongen/capture-v1.gd
& $GodotExe --path . --script res://tests/regiongen/capture-v1.gd -- --verify-render
& $GodotExe --editor --path .
```

In Godot's FileSystem dock open **`scenes/debug/local_region_v1.tscn`**, then press **F6**. This opens the isolated developer viewer. **1–3** select first-world shore/river/highland; **4–6** select the second world. **F** fits; wheel zooms; arrow keys or middle-button drag pan; click a known burg/site to inspect. **X** toggles hexes; **G** toggles source neighbour polygons; **D** loads explicitly labelled full developer truth (toggle again to return to public data). D changes no save or knowledge state. Public view deliberately has no initially discovered minor sites.

Judge fitted, medium and close zoom; source shore/road/burg relationships; readable label/marker sizes; terrain variety and empty space; and whether developer site density is convincing. Send the sample number plus a screenshot and a brief description of any unacceptable placement, scale or artwork. This task stops at that visual acceptance gate.
