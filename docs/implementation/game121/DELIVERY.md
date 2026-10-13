# GAME-121 review delivery

Status: production implementation, regression workflows and self-contained native Windows/Linux verification passed. Windows package downloaded and independently checked. Human acceptance and draft publication remain pending.

## Source and scope

Branch `feature/game-121-sustainable-adventures`, stacked on GAME-119 `feature/game-119-deep-character-progression` (05b093a), incorporating research2441a6f. Gameplay/build source `1ff309bca003c2d0bbe0cc6a3c05b145565c5225`; later commits preserve documentation/evidence only. Parent PR80/81/88 and GAME-119 remain unmerged. Neither GAME-119 nor GAME-121 draft publication is claimed before Mark's Publish draft PR click.

The fresh normal home screen offers **Seek new leads**. Four contextual reports persist until resolved; subsequent sets retain old history and geography. Full recovery, investigation, peaceful access or combat victory grants10 XP each once. Inspection, partial/failed attempts, withdrawal, travel/rest and seeking reports grant0. Combat has one objective reward. Unfinished returns/restarts retain the same report/battle, and completed events cannot replay for XP.

The new optional cycle ledger uses the existing opportunity transitions, character kernel and single lock/journal writer. Whole tactical source, historical rules/character packs v1–v9, original sandbox manifests and both XP policies are unchanged and protected by source-pins.json. Old campaigns retain exact mechanics/policy pins; old zero-XP noncombat results are not retroactively rewarded.

Real skill contributions use saved briefing totals with an independent deterministic report seed and lower provision costs. History remembers both recent outcomes and still-present armed groups. New enemies advance through legal existing class definitions at the rounded-up mean party level, capped12; original tactical action economy/commands/RNG remain authoritative.

## Verified evidence

[GAME-121 full source/native workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38334351918) passed on Windows and Linux at source1ff309b, including exported-game checks and package upload. Parent source coverage includes ten generated worlds/forty contexts, original V1/V2 lifecycle/save/replay, GAME-103/104/118/119 character suites, frozen GAME-32, original adventure and responsive presentation.

Final CI evidence, retained separately from local historical runs:

| Verification | Windows | Linux |
| --- | --- | --- |
| Legacy pinned campaign extension |22 checks,0 failures|22 checks,0 failures|
| Negative/reward/cache/journal checks |68 checks,0 failures|69 checks,0 failures|
| Source earned journey |1,111 checks,380 XP,0 failures|875 checks,360 XP,0 failures|
| Native exported earned journey |1,489 checks,380 XP,0 failures|967 checks,370 XP,0 failures|
| Separate-process restart and production launch |passed|passed|

Both native packages earned Arcane Trickster1 at250 XP and Arcane Trickster2 at360 XP through actual saved objectives, used real spells and the prestige ability, and ran with empty PATH and no source-helper override. Different generated campaigns/command counts explain differing assertion totals; this is not a cross-platform identical-world replay claim. Per-run proofs and wall-clock timings are in [evidence](evidence/). Source earned automation took710.515 seconds on Windows and433.454 seconds on Linux; neither is measured human playtime.

[Production UI/GAME-81 input/render and distribution workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38333540759) passed on **both OSes**, source15a96af. The subsequent1ff309b changes only the cycle-validation cache key and its negative test; UI source is identical. The initial GAME-12115a96af run was superseded/cancelled by that fix, not described as a successful run.

Actual local evidence:

