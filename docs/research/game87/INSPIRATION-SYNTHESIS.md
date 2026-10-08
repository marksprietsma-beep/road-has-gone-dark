# GAME-87 — RPG inspiration synthesis for The Road Has Gone Dark

**Status:** pre-study / design input, not production implementation  
**Date:** 2026-10-08  
**Purpose:** identify what selected RPGs can contribute to TRHGD **without undoing** the accepted GAME-86 combat direction or the GAME-32 character-rules work already underway.

## Executive conclusion

This research is worthwhile, but it should **not** become a second attempt to redesign the whole game.

The strongest opportunity is not to replace the current systems. It is to define a clearer product identity:

> **Wildermyth-like emergent character lives and campaign consequences + D&D 3.5 / PF1e-style build depth + GAME-86 tactical combat + a persistent generated world.**

That combination is materially more distinctive than “procedural fantasy RPG with FFT-like combat”.

The current project already has several pieces that make this feasible:

- persistent immutable worlds;
- deterministic generated states, regions, hometowns and sites;
- stable character IDs and generated backgrounds;
- party creation;
- a persistent expedition loop;
- a data-driven d20/PF1e-derived rules kernel now being implemented in GAME-32;
- the GAME-86 combat model designed for manual and same-engine auto control.

The missing layer is **character life**: persistent relationships, personal hooks, scars, injuries, transformations, reputation, personal quests and event-driven changes that make a generated adventurer accumulate a unique history.

That is where Wildermyth is much more strategically relevant than another combat ruleset.

---

# 1. Product north star

A useful shorthand for the future game is:

> **“Wildermyth’s emergent people inside a deeper D&D/PF character-building game, living in a persistent generated fantasy world and fighting through readable tactical battles.”**

This does **not** mean cloning Wildermyth.

TRHGD should differ in several important ways:

- deeper class / feat / multiclass / prestige progression;
- persistent world geography and settlements rather than a disposable campaign board;
- more systemic towns, facilities, guilds and expeditions;
- stronger tactical-combat determinism and auto-resolve;
- greater emphasis on generated world identity and provenance;
- longer-lived campaign state.

Wildermyth’s useful lesson is that **characters should acquire history**, not remain the same mechanically-defined pieces with higher numbers.

---

# 2. Inspiration ranking

## Tier 1 — highly relevant

### Wildermyth

Most strategically important new reference.

Useful for:

- generated character identity;
- history → aspects → mechanics;
- personality;
- relationships;
- personal hooks;
- character-targeted events;
- injuries and maiming;
- transformations;
- permanent consequences;
- overland/campaign stories;
- personal quests;
- event anti-repetition;
- heroes becoming memorable because of things that happened to them.

Wildermyth generates heroes with history that feeds aspects, stats and hooks. Events can target characters based on personality, history, aspects and relationships. Relationships deepen from shared activity and produce gameplay effects. Characters can be permanently maimed or transformed, and those changes can alter equipment access, abilities, statistics and future story eligibility.

**TRHGD should study this deeply.**

### Neverwinter Nights 2: Enhanced Edition

Primary relevance is character-building depth, not tactical combat.

The current Enhanced Edition explicitly retains the D&D 3.5 ruleset. Its value to TRHGD is the model of:

- base classes;
- multiclass progression;
- prestige classes;
- prerequisites;
- feat chains;
- spell progression;
- party specialization;
- build planning over many levels.

This reinforces GAME-32 rather than changing it.

**Use as a character-build inspiration, not as the combat template.**

### Wasteland 2

Especially useful for party capability and persistent consequence.

Important lessons:

- different party members own different skills;
- environmental interactions surface the most relevant character;
- skills matter both inside and outside combat;
- many problems allow multiple approaches;
- decisions have delayed consequences;
- party composition affects how the world can be interacted with.

TRHGD can use this to make the three adventurers matter during expeditions and town interactions.

A former mason, scout, healer, priest, woodsman or scholar should not merely have flavour text. Their mechanical/background tags should create different interaction options.

---

## Tier 2 — valuable targeted lessons

### Gloomhaven

