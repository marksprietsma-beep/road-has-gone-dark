## Problem and behavior

Fighter Veteran/Archery/discipline bonuses were lost to existing same-type training. Disciplines also accepted the wrong active weapon, and pure Barbarian Resilient mastery granted a DC it could not use. Append-only30 makes the bonuses actually apply, scopes disciplines to their actual equipment/attack profile and gives Resilient mastery real Fortitude. Existing paid Rage combinations and functioning late Whirlwind DC remain intact.

The Windows production-control test additionally reproduced an empty-search bug that hid every feat except the selected default; clearing class search had the same pattern. The existing creator now restores full lists for an empty query, retaining selected choices during nonempty searches.

## Scope and authority

- Existing32 base /18 prestige careers, cap20; no new roster, feat, creature, spell, gear or ability records. All1–29 bytes/pins stay unchanged; new campaigns use30 and old saves are never migrated.
- Reuse original attack, RNG, XP and sole campaign writer. The existing tactical adapter supplies scoped transient actual-weapon context to derivation and restores it after normal/natural/reaction attacks; no parallel resolver or saved context.
- Auditable small content recipe and exact source/old-pack guards explain the large appended JSON snapshot.

## Verification and delivery

The complete [native Windows release40256408205](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40256408205) passed at `e24d7a2ba920f167485ead1804327b7a59163a6d`; subsequent changes are delivery-only. Final native mechanics1143/cold49, extended642/cold37, production input141, ordinary490XP/class8 journey623/cold8, connected34/cold82, all32 tracks2598/cold65, frozen22181 and historical/upper-casting/cold gates all passed. Twenty genuine Godot renders include paid Whirlwind/Titan actions and explicitly labelled high-level fixtures. Source-bound readiness is39 COMPLETE/11 PARTIAL/0 BLOCKED.

[Playable Windows x64](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40256408205/artifacts/12624458209); inner ZIP SHA-256 `2449b5160b23b0ff46af36df4430eb2fbe216c21a4a468f41f1853912e8bdbd0`. Empty-PATH exported-game execution, independent production startup, AMD64/support files, credits, source/core equality, archive CRC and exact cold continuation passed. [Delivery](docs/implementation/game123-martial-acceptance/DELIVERY.md), [review steps](docs/implementation/game123-martial-acceptance/TESTING.md), [original screenshots](docs/implementation/game123-martial-acceptance/screenshots/README.md).

Known limits: long shared combat labels clip and need scrolling; existing humanoid LPC fallbacks; ordinary earned campaign reaches8, not20. No general UI/balance completion claim.

Tracks #153; close only after normal merge and actual post-main Windows checks. Parent #101 / GAME123 remains OPEN. Monk/Paladin #156 begins only after this integration passes, on a fresh main-based branch. No world/NPC/pantheon work.
