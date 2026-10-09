# GAME-94 audit and implementation boundary

Starting point: PR #72, `e02e22dca1d9e20a75c9a087d9e8565d44ecca01`, stacked on unmerged PR #71. The authoritative GAME-94 handoff chooses LPC alone. The accepted GAME-88 guide was read again; its ancestry examples are illustrative and the later user correction takes precedence.

The existing `CombatArt`, `CombatPawn`, `CombatEffect` and First Adventure controller are reusable. GAME-83 theme/responsive canvas, existing 8×6 tile buttons, deterministic command authority and single campaign writer remain the integration points.

## Findings before implementation

- The shipped LPC subset has 55 original PNGs: one male body/head, two orange hairstyles, pants/boots, plate/leather/laced shirt, wizard hat, longsword, bow shoot layers and cane walk pose. Almost every identity therefore receives the same silhouette/skin/hair; a hat hides the mage's hair entirely.
- Mechanical records already contain equipment. Vanguard has `shortblade`, `mail`, `shield`; Scout has `shortblade`, `bow`, `leathers`; Adept has `staff`, `focus-token`; Expert has `shortblade`, `leathers`. Authored raiders have only their weapon. The old art chooses mainly by weapon: it displays plate for mail, omits shields and gives raiders the same armour as party members. A giant longsword is also a poor shortblade preview.
- Bodies/clothing use native walk/slash/shoot/spellcast/hurt PNGs, but all face row 2. Sword attacks use a 192px oversize layer while the other layers use independent native widths. Hair animation is selected as Vanguard even for a bow user. Bow/cane layers are held poses in several actions. Idle holds walk frame zero. Effects and motion use Godot tweens; those are not original idle/walk/spell frames.
- The pawn clock loops each layer according to its own sheet width rather than one explicit animation timeline. Effects last 0.65 seconds regardless of source sequence. Downed hurt poses eventually settle but get reset by reconstruction. Every refresh recreates pawn Controls, interrupting visible motion on harmless mode changes. Zero HP delta is labelled Miss even when a guard absorbs damage.
- The pinned upstream generator has authentic directional idle/walk/slash/shoot/thrust/spellcast/hurt layers, additional body/head families, beards/ponytails, chainmail, robes, clothes, capes/hoods, small blades, paired bow foreground/background and shields. Its per-item metadata carries body compatibility, drawing order and licence alternatives. Its tree is too large for a complete recursive API response; inspect relevant directories/definitions directly instead of treating a truncated listing as absence.

## Focused V1 plan

1. Extend the existing data catalog with a selected compatible male/female humanoid subset, authored coherent wardrobe recipes and stable body/head/hair/palette choices. Use equipment records rather than provisional race/class-name enums. Raiders get rough clothing, no unowned armour/shields. Source-defined ordering and matching body-family clothing take priority over combination count.
2. Keep original PNGs unchanged and track selected item definitions, source revision, original hashes, contributors and chosen per-item licences. Palette adjustments are explicitly project-authored derivative presentation, with applicable art licences retained. Do not copy the upstream generator implementation.
3. Give the existing pawn one timeline and facing for all layers. Walk along the authority's route with direction per segment; play shortblade slash, bow shoot, staff thrust and casting frames once, with timed projectile/impact feedback. Keep held/equipment fallback poses explicit. Downed poses freeze; misses differ from guarded zero damage. Reuse pawn instances across harmless refreshes and bound every effect/cancellation.
4. Retire the production selector/F7; legacy non-LPC preferences resolve to LPC. Preserve GAME-93 sources/evidence and its draft. Export only LPC provider artwork and applicable credits, retaining the existing bundled helper and save path.
5. Compare the same generated party/encounter before and after using an isolated copied fixture. Capture all requested animations from actual Godot renders and resolved commands. Run First Adventure, GAME-32, GAME-83, appearance/integrity/animation/persistence and native Windows package checks. Deliver a separate stacked draft PR and verified artifact.

The remaining battlemap work is GAME-95. No geometry, new terrain, combat rules, ancestry mechanics, save schema or parallel character-rendering framework belongs here.