Gloomhaven is not a model for TRHGD’s class system, but its **decision economy and attrition** are worth studying.

Useful ideas:

- every meaningful ability use is also a resource decision;
- scenario length matters because resources are depleted;
- initiative is part of tactical planning;
- objectives are not merely “kill everything”;
- monster behaviour is predictable enough to reason about;
- powerful options have opportunity costs.

The card/exhaustion system itself should **not** replace TRHGD’s d20 mechanics.

The transferable principle is:

> powerful actions should have costs across a battle or expedition, so there is a reason not to use the strongest ability every turn.

This aligns with GAME-86’s recommendation for scarce Focus / persistent resources.

### Warhammer 40,000: Rogue Trader

Relevant because it combines a deep CRPG character system with highly readable turn-based tactical combat.

Useful lessons:

- movement resources and action resources are visually distinct;
- cover is central;
- normally limiting attacks prevents static multi-attack dominance;
- friendly fire creates spatial decisions;
- party momentum provides visible battle tempo;
- archetypes create strong tactical identities.

The GAME-86 “move + main + shared reaction” model already captures the most valuable structural lesson: **movement and action should remain readable and bounded.**

Momentum is interesting, but should not be added merely because Rogue Trader has it. TRHGD should first see whether reactions, resources, objectives and delayed magic already provide enough tactical tempo.

### Sunderfolk

Useful primarily for clarity and role readability.

Sunderfolk gives each hero a strongly legible tactical role and keeps combat information close to the current decision. Its party phase allows players to choose who acts first, supporting tactical setup/combos. Skill cards and Fate cards make builds legible and allow gradual complexity.

TRHGD should borrow:

- abilities that communicate purpose clearly;
- visible party synergies;
- concise tactical information;
- understandable class identity.

Do not borrow:

- fixed pre-authored heroes;
- card-based progression as the core character system;
- party-phase initiative unless later playtesting shows fixed individual initiative is a problem.

### Stolen Realm

Useful for character-build freedom and pacing.

The game allows cross-tree character construction and supports highly unconventional combinations. Its simultaneous team turns reduce multiplayer downtime.

TRHGD should borrow the **build freedom principle**:

> classes and prestige paths should create combinations rather than isolated silos.

That strongly supports GAME-32’s data-driven multiclass / requirement architecture.

Do not currently borrow simultaneous turns. GAME-86 already identified fixed individual turns as the clearer V1 foundation, and simultaneous party action creates different AI, preview and balance problems.

---

## Tier 3 — historical / supporting reference

### Wasteland (1988)

Its most useful lesson is philosophical rather than mechanical:

- characters possess skills rather than being one class-defined solution;
- NPCs have some autonomy;
- party composition determines available solutions;
- advancement and skill acquisition alter interaction with the world.

Modern implementation should follow Wasteland 2 rather than recreating the original interface.

---

# 3. Borrow / adapt / avoid matrix

| Game | Borrow | Adapt | Avoid |
|---|---|---|---|
| Wildermyth | character hooks, aspects, relationships, event targeting, lasting change | transformations/injuries into TRHGD’s deeper build system | making random transformations so frequent that carefully built characters lose identity |
| NWN2 EE | multiclass/prestige depth, long-term build planning | 3.5 concepts through TRHGD/PF-derived rules | importing tabletop complexity without videogame justification |
| Wasteland 2 | party skills, multiple approaches, consequences | highest-relevant-member contribution and background-driven options | constant percentage skill checks for every interaction |
| Gloomhaven | resource pressure, scenario objectives, meaningful opportunity cost | expedition-level resource attrition | card exhaustion as the core character engine |
| Rogue Trader | cover clarity, bounded attacks, readable tactical identities | battle-flow resource only if needed after playtest | stacking extra action loops and momentum on top of an already complex engine |
| Sunderfolk | role readability, concise ability presentation, party combo clarity | some flexible activation ideas as a later experiment | fixed heroes/card progression as TRHGD’s core |
| Stolen Realm | cross-tree build freedom, unusual build combinations | multi-path classes/prestige combinations | simultaneous turns in V1 |
| Wasteland | skill-based identity, party complementarity | long-term consequences and imperfect companions later | original interface / opaque UX |

