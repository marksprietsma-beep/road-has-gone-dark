# Tiered NPC builds and bounded exceptional-encounter action economies

**Status:** Accepted — 17 October 2026, NPC & Monster Question 6 (B), with additional explicit player requirement for **lair actions** and action-economy support for bosses and epic people. This is **design direction only**; no boss or NPC system is implemented by this record.

## Decision 1 — mechanical depth follows actual NPC significance

Humanoid and intelligent non-player characters share the game's canonical d20 capability, effects, action and save authorities with the Player's Adventurers. The detail of their stored mechanical builds is **proportional to what they can credibly do and what currently matters to play**, rather than assigning the same twenty-level history to every unnamed resident.

- **Ordinary/background residents:** identity and context as needed, meaningful profession, aptitudes and relevant skills; can perform and contest actual checks. Broad crowds can remain aggregated. An artisan's mastery need not be represented as many Fighter levels or an automatically combat-effective heroic build.
- **Active specialists and repeat interactors:** guards, mercenaries, merchants, scholars, skilled artisans, travelling NPCs, named rivals and potential hires receive sufficient attributes, ancestry/heritage, skills, equipment and appropriate class/role capabilities to resolve actual tasks and fights credibly. Depth grows when a player recruits, fights, assists or relies on them.
- **Significant NPCs and exceptional people:** individually persistent identity, relationships, motives, competence, equipment, legal class/level/feat/skill/spell or prestige progression where suitable, real resource constraints and consequences. A known Archmage cannot merely carry a label and unlimited magic; an elite veteran needs the actual powers and limits that explain their reputation. Recruits and NPC combatants share the existing underlying character/effects/tactics, not a second NPC-only damage or spell engine.

**Promotion to significance:** an ordinary resident can become a consequential individual through player interaction or meaningful events. Retain established facts and provenance; add mechanical information when needed without retroactive fabricated experiences, duplicate identities, rerolled professions or contradictory levels. Not every resident must be fully generated in advance. Significant NPCs' bounded off-screen agency, relationships and personality development follow [ADR 0002](0002-bounded-offscreen-world-simulation.md), with change stored in the Playthrough rather than rewriting the World Template.

**Not every exceptional being is a humanoid class build.** A dragon, guardian spirit or ancient horror derives credible special abilities from species and identity, whereas an intelligent human, orc, lich or similar figure may additionally have lawful career training under the shared d20 rules. No fake human ancestry for nonhumanoid monsters merely to use a common battle core.

## Decision 2 — bosses and epic people need meaningful action-economy tools

**Explicit player requirement:** *Bosses and epic individuals should be able to use lair actions or comparable exceptional encounter capabilities so their significance and challenge survives the Party's multiple actions.*

The existing FFT-inspired base combat budget (move + main + shared reaction) is the default. A single noteworthy enemy should not routinely be trivialised by being outnumbered three-to-one, but **arbitrary inflated HP/damage, guaranteed immunity, secretly doubled turns or unlimited reactions** are not acceptable substitutes for tactical depth.

Distinguish complementary tools; this is not a requirement for every boss to have every tool:

1. **Lair or prepared-territory actions:** when a boss is in its established lair/stronghold, credible local advantages can act through explicit, bounded triggers and deterministic command/effect rules. Environmental hazards, shifting terrain, prepared defences, protective wards, followers, machinery or supernatural manifestations must relate to the location and can be sabotaged, resisted, escaped, interrupted or avoided where justified. A dragon cannot automatically use its cave's collapsing pillars in a city street.
2. **Exceptional actor responses:** at most scoped/limited extra reactions, conditional off-turn interventions, phase transitions, restricted action tokens or explicit abilities may let an epic opponent participate between the party's ordinary turns even when outside a lair. They are **personal abilities**, not automatically called “lair actions”. They obey a known, limited resource/action budget, legal trigger, timing and conflict rules. No new global free/swift/bonus-action layer by default.
3. **Encounter composition and objectives:** leaders can have guards, summons, allies, escape goals, rituals, protectable objects or multiple positions; a meaningful challenge need not always be a single boss in an empty square arena. AI and player commands share the one deterministic battle authority.
4. **Readable phases and counterplay:** major transitions, impending environmental effects or devastating techniques should be telegraphed appropriately and mechanically answerable (positioning, interrupting, dispelling, retreating, exploiting weaknesses, resolving alternate objectives), without turning every encounter into a memorised scripted puzzle. A boss may flee, bargain or surrender according to Q5's motives; “boss” does not mean hostile-to-the-death.

