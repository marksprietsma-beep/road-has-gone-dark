# GAME-126 verification

This batch keeps 32 base classes and appends v16 for competence repairs. No new base class is added. The audit stages distinguish catalogue/definition/selection/derived effects/source testing/native testing/human validation. No per-option player acceptance is recorded.

## Reproducible automation

Run `python tools/character-content/validate.py` and `python tools/character-content/check-historical-packs.py`. The latter compares all15 historical pack bytes and exact manifest references with merged Wave Five0db4182, without needing network or a deep CI checkout.

Godot4.6.3 source entry points are in `tests/character_completeness/`: `repair_launch.gd`, `options_launch.gd`, `launch.gd` (all32 class tracks), `compatibility_launch.gd` and `journey_launch.gd`. Their output roots are respectively `GAME126_REPAIR_ROOT`, `GAME126_OPTIONS_ROOT`, `GAME126_AUDIT_ROOT`, `GAME126_COMPATIBILITY_ROOT` and `GAME126_JOURNEY_ROOT`. Set `GAME126_PACK=res://data/rules/trhgd-character-v16.json` for the all-class audit. Launch with `godot --headless --path . --script tests/character_completeness/<entry>.gd`. Set `GAME126_AUDIT_RESTART=1` in a genuinely new process to verify the saved output; never substitute an in-process deepcopy for restart. These are development-host source checks, not Windows distribution receipts.

The journey driver uses four independent3-person parties, selected by `GAME126_COHORT=0..3`. It creates new isolated campaigns, selects lawful skills/feats/classes, completes ordinary contextual objectives through AdventureService, returns home and explicitly commits XP-funded advancement through CharacterBuilderService. Each party member earns360XP and reaches7; prestige paths are optional, never starting classes. Advanced20-level careers and the exhaustive compatibility fixtures are separately labelled development fixtures. `GAME126_RESUME=1` is solely for recovering an interrupted QA campaign; it reads the existing save and awards nothing. `GAME126_COMBAT_ONLY=1` reuses a preserved earned campaign for tactical verification without repeating its rewards.

The native verifier `python tests/character_completeness/verify-package.py` runs on Windows only with `GAME126_ROOT`, the official `GODOT_BIN`, and the prepared `GAME76_HELPER_ROOT`. Workflow `verify-character-completeness.yml` installs exact dependencies, exports production and QA executables, clears PATH and helper overrides, executes original v15 mechanics/restart, v16 competence/skill/feat/heritage/class/compatibility checks,485 exact legacy prestige histories, all12 earned characters and cold campaign reloads. It then launches the ordinary production executable, removes the diagnostic executable and packages the complete game with licences/helper, manifest, source receipt and SHA256. Source-only success is insufficient to pass this gate.

## Actual scope of witnesses

- v15/v16 all-class audit:640 lawful levels and588 successful observable direct RulesEffects uses. Direct effects do **not** establish tactical target selection or coverage of every conditional trigger, channel, passive or career selection.
- Prestige baseline: all576 base/prestige pairs investigated using bounded, prerequisite-directed production previews.485 full-cap histories succeed through total20;91 missing witnesses remain unresolved. The current-pack compatibility pass replays those485 histories as newly labelled v16 development fixtures, including nested creature pins. It is not a production campaign migration. Native cold replay also checks their original v15 histories unchanged.
- All82 feats: lawful prerequisite-directed selections, actual applied features/derived statistics/capacities. Conditional tactical effects retain separate coverage limits. All50 heritage records: legal birth, inherited numerical/capability outputs and equipment/body restriction enforcement. This is not every ancestry×class×equipment permutation or custom sprite coverage.
- Five new skill approaches: rank gating, deterministic successes/failures, exact costs/time/outcomes and reward-policy projection; real campaigns additionally persist successful selections, reject repeated rewards and fork a failed check through the original writer without XP. Nature/Performance formula counterfactuals verify their pre-existing skill uses.
- Twelve earned identities: actual tactical main actions or attacks and exact command/RNG replay; move/end actions do not count as an ability witness. These battles use the actual earned records and production engine; the four isolated tactical fixtures do not manufacture campaign XP.

## Test-harness corrections

Early local journey attempts passed a seven-field history step to a six-field choice API, attempted to forget permanent spontaneous knowledge, changed Spirit Shaman retrieval without a rest permit, or selected a Duskblade delivery wrapper as a known spell. Production correctly rejected them. The fixture now uses legal player choices and retains known spells. The wrapper problem also exposed a real suggestion-helper defect; v16 suggestions now exclude wrappers, matching the existing Spellbook selector and authority.

The first compatibility-prefix fixture retained level20 HP/resources/companions after truncating history, causing invalid prefixes despite valid full histories. It now projects prefix capacities and synchronises owned creatures with that prefix's actual owner level. Nested v15 creature pins are explicitly updated only inside newly constructed v16 QA fixtures; old campaign records are never repinned. Exact-save/hash invariants remain intact. Final CI must run these corrected tests; earlier failed runs are not release evidence.

## Human review

Extract both ZIP layers. Run `road-has-gone-dark.exe`; keep every supporting directory beside it. No installed Godot/Node is needed. Escape skips the introduction. New Game defaults to v16; existing campaigns retain their original pins.

Create distinct classes and inspect Race/Class, Build (skills/feats/equipment/spells), Sheet and Advance. Invest ranks in Athletics, Stealth, Acrobatics, Spellcraft or Animal Handling. Enter the hometown, Seek new leads, follow a recovery/investigation/access opportunity and review trained contextual options, DC and cost. Spellcraft/Animal Handling assess possible explanations of existing reports; success does not invent magic or animals. Complete an objective, return home and advance with actual earned XP. Exit and Resume; identity, history, outcomes and XP must persist. Failed checks give no XP and an already completed objective cannot pay again.

For Archmage, review the permanent seventh-tier arcane requirement in Advance. It is never a starting class or automatically granted. Nominal slots, temporary feature grants and unlearned spontaneous spells cannot qualify. Depleted resources and unprepared copies do not erase permanent prepared-caster competence. The level13+ examples are development fixtures; the earned journey evidence reaches7 only.

CI links, native results, screenshots and package checksum are recorded in DELIVERY.md once verified. Do not mark GAME-123 or the broad character programme complete from these tests.
