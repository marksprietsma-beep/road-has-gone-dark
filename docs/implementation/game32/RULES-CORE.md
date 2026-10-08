# GAME-32 rules core V1

Existing GAME-81 characters gain mechanical builds through a deliberate preview and atomic commit. Their IDs, names, people, backgrounds, biographies, narrative roles, relationships, slots, world pins and active GAME-84 expedition remain unchanged. Historical saves still load without mechanics and report `not_prepared`.

The production branch starts at GAME-83 `bc6f301f6458f992a16c1a201a381376d536b80c`. Research input is [GAME-86 draft PR68](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/68), whose completed artifacts were checked without rerunning the 19,456 battles. GAME-33/34/35 remain separate work. This branch adds no battlefield, AI, initiative queue, pathfinding, LOS, autoresolve, combat presentation or new runtime/helper.

## Authority and APIs

| Module | Responsibility |
| --- | --- |
| `RulesRegistry` | Validate immutable definitions once; exact package/schema/version/content hash/engine pin; sorted stable IDs and per-definition provenance |
| `RulesExpressions` | Bounded integer formula and prerequisite ASTs; structured code/path/current/expected failures |
| `RulesModifiers` | Deterministic typed stacking and conditional applicability |
| `RulesRng` | Explicit SHA-256 counter RNG, rejection-sampled dice, numeric saving throws and attack/critical contests |
| `RulesCharacter` | Replay ordered advancement, preview options/advancement, validate builds and derive immutable hashed snapshots |
| `RulesEffects` | Pure cost/resource/status/save/damage/healing/appearance primitives; no tactical eligibility or scheduling |
| `RulesHooks` | Versioned trusted deterministic handlers, never executable content strings |
| `RulesRecords` | Additive campaign mechanics, deterministic preparation and advancement/current-state previews |
| `RulesService` | Reconstruct previews under existing world/slot locks, check stale hashes, and reuse GAME-81 atomic save/recovery journal |

`GamePlaythroughStore` gains one optional validator. The rest of the existing save schema and party member schema stay intact. `mechanics = {schema_version, rules_ref, revision, source_party_sha, records}` is keyed by existing character IDs. Each record stores base attributes, heritage/background references, exact advancement history, equipment/prepared choices, revision and mutable current mechanics. Derived totals are reconstructed rather than persisted as a competing authority.

The exact `RulesRef` includes `pack_id`, `schema_version`, `rules_version`, `content_hash` and `engine_schema`. Only `trhgd-rules-v1`/schema1/rules1.0.0/engine1 is supported. A missing or mismatched pin rejects preparation/load explicitly; no automatic content upgrade or substitution exists. Later pack upgrades require a new previewed migration. Integral JSON floats normalize to the same canonical integer bytes as in-memory values. Hashes are unambiguous sorted-key canonical JSON, not platform dictionary iteration order.

Typical trusted integration:

```gdscript
var preview = RulesRecords.preview_preparation(existing_state)
# Review preview.candidate; no write occurs here.
var committed = RulesService.new().commit_preview(entry, slot, preview)
var record = committed.state.mechanics.records[existing_character_id]
var kernel = RulesCharacter.new(RulesRecords.registry())
var options = kernel.preview_choices(record, "wayfinder")
var choice = kernel.suggested_choice(record, "wayfinder").choice
var advance = RulesRecords.preview_advancement(committed.state, existing_character_id, choice)
```

A service must receive the existing configured store/library when using non-default save roots, as the integration tests demonstrate. `commit_preview` accepts preparation, advancement or a validated current-runtime update, reconstructs the candidate from the current save and compares its hash. Invalid/stale/tampered requests preserve prior bytes. Runtime updates are submitted by the trusted campaign owner; they are not a player-facing arbitrary-stat editing API. `PartyService.commit` remains the existing internal transaction primitive.

`preview_choices` explains class entry, next-level skill budget/rank room, scheduled attribute choices and feat eligibility after a partial allocation. `suggested_choice` is a deterministic fixture/migration convenience. Actual ordered choices, not the suggestion algorithm, are replayed on load. Class names never select an engine behavior branch.

## Initial mechanics

Standard array: 15/14/13/12/10/8. Narrative roles recommend allocations and initial paths; they do not become mechanical classes. Heritage maps the existing people ID to an original mechanical reference with tags and no speculative racial bonuses. The original hometown background also preserves its narrative record.

