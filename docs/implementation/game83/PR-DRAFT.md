The player flow previously stretched a fixed 640×360 interface into oversized desktop controls, gave metadata and prose equal emphasis, and covered the expedition terrain with decorative houses and numbered blocks. This refactor gives onboarding, party creation and expeditions a shared compact black/parchment/gold interface, responsive layout space, clear actions and small selectable map symbols.

## Architecture and scope

- Shared `GameUI` theme, typography, actions, rows, badges and sections; existing screen controllers retained. Larger windows add logical layout space while limiting control scaling; party text has a bounded reading width.
- Origin profiles and factual information retain their existing content. Party roster entries expose all three names/ancestries/roles; ready parties open on backgrounds with unavailable editing controls hidden.
- Local-map display suppresses oversized nested SVG decorations and empty unsupported captions. Source packets, terrain/roads/water, settlement/site coordinates and canonical geography remain intact. Known sites use diamonds, selection has a gold outline, and hometown/party share a single symbol with explicit location wording.
- Results show existing investigation status and recorded consequences under “What changed.” Keyboard focus remains on a visible action after saved transitions, and result panels start at their heading.
- The Back regression was reproduced without altering its test. The hometown shortlist reserves space for longer lore; layout changes reveal the selected row after Back or live resize. The original test passes 109/109, plus 28 direct row-visibility checks.

GAME-84 service/save/knowledge/lead/consequence semantics, generators, canonical fixtures and runtime pins are unchanged. No combat, facilities, economy, inventory or new content generation. PR #66 and all earlier draft stacks remain untouched.

[Engineering assessment](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/feature/game-83-production-ui-system-refactor/docs/implementation/game83/ASSESSMENT.md) · [Components and Windows review steps](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/feature/game-83-production-ui-system-refactor/docs/implementation/game83/README.md) · [Per-screen self-review](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/feature/game-83-production-ui-system-refactor/docs/implementation/game83/UX-REVIEW.md)

## Actual render evidence

![Onboarding before/after](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/feature/game-83-production-ui-system-refactor/docs/implementation/game83/onboarding-comparison.png?raw=true)

![Expedition before/after](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/feature/game-83-production-ui-system-refactor/docs/implementation/game83/expedition-comparison.png?raw=true)

[All 640×360, 1280×720 and 2560×1440 window captures](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/feature/game-83-production-ui-system-refactor/docs/implementation/game83/SCREENSHOTS.md). These are actual Godot 4.6.3 captures. The 1280×720 responsive window yields a 1280×719 viewport texture due to integer rounding; exact raster sizes and hashes are recorded. Final visual review found no further code issue.

## Executed validation

[Final source CI 37599062997](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37599062997): **Windows and Linux success**, including GAME-7 persistence and GAME-74/75/76/79/80/81/84 regressions. Linux includes actual input/render; both native packaged distributions pass 60 checks with zero failures, empty PATH, no source helper override, two presets and one fresh world.

- GAME-83 presentation: 20/20; origin/party render journey: 114/114; expedition journey: 468/468.
- Original GAME-84 input/render: 230/230. Lifecycle create/replay: 324/85; cache/failure safety: 15/32; zero failures.
- Actual outcome corpus: 336 cases / 2,822 assertions; batch: seven worlds / 105 regions / 840 sites with zero geography violations, knowledge leaks or determinism failures.
- Complete before/after campaign records match with no fields excluded: one exercised capture campaign and 13 untouched campaigns. Source boundary and screenshot-hash checks also pass.

[Exact results and provenance](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/feature/game-83-production-ui-system-refactor/docs/implementation/game83/TEST-RESULTS.md). The additional local full-chain run was interrupted; full-chain success is claimed from completed CI, not that partial local log. Final publication changes documentation only; completed implementation tests were not manually rerun.

## Windows review delivery

**[Download game83-complete-Windows, artifact 11473119406](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37599062997/artifacts/11473119406).** Extract the artifact ZIP and its inner `game83-windows-x64.zip`; keep the matching `worldgen-helper` beside the executable. No Node/Godot installation is required.

Inner Windows archive SHA-256: `6ccb4032f7c18b5ab6fa5f7a291a1acea42de4cf2081000436e749039331e850`.

[Linux artifact, all outer/inner checksums and native proofs](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/feature/game-83-production-ui-system-refactor/docs/implementation/game83/CI-EVIDENCE.md).

Review New Game → origin → party → hometown → lead → expedition → investigate → return → quit/Continue at all three window sizes. Exercise mouse, Tab/Shift+Tab/arrows/Enter/Escape; check late hometown selection after Back, three-member scanning, hidden-site discovery and persisted results. Windows laptop display comfort and the subjective two-second action-recognition goal remain human review. At 640×360 long text scrolls; dense markers retain named-list/keyboard access; existing generated prose repetition remains unchanged.

## Stack and review state

Base branch: `feature/game-84-first-production-expedition-v0`.

Verified base SHA: `3541e0bb2cc72ee147c3589e3a354b3b670d85e5`.

Tested implementation SHA: `bfbdf48b4ae26dd1fc516cd8641177ee63fc4bd5`; later commits are evidence/docs only.

Keep this PR **draft** and unmerged. GAME-83 is ready for In Review; authenticated Linear access is unavailable, so the prepared update is committed in [LINEAR-UPDATE.md](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/feature/game-83-production-ui-system-refactor/docs/implementation/game83/LINEAR-UPDATE.md).
