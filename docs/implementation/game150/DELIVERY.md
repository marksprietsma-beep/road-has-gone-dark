# GAME-150 — Wizard and Cleric Windows delivery

Four bounded gaps are addressed in immutable **trhgd-character-v23**: upper-tier arcane control/counterplay, divine condition protection/sustained recovery, two permanent-choice/ward-beneficiary defects, and live preparation-copy/slot feedback. No class, ancestry, feat or creature was added. Existing school/domain actions and level15 numerical features remain; this wave verifies their consumers rather than replacing them.

## Playable Windows package

[Download the complete Windows x64 artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39423972908/artifacts/12267518393). Extract the outer GitHub artifact, then **also extract** `game150-upper-prepared-windows-x64.zip`. Keep every helper, artwork, licence and support file together and run `road-has-gone-dark.exe`. No installed Godot or Node is needed; Escape skips the intro. New campaigns use v23. Older campaigns deliberately keep their original pins; do not delete/reset them.

SHA-256 of the **inner playable ZIP**:

```text
777260318d9763c1352fb78d54c6d8645927d00f8e48c6bd9119f529ff4351b3
```

Build/export source: `8b37e0d03ed38df138bc6bf2fdf6bba221673d85`; last production implementation: `7ff0e27d3bdcd6cfdead25e246fe42a3e920f63f`. Later changes correct diagnostic capture interactions, strengthen visual-evidence/readiness checks and add delivery records; they do not change shipped gameplay, rules, scenes, assets, helper or release exporter. The exact source comparison is recorded in evidence/source-equivalence.json. The original complete native release is retained, not described as a fresh test of later diagnostic/reporting edits.

Rules version23.0.0 / engine schema3; canonical content hash `e47c16b87f175d589b040984067146a13db4625fdfa2cada130815c730da8ffd`. All historical v1–v22 pack bytes and manifest rows remain unchanged, as does frozen GAME-32 TacticalCombat. Existing effects, turn boundaries, resource authority and the single campaign writer are reused.

## Playable changes

| Class/tier | Selection | Actual decision and counterplay |
|---|---|---|
| Wizard8 | Unweaving tide | Range6/radius1 enemy-group removal of sixteen explicitly supported temporary boons; independent Will saves. Nearby allies retain boons. Expands the existing dispel family, not universal antimagic or form removal. |
| Wizard9 | Stillness lattice | Will negates one target-activation main-action denial. Movement/shared reactions remain; condition immunity/cleansing counters it. Expiry never refunds an already prevented action. |
| Cleric8 | Concord of release | Ally-group removal and two-global-boundary immunity for Stillness, Dissonant Seal, Gravitic Snare, Slowed and Off Balance. No healing, slot recovery or extra action. |
| Cleric9 | Renewing benediction | Living allies heal20 immediately and12 at their own activation starts while the three-global-boundary boon remains. HP caps, expiry and dispelling apply. No downed/dead activation healing or resurrection. |

Every new spell needs a main action, one matching shared tier slot, one prepared copy, range/clear sight and the permanent INT/WIS requirement. Enemy saves still consume the cast. Tier8 unlocks at casting15 with attribute18; tier9 at casting17 with attribute19. Class references and numerical variants are not counted as new effect families. REPERTOIRE-AUDIT.json retains actual old/new payloads; PACK-DELTA.json lists the four new abilities, three statuses and four prepared-copy pools.

In v23 only, advanced Cleric6 domains require the original matching domain. Wizard Abjuration6/Cleric War6 give both ward and class-level temporary HP to the **selected ally**, instead of secretly buffering the caster. Native tests retain v22's old cross-domain and caster-buffer semantics. Existing Evocation/Abjuration/Healing/War branches execute and spend finite resources at1/6/20. The existing school/domain15 bonuses remain ordinary derived modifiers.

