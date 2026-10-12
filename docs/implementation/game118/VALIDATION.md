# GAME-118 release validation

Production source: `de63453c83e6451b8929e708f3e1e5a9e559ca38`. Exact current core pin is recorded in both native core-proof.json files and data/rules/packs.json. All old pack files/builder-v1 are byte-identical to PR81's `b146dd4`.

The native Windows/Linux workflow and all nine companion source workflows passed. The packaged native diagnostic used normal production controllers, empty PATH and bundled artwork/helper, then a separate process verified snapshots/pins and persisted journeys. It is removed from the playable ZIP. Raw results and actual timings are in evidence/native-windows/ and evidence/native-linux/.

See DELIVERY.md for counts, links/checksum and known limits. Evidence is scoped: completed low-level original adaptations are distinguished from the uncompleted source catalogue. Higher-level powers are tested with explicit development fixtures; organic play demonstrates level two using earned victory XP.

All screenshots are actual Godot 4.6.3 renders. Final creator/card captures use de63453; the longer a461936 rendered journey predates only the pending-card fix. Combat/rules/content are byte-identical between those commits. The manifest records individual source revisions. No synthetic UI screenshots were substituted.
