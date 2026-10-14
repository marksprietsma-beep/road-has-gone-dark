# GAME-112 Character Catalogue Wave Two delivery

PR: https://github.com/marksprietsma-beep/road-has-gone-dark/pull/96

PR #96 was normally merged as `89c8956de79122e64c57a3826645a87007ed632c`, preserving the baseline9b3680e and delivery0b76d84 histories. All16 final PR checks passed; one optional World Library package job was skipped. All four post-merge workflows passed, including both complete native character jobs, both party/expedition jobs, both UI jobs and the production Windows build.

Latest native-package source is merged main `89c8956de79122e64c57a3826645a87007ed632c`. The original implementation source was3eca310, followed by documentation-only delivery0b76d84. Main's tree equals that delivery tree; all production/test/build trees match the original verified implementation. This final publication follow-up changes documentation/evidence only. Actual final main SHA is recorded in GitHub rather than anticipating the hash of a future documentation merge.

Character pack: `trhgd-character-v12`, canonical content hash `5e8c86623f159e032f7201233c18fad9d4a033d4ae79a0959595f439c5428a0b`. Fresh campaigns default to v12. Historical v1–v11 files are byte-identical to the integrated baseline, and existing campaigns retain exact saved rules pins. Once delivered, append a new content version rather than editing v12.

## Playable cohort

| Category | Before (v11) | Verified v12 |
|---|---:|---:|
| Base-class adaptations | 19 | 23 |
| Prestige paths | 8 | 10 |
| Ancestry families | 17 | 21 |
| Heritage records | 26 | 30 |
| Mechanical feats | 40 | 45 |
| Skills | 14 | 14 |
| Scheduled career-choice groups | 47 | 66 |

All 23 base tracks support executable progression through level 20. The eleven core tracks are retained; Psion, Psychic Warrior, Soulknife, Warlock, Scout, Swashbuckler, Knight and Warblade extend from 12 to 20 with active powers and persistent career choices. New Crusader, Swordsage, Wilder and Binder tracks run through 20. They remain bounded original adaptations with small repertoires, not complete tabletop/sourcebook conversions.

Crusader has selected stance/manoeuvre, readiness expenditure and main-action recovery, healing/guarding and allied renewal/radiant effects. Swordsage has distinct disruption, fire, mobility/recovery and concealment effects. Wilder uses finite psychic points and an optional four-point surge with a self-Weakened drawback and later control/augmentation. Binder chooses a persistent ember/sentinel covenant with daily commitments, and later gains real sentinel/form powers. It does not implement a full rotating pact catalogue.

New prestige paths, each five levels:

- **Warshaper:** total level at least 5, BAB at least 4, permanent Wild Shape feature. A normal Druid 6 qualifies for entry at total level 7, requiring 360 earned XP. Progression strengthens actual body forms and natural weapons.
- **Bonded Summoner:** total level at least 5, arcane casting at least 3, Arcana ranks at least 4. Wizard 5 can enter at total level 6, requiring 250 earned XP. Progression grants bounded sentinel summons with increasing durations.

Temporary body/casting effects cannot replace permanent entry requirements. Positive and negative eligibility, five prestige levels, actual tactical powers, ordered multiclass histories and reload are verified.

New inherited families/heritages: **Centaur, Minotaur, Changeling and Shifter**, each with one Standard heritage. Centaur changes size/reach/stride and armour compatibility; Minotaur has physical resistance and actual horn attack; Changeling has bounded adaptive reflexes; Shifter has an inherited Wolf form. Culture/background remains separate from ancestry. No social disguise simulation is claimed.

New feats: Natural Form Training, Martial Recovery, Psychic Discipline, Pact Endurance and Shape Endurance. Added abilities include prepared Summon Sentinel for Wizard/Cleric/Druid, Wolf/Bear natural attacks, form reversion, selected martial manoeuvres, psychic surge and covenant powers. Small executable repertoires are reported as such, rather than as complete spell/power libraries.

## Companions, summons and body forms

Druid selects Wolf/Bear at level 1; Ranger at 4. Druid growth uses its class level; Ranger growth uses level minus 3. A durable creature record is nested under its owner and saved by the original campaign writer. Creatures receive real placement, initiative, controllable ordinary movement/attacks, action resources, HP and conditions. Growth preserves accumulated damage; existing home recovery restores companions. One nature companion per owner is enforced, including multiclass builds.

Prepared Summon Sentinel consumes the caster's main action, tier-one slot and prepared copy. It enters the first free adjacent tile, acts after its owner and expires after three global rounds (prestige abilities have their own bounded durations). One active temporary summon per owner; duplicate/no-space requests fail atomically without spending resources. Dismissal costs a main action. Defeat, withdrawal, expiry and replay use the existing combat authority. Encounter history is bounded to 32 total actors. Players directly control creature turns; diagnostic gameplay also uses the existing deterministic nearest-target command policy.

Druid 5 gains actual Bear/Wolf forms: changed STR/DEX, size/reach/movement, natural weapons, equipment melding and spell suppression. Original ancestry, identity, HP/damage and other conditions remain. Revert consumes a main action and never heals. Duration/home recovery removes temporary forms; save/restart preserves an active form. Higher master-form damage is applied to the actual natural weapon, with a specific tactical regression test.

