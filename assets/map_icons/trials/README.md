# Atlas icon art — Game-icons selected (GAME-28)

See [AUDIT.md](AUDIT.md) for the verified shortlist, corrections, coverage and sources. `candidate_manifest.json` is the screening record; each installed family has `mapping.json` with exact source members, checksums, prepared crop boxes, role mappings and declared gaps. `audit/` contains complete downloaded archive inventories and category counts.

## Approved artwork

After testing the atlas viewer, Mark selected **Game-icons by Delapouite (CC BY 3.0)**. The 12 `game-icons/{role}.svg` illustrations are the initial world-scale settlement and macro-POI mappings, not a fixed limit for the later regional game. **Attribution to Delapouite and the game-icons.net CC BY 3.0 licence is required on distribution.** The source SVGs were modified for parchment preview by removing the old square backing and recolouring the original white ink to a dark tone, while retaining icon outlines.

Only `Game-icons` and a developer-only `Procedural` control are active in the viewer. Azgaar macrodata, maps, hidden sites, terrain, mountains, vegetation, roads and zoom rules remain unchanged. We do **not** silently borrow glyphs from other packs.

## Azgaar macro landmarks — GAME-31 (visually approved)

The original atlas imported only 4 of Azgaar's 36 built-in marker categories, leaving custom volcano cones, crossed-line battlefields and generic POI dots. GAME-31 adds verified Game-icons SVGs for the other **32 official marker classes**, plus a neutral authored `unidentified` pin for unknown/custom future categories (with a warning). All existing placements, zoom-band visibility rules and objective data are preserved. No new POIs or hidden information are created.

