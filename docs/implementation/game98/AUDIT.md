# GAME-98 audit and integration

Base: merged GAME-99 main `d4e5e3c559793633cf1dc03f2b11e33d933c2f8d`. Work begins on `feature/game-98-shared-local-icons`; no historical research branches were merged.

The atlas's `MapIconProvider` already decodes the approved original Game-icons SVGs into cached Godot textures. Settlement and landmark layers select semantic roles. The GAME-62 debug local viewer consumes Node-generated shared-icon metadata and uses the same provider. Neither pathway supplied the actual gameplay map: `scripts/expedition/expedition_map.gd` instantiated `site_marker.gd` diamond buttons and manually drew a house. The existing sealed geography artwork correctly omitted private sites; the missing integration was its public marker overlay.

The implementation reuses that provider and the existing production controls. `data/map_icons/semantic-roles-v1.json` is the common mapping consumed by `MapIconRoles` in Godot and `shared-map-icons.mjs` in Node. Atlas settlement groups and singular marker aliases retain their existing meanings. The helper includes and integrity-pins the JSON; export presets preserve raw SVGs so FileAccess-based decoding works inside the exported game.

| Meaning | Approved role |
| --- | --- |
| Source city/town/village/hamlet/fort etc. | Actual source settlement group; trading-post/caravanserai alias to trading |
| Source caves/mines/lighthouses | Existing singular cave/mine/lighthouse SVG |
| Source shrine, sacred grove, crypt, bridge, portal or rift | Only the corresponding actual source type justifies that role |
| Generated ruins | ruins |
| Generated camp, ordinary clearing, roadside obstruction | encounters; approved portrait, exact kind in tooltip |
| Unknown/custom generated type | unidentified |

There is no approved tent, ordinary clearing or obstruction icon in the retained family. The generic encounter portrait is an explicit fallback, not a claim that every such site is magical. Dangerous woodland no longer maps to sacred forest. A nearby source route does not justify a bridge or fortress. Ordinary rumours never borrow a portal. Existing watchtower/shrine debug mappings retain the defensive/religious roles; no new landmarks are generated to showcase them.

The production map accepts only the established public projection plus the known source hometown's name/role. Unknown and rumoured rows receive no textures, tooltips, coordinates or click controls. Discovered, visited and resolved rows retain identity; completion is a separate tick, the active party a pennant and the destination a gold rim. Existing generation records, IDs, coordinates, save ownership, combat, character identities and XP authority are unchanged.

Buttons stay at their exact projected position and survive selection updates. The rectangular 32-logical-pixel hitbox is independent of transparent SVG pixels. Close neighbors shrink artwork only; hometown, party and selection have stable visual/input priority. There is no cosmetic repositioning or hidden-site decluttering. Tooltips retain full names, generated provenance, knowledge and state. Source hometown remains distinguishable.

`tools/regiongen/site-icons.mjs` handles debug SVG labels and needs no production rewrite. `tools/expedition/content.mjs` and `SandboxGenerator` remain unchanged; six existing GAME-99 context fixtures pin their original content SHA values. The only sandbox-record change is defensive filtering of its public projection to explicitly known states; no saved record schema changes.

Licence: existing Game-icons CC BY 3.0 attribution to Delapouite/Lorc, upstream commit `82d948812bfe3f269ef8f731dcdb07b08160edc4`, retained per-role metadata and README. No new artwork, asset recolours, substitutions or separate rasterisation files were generated. The retained `assets/map_icons/trials/game-icons` directory is a runtime resource catalogue despite its historical name; the playable map does not require a debug scene to load it.
