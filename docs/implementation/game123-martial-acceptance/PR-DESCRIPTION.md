## Problem and behavior

Fighter Veteran/Archery/discipline bonuses were lost to existing same-type training. Disciplines also accepted the wrong active weapon, and pure Barbarian Resilient mastery granted a DC it could not use. Append-only30 makes the bonuses actually apply, scopes disciplines to their actual equipment/attack profile and gives Resilient mastery real Fortitude. Existing paid Rage combinations and functioning late Whirlwind DC remain intact.

The Windows production-control test additionally reproduced an empty-search bug that hid every feat except the selected default; clearing class search had the same pattern. The existing creator now restores full lists for an empty query, retaining selected choices during nonempty searches.

## Scope and authority

- Existing32 base /18 prestige careers, cap20; no new roster, feat, creature, spell, gear or ability records. All1–29 bytes/pins stay unchanged; new campaigns use30 and old saves are never migrated.
- Reuse original attack, RNG, XP and sole campaign writer. The existing tactical adapter supplies scoped transient actual-weapon context to derivation and restores it after normal/natural/reaction attacks; no parallel resolver or saved context.
- Auditable small content recipe and exact source/old-pack guards explain the large appended JSON snapshot.

## Verification and delivery

See [delivery](docs/implementation/game123-martial-acceptance/DELIVERY.md), [exact review instructions](docs/implementation/game123-martial-acceptance/TESTING.md) and [source-labelled evidence](docs/implementation/game123-martial-acceptance/evidence). Windows only. Focused candidate input, earned/cold journey and final native acceptance are pending at this preparation checkpoint; no completed release/readiness promotion is claimed here.

The final delivery must include real paid hit/miss/critical/protection/rage counterplay, deliberate feats/gear, finite resources/expiry/recovery, actual production controls, three ordinary490XP/8 builds, connected command/resolution/home-rest and exact process restart. High20 examples are labelled development fixtures. Native archive/startup/source/credits/SHA, historical/frozen regression and genuine Godot captures gate promotion of this pair to39/11.

Tracks #153; close it only after the merged main passes its actual Windows integration checks. Parent #101 / GAME123 remains open. Monk/Paladin156 begins only after this PR is green, normally merged and actual post-main Windows passes. No world/NPC/pantheon work.
