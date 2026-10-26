# GAME-161 — Ranger and Beast Steward

Continue the existing50-career GAME-123 milestone; no new career, ancestry, feat, spell, creature, AI or world framework is proposed. Main f9880ed0865f163a8f90a19b2a650365b664dd96 already contains merged Monk/Paladin160 and native31 acceptance40287149055. Readiness remains41 COMPLETE /9 PARTIAL /0 BLOCKED until this pair has matching-source native evidence. The successful31 release is preserved, not manually rebuilt.

## Existing implementation to retain

Ranger already has Archery/Blade choices, raider/archer quarry, costed styles and pursuit techniques, prepared Wisdom-based nature magic, a persistent chosen companion from4 and late techniques through20. Beast Steward already has durable bond/feat/rank/level prerequisites, an optional five-level prestige track, Swift/Enduring training, actual companion growth, finite Rally/Pack Drive ally commands and its own resource pool.

RulesCharacter/RulesCareer/RulesExpressions/RulesModifiers/RulesEffects/RulesEntities and the inherited TacticalAuras/CombatEntities path own these mechanics. Existing creator, advancement, spellbook and combat controls already expose their choices and actual owned-actor turns. GamePlaythroughStore remains the sole campaign writer; ordinary OpportunityCycles fund advancement. Reuse them.

## Three confirmed released31 Windows defects

1. Aimed Shot is described as a bow attack but has no active-ranged requirement. Reproduce an actual shortblade Aimed Shot before changing it.
2. Paid Archery Style gives unconditional damage, including actual melee strikes/reactions. Reproduce paired equal-RNG melee attacks and inspect the real modifier context. Existing attack_ranged_weapon predicates can constrain the damage without a new resolver.
3. Companion scaling preserves a numeric HP deficit. A zeroHP pet can therefore gain positiveHP during advancement without eligible recovery. Reproduce a valid defeated owner/pet record advancing through the actual kernel; preserve downed state under the next immutable pin while retaining ordinary living damage deficits and spent effort.

Windows40332195985 at352d11c passed76 checks and reproduced all three: shortblade Aimed Shot accepted, melee Archery damage0→2 and defeated companion0→5HP. Original receipts/timings are preserved. Append32 with only the data predicates/conditional modifiers and a version-bound shared companion correction. Preserve all released1–31 bytes/pins, frozen attack/RNG/writer, existing quarry profiles, support target policy, resource/XP rules and the same50 careers.

## Execution order and acceptance

First finish actual f9880ed main-push Windows integration, record all25 runs, close156 and keep101OPEN. Start this new branch from updated verified main; do not reuse/remerge160. Run a small released31 Windows probe before a correction.

Then use focused current mechanics/cold/production-control checks: actual ranged attacks, style alternatives, quarry, prepared spells, permanent growth/ownership, all five prestige levels and optional entry/decline, creature turns/attacks/movement/reactions, finite commands, summon separation, owner defeat, negative cases and exact cold replay. Cache development tracks rather than repeatedly running the expensive all-base audit.

Separately earn490XP/total8 through existing ordinary opportunities: Ranger Archery/Wolf, Ranger Blade/Leopard and Ranger5/Steward3/Stag. Preserve the actual funded250XP Ranger5 entry/decline state. Connect real pet damage and owner actions to a saved campaign battle, cold resolution and eligible home recovery. High20 and prestige5 records are labelled development fixtures; no earned20 claim.

After focused/source-earned/capture success and stable inputs, run one complete Windows-native self-contained release: all32 base tracks once, historical31/30/29/18/16, frozen22,181, actual controls, independent cold processes, original Godot captures, emptyPATH production/QA startup and archive/source/hash/licence checks. No Linux Godot validation. Only matching-source native acceptance can promote these two to43/7. Publish one PR for161, pass current-head Windows, normal merge, confirm actual post-main and close161;101/GAME-123 remains open.

## Limits retained

Quarry uses existing humanoid-raider/hostile-ranged profiles, not a new monster taxonomy. Creature art is an honest humanoid fallback; no new quadruped, flight, ecology or AI claim. Existing global-round withdrawal after owner defeat and ally-wide Steward support remain. The separate50-career browser158, shared long-label/small-window issues, pantheon, monsters, NPCs and living-world work are outside this cohort.
