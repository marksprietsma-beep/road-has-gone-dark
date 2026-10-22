# GAME-127: Ardent, Lurk and Erudite acceptance

**Status: implementation and focused Windows verification complete; earned/native release and publication validation pending. Do not treat this checkpoint as a completed delivery.**

Draft PR145: https://github.com/marksprietsma-beep/road-has-gone-dark/pull/145

Baseline main e96c235c6dfe244801b9d4ef09d8dcfd929f0e2f. Candidate implementation c9a9827f4220ef36a37e9ad9edd651e9f396d415; focused source73c9417dd532503e42a657ae055be1187b74135d. V25 content hash `c828f3cb74005a4b602bd5986fa96549905a0699dd780e75d7bb40c84b7c98a7`. Fresh campaigns default to25;24 historical pack bytes/pins remain unchanged. No roster additions or silent save migration.

## Reproduced defects and bounded corrections

1. The historical tactical weapon-strike adapter used normal weapon/ancestry reach for an ability authored as adjacent. A lawful Ogre Lurk could use Psychic ambush at Manhattan distance2. V25 appends typed `requires_adjacent` and `requires_melee` descriptors consumed by the existing TacticalAuras eligibility adapter. Ordinary extra-reach attacks stay legal. Earlier invalid two-weapon and blocked-cell reproduction fixtures were corrected; their failures were not counted as production defects.
2. Erudite's existing authority correctly rejected a new power identity at the distinct-per-rest cap, but actual action buttons and target previews still offered it. V25 presentation reuses the same existing `RulesWaveFour.power_access` predicate. New exhausted identities have disabled actions, no legal target highlight and a visible explanation; repeats and affordable augmentation of used identities remain possible. No resource, save, action or RNG authority was duplicated.

Ardent's existing permanent mantle/power restrictions and learned-class attributes were retained. Energy/body versus energy/mind choices, temporary-feature rejection, distinct mantles, multi-manifester origins, tactical attack/ally support, finite points and eligible rest are exercised. Level20 includes an executable tier9 ally-support alternative.

Lurk still spends main/focus to veil, grants25% weapon concealment for two global round starts, then pays main/focus/PP and consumes veil for adjacent ambush. Its **existing direct psychic damage/off-balance precede a separate weapon attack**: the weapon can miss; this wave does not turn the direct component into a hit rider. Starting focus is2, enough for one sequence. Exhaustion, duration expiry, owned equipment, inherited reach, actual target tiles, hit/miss and exact replay are tested. No invisibility/general stealth engine is claimed.

Erudite retains `1 + floor(Erudite level/4)` distinct identities per eligible rest across augmentation, repeated casts, encounter changes and cold restart. Repeats still require PP/actions. Exhaustion and home recovery are tested without free production resources.

## Verified evidence so far

Historical v24 reproduction: run39739126204,71 checks /0 failures.

Current focused Windows: https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/39740020116

- V25 mechanics752/0.
- Separate-process exact restart102/0.
- Actual production creator/combat controls147/0.
- Retained historical baseline71/0.
- Development histories1/4/8/15/20 for all three; these are not earned level20 characters.

Earned/connected/capture run39740803359 is pending. One complete native release has not yet run. Windows build URL/SHA and final source/main SHA will be recorded only after genuine verification. Readiness remains23 COMPLETE /27 PARTIAL /0 BLOCKED until the native-gated generator runs.

## Counts and limits

The unchanged roster is32 base careers /18 prestige paths (50 supported careers),37 ancestry families /50 heritage records,83 feats,14 skills,45 selectable psychic powers and14 creature definitions. Named ability records are not unique spells. All three targeted base classes retain cap20; the ordinary campaign journey is separately tested at490 earned XP /level8.

Original bounded adaptations, finite shared manifesting pool, supported humanoid LPC fallbacks and human readability/balance acceptance remain separate from technical functional readiness. The character milestone is not finished. No world simulation or roster expansion was started.

Linear has no callable connector in this session; GitHub101 and committed records are updated without claiming a Linear write. See TESTING.md for the exact manual journey; CONTINUATION.md records pending publication steps.
