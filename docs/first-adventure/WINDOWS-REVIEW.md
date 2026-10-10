# First Adventure + GAME-83 Windows review

This review continues PR #71. No combat rules or character-life architecture were changed. The gameplay commit is `105f7e4`; presentation is committed separately in `e6229aa`, with the targeting label fix in `bb6563e`. Windows packaging/verification is in `036b859` and `e0727fb`. PR #71 stays draft for human review.

## Integration audit

GAME-83's PR #67 is open, but its implementation (`60d573d` and subsequent fixes) is already an ancestor of this branch. There is no integration merge to perform. Main remains behind these implementation branches.

The existing `GameUI` shared theme, `responsive_canvas`, `ChoiceRow`, primary/quiet actions, sections and metadata labels are reused directly. Onboarding and the GAME-83 party editor remain intact. The expedition map continues using its public geographic projection and compact markers.

The V0 companion paragraphs obscured local accounts. The hometown now presents an objective, discoverable leads and compact name/class/background rows; click one to reveal motivation, hook, relationship and history. Preparation and combat entry use existing primary-action styling.

The combat screen now prioritizes the active character and ready/spent action tokens. Reachable tiles and eligible targets have distinct outlines, hover text explains the tile/unit, and the gold active-unit border remains visible. Turn order trims with its full text in a tooltip. The action panel scrolls and the footer remains outside it at 640×360, 1280×720 and 2560×1440. No second UI theme or component framework was created.

## Verified build

[Download Windows x64 review build](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37798817180/artifacts/11559634721) · [successful Windows run](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37798817180).

Built from `bb6563e2fc097441305398ecbd9df6bc266aea1b`. The player artifact expires on **7 November 2026**. The inner application ZIP is also available locally at `/workspace/artifacts/first-adventure-windows/first-adventure-windows-x64.zip`.

SHA-256 of **`first-adventure-windows-x64.zip`** (the inner application archive, not GitHub's outer artifact ZIP):

```text
46ae343e0a070c90b8128c40c81878b8b776d754d3b5ad72893dec519c9e768b
```

The archive was independently downloaded and verified against the producer's checksum. ZIP CRC checks passed; the executable is an x64 PE binary and matches its recorded SHA-256. All 6,748 package entries were checked, including the bundled Node executable, helper manifest and launch guide. The diagnostic executable is excluded from the player package.

## Launch and play

Download the **first-adventure-windows-x64** artifact from the successful review run linked in the build record. Extract the GitHub artifact ZIP, then extract its inner `first-adventure-windows-x64.zip`. Open the extracted `first-adventure-windows-x64` folder and double-click **`road-has-gone-dark.exe`**. Keep **`worldgen-helper`** beside it. This package includes game resources, the matching Windows x64 Node runtime, generation/enrichment/local-map dependencies and their notices. No separate Godot or Node installation is required.

Escape skips the intro. **New Game → Generate New World** (or select a bundled world) → choose state, region and hometown → **Confirm origin** → configure three companions → **Party ready → Enter hometown**.

Click **Prepare first adventure**, select a local account, then **Accept local lead → Begin expedition → Scout** if needed → **Travel to the site → Bandits on the Old Road · fight**.

During a player turn choose **Move**, then a dotted tile, or an attack/ability, then a highlighted target. **End turn** continues the order. Victory or **Withdraw · defeat** leads to **Return to regional play → Return to hometown**. Click a companion row to inspect the remembered result. **Main menu → Resume Expedition** restores a saved battle.

Saves are under `%APPDATA%\Godot\app_userdata\Road Has Gone Dark`. The review diagnostic uses an isolated test profile; no test save is included in the player archive.

## Evidence and review scope

The rendered walkthrough uses the actual production New Game, origin, party, expedition and combat controllers. Only its Generate button receives a fixed review seed. It generates a fresh world, sets the three showcase roles through the existing editor operation, plays through victory and menu resume, and tests withdrawal/defeat in an isolated copy of that campaign. It captures all requested screens; both outcomes reload and return correctly. Rendered screenshots are from Linux/Mesa, not Windows screenshots.

The native Windows diagnostic uses the same production controllers and their button signals, inside a release export. A fresh save/library directory, empty PATH and removed source-helper override ensure that generation and expedition content use the helper packaged beside the executable. A separate production executable launch verifies its normal intro entry point. These Windows checks are headless; desktop/GPU behavior and encounter feel remain the human playtest.

The final rendered walkthrough passed **180 checks**; the native Windows release diagnostic passed **160 checks**, with empty PATH and no helper override. The 173 Windows combat/campaign checkpoint checks passed, as did the 216-check Linux regression suite and 20 GAME-83 shared-presentation checks. Source proof, native Windows proof, timings and artifact checksums are in [windows-review](windows-review/). The minimum-size targeting hint initially clipped its font; an explicit line height and viewport assertion fixed it. No gameplay blocker remained in the tested flow.

Screenshots:

- [Party editor](windows-review/screenshots/party.png)
- [Compact companion preparation](windows-review/screenshots/party-prepared.png)
- [Expedition objective and geography](windows-review/screenshots/expedition.png)
- [Combat at 640×360](windows-review/screenshots/combat-640x360.png)
- [Combat at 1280×720](windows-review/screenshots/combat-1280x720.png)
- [Victory result](windows-review/screenshots/results.png)
- [Defeat result](windows-review/screenshots/defeat-results.png)
- [Remembered history at home](windows-review/screenshots/returned-home.png)

For feedback, report the Windows version, window size, reproduction actions and a screenshot/log for any blocker. Focus on whether the party feels identifiable, the next action is obvious, targets are readable and tactical decisions are interesting. XP, rescue and pending consequence hooks retain their existing V0 meanings.
