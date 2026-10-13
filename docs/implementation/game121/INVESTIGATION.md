# GAME-121 — Sustainable earned XP: initial investigation

Historical investigation checkpoint (research commit2441a6f): source audit complete; implementation had not started. Current production implementation and verification are documented in [ASSESSMENT.md](ASSESSMENT.md), [TESTING.md](TESTING.md) and [PACING.md](PACING.md). Separate branch `research/game-121-earned-xp-cadence`, based on recovered GAME-119 review head `05b093a`. GAME-119's tested source is `0971a58`; this investigation adds documentation only. [GitHub mirror #90](https://github.com/marksprietsma-beep/road-has-gone-dark/issues/90); [Linear GAME-121](https://linear.app/marksprietsma/issue/GAME-121). No Linear update is claimed.

## The present journey stops before level three

The normal fresh campaign uses V2: four saved opportunities, including one recovery, one investigation, one contested encounter and one weighted wildcard. Seven activity templates exist: two recovery, two investigation, three contested. Only contested activities can start a battle. Therefore any successfully generated set has **one or two combat opportunities**, regardless of world seed or route eligibility.

A saved combat victory grants **10 journey XP to each character**. Defeat, peaceful access, recovery, investigation, partial assessment and withdrawal grant zero XP. The maximum for a fresh normal V2 campaign is **20 XP per character**, not 60: party members receive parallel progression, not a shared triple award. At 10–20 XP a character can reach level two; level three needs40. This is a hard content ceiling, not merely slow pacing.

| Target | Cumulative core-policy XP | Successful 10-XP objectives from zero | Further successes after best V2 total20 |
| --- | ---: | ---: | ---: |
| Level2 | 10 | 1 | 0 |
| Level3 | 40 | 4 | 2 |
| Level6 | 250 | 25 | 23 |
| Level12 | 1,210 | 121 | 119 |
| Level20 | 3,610 | 361 | 359 |

Existing GAME-119 CI preserves these legally qualified example histories (examples, not a claim of the mathematically earliest possible build):

| Prestige path | Qualified pre-entry history | Next character level | XP needed for first prestige level |
| --- | --- | ---: | ---: |
| Arcane Trickster | Rogue2 / Wizard3 | 6 | 250 |
| Duelist | Fighter6 | 7 | 360 |
| Eldritch Knight | Fighter2 / Wizard5 | 8 | 490 |
| Mystic Theurge | Wizard3 / Cleric3 | 7 | 360 |

Levels6/12/20 cannot be earned in the present fresh journey. High-level GAME-119 fixtures prove mechanics, not organic access. Total character level20 is permitted by the existing kernel through legal multiclass histories; individual core classes are capped at12 and the four prestige classes at5. Neither cap solves the XP ceiling.

Older V1 sandbox records contain four fights, for at most40 sandbox XP. A saved authored Old Road victory can contribute another10; it can happen only once. Those are alternative/historical record paths, not another40 XP obtainable by switching an existing V2 campaign to V1. A fresh normal UI bypasses the authored opening. Even a hypothetical core-policy campaign with both a completed Old Road and V2 reaches at most30, below level three. Existing engine1/2 builder policies require20×(level−1)²; their exact `policy_sha` and rules pin must remain intact. Do not apply the newer thresholds to old campaigns.

## Why travel or repetition does not solve it

`OpportunityGenerator.seed_for` uses version/manifest hash, canonical world fingerprint, hometown, hometown cell and local-content hash. Neither time nor a cycle counter enters the seed. Site/encounter IDs are stable, and `sandbox_begin` returns the existing record once prepared. Reloading, resting, waiting or repeatedly preparing cannot create a fresh set.

`OpportunityAdventure.transition` rejects accepting resolved sites, repeating completed activity, starting another encounter for a saved site, and commands after terminal results. Inspecting a contested site may leave it unresolved, but repeated identical inspection is rejected and earns no XP. Returning home before committing a terminal outcome allows another approach to the same event. Victory, defeat, peaceful access, completed recovery/investigation and the explicit Withdraw choice are terminal. Withdrawal's narrative says the concern remains, yet its `complete=true` closes that opportunity instance; another instance would need explicit generation. Defeat likewise cannot be replayed for reward.

`OpportunityRecords.validate` reconstructs ordered actions, results, information, world deltas, per-character XP/history and expedition provisions. It rejects duplicate/missing rewards and action-after-resolution; terminal combat and reward share the existing atomic save transaction. Keep these protections.

The generator accepts a different hometown and already selects different contextual activities/placements for it. Native review records demonstrate six hometown journeys, but **each belongs to a separate campaign**. Normal expedition services always use `state.origin.home_burg_id`; the UI has local site travel and return-home, with no campaign settlement/region-travel operation. Individual character origin choices do not relocate the party's saved hometown. Manually editing origin would invalidate source/cache/base pins. Additional regions therefore supply reusable technical context, but not currently accessible extra XP for this campaign.

## Smallest robust implementation brief

Extend the current opportunity lifecycle with a **versioned contextual cycle**, initially around the existing hometown. Preserve the old `sandbox` and `first_adventure` records byte-for-byte, including zero-XP noncombat results. Add an optional, explicitly validated cycle namespace through the existing campaign store/journal; no second save writer or rules engine. A campaign begins the extension through the ordinary home action **Seek new leads**, not an obscure content setting. Existing rules and builder XP-policy pins remain unchanged.