- Service-driven fresh campaign:380 genuinely earned XP from40 report attempts/38 successes; Rogue2/Wizard3/ArcaneTrickster2;1,013 checks, no errors; prepared spells and real prestige action used. Separate-process reload passes. No inserted XP, high-level grandfathering or substituted party.
- Genuine Godot/Mesa rendered campaign:360 earned XP and prestige2,853 checks; rendered new-process reload8 checks. Separate actual earned campaign captures prestige combat and full ordered history,129 checks. Correctly paced production-button/skill-choice capture25 checks with no errors. The first immediate-signal diagnostic retained a deferred-focus error; its raw log is preserved and is not called a clean run.
- Original pinned campaign extension22 checks; duplicate/partial/failure/journal/source corruption checks passed. Targeted post-fix cache-integrity run64 checks.
- Local self-contained Linux package:1,125 checks,390 earned XP, prestige2, real spell/power use, empty PATH/no source helper, separate-process restart and production launch. Archive SHA-256 `429af74b7103c72ac33f005e3de8e04be118ce6f9e13f6c5b5c1f2ba249a0c41`;7,916 archive members independently checked, exact v9 content and bundled Node/helper. Local evidence does not replace final Windows CI evidence.

[Raw evidence](evidence/) and [34 real Godot screenshots](screenshots/), with [hash manifest](evidence/screenshots.json), are committed. Images cover640×360,1280×720,2560×1440. They include the visible next-lead action, skill choices, full objective reward, home XP/threshold, earned level2, prestige requirements, earned class history, actual prestige combat and restart. These are earned saved states, not prior GAME-119 development fixtures.

## Windows package

[Download the complete Windows x64 artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38334351918/artifacts/11786328530) (`game121-complete-Windows`). GitHub sign-in may be required. Inner playable archive: `game121-sustainable-adventures-windows-x64.zip`.

SHA-256: `a9ceccd24bc3b7b757b05d9561820223201e259b5dbf4dc2cfe3346aeb0bbe7e`.

The downloaded archive matches both the CI distribution proof and supplied checksum file. All7,063 ZIP entries passed CRC validation; the executable hash matches distribution.json; v9 character content, both XP policy files and cycle policy are byte-identical to the tested repository; bundled Windows Node, helper, artwork and required notices are present. The rules manifest retains installed historical packs. Build source is `1ff309bca003c2d0bbe0cc6a3c05b145565c5225`; subsequent documentation/evidence commits have no changes to scripts, scenes, data, assets, themes, tools, tests, project.godot or export_presets.cfg.

[Linux x64 artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38334351918/artifacts/11786076257), inner archive SHA-256 from CI distribution proof: `d797fb2bdc619ed995e3231579d6ed1091e3a824f8912d22cac94d73f3d61d05`. The earlier locally built Linux archive has a different hash and is identified separately above.

Download the GitHub artifact, extract its outer ZIP, then extract the inner `game121-sustainable-adventures-windows-x64.zip` completely. Open the extracted game folder and run `road-has-gone-dark.exe`, keeping `worldgen-helper`, artwork and licence notices together. No Godot or Node installation is required. Follow [TESTING.md](TESTING.md); source scene is `res://scenes/ui/main_menu.tscn`. Existing campaigns use Resume without deleting/recreating saves.

## Pacing, content and limits

See [PACING.md](PACING.md):25/121/361 full successes fund levels6/12/20 under the unchanged core curve. The473.731-second automated service journey is not a measured human playtest duration. Current seven activity templates, one/two basic-AI bandits and capped12 encounter progression do not establish ideal high-level pacing/balance.

Character content remains11 familiar core adaptations1–12,4 prestige paths1–5,30 mechanical feats,12 skills,27 scheduled specialisation groups,9 race families/14 heritage records. Complete core13–20, broader companions/summons/transformations and403 ancestry/66 base/~283 prestige catalogue are still open.

Current limits: hometown-only context; skill totals fixed at each report briefing; still-present/peacefully accommodated armed groups retain occupation and can reduce future contested reports, while safe noncombat objectives continue. A richer durable threat-follow-up/activity system belongs to the explicit continuation, not silently respawning or rewriting old enemies/results. LPC/class/equipment presentation improvements retain their separate tickets.

GitHub #90 tracks this implementation; full programme #82 remains open. No callable Linear connector is available, so no Linear status change is claimed. Human acceptance and draft publication remain pending. Prepare the [PR description](PR-DESCRIPTION.md), target the GAME-119 branch, and prompt Mark to click **Publish draft PR**. Do not merge. [Continuation](CONTINUATION.md) records the next concrete programme work.
