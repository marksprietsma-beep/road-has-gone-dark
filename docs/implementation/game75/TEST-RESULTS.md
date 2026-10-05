# Executed GAME-75 QA

Godot 4.6.3 (`7d41c59c4`), Linux x86_64; real OpenGL compatibility rendering on
Mesa llvmpipe through Xvfb. Bundled accepted GAME-76 Node v24.19.0 helper used
for genuine offline generation, not fixture cloning or a system-runtime fallback.

| Executed check | Result | Evidence |
| --- | --- | --- |
| Deterministic context and claim backing, both presets + 3 fresh worlds | 105,425 assertions, 0 failures | [context log](logs/context.txt), [source/contrast facts](context-proof.json) |
| Independent Python source audit | 5 worlds passed; exact identity/landmass/biome/coast counts and scalar median/complete sample neighbourhoods | [audit log](logs/independent-source-audit.txt), [proof](independent-proof.json) |
| Fresh GAME-75 helper generation | 3 genuine outputs, distinct immutable SHA values; original fixtures unchanged | [generated proof](generated-proof.json), [A](logs/generate-game75-context-a.txt), [B](logs/generate-game75-context-b.txt), [C](logs/generate-game75-context-c.txt) |
| Actual GAME-75 Godot keyboard/mouse/context/render flow | 108 assertions, 0 failures; genuine UI generation, save/reload, 640×360 / 1280×720 / 2560×1440 | [visual log](logs/visual.txt), [exact screenshot identities/claims](visual-proof.json) |
| GAME-76 packaged-helper contract | 6 genuine generations, repeated-seed byte determinism, distinct seeds, accepted fixture SHA, safe argv and wall-clock timeout | [helper log](logs/legacy/helper-linux.txt), [proof](game76-helper-proof.json) |
| GAME-76 persistent library/lifecycle | 57 assertions, 0 failures | [library log](logs/legacy/library.txt), [proof](game76-library-proof.json) |
| GAME-76 actual Godot generation/delete/input flow | 20 assertions, 0 failures; generated world save/reload and dependent-delete protection | [UI log](logs/legacy/visual.txt), [proof](game76-ui-proof.json) |
| GAME-74 source/save selection flow | 3,973 assertions, 0 failures | [onboarding log](logs/legacy/game74.txt), [persistence proof](game74-persistence-proof.json) |
| GAME-74 forced post-write reload failure | 26 assertions, 0 failures; no false handoff, cleanup/retry/lockout preserved | [failure-path log](logs/legacy/reload-failure.txt) |
| GAME-74 actual Godot keyboard/mouse/render flow | 17 assertions, 0 failures | [input/render log](logs/legacy/game74-visual.txt) |
| GAME-7 persistence smoke | PASS: independent IDs, origin, skeletal party, knowledge separation, mismatch rejection, immutable fixtures | [smoke log](logs/legacy/game7.txt) |
| Both accepted canonical fixture validators | PASS | [World I](logs/legacy/validate-game-11-determinism.txt), [World II](logs/legacy/validate-atlas-showcase.txt) |
| Canonical Unicode/JSON tests | 5 tests passed | [Node test log](logs/canonical-json.txt) |
| Landmark taxonomy/source icon coverage | All 36 macro types + neutral fallback; 73 / 79 existing markers covered | [coverage log](logs/landmark-taxonomy.txt) |
| Map key renderer smoke | PASS | [key log](logs/landmark-key.txt) |
| Landmark/settlement inspector renderer smoke | PASS: safe text, bounded inspector, hidden/zoom protection | [inspection log](logs/landmark-inspection.txt) |

The GAME-74 test's two obsolete wording assertions were replaced with current
UI/service integration and exact source wall-tag checks. All source identity,
persistence, eligibility, cancel and selection tests remain; GAME-75 independently
checks claim support, unknown facts, nearby/sea/hidden route rejection and hidden
settlement/POI exclusion. Generated-world checks have no fixture-name branching.

No Godot script errors occurred in these passing runs. The Xvfb driver reports
that V-Sync control is unsupported; that rendering-driver warning is recorded.
All 19 current GAME-75 screenshots were visually inspected, including smallest
logical and large-desktop confirmation views. No fonts were shrunk. The context
fits within four rendered lines in every captured case, above the footer, while
retaining at least 146 logical pixels of map height. These checks accompany visual
inspection rather than replace it.

Native Windows and Linux GitHub Actions execute the same fresh-generation/context
suite and GAME-7/74/76 regressions. Final platform results and links are recorded in
the [draft PR checks](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/58/checks). Linux also runs actual Godot screenshots and input.
Windows CI is headless and does not replace Mark's interactive Windows acceptance.

The first new Windows context/regression step exited with code 1. The new QA
runner used locale-default JSON text reading. Reading that actual generated UTF-8 JSON as Windows CP1252 was reproduced
locally and raises a UnicodeDecodeError. The runner now explicitly uses UTF-8 for
files, captured process output and console output; native CI is rerun. The world
generator and canonical bytes were not changed.