## Windows review package

[Download Windows x64 artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38521625941/artifacts/11876850412)

Inner playable ZIP: `game112-character-catalogue-wave-two-windows-x64.zip` (121,376,303 bytes).

SHA-256:

```text
d2b21eeda18977af635eaeb06275d6c169e9d790579f556857a773b43c37dc3d
```

Extract the outer GitHub artifact ZIP, then this inner playable ZIP. Open the extracted folder and run `road-has-gone-dark.exe`. Keep all files together, including the bundled helper, artwork and licence notices. No installed Godot or Node is needed. Escape skips the intro. GitHub sign-in may be needed to download an Actions artifact. Retention is 90 days from upload; archive the package for longer-term access.

The downloaded archive passes ZIP integrity checking; executable/content/manifest/start instructions and bundled helper are present, QA executables are excluded, and its content JSON matches this repository byte-for-byte. Native Windows CI ran gameplay and a new-process restart with empty PATH and no source-helper override, then launched the production executable. This is native headless verification, not human desktop/GPU acceptance.

[Linux x64 artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38521625941/artifacts/11878025259), inner archive `game112-character-catalogue-wave-two-linux-x64.tar.gz`:

```text
1153a2115de6e70d8b3422815c64ee154dad021a5ea5d1b102f705df7904fe1e
```

## Verified results

[Full post-merge source/native Windows and Linux workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38521625941): both jobs passed on merged main89c8956. Original implementation-run evidence38492793161 is retained separately. Downloaded proofs and phase timings are retained in [evidence](evidence/), including independent archive verification.

| Proof | Windows | Linux |
|---|---:|---:|
| Wave Two mechanics (source and native, each) | 1,953 / 0 failures | 1,953 / 0 failures |
| Separate mechanics restart | 7 / 0 | 7 / 0 |
| Original3eca310 source campaign journey | 189 / 0 | 174 / 0 |
| Main native campaign journey | 243 / 0 | 210 / 0 |
| Separate campaign restart | 6 / 0 | 6 / 0 |
| Earned journey XP | 40 | 40 |

Journey command counts vary with independently created persistent identities/encounters; each run verifies deterministic replay and exact writer-owned state. Do not treat distinct campaign identities as an identical seed comparison. Native gameplay took 162.328 seconds on Windows and 205.006 on Linux; restart took 2.766 and 3.173 seconds respectively. No engine errors were hidden behind zero exit codes.

The full workflow passed the original generated-world/40-context opportunity tests, V1/V2 save compatibility, GAME-103/104/118 creator/content/default/atomic checks, GAME-119 careers/prestige, GAME-121 actual earned prestige/cycles, historical Wave One matrix, First Adventure and responsive UI checks. Frozen GAME-32 kernel: 22,181 checks, zero failures; original migration/restart checks also pass. Protected historical packs, hashes and behavioural oracle remain unchanged.

Additional merged-main workflows all passed:

- [Final PR-head rules and native distribution](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38517244100)
- [Main production Windows build](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38521625923)
- [Party, input/render and expedition](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38521625849)
- [Production UI and native distribution](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38521625871)

All current PR checks passed; the optional World Library `review-packages` job was skipped, with both library verification jobs successful. The Wave Two package was independently produced and verified. Earlier failed/cancelled runs are historical, not successful final evidence. The long ancestry-menu failure on 712b5b1 was a real production input bug, corrected on 3eca310 without changing old assertions; see [CI-REPAIR.md](CI-REPAIR.md). The initial unregistered source-projection failure was also corrected with explicit reversible v12 adapters while retaining original frozen hashes/oracle.

[84 actual Godot screenshots](SCREENSHOTS.md) cover 640×360, 1280×720 and 2560×1440. Each has source qualification and SHA-256 in screenshots.json. Normal level-two progression is earned. Higher-level form/prestige fixtures are independently saved, explicitly labelled development data, with no ordinary XP grant. See [TESTING.md](TESTING.md) for exact player actions.

## Coverage and limits

The canonical [coverage matrix](../game104/COVERAGE.json) retains all 720 rows and 760 source occurrences: 403 ancestry/subrace, 66 adventurer base, 283 prestige and eight NPC families. There are now 54 bounded, natively validated first-occurrence adaptations, up from 44; 706 source occurrences remain unplayable. Source/setting variants are not silently consolidated. One internal creature advancement track is excluded from adventurer/NPC-family counts. Original cosmetic heritage records do not fulfil unrelated indexed races.

Creature, unusual ancestry and transformed-body art is an explicitly labelled humanoid LPC fallback. Large actors still occupy one tactical cell. No flight, aquatic movement, climbing, darkness, companion inventory, full animal special-attack library, complete summon taxonomy or rotating pact library is claimed. Summon strength is bounded half total character level, capped at 10. Forms alter STR/DEX; original CON/health remains authoritative. Existing basic enemy level cap 12, reward cadence and human balance/pacing/art acceptance remain limitations, not new world/enemy work in this task.

The complete character programme is unfinished; issue #82 must remain open. Next character-only cohort: selectable psionic powers/augmentations and companion/form repertoires, then distinct Ardent/Lurk and Beast Heart Adept adaptations. Expand shared mechanics and actual choices before counting those careers playable. See [CONTINUATION.md](CONTINUATION.md).
