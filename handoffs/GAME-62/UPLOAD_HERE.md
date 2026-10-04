# GAME-62 — Original Git bundle handoff

**Status:** source has been preserved in the original `GAME-62-Complete-Delivery.zip` from Codex/Work but NOT yet uploaded to this branch. Only this small file is required for publication.

## One required upload

Open the original `GAME-62-Complete-Delivery.zip` on your PC, extract `GAME-62-source.bundle` (about 125 KB), and upload that exact file into **this folder** with GitHub **Add file → Upload files → Commit changes**. Keep the exact filename `GAME-62-source.bundle`. Make sure the selected branch is `handoff/game-62-local-region-upload`, **not** `main`.

A dedicated workflow at `.github/workflows/restore-game-62-bundle.yml` checks the prerequisite base `3c06cf81e46c7ce9edd4e9ebf20a9940c0ca6f23`, verifies the bundle's exact commit `0c15fcc77011d5dd1ca5418cbc67be1cee576360`, and attempts to push the **same original commit** to `game-62-preserved-original`. It does not change game code, create a PR or merge. If GitHub Action write permissions fail, retain this bundle as evidence and report the exact job error.

The full delivery ZIP (16.5 MB) includes existing QA screenshots and tests and remains independently preserved; it does **not** need to be placed into Git history to publish the original commit. The user or ChatGPT Work can subsequently review the original review ZIP separately. A draft PR against `main` should be opened **only once** `game-62-preserved-original` exists and its SHA has been verified; do not merge automatically.

Linear: https://linear.app/marksprietsma/issue/GAME-62
