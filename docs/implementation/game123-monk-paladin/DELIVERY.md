# Monk / Paladin native Windows delivery

The complete [Windows release40287149055](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40287149055) PASSED at source `d0460ff5942327b8cb6d238905c598704158aef4`. Subsequent delivery commits contain documentation, original screenshots and evidence-backed readiness only. No tested game, rules, harness, export or workflow input changes after that source.

## Download and launch

[Self-contained Windows x64 artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40287149055/artifacts/12636259638) · [complete native proof, raw saves/logs/timings and renders](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40287149055/artifacts/12637790046). GitHub authentication may be required.

1. Download and extract the outer artifact ZIP.
2. Extract `monk-paladin-windows-x64.zip` inside it.
3. Keep the entire inner directory and launch `road-has-gone-dark.exe`. No Godot, Node or separate artwork installation is required. Escape skips the intro.
4. Fresh New Game -> world -> origin -> hometown -> create Monk / Mercy Paladin / Justice Paladin. Existing saves retain their original rules pins and are never upgraded automatically.

Playable inner ZIP SHA-256:

`383ec9386c630706993b454db3d04ca88538eec15889c533bf3bee4d166481e4`

Independent audit verified7061 safe archive entries, CRC, AMD64 game and bundled Node, exact source manifest/core,121 licence/credit files and no QA executable. The Windows workflow actually executed the exported game with empty PATH/no installed Godot or source-helper override, separately launched the production EXE, and cold-restarted saved campaigns. The host archive/PE/hash audit does not execute Godot on Linux.

## Three reproduced repairs

Released30 Windows40278360934 passed85 checks and reproduced: paid Wind Reflex6→6 while ki3→2; Flurry accepted an actually manifested blade because its target gate used the original held flag; melee-described Smite accepted bows.

Append-only31 makes Wind's +2 stride/Reflex insight bonuses work alongside permanent speed/Evasion, requires the actual current unarmed profile for Flurry, and limits Smite to actual melee. The existing adapter consults the same requirement evaluator used by casting; the existing engine still owns targets, costs, turns, rolls, damage, XP and saves. Authentic free two-strike/-2 main-action Flurry is retained; ki pays for other techniques and recovery. Working Divine Grace, healing, prepared casting, party shelter and late powers are preserved and tested.

Content is `trhgd-character-v31`,31.0.0, canonical hash `2b1d5c8cb7f4c43a38a5705e65e694055fb2beca6d160a4f1f1e1c3fc69e19c1`. All1–30 bytes/pins remain unchanged. The roster stays32 base /18 prestige careers, total cap20; no ancestry, feat, spell, ability, equipment, resource or creature record IDs were added. Frozen TacticalCombat, RulesRng and the sole campaign writer remain byte-identical to verified main5a8de72. Other runtime edits are exact version enablement.

## Actual final native results

| Final native phase | Warm checks | Independent cold checks | Failures |
|---|---:|---:|---:|
| Pinned30 defect reproduction |85|—|0|
| Current Monk/Paladin mechanics |1343|145|0|
| Production creator/combat controls |72|—|0|
| Ordinary earned campaign |632|8|0|
| Connected combat/resolution/home |34|85|0|
| All32 base tracks through20 |2598|65|0|
| Current upper casting |1634|97|0|
| Historical30 martial mechanics |1143|49|0|
| Historical30 extended combat |642|37|0|
| Historical30 production controls |141|—|0|
| Historical29 |1290|125|0|
| Historical18 |599|31|0|
| Legacy16 |818|4|0|
| Compatibility16 |1941|486|0|
| Frozen GAME32 Windows oracle |22181|—|0|
| Actual exported Godot renders |39 checks /23 images|—|0|

These are this native run's results. Earlier source-only journey40284555076 had634 warm checks; the final native journey has632, reported separately rather than substituting a larger historical count. Raw outcomes, phase source bindings, saves, traces and timing are retained. The largest native phase was the all32 track audit at998.484 seconds; no successful expensive suite was rerun to inflate counts.

The ordinary campaign earns490XP and deliberately funds class8 for three distinct Wind/Mercy/Justice identities through existing opportunities. It proves the ninth level remains unfunded. The connected verification fork pays real class costs, waits for actual enemy injury before Mercy, then cold-resolves and returns home. The primary campaign is preserved. High20 examples are explicitly development fixtures, not earned20.

Matching-source native evidence promotes **only Monk and Paladin**: **41 COMPLETE /9 PARTIAL /0 BLOCKED**. Prior39 careers retain source-labelled acceptance; this is bounded technical readiness, not complete tabletop parity or human balance acceptance.

## Preserved integration and limitations

Owner-merged Fighter/Barbarian157 at61d4a79d passed all24 actual post-main Windows workflows;153 closed only then. Baseline5a8de72 adds only two approved class-browser design documents. No duplicate157 merge or repeated native30 release was performed.

Explicit Unarmed loadout and existing strict Monk armour rejection, including multiclass armour, remain required. The legacy empty-loadout fallback is unchanged. Shared long-label/small-screen clipping,1280×719 actual viewport and humanoid art fallbacks remain. Higher Paladin buffers apply to their authored target; Monk late buffers explicitly target the caster. No alignment, pantheon, piety, world or NPC expansion is claimed.

GitHub156 closes only after this cohort's normal merge and actual post-main Windows success. Parent101/GAME123 stays OPEN. No callable Linear connector exists; no direct Linear write is claimed. [Review steps](TESTING.md) · [original screenshots](screenshots/README.md) · [remaining finite work](NEXT-WAVE.md).


## Confirmed integration close-out

PR160 was already merged at f9880ed0865f163a8f90a19b2a650365b664dd96. All25 actual main-push Windows workflows now passed, including the long inherited native opportunity/creature/psychic pipelines. See ../game123-ranger-steward/evidence/monk-paladin-post-main.json for run IDs and actual conclusions.156 is resolved after this verification;101/GAME123 stays open at41/9. The successful31 release40287149055/source d0460ff and its original archive/checksum are preserved without another manual full release. Subsequent Ranger/Beast Steward161 work uses a separate branch from verified main.
