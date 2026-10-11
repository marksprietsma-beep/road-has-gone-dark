# GAME-98 delivery

The actual production expedition map now uses the same approved Game-icons family and shared semantic mapping as the atlas. Known sites retain their real IDs and geographic centres. Gold rims indicate selection, pennants indicate party position and separate ticks indicate saved completion. Unknown and unlocated rumoured opportunities acquire no map icon, tooltip or hitbox.

Draft PR: [#78](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/78), against `main`. GAME-99 was already merged as `d4e5e3c559793633cf1dc03f2b11e33d933c2f8d` before this branch was created. GAME-98 is not merged.

## Windows download

Verified Windows x64 playable ZIP: [game98-complete-Windows](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38128201448/artifacts/11698001115).

GitHub wraps the playable ZIP and its checksum in an artifact ZIP. **Extract both archives**:

1. Sign in to GitHub, download the artifact and extract it.
2. Extract `game98-local-game-icons-windows-x64.zip` into a new folder. Keep the entire extracted directory together.
3. Open `game98-local-game-icons-windows-x64/road-has-gone-dark.exe`. No Godot, Node.js, artwork install or network access is required to play or generate worlds.
4. Escape skips the introduction. Choose **Continue** or **Resume Expedition** to use your existing campaign. Do not delete, recreate or reset your saves.

SHA-256 of the **inner playable ZIP**, not GitHub's outer artifact ZIP:

```text
e78f0c2eac912211f8359fb2610ee642cc2c82c1ecdf91edba94b9ebafc97259
```

The archive is 120,337,370 bytes. Its `worldgen-helper` contains the compatible native Node runtime and frozen world-generation dependencies. The original LPC layers/notices and Game-icons SVGs/metadata accompany the game. The diagnostic executable is removed; `START-HERE.txt` provides launch guidance. The archive CRC, AMD64 executable, bundled runtime hash, all 147 expedition integrity pins and 45 original SVGs were independently checked against the repository: [archive audit](evidence/windows-archive-integrity.json).

Build source: `ad2c1792fa25f237ba105d9fd7180135f4256346`. Final publication adds documentation/evidence only; the game's production source, helper, artwork and save contracts match this build. A final delivery commit can be identified from PR #78. GitHub artifacts have 30-day retention and require repository access; download a local copy for longer-term review. This is an unsigned review build.

## Testing the player's campaign

The normal save location remains `%APPDATA%/Godot/app_userdata/Road Has Gone Dark`. Launch from the extracted directory rather than from inside either ZIP.

1. Continue the existing ready-party campaign and enter its hometown/local region. The GAME-99 geometry recovery and validation remain included. Existing character names, site positions, history, XP and outcomes should be unchanged.
2. Select a **located** opportunity using either its map icon or existing list entry. Its gold rim changes without moving the marker. Hover to see its actual name, kind, generated provenance and knowledge/completion state.
3. For an **unlocated rumour**, confirm the report is available in the list but no exact map marker is revealed. Choose **Set out for this opportunity**, then **Scout the report · 2 turns / 1 provision**. Its genuine position and kind become visible when discovered.
4. Choose **Travel to the site · 1 turn / 1 provision**, then **Engage the occupants**. The existing tactical rules and persistent adventurers are unchanged.
5. Complete the fight and return to regional play. Victory retains the site's original icon, adds a completion tick and records 10 journey XP per companion once. Defeat retains the saved failed attempt and existing return path.
6. Choose **Return home & rest · 1 turn**, return to the main menu and Continue again. The correct public site identity, tooltip, completion state and reward should persist.
7. Resize to 640×360, 1280×720 and 2560×1440. Rectangular 32-logical-pixel click targets include transparent corners. Crowded markers select the nearest real public centre; their geography does not move. List entries remain an alternate way to select crowded opportunities.

For a new campaign, use **New Game → generate/select world → origin → hometown → ready party → Enter hometown → Explore local opportunities**, then follow the same steps. The real origin/party flow is preserved.

## Verification and evidence

[Six phone contact sheets and original Godot screenshots](EVIDENCE.md) show temperate forest, wetland, savanna, tundra, grassland and hot desert. The component captures are identified explicitly; separate full production-controller captures show a resumed GAME-99 campaign and its new victory. Image hashes and actual pixel dimensions are recorded rather than inferred from filenames.

| Check | Result / evidence |
| --- | --- |
| Shared Node/Godot semantics and original asset provenance | Pass; one JSON manifest, original CC BY metadata and SVGs |
| Six existing GAME-99 region contexts | Pass; three original canonical world hashes and six original content hashes retained |
| Real graphical production-map contracts | 606 checks, zero failures; [proof](evidence/linux-render-proof.json) |
| Windows source and native exported-game contracts | 534 checks each, zero failures; bundled helper, empty PATH, no source helper override |
| Linux source and native exported-game contracts | 534 checks each, zero failures; same isolation |
| Existing-save resume, live site selection, combat victory, return and reload | Pass on both native platforms; original save bytes, persistent party/site IDs and rewards verified |
| Existing First Adventure combat/save regression | Pass on Linux and Windows; 67 combat assertions plus campaign create/reload |
| Existing GAME-83 responsive presentation | Pass on both platforms in the native-build workflow |
| Full existing graphical GAME-83/GAME-84 keyboard/mouse journey | 476 checks, zero failures; [log](evidence/legacy-ui-input.log), all three target sizes |
| All 36 pinned Azgaar marker types, glossary and source artwork | Pass; [atlas workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38127281507) |
| Existing landmark inspection and New Game origin | Pass; [inspection](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38127281543), [origin](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38127281559) |
| Existing local-region generation and GameWorld save foundation | Pass; [region](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38127281536), [save](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38127281472) |
| Existing GAME-99 geometry/campaign recovery | Pass on Linux and Windows; [workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38127281497) |
| Existing world library and origin context | Pass; [library](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38127281506), [context](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38127281481) |

Successful combined [Windows/Linux native-build workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38128201448). Preserved [Windows](evidence/windows-run-results.json) and [Linux](evidence/linux-run-results.json) timings cover semantics, canonical contexts, imports and production-map contracts. Native logs and distribution proofs are alongside them. Windows's source contracts took 50.141 seconds and Linux's 37.932 seconds; these numbers exclude imports, context preparation and packaging. Full Windows GUI/hardware human acceptance remains review work; native Windows automation launches the actual exported executables headlessly, while screenshots use a real graphical Linux Godot renderer.

GAME-99 geometry, canonical generation and recovery source files are unchanged. The six canonical context pins and actual old GAME-99 recovery save are exercised directly; the wider existing GAME-99 workflow also runs independently on this PR. The player's private vertex 11702 world was not independently reproduced. No screenshot or public fixture is presented as that private world.

The build workflow is green on the exact final implementation/test source above. Several wider legacy PR workflows were still running at documentation publication; their earlier successes on the identical production source are linked above, and the final-source status snapshot is in [ci-source-snapshot.json](evidence/ci-source-snapshot.json). Updating the old graphical-driver assertions addresses its known failed child-count assumption; the corrected full graphical journey was verified locally. Superseded runs were cancelled to free the queue, without bypassing a failed check or cancelling the final source. Subsequent documentation-only publication can trigger additional PR checks; it does not change the verified executable.

## Loading, licences and limitations

The editor/source provider can decode original SVG bytes. In an exported PCK, Godot remaps imported images; `ResourceLoader` now follows those remaps when raw files are unavailable. The same provider caches textures for both atlas and local map. The helper retains original SVGs for Node rendering and source inspection; no separate hand-rasterised icon files were added.

Game-icons artwork is by **Delapouite and Lorc**, **CC BY 3.0**, pinned to [`82d948812bfe3f269ef8f731dcdb07b08160edc4`](https://github.com/game-icons/icons/tree/82d948812bfe3f269ef8f731dcdb07b08160edc4). Existing preparations remove opaque square backgrounds and recolour original paths to parchment ink; no source artwork was changed in GAME-98. Repository credit guide: [README](../../../assets/map_icons/trials/README.md); exact artists/source paths: [landmark_sources.json](../../../assets/map_icons/trials/game-icons/landmark_sources.json). The Windows distribution retains `REGIONAL-ART-NOTICE.txt`, `worldgen-helper/assets/map_icons/trials/README.md` and `worldgen-helper/assets/map_icons/trials/game-icons/landmark_sources.json`, including the licence/source links. Other included LPC and helper notices remain intact.

The approved family has no ordinary tent, clearing or roadside-obstruction drawing. Those kinds use the approved generic encounter portrait with their exact meaning in the tooltip; they are not silently sacred groves, fortresses, bridges or portals. Unsupported roles use the approved unidentified pin, and unavailable resources show a neutral question mark with `Icon unavailable` while retaining the correct site action. Extremely close sites retain their fixed positions; small artwork and nearest-centre routing improve selection, but this task does not introduce clustering, cosmetic relocation or a new renderer. Existing underlying settlement geometry remains visible in the geographic artwork.

The audit is in [AUDIT.md](AUDIT.md). No new encounters, races, quests, towns, combat rules, geography algorithms or second save writer were introduced. PR #78 remains a draft for human review.
