# GAME-76 — World Library V1

Base: `4079c442bb26069fde8d9f40e4d686e1eff1d518` (accepted GAME-74).
The WORLD step now lists protected presets and persistent generated worlds,
with Generate New World and confirmed, dependency-checked Delete World.
New generated worlds continue through the existing region/hometown/origin flow;
GAME-7 still owns eligibility, immutable identities and independent saves.
No character creation, GAME-75 wording, Continue or gameplay was implemented.

## Generation and distribution

The helper ships its own Node **24.19.0**, the pinned Azgaar **1.153.1** source
(`cc5dbac5db12ba4a7c47e647f6bef8bd7bf930c6`) and 108 locked runtime packages.
Players install no Node, npm or browser. Godot invokes an absolute bundled
executable with argv, never a shell or PATH fallback. The helper disables fetch
and HTTP requests, validates ASCII seeds/output paths and limits generation to
120 seconds. The existing canonical serializer and generator are reused; the
only existing generation-tool change disables Vite HMR/watch transport.
No generator algorithm, source fixture or research PR was modified.

Build-time Node/npm are separate from player requirements. To reproduce:

```sh
npm ci --ignore-scripts --prefix vendor/azgaar
node tools/worldgen/package-helper.mjs --output /new/path/worldgen-helper --runtime-license /path/to/full/Node-v24.19.0-LICENSE
```

Packaging copies licences, source, lock/integrity records, platform-native
optional dependencies and runtime binary SHA into `runtime.json`. Full Node
third-party notices are in NODE-LICENSE; pinned Azgaar retains its MIT licence.
The Linux bundle is about **304 MB uncompressed**. That footprint is the V1
tradeoff for reusing the accepted generator rather than maintaining a port or
new dynamic-module executable bundler. Windows and Linux CI build and test
separate native packages. macOS packaging is possible but untested; no macOS
package is claimed.

