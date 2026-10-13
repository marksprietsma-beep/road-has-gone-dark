# GAME-103 Windows character-builder review

Draft PR: https://github.com/marksprietsma-beep/road-has-gone-dark/pull/80

Branch: `feature/game-103-character-builder`, from main `a47f972`.

**Packaged implementation source:** `9e4dd2502d24aeab4943b00be3bc7a9f1517494b`.

[Download complete Windows x64 artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38151463856/artifacts/11707323484)

Playable ZIP: `game103-character-builder-windows-x64.zip`.

SHA-256:

```text
296f18b07879a434e36f1ce14eed56f1de27bb1f096d648bd76679f6f44c6f46
```

The artifact was downloaded independently after native Windows validation. Its checksum matches both the published checksum file and native distribution proof; ZIP integrity and 7,059 packaged files were checked. It contains the production executable, bundled Node/worldgen-helper, original LPC artwork/credits/licences and the separately readable creator policy. The diagnostic executable is removed. GitHub login with repository access is required; workflow artifacts retain the package for 90 days.

## Extract and launch

1. Download and extract the GitHub artifact ZIP.
2. Extract the enclosed playable ZIP completely.
3. Open `game103-character-builder-windows-x64` and run `road-has-gone-dark.exe`. Keep all sibling files, artwork and worldgen-helper folders together. No installed Godot, Node or separately downloaded artwork is required. This is an unsigned review build.
4. Escape skips the intro. New Game → world → origin → hometown → individually build/save all three adventurers → Party ready → Enter hometown. Identity, Build and Sheet tabs expose actual choices and live GAME-32 statistics. Recommendations are optional.
5. Explore opportunities → travel → fight → return home. Characters opens the permanent sheet; combat Sheet shows active resources. Advance requires being home and actual journey XP: 20 total for level 2, 80 for level 3. No production XP/level grant exists.
6. Relaunch and Resume Expedition to check persistence. Continue existing campaigns without deleting, resetting or recreating them. Old ready parties without mechanics also retain their identities and use the existing rules-preparation path on entering the hometown.

Detailed keyboard/mouse, build and advancement steps: [TESTING.md](TESTING.md).

## Verification and source correspondence

[Windows/Linux native workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38151463856) passed both platform jobs. Each exported runtime passed **773 journey checks and 30 fresh-process checks**, with an empty PATH and no external helper override. These include new player-created parties, actual generated worlds, combat/return, earned legacy multiclass advancement, and pre-GAME32 ready-party preview/hometown compatibility. Production launch also passed. See [VALIDATION.md](VALIDATION.md) and committed raw native proof/timing JSON in `evidence/`.

Later changes only correct an obsolete render-test assertion and add delivery evidence/documentation. Production scripts, scenes, data, artwork, themes, helper/tool sources, project settings and export presets remain identical to packaged source `9e4dd25`; this was checked with git diff. The shared-theme origin label remains readable and within the viewport; the existing rendered-ink check is retained. The complete actual mouse/keyboard/render journey passes 111 checks.

Screenshots in [screenshots/](screenshots/) are real Godot renders at 640×360, 1280×720 and 2560×1440, including creation, equipment/feat controls, permanent sheets and earned multiclass history. Visual evidence uses Linux Mesa; native Windows game/UI execution was headless. Human Windows GPU/gameplay review remains the stopping point.

## Current content and limits

Three original base classes are selectable: Roadwarden, Wayfinder and Lantern Adept. Veil Adept is a real prerequisite-gated kernel prestige path. The current finite adventures limit how far earned progression can go; higher-level qualification fixtures are development-only. Some authored abilities are implemented in the rules kernel but not yet wired into V0 tactical controls, and the sheet labels them explicitly.

Eight existing peoples are provisional examples with one neutral heritage each, not a final fantasy ancestry roster. Professions and personal origins are grounded in real world context; current profession choices do not invent extra stat bonuses. Broader class/ancestry/feat content is GAME-104; future skill checks are GAME-105. See [OPTIONS-COVERAGE.md](OPTIONS-COVERAGE.md). No production combat rewrite, world-generation change, inventory framework or full GAME-87 architecture is included.

Keep the PR draft for human review. Do not merge automatically.
