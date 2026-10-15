# Wave Three delivery

PR: https://github.com/marksprietsma-beep/road-has-gone-dark/pull/98

Last gameplay correction: `a2021ee3d3e3f32f78aa25aafaf145cdca5362e2`. Verified build/test source: `5d6576102057c936f1c14fce868c70052958eb57`. Later delivery commits change documentation, coverage accounting and screenshot/evidence files only. PR98 merged as `0f46194beabedf8b287795076f75800a3aef467b`. Post-merge validation: https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38669734386 (running at this documentation checkpoint; branch-level full native verification below passed).

Pack `trhgd-character-v13`, exact content hash `e6c2a203f9930033922a1551c4d86edd0672f698eceee5eae2bbeb806d1193aa`. v1–v12 are unchanged. New campaigns default to v13; older saves retain their exact original pins.

## Implemented and natively verified scope

| Category | Before | After |
|---|---:|---:|
| Base tracks, levels1–20 | 23 | 25 |
| Prestige paths | 10 | 12 |
| Ancestry families | 21 | 25 |
| Heritage records | 30 | 34 |
| Feats | 45 | 50 |
| Skills | 14 | 14 |
| Selectable psychic powers | 0 | 21 |
| Creature definitions | 3 | 8 |
| Career-choice groups | 66 | 133 |

New careers: Ardent and Lurk. New five-level prestige paths: Beast Steward (original adaptation of the Beast Heart Adept concept) and Cerebremancer. New inherited adaptations: Elan, Xeph, Maenad and Dromite. These are bounded original implementations, not complete sourcebook conversions. All25 base tracks cap at20. Prestige caps are5 for Duelist, Eldritch Knight, Arcane Trickster, Mystic Theurge, Warshaper, Bonded Summoner, Beast Steward and Cerebremancer;10 for Shadowdancer, Dragon Disciple, Dwarven Defender and Pyrokineticist.

Powers known come from persistent ordered career selections. The21 powers span tiers1–9 and have authored augmentation variants; this is a limited repertoire. Variants spend their actual additional points and cannot exceed shared manifesting level. Psion, Ardent, Wilder and Cerebremancer contribute two points per class level; Psychic Warrior/Lurk contribute one, plus a single shared base allowance of two. Shared save attunement uses the best mental modifier among owned manifesting profiles. Psychic Warrior/Ardent use Wisdom, Psion/Lurk/Cerebremancer Intelligence, Wilder Charisma. Ardent mantles restrict powers and grant distinct capabilities. Lurk's finite veil precedes a separately rolled melee ambush consuming points and focus.

Leopard, Boar, Stag, Stone Guardian and Renewal Spirit have distinct natural attacks, movement, defences and effort-costed actions. Druid/Ranger have five persistent animal choices. Prepared summons spend matching slots/copies; psychic summons spend points, with duration augmentation. Existing one-permanent/one-active-temporary limits, legal placement, ordinary ownership/turns and expiry remain authoritative. Three additional body forms change physical attributes, attacks and tactics while preserving health/identity and suppressing equipment, spells and psychic actions. Beast Steward grants companion growth/training and actual rally actions; Cerebremancer advances qualifying saved arcane/psychic histories and power choices.

## Verification

Full Windows/Linux source and native workflow PASSED at the build source above:
https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38659291625

| Native platform | Mechanics / failures | Mechanics restart / failures | Ordinary journey / failures | Earned XP | Campaign restart |
|---|---:|---:|---:|---:|---|
| Windows | 1792 / 0 | 6 / 0 | 165 / 0 | 30 | Passed |
| Linux | 1792 / 0 | 6 / 0 | 178 / 0 | 30 | Passed |

Both packages run QA with empty PATH and no source helper override, followed by a distinct process restart. Production executable startup is separately checked. This is automated native acceptance on GitHub's Windows/Linux runners, not a claim of human acceptance or a separate pristine Windows VM test.

Both focused native catalogue jobs additionally passed1,684 historical mechanics,2,066 tactical and133 prestige gates each, followed by23 cold-restart checks including allnine complete before/after snapshot comparisons. Their same-head proofs are in FOCUSED-NATIVE-EVIDENCE.json. The source earned optional-choice branch passed911 checks/380 genuine XP andfive restart checks; it committed Wizard instead of eligible Arcane Trickster without granting XP while the primary save chose prestige. See ACCEPTANCE.md for every original wave requirement.

The full workflow also passed original content, low/high class progression, prestige, frozen GAME-32, legacy builder/save, First Adventure, GAME-83 presentation, contextual opportunities, earned rewards and earlier native packages. Raw job/step results are in CI-EVIDENCE.json; new native results/timings are in NATIVE-EVIDENCE.json.