**Threat remains world-grounded.** Exceptional mechanics, location preparation, servants and abilities explain a legendary creature's power; they are not retrofitted to automatically match the current party's level. Parties should be able to learn credible danger signals and decide against confrontation consistent with Q4 and [ADR 0004](0004-regional-monster-ecology-and-creature-persistence.md). Epic NPCs' talent, resources and decisions persist across significant encounters and cannot reset or respawn without recorded causes.

### Authority and test boundary

Any lair action, extra off-turn decision, regional terrain effect or boss phase must operate through the **same** GAME-32/33 rules, TacticalCombat/RulesEffects command validation, bounded RNG, event logs and sole Playthrough save writer as other combat actions. If the current move/main/reaction schema is insufficient, add a reviewed and versioned **extension** to the shared action-budget contract—not a parallel special-case resolution engine or retroactive modification to historical immutable rules packs. The same legal action must behave identically under manual control and AI/autoresolve.

Future implementation must demonstrate visible phase/timing cues, initiative and per-round budget constraints, invalid-command rejection, immunity/resistance/interrupt behaviour, victory/retreat/defeat persistence, independent process cold reload, environmental applicability and absence outside the lair. Test representative 3-adventurer parties, solo powerful enemies, bosses with support, and basic enemies without exception features, across a range of seeded fights. Native Windows only.

### Examples (not implementation commitments)

- **Lair-bound ancient dragon:** periodically breathes fire through volcanic vents or collapses a prepared ledge, clearly signalled with positioning counterplay. Outside the volcano it retains dragon capabilities but not the location-specific triggers.
- **High-level archmage in a warded tower:** wards, prepared glyphs and controlled hazards tied to the tower, plus limited personal countercasting/interrupts; away from the tower the Archmage still has genuine spell slots, feats, limits and perhaps a scarce off-turn defence.
- **Warlord with retainers:** tactical command or rally interrupts and coordinated guards; an ordinary mercenary is not automatically granted a boss action merely because the encounter UI labels them leader.

These examples illustrate the desired design vocabulary, **not production features or approved precise cooldowns, initiative counts, extra-action numbers, damage values or ready-to-copy third-party ability text**.

## Alternatives rejected and boundaries

- **Q6 A:** NPC combat and high-level competence largely represented by shallow fixed statblocks, except a small handful of special actors. This would undermine reuse of the developed character mechanics and could cause arbitrary class-asymmetric enemy rules.
- **Q6 C:** full ancestry, class, XP, feats, skills, equipment and prestige career reconstruction for virtually every bartender, artisan or farmer. This is excessive simulation and a waste of content effort.
- **Bosses as pure stat inflation:** raising HP/damage until a 3-vs-1 match feels fair, while the opponent still takes only one ordinary action, is not the goal.
- **Generic portable lair magic or invisible free moves:** a lair power needs a real location and counterplay; personal extraordinary responses must be disclosed, bounded and deterministic.

## Dynamic recruitment, independent loyalties and credible separation — accepted 17 October 2026 (NPC & Monster Q7, B)

**Many NPCs may become companions, employees, allies or rivals through believable circumstances**, rather than recruitment being limited to a hand-authored selectable cast. Availability and willingness depend on their established personality, motives, competence, relationships, duties, faction ties, knowledge, personal safety, promises, material terms and unfolding Playthrough history. It is *not* an unrestricted ability to convert nearly any NPC into a party member by passing a universal persuasion roll. NPC consent, existing commitments, social situation and practical constraints matter.

**Relationships can take different forms without conflating them with permanent party membership:**
- **Temporary hire or contract:** an agreed service with a credible duration, pay, risks, responsibilities and possible extension or negotiated ending.
- **Travelling or long-term companion:** an NPC who journeys with the Party and may participate meaningfully in its adventures, develop skills and relationships, bring personal objectives, and choose to remain or eventually leave.
- **Ally or contact:** helps with information, influence, local support or particular commitments without necessarily becoming a controllable combat unit.
- **Rival, enemy or former opponent:** may oppose, bargain, reconcile, surrender or later cooperate where motives and history permit. Defeating an NPC does not itself grant recruitment rights.
- **Employer, patron or delegate:** supports or entrusts objectives under meaningful agreements and bounded agency; a hired or appointed person retains their own judgement under the prior [ADR 0002](0002-bounded-offscreen-world-simulation.md) mandate contract.

