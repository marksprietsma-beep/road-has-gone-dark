A legitimate Azgaar Voronoi vertex outside the displayed canvas prevented entering the hometown: the preserved `game96-sandbox-review-v2` fails at [722.0000000000003,800.4226306386807] on a 1280×800 map. Preserve the original graph and source fingerprints, validate finite geometry consistently in writer/reader, and reconstruct missing geography caches through fingerprint-checked staging so existing campaigns can resume.

Closes #76 after independent review and merge. No combat, source-world generation, character identity or gameplay changes. Sidecar v1 and successful cache bytes remain compatible.

Validation: real failing seed, both exact canonical fixtures and 30 additional fixed independent seeds; malformed-geometry and cache interruption tests; original-production failed/valid save handoff; generated sandbox and Old Road regressions; native Windows self-contained build. Full CI, render evidence, recovery details and Windows checksum will be linked in docs/implementation/game99/DELIVERY.md when complete.

Draft only; do not merge without human review. Exact player-world vertex 11702 remains unverified because its source data were not provided.