Spellbook now shows staged copies/daily capacity and actual current slots per tier, including OVER feedback. Rules reject excess copies and insufficient permanent attributes. Saving home preparations intentionally refills selected prepared-copy allocations; it **never** refills shared daily slots or creates XP. Eligible return/rest restores daily slots. This existing policy is explained accurately rather than silently rebalanced.

## Native evidence

[Complete Windows gate39423972908](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39423972908) **SUCCESS**. [Full native evidence](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39423972908/artifacts/12268191122) retains logs, timings, exact saves,32 proof receipts and18 original Godot renders. Every final phase executed freshly; none is a reused failed/cancelled prefix. Native phase time is2,466.140 seconds. All32 receipts have zero failures.

| Acceptance | Native outcome |
|---|---|
| New mechanics / exact cold restart / actual production controls |1,634 /97 /26 checks, zero failures|
| Genuine Wizard/Cleric/Fighter campaign / process restart |696 /8;49 opportunities,490 earned XP, level8, no XP injection|
| Actual earned allied wards / campaign cold resolution and return/rest |49 /64; actual resources, next-command log/RNG and final save exact|
| Current Bard/Beguiler/Spirit mechanics and cold / actual controls |1,560 /115 /72; matching v23|
| Current supernatural / signatures / mobile and cold |988/77,956/83,622/33; matching v23|
| Historical v22/v21/v20/v19/v18 tactical and cold |1,560/115,988/77,622/33,956/83,598/31|
| v16 legacy / compatibility and cold |818/4,1,941/486|
| All32 base-class current kernel audit / cold |2,598/65|
| Original Godot capture pass |32 checks/18 PNGs; specific visibility defects identified below|
| Independent package audit |7,061 entries; CRC/safe paths/unique entries, AMD64 game and bundled Node, exact v23/source/executable hash, licences, QA executable removed|
| Bundled production startup |Passed with empty PATH and no source-helper override|

There are114 legal class/spell cast witnesses over73 class/spell IDs at1/6/20, **not**73 new spells or one build owning every option. Lawful early/mid/high, low-attribute and Mystic Theurge17/8 casting examples are explicitly development fixtures. The genuine native journey earns490XP/level8; it does not claim earned level20. The five-level Theurge route preserves independent arcane/divine slots and requirements. No Linux game validation was performed; host source/JSON/archive/hash checks are separately labelled.

Actual screenshot review caught four search captures which set text without emitting the typing signal, so they still showed tier-one rows; the advanced-choice capture also needed the actual Specialisation tab. Those initial images remain unmodified in evidence/original-captures and the original artifact. The corrected Windows control/capture receipt and primary screenshots are recorded separately in SCREENSHOTS.md. This is a diagnostic-evidence correction, not a gameplay fix or another complete release claim.

## Readiness and remaining work

The all50-career matrix must be regenerated from the matching complete native proof **and** corrected Windows visual/control receipt before recording final totals. GAME-123 and GitHub101 remain open. COMPLETE means scoped executable original class identity, not every sourcebook feature, final human balance or clean visual acceptance.

Material limitations: explicit boon/condition lists rather than universal dispelling; global-boundary duration means casting order affects renewal ticks; no deity/religion system, general resurrection or exhaustive spell catalogue. Long action captions still clip, compact640 compromises remain, internal status labels are visible, and some hover tooltips overlap content. The requested1280×720 window produces1280×719 client pixels; original dimensions/hashes are retained. High-level fixture portraits also use existing humanoid fallbacks. These are not presented as clean visual acceptance.

Read REVIEW.md for exact character, choice, preparation, combat, rest and cold-reload instructions. Next recommended bounded task: audit Psion, Wilder and Cerebremancer's selected powers, augmentation, surge and independent arcane/psychic resources, then fix the strongest2–4 demonstrated gaps. Remaining martial/creature/prestige acceptance follows; no new roster or world expansion starts here. Linear is unavailable in this session; existing GitHub101 is the explicit tracking fallback, not a claim of a Linear update.
