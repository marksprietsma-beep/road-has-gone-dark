# GAME-119 review steps

The verified Windows package link and inner-ZIP checksum are recorded in [DELIVERY.md](DELIVERY.md). Historical native Windows/Linux CI succeeded; human acceptance remains pending. Extract both ZIP layers and keep the executable, helper and artwork together; run road-has-gone-dark.exe. No Godot or Node installation is required. Escape skips the intro.

1. **New Game** → generate/select a world → origin → hometown. Fresh creator offers eleven familiar core classes automatically; existing campaigns deliberately keep their original exact rules pins.
2. Choose race/heritage/background/class. In **Build → Specialisation**, compare the two class choices. Examples: Wizard evocation/abjuration; Cleric healing/war domains; Sorcerer draconic/fey bloodlines; Ranger style and quarry. Review actual powers, finite resources and numerical effects. Review attributes, skill ranks, feats, spells and equipment; save all three adventurers and choose Party ready.
3. Prepare an opportunity, follow its lead, travel to the site and fight. Use the selected class ability and actual prepared/known spell where available. Resolve the encounter, return home and inspect Characters.
4. Review earned journey XP; **Advance** previews class/multiclass choices, prerequisite explanations, scheduled skill/attribute/feat choices and future features. Coincident class/general feat grants appear separately in the Feats tab. Commit an earned level, quit and Resume; identities, choices and progress must reload unchanged.
5. Prestige options appear in advancement, with entry requirements and legal casting-track selections. Current finite adventures demonstrate earned level two; they do **not** guarantee the XP for prestige entry or level12. Do not interpret development fixtures as ordinary earned advancement.

## Development verification

`GAME119_TEST_ROOT=<owned evidence directory> python tests/character_progression/run-tests.py` runs the actual Godot career/feat, prestige-entry, all-choice, prestige-combat and tactical suites. Use Godot4.6.3 and the existing project dependencies. Set XDG overrides to writable directories in cloud environments.

`tests/character_progression/review.tscn` extends the production New Game/opportunity review. Native exports execute six genuine hometown journeys, earned level-two advancement and old-campaign continuation. It additionally creates eight isolated development saves (four prerequisite-entry and four advanced prestige builds), through the existing save writer. These fixture histories are constructed by legal GAME32 choices. Original identities/consequences/earned XP remain unchanged; the high-level fixture is visibly labelled and advancement stays disabled without sufficient real XP. Another process reloads and verifies exact snapshots.

`GAME119_ADVANCED_ONLY=1` reuses an already completed review campaign checkpoint and captures only the isolated development fixtures. `GAME101_RESTART=1` verifies those saves in another process. These flags belong to the diagnostic scene, not the normal player journey; they do not grant production XP or upgrade saves.

Actual Godot PNGs are in `screenshots/`; file hashes are in `evidence/screenshots.json`. First-open/class-specialisation and normal earned-level screenshots are separate from the explicitly labelled higher-level fixture sheets/history/prerequisites/combat/reload.

All previous frozen GAME32/GAME94 oracles remain enabled. Original GAME118 v6 mechanical suites explicitly retain that historical pin. Fresh v9 and original legacy GAME81 input captures remain enabled in production-UI CI. A separate v4 campaign test protects exact old options, identities, byte-preserving navigation and reload.
