# GAME-152 — psychic resource parity

Delivery is pending the fresh Windows self-manifestation control and exact-source presentation recheck. PR [#144](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/144) remains unmerged until these checks pass. The earlier complete native release is evidence for unchanged mechanics, not the final corrected download.

## Playable changes

- Psion Assault adds 2 to positive psychic ability damage. Wilder's existing Weakened condition subtracts 2 from subsequent psychic ability damage. Both adjustments precede successful-save reductions and resistances; neither boosts healing, barriers or zero-damage control. Surge retains its four-point/main-action cost and three global-round-start penalty.
- Known powers derive their casting attribute and minimum from their persistent learned-class origin. An unrelated multiclass attribute no longer improves their saves. Augmentations retain the existing manifesting-level cap, power-point pool and action authority.
- Cerebremancer requires actual permanent arcane spell access alongside its existing levels, skills and feat prerequisites. Entry remains an explicit, optional, XP-funded advancement. Arcane slots and psychic points remain separate resources.
- The existing creator's empty power search now shows legal alternatives. Creator, sheet and combat controls explain power origins and costs. Self-manifestation buttons consult the existing tactical eligibility gate.

Fresh campaigns use immutable `trhgd-character-v24`, content hash `fa919e9413c7eaa669ee00304a44bb61ee89b71a2835c38f2c23c2cde6e5f4de`. Packs v1–v23 and their pins remain byte-for-byte unchanged; old saves do not migrate. There are no roster additions: 32 base classes, 18 prestige paths, 37 ancestry families, 50 heritages, 83 feats, 14 skills, 45 selectable psychic powers and 14 creature definitions. The internal companion class is excluded from the 50-career total; ability records are not unique spell counts.

## Evidence and source provenance

The [complete Windows run 39578198867](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39578198867) succeeded at `59f1b20b8bbb2a4a7029ee71b10190e774b9ed74`. It tested exported current and historical mechanics, exact separate-process restart, actual earned campaigns, connected combat, controls, rendering, the frozen 22,181-assertion GAME-32 oracle and production startup without installed Godot/Node dependencies.

The final presentation recheck must verify this successful receipt and exact unchanged authority/data/service/other-UI source, allowing only the specified self-button presentation line. It must freshly export, execute mechanics/cold restart and current controls, capture actual Godot pixels and launch the production executable. Its per-phase `proof_sources` must distinguish reused full-release observations from freshly executed checks. A fixture cache checksum may only be restored when its bytes match the already-saved packet fingerprint; no campaign or geometry is recreated.

Three normal campaigns earned 490 XP per character and reached level 8, including Psion 3 / Wizard 3 / Cerebremancer 2. Separate development fixtures prove Psion/Wilder through level 20 and all five implemented Cerebremancer levels. These fixtures did not earn level 20 through ordinary adventures. Connected combat, rewards, rest and exact reload are separately verified.

## Windows review and limitations

The final artifact URL, source, SHA-256, source-equivalence audit, native results, screenshots and regenerated readiness totals will be recorded here after the fresh recheck succeeds. Do not use the earlier pre-correction package as the final delivery.

Extract both archive layers, retaining all support, helper, asset and licence files beside `road-has-gone-dark.exe`. Launch that executable; no Godot or Node installation is required. Follow [TESTING.md](TESTING.md) for the ordinary creator, power choices, tactical augmentation/surge, earned advancement, optional prestige and full exit/reload checks. Existing campaigns retain their exact rules version.

These are bounded original adaptations, not a full tabletop conversion. Psychic multiclassing retains the existing shared manifesting pool; Cerebremancer-authored new powers retain its existing INT profile, while previously learned Wilder powers retain CHA. The UI tests exercise real controls through signals, not human/OS-driven acceptance. Windows empty-PATH startup is not a claim of a separately provisioned clean operating system. Inherited hover tooltips can obscure long labels and compact layouts require scrolling; human visual/balance acceptance remains outstanding.

GAME-123 remains open. [NEXT-WAVE.md](NEXT-WAVE.md) defines finite acceptance cohorts for the existing roster; Ardent, Lurk and Erudite are the recommended next audit. No new cohort or living-world development is included here. Linear is not callable in this session; GitHub issue #101 is the available milestone record, and no Linear write is claimed.
