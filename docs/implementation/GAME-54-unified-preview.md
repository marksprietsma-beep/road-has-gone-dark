# GAME-54 — first common-scale site/terrain preview (draft)

GAME-44 source-constrained fantasy sites [PR #42](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/42) and GAME-51 source/inferred relief [PR #44](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/44) are **sibling drafts** and cannot be laid on top of one another without a coordinate agreement.

## Explicit spatial decision

This first integration uses only the existing GAME-46/47 **16 original Azgaar canvas units** around an actual named burg. It deliberately does **not** render the separate GAME-48 Earth-equivalent hypothetical 30 km local reference over those POI coordinates. That physical assumption and any real planetary radius remain undecided and are not implied by screenshots.

The original source v1 `source_context.id` is reused, and:
- GAME-44 generated sites v2, their source-route eligibility, discovery filtering and stable IDs remain unchanged. Original `burg:<id>` hometown and source routes are not moved.
- GAME-51 `buildInferredFineTerrain` is sampled using the **exact same original context source bounds** and input world fingerprint. The separately versioned inferred-field ID is an illustration, never a walking collision map or a SAVE record.
- The original source polygon land/lake visual masks still clip vegetation/relief. River-cell polylines remain approximate, and no safe routes, ports, bridges, crossing sites or actual detailed coastlines are claimed.
- The normal SVG displays only original source facts plus `discovered`/`visited` game-owned site glyphs. Rumours carry non-positional hints. Hidden and rumoured names/IDs/coordinates never go into its paired public JSON.
- Any full unfiltered generated sites, source authority and inferred field are written to an explicitly **developer-only JSON path**, separate from the public preview archive. These files are not gameplay saves and must not be served as a public game state.

`tools/regiongen/generate-unified-preview.mjs` **rejects** mismatched canonical world fingerprints and reference-scale viewports. `tests/regiongen/verify-unified-preview.mjs` checks each of six actual Azgaar contexts for identity consistency, dry-land site placement, developer/public separation, no leaks and generation determinism. CI regenerates original worlds byte-identically and publishes six paired filtered SVG/JSON previews. Vendor trees and existing saved site formats are never edited.

## Still missing

This is only a source-correct **two-layer visual integration**, not GAME-44 and GAME-51 fully merged and **not** an approved playable local map. Source macro roads are not fine travel routes; detailed terrain and scale calibration remain undecided. An **independent public-only Godot F6 preview** now exists at `scenes/debug/unified_public_preview.tscn`: 1–6 switch six source regions, F fits the map, and click inspects known places. It reads **only** `tools/regiongen/.tmp/public/` JSON and SVG, rejects traversal and non-public paths, displays rumours only as generic non-positional hints, and performs **no saves or discovery writes**. The new `smoke-unified-public.gd` checks each real world, known-place clicking, missing-file fail-closed and refusal of developer data. This is not an actual game screen or debug hidden-site reveal. Detailed local buildings, true route/terrain travel, physical scale, legacy save migration, richer illustration and optional terrain/audit toggles remain future work. Do not merge all stacked PRs or present this as a finished 30 km world.

**In-editor testing:** not requested of Mark until visual acceptance. The dedicated test scene is `scenes/debug/unified_public_preview.tscn`; open it and press F6 only when requested. The Actions workflow runs the headless smoke automatically against all six player-filtered maps.
