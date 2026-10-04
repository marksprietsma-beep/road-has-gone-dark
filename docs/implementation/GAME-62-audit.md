# GAME-62 dependency and extraction audit

Baseline: main `3c06cf81e46c7ce9edd4e9ebf20a9940c0ca6f23`. Remote game-57 head: `be768eb` (129 commits / 113 files ahead of main). Repository cloned successfully; no existing remote branches modified.

| PR | Base | Head | Audit / extraction decision |
|---|---|---|---|
| #35 | main | game-21-town-forge-region-spike (9d4f66d) | Reuse pinned provider invocation and source validation; exclude provisional km/tile CLI |
| #36 | game-21-town-forge-region-spike | game-40-direct-populated-region (c7ec757) | Historical site prototype only; use later source-constrained algorithm |
| #37 | game-40-direct-populated-region | game-42-illustrated-region-direct (bee327a) | Reuse sparse label layout; use accepted Game-icons rather than custom glyph family |
| #38 | game-21-town-forge-region-spike | game-39-source-spatial-constraints (76a9b48) | Earlier projection sibling; use mature source-projection implementation |
| #39 | game-21-town-forge-region-spike | game-39-world-space-constraints-v1 (f9b09b8) | Reuse source clipping, indexed coast/lake geometry and tests |
| #40 | game-39-world-space-constraints-v1 | game-46-local-world-context-v1 (a17bc38) | Reuse local source context and constrained decoration; replace fixed crop with cell bounds |
| #41 | game-46-local-world-context-v1 | game-48-reference-scale-diagnostic (3aeb367) | Exclude assumed-radius/physical-scale diagnostics |
| #42 | game-46-local-world-context-v1 | game-44-contextual-source-sites-v2 (fa2ef6b) | Reuse contextual eligibility, route audit and privacy filtering |
| #43 | game-48-reference-scale-diagnostic | game-49-source-authority-v1 (45163d4) | Retain provenance distinctions, no separate authority UI |
| #44 | game-49-source-authority-v1 | game-49-fine-inference-v2 (4464bf9) | Reuse global biome/elevation art sampler and rendering primitives |
| #45 | game-49-fine-inference-v2 | game-54-coherent-site-terrain-preview (2f409d5) | Sibling integration reference; use later unified component snapshots |
| #46 | game-49-fine-inference-v2 | game-53-integrated-terrain-preview (3b90f87) | Reuse unified landscape/source/site composition; replace identity and ownership |
| #47 | game-53-integrated-terrain-preview | game-55-first-expedition-loop (dbd4259) | Exclude all expedition/session/gameplay components |

Extracted files come from game-57 snapshots; retained modules adapted only where cell ownership, public filtering or clean dependency removal required it. New provider adapter uses the exact GAME-21 TypeScript transpilation and generateFull landscape invocation. No merge/cherry-pick of the gameplay stack, no deletion/rebase/reset of remote history.

Excluded GAME-55/56 expedition scenes/scripts/menu/export; GAME-59 actor mockups; GAME-60 pathfinding/effort; GAME-61 hours/scenario modules. Existing atlas, campaign/store and canonical fixtures stay identical to main. Optional sidecar adds original pack.cells.v outside canonical world JSON; no vendored Azgaar source change.
