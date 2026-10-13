# GAME-103 validation and compatibility evidence

Implementation source: `9e4dd2502d24aeab4943b00be3bc7a9f1517494b`; clean feature branch from main `a47f972`. No rules-pack, world-generator/helper, tactical-kernel, opportunity-version or save-owner rewrite.

The broader legacy render regression identified a pre-GAME32 ready party without mechanics. The preview now delegates to the existing pure art preview rather than accessing nonexistent creator drafts. Its exact saved bytes and identity remain unchanged. A targeted real UI journey passed 17 checks through the hometown handoff; the native QA now includes the same old-format case.

## Local proof

| Check | Result |
|---|---|
| Frozen GAME-32 kernel | 22,181 / 0 failures |
| Existing mechanics migration / second process | 235 + 6 / 0 |
| Custom creation, ancestry/class/feat/equipment matrix, illegal/stale choices, deterministic real combat and earned legacy multiclass | 149 / 0 |
| Custom and earned legacy history fresh process | 5 / 0 |
| Enter-to-save, nested control locks, three confirmations, read-only ready identity, no free levels | 25 / 0 |
| Malformed progression containers/values and real advanced-save rejection; legitimate combined XP retained | 26 / 0 |
| Party failure/reload/journal recovery | 74 / 0 |
| Existing First Adventure combat / campaign save / restart | Passed; frozen combat hash retained |
| Existing GAME-83 responsive theme/layout | 20 / 0 |
| Actual rendered New Game → two generated worlds / six hometowns → individual character saving → V2 opportunities → combat → return → sheets and earned legacy multiclass | 888 / 0 |
| Same six journeys restored in a second process | 36 / 0 |

Raw JSON, logs and timings are committed in `evidence/`. Screenshot assets are actual Godot 4.6.3/Mesa renders at 640×360, 1280×720 and 2560×1440. The complete rendered journey predates the final save-input/XP guards; those guards are separately covered by the editor and corruption regressions and do not alter the rendered layout. Feat/equipment captures use the final layout. Kernel/migration evidence predates the final guard because their implementation and frozen definitions did not change.

## Native CI

The final GAME-103 workflow runs Linux and Windows source regressions, ten independently generated worlds / forty contexts, V1/V2 persistence, custom lifecycle/restart/editor/XP-shape tests, First Adventure deterministic combat/save tests, GAME-83 layout, and native exported UI journeys with no external helper override and an empty PATH. It exports a separate diagnostic entry point from the same source/resources; the production main scene is unchanged. The test executable is removed from the playable archive.

Native production launch and six-hometown/new-and-legacy journeys must pass before the archive is published. This is native Windows headless UI/game execution, with genuine rendered visual evidence captured on Linux; the Windows GPU playtest remains human review.

Workflow: https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38151463856

Both native platform jobs passed: 773 production-journey checks and 30 fresh-process checks per platform. All helper overrides were removed and PATH was empty. The old unprepared-ready party kept its exact bytes during preview and persistent IDs through the hometown handoff. The separately launched production executable also passed.

Source builder tests passed 149 creation/eligibility/combat/legacy-advancement checks, five second-process checks, 25 editor/legacy-ready checks and 26 malformed-XP checks on both native hosts. Ten generated worlds / forty contexts and existing V1/V2 save/replay passed. Native proof, timing and corpus metrics are committed under evidence/native-windows and evidence/native-linux.

The complete actual mouse/keyboard/render flow passed 111 checks locally after replacing its obsolete 18-pixel label assumption with shared-theme readability and viewport bounds. Its rendered-ink check is retained. GAME-83's actual origin/party flow passed 123 checks across all three resolutions. These are test-only corrections; production source and resources are unchanged from packaged commit 9e4dd25.

The independently downloaded Windows archive has SHA-256 296f18b07879a434e36f1ce14eed56f1de27bb1f096d648bd76679f6f44c6f46. It matches the workflow checksum and source commit. ZIP integrity, required executable/helper/policy/credits and removal of the diagnostic executable were checked. See DELIVERY.md for the download and launch steps.
