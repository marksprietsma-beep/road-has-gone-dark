# NPC and monster design checkpoint — 17 October 2026

**Status:** Twelve questions answered; design interview complete. **Development next:** [GAME-141](https://linear.app/marksprietsma/issue/GAME-141/milestone-broad-integrated-living-world-prototype-before-windows), beginning with [GAME-142](https://linear.app/marksprietsma/issue/GAME-142/audit-current-game-and-lock-integration-contracts-for-broad-living).

This summary records accepted design only; it does **not** certify features implemented in Godot. Full contracts are the referenced ADRs, which prevail in any dispute.

| Question | Choice and accepted outcome | Canonical document |
| --- | --- | --- |
| 1. Ecology and persistence | **B** — regional habitats, territories and group-level population changes; consequential creatures individually persistent; bounded advancement | [ADR 0004](../adr/0004-regional-monster-ecology-and-creature-persistence.md) |
| 2. Species mechanics | **B** — different anatomy, natural weapons, movement, senses, resistances, powers and tactics on **one shared d20 combat/effect authority** | ADR 0004 |
| 3. Distribution | **B** — geography, ecology, fantasy history, magic, faction influence, rarity and credible migration | ADR 0004 |
| 4. Threat | **B** — world-grounded danger **independent of current party level**, meaningful cues and real avoidance, diplomacy or retreat opportunities | ADR 0004 |
| 5. Behaviour | **B** — species-specific instincts, intelligence, needs, morale and contextually nonviolent outcomes, not universal kill-on-sight AI | ADR 0004 |
| 6. Humanoid NPC competence | **B** — tiered mechanical depth; major NPCs use real classes/feats/spells; **extra:** boss/epic action economy and credible prepared-place lair actions, bounded and counterable | [ADR 0005](../adr/0005-tiered-npc-builds-and-boss-action-economy.md) |
| 7. Recruitment | **B** — many NPCs may become hires/companions/allies/rivals through real contracts, independence, conflicting obligations and credible leaving | ADR 0005 |
| 8. Factions | **B** — factions have goals, rivalries, internal differences; people have multiple changeable loyalties, no always-on political sim | ADR 0005 |
| 9. Sapient nonhumans | **B** — intelligent historically monster-labelled peoples are culturally and socially diverse, not default enemies; distinctive species mechanics remain | ADR 0005 |
| 10. Adventure situation | **B** — mechanically real combat and alternative encounters using actual character powers with distinct persistent consequences | [ADR 0006](../adr/0006-systemic-encounter-approaches-and-persistent-outcomes.md) |
| 11. Creature art | **B** — accurate species body plans/silhouettes and equipment plus truthful combat telegraphs, modular animation and cited assets | [ADR 0007](../adr/0007-species-art-and-combat-telegraphs.md) |
| 12. Next Windows user playtest | **C** — **broad, integrated prototype** with multiple monster species, persistent NPCs, populated settlements, factions and diverse encounters **before** asking the player to test again | [ADR 0008](../adr/0008-integrated-living-world-prototype-milestone.md) |

## Delivery interpretation

**Not a one-scene vertical slice.** Start from a tested core and implement separate waves that converge on a genuinely connected procedural setting: real opposing species, people, societies and factions, mechanically different choices, lasting outcomes and correct presentation. Interim engineering tests/merges are encouraged; the **next human review build** should be this broader integrated milestone.

**Start with GAME-142** architecture/code truth audit, then coordinate the existing specialised issues: GAME-122 species/opposition, GAME-105 character-driven noncombat, GAME-137 recruitment, GAME-138 factions, GAME-139 nonhuman society, GAME-140 creature art, GAME-136 boss/lair action economy, GAME-94/106/107 LPC humanoid visuals, GAME-96/101 world-based opportunities, and GAME-10/29 source peoples and guild context. Avoid duplicating their owners.

**Non-negotiables:** Windows-only; source-backed immutable World Template versus Playthrough deltas, save-pinned rules/old campaign compatibility, seeded determinism, one combat/effects and save authority, no continuously simulated every-entity world. **Q12(C) overrides earlier recommendations** to finish an isolated one-adventure prototype before the user's next playtest, not the value of small automated proof tests within production.
