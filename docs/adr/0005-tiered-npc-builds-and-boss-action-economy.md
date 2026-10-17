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

## Dynamic factions and overlapping loyalties — accepted 17 October 2026 (NPC & Monster Q8, B)

**NPCs may hold several meaningful affiliations at once.** A mercenary may owe contractual duties to a guild, affection to family, allegiance to a settlement and friendship to an adventuring companion. Their responsibilities can compete. Individual people can disagree with leaders, question their organisation, renegotiate terms, assist outsiders, switch affiliations or take other plausible paths. No faction or culture automatically controls every member's beliefs and choices.

**Factions have contextual goals and capacity.** Guilds, factions, faith organisations, households, settlements and other groups can maintain aims, alliances, rivalries, resources, hierarchies, obligations and internal differences. These affect relevant opportunities, recruitment, protection, negotiation and regional developments. Relationships may change through consequential, recorded events: defections, aid, discovered wrongdoing, disputes, alliances, leadership changes, shared threats and settlement events. Do not assume every faction pursues every possible objective constantly.

**Faction standing is not a universal reputation number.** Distinguish what an organisation actually did, what each individual or faction knows or believes, and what the player has learned. News, testimony and orders must travel through credible in-world channels. An NPC may support the Party without their employer agreeing, and a faction's hostile leadership does not make all its members enemies. Reputation, recognition and sanctions are context-dependent and may vary between places, institutions and people. Accepted ADR 0002 principles for NPC beliefs, sparse relationships, bounded initiative and imperfect communication remain authoritative.

**Identity, culture and species are distinct from politics and morality.** Cultural membership, religion, ancestry or monster species is not a mechanical assignment of universal virtue, hostility or allegiance. Historical and social institutions can still influence choices, opportunities and conflicts in grounded ways. Some creatures and factions may have established violent or controlling goals, but individual exceptions and political divisions should remain possible where intelligence and social context warrant them.

**Bounded persistence, not continuous global politics.** Preserve relevant memberships, obligations, faction ties, decisions, world events and resulting effects in Playthrough deltas anchored to canonical World Template institutions and sites. Promote a group or relationship into tracked significance only when it can affect meaningful decisions or wider events. A distant major war may develop, but routine minor faction disputes across every remote settlement need not be simulated. Important off-screen changes follow World Situations and fair information-delivery rules; no auto-decaying friendship or always-on NPC network is required.

**Examples (design intent, not claims of current gameplay):**
- A hired guild mercenary may help expose corruption while still fearing sanctions for disobeying a superior.
- Two local guild branches may act differently, shaped by their leadership and agreements.
- A former enemy commander may negotiate an alliance against a mutual threat while preserving other obligations.

**Not settled by Q8:** numeric faction standing, exact membership schemas, political jurisdiction, espionage mechanics, communications timing, war resolution, reputation presentation, faction resource budgets or who can found/manage an organisation. These belong to later scoped systems, including GAME-29 and the living-NPC programme. Q8 does **not** authorise broad ongoing political simulation.

**Rejected:** a single primary-faction opinion imposed on each NPC (A), and continuous elaborate simulation of every faction worldwide (C). The accepted approach preserves systemic depth, contextual disagreement and reproducible consequential change.

**Next focused question (Q9):** treatment of intelligent nonhuman/monstrous peoples as full societies and individuals rather than automatically hostile creatures.

## Sapient nonhuman peoples as full societies and individuals — accepted 17 October 2026 (NPC & Monster Q9, B)

**Intelligent nonhuman and historically “monstrous” peoples are inhabitants of the world with full social and individual depth, not automatically hostile enemy populations.** Orcs, goblins, giants and other sufficiently sapient beings may form settlements, families, trades, guilds, religions, governments, communities, alliances, rivalries and diverse ways of life, subject to the world’s grounded histories and their species’ actual capabilities. Their members may be merchants, farmers, wanderers, healers, raiders, rulers or adventurers, with personal motives and abilities.

**Ancestry/species, culture and political allegiance remain separate.** An orc's inherited body, movement, senses or other species-native capability remains real under the same d20 mechanics; none determines universal morality, profession, politics, intelligence, cultural membership or hostility. Neither should all nonhuman societies be copied wholesale from human institutions: believable variation in settlement organisation, economy, communication, technology, customs and social structures is welcome when supported by ecology, history, body plan and culture. A hostile raiding group needs a world-grounded conflict or interest; not every other community or member of that people inherits its guilt.

