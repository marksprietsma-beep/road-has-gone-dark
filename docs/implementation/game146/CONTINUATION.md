# GAME-146 work in progress

Branch: feature/game-146-mobile-precision. Baseline a10f533. Implementation candidate v20; not released, not native validated. Do not merge until all required gates pass.

Focused Windows workflow `.github/workflows/verify-mobile-precision.yml` exercises `tests/mobile_precision/review.tscn` twice (fresh/cold). First priority: inspect actual CI import/schema/mechanics failures; correct before release checks. No Linux game execution is authorised.

Remaining: broaden negative/hit/reaction/precision+skirmish witnesses; real Duelist/Arcane Trickster progression; rest and earned campaign; actual production controls/screenshots; single complete Windows distribution gate; update all-50 readiness with evidence; PR review, current-head checks, normal merge and post-merge validation. Counts unchanged (32 base,18 prestige); milestone not complete.

Verified production-code head `03fc70a`:582/33 Windows fresh/cold, zero failures (run39184788280), v20 hash79fa1f89a785b37fe651d422755ac9634dbfef8e9b9f959bdc08f510ebba8483. Focused tests now include actual prestige precision, selectable Rogue talents, early/mid/late Scout/fencing strikes, active weapon override and shared protection. Original failed fixture attempts are documented; no checks were suppressed.

Next: dispatch `verify-mobile-precision.yml` on the latest branch with `release=true`. The full release runner includes actual earned prestige journeys, inherited current-v20 signatures, archived v19/v18/v16, all32-class audit, production input, captures and empty-PATH native export. Diagnose actual logs if any phase fails; do not redo passed source mechanics unnecessarily. Download complete native evidence and playable artifact; run the independent host archive audit, inspect Godot PNGs, generate `python tools/character-content/build-readiness.py --native <evidence-dir>`, and commit truthful final delivery/status. Review PR139 current-head Windows gates, mark ready and merge normally only when green. Keep parent101 open. Preserve existing incidental Python `__pycache__` outside commits.
