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

**Tactical Encounter**:
A bounded, deterministic combat situation resolved through the same character rules and resource authority used elsewhere in the Playthrough.

**Outcome**:
A recorded result of a player action or encounter. Whether and how it subsequently affects other characters, settlements or the wider world is a separate design concern.
_Avoid_: Lead, opportunity
