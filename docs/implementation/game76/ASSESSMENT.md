# GAME-76 engineering assessment

Production main is exactly accepted GAME-74 merge
`4079c442bb26069fde8d9f40e4d686e1eff1d518`; no later commits.

The real generation boundary is project-owned canonical serialization around
pinned Azgaar 1.153.1 / cc5dbac5db12ba4a7c47e647f6bef8bd7bf930c6, loaded by
Vite SSR with jsdom and locked npm dependencies. System Node is unacceptable for
players. A GDScript port would diverge from the accepted generator; a single
SEA executable would need new ESM/dynamic-import/data-file bundling machinery.
Choose a platform-specific **bundled runtime helper directory**, with Node 24,
the existing source boundary and runtime dependency closure from the vendor
lock. Include source and third-party licences, pin runtime version/checksum in
packaging CI, and test generation using the packaged executable. The larger
runtime footprint is an explicit V1 tradeoff; no website/browser/network call
is needed at runtime. Windows ships node.exe; Linux/macOS ship node. No bash or
PATH lookup occurs in the player path. Packaging scripts are developer tools.

Store generated worlds under user://worlds/<canonical SHA>/, containing world
JSON, metadata and rebuildable preview. Presets remain in res://. No central
registry: discovery validates each self-describing entry against GAME-7's
world identity/fingerprint. Local label/date/cache never affect identity.
Generation writes a hidden staging directory, validates and builds preview,
then commits by directory rename; incomplete staging is excluded/recovered.
Identical output deduplicates by fingerprint instead of creating duplicate
world entries. Existing onboarding consumes discovered entries and unchanged
GAME-7 hometown/persistence APIs.

Deletion checks all JSON saves plus interrupted .bak/.tmp saves. Unreadable or
malformed dependency information blocks deletion. A matching immutable ID or
SHA blocks deletion without touching saves. Rename an unreferenced generated
world into hidden trash first, then remove its contents; restart finishes
interrupted trash removal. Presets are never deletion targets. Confirm the
exact selected entry and recheck references at commit time.

Reuse MapRenderBaker for generated previews, cache texture/cell IDs with source
fingerprint and cache hashes, and rebuild missing/corrupt caches. Run slow
helper execution and baking off the UI thread; prevent concurrent jobs, show
truthful phases and restore controls after errors. Defer cancellation rather
than abandoning an external process; close must wait for the job. No full atlas.

Tests: packaged genuine generation twice per seed and distinct seeds,
canonical/provider pins, immutable fixtures, restart/discovery, transactional
failure/recovery, preview rebuild, multiple independent saves per world,
conservative deletion guards (including corrupt and interrupted saves), actual
Godot input/render flow and screenshots. Windows CI builds/packages the same
helper and runs its deterministic generation contract. Existing GAME-7/74
regressions remain required. No export preset exists: document helper placement
beside exported executable and project-run placement explicitly.

Non-goals: GAME-75 flavour, character/party creation, gameplay, Continue/campaign
management, generator parameters, world editing, cloud sync, research stack
integration or merges. Linear has no authenticated tool in this environment;
prepare a repository update if that remains unavailable.
