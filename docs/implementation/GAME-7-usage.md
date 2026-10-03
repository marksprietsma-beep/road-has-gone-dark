# GAME-7 world/save foundation — test and data boundary

This is the **first implementation-only slice** of [GAME-17's accepted exploration plan](../design/first-playable-exploration-loop.md). It is independent of the visual atlas debug viewer, final New Game screen, character creation, local region, guild, combat and dungeon code.

## What the adapter reads

- \`GameWorldTemplate\` validates the real Azgaar fixture's schema version, generator/provider/version, map dimensions and cell identity arrays.
- It computes a pinned \`world_ref\` from **Azgaar version, seed and the canonical fixture SHA256**. Every game save stores that reference, not the full source JSON. Changing an upstream world snapshot intentionally invalidates a save's exact-world match.
- \`get_record(kind, source_id)\` returns **defensive deep copies** of existing source records. Entity references use **source numeric IDs**, not a settlement's mutable display name.
- \`home_candidates(state_id, province_id?)\` returns existing small, non-capital burgs (Azgaar population scale 0–5). Results are deterministic sorted by source population then numeric burg ID. Missing provinces, invalid states and regions with no candidates yield an empty array.
- Road access, town militia and outside guild protection are **unverified** until actual route/protection sources are implemented. No world generation or invented guild office occurs at selection.
- \`objective_marker_count()\` is a development-only source query. Objective POIs are **not** automatically exposed through a new playthrough's \`player_knowledge\` field.

## What a new playthrough stores

\`GamePlaythroughStore.create_playthrough(world, state_id, home_burg_id)\` returns a mutable, versioned **playthrough state** with a random unique ID, stable home burg ID and state/province, three distinct **placeholder** character IDs, party list, world deltas, clock placeholder and four separate player-knowledge collections: known settlements, rumoured POIs, discovered POIs, visited POIs.

This is a skeleton contract for future GAME-32/33 rather than a pretend fully formed Pathfinder character. The immutable world snapshot is not duplicated into the save.

\`save_new(slot,state,world)\` refuses to overwrite an existing save. \`save_existing\` is explicitly for updating one; it stages temporary bytes and backs up an existing file during replacement. \`load_save\` validates save version, referenced source SHA, actual hometown, party identities, knowledge references and mutable fields. Slot names are limited to 1–64 characters from \`A-Z a-z 0-9 _ -\` (no slashes, absolute paths or traversal).

Save files are under Godot's **\`user://game_world_saves\`**, not the repository. A preview/re-roll of a seed or a second independent run never implicitly changes any existing game file.

## Developer test

In **Windows PowerShell**, after checking out the GAME-7 PR:

\`\`\`powershell
cd C:\projects\road-has-gone-dark
& "C:\path\to\Godot_v4.7.2-stable_win64_console.exe" --headless --editor --path . --quit
& "C:\path\to\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/game_world/smoke-game-world.gd
\`\`\`

Replace the example executable path with your installed Godot executable location. Expected smoke output:

\`\`\`text
PASS: GAME-7 independent world/save IDs, origin, 3-member party, knowledge, mismatches and immutable fixtures
\`\`\`

The smoke creates two separate saves in a dedicated test directory using the **same canonical world**, mutates and reloads them separately, checks stable IDs, invalid origins, bad slots, corruption, cross-world mismatch and unsupported version, then deletes test files. It also reads the second atlas showcase world, leaves the original canonical fixture bytes untouched and verifies its checksum.

**GitHub Actions** repeats the run on **Godot 4.7.2** and validates pinned canonical world fixture hashes. Subsequent GAME-8/9 work will introduce a game-facing selection UI; this smoke is not a final interface.
