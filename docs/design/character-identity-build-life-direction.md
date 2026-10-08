# The Road Has Gone Dark — Character Identity, Build and Life Direction

**Status:** accepted product/design direction  
**Accepted by:** Mark, 8 Oct 2026  
**Purpose:** provide one cohesive reference for future character creation, character progression, Character Life, guild/recruitment, expedition consequence and tactical integration.

This guide consolidates the strongest conclusions from:
- GAME-32 — d20/PF-derived production rules kernel;
- GAME-86 — tactical combat research;
- GAME-87 — RPG inspiration synthesis;
- GAME-88 — D&D 3.x / Warhammer RPG character-option and consequence research;
- existing GAME-81 party creation;
- GAME-84 expedition feedback;
- Wildermyth, Wasteland, WFRP/Dark Heresy/Black Crusade/Imperium Maledictum, NWN2, Gloomhaven, Rogue Trader, Sunderfolk and Stolen Realm research.

It is intended to become the north-star guide for later character creation and Character Life implementation.

---

# 1. Product north star

The intended character experience is:

> **Deep deliberate D&D/PF-style builds, living inside Wildermyth-like personal histories, with Warhammer-like consequence and social context, all anchored to TRHGD's persistent generated world and GAME-86 tactical combat.**

The distinguishing idea is:

> A character is not just a build, and not just a story.  
> They are a build that acquires a life.

The long-term TRHGD character should be understandable as:

```text
WHO THEY ARE
    people / ancestry
    heritage
    culture
    origin
    background

WHAT THEY CHOOSE TO BECOME
    ordered class history
    multiclassing
    prestige paths
    feats / talents
    skills
    spells / abilities
    equipment

WHERE THEY FIT IN THE WORLD
    occupation / career
    guild role
    faction standing
    patronage
    social status
    duties / obligations

WHAT HAS HAPPENED TO THEM
    relationships
    ambitions
    personal hooks
    reputation
    scars / wounds
    trauma
    corruption
    curses
    mutations
    grafts / prosthetics
    symbionts
    pacts
    transformations

WHAT THE RULES ENGINE DERIVES
    immutable combat-ready snapshot
```

These layers must remain distinct in data, but able to interact through generic tags, requirements, effects and provenance.

---

# 2. Fundamental separation of identity layers

Do not collapse ancestry, culture, background and class into one thing.

## People / ancestry

Broad biological/fantasy identity.

Examples:
- Human
- Dwarf
- Woodland Elf
- Hearth Elf
- Smallfolk
- Orc
- Goblin
- Emberkin

People should define only the broadest inherited traits and physical assumptions.

Do not create hundreds of top-level peoples merely because D&D 3.x contains hundreds of race/subrace entries.

## Heritage / lineage

Narrower inherited variation or latent supernatural lineage.

Examples:
- deep-dwelling;
- frost-adapted;
- aquatic;
- fey-touched;
- draconic;
- elemental;
- celestial/fiendish-style lineage;
- dormant bloodline.

Heritage is where much of D&D's huge subrace breadth should be compressed.

## Culture

Social identity generated from the world.

Culture is **not ancestry**.

A Human and an Orc may share a culture.
Two Humans may belong to radically different cultures.

Azgaar culture can remain useful world context, but playable people/ancestry must remain a separate TRHGD system.

## Origin

State / region / hometown and source-backed local context.

Origin affects:
- local knowledge;
- reputation;
- family/community contacts;
- available background facts;
- local cultural identity;
- personal hooks;
- event eligibility.

## Background

What the character did or experienced before becoming an adventurer.

Examples:
- mason's apprentice;
- temple scribe;
- caravan hand;
- forester;
- dock worker;
- minor clerk;
- poacher;
- healer's assistant.

Background should matter mechanically/contextually through:
- automatic knowledge;
- special interaction options;
- reduced costs;
- better information;
- contacts;
- event targeting.

It should not merely be biography prose.

---

# 3. Character creation V1 philosophy

Character creation should create **three persistent people**, not three disposable tactical units.

The starting process should eventually establish:

1. stable character identity;
2. people/ancestry;
3. heritage where relevant;
4. name;
5. world-backed origin;
6. background;
7. motivation;
8. provisional role / recommended build path;
9. initial attribute/build candidate;
10. a small number of unresolved personal hooks;
11. initial relationships among the three;
12. a mechanical build that can grow through GAME-32.

