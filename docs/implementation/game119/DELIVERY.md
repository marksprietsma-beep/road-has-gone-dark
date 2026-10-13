# GAME-119 review delivery

Independent branch: `feature/game-119-deep-character-progression`, stacked on `feature/game-118-playable-core-characters` (draft PR88). PR80, PR81 and PR88 remain unmerged. GitHub mirror: [#89](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/89); full programme [#82](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/82) remains open. Linear is not callable; no Linear update is claimed.

## Implemented batch

- Eleven distinct core archetype adaptations through levels1–12.
- 27 scheduled persistent career-choice groups: school, domain, bloodline, style, quarry, rage/talent/divine/ki/nature/performance options and selected prestige casting tracks.
- Four five-level prestige adaptations: Duelist, Eldritch Knight, Arcane Trickster, Mystic Theurge. Actual entry prerequisites, ordered multiclass replay, finite tactical actions and hybrid spell progression.
- 30 selectable mechanical feats, including actual higher chains and separate coincident general/class grants.
- Existing nine race families/fourteen heritages retained. Latest fresh default v9; installed v1–v8 remain byte-identical. Existing campaigns do not repin.

These are original bounded TRHGD adaptations, not complete sourcebook conversions. Core13–20, broader specialisations, companion/summon authority, more feats/spells and the full403/66/~283 catalogue remain unfinished. Deep-level fixtures are developmental. Normal adventures prove earned level two; sustainable deep-career XP is a separate [follow-up #90](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/90). No arbitrary production XP grant.

## Preserved local verification

Local actual Godot: career/feat progression601 checks; all selectable choice effects285; prestige prerequisites/history101; prestige combat/quarry84; all spontaneous tier unlocks63; complete core tactical effects8674. All pass. Frozen source boundary9 and legacy battlefield/independent command oracle3370 pass. The v9 rendered full journey/entry/build/actual combat fixtures pass831 checks, and a new process passes43 reload checks; original pinned creator344 and v3 creator375 pass. Self-contained native Linux export runs six hometown journeys1252 checks and fresh-process restart87 checks with empty PATH and no source-helper override. Historical Windows/Linux CI is now verified successful below. Human interactive acceptance remains pending.

Screenshots are actual Godot/Mesa renders, not drawn substitutes. See [screenshots](screenshots/) and [raw evidence](evidence/). The 58 screenshot hashes were checked during recovery; all match their committed manifest. Native CI proof and packaging records are retained below.

[Assessment](ASSESSMENT.md), [coverage](COVERAGE.json), [testing](TESTING.md), [precise continuation](CONTINUATION.md).

Publication stopping point: prepare a draft PR against GAME118, then prompt the user to click **Publish draft PR**. Do not merge automatically.

## Recovered source and successful CI

Recovery confirmed clean, pushed HEAD `1af874f0d6a2a0a05e75c37bce084ee1bd082eaf`. Its entire delta from tested gameplay/build source `0971a58a42abd1012d8798023ae50f5d62d39979` consists of `docs/implementation/game119/` documentation, screenshots and evidence. The recovery correction also changes only that documentation directory. Gameplay, rules, tests, art and packaging are unchanged from the tested source.

The following historical results were read from GitHub during recovery. They are not newly executed tests:

| Workflow | Source | Windows | Linux |
| --- | --- | --- | --- |
| [GAME-119 native package and progression](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38282791480) | `0971a58` | Success | Success |
| [GAME-103 original creator compatibility](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38282792357) | `0971a58` | Success | Success |
| [GAME-104 content compatibility](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38282797418) | `0971a58` | Success | Success |

The native exported package passed 1,252 checks and a separate-process restart passed 87 checks **on each platform**, with empty PATH and no source-helper override. Evidence includes six hometown journeys, existing-campaign continuation and eight isolated entry/advanced prestige saves. All eleven classes receive mechanical native-Godot checks; exported ordinary journeys specifically use Fighter/Rogue/Wizard. The Windows proof is headless (`visual: false`); committed visual evidence is genuine Linux Godot/Mesa rendering. Do not describe CI as a human Windows playtest.

[Recovery verification](evidence/recovery-verification.json), [Windows distribution proof](evidence/ci-windows-distribution-proof.json), [Windows native proof](evidence/ci-windows-native-export-proof.json), [Windows restart](evidence/ci-windows-native-restart-proof.json), and corresponding `ci-linux-*` records preserve the original results. Earlier local records remain historical and are not replaced or relabelled as CI.

## Windows download and launch

[Download the complete Windows x64 artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38282791480/artifacts/11763575553) (GitHub sign-in required; artifact retention currently expires 10 January 2027).

Inner playable file: `game119-deep-character-progression-windows-x64.zip`.

SHA-256: `61c82b65ae29ba5548c4e35ae25594a4f055406fb86aa5057f90219c1b8c07cc`.

This checksum is for the inner playable ZIP, not GitHub's outer artifact wrapper. Recovery downloaded that ZIP, checked its checksum against the CI proof and supplied `.sha256`, verified all 7,062 ZIP entries without CRC errors, matched the exact v9 content and installed rules manifest, and verified the executable hash against `distribution.json`. It includes `worldgen-helper/node.exe` and 124 licence/credit entries. No local rebuild was performed.

1. Download and extract the GitHub artifact ZIP.
2. Extract the inner playable ZIP completely into a writable folder. Keep `worldgen-helper`, artwork and notices beside the executable.
3. Run `road-has-gone-dark.exe`. No Godot or Node installation is needed. Escape skips the intro.
4. Follow [TESTING.md](TESTING.md) for New Game, specialisation, combat, earned level two and Resume. Existing campaigns retain their exact content/rules/XP pins; do not delete or recreate them.

## Publication and remaining work

No GAME-119 pull request exists at this recovery checkpoint. The branch and [prepared PR description](PR-DESCRIPTION.md) are ready for Mark to click **Publish draft PR**, targeting `feature/game-118-playable-core-characters`, not `main`. No parent draft is merged. Record the actual PR URL and move GAME-119 to In Review only after publication is confirmed. Human acceptance is pending; this batch and the wider programme are not marked fully complete.

GAME-121 ([GitHub #90](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/90)) is the immediate earned-XP dependency. Investigate it separately rather than expanding this review branch. Core13–20, sourcebook-level breadth, companions/summons/transformations and the remainder of the 403/66/~283 catalogue remain continuation work.
