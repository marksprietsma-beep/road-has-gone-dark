# GAME-127: bounded psychic identity acceptance

Recovered main e96c235c6dfe244801b9d4ef09d8dcfd929f0e2f, v24, 23 COMPLETE / 27 PARTIAL. No concurrent GAME-127 branch or PR existed. All50 readiness rows and GAME-152's finite next-wave guidance were reviewed. The roster remains32 base /18 prestige; no additions are planned.

Existing authority already implements permanent mantle/power choices, owning-class casting attributes, shared manifesting expenditure, veil/ambush costs, Erudite distinct-per-rest identities, eligible rest, ordered advancement and exact pinned saves. Preserve those mechanisms.

Two defects were reproduced on native Windows before release validation (run 39739126204:71 checks, zero failures):

1. Lurk's authored adjacent melee ambush uses generic weapon-strike reach. A lawful large-ancestry character can ambush from two tiles despite the authored one-tile targeting range. Fix only the actual weapon/range gate, preserving the explicitly authored psychic effect followed by a separate attack roll.
2. Erudite's authority rejects a new distinct power after exhaustion, but actual combat controls and target highlights still offer it. Repeated identities must remain available; failed previews must not spend resources or RNG. Reuse the existing distinct-access authority for presentation.

Ardent mantle restrictions and all three classes' existing progression, resource recovery and persistence require proof, not speculative replacement. No additional defects will be invented to force new content. Append v25 only for the necessary Lurk rules change; retain v1–v24 byte-for-byte and exact historical semantics. Focused Windows reproductions precede implementation, then actual production controls, lawful development histories and separately earned adventures. One complete native Windows release follows a stable candidate.

Linear has no callable connector in this session; GitHub101 and committed delivery records will carry verified status. Human balance/readability acceptance remains separate from technical readiness.

The first reproduction attempt used two active weapons and was correctly rejected by the existing equipment validator. That invalid fixture is not evidence of a production bow exploit. The corrected reproduction uses a lawful Ogre Lurk with inherited reach and one equipped shortblade.

The Erudite display-only correction also applies to older eligible packs (v14+): their existing distinct-access validator already rejects the action. Current historical24 continuation requires disabled controls while preserving its old ambush mechanics. The original pre-fix reproduction remains at d5a611d and evidence/v24-baseline-proof.json; no historical rules are changed.
