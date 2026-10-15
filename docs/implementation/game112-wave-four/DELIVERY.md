# Wave Four delivery — merged, main integration under verification

PR [#99](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/99) merged normally on15 October2026 at `dc7243bb34ab82791abeab52dbae9242b6676f81`. Final feature source: `5509b7b89c8250cef02826b40066919e06d7023e`. The merge tree is byte-identical to that source. Programme #82 remains OPEN.

Released pack: `trhgd-character-v14`, version14.0.0, engine3. Content hash: `3688456544f6e1c0f62e4a26faf5ec114b4ea668e4267cd1bdad3d211cdf8559`.

## Corrected Windows download

[Final-source Windows x64 artifact11952778574](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38690794560/artifacts/11952778574).

Playable inner ZIP: `game112-character-catalogue-wave-four-windows-x64.zip`.

SHA-256: `a1ef9046eae34bcf08cc5507a1ab3f6e5f4b290862bc1f662d32158d4872680c`.

Extract the GitHub artifact ZIP, then its inner playable ZIP. Keep the entire extracted folder together and launch `road-has-gone-dark.exe`. No separately installed Godot or Node is needed. The distribution includes `worldgen-helper/node.exe`, helper sources/dependencies, resources, art and licence notices. [PLAYTEST.md](PLAYTEST.md) gives the exact journey.

Independent download validation passed ZIP CRC for7061 entries, confirmed both Windows PE binaries and matching sidecar checksum, and compared bundled CORE-CHARACTER-CONTENT.json byte-for-byte against the final source. Windows CI independently launched production with empty PATH/no checkout-helper override and verified a separate saved-game restart. This is native automated verification, not a new human acceptance claim.

Linux artifact11952303369: https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38690794560/artifacts/11952303369 . Inner tar.gz SHA-256: `75df85d16e64bc256fc59ee51d17b59edfd8baeda19274599255b85d052c8694`.

## Final feature-source verification

The complete six-job Windows/Linux workflow [38690794560](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38690794560) PASSED on5509b7b, including focused native restart, expanded source/native and broad compatibility on both platforms. Exact final-source receipts/timings are in [evidence/final-source-native.json](evidence/final-source-native.json); earlier1115aa7 receipts remain historical.

Both native platforms passed1847 mechanics,452 cohort,73 main restart,7 cohort restart,273 earned-progression and3 earned-restart checks, zero failures. Ordinary generated journey counts were167Linux/154Windows, with30/40earnedXP respectively; different valid generated journeys are not combined or described as identical. The independent prestige journey earned360XP through nine real cycles and manually selected War Chanter, with a separately saved lawful Marshal continuation.

The final creation-only starting-gear correction is included. New heroes cannot equip creature-only natural weapons, including forged payloads. Existing saves, historical creation pins, innate attacks and actual creature weapons remain valid. Focused46/0 and cohort452/0 tests preserve those distinctions.

Final-source real Godot creator validation passed63/0 with48 captures at640×360,1280×720 and2560×1440, including equipment filtering. The unchanged campaign/advanced presentation has63/0 and39 renders on1115aa7. Earned War Chanter evidence uses actual360XP; high-level Archmage/Metamind/Cognition fixtures are explicitly labelled development-only.

## Main integration

Post-merge runs ondc7243b: WaveFour38722381798; WaveThree38722381984; WaveTwo38722382016; productionUI38722381897; party/expedition38722382021; Windows sandbox38722381827. ProductionUI, party/expedition and Windows sandbox passed. WaveTwo also passed. WaveThree38722381984 failed its Windows native journey assertion `distinct psychic surge acts in saved combat`; the saved encounter showed the test bot stalling behind a blocked corner while using melee movement for a ranged power. A narrow test-only correction and captured15-check regression are being validated on `fix/game-112-native-journey-actions`. WaveFour remains in progress. WaveFive has not been applied, and main close-out remains blocked until the repair passes and is merged. Do not restart successful feature-source tests merely to update documentation.

The older1115aa7 Windows artifact11950207480 does not contain the starting-gear fix. It remains an interim historical package and is superseded by11952778574 above. Earlier unreleased candidate builds are not the final release.

## Scope and limitations

[PR-DESCRIPTION.md](PR-DESCRIPTION.md), [CONTENT-DELTA.md](CONTENT-DELTA.md) and [REPERTOIRE.json](REPERTOIRE.json) contain the full before/after inventory and mechanics. Thirty base tracks support1–20. Sixteen prestige paths retain their own5/10-level caps, permanent prerequisites and explicit earned-XP selection. Starting selectors and forged level-one payloads reject prestige; qualification never grants it automatically.

Historicalv1–v13 files and campaign pins remain unchanged, and frozen GAME-32 tactical source is byte-identical. Earlier unreleased v14 candidate saves remain tied to their exact candidate binary/hash; mismatched saves are never silently repinned. The earlier06c8bfb build remains preserved as historical evidence, not the expanded release.

Ancestry, form and creature sprites use disclosed neutral humanoid fallbacks; large actors still occupy one tile. No flight, aquatic exploration, environmental vision, mind-controlled AI or breath cone is claimed. Duskblade's hit-conditioned channeling and Spirit Shaman's rest-selected repertoire remain substantive follow-up mechanics. These are bounded original adaptations rather than complete sourcebook conversions.

All760 research occurrences remain accounted for across720 taxonomy rows. Seventy-nine occurrences now map to native-tested adaptations;681 remain unresolved. Heritage variants, feat/spell counts and scheduled choices are tracked separately and do not inflate source coverage. The overall character programme is unfinished.
