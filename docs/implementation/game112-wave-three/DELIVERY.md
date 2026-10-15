# Wave Three delivery — verification in progress

**Current status:** full run38610375101 failed both native catalogue restart jobs. The isolated v13 canonical-key repair and focused Linux native restart passed; earned-prestige acceptance and independent Windows focus/full verification are now being completed. Earlier counts below are historical evidence, not final-release validation. See NATIVE-HASH-REPAIR.md. No merge or final Windows build is claimed.
Draft PR: https://github.com/marksprietsma-beep/road-has-gone-dark/pull/98

Gameplay implementation checkpoint: `29809cca063f56a83b22e9032614de373b5f174f`; spell-suggestion correction: `c805ae88d53c0faac5153ac8227110d59db50803`. Candidate pack `trhgd-character-v13`, content hash `e6c2a203f9930033922a1551c4d86edd0672f698eceee5eae2bbeb806d1193aa`. Historical v1–v12 content is unchanged. New campaigns default to v13; existing campaigns retain exact original pins.

## Content

| Category | Before | Candidate after |
|---|---:|---:|
| Base careers, levels 1–20 | 23 | 25 |
| Prestige paths | 10 | 12 |
| Ancestry families | 21 | 25 |
| Heritage records | 30 | 34 |
| Feats | 45 | 50 |
| Skills | 14 | 14 |
| Selectable psychic powers | 0 | 21 |
| Creature definitions | 3 | 8 |
| Career-choice groups | 66 | 133 |

New base careers are Ardent and Lurk. New prestige paths are Beast Steward (the researched Beast Heart Adept concept, using an original production identity) and Cerebremancer; both have five playable implementation levels under verification. Four new ancestry adaptations are Elan, Xeph, Maenad and Dromite. These are bounded original adaptations, not complete sourcebook conversions. All25 base tracks cap at20. Prestige caps are5 for Duelist, Eldritch Knight, Arcane Trickster, Mystic Theurge, Warshaper, Bonded Summoner, Beast Steward and Cerebremancer;10 for Shadowdancer, Dragon Disciple, Dwarven Defender and Pyrokineticist. The21 selected powers span tiers1–9 with authored augmentation variants; this is a limited repertoire, not every sourcebook power.

Powers known derive from persistent ordered career selections. Authored augmentation variants spend their actual additional points and cannot exceed shared manifesting level. Psion/Ardent/Wilder contribute two points per class level; Psychic Warrior/Lurk contribute one, with one shared base allowance of two. Shared save attunement uses the best mental modifier among owned manifesting classes. Psychic Warrior and Ardent use Wisdom, Psion/Lurk/Cerebremancer Intelligence, Wilder Charisma. Ardent mantles restrict access and grant distinct capabilities. Lurk consumes a prior veil and separate finite ambush focus; the melee attack remains independently rolled.

Leopard, Boar, Stag, Stone Guardian and Renewal Spirit add distinct natural attacks, movement, defences and effort-costed actions. Druid/Ranger have five permanent animal choices. Prepared summons spend matching slots/copies; psychic summons spend points, and augmentation extends duration. Existing one-permanent/one-active-temporary limits, legal placement, turn ownership and round expiry remain authoritative. Three additional forms change physical attributes, natural attacks and tactics while preserving health/identity and suppressing spells and psychic actions.

## Actual verification

- Local frozen GAME-32: 22,181 kernel assertions,235 migration-create checks and six fresh-process migration reload checks passed. No frozen oracle changed.
- Final candidate source: 1,646 mechanics checks with zero failures; six mechanics-restart checks passed. All25 base tracks advanced to20, every advertised power variant executed, both new prestige histories qualified/advanced, and negative eligibility/resource/form/ownership cases were checked.
- Source ordinary campaign:169 journey checks, zero failures,40 genuinely earned XP and level-two advancement. Separate-process campaign reload passed. Advanced fixtures are separate, explicitly labelled development saves; their levels were not earned in that journey.
- Native Linux sourcec805ae8:1,742 mechanics and177 journey checks, zero failures; six mechanics-restart checks and separate campaign restart passed,30 earned XP. QA ran with empty PATH and no source helper override; production startup was separately checked.
- Real Godot review render harness:254 checks, zero failures,93 renders across640×360,1280×720 and2560×1440. It exercised actual selector input without state/RNG changes, augmented barrier/summon costs, summon turn/expiry, Lurk veil/ambush, two body forms, two creature actions and both saved prestige paths. A focused creator capture added15 checks/zero failures. Render shutdown emits an ObjectDB cleanup warning; raw evidence retains it.

Linux package SHA-256: `edd8ee71179209e438d2c1386fad8790acbfd998a24b74adf4331406e0112264`. Local archive: `/workspace/artifacts/wave-three/native-linux-delivery/distribution/game112-character-catalogue-wave-three-linux-x64.tar.gz`. This is not the Windows delivery.

Full Windows/Linux verification is still pending. Initial Linux CI reached the earned-XP suite and rejected the authorised new manifest append with its whole-file hash guard. The correction preserves the original baseline/hash and checks exact historical rows plus valid appended content; nine negative/positive pin tests pass, including explicit UTF-8 decoding independent of the Windows default codepage. No legacy pack hash or tactical source pin was changed. Local earned advancement then reproduced a real suggestion overflow at Wizard advancement (451 checks/one failure). The v13 suggestion helper now respects distinct-repertoire and tier-slot limits;96 additional caster checks passed through20. The corrected local earned journey passed1,119 checks/zero failures, earning370XP across ten cycles and entering Arcane Trickster at250XP; four separate-process restart checks passed. The rebuilt native Linux package passed as recorded above. Subsequent CI reproduced two harness issues: Windows default-codepage JSON decoding changed calculated pins, and the older catalogue harness assumed automatic Psion techniques which v13 replaces with saved learned powers. Both corrections preserve historical pins and retain ownership/accepted-command/exact-state assertions. The latest full run is https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38610375101 . No final Windows artifact or merge is claimed yet.

## Testing and limitations

Extract the GitHub artifact ZIP and then its playable ZIP. Keep all files together and run `road-has-gone-dark.exe`; no installed Godot/Node is needed. Escape skips the intro. New Game → world/origin/hometown → select races/classes → Build/Specialisation/Powers → review sheet → save three adventurers → ready party → seek an opportunity → travel/fight → return home → earned advancement → exit/Resume.

Combat: choose a learned power, select its augmentation and click Manifest/select a legal target. The selected variant updates targeting; it never spends resources merely by changing the selector. Rest at home restores eligible reserves. Lurk must veil before ambushing with equipped melee gear. Companion/summon actors have ordinary turns; summons expire and cannot be duplicated. Druid transforms/reverts using existing actions. Temporary HP remains until consumed/rest; associated timed defensive statuses expire independently.

Creature/form and unsupported ancestry silhouettes use labelled humanoid LPC fallbacks. Large size/reach remains within the existing one-actor-per-tile authority. Perception buffs are limited to supported initiative/Will effects; no flight, climbing, aquatic travel or dark-vision gameplay is claimed. Combat AI/world encounter breadth and noncombat character-skill integration remain limited. High-level fixture wins are not a balance judgement.

The canonical matrix retains720 taxonomy rows/760 occurrences. Eight new rows remain implemented rather than playable until final native Windows/Linux validation. The previously verified54 first occurrences remain playable; none of the706 remaining occurrences is silently removed. #82 and related programme issues remain open.
