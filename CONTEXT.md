# The Road Has Gone Dark

Canonical domain language for the persistent fantasy RPG. These definitions describe concepts, not claims that every associated feature is complete.

## World and place

**World Template**:
An immutable, generated strategic world containing geography, settlements, major routes and other source-world facts. Multiple independent Playthroughs may reference the same template.
_Avoid_: Save game, playthrough

**Playthrough**:
One independent campaign in a World Template, with its own adventurers, origin, elapsed time, knowledge and persistent consequences.
_Avoid_: World template, world seed

**World Cell**:
A stable geographical unit of the strategic world, used as an anchor for more detailed local content.
_Avoid_: Local Region

**Local Region**:
An explorable area derived from a particular World Cell, constrained by that cell's strategic geography and important world features.
_Avoid_: World Cell, province

**Settlement**:
A persistent inhabited place identified in the strategic world. Its strategic existence does not imply that a detailed street or building layout has been generated.
_Avoid_: Detailed town map

**Holding**:
A Playthrough-specific property or place over which the player has acquired a recognised or contested ownership, lease, stewardship or governing interest. It references stable world locations without rewriting the immutable World Template.
_Avoid_: Every Settlement, free edit of generated geography

**Stronghold**:
A Holding developed to provide substantial defensible, residential or operational capability. Its improvements, occupants and consequences persist within its Playthrough.
_Avoid_: Cosmetic home, automatically founded city

**Managed Settlement**:
A Holding or settlement under credible player administration, supporting strategic development and governance such as infrastructure, production, labour, trade, defence and local politics. Control does not imply that every resident is individually simulated.
_Avoid_: World Template Settlement, decorative facility list

**Founded Settlement**:
A new settlement established during one Playthrough at a world-grounded suitable location, rather than an original World Template Settlement. Its founding, development, location anchor and consequences persist within that Playthrough.
_Avoid_: Mutating the World Template, unplaced town

**Territorial Claim**:
An asserted or recognised right to own, occupy or govern land that may affect settlement establishment and development. A claim can be disputed; discovering a suitable site does not automatically make it unclaimed or legally controlled.
_Avoid_: Automatically uncontested ownership

**Governing Authority**:
A context-specific right or practical mandate to make binding decisions for people, institutions or territory. It is separate from owning a Holding or physically occupying land, and may be limited, delegated, revoked or contested.
_Avoid_: Property deed, automatic control of every resident

**Political Legitimacy**:
The grounds on which relevant people and institutions recognise, tolerate or challenge a character's or faction's Governing Authority, shaped by credible in-world claims, agreements, custom, support, power and history.
_Avoid_: Universal reputation score, force automatically conferring lawful title

**Settlement District**:
A player-planned area within a Managed Settlement with an intended role, such as residential, commercial, agricultural or industrial. Its ordinary development may be generated within the established location, access and resource constraints.
_Avoid_: Each individual building, abstract production toggle

**Landmark Construction**:
A consequential, individually placed settlement structure or infrastructure element, including major buildings, roads and fortifications, whose location and effects persist in the Playthrough.
_Avoid_: Every ordinary house or decoration, menu-only upgrade

**Production Chain**:
A meaningful conversion or dependency linking settlement resources, productive facilities and outputs, potentially across several settlements. Inputs, available capacity and downstream uses must be grounded in persistent Playthrough state.
_Avoid_: Passive income bonus, individual factory work-order log

**Supply Connection**:
A credible economic link between settlements or facilities through which goods may move subject to access, transport constraints and disruption. Its relevant commitments and consequences persist without requiring simulation of every vehicle.
_Avoid_: Instant global inventory, every wagon as an independently simulated agent

**Population Cohort**:
An aggregate group of residents in a Managed Settlement used to represent relevant labour capacity, occupations, needs and demographics without simulating the lives of every member. Population changes must have persistent Playthrough consequences.
_Avoid_: Independently simulated citizen, interchangeable named specialist

**Significant Resident**:
A settlement-associated Significant NPC whose individual competence, obligations, personality, relationships or history meaningfully affects the settlement and its future events. Residents can become significant through consequential actions or relationships; cohort-level statistics do not automatically invent individual biographies.
_Avoid_: Every resident as a fully simulated character, anonymous worker bonus

**Community Need**:
A settlement or Population Cohort requirement or valued condition, such as food, housing, safety, fair working conditions or locally important customs, whose consequential shortfall or fulfilment can affect the Playthrough.
_Avoid_: Universal happiness bar, individual resident maintenance meter

