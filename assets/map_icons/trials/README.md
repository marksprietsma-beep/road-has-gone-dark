# Atlas icon art — Game-icons selected (GAME-28)

See [AUDIT.md](AUDIT.md) for the verified shortlist, corrections, coverage and sources. `candidate_manifest.json` is the screening record; each installed family has `mapping.json` with exact source members, checksums, prepared crop boxes, role mappings and declared gaps. `audit/` contains complete downloaded archive inventories and category counts.

## Approved artwork

After testing the atlas viewer, Mark selected **Game-icons by Delapouite (CC BY 3.0)**. The 12 `game-icons/{role}.svg` illustrations are the initial world-scale settlement and macro-POI mappings, not a fixed limit for the later regional game. **Attribution to Delapouite and the game-icons.net CC BY 3.0 licence is required on distribution.** The source SVGs were modified for parchment preview by removing the old square backing and recolouring the original white ink to a dark tone, while retaining icon outlines.

Only `Game-icons` and a developer-only `Procedural` control are active in the viewer. Azgaar macrodata, maps, hidden sites, terrain, mountains, vegetation, roads and zoom rules remain unchanged. We do **not** silently borrow glyphs from other packs.

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