**Full social participation where meaningful.** Sapient nonhuman communities can offer trade, protection, information, recruitment, negotiated access, political conflict and peaceful or hostile encounters. Their named significant individuals and ordinary residents follow the same tiered NPC mechanical-depth principle, independent loyalty rules and bounded faction agency accepted in Q6–Q8, and may join or oppose the party when the individual has credible reasons. A person’s potential to negotiate does not make them automatically friendly or recruitable.

**Keep important distinctions.** Animal predators, mindless undead, constrained constructs and supernatural entities lacking ordinary social or linguistic capabilities do not automatically become settlement citizens or diplomacy partners. Highly intelligent but genuinely solitary or rare monsters can retain distinctive needs, habitats, social capacities and hazards; Q9 does not require universal integration of every intelligent creature into marketplaces or player settlements. Distinguish physical/supernatural species identity from capability for social membership, and define exceptions through credible fiction and rule-supported behaviour.

**World-state constraints:** Existing generated geography, cultural populations, settlements and factions have stable source provenance. Introduce nonhuman communities through compatible generated world content and Playthrough deltas, not arbitrary rewriting of Azgaar cultures or inventing a pre-existing civilisation without documented origin. Apply Q1–Q5 geography, ecology, historical/supernatural distribution and world-grounded risk; some communities may be dangerous, conflicted, hidden or culturally inaccessible, and not all encounters must be combat. Important NPC histories, faction relationships and recruitment decisions persist via the one Playthrough writer. Avoid large-scale NPC simulation or a blanket procedural town generator as prerequisites for the first gameplay slice.

**Rejected:** (A) default adversarial settlements and token friendly exceptions as the predominant role for nonhuman peoples; (C) requiring almost every intelligent monster, including unusual solitary entities, to participate in expansive universal trade and politics regardless of species-specific behaviour. This is **design direction**, not delivered society, diplomacy or settlement gameplay.

**Next design dependency (Q10):** how a generated encounter exposes multiple meaningful approaches and records the consequences of choices rather than being a disguised mandatory tactical fight.

## Implementation dependencies

- [GAME-134](https://linear.app/marksprietsma/issue/GAME-134/milestone-living-bestiary-humanoid-npcs-and-meaningful-opposition): programme for creature/opposition/NPC systems.
- [GAME-135](https://linear.app/marksprietsma/issue/GAME-135/npc-and-monster-design-grill-ecology-agency-and-encounters): decisions. Q7 next asks about NPC participation/recruitment and relationship roles.
- [GAME-33](https://linear.app/marksprietsma/issue/GAME-33/build-deterministic-grid-combat-simulator-shared-by-manual-and-auto): accepted extensible single action-budget combat baseline; [GAME-86](https://linear.app/marksprietsma/issue/GAME-86/research-fft-style-d20-combat-model-action-economy-and-meleeranged) establishes the basic action economy.
- [GAME-122](https://linear.app/marksprietsma/issue/GAME-122/expand-procedural-combat-encounters-beyond-repetitive-bandits): more varied world-grounded opposition; [GAME-96](https://linear.app/marksprietsma/issue/GAME-96/procedural-sandbox-spine-v1-generate-contextual-sites-encounters-and): grounded encounter/site persistence.
- [GAME-136](https://linear.app/marksprietsma/issue/GAME-136/boss-and-epic-npc-action-economy-lair-actions-and-bounded-off-turn) tracks a **separate narrow action-economy boss encounter**; finish the design interview before authorising implementation. Start with one evidence-backed vertical slice; do not create an encyclopaedia or a parallel combat engine.

Open particulars: exact depth threshold per NPC, whether class builds remain permanently materialised once an NPC is significant, leadership and recruitment contract, boss encounter timing model, how lair features are derived from procedural sites, UI telegraphing, action resource budgets, balance and difficulty tests. These require implementation review, not another mandatory broad design round.

**Q7–Q9 resolved:** recruitment follows NPC motives and commitments, factions have overlapping loyalties, and sapient nonhuman peoples have full social and individual depth without compulsory hostility or ancestry-based morality. **Next focused question (Q10):** meaningful approaches and persistent outcomes in procedural encounters.
