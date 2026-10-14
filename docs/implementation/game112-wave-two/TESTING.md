# Wave Two verification and human review

## Launch and normal journey

Extract the outer GitHub artifact ZIP, then the playable Windows ZIP. Keep the executable, worldgen-helper, artwork and notices together. Launch road-has-gone-dark.exe; no installed Node or Godot is required. Escape skips the intro. Source entry remains `res://scenes/ui/main_menu.tscn`. The verified build and SHA-256 are recorded in DELIVERY.md.

New Game → world → origin → hometown → creator. Fresh campaigns automatically use v12; existing campaigns retain their exact original pins. Race & class offers23 base adaptations/21 families. Build → Specialisation selects the Druid wolf/bear companion at1 or Ranger companion at4. Choose skills/feats/equipment and review the numerical Sheet. Wizard/Cleric/Druid can choose Summon sentinel in the spell preparation controls, assigning a real prepared copy. Save three adventurers → Party ready.

Seek leads → contextual opportunity → travel → fight. Permanent companion turns are marked C and temporary summons S. On each creature turn use ordinary Move/Attack. It has its own HP, status, movement/main tokens and shared reaction. Summoning consumes the caster's main action, tier-one slot and prepared copy; one active summon per caster, first clear adjacent tile, bounded global-round duration. Dismissal consumes a main action. Duplicate summons/no free placement are rejected atomically without spending resources. Player control is direct; the existing deterministic nearest-target command policy also supports owned actors in diagnostic/gameplay tests.

Druid5 can choose Wild shape: bear/wolf. Size metadata, Strength/Dexterity, natural weapon, movement/reach and equipment contribution change; spells are suppressed. Existing HP/damage/conditions and original identity/ancestry remain. Revert costs a main action and never heals. Expiration/home recovery removes transient forms. Bear/wolf/sentinel/centaur etc use explicitly labelled humanoid LPC artwork fallbacks. No flight, aquatic, climbing or darkness functionality is claimed.

Complete objectives for earned XP once, return home → Characters → Advance; restart/Resume verifies saved careers, choices, companion health and rewards. Druid/Ranger companion growth preserves accumulated damage and scales differently; ordinary home recovery restores creatures through the same campaign authority. No production XP grant button exists.

## Distinct new careers and prestige entry

Crusader: persistent stance, chosen ready manoeuvre at8, two readiness charges, main-action recovery; restoration/guarding and higher allied renewal/radiant attacks. Swordsage: stance/manoeuvre choice, readiness/recovery, disruption, fire, mobility recovery and concealment. Wilder: finite psychic points, deliberate four-point surge with self-Weakened drawback, later control/augmentation. Binder: one persistent ember/sentinel covenant and daily commitments, later actual sentinel/form powers. All four tracks and the previous eight alternative tracks have bounded executable progression through20. These are original adaptations with small repertoires, not complete sourcebook implementations.

Warshaper (5): total level≥5, BAB≥4, permanent Druid shape feature. A normal Druid6 qualifies for entry at total7, requiring360 earned XP. Features strengthen actual body forms and natural weapons. Bonded Summoner (5): total≥5, arcane casting≥3, Arcana ranks≥4; Wizard5 can enter at total6/250 XP. Features provide bounded, progressively longer sentinel summons. Temporary grants/forms do not replace permanent entry history.

## Automated checks

Set GODOT_BIN to the pinned4.6.3 engine, GAME76_HELPER_ROOT to a verified matching offline helper and XDG data/config/cache to owned directories for source runs. Run `GAME112W2_TEST_ROOT=/owned/output python tests/character_entities/run-tests.py`. It executes mechanics, a separate mechanics-restart process, real campaign/journal/earned advancement, and another campaign restart; every engine error fails despite zero exit status. Native `verify-package.py` exports the same game, runs both phases with empty PATH and no source-helper override, then launches the production executable and packages all required resources/notices.

The Wave Two Windows/Linux workflow also retains GAME32 frozen oracle/migration, GAME103/104/118 creator/content/default/input checks, GAME119 careers/prestige, GAME121 actual earned prestige/cycles, the historical Wave One content matrix and original opportunity/First Adventure/UI tests. Historical byte hashes stay frozen. Twelve explicit v12 source adapters reconstruct the exact integrated pre-wave combat source before applying its unchanged earlier legacy projection; this registration is not a substitute for the behavioural oracle.

High-level/prestige/multiclass fixtures are labelled development data, independently saved through the original writer. They prove mechanics without pretending those levels were ordinarily earned. Actual level-two advancement is earned through completed objectives. See SCREENSHOTS.md for actual Godot renders at640×360,1280×720,2560×1440. Windows CI is headless native verification, not human desktop/GPU acceptance.
