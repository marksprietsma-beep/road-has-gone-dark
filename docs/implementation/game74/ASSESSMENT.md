# GAME-74 initial engineering assessment

Base: production main `238045b395ad9e693c71ac6b018442257fe0d6f3`.

GAME-4 uses a Control main menu and a placeholder scene. GAME-7's validated
GameWorldTemplate already owns eligibility (positive population <=5, non-capital,
non-hidden), deterministic ordering and source identities. GamePlaythroughStore
creates independent states, atomically saves new slots and validates reloads.
Reuse both without replacing their schemas or exposing skeletal adventurers.

The atlas has a reusable MapRenderModel/MapRenderBaker; its selection layer only
marks a cell. A list plus a small read-only baked terrain/political preview with
state/province highlighting is sufficient. GAME-8's layer browser, inspection,
map navigation and clickable polygon selection are unnecessary dependencies.
No research stack code will be migrated. Source cell IDs/index assumptions in
existing atlas and eligibility are valid for these dense canonical fixtures;
verify fixture identity and ownership through the existing adapter.

Implement a separate onboarding controller/presentation with world, region,
hometown, confirmation and persisted handoff pages. Offer two existing validated
templates, source state/province lists and eight deterministic eligible homes.
No arbitrary seeds, random generator, invented protection/road facts or POIs.
Earlier changes invalidate downstream choices; Back preserves valid selections.
Only final confirmation calls create_playthrough/save_new; use its unique ID as
slot. Failed writes remain on confirmation. Successful confirmation is guarded
against repetition and immediately reload-validated.

Test both fixtures and byte fingerprints, ownership, deterministic lists,
empty candidate handling, name-independent IDs, saves/reloads and independent
same-origin runs. Exercise actual Godot keyboard/mouse flow and cancellation,
capture real frames at 640x360, 1280x720 and larger scaled resolutions, inspect
layouts, and rerun GAME-7. Continue remains disabled pending a save browser and
party setup. Character creation, gameplay, source generation, saves schemas and
PRs #51–#55 are out of scope. Linear tools are unavailable in this environment;
prepare a repository update with evidence instead.
