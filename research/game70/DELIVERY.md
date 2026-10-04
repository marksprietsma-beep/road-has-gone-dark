# GAME-70 GitHub delivery

[Draft PR #53](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/53):
head `research/game-70-map-flow`, base `research/game-69-settlement-art`.
Open draft, not merged. Base is exact GAME-69 commit
`c90a96be9c1a6546f147e4853d5bdc183a8b24c9`.

Incremental pushes were checked independently with `git ls-remote`:

- `2c1ae7a070ea1e27129a93d76a0eb00e212a77e8`: initial meaningful publication gate.
- `acea06dcf5b8f52dbbce6e50b19a10b7a5076a09`: native scene, adapters and exact proof assets.
- `479f39f81025c2e4b0bab0f9688b608123f58591`: final executed tests, screenshots, caching and review package.

The final completion message reports the latest remote SHA after these notes.
Its own SHA is not embedded in the commit. Final verification compares the remote
branch and PR head, matches every changed file's Git blob against the published
GitHub API tree, and checks scope and unchanged upstream refs.

Allowed changed paths: `research/game70/`, `scripts/debug/game70/`,
`scripts/debug/world_region_town_flow.gd`, and
`scenes/debug/world_region_town_flow.tscn`. Existing world/region renderer and
generator files, canonical fixtures, original archives, main scene, saves and all
GAME-67/69 files are unchanged relative to the base.

PR #51 remains open/draft at `740f1910787cafae172fdf5d74777bbb032b92a0`.
PR #52 remains open/draft at `c90a96be9c1a6546f147e4853d5bdc183a8b24c9`.
Their titles/heads/statuses remain unchanged. Main remains
`238045b395ad9e693c71ac6b018442257fe0d6f3`. No force push or merge.

The existing **Verify Local Region Generator V1** GitHub workflow started for
the new debug region-scene paths. Its live status is on the PR/Actions page;
the completion message distinguishes its final status from the executed local
suites in the README. No CI pass is inferred from an empty status-context array. Authenticated Linear
access was unavailable, so no issue contents/statuses were independently fetched
or changed. The uploaded brief and repository documentation supplied the scope.
