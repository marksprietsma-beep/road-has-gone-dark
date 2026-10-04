# Execute exact source restoration

This script stages all GAME-62 source files byte-for-byte from commit `0c15fcc` while omitting **only** `.github/workflows/verify-local-region-v1.yml` because GitHub Actions tokens cannot publish changes to workflows. The workflow is subsequently restored by the connected GitHub App using the original bytes. The original bundle remains preserved unmodified, and no merge is authorised.