Extract the matching review package so **worldgen-helper/** is beside the
exported game executable, or beside project.godot for editor runs. Preserve Linux
execute permissions (tar.gz does so). The folder is deliberately excluded from
Git/imports and has .gdignore. No export preset exists in main: future game
packaging must include this sibling helper and the canonical preset JSON,
previews, .cells and .sha256 files needed by the existing onboarding. This task
provides helper packages, not a complete game installer.

## Storage, identity and recovery

- Presets stay in res://; Delete World is disabled and the service rejects them.
- Generated worlds live in **user://worlds/<canonical SHA>/**: world.json,
  metadata.json, preview.png, preview.cells and preview.meta.json.
- Source seed/provider/version/SHA form GAME-7's immutable world identity.
  Local label/date/cache never change it. Identical canonical output deduplicates.
- Discovery validates independent self-describing directories, not a central
  registry. Invalid entries and hidden staging/trash are never selectable.
- A worker generates into an owned .pending-UUID directory, validates source,
  bakes an atlas/cache, writes metadata and commits by directory rename.
  Dead-owner incomplete stages are discarded; complete stages are promoted.
- Preview hashes and source fingerprint detect invalidation. Cache can be
  rebuilt from canonical JSON without regenerating the world. A rebuild failure
  reports an error and leaves the source intact rather than displaying old art.
- The existing renderer bakes terrain/political/border textures and source-cell
  IDs; onboarding adds its existing highlight. There is no hidden POI layer.
- A single-writer lock covers commit, deletion and generated-origin save/reload.
  Stale owners are probed with the bundled runtime; uncertain ownership blocks
  writes rather than erasing a possibly live operation. No runtime means stale
  locks cannot be automatically reclaimed. PID reuse may conservatively require
  manual diagnosis. Recovery is for application interruption; fsync/power-loss
  guarantees or hostile filesystem interference are not claimed.
- Dependency checks read every GAME-7 JSON save header, including .bak/.tmp.
  Matching world ID OR SHA blocks deletion. Unreadable/unsupported/ambiguous
  references block all deletion. Save files are never removed or modified by
  world deletion. Confirmation rechecks dependencies under the library lock.
- Unreferenced worlds are atomically renamed to .trash before flat cleanup;
  restart finishes cleanup. Referenced intact trash is restored; uncertain
  partial trash is retained. Unknown nested directories/symlinks are not purged.

UI work runs off the main thread with truthful generation/map phases and
conflicting controls disabled. Cancellation is deliberately deferred; closing
waits for the bounded generation and preview worker. The library shows concise
labels, preset/generated status and creation date, retaining seed/SHA internally.

## Executed evidence

Linux Godot **4.6.3**, actual 1280×720 OpenGL/Mesa render/input:

| Check | Result |
|---|---|
| Packaged helper with empty PATH | Six genuine generations passed |
| Same seed twice / different seeds | Byte-identical per seed / distinct worlds |
| Accepted game-11 seed | Exact canonical SHA 2eb428e783101dc1c99213c31816dbd50f3a68370094917949a88bfbb5811fa5 |
| Library/restart/cache/failure/deletion/save checks | 56 checks, zero failures |
| GAME-7 persistence smoke | Passed |
| GAME-74 source/save | 3,973 checks, zero failures |
| GAME-74 post-write reload failure | 26 checks, zero failures |
| GAME-74 real input/render | 17 checks, zero failures |
| GAME-76 real generation/input/render | 20 checks, zero failures |
| Both canonical fixture validators | Passed; original bytes unchanged |

[Helper evidence](helper-proof.json), [library/save/recovery proof](library-proof.json),
[actual UI run proof](ui-proof.json), and [exact logs](logs/).
The virtual Linux driver's unsupported VSync warning is recorded; there are no
Godot script/runtime errors. Native Windows helper/filesystem CI results will
be recorded separately; Linux screenshots are not claimed as Windows captures.

Run a built helper's full suite with:

```sh
GAME76_HELPER_ROOT=/absolute/worldgen-helper python tests/world_library/run-tests.py --visual
```

A display is required for --visual. CI uses Xvfb on Linux; Windows runs genuine
native helper generation and headless Godot lifecycle/persistence tests.

## Actual screenshots

These are sequential captures from Godot, including two genuinely newly
seeded worlds generated by the player helper. They are not fixture copies or
mock-ups. Source IDs/seeds for both are retained in ui-proof.json. The capture
checks persistence through a fresh onboarding instance and independent library
reload; backend tests also reconstruct the library after import/deletion.

1. [Library/presets](screenshots/01-world-library.png)
2. [Keyboard Generate action](screenshots/02-generate-action.png)
3. [Genuine generation in progress](screenshots/03-generating.png)
4. [Generated entry](screenshots/04-generated-library.png)
5. [Generated map](screenshots/05-generated-preview.png)
6. [Exact deletion confirmation](screenshots/06-delete-confirmation.png)
7. [World removed](screenshots/07-world-deleted.png)
8. [Dependent-save deletion blocked](screenshots/08-deletion-blocked.png)
9. [Generated state's highlight](screenshots/09-generated-region.png)
10. [Generated eligible hometown](screenshots/10-generated-hometown.png)

## Windows review steps

1. Extract Windows helper beside project.godot. Launch main scene in Godot
   4.6.3 at 1280×720; skip intro, choose New Game.
2. Verify World I/II remain selectable and Delete World is disabled for them.
3. Keyboard-tab or click Generate New World. Wait through geography/map phases.
   No website, browser or external runtime installation should be requested.
4. Choose the generated entry; preview and generated date should appear.
   Exit/relaunch and verify that entry/map survive.
5. Pick a real state/province and eligible hometown; confirm origin. It should
   reach Origin Established only after the existing save and reload validation.
6. Start New Game again, select that same world and try Delete World. It must
   report a dependent save and leave world/save intact.
7. Generate another world, Delete World → Keep World, then Delete World →
   confirm. Verify removal survives restart and preset/dependent worlds remain.
8. Test 640×360 logical layout, 1280×720 and larger desktop scaling, keyboard,
   mouse and Back/Escape. Native Windows visual acceptance remains Mark's review.

No merges, campaign deletion, research stack integration or subsequent stage
implementation are part of this delivery. Linear access is unavailable; the
prepared [Linear update](LINEAR-UPDATE.md) accompanies the package.
