# Systemic encounters with credible choices and persistent outcomes

**Accepted — 17 October 2026, NPC and Monster Question 10 (B).** Design decision, not implemented gameplay.

## Decision

An encounter is a contextually generated situation among actors with actual motives, place, terrain, resources, history, knowledge and competing interests. The party can resolve it through different **mechanically valid** courses of action: combat, negotiation, stealth, relevant skills and spells, assistance, environmental manipulation, preparation, or retreat, whenever appropriate to the circumstances. Not every encounter offers all approaches. Decisions must produce distinct lasting consequences rather than cosmetic alternative buttons.

### Example

A troll controls a weakened trade bridge and a caravan cannot pass. A prepared party may fight and risk casualties; negotiate a toll or durable agreement; use genuine class skills or available spells to assist with the bridge; appeal to involved factions; scout, bypass or withdraw if geography permits. Each option requires actual capabilities, resources and factual context. The troll may refuse a bargain. Repair must be executable, not just narrative text. The recorded troll, bridge, merchant and faction outcomes must differ across the paths, and a resolved unique threat cannot silently respawn on return.

### Rules and persistence

- **Actual builds, not decorations:** eligibility, difficulty and results use GAME-32's attributes, trained skills, feats, class features, resources, spells, equipment and relationship authority. Identical encounters must be meaningfully different for contrasting legal party builds. Implement through the existing rules/effects/command systems, not a detached skill roulette.
- **Believable actors and knowledge:** creature instincts/morale (ADR 0004) and significant NPC motives, memberships and beliefs (ADR 0002 and ADR 0005) constrain which approaches are possible. Player Knowledge is distinct from world truth; a character may not automatically know hidden dangers or opposing interests.
- **Consequential resolution:** outcomes may alter injuries, relationships, access, resources, time, settlements, discoveries, regional risks and obligations. Partial success, failed checks, retreat and nonviolent solutions deserve truthful records, not identical loot/XP. Reward a resolved objective at most once; no repeatedly farmable equivalent choices.
- **One durable authority:** preserve canonical generated Site/source IDs, immutable World Template, per-Playthrough change records, saved actor identities, deterministic RNG, one existing campaign writer and replayable outcomes on a separate cold restart. Preserve prior source/rules pack pins and save versions.
- **Bounded generation:** compose compatible actors, stakes, context and legally supported resolution pathways. Neither every scene must have three choices nor every imaginable action has to be simulated.

### A useful first gameplay proof

One supported generated situation, grounded in existing world/site facts, must expose at least three genuinely different feasible approaches when appropriate, with visible legal prerequisites, actual character mechanics, different costs/risks and persistent consequences visible after returning. Test contrasting character builds at the same site; test failure, inability, withdrawal, restart and replay. Produce a real Windows-only Godot playable package and test evidence. This is a narrow implementation target, **not a claim that gameplay already meets it**.

**Implementation ownership:** build on [GAME-105](https://linear.app/marksprietsma/issue/GAME-105/use-actual-character-skills-and-class-abilities-in-procedural) for genuine noncombat character authority, GAME-96 for sandbox/source-pinned sites and persistence, GAME-101 for existing varied opportunities, and GAME-122 for future opposition diversity. Do not duplicate these with a new quest or combat engine.

**Rejected:** A, mostly fixed activities with superficial alternate buttons; C, unrestricted arbitrary creative action simulation without executable rules.

**Open:** UI, eligibility operator schema, checks, approach generation, resources, negotiation/stealth, partial outcomes, encounter time, NPC refusal, threat escalation and human gameplay acceptance. The user will test the Windows game after meaningful gameplay integration, not after each character/spell data update.

**Q11 accepted:** [ADR 0007](0007-species-art-and-combat-telegraphs.md) requires recognisable species/body plans and accurate combat telegraphs, with GAME-106 for humanoid LPC ancestries and GAME-140 for distinct nonhumanoid monsters. **Q12 accepted (C):** [ADR 0008](0008-integrated-living-world-prototype-milestone.md) requires the first upcoming player Windows test to encompass a broad integrated cast of creatures, settlements, NPCs, factions and different encounters, delivered by incremental engineering PRs.
