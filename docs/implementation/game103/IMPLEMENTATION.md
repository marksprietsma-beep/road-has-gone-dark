# GAME-103 player-controlled characters

New and unfinished campaigns enter the existing party-creation scene with three suggested level-one build drafts. Suggestions are optional; none become gameplay mechanics until the player saves and confirms each adventurer, then readies the party. Ready legacy parties skip creation and are never regenerated. The permanent **Characters** sheet is accessible from the expedition and **Sheet** from paused tactical combat.

## Ownership and validation

`CharacterBuilderService` extends the existing service and uses its world guard, campaign lock, transactional journal and `GamePlaythroughStore`. No second save writer exists. It rejects stale full-state hashes. Malformed XP namespaces, rosters and numeric values cannot throw script errors or fund advancement; campaign validation still rejects the damaged save. Finalisation transfers all drafts into the existing pinned mechanics records atomically. Gameplay still consumes `RulesCharacter` derived snapshots; narrative role does not select a different class after finalisation.

Player parties have schema 2 / `player-party-1`, explicitly permitting independently source-backed personal hometowns and source-compatible professions. Schema 1 retains its original generated-party contract. New-party identity mirrors, background identity, world geography, tags, ancestry/heritage correspondence, companion IDs and confirmed records are validated on every load. Existing world fingerprints, art recipes, opportunity versions, helper pins and `trhgd-rules-v1` definitions are unchanged.

The shared `BuildEditor` calls GAME-32 creation, choice, advancement and derivation APIs. Standard-array controls swap scores rather than duplicating them. Skill budgets/rank caps, feats, equipment exclusivity and preparations are validated by the kernel, with explanations and live statistics. Class changes require reviewing the resulting allocation. Optional recommendation buttons explicitly replace build choices. Unsaved edits must be saved or reverted before leaving. All three confirmations are required before finalisation.

Identity includes an editable name, existing prototype people/current heritage, separate narrative role, source-world personal origin and compatible profession. Personal culture and biography come from actual source geography; changing a class never invents a different ancestry or culture. Starting equipment is selected from the existing authored pack; this task does not add shops, loot or an inventory economy.

## Earned advancement

The separate original `builder-v1.json` campaign policy requires cumulative validated journey XP `20*(level-1)^2`; level one is free only during creation. Level 2 requires 20 XP; level 3 requires 80. Advance is allowed at home, with the real kernel's class, skills, scheduled feat and ability-increase choices. A funded, ordered ledger pins each committed history step. Saved HP/resources are retained through the existing advancement API; advancement is not a free heal. Legacy ordered levels are grandfathered when first advancing, not rebuilt. There is no production XP or level grant control.

The current finite sandbox has four opportunities, so higher progression is content-limited. Isolated test fixtures exercise prestige prerequisites directly in the kernel; those fixtures do not grant campaign XP or unlock production content. This policy is an initial original progression contract, separately versioned from unchanged rules definitions; changing it later requires an explicit compatibility decision.

## Limits

The creator exposes current implemented original content only. GAME-88 research is not playable content or a final ancestry roster. GAME-104 owns wider option design; GAME-105 owns future skill checks. Some derived class abilities are implemented in the rules kernel but remain unconnected to First Adventure tactical controls. The sheet labels that distinction. LPC anatomy coverage and the existing deterministic visual recipes are unchanged. No new combat, world generation, ancestry mechanics, transformations or procedural dungeon framework is introduced.