---

# 4. The most valuable Wildermyth lesson

The important system is not “random events”.

It is the chain:

```text
CHARACTER HISTORY
        ↓
PERSISTENT FACTS / ASPECTS
        ↓
EVENT ELIGIBILITY
        ↓
PLAYER CHOICE
        ↓
NEW ASPECTS / RELATIONSHIPS / INJURY / REWARD
        ↓
NEW GAMEPLAY POSSIBILITIES
        ↓
FUTURE EVENTS
```

This makes character development partially **historical**, not merely numerical.

TRHGD already generates background facts such as occupation, motivation, contacts and hometown history. These should become inputs into a persistent character-life system rather than remain biography text.

Example:

```text
Mara
Former occupation: mason's apprentice
Hometown: forestry frontier village
Motivation: prove herself outside the family trade

Expedition 1:
recognises reused masonry at a ruin

Expedition 4:
injured while protecting another party member
→ gains scar
→ relationship strengthened

Later:
personal event about an abandoned quarry becomes eligible

Choice:
enter quarry / refuse / ask old mentor for help

Outcome:
gains Stonewise aspect
or
loses confidence / changes relationship
or
discovers a prestige-path prerequisite
```

That is substantially more memorable than:

```text
Mara reached level 5.
Choose feat.
```

TRHGD can and should do both.

---

# 5. Proposed TRHGD character-life architecture

This is a design recommendation for future work, not an instruction to interrupt GAME-32.

## 5.1 Persistent aspects

Add a versioned structured aspect layer to characters.

Concept:

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

```text
former_mason
frontier_child
afraid_of_deep_water
scarred_left_arm
saved_by_character:<id>
wolf_touched
known_in_yulfod
owes_templeservice
```

Aspects can be:

- narrative only;
- event targeting;
- mechanical;
- both.

GAME-32 should not need to know every aspect by name. It should expose safe queries/tags so content can grant modifiers/features through versioned definitions.

---

## 5.2 Relationships

Persistent directed or symmetric edges between stable character IDs.

Concept:

```text
relationship:
    character_a
    character_b
    type
    strength
    history_events[]
    tags
```

Possible types:

- friend;
- rival;
- lover;
- sibling/family;
- mentor;
- debtor;
- oath-bound.

Do not make relationships purely cosmetic.

They can influence:

- event eligibility;
- willingness to take risks;
- tactical reaction abilities;
- recovery;
- personal quests;
- morale later.

Keep bonuses small enough that players are not forced to manufacture romances/rivalries for optimization.

---

## 5.3 Hooks / unresolved personal threads

Generated backgrounds should seed 2–3 unresolved hooks.

Examples:

- absent parent;
- former mentor;
- old debt;
- unexplained religious experience;
- disgraced apprenticeship;
- missing sibling;
- obsession with a local ruin;
- oath;
- fear;
- ambition.

Hooks are excellent procedural quest anchors because they are already tied to a specific character.

A hook should not guarantee a quest immediately.

Eligibility can depend on:

- time;
- region;
- relationship;
- site type;
- party composition;
- campaign events.

---

## 5.4 Event targeting

Future generated/authored events should use a safe targeting AST.

Possible predicates:

```text
has_aspect
lacks_aspect
relationship_at_least
background_tag
people_id
class_feature
skill_rank
origin_region
site_type
state_trait
injury
time_since_event
has_unresolved_hook
```

The engine selects valid event templates, then fills them using current persistent facts.

This is much more useful than unconstrained procedural prose.

---

## 5.5 Anti-repetition memory

Wildermyth deliberately reduces the likelihood of repeatedly surfacing previously-seen events.

TRHGD should maintain event-memory records at:

- playthrough;
- character;
- perhaps player profile later.

At minimum:

```text
event_id
times_seen
last_seen
characters_used
resolved_variant
```

Selection weights should strongly suppress recent repeats.

This will matter once procedural event libraries become large.

---