The current GAME-81 roles:
- Vanguard
- Scout
- Adept
- Expert

remain useful as **onboarding/narrative recommendations**, not final classes.

They should point the player toward build families without constraining later multiclassing.

---

# 4. Deliberate progression

The player deliberately controls:

- class levels;
- multiclassing;
- prestige progression;
- feats / talents;
- skills;
- spells;
- equipment;
- build strategy.

This is where D&D 3.5 / Pathfinder 1e / NWN2-style depth belongs.

The design goal is not to reproduce tabletop Pathfinder exactly.

TRHGD uses one internally consistent ruleset derived from those traditions and adapted for its tactical videogame.

Important principles:
- ordered advancement history is preserved;
- prestige requirements are declarative and explain failures;
- new content should be mostly data-driven;
- class names are not hardcoded into generic rules logic;
- same rules engine serves player-controlled combat and future AI/autoresolve;
- non-damage/control/illusion builds are first-class.

---

# 5. Emergent progression / Character Life

The campaign creates a second progression axis:

```text
BUILD CHOICES
+
LIVED HISTORY
=
UNIQUE CHARACTER
```

Lived history can include:
- relationships;
- ambitions;
- personal hooks;
- faction standing;
- regional reputation;
- injuries;
- scars;
- trauma;
- corruption;
- curses;
- mutations;
- grafts/prosthetics;
- symbionts;
- pacts;
- transformations;
- discoveries;
- debts;
- oaths;
- mentors;
- personal quests.

This layer should never replace GAME-32 progression.

Instead it should feed the same generic rules engine through:
- tags;
- granted features;
- modifiers;
- abilities;
- senses;
- resources;
- restrictions;
- prerequisite facts.

---

# 6. Character aspects

Use a persistent aspect model for important lived facts.

Conceptually:

```text
aspect:
    id
    source
    acquired_at
    visibility
    tags
    narrative_data
    mechanical_refs
    event_tags
    conflicts
```

Examples:
- former_mason;
- frontier_child;
- afraid_of_deep_water;
- scarred_left_arm;
- saved_by:<character_id>;
- known_in:<region_id>;
- owes:<facility_id>;
- fey_touched.

Not every sentence in a biography becomes an aspect.

Aspects should exist only when they matter to:
- future events;
- rules;
- reputation;
- relationships;
- progression;
- presentation.

---

# 7. Relationships

Relationships should use stable character IDs.

Possible types:
- friend;
- rival;
- lover;
- sibling/family;
- mentor;
- student;
- debtor;
- oath-bound;
- former colleague.

Relationships should influence:
- event eligibility;
- personal quests;
- rescue/protection decisions;
- recovery;
- dialogue/context;
- occasional restrained tactical effects.

They should **not** become mandatory min-max mechanics.

A player should not feel forced to manufacture romance or rivalry because it produces the best DPS.

---

# 8. Motivations, ambitions and personal hooks

Each character should eventually possess:
- a motivation;
- a short-term ambition;
- a long-term ambition;
- 2–3 unresolved personal hooks.

Possible hooks:
- missing sibling;
- old mentor;
- debt;
- failed apprenticeship;
- family expectation;
- unexplained religious experience;
- lost object;
- oath;
- fear;
- criminal connection;
- former employer;
- obsession with a site.

Hooks should not immediately become quests.

They become eligible when world context aligns:
- time;
- location;
- site type;
- relationship;
- facility;
- faction;
- party composition;
- previous events.

This keeps personal quests tied to the actual generated world.

---

# 9. Personal quest generation

A personal quest should combine persistent facts rather than invent arbitrary story.

Example:

```text
CHARACTER
former miner

+
HOOK
missing mentor

+
WORLD
nearby abandoned mine

+
RELATIONSHIP
close friend accompanies them

=
personal quest opportunity
```

The objective truth remains structured.

Generated prose renders the event but is never authoritative state.

---

# 10. Careers / occupations

Warhammer RPGs add an important distinction:

> Class is what the character can do.  
> Occupation/career is how they currently fit into society.

Do not replace GAME-32 classes with WFRP-style careers.

Instead support:

```text
Background:
Mason's apprentice

Build:
Roadwarden 4 / Wayfinder 2

Current occupation:
Caravan guard
```