**Social Pressure**:
A grounded, developing settlement circumstance arising from unmet needs, perceived unfairness, conflicts or changing community priorities. It can produce consequential responses by residents, leaders or factions rather than automatic punishment at a numerical threshold.
_Avoid_: Random unrest penalty, constant mood decay

**Settlement Administrator**:
An NPC appointed to manage a Holding or Managed Settlement under an agreed Mandate, with bounded authority over ordinary operations and plausible local responses while the Party is elsewhere. Competence, obligations, relationships and available resources affect decisions.
_Avoid_: Omniscient player puppet, universal settlement AI

**Hometown**:
The settlement selected as the Playthrough's starting home and initial point of return. It need not be every Adventurer's personal place of origin.
_Avoid_: Character origin

**Site**:
A stable, revisitable location of interest within the world, whether currently hidden, rumoured or discovered by the player.
_Avoid_: Lead, encounter

**Player Knowledge**:
The Playthrough's record of what is known about world entities and sites, distinct from the underlying truth of the World Template.

**World Delta**:
A Playthrough-specific alteration or consequence associated with a stable world entity or Site, without mutating the World Template.

**World Situation**:
A persistent, developing circumstance involving identifiable places, people or groups, capable of changing over in-game time even when the Party is elsewhere.
_Avoid_: Quest, continuous NPC simulation

**Tracked World Situation**:
A World Situation selected for ongoing consequential advancement because of its relevance to the Party, its relationships or surroundings, or its exceptional regional or world importance. Not every generated threat or local circumstance is tracked.
_Avoid_: Every generated world event, quest objective

**World Event**:
A consequential development affecting a World Situation or other persistent world entity during a Playthrough; it is not necessarily a player-triggered Outcome.
_Avoid_: Outcome, narrative flavour text

**Regional Ecology**:
The geographically grounded distribution and interactions of creature species, habitats, territories and population groups within a World Template and its evolving Playthrough. It is represented through bounded consequential changes, not continuous simulation of every animal.
_Avoid_: Arbitrary encounter spawn table, continuous individual creature simulation

**Creature Distribution Context**:
A world-grounded explanation and constraint for a species' presence and rarity, based on habitat, geography, history, supernatural conditions, factions and credible movement. Its provenance is stable and distinguishable from discoveries or subsequent Playthrough changes.
_Avoid_: Biome-only monster spawn list, anything-spawns-anywhere probability

**Sapient People**:
An intelligent, socially capable population of persons, including nonhuman and historically monster-labelled peoples, whose members may have distinct cultures, communities, settlements, occupations, beliefs, personal histories and political affiliations. Shared ancestry or species-native abilities do not prescribe uniform morality, culture or hostility.
_Avoid_: Default enemy species, uniform ancestry-based culture, cosmetic humanoid reskin

**Creature Species**:
A mechanically distinct animal, monster, supernatural being or other non-player creature kind, defined by its intrinsic body, senses, movement, natural attacks, protections, weaknesses and capabilities rather than by a human combat-template reskin.
_Avoid_: Encounter role, cosmetic skin, humanoid class name

**Species-Native Capability**:
An intrinsic physical or supernatural action, passive trait or limitation grounded in a Creature Species, resolved through the game's shared d20, effects and tactical-combat authority with honest requirements and observable consequences.
_Avoid_: Unimplemented flavour text, parallel monster-only combat engine

**Creature Population Group**:
A regional or local aggregate of a creature species whose plausible habitat, abundance, territorial pressure and relationships to other groups or settlements can change through significant Playthrough events. It is not a roster of individually simulated specimens.
_Avoid_: Every creature is a persistent NPC, stateless respawn token

**Faction Affiliation**:
A person's meaningful and potentially multiple ties to organised groups, with context-specific rights and obligations rather than compulsory loyalty based on culture or ancestry.
_Avoid_: Single faction slot, mandatory racial allegiance

**Faction Relationship**:
A consequential alliance, rivalry, obligation or internal disagreement between groups or members, changed through grounded events and credible information rather than global reputation updates.
_Avoid_: Uniform member opinions, universally informed factions

