# Map asset audit — 2 October 2026 (historical comparison archive)

**Decision on 2 October:** Mark chose **Game-icons (Delapouite)** after local Godot comparisons. It is the only active authored candidate; Procedural is the development control. All *other* sourced PNG/source-sample files were pruned from the current PR tree to avoid shipping unused texture imports, but are preserved in earlier [commit `f12122a`](https://github.com/marksprietsma-beep/road-has-gone-dark/commit/f12122a96df46a6ac66a512b35d3f7cb2d521b85). The full original ZIP bundle was never in GitHub. Tables below document the **historical audit**, not currently installed/active art.


Downloaded and CRC-checked 12 source archives. Every PNG in those archives decoded successfully. Exact inventories and SHA-256 archive hashes are under `audit/`; each installed family has a `mapping.json` tracing source members, source hashes, crop boxes and prepared hashes. Counts below are image variants, not distinct gameplay roles.

## Historical audit observations

Before the local visual decision, the research assessment favoured Vischer for illustrated historical settlements, Müller and Ogilby for additional regional POIs, and Game-icons for specialist fantasy coverage. The visual choice is now final: **Game-icons**. The source families described below are retained as comparative evidence, not a pending selection.

## Verified shortlist

| Family | Score | PNGs in source archive | Viewer roles / 12 | Assessment |
| --- | ---: | ---: | ---: | --- |
| Mercator | 7 | 238 | 5 | Capital/city use different city drawings. Village/hamlet use small-town drawings as scale proxies. No dedicated supernatural POIs. |
| de Fer | 8 | 303 | 8 | Capital/city use manor-and-village combinations as scale proxies. Castle and ruins are verified individual members inside the Unique folder. No dedicated cave, lighthouse or mine. |
| Donia | 7 | 122 | 4 | Church artwork is a religious-site proxy for monastery, not a dedicated monastery. No verified town/rural roles, so retained as a supplementary source rather than a viewer family. |
| Müller | 8 | 1631 | 8 | Capital uses walled city; hamlet uses a village dot. Trading uses a market town, not a caravanserai. Mineral symbols are not mine-entrance drawings, so mine remains absent. |
| Janssonius | 7 | 274 | 4 | Capital/city use separate city variants. Maritime marks include abstract shipwreck symbols, not illustrated wrecked ships. Missing rural and religious roles. |
| Super Rough RPG/HEX | 8 | 24 | 6 | Capital uses castle. Dungeon icon is not a cave and is retained separately. White interior fills are part of source artwork. No dedicated rural, religious, trading or lighthouse roles. |
| Vischer | 9 | 959 | 8 | Capital/city use different city drawings; hamlet uses a house, fort a castle. Ruins/monuments is a mixed source category: chosen specimen visually reviewed as ruined structures. |
| Ogilby | 8 | 907 | 8 | Capital/fort use castles; town uses a large-village road plan. No distinct city sprite. Mine is a historical lead-mine symbol, not an entrance illustration. Two genuine lighthouses were found inside Unique Settlements. |
| Hogenburg | 8 | 718 | 7 | Urban-building kit: capital/fort use castles, city a block, town a building group, village/hamlet individual buildings. These are scale proxies, not prebuilt settlement tiers. |

Game-icons: **8/10**, existing 12/12-role SVG trial retained. These ratings are subjective project-fit assessments, not marketplace ratings or final visual approval.

## Corrections to the earlier research

- CoMiGo: **6/10 for this map task**, down from 8. Its 271 SVG designs repeat as black and white PNGs (plus a cover); equipment, UI and skill icons dominate. It lacks a broad settlement/POI ladder. Downloaded, inspected, excluded from the selector.
- Zatta: **6/10**, down from 7. The 507 PNGs include many hachures and abstract fortified/dot symbols. Its later-period cartographic style and limited POI breadth make it a weaker fit. Downloaded, inspected, excluded.
- Müller: **8/10**, down from 9. Excellent breadth, but villages are often dots and industry uses abstract symbols. Resource symbols have not been relabelled as mine entrances.
- Janssonius: **7/10**, down from 8. Useful maritime extension; shipwrecks are chart symbols, and rural/religious/ruin/cave roles are absent.
- Donia: **7/10**, supplementary source only. No separate town/rural set was verified; it is not advertised as a full selectable family.
- Super Rough distribution is confirmed by the author on the official page: use, modification and distribution are unrestricted. The 24 original PNGs are retained as small source samples.

## Additional discoveries

- **Vischer — 9/10:** 959 PNGs; diverse settlements, castles, monasteries, agriculture and ruins/monuments. Added to viewer.
- **Ogilby — 8/10:** 907 PNGs; especially useful for road journeys, with bridges, wells, springs, mines, quarries and beacons. Added to viewer.
- **Hogenburg — 8/10:** 718 PNGs; city blocks, walls/gates, shrines, tombs and caves. Added as a clearly documented urban-kit trial; settlement tiers are illustrative proxies.
- **Miko Map Icons — provisional 8/10:** 43 PNGs, downloaded and visually inspected. Strong cave/lighthouse/mine/ruin coverage; coloured cartoon look. Free game use is stated, but no raw-asset redistribution licence is bundled or explicit on the page, so loose files are not added to the public repository. Original ZIP retained in the personal source bundle.
- **Limofeus:** source page checked, not downloaded. The 455 designs / 1,820 files are mostly dungeon props, UI and variants; useful for a later dungeon-art task, not selected as a settlement family.

## Historical viewer behaviour and validation (pre-pruning)

- During the comparison, nine authored families plus Procedural were available: Game-icons, Mercator, de Fer, Müller, Janssonius, Vischer, Ogilby, Hogenburg, Super Rough. Now only **Game-icons plus Procedural** are selectable.
- N/A means a role is absent in that source pack; the map uses its existing procedural marker. This is explicitly stated in the viewer. It does not silently borrow another artist’s icon.
- Red X is reserved for a promised asset that fails to load. The inventory/mapping records distinguish absence from failure.
- Political capital and settlement sizes are display roles, not claims about original historical meanings. All proxy mappings are disclosed in each mapping file.
- Prepared PNGs are only cropped to their nontransparent bounds. Source shape/colour is preserved; no generated replacements or invented crops from sheets.
- Godot 4.7.2 headless loaded all **66 expected textures** across nine authored families and recognised **42 declared gaps**, with zero provider errors. Source PNG integrity and prepared hashes also checked.
- Mark completed local aesthetic comparison and selected Game-icons. Runtime recheck of the Game-icons *default* on both fixtures remains appropriate before merging the revised PR. Terrain, seed data, zoom thresholds and generation are unchanged.

## Sources

- Game-icons: https://github.com/game-icons/icons/tree/master/delapouite
- Mercator: https://kmalexander.com/2026/06/30/mercator-settlement-a-free-16th-century-settlement-brush-set-for-fantasy-maps/
- de Fer: https://kmalexander.com/2021/09/22/de-fer-settlement-a-free-18th-century-brush-set-for-fantasy-maps/
- Donia: https://kmalexander.com/2019/05/15/donia-a-free-17th-century-cartography-brush-set-for-fantasy-maps/
- Müller: https://kmalexander.com/2025/04/16/muller-a-free-18th-century-cartography-brush-set-for-fantasy-maps/
- Janssonius: https://kmalexander.com/2020/04/27/janssonius-a-free-17th-century-cartography-brush-set-for-fantasy-maps/
- Super Rough RPG/HEX: https://bizinbarstome.itch.io/super-rough-rpghex-icons
- Vischer: https://kmalexander.com/2019/12/16/vischer-a-free-17th-century-cartography-brush-set-for-fantasy-maps/
- Ogilby: https://kmalexander.com/2019/10/15/ogilby-a-free-17th-century-road-atlas-brush-set-for-fantasy-maps/
- Hogenburg: https://kmalexander.com/2024/08/27/hogenburg-a-free-16th-century-urban-cartography-brush-set-for-fantasy-city-maps/
- Miko Map Icons: https://mikobrzu.itch.io/free-map-icon-asset-pack
- Limofeus Hand Drawn Dungeon Icons: https://limofeus.itch.io/handdrawniconpack
- CoMiGo: https://comigo.itch.io/fantasy-icons-ink
- Zatta: https://kmalexander.com/2020/05/26/zatta-a-free-18th-century-cartography-brush-set-for-fantasy-maps/
