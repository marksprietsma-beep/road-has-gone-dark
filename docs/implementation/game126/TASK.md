# Codex task — GAME-126: Complete the character experience before expanding the roster

Repository: `marksprietsma-beep/road-has-gone-dark`

Linear: GAME-126, under milestone GAME-123.

**Before beginning, critically evaluate this task brief for technical accuracy, scope and completeness. Refine your implementation plan, but preserve the user's priorities and do not substitute a smaller permanent product vision.**

## Objective

The Road Has Gone Dark now contains a substantial character catalogue, but we need to establish whether those options are actually complete, mechanically distinct and playable throughout a character's career.

The priority is no longer simply adding more classes. It is ensuring that existing classes have comprehensive supporting feats, skills, spells, abilities, ancestry options and meaningful prestige opportunities.

Start from the latest `main`, including the integrated Wave Five v15 character pack. Read GAME-123, GAME-126, GAME-112, the GAME-88 catalogue and the current character-delivery evidence. Check actual source, not just issue summaries.

## Part 1 — Audit character completeness

Create a reproducible, machine-readable compatibility and completeness matrix covering:

**1. Base classes**

For every implemented base class, audit levels 1–20, class features, resource progression, multiclass eligibility, meaningful choices, signature capabilities, equipment compatibility and actual gameplay effects.

Identify empty levels, weak progression, placeholder mechanics and features that are listed but not executable.

**2. Prestige classes**

For every base class, identify which existing prestige classes can actually be entered through legitimate permanent prerequisites and earned advancement.

Test entry, progression through the prestige class's intended level cap, and continuation of the character's overall progression.

Identify classes with no meaningful prestige opportunities, unreachable prerequisites, dead-end builds or prestige choices with little mechanical identity.

Do not invent filler prestige classes to meet numerical quotas.

**3. Skills**

Audit every implemented skill, its progression, class availability, checks and effects.

Distinguish skills that genuinely affect existing gameplay from skills that only appear on character sheets or satisfy prerequisites.

Our eventual goal is a complete, functional skill system for supported characters.

**4. Feats**

Audit all feats for prerequisites, legal selection, level relevance, combat/noncombat effects, class synergies and actual execution.

Identify missing supporting feats for implemented class families, especially metamagic, martial specialisation, ranged, stealth, divine, psychic, summoning and defensive builds.

No duplicate bonuses or mechanically empty filler.

**5. Spells, powers and class abilities**

For every supported caster or ability-using class, audit its level-by-level repertoire and accessible resource tiers.

Check spell learning/preparation, targeting, resource costs, actual effects, action economy, resistance, saving, reloading and progression.

Identify thin or missing spell tiers, incomplete signature capabilities, inert effects and class families lacking appropriate choices.

Prioritise a coherent, genuinely usable repertoire for supported classes before adding additional caster classes.

**6. Ancestries and heritages**

Audit all playable ancestries and heritages for meaningful mechanical identity, character-creation accessibility, progression compatibility, body plans and equipment interactions.

Compare them with the full indexed race catalogue. Classify entries accurately as playable ancestry, heritage, template, transformation, monstrous/NPC option, duplicate or unresolved.

Our long-term ambition remains broad playable race coverage. Do not silently discard source entries, treat merely indexed races as implemented, or use unlicensed material.

## Part 2 — Prove actual playable character journeys

Produce a class-by-class and prestige-path compatibility report.

Test at least twelve representative builds across martial, stealth, arcane, divine, nature, hybrid, psychic and unusual ancestry combinations.

Verify legitimate creation, progression, distinct abilities, combat and relevant noncombat outcomes, XP-funded advancement, prestige entry or deliberate decline, and save/reload.

Include level-20 progression validation and clear separation between genuinely earned levels and development fixtures.

Every reported option must distinguish:

`Indexed → Defined → Selectable → Mechanically functional → Automated-tested → Player-validated`

Provide evidence for each claim.

## Part 3 — Deliver the first real completeness improvement

After identifying the highest-impact gaps, implement **one coherent, reviewable repair wave**.

Prioritise weaknesses in already-supported characters, such as missing skill functionality, hollow spell tiers, unreachable prestige progression, inert feats or absent signature class mechanics.

Do not add new base classes during this wave.

Use a new immutable versioned rules pack if content changes require one. Never mutate historical v1–v15 content or silently migrate saved characters.

Avoid unrelated world generation, settlement management, maps or new quest systems.

If the audit reveals several major architectural changes, separate them into clearly ranked follow-up issues rather than placing them into one enormous PR.

## Part 4 — Delivery and reporting

Maintain a clear coverage dashboard showing actual playable breadth, missing capabilities and prioritised follow-up work.

Publish:

- A human-readable character completeness report.
- Machine-readable class/prestige/feat/skill/spell/ancestry coverage.
- A ranked plan for subsequent completeness waves.
- A verified implementation of the selected high-impact repair.
- Automated tests and native Windows x64 evidence.

Preserve the existing GAME-32 combat authority, immutable rules-pack history, legitimate earned XP and deterministic save/replay.

Follow the project's Windows-only CI policy. No Linux CI.

Commit and push all work to GitHub. Create a PR against current `main`, run applicable checks and review results. Merge verified, approved-scope work only when required checks pass; do not bypass failures. Record the resulting PR and evidence in GAME-126 and GAME-123.

Do not mark GAME-123 complete on the strength of catalogue counts or an audit alone.

**Final objective: a player should be able to create a character from our supported roster and enjoy a coherent, mechanically rich RPG career, with real abilities, a useful repertoire, meaningful advancement and appropriate optional prestige choices—not simply see hundreds of names in dropdown menus.**