**Loyalty is earned and contextual, not a flat permanent unlock.** Trust, obligations, personal ethics, faction duties, treatment, unmet terms, compatible or conflicting aims, past sacrifices, mistakes, promises and relationships can influence an NPC's willingness to join or stay. An NPC may refuse a mission, request different terms, leave voluntarily, be called home, pursue another goal, change allegiance or—under **credible, consequential circumstances**—betray a commitment. Such changes must follow established facts and interpretable motivations, not random betrayal dice, an arbitrary friendship meter or universal passive relationship decay. Earlier fair-warning principles apply to major avoidable losses where appropriate; twists may still be uncertain and personal beliefs may be mistaken. Character-specific consent is not a mechanic that obligates loyalty.

**Independence persists within and outside the Party.** A significant NPC's personal relationships, history, ambitions and beliefs do not disappear upon recruitment. Party combat commands may be handled through the same shared character and tactical authority, while longer-term acceptance, refusal, departure and delegated choices reflect the NPC's own agency; exact control boundaries and limitations on orders are **not decided here**. Player-controlled Adventurers remain governed by the accepted player-autonomy rule in ADR 0002: NPC independence must not be used to covertly seize control of a character the player already owns.

**Mechanics and persistence:** identity and class/skill/equipment progression must remain consistent with Q6's tiered NPC depth; if a lightly represented person becomes recruitable or significant, retain their established traits/relationships and add supported mechanical detail without rerolling history or inventing past class levels. Employment and companionship form explicit Playthrough commitments with meaningful consequences of joining/leaving, and the same campaign journal and versioned rules remain authoritative. Named companions remain identifiable after separation; they are not removed from the world or respawned as interchangeable mercenaries.

**No decision to support unlimited active party members.** Recruitment breadth, roster/storage size, active combat party count, replacement of the current three-character testing formation, wage calculations, party-leader control, defection/return conditions, progression for nonactive allies and capacity constraints need separately scoped implementation decisions. Asymmetric relationships with third parties, NPC information limits, delayed communications and bounded off-screen actions continue to follow ADR 0002. Do not equate the number of recruitable contacts with the number of simultaneous combatants.

**Rejected:** (A) only designated recruits with generally simple permanent loyalty, and (C) near-universal recruitment of arbitrary inhabitants. **Accepted B** balances dynamic social possibilities with believable human agency and the existing bounded simulation model.

**This is a design decision, not delivered gameplay.** Do not treat existing three-adventurer party creation or NPC generation as proof that contract negotiation, recruit acceptance, departure, betrayal, companion progression or relationship-driven recruitment exists.

**Next interview dependency (Q8):** influence of factions, cultures and NPC-to-NPC connections on loyalties, conflicts, settlement reactions and recruitability.

## Implementation dependencies

- [GAME-134](https://linear.app/marksprietsma/issue/GAME-134/milestone-living-bestiary-humanoid-npcs-and-meaningful-opposition): programme for creature/opposition/NPC systems.
- [GAME-135](https://linear.app/marksprietsma/issue/GAME-135/npc-and-monster-design-grill-ecology-agency-and-encounters): decisions. Q7 next asks about NPC participation/recruitment and relationship roles.
- [GAME-33](https://linear.app/marksprietsma/issue/GAME-33/build-deterministic-grid-combat-simulator-shared-by-manual-and-auto): accepted extensible single action-budget combat baseline; [GAME-86](https://linear.app/marksprietsma/issue/GAME-86/research-fft-style-d20-combat-model-action-economy-and-meleeranged) establishes the basic action economy.
- [GAME-122](https://linear.app/marksprietsma/issue/GAME-122/expand-procedural-combat-encounters-beyond-repetitive-bandits): more varied world-grounded opposition; [GAME-96](https://linear.app/marksprietsma/issue/GAME-96/procedural-sandbox-spine-v1-generate-contextual-sites-encounters-and): grounded encounter/site persistence.
- [GAME-136](https://linear.app/marksprietsma/issue/GAME-136/boss-and-epic-npc-action-economy-lair-actions-and-bounded-off-turn) tracks a **separate narrow action-economy boss encounter**; finish the design interview before authorising implementation. Start with one evidence-backed vertical slice; do not create an encyclopaedia or a parallel combat engine.

Open particulars: exact depth threshold per NPC, whether class builds remain permanently materialised once an NPC is significant, leadership and recruitment contract, boss encounter timing model, how lair features are derived from procedural sites, UI telegraphing, action resource budgets, balance and difficulty tests. These require implementation review, not another mandatory broad design round.

**Q7 resolved:** dynamic and credible recruitment plus independently motivated companions, employees, allies and rivals; see the accepted section above. **Next focused question (Q8):** how factions, cultural identity and cross-NPC relationships shape loyalties and regional consequences.
