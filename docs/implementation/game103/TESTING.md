# Human review

Use the complete Windows package linked in DELIVERY.md. Extract the GitHub artifact ZIP, then extract its playable ZIP completely. Launch `road-has-gone-dark.exe` beside its artwork and worldgen-helper folders; no installed Godot or Node is needed. Escape skips the intro. Do not delete existing saves.

1. New Game → generate/select world → origin region → hometown → confirm.
2. On **Build your adventurers**, select the first adventurer. Identity permits name, current ancestry/heritage, separate narrative role, personal origin and compatible profession. A different personal origin does not move the party hometown.
3. Open **Build**. Swap standard-array scores, choose Roadwarden/Wayfinder/Lantern Adept, allocate the exact skill budget, choose an eligible feat, real starting equipment and granted preparations. Optional recommendations are clearly labelled; they are not required. Locked feats/classes explain their prerequisites. A duplicate score cannot be allocated; illegal builds cannot be saved.
4. Review **Sheet**. Change CON to see real HP change; change armour to see defence change. Save adventurer. Repeat independently for the other two; **Party ready** stays disabled until all three are confirmed. Revert edits discards unsaved changes. Tab/Enter and mouse work; scroll each tab for further choices.
5. Ready party → Enter hometown → Explore local opportunities → choose an actual report → Set out → Scout if necessary → Travel → choose combat. The same names, builds and LPC identities must be used. Movement, targeting, action economy and RNG remain existing rules.
6. Resolve combat and return home. **Characters** opens the persistent sheet. Combat **Sheet** pauses presentation and shows actual encounter HP/resources; Back returns to the same fight.
7. **Advance** shows actual journey XP and the next cumulative threshold. Two 10-XP victories can fund level 2 (20 XP). Select a legal class, allocate that level's ranks and any scheduled feat/increase, inspect the preview and commit once. Level 3 needs 80 XP; no free XP or production test levels exist. Locked prestige requirements remain visible. At-home restrictions are explicit.
8. Return to menu, relaunch and Resume Expedition. All party choices, ordered advancement, exact completed opportunities and earned XP must remain. Existing GAME-96/99/101 campaigns should continue with their old party without recreation.

Test 640×360, 1280×720 and 2560×1440 windows. Controls remain above the footer; focused fields are revealed by scrolling. A complete high-level progression campaign is limited by the current four-opportunity content, not bypassed with fake XP.

## Repeatable engineering proof

Set GODOT_BIN and GAME76_HELPER_ROOT to the verified engine/helper. `python tests/character_builder/run-tests.py` needs GAME103_TEST_ROOT (new scratch directory) and runs custom builds, illegal choices, actual deterministic combat, existing-save earned advancement and a second-process restore. `tests/opportunities/run-tests.py --output <scratch>` runs the existing ten-world / forty-context V1/V2 and six-hometown journey regressions. The GAME-103 workflow additionally runs native bundled-helper QA, the frozen combat/save suite and responsive GAME-83 checks on Windows/Linux. `tests/character_builder/review.tscn` extends the real six-hometown UI journey with edited scores/names, responsive creator/sheets and earned legacy multiclass UI; visual renders require a display, with headless execution for native regression.

Development-only prestige fixtures call the kernel directly and never give a campaign XP. Raw JSON/logs and timing evidence are retained in workflow artifacts; screenshots are real Godot renders, not mockups.
