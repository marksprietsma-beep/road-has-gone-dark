# GAME-73: critical review and refined research strategy

Base verified remotely: GAME-71/72 `ec6f8b5887826268366a9063f2099b34ae44d297`.
Existing PRs #51–#54 remain protected. This assessment is the initial meaningful
publication/authentication gate; implementation follows only after remote verification.
Linear tooling is unavailable in this session; the supplied GAME-73 brief and
repository evidence are available, but the actual Linear ticket/roadmap cannot be read.

The brief correctly separates authoritative geography from illustration, local
artistic freedom and uncalibrated distances. Existing GAME-62 already projects all
real visible burgs, routes, clipped source feature polygons and shared coordinates.
It has a 20% longest-cell-extent fringe on **each side**, not a new ownership region.
The canonical fixtures contain 873 / 783 visible burgs and **zero same-cell pairs**.
Adjacent-cell neighbours are common; the source-connected Colira/Riveivalfei pair
(game-11-determinism burgs 569/774, cells 3311/3171, route 12) is a genuine candidate.
A shared route ID alone does not prove a direct connecting segment: inspect its
ordered route vertices before claiming the connection.

Questionable assumptions: town artwork units are not world units; village and city
provider units are not mutually calibrated. Population is source metadata, not an
authorised people-to-kilometre conversion. A capital need not outrank every port by
population. River geometry is a cell-chain approximation, not exact meanders. A
shoreline land cell can border lake or sea; water type needs feature evidence.
Rotation can align one waterfront direction while contradicting roads, so score
those relationships independently. Inferred decoration may vary even where exact
source roads/coasts agree. Do not assume theoretical generator controls are supported:
inspect the pinned Settlemaker entry points, planner distinctions and failure flags.

Refined approach: one small provider-neutral research module wraps existing source
context and exact cell geometry. Keep identity, provenance/confidence, unknowns and
relative aesthetic envelopes explicit. Scan both complete fixtures and publish
statistics with defined denominators; select an authentic adjacent road-connected
pair with shared viewing visibility. Reuse the three preserved GAME-70 public regions
and generate only the pair's independent regional proofs with unchanged GAME-62.
Measure authoritative overlap separately from inferred trees/fields/provider marks.

Use source-derived SVG diagnostics and the accepted regional renderer, rasterised
with real SVG tooling, plus preserved public town artwork. Produce phone-width
case sheets with source-backed arrows, ownership/fringe boundaries and explicitly
hypothetical footprint envelopes. No extra navigation system or Godot scene is needed
unless these simpler proofs fail to answer a question. A non-destructive display-only
rotation experiment may test feasibility; never replace approved artwork or claim
it fits multiple constraints without measurements.

Verification: immutable fixture/sidecar and original-art hashes, context repeatability
and rename independence, full-world/cell/burg identities, pair route ordering,
ownership versus visibility, inverse source projections, shared source geometry,
unknown fields, deterministic classification, scale bounds labelled aesthetic,
repeated region output, evidence manifests, inherited source/model/art regressions.
Before delivery visually inspect actual images and publish a mismatch table, pinned
engine capability evidence and the smallest next step. All work stays in research/game73;
no production changes, regeneration of approved towns, gameplay, saves, GAME-19,
physical travel calibration, new GPL dependencies or merges.
