# Prepared GAME-84 update — ready for review

Authenticated Linear tools were unavailable; this is a prepared update, not a claimed posted comment. Do not mark accepted/Done.

Branch: `https://github.com/marksprietsma-beep/road-has-gone-dark/tree/feature/game-84-first-production-expedition-v0`
Base: `feature/game-81-party-creation-v0` at `78b00109687e0719c6408e700da9387fbad330de`.
Tested implementation: `1c9d00d0744259f8f8d37a03fcd3c6122a534904`.
Publication: normal Publish draft PR, targeting GAME-81; no PR merged or existing draft modified.

Ready party → hometown → local lead → accepted one-cell/fringe illustration → scout/travel → meaningful knowledge/consequence choice → return → restart/resume is implemented. Eight world/cell-derived immutable sites are separate from source POIs and campaign knowledge; public projection withholds unknown coordinates/names and secrets. Existing journalled persistence validates every written transition with immediate reload and exact rollback. Missing-only legacy ready-party upgrade; actual three adventurer IDs retained.

Local results: 309 lifecycle + 85 restart + 32 failure + 15 cache + 230 real input/render checks, zero failures; 336 executed outcome sets / 2,822 assertions. Both presets and five fresh worlds; 840 sites/315 leads in 105 source regions. Full GAME-81/80/79/75/76/74/7 regressions passed. All 21 frozen inputs remain byte-identical.

Windows and Linux CI passed: https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37510326837. Both native builds passed 60 checks, empty PATH, single packaged helper; complete downloads and SHA-256: [CI evidence](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/feature/game-84-first-production-expedition-v0/docs/implementation/game84/CI-EVIDENCE.md). [Screenshots](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/feature/game-84-first-production-expedition-v0/docs/implementation/game84/SCREENSHOTS.md), [test results](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/feature/game-84-first-production-expedition-v0/docs/implementation/game84/TEST-RESULTS.md), [Windows procedure](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/feature/game-84-first-production-expedition-v0/docs/implementation/game84/README.md#windows-review-steps).

Review limits: repeated restrained prose, large inherited settlement glyphs, simple provisions/abstract turns, one resolved approach/site. No combat/stats/guild/economy/full-quest/dungeon/free-roam/physical travel systems added; canonical source and accepted generators unchanged. Mark’s actual Windows display and 10–20-minute human pacing review remain outstanding.
