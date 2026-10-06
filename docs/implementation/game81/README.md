# GAME-81 — party creation V0

Draft [PR #65](https://github.com/marksprietsma-beep/road-has-gone-dark/pull/65), stacked on GAME-80 `c661d31c41b255384de49a4db7be111b6a3abfc1`. No upstream research PR or base branch is modified. This implementation ends at Party Ready.

Origin confirmation now enters a three-adventurer editor. Each existing GAME-7 skeleton keeps its immutable campaign/slot ID. Players edit a name, choose one of eight peoples and one of four provisional roles, inspect a structured background, or deliberately regenerate that member. Saving and returning to the menu preserve the same campaign. A narrow Resume party setup action reopens that campaign; Continue and expedition gameplay remain disabled.

## Architecture reused

`tools/party/generator.mjs` adapts the production GAME-78 staged character generator, declarative compatibility, original background tables, Lexicon weighted choices/phonotactics and fact-bound Rant rendering. It receives actual GAME-80 public state/region/hometown profiles. Local and regional economy weight compatible former occupations; a regional mine is a public regional constraint, not an invented hometown mine. Source culture/religion/geography, public profile IDs, state posture, local memory and regional contribution remain structured references. No hidden world site or private generator field is serialized into the party.

The original pack adds eight separate peoples, four semantic roles and eight contextual occupation refinements over the 30 production occupations. Roles are intentions, not classes or mechanical abilities. Culture and ancestry remain separate: source culture IDs condition naming/presence seeds, never a one-to-one race conversion. There is no reliable independent source ancestry field or naming-base dictionary in these canonical exports; fantasy words in culture names are not evidence. Names use original phonotactics, not imported cultural vocabulary.

`peoples-v1` is immutable generated TRHGD enrichment: world/state/region/home qualitative common/present/uncommon weights. Those weights are generation preferences, not census figures. All eight peoples remain selectable everywhere. Source geography is a soft preference, not an ancestry rule. Parent presence contributes to children; independent stable entity seeds prevent generation order from rerolling neighbours. The source worlds remain immutable.

A third exact `runtime-party-v1.json` includes the frozen origin-V1/profiles-V2 closure plus the new party modules/pack. No existing manifest or V1/V2 package is regenerated. The existing offline Node 24 helper is extended without a new dependency or second runtime. Generated worlds receive missing people enrichment on deliberate party entry under the library lock. Corrupt, mismatched or pinned packages are refused; retries never overwrite them silently.

## Identity and persistence

Save version 1 receives an optional `party` record and `onboarding_stage` (`party_creation`/`party_ready`). It mirrors names/people/role/background references into the existing skeleton records while retaining their IDs and untouched mechanical placeholders. The party pins the exact people, content and runtime versions. Each background retains its explicit variant counter and stable origin IDs. An edited name survives ancestry changes and rerolls; a name-only edit does not change background identity. The member name is authoritative for display; the original generated name remains a proposal in the structured generator facts, distinguished by the edit marker. Default members prefer different roles, occupations, households, motives and keepsakes; manual duplicate people/roles are allowed.

`PartyService` serializes one campaign update, validates the candidate through GAME-7, writes the same slot, then immediately reload-validates it. A recovery journal preserves the exact previous bytes. Failed post-write validation rolls back and reports an error, never a success handoff. Restart either validates the completed candidate or restores the exact prior draft, including interrupted Game-7 backup/party rollback renames. Unexpected external file changes are preserved and reported rather than overwritten. Failed edits retain the visible draft; failed preparation offers an explicit retry in the same slot.

Legacy campaigns lacking a party remain valid with their existing V1/V2 pins. Explicit party entry adds the new package/records. There is no destructive migration, silent content-version upgrade or second campaign. Future generator/pack changes require separate versioned packages and explicit migration policy; they cannot reroll an existing party on ordinary reload.

## Review and reproduction

[Executed results](QA-RESULTS.md), [sequential examples](QUALITY-SAMPLES.md), [all 1,050 records](sequential-backgrounds.json), [batch metrics](batch-metrics.json), [five fresh-world identities](generated-worlds.json), [screenshots](screenshots/), and [native distribution proof](distribution-proof.json).

Build the single helper with `node tools/worldgen/bootstrap-helper.mjs`, using Node 24.19.0 and Godot 4.6.3. Then run `python tests/party/run-tests.py --visual --regressions` under a real display (Linux CI uses Xvfb). The runner fails on script errors as well as nonzero exit codes. Two independent Godot processes create/edit/ready and then reload/corrupt/restore seven campaigns. Older origin regressions intercept only their new routing signal so their persistence boundary remains testable; GAME-81 exercises the real default menu→origin→party routing and actual keyboard/mouse controls.

`GAME81_RELEASE_ROOT=<owned-new-directory> python tests/party/verify-package.py` exports the game plus matching native helper, checks fresh-world/party lifecycle with empty PATH, launches the production executable, excludes the diagnostic executable from the final archive and emits a checksum. `.github/workflows/verify-party-creation.yml` performs this on Windows and Linux and publishes `game81-complete-Windows`/`game81-complete-Linux`. CI must finish successfully before those packages are described as ready.

## Windows review steps

Download the latest successful PR #65 Actions artifact `game81-complete-Windows`; extract the artifact and its inner ZIP together, retaining the adjacent `worldgen-helper` directory and notices. Launch `road-has-gone-dark.exe` using Godot's bundled executable; no installed Node/browser/internet is required. Skip the intro, New Game, choose a template or generate a world, choose state/region/home, review and confirm.

Check three adventurers, people descriptions/commonness and all eight choices. Edit a name and press Enter; select another role/people and Save character. On Background, regenerate one member and verify the other two remain unchanged. Use Tab, arrows, Enter, mouse and Escape. Mark Party Ready, return to the menu, close/relaunch and Resume party setup. Names, ancestry, roles, backgrounds and variants must remain identical. Repeat at 640×360, 1280×720 and a larger desktop window. Continue remains disabled; no expedition or character mechanics are entered.

## Limits and next boundary

Eight original peoples and four provisional roles are V0 definitions, not a ruleset. Presence is fictional TRHGD enrichment; naming is conservative phonotactic conditioning rather than a full language model. Biographies deliberately retain three recognizable compact forms; prose expansion/polish belongs to GAME-82. Shared hometown acquaintance is the only party relationship. No portraits are required or generated. Strict existing whole-world package validation remains part of save latency; generation/commits run off the UI thread and immutable local presence is cached for selection responsiveness.

GAME-32 may later attach mechanics to existing character IDs through a separately versioned build model. This PR assigns no ancestry bonuses, classes, feats, stats, gear, spells, combat, travel, quests or gameplay. It does not implement that next stage. Mark's hands-on Windows visual acceptance remains a separate review after native automated proof.