- Existing roles reused: `ruins`, `caves`, `lighthouses`, `mines` (the original approved four).
- All **36 exact `type` names** come from pinned `vendor/azgaar/src/generators/markers-generator.ts`, not a speculative taxonomy. Asset coverage is checked by `node tools/worldgen/verify-landmark-icons.mjs`.
- New SVGs in `game-icons/<type>.svg` come from [Game-icons](https://github.com/game-icons/icons), pinned source revision `82d948812bfe3f269ef8f731dcdb07b08160edc4`, credited by individual artist in [landmark_sources.json](game-icons/landmark_sources.json). **Delapouite and Lorc, CC BY 3.0**: both artists must be credited if the game is distributed. Only original shapes are used, with the same dark parchment-ink adaptation as our earlier assets.
- Mark reviewed the original and ×8 stress fixtures visually and approved the simplified, decluttered result. The obsolete art-comparison panel remains removed. All 36 source categories are covered.
- Labeling/inspection remains **GAME-22**, and hidden-site/fog knowledge remains **GAME-10**. Local minor-POI art expansion is separate **GAME-21**.

## Landmark readability and reference key (GAME-31)

The first ×8 landmark-stress images exposed collisions, especially over named cities, forests and mountain passes. **This is a stress fixture, not the actual planned game population.** The renderer now:
- Uses **screen-aware spacing**, rather than painting every nearby icon regardless of zoom; at equal priority, marker source order is deterministic.
- Gives important persistent locations (volcanoes, ruins, major battles, dungeons, portals, rifts) precedence over routine waypoints. Dangerous encounters outrank minor events.
- Reserves the actual settlement-symbol positions and approximate drawn state/burg label bounds, then suppresses marker icons that would cover those positions. Disabling Labels or Settlements releases their protected space on the next redraw. No source data or discovery flags are modified, and source markers marked `hidden` are not drawn.
- Displays a compact, **default-collapsed Map Key** at the upper left. Expand to browse four themed sections with the actual Game-icons textures and concise explanations for all 36 native Azgaar roles.
- Provides **Show all overlaps (QA)** inside the key so a reviewer can temporarily see raw crowded markers without changing the saved fixture, then disable it to return to the priority-based display.

The Map Key uses **white text and a legend-only white-alpha shader** to show white versions of the otherwise dark Game-icons shapes. Map-world sprites keep the original dark ink. This white rendering is a UI-only preference; no source SVGs were recoloured for the map.

This is a **readability and icon-meaning preview**, not final POI exploration UI. GAME-22 handles selecting individual landmarks and known/discovered inspection details; this change must not automatically reveal unknown fantasy sites.

## Dense landmark preview for visual QA (GAME-31)

For icon review, we can ask **Azgaar itself** to regenerate landmarks on the same fixed geography using its native placement criteria at higher density. This is an *optional developer-only test world*, **not** the normal game world's spawn rate, not new fixture data in GitHub, and not a mock set of arbitrary test dots.

Run once with **Node.js 24+** after `npm ci --prefix vendor/azgaar --ignore-scripts`:

```powershell
cd C:\projects\road-has-gone-dark
npm ci --prefix vendor/azgaar --ignore-scripts
node tools/worldgen/generate-azgaar.mjs --seed game-11-determinism --output tools/worldgen/.tmp/landmark-stress.json --landmark-density 8
```

The generator writes three files in ignored `tools/worldgen/.tmp/`: `landmark-stress.json`, `landmark-stress.relief.svg`, `landmark-stress.vegetation.svg`. Run `node tests/worldgen/validate-fixture.mjs tools/worldgen/.tmp/landmark-stress.json` to validate. **Close Godot before generating the files and reopen the scene afterward** so it discovers the extra optional fixture.

Open `scenes/debug/world_fixture_viewer.tscn`, F6, then press `N` until the extra landmark-stress fixture appears; F to fit, wheel zoom medium/close, toggle **Landmarks**. The same seed means exactly the same terrain, cultures, towns and illustrated mountain/vegetation sidecars, but much more artwork to evaluate. The supported preview density range is 1–12. Density 1 is fully backward-compatible: it must not regenerate markers or change the canonical test hashes. Density 8 is an intentionally crowded stress fixture and should **not** be taken as the planned in-game balance.

A downloadable version is also produced by the **Verify atlas landmark icons** GitHub Actions workflow as the `landmark-stress-preview` artifact, if online generation passes. Unzip its three files into `tools/worldgen/.tmp/`. Do not commit these large JSON/SVG files.

## Archived comparison and provenance

A dozen source archives were retrieved and verified during research, with nine families compared. The original evidence is in [AUDIT.md](AUDIT.md), `candidate_manifest.json`, `audit/*-inventory.json` and historical `<pack>/mapping.json` files. Non-selected illustrative PNGs/source samples were removed from the current PR tree to avoid shipping unused Godot assets; all remain recoverable from **Git commit `f12122a96df46a6ac66a512b35d3f7cb2d521b85`**. The complete original external ZIP archives were **not** checked into GitHub, so independently preserve the `Map_Asset_Sources_2026-10-02.zip` bundle where applicable. Historical mapping paths for archived packs refer to that earlier commit, not currently installed runtime assets.

## Test selected defaults

Open `scenes/debug/world_fixture_viewer.tscn` in Godot, press **F6**. The viewer always uses the selected Game-icons provider and no longer displays the retired Icon Art Trial panel. Press F to fit; mouse wheel to zoom; N to switch fixtures. The approved, softer blue-green rivers are shown by default. Validate map visibility with the layer toggles as usual.

## Retained earlier source provenance

Rejected earlier assets stay for rollback/provenance; they are not selectable.

| Key / directory | Upstream source | Licence | Notes |
| --- | --- | --- | --- |
| `pinhead/` | [Pinhead](https://github.com/waysidemapping/pinhead) (original `icons/`) | CC0 1.0 | Diverse cartographic icons (castles, houses, chapels, caves, forts, mines). Has distinctive pictograms. |
| `game-icons/` | [Game-icons.net (Delapouite)](https://github.com/game-icons/icons/tree/master/delapouite) | CC BY 3.0 | Illustrative fantasy silhouettes, especially strong breadth of ruins, caves, shrines, towers etc. Artist: Delapouite (http://delapouite.com). Original square backdrop removed and white ink converted to dark ink for transparent atlas use, retaining shapes. Attribution required if distributed. |
| `osmic/` | [Osmic](https://github.com/gmgeo/osmic) | CC0 1.0 | Simplified practical map pictograms, including castles, gate, lighthouse, monastery/worship, huts, historical sites. SVG metadata retained. |
| `lucide/` | [Lucide](https://github.com/lucide-icons/lucide) | ISC; [LICENSE](https://github.com/lucide-icons/lucide/blob/main/LICENSE) | Coherent outline icons, useful in regional UI and POI panels. CurrentColor replaced by dark ink and stroke slightly thickened in this **trial only**. Retain ISC copyright notice if redistributed. |
| `kenney/` | [Kenney Cartography Pack](https://kenney.nl/assets/cartography-pack), [public redistribution mirror](https://github.com/ETdoFresh/kenney.nl/tree/master/cartographypack) | CC0 1.0 | Original complete 832×448 SVG vector atlas plus 12 role-named original PNG sprites from the source pack's `PNG/Default/` directory; no unverified vector crops. |
