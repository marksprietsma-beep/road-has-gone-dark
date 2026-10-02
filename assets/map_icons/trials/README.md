# Settlement / landmark icon comparison assets (GAME-28)

These are small curated *source-derived* trial assets, staged separately from implementation so Codex can work **offline**. All are actual external icon artwork; none is a generated drawing. The sets cover settlement levels and future major POIs/local-area maps. **No provider is selected yet**. A Godot test selector should compare them side by side in the same two atlas fixtures before choosing an art direction.

| Key / directory | Upstream source | Licence | Notes |
| --- | --- | --- | --- |
| `pinhead/` | [Pinhead](https://github.com/waysidemapping/pinhead) (original `icons/`) | CC0 1.0 | Diverse cartographic icons (castles, houses, chapels, caves, forts, mines). Has distinctive pictograms. |
| `game-icons/` | [Game-icons.net (Delapouite)](https://github.com/game-icons/icons/tree/master/delapouite) | CC BY 3.0 | Illustrative fantasy silhouettes, especially strong breadth of ruins, caves, shrines, towers etc. Artist: Delapouite (http://delapouite.com). Original square backdrop removed and white ink converted to dark ink for transparent atlas use, retaining shapes. Attribution required if distributed. |
| `osmic/` | [Osmic](https://github.com/gmgeo/osmic) | CC0 1.0 | Simplified practical map pictograms, including castles, gate, lighthouse, monastery/worship, huts, historical sites. SVG metadata retained. |
| `lucide/` | [Lucide](https://github.com/lucide-icons/lucide) | ISC; [LICENSE](https://github.com/lucide-icons/lucide/blob/main/LICENSE) | Coherent outline icons, useful in regional UI and POI panels. CurrentColor replaced by dark ink and stroke slightly thickened in this **trial only**. Retain ISC copyright notice if redistributed. |
| `kenney/` | [Kenney Cartography Pack](https://kenney.nl/assets/cartography-pack), [public redistribution mirror](https://github.com/ETdoFresh/kenney.nl/tree/master/cartographypack) | CC0 1.0 | Original complete 832×448 SVG vector atlas plus 12 role-named original PNG sprites from the source pack's `PNG/Default/` directory; no unverified vector crops. |

## Screening policy — updated 2 October 2026

Mark set a **minimum 7/10** score. These are **provisional research screening scores**, calculated as
period-appropriate map aesthetic (0–5) + useful fantasy/world/POI coverage (0–5).
They are **not** a replacement for in-Godot visual judgement.
The authoritative machine-readable shortlist is `candidate_manifest.json`.

| Trial | Style | Coverage | Total | In viewer? |
| --- | ---: | ---: | ---: | --- |
| Game-icons | 3 | 5 | **8** | Yes: all 12 SVG roles are staged. |
| Mercator | 5 | 2 | **7** | Not yet: original PNG package needed. |
| de Fer | 5 | 3 | **8** | Not yet: original PNG package needed. |
| Donia | 5 | 2 | **7** | Not yet: original PNG package needed. |
| Zatta | 5 | 2 | **7** | Not yet: original PNG package needed. |
| CoMiGo | 4 | 4 | **8** | Not yet: original SVG/PNG package needed. |
| Müller | 5 | 4 | **9** | Not yet: original PNG package needed. |
| Janssonius | 5 | 3 | **8** | Not yet: original PNG package needed. |
| Super Rough RPG/HEX | 4 | 4 | **8** | Research only: distribution terms / pack need verifying before checking into repository. |

Removed from the **selector**: Kenney (6), Pinhead (6), Osmic (3), Lucide (3).
They remain physically checked in as archived research material rather than
deleting already merged source files. Procedural is an unscored baseline.

**No empty or fabricated choices:** the Godot selector only exposes a qualified
family when actual role-named `capital` and `town` SVG or PNG files are present
under the matching `trials/<directory>/`. At present, that means **Procedural**
and **Game-icons**. Other candidates have been recorded and will become
selectable when their real source artwork is staged.
A new provider directory accepts a mix of `<role>.png` and `<role>.svg`;
role identity must be supported by the source, not inferred from an unrelated
icon. Explicitly document absent roles rather than silently using another set.

Original download pages, licence claims, exact source directories and
screening notes are in `candidate_manifest.json`. Do not commit entire
original archives; choose small, representative, verified source artwork
before comparing at actual map zoom levels. The historical packs have very
different detailed illustration footprints and may need careful resampling.

## Standard trial mapping
Each standalone directory contains the same 12 **role filenames** (all `.svg`):
`capital`, `city`, `town`, `village`, `hamlet`, `fort`, `monastery`, `trading`, `ruins`, `cave`, `lighthouse`, and `mine`.

The names describe the **intended test role**, not necessarily a claim about a site's underlying Azgaar group or an icon's specificity. E.g. `osmic/cave.svg` uses an entrance symbol; it is a fallback approximation. Do not conflate missing POI art with detected POI type.

Kenney now uses original individually named **PNG/Default** art from the same CC0 pack rather than guessing positions in the vector sheet. Source mappings: `capital` ← `castleWide`, `city` ← `castle`, `town` ← `houses`, `village` ← `house`, `hamlet` ← `houseSmall`, `fort` ← `towerWatch`, `monastery` ← `churchLarge`, `trading` ← `stable`, `ruins` ← `runis` (the pack's original spelling), `cave` ← `rocks`, `lighthouse` ← `lighthouse`, `mine` ← `mine`. **Cave caveat:** the pack contains no dedicated cave icon; `rocks` is an explicitly approximate rocky-site marker, not a cave-entrance depiction. These are display-only mappings and do not modify world generation or actual POI identities.

### Godot comparison acceptance
- Expose **only actual downloaded and source-verified candidates** scoring at least 7/10 in the Godot selector. Procedural remains a baseline only. See the shortlist above. Do not display a new candidate as working before it has real authored art.
- Use a single active family for both Settlement and Landmark **preview** so visual coherence can be compared across a populated coast, mountain belt and islands. Keep independent layer toggles.
- Preserve the Azgaar `group` lookup/fallback, identical count/filtering, layer order, seed, and fixture data across all candidates. Do not let style change the generated data, terrain or zoom band thresholds.
- No new world POIs or local generator features: test current **actual** landmark records, and use a small in-view **legend** of the common 12 roles if some POI examples aren't near the current viewport. The preview must not imply that all POIs should be revealed in real gameplay.
- Cache small textures per style/role; set consistent world-unit target sizes for meaningful comparison. Carefully handle Godot 4 SVG import, transparent backgrounds, pixel density and aspect ratio. If an image can't render, show the error rather than silently replacing it with rectangles.
- Keep original licences/documentation in project; no fonts or large generated maps.
- Stage trial code as a **small draft PR**. Mark selects **Publish draft PR** in ChatGPT after Codex completes, then visually tests both seeds and shares screenshots.
- Later `GAME-21` regional maps can reuse the same source art **through a style provider/manifest**, not by hardcoding source paths in gameplay logic.

See: `docs/design/world-map-worldbuilding-decisions.md`.
