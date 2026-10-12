# GAME-119 implementation assessment

Start: GAME-118 draft PR88, 9a52a7bed19cda2b2ecdc3e5e435dc9598812be9. Independent branch is stacked on that exact implementation. Accepted GAME-88 identity/build/life direction was read from the research branch; culture, ancestry, build and acquired conditions remain distinct.

The existing GAME-32 engine already replays ordered multiclass history, skills, class BAB/saves and declarative prerequisites. Reuse it, the campaign lock/journal/save owner, creator editor, spellbook editor and tactical effects. No second rules engine, save writer or combat action economy.

The blocking gaps were durable class choices, simultaneous general/class feat grants and choosing which existing casting track a hybrid prestige class advances. These are implemented as optional versioned class definitions and explicit choices in v7 ordered history. Old v1–v6 records retain exact original shape and mechanics. New campaigns use v7; no campaign auto-upgrade.

This coherent batch targets all eleven core classes through **12**, two scheduled specialisation groups per core class (plus Ranger quarry), and **four five-level prestige adaptations**. It does not claim full levels 1–20, sourcebook parity, every domain/bloodline/school, companions, summons or completion of 403/66/~283 research scope. Higher progression is only counted when actual effects and resources validate.

Prestige paths: Duelist, Eldritch Knight, Arcane Trickster and Mystic Theurge. Durable entry uses BAB, skill ranks, feats, casting and a Sneak Attack feature. Temporary battle statuses/runtime grants never qualify historical entry. Hybrid progression advances selected spell tiers/slots/repertoire without granting unrelated base-class abilities or rewriting original classes. Persistent-world prerequisite paths are not implemented in this batch; no fictional accomplishments are granted.

Sequence: exact-pinned content and generic replay; visible player choices and prerequisite explanations; actual effects/negative gates/persistence; original fresh/legacy input tests; native Linux/Windows packages and rendered evidence. High-level fixtures are explicitly developmental, never free production XP. Ordinary victory/earned level-two/reload remains part of native review.

XP assessment: current policy is 10 × (level − 1)²: level6 needs250, level12 needs1210, level20 needs3610. Existing finite contextual opportunities do not guarantee enough earned XP for deep progression. Keep that policy/pinned consequences unchanged; use real victory for accessible earned advancement and clearly labelled legal development fixtures for higher combinations. A separate repeatable-opportunity/pacing ticket is required before claiming the full career is organically accessible. No unrelated world-content expansion or arbitrary XP grants here.

CI exposed an older byte-protection assertion for the entire tactical file. The frozen v1-pins hash is retained. Its test now projects away exactly two explicitly v7-gated quarry calls (one attack modifier, one damage modifier), then verifies the original complete source hash. Any other legacy source change still fails. The independent frozen GAME94 oracle and GAME32 oracle remain unchanged; actual v7 quarry attacks also compare damage and RNG. This is an explicit new-content extension, not a blind hash update.

The legacy battlefield preview supplied an empty world entry to the redesigned creator. Its fixture now reconstructs the same public seed once, verifies the original fingerprint and binds the real read-only world. All original roster/portrait/input/command assertions remain. Production sheet reading also falls back to campaign hometown for old members that predate individual origin_refs; no save migration or write is required.
