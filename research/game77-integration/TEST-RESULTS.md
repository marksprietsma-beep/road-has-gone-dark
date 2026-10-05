# Integration QA

Production facts/save APIs reused; no new eligibility/save model.

- Actual Godot 4.6.3 input/render: **48 assertions, 0 failures**. Real mouse
  confirmation → validated saved origin; Review Origin/reconfirmation creates no
  duplicate save. Back restores selection. Both canonical world identities,
  missing-lore fallback, factual-panel equality and footer bounds checked.
- Public adapter: **28 checks pass**; exact source/eligibility/cell/world/digest and stored-fact text
  checks, cross-world/missing-town rejection, failed-load stale clearing; count
  and full result in `evidence/logs/public-adapter.txt`.
- GAME-7 persistence smoke; GAME-74 3,973 source/save and 26 forced-reload-failure
  checks rerun. Full GAME-75 source/context: **105,425 checks, 0 failures** across two presets
  and three freshly generated helper worlds; independent Python audit of all
  five worlds passes.
- Existing native Windows/Linux CI also runs the accepted world-library/helper
  regressions; integration-specific headless adapter/actual Linux flow steps
  are added to that workflow. Final check conclusions belong to the final PR head.
- Actual screenshots at 640×360 and 1280×720 inspected. The longer coastal-town
  memory also fits the approved left column. No style/layout redesign.

World JSON remains byte-identical. No scripts/runtime errors in passing runs.
Linux Xvfb reports only the documented unsupported VSync capability warning.
A first new test harness called a nonexistent list_saves method; it was corrected
to inspect the isolated test save directory using the actual API. The rerun above
passed; this was a test-harness issue, not a product save defect.

Limit: three static preset examples. This PR does not automatically enrich newly
generated worlds, modify saved playthroughs or persist an enrichment reference in
GAME-7. That lifecycle must be reviewed separately before production integration.
