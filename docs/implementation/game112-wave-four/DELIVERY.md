# Wave Four delivery — merged and native integration repaired

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

## Main integration and repair

Original merged main `dc7243bb34ab82791abeab52dbae9242b6676f81`: WaveFour38722381798, WaveTwo38722382016, productionUI38722381897, party/expedition38722382021 and Windows sandbox38722381827 passed. WaveThree38722381984 passed Linux but failed the Windows native WaveTwo journey because its melee test bot never acquired line of sight for Wilder's ranged surge. The captured save reproduced this exact strategy defect; no production power or persistence change was needed.

Narrow [PR100](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/100) merged normally at `c1d5973a88fd6ff3f9584465e10a68ea16f571f6`. Its source `a495fe14beb50f40742eeb03acaa1403817f0c03` passed all seven current-head checks, including native Windows/Linux [38735236420](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38735236420). The merge tree equals that tested head. All runtime source, scenes, assets, rules and gameplay data are byte-identical to the previously tested main; only tests/CI and delivery evidence changed. Existing assertions remain enabled.

Native repair results on both:1953 entity mechanics,15 captured geometry checks and7 legacy restart checks, zero failures. Real journeys171Windows/240Linux passed; their full campaign/form restarts also passed. Local source journey249/0 earned40XP and cold reload passed. See [integration-repair/ASSESSMENT.md](integration-repair/ASSESSMENT.md) and [evidence/repair-native.json](evidence/repair-native.json).

Repair Windows artifact11974396472: https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38735236420/artifacts/11974396472 . Inner `game112-character-catalogue-wave-two-windows-x64.zip` contains current v14; this is its legacy-verification filename, not a content downgrade. SHA-256 `a59bd7862481edb6477bfa4dfb533556ef6879b4e0d32eaac3982bf16bb56393`. Independent CRC7061/PE binaries/exact CORE-content/sidecar/source-stamp checks passed. Native production startup and independent restart passed with empty PATH and the bundled helper.

All automatic post-repair main runs PASSED: focused repair38741425966; WaveFour38741425954; WaveThree38741425956; WaveTwo38741426013; productionUI38741425975; party38741426037. Exact GitHub conclusions are preserved in evidence/post-repair-main.json. No unnecessary local repetition was performed.

The older1115aa7 Windows artifact11950207480 is superseded by the corrected final-source11952778574 above. Earlier unreleased candidates are not silently repinned. Programme82 is OPEN; the overall catalogue remains unfinished.

## Scope and limitations

[PR-DESCRIPTION.md](PR-DESCRIPTION.md), [CONTENT-DELTA.md](CONTENT-DELTA.md) and [REPERTOIRE.json](REPERTOIRE.json) contain the full before/after inventory and mechanics. Thirty base tracks support1–20. Sixteen prestige paths retain their own5/10-level caps, permanent prerequisites and explicit earned-XP selection. Starting selectors and forged level-one payloads reject prestige; qualification never grants it automatically.

Historicalv1–v13 files and campaign pins remain unchanged, and frozen GAME-32 tactical source is byte-identical. Earlier unreleased v14 candidate saves remain tied to their exact candidate binary/hash; mismatched saves are never silently repinned. The earlier06c8bfb build remains preserved as historical evidence, not the expanded release.

Ancestry, form and creature sprites use disclosed neutral humanoid fallbacks; large actors still occupy one tile. No flight, aquatic exploration, environmental vision, mind-controlled AI or breath cone is claimed. Duskblade's hit-conditioned channeling and Spirit Shaman's rest-selected repertoire remain substantive follow-up mechanics. These are bounded original adaptations rather than complete sourcebook conversions.

All760 research occurrences remain accounted for across720 taxonomy rows. Seventy-nine occurrences now map to native-tested adaptations;681 remain unresolved. Heritage variants, feat/spell counts and scheduled choices are tracked separately and do not inflate source coverage. The overall character programme is unfinished.


## Closed post-repair main verification and later Windows policy

All six automatic c1d5973 repeats completed SUCCESS, independently read from GitHub: WaveThree38741425956, productionUI38741425975, party38741426037, WaveFour38741425954, native journey38741425966, WaveTwo38741426013. See evidence/post-repair-main.json. Any earlier “pending repeat” text is superseded by this receipt. No Wave Four implementation remains to recreate.

PR102 subsequently established Windows x64 as the only supported target and merged at129e5de. Earlier Linux proofs/links in this document are historical; do not generate new Linux CI/packages or require Linux acceptance. The existing Wave Five branch was synchronized at3a098d5 and real v15 source is now committed in PR103. See the Wave Five delivery for new content and independent Windows-native receipts; the old v14 packages above do not contain those classes.