Current occupation may affect:
- training access;
- contacts;
- income;
- downtime;
- social status;
- faction rank;
- event eligibility;
- prestige access;
- obligations.

A character may change occupation without rewriting class history.

---

# 11. Social position, reputation and influence

Do not use one universal reputation number.

Potential scopes:
- hometown;
- region;
- state;
- faction;
- religion;
- guild;
- noble house;
- criminal group;
- profession.

A character may be:
- wealthy but disreputable;
- poor but respected;
- famous locally but unknown elsewhere;
- trusted by one faction and hated by another.

Higher social standing should also generate obligations.

```text
more access
+
more responsibility
```

Examples:
- guild officer owes administrative time;
- temple initiate owes service;
- patron expects favors;
- noble rank creates legal/political duties;
- faction agent receives assignments.

---

# 12. Downtime / between expeditions

Use **time and opportunity** as resources, not only money.

A character cannot do everything between expeditions.

Possible downtime actions:
- recover from injury;
- seek treatment;
- train skill/feat;
- investigate a personal hook;
- research a site;
- work for income;
- maintain faction role;
- craft/repair equipment;
- strengthen a relationship;
- cleanse corruption;
- adapt to mutation;
- seek graft/prosthetic;
- recruit/train a guild member.

This creates meaningful choice without requiring excessive resource micromanagement.

---

# 13. Investigation should create gameplay advantage

Investigation must not merely produce XP or a completion flag.

A successful investigation can create structured advantage later:

- reveal enemy type;
- identify resistance/weakness;
- discover alternate entrance;
- improve deployment;
- reduce reinforcements;
- reveal hazard;
- unlock dialogue;
- expose illusion;
- identify true target;
- create environmental interaction;
- grant surprise/preparation.

Example:

```text
Wayfinder tracks raiders
→ alternate deployment zone

Former mason studies ruins
→ unstable wall becomes tactical breach

Adept reads magical residue
→ suspected illusionist identified
```

This directly answers the GAME-84 question:
**why are we investigating, what did we gain, and how did each party member contribute?**

---

# 14. Injuries and scars

Ordinary HP loss is not the same as long-term injury.

Use a layered model:

```text
ordinary damage
    ↓
combat HP/resource

serious defeat threshold
    ↓
critical consequence

critical consequence
    ↓
temporary injury
lasting scar
body-slot injury
death risk
graft/prosthetic opportunity
personal event
```

Possible record:

```text
injury:
    source_event
    body_slot
    severity
    temporary_effects
    lasting_effects
    treatment
    recovery_clock
    scar
    adaptation_options[]
```

Do not make every zero-HP event create permanent mutilation.

Serious lasting consequences should be rare enough to remain memorable.

---

# 15. Fate-like survival and mortal consequence

The game may eventually need a scarce survival mechanism to preserve danger while reducing reload pressure.

Possible outcomes of a lethal result:
- death;
- severe injury;
- ally rescue at a cost;
- forced retreat;
- sacrificed equipment;
- curse;
- graft/transformation;
- rare survival resource spent.

The important design goal is:

> A bad roll can change the character without routinely deleting them.

This should be tested before adopting a formal Fate-point system.

---

# 16. Trauma vs corruption

Keep these separate.

```text
TRAUMA
what the mind has endured

CORRUPTION
what supernatural exposure has changed
```

A character can have:
- trauma without corruption;
- corruption without trauma;
- both;
- neither.

Immediate fear/stress can be common.

Persistent trauma should be uncommon and story-worthy.

Avoid caricaturing real-world mental illness.

Use contextual fictional responses:
- fear of a creature/site;
- recurring nightmare;
- compulsion;
- avoidance;
- intrusive memory;
- specific stress trigger.

---

# 17. Corruption

Corruption is **not a morality meter**.

Prefer typed sources:
- void/aberrant;
- necrotic;
- abyssal;
- fey;
- elemental;
- divine;
- blight;
- artifact-specific.

Potential state:

```text
corruption_state:
    source_domain
    bodily_score
    psychic_score
    stage
    symptoms[]
    granted_features[]
    compulsions[]
    exposure_history[]
    cleansing_options[]
    irreversible_threshold
```

Possible stages:

```text
clean
trace
marked
changed
consumed
```

Corruption should be tempting:

