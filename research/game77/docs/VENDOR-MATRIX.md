# Vendor / content provenance matrix

Exact upstream commits, licence hashes and snapshots: [pins.json](../audit/pins.json).
No upstream runtime, prose, dictionary, names or item tables are vendored. Licence
snapshots are audit documentation only. This is a source audit, not legal clearance
of each upstream dataset. “No import” avoids unresolved data lineage.

| Provider / repository | Pin / version | Licence / language | Dependencies and footprint | Content / risks | Recommendation / attribution |
|---|---|---|---|---|---|
| [Lexicon](https://github.com/ianlintner/lexiconlang) | `da0a823e275d9642731bdaed1f3006d2c9bfae74`; core/grammar 0.2.0, fantasy 0.4.0 | MIT / TypeScript | Core zero external runtime deps; grammar+markov internal core. Core+grammar reachable transformed source 22,650 B / 13 modules; Markov ~6.6 KB. Monorepo pnpm build/dev toolchain separate. | Context.child forks original seed, not parent draw state; Tracery-like symbols/actions/modifiers, context functions; offline Markov. Fantasy NPC/settlement/faction/tavern/equipment/hooks facilities exist, but corpora include recognizable fantasy names without per-entry lineage. No clean culture mapping or row-level clearance. | Keep code-only grammar as a future option. No fantasy corpus import. MIT copyright/permission notice required if adopted. |
| [Rantjs](https://github.com/robbestad/Rantjs) | `c62d5b21b9da9be561c15afdccd5f352cdb91e64`; 3.0.0 | ISC / TypeScript | Zero runtime deps; engine-only reachable source 40,147 B / 15 modules. Full src ~970 KB includes vocabulary. | Explicit seed, dictionaries, carriers/remembered variables, compile/explain APIs. Instance RNG is stateful unless reseeded per entity; missing seed uses Math.random. README freezes 3.0, successor seeds not portable. Default vocabulary refers to Rantionary; ISC code alone does not clear data. | Engine-only + original dictionaries works, but unnecessary today. ISC notice if adopted. Do not import vocabulary. |
| [Fantasy Content Generator](https://github.com/thomascgray/fantasy-content-generator) | `323aca8d0e946420cae59a315fbb2a9ba7958ec8`; 4.9.1 | MIT / TypeScript | One runtime dep seedrandom ^3.0.5; older Parcel/Jest build tree. | NPC traits/desires, hooks/loot/items/settlement field structures. Explicit D&D 5E association; README advises checking source licensing. Seeded selection is separate from UUIDs using Date/performance/Math.random. No complete SRD/text-table lineage audited. | Donor-inspired staged fields only, original implementation/content. Reject direct corpus/mechanics/UUIDs. MIT notice if code later copied. |
| [Venture](https://github.com/opd-ai/venture) | `3e308230f7ca387a23e774c346baa7db5c4f78e6`; commit snapshot | MIT / Go 1.24.5 | 7 direct + 34 indirect modules in go.mod (Ebiten, WebRTC, graphics etc). GitHub repository ~542 MB; this is repository size, not a shipped binary measurement. | Reviewed narrative generator, quest/item types, faction generator: staged participants/events/tags useful; item combat schemas and mutable RNG unsuitable. No entire corpus or all transitive content licences cleared. | Do not vendor application/runtime. Conceptual staging/tags only, no copied code. MIT notice if adapted code later used. |
| [Loremaker](https://github.com/kesac/Loremaker) | `fe18b6e95bfffe9adfb149c3388d1a61e6860753`; 0.1-alpha7 | MIT / C# netstandard2.0 | Five library deps: Archigen, Delaunator, Stateless, Syllabore, System.Text.Json; examples net8.0/additional graphics deps. | TextTemplate substitution; Syllabore naming. Embedded data and completion prompt resources need separate audit; not all features meet offline-only intent. No runtime build/benchmark performed. | Not useful enough for an extra .NET boundary. No data import. MIT notice if adopted. |
| [NPC Generator](https://github.com/FyefoxxM/npc-generator) | `b2a16ceb7f12a4467fe91444d488ff9199c64434`; snapshot | MIT / Python | Stdlib generator; optional sibling name generator/data. No build/benchmark performed. | Explicit trait conflict table is useful design; global random.seed is not our hierarchical model. D&D-labelled occupations/secrets/hooks JSON lacks per-entry source audit. | Constraint concept only; no Python runtime or prose/table import. MIT notice if copied. |
| [Corpora](https://github.com/dariusk/corpora) | `2e7adec11a0561696c236ae1fca82e88be173d42`; snapshot | README CC0 dedication / JSON | Static files; no runtime needed | Data-first collection with contributor CC0 rule. Specific future lists still need lineage/context/quality review; no generic bulk naming import. | Potential small curated dataset later. CC0 does not require attribution; keep provenance regardless. None imported. |

Alethea/world-history-engine returned GitHub 404 during this audit; unavailable,
not tested or substituted. “Questify” lacks an unambiguous repository in the brief;
not a serious selected candidate and no provenance asserted. Eigengrau prose is
excluded under the explicit historical-provenance warning; no code or corpus used.

## Comparable experiments and decision

[Actual results](../evidence/provider-comparison.json): 1,000 real pinned Lexicon
and Rant renders use **the exact same structured TRHGD facts** as the donor-inspired
TRHGD staged generator/renderer. All outputs match, repeat, and leave facts unchanged.
The initial experiment separately exercises Lexicon independent child forks and
Rant remembered carriers. This does not claim FCG/Venture runtimes were executed.

Measured local 1,000-render times are single-run diagnostics, not a universal
performance ranking. Both libraries are small enough; the decisive factor is
that neither handles canonical facts, contradiction rules, visibility or versioned
storage for us. The original renderer is sufficient for this content-pack size.
No package install, new player runtime or added production helper megabytes.
Node 24.19.0 from GAME-76 runs all enrichment directly. Research module source size
is recorded in TEST-RESULTS; no production pipeline is changed.

Reproduce the external audit experiment with checkouts at the pins:

```
node research/game77/tools/provider-comparison.mjs /path/to/lexiconlang /path/to/Rantjs /tmp/comparison.json
```

Native Node stripTypeScriptTypes is used only for temporary audit compilation;
its experimental warning is documented. Player/research enrichment itself is
plain .mjs with Node built-ins. Original TRHGD pack has no third-party content;
this repository has no blanket licence granting commercial distribution rights.
The project owner must set its own content/software distribution licence.
