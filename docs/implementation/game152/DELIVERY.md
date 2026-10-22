# GAME-152 — psychic resource parity

The corrected Windows package passed the exact-source-guarded native recheck [39703183260](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39703183260). PR [#144](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/144) contains the implementation and final evidence. Its GitHub merge record and final milestone comment record publication/postmerge outcomes; they must be verified before claiming the merge.

## Playable changes

- Psion Assault adds 2 to positive psychic ability damage. Wilder's existing Weakened condition subtracts 2 from subsequent psychic ability damage. Both adjustments precede successful-save reductions and resistances; neither boosts healing, barriers or zero-damage control. Surge retains its four-point/main-action cost and three global-round-start penalty.
- Known powers derive their casting attribute and minimum from their persistent learned-class origin. An unrelated multiclass attribute no longer improves their saves. Augmentations retain the existing manifesting-level cap, power-point pool and action authority.
- Cerebremancer requires actual permanent arcane spell access alongside its existing levels, skills and feat prerequisites. Entry remains an explicit, optional, XP-funded advancement. Arcane slots and psychic points remain separate resources.
- The existing creator's empty power search now shows legal alternatives. Creator, sheet and combat controls explain power origins and costs. Self-manifestation buttons consult the existing tactical eligibility gate.

Fresh campaigns use immutable `trhgd-character-v24`, content hash `fa919e9413c7eaa669ee00304a44bb61ee89b71a2835c38f2c23c2cde6e5f4de`. Packs v1–v23 and their pins remain byte-for-byte unchanged; old saves do not migrate. There are no roster additions: 32 base classes, 18 prestige paths, 37 ancestry families, 50 heritages, 83 feats, 14 skills, 45 selectable psychic powers and 14 creature definitions. The internal companion class is excluded from the 50-career total; ability records are not unique spell counts.

## Evidence and source provenance

The [complete Windows run 39578198867](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39578198867) succeeded at `59f1b20b8bbb2a4a7029ee71b10190e774b9ed74`. It tested exported current and historical mechanics, exact separate-process restart, actual earned campaigns, connected combat, controls, rendering, the frozen 22,181-assertion GAME-32 oracle and production startup without installed Godot/Node dependencies.

The successful presentation recheck verified this receipt and unchanged authority/data/service/other-UI source. Removing exactly the two specified self/targeted display guards reproduces the original entire UI file. It freshly exported the corrected game, executed564 mechanics/73 cold/114 actual control checks with zero failures, captured19 actual Godot renders and launched the production executable with an empty PATH and no source-helper override. Per-phase `proof_sources` distinguishes reused full-release observations from fresh checks. A missing fixture cache checksum was restored only after its bytes matched the already-saved packet fingerprint; no campaign or geometry was recreated. Original metadata was retained and the new game exported to a separate fresh directory, preserving the no-overwrite safeguard.

Three normal campaigns earned 490 XP per character and reached level 8, including Psion 3 / Wizard 3 / Cerebremancer 2. Separate development fixtures prove Psion/Wilder through level 20 and all five implemented Cerebremancer levels. These fixtures did not earn level 20 through ordinary adventures. Connected combat, rewards, rest and exact reload are separately verified.

## Windows review and limitations

[Download the self-contained Windows x64 package](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39703183260/artifacts/12393627401). GitHub sign-in/repository access may be required; artifact retention is90days.

Playable inner ZIP: `game152-psychic-parity-windows-x64.zip`.

SHA-256: `3546b4e0ca2d9ce45c6b8c7e9c1ecebe18293109f2d08738f3391affd8c526d5`.

Exact artifact source: `46eaaa6608810c124aaa89e2547d326fc8995896`; gameplay/controls match verified `8cd5a8ace4e4ac42b8c153e123dd8dcda618a8f3`, followed only by the fresh-export producer correction. Subsequent delivery changes are documentation/evidence and the host-only readiness gate, with no exported runtime change. The archive audit confirms7022 entries, ZIP CRC integrity, AMD64 game and bundled Node, exact source/content manifest,121 licence/credit files and no QA executable. It independently checks metadata and executable hashes; native execution evidence comes from Windows, not this host.

Evidence-backed50-career readiness is now **23 COMPLETE /27 PARTIAL /0 BLOCKED**, up from20/30/0. Psion, Wilder and Cerebremancer are newly accepted bounded original adaptations. The [matrix](../game129/READINESS.md) retains explicit limitations and historical evidence labels. The unchanged aura paths use documented compositional historical reuse; there is no claim of a new targeted v24 War Chanter encounter.

[Native receipt](evidence/native-proof.json), [full-release receipt](evidence/full-release-proof.json), [archive audit](evidence/archive-audit.json), [source-equivalence audit](evidence/source-equivalence.json), [timings](evidence/presentation-timings.json) and [all19 original screenshots](screenshots/README.md) are committed. The complete native timings are retained separately; counts from overlapping suites/reruns are not added together as unique tests.

| Windows evidence | Checks / cold | Source |
|---|---:|---|
| Focused source controls / mechanics / cold |114 /564 /73; zero failures |8cd5a8a, runs39701555387 and39701550078 |
| Fresh exported mechanics and exact restart |564 /73 |46eaaa6, run39703183260 |
| Fresh exported actual controls / captures |114 /30;19 PNGs |46eaaa6, run39703183260 |
| Real earned journeys |633 /8; three490XP characters |59f1b20, full39578198867, unchanged-source reuse |
| Connected battle / exact restart |34 /124 |59f1b20, full39578198867, unchanged-source reuse |
| All-base native audit |2598 /65 |59f1b20, full39578198867, unchanged-source reuse |
| Historical v23 / v13 |1634+97 /1792+6 |59f1b20, full39578198867, unchanged-source reuse |
| v16 repair / compatibility |818+4 /1941+486 |59f1b20, full39578198867, unchanged-source reuse |
| Frozen GAME-32 oracle |22,181; zero failures |59f1b20, full39578198867, unchanged-source reuse |

Current upper-casting, performance, supernatural, signature and mobile cohorts also passed in the complete native run; their exact proofs, controls and source provenance remain in the native receipt. All Windows checks must be green before merging; postmerge results are recorded on PR144/#101.

Extract both archive layers, retaining all support, helper, asset and licence files beside `road-has-gone-dark.exe`. Launch that executable; no Godot or Node installation is required. Follow [TESTING.md](TESTING.md) for the ordinary creator, power choices, tactical augmentation/surge, earned advancement, optional prestige and full exit/reload checks. Existing campaigns retain their exact rules version.

These are bounded original adaptations, not a full tabletop conversion. Psychic multiclassing retains the existing shared manifesting pool; Cerebremancer-authored new powers retain its existing INT profile, while previously learned Wilder powers retain CHA. The UI tests exercise real controls through signals, not human/OS-driven acceptance. Windows empty-PATH startup is not a claim of a separately provisioned clean operating system. Inherited hover tooltips can obscure long labels and compact layouts require scrolling; human visual/balance acceptance remains outstanding.

GAME-123 remains open. [NEXT-WAVE.md](NEXT-WAVE.md) defines finite acceptance cohorts for the existing roster; Ardent, Lurk and Erudite are the recommended next audit. No new cohort or living-world development is included here. Linear is not callable in this session; GitHub issue #101 is the available milestone record, and no Linear write is claimed.
