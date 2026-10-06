# Production notices and extraction provenance

Extracted from GAME-78 `31adff84cf1531bd06947361523aec7675f4d67a`, preserving reviewed content-pack SHA `31a9bd036a153e9356b6b7cc1dfae2945992fc4c70e2f32c2881ef3c3031104c`.

| Material | Exact upstream | Licence | Production use |
|---|---|---|---|
| Lexicon core/grammar/language/Markov engine | ianlintner/lexiconlang `da0a823e275d9642731bdaed1f3006d2c9bfae74` | MIT | Selected Node ESM engine files only; no upstream fantasy tables |
| Rant reachable prose engine | robbestad/Rantjs `c62d5b21b9da9be561c15afdccd5f352cdb91e64` | ISC | Fact-bound original templates; no Rantionary/default dictionaries |
| Curated common material/room words | dariusk/corpora `2e7adec11a0561696c236ae1fca82e88be173d42` | CC0-1.0 README dedication | Four small curated subsets; exact paths, input digests and last-change pins in vocabulary JSON |
| Expanded pack/compatibility/seed/context/structured generators/render patterns | TRHGD GAME-77/78 review heads | Project-owned original code/content | Promoted shared modules, only origin compiler active |

`vendor/content/provenance.json` records each redistributed file, original path, source SHA, transformed SHA, copyright, modification and required notice. Relative imports between copied vendor files remain unchanged. Production-owned module imports were relocated; code algorithms and pack bytes were retained. Preserve `vendor/content/lexicon/LICENSE` and `vendor/content/rant/LICENSE` in every helper distribution. The helper copies the complete provenance inventory and notices. CC0 excerpts preserve their source metadata even though attribution is not required.

No FCG/SRD tables, Venture runtime, Eigengrau prose, questionable corpora, GPL dependencies, provider batches or native research outputs are promoted. The approved research remains on its original branches. Shared future domain modules are dormant, not production gameplay services.
