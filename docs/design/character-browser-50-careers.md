# Character browser: 50 player-facing career descriptions

**Status:** Proposed UI copy, based on the verified `trhgd-character-v30` readiness catalogue. Does not change mechanics, classes, or save-game pins.

## Design intent

- **New character:** show only the 32 starting/base classes. Keep prestige classes out of the initial selection.
- **Level advancement:** show the 18 prestige careers under a separate tab alongside available base careers, retaining every locked option with explicit requirements.
- Left pane: searchable, filterable class cards (name, compact `summary`, two or three playstyle tags); right pane: fixed class detail, full `description`, truthful mechanics/prerequisites and a level preview.
- Filters: free-text by name/summary/tags, role/playstyle chips; allow comparing two classes without losing the staged build.
- Selecting a class must not silently reset allocated abilities, equipment or level choices; use existing preview eligibility and commit authority.
- Responsive at 1280x720 and 2560x1440 with keyboard focus and scroll, no clipped action labels or tooltip-only critical information.
- Words like 'stealth', 'patron' or 'teleportation' must not imply unsupported mechanics. Keep short descriptions distinct from verified mechanical tooltips.

## 32 starting classes

| Class | Short line | Description |
|---|---|---|
| Barbarian | Rage-fuelled frontline fighter | A relentless warrior who burns limited rage to hit harder and survive brutal exchanges. Reckless and resilient paths offer different offensive and defensive trade-offs. |
| Bard | Songs, spells and party support | A charismatic performer who bolsters allies with sustained songs and disrupts enemies with hostile verses. Spontaneous magic and limited performance resources reward good timing. |
| Cleric | Divine healer and protector | A prepared divine spellcaster who heals wounds, protects allies and channels sacred energy. Excels at answering danger with the right prayers and controlled battlefield support. |
| Druid | Wild magic and changing forms | A guardian of nature who prepares restorative and controlling spells, follows a chosen bond and can assume a bear's form. Blends spellcasting with practical battlefield adaptability. |
| Fighter | Versatile master of weapons | A disciplined combatant who specialises in blades, bows or protective techniques. Weapon choices, feats and finite resolve shape distinctly offensive or defensive fighting styles. |
| Monk | Ki-powered unarmoured martial artist | An unarmoured martial artist who strings together unarmed strikes and spends limited ki on specialised techniques. Careful positioning and resource management matter as much as speed. |
| Paladin | Oath-bound divine defender | A steadfast warrior who smites selected foes, heals by touch and protects the party through divine grace. Combines armed combat with limited healing and protective power. |
| Ranger | Hunter, tracker and skirmisher | A wilderness specialist who chooses a quarry and fighting style before developing nature magic. Excels at focused weapon pressure and practical tracking rather than raw spell power. |
| Rogue | Precision striker and skill expert | A versatile expert who exploits openings created by allies to land precise weapon attacks. Special talents can hinder an exposed opponent or help escape trouble. |
| Sorcerer | Innate spontaneous spellcaster | An instinctive arcane caster whose bloodline and permanently learned spells define each build. Casts familiar magic without preparing individual copies, but choices carry lasting weight. |
| Wizard | Prepared scholar of the arcane | An intelligent spellcaster who plans a prepared repertoire and specialises in an arcane school. Rewards foresight, spell selection and well-timed control or protection. |
| Psion | Disciplined mental power | A psychic specialist whose chosen focus shapes the powers learned. Spend a shared pool of power points and augment individual effects when greater impact justifies the cost. |
| Psychic Warrior | Armed combat enhanced by thought | A martial psychic who spends a smaller power-point reserve to enhance the body and empower attacks. Trades a full psionic repertoire for practical battlefield presence. |
| Soulknife | Summoned weapon of the mind | A psychic fighter who shapes a mental blade, charges it with focus and can throw it at nearby threats. Focus is finite and requires deliberate recovery. |
| Warlock | Repeatable eldritch invocations | An occult invoker who unleashes repeatable eldritch attacks and chooses control or concealment techniques. Powers need no spell slots, but still spend actions and face counters. |
| Scout | Movement becomes striking power | A mobile combatant whose repositioning opens opportunities for skirmish damage. Rewards crossing the battlefield and choosing attack angles rather than remaining stationary. |
| Swashbuckler | Agile fencing and daring flourishes | A lightly equipped finesse fighter who spends resolve on skilful strikes that weaken foes or create protection. Favors quick, well-timed exchanges over heavy armour. |
| Knight | Hold the line for your allies | A protective warrior who challenges threats and uses a shared reaction to defend companions. Particularly effective when positioning matters and allies need a reliable front line. |
| Warblade | Stances, strikes and ripostes | A tactical swordmaster who shifts between offensive and defensive stances, breaches enemy guard and prepares responses to nearby misses. Special manoeuvres use recoverable readiness. |
| Crusader | Restorative strikes and martial resolve | A battle-tested guardian whose successful strikes can support allies and whose techniques reinforce nearby companions. Readiness returns during battle or through deliberate recovery. |
| Swordsage | Disciplined stances and deceptive strikes | A precise martial adept who alternates flowing and fiery stances, disrupts enemies and prepares afterimage defences. Meditation restores technique readiness at a tactical cost. |
| Wilder | Dangerous psychic surges | An intuitive psychic who pushes powers past safer limits for greater effect. Surges invite self-weakening consequences, creating a constant choice between impact and restraint. |
| Binder | Spirit covenants with real costs | An occult warrior who commits to an enduring spirit covenant, favouring ember-driven offence or sentinel protection. Covenant actions draw from a rest-limited pool. |
| Ardent | Psychic ideals made practical | A philosophical manifester whose chosen mantles shape accessible powers. Wisdom-guided abilities favour distinctive combinations of perception, protection and restorative support. |
| Lurk | Concealed psychic ambusher | A psychic infiltrator who combines limited power points, concealment and precise melee opportunities. Prefers a carefully prepared opening over sustained head-on combat. |
| Erudite | Broad knowledge, limited daily choices | A learned psychic with access to many powers but only a limited number of distinct identities per rest. Rewards adapting a deep repertoire to each expedition. |
| Divine Mind | Armoured psychic aura guardian | A protective psychic whose chosen mantle shapes nearby aura effects and learned powers. Switching support modes costs time and resources; position determines who benefits. |
| Marshal | Lead through commands, not spells | A battlefield leader who strengthens companions through local auras, rallies and limited tactical orders. Suits a party that benefits from coordinated positioning. |
| Beguiler | Illusions, subtlety and control | A spontaneous intelligence-based caster who deceives perception and alters enemy options. Prefers clever disabling effects and protective misdirection over straightforward damage. |
| Dragonfire Adept | Breath weapon and draconic invocations | An elemental invoker who repeatedly unleashes chosen breath attacks, favouring focused reach or wider bursts. Later invocations add protection and battlefield control. |
| Duskblade | Channel magic through a blade | An intelligence-based warrior-mage who delivers a chosen known spell through an equipped melee weapon. Even a missed attack consumes the action and spell slot. |
| Spirit Shaman | Nature spells guided by spirits | A spirit-focused nature caster who retrieves a limited spell selection after genuine home rest. Combines Wisdom-based magic with chosen guides and finite spiritual favour. |

