# GAME-112 character catalogue wave one

This substantial implementation batch is verified and pushed for human review. The full character programme remains unfinished. Branch `feature/game-112-character-catalogue-wave-one` is stacked on unchanged `feature/game-121-sustainable-adventures` at `f3c12b9a2b93a6b3bcd3cbf562faec6328b4d770`. No parent draft was merged.

## Windows review build

[Download the complete Windows x64 artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38378307066/artifacts/11807636527). GitHub sign-in may be required. The artifact contains `game112-character-catalogue-wave-one-windows-x64.zip` and its checksum file; retained for 90 days by GitHub Actions.

Playable ZIP SHA-256:

`4f40725c3f866dbdb73c08e7f7b13ed56ed34db72dd79df8e3d6cd3247a79e1e`

1. Download and extract the outer GitHub artifact ZIP.
2. Extract the inner `game112-character-catalogue-wave-one-windows-x64.zip` ZIP.
3. Open the extracted folder and run `road-has-gone-dark.exe`. Keep the executable, `worldgen-helper`, artwork and notices together. Godot and Node installation are unnecessary.
4. Escape skips the intro. Choose New Game, a world, origin and hometown. The first-open creator uses v11 automatically, with 19 base classes and 17 ancestry families; no hidden content button.
5. Compare Tiefling Psion, Aasimar Warlock and Steelbound Warblade. In Build, use Suggested skill allocation / Suggested class equipment and spells, review legal feats and persistent class choices, then inspect Sheet. Save adventurer for each of the three roster members; choose Party ready.
6. Seek new leads, select a contested report and complete its travel/objective. Use Mind Thrust, Eldritch Blast or the Warblade manoeuvre; inspect their different point/readiness/action costs. Complete the objective and return home.
7. Open Characters → Advance, commit an earned level and review spells/options. Quit, relaunch and Resume. Identities, pins, choices, XP and completed rewards must persist. Existing campaigns retain their original options and exact rules pins.

See [TESTING.md](TESTING.md) for prerequisites, legacy review and source-scene instructions, and [SCREENSHOTS.md](SCREENSHOTS.md) for actual Godot evidence. No player's private save was reset or changed.

## Playable scope

| Content | Available now | Bounds |
|---|---:|---|
| Base class adaptations | 19 | Eleven core tracks 1–20; eight new tracks 1–12 |
| Prestige paths | 8 | Four previous paths 1–5; four new paths 1–10 |
| Ancestry families | 17 | 26 inherited/heritage records in total |
| Mechanical feats | 40 | Prerequisites and class/skill restrictions apply |
| Skills | 14 | Includes functioning Nature and Performance ranks |
| Scheduled career-choice groups | 47 | Persistent selections with actual effects |

Added classes: Psion, Psychic Warrior, Soulknife, Warlock, Scout, Swashbuckler, Knight and Warblade. Shared psychic points/augmentation, mind-blade delivery, repeatable invocations, movement-based skirmishing, finesse/panache, challenge/guarding and readiness/recovery operate through the existing GAME-32 authority.

Added prestige paths: Shadowdancer, Dragon Disciple, Dwarven Defender and Pyrokineticist. Entry requirements are permanent character prerequisites; ordered histories, hybrid casting, concealment, breath/scales, stationary defence and psychic fire are executable. Core tracks gain actual higher-level actions/choices, resource scaling and bounded tier-seven-to-nine spells.

Added ancestry families: Aasimar, Tiefling, Kobold, Lizardfolk, Gnoll, Hobgoblin, Goliath and Steelbound (original adaptation of the indexed constructed-person concept). Numerical traits, damage resistance/immunity, size/reach, natural attacks and body equipment restrictions have consequences. Four additional original heritage variants do not count as conversions of missing research entries. Culture stays separate from ancestry.

The research scope is still **403 ancestry/subrace, 66 adventurer base-class and 283 prestige occurrences**, plus eight separately indexed NPC families. The matrix retains all 720 unique rows and 760 source occurrences. It marks 44 bounded adaptations playable, retaining unresolved variants independently. This does not mean full sourcebook conversions or programme completion. See [COVERAGE.json](COVERAGE.json) and the [canonical matrix](../game104/COVERAGE.json).

## Verification and provenance

[Full Windows/Linux source and native CI](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38378307066): both jobs succeeded at `7777f1d435819dd18098efd5a71fb1e6928b751f`.

[Repaired production UI/input CI](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38376631906): Windows and Linux succeeded at `b5977181d1d8b954e8b95572cf4f9edcb2e9c5c9`. Its actual UI/input driver, gameplay, content and assets are identical to the final source; subsequent changes were validation/native-test fixes and documentation.

