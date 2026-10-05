# Prepared Linear update — GAME-71 and GAME-72

Implementation ready for Mark's review; keep acceptance pending. No Linear tooling
was accessible in this cloud session, so this text has not been posted.

GAME-71: confirmed camera-scaled small glyphs, offset halos, estimated collision
bounds and actual high-resolution viewport undersampling. Replaced these with
native-pixel measured, deterministic priority labels and thin outlines; selected
settlements remain eligible, and congested selected labels can use a short source
leader. Native map resolution and mouse/camera conversions now respect physical
output scaling. Both canonical worlds were captured at fit/medium/dense/selected,
125% and 2×; GUI/input checks include 1920×1080 and 3840×2160.

GAME-72: confirmed combined marker/label collision plus selection-first ordering
caused unrelated marker suppression. Stable known-only marker groups now precede a
separate label pass. Same-camera snapshots for all requested Albanes selections,
and representative Batan/Thilranlena selections, show identical marker IDs, exact
source locations and membership. Full known index, building roof hit tests and
canonical polygon highlights remain functional; unknown facilities stay excluded.

Evidence, reproduction commands and executed inherited/regression test results are
in research/game71-72/README.md. Native Windows laptop validation and low-end GPU
performance remain unverified. Gameplay, source geography, accepted generation,
settlement identities/art/geometry, saves, main scene and GAME-73 are unchanged.
New draft PR targets research/game-70-map-flow; existing PRs remain untouched.
