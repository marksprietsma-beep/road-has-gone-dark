# Original-art alignment and public preparation

The source is the original archived GAME-63 SVG, not a new Settlemaker run.
Each original file matches its archived SHA-256; the four volumes, reconstructed
7z CRC and all 37 internal checksums were checked before using it.

| Town | Source-to-model transform | Tagged paint anchors measured | Maximum residual |
| --- | --- | ---: | ---: |
| Batan | model x=(SVG x−1083.59)/4; y=(SVG y−1095.60)/4 | 77 / 77 | 0.002439 source units |
| Albanes | Identity: original SVG local units = model local units | 461 / 463 | 0.006794 local units |
| Thilranlena | Identity: original SVG local units = model local units | 535 / 537 | 0.006905 local units |

Batan's original SVG supplies `data-origin-x`, `data-origin-y` and
`data-px-per-metre`; its metadata precision is 0.01 pixel. The city SVGs provide
local viewBoxes and source building IDs on paint nodes. Display rounding causes
small residuals. No transform was fitted by eye or inferred from a screenshot.
The root SVG viewBoxes also round the original crop boundaries; they are retained.
These are renderer-local measurements, not verified real-world distances.

For glyph-backed city roofs, compare original SVG translation against the ORIGINAL
Scene symbol centre. For path-backed roofs, compare the original path's vertex
mean against the source polygon's vertex mean. A glyph's anchor is not necessarily
the mean of an irregular polygon's vertices; substituting the latter would falsely
report about 0.5 units of error. The diagnostic explicitly records its reference.

All inn/chapel/manor/guildhall/warehouse source POI anchors measured below 0.005
local units from their corresponding original artwork anchors. Guildhall `b93`:
0.003972 units. Warehouse `b223`: 0.002501 units. Projection to screenshot pixels
is recorded by the browser tests for fit, district and close views.

There are four original city polygons with no individual SVG paint ID:
Albanes `b60`, `b299`; Thilranlena `b331`, `b414`. Their source polygons and the
complete original artwork remain intact. The absence of paint tags limits
individual-ID measurement; it is not proof those structures are absent. We do
not claim independent paint-ID verification of all 1,077 polygons or perfect
pixel equality between stylized artwork and GeoJSON footprints.

The original glyph silhouettes, roof overhangs and intentional shadows may extend
outside the canonical footprint. Shadow translation (0.40, 0.60 in the city art)
is presentation, not building relocation, and is excluded from anchor measurements.
Selected highlights use the exact original GAME-67 building polygon, with reduced
fill opacity so its artwork stays visible. The optional diagnostic shows original
anonymous footprint outlines; it does not relocate, replace or regenerate roofs.

## Knowledge separation

Complete `.original.svg` files are byte-identical source outputs and are used only
for the labelled complete-research comparison and explicit developer inspection.
They retain source semantic imagery and metadata. They are NOT public gameplay
payloads. The comparison A selection explicitly enables developer context; opting
out of developer inspection also exits A.

The `.public.svg` copies remove all `data-*` metadata. Source stock definitions,
paths, transforms, decorations, water, crop patterns, roof variation and framing
are preserved. To avoid revealing the hypothetical unknown shop's function:

- Albanes `b12`: two active shop-house references (paint and shadow) become existing
  ORIGINAL generic tiled-house glyphs. The original translate/rotate/scale are kept.
- Thilranlena `b267`: the two original round market-roof paths retain their exact
  path geometry. Their semantic class is removed and the original neutral timber/
  shadow palette replaces its market styling.
- Batan has no unknown facilities; only invisible metadata is removed.

No building polygon, path coordinate or transform changes in public preparation.
Only these four paint nodes change visual semantics. Exact public derivatives
are checksum-recorded. This is a documented privacy/fidelity tradeoff, not a claim
that complete original imagery can always be blindly shipped to players.

The viewer fetches only `frames.json` (frame transforms, aggregate residuals and
counts) and the appropriate public/developer assets. It does not load the privileged
`manifest.json`, source fixtures or hidden binding metadata in public mode. It
reuses GAME-67's public model and sanitizing export. This openly available research
bundle still contains originals and diagnostics: future production must withhold
privileged files on the server. No authentication boundary is implemented.