## 5.6 Lasting wounds and scars

This is one of the strongest potential systems for TRHGD.

Do not simply reset everyone to perfect condition after every fight.

However, do not make random permanent penalties commonplace.

A possible model:

At a serious defeat / zero-HP event, the player gets a **mortal consequence decision**.

Examples:

- withdraw with a lasting wound;
- sacrifice valuable equipment;
- accept a transformation/curse;
- another party member intervenes and gains a relationship consequence;
- risk death for a tactical/campaign benefit.

Persistent wound records may affect:

- stats;
- movement;
- equipment access;
- event eligibility;
- appearance/presentation;
- recovery time.

Later systems can provide:

- treatment;
- prosthetics;
- magical replacements;
- acceptance/adaptation feats.

---

## 5.7 Transformations

Wildermyth demonstrates that transformation is memorable because it affects both story and mechanics.

TRHGD should make these rarer and more contextual.

Possible categories:

- curse;
- blessing;
- elemental corruption;
- draconic mutation;
- fey change;
- undead condition;
- prosthetic / artificed replacement;
- divine mark.

These should be **structured character changes**, not merely prose.

A transformation may:

- occupy/alter a body slot;
- change ability availability;
- grant features;
- alter ancestry tags;
- change event eligibility;
- conflict with other transformations.

But it should not silently invalidate a carefully planned GAME-32 build.

The rules engine should be able to preview conflicts and effects.

---

# 6. How this interacts with deep D&D/PF customization

The two systems should be complementary.

## Deliberate progression

The player controls:

- class levels;
- multiclassing;
- prestige entry;
- skills;
- feats;
- spells;
- equipment;
- build strategy.

## Emergent progression

The campaign creates:

- scars;
- reputation;
- relationships;
- hooks;
- transformations;
- personal discoveries;
- regional ties;
- fears;
- obligations.

A character therefore becomes unique through:

```text
BUILD CHOICES
+
LIVED HISTORY
```

That is a strong product identity.

Two level-8 illusionists with identical class progression might still be radically different because:

- one lost an arm and uses an enchanted prosthetic;
- one is fey-touched;
- one has a rival in the party;
- one owes a temple;
- one is known as the survivor of a ruined mine;
- one has discovered a personal prestige prerequisite through a quest.

---

# 7. Implications for GAME-32

GAME-32 should **continue**. This research should not interrupt it.

The only architectural checks worth preserving are:

1. mechanical character IDs remain stable;
2. external persistent aspects can grant/query rules tags safely;
3. features can be granted by sources other than class levels;
4. prerequisite AST can query tags/aspects without hardcoding narrative systems;
5. build validation can explain when a transformation conflicts with equipment/features;
6. modifiers/effects record provenance/source;
7. persistent wounds can eventually apply versioned mechanical effects;
8. the rules engine is not written under the assumption that class progression is the only source of abilities.

If GAME-32 already supports generic granted features/tags/effects, no redesign is required.

---

# 8. Implications for combat

GAME-86 should remain the combat foundation.

This study mostly reinforces it.

## Reinforced by Rogue Trader

- separate movement/action readability;
- bounded attacks;
- cover;
- friendly-fire potential;
- tactical role identity.

## Reinforced by Sunderfolk

- readable role kits;
- every ability should clearly explain why it exists;
- party order/combo presentation matters.

## Reinforced by Gloomhaven

- powerful abilities should have meaningful opportunity/resource costs;
- scenario objectives create better tactical play than pure extermination;
- attrition can span the encounter.

## Reinforced by Wildermyth

- relationships/backgrounds can produce tactical modifiers or contextual actions;
- serious battle outcomes can affect campaign character state.

## Do not change now

Do not reopen:

- move + main;
- shared reaction;
- fixed individual initiative;
- compact grid;
- cover/LOS;
- telegraphed powerful magic.

Those should be playtested before another theoretical redesign.

---

# 9. Implications for expeditions

GAME-84 currently proves a persistent expedition loop but the player felt unclear about:

- why they were doing the investigation;
- what they received;
- how individual party members mattered.

These inspirations give a better answer.