```text
higher corruption
→ power / resistance / sense / prestige access
→ symptoms / event changes / obligations
→ harder cleansing / greater long-term risk
```

Do not force alignment change.

Do not force class levels.

---

# 18. Curses

A major curse should be a persistent gameplay/story state, not simply "-2 until healed".

Possible structures:
- pure burden;
- boon-with-cost;
- escalating;
- conditional;
- requirement/obligation;
- transformative;
- social/reputation curse.

Every major curse should answer:

1. What is gained or risked by keeping it?
2. What new gameplay/story opportunities does it create?
3. What meaningful route exists to suppress, transform or remove it?

Curse truth can remain hidden from the player initially.

This aligns with TRHGD's objective-truth vs player-knowledge architecture.

---

# 19. Mutation

Mutation is an acquired overlay, not a new ancestry.

Possible state:

```text
mutation:
    id
    source
    body_slot
    stage
    visible_traits[]
    granted_tags[]
    granted_features[]
    drawbacks[]
    conflicts[]
    progression_options[]
    reversible
    cure_or_stabilize
```

Mutation should support:

## Involuntary progression

Exposure/events advance it.

## Chosen adaptation

The player later chooses whether to:
- cure;
- suppress;
- stabilize;
- embrace;
- invest feats/talents;
- seek graft/prosthetic solution;
- enter a mutation-linked prestige path.

Thus:

> The world starts the change.  
> The player decides what the change becomes.

---

# 20. Grafts, prosthetics and body modification

Use a generic body-modification system.

Possible record:

```text
body_modification:
    id
    source
    body_slot
    tags
    granted_features
    granted_abilities
    modifiers
    equipment_conflicts
    appearance
    removal_rule
    side_effects
    provenance
```

Examples:
- crafted prosthetic;
- enchanted prosthetic;
- monster-derived graft;
- elemental limb;
- living armour;
- cursed replacement;
- divine relic replacement.

A serious wound can therefore become a new progression branch rather than a permanent dead-end penalty.

---

# 21. Symbionts

Symbionts are equipment + relationship + acquired-state hybrids.

Potential properties:
- entity identity;
- body/equipment slot;
- abilities;
- dependency;
- bond strength;
- obligations;
- events;
- possible conflict/separation.

They should not be treated as ordinary loot.

---

# 22. Pacts and patrons

A supernatural pact should begin with a real desire:

> I need something badly enough to accept a cost.

Possible motives:
- save another character;
- cure a fatal wound;
- gain forbidden knowledge;
- protect hometown;
- defeat a specific enemy;
- undo a tragedy.

Possible costs:
- corruption;
- obligation;
- taboo;
- visible mark;
- future service;
- relationship damage;
- escalating supernatural claim.

Patrons need not be supernatural.

A future campaign patron could be:
- noble;
- merchant group;
- temple;
- town council;
- retired adventurer;
- officer;
- arcane society.

Patrons should offer:
- access;
- resources;
- information;
- legal cover;
- specialists;

and also:
- obligations;
- rivals;
- secrecy;
- political exposure;
- demanded service.

---

# 23. Acquired-state architecture

Corruption, curses, mutation, wounds, grafts, transformations, symbionts, diseases and pacts should share one generic layer.

```text
ACQUIRED STATE
    id
    category
        corruption
        curse
        mutation
        wound
        graft
        transformation
        symbiont
        disease
        pact

    source
    acquired_at
    stage
    visibility
    body_slots[]
    tags[]
    granted_features[]
    modifiers[]
    restrictions[]
    event_tags[]
    progression
    suppression
    cure/removal
    provenance
```

GAME-32 should consume only generic outputs.

Do not hardcode "curse logic" into class progression.

---

# 24. Body configuration

Do not create a huge body simulation unless needed.

A minimal useful body-slot model may include:
- head;
- torso;
- left arm;
- right arm;
- left leg;
- right leg;
- optional special slots such as wings/tail where relevant.

This exists to support:
- injuries;
- equipment;
- grafts;
- prosthetics;
- mutations;
- transformations.

Body state must not silently invalidate a carefully planned build.

Preview conflicts before irreversible changes whenever possible.

---

# 25. Prestige progression tied to lived history

Prestige paths are the strongest bridge between deliberate build and emergent history.

