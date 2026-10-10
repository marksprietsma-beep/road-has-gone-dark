# GAME-75 engineering assessment

Verified production main: 3350aed73aa22f2f144ae4613f054ff81ab0ca34, including
accepted GAME-76. No research-stack integration is needed.

Audited both presets and genuine GAME-76 A/B outputs. Trust explicit burg
walls, port, group and population; canonical land heights, neighbour topology,
feature types, biome IDs/areas, political ownership and source positions.
Route points include [x,y,cell]; require matching cell AND burg coordinates
within serialization rounding (0.02 map units), never infer access from a road
merely crossing its cell. Road/trail groups only, no sea-route/road conflation.

Reject prosperity, danger, protection, economic/diplomatic records and social
behaviour even though some raw upstream records contain speculative simulation
fields. Omit river-adjacency and dominant culture/religion rather than infer
burg-scale conditions from coarse cells. Coastal means adjacent ocean-feature
water cell; lakeside remains separate, port does not imply ocean coastline.

Use a small immutable OriginContext service with summary/tags/supporting facts
and rule identifiers. Cache per canonical source in onboarding; index source
records once, avoid O(cells) GAME-7 getter scans inside geographic aggregation.
Never consult markers/POIs. Visible, nonremoved positive-population settlements
only; stable source IDs stay independent of local prose and labels.

Qualitative rules: dominant landscape by land-cell source-area totals; state/
province settlement concentration compared with within-world land-area densities
(lower/upper tertiles, ties neutral). Nearby means within twice the median of
public settlements' nearest same-land-feature neighbour distances; neighbour
IDs/distances are retained for audit, never kilometres/travel times. Larger
neighbour means strictly greater source population, not wealth or protection.
World descriptions remain modest: strongest land biomes, landmass composition,
and measured coastal/port or political distribution where it adds value.

Keep accepted black/gold layout and font sizes. Replace generic fact panels
with at most four short lines; fit by choosing information, not shrinking text.
Region summarises selected province or whole state. Home gets landscape/water,
recorded walls/port, verified routes and nearest-neighbour context. Confirmation
retains concise hometown context. Remove “suggested first” ranking language.

Tests: deterministic outputs and claim backing for all offered hometowns,
both presets and at least three genuinely generated worlds; contrasting real
regions and coastal/inland, walled/unwalled, sparse/clustered towns; hidden
settlement/POI exclusion, unsupported fields unknown, rename/identity invariants.
Capture real Godot screens, inspect them, run GAME-7/74/76 and renderer regressions.
No generator, deletion, canonical fixture, save schema, gameplay, Party Creation,
Continue, GAME-8 expansion or authored lore changes. Prepare Linear update if
no authenticated Linear tools are available.

## Implementation audit refinements

The pinned burg generator explicitly promotes inland navigable-river ports.
A port feature ID can also identify a downstream ocean from a lake outlet.
Therefore port is never a coastline test. River-port wording additionally
requires an inland recorded port, a positive cell river ID and matching river
cells. Ordinary river proximity remains omitted.

Larger nearby settlements must exceed both the selected population and GAME-7's
existing small-hometown ceiling of 5; tiny differences among small homes do not
produce a “larger settlement” claim. Neighbour distances remain uncalibrated.
