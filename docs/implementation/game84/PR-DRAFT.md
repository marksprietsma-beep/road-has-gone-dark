# GAME-84 — first persisted hometown expedition

**Publish as draft. Base: `feature/game-81-party-creation-v0`, not main.**

Party Ready now enters a hometown with deterministic local leads. The existing three adventurers can scout a rumour, travel on the accepted GAME-62 regional illustration, choose an approach, record a persistent consequence and return. Continue/Resume Expedition restores the campaign after a full restart.

Verified base: `78b00109687e0719c6408e700da9387fbad330de` (GAME-81 / unchanged draft PR #65). Tested implementation: `1c9d00d0744259f8f8d37a03fcd3c6122a534904`. The final evidence-only commits do not alter executable code. Branch: `feature/game-84-first-production-expedition-v0`.

## Implementation

Eight immutable world/cell/version-derived sites use GAME-78 structured history, compatibility rules, contracts and Rant prose. They remain distinct from canonical source markers. Public knowledge controls names/coordinates/history; unknown sites and objective secrets never enter map/UI/log projections. Two known leads and one rumour introduce the loop. Survey can reveal a further account; examination and contextual party approaches record an investigation; withdrawal preserves the unresolved state.

The optional GAME-7 campaign record stores knowledge, lead status, active phase, actual party IDs, provisions, abstract expedition turns, consequences and logs. GAME-81's per-slot journal/lock, exact-byte rollback and immediate reload guard every transition. Stale/repeated actions cannot apply costs twice. Only missing ready-party records with the previously unassigned clock receive the narrow legacy upgrade. Immutable sidecar validation is memoized with continued dependency-byte checks; corruption remains a hard failure.

The production scene, record/service/map modules and offline helper adapter are new. Small changes connect Party Ready and the existing menu, extend persistence validation and bundle the accepted regional assets through one additive runtime manifest. No accepted generator algorithm, canonical fixture, historical runtime manifest or production main scene was changed.

## Verification and evidence

[Executed results](TEST-RESULTS.md), [CI/native archive proof](CI-EVIDENCE.md), [screenshots](SCREENSHOTS.md), [quality review](QUALITY-REVIEW.md), [raw outcome corpus](actual-outcome-corpus.json) and [full logs](logs/) are committed. Local checks include lifecycle 309, restart 85, forced-failure 32, cache integrity 15, real input/render 230 and 2,822 assertions over 336 executed outcome sets, all with zero failures. Seven worlds include both presets and five fresh generations. The source batch contains 840 sites/315 leads across 105 real regions, without detected geography, knowledge or determinism violations. The complete GAME-81→80/79/75/76/74/7 regression chain passed.

Native Windows/Linux results and complete matching-helper downloads are linked in CI-EVIDENCE.md. Each native diagnostic runs both packed worlds and a fresh generated world with PATH empty and no source helper override, then launches the production executable. Human Windows laptop acceptance remains for review.

## Windows review

Download/extract the complete Windows artifact and its inner archive; keep `worldgen-helper` beside the executable. Follow the [six-step Windows procedure](README.md#windows-review-steps): New Game → actual three-person party → Enter hometown → accept rumour → depart/scout/travel → investigate → menu/full restart → Resume Expedition → return. Check persistent costs/status, second expedition, independent second campaign, keyboard/mouse controls and larger-window layout.

## Limits and scope

Cold original-geometry preparation measured 10.6–18.7 seconds; cached resume 0.19–0.58 seconds. Prose/lead repetition and the accepted renderer's oversized settlement symbols are documented. V0 has one resolved approach per site, simple provisions and abstract turns, with no kilometres, route simulation, combat, character stats, economy, guilds, quest framework or dungeon interiors. No PR was merged or accepted and no downstream task was started. Use normal Publish draft PR and retain draft status.
