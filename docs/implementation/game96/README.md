# GAME-96 procedural sandbox spine V1

Normal play now records four locally anchored opportunities, rather than requiring an authored Old Road opening. Choose a camp, rumoured work-yard, hostile clearing or source-route threat; scout/travel, enter its generated map and encounter, resolve or withdraw, return home and choose another. Generated base data, knowledge, opponents, final battles, consequences and companion journey histories remain saved.

Read [AUDIT.md](AUDIT.md) and [GENERATION.md](GENERATION.md) for the existing-system assessment, seed derivation, source truth, constraints and transaction contract. [VALIDATION.md](VALIDATION.md) records measured results and screenshots; [DELIVERY.md](DELIVERY.md) records build/source/checksum and human review steps.

## Exact human review path

1. Extract the entire Windows ZIP; run `road-has-gone-dark.exe`, leaving `worldgen-helper` and `artwork` beside it. No Godot/Node/art installation required. Escape skips the intro.
2. New Game → generate/select world → origin state → region → hometown → review/confirm origin. Inspect the actual three saved LPC companion previews. Party ready → Enter hometown.
3. Click **Explore local opportunities**. Inspect any available row or discovered map marker. Click **Set out for this opportunity**; **Scout** the rumoured work-yard when necessary; **Travel to the site**; **Engage the occupants**.
4. Movement: click **Move**, then a dotted tile. Attack/ability: click an action, then a highlighted legal target. **End turn** passes. Gold marks the active unit; crosses on props mark actual blockers. Ordinary ground has no new terrain modifier. LPC and existing animation pacing remain in use.
5. Main menu → **Resume Expedition** should restore the exact saved encounter. Victory or **Withdraw · defeat** → **Return to regional play** → **Return home & rest**.
6. The opportunity stays resolved; each companion remembers the result. Victory grants exactly 10 placeholder journey XP each. Withdrawal grants none and retains survivors/final battle. Choose another opportunity; no required scripted sequence. Returning before combat instead preserves a visited unresolved site for later.
7. Restart the application and confirm knowledge, encounter and history remain. Try another world/hometown for geography, map dimensions, terrain and enemy composition. Escape backs out of a home opportunity detail without modifying gameplay.

Start scene in Godot: `res://scenes/ui/main_menu.tscn` (the project entry also includes the intro). Automated rendered journey: `res://tests/sandbox/review-flow.tscn`; exported diagnostic router is intentionally omitted from the playable distribution after verification.

## Repeatable tests

Use the already verified Godot 4.6.3 and Node 24.19 compatible helper. `python tests/sandbox/run-tests.py --output <new-evidence-directory>` runs five actual worlds, contrasting source-owned hometowns, all generated encounters against the independent frozen GAME94 command oracle, and a separate-process multi-opportunity lifecycle. `GAME76_HELPER_ROOT` points to the repository's existing verified `worldgen-helper` for source testing. Logs, complete source corpus, timings and metrics remain in the evidence directory.

Rendered test: set `ADVENTURE_REVIEW_ROOT` to a new directory and open `tests/sandbox/review-flow.tscn` with normal Godot rendering. It uses real production controllers and mouse/keyboard input for world generation, identity previews, multiple generated fights, menu resume, outcomes and returning home. Linux CI uses Xvfb; no source-only screenshot or mocked battlefield renderer.

Native Windows CI runs the legacy journey as well as the procedural journey from the exported resources with empty PATH, no installed helper override and separate clean profiles. It also verifies the production executable launch, all distributed LPC source hashes and preference restart.

## Honest limits / next milestone

- Four finite opportunities per hometown; armed-human Vanguard/Scout builds only. No enemy ecosystem, wandering population or respawn simulation.
- Camps, ruined yards and clearings are inferred local fiction. Source truth supplies geography/biome/route references; the source does not assert these occupations or structures existed. Grass is a broad fallback for unclassified local ground, not a precise wetland/coast/snow renderer. No cave/interior claims.
- Connected approach lanes are intentionally conservative for the existing greedy AI. Isolated blockers change LOS and flank routes; there are no invented directional cover/charge/delayed-magic/terrain-cost rules. This is not a final encounter-budget or class-balance result.
- Tactical withdrawal is terminal defeat, preserving that attempt rather than resetting it. Precombat return permits revisit. A retreat/re-engagement policy needs an explicit future mechanical contract.
- Return provides labelled V0 HP/Focus recovery; journey XP is not levelling. Injuries, death, factions, relationships, personal quests and economic rewards remain future systems/hooks.
- Version/config/source drift fails visibly and preserves the campaign; future generator revisions need compatibility/versioned readers, not a reroll migration.
- An additional fresh-world trial (`game96-sandbox-review-v2`, source SHA `c9eb47dacfe4560df8cdd4bb128ab578ff2997e288c79665fb2cf9ab5791cbe1`) hit the existing geography-sidecar error `Bad Azgaar packed vertex position 9109` before sandbox preparation. Its campaign stayed preserved. World generation/geography code was deliberately not changed; that source-world limitation is separate from the passing five-world corpus. Use another world/preset for this review if encountered.
- Native packaged logic/launch tests do not replace a human Windows desktop/GPU playtest of this unsigned build.

Recommended next mechanical sandbox milestone: a bounded encounter-threat budget plus reviewed post-expedition recovery/withdrawal rules, using this persisted encounter ledger. Measure actual player decisions before expanding the bestiary or geography types.

Prepared as a stacked review branch on GAME95. No merge, force-push or automatic PR publication; leave the prepared description for **Publish draft PR**.
