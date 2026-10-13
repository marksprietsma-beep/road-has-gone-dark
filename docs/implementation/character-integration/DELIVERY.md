# Character programme integration

GAME-119, GAME-121 and the first GAME-112 catalogue wave are consolidated into main. The owner explicitly authorised direct publication and verified normal merges, superseding earlier draft-only instructions. No new gameplay/content/world features were developed during this task.

## Verified merge history

| PR | Normal merge commit | Successful current PR checks before merge |
|---|---|---:|
| [#91](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/91) | `47d50a941fbca9b92697de01e380c6a9662d8192` | 16 passed |
| [#92](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/92) | `6f3f68a75a8a8c935ff505de353236e28ee2158e` | 16 passed |
| [#93](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/93) | `94f2c3391844e4dd5fd62310c304733728ce87b0` | 16 passed |
| [#94](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/94) | `a3b47ede4703b1fdea3eb3052ecf3e7060321e19` | 5 passed |

PRs #91, #92 and #93 each also had one intentionally skipped conditional review-package job. PR #94 additionally passed its complete native Windows workflow and isolated native Linux review. All four commits retain the previous main and original feature head as their two parents; their trees match the respective feature heads exactly. Original branches remain present; no force-push, squash, protection bypass or branch deletion was used. Already merged #80, #81 and #88 were audited, not recreated.

Consolidated gameplay/build source: `94f2c3391844e4dd5fd62310c304733728ce87b0`, identical complete tree to GAME-112 head `b885e6fe9e2127cf7052f13ae8411454707b8353`. Post-repair verified main: `a3b47ede4703b1fdea3eb3052ecf3e7060321e19`. Between those sources only `tests/adventure/review-flow.gd`, `tests/sandbox/review-flow.gd` and integration documentation/evidence changed. Production scripts/scenes/data/assets/themes/helpers/export configuration remain byte-identical, verified directly. Later bookkeeping publication changes documentation/evidence only; its final main SHA is recorded on GitHub and in the final handoff to avoid a self-referencing commit hash.

## Current verification

- [Full catalogue, combat, immutable content/source pins, sustainable earned prestige and native Windows/Linux](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38407730002): both passed at gameplay/build source `94f2c3391844e4dd5fd62310c304733728ce87b0`.
- [Production Windows, LPC/battlefields, frozen oracle and original-to-repaired geography/save recovery](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38422947010): passed at post-repair main `a3b47ede4703b1fdea3eb3052ecf3e7060321e19`.
- [UI/input/render and native Windows/Linux](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38422946956): both passed at that post-repair main.
- [Party/expedition, five fresh worlds, persistence and native Windows/Linux](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38422947103): both passed at that post-repair main.

| Native catalogue game | Mechanics checks | Tactical checks | Fresh journey checks | Failures |
|---|---:|---:|---:|---:|
| Windows | 1684 | 2066 | 208 | 0 |
| Linux | 1684 | 2066 | 133 | 0 |

Separate-process restart and production launch passed with empty PATH and no source-helper override. High-level fixtures remain separate from actual earned XP; genuine Arcane Trickster entry at 250 XP and advancement at 360 XP remain verified by the full workflow. Existing rules/content/career/builder/opportunity regressions and immutable v1–v11 definitions remain tested. Raw workflow receipts, native proofs, timings, archive audit and integration history are in evidence/.

## Windows delivery

[Download the complete integrated Windows x64 build](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38407730002/artifacts/11826370594). Extract the outer GitHub artifact ZIP, then `game112-character-catalogue-wave-one-windows-x64.zip`, and launch `road-has-gone-dark.exe`. Keep worldgen-helper, artwork and notices together; no Godot or Node installation is required. GitHub sign-in may be needed; artifacts have 90-day retention.

Playable ZIP SHA-256:

`586bceb94563ae104a0ad8744a3908317cc4dedcf523996facb8476acd6dc33b`

[Linux package](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38407730002/artifacts/11824757408), SHA-256 `3e46f6cc90371d988ff84da55ee47060097a11a8c5a532334e86865a46f62fd0`.

The archive source is `94f2c3391844e4dd5fd62310c304733728ce87b0`. The later diagnostic test repair and documentation are not production changes; all delivered gameplay, UI, content, artwork and helper source matches final main. Independently checked ZIP CRC, game/helper x64 binaries and hashes, exact v11/manifests, cycle/opportunity policies, embedded helper runtime/content contracts and notices. QA executables are excluded from the playable package.

Escape skips the intro. New Game → world → origin → hometown → creator; v11 is the automatic default. Compare actual races/classes, review Build/Sheet, save all three, choose Party ready. Seek new leads, travel and complete an objective using real class powers; return home, commit an earned level, exit/relaunch/Resume. Existing campaigns retain exact original pins. See [detailed tests](../game112/TESTING.md) and [69 genuine historical Godot screenshots](../game112/SCREENSHOTS.md). Gameplay/UI/assets are unchanged, so those images remain applicable; they are not claimed as new renders of the bookkeeping merge. Human desktop/GPU, pacing and balance acceptance remain pending.

## Narrow CI repair and bookkeeping corrections

Two superseded older main Windows builds failed because their battlefield fixture passed an empty source-world entry to the redesigned creator. Incoming #93 already reconstructs the exact canonical public world. The focused test passed 3,370 checks / 0 failures; the integrated Windows workflow also verified it. No new production correction was required.

The first consolidated Windows run [38407548386](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38407548386) then exposed a separate obsolete battle driver: it selected retired Adept Spark/basic attacks rather than current Wizard/Ranger/Fighter powers, leaving a valid battle active at its original four-minute deadline. [PR #94](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/94) selects enabled offensive production controls and adds an assertion for actual Wizard spell use. The deadline, legal commands, victory/defeat/rewards, legacy saves/hash checks and frozen oracle remain intact; no assertion was weakened. Linux source passed 227 checks, the initial isolated native Linux journey 229 checks. The current shared-helper follow-up passed the sandbox source journey 266 checks, both empty-PATH Linux exported journeys (229 First Adventure / 284 sandbox checks, zero failures), the same two native Windows journeys (229 / 284, zero failures), and the [complete native Windows repair workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38417377835). The inherited sandbox policy passed the earlier sampled basic-only fights; its obsolete Spark assumption is corrected, not reported as a separately observed failure. [Detailed reproduction and raw before/after evidence](CI-REPAIR.md) retain the failures; they are not counted as passes.

Only duplicate runs on superseded main commits were cancelled, with original states/results retained in the ledger. Current feature and final-main verification was kept intact. Authentication expiry was recovered through the owner-authorised standard GitHub CLI device login; no credential value was printed or committed. A nonblocking environment start-skill draft records how to reuse the existing authorised profile. Older CLI retargeting hit removed Projects Classic; equivalent REST updates succeeded.

The Linear/GitHub synchronisation bot briefly closed #82 immediately after #93 merged; it was explicitly reopened. Keep #82 open. Initial GAME-119/GAME-121 implementation milestones are integrated/resolved, while human acceptance and the full programme remain separate.

## Actual scope and next wave

Main contains 19 bounded base adaptations (eleven core through 20, eight new through 12), 8 prestige paths (four through 5, four through 10), 17 ancestry families/26 inherited records, 40 feats, 14 skills and 47 scheduled choice groups. Sustainable adventure/earned-XP cycles are integrated. These are original bounded adaptations, not complete tabletop conversions.

The 403 ancestry/subrace, 66 adventurer base-class and 283 prestige research destination remains unfinished; repeated source variants stay independent and original heritage variants do not count as missing indexed race conversions. Outstanding: companions/summons, substantial forms/transformations, broader psychic/discipline/pact/binding/incarnum systems, deeper new-class tracks, catalogue entries and dedicated unusual-anatomy artwork. Inherited vision has no darkness mechanics; intermediate v10 retains its documented high-Intelligence rank-capacity limitation. Existing enemy cap 12/basic bandits and 25/121/361 successful-objective cadence to levels 6/12/20 remain human-pacing limitations.

Start the next character-only wave on a new branch from consolidated main, append a new immutable pack, preserve v1–v11/saved pins and deliberately register capability/career compatibility gates. Next dependencies are genuine companions/summons and body forms, then deeper new-class progression and coherent martial/psychic/pact, ancestry and prestige cohorts. GAME-105/GAME-122/world expansion remain deferred. No next-wave implementation starts in this integration task.