**Recruitment Relationship**:
A credible, voluntary and persistent arrangement through which an NPC may become a short-term hire, a travelling companion, a trusted long-term party member, an ally or a contracted specialist. The arrangement has reasons, scope and limits informed by that person's existing obligations, ambitions and knowledge.
_Avoid_: Universal persuasion-to-recruit button, guaranteed obedience, automatic party membership

**NPC Loyalty and Departure**:
A consequential choice by a non-player person to honour, renegotiate or leave a commitment—or, in exceptional grounded circumstances, betray it—based on their motives, beliefs, relationships, treatment and opportunities. The resulting action has persistent causes and consequences, not unexplained random disloyalty.
_Avoid_: Passive friendship decay, arbitrary betrayal roll, invisible scripted abandonment

**NPC Mechanical Depth**:
A tiered representation of a non-player person's relevant competence: ordinary residents need credible professions and usable skills; consequential specialists, companions, rivals and leaders may require full ancestry, class, level, feats, spells, equipment and persistent advancement as their role warrants. Any contested action resolves through the shared d20 authority.
_Avoid_: Every citizen as level-20 character sheet, inconsistent simplified combat roll

**Boss Action-Economy Profile**:
A bounded, visible and testable encounter capability for a major individual to remain challenging against a multi-character Party through distinctive command opportunities, allies, reactions, phases or environment-linked actions without simply inflating hit points or adding unlimited extra turns.
_Avoid_: Free action spam, secretly changing action rules, universal boss privilege

**Lair Action**:
A powerful encounter effect arising from a boss's credible prepared territory, stronghold or supernatural domain, with explicit triggers, telegraphing and player counterplay; its availability is conditional on that environment rather than an inherent feature the boss carries everywhere.
_Avoid_: Portable magic whenever the boss travels, unavoidable environment damage

**Significant Creature**:
An individually persistent monster or animal distinguished by consequential actions, a unique role, history, relationship, threat or encounter outcome; it can survive, move, be injured or become important without treating its entire species as individual characters.
_Avoid_: Generic population total, automatically tracking every wolf

**Creature Behaviour Profile**:
A species- and context-grounded set of instincts, intelligence limits, needs, social responses, threat assessment, and possible combat or noncombat decisions. Different creatures can stalk, warn, defend, withdraw, bargain or remain relentless according to their actual nature and circumstances.
_Avoid_: All monsters always attack, every creature reasons like a human, cosmetic AI tag

**Creature Morale**:
A contextual willingness to continue confrontation based on injury, fear, companions, leadership, defended interests and available escape or surrender options; not a universal panic meter that overrides mindless or genuinely fearless creatures.
_Avoid_: Mandatory flee-at-low-HP rule, perfect information, automatic surrender

**World-Grounded Threat Profile**:
A contextual estimate of a creature, group, site or region's credible danger, derived from its established capabilities, ecology, history and active circumstances rather than automatically matching the Party's current level. Player Knowledge can reveal imperfect but actionable warning signs.
_Avoid_: Automatic level scaling, guaranteed winnable encounter, arbitrary unwarned lethal surprise

**Threat**:
A developing World Situation that can plausibly cause a harmful change if left unresolved; a Threat is not automatically a quest or a mandatory objective.
_Avoid_: Mandatory quest, arbitrary loss

**Information Report**:
A message, rumour, warning or account of a World Event that can reach the Party through a plausible in-world source; its contents and arrival need not match the full underlying world truth.
_Avoid_: World Event, omniscient notification

**Information Channel**:
A credible means by which information travels between people and places, such as messengers, travellers, established contacts or organisations.
_Avoid_: Instant global alert

**Remote Intervention**:
An attempt to influence a distant World Situation through a credible relationship or organisation, rather than direct action by the travelling Party; communication delays and local capability limit what it can achieve.
_Avoid_: Instant global command, direct Party action

**Delegate**:
A person or group that accepts a bounded responsibility on the player's behalf and may exercise judgement within that responsibility, subject to relationships, personal obligations, circumstances and available resources.
_Avoid_: Automatically obedient unit, universally controllable NPC

**Mandate**:
An agreed objective and its limits entrusted to a Delegate, allowing reasonable independent decisions without granting unrestricted control of the Delegate's behaviour.
_Avoid_: Unconditional order, total control

**Significant NPC**:
A non-player character selected for consequential personal development through relationships, repeated interactions, influential actions, important roles or significant World Situations. Significance can emerge or fade, but prior identity, relationships and history persist when active development stops.
_Avoid_: Every named NPC, continuously simulated citizen

