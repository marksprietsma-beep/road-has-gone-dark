# GAME-129 — Class signature repair delivery

Candidate v19 improves the existing Soulknife, Warblade, Crusader and Swordsage without adding base/prestige classes, ancestry or spell counts. Existing campaigns retain exact v1–v18 pins. Baseline main ea1344c included successful GAME-133 and GAME-132 verification. PR#135 is the delivery branch; publication remains gated on actual Windows results, never this document alone.

## Implemented cohort

- Soulknife manifestation selects a real weapon instead of merely modifying an unarmed attack. Held equipment remains saved; natural forms take precedence. Dice grow1d8→2d6 at8→2d8 at16; manifestation enhancement scales with class level. Psychic strikes require the active blade and only deliver damage/disruption on confirmed hits; higher strikes and level4 ranged Hurl retain real resource, range and resistance costs.
- Warblade has exclusive Pressure/Shelter stances, movement/readiness-cost armed riposte, nonrecursive shared-reaction counterattack and main-only recovery. Later strikes make different tactical decisions: breach Guarding/Warded, Fortitude-resisted rooting, weakening, self-disruption cleansing and a late physical finisher. Separate damage packets each face ordinary resistance; these are original project adaptations.
- Crusader restoration/protection requires a real hit. One readiness renews at actual activation start, including the first encounter activation; manual recovery and finite capacity remain. No random manoeuvre deck is claimed.
- Swordsage has Flow/Cinder stances, movement/readiness-cost armed Afterimage and full-main-and-movement meditation. Afterimage spends the shared reaction after surviving an ordinary melee hit and protects against later weapons; it does not undo triggering damage.
- Existing Adamant stance and Martial recovery retain their passive bonuses and gain actual conditional consumers. One new feat, Mindblade echo, has a real Iron soul/class-level prerequisite and hit-confirmed shared-reaction buffer. Reaction effects compete with protection/opportunity and never chain. Concealment misses, ranged attacks and reaction attacks cannot trigger these melee counters.
- A v19-only condition in existing TacticalCombat requires an actual successful move command for Scout skirmish. Stance/arming/meditation token spending cannot fake travel. v1–v18 keep their original frozen condition. No second attack resolver, RNG, XP or save writer exists.
- Combat displays actual active weapon, owned focus/readiness, shared reaction and statuses. Trigger-only effects are excluded from manual buttons; explicit arm/stance/attack controls use existing campaign commands.

## Evidence and interpretation

Windows-only validation is in progress. Final delivery must record the actual successful run, source, archive URL/SHA, phase results and real PNG provenance. Never infer native completion from this candidate status. Focused Windows iteration and the required complete native gate are separate. Historical receipts are explicitly pinned; fresh campaign receipt comparisons use the exact current default.

The acceptance harness distinguishes lawfully constructed high-level development fixtures from three ordinary earned level8/490XP careers. It uses the sole production campaign writer for saved battle actions, cold process restart, normal combat resolution and return/rest. No QA executable or developer XP button is shipped. See TESTING.md for reproducible human instructions.

READINESS.json is the single reproducible functional matrix for32 supported base classes and18 prestige paths; it is separate from the760-occurrence research ledger. A level20 table does not make a class complete. Current native evidence may promote only its scoped cohort after all gates pass; the rich-character milestone and broader programme stay open. Human balance/readability acceptance remains separate.

Known limits: these are bounded original adaptations, not full sourcebook conversions. No general reaction-choice modal, sourcebook random manoeuvre deck, full disarm/terrain engine, new creature/art or living-world system is introduced. Ward stripping/cleansing is explicitly bounded. The finite next repair queue is in READINESS.md; GAME-123 stays open until all supported-class gates and acceptance are met, then priority moves to GAME-142/141 without waiting for the exhaustive research catalogue.

No callable Linear connector/credential is available. GitHub mirrors119/101/118 carry verified status; do not claim direct Linear updates.
