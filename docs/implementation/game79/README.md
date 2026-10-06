# GAME-79 — Production Origin Lore V1

Production origin enrichment is separate from canonical geography and campaign knowledge. Every GAME-7 eligible hometown receives an immutable generated memory and tradition. GAME-75 factual descriptions remain unchanged. Hometown comparison shows a concise stored memory; confirmation and handoff show the fuller stored history in a bounded, scrollable area. Map size, fonts, rectangular controls and keyboard/mouse selection are preserved.

## Promoted components

`tools/world_enrichment/` contains the reviewed SHA field seeds, context, compatibility, provider-neutral structured generators and fact-bound Rant renderer. `data/world_enrichment/` contains the original expanded pack, curated CC0 vocabulary, integrity manifest and complete preset packages. `vendor/content/` retains selected clean MIT/ISC engines and exact notices/provenance. `scripts/world_enrichment/origin_lore.gd` validates and caches only the explicit public projection for UI lookup.

Only Origin V1 is invoked by production. Other structured domain generators remain dormant shared infrastructure. Native provider experiments, giant batches and research UI are left in #59–62; their histories are not merged. No FCG/SRD pack, Venture executable, dubious prose corpus, extra player runtime or online service is added. See [licensing inventory](LICENSING.md).

## Three distinct identities

1. Azgaar world ID/SHA — existing GAME-7 identity and immutable fixture/world bytes.
2. Enrichment descriptor — schema, provider, generator, exact pack version/SHA, renderer, base world identity, structured-file SHA, public-file SHA, runtime-manifest SHA and eligible coverage count.
3. Playthrough ID/knowledge — existing GAME-7 independent campaign and skeleton records. New onboarding saves additionally pin the descriptor; old saves without that field remain legacy and load normally.

`enrichment_sha` in the **descriptor** is SHA-256 of the entire structured file, including its newline; this permits exact byte validation in Godot. The retained structured envelope also carries its GAME-78 internal canonical-payload digest. These deliberately name different validation boundaries. `public_projection_sha` hashes the complete projection bytes. Neither hash alters the base world ID.

## World lifecycle

Presets ship all 855 eligible origins (429 + 426), not a shortlist. Newly generated worlds use the same packaged Node 24.19.0 helper. Godot validates geography and prepares its existing preview, then compiles/validates enrichment in the owned staging directory before writing metadata and renaming the complete world directory. Generation/enrichment failure publishes no library entry. Complete crash staging is recoverable only with valid descriptor/files.

```
user://worlds/<canonical-sha>/
  world.json
  metadata.json                 # existing world reference + origin descriptor
  preview.png / preview.cells / preview.meta.json
  enrichment/origin-v1/
    descriptor.json
    enrichment.json             # structured facts, including private provenance
    public.json                 # source IDs and allowlisted public text only
```

A legacy generated world remains discoverable without lore. Selecting it initiates a background, missing-only upgrade. The existing library lock protects the upgrade; a complete candidate is validated against every matching campaign pin, including recovery backups, before the final directory rename. Incompatible pinned history is refused; campaign bytes are never rewritten. Corrupt/unsupported existing lore is never regenerated silently. Restarting after a successful upgrade reads the exact persisted bytes. Factual browsing remains available on failure; creating a new origin is blocked until its lore validates.

Unused-world deletion removes the owned enrichment tree with the template and preview. Existing GAME-76 save references still block deletion of used worlds. Save deletion does not remove a reusable template. Unknown directories and symlinks are never followed during cleanup.

## Save and version policy

New confirmation attaches `origin_enrichment` to the existing save schema. GAME-7 validates that reference at write and reload. A mismatched digest/version/world/hometown gives a specific error and does not delete a campaign. Immediate reload must pass before the UI claims success. If external enrichment fails after a successful write, confirmation retains and retries that same slot; restoring the exact lore completes handoff with one save. The earlier GAME-74 cleanup/retry behavior for corrupt origin records remains tested separately.

Changing a pack, provider, generator, renderer or release manifest requires an explicit new descriptor/version package. Existing packages/campaign pins must not be rewritten. V1 supports the reviewed versions only: an unsupported old version fails clearly rather than being reinterpreted. A future release must retain compatible old readers/packs or provide an explicit migration; no migration UI is introduced here. Mutable campaign discoveries never enter the immutable public projection.

## Offline packaging and integrity

`tools/worldgen/package-helper.mjs` packages the selected engines, content, compiler, licences and provenance into the existing native Node helper. No player npm install or separately installed Node/Python/browser is needed. The compiler verifies every manifest file before publication. Godot verifies those hashes before accepting a projection; files may be in `res://` or the same packaged helper, supporting exported projects. Keep the production JSON data and canonical fixtures available in exported resources, and distribute `worldgen-helper` beside the executable using the existing GAME-76 recipe. Source projects already contain these files. This task does not introduce a new export/build system.

Preset/runtime reproduction (build tools only):

```sh
node tools/world_enrichment/build-manifest.mjs
node tools/world_enrichment/origin-world.mjs --world <canonical-world.json> --output <new-enrichment-directory>
```

The manifest build is a release action; players never repair mismatched code by rebuilding a manifest. The compiler refuses to overwrite different existing bytes. Move reviewed old packages aside deliberately when authoring a new release; never do that as a campaign repair.

## Verification and Windows review

Run `node --test tests/world_enrichment/compiler.test.mjs`, then `python tests/world_enrichment/run-tests.py --visual --regressions` with the verified Godot executable and `GAME76_HELPER_ROOT`. Linux render checks require Xvfb; Windows CI runs the native generation/persistence/source regressions. The workflow is `Verify Production World Enrichment`; its `game79-helper-Windows` and `game79-helper-Linux` artifacts contain the matching native helper archive and checksum. These artifacts supplement the durable committed build recipe; they are not the source delivery. Platform timing is emitted as a check annotation and retained in `generated-worlds.json` artifacts.

Windows Godot 4.6.3 steps:

1. Obtain this branch plus its matching GAME-76 native helper; place `worldgen-helper` beside the exported executable or in the project root. Do not reuse a helper from an earlier branch without the new modules.
2. Launch/skip intro → New Game → World I → choose state/province → compare several hometowns using mouse, arrows and Tab. Memory, factual summary and map location must change together.
3. Repeat in World II and Generate New World. Select a hometown, review its fuller history, scroll that history if needed, confirm once and reach Party Creation Next. Review Origin must retain the same lore.
4. Close/reopen Godot, select the generated world again and compare its same hometown. Run the underlying save reload tests; Continue remains disabled.
5. Check 640×360, 1280×720 and a larger desktop window. Both action buttons, the factual summary and useful map must remain visible. Linux screenshots and Windows CI are evidence, not a claim of Mark's laptop visual acceptance.

No character creation, Continue enablement, travel, quests, combat, new map generation, canonical fixture mutation or research-branch merge is included. See the review gallery and executed proofs in this directory.
