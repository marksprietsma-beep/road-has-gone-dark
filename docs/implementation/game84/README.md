# GAME-84 — first production expedition V0

A ready party now enters its hometown, accepts a local account, travels on the original one-cell GAME-62 illustration, investigates a known site or scouts a rumour, makes a choice, and returns home. Continue resumes the last valid campaign; an away party gets Resume Expedition. Every consequential action is written and immediately reloaded before the UI displays success.

Base: GAME-81 `78b00109687e0719c6408e700da9387fbad330de`, branch `feature/game-81-party-creation-v0` (PR #65). Delivery: `feature/game-84-first-production-expedition-v0`. Existing PRs are untouched and unmerged. Use the normal **Publish draft PR** workflow with the GAME-81 branch as base.

## Architecture and boundaries

- `tools/expedition/content.mjs` adapts the existing GAME-78 pack, SHA seed paths, compatibility rules, structured history, contract generator and Rant text rendering. Eight deterministic sites belong to the real hometown cell. Their `site:<SHA>` IDs include immutable world identity, source cell, content version and slot; campaign IDs and scene/order state never seed world facts. The content hash also pins the pack. Generated sites explicitly say generated-local; they are never fabricated source markers.
- `tools/expedition/entry.mjs` uses the existing offline Node helper and **unchanged** accepted GAME-62 `generateCellRegion` / `renderRegion` implementation. Exact canonical replay supplies omitted source geometry and must reproduce the original world SHA. The region retains its 20% viewing fringe. Sites are placed only inside the owned dry-land polygon, not in a neighbouring cell or in water. Source landmarks/provider sites are removed from the public SVG composition, so hidden content cannot leak through the illustration. Developer footer text is omitted in the gameplay composition.
- The sidecar packet contains objective sites, provenance, secrets, illustration and initial leads. It is self-sealed in the user cache. Campaign data pins both its semantic content SHA and exact packet SHA. Public projections whitelist discovered names/positions; an undiscovered rumour gets only an opaque lead identity and a vague account. Investigated history is revealed after the choice. Objective secrets never enter UI/log text.
- `ExpeditionService` inherits the GAME-81 transaction service: same per-slot lock, exact-byte recovery journal, guarded world lifetime, immediate reload and rollback on write/reload failure. A stale revision, repeated action or wrong phase cannot apply time, knowledge or consequences again. Interrupted writes recover once; unrelated external changes are preserved with an error.
- GAME-7 validates the optional expedition record without changing source-POI rules. Missing expedition data is added only to a ready legacy campaign using the previously unassigned zero clock. Existing expedition content/clock versions are never silently upgraded. Unsupported versions fail visibly.
- `expedition_records.gd` owns the schema and public projection; `expedition.gd` owns presentation. The three actual GAME-81 character IDs travel together. Scout/Expert/Vanguard/Adept and relevant generated craft upbringing can offer a contextual approach; generic examination/survey/withdrawal remain available. No party member is fabricated or replaced.
- Repeated interpretation of immutable profile/people/origin data is memoized on the exact loaded world instance. **All dependent files and pinned runtime inputs are still rehashed on access.** Changed bytes, malformed fields and recomputed pins take validation and fail; caching does not relax persistence validation. Corruption-after-cache tests cover this boundary.

## Playable state and tradeoffs

Home → accepted lead → map → site → result → home. Two initial known locations and one rumour are offered. Scouting reveals a genuine pre-existing objective site; surveying can add a further rumour only while it is unknown. Survey records surroundings/further leads, examination records former use, contextual approaches record relevant construction/marks/instability, and withdrawal leaves the concern unresolved. Outcomes and knowledge changes persist separately from immutable facts. Completed means a local investigation was recorded and the party returned; no issuer/reward adjudication is implemented.

Departure costs one expedition turn and starts four provisions. Scouting costs two turns/one provision; abstract travel costs one turn/one provision; investigation costs two turns/one provision. Withdrawal costs neither; returning home always remains possible and costs one turn. Turns are **not hours, kilometres, route lengths or travel speeds**. Restocking at home is the narrow V0 provision abstraction, without an economy. No combat, stats, skills checks, loot mechanics, guilds, quests framework, dungeon interior, party splitting, free roam or physical pathfinding is implemented.

## Evidence and reproducibility

[Engineering assessment](ASSESSMENT.md), [batch metrics](batch-metrics.json), [unfiltered sequential samples](SEQUENTIAL-REVIEW.md), [actual persisted outcomes](actual-outcome-corpus.json), [human quality review](QUALITY-REVIEW.md), [first 50 executed outcomes](ACTUAL-OUTCOME-REVIEW.md), [screenshot sequence/contact sheet](SCREENSHOTS.md) and [executed test results](TEST-RESULTS.md) and [test logs](logs/) accompany the source. The batch's `choice-cases.json` records generated expectations; the separate outcome corpus executes real production transactions from explicitly labelled developer-seeded arrived states. Those fixtures are not passed off as screenshots or complete played journeys.

```bash
# Godot 4.6.3, build Node 24.19.0, frozen vendor dependencies and compatible helper
python tests/world_library/prepare-ci.py
python tests/expedition/run-tests.py --visual --regressions
# Linux requires a display; xvfb-run -a -s '-screen 0 3840x2160x24' works.
# Native package (official matching export templates required):
python tools/release/prepare-templates.py
GAME84_RELEASE_ROOT=/an/owned/new/build-root python tests/expedition/verify-package.py
```

On Windows omit `--visual` in the source runner; native packaging/empty-PATH proof runs in Windows CI. The Linux real-render run uses actual Godot mouse, Tab/arrows/Enter/Escape input at 640×360, 1280×720 and 2560×1440. The native diagnostic export runs the production expedition scene against both packed presets and a freshly generated world, with no source helper override and PATH empty; the delivered production executable also launches successfully. Only the production executable and its automatically bundled helper are archived, with checksum and runtime/art notices. No separate player Node/Godot install is required.

## Windows review steps

1. Download **game84-complete-Windows** from the verified Actions run linked in [CI evidence](CI-EVIDENCE.md). Extract the artifact, then extract `game84-windows-x64.zip` completely. Keep its `worldgen-helper` directory beside `road-has-gone-dark.exe`; do not mix helpers from another build. Compare the supplied SHA-256 using `Get-FileHash .\game84-windows-x64.zip -Algorithm SHA256`.
2. Launch `road-has-gone-dark.exe`, skip/finish the intro, choose New Game, choose either world template (or generate a fresh world), a state/region and eligible hometown, then confirm. Create the three adventurers, choose roles/background variants if desired, and finish party setup. Click **Enter hometown**.
3. Inspect two known leads and the rumour. Accept the rumour, depart, and verify its marker/name are absent. Scout; the site becomes named and marked. Travel, read the description and approach effects, then choose Survey or Examine. Check provisions, expedition turns, revealed history and the recorded consequence.
4. Escape to the main menu; **Resume Expedition** must restore the result, party and costs. Quit the executable completely and relaunch; resume again, then use **Return home**. Confirm the lead's Completed status and persistent recent log. Continue should now reopen the hometown.
5. Take a second known lead and choose a different approach or withdraw. Return remains available even with no provisions. Try keyboard Tab/arrows/Enter and mouse map markers/list controls. Test 1280×720 and a larger display; the scrollable detail pane must not cover the footer.
6. Start another game in the same world/hometown. It must have a separate party/save and initial knowledge; the earlier campaign's discoveries must not transfer. A referenced generated world must remain protected from deletion. Test another hometown and a freshly generated world to compare content.

Native CI is not a claim of human Windows visual acceptance. Mark's laptop review and the desired 10–20-minute human session pacing remain review items.

## Known V0 compromises

- The dry-land generator intentionally excludes maritime, mining and roadside purposes without site-level proximity evidence. Narrow eligibility is preferable to invented geography. It fails if eight supported placements cannot be found; it never substitutes another cell.
- The batch contains 27 site purposes, but only three supported lead-goal forms and repeated restrained appearance phrasing (339 distinct appearance strings in 840 sites). Slot prefixes also recur across cells. This proves a varied functional first slice, not an unlimited narrative system. History and role/context alternatives add detail, but a later authoring pass should improve repetition.
- A site has one resolved approach per campaign. Survey reveals at most one additional account in this slice. Return/withdrawal/retry semantics are explicit; no open-ended exploration or route simulation is promised.
- The accepted region renderer's settlement symbols can dominate a small logical map. This task preserves the original illustration/generation rather than altering scale or terrain. Markers remain selectable through the text list.
- Initial preparation replays missing original geometry offline; it can take longer than a cached resume. Measured fresh-cache preparation took 10.6–18.7 seconds across seven worlds; cached resumes took 0.19–0.58 seconds. A progress message and worker thread keep the UI responsive. [Raw timings](PERFORMANCE.json) distinguish cold replay, cached reads and ordinary saved transitions. Corrupt/unsupported cache or campaign versions produce an error and preserve the campaign; no silent content migration occurs. Cache repair should retain the campaign and regenerate only from the exact pinned inputs.
- Continue chooses the newest valid campaign; there is no save-slot browser or campaign manager. Ordinary main-menu lookup reads existing saves; pending recovery journals use the existing recovery path. New Game creates independent campaigns as before.

Canonical fixtures, historical sidecars and historical runtime manifests remain byte-identical. The additive expedition runtime manifest pins the already accepted regional provider and its required assets; GPL settlement generators are not introduced.
