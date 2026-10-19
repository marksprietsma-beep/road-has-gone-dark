# GAME-146 delivery

The bounded mobile/precision repair is implemented in immutable `trhgd-character-v20`. Fresh campaigns use v20; existing campaigns keep their exact historical pins. All v1–v19 pack bytes and manifest rows are preserved. Original GAME-32 authority, single campaign writer and action economy remain in place.

## Actual improvements

- Scout, Swashbuckler and Duelist strike riders apply only after a confirmed hit, including late techniques. A miss or concealment still spends the legal action/resource, but grants no hit rider.
- Rogue and Arcane Trickster levels share precision scaling. Precision requires a living adjacent allied melee threat and an ordinary confirmed hit, consumes once per activation, and can accompany actual-movement Scout skirmish on the same qualifying hit. Reactions and a nearby ally holding a bow cannot trigger it.
- Finesse substitutes Dexterity for lower Strength without swallowing independent training. Actual active Travel Blade, light/no armour, no shield and no form are required; virtual weapon overrides cannot inherit inventory-blade eligibility. Fencing descriptors enforce the same restrictions. Class/feature text describes fencing rather than unsupported general disarming.
- Mobile Skirmisher now adds an effective untyped stride point instead of duplicating the Scout training modifier. Legal movement/path boundaries, feat prerequisites and historical stacking are tested. It adds no action or movement token.
- Knight challenge and adjacent Guarding protection were verified: actual costs, positioning, reduction on a hit and shared reaction competition. No forced AI taunt is advertised.

## Verified Windows build

[Download Windows x64 artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39190333104/artifacts/12160967657). GitHub delivers an outer artifact ZIP; extract it, then extract `game146-mobile-precision-windows-x64.zip`. Open the extracted game folder and run `road-has-gone-dark.exe`. Keep all bundled files together; no installed Godot or Node is required.

Playable inner ZIP SHA-256:

`72a2bc9cbf64dc64da7b9cd3de6f748e47f52737fb58f33983556f988e3cc052`

Tested implementation source: `b2cb64c776d776156afd4793fc1742bb42d6256b`. Rules hash: `27d34787937d48f72bcd8710808d837a6eec5c4f3d93fcfe7ae3fccf336683a9`. [Complete successful Windows workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39190333104); [native evidence](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39190333104/artifacts/12160329100). The independent archive audit checked CRC, paths/duplicates, both Windows AMD64 binaries, production startup flags, exact canonical v20 content, licences/credits, removal of the QA executable and all16 PNG hashes/dimensions. Later source-tooling/readiness/evidence changes do not alter the exported gameplay; runtime-equivalence receipt records the exact comparison.

## Verification and evidence

All21 native phase receipts have zero failures:621 focused mechanics/33 cold;956 current signature/83 cold;956 archived v19/83 cold;598 v18/31 cold;818 legacy/4 cold;1,941 compatibility/486 cold;2,596 current kernel audit/65 cold;615 earned journey/8 cold;632 earned prestige journey/8 cold;43 connected battle/41 cold;8 production-input checks. These cover different scopes and historical pins, not21 independent gameplay systems. All32 base tracks are kernel-checked to20; this alone does not establish complete tactical identity.

The two genuine procedural-opportunity journeys earn490XP and reach level8 through normal campaign authority, without arbitrary grants. One advances Scout/Rogue/Knight; the other explicitly selects Duelist and Arcane Trickster after permanent eligibility, with decline/no-automatic-assignment checks. Rest generates no XP. Level20 and full five-level path witnesses are development fixtures. The connected campaign exercises actual battle resolution, rewards, return/rest and exact separate-process next-command/RNG replay.

All nine accompanying source-head Windows workflows passed: rules39190335949, UI39190335937, party39190335938, profiles39190335920, context39190335988, enrichment39190335994, library39190335953, origin39190335954 and world-save39190335945. Current final-head publication checks must also pass before merge. No Linux game test/build was run.

[Unmodified Godot screenshots](SCREENSHOTS.md), [full native receipt](evidence/final-distribution-proof.json), [archive audit](evidence/final-archive-audit.json), [attempt history](TESTING.md), [complete readiness matrix](../game129/READINESS.md).

## Review instructions

1. Launch the extracted executable. Keep any existing saves; do not delete them. For new mechanics choose New Game, generate/select a world, choose origin/hometown, and create a party including Scout, Rogue or Swashbuckler. Fresh characters pin v20; older campaigns retain their original mechanics.
2. On the character sheet inspect feats, abilities, costs and equipment. Mobile Skirmisher requires Scout4 and Mobility. Fencing requires Travel Blade/light gear/no shield and cannot be used while transformed.
3. Follow an opportunity to tactical combat. Move the Scout before its first qualifying hit; merely spending movement is insufficient. Position a melee ally beside the Rogue's target. Compare attacks without that threat, misses and subsequent hits; precision must not recur during the same activation.
4. Use a legal fencing technique: the action/resource is spent on hit or miss; only a confirmed hit grants its rider. Use Guard with a Knight adjacent to an ally and observe the shared defensive reaction rather than assumed AI taunting.
5. Resolve the opportunity, return home, rest, save and fully exit/relaunch. Resources recover through rest, saved outcomes persist and reward replays cannot duplicate XP. Earn XP before selecting advancement. Prestige is optional, permanent-prerequisite gated and never a starting class.

The automated high-level fixtures are not exposed as production XP buttons or replacement saves. Review receipts/screenshots for those late-career cases.

## Remaining scope

The roster is unchanged:32 base classes,18 prestige paths,37 ancestry families,50 heritages,83 defined feats,14 skills,45 selectable psychic powers and14 creature definitions. Base level cap20; path caps5. Counts are definitions, not a claim every option has complete functional acceptance.

Readiness:12 scoped COMPLETE,38 PARTIAL,0 reproduced BLOCKED. COMPLETE means the bounded original class identity has evidence, not complete tabletop parity or final balance. Marshal/War Chanter reuse explicitly labelled unchanged historical native aura/earned evidence alongside current kernel/cold checks; they are not relabelled as fresh v20 aura runs.

Known limits: Travel Blade is the current fencing weapon; no general disarm, AI taunt or tabletop panache regeneration is implemented. Long combat ability labels can clip at640×360 and1280×719, and hover feedback can overlap the panel; screenshots retain those actual pixels. Windows captured the requested720-height window at719 content pixels; filenames and evidence report the real dimensions. Large sheets require scrolling. Human balance/playability acceptance remains separate.

Next bounded GAME-123 task: audit Warlock, Binder and Dragonfire Adept pact/invocation/breath consumers, then fix the strongest2–4 reproduced identity/resource/counterplay gaps. Do not grow the roster or start GAME-141/142. GAME-123 and the full catalogue programme remain open. No callable Linear connector is available; GitHub#138 and parent#101 carry the delivery status.

Publication: [PR139](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/139). Final-head checks/merge and post-merge status are recorded in GitHub and the final delivery report; this receipt does not anticipate a merge SHA.
