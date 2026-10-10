# GAME-94 Windows review delivery

Draft PR: [#73](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/73), stacked on PR #72 / PR #71. Nothing was merged.

**Download:** [game94-windows-x64](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37932283652/artifacts/11617103059). GitHub sign-in/repository access may be required. Artifact expires **8 November 2026, 12:55 UTC / 20:55 China Standard Time**. This is an Actions artifact containing the playable ZIP and checksum, not a source checkout.

**Build commit:** `c4a5b7c7b55aaffff568e940c04ca9bf75eee61f`.

- Art/assets/attribution: `19caa391f329a9f9797a18cbcf19c48d083271a2`.
- Runtime/integration/tests: `81e56e17b1910268b8870e22e53bf8bf4ba41ec0`.
- Responsive rendered closeup verification: `c4a5b7c7b55aaffff568e940c04ca9bf75eee61f`.
- Later delivery documentation/evidence commits do not change game runtime. The binary is traced to the exact successful build commit above.

**Inner playable archive:** `game94-lpc-v1-windows-x64.zip`, 119,909,010 bytes.

SHA-256:

```text
95b06da6f39238791b65123f1540b64a1a6550b918b93a4aa9d8d49de38249ec
```

Executable SHA-256: `fa34d952d9d84468ecc10e5beee9984406b6322e6fd14fff33ced079ca76c26e`.

## Extract and launch

1. Download the Actions artifact and extract its outer ZIP.
2. Extract the included `game94-lpc-v1-windows-x64.zip` completely into a writable folder.
3. Open `game94-lpc-v1-windows-x64` and run `road-has-gone-dark.exe`.
4. Keep `worldgen-helper`, `artwork`, licences and other supplied files beside the executable. Godot, Node.js and separate artwork installations are not required.

Optional checksum verification before extraction, from PowerShell:

```powershell
(Get-FileHash .\game94-lpc-v1-windows-x64.zip -Algorithm SHA256).Hash
```

Saves remain in `%APPDATA%\Godot\app_userdata\Road Has Gone Dark`. Existing PR #71/#72 campaigns are supported; legacy non-LPC visual preferences default to LPC without rewriting gameplay.

## Exact review path

Escape skips the intro. Choose **New Game** → generate/select a world → origin state → region → hometown → **Confirm origin** → **Party ready** → **Enter hometown**. To compare the demonstrated roles, use the existing party editor for Vanguard, Scout and Adept before confirming. Read their names/backgrounds/hooks; GAME-94 retains these identities.

At home choose **Prepare first adventure**, select a local account/lead, **Accept**, **Begin expedition**, **Scout** if offered, **Travel**, then **Fight**. The existing 8×6 battle presents the persistent party and two raiders.

- **Move** then click a dotted/reachable tile. Watch directional native walking between actual positions.
- **Attack** then click a highlighted enemy: the Vanguard/Expert slash with shortblades; the Scout draws/releases the bow and the projectile travels before hit/miss feedback. Move within legal range first when necessary.
- On the Adept's turn choose **Lantern Spark** and a highlighted enemy to see casting, the restrained spell trace and target reaction. Basic staff attacks use thrust; they retain their original mechanical range. Binding Step/Mending Thread retain their existing Focus rules.
- **Guard** uses the real Vanguard's shield equipment and the existing protection ability. Source layers without a dedicated guard pose hold the matching equipped pose.
- Watch HP change, floating damage and MISS/BLOCKED/RESISTED distinctions. Downed characters play hurt/defeat and stay DOWN. Use **End turn** normally; animation does not change legality or block input indefinitely.
- **Main menu** → **Resume Expedition** restores the exact saved battle and appearances. Leaving during an effect restores the already committed result, not a half-simulated action.
- Victory → **Return to regional play** → hometown: history/event completion/10 XP placeholder remain remembered. Alternatively **Withdraw · defeat** → return/home: failure history remains, with no victory XP.
- **Art credits** opens scrolling attribution at every target resolution. There is one LPC provider; F7 and the old selector are deliberately retired.

Try 640×360, 1280×720 and 2560×1440. Names/weapon/HP remain in existing tooltips and side information; click targets follow logical tiles, not moving sprite pixels. Report any wrong facing, weapon clipping, stale pose/HP or UI overflow with resolution, character name/role, action, screenshot/short recording and the saved campaign. The raw scripted comparison uses the same old generated identities; a new campaign may generate different names/visual recipes.

## Verified delivery evidence

[Successful native Windows workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37932283652) and [downloadable raw Windows proof/logs](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37932283652/artifacts/11617068211).

- Native Windows First Adventure, GAME-32, GAME-83 and LPC source/appearance regressions passed.
- Native live-scene animation checks: **213 assertions**, seven actual resolved-command cases, zero failures. [Windows proof](evidence/windows-lpc-proof.json).
- Exported clean-profile diagnostic: **180 assertions**, zero failures; fresh world generation, party/adventure/battle, exact saved battle resume, victory/home/history and isolated withdrawal/home/history passed. PATH/Node options were cleared and source-helper override removed. [Packaged-game proof](evidence/windows-proof.json).
- Separately launched the actual production executable and tested preference fallback across native processes. [Launch log](evidence/windows-production-launch.log).
- Downloaded ZIP independently passed CRC, all **291** original LPC resource SHA checks, unchanged upstream notice comparison and AMD64 headers for both game and bundled Node. All three retired provider folders are absent. [Independent archive audit](evidence/archive-audit.json).
- Linux rendered proof and Windows source proof have identical generated-party initial hash, appearance recipes and every diagnostic command's before/after battle hash. [Cross-platform proof](evidence/cross-platform-proof.json).

[Before/after screenshots, distinct-character closeups, movement/melee/ranged/staff/spell/miss/defeat GIFs, logs and licensing details](README.md) are committed in this PR. Original source URLs/revision/per-layer licence choices/authors/hashes are in `artwork/sources.json`; full original credits and legal notices are included beside the executable. No generator code was copied; palette/composition adaptations are CC-BY-SA 3.0 artwork.

Human Windows desktop/GPU animation review remains necessary: native automation used the headless driver, and screenshots/GIFs use actual Linux Godot/Mesa rendering. Some missing item animations use explicitly documented held/stowed poses; only two humanlike body families are supplied, with neutral warnings for unsupported anatomy. Minor source seams and the earlier ObjectDB warning at short automated shutdown remain. No blocker prevented the self-contained build or seeded gameplay checks. GAME-95 terrain/dimensions and the later combined visual polish are outside this delivery.
