# Wave Four native delivery receipt

Implementation source: `1115aa7722b93a955256ad3b157f2ab201648dad` on `feature/game-112-character-catalogue-wave-four`. Existing PR: https://github.com/marksprietsma-beep/road-has-gone-dark/pull/99 . The PR records readiness, final merge status and main SHA; publication requires successful compatibility checks. Programme #82 remains open.

Final candidate: `trhgd-character-v14`, schema14.0.0, engine3, content hash `3688456544f6e1c0f62e4a26faf5ec114b4ea668e4267cd1bdad3d211cdf8559`.

## Windows download

https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38684785820/artifacts/11950207480

Inner playable archive: `game112-character-catalogue-wave-four-windows-x64.zip`.

SHA-256: `4a99be627162f089d96bf2cf50725ade79b8cc4383deb0176148fb402bebec11`.

Extract the GitHub artifact ZIP, then its inner playable ZIP. Keep the complete inner folder together and run `road-has-gone-dark.exe`. No installed Godot or Node is needed. The helper, resources and required artwork/licences are bundled. Detailed actions and expected results: [PLAYTEST.md](PLAYTEST.md).

The native Windows job passed on a Windows runner with empty PATH and no source-helper override, including production executable startup and independent save/restart. The downloaded ZIP passed CRC validation for7061 files, contained the genuine Windows PE executable and bundled helper, and its content JSON matched the implementation commit byte-for-byte. This is automated native verification, not a claim of a new human Windows acceptance test.

Linux CI also passed. Its downloadable package is https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38684785820/artifacts/11950721053 ; inner tar.gz SHA-256 `7c920d506f749ea7f4ed0a4a66fbb16dfae030649da2da2888eed1ca19b8c1a2`.

## Verification and source provenance

Native Windows/Linux and full compatibility matrix: https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38684785820 . Native platform jobs passed; the linked workflow records the broader compatibility conclusion and controls publication. Exact proof/timing receipts are in evidence/; raw logs, source/native saves and timings remain in that run's platform evidence artifacts. Current-head PR checks and subsequent main checks are linked from PR99.

Both native platforms passed1847 mechanics,407 additional cohort,73 main cold-restart,7 cohort cold-restart,273 earned-progression and3 earned cold-restart checks, with zero failures. Their ordinary generated journey counts are113 Linux/135 Windows, each with40 earned XP. Separate-process advanced histories, resources and content pins match exactly. The new prestige campaign earned360XP through nine real opportunity cycles, manually chose War Chanter and separately saved a legal Marshal continuation; no XP was injected.

Actual Godot capture validation passed59 creator checks/45 renders and63 campaign/advanced checks/39 renders at640×360,1280×720 and2560×1440. Eighteen selected screenshots and their SHA-256 manifest are committed. Earned War Chanter screenshots use real360XP; Archmage/Metamind/Cognition screenshots are explicitly labelled development fixtures. [TESTING.md](TESTING.md) distinguishes these sources and test outcomes.

Documentation, coverage and screenshots added after1115aa7 do not alter executable source, content or workflow logic. Verify this with `git diff 1115aa7..HEAD -- scripts tests tools data scenes themes project.godot export_presets.cfg .github`. Later delivery receipts and the post-merge main package, when available, are recorded in PR99 and programme issue82 without changing tested gameplay merely to update a SHA.

## Scope and limitations

[PR-DESCRIPTION.md](PR-DESCRIPTION.md), [CONTENT-DELTA.md](CONTENT-DELTA.md) and [REPERTOIRE.json](REPERTOIRE.json) contain the full before/after inventory and mechanics. Thirty base tracks support1–20. Sixteen prestige paths retain their own5/10-level caps, permanent prerequisites and explicit earned-XP selection. Starting selectors and forged level-one payloads reject prestige; qualification never grants it automatically.

Historicalv1–v13 files and campaign pins remain unchanged, and frozen GAME-32 tactical source is byte-identical. Earlier unreleased v14 candidate saves remain tied to their exact candidate binary/hash; mismatched saves are never silently repinned. The earlier06c8bfb build remains preserved as historical evidence, not the expanded release.

Ancestry, form and creature sprites use disclosed neutral humanoid fallbacks; large actors still occupy one tile. No flight, aquatic exploration, environmental vision, mind-controlled AI or breath cone is claimed. Duskblade's hit-conditioned channeling and Spirit Shaman's rest-selected repertoire remain substantive follow-up mechanics. These are bounded original adaptations rather than complete sourcebook conversions.

All760 research occurrences remain accounted for across720 taxonomy rows. Seventy-nine occurrences now map to native-tested adaptations;681 remain unresolved. Heritage variants, feat/spell counts and scheduled choices are tracked separately and do not inflate source coverage. The overall character programme is unfinished.
