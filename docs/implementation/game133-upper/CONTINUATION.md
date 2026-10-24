# In-progress source checkpoint

Branch feature/game-123-sorcerer-druid-upper-tiers, based on main3e62d5c. Four-spell immutable v27 cohort, existing capability gates, small v27-only weapon-shell interception and allied-form reversion are implemented. No1–26 pack changed; static source guard passes. Windows validation has **not yet passed**. Do not promote either career or claim a playable release yet.

Focused workflow: `.github/workflows/verify-upper-nature.yml`. It runs on this feature branch, PR and main, Windows only. First diagnose actual import/compile/mechanics/control failures, preserving assertions. `tests/upper_nature/run-focused.py` never executes a game on Linux. `check-source.py` is static host inspection only.

After focused success: finish earned ordinary Sorcerer/Druid/Fighter campaigns using the existing nature journey; saved encounter/cold continuation; production-scene captures at supported sizes; full native package/independent archive/source/hash/licence audit; evidence-gated31→33 readiness only if actual criteria pass. Release packaging script and captures are still pending. Preserve source checkpoints before expensive tests. Update stale game127-support/NEXT-WAVE.md and reassess the remaining hybrid queue; do not implement another cohort.

Create one reviewable PR, inspect all changes, wait required Windows checks, merge normally, verify actual main/post-merge outcomes. Keep GAME123/#101 InProgress/OPEN; no direct Linear write is available. No new roster/world development.
