# Character content foundation review

Godot 4.6.3: open `scenes/ui/main_menu.tscn` and press F6. For the packaged game, launch the executable after extracting the entire distribution.

1. New Game → world → origin → hometown → Build your adventurers.
2. Before saving any adventurer, choose **Use expanded martial content · new party only**. This explicitly repins the unconfirmed suggestions; identities and source-world facts remain stable. The button disappears after selection. It is disabled once anyone has been saved.
3. Select each adventurer. Identity offers the current prototype people and optional inherited traits; hover heritage choices for actual modifiers. Culture and personal origin remain separate.
4. Build: search classes, choose Blade Dancer, Iron Bulwark or Road Stalker, review HP/skills and level:value BAB/save progression. Select a legal feat and spend the exact skill budget. Choosing a new class may invalidate a previous class-dependent feat; the builder explains this and prevents saving. Suggested skills are optional. Select legal equipment/preparations, inspect Sheet, then Save adventurer. Repeat for all three; Party ready → Enter hometown.
5. Explore existing opportunities, travel, fight and return. Passive features use the existing Attack/Guard/movement authority. Characters opens the permanent sheet. Actual earned XP and home presence gate advancement; choose another martial path to test multiclassing. No test-only level or XP grant is exposed.
6. Quit/relaunch and Resume Expedition. Class order, appearance, resources, world history and exact content pin must persist.
7. Continue a previous v1 campaign. Its content selection is unavailable, saved class/identity remains unchanged, and original combat/rest/advancement still work. Never reset the user's save.

Current expanded content: six base paths plus one gated prestige path (three base paths newly authored here), fifteen ancestry/heritage records (seven new optional traits), twelve feats (seven new). These are original limited mechanics, not full catalogue coverage. Missing spells, body types, skills/proficiencies and other subsystems remain explicit in AUDIT/PROGRAMME.

## Automated validation

Use the repository's pinned Godot/helper and export-template setup. Keep evidence outside the checkout unless deliberately committing it.

- `python tools/character-content/validate.py`
- `godot --headless --path . --script tests/character_content/packs.gd`
- `GAME32_EVIDENCE=<evidence>/rules python tests/rules/run-tests.py`
- `GAME103_TEST_ROOT=<populated existing builder fixture> python tests/character_builder/run-tests.py`
- `python tests/adventure/run-tests.py --work-dir <evidence>/adventure`
- `GAME101_TEST_ROOT=<generated review fixture> godot --path . tests/character_content/review.tscn`
- Same review command with `GAME101_RESTART=1` validates a fresh process and identical new-pack snapshots.

The review contexts are produced by `python tests/opportunities/run-tests.py --output <fixture>`; it validates ten independent generated worlds and forty contexts, existing V1/V2 campaigns and persistence. Reuse a valid existing fixture for local UI iteration. `tests/character_content/verify-package.py` runs actual exported native creation/combat/return and restart using an empty PATH and bundled helper, launches production, removes diagnostics and hashes the final complete archive. Windows/Linux CI: `.github/workflows/verify-character-content.yml`.

Screenshots must be actual Godot renders. The expanded Build captures scroll to the numerical class explanation at 640×360, 1280×720 and 2560×1440. Human Windows GPU and gameplay acceptance remains necessary.