Requirements may include:
- level/class level;
- attributes;
- skills;
- feats;
- casting capability;
- ancestry/heritage tag;
- faction reputation;
- mentor relationship;
- completed personal hook;
- discovered site;
- relic/trainer;
- acquired state;
- corruption stage;
- world-state achievement.

Example concept:

```text
requires:
    arcane capability
    veil-related feat
    survived specific phenomenon
    trusted mentor OR discovered site
```

Prestige should therefore represent:
- mastery;
- hybridization;
- affiliation;
- transformation;
- personal-quest outcome;
- rare discovery.

---

# 26. Transformations

Transformations should be rare, structured, and meaningful.

Possible categories:
- fey;
- draconic;
- elemental;
- divine;
- cursed;
- undead;
- demonic/abyssal;
- artificed/prosthetic;
- wild/nature;
- void/aberrant.

A transformation may:
- alter body slot;
- grant/remove features;
- change senses;
- modify event eligibility;
- change social reaction;
- create new prestige options.

It should not casually overwrite the deliberate class build.

---

# 27. Social visibility of mutation/transformation

Acquired states should include visibility:

```text
hidden
concealable
obvious
unmistakable
```

And contextual social tags:

```text
feared
forbidden
sacred
prestigious
suspicious
```

Social response depends on:
- culture;
- faction;
- religion;
- region.

A visible fey mark may be revered in one place and feared in another.

---

# 28. Event targeting

Future Character Life events should use declarative eligibility.

Possible predicates:
- has_aspect;
- lacks_aspect;
- relationship type/strength;
- background tag;
- people/heritage;
- class/feature;
- skill;
- origin;
- region;
- site type;
- facility type;
- faction/religion;
- injury;
- acquired state;
- corruption stage;
- hook;
- time;
- previous event;
- world state.

No arbitrary executable content scripts.

---

# 29. Event outcomes

Structured outcomes may include:
- add/remove aspect;
- modify relationship;
- advance/resolve hook;
- modify reputation;
- grant item;
- grant training eligibility;
- grant feature;
- apply wound;
- start recovery;
- add corruption;
- add mutation;
- add curse;
- add graft;
- start transformation;
- create pact;
- unlock quest;
- alter site/facility/world delta.

Prose never becomes authoritative state.

---

# 30. Anti-repetition memory

Maintain event memory.

Potential fields:
- event ID;
- times seen;
- last seen;
- characters used;
- variant;
- cooldown;
- resolution.

Selection should strongly suppress recent repetition.

A large procedural system becomes meaningless if the same "mysterious shrine" story repeats constantly.

---

# 31. NPCs, guild and recruitment

As the roster grows, Character Life becomes more valuable.

Future guild states may include:
- active adventurer;
- injured/recovering;
- retired;
- trainer;
- mentor;
- administrator;
- specialist;
- temporary hire.

Retirement should not necessarily remove a character from the game.

Possible future roles:
- trainer;
- facility keeper;
- quest giver;
- mentor;
- guild officer;
- historical figure.

Generated hirelings should have manageable personality/work traits:
- reliability;
- ambition;
- loyalty;
- fear;
- vice;
- work ethic;
- social ties;
- boundaries.

Not uncontrolled random AI behavior.

---

# 32. Death philosophy

No final death model is locked yet.

Possible tools:
- permadeath;
- rare death;
- downed/injury;
- mortal consequence;
- scarce Fate-like resource;
- ally rescue;
- retirement.

The design goal is:

> Danger must be real, but the rational response should not always be save-scumming.

This should be tested after combat exists.

---

# 33. Character uniqueness tests

## Life test

Take two characters with the same mechanical build.

After ten expeditions, do they feel meaningfully different because of:
- relationships;
- injuries;
- hooks;
- reputation;
- acquired states;
- obligations;
- discoveries?

If not, Character Life has failed.

## Build test

Take two characters with similar history.

Can different classes/feats/prestige choices still make them mechanically distinct?

If not, Character Life has swallowed GAME-32.

Both tests must pass.

---

# 34. Complexity budget

TRHGD already contains:
- world generation;
- origins;
- party creation;
- deep builds;
- expeditions;
- tactical combat;
- towns/facilities;
- future guilds.

Therefore character-life systems must be staged.

Highest-value early systems:
1. aspects;
2. relationships;
3. hooks;
4. event targeting;
5. investigation rewards;
6. downtime;
7. injuries/scars;
8. scoped reputation.

