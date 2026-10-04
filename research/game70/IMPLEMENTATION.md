# GAME-70 implementation, reproduction and limitations

## Architecture and reproducible assets

The new flow controller coordinates the existing atlas scene and its real
`settlement_selected` signal. The region adapter inherits the existing GAME-62
Godot drawing unchanged, disabling its stock-sample/developer shortcuts and using
the flow's camera. Region source-exact coast/roads/burgs, parent-cell boundaries,
public knowledge filtering and inferred landscape remain those of GAME-62 V1.
The new native town layer reads the **unchanged GAME-67 public JSON**, draws the
exact preserved GAME-69 public illustration, and selects the original canonical
roof polygon. Outdoor facilities have no invented roof. Same-family Game-icons
use the existing GAME-69 prepared assets, with screen-size marker decluttering.

Town PNGs are faithful aspect-preserving raster conversions of the exact GAME-69
public SVGs, at a maximum dimension of 4096 pixels. They keep the supplied native
viewBox/frame conversion from `research/game69/art/frames.json`; no source path,
building coordinate or facility ID is changed. [Raster manifest](art/manifest.json)
records input/output SHA-256, dimensions and librsvg version. Native Godot texture
resources are used, rather than invoking an external browser. Raster resolution
places a limit on extreme close-up sharpness; source SVGs remain available upstream.
The four original city roofs without individual paint IDs remain the previously
measured GAME-69 limitation, not new invented alignment claims.

The two original world vegetation presentation sidecars are included under
[world-art](world-art), with canonical fixture fingerprints and hashes. They are
copied from the pinned accepted generator's canonical replay, not redrawn; the
existing committed relief sidecars remain in use. These proof-only copies make
an ordinary checkout independent of ignored generator working files. `.gdignore`
prevents editor imports of raw sidecars and screenshot evidence; the existing atlas
sidecar loader reads the SVG bytes. Actual town texture assets import normally.
No generated `.godot` cache or `.import` sidecar is committed.

To rebuild proof assets, from repository root with Node 24/project dependencies,
Python/Pillow and `rsvg-convert` (executed version 2.60.0):

```sh
npm ci --ignore-scripts --prefix vendor/azgaar
node research/game70/scripts/prepare-regions.mjs
python3 research/game70/scripts/prepare-art.py
godot --headless --editor --path . --import
```

The region script replays both worlds into ignored `tools/regiongen/.tmp/`, checks
byte equality against the original immutable canonical fixtures, and invokes the
existing GAME-62 `generateCellRegion` and `publicRegion` for cells 917/4354/1689.
It verifies a second identical generation before committing each output. It never
runs Settlemaker. `--reuse-geography` can use already-verified local sidecars and
fixture vegetation copies; `RSVG_CONVERT` can select a custom renderer executable.
No Node/Python/Settlemaker runtime is needed to review the prepared F6 scene.

## Observed failures, timings and provisional scope

Early failures are retained: [test assumption](evidence/initial-test-failure.txt),
[stale texture import](evidence/import-cache-failure.txt), and
[camera-test assumption](evidence/camera-test-failure.txt). The first incorrectly
assumed burg 760 was absent from the other world; the test now checks world identity.
The texture import had cached a failed read while the port PNG was still being
written; completing conversion and clearing that generated import fixed it. The
camera test initially expected Fit to move away from the pre-drag centre even when
that centre was already correct; it now compares against the actual map bounds.
The final run uses normally imported textures and records fresh complete captures.

The original atlas bake/sidecar decode blocks briefly on first loading each world.
Software-renderer initial observations were about 10–11 seconds; world renderers are
cached so subsequent world switches avoid that bake. Region JSON loading was about
34–76 ms and town texture creation about 229–568 ms in the first run. Final measured
loads are in `godot-results.json`; cached timings and software rendering are not
hardware performance guarantees. Back reuses the already-loaded maps. This proof
has not been tested on a physical mobile device, an exported build or a low-memory
machine. The fixed desktop debug layout is the tested review target.

The three scale representations deliberately expose a seam: **Settlemaker town
coast, streets and extent are not fitted to GAME-62/Azgaar geography**. This warning
is visible in the town interface. The regional source is authoritative, while town
art remains source-backed research in provider-local units. No physical distance,
bridge, travel time, route safety, save contract or production integration is inferred.
Only the three requested parent cells are prepared. Runtime Godot does not generate
additional regions or settlements. GAME-19 remains deferred and no main scene changes.

Licence findings carry forward from [GAME-69 attribution](../game69/assets/ATTRIBUTION.md):
completed original SettleMaker maps use the documented default-symbol rendered-output
exception; engine GPL-3.0-only is separate and no engine code is vendored. Game-icons
by Delapouite/Lorc are attributed CC BY 3.0 derivatives; no family replacement.
Accepted Azgaar presentation retains its existing project provenance and obligations.
Public mode loads only known facility JSON and neutralized public artwork, but this
open research repository contains privileged parent research too; this scene is
not a server authentication boundary.

Authenticated Linear access was unavailable; GAME-70/62/67/69 were not independently
read or updated there. The uploaded GAME-70 brief and repository review documents
were used. Final publication is a new draft targeting GAME-69, with PRs #51/#52
unchanged and no merge.
