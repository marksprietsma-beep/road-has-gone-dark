# Metamind and Pyrokineticist — verified Windows delivery

Both existing ten-level prestige paths passed bounded technical acceptance. Their authored gameplay already worked: no production rules defect or new v27 was justified. Immutable **v26** remains unchanged. This wave adds the missing progression, tactical, production-control, earned-entry, cold-process and native evidence. [PR #147](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/147) and [OPEN milestone #101](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/101) record actual merge/post-main status; this document does not predeclare pending checks successful.

## What was preserved and verified

- Metamind: finite main-action reclamation restores4+path level points up to capacity. Charges are1+floor(path level/4), refreshed by eligible home rest. Encounter entry/reload/unrelated rest scopes cannot bypass the reserve. Reserve/resilience choices, learned powers, owning-class attributes, independent arcane slots and Erudite distinct-per-rest limits remain consequential.
- Pyrokineticist: authored path1/4/7/10 Reflex-save fire ignitions spend2 points/main action. Saves halve fire; failed saves add Weakened. Actual fire resistance reduces damage while condition immunity blocks the rider independently. These are save-based ignitions, not weapon-flame riders or a general elemental-immunity system. Natural forms suppress psychic fire; reversion preserves identity and spent points.
- Both paths: permanent prerequisites, no starting prestige class, optional manually chosen advancement, legal rejection/decline, all ten path levels and total20 development histories, resource exhaustion, exact saved records and deterministic next-command/log/RNG continuation.

Only test/tooling defects needed correction: an unfreed prerequisite-planner Node caused strict process-exit failure after621 passing assertions; freeing it preserved the error guard. Native attempt39971651007 stopped **before export** because the source guard used Windows backslashes in a git-show object path. Using `relative_path.as_posix()` corrected the path without relaxing any source, pin, hash or save invariant. That attempt is not counted as a native pass.

Production scripts, rules, scenes, assets, world systems, campaign writer, action economy and RNG are identical to verified mainaab717e / prior nativee65. All **v1–v26 bytes/pins** are frozen. The exporter adds only the approved diagnostic scene. Existing nature/connected test harnesses gain explicit hooks whose original490XP/level8/no-setup defaults remain unchanged; this child alone targets810XP/level10 and a real pre-reclamation ward. No alternate mechanics/save engine or roster expansion.

## Native Windows evidence

[Complete native run39972423768](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39972423768) **SUCCESS**, exact source **`239358f1e234059dd4e1a8ca447bf5455e9cd268`**. [Raw receipt](evidence/native-proof.json), [timings](evidence/native-timings.json), [source/artifact identity](evidence/NATIVE-SOURCE.json), [archive audit](evidence/archive-audit.json), and [original screenshots](screenshots/README.md) are committed.

| Fresh Windows scope | Checks / separate-process cold | Result |
|---|---:|---|
| Current two-path mechanics, prerequisites, counterplay, lawful fixtures | 1,130 /129 | Pass |
| Actual production creator, advancement and tactical controls | 24 | Pass |
| Three ordinary earned careers and funded pre-entry saves | 989 /10 | Pass |
| Connected saved encounter, resolution and return/rest | 58 /136 | Pass |
| Prior v26 Psychic Warrior/Divine Mind/Cognition regression | 1,159 /135 plus108 controls | Pass |
| Historical v16 competence/save continuation | 818 /4 | Pass |
| Frozen GAME-32 oracle | 22,181 | Pass |
| Original Godot renders | 31 checks /19 PNGs | Pass |

Every phase has zero failures. The native QA executable runs with empty PATH/NODE_PATH and no source-helper override; the production executable is independently started. The frozen oracle uses the Windows source-Godot harness in the same job, not the exported executable. No Linux game validation.

Unrelated v26 current/historical native scopes are **explicitly reused**, not claimed fresh, from successful39882645495 at e65d098. The guard proves every production input and all26 immutable pins unchanged, restricts the exporter delta to one diagnostic entry, and checks the original committed receipt data/hash. This avoids repeating expensive unchanged work. The fresh two-path/native controls/earned/cold/render and current-support/legacy scopes above execute on the new source.

The three actual careers earned **810XP /total10** through81 normal rewarded opportunity resolutions, with duplicate rewards rejected. Histories: **Psion8/Metamind2**, **Psion5/Pyrokineticist5**, and Psion10. First funded entries are640XP/total9 and250XP/total6. Original-writer pre-entry forks are cold-loaded exactly; eligibility never automatically assigns a class. In connected saved combat, Metamind first spends3 real points on ally protection before reclaiming them. Native cold continuation resolves victory/defeat and normal rewards/rest without free XP. See [earned](evidence/earned-proof.json) and [connected](evidence/connected-proof.json) receipts.

Full ten-level prestige/total20 histories and images are **development fixtures**, not earned level20 claims.

## Windows download

[Self-contained Windows x64 artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39972423768/artifacts/12511742010) — artifact12511742010,90-day retention from upload. Repository access is required.

Inner playable ZIP: `game127-advanced-psychic-paths-windows-x64.zip`

SHA-256:

`d3b931a11c74efea668ce244f94352cdada53a93e04eba76778cd3aced00ae72`

Extract the outer GitHub ZIP, then the inner playable ZIP. Keep every extracted supporting file together and launch `road-has-gone-dark.exe`. No installed Godot or Node is needed; the AMD64 Node helper is bundled. Escape skips the intro. Resume existing campaigns without deleting or migrating saves. See [exact testing steps](TESTING.md) and bundled START-HERE.txt.

Independent inspection passed ZIP CRC, checksum/sidecar/native-receipt equality, AMD64 game/helper, exact manifest/core bytes, canonical v26 content hash,121 licence/credit files and absence of the QA executable. The actual startup/empty-PATH/save/restart proof comes from Windows, not host static inspection.

## Readiness and limits

The guarded generator consumed matching native evidence: **31 COMPLETE /19 PARTIAL /0 BLOCKED** across50 existing careers. Only Metamind/Pyrokineticist were promoted. Other acceptance remains explicitly source-labelled; COMPLETE denotes bounded original technical contracts, not full tabletop conversion or human balance/usability acceptance. [Readiness matrix](../game129/READINESS.md).

Rules remain `trhgd-character-v26`,26.0.0/schema1/engine3; canonical content hash `8eabc528b857b7d001ff9be1c5e34a963538c7f140cc544eb304844b73b2805d`. Counts unchanged:32 base classes,18 prestige paths,37 ancestry families,50 heritages,83 feats,14 skills,45 selectable powers and14 creatures. Both accepted paths have ten prestige levels; total20 multiclass fixtures are lawful.

Existing panels require scrolling; compact roster labels can truncate long multiclass text, while full names remain in tooltips/sheet/history. Requested1280×720 rendered1280×719; original640×360 and2560×1440 views are also retained. Existing nonhumanoid artwork fallback and human balance/readability remain. GAME89 playtest/downed movement, GAME92 tooltips/targeting/AoE/downed clarity and GAME140 sprites stay separate.

Final publication changes only documentation/evidence/generated readiness; the delivered source remains `239358f1e234059dd4e1a8ca447bf5455e9cd268` and is not rebuilt for those changes. PR147/#101 record actual normal merge and post-main Windows outcomes. Keep GAME123 **In Progress** and #101 **OPEN**. No callable Linear connector is available; GitHub and committed records provide the accurate handoff, with no direct Linear write claimed. Next recommended bounded cohort: **Sorcerer and Druid upper-tier acceptance**, not implemented here. Stop after this publication.