Later:
- corruption;
- curses;
- grafts;
- mutations;
- pacts;
- transformations;
- retirement/legacy.

Do not build everything at once.

---

# 35. Implementation roadmap

## Current foundation

Finish:
- GAME-32 rules kernel;
- GAME-33 deterministic combat;
- GAME-34 manual tactical presentation;
- GAME-35 same-engine AI/autoresolve.

Do not derail these.

## Character Life V0

Implement:
- aspects;
- relationships;
- motivation;
- 2–3 personal hooks;
- event targeting;
- event memory;
- 20–30 carefully designed events;
- expedition integration.

No transformations yet.

## Character Life V1

Add:
- downtime;
- occupations/careers;
- scoped reputation;
- investigation-to-confrontation advantages;
- facilities/mentor/training integration.

## Lasting Consequences V0

Add:
- critical injury;
- recovery time;
- scars;
- treatment;
- one prosthetic/graft path;
- mortal consequence prototype.

## Acquired States V0

Add:
- corruption;
- curse;
- mutation;
- disease;
- pact;
- generic acquired-state framework.

## Personal Quests

Use:
- hook;
- relationship;
- world site;
- facility;
- faction;
- origin;
- event history.

## Transformations

Only after acquired-state architecture is stable.

## Guild / legacy

Later:
- retirees;
- mentors;
- trainers;
- returning veterans;
- historical reputation;
- possible world-specific legacy.

---

# 36. Character creation UI implication

Future character creation should remain readable despite system depth.

Do not expose every future system at character creation.

Initial creation should focus on:
- identity;
- ancestry/heritage;
- background;
- motivations;
- recommended role/build;
- initial mechanical choices;
- party relationships where appropriate.

Do **not** ask the player to choose:
- corruption;
- mutations;
- grafts;
- pacts;
- prestige classes;
- permanent wounds;
- future careers.

Those should emerge through play.

The depth should unfold over time rather than appear as a 30-tab creation screen.

---

# 37. Rules ownership boundary

## GAME-32 owns

- classes;
- feats;
- skills;
- resources;
- modifiers;
- requirements;
- effects;
- formulas;
- generic tags;
- derived snapshots.

## Character Life owns

- aspects;
- relationships;
- hooks;
- occupations;
- injury;
- trauma;
- corruption;
- curse;
- mutation;
- graft;
- pact;
- reputation;
- obligations.

## World/campaign owns

- factions;
- patrons;
- facilities;
- mentors;
- sites;
- settlement state;
- event availability;
- downtime clock.

## GAME-33 owns

- battlefield geometry;
- movement;
- LOS;
- cover;
- initiative;
- combat resolution;
- per-observer battlefield state.

The systems interact through explicit contracts, not hidden cross-module assumptions.

---

# 38. Core player-agency rules

1. Major irreversible changes should be previewed when the player has a choice.
2. Random events should rarely destroy the core build.
3. Severe negative consequences should usually create an adaptation path.
4. A cure should often require time, access, favors or choices—not merely money.
5. Corruption powers should be tempting, not mandatory.
6. Mutations do not overwrite ancestry/class history.
7. Body changes use explicit equipment compatibility.
8. Removing a state that supplied prerequisites must preview consequences.
9. Committed events do not reroll on save/reload.
10. Relationships/history should enrich builds, not dictate the optimal build.

---

# 39. Long-term product identity

The intended pitch becomes:

> **The Road Has Gone Dark is a persistent procedural fantasy RPG where you build deeply customizable adventurers, send them into tactical expeditions, and watch their relationships, occupations, injuries, corruption, transformations, reputations and personal histories accumulate into unique lives inside a generated world.**

The generated world is the stage.

GAME-32 provides mechanical depth.

GAME-86/33 provides tactical expression.

Character Life provides emotional continuity and persistent consequence.

Guilds and facilities provide social/world anchoring.

Together, this should create characters the player remembers because of both **what they built** and **what happened to them**.

---

# 40. Non-negotiable design principles

