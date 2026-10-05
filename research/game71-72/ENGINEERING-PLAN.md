# GAME-71/72 critical review and refined plan

Base: verified remote GAME-70 `10b8dcdfb480366e92018098923500efeb88db35`.
Fetched main and GAME-67/69/70 refs; the published GAME-70 head has no new commits.
This initial meaningful commit is the authenticated push gate before implementation.
Linear tooling/authentication is unavailable; the supplied authoritative brief,
actual renderer code and GAME-70 evidence were read. No Linear acceptance is implied.

## Confirmed defects versus hypotheses

World names are 7–8 map-unit glyphs scaled by the camera; four shifted text copies
form an expanding halo. Collision rectangles estimate width from character counts.
State names are claimed before settlements, with no selected-burg priority, and
labels do not consistently match the icons' eligibility. The landmark renderer
independently mirrors the same inaccurate label claims. These are confirmed code
problems. Fixed 1440×960 content plus a stretched SubViewport is a plausible extra
high-resolution blur source; measure viewport/output pixel ratios before altering it.

Town marker visibility depends on selected-first sorting and combined marker/label
bounds. A colliding label removes its icon and hit target: confirmed. Coordinates
and facility records are intact. Clustering is optional, not inherently a remedy;
it can obstruct individual hit targets and adds navigation/accessibility complexity.

## Refined strategy

1. Capture the unchanged Godot 4.6.3 baseline at fit/medium/close, both worlds,
   Albanes bookmark and enlarged/high-resolution windows. Capture same-camera town
   selections. Record native viewport sizes/transforms and reproduce marker churn.
2. Use actual Godot font metrics and screen-aware sizes/bounds for world labels.
   Prioritize selected burg, capitals and population deterministically, progressively
   expose smaller names, try a few nearby placements, and use a restrained outline.
   Keep source anchors and icon hit tests. Avoid a cyclic label/landmark dependency:
   use one source of label layout and reserve real visible icon bounds.
3. Make the map render at the display's appropriate pixel resolution if measurements
   confirm undersampling. Keep logical camera/navigation context, correctly map mouse
   events, and test fractional display scales as well as doubled output dimensions.
4. Use selection-independent town marker priority and marker-only spacing. Lay labels
   out afterward with exact font bounds, selected label first. Keep physical anchors,
   exact polygon highlights, public filtering and the full known-facility index.
   Preserve discoverability through source-roof clicks/index; use stable clustering
   only if actual visual density warrants it.
5. Capture and inspect matching before/after frames. Assert marker IDs/positions are
   invariant across selection, label/icon overlap control, complete known references,
   exact source hit testing, window/zoom behavior and no hidden leaks. Run existing
   GAME-62/67/69/70 and save/world tests and the complete native navigation proof.

Expected improvements: crisp text of consistent readable display size, less text/
icon competition, selected capitals identifiable, and selection changes confined
to highlights/labels rather than unrelated icons. Risks: camera transform and DPI
input conversion, draw-order dependencies, dense selected-label placement, and
per-frame layout cost. Cache unchanged layout inputs rather than build a new UI
framework; use measured evidence, not a font-size-only patch.

Scope: new QA/research files plus small presentation/viewport changes. No GAME-73,
geography fitting, source-data or facility identity edits, regional algorithms,
settlement regeneration, gameplay, saves or main-scene changes. New draft PR targets
GAME-70; PRs #51/#52/#53 and their branches remain untouched. Windows hardware is
not available here; emulate documented physical resolution/scaling in Godot and
explicitly distinguish that from a native Windows validation.