| Original path | HP per level | BAB | Good save | Skill points before INT | Identity proof |
| --- | ---: | --- | --- | ---: | --- |
| Roadwarden | 6 | full | Fortitude | 2 | Armour/shield, melee training, Guard and frontliner tags |
| Wayfinder | 4 | floor(3n/4) | Reflex | 4 | +1 stride, skill breadth and contextual +4 Precision descriptor |
| Lantern Adept | 3 | floor(n/2) | Will | 3 | Focus, healing, Slow, apparent obstacle/false target and delayed burst |
| Veil Adept | 3 | floor(n/2) | Will | 3 | Original prestige: insight, Veil uses, shared-reaction Echo hook and defensive duplicate |

Veil entry checks prior character level4, INT13, Arcana4, Veiled Casting and arcane capability2; earliest entry is the fifth character level. Its class cap is10 within total character cap20. Three pure paths, two multiclass paths and Lantern4/Veil10/Lantern6 exercise every level through20. Class levels aggregate for formulas but ordered steps remain authoritative. Good saves contribute 2+floor(class level/2); poor saves floor(class level/3), then CON/DEX/WIS modifiers. Additive good-save contributions on multiclassing are an explicit V1 choice, subject to later balance review.

Max HP = max(1, 6 + sum(class HP × class levels) + CON modifier × total level), plus typed modifiers. Defence =10+DEX modifier+typed equipment/features/status modifiers. Melee/ranged attack = summed class BAB+STR/DEX modifier+typed modifiers. Initiative uses DEX; base stride4 and reach1. Current HP is separate: only initial preparation fills HP; later advancement clamps to the new maximum without free healing. Newly unlocked resource pools begin full during advancement; existing spent pools preserve their current amount.

Skills consolidate Athletics, Stealth, Perception, Arcana, Craft, Persuasion, Survival and Insight. Each defines attribute, trained behavior, rank rule, tags and declarative typed modifiers. Ranks cannot exceed total level. Skill total combines ranks, attribute modifier and typed modifiers. Feats occur at1,3,…19; one attribute increases at4,8,12,16,20 (cap22). Skill allocation must spend exactly the class/INT budget, with at least1 point. Repeatable Steady Study is an original untyped Will+1 proof, not a balanced final catalogue.

Typed positive modifiers keep the largest bonus and typed penalties the worst penalty of each type; those two contributions coexist. Untyped modifiers stack. Stable source ordering resolves ties. Definition formulas read base/context inputs rather than recursively modified outputs; class progressions cannot read derived stats. Cyclic feature grants and recursive status-effect expansions are rejected.

Numeric contests use `d20 + bonus >= target`. Saves have no automatic natural1/20 rule. Critical metadata defaults to natural20 and +4 damage; a critical requires a hit and returns a damage bonus for the caller. Attack eligibility, natural-hit rules if later desired, equipment selection and applying attack damage belong to the battlefield consumer. These values are tunable original V1 defaults, not claimed Pathfinder rules or final class balance.

## Costs, current state and effects

One movement token and one main token per activation; exactly one shared reaction refreshes only at an explicit global-round boundary. `activation_budget(remaining_reaction)` carries the current remainder and cannot refill it. All reaction abilities share the same token, including departure, Guard follow-up and Echo; there is no generic swift/bonus/immediate action.

Dash spends move+main, doubles stride and grants no attack. Charge spends both, adds2 movement, requires a straight path ending adjacent, and describes one attack. Disengage spends main and describes departure protection. Geometry, actual attacks and protection lifetimes remain GAME-33 responsibilities. The rules pack also supplies the engaged-ranged circumstance penalty of−4; the consumer supplies validated engagement context rather than character derivation assuming every archer is engaged.

Focus capacity =2+floor(Lantern level/4), refreshed at an eligible rest, never automatically per encounter. Veil uses =max(1,floor(Veil level/2)), daily. Generic Stamina2 uses encounter refresh; short-rest and explicit scopes also work through the same API. Refresh is caller-driven and scoped to each definition. Ability costs are checked before pure candidate resolution; failures return no committed candidate or partial RNG/resource changes. Spent Focus is saved through `preview_runtime` and tested across process restart.

