# GAME-77 public origin-lore demonstration on GAME-75

Separate branch `integration/game-77-origin-lore`, based on frozen, green GAME-75
head `3cdbd31b9d4a34ebe7211337e7f2112c9a73526f` (draft #58). Core GAME-77 remains
independent draft #59 on production main. Neither original branch is modified.

Minimal UI change: confirmation/handoff can show **Local memory** beneath the
origin details, separate from unchanged GAME-75 factual context. Only a pinned
public projection is loaded. Missing world/town lore adds nothing and never
substitutes another town's story. Existing selection, factual panel, map, save
validation and navigation remain unchanged. No gameplay or character creation.

This is deliberately a **three-town demonstration**, not full world-generation
integration: Maura (771), Klovskitaue (25), and one actual eligible Atlas hometown
(ID in public-origins.json). Existing/newly generated worlds with other identities
have no demonstration lore. This narrow proof does not persist a new enrichment
reference into GAME-7 saves; production reference/lifecycle integration is still
an explicit future decision. The static immutable research sidecars store the
full generated local memory + tradition; the public UI renders only the memory
sentence to fit the approved 640×360 layout. No UI invents prose dynamically.

`data/manifest.json` pins core source modules, projection digest and renderer
variant. To reproduce, check out core commit
`325799cca5d082d6c05d3c589c13c18fc91cd4e1` in a separate directory, then run:

```
worldgen-helper/node research/game77-integration/generate-demo.mjs /path/to/core-checkout
```

The exact core Godot OriginLore adapter is copied unchanged at its eventual core
path, so the two drafts do not contain differing versions of that file. No core
vendor experiment/framework or unrelated files are copied into this UI draft.
Tests and actual screenshots under evidence demonstrate public-only payload,
wrong identity/digest rejection, unchanged factual context, confirmation/save
handoff, Back and missing-lore fallback. Prepared Linear update lives below.
