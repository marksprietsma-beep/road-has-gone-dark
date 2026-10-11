# Procedural Opportunities V2

V2 extends the existing four-opportunity sandbox. It adds recovery, investigation and contested access without replacing world generation, party generation, rules, combat or the save owner. The audit/version boundary is in [AUDIT-AND-VERSIONING.md](AUDIT-AND-VERSIONING.md).

## Selection and provenance

`opportunities-v2.json` contains seven authored templates: scattered supplies, abandoned shelter, traces of old work, unusual traces, occupied shelter, contested salvage and obstruction near a verified route. Environment weights derive from the hometown's actual parent-cell biome/height. Route obstruction is eligible only within two source-map units of a visible source road/trail touching that cell. Templates cannot repeat in one four-opportunity set.

A small coverage constraint reserves one recovery, one investigation and one contested template; the fourth is another weighted eligible template. Coverage slots are hash-permuted independently of placements, rather than assigning a kind to each index. This intentionally guarantees a playable comparison in this bounded slice; it does not simulate objective abundance, canonical ruins, factions or a living global economy. Fine site fiction is labelled generated/inferred.

V1 supplies the exact eight legal, dry-land, original-cell-owned local placements and its unchanged legal board composer. V2 assigns separate versioned IDs and seeds to four of those placements. V2 hostile boards use the same 8×6, 10×8 and 12×8 deployments, terrain primitives and four opponent compositions. Non-hostile sites retain an inert potential board recipe for schema consistency, but cannot start combat; measurements report hostile opponents separately. No tactical RNG is consumed by opportunity selection or companion choices.

## Decisions and costs

| Family | Approach | Actual consequence |
| --- | --- | --- |
| Recovery | Checked recovery | 2 turns, 1 provision; recover up to 3, capped at 4; checked-store information |
| Recovery | Quick recovery | 1 turn, 1 provision; recover up to 1; partial information and less net supply |
| Investigation | Careful comparison | 2 turns, 1 provision; record compared evidence; chart a still-unlocated other report if one exists |
| Investigation | Quick assessment | 1 turn, no provision cost; surface information; no additional location discovery |
| Contested | Peaceful access | 2 turns, 2 provisions; access secured; occupants remain; no combat reward |
| Contested | Observe | 2 turns, 1 provision; persist actual opponent/board information, leave the confrontation open |
| Contested | Fight | Existing saved tactical encounter; actual HP/Focus risk and authoritative 10/0 journey XP |
| Any | Withdraw | No site-resolution time/provision cost; close the attempt without completing its objective |

Departure, scouting, travel and return retain their existing costs. Fighting retains its existing preparation threshold (at least one provision), rather than charging a new attack cost. Recovery is capped by existing journey capacity; buttons explicitly display that cap. Time is the existing expedition clock, with no new survival-pressure simulation. Return home retains V0 rest and preparation; provisions are journey-local rather than a newly invented inventory.

Optional contribution choices match a companion's **saved occupation** against template-supported professions. A relevant worker saves one provision; recovery also takes one rather than two turns. A former porter can help assess packs, a repairer or potter can examine old work, and a traveller can observe a controlled approach. These are bounded authored activities, not claims that provisional roles grant skills. No ancestry assumptions, new proficiencies, skill rolls, money, items, personal acquaintances or mandatory quests are added. Unmatched parties have no fabricated hook. Every contributor is recorded by persistent character ID and exact saved profession.

## Save and result contract

Saved V1 records route through their original validation/transitions and frozen manifest. New sandbox preparation defaults to `sandbox-opportunities-v2`; old expedition/Old Road records are retained. There is no V1 migration. V2's manifest must be versioned again before any future incompatible generator change; rewriting it after release would invalidate its pinned saves.

V2 keeps the existing sandbox record's base/knowledge/encounters/results/active/characters and adds `actions` and `information`. The action ledger binds:

- Site and choice IDs, optional participant and profession.
- Provision cost/recovery and balances before/after, plus clock cost.
- Ordered expedition event sequence/type and readable summary.
- Distinct outcome, discovered information and optional discovered site.
- Completion, genuine battle hash and genuine battle XP (empty/zero for noncombat).

Completed actions become explicit `activity-result-v2` results. Observation remains an incomplete action, so the player can return, reload and decide later; observing the same occupants again is rejected. A resolved knowledge state means the attempt is **closed**, including withdrawal/defeat, whereas `world_deltas.objective_completed` and `threat_defeated` separately describe what was accomplished. Avoidance never marks enemies defeated. There are no hidden retries, rerolls or respawns.

The validator reconstructs ordered results, information, party XP/history, contributor records and world deltas from the ledger, checks choice eligibility/costs against the pinned template and saved profession, and reconstructs provision balances from expedition events. It validates combat through TacticalCombat, checks source/site provenance and regenerated legal board recipes, and rejects actions after a terminal result. Service resume additionally reproduces the exact base from the canonical region packet, rejecting source-coordinate drift.

AdventureService retains its existing lock, exact-byte journal, GamePlaythroughStore validation/save/reload and expedition revision guard. Final combat state and consequence remain one transaction. Separate presentation selection never writes a save. Four narrowly permitted V2 clock-event types are rejected on V1 campaigns; existing V1 event timing and authored encounters are unchanged. Legacy diagnostics explicitly select V1 when creating historical fixtures, while saved versions take precedence over that test-only flag.

## UI and scope

The production expedition controller retains its existing map, shared GAME-98 icons, unknown/rumoured projection, party history, responsive split layout and mouse/keyboard controls. At a visited V2 site it shows the activity family, danger, affordable choices, real costs and expected information. Unsupported/unaffordable/repeated inspection choices are disabled. Noncombat results display their own outcome and costs. Rumoured reports have generic titles and no public position or kind.

This remains a finite local slice: four opportunities, seven templates, no dungeons, guilds, economy, new bestiary, factions or generic story engine. Unchecked assessment uses an explicit partial-information result, not a fabricated random danger roll. Peaceful access is an authored provision exchange, not a charisma check. Companion contribution is based on saved profession, not a personal quest. Full transformation, recruitment, multiclass progression and advanced GAME-33 rules remain separate work.
