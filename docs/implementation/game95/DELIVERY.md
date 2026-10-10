# GAME-95 Windows playtest delivery

[Draft PR #74](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/74) targets draft #73's `feature/game-94-lpc-character-presentation`. PRs #71–#74 remain open and unmerged.

**Download:** [game95-windows-x64](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37954669406/artifacts/11628051906). GitHub sign-in/repository access may be required. The Actions artifact contains the playable ZIP and checksum; it is not a source checkout. It expires **8 November 2026, 16:02 UTC / 9 November 2026, 00:02 China Standard Time**.

**Successful native Windows workflow:** [run 37954669406](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37954669406). [Complete native evidence artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37954669406/artifacts/11628431036) is also available.

**Build source commit:** `4b430aef7638dcfbd54a971b393353761e5106fc`. Subsequent delivery/evidence commits change documentation only; the binary is built from this exact tested source.

Implementation commits:

- `1c1af9d717ebda7735b72d78c31e9ec90a4d2662` — immutable registered battlefield sizes and backwards-compatible pins.
- `12293417dd71b2cf748a8a63580e3feb81e31697` — party paper dolls, presentation pacing and authored roadside rendering.
- `4b430aef7638dcfbd54a971b393353761e5106fc` — independent authority/visual proofs, rendered evidence and Windows packaging.

**Inner playable archive:** `game95-old-road-windows-x64.zip`, 119,980,427 bytes.

**SHA-256 of that inner archive:**

```text
1aee52d5f25f8a268cccc526cdf473bb8929fae15cf150a89075d11088a7a746
```

GitHub's outer artifact digest is different; the checksum above applies to the actual playable ZIP inside the downloaded artifact. [Checksum file](evidence/game95-old-road-windows-x64.zip.sha256) and [independent archive audit](evidence/archive-audit.json) are retained in the repository.

## Extract and launch

1. Download the `game95-windows-x64` Actions artifact and extract its outer ZIP.
2. Extract the contained `game95-old-road-windows-x64.zip` completely into a writable folder.
3. Open the `game95-old-road-windows-x64` folder and launch **`road-has-gone-dark.exe`**.
4. Keep the `worldgen-helper`, `artwork`, notices and `START-HERE.txt` beside the executable. Do not run it inside a compressed-folder preview. No Godot, Node.js or separate artwork installation is needed.

Optional PowerShell checksum verification before extraction:

```powershell
(Get-FileHash .\game95-old-road-windows-x64.zip -Algorithm SHA256).Hash
```

Existing campaign saves remain in `%APPDATA%\Godot\app_userdata\Road Has Gone Dark`. A previously saved in-progress 8×6 battle resumes its exact original board. A campaign that has not begun its battle starts the new 12×8 Old Road. The registered 10×8 layout is available/tested for authored definitions, not exposed as a new player size menu. To review the new map if your existing fight is already completed, start a separate New Game without deleting old saves.

## Exact playtest path

1. Escape skips the intro. **New Game → generate/select world → origin state → region → hometown → Confirm origin**.
2. In **Party Creation**, inspect all three LPC thumbnails with names/people/callings. Select with mouse or arrow keys. Use existing editors to choose Vanguard, Scout and Adept for the demonstrated composition; save changes, then **Party ready → Enter hometown**. Preview equipment must match those characters later in combat.
3. **Prepare first adventure → select a local account → Accept → Begin expedition → Scout if needed → Travel → Fight**.
4. Inspect the 12×8 worn road, verge, trees/rock, milestone, cart and shallow ditch. Lower-right crosses mark blocked cells. Scrub/ditch/road use ordinary movement: no new cover or terrain-cost rules.
5. **Move → dotted tile**, then watch actual tile-to-tile travel. **Attack/ability → highlighted target**; watch anticipation, release/projectile, hit/miss feedback and HP/down response. The following action unlocks after the bounded presentation beat; **End turn** advances normally. LPC is the sole provider; F7/four-style selection remains retired.
6. Use **Main menu → Resume Expedition** during or after a visual beat. Saved positions, resources, log and results must remain identical; visual timers do not persist. Verify an old 8×6 save separately if available.
7. **Victory or Withdraw → Return to regional play → Return home**. Inspect the remembered result and companion history. Victory awards the existing XP placeholder; defeat does not.
8. Review at 640×360, 1280×720 and 2560×1440. At the smallest size, the right-hand details scroll and sprites are smaller; board, targeting and footer controls should remain accessible.

In the editor, open `scenes/ui/main_menu.tscn`, or run the normal project. [Implementation documentation](README.md) contains the before/after images, all supported map/resolution renders, seven animation GIFs and regression commands. Useful feedback includes a screenshot, resolution, actor/action/target, visible battle log, whether the issue survives menu resume, and whether movement or action recovery feels too slow/fast.

## Verification and limits

Native Windows CI built with official verified Godot 4.6.3/templates and the compatible Windows offline helper. The exported diagnostic uses the same production controllers/resources with an isolated entry point; the playable executable retains the ordinary intro/main-menu entry point. Diagnostic executables are removed from the final ZIP.

- Native exported full journey passed **237 checks, zero failures**, with empty PATH/NODE_PATH and no source helper override: fresh world, origin/hometown, generated party editing/preview, preparation/expedition/site, old 8×6 save/command/menu resume, new 12×8 encounter, victory, explicit defeat and persisted return-home consequences.
- Native registered-map/preview/timing rig passed **3,366 headless checks**. Its exact three layout initial/final/RNG replay results, all three generated appearance recipes and all seven animation command/before/after hashes equal the Linux rendered proof. Full fresh-world runs use different random campaign IDs; their whole-campaign hashes are therefore not compared as if they were identical fixtures.
- First Adventure combat/campaign create/restart, frozen GAME-32 kernel/migrations, GAME-83 presentation, LPC animation isolation, original-source integrity and separate-process presentation preference all passed on Windows.
- The ordinary production executable launched successfully on Windows. Independent download audit verified ZIP CRCs, checksum, AMD64 game/helper PE headers, all **291 original artwork resource hashes**, licences/notices, executable hash, absence of QA executables and exclusion of retired comparison art.

[Raw Windows journey proof](evidence/windows-proof.json), [native log](evidence/windows-native.log), [registered layout/action proof](evidence/windows-game95-proof.json), [source test timings](evidence/windows-adventure-timings.json) and [archive audit](evidence/archive-audit.json) are retained.

Native Windows automation uses the headless driver. Actual screenshots/GIFs use Linux Godot/Mesa rendering; human Windows desktop/GPU review and pacing assessment remain necessary. The short automated production shutdown emits the inherited Godot ObjectDB cleanup warning; no script errors or failed gameplay checks occurred. This is an unsigned review executable. The map is one authored roadside approach, not a procedural reconstruction of all world terrain. Broader terrain families, final ancestry artwork, sound and gameplay expansion are outside GAME-95.

No blocker prevented the self-contained build. Stop at human review; do not merge this PR or its parents automatically.
