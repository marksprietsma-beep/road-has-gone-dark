# GAME-118 regression repair and continuation review delivery

[Draft PR88](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/88) remains stacked on draft PR81/PR80. None are merged. Human acceptance and the full character programme remain open.

## Windows download, checksum and native proof

The refreshed self-contained Windows x64 package and matching SHA-256 file are attached to the [final production-source Windows/Linux release workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38239740437), under **game118-complete-Windows**. The inner playable archive is `game118-playable-core-characters-windows-x64.zip`. The exact artifact link, independently checked checksum and final CI conclusions are recorded in the [PR88 delivery section](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/88). Per-OS native export/restart proofs, source SHA and distribution hashes are retained in **game118-evidence-Windows/Linux** on that same run. Do not substitute the earlier v4 package; its historical delivery is preserved in DELIVERY-CORE-V4.md.

Production/build source: **5c422cee29cc3f61292d834e4ff5c2cac988e630**. Separate commits: bfe808c regression repair, d8b3a4e progression/ancestry/feat batch, 5c422ce spontaneous repertoire edge case. Subsequent test/evidence/documentation changes do not alter production files or installed content pins; equivalence is checked before publication.

Extract the outer GitHub artifact ZIP, then extract the playable ZIP inside it. Run `road-has-gone-dark.exe`, retaining its accompanying artwork/helper folders. No Godot or Node installation is needed. Escape skips the intro. The build is unsigned; native packaging verification uses the bundled helper with an empty PATH.

## Exact player route

1. **New Game → generate/select world → origin → hometown.** Race & class opens automatically with eleven familiar classes and nine ancestry families; no content opt-in. Existing Resume campaigns deliberately keep their original options and pins.
2. Create a Dwarf Fighter, Half-elf Rogue and Elf Wizard. Review **Build → Attributes / Skills / Feats / Equipment / Spells / Progression**, then **Sheet**. Spells show individual prepared copies or known repertoire. Review ancestry bonuses, class features, restrictions and numerical totals; save all three → **Party ready → Enter hometown**.
3. To exercise the repaired case, select a Human Wizard, save it, then select Orc. Inherited INT changes the skill and slot budgets. Save must remain disabled until these choices are legal. **Review incomplete build → Skills → Suggested skill allocation**, then return to **Race & class → Review incomplete build → Spells → Suggested spell selections**. The spell suggestion preserves attributes and equipment. Save, edit the name with Enter, navigate the roster and complete the party.
4. Prepare/scout/travel to a contextual contested opportunity. Enter combat, move, attack and cast the Wizard's prepared spells. Win, resolve consequences and return home. **Characters → Advance** uses actual earned 10 XP to fund level two under the new policy; review and commit each character once.
5. Exit/relaunch/Resume. Character IDs, class history, traits, equipment, spells/resources, XP and campaign consequences must reload. Existing saves are retained: no deletion or silent content upgrade is part of this route.

Production scenes remain scenes/ui/main_menu.tscn, scenes/ui/party_creation.tscn, scenes/ui/character_sheet.tscn and scenes/gameplay/expedition.tscn. More route detail: TESTING.md. Exact scope/handoff: CONTINUATION.md. Root cause: REGRESSION-REPAIR.md.

## Actual local evidence

Final-source creation/progression: **6,868 / 0**; tactical commands and exact state/log/RNG replay: **3,111 / 0**; continuation/feat prerequisites/spontaneous tier learning: **109 / 0**; previous v4 campaign load/sheet/save-byte/reload proof: **15 / 0**. These include 11 classes across 14 heritage records through eight. Published v1–v5 remain installed unchanged; old v4 class cap and repertoire are explicitly checked.

Final-source real Godot/Mesa focused journey: **539 / 0**, one fresh hometown plus original GAME99 continuation, with real combat XP and all three earned level-two characters. Separate-process restart: **10 / 0**. Capture driver: **70 / 0**. Twenty-four actual PNGs under screenshots/continuation/ show first-open UI at 640×360, 1280×720 and 2560×1440, class/race menus, attributes, prepared spells, sheets, new ancestry traits, combat/results, earned advancement and reload. Each has a SHA-256, source revision and dimensions in evidence/continuation/screenshots.json. The earlier six-hometown/full-11-class render passed **1,147 / 0** at d8b3a4e; its only later production change is the class-eight Sorcerer allowance. Final native workflows run the complete six-hometown path on the final source.

The original GAME81 input/render assertions remain, with deterministic Human Wizard → Orc setup for the fresh run and a separate untouched legacy setup. The fresh real-input capture passes **176 / 0**. Proof files retain the actual immutable pins. Final native workflow outcomes and input counts are available in PR88 and the corresponding QA artifacts; CI failures remain failures until investigated, never converted to skipped gates.

## Playable versus researched

Latest fresh content: **9 race families / 14 heritage records, 11 core archetype adaptations through level 8, 26 mechanical feats, 0 prestige classes**. The 403 ancestry / 66 base / approximately 283 prestige research programme is unfinished; no coverage row is counted as a complete playable conversion simply because a low-level adaptation exists.

Higher class levels, full repertoires, parameterised domains/bloodlines/quarries/schools, multiple simultaneous feat grants at overlapping schedules, companions/summons, more substantial transformations and prestige paths remain work. Current finite opportunities constrain organically attainable higher XP; upper-level mechanics use explicit development progression fixtures, while actual play demonstrates earned level two. Goblin/Orc and unsupported body plans have neutral LPC fallbacks, not dedicated completed anatomy. Senses are descriptors on current daylight maps. See CONTINUATION.md for concrete programme priorities; #82 and #83–87 remain open.
