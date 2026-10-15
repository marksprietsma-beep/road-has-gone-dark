# CI policy — Windows is the only supported runtime target

Owner decision (2026-10-15): The Road Has Gone Dark currently targets **Windows x64 only**. GitHub Actions should not launch Linux or macOS test jobs, generate Linux distributions, or make Linux compatibility a condition of PR merging or release. Windows source/unit, native Godot, save/restart, deterministic replay, screenshot/visual where supported, packaging and offline helper checks remain required.

- Shared CI matrices contain only `windows-latest` while retaining their existing Windows tests and review artifacts.
- Legacy Godot workflows previously Linux-only were ported to `windows-latest` using `tests/world_library/prepare-ci.py`, PowerShell commands, and Windows scripts. Their Windows outputs must pass before considering this migration integrated.
- The old GAME-76 cross-platform draft release-publishing job is retired. Its Windows QA/helper artifacts remain available in the `library` job.
- Do **not** reinstate Ubuntu/Linux CI in future Codex waves without explicit new owner approval. Build and test new character versions with Windows-only native validation.
- Previous Linux run history is preserved as historical evidence; prior Linux artifact links remain valid where still hosted, but no *new* Linux validation is promised.
- Do not weaken Windows assertions or frozen content/source pins to compensate for removing the extra OS.
- If branch protections require old Linux check contexts, update GitHub repository rules through authorised administration; **do not bypass** merge protection. Replace required contexts with corresponding Windows checks.

On any new implementation wave, inspect the existing workflow before copying a two-platform matrix from historical docs.