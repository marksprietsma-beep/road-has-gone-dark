# Settlement / landmark icon comparison assets (GAME-28)

These are small curated *source-derived* trial assets, staged separately from implementation so Codex can work **offline**. All are actual external icon artwork; none is a generated drawing. The sets cover settlement levels and future major POIs/local-area maps. **No provider is selected yet**. A Godot test selector should compare them side by side in the same two atlas fixtures before choosing an art direction.

| Key / directory | Upstream source | Licence | Notes |
| --- | --- | --- | --- |
| `pinhead/` | [Pinhead](https://github.com/waysidemapping/pinhead) (original `icons/`) | CC0 1.0 | Diverse cartographic icons (castles, houses, chapels, caves, forts, mines). Has distinctive pictograms. |
| `game-icons/` | [Game-icons.net (Delapouite)](https://github.com/game-icons/icons/tree/master/delapouite) | CC BY 3.0 | Illustrative fantasy silhouettes, especially strong breadth of ruins, caves, shrines, towers etc. Artist: Delapouite (http://delapouite.com). Original square backdrop removed and white ink converted to dark ink for transparent atlas use, retaining shapes. Attribution required if distributed. |
| `osmic/` | [Osmic](https://github.com/gmgeo/osmic) | CC0 1.0 | Simplified practical map pictograms, including castles, gate, lighthouse, monastery/worship, huts, historical sites. SVG metadata retained. |
| `lucide/` | [Lucide](https://github.com/lucide-icons/lucide) | ISC; [LICENSE](https://github.com/lucide-icons/lucide/blob/main/LICENSE) | Coherent outline icons, useful in regional UI and POI panels. CurrentColor replaced by dark ink and stroke slightly thickened in this **trial only**. Retain ISC copyright notice if redistributed. |
| `kenney/` | [Kenney Cartography Pack](https://kenney.nl/assets/cartography-pack), [public redistribution mirror](https://github.com/ETdoFresh/kenney.nl/tree/master/cartographypack) | CC0 1.0 | **Original complete source SVG atlas**, not individual sprites. Original source SVG lacked explicit dimensions; provided 832x448 viewBox. A Godot prototype must isolate actual matching source cells or split/crop icons; **do not treat the entire SVG as an individual symbol**. Broader original pack offers castles, buildings, churches, mills, gates, ruins, lighthouses, mines, towers, trees etc. |

## Standard trial mapping
Each standalone directory contains the same 12 **role filenames** (all `.svg`):
`capital`, `city`, `town`, `village`, `hamlet`, `fort`, `monastery`, `trading`, `ruins`, `cave`, `lighthouse`, and `mine`.

The names describe the **intended test role**, not necessarily a claim about a site's underlying Azgaar group or an icon's specificity. E.g. `osmic/cave.svg` uses an entrance symbol; it is a fallback approximation. Do not conflate missing POI art with detected POI type.

Kenney is currently a *single source atlas*; include Kenney in a meaningful comparison only once a correct sprite crop or subset export is verified. Do not fake Kenney by substituting handmade or another library's artwork.

### Godot comparison acceptance
- Build a development-only asset family selector for these **five** options: **Kenney, Pinhead, Game-icons, Osmic, Lucide**. Also offer **Current (procedural)** as a useful control, but do not count it as one of the five candidate assets.
- Use a single active family for both Settlement and Landmark **preview** so visual coherence can be compared across a populated coast, mountain belt and islands. Keep independent layer toggles.
- Preserve the Azgaar `group` lookup/fallback, identical count/filtering, layer order, seed, and fixture data across all candidates. Do not let style change the generated data, terrain or zoom band thresholds.
- No new world POIs or local generator features: test current **actual** landmark records, and use a small in-view **legend** of the common 12 roles if some POI examples aren't near the current viewport. The preview must not imply that all POIs should be revealed in real gameplay.
- Cache small textures per style/role; set consistent world-unit target sizes for meaningful comparison. Carefully handle Godot 4 SVG import, transparent backgrounds, pixel density and aspect ratio. If an image can't render, show the error rather than silently replacing it with rectangles.
- Keep original licences/documentation in project; no fonts or large generated maps.
- Stage trial code as a **small draft PR**. Mark selects **Publish draft PR** in ChatGPT after Codex completes, then visually tests both seeds and shares screenshots.
- Later `GAME-21` regional maps can reuse the same source art **through a style provider/manifest**, not by hardcoding source paths in gameplay logic.

See: `docs/design/world-map-worldbuilding-decisions.md`.
