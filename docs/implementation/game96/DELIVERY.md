# GAME-96 review delivery

Review branch: `feature/game-96-procedural-sandbox-spine`, stacked on verified GAME95 `988d285bf2761f9c421dc79772e523e6c83e7ab0`. Base for the prepared draft is `feature/game-95-party-preview-old-road`. No parent merge, force-push or automatic PR publication.

Implementation checkpoints:

- `86d758e` — source-anchored generation, persistent records, existing resolver/writer and UI integration.
- `aa6fcaa` — real-world corpus, multi-opportunity restart and Windows/package diagnostics.
- `4e15a82` — repeat preparation also rejects source-coordinate drift.
- `b20cf27d72d3eeac805b3858455286faa4914a4d` — final gameplay/build source: Taiga remains forest; deterministic invalid-candidate retry/exhaustion fixtures.

## Windows x64 download

[Download game96-windows-x64](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38013974869/artifacts/11654514569) · [successful native Windows run](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38013974869) · [complete source/native evidence artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38013974869/artifacts/11654814465).

The playable artifact expires **2026-11-09 01:56:39 UTC** (30-day retention). Downloading GitHub artifacts may require a GitHub login. The artifact wrapper contains `game96-sandbox-windows-x64.zip` and its `.sha256` sidecar.

1. Extract the downloaded GitHub artifact wrapper.
2. Extract the enclosed **game96-sandbox-windows-x64.zip** completely.
3. Open its `game96-sandbox-windows-x64` folder and run **road-has-gone-dark.exe**. Keep the executable, PCK, `worldgen-helper` and `artwork` together. No installed Godot, Node or artwork is required.
4. Escape skips intro. New Game → generate/select world → origin/region/hometown → confirm → party previews/ready → Enter hometown → Explore local opportunities → inspect/set out → scout if rumoured → travel → engage. Move then click a dotted tile; attack/ability then a highlighted target; End turn. Victory/Withdraw → Return to regional play → Return home & rest → another opportunity. Main menu/Resume and application restart should preserve the site, encounter and consequences.

SHA-256 of the **enclosed playable ZIP** (120,020,045 bytes, not the outer GitHub wrapper):

```text
d3a48f0936d98d4fea73a00abd2c329f279202dbee98c2bc4588fd51f0ef08bb
```

[SHA sidecar](evidence/game96-sandbox-windows-x64.zip.sha256) · [package audit](evidence/package-audit.json).

## Native and package verification

Official Godot 4.6.3 Windows export, native Windows runner, empty PATH and cleared helper override. The exported old/legacy journey passes 237 checks; the procedural journey passes 294 checks, including two wins, withdrawal, multiple opportunities and menu resume. Production launch and separate-process preference checks pass. Native source tests also run the full rules/art/UI/map/regression suites, 180 generated encounters and multi-site campaign restart/rollback/reward checks.

Downloaded artifact audit: checksum/ZIP CRC, 7,055 entries, both executable and bundled Node are **AMD64 (0x8664)**, all 291 original LPC source hashes/credits/licences retained, generation/terrain notices/config included, diagnostics removed. Native corpus metrics equal the Linux corpus exactly; native generated review boards/base equal the actual Godot-rendered walkthrough. [Native proof](evidence/windows-proof.json) · [procedural native proof](evidence/windows-sandbox-proof.json) · [production launch log](evidence/windows-production-launch.log).

The native Python proof reader used Windows locale decoding for a delimiter in its annotation/derived JSON (`Â·`); the original artifact evidence is retained. Game generation/save/compiled strings use Godot UTF-8, and map/source/hash checks match across platforms. The source diagnostic reader now explicitly uses UTF-8. Subsequent handoff changes affect documentation and diagnostic scripts only; production gameplay/build code remains the verified `b20cf27` source.

Human Windows desktop/GPU playtest remains outstanding; native package logic/launch checks and actual Linux renders do not assert a completed human GPU review. Other material limits, including the extra upstream Azgaar geography error and V0 recovery/XP/withdrawal policy, are listed in README/VALIDATION.

Exact extraction, launch, mouse/keyboard, sandbox opportunity/reload and expected-result steps: [README.md](README.md). Source architecture and actual measured distributions: [GENERATION.md](GENERATION.md) and [VALIDATION.md](VALIDATION.md). Prepared review description: [PR-DRAFT.md](PR-DRAFT.md).