A future expedition should potentially progress:

### World state
- site discovered;
- local problem resolved;
- facility unlocked;
- faction changed.

### Character state
- relationship changed;
- hook advanced;
- injury/scar acquired;
- reputation gained;
- transformation triggered;
- skill/background moment surfaced.

### Build state
- experience/advancement opportunity;
- item;
- feat/prestige prerequisite;
- trainer/contact;
- spell/technique discovery.

Then an expedition has a reason to exist beyond ticking “investigated”.

---

# 10. Implications for hometown facilities

GAME-85 can benefit heavily from Wasteland/Wildermyth-style character context.

A facility should not just expose:

```text
BLACKSMITH
Buy / Repair
```

It can also be:

- a source of contacts;
- a background-specific interaction;
- a personal-hook location;
- a treatment/recovery service;
- an apprenticeship/training source;
- a relationship/event stage.

Example:

A character with `former_blacksmith_apprentice` may receive a different dialogue/event at the smithy.

A character with a maimed limb may find a prosthetic-related service.

A character with a religious obligation may be called back to the shrine.

This turns facilities into persistent places rather than menu buttons.

---

# 11. Implications for guilds and recruitment

A Wildermyth-like character-life system becomes even more valuable once the roster expands beyond the starting three.

The guild can become a home for:

- active adventurers;
- injured/recovering characters;
- retirees;
- mentors;
- apprentices;
- relationships;
- old heroes;
- new recruits.

This provides a future answer to permanent consequences:

a badly injured hero does not necessarily mean “reload”.

They may:

- recover;
- retire;
- become trainer;
- become administrator;
- mentor a recruit;
- return later changed.

That fits TRHGD’s guild ambition extremely well.

---

# 12. What not to copy

## Do not copy Wildermyth’s shallow class breadth

TRHGD deliberately wants deeper build customization.

## Do not let random events invalidate build planning

Permanent changes should be previewable and meaningful.

## Do not make every battle produce a scar

Lasting consequences become meaningless if constant.

## Do not make relationships mandatory optimisation puzzles

Their main purpose is character identity and emergent choice.

## Do not adopt Gloomhaven cards as the rules engine

The resource-pressure lesson is enough.

## Do not adopt Stolen Realm simultaneous turns

Interesting for co-op speed, but inconsistent with GAME-86 V1 and potentially awkward for single-player multi-character control.

## Do not import Rogue Trader’s complexity stack wholesale

Momentum, cover, MP/AP, archetype systems and extra-turn abilities together can create significant action-economy complexity.

## Do not treat NWN2’s D&D 3.5 implementation as sacred

Use it as evidence that deep build progression is compelling, not as a requirement to copy every tabletop rule.

---

# 13. Suggested staged roadmap

## Stage A — continue current work

GAME-32:
finish production character rules kernel.

Then GAME-33:
shared deterministic tactical simulator.

Then GAME-34/35:
manual battle presentation + same-engine auto control.

Do not derail these with new character-life scope.

## Stage B — Character Life V0

Create a focused production slice:

- aspects;
- relationships;
- 2–3 hooks per character;
- event targeting;
- 15–30 authored/generative event templates;
- anti-repetition memory;
- expedition integration.

No transformations yet.

## Stage C — Lasting Consequences V0

Add:

- injuries;
- recovery time;
- scars;
- mortal-choice event;
- treatment;
- one simple prosthetic/replacement path.

## Stage D — Personal quests

Use:

character hook
+
relationship
+
generated world site/facility

to create deterministic personal quest opportunities.

## Stage E — Transformations / exceptional life changes

Only once the base aspect/event system is stable.

## Stage F — Legacy / generational systems

Potentially much later:

- retirees;
- guild mentors;
- descendants;
- returning heroes;
- historical reputation.

Do not commit to cross-campaign legacy until the single-campaign loop is mature.

---

# 14. Recommended product identity

If the project successfully combines these systems, the pitch becomes substantially clearer:

> **The Road Has Gone Dark is a persistent procedural fantasy RPG where you build deeply-customised adventurers, send them into tactical expeditions, and watch their relationships, injuries, transformations, reputations and personal histories accumulate into unique lives inside a generated world.**

