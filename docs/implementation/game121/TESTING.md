# GAME-121 playtest instructions

Use the self-contained Windows package linked in DELIVERY.md after native verification. Extract both ZIP layers completely and run `road-has-gone-dark.exe`; keep `worldgen-helper` and artwork beside it. No Godot/Node installation is required. Escape skips the intro. For source review, open `res://scenes/ui/main_menu.tscn` in Godot4.6.3, or run the project normally.

1. New Game → generate/select a world → origin → hometown → create and save three real adventurers → Party ready → enter hometown. Existing saved campaigns use Resume instead; retain their original pins and saved history.
2. At home choose **Seek new leads**. Four current reports appear on the existing regional map. Choose one, **Set out**, scout if rumoured, then travel to its site.
3. Compare careful recovery/investigation, quick partial work, peaceful access, skill contributions and combat where offered. Full successful objectives grant10 XP to each character once. Partial assessment, failed checks, inspection, withdrawal, travel/rest and seeking reports grant0. Skill labels show the actual briefing bonus/DC; contributions offer lower provision costs with a deterministic failure risk. Combat is a single objective award, not a second bonus.
4. Return home & rest. The home panel shows XP and the next level threshold. **Characters → Advance** previews and commits legal class, skill, feat, attribute and specialisation selections. **Spellbook** prepares actual Wizard/Cleric/Druid spell copies or selects known spontaneous spells using the original class mechanics.
5. Finish all four reports; **Seek new leads** records another set without replacing the old results. **Adventure journal → Older/Newer reports** reviews completed consequences. Returning home before completion leaves that same report available; it is not silently respawned or rerolled. Finished battles, failed objectives and explicit withdrawal are terminal attempts.
6. Earn25 full objectives (250 XP) for level6 under the current core policy. For the demonstrated prestige path choose Rogue at1/2, Wizard at3/4/5, keep Arcana/Stealth ranks at least4, and prepare/use genuine Wizard spells. At6 choose **Arcane Trickster** and its Wizard casting track after reviewing requirements. The first prestige power is a real limited-use tactical action. Other paths have different earned prerequisites: tested Duelist/Mystic Theurge entry at7 (360 XP) and Eldritch Knight at8 (490 XP).
7. Quit to menu/exit, relaunch and Resume. Verify exact identities, multiclass order, feats, choices, spell preparations, earned XP, previous objectives and unfinished/battle positions. A fully completed event must not grant a second reward.

## Review evidence

Requested captures: new leads, completed objective, home XP/threshold, actual earned level preview/sheet, prestige entry prerequisites, earned prestige history, real spell/prestige combat and fresh-process reload. Capture the normal production scenes; no authored image substitute or fixture XP grant. Screenshots and raw proofs are retained in this directory once verified.

## Automated verification

`python tests/adventure_cycles/run-tests.py --output <owned directory>` runs real legacy-save extension, duplicate/corruption/journal tests, an earned prestige journey and a new-process reload. Set `GODOT_BIN` to Godot4.6.3 and use the existing verified helper setup. The runner creates only isolated review campaigns and rejects any ERROR/SCRIPT ERROR despite a zero process exit code. `source-pins.json` protects all historical rules/XP packs and unchanged tactical authority.

`tests/adventure_cycles/review.tscn` is an isolated diagnostic entry used in native export verification. It runs the same production save/choice/advancement services; it does not insert XP, grandfather high levels or appear in the normal player menu. Parent GAME-103/104/118/119, original V1/V2, GAME-32 and responsive/input regressions remain enabled in CI.

Known limits to assess: seven reused activity templates, one/two humanoid bandits with basic AI, encounter level cap12, skills taken from the saved party briefing until the next cycle, hometown-only context and no measured human high-level pacing. Core13–20 and the wider character catalogue remain future batches.