- Culture != ancestry.
- Build != biography.
- Class != occupation.
- Trauma != corruption.
- Mutation != moral alignment.
- Reputation is scoped, not universal.
- Permanent consequence should create play, not merely punishment.
- Prestige can be earned through lived history.
- Investigation must create useful consequences.
- Objective truth and player knowledge remain separate.
- Prose renders state; prose never owns state.
- Same character ID persists through all growth/change.
- Same GAME-32 rules engine handles mechanical outputs regardless of their source.
- Do not overwhelm character creation with systems that should emerge through play.
- Do not copy proprietary D&D/Warhammer/Wildermyth expression; use structural inspiration and original TRHGD content.

This document is the accepted direction guide until deliberately superseded by a later reviewed design decision.

---

# 41. Combat compatibility contract

All Character Life systems must remain compatible with the accepted GAME-86 / future GAME-33 combat model.

The combat foundation remains:

- one movement allowance;
- one main action;
- one shared reaction;
- fixed individual initiative with stable tie-breaking;
- compact square-grid combat;
- explicit LOS / cover / engagement;
- telegraphed powerful effects;
- rare hard action denial;
- objective-based encounters;
- deterministic resolution;
- the same simulator for manual play and autoresolve.

Character Life may change **capabilities, costs, risks, information, resources and consequences**, and some features may create explicit bounded exceptions to the baseline action budget. The requirement is not “never grant extra attacks/actions”; it is that every exception must be represented inside the same deterministic action-budget model so manual play, AI and autoresolve all understand it.

## Allowed integration

Character Life can affect combat through structured GAME-32-compatible outputs such as:

- granted abilities;
- modifiers;
- tags;
- senses;
- resources;
- damage/resistance types;
- movement values;
- reach;
- reaction options;
- targeting restrictions;
- status resistances;
- spell/ability availability;
- equipment/body-slot compatibility;
- observer knowledge;
- pre-combat advantages;
- post-combat consequences.

Examples:

- a prosthetic arm grants a defensive feature;
- a mutation changes stride or grants climbing;
- corruption unlocks a new ability with a resource cost;
- a curse imposes a targeting restriction or occasional condition;
- a relationship grants a restrained protective reaction;
- an injury reduces movement until recovered;
- investigation reveals an enemy weakness or alternate deployment zone;
- a pact grants a powerful main-action ability with an attached campaign cost.

## Forbidden integration

Character Life systems must not casually introduce:

- an always-on universal bonus/swift-action layer added casually;
- unbounded or recursive extra full turns;
- independent hidden reaction pools;
- uncontrolled extra attacks that bypass declared action costs or feature limits;
- separate hidden combat formulas;
- manual-only mechanics that autoresolve cannot reproduce;
- narrative-only bonuses with no machine-readable rule;
- free actions that bypass GAME-86 costs;
- random permanent combat rewrites that invalidate the player's build.

If a future feature appears to require one of these, it must be reviewed as a combat-system change rather than smuggled in through Character Life.

## Acquired states feed the same rules engine

A wound, mutation, graft, curse, transformation or pact does not directly alter GAME-33 internals.

Instead:

```text
Character Life state
        ↓
generic tags / features / modifiers / resources
        ↓
GAME-32 derived character snapshot
        ↓
GAME-33 deterministic combat state
```

This preserves one source of truth.

GAME-33 should never need code such as:

`if character.is_cursed: ...`

It should consume the resulting structured rule effects.

## Investigation and pre-combat preparation

Investigation fits particularly well because it can alter **encounter inputs** rather than action economy.

Examples:

- alternate deployment zones;
- known enemy traits;
- exposed illusion;
- reduced reinforcement count;
- pre-identified hazard;
- prepared resistance;
- battlefield object revealed;
- surprise/preparation state.

These are excellent bridges between expedition play and tactical combat.

## Injuries and body changes

Injuries, grafts and mutations can affect:

- movement;
- reach;
- equipment;
- senses;
- defence;
- available abilities.

But they must be deterministic and previewable.

A lost arm must not unexpectedly destroy a two-handed build with no adaptation path.

Possible responses include:

- temporary injury first;
- retraining opportunity;
- prosthetic;
- graft;
- transformation;
- equipment conversion;
- compensation feature.

## Corruption and curses

Corruption fits combat best when it creates **new options with costs**, not random turn theft.

Good examples:

- gain a powerful ability that spends a corruption-linked resource;
- increased resistance paired with recovery penalty;
- new sense paired with social/campaign consequence;
- dangerous overchannel option using the normal main action.

Avoid:

