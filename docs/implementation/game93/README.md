# GAME-93 — Four original combat-art providers

This draft builds on First Adventure V0 / PR #71 at `fa1b31c9e609335c55ba572f6600bef55435ff9e`. GAME-83's shared theme/responsive canvas already exists in that branch. It reuses the actual three persistent companions, authored blade/bow raiders, campaign controller, 8×6 encounter, targeting and deterministic tactical engine. No parent draft is merged.

The authoritative input is Mark's GAME-93 handoff in this conversation, including the correction that the eight GAME-81 peoples and GAME-88 ancestry examples are provisional. The accepted [GAME-88 direction](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/research/game-88-dnd35-character-options/docs/design/character-identity-build-life-direction.md) and supporting character-options catalogue were read from that branch (`c09e5864245c1a7eef9ace7b71f79ac9928c04d8`). Identity, culture, build and acquired history remain separate; no ancestry mechanics are added.

## Playtest

The Windows artifact and checksum are recorded in [BUILD.md](BUILD.md).

1. Extract GitHub's artifact ZIP, then the contained `game93-four-art-styles-windows-x64.zip`. Run `road-has-gone-dark.exe` from the extracted folder. Keep `worldgen-helper` and `artwork` beside it. Godot, Node and extra asset downloads are unnecessary.
2. Escape skips the intro. Use **Resume Expedition** for an existing in-progress First Adventure campaign, or **New Game** → generate/select a world → state/region/hometown → confirm origin → party ready → enter hometown.
3. **Prepare first adventure** → choose a local account → **Accept** → **Begin expedition** → **Scout** if required → **Travel** → **Fight** at Bandits on the Old Road.
4. The top-right selector chooses Universal LPC, Kenney Roguelike, 0x72 DungeonTileset II or Navinius Modular. **F7** cycles them. Switch repeatedly before and after movement/attacks; names, HP, turn, Focus, movement and log remain unchanged.
5. **Move** then click a dotted tile; **Attack** or an ability then click a highlighted legal target; **End turn** advances play. Hover a unit to read its exact name, weapon and HP. Numbered diamond badges identify companions; B/A cross badges identify the blade/bow raiders. Gold marks the active unit.
6. Victory or **Withdraw · defeat** → **Return to regional play** → return home. Inspect the companion history. Exit/relaunch and resume: the selected art and character appearances return.

The source scene is `scenes/combat/first_adventure.tscn`; normal entry is `scenes/intro/intro_sequence.tscn`. Opening combat alone without a campaign handoff deliberately offers a menu return. Use the normal player path for review.

Saves remain in `%APPDATA%\Godot\app_userdata\Road Has Gone Dark`. The separate `presentation.cfg` in that directory contains only the visual preference. Existing campaign bytes/schema are unchanged. This unsigned playtest may trigger Windows reputation prompts.

## Original sources and obligations

| Provider | Acquired original | Composition/animation | Practical limitation |
| --- | --- | --- | --- |
| Universal LPC | Generator revision `58ce1aa479e4df32845a73a5d0afc221c3a893c2`; 55 selected original PNG animation layers, full credits | 64px body/head/hair, pants, boots, armour/shirt, hat and blade/bow/cane layers; source walk/slash/shoot/spellcast/hurt frames | This spike ships one humanoid body family, not the whole ancestry catalogue. Some weapon frames are held poses with Godot projectile effects. Per-layer OGA-BY / CC-BY-SA obligations apply. |
| Kenney Roguelike Characters | Original pack 2.0 ZIP; CC0 | Original 16px transparent atlas with 1px spacing; modular body/clothes/hair/headwear/weapons. Godot motion/impact effects. | ZIP distributes a packed atlas, not hundreds of separate PNGs. Limited silhouettes and native animation. |
| 0x72 DungeonTileset II | Original v1.7 ZIP; CC0 | Original knight/elf/wizard silhouettes, weapons and idle/run/hit frames. Godot attack/spell effects. | Ready-made costumes are less flexible; their ears/proportions are provider art, not an ancestry interpretation. |
| Navinius Pixel RPG Modular Kit | Original WIP ZIP, acquired 9 October 2026; CC0 | Original body, hair, armour/clothing, headwear, sword/shield and slash layers; Godot animation. | No original bow or staff is supplied. Those two props are Godot-drawn and explicitly labelled in the combat UI; no other pack substitutes for them. Small WIP silhouette/colour selection. |

