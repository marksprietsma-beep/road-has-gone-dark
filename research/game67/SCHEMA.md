# Facility contract v1 (research only)

`Settlement → BuildingInstance → Establishment → Function` is a research boundary,
not the existing GameWorld/save schema. An outdoor establishment has no building.
A function describes premises; it does not implement a playable service.

- `schemaVersion: 1`, `audience: developer | public`.
- Settlement: `id`, immutable `worldIdentity` (the original canonical fixture SHA-256),
  `burgId`, `worldSeed` for provenance, and mutable display `name`.
- Layout: SHA-256 `revision` over original building IDs and polygons, pinned
  `providerRevision`, coordinate `units`, y-down axes, bounds, scale evidence,
  and an explicit non-authoritative geographical classification.
- Building: canonical `id`, original polygon rings and district. Developer records
  also contain `providerId` and polygon provenance. Ordinary buildings have no
  invented establishment, owner or service.
- Establishment: canonical `id`, `type`, descriptive `function`, generic `label`,
  nullable `name`, explicit unnamed status, `locationType`, nullable `buildingId`,
  anchor `position`, preserved `sourcePosition`, district, knowledge, and provenance.
  Availability is unknown. No guild is invented where the source lacks one.
- Provenance: provider revision, nullable provider POI/building IDs, source evidence,
  binding method and `truth: provider-generated, source-backed`.
- Knowledge: `unknown | discovered | visited`, separate from objective facilities.
  The committed scenario deliberately hides ONE real shop in each city. This is
  hypothetical player knowledge, not generated lore or an actual campaign save.
- Geometry: untouched original roof polygons and source line/polygon features;
  original Scene fields and water rings supplement city GeoJSON. Rendering uses
  a research parchment style, not the provider's complete textured artwork.

## Identity and relocation

IDs are versioned namespace + full SHA-256 of canonical tuples. Settlement identity
uses immutable world fixture identity and burg ID, never the settlement name.
Building IDs additionally include layout revision and provider building ID.
Establishment IDs include the same layout revision and either provider POI ID or
an explicitly identified village landmark building ID. Village glyphs establish
chapel/inn/manor semantics; they are not falsely recorded as POIs.

These IDs are repeatable within this layout, NOT guaranteed across provider
upgrades. Any geometry change generates a new layout namespace. Future migration
must keep the old layout and an explicit old-to-new establishment crosswalk:
semantic kind + district + geometric overlap/interior distance can propose a
match, but ambiguous matches require review. Do not transfer knowledge silently,
identify buildings by display name, or regenerate an established campaign layout.
Relocated facilities need a separately versioned crosswalk with confidence and
approval, preserving original provenance. No migration is implemented here.

## Binding and validation

Explicit source building references take priority. References must exist and
POI IDs must be unique; invalid and duplicate records fail loudly. Original
point-in-polygon anchors are tested against actual polygons. If an explicit
reference lies outside its roof, an interior centroid fallback is recorded as a
diagnostic; an invalid fallback fails. All three original datasets need ZERO
fallbacks. Outdoor POIs keep their actual point and null building reference.
No polygon is moved, resized or renamed to suit a facility.

## Public boundary

`publicExport()` removes undiscovered establishment records, including their IDs,
positions, source points, semantic types and building association. It removes
provider building IDs/provenance and diagnostics. Anonymous objective roof geometry
remains visible, as on a town map, without hidden associations. Public rendering
uses only this payload. The developer payload is fetched solely after explicit
opt-in, cleared on return to public view, and marked prominently in the UI.

This openly published research package includes developer/source fixtures; it is
NOT an authorization/security boundary. A future server must withhold privileged
payloads entirely. Player-known public records may carry source-backed provenance;
undiscovered records never enter the public map payload or DOM. Static saved data
and download output are tested independently of client-side marker filtering.

`model.mjs` performs runtime validation and serialization checks. The JSON schema
is an interchange outline; geometric association and ID uniqueness need runtime
validation beyond JSON Schema.
