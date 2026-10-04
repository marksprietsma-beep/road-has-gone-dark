# GAME-63 — Settlemaker research archive upload

**Research only — no implementation or integration authorised.** This folder accepts the complete original Settlemaker evidence archive. The 36,523,657-byte ZIP exceeds GitHub's browser per-file upload limit. Upload the provided, **already split** files instead:

- `GAME-63-Settlemaker-Feasibility.zip.001` (20,971,520 bytes)
- `GAME-63-Settlemaker-Feasibility.zip.002` (15,552,137 bytes)

Keep exact filenames. Use **Add file → Upload files → Commit changes** on this `handoff/game-63-settlemaker-upload` branch, not `main`.

To reconstruct on Linux/macOS or in ChatGPT Work:

```bash
cat handoffs/GAME-63/GAME-63-Settlemaker-Feasibility.zip.001 handoffs/GAME-63/GAME-63-Settlemaker-Feasibility.zip.002 > /tmp/GAME-63-Settlemaker-Feasibility.zip
sha256sum /tmp/GAME-63-Settlemaker-Feasibility.zip
```

Expected SHA-256: `c5f7a3763c5b59545fdd0031f033290824469a120399c6abdd9044d53a50fd21`. Parts were verified against the original archive byte-for-byte before upload. Do not alter, omit or repackage any contents. The archive is for isolated review, visual comparisons, reproducibility, limitations and later approval of a provider-neutral interface; **do not** implement `GAME-19` or merge source automatically.

Linear: https://linear.app/marksprietsma/issue/GAME-63
