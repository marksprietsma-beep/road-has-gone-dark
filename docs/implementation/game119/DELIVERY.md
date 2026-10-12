# GAME-119 review delivery

Independent branch: `feature/game-119-deep-character-progression`, stacked on `feature/game-118-playable-core-characters` (draft PR88). PR80, PR81 and PR88 remain unmerged. GitHub mirror: [#89](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/89); full programme [#82](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/82) remains open. Linear is not callable; no Linear update is claimed.

## Implemented batch

- Eleven distinct core archetype adaptations through levels1–12.
- 27 scheduled persistent career-choice groups: school, domain, bloodline, style, quarry, rage/talent/divine/ki/nature/performance options and selected prestige casting tracks.
- Four five-level prestige adaptations: Duelist, Eldritch Knight, Arcane Trickster, Mystic Theurge. Actual entry prerequisites, ordered multiclass replay, finite tactical actions and hybrid spell progression.
- 30 selectable mechanical feats, including actual higher chains and separate coincident general/class grants.
- Existing nine race families/fourteen heritages retained. Latest fresh default v9; installed v1–v8 remain byte-identical. Existing campaigns do not repin.

These are original bounded TRHGD adaptations, not complete sourcebook conversions. Core13–20, broader specialisations, companion/summon authority, more feats/spells and the full403/66/~283 catalogue remain unfinished. Deep-level fixtures are developmental. Normal adventures prove earned level two; sustainable deep-career XP is a separate [follow-up #90](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/90). No arbitrary production XP grant.

## Verification so far

Local actual Godot: career/feat progression601 checks; all selectable choice effects285; prestige prerequisites/history101; prestige combat/quarry84; all spontaneous tier unlocks63; complete core tactical effects8674. All pass. Frozen source boundary9 and legacy battlefield/independent command oracle3370 pass. The v9 rendered full journey/entry/build/actual combat fixtures pass831 checks, and a new process passes43 reload checks; original pinned creator344 and v3 creator375 pass. Self-contained native Linux export runs six hometown journeys1252 checks and fresh-process restart87 checks with empty PATH and no source-helper override. Windows/current-source CI is still pending; release acceptance is not claimed here yet.

Screenshots are actual Godot/Mesa renders, not drawn substitutes. See [screenshots](screenshots/) and [raw evidence](evidence/). Full source and native workflow results, final Windows link/checksum and exact source qualification will be appended after CI completes.

[Assessment](ASSESSMENT.md), [coverage](COVERAGE.json), [testing](TESTING.md), [precise continuation](CONTINUATION.md).

Publication stopping point: prepare a draft PR against GAME118, then prompt the user to click **Publish draft PR**. Do not merge automatically.