**NPC Initiative**:
A bounded consequential action undertaken by an NPC to advance their own established ambition or relationship rather than in response to a player-issued Mandate. The action may happen while the Party is elsewhere.
_Avoid_: Delegated order, continuous autonomous life simulation

**Social Relationship**:
A persistent, consequential connection between specific characters, including family, friendship, rivalry, loyalty, debt or obligation. Relationships may be asymmetric and change through meaningful events; an NPC need not be related to the Party for the connection to matter.
_Avoid_: Every acquaintance, automatic reciprocal opinion

**NPC Belief**:
What a particular NPC currently considers true or likely based on firsthand experience, evidence or information received; it may be incomplete, mistaken or revised without changing actual World Events.
_Avoid_: World truth, Player Knowledge, automatic omniscience

**Motivation Conflict**:
A consequential choice in which an NPC's established ambitions, beliefs, loyalties or obligations favour competing actions. Strongly supported choices can be clear; genuinely uncertain choices may depend on a bounded, context-informed roll.
_Avoid_: Arbitrary personality reroll, Wisdom as morality

**Personality Priority**:
An enduring but potentially revisable preference or value guiding an NPC's decisions and suggesting roleplay or story responses for a player-controlled Adventurer. It is distinct from abilities, skills, obligations and relationships and never removes the player's authority over their Adventurer's choices.
_Avoid_: Wisdom, alignment-as-destiny, fixed moral rule

**Personality Milestone**:
A consequential, recorded experience that warrants reviewing whether a character's Personality Priorities have strengthened, shifted or been reinterpreted. For a player-controlled Adventurer, the player confirms any change; for an NPC, a bounded event may resolve the development according to that character's established motivations.
_Avoid_: Routine action counter, automatic trait drift

## Characters and progression

**Adventurer**:
An individually identified character with a persistent personal history and a separate mechanical build. The same Adventurer remains identifiable as their build progresses.

**Party**:
The currently associated group of Adventurers taking part in the player's journey. The initial three-character group is not a permanent recruitment limit.

**Ancestry**:
An Adventurer's species or broader people-family, distinct from upbringing, occupation and adventuring career.
_Avoid_: Class, culture

**Heritage**:
A defined variation within an Ancestry that may confer distinct characteristics.
_Avoid_: Culture, occupation

**Culture**:
An Adventurer's learned social and community background, conceptually distinct from Ancestry and Heritage.
_Avoid_: Ancestry

**Occupation**:
An Adventurer's non-adventuring livelihood or background training, distinct from their adventuring Class.
_Avoid_: Class

**Base Class**:
A selectable adventuring career with its own advancement and abilities; distinct from an Adventurer's narrative role or Occupation.

**Prestige Path**:
An optional, additional advancement path entered only after meeting persistent prerequisites and explicitly choosing to advance in it.
_Avoid_: Starting class, automatic promotion

**Rules Pack**:
A versioned set of character and action rules to which a Playthrough is pinned, so continuing a saved campaign does not silently change its mechanics.

## Exploration and resolution

**Lead**:
An available reason or request to investigate a Site. A Lead is not the Site itself and can have its own acceptance and completion state.
_Avoid_: Site

**Expedition**:
A party journey from a safe return point towards a destination or Site, consuming in-world resources and time and producing recorded actions and results.

**Opportunity**:
A context-specific, actionable choice or challenge encountered during exploration; it need not result in tactical combat.
_Avoid_: Quest, battle

**Systemic Encounter Situation**:
A grounded interaction among actors, competing interests, a location, available resources, risks and information, which may be approached in several different lawful ways when the circumstances support them. It can lead to combat but is not defined by combat.
_Avoid_: Mandatory battle with cosmetic choice labels, arbitrary options unsupported by world state

**Encounter Approach**:
A feasible course of action made available by a character's actual capabilities, equipment, relationships, knowledge and environmental context, with meaningful costs, checks, risks and potential consequences. Not every approach applies to every situation.
_Avoid_: Universal talk/sneak/fight menu, decorative skill names, disconnected dice roll

**Tactical Encounter**:
A bounded, deterministic combat situation resolved through the same character rules and resource authority used elsewhere in the Playthrough.

**Outcome**:
A recorded result of a player action or encounter. Whether and how it subsequently affects other characters, settlements or the wider world is a separate design concern.
_Avoid_: Lead, opportunity
