# GAME-93 — Windows x64 review delivery

Draft review: [PR #72](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/72), targeting `feature/first-adventure-vertical-slice` / PR #71. Both remain unmerged.

Build source: `1b95971eccab9d811be60851122e21f1012d3a06`. [Native Windows workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37878939363) verifies the pinned Godot 4.6.3 and Node 24.19.0, packages the offline helper, exports the production executable, and exercises an isolated diagnostic using the same production controllers with PATH empty and source helper overrides removed.

## Verified download

[Download Windows x64 playtest](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37878939363/artifacts/11593463930) · [native Windows evidence artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37878939363/artifacts/11594226001). GitHub sign-in is required. The player artifact expires **8 November 2026, 03:31 UTC**; its exact ZIP and checksum are also retained in the current workspace at `/workspace/artifacts/game93-windows-build`.

Inner player ZIP: `game93-four-art-styles-windows-x64.zip`, **119,524,464 bytes**, 7,239 packaged files.

```text
SHA-256 (player ZIP):
ac96799344975cee3bc0518bdd1a5479cb48a553fcb960373c7e9bdf1a968714

SHA-256 (production executable):
0d861c0cf0f0aeb0d862b25fa0e34be704458c418fad35e67df50b5382a87045
```

The workflow completed successfully. Native Windows exported-package QA passed **237 checks**, zero failures; the production executable launches headless with empty PATH. Both outcomes return home with valid saves, all four providers load, and preference survives two separate exported-program processes. All 481 original distributed resource hashes match. Source Windows regressions also passed: First Adventure 173, art 273 plus restart persistence, GAME-32 22,422 and GAME-83 20. [Native proof](evidence/windows-proof.json), [package log](evidence/windows-native.log), [download audit](evidence/downloaded-archive-audit.json), [checksum file](evidence/windows-build.sha256).

The downloaded archive was independently rechecked: checksum, ZIP CRCs, 481 original artwork hashes, production EXE hash, game/bundled Node AMD64 PE headers and absence of the QA executable. Direct imports of both executables are Windows system DLLs; no separate Visual C++/Node/Godot installation is referenced. This is native clean-profile/headless Windows evidence, not a claimed manual Windows desktop/GPU session.

## Extract and play

1. Download `game93-windows-x64` from the workflow's Artifacts section while signed into GitHub. Extract that artifact ZIP, then extract the enclosed `game93-four-art-styles-windows-x64.zip` completely.
2. Open the extracted folder and launch `road-has-gone-dark.exe`. Keep `worldgen-helper`, `artwork`, licence notices and other supplied files beside it. Windows x64, Windows 10/11; no separate Godot, Node or art download is needed. `START-HERE.txt` repeats the controls.
3. Escape skips the intro. **New Game** → generate/select world → state → region → hometown → confirm → party ready → hometown. Use the existing resume button for an in-progress First Adventure campaign.
4. **Prepare first adventure** → select local account → **Accept** → **Begin expedition** → **Scout** if required → **Travel** → **Fight**. The three actual companions and blade/bow raiders appear on the existing 8×6 board.
5. Use **F7** to cycle Universal LPC → Kenney → 0x72 → Navinius, or select one directly in the top-right control. Choice persists separately from campaign state. **Move** → dotted tile; **Attack/ability** → legal highlighted target; **End turn**. Victory or **Withdraw · defeat** → **Return to regional play** → home/history. Exit/relaunch/resume to check the same style and identities return.

Godot user data remains `%APPDATA%\Godot\app_userdata\Road Has Gone Dark`; `presentation.cfg` stores only the art choice. Existing save schema and gameplay are unchanged. For a completely empty campaign list use a fresh Windows user profile rather than deleting an existing player's saves.

## Contents, attribution and limits

The production EXE embeds game resources. `worldgen-helper` supplies its own compatible Windows x64 Node runtime and world/town generation resources. `artwork` contains original resources from all four providers, the full LPC credits, original CC0 notices/README, `ART-CREDITS.txt` and the SHA-pinned `sources.json`/`styles.json` manifests. The isolated QA executable is removed from the player ZIP after verification. The build is unsigned.

Navinius's genuine WIP library has no bow or staff: those two props are explicitly labelled Godot drawing over its original layers. No other pack substitutes for it. LPC ships 55 selected original animation layers, not the entire enormous generator library; unsupported anatomical forms are visibly neutral humanoid previews. See [provider limits and recommendation](README.md) and [actual screenshots](VALIDATION.md).

Native Windows headless verification demonstrates application launch, generated-world journey, both outcomes, save reload, four resource providers and separate-process preference persistence using the bundled helper. Screenshots and native popup input evidence come from actual Linux/Mesa Godot renders. Windows desktop/GPU behaviour, subjective animation feel and unsigned-executable prompts remain human review items.

## Commit checkpoints

- `de72770`: original four libraries, source manifest and per-layer credits.
- `fda3907`: preserve original art/attribution bytes across Windows checkouts.
- `1b95971`: provider profiles, selector/F7, larger board, animation effects, regression drivers and Windows packaging.

Documentation/evidence is committed separately after package verification. No combat authority, RNG, action economy, diagonal rules, world-generation logic, campaign save writer, ancestry mechanics or parent draft merge is part of this delivery.