1. Pin the new opportunity manifest/reward policy when the first cycle is committed. Derive each cycle deterministically from source world/home/cell/local-content hash, manifest hash and monotonically increasing cycle ordinal. Store complete generated bases and their digests. Reuse verified local placements, weighted biome/route eligibility and frozen battlefield composition; do not regenerate the world or alter V1/V2 manifests.
2. Give every new event its own cycle-scoped opportunity/encounter identity, separate from its persistent geographic placement reference. Store historical cycles/results; never replace completed records or relabel old defeated opponents as fresh enemies. Existing world consequences must remain readable. Eligibility/narrative should account for recorded access/control; valid recovery/investigation alternatives must prevent exhausted placements or repeated defeats from permanently blocking new opportunities. Canonical routes/biomes are facts; new arrivals and reports remain clearly generated local fiction.
3. Advance a cycle only at home, with no active expedition/battle, and after current instances are terminal. Both success and failure/withdrawal must allow eventual continuation. Seeking leads costs a recorded expedition turn and yields no XP. Active/unresolved encounters survive reload exactly. Repeated preview/request/retry must select the same next cycle and commit at most once; stale revisions cannot reroll or create two cycles.
4. Award a proposed **10 XP per character once for each fully completed objective** in the *new* policy, whether achieved through combat victory or an authored valid noncombat success. This gives peaceful choices progression without retroactively changing V2. Inspection, partial assessment, withdrawal, defeat, travel, rest and seeking reports award zero. Battle resolution and objective resolution must share one reward identity; never grant both awards for the same event. Each four-opportunity cycle has a hard40-XP ceiling; reconstruct XP/history from validated terminal results rather than trusting mutable totals.
5. Let the existing `CharacterBuilderRecords.xp` aggregate legacy ledgers plus validated new-cycle rewards; preserve threshold/policy hash and every historical advancement. Reuse current creator/sheet/Advance service and GAME-32 combat authority. Add clear objective rewards, exhausted-cycle messaging, next-lead action and persistent history to the existing expedition UI. Do not hide the path behind developer flags or award free levels.

This first batch removes the hard ceiling and supports level-six prestige entry through ordinary adventures. It does **not** prove reasonable human pacing to12/20. At a constant10 XP, those targets still need121/361 successful objectives. Current generated opponents receive only their initial advancement and boards contain one or two opponents: indefinitely farming these at high levels would not provide meaningful challenge. Sustainable supply, advancement pacing and appropriate challenge are distinct acceptance concerns. Measure ordinary playtest activity duration and failure rates; any later challenge/reward bands need separately pinned original definitions and tested combat through the existing authority. Do not quietly increase rewards for trivial repeated encounters or change old XP thresholds. Core13–20 content remains a separate character-programme batch.

## Implementation sequence and acceptance

Start a separate feature branch from recovered GAME-119 (or its accepted successor), keeping all parent drafts unmerged. First add immutable cycle identity/schema/replay and negative reward tests. Then add contextual generation and ordinary UI lifecycle, followed by earned advancement and package evidence. Do not implement this on GAME-119's review branch.

Required proof for that future implementation:

- Fresh campaigns and exhausted existing V1/V2 campaigns obtain new meaningful events without world resets or rewritten historical pins/results; starting the extension changes only permitted new state.
- Repeated cycle preview, stale commands, interrupted generation/commit, mid-combat restart and duplicate terminal requests do not reroll, lose history or duplicate XP. Corrupt cycle IDs/base hashes/reward records fail validation.
- Recovery/investigation/peaceful success earns its explicitly pinned objective reward; partial actions and unsuccessful outcomes do not. Combat earns the same single objective reward, with unchanged GAME-32 command/RNG results.
- A genuine fresh campaign earns250 XP from saved real objectives and advances to level six. Demonstrate actual earned prestige entry using an approved legal history: Rogue2/Wizard3 then Arcane Trickster1 at250 XP, or continue to490 XP for the tested Fighter2/Wizard5 then Eldritch Knight1 example. Reload choices/history/XP unchanged. Do not claim the Wizard/Fighter path enters at level six, or insert fixture XP/levels.
- An isolated deterministic long-run *gameplay driver* completes enough actual events to cross1,210 and3,610 XP and verifies every reward/reload, clearly distinguished from a human playthrough and from prior high-level development fixtures. Full single-class13–20 is not claimed until its own content exists.
- Preserve frozen V1/V2, existing pinned character policies, GAME-81 input/UI, GAME-32 replay, procedural combat/save suites and native Windows/Linux packages. Capture the real home/next-cycle/earned-advancement/reload UI.
- Record human activity timings before calling the high-level cadence reasonably paced. Catalogue breadth is not marked complete by this work.

## Evidence and practical handoff

[XP-AUDIT.json](XP-AUDIT.json) contains exact thresholds, ceilings, activity counts and audited source hashes. This session inspected code/data and historical records; it generated no new worlds, reset no saves, implemented no cycle system and ran no fresh gameplay regression suite.

Useful existing files: `scripts/sandbox/opportunity_generator.gd`, `opportunity_adventure.gd`, `opportunity_records.gd`, `sandbox_generator.gd`, `sandbox_adventure.gd`; `scripts/combat/adventure_service.gd`; `scripts/party/character_builder_records.gd`; `scripts/game_world/game_playthrough_store.gd`; `scripts/ui/expedition.gd`; `data/sandbox/opportunities-v2.json`; `tests/opportunities/lifecycle.gd` and `corpus.gd`. Current validators use strict schemas and source hashes: extend through new records/version dispatch, not by editing frozen V1/V2 data or weakening their assertions.

Next concrete development step: implement GAME-121's durable cycle/reward ledger and its duplicate/interruption/legacy tests on a separate branch, then connect the ordinary **Seek new leads** journey. After that dependency is validated, resume genuine core13–20 and broader class/spell/prestige content.