Safe effects cover typed stat/save modifiers, feature/sense grants, spend/restore resource, damage, capped healing, temporary HP, status apply/remove, numeric saves with failure effects, apparent effects/defensive duplicates and trusted hooks. Damage consumes temporary HP before current HP; temporary HP keeps the greater amount rather than stacking. Healing Thread spends a main action and1 Focus for at most6 HP; no unlimited sustain loop. Status instances persist ID/source/remaining/expiry; definitions own duration, stacking, modifiers and immediate effects. Slow removes2 stride (minimum1) through the next target activation end and does not remove the main action. Status expiry only occurs when a caller supplies its explicit boundary.

RNG state is `{version: sha256-counter-v1, seed, counter}`. Hashing `[version,seed,counter]` yields a 32-bit draw, with rejection sampling to avoid modulo bias. State is passed/returned explicitly and never calls Godot global randomness. Structured dice or bounded `NdS±B` syntax are accepted; script strings are rejected. Effect events record actual amounts, save outcomes and consumed resources.

## Perception and delayed-magic handoff

Apparent-wall, false-guard and defensive-duplicate use sense-dependent descriptors: explicit investigation trigger, save/DC, success/failure, duration, bypass tags, maximum maintained count, replacement and break conditions. They always have `collision:false`. A nonphysical apparent ID occupies a separate namespace; public projection exposes only apparent ID, visual/audio presentation and senses. It omits kind, caster identity, physical identity and disbelief truth. GAME-33 must use observer-facing apparent IDs for real and illusory perceived targets alike; the namespace labels perception references, not illusion truth. Snapshots are authority-only inputs and must never be sent wholesale to an observer. GAME-33 owns observer-specific beliefs/knowledge, deciding which projection an observer sees, investigation, obstacle bypass and targeting legality. The kernel cannot falsely promise an illusion already fools an AI or blocks a route.

Initial illusion DC =10+INT modifier+typed DC bonuses. One maintained illusion replaces the previous one; two source-round durations and source-incapacitated break metadata are defaults. The consumer enforces these declared break/duration boundaries for maintained battlefield effects. Defensive duplicates have no physical collision or hidden target identity in the public view.

`veil_echo_v1` is a fixed trusted handler for `illusion_disbelieved`, declared by the prestige feature. It requires source/apparent/observer IDs and emits a deterministic apparent-target intent/event. Echo spends the shared reaction and a Veil use. It never loads a script path from content. Hook intents remain trusted authority data for GAME-33.

Delayed Burst spends main+1 Focus now, describes next-activation 2d4+2+INT damage, radius1/range5, friendly fire, locked tile and interruption/cancellation. It returns an intent without immediate damage, RNG draws or pending battlefield state. No initiative/scheduler/tile lock implementation exists here.

## Review limits

The content is small and original, with per-definition provenance. It proves extension mechanisms rather than shipping a broad class catalogue. Armour proficiency restrictions, equipment capacity/weight, spell preparation limits, tactical Precision once-per-activation enforcement and detailed alternate senses remain data/consumer policies to extend in later reviewed work. Current original feats have no parameter choices. Multi-pack migration and a complete class-creation/level-up UI remain separate work.

GAME-86 isolated AI wins are diagnostics, not final class balance: terrain, protected ranged positions, team screening, objectives and information can change their meaning. GAME-32 does not adjust classes to repair those win rates. It provides values/costs/tags and validated snapshots that a shared GAME-33 engine can consume consistently for manual play and future autoresolve.

## Extension audit against GAME-87 design context

The attached synthesis is future research, not production scope. No aspects, injuries, transformations, relationships, event targeting or character-life UI were implemented. Existing ancestry/background feature roots and runtime `grant_feature`/`grant_sense`/status/modifier operators already allow sources outside class progression. A dedicated fixture grants Light Step to an adept through the generic effect primitive and verifies feature, tag and stride changes without class branching. A second fixture proves an external feature tag can make currently equipped gear illegal with a structured explanation. Current equipment requirements therefore use current granted features rather than only level-history features.

Class and feat entry are replayed against ordered, durable build choices and static ancestry/background roots. Class-option previews use that same basis, rather than suggesting entry based on temporary runtime grants that replay would reject. Future temporary injuries must not retroactively rewrite historical entry facts. If GAME-87 allows time-limited aspects to qualify for permanent advancement, it must define and persist a versioned grant/qualification history in that later change; this V1 does not invent such a life-history schema. Current tags/features can already be queried by the requirement API and supply legal abilities to an authority snapshot. Visibility decisions and narrative targeting remain the later owner’s responsibility.
