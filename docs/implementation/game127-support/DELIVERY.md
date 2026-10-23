# GAME-127 psychic support cohort — verified Windows delivery

Psychic Warrior, Divine Mind and Cognition Adept passed their bounded native acceptance contracts. This completes this cohort's technical acceptance, not GAME-123 or human balance/usability review. [PR #146](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/146) targets main; actual merge and post-merge status are recorded on that PR and [open milestone #101](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/101).

## Implementation and compatibility

The valid Ogre reproduction demonstrated that Cognition Adept's authored adjacent melee strikes inherited ordinary two-tile weapon reach. Immutable **v26** restricts the five existing strikes to equipped melee and exact adjacency. Their original direct psychic damage still precedes a separately rolled weapon attack, which may miss. Ordinary ancestry reach remains functional. A second reproduced presentation defect advertised range 2 for an already adjacent-only Lurk action; the shared caption now respects the existing descriptor and displays range 1. No Lurk combat semantics changed.

All historical **v1–v25 bytes and pins remain unchanged**. Fresh campaigns default to v26; existing campaigns retain exact original mechanics, including historical Cognition reach. No migration, combat resolver replacement, campaign writer change, world-system change or roster expansion. Other runtime changes append v26 to existing version gates. See [runtime scope audit](evidence/runtime-scope-review.json).

Pin: `trhgd-character-v26`, rules `26.0.0`, schema 1 / engine schema 3. Canonical content hash:

`8eabc528b857b7d001ff9be1c5e34a963538c7f140cc544eb304844b73b2805d`

Existing working mechanics were verified rather than replaced:

- Psychic Warrior: selected support/damage powers, physical augmentation versus weapon attacks, actual costs/misses, late stance/resistance, natural-form suppression and restoration after reversion.
- Divine Mind: permanent mantles/doctrines, typed aura bonuses within radius 3 and clear sight, source downing/transformation suppression, switching and Rally. Activation/switching spends a main action and Resolve; maintaining the aura has no per-turn upkeep. Powers compete for the main action and spend psychic points separately.
- Cognition Adept: permanent prerequisites, optional manually selected XP-funded entry, all five prestige levels, actual strikes and selected augmented powers. Eligibility never grants a class automatically. It remains unavailable at character creation; temporary bonuses cannot satisfy permanent entry.
- One finite shared psychic pool with owning-class casting attributes, independent arcane preparations/slots, exhaustion/rest, exact saved history/resources/statuses and deterministic next-command combat/RNG continuation.

## Successful Windows evidence

The single full release [39882645495](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39882645495) **succeeded** at exact source **`e65d098a68858ef9247a7644a94b2485f671a323`**. Subsequent delivery/readiness changes preserve runtime, test and packaging source equivalence; no duplicate full release. See [source identity](evidence/NATIVE-SOURCE.json), [full raw receipt](evidence/native-proof.json), [actual timings](evidence/native-timings.json) and [independent archive audit](evidence/archive-audit.json).

| Acceptance phase | Checks / separate-process cold checks | Result |
|---|---:|---|
| Cohort mechanics; lawful early/mid/late development builds | 1,159 / 135 | Pass |
| Actual production creator/advancement/target controls | 108 | Pass |
| Three real earned careers | 620 / 8 | Pass |
| Connected saved generated encounter | 40 / 76 | Pass |
| Current all-base legal level 1–20 audit | 2,598 / 65 | Pass |
| Current inherited upper/performance/supernatural/martial/mobile/psychic/identity cohorts | Individually recorded in raw receipt | Pass |
| Historical v25, v24, v23, v13 and legacy/compatibility v16 mechanics/cold continuation | Individually recorded in raw receipt | Pass |
| Historical byte/pin guards v1–v25 | All 25 unchanged | Pass |
| Frozen GAME-32 oracle | 22,181 | Pass |
| Original native Godot captures | 35 checks / 24 PNGs | Pass |

Every phase has zero failures. Native QA phases run the exported executable with empty PATH/NODE_PATH and no source-helper override. Normal production executable startup is separately checked. The frozen oracle uses the Windows source-Godot harness in the same workflow, not the exported game. No Linux game validation.

The earlier [source campaign/capture run 39880568491](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39880568491) also passed at e65. The final exported journey has **620** checks, not the source run's 619. Original pre-fix and intermediate source receipts remain separately labelled.

Three ordinary careers genuinely earned **490 XP / total level 8**, without XP injection: Psychic Warrior 8, Divine Mind 8, and Psychic Warrior 6 / Cognition Adept 2. Failed choices, reward limits, explicit prestige selection, save/restart and connected combat are verified. Base level 20 and five-level prestige histories are lawful **development fixtures**, not earned level-20 claims. See [earned receipt](evidence/earned-proof.json) and [original screenshots](screenshots/README.md).

## Windows download and launch

[Complete Windows x64 artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39882645495/artifacts/12473865536). Repository access is required; retention is 90 days from upload.

Inner playable ZIP: `game127-psychic-support-windows-x64.zip`

SHA-256:

`3e2a7b76d3e503cebc0014087c1f4a006d76b2e49febc0d0038d9f371f400c18`

Extract the outer GitHub ZIP, then the inner playable ZIP. Keep the entire extracted folder together and launch `road-has-gone-dark.exe`. No installed Godot or Node is required: worldgen-helper and its AMD64 Node runtime are bundled. Escape skips the intro. Resume existing campaigns normally; never delete/recreate a save for this test. See [exact playtest steps](TESTING.md) and bundled `START-HERE.txt`.

Independent static inspection verified ZIP CRC, SHA sidecar/receipt, AMD64 executable and bundled Node, exact manifest/core bytes, canonical hash, 121 licence/credit files and absence of the QA executable. Native runtime/restart evidence comes from the Windows workflow, not host static inspection.

## Readiness and remaining limits

The guarded generator consumed matching native evidence and promoted only these three careers: **29 COMPLETE / 21 PARTIAL / 0 BLOCKED**. [The 50-career matrix](../game129/READINESS.md) retains labelled inherited evidence and a finite remaining queue. COMPLETE denotes bounded technical contracts, not full tabletop fidelity or human acceptance.

Counts unchanged: **32 base classes, 18 prestige paths, 37 ancestry families, 50 heritages, 83 feats, 14 skills, 45 selectable psychic powers, 14 creatures**. Psychic Warrior/Divine Mind support levels 1–20; Cognition Adept has five prestige levels. No catalogue growth claim.

Known limits: one original shared psychic pool; natural forms suppress psychic actions; creature/nonhumanoid sprites retain existing fallback; small panels require scrolling. Requested 1280×720 produced an actual 1280×719 viewport, recorded honestly alongside 640×360 and 2560×1440. Human balance/readability review remains separate. GAME-92 tooltips/targeting/AoE/downed clarity, GAME-89 Windows playtest/downed-movement findings and GAME-140 nonhumanoid sprites remain separately tracked, unchanged here.

GitHub #101 stays OPEN / GAME-123 In Progress. No callable Linear connector is available; no direct Linear update is claimed. GitHub and committed records provide the handoff. Next recommended cohort: **Metamind and Pyrokineticist**, not implemented here. Stop after publication.
