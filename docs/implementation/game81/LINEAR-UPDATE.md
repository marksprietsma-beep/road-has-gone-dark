# Prepared GAME-81 update

Draft PR: https://github.com/marksprietsma-beep/road-has-gone-dark/pull/65
Branch: feature/game-81-party-creation-v0
Base: GAME-80 c661d31c41b255384de49a4db7be111b6a3abfc1, unchanged.

Implemented the three-adventurer Party Creation V0 slice on the same origin campaign. Reused GAME-78 production character generation/compatibility, GAME-80 public profiles, GAME-7 atomic same-slot saves and the existing Node helper. Original eight-people presence is independent of Azgaar culture; four roles are provisional intent, not classes. Names, people/roles, structured public backgrounds and deliberate variant counters persist; siblings do not reroll. Party Ready stops before mechanics/gameplay; a narrow menu resume action keeps Continue disabled.

A separate immutable people package and third runtime pin preserve V1/V2 packages and canonical world bytes. Missing-only upgrade, package corruption refusal, per-campaign/world locking, immediate reload validation and exact previous-byte recovery prevent false success and duplicate campaigns. Legacy skeleton saves remain valid.

Evidence is in docs/implementation/game81: sequential screenshots/gallery, 1,050 unfiltered backgrounds across two presets and five fresh worlds, compatibility/duplicate metrics and human review of the first 100. Failure tests exercise the actual UI rejecting a failed post-write reload and deterministic retry, plus generator/write/corruption/identity/incomplete-party and interrupted-write/rollback cases. The local native proof passed 29 checks, including generate/edit/reroll/ready/reload for both presets inside the exported PCK and the fresh-world production UI. Preset inputs are copied byte-for-byte into exact owned jobs and removed afterward; partial-copy failure preserves the origin. Native Linux/Windows workflow publishes complete matching executable/helper packages; inspect the final successful run, not an obsolete intermediate run.

This is prepared text because no authenticated Linear connector is exposed in this environment. No issue status was changed. GAME-80 acceptance, GAME-32 mechanics and GAME-82 prose polishing are not included. Mark's final Windows laptop visual acceptance remains for review; nothing is merged.
