# Prioritise a broad integrated living-world prototype before the next personal Windows playtest

**Status:** Accepted — 17 October 2026, NPC and Monster Design Question 12, **C**.

This closes the twelve-question NPC/monster design interview (Q1–Q11 captured in ADRs 0004–0007) and selects the next **playable integration milestone** for *The Road Has Gone Dark*. The player explicitly prefers a **broader connected prototype containing multiple species, NPCs, settlements, factions and encounters before the next hands-on Windows playtest**, over either an isolated monster-combat slice (A) or a single living adventure as the final milestone (B).

This is not a directive to build the entire game at once. Implementation can and should be split into narrow, independently reviewed and Windows-validated PRs; what must not shrink is the **breadth of the combined user-facing acceptance build**. A demonstration of one encounter alone is a valid engineering proof en route, **not satisfaction of Q12(C)**.

## First integrated release target — coverage and proof

These quantified targets are initial **engineering acceptance goals** rather than invented mandatory lore or requirements to simulate every world entity. Audit against actual canonical content and source-backed locations before fixing witness counts and seeds.

| Area | Integrated evidence required |
| --- | --- |
| Living bestiary | At least **four genuinely mechanically different** creature species across distinct ecological or supernatural contexts, including **two nonhumanoid body plans** with actual natural/special attacks, different dispositions and real enemy AI/skills where supported. Ordinary creature population groups and separately persisted significant individuals where consequential; no fake humanoid-only monster actors. |
| Places | At least **two inhabited settlement contexts**, correctly anchored in distinct canonical geography; one meaningfully nonhuman or mixed-culture community. Recognisable inhabitants and local interests, not necessarily full settlement-building UI or individual schedules for every resident. |
| People | At least **six distinct persistent NPCs**, with contrasting skills, jobs, beliefs and ties; include a genuinely interactable recruit/temporary hire, a rival/contact, a person capable of fighting or casting with real shared rules, and someone who can change behaviour or location after a significant outcome. |
| Factions | At least **two identifiable organisations/groups** with divergent interests, a meaningful alliance/dispute and at least one NPC with competing allegiances. Outcomes update relevant individuals' and factions' world truth, without global omniscient reputation or automatic all-region ticks. |
| Encounters | At least **three contextual generated encounter families** in different real site contexts, not just three scripted conversations. Across the family set, show different real character-driven combat, negotiation, investigation, aid, avoidance/retreat or environmental alternatives when supported, with **at least three materially distinct outcome patterns** persisting across revisits. |
| Exceptional actor | One noteworthy monster or epic person with a special action and demonstrable multi-character pressure; **lair-linked** environment action or appropriately bounded personal off-turn capability under GAME-136, with real timing, telegraphing and counterplay. It cannot be simulated through inflated HP or undocumented bonus turns. |
| Art / information | Legible genuine species silhouette, movement, anatomical scale, real equipped gear when appropriate, known-status/special-action telegraphs and readable non-colour information. Use Universal LPC for compatible humanoids, separate reusable nonhumanoid sheets where needed, licensed attribution and honest fallbacks. |
| Save and delivery | From generated world, origin and built Party through exploration, inhabited places, real NPC/creature confrontation or peaceful resolution and revisitation. Persistent identities, deaths/migration when applicable, changes to world situations, Player Knowledge, faction relations, resources and site state; deterministic multisource seeds, source/rules pins, old-save regressions and **cold process restart**. Deliver one usable **Windows x64 Godot build** with exact controls and factual logs/screenshots. |

A broad prototype must integrate the above; no set of disconnected isolated scenes or hidden fixtures counts as a finished release. The same generated world should connect its towns, regional ecology, nearby encounter sites and consequence records. Not every potential action, NPC or faction needs to exist at every location.

## Integration stages — interim engineering gates, not user playtest milestones