| Exported game | Mechanics checks / failures | Tactical checks / failures | Actual fresh journey checks / failures | Separate-process restart |
|---|---:|---:|---:|---|
| Linux | 1684 / 0 | 2066 / 0 | 181 / 0 | Passed |
| Windows | 1684 / 0 | 2066 / 0 | 223 / 0 | Passed |

Both native catalogue packages launched with an empty PATH and without a source helper override. Actual saved powers, new-party creation, earned objective XP, exact reload and labelled high-level fixture saves passed. Independently exported sustainable-XP native tests earned Arcane Trickster entry at 250 XP and advancement at 360 XP on both platforms. Source/native compatibility retained the frozen GAME-32 oracle, ten generated worlds/forty contexts, legacy V1/V2 journeys, original builder, v9 careers, pinned saves, negative eligibility and atomic rewards.

The original V1 combat oracle is byte-identical to GAME-121. Reviewed capability extensions project back to exact parent source before the existing historical projection; current/reconstructed hashes and occurrence checks remain asserted. Historical installed v1–v10 definitions/pins remain unchanged.

Actual gameplay/UI implementation is `215bbe8c416b0f2569f434d448ed98a9f0034a72`. `b597718` and `7777f1d435819dd18098efd5a71fb1e6928b751f` changed input/native review tests, UTF-8 validator reads and CI failure propagation, not gameplay/content/UI. Later delivery commits contain documentation/evidence only. The final source and archive audits are in `evidence/`; the downloaded ZIP CRC, executable/helper identity, exact v11 data, manifest, policies and notices were checked separately.

[Linux package](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38378307066/artifacts/11804632790), SHA-256 `7cef6638ec52ff876f32daa0316ec8fcc6350306a32527651bd73b681084c5b8`. [Windows raw evidence](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38378307066/artifacts/11807546631) and [Linux raw evidence](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38378307066/artifacts/11804473061) preserve logs, timings and proofs. Successful CI is reported as verified historical execution at its exact source, not as a fresh rerun on documentation commits.

69 genuine Godot screenshots cover three resolutions. The initial rendered new-party path passed 240 checks; a separate saved-command continuation used Psion/Warlock/Warblade powers, advanced all three characters with existing earned XP, completed another cycle, reached 80 earned XP and reloaded (172 checks, zero errors). Wizard20, Psion12 and Shadowdancer10 images are explicitly **development fixtures**, not ordinary earned progression. Raw diagnostic failures and Mesa VSync/ObjectDB shutdown warnings remain disclosed.

## Corrections and remaining limits

The expanded ancestry list invalidated an old test's assumption that Down from Human selects Orc. The repaired fresh input test selects the intended Orc through the actual popup/keyboard by stable identity; illegal-budget and disabled-Save assertions remain. The exact legacy arrow-input path remains unchanged. Native parent assertions compare the complete live registry/UI lists and still explicitly require the original core options. Windows validation reads UTF-8, and checked subprocesses prevent a failed validator being hidden by a subsequent successful command. Earlier failed workflow runs are superseded, not counted as passes.

An actual high-Intelligence Rogue rank-capacity defect required immutable v11; pushed v10 was retained untouched. Nature/Performance and rank-dependent effects resolve that capacity gap. An already-pinned intermediate v10 high-Intelligence Rogue retains its old rank-capacity limitation; no silent repinning or migration is performed. Attribute suggestions skip scores already at the existing cap. Character sheets display casting progress only for actual casting tracks.

These are original TRHGD adaptations with bounded repertoires. Companions, summons, substantial body forms, full discipline/pact/binding/incarnum systems and many source-specific features are still missing. Warblade has two readiness charges and main-action recovery, not a complete discipline library. Shadowdancer provides weapon concealment, not teleportation. Dragon Disciple has breath/scales and half-rate selected arcane advancement, not flight. Knight challenge does not implement an AI taunt. New unusual body plans use an explicitly disclosed neutral humanoid art fallback. Recorded inherited vision has no darkness rules. High-level balance and the 25/121/361-success cadence to levels 6/12/20 require human assessment; existing world/XP policies were preserved.

## Publication and continuation

**Mark must click Publish draft PR**, targeting `feature/game-121-sustainable-adventures`, using [PR-DESCRIPTION.md](PR-DESCRIPTION.md). No GAME-112 PR exists yet; do not claim publication or merge. Keep parent PRs #80, #81 and #88 draft and unmerged. GitHub mirrors #82–#87 stay open; no Linear update is claimed because its connector is unavailable.

Next character-only implementation: companions/summons and real body-form mechanics through the existing authority, then strengthen the eight new tracks beyond level 12 and add coherent martial/psychic/pact, ancestry and prestige cohorts in a new immutable pack. [CONTINUATION.md](CONTINUATION.md) preserves exact gaps and order. GAME-105, GAME-122 and world expansion remain deferred. The full programme remains open.
