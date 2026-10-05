# Executed QA and self-review

Local Linux: Godot 4.6.3, Node 24.19.0 **from the accepted GAME-76 helper**.
Repeatable orchestration: `tools/run-qa.py`; exact stdout under `evidence/logs/`.
Native Windows/Linux CI workflow is added; final conclusions are recorded in PR.

| Executed check | Result |
|---|---|
| Framework tests under blocked fetch/http/https/net/TLS/DNS and forbidden Math.random | 9 tests, 0 failures |
| Genuine canonical eligible hometown matrix | 2,565 character/context checks across both worlds, 3 entity instances per eligible town |
| Explicit negative cases | Reject maritime role without source port, opposed traits, wrong material, moved site anchor, hidden/removed sources, cross-world/mixed-scope sidecars, unknown generator, tamper, collision and leaked projection fields |
| Real pinned Lexicon / Rant / own staged renderer comparison | 1,000 equal-fact outputs match and repeat, no fact mutation |
| Sequential-ID content QA | 1,000 IDs per domain, 5,000 records; first 20 per domain retained, no lucky-seed selection; 0 bad-token matches |
| Godot public OriginLore adapter | 11 checks pass: exact real world/burg, no private fields, unknown identity, copy isolation, digest failure/stale clearing, unexpected secret fields |
| GAME-7 persistence smoke | Pass: independent IDs, origins, three skeletal members, knowledge separation, mismatch rejection, immutable fixtures |
| GAME-74 source/save assertions | 3,973 checks, 0 failures |
| GAME-74 forced post-write reload failure | 26 checks, 0 failures |
| GAME-74 actual input/render | 17 checks, 0 failures |
| GAME-76 accepted packaged helper | 6 genuine generations; same-seed bytes, different seeds, accepted canonical SHA, safe argv/path-with-spaces, offline packaging, timeout checks pass |
| GAME-76 library lifecycle | 57 checks, 0 failures |
| GAME-76 actual input/render | 20 checks, 0 failures |
| Canonical JSON | 5 tests pass; both original fixture validation passes |
| Public origin rendered proof | Actual Godot screenshots at 640×360, 1280×720 and 1920×1080 inspected |

No project script/runtime errors in the completed runs. Linux llvmpipe/Xvfb reports
an unsupported VSync warning; this is renderer-driver capability, not a script
failure. This does not claim a real Windows high-DPI laptop test.

## Readability and content audit

Read the first sequential twenty samples per domain, not one fortunate output.
Removed repeated “Raised ... raised ...” biography phrasing. Avoided unsupported
winter/terrain/port assumptions. Public text never interpolates vendor HTML,
hidden records, rumour verdicts or private facts. A public `underground` tag leak
was caught and excluded with an explicit negative assertion. Starting-character
private facts now have separate playthrough storage, never world sidecars.

Observed distinct prose over 1,000 IDs: site 36, origin 9, character 399, mundane
3, rare 3 (machine report is authoritative if pack changes). This is intentionally
a small original proof pack: **not production-scale variety**. Histories and
traditions are restrained local craft/family memories rather than grand legends;
rare items are local craft curiosities, ordinary items remain ordinary.

## Limits and recommendation

No culture-specific personal-name corpus is cleared; role labels preserve actual
Azgaar names and culture references without invented cultural stereotypes.
Current culture does not prove the historical creator; generated attribution is
explicitly labelled fiction. Coastline classification stays unknown in this
minimal adapter. Hidden dungeon source URLs are stored only as vendor provenance;
no interior, iframe or network dependency exists.

Sidecars demonstrate immutable version/digest lifecycle, not production library
installation or save migration. No fsync/crash durability guarantee beyond atomic
complete-file publication; `.tmp` files cannot be loaded as committed sidecars.
Gameplay knowledge authorization remains a future consumer responsibility.
The optional contract domain is omitted: the four required domains and public
origin adapter prove the framework without pretending quest gameplay exists.

Core changes are under `research/game77/` plus its native QA workflow only. No
canonical fixtures, accepted map generation, source/save schemas, onboarding UI,
GAME-75 branch or earlier draft PRs changed. Existing QA scripts can overwrite
historic GAME-74/76 evidence during execution; those tracked files are restored,
and this run's logs/proofs are preserved under GAME-77.

Research `.mjs` module bytes (not a binary/heap measurement): 19323; zero external npm dependencies.

## Windows runner correction

The first native Windows run failed in the new Python QA wrapper. A local
CP1252 stdout reproduction raised UnicodeEncodeError on Node's U+2714 test
checkmark after the tests completed. Source/log reads already used UTF-8; stdout
now explicitly uses UTF-8 too (as GAME-75 already does). The failing reproduction
and corrected CP1252-environment rerun are retained; final Windows CI must pass
before handoff. This was a QA reporting bug, not a content/save failure.

Final route-group audit: searoutes/trails were wrongly grouped as roads in trial
v1. Corrected v2 with per-group assertions across both worlds; canonical bytes and
GAME-75 factual renderer unchanged. Current sample/prose counts are refreshed in
quality-audit.json after the explicit generator-version change. Historical v1
sidecars retained, never installed or silently rewritten.

Native Linux and Windows passed on corrected generator-v2 code head
`f34b4acb5cdaf79604c13704df833d1e76bdd748`: GitHub run
https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37337162447.
This includes the per-route-type matrix, pinned-sidecar reader, same accepted
helper, offline tests and original source/save/library regressions. Final
documentation-head CI is independently verified in the PR/final delivery.
