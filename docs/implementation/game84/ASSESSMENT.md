# GAME-84 engineering assessment

Base: GAME-81 PR #65, `78b00109687e0719c6408e700da9387fbad330de`, verified open/draft and unchanged. A separate branch preserves it.

The current party handoff deliberately stops. GAME-7 saves already contain source identities, POI knowledge, world deltas and a clock. GAME-81 supplies strict roster validation and journalled write/immediate-reload recovery. Reuse those transactions rather than introducing a second store. Optional expedition-v1 data is a missing-only upgrade; existing saves remain valid. Generated site knowledge has its own namespace and cannot weaken source POI checks.

GAME-62 `generateCellRegion` already owns exact source-cell/fringe geography. Its Town Forge adapter transpiles pinned MIT code at build/runtime; packaging must include that existing provider and its TypeScript dependency or precompiled equivalent. A production map will consume that output, omit all provider sites/landmarks from its public rendering, and draw only explicitly known gameplay sites. No algorithm edits or arbitrary substitute region.

GAME-78 structured site/contract generation currently requires source markers. Extend with an isolated generated-local adapter: retain explicit generated provenance, stable world/cell/version/slot IDs, source-conditioned compatibility, existing purposes/events/conditions and public rendering. Objective records precede knowledge. Do not masquerade generated sites as Azgaar markers. Source facts, fiction, and campaign effects remain distinct.

Historical GAME-55 is inspected only for lessons: its session model is not imported. Durable gameplay must never depend on scene/session variables. Every action validates its phase, immutable references and exact party IDs, commits before presentation, and rejects repeated operations. Return remains possible without a role or provisions requirement.

Plan: pinned local-content helper entrypoint in the existing bundled runtime; 6–12 deterministic owned dry-land sites with conservative context; 2–3 initial known/rumoured leads; additive strict campaign schema; home/map/site/result UI; latest-valid-save Continue; structured clock/log/consequences. Public projections whitelist names, history and coordinates by knowledge, never copy objective secrets into UI.

Verification: deterministic geographic/site corpus (500 sites, 300 leads/outcome sets); unfiltered human samples; two presets plus five fresh worlds; real party creation and complete loops; independent campaigns; role/background alternatives; malformed references; forced write/reload/retry rollback; separate-process restart at all phases; real mouse/keyboard and screenshots at 640×360/1280×720/high DPI; existing GAME-7/74/75/76/79/80/81 and region regressions; packaged offline Windows/Linux execution, one helper, native artifacts. Report executed evidence honestly.

No combat, rules stats, economy, guilds, dungeon interiors, free roam, geography calibration, onboarding redesign, canonical mutation, research merge or existing branch alteration. Prepare normal Publish draft PR workflow; do not merge or claim acceptance.
