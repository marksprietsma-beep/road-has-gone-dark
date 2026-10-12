# Character content validation checkpoint

Production source: `a5138f871532d5573ce323cd06b5dabe661c7bbd`. Current new content is `trhgd-character-v3`, rules3.0.0, engine2. All v1 and prototype v2 files/pins remain byte-identical. No automatic migration occurs.

## Completed local checks

| Check | Actual result |
| --- | --- |
| New-pack combinations, twenty-level progressions, JSON history/snapshot equality and retained earlier pin | 3,721 checks / 0 failures |
| Frozen GAME-32 oracle | 22,181 / 0; original golden and rules ref unchanged |
| Actual old-campaign migration and fresh process | 235 + 6 / 0 |
| Original builder lifecycle / fresh process | 149 + 5 / 0 |
| Original editor / malformed XP guards | 25 + 26 / 0 |
| Frozen First Adventure combat | 67 / 0, original deterministic combat digest retained |
| Original combat/campaign/restart runner | All completed with zero errors |
| Generated opportunity corpus | Ten real worlds, forty contexts, 1,693 checks / 0 |
| Existing V1/V2 opportunities, persistence and full production journeys | All runner stages passed; timings committed |
| Current engine2 expanded-pack rendered journey | 1,034 / 0; six hometowns, two generated worlds, all three new martial paths, preserved V1 campaign |
| Current engine2 independent restart | 60 / 0, including exact saved pins and 18 reconstructed character snapshots |
| Three actual new class/heritage/feat combinations, save/reload and blocked post-confirmation repin | 39 / 0 |

The original builder/editor and First Adventure checks were run during initial pack routing; the final native workflow reruns these against the engine2 production source. Raw JSON/logs and timings are in `evidence/`. PNGs are actual Godot/Mesa renders at 640×360, 1280×720 and 2560×1440, not mockups. Native Windows GPU interaction remains a human review step.

## Diagnosed failures and narrow corrections

- GAME101's protected whole-file tactical fingerprint rejected the required saved-pack routing additions. Update only that reviewed fingerprint; original frozen combat behaviour and all other protected source/world/icon pins remain unchanged.
- A new class invalidated a recommendation's class-dependent feat. The UI correctly refused the build; the diagnostic now selects legal actual equipment, feat and ranks.
- The initial restart test compared raw JSON floats against integer reference fields. Compare both references canonically, preserving exact values.
- Godot StringName statistic keys can sort differently from string keys in snapshot hashing. Preserve engine1 hashing and all earlier content; engine2 normalizes key types at the new snapshot boundary. New content has a separate v3 pin. Its full source journey and restart pass without replacing expected snapshots or weakening assertions.

The failed prototype diagnostics are not final acceptance evidence. The original summary was overwritten by an early diagnostic failure; final engine2 journey/restart proofs are newly generated from actual completed journeys and are intact.

## Native verification

[Windows/Linux workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38193531641) passed both platforms: 887 exported journey checks and 54 independent restart checks each, with empty PATH and bundled helper. Its archive was independently verified, but is superseded by the subsequent small-screen footer correction. Final refreshed proof, archive checksum and delivery link will be added only after successful execution and independent archive verification.

## Coverage status

All 752 indexed catalogue occurrences plus eight NPC families are accounted for, in 720 unique taxonomy rows with 760 independent source-occurrence records. Research-only source concepts are not exposed as playable. The original martial proof classes are not asserted to implement the missing defining mechanics of Monk, Barbarian, Ranger, psionic/occult classes or the other researched paths.

The expanded pack exposes six original base paths (three new), fifteen inherited records (seven new) and twelve feats (seven new). One existing prerequisite-gated prestige path remains partly unconnected to V0 tactical controls. New martial features are real passive numerical effects, not new animations/actions or a complete catalogue implementation. Twenty-level mechanics are validated through development fixtures; finite current adventures limit normal earned progression. The full programme remains open.
