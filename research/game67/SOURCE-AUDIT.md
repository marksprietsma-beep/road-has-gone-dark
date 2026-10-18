# Baseline and source audit

Accepted baseline: GAME-62, PR #50, merge
`238045b395ad9e693c71ac6b018442257fe0d6f3`. GAME-7 also provides independent
GameWorld/playthrough saves. Those production implementations are unchanged.
GAME-19 integration is outside this research task.

GAME-63 holding branch: `handoff/game-63-settlemaker-upload` at
`a07775937272148858370bb2cb263182484c6a2f`.
Read `handoffs/GAME-63/REVIEW-2026-10-04.md` there. All four archive volumes in
this checkout were compared byte-for-byte with the corresponding Git objects.

| Volume | Bytes | SHA-256 |
| --- | ---: | --- |
| .001 | 10485760 | 38fe70bf0657583027b200546e562d3c705cac2edb3c0a48a47a0200eb53a79e |
| .002 | 10485760 | aeb028d1b4419059cdc9c0e598c38ea772badb9d9149ca69611bac8f2b3b50ad |
| .003 | 10485760 | 03cca98de4402f7d2ae2a50b4852d3e2d56fcc3e84ff7d9046ad21a23002b74f |
| .004 | 4155402 | db5c2ebdd1be3da2750eddc1955c5138e92f6bd1f314d3f59360a9d2aaf001c6 |

Concatenated 7z: `ba6a216632020d3b3134ca818176f484b1f2d4ca4ca5cde8441d9fda8fbf16cf`.
CRC test passed with py7zr 1.1.3 (`testzip()` returned None). There are 41 archive
members; all 37 entries in `evidence/SHA256SUMS.txt` passed. This is NOT the
lost GAME-67 ZIP and its checksum is not that ZIP's checksum.

The bundled `settlemaker-pinned-source.tar.gz` passes its recorded checksum but
`gzip -t` reports unexpected end of file. Do not use it to reproduce the engine.
Instead, upstream `barrulus/settlemaker` was cloned and checked out at exactly
`d5cf3590cf59e1d382110d25a6910f12507299e2` to inspect licensing. Town outputs
were NOT regenerated. Original GAME-63 test logs are historical evidence,
not rerun results for this task.

## Genuine source results

| Town | Buildings | Raw POIs | Research establishments | Building-bound | Outdoor |
| --- | ---: | ---: | ---: | ---: | ---: |
| Batan, world atlas-showcase-06, burg 760 | 77 | 1 | 4 | 3 | 1 |
| Albanes, world game-11-determinism, burg 7 | 463 | 32 | 32 | 27 | 5 |
| Thilranlena, world atlas-showcase-06, burg 68 | 537 | 29 | 29 | 21 | 8 |

Batan's chapel, inn and manor are existing explicit landmark building IDs/glyphs,
not newly fabricated POIs. Its well remains outdoors; no guildhall exists.
Albanes has 1 guildhall, 3 inns, 3 taverns, 5 shops, 2 smithies and 12 guardhouses.
Thilranlena has 1 warehouse, 3 inns, 4 taverns, 6 shops, 2 smithies, 2 piers and
3 guardhouses. Every original building reference exists and every bound source
point is inside its actual roof polygon. No orphan references or fallbacks.

`fixtures/provenance.json` records the original files' SHA-256s and each compact
fixture checksum. Compact fixtures preserve ALL original GeoJSON coordinates and
properties, plus original Scene water/field rings, and immutable request identity.
Unneeded full world inputs, cyclic models, renderer engine and archive volumes
are not copied into this research package.

City Scene and GeoJSON disagree on physical scale estimates. This prototype
retains local provider units and does not assert metre accuracy or align them
to GAME-62. Coastal water comes from the ORIGINAL Scene because GeoJSON omits it.
It remains synthetic provider geography. The source town artwork is brighter and
more regular than the intended dark fantasy style; this research render uses
restrained project icons and a separate geometry-only parchment treatment.
