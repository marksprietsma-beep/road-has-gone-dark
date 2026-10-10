# Prepared GAME-80 update

Implementation is published in draft PR #64: https://github.com/marksprietsma-beep/road-has-gone-dark/pull/64

Branch: `feature/game-80-meaningful-origin-profiles`, stacked on GAME-79 `93951ba46a91219c5e33595dc4693b8c5d08c714`. Earlier branches/PRs remain untouched.

Persistent public state → region → hometown profiles now provide compatible political/social character, source-constrained livelihoods and concrete regional contributions. Source geography/cultural presence remains separate from generated background; unknown remains unknown. V1 sidecars and campaign references remain unchanged; new campaigns additionally pin `profiles-v2`. A missing-only upgrade never overwrites corrupt or campaign-pinned enrichment.

The themed state list, explicit region step, keyboard/mouse navigation and live list/profile/map alignment are implemented. Original memories/traditions are secondary. Complete native game/helper packaging and compatibility preflight remove manual helper matching.

Linux evidence: ten Node profile tests; 2,581 Godot preset/legacy assertions; 2,211 lifecycle-create and 40 restart assertions; nine forced post-write failure/retry assertions; 2,926 actual input/render assertions covering 16 states and 22 towns at three resolutions; 11 native export lifecycle assertions plus production release launch. Both presets and five genuinely generated offline worlds replay exactly. Sequential engineering review covers 50 states, 100 regions and 200 hometowns. Existing regressions passed as recorded in VALIDATION.md. Current-head Windows/Linux CI and artifact links are recorded in the PR at handoff.

Evidence: https://github.com/marksprietsma-beep/road-has-gone-dark/blob/feature/game-80-meaningful-origin-profiles/docs/implementation/game80/README.md

Review remaining: Windows laptop visual acceptance and narrative review. Repeated mundane practices/templates are disclosed; profiles do not implement trade, diplomacy, character creation, danger/protection or gameplay. Continue stays disabled. Nothing merged or marked accepted. Linear connector access is unavailable; this is a prepared update, not a claim that Linear was changed.

Final source audit refinement: maritime identities now require a co-located source coastal port, avoiding the invalid combination of unrelated coast and inland port. All 112 current maritime profiles pass the independent source check; downstream identity tags are scoped so parent geography cannot grant local prerequisites.

Recorded village/town/fort classes are preserved rather than calling all hometowns villages. All 3,031 source associations and 58 changed sequential-review records were checked/read.
