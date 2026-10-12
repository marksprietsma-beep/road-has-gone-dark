# Character content foundation Windows review

Draft PR: https://github.com/marksprietsma-beep/road-has-gone-dark/pull/81, stacked on unmerged draft PR80. No merge performed.

This is the first full-programme checkpoint, **not completion of the entire character catalogue**. All 752 indexed source entries plus eight NPC families are tracked; research-only concepts remain unplayable. New original content adds three martial paths with twenty-level mechanics, seven inherited traits and seven feats, with saved-pack resolution, class/feat search and numerical sheet explanations.

## Windows x64 download

[Download complete Windows artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38197788374/artifacts/11725120008)

Playable ZIP: `game104-character-foundation-windows-x64.zip`

SHA-256:

```text
3140d6a922bf1370a8afe8aa27ca9b41bbe5b9a5dd73028d3e11ddca09fb9670
```

Packaged production source: `0184fcfa2149e39472424e55fd55d0f277a54e3b`. Later delivery-only commits do not change game scripts/scenes/data/artwork/helper/export sources. Independent download verification confirms checksum, archive integrity and 7,059 files. Bundled Node/worldgen-helper, original artwork and licence notices are included; no installed Godot or Node is needed. The earlier a5138f8 build is superseded by this package's 640x360 footer correction.

## Extract and play

1. Download and extract the GitHub artifact ZIP, then extract the enclosed playable ZIP completely.
2. Open `game104-character-foundation-windows-x64` and run `road-has-gone-dark.exe`; retain every sibling file/folder.
3. Escape skips intro. New Game → generate/select world → origin → hometown → character builder.
4. Before saving any adventurer, open **Identity** and choose **Use expanded martial content · new party only**. This explicitly selects current pack `trhgd-character-v3` / rules3.0.0 / engine2; existing campaigns remain on their exact earlier content.
5. Build/save all three individually. Search classes/feats; review the actual class-cap progression, skill budget, prerequisites, equipment/preparations and live sheet. Try Blade Dancer, Iron Bulwark and Road Stalker. Seven optional inherited traits show numerical modifiers in their picker tooltips. Culture, origin, profession and class remain separate.
6. Party ready → Enter hometown → existing opportunities → travel → fight → return. Characters opens the permanent sheet with actual summed BAB, attacks, saves, modifiers/ranks, resources and ordered class history. Home presence and actual earned journey XP gate advancement; no production XP/level grant exists.
7. Quit/relaunch and Resume Expedition. Earlier campaigns continue without deletion/recreation; their identities, class history, content pins and consequences remain unchanged. Confirmed parties cannot change packs; reviewed migration is future GAME-36 work.

Detailed Godot scene, keyboard/mouse and testing commands: [TESTING.md](TESTING.md). Screenshots: [screenshots/](screenshots/). Raw native proofs/timings and regression results: [VALIDATION.md](VALIDATION.md).

## Verification and limits

Final native workflow passed Windows and Linux: **887 exported journey checks plus 54 independent restart checks each**, with empty PATH and bundled dependencies. Real Linux/Mesa renders cover 640x360, 1280x720 and 2560x1440. Human Windows GPU/gameplay acceptance remains outstanding; native Windows automated execution was headless.

Available expanded content totals six original base paths, fifteen inherited records and twelve feats. The existing gated prestige path has some abilities not yet wired to tactical controls and labels them honestly. Finite current adventures limit normal earned progression; all twenty levels are mechanically validated through development fixtures. These original martial proof paths do not constitute complete Monk/Barbarian/Ranger/etc. equivalents. The eight prototype people are provisional, not a final ancestry roster. Prepared/spontaneous/divine/psionic/occult systems, class-specific proficiencies/skills, companions/summons, full ancestry/body/transformation mechanics and the remaining prestige programme remain open.

Engine2 makes new snapshot key serialization deterministic while earlier v1/prototype-v2 data and hashing remain intact. No automatic migration, combat rule rewrite, world-content expansion or second save writer is included. Retain old content files forever; follow [PROGRAMME.md](PROGRAMME.md) and issue82/children83–87 for exact continuation.

Linear tools are unavailable; GitHub tracking was updated, Linear was not. Artifact access requires GitHub repository access/login and expires after the workflow's 90-day retention. This is an unsigned review build. Keep PR81 and parent PR80 draft for human review.