- arbitrary skipped turns;
- random loss of player control every round;
- unbounded extra actions;
- hidden damage bonuses outside the standard modifier system.

## Relationships

Relationship mechanics should be small and expressive.

Good examples:

- one protective reaction;
- recovery bonus;
- morale/resilience effect;
- rescue behavior;
- limited coordinated action.

Avoid large permanent attack/damage multipliers that make relationships into optimization requirements.

## Trauma / fear

Immediate fear effects may alter combat state through normal statuses.

Examples:

- frightened;
- shaken;
- retreat pressure;
- concentration penalty.

Long-term trauma belongs primarily in Character Life and event systems, not as constant hard control.

## Mutations, extra limbs and additional attacks

Extra anatomy **can** justify additional attacks, but only through explicit rules.

An extra limb may enable:

- more equipment slots;
- different weapon combinations;
- climbing/grappling utility;
- multiweapon techniques;
- a dedicated extra-strike rider;
- a limited additional action token from a named feature.

The engine should distinguish:

1. **Extra strikes inside one Main action**  
   Example: Two-Weapon Attack spends one Main action and resolves a main-hand strike plus an off-hand strike, each with its own accuracy/damage rules.

2. **Attack sequences unlocked by progression**  
   Example: an advanced fighter feature turns the Attack action into two ordered strikes. This is still one Main action, not two turns.

3. **Conditional action grants**  
   Example: a rare capstone, haste-like spell or four-armed mutation grants one additional restricted action such as `StrikeOnly`, `MoveOnly` or `TechniqueOnly` for that activation.

4. **Reactions**  
   These continue to compete for the shared reaction budget unless a feature explicitly and visibly increases that budget.

This means the baseline action economy remains readable while exceptional builds can genuinely bend it.

### Two-weapon fighting

A good V1 structure is:

```text
Main Action: Twin Strike
    attack main-hand
    attack off-hand
    apply declared dual-wield accuracy/damage rules
```

Later feats can modify that package:

```text
Improved Twin Strike
    reduce penalty

Flowing Blades
    allow one attack before and one after movement

Whirling Assault
    spend resource
    gain third restricted strike
```

The exact names/numbers are provisional, but the architectural pattern is important: **multiple attack rolls do not require multiple turns**.

### Fighter extra attacks

Fighter progression can increase the number or quality of strikes produced by the normal Attack action.

For example:

```text
Attack
    level 1: one strike
    advanced martial feature: two strikes
    mastery feature: second strike may target adjacent enemy
```

This avoids the Pathfinder problem where a character must stand still and perform a complicated full-attack routine, while still letting high-level martials feel faster and more dangerous.

### Extra arms

An extra arm does not automatically equal “+1 unrestricted Main action”.

Instead it can unlock:

- multiweapon attack actions;
- simultaneous weapon + shield configurations;
- weapon + focus/tool combinations;
- grappling while armed;
- special techniques;
- possibly a restricted extra strike if the mutation/feature explicitly grants one.

A particularly powerful four-armed transformation could absolutely grant a limited extra action. That is acceptable if it is:

- explicit;
- data-driven;
- bounded;
- visible in the UI;
- deterministic;
- available to the AI/autoresolve through the same legal-action model;
- balanced by opportunity cost, rarity, resource, corruption or other consequence.

The design rule is therefore:

> **The baseline is stable; exceptional features may bend it in declared, machine-readable ways.**

## Same-engine autoresolve requirement

Every combat-relevant effect from Character Life must be representable in the same deterministic command/state model used by manual combat.

If the human player can benefit from:

- a graft;
- a pact;
- a relationship reaction;
- corruption ability;
- mutation;
- injury;
- investigation advantage;

the autoresolve AI must receive and evaluate the same legal options and state.

No second shortcut combat model may approximate these systems.

## Combat-balance principle

The goal is not symmetry.

A mutation, injury, pact or prestige path may make one character unusually strong in a particular context.

Balance should focus on:

- meaningful tradeoffs;
- opportunity cost;
- role value;
- resource pressure;
- counterplay;
- objective contribution;
- expedition consequences;

not equal blank-room duel win rates.

## Final compatibility rule

> Character Life enriches the combatant and may bend the baseline action budget through explicit, bounded rules. It does not create a separate combat engine.

Any future feature that violates that rule requires an explicit GAME-86/GAME-33 design review before implementation.


