# Wave Five — merged Windows character cohort

PR [103](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/103) merged normally, preserving history, at `0db418283bf2f32668760b872d5908fb944b4270`. Final feature head: `193e702f681c95257afe6812144bb3dbc6ecfd6c`. All 13 required feature-head checks and full Windows workflow 38843879866 passed before merge. All seven automatic Windows integration workflows then passed on the exact merge commit; see evidence/final-ci.json and TESTING.md. The merge tree exactly matches the tested feature tree.

Subsequent design-only PRs through #115 added/extended only CONTEXT.md, ADRs and the design checkpoint (current documentation main at receipt time: `dd01fdf5a8f2f04634aa2aa29e99ed0c2b74e81b`). Those changes were inspected; runtime, content, assets, tests and packaging are unchanged. This final delivery close-out also changes documentation/evidence only. The build source below remains the verified implementation merge; no fresh runtime success is invented for later documentation-only SHAs.

The recovered proposal became committed gameplay at `9389f00df4415b193da7daac99cd099145963cb5`; subsequent QA, skill acceptance and evidence increments were preserved. Do not restart or republish this cohort. v15 content hash: `65983a234663928122e7b085af01e4d8246e1b95df67612d7236dc39e14452e1`. Historical v1–v14 pack bytes and frozen GAME-32 tactical source remain unchanged. Existing Playthroughs retain exact rules pins; New Game defaults to v15. Windows x64 is the only supported release target.

## Implemented first cohort

- Duskblade1–20: INT-based martial spellcasting, finite tier slots, persistent runic choices and real melee spell channeling from class3. One authoritative equipped/proficient melee attack; only its actual hit delivers the original owned/selected spell through RulesEffects. One main action and one original slot are paid on hits, misses and concealment. No second attack, free spell or HP-loss inference. Critical weapon damage does not double the spell.
- Spirit Shaman1–20: WIS-based bounded retrieved nature/spirit repertoire, nine spell tiers, finite guide abilities and persistent guide choices. Initial choice consumes its permit; existing actual home-return rest permits one change. Selecting spells never refills slots; encounter changes, reopening the sheet and restart do not refresh retrieval. Ordinary spontaneous classes retain their known-spell restrictions.
- Abjurant Champion5 and original Grove Warden3: permanent feat/skill/BAB/casting prerequisites, selected hybrid caster advancement, finite ward/strike or sanctuary/renewal actions. Never starting or automatically awarded. The ordinary campaign earns360XP and explicitly selects Abjurant Champion; a separately saved legal Duskblade decline also reloads exactly.
- Catfolk, Riverborn, Wildborn and Ratfolk original ancestry adaptations; Swiftstrider/Rime additional heritages. Inherited attributes, physical/mental traits, natural attacks or finite protection work; culture/background stay separate. All unusual anatomy has an honest neutral humanoid LPC fallback.
- Sixteen gated feats; thirty-two named spells; ten selectable psychic powers with thirty actual augmentation variants; Ancestor Sentinel/Briar Beast owned creatures and real actions/summons; Moon Stag/Iron Tortoise/Briar Cat forms with physical changes, suppression, reversion and expiry. Existing ownership, turn, duration, action, RNG and save authority is reused.

## Inventory, not milestone acceptance

| Category | Released v14 | Native-validated v15 |
|---|---:|---:|
| Base classes |30|32|
| Prestige paths |16|18|
| Ancestry families |33|37|
| Heritages |44|50|
| Feats |66|82|
| Skills |14|14|
| Named spell identities |111|143|
| Class spell references |162|198|
| Psychic identities |35|45|
| Other named ability labels |367|401|
| Other ability records |391|425|
| Creatures |12|14|
| Body forms |12|15|
| Scheduled career-choice groups |212|228|
| Channel delivery wrappers (not new spells) |0|10|

REPERTOIRE.json records identities/references. ACTIVE-MECHANICS.json separately excludes unreferenced legacy abilities, passive/automatic records, channel wrappers and psychic augmentation. It folds class gates and numeric progression into conservative structural effect/cost groups: v14 has568candidate active records/307structural groups; v15 has648/364. These are reproducible source groups and upper bounds on distinct design ideas, not proof of364individually native-validated, balanced player choices. Do not equate level labels, different names, scheduled selections or all feature records to unique mechanics. Native receipts below validate the cohort; this inventory does not replace human review of mechanical variety.


## Final Windows build

[Download the self-contained Windows x64 review artifact](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/38852441096/artifacts/12026441509).

Playable inner archive: `game112-character-catalogue-wave-five-windows-x64.zip`.

SHA-256: `fffffaf0004f2bb94c7b1d96ace9b58879974b5afa54ee2a85c86fd26ca09651`.