481 original source resources are individually SHA-256 pinned in [`data/art/sources.json`](../../../data/art/sources.json). The three original ZIP hashes and original source URLs are retained there. All PNGs remain unchanged. [`ART-CREDITS.txt`](../../../assets/combat/ART-CREDITS.txt) and the full LPC credits specify contributors, original work URLs and licence choices. Vendored originals use Git attributes that preserve their bytes/line endings, including upstream whitespace.

The Windows distribution includes original layers, credits and source/style manifests outside the executable in `artwork/`, in addition to embedded game resources. LPC runtime arrangements/scaling/compositions are offered under CC-BY-SA 3.0; original layers keep their own selected licences. This applies to artwork, not gameplay code. The CC-BY-SA URI is included; the official legalcode download endpoint returned HTTP 403 during acquisition. No source artwork was blocked or replaced on that account.

## Appearance boundary

`CombatArt` reads a data catalog, derives a separate `trhgd-visual-v1:<character ID>` seed and builds provider-specific recipes. It never consumes combat RNG. Palette variants are genuine source layers; the four providers are independent libraries. Runtime member names and IDs always come from the saved campaign. Equipment changes select appropriate clothing/weapon presentations without reseeding identity. Expert blade users have a lighter clothing preset.

The visual profile carries distinct identity provenance, inherited body, heritage layers, equipment layers, acquired layers and an optional visual transformation descriptor. Body descriptors carry a plan, size/proportions, surface, anatomical parts and optional features. Provider-specific `visual_recipes` can replace a complete silhouette; same-provider overlays can append authored horns, tails, prosthetics or other layers at explicit native-frame offsets. These are presentation inputs for future authored content, not gameplay systems or existing ancestry coverage.

Unknown anatomy/features visibly report a **neutral humanoid preview**. They are not mapped from the eight prototype IDs, culture names or biography. Full replacement/overlay paths stay inside the selected provider's asset namespace. There is no Emberkin art branch and no final race enum. No body alteration rewrites inherited identity or class history.

`CombatPawn` draws original nearest-filtered layers and HP/badges. It animates only after an authoritative command is saved. Movement follows the engine's existing reachable route; attacks lunge; ranged/abilities produce short Godot traces/rings; HP deltas drive flashes/floating text; downed units retain defeated poses. Effects can be interrupted by subsequent input/style switching and are never replay authority. Existing combat logs do not record individual reaction events structurally, so a reaction miss is not separately choreographed; HP deltas still show its damage.

The battlefield occupies more of the responsive canvas. Tile hitboxes remain tied to the original coordinates. At 640×360 the order moves to its tooltip/sidebar and details scroll; 1280×720 or larger is preferable for visual comparison. Optional styles with missing resources are disabled and labelled, and missing silhouettes show an explicit neutral token.

## Validation and recommendation

See [VALIDATION.md](VALIDATION.md) for executed checks and comparable actual Godot screenshots at all three requested resolutions. Native Windows release QA verifies the complete flow with an empty PATH and the bundled helper; Linux/Mesa supplies the rendered/input evidence. Windows desktop/GPU feel remains a human review check.

LPC is the strongest candidate for future character customisation because its genuine layered animations and larger upstream body library fit the intended long-lived identities. 0x72 is a useful clarity benchmark. Kenney and Navinius keep the tiny-pixel approach legible but need more authored silhouettes/equipment for the eventual fantasy breadth. This recommendation does not lock the final art direction or imply unsupported ancestries already have artwork.