## 18 prestige classes

| Class | Short line | Description |
|---|---|---|
| Duelist | Finesse and calculated counters | A prestige fencing specialist focused on precise weapon technique and personal defence. Suits an experienced combatant who prefers timing and elegant exchanges over brute strength. |
| Eldritch Knight | Weapon mastery meets arcane study | A prestige warrior-mage who continues a chosen arcane casting tradition while improving martial capability. Its strength is combining weapons and spells within one build. |
| Arcane Trickster | Spellcasting with rogue precision | A prestige infiltrator who mixes arcane magic with opportunistic, precision-focused combat. Rewards careful positioning, well-chosen spells and exploiting openings rather than direct confrontation. |
| Mystic Theurge | Arcane and divine magic united | A prestige caster who advances one existing arcane and one divine tradition independently. Gains broad spell access and specialised restoration or protection, without sharing the two spell pools. |
| Shadowdancer | Concealment in living shadow | A prestige combatant who uses shadowy shrouds and movement-based disruption to make physical attacks less reliable. Focuses on concealment and control, not unrestricted teleportation. |
| Dragon Disciple | Awaken inherited draconic power | A prestige path that develops draconic traits, natural protection and fiery breath. New bodily capabilities do not erase the character's original ancestry or history. |
| Dwarven Defender | An immovable defensive bulwark | A prestige protector who anchors a defensive stance to gain resistance and stronger protection. The price of holding firm is severely limited movement. |
| Pyrokineticist | Psychic fire and focused ignition | A prestige psychic specialist who turns existing power points into flame-based attacks and pressure. Trades broad flexibility for a distinctive command of fire. |
| Warshaper | Body and weapon become one | A prestige specialist who draws strength from an altered physical form and its natural attacks. Success depends on the active body, its reach and compatible equipment. |
| Bonded Summoner | Fight beside a bound summon | A prestige specialist built around an existing summoned companion. Its usefulness comes from coordinating a separate ally and managing the limits of that bond. |
| Cerebremancer | Spellcraft and psionics together | A prestige hybrid who advances an existing arcane casting tradition alongside psychic manifesting. Offers two separate magical toolkits to a carefully qualified character. |
| Beast Steward | Deepen an existing animal bond | A prestige companion specialist who develops one established animal partnership through training and deliberate commands. The bonded creature has its own identity and battlefield role. |
| Cognition Adept | Psychic hunter and mental defender | A prestige fighter trained to combine precise weapon strikes with psychic wards and learned powers. Focuses on identifying and overcoming dangerous adversaries. |
| War Chanter | Turn battle into a rallying chorus | A prestige battlefield performer whose wider war chorus and finite rally power support the company. Brings sustained morale and protection into martial encounters. |
| Archmage | High arcana earned through mastery | A prestige arcane expert who advances an established spellcasting tradition and chooses powerful force or warding techniques. Access requires genuine advanced spellcasting. |
| Metamind | Stretch psychic endurance | A prestige psychic master who deliberately converts a finite reserve into recovered power points. Excels at sustaining a long series of decisions, not infinite casting. |
| Abjurant Champion | Armed combat behind arcane wards | A prestige martial caster who advances an existing arcane tradition while choosing a protective aegis or retaliatory technique. Powerful defences remain action- and resource-bound. |
| Grove Warden | Sanctuary and restorative nature magic | A prestige nature protector who advances an existing nature caster, maintains a nearby sanctuary and spends finite favour renewing allies. Focuses on local protection rather than wilderness travel simulation. |

## Implementation note

The adjacent JSON is keyed by existing stable class IDs and contains `kind`, `summary`, `description`, and discoverability tags. It is proposed presentation copy; do not overwrite the historical class content `description` field in immutable v1–v30 packs. The current `scripts/ui/components/build_editor.gd` uses one class OptionButton with a search LineEdit and replaces visible `class_detail` text with compact statistics while full mechanics live in the progression tab/tooltip. An editable, data-driven detail pane should read the appropriate UI copy without changing the underlying class-selection, legal-advance or save behavior.

**Not implemented in this design handoff:** Godot GUI changes, new game abilities or prestige unlocks, original deity/pantheon system, changes to old content packs.