Exact build source: `0db418283bf2f32668760b872d5908fb944b4270`. Native Windows proof: **1,662 mechanics, 46 exact cold character/battle reload, 565 ordinary earned/skill/rest and 4 earned restart checks; zero failures**. Actual production launch used empty PATH and no checkout helper override; no installed Godot or Node is required. Independent download audit verified both ZIP CRCs, 7,061 entries, AMD64 game and bundled helper, exact exported v15 bytes, manifest, source metadata and checksum. See evidence/accepted-main-windows-{native,audit}.json.

The campaign genuinely earns 360 XP through 9 cycles/36 objectives, manually selects Abjurant Champion and separately persists a lawful base-class continuation. Actual saved objectives exercise Arcana, Craft, Insight, Perception, Persuasion, Religion and Survival, including permanent profile bonuses, stable previews, information/outcome/reward persistence and duplicate rejection. High-level development fixtures are labelled; they are not claimed earned level-20 histories.

## Exact review steps

1. Extract the downloaded Actions archive, then its contained playable ZIP. Keep the entire game directory together and launch `road-has-gone-dark.exe`.
2. New Game: choose/generate the World Template, origin and Hometown. Review three Adventurers in the existing creator. Only legal Base Classes appear as starting choices; inspect Duskblade and Spirit Shaman, traits, attributes, skills, feats, equipment, spells and specialisations. Save each Adventurer, then select **Party ready**.
3. Follow ordinary Opportunities and Expeditions to earn XP. Return home and explicitly commit a legal funded advancement; the selector grants no XP. Duskblade channel actions become available from class 3, requiring an equipped proficient melee weapon and selected original spell. Check target feedback, hit/miss handling and action/slot spending.
4. In the Spirit Shaman Spellbook, inspect the saved retrieval allowance. A genuine home-return rest permits one bounded repertoire exchange; selecting spells does not refill slots. Reopening or restarting grants no extra exchange.
5. Review Prestige Path requirements. Eligibility changes nothing automatically; choose an eligible path or continue a legal Base Class during earned advancement. Exit/relaunch and verify identity, ordered history, choices, resources, XP and party consequences remain saved. Existing Playthroughs keep their original pack rather than silently migrating to v15.

## Genuine visual evidence

Godot creator: 54 checks/0, 36 frames; campaign: 81 checks/0, 45 frames. Captures cover 640×360, 1280×720 and 2560×1440, with 13 selected images committed under screenshots/. These are actual Godot/OpenGL development-host renders, not mockups or claimed Windows screenshots. Runtime source matches the final native build; capture harness refinements are separate. Advanced fixtures are labelled, and earned screenshots use actual saved campaign checkpoints. The earlier rejected history replacement was corrected by an isolated new normal birth, never by resetting an earned save.

## Historical receipts and narrow CI corrections

The earlier 705bfe3 native package passed 1591/42/565/4 checks, and 9389f00 passed 1591/42/454/4. Their accepted/initial evidence files remain historical receipts; they are superseded by the exact merge-source package above. Incomplete obsolete enclosing workflows were stopped only after native successes/artifacts were preserved, not relabelled as complete passes.

Onboarding run 38841017525 exceeded the old 120-second cold-import budget before gameplay assertions. Its uploaded log matched a committed stale file because the old runner wrote only after success. The narrow fix writes/truncates live UTF8 logs, retains timeout output, excludes Node-only examples and matches the existing production UI 600-second import budget. Runtime/assertion/error budgets were not weakened. Run 38843368151 then exposed Windows CP1252 output while echoing Node Unicode. Explicit UTF8 stdout/stderr and real Unicode/timeout/error/nonzero tests corrected this. Both failed runs remain recorded as failures; final corrected Windows onboarding 38843818019 passed. Added prestige-effect and hybrid-tier tests execute in the final 1662/46 native proof. Gameplay/content/scene/asset/export source was unchanged by these QA increments.

## Continuing programme and limits

#82 and #101 remain OPEN. This finishes one coherent Wave Five cohort, not the rich-character milestone or full catalogue. The complete 760-occurrence/720-normalised-row ledger remains: 87 bounded native mappings, 673 unresolved. Only eight proven new source mappings were promoted; related sourcebook variants remain unresolved. Source structural groups 307→364 are upper-bound effect/cost inventories, not 364 individually accepted distinct gameplay ideas.

Outstanding milestone work includes greater class/prestige/ancestry/feat breadth, at least 12 representative build journeys, five or more earned optional prestige paths and human build-clarity/balance acceptance. Unusual anatomies, creatures and forms retain an honest neutral humanoid LPC fallback; no flight/aquatic/environmental-vision functionality is claimed. Long combat labels can clip at narrow widths; hover provides details. See CONTINUATION.md for the next substantive cohort; no unrelated world/map/quest or GAME-105/122 implementation was added.