Additional recorded local evidence:22,181 frozen kernel assertions,235 migration-create/six reload checks; corrected earned journey1,119 checks/zero failures,370 genuine XP over ten cycles (Arcane Trickster entry at250XP),four restart checks; catalogue210 gameplay/14 restart checks; frozen Wave Two1,953 mechanics/seven restart and288 journey/six restart checks. These are local evidence, not fresh Windows counts. The normal psychic journey's XP above is earned; advanced fixtures are separately labelled development saves.

Real Godot rendering passed254 checks/zero failures and93 renders across640×360,1280×720 and2560×1440; a focused creator capture added15 checks/zero failures. The54 selected screenshots and matching hashes are in SCREENSHOTS.json. They demonstrate same-ancestry Psion offence/control, Ardent choices, Lurk veil/ambush, augmentation targeting without state/RNG mutation, actual summon cost/turn/expiry, distinct creature actions, two forms and both saved prestige histories. Render shutdown emits an ObjectDB cleanup warning retained in raw evidence; no script error was concealed.

The native snapshot failure came from v13 dotted StringName fields appended after the earlier key-normalisation boundary. Mixed-key sorting was not lexical. The complete v13 snapshot is now normalised after all fields; mechanical values and historical v1–v12 hashes are preserved. First-entry prestige is rejected independently of data prerequisites, starting selectors are base-only, and permanent companion entitlement excludes runtime grants. Eligibility never assigns prestige: the player commits a manually selected, genuinely funded level.

Actual failures and corrections: the old whole-manifest pin guard rejected an authorised append; the frozen historical baseline/hash and exact historical rows are retained, with append-only validation and nine positive/negative gates. Windows JSON parsing explicitly uses UTF-8 for exact pins. A genuine v13 Wizard advancement overflow was fixed by keeping spell suggestions within existing repertoire/tier limits (96 caster checks through20). The earlier catalogue harness now exercises the saved v13 Psion power and preserves old automatic techniques for older pins; ownership, accepted-command and exact-state assertions remain. Historical packs, tactical source pins and frozen assertions were not changed.

## Windows download and launch

Download: https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38659291625/artifacts/11943178057

Playable ZIP: `game112-character-catalogue-wave-three-windows-x64.zip`
SHA-256: `3858150ba17360147cee91808fd1aa5c703c9ae9460a68b12b8793fd37fae18e`

1. Download the GitHub artifact ZIP while signed into GitHub.
2. Extract it, then extract the contained playable ZIP.
3. Open the resulting game folder and run `road-has-gone-dark.exe`. Keep all files/subfolders together. Bundled helper, artwork and licences are included; no installed Godot or Node is required.
4. Escape skips the intro. New Game → world/origin/hometown → choose Race/Class → Build/Specialisation/Powers → review sheet → save three adventurers → ready party → seek an opportunity → travel/fight → return home → earn advancement → exit/Resume.
5. In combat select a learned power and augmentation, press Manifest and choose a legal target. Selector changes spend no resources and change no battle state/RNG. Rest at home restores eligible reserves. Lurk must veil before ambushing with equipped melee gear. Companions have ordinary turns; temporary summons expire and cannot be duplicated. Druid forms/reversion use existing actions.
6. Resume an older campaign separately and verify its original rules pin and identities remain. No save reset or content upgrade is required.

Linux CI package SHA-256: `cb2e21b103860da80f4f8a488a1df8c150ca2e9ad1f6a57b858292c7dcf5377f`. The earlier local c805 Linux archive remains separately recorded at `/workspace/artifacts/wave-three/native-linux-delivery/distribution/game112-character-catalogue-wave-three-linux-x64.tar.gz`, SHA `edd8ee71179209e438d2c1386fad8790acbfd998a24b74adf4331406e0112264`; it is not the Windows download.

## Limitations and continuation

Creature/form and unsupported ancestry silhouettes use labelled neutral humanoid LPC fallbacks. Large size/reach remains within one actor per tile. No flight, climbing, aquatic travel or dark-vision gameplay is claimed. Perception buffs are limited to supported initiative/Will effects. Repertoires, prestige caps, companion limits, AI/encounter breadth and noncombat skill integration remain bounded. High-level fixture victories are not a balance judgement. Human playtest remains useful after the authorised automated integration.

The matrix retains720 taxonomy rows/760 indexed occurrences. Natively validated bounded first-occurrence adaptations increase54→62;698 occurrences remain unplayable. Original heritage variants are not counted as unrelated completed source concepts. #82–87 remain OPEN and the programme is unfinished.

Recommended next character wave: distinct Erudite with persistent unique-powers-per-rest limits and Divine Mind with maintained auras, followed by broader prestige/ancestry/feat coverage and real character-skill checks in existing noncombat activities. Dedicated LPC anatomy belongs to its separate art work. No new world/quest/map system is introduced here.
