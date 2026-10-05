# Prepared GAME-73 update

Research implementation ready for Mark's review; acceptance pending. Linear access
was unavailable, so this update has not been posted.

Both canonical worlds were fully scanned: 873/783 original burgs, zero same-cell
pairs, 631/588 adjacent-cell pairs. The 20%-per-side fringe adds the first visible
neighbour in 279/257 occupied-cell windows. Genuine proof: Colira/Riveivalfei,
burgs 569/774, cells 3311/3171, consecutive original road-12 points. Both are visible
in each independent region; ownership stays distinct, and detailed plans are unavailable.

Isolated Settlement Context adapter keeps exact/derived/inferred/unknown facts and
name-independent identities separate. Deterministic relative classes and hypothetical
cell-area envelopes cover four real examples, with no kilometre conversion.
Overlap checks preserve source roads/coasts/cells; inferred decoration seams are
quantified. The existing Batan/Albanes/Thilranlena maps are broadly coherent.
Thilranlena water differs by 0.87°; forced rotation worsens both water and roads.
Its harbour-tagged land-trail entrance is a semantic review item, not proven water
crossing. Pinned engine capabilities/licensing and the smallest future step are documented.

Evidence links: research/game73/README.md, evidence/contact-sheet.png,
evidence/neighbour-comparison.png, evidence/rotation-comparison.png,
evidence/relative-scale.png. Source/context/fringe/scale/evidence tests and relevant
inherited regressions passed; full logs are committed. No source data, approved
art/facilities, accepted generators, navigation, saves, gameplay or GAME-19 changed.
New stacked draft PR targets fix/game-71-72-map-presentation; existing drafts remain
untouched and unmerged. Recommendations are not automatically implemented.

Published draft: https://github.com/marksprietsma-beep/road-has-gone-dark/pull/55

Direct durable review links:

- [Report](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/research/game-73-geographical-coherence/research/game73/README.md)
- [Phone overview](https://raw.githubusercontent.com/marksprietsma-beep/road-has-gone-dark/research/game-73-geographical-coherence/research/game73/evidence/contact-sheet.png)
- [Real neighbouring regions](https://raw.githubusercontent.com/marksprietsma-beep/road-has-gone-dark/research/game-73-geographical-coherence/research/game73/evidence/neighbour-comparison.png)
- [Measured rotation rejection](https://raw.githubusercontent.com/marksprietsma-beep/road-has-gone-dark/research/game-73-geographical-coherence/research/game73/evidence/rotation-comparison.png)
- [Explicitly hypothetical scale envelopes](https://raw.githubusercontent.com/marksprietsma-beep/road-has-gone-dark/research/game-73-geographical-coherence/research/game73/evidence/relative-scale.png)

GitHub verification at the implementation milestone confirmed all 111 changed-file
blob hashes, correct stacked draft base, and protected PRs #51–#54 unchanged/open/unmerged.
