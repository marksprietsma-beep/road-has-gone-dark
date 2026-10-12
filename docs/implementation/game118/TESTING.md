# Current continuation review

Use the Windows package and exact fresh/legacy test route in [DELIVERY.md](DELIVERY.md). Latest content is v6: nine race families, fourteen heritages, eleven core classes through eight and twenty-six feats. An ancestry edit can change Skills and Spells budgets; Review incomplete build explains and links the required choices. The following original v4 instructions remain historical guidance for that pinned batch.

# GAME-118 player review

Download/extract the complete Windows archive, preserving the executable, worldgen-helper and artwork folders. Launch `road-has-gone-dark.exe`; Escape skips the intro. No Godot or Node installation is needed.

1. Select **New Game**, generate/select a world, choose region/state and hometown, confirm. The first creator tab must visibly offer **Class** and **Race / ancestry** without any content opt-in. Open Class to see Barbarian, Bard, Cleric, Druid, Fighter, Monk, Paladin, Ranger, Rogue, Sorcerer and Wizard.
2. Create a Dwarf Fighter, Half-elf Rogue and Elf Wizard. Choose compatible heritage/background independently. Class changes provide editable starting recommendations. In **Build → Attributes**, change CON and confirm the score swaps with its previous owner; Sheet must show the same base/final scores and HP adjustment.
3. Review **Build → Skills/Feats/Equipment/Spells/Progression**. Illegal equipment/over-budget choices cannot save. Wizard spells use preparation copy counts; Sorcerer/Bard use known-spell checkboxes. Review Sheet's numerical traits, actual abilities and resources. Edit a name/background and check the pending biography before saving each adventurer.
4. Save all three → **Party ready** → **Enter hometown** → contextual opportunities. Select a contested site, accept the lead, scout if necessary, travel, fight. Movement/attacks remain orthogonal and use the existing action economy. Spell/technique buttons show remaining uses/copies/slots. Exhausted or unprepared powers cannot cast.
5. Win, return to regional play, return home. **Characters → Advance** now shows the real earned 10 XP meeting the core level-two threshold. Review skills and any scheduled bonus/general feat, commit one level. Current HP/resources are retained, not healed by advancing.
6. **Spellbook** at home can reallocate prepared copies within each tier's capacity. It preserves total remaining slots and cannot forget existing spontaneous known spells. Exit, relaunch and Resume: identities, class history, traits, equipment, preparations, resources, XP and results must persist.
7. Continue an older campaign too. Its old class options and exact rules/XP policy must remain unchanged. Do not delete saves or use an upgrade configuration.

Source scenes: `scenes/ui/party_creation.tscn`, `scenes/ui/character_sheet.tscn`, `scenes/gameplay/expedition.tscn`, `scenes/combat/first_adventure.tscn`. The creator requires the normal origin handoff; start from `scenes/ui/main_menu.tscn` for the real journey.

Automated gates: `tests/character_core/run-tests.py` (core creation/progression, equipment, score input, prepared exhaustion, tactical abilities, Evasion and deterministic replay); `tests/character_core/review.tscn` (real New Game/UI journey, all eleven created classes over six hometowns, genuine spell casts, three earned level-ups, legacy continuation); separate restart invocation; frozen GAME32, previous packs, original builder/adventure and GAME83 checks. The native verifier exports production plus a temporary diagnostic from identical source, runs with empty PATH and only the bundled helper, restarts, launches production, and removes diagnostics before packaging.

Provide screenshots of first-open creator, open class list, ancestry traits, mechanical sheet, spell preparation, progression/earned level, combat and return. Real Godot renders at 640×360, 1280×720 and 2560×1440; no synthetic UI images.
