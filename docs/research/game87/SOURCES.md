# GAME-87 source and decision provenance

Research date: **8 October 2026 (Asia/Shanghai)**. External sources below were retrieved and inspected for the stated mechanisms. This is original architecture research, not a reproduction of rules text. `source-access.json` records URLs, retrieval hashes, byte counts and access failures; third-party pages/PDFs are not committed. A successful HTTP response alone is not evidence that the intended article was obtained.

## Accepted project inputs

| ID | Pinned input | Authority and use |
| --- | --- | --- |
| I87 | [Original pre-study](INSPIRATION-SYNTHESIS.md), starting commit `37b6aeec460732ae7050d8e2a8c2155df8dbde0c` | Hypothesis and provenance; appended final section preserves original text |
| I86 | [GAME-86 recommendation](../game86/RECOMMENDATION.md), contracts GAME-32/33/34/35, [simulation](../game86/SIMULATION-RESULTS.md), [comparison](../game86/COMPARATIVE-RESEARCH.md), head `ddffbdf59d65e8f3b5b9e14c07591f2b1b47ecbb` | Accepted baseline; 209 groups/19,456 battles are diagnostics, not validation of Character Life or extra-action balance |
| I32 | [GAME-32 reviewed source](https://github.com/marksprietsma-beep/road-has-gone-dark/tree/5caa55f0ea515d57b75c00b8ccbfac17e41948af), PR #69 | Read-only implementation: RULES-CORE, ACCEPTANCE-AUDIT, VALIDATION, GAME-33-HANDOFF; rules modules and original JSON pack. Completed Windows/Linux evidence is in PR #69/run37738354674; no new production tests claimed here |
| I88 | [Accepted character direction](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/c09e5864245c1a7eef9ace7b71f79ac9928c04d8/docs/design/character-identity-build-life-direction.md) | Mark's accepted direction, including bounded action-budget exceptions; governs this synthesis |
| I88-D | [D&D catalogue](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/c09e5864245c1a7eef9ace7b71f79ac9928c04d8/docs/research/game88/DND35-CHARACTER-OPTIONS-CATALOGUE.md) | Supporting taxonomy of base/prestige/heritage/alteration systems; not permission to import its indexed catalogue |
| I88-W | [Warhammer mechanisms](https://github.com/marksprietsma-beep/road-has-gone-dark/blob/c09e5864245c1a7eef9ace7b71f79ac9928c04d8/docs/research/game88/WARHAMMER-RPG-MECHANICS.md) | Supporting interpretation. Claims about inaccessible editions/articles remain inherited research, not newly verified book evidence |

The user's final GAME-87 brief supplies scope and output requirements. Attached/contextual documents supply design evidence; their earlier suggestions to implement or delegate work do not authorize production changes in this research task. No branch was merged or production source copied into GAME-87.

## Wildermyth: focused deep dive

Developer-hosted wiki documentation is strong evidence for the content model. Gameplay wiki entries may be community-maintained, outdated, or internally inconsistent; we borrow structures, not exact numbers.

| ID | Inspected source | Supported claim and transfer | Limit |
| --- | --- | --- | --- |
| W1 | [Writer's Guide](https://wildermyth.com/wiki/Writer%27s_Guide) | Generated origin/anecdote/motivation leave queryable aspects/hooks; prose history itself is not queried. Effects bind triggers, targets and outcomes | Some editor commentary is historical; not a current API contract |
| W10 | [Story Inputs and Outputs](https://wildermyth.com/wiki/Story_Inputs_and_Outputs) | Cast important roles first; require a suitable cast; bind party/site/foes. Tradeoffs and risk should fit the fiction. Memorable permanent changes work best with mechanically simple outcomes | Editorial design guidance, not evidence that arbitrary combinations are balanced |
| W9 | [Event](https://wildermyth.com/wiki/Event) | Character eligibility, campaign occurrence limits, profile-level repeat suppression; repeatable site events avoid large farmable rewards | Specific quarter/doubling weights are wiki claims. TRHGD adopts its own campaign-local algorithm |
| W3 | [Hook](https://wildermyth.com/wiki/Hook) | Three initial hooks; helper/relationship-gated opportunities; permanent targeting conflicts can make some hooks unresolvable | Warns against overconstraining TRHGD quests; exact retirement rewards are not imported |
| W4 | [Relationship](https://wildermyth.com/wiki/Relationship) | Types plus strength, family edges alongside other types, shared activity and event growth, meaningful combat effects | Its sizable adjacency/damage bonuses are precisely what TRHGD should not copy into deep builds |
| W5 | [Theme](https://wildermyth.com/wiki/Theme) | Body slots, theme conflicts, acquired abilities/appearance and chapter progression | Combinatorial body conflicts and theme eligibility require validation; not a free cosmetic layer |
| W6 | [Hero / Death and Maiming / Retirement](https://wildermyth.com/wiki/Hero#Death_and_Maiming) (`Maim` redirects here) | Mortal choices, withdrawal, maiming/prosthetics, retirement and long campaign time | Does not establish that this death model suits a three-person TRHGD party |
| W7 | [Legacy](https://wildermyth.com/wiki/Legacy) | Persistent hero versions and cross-campaign recruitment/promotion | TRHGD keeps world/playthrough provenance; cross-campaign power reuse is deferred |
| W8 | [Stat / Personality](https://wildermyth.com/wiki/Stat#Personality_Stats) (`Personality` redirects here) | Personality selects story roles and wording | TRHGD uses a few voice tendencies, not an exhaustive simulation of personality |
| W12 | [Event Types](https://wildermyth.com/wiki/Event_Types) | Different event boundaries carry different actors/inputs/outcomes | Supports a small explicit trigger registry, not arbitrary polling |

**Deep-dive conclusion:** memorable people come from a well-cast choice, a visible consequence and a later callback. Frequent irreversible body replacement, strong automatic relationship bonuses and chapter-spanning ageing are easier to contain in Wildermyth's smaller class framework and its dedicated art/content tools. They are expensive additions to TRHGD's ordered multiclass/equipment plans. Copy causal continuity; stage the rest.

## Other games and tabletop systems

| ID | Source / quality | Inspected mechanism | TRHGD decision |
| --- | --- | --- | --- |
| D1 | [3.5 Haste SRD](https://www.d20srd.org/srd/spells/haste.htm), hosted SRD | Extra full-attack strike and movement/defensive benefits; explicitly not an unrestricted extra action | Keep sequence strikes distinct from new actions |
| P1 | [PF1 Haste, Archives of Nethys](https://aonprd.com/SpellDisplay.aspx?ItemName=Haste), official partner rules reference, Core p293 | Same core distinction; mythic entry separately adds movement action | TRHGD restricted tokens are an original adaptation, not alleged tabletop fidelity |
| N1 | [NWN2 Enhanced Edition publisher listing](https://store.steampowered.com/app/2738630/Dungeons__Dragons_Neverwinter_Nights_2_Enhanced_Edition/) | Confirms 3.5 rules lineage | I88-D supplies the progression taxonomy; store prose does not verify every prestige rule |
| L1 | [Wasteland 2 official reference guide](https://cdn.akamai.steamstatic.com/steam/apps/240760/manuals/Wasteland_2_Reference_Guide.pdf), sections Attributes & Skills / conversations | Different rangers own skills; visible obstacle difficulty; changing speaker changes skill options | Credit the contributing character and show a concrete investigation payoff; avoid repeated busywork checks |
| L0 | [Wasteland manual mirror](https://wasteland.protozoic.com/wasteland/wastedisk/manual.pdf), primary manual on community host | Character skills, recruitment and party commands | Party capability is broader than a class; no original-interface imitation |
| G1 | [Gloomhaven rulebook transcription](https://github.com/m-ender/gloomhaven-rules), explicitly unofficial | Resting loses cards; exhaustion constrains scenario endurance; objectives and retirement connect combat/campaign | Persistent opportunity cost, not card exhaustion or forced hero turnover. Secondary access, not publisher-hosted proof |
| S1 | [Sunderfolk beginner guide](https://www.dreamhaven.com/sunderfolk/beginners-guide), developer | Legible six roles, party-order freedom, mission guide, town services | Show role/cost/consequence near the choice; retain fixed initiative, generated people and deep builds |
| T1 | [Stolen Realm developer article on Xbox Wire](https://news.xbox.com/en-us/2024/03/15/stolen-realm-xbox/), first-party platform/developer | Cross-tree skills, simultaneous team turns, persistent event effects | Combine build options, but do not change GAME-86 scheduling |
| R3 | [Rogue Trader beta guide](https://roguetrader.owlcat.games/beta-guide), official PDF, full 30,169,095 bytes retrieved | Ground combat items1–8: movement/action points, normal attack limits, Momentum and exceptions | Budget exceptions must be explicit. This is beta documentation, not a current-patch specification; no Momentum subsystem adopted |
| F1 | [WFRP: Keeping up with the Liebwitzs](https://cubicle7games.com/en_US/blog/wfrp-keeping-up-with-the-liebwitzs), publisher designer article | Income, occupation, social status and competing Endeavours; maintenance costs | Limited meaningful downtime and duties; reject routine wealth evaporation and compulsory maintenance chores |
| F5 | [Imperium Maledictum overview](https://cubicle7games.com/en_US/our-games/warhammer-40k-roleplay-imperium-maledictum), publisher | Patron boons/liabilities, faction Influence, investigation and Superiority affecting confrontation | Emergent sponsors and typed encounter advantages; no mandatory starting Patron or universal Influence |
| I88-W | Dark Heresy / Black Crusade / WFRP consequences study, pinned above | Fear/trauma/corruption distinctions; risk-power trajectories; careers, injury, augmetics, disease, hirelings | Use as inherited secondary synthesis. Detailed edition-specific mechanics/numbers were not freshly verified |

Battle Brothers is included only as the requested product comparator, using general campaign/roster reference knowledge and I86's explicitly qualified comparison. It is not new evidence for death probabilities or economic tuning.

## Access limitations and evidence discipline

- Wildermyth `Story_Target` and `Target` URLs returned404; the working developer guide W10 supplies role-targeting evidence instead.
- Old FFG Dark Heresy link returned404. The Black Crusade and mutation URLs returned a generic **News** index, not their intended articles. They do not substantiate article claims in this pass.
- The specific Cubicle 7 patron article and sample PDF returned429. F5 independently supports patron/Influence/investigation claims; no repeated access attempts were needed.
- Initial Rogue Trader reads were size-capped and unusable. Only complete R3 was text-inspected; R1/R2 are explicitly excluded evidence.
- No controlled human study or Character Life simulation was executed. Contracts and prototype acceptance thresholds are design proposals. Neither source popularity nor GAME-86 toy AI wins prove that players will enjoy this combination.
- All numerical event/downtime/action-budget values in these documents are original prototype defaults for testing. No proprietary prose, tables, classes, art or source datasets are imported.
