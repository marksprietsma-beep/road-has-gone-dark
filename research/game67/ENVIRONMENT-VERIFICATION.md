# GAME-67 environment verification

The Codex Cloud checkout uses the HTTPS origin
`https://github.com/marksprietsma-beep/road-has-gone-dark.git`.
Remote `main`, `review/game-67-facilities-recovery`, and
`handoff/game-63-settlemaker-upload` were fetched successfully.

The review branch descends from accepted GAME-62 merge
`238045b395ad9e693c71ac6b018442257fe0d6f3`, which is also the fetched
`main` baseline. No merge or reset is required. Its existing change is
the recovery handoff documentation; no GAME-67 implementation is present.

The GAME-63 holding branch contains `handoffs/GAME-63/REVIEW-2026-10-04.md`.
The four original `game63-proof.7z` volumes are present in the checkout;
archive integrity must be tested before using the preserved source data.
The review records upstream Settlemaker revision
`d5cf3590cf59e1d382110d25a6910f12507299e2` and the Batan, Albanes, and
Thilranlena source settlements.

The authorized rebuild is confined to research: a provider-neutral facility
model, standalone inspection viewer, tests, and review evidence. Accepted
GAME-62 code, production Godot scenes, world fixtures, saves, and gameplay
remain outside scope. Settlemaker's synthetic geography and GPL-3.0-only
engine licence require explicit documentation and prevent assumptions about
shipping integration.

This initial commit tests direct publication to the existing review branch.
Implementation proceeds only after its exact SHA is verified remotely.
No attempt will be made to recover the lost GAME-67 implementation.
