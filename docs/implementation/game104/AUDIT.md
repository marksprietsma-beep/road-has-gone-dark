# Complete character programme: architecture and coverage audit

Baseline: GAME-103 draft PR80, `6f3bba8099f202a0b536b445227d69a9d3b3722f`, with all outstanding CI workflows now successful. Main remains `a47f972`. This feature is stacked on PR80; neither PR is authorised to merge. The user's full-scope programme supersedes the older GAME-88 recommendations limiting production breadth, while retaining the accepted guide's separation of identity, build and acquired life history.

Inputs read: complete GAME-88 catalogue and accepted direction at research commit `c09e586`, GAME-32 contract, current kernel/builder, native delivery proofs and current CI. Toolchain/helper/templates already verified in the existing environment; no setup changes needed. No callable Linear connector is present. GitHub will carry implementation tracking and a precise Linear reconciliation file without claiming external updates.

## Coverage, including source discrepancies

`COVERAGE.json` accounts for every transcribed ancestry and prestige entry and each listed base/NPC class, retaining repeated source-group references. Actual unique names are **364 ancestry/subrace entries, 66 adventurer classes plus 8 NPC families, and 282 prestige paths**. These differ from index headline figures (~403/66/283) because the research transcription and index claims are not identical. Do not fabricate missing entries or silently claim the headline count has been implemented. NPC careers remain accounted for without being promised as starting adventurers. All entries initially remain researched, with individual stable IDs, original-equivalent licensing strategy and explicit category owner. Similarity to an existing starter class is not sufficient to mark a catalogue concept playable.

## Reuse and constraints

The existing kernel already has ordered multiclass history, caps, skills, typed requirements, feats, equipment, modifiers, bounded effects, resources and exact snapshot hashes. Existing save/journal locks, campaign owner, generated identities, source-world professions, combat authority, artwork and onboarding remain reusable.

Confirmed architectural constraints:

- The registry only recognises the v1 identity; campaign/UI/combat call sites always use that singleton. New definitions cannot be appended to v1 without invalidating every exact saved pin. First delivery adds an explicit installed-pack manifest, exact-reference resolver and per-record/per-campaign registry routing. No implicit migration.
- Creator previews contain draft records, not authoritative saved mechanics. Their art projection must construct a complete temporary preparation namespace so the existing validation can render all three current builds. This does not write or alter campaign state.
- Current small dropdowns need search and numerical explanations before scaling. First delivery adds search without changing actual choices, and displays actual class progression/feature modifiers from the registry.
- Attribute inheritance, size, vision, resistances, body slots and acquired overlays need typed capability extensions. Existing ancestry `modifiers` can safely express a first limited inherited-trait batch; it cannot honestly represent aquatic breathing, flight or transformations yet.
- Casting only recognises arcane capacity; preparations do not implement tabletop spell levels/slots/known-spell selection. Divine/spontaneous/psionic/occult systems need their own typed definitions and generic authority support. Do not label a generic spark caster as all these classes.
- Existing V0 tactical wiring accepts Attack, Guard, Spark, Slow and Healing Thread plus trusted precision/reaction hooks. Every new active ability needs real generic action/targeting UI wiring and deterministic manual/AI tests. Passive martial progressions are genuinely usable now without a combat rewrite.
- Class-specific skill lists, proficiencies, armour restrictions, hit dice, companions, summons, stances, manoeuvres and prestige world-achievement requirements are not represented fully. Keep these catalogue entries unplayable until those consequences exist.

## First coherent delivery

Separately pinned original `trhgd-character-v2` extends the unchanged legacy data. Three original martial paths have distinct twenty-level HP/BAB/save/skill progressions and tiered passive features: Blade Dancer (mobility/accuracy), Iron Bulwark (durability/guard with movement cost), Road Stalker (ranged accuracy/initiative/skill breadth). They are narrow original specializations, not complete equivalents of Monk, Barbarian, Ranger or other researched classes. Seven optional inherited traits and seven actual feats use existing validated typed modifiers/prerequisites. No Emberkin-specific art or mechanics are added.

The expanded pack is explicitly selected before confirming any starting character. Existing drafts and ready campaigns stay pinned; changing a confirmed party's pack is rejected. The same kernel resolves creation, advancement, combat, save/reload and home recovery. V1 source bytes, helper pins, RNG and original frozen combat remain unchanged.

## Ordered continuation to complete breadth

1. GAME-36: retain installed packs forever; add reviewed migrations only when necessary, manifest validation and source/licence audit gates.
2. GAME-108: typed inherited ability adjustments, sizes/movement/vision/resistance/body compatibility; then genuine ancestry/heritage combinations; acquired overlays retain original ancestry/class history.
3. GAME-109 / GAME-111: proficiencies/class skills, weapon choices, bounded combat ability wiring, prepared/spontaneous spell lists/slots and divine traditions. Preserve distinct concepts, not recoloured templates.
4. GAME-111: companion/summon authority, manoeuvre/stance and psionic/occult/binding systems, each with persistence and deterministic combat proofs.
5. GAME-110: catalogue-specific prerequisite/progression design, hybrid casting and world-achievement facts, then source-group coherent prestige batches.
6. Remaining catalogue rows: independently reviewable original designs, mechanical validation, real playable journey proof, and explicit exception rationale where licensing or incompatible source concepts require original adaptation.

This delivery is a programme checkpoint, not completion of the full catalogue. Coverage statuses must only advance with per-option evidence. No arbitrary final option cap is introduced.
