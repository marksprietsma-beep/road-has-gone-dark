# Prepared draft PR

Publication: leave this in ChatGPT **Publish draft PR** for human review; no PR has been automatically opened.

Base: `feature/game-95-party-preview-old-road`
Head: `feature/game-96-procedural-sandbox-spine`

Title: **GAME-96: persistent procedural opportunities and generated tactical encounters**

## Description

Normal hometown play previously offered one authored Old Road encounter. It now records four source-anchored local opportunities and lets the same persistent three companions discover/visit, fight or withdraw, return home and choose another. Camps, ruined yards, clearings and source-route threats compose different dimensions, obstacle/LOS arrangements, deployments and blade/bow opposition. Old Road remains an explicit regression fixture and existing active saves keep their original pin.

One existing GAME32/tactical resolver and PartyService save owner handle all encounters. The new optional sandbox namespace separates immutable versioned source/recipe data from knowledge, saved battles, terminal results, world deltas and exactly-once placeholder journey history/XP. Source/config drift fails visibly without rerolling. No new race, combat, world-generation, injury, bestiary or campaign framework. LPC identity/previews and GAME95 pacing remain.

Validation: five actual worlds, 45 contrasting hometowns, 180 generated encounters and 178 distinct geometries; 6,925 legal commands match the independent frozen resolver with identical logs/RNG. 25,111 corpus assertions pass, plus deterministic rejected-candidate/retry/exhaustion checks and multi-opportunity separate-process reload/rollback/reward tests. GAME32, GAME83, First Adventure, LPC/source integrity and registered-board regressions pass. Normal Godot rendering drives the full three-opportunity journey at 640×360, 1280×720 and 2560×1440 (331 assertions). Native Windows exported legacy/procedural journeys pass 237/294 assertions with bundled dependencies and empty PATH; package CRC, AMD64 binaries, all 291 original art hashes and cross-platform corpus equality pass. [Windows download](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38013974869/artifacts/11654514569); SHA-256 `d3a48f0936d98d4fea73a00abd2c329f279202dbee98c2bc4588fd51f0ef08bb`. Build source `b20cf27d72d3eeac805b3858455286faa4914a4d`; final handoff changes only documentation/diagnostics. Exact steps and full proofs are in DELIVERY.md.

Read `docs/implementation/game96/AUDIT.md`, `GENERATION.md`, `VALIDATION.md` and `DELIVERY.md`; inspect real screenshot evidence, then use the exact human test steps in `README.md`.

Limits: finite four-opportunity pool; existing armed-human builds; inferred fine terrain/occupation; conservative AI-compatible approaches; terminal withdrawal, V0 rest and placeholder XP. Toy-AI victories are not class balance. An extra fresh-world trial exposed an existing Azgaar packed-vertex geography-sidecar error before sandbox preparation; it is documented with exact seed/SHA/log and preserved campaign. Windows desktop/GPU human playtest remains required.

Keep draft and unmerged pending human review. Parent branch stack remains unchanged.
