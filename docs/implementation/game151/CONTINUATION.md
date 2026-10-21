# GAME-151 publication checkpoint

Branch `fix/game-151-windows-regressions` from `813bf519dc2d33d42e87c44021157ce911aad965`; draft PR [143](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/143). All runtime scripts/data, rules v1–v23, saves and readiness unchanged. Source repair1563c4a; later commits retain evidence/documentation only. No further character wave is part of this PR.

Focused Windows39537842078:206 checks and14 exact cold-restart checks, zero failures. Current PR-focused39537944304 also SUCCESS. Original failure is four missing new zero-capacity prepared-copy fields, not domain incompatibility. Render-only helper validates both pins, never respecs, refills or writes a campaign. Exact domain/forged-pin negative gates retained.

At this checkpoint branch review39537454580 and full GAME-13039538194941 are running. Inspect their actual conclusions; do not restart successful phases. Require them and latest-head PR checks to pass before normal merge. Verify actual postmerge GAME-130, review, production UI and focused Windows checks. Record final run conclusions/main SHA in PR143 and issue101 so documentation-only receipts do not recursively trigger new release commits. If anything fails, retrieve exact logs and correct narrowly.

Successful full GAME-150 native release39423972908 and corrected controls39432740551 are reused as historical evidence; do not rerun the expensive release without demonstrated need. Keep101/GAME123 open; readiness20 COMPLETE /30 PARTIAL /0 BLOCKED. Linear is unavailable in this session; do not claim a Linear status change. Next recommendation: Psion/Wilder/Cerebremancer after repair acceptance, with no implementation here.
