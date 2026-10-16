# GAME-126 — completeness before further roster expansion

Start: main `dd01fdf5a8f2f04634aa2aa29e99ed0c2b74e81b`. Gameplay and immutable v15 still match the Wave Five implementation merge `0db418283bf2f32668760b872d5908fb944b4270`; intervening commits are design documentation only. All seven implementation-merge Windows workflows now passed. The verified Windows package and final receipts are preserved in the updated Wave Five delivery documents. No historical pack is changed.

The authoritative task is TASK.md, under GAME-123 (GitHub milestone mirror #101). GAME-88's research catalogue and accepted identity/build/life guide remain design/provenance references, not licences to copy proprietary sourcebook implementations. Current main's glossary and design checkpoint retain character completeness as the delivery priority; NPC/settlement design does not authorise implementation here.

## Critical refinements to the brief

- Keep all six audit domains and the twelve representative journeys. Do not replace the eventual broad character vision with a smaller roster. No new Base Classes in this repair wave.
- A legal progression table, a numerical level increase, an owned ability and an executed effect are different claims. Audit each level's actual gains and resource/selection changes; flag numerical-only or absent signature progression without equating every quiet level to a bug.
- Prestige compatibility needs distinct single-class and multiclass witnesses, entry level, permanent prerequisites, intended path cap and legal continuation to total level 20. A failed bounded search is not proof of impossibility. Every positive witness must replay through the existing rules authority; earned entry must separately pass the existing campaign XP/save authority.
- Static effect/consumer discovery is evidence of definition, not automatic functional or player acceptance. Store Indexed, Defined, Selectable, Mechanically functional, Automated-tested and Player-validated separately, with witness references. Inherit historical receipts only with explicit source provenance; do not claim comprehensive human acceptance.
- Native tactical tests and noncombat tests have different scopes. The current seven skill checks are real outcomes, but do not imply all fourteen skills affect gameplay. Inspect actual consumers before selecting a repair.
- Keep all 760 source occurrences/720 normalised rows, including 403 ancestry/subrace occurrences. Preserve uncertain taxonomy and source variants rather than guessing equivalence or discarding templates/monstrous options. Unsupported body/visual capabilities remain explicit.
- Matrix generation must call the production Godot character, prerequisite, effect and advancement code for dynamic claims. Python may inventory JSON and references, never act as a competing rules engine.

## Engineering sequence

1. Reproducible static inventory of every implemented class/level, prestige, feat, skill, spell/power/ability, ancestry/heritage and every research-source occurrence. Record source/pack hashes and precise scope of existing evidence.
2. Production-kernel witnesses: legal class tracks, level gains, equipment, actual abilities, prerequisite-directed prestige routes and continuation; persistent exact snapshots and separate-process reload. Preserve bounded-search unknowns.
3. Twelve representative build journeys spanning martial, stealth, arcane, divine, nature, hybrid, psychic and unusual ancestry. Distinguish development level-20 fixtures from real XP-funded campaign advancement/entry/decline.
4. Rank findings by lost player capability, supporting-system reach, save risk and bounded delivery cost. Implement one coherent repair, not a roster or architecture expansion. Content changes append immutable v16; retain v1–v15 and old campaign pins.
5. Focused meaningful effect/negative/replay tests, real Godot UI evidence and Windows-only native acceptance. Reuse verified unchanged historical receipts; run required current candidate checks. Commit/push, publish a PR against current main and merge normally only after required success.

## Initial source findings — not repair acceptance

- v15 inventories 32 Base Classes, 18 Prestige Paths, 37 ancestry families/50 heritage records, 82 feats, 14 skills, 143 named spell identities/198 class references and 45 psychic identities. These counts do not establish complete mechanics or human acceptance.
- The legacy coverage dashboard's top-level `current_delivery` still describes v13 while later sections describe v15. The new dashboard must distinguish source ledger history from current per-option evidence rather than propagate that stale summary.
- OpportunityCycles uses a pinned family-to-skill map and saved character profiles. Source inspection finds only seven skills in that map. The other seven require consumer/effect audit, not an automatic declaration of functionality.

No repair option has been selected or reported complete at this checkpoint. Detailed reproducible findings and the selected improvement follow after the source/kernel audit.
