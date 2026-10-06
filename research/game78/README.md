# GAME-78 — combined deterministic content system

Research implementation stacked on GAME-77. **No production integration, gameplay or merges.**

The combined provider keeps TRHGD structured facts and SHA-256 field seeds, uses clean Lexicon engine modules for an alternative weighted fact provider and culture-bound phonotactic names, and uses Rant for deterministic, fact-bound prose. Curated CC0 material/room vocabulary is separately attributed. FCG/Venture/NPC architecture informs staged relationships, ownership/history chains and compatibility rules; their fantasy prose and mechanical tables are not imported.

Start with [the review](evidence/REVIEW.md), [interactive local HTML](evidence/review.html), [provider findings](docs/PROVIDER-FINDINGS.md), and [sequential corpus](evidence/REVIEW-CORPUS.md). The HTML is a standalone file that can be downloaded and opened offline. Machine records include secrets and are developer evidence; the public diagnostic payload does not.

## Implemented breadth

36 site purposes, 32 condition facets, 58 history events, 58 local memories, 58 traditions, 30 occupations, 72 item types across weapons/tools/clothing/containers/documents/jewellery/religious/travel/household categories, and 12–18 choices in the main background fields. Eight domains: site, origin, character, NPC, mundane item, special heirloom, contract proposal, group. Site histories have six dated stages; items have connected two/four-owner chains. These are authored research content, not adopted vendor prose.

```sh
# From repository root, using the existing accepted Node 24 helper/runtime:
node --import ./research/game77/tests/offline-guard.mjs --test research/game78/tests/framework.test.mjs
node research/game78/tools/preview.mjs
node research/game78/tools/batch.mjs
node research/game78/tools/fresh-worlds.mjs
node research/game78/tools/benchmark.mjs
node research/game78/tools/review.mjs
python3 research/game78/tools/run-qa.py --helper-contract
# With a display / xvfb-run, add --visual for real Godot input/render checks.
```

`fresh-worlds.mjs` requires the existing GAME-76 helper (`GAME76_HELPER_ROOT`, default `worldgen-helper`); it generates and independently replays five actual worlds. The other framework commands require no install step, network, external browser, Go, .NET or separate Node runtime. Native vendor rebuilds are optional development tooling: see [native setup](tools/setup-native.py), requiring Node24, Git, Python, Go1.24.5 and .NET8 for their respective harnesses. `--help` documents exact paths; use a fresh scratch source directory, since native Godot imports and Linux resource workarounds produce build artifacts. Do not install those tools for players.

## Boundaries and recommendation

Keep this research-only. Generate a small public-origin sidecar at world-library creation; generate larger site/NPC/item records deterministically as needed, then persist the exact versioned facts and rendered-artifact identity before campaigns reference them. Characters belong to an explicit playthrough namespace. No automatic upgrades of existing lore. See [architecture](docs/ARCHITECTURE.md) and [licensing](docs/LICENSING.md).

This is materially broader than GAME-77, with genuine native comparisons, but **unique combinations are not a claim of production narrative quality**. Repeated craft/account themes, approximate personal names, two fixed site-rumour forms, modest special-item histories, and small contract/group vocabularies remain editorial limits. No magical properties, stat blocks, active quests or faction simulation are implemented.