That is stronger than merely:

> procedural world + Pathfinder + FFT combat.

The generated world becomes the stage.

GAME-32 gives the characters mechanical depth.

GAME-86/33 gives them tactical expression.

The Wildermyth-like layer gives the player a reason to care what happens to them.

---

# 15. Priority recommendation by reference game

If further model/research time is limited:

1. **Wildermyth — deep follow-up required**
2. **NWN2 EE — continue as GAME-32 build reference**
3. **Wasteland 2 — study party skills / consequence / interaction**
4. **Gloomhaven — study expedition resource pressure / objectives**
5. **Rogue Trader — study combat readability and cover**
6. **Sunderfolk — study class readability / tactical UI**
7. **Stolen Realm — study build freedom; avoid action-economy adoption**
8. **Wasteland 1 — historical principles only**

---

# 16. Questions for the Astra follow-up

Astra should not merely summarise these games again.

It should answer:

1. Is the proposed “Wildermyth character life + D&D build depth” combination technically coherent with current TRHGD architecture?
2. What is the minimum persistent aspect/event schema needed?
3. How should character history and GAME-32 mechanics interact without becoming tightly coupled?
4. Which permanent consequences create interesting decisions without encouraging reloads?
5. How should injury/maiming work with equipment and multiclass builds?
6. How should relationships matter without becoming mandatory min-max bonuses?
7. How should hooks produce personal quests from generated world data?
8. How should event eligibility avoid contradictions and repetition?
9. What character-life data should AI/autoresolve/combat be permitted to consume?
10. What should be explicitly deferred?
11. Can a 20–30 event prototype demonstrate the design before building a huge content library?
12. Does this create a stronger core identity than spending the same effort on more classes, towns or procedural prose?

---

# Sources consulted in this pre-study

Accessed 2026-10-08.

## Wildermyth
- https://wildermyth.com/
- https://wildermyth.com/wiki/Main_Page
- https://wildermyth.com/wiki/Writer%27s_Guide
- https://wildermyth.com/wiki/Event
- https://wildermyth.com/wiki/Event_Types
- https://wildermyth.com/wiki/Hook
- https://wildermyth.com/wiki/Relationship
- https://wildermyth.com/wiki/Theme
- https://wildermyth.com/wiki/Maim
- https://wildermyth.com/wiki/Combat_mechanics

## Wasteland / Wasteland 2
- https://support.inxile-entertainment.com/hc/en-us/articles/115004513287-About-Wasteland-2
- https://cdn.akamai.steamstatic.com/steam/apps/240760/manuals/Wasteland_2_Reference_Guide.pdf
- https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/240760/manuals/Wasteland_2_Director%27s_Cut_Manual_PC.pdf
- https://wasteland.protozoic.com/wasteland/wastedisk/manual.pdf

## Gloomhaven
- https://github.com/m-ender/gloomhaven-rules
- https://github.com/mikkelam/gloomhaven-2e-dump/

## Neverwinter Nights 2: Enhanced Edition
- https://store.steampowered.com/app/2738630/Dungeons__Dragons_Neverwinter_Nights_2_Enhanced_Edition/

## Stolen Realm
- https://news.xbox.com/en-us/2024/03/15/stolen-realm-xbox/
- https://steamcommunity.com/games/1330000/announcements/detail/3194750393573045750
- https://steamcommunity.com/app/1330000

## Sunderfolk
- https://dreamhaven.com/games/sunderfolk
- https://www.dreamhaven.com/sunderfolk/beginners-guide
- https://support.dreamhaven.com/hc/en-us/articles/49914757379867-Understanding-Turns-in-Sunderfolk
- https://dreamhaven.com/sunderfolk/meet-your-heroes-the-arcanist
- https://dreamhaven.com/sunderfolk/meet-your-heroes-the-rogue

## Warhammer 40,000: Rogue Trader
- https://roguetrader.owlcat.games/beta-guide
- https://roguetrader.owlcat.games/news/en/27
