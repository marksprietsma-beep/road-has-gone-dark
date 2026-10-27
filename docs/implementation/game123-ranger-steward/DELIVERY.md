# GAME-161 — Ranger and Beast Steward Windows acceptance

## Delivered mechanics

Released v31 reproduction [40332195985](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40332195985) passed 76 checks and established three defects. New immutable **trhgd-character-v32** corrects them:

- Aimed Shot now requires the actual active ranged weapon. Its existing +2 accuracy, main-and-movement cost and zero resolve cost remain.
- Paid Archery damage applies only to an actual ranged attack. Melee strikes and fallback melee departure reactions receive no Archery damage; normal training stacking, cost and expiry remain.
- A defeated permanent companion remains at 0 HP during advancement. Living HP deficits and spent effort remain persistent; eligible home recovery uses the existing authority.

The shared requirement/modifier/owned-actor paths perform these repairs. All other production edits enable v32 in existing version gates. **No content-record IDs or careers were added.** The 50-career roster is unchanged: 32 base classes and 18 prestige paths. Original packs v1–v31 remain byte-for-byte intact with exact pins; older campaigns are not migrated. The original attack, RNG and campaign writer are frozen.

Pack canonical hash: `f0a55222931fb5e948c480a5b94dbe0f5a46dd64696c83f28e3418bba266b8ed`. Matching native source: `2a3262fb73097fa8ce43939b18c7836a50f5cc8a`. Later delivery/readiness/evidence commits change only documentation; the scoped runtime/test/export diff is empty. Native source and final merge are deliberately distinct identities.

## Windows download and launch

[Download the complete Windows x64 artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40431423311/artifacts/12703992392). GitHub retains this Actions artifact for 90 days; a repository login may be required.

1. Download and extract the outer GitHub artifact ZIP.
2. Extract the inner **`ranger-steward-windows-x64.zip`** and retain the entire extracted directory.
3. Run **`road-has-gone-dark.exe`**. No installed Godot, Node or artwork is needed. Escape skips the intro. Fresh New Game uses v32; Resume keeps the campaign's original pin.

SHA-256 of the **inner playable ZIP**:

```text
6b2178eeee454f9624d084fdb271e98c58eba7b6e97f879f7112bd6f1e300df6
```

[Native Windows workflow](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40431423311) · [Raw Windows evidence](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40431423311/artifacts/12704017396) · [Exact player testing steps](TESTING.md) · [Original screenshots](screenshots/README.md).

## Verification and evidence boundaries

Focused Windows [40427262413](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40427262413) passed mechanics 1789, cold 237 and actual production controls 53 at `1aa11e7`. Source-earned [40428241753](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/40428241753) passed ordinary 664 / cold 8, connected 132 / cold 113 and 46 capture checks / 25 original images. These are separately labelled source proofs; the table below is from the single complete exported Windows release at the matching native source, not extrapolated from those earlier runs.

The native release passed every phase below, independent process restart, actual production startup with empty PATH/no source-helper override, all 32 base tracks through level 20, current v32 controls and historical v31/v30/v29/v18/v16 plus frozen GAME-32. Original phase receipts, timings, source guards and image hashes are retained in [native-proof.json](evidence/native-proof.json).

| Native phase | Checks | Failures |
|---|---:|---:|
| mechanics/proof.json | 1789 | 0 |
| mechanics/restart-proof.json | 237 | 0 |
| journey/proof.json | 664 | 0 |
| journey/restart-proof.json | 8 | 0 |
| connected/proof.json | 132 | 0 |
| connected/restart-proof.json | 113 | 0 |
| audit/proof.json | 2598 | 0 |
| audit/restart-proof.json | 65 | 0 |
| current-upper/proof.json | 1634 | 0 |
| current-upper/restart-proof.json | 97 | 0 |
| historical31/proof.json | 1343 | 0 |
| historical31/restart-proof.json | 145 | 0 |
| historical30/proof.json | 1143 | 0 |
| historical30/restart-proof.json | 49 | 0 |
| historical30-extended/proof.json | 642 | 0 |
| historical30-extended/restart-proof.json | 37 | 0 |
| historical29/proof.json | 1290 | 0 |
| historical29/restart-proof.json | 125 | 0 |
| historical18/proof.json | 599 | 0 |
| historical18/restart-proof.json | 31 | 0 |
| legacy/proof.json | 818 | 0 |
| legacy/restart-proof.json | 4 | 0 |
| compatibility/proof.json | 1941 | 0 |
| compatibility/restart-proof.json | 486 | 0 |
| pinned31-probe | 76 | 0 |
| input | 53 | 0 |
| historical30-input | 141 | 0 |
| historical31-input | 72 | 0 |
| frozen | 22181 | 0 |

The ordinary campaign earns **490 XP / total level 8** for Archery Ranger/Wolf, Blade Ranger/Leopard and Ranger 5/Beast Steward 3/Stag. It preserves the funded 250 XP Ranger 5 state where entry and decline are both legal and neither occurs automatically. A real owned Stag attack damages the enemy; paid Archery, Blade and Pack Drive commands, cold battle continuation, resolution and eligible home recovery are verified. No XP is injected. Ranger 20, both Steward training tracks 1–5 and Ranger 15/Steward 5 histories are **development fixtures**, not earned level 20 or earned prestige level 5.

The independent [archive audit](evidence/archive-audit.json) rechecked the inner ZIP SHA/CRC, unique safe entries, AMD64 production EXE and bundled Node, executable hash, exact content/manifest/source identity, required credit/licence files and absence of the QA executable. Windows runtime proof verifies actual launch, bundled helper and cold operation without installed tools. No Linux Godot/game validation was performed.

## Readiness and remaining limits

Evidence-gated readiness is **43 COMPLETE / 7 PARTIAL / 0 BLOCKED** across the same 50 careers. Only Ranger and Beast Steward are promoted; the previous 41 retain their original source-labelled acceptance. Ranger supports 20 class levels; Beast Steward supports 5 prestige levels within the total character level cap of 20. Technical acceptance is separate from human balance and usability.

Quarry still uses the existing bounded humanoid-raider/hostile-ranged profiles. Companion/summon art is explicitly labelled humanoid LPC fallback. Existing global-round withdrawal after owner defeat, ally-wide Steward support, reaction/expiry policy and shared long-label/small-window UI limitations remain. No new AI, creature roster, browser #158, pantheon or world simulation is claimed.

GAME-123/GitHub #101 remains OPEN. The seven remaining careers and next bounded recommendation are in [NEXT-WAVE.md](NEXT-WAVE.md). There is no callable Linear connector; GitHub carries the verified status for Linear reconciliation. Publication, actual merge SHA and post-main results must be recorded against the real PR, not inferred from this native release.
