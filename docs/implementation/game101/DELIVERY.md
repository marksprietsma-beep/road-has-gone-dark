# GAME-101 delivery

Draft PR: https://github.com/marksprietsma-beep/road-has-gone-dark/pull/79

Production/test source: `a5feacd5413cff1d8a97a30f2c002a909c8a563c` (implementation `30080bc058bab31de66a1aece1fe4806a1bcdf84`, followed by the production-shortlist review fixture correction). Later delivery commits contain documentation/evidence only. All production, test, packaging and workflow tree IDs equal the shipped source; see [source-tree verification](evidence/source-tree-verification.json). Main remains `69fd8c02b2ca235826535bd1f3a7f353591b1a8a`; nothing is merged.

## Windows package

Artifact: https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38133791452/artifacts/11700448344

Native build workflow: https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38133791452

Inner playable archive: `game101-opportunities-v2-windows-x64.zip`

SHA-256:

```
b862796526948870fe96ec84f21ae8866671b8c87ba031574eafc314ffd61823
```

The package contains the executable, embedded game resources, complete compatible worldgen-helper/Node runtime, original LPC source layers and licence notices, retained Game-icons source/artist notices, and both V1/V2 generation manifests. No separate Godot, Node or artwork installation is needed. Existing artwork attribution is in `artwork/ART-CREDITS.txt`, `artwork/sources.json`, the original `artwork/licenses/` files and `REGIONAL-ART-NOTICE.txt`; the approved Game-icons artist/source mapping remains in `worldgen-helper/assets/map_icons/trials/game-icons/landmark_sources.json` and its adjacent README.

GitHub's artifact download is an outer ZIP containing the inner playable ZIP and checksum file. Download and **extract both ZIPs**, retaining the complete `game101-opportunities-v2-windows-x64` directory. Run `road-has-gone-dark.exe` inside it; keep `worldgen-helper` and `artwork` beside the executable. Escape skips the intro. The artifact requires GitHub access and has 90-day retention.

## Exact playtest

1. For V2, choose **New Game → Generate world** (or select an existing world), then select state/region, hometown and your real three-person party. Ready the party and **Enter hometown**.
2. Choose **Explore local opportunities**. Pick a known report or an **Unlocated local report**, then **Set out**. Scout an unlocated report before **Travel**. Its position/type stays hidden until discovered.
3. At a recovery site, compare checked recovery against quick recovery: different turn/net-provision costs and information. At an investigation site, compare careful evidence against quick assessment; careful comparison charts another still-unlocated report if one exists. Read the displayed costs and saved result. These outcomes earn **zero battle XP**.
4. A named companion choice appears only when that actual saved profession is relevant. Its displayed lower provision/time cost is real. Try another site if this party has no relevant occupation; there is no fabricated universal hook.
5. At a contested site, offer two provisions for peaceful access, observe before committing, withdraw, or **Engage in tactical combat**. Payment leaves occupants alive and gives zero battle XP. Observation consumes resources and preserves the remaining choice; a relevant companion can reduce that cost. Combat uses the existing move/attack/class-ability/end-turn/withdraw controls and only its actual victory earns ten XP each.
6. **Return home & rest**. Select the resolved report to read its result and inspect party XP/history. Use **Main menu → Resume Expedition**, then close/relaunch and resume again. Outcomes, information, contributors, world deltas and costs stay recorded; no reroll or duplicate reward occurs.
7. For V1 compatibility, use **Continue / Resume Expedition** with your existing campaign. Do not delete or recreate it. A saved `sandbox-spine-v1` campaign retains its original four opportunities, party, victories and XP; continue its remaining fight and return home. V2 does not silently convert old results.

Tab/Enter and mouse remain usable; longer choice/history panels scroll, especially at 640×360. See [SCREENSHOTS.md](SCREENSHOTS.md) for six hometowns, different activity families, two contrasting journeys, relevant companions, actual combat, noncombat resolution, returned outcomes, fresh-process restore and a preserved V1 campaign.

## Verification

Ten independent generated/replayed worlds, forty hometowns, 160 opportunities, seven weighted templates, eighteen four-template sets and all existing hostile board sizes/compositions pass. [VALIDATION.md](VALIDATION.md) records distributions, actual assertion counts, atomic journal/retry tests, separate-process activity/combat/reward restores and bounded non-goals. Raw evidence is in [evidence](evidence).

The source suite and exported native game pass on Linux and Windows. Each native export passes 623 journey checks plus 30 fresh-process checks. The downloaded Windows ZIP was independently hashed and inspected: 7,058 entries, all required runtime/artwork/manifests present, and the diagnostic executable removed. Exported QA executes all six real production journeys, the genuine V1 campaign and fresh-process reload with **empty PATH and no helper override**, then the production executable itself launches. Windows checks are native CI tests; the graphical PNG evidence is from actual Linux Godot/Xvfb renders. Native structured proofs, timings, logs and the archive checksum are retained in the workflow artifacts.

Relevant regression workflows: [GAME-99 geometry/recovery](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38133793931), [party/expedition](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38133793977), [GAME-83 UI/rules](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38133794097). Complete GAME-32 kernel/migration and First Adventure combat/save regressions also pass locally; source CI verifies the unchanged rules and existing native flows.

## Limits and stopping point

This is four local opportunities per hometown from seven authored templates, with coverage constraints; it is not an endless dynamic event simulation. Return retains V0 rest/preparation; provisions are journey-local and time has no new survival penalty. No inventory, money, faction economy, skill dice engine, injury system, personal quest, dungeon engine or new combat rules were added. Peaceful access and limited assessment are explicit authored outcomes, not fabricated checks or battle victories. Original character identities, canonical worlds and gameplay save ownership are preserved.

The exact earlier private world at vertex 11702 has not been independently identified or reproduced. The public original failing source and a genuine existing V1 campaign were verified without claiming that private-world reproduction.

PR #79 remains a draft for human review. No merge is authorised or performed.