1. **Truthful baseline and contracts (GAME-142).** Audit actual repository implementation and rules pack, one authoritative actor/character and battle command model, Site and stable identity provenance, NPC history and single Playthrough writer. Identify already-tested pieces versus designed-only future systems. Produce a target test/seed matrix, branch/PR plan and gaps. *No fresh big gameplay implementation before interfaces are grounded.*
2. **Species, opposition and encounter mechanics.** Extend existing GAME-122 and GAME-96 pipelines with species-native actors, body/ability data, world-grounded threats, realistic tactical AI/morale and multiple encounter group families. Never reroll unique defeated threats or instantiate nonhumanoids as fake humans. Version new manifests and protect historical character packs.
3. **Actually inhabited settlements, societies and connected people.** Integrate existing world peoples/source-backed sites (GAME-10, GAME-139), significant NPC progression/relationships and recruitment (GAME-137), bounded faction conflict/agency (GAME-138), local guild and settlement context (GAME-29). More than one location and enough NPC variety to show cross-site consequence and loyalty, without universal citizen schedules or global political simulation.
4. **Cross-system adventures, powers, and presentation.** GAME-105 actual skill/spell/feat selection in noncombat; GAME-101/96 persistent opportunities; one exceptional foe or lair action from GAME-136; distinctive creature art/telegraphs from GAME-140 and humanoid LPC work (GAME-94/106/107). Verify options have different mechanical and world-state effects. Maintain a single deterministic RulesEffects/TacticalCombat engine and one save writer.
5. **Integration quality / Windows handoff.** Multiple generated worlds/hometowns, party build contrasts, outcomes and NPC survival/defeat/refusal/retreat, contested factions, restart/regression tests, visual evidence and accurate human instructions. Player's next **manual** test is the integrated broad package. Interim automated/code-level and CI verification can occur at each stage.

The initial broad release is a **prototype**, not a commitment to implement hundreds of creatures, every v17+ class option, complete politics/economics, large-scale settlement construction or all personality possibilities before testing. Q12(C) trades a later manual checkpoint for more credible connected breadth; errors should still be caught in early smaller PRs.

## Current evidence / gap

As of the accepted decision, source inspection shows:
- Generated hostile records in `scripts/combat/tactical_combat.gd` still use class recommendation and `heritage-human`, while `scripts/rules/rules_entities.gd` produces companion creature records on that interim base. Native hostile monster species and natural/supernatural anatomy need real integration.
- Legacy `data/sandbox/generation-v1.json` uses only `blade`/`bow` compositions. GAME-96/101 and opportunity cycles offer bounded procedural scaffolding, but not this integrated multi-species/social range.
- GAME-105 remains the dedicated noncombat actual character-build resolution task. GAME-136–140 represent designed subsystem tasks, not proof they are merged or playable.
- Character options are comparatively advanced; additional isolated character-data expansion must not masquerade as improved world/NPC gameplay.

These facts can change as implementations merge; GAME-142 must re-audit the then-current repository rather than assume static gaps.

## Controls and work ownership

- **Programme:** [GAME-141](https://linear.app/marksprietsma/issue/GAME-141/milestone-broad-integrated-living-world-prototype-before-windows), under [GAME-134](https://linear.app/marksprietsma/issue/GAME-134/milestone-living-bestiary-humanoid-npcs-and-meaningful-opposition).
- **First integration contract:** [GAME-142](https://linear.app/marksprietsma/issue/GAME-142/audit-current-game-and-lock-integration-contracts-for-broad-living).
- **Existing implementation owners:** GAME-122 real creature encounters; GAME-105 true noncombat character abilities; GAME-96/101 sites/encounters; GAME-136 exceptional actors/lair actions; GAME-137 recruitments; GAME-138 factions; GAME-139 nonhuman societies; GAME-140 nonhumanoid art; GAME-94/106/107 LPC humanoids/equipment; GAME-10 peoples and GAME-29 guild/settlement support.
- **Canonical design:** [ADR 0001](0001-world-template-playthrough-boundary.md) immutable source/world vs Playthrough; [ADR 0002](0002-bounded-offscreen-world-simulation.md) bounded consequential simulation and significant NPC agency; [ADR 0003](0003-player-holdings-strongholds-and-settlement-management.md) settlement/holding scope; [ADR 0004](0004-regional-monster-ecology-and-creature-persistence.md) Q1–Q5; [ADR 0005](0005-tiered-npc-builds-and-boss-action-economy.md) Q6–Q9 and lair actions; [ADR 0006](0006-systemic-encounter-approaches-and-persistent-outcomes.md) Q10; [ADR 0007](0007-species-art-and-combat-telegraphs.md) Q11.

**Non-negotiables:** Windows-only native validation and handoff, no wasteful Linux gates; seeded/reproducible action and sources, pin older immutable rules/saves, no parallel combat/skill/XP/save engines, no general always-on world simulation, no obligatory level scaling, no repackaging old static data as new gameplay. Document all truthful coverage, known omissions and per-wave evidence.

## Rejected options

- **Q12 A:** separate monster combat first and leave social worlds for much later.
- **Q12 B:** one complete living adventure as the user-facing next test milestone. Such a scene can be a test fixture, but is *not broad enough* for the requested player test.
- **Unapproved extrapolation:** building a worldwide every-entity simulation or an effectively feature-complete RPG before any further merged and automated evidence. Q12 C does not request that.

**Status:** Design interview is complete at Q12. Move from questions to scoped implementation and progressive merge work; ask only when a material delivery dependency truly cannot be resolved from the accepted decisions.
