# Settlement and landmark icon trials (GAME-28)

See [AUDIT.md](AUDIT.md) for the verified shortlist, corrections, coverage and sources. `candidate_manifest.json` is the screening record; each installed family has `mapping.json` with exact source members, checksums, prepared crop boxes, role mappings and declared gaps. `audit/` contains complete downloaded archive inventories and category counts.

## Chosen art direction — 2 October 2026

**Game-icons (Delapouite, CC BY 3.0)** was selected by Mark after reviewing the rendered alternatives in Godot. It is the **default** for both settlement and supported macro-POI symbols. The existing 12 source-derived SVGs are the **initial atlas role mappings**, not the limit of the broader library. Source-specific credit and the CC BY 3.0 attribution requirement remain mandatory if published. Keep future GAME-21 regional landmarks within this coherent icon family where possible; any extensions must have verified semantic meaning, deliberate ink treatment and licensing/attribution.

The other artwork families were evaluated solely for comparison and provenance. The trial harness should not dictate final game asset contracts. Azgaar terrain, vegetation, seed logic, data, zoom thresholds and hidden-POI rules are unaffected by this art decision. The procedural markers remain an explicit development fallback.

## Original comparison inventory

Nine authored families plus Procedural were previously available: Game-icons, Mercator, de Fer, Müller, Janssonius, Vischer, Ogilby, Hogenburg and Super Rough. All pass the minimum 7/10 screening threshold. Donia is retained as supplementary source samples. CoMiGo and Zatta were downgraded to 6 after actual download inspection.

Only role-named samples and small representative original source samples are checked in; full ZIP archives are kept out of the game repository. Additional variants can be recovered from the recorded original download URLs and archive hashes. No source artwork is generated. No terrain or world data changes.

**N/A** in the legend means the source lacks that role; the existing procedural map marker remains visible. **Red X** means an expected asset failed to load. Some settlement-tier drawings are explicitly documented display proxies; never interpret those choices as changes to generated settlement identity.

## Testing

Open `scenes/debug/world_fixture_viewer.tscn` in Godot and press F6. Change Icon Art Trial, press F to fit, zoom with the wheel and press N for the other available fixture. Compare settlements and POIs, including the 12-role legend. Missing source roles are disclosed. Mark has chosen Game-icons in the interactive visual comparison. Confirm the chosen default loads correctly on both fixtures after the selection commit; merge only after the normal PR review and Mark publishes the draft PR.

## Retained earlier source provenance

Rejected earlier assets stay for rollback/provenance; they are not selectable.

| Key / directory | Upstream source | Licence | Notes |
| --- | --- | --- | --- |
| `pinhead/` | [Pinhead](https://github.com/waysidemapping/pinhead) (original `icons/`) | CC0 1.0 | Diverse cartographic icons (castles, houses, chapels, caves, forts, mines). Has distinctive pictograms. |
| `game-icons/` | [Game-icons.net (Delapouite)](https://github.com/game-icons/icons/tree/master/delapouite) | CC BY 3.0 | Illustrative fantasy silhouettes, especially strong breadth of ruins, caves, shrines, towers etc. Artist: Delapouite (http://delapouite.com). Original square backdrop removed and white ink converted to dark ink for transparent atlas use, retaining shapes. Attribution required if distributed. |
| `osmic/` | [Osmic](https://github.com/gmgeo/osmic) | CC0 1.0 | Simplified practical map pictograms, including castles, gate, lighthouse, monastery/worship, huts, historical sites. SVG metadata retained. |
| `lucide/` | [Lucide](https://github.com/lucide-icons/lucide) | ISC; [LICENSE](https://github.com/lucide-icons/lucide/blob/main/LICENSE) | Coherent outline icons, useful in regional UI and POI panels. CurrentColor replaced by dark ink and stroke slightly thickened in this **trial only**. Retain ISC copyright notice if redistributed. |
| `kenney/` | [Kenney Cartography Pack](https://kenney.nl/assets/cartography-pack), [public redistribution mirror](https://github.com/ETdoFresh/kenney.nl/tree/master/cartographypack) | CC0 1.0 | Original complete 832×448 SVG vector atlas plus 12 role-named original PNG sprites from the source pack's `PNG/Default/` directory; no unverified vector crops. |
