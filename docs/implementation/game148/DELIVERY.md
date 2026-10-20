# GAME-148 — Windows release and technical acceptance

## Delivered scope

Immutable **trhgd-character-v21** gives three existing classes distinct executable identities. No roster, world or alternative rules engine was added.

- **Warlock:** selected Binding utterance is an at-will main-action, range5 Will-negated movement penalty; the alternative Dusk veil provides personal weapon concealment and relief. Late sapping damage now allows Reflex half damage, with its weakening rider only on failure, respecting Evasion/immunity. The deliberate late Dread pressure choice applies independently saved area control rather than a weapon-only bonus.
- **Binder:** permanent, mutually exclusive Embers versus Sentinel changes the actual action. Embers spends a rest-limited commitment for saved fire damage and Off Balance. Covenant intercession spends a commitment to give an ally temporary HP, relief and Guarding. Guarding protects an adjacent *other* ally using the recipient’s existing shared reaction, not an extra reaction or AI taunt. Late owned-summon and body-form paths are exercised separately.
- **Dragonfire Adept:** repeatable elemental basic breath remains free of finite invocation costs. At class6 the player deliberately chooses a longer single-target, two-global-start recovery breath or a wider enemy burst costing resolve. Later selected invocations acquire actual ally/group targeting, relief and hindrance differences. Read-only target preview lists affected combatants; resource/recovery summaries remain in the existing combat controls.

These are three bounded gap groups. Six elemental shape variants plus one Pressure definition are seven action records, not seven unique spells. See PACK-DELTA.json and ASSESSMENT.md for precise before/after data and bounds.

## Verified Windows distribution

- [Playable Windows x64 artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39232732845/artifacts/12179465231) — download the GitHub artifact ZIP, then extract the playable ZIP inside it.
- Inner ZIP: `game148-supernatural-signatures-windows-x64.zip`
- SHA-256 of that **inner playable ZIP**: `16f4b926cdcb9b129592e974251747818fd71177f9edb93fc2deabcff4c014ea`
- [Successful complete native workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39232732845); [native evidence artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39232732845/artifacts/12179475242).
- Exported/tested source: `0f469c9ae24bb0f29372eb92b239b848fe6b5be7`. Production mechanics/data are unchanged since `0f404cf1c48441b2efd5a9d4b7c563a78735ee91`.
- Pack content hash: `b3417a02264a64204482b022e211b26bf013ae7bc27bc1d1aa2f668879bdddab`.

Independent host **artifact inspection**, not Linux game execution, passed ZIP CRC/path/duplicate checks across7,061 entries, Windows AMD64 game and bundled Node PE checks, executable SHA/source provenance, exact bundled v21 content, licence/credit presence and absence of the QA executable. Production startup ran on native Windows with an empty PATH and no source helper override; no installed Godot/Node is required. Exact proof, provenance, timings, reuse and archive-audit records are in evidence/.

### Execution evidence and reuse

The final gate contains23 zero-failure receipt records plus24 capture checks. It reuses nine **unchanged completed phase groups** from run39226588983/source0f404cf, with exact pins, clean timing/exit records, source diff and export anchor checks. That earlier overall run failed later in an unexecuted journey script; it is never described as a complete successful release. Fresh final-run execution covers the corrected v18 phase/cold, earned journey/cold, connected battle/cold, captures, newly exported production startup and final archive. The final workflow also freshly passed13-script compilation,988 focused mechanics,77 cold and20 production-control checks before export. See TESTING.md for exact per-phase counts and failure history.

The genuine campaign earns490XP through normal opportunities and reaches level8 for Warlock, Binder and Dragonfire Adept, with no injected XP. The connected verification fork uses all three real selected actions in active campaign combat, saves spent pools, cold-resumes deterministic commands/RNG, resolves consequences and rests through the production writer. Lawful1/6/12/20 and late summon/form/multiclass examples are **development fixtures**, not earned level20 campaigns.

## Compatibility and readiness

All historical v1–v20 pack bytes/manifest rows and frozen GAME-32 TacticalCombat source remain unchanged. Fresh campaigns use21; old saves retain exact original pins/mechanics. Archived v20/v19/v18/v16 and migration/cold witnesses pass. No second writer or silent migration exists.

Roster counts remain32 base careers,18 prestige paths,37 ancestry families/50 heritage records,83 feats,14 skills,45 selected psychic powers and14 creature definitions. Base caps remain20; prestige paths remain5. Counts do not establish complete class identity.

The reproducible50-career matrix now reports **15 scoped technically COMPLETE /35 PARTIAL /0 reproduced BLOCKED**, previously12/38/0. Warlock, Binder and Dragonfire Adept are promoted on matching v21 native tactical, choice, resource, early/mid/late, earned and persistence evidence. Earlier cohorts retain explicitly labelled historical acceptance where reused. This is original technical functionality, not exhaustive tabletop conversion or final human balance. GAME-123/#101 and the broader programme remain OPEN.

## Playtest and limitations

Extract both ZIP layers, keep every supporting folder, and launch `road-has-gone-dark.exe`. Escape skips the intro. Start a **fresh** campaign to obtain21; do not reset or change an existing save’s pin. Create the three classes, inspect their persistent choices, follow an opportunity and use their actions. Return home/rest, earn250XP for level6 and choose a Dragonfire shape via Characters → Advance. Save, fully exit/relaunch, and resume. Detailed controls/expected outcomes: REVIEW.md.

Actual unmodified Godot PNGs, dimensions and hashes are in screenshots/ and SCREENSHOTS.md. Combat captures show existing LPC sprites, actual pools, logs and area feedback. Visual inspection found missing text in some earned sheet captures, a blank build-tab detail capture, and horizontally clipped compact combat captions. These captures are retained honestly; they do not prove clean sheet/build visual acceptance. Requested1280×720 captures have actual1280×719 client dimensions. Capture artefact versus interactive rendering has not been independently isolated. Larger combat captures are readable. Human visual/balance review remains separate.

No cones, flight, general stealth/world-pact mechanics, daily rebinding, custom transformed creature art or new VFX engine is claimed. Current engine uses bounded radius targeting, existing rest authority and humanoid fallback presentation. No next implementation wave is included.

## Publication

PR/current-head Windows checks and normal merge are the remaining publication gates at this documentation checkpoint. The merged PR and exact main SHA will be recorded in GitHub tracking after confirmation. No direct Linear connector is available; existing GitHub milestone#101 is the authorised fallback.
