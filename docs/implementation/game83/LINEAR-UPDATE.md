# Prepared GAME-83 review update

Requested state: **In Review**. This transition has **not been applied**: no authenticated Linear connector is available in this environment. This text is ready to post to GAME-83; do not mark GAME-84 Done.

GAME-83 is ready for independent review. The existing production UI refactor is complete, including the unchanged Back/ItemList regression, focus restoration, responsive layouts and clearer local-map markers. The original Back test passes 109/109; added visibility/resize checks pass 28/28. Actual Godot comparison journeys pass 114 origin/party and 468 expedition checks. The complete saved-record comparison is identical, and gameplay/save/generation services remain unchanged.

Windows and Linux CI run [37599062997](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37599062997) is fully green, including the full foundation regressions and native packages. Both native packages passed 60/60 checks. Tested implementation: `bfbdf48b4ae26dd1fc516cd8641177ee63fc4bd5`; subsequent commits are review documentation only.

- [Published draft PR for this branch](https://github.com/marksprietsma-beep/road-has-gone-dark/pulls?q=is%3Apr+head%3Afeature%2Fgame-83-production-ui-system-refactor)
- [Branch](https://github.com/marksprietsma-beep/road-has-gone-dark/tree/feature/game-83-production-ui-system-refactor), stacked on `feature/game-84-first-production-expedition-v0`
- [Before/after screenshots at all three window sizes](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/feature/game-83-production-ui-system-refactor/docs/implementation/game83/SCREENSHOTS.md)
- [Complete Windows review package](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37599062997/artifacts/11473119406)
- [Test results, checksums and exact native proofs](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/feature/game-83-production-ui-system-refactor/docs/implementation/game83/CI-EVIDENCE.md)

Review: extract both ZIP layers, keep the matching helper beside the executable, and test New Game → origin → party → hometown → lead → expedition → investigate → return → quit/Continue at 640×360, 1280×720 and 2560×1440. Long text still scrolls at 640×360. Subjective reading comfort/action recognition on Mark's Windows laptop remains for review. The draft stays unmerged; no new gameplay or GAME-85 work was added.
