# First Adventure V0

For the combined GAME-83 Windows playtest package, see [Windows review build](WINDOWS-REVIEW.md).

The existing world/origin/town onboarding now leads into a party with personal hooks, one authored tactical encounter, a saved outcome, and return to local expeditions. This is a playable prototype, not completion of GAME-33 or the full GAME-87 architecture.

## Audit and implementation boundary

Audit baseline: `5caa55f0ea515d57b75c00b8ccbfac17e41948af`, the current GAME-32 implementation branch. Main is behind the existing onboarding/party/expedition work; this slice builds on that implementation.

| Existing system | Reuse / gap |
|---|---|
| GAME-76/79 world library and `new_game_origin.gd` | Reuse generation/selection, state/region/town choices, exact world pins and origin save. No new onboarding shell. |
| GAME-81 `PartyService`, `PartyRecords`, `party_creation.gd` | Already creates three named characters with people, occupations, biographies, motivations and hometown-neighbour relationships. Preserve these IDs and all original facts; add a hook/history record separately. |
| GAME-84 `ExpeditionService`, `ExpeditionRecords`, expedition map/view | Already supports accounts, acceptance, departure, scouting, site arrival, choices, consequences and return. Add a battle option at an unresolved site. |
| GAME-32 rules kernel | Existing class recommendations, equipment definitions, explicit dice state, costs, abilities, HP/Focus and build validation. Reuse the kernel without changing the rules pack or progression system. |
| GAME-86 / GAME-33 | Research simulator and design contracts exist on research branches; this implementation baseline has no playable tactical engine. Do not import/rewrite that simulator. V0 implements one encounter and a small authority/view, not the full GAME-33 contract. |
| GAME-87 | Architecture/research exists separately. V0 provides an additive personal hook, XP placeholder, histories and future consequence descriptors; no character-life event framework. |
| Save authority | Reuse `PartyService.operate/commit`: existing world guard, slot lock, exact-byte journal, reload verification and rollback. Every battle action uses that writer. |

Minimal changes to existing systems: `GamePlaythroughStore` validates the optional adventure section; expedition UI calls the service subclass and presents identities/fight/results; expedition site updates merge world deltas so revisiting after defeat preserves combat memory. New files are limited to the authored encounter, combat authority, additive records/service, battle scene/view and tests. There is no new quest manager, character generator, equipment system or save writer.

## Character Life V0

The hometown's **Prepare first adventure** action explicitly prepares existing characters through GAME-32 and attaches `first_adventure.characters[character_id]`. Already prepared builds are retained. The companion cards show name, class/archetype (Roadwarden, Wayfinder or Lantern), occupation/background, existing motivation, a concern-backed personal hook and the existing neighbour relationship. They do not invent a missing person, faction or settlement fact.

Hooks retain `background_ref`, `concern_ref` and the chosen `home_ref`. A battle marks them *experienced*, not resolved. The original biographies and relationships remain authoritative. Generated parties use three of four narrative roles; expert and scout both start as Wayfinders, and a party without a caster remains playable.

## Tactical V0

**Bandits on the Old Road** is an explicitly authored gameplay overlay at the approach to the player's selected local site. The title does not assert that the generated world contains a canonical road, or that its historical site truth included these raiders. The encounter references the actual site ID and hometown; all outcomes belong to the campaign, not the immutable world template. It appears once per campaign at any unresolved site visited after preparation.

- Fixed 8×6 board, four blocked tiles, three original party members and two lightly armed raiders. No generated battlefield/enemy composition.
- Initiative descending, ties by original party/authored order. One movement and one main action per activation; downed units leave the order. Each unit gets one shared reaction refreshed at a global round boundary.
- Orthogonal movement up to derived Stride; occupancy and rocks block movement. Symmetric supercover line of sight and Manhattan range apply to attacks. Dead units do not block tiles.
- Basic attacks use the existing d20 contest, weapon dice and critical rule. Adjacent enemy threat imposes the existing −4 ranged penalty. Leaving adjacency can provoke one departure attack; bow holders make an improvised adjacent blade strike for this prototype.
- **Roadwarden / Guard:** main action; an adjacent living ally's next weapon hit receives −4 damage, spending the guard's reaction. Expires at the next global round. V0 Guard covers weapon hits; Lantern effects are direct rules effects.
- **Wayfinder / Opening Strike:** first qualifying hit per round receives +4 when a living ally threatens the target in melee. This is passive and explained beside the controls; no stealth subsystem.
- **Lantern / Lantern Spark:** main action, range 5, existing damage roll. **Binding Step:** range 5, one Focus, Will save or reduced Stride until target activation end. **Mending Thread:** adjacent living ally, one Focus, heal up to capacity. Spent Focus persists; V0 adds no rest/refill system.
- Enemy AI attacks the nearest eligible target, otherwise moves toward the nearest opponent and ends its turn. Stable ties, explicit SHA-counter dice, no wall clock/global randomness. Each enemy action is saved too.
- Eliminate the raiders for victory. All companions down gives defeat. **Withdraw · defeat** supplies an explicit failure exit during a player turn.

No charge/dash/disengage UI, full spell scheduler, equipment editor, multiplayer or combat generation is added. The rules pack still describes those future actions. This prototype does not claim full GAME-33 tactical conformance.

## Consequences and persistence

The final action and consequences are committed together. Victory gives each original character exactly **10 journey XP** (display/history placeholder; no automatic advancement), records the site, consumes one provision and two expedition turns, and completes the lead on return. Defeat gives no XP, writes the failure, leaves the lead unresolved/withdrawn, and permits return. Surviving HP/Focus persist. Downed members recover to **1 HP**; transient combat statuses clear. This is an explicit V0 rescue rule, not death/injury simulation.

Each companion gets one encounter history. `world_deltas[site_id].first_adventure` remembers victory/defeat even if a later investigation resolves the site. Four saved descriptors (`injury`, `relationship`, `reputation`, `personal_quest`) identify the encounter, affected characters and site with `pending_future_system`; they do not apply those systems.

The saved battle contains the authored-content hash, rules-pinned records, board, order, round/cursor, action tokens, remaining reactions, HP/Focus/statuses, explicit RNG, ordered commands/log and canonical state hash. Resume restores that state. Stale/duplicate commands reject; active encounters block bypassing them with regional actions. Completing the first encounter prevents another reward/fight, while ordinary expeditions remain available.

## Manual playtest

Open **`scenes/ui/main_menu.tscn`** in Godot 4.6 and run that scene (F6), or run the project's main intro normally (F5). Do not run the combat scene alone; it needs an existing campaign handoff.

1. **New Game** → select a world (either bundled preset is sufficient), state, region and eligible hometown → **Confirm origin**. Use the existing three-character editor. For the three showcased ability types choose Vanguard, Scout and Adept; any supported generated trio is valid. **Party ready** → **Enter hometown**.
2. Click **Prepare first adventure**. Click a compact companion row to read its identity and hook. Expect existing names/backgrounds/motivations plus a personal hook and neighbour relationship. Scroll to local accounts and select one.
3. **Accept local lead** → **Begin expedition**. If location unknown, **Scout the rumour**; otherwise **Travel to the site**.
4. At an unresolved site click **Bandits on the Old Road · fight**. Expect a fixed grid, three blue party units, two red raiders, HP on units and a gold border on the current actor. Numbers identify companions in the roster beside the board.
5. **Move · select a clear tile**, then click a reachable dotted tile. **Attack · select enemy**, then click an enemy in weapon range with a clear line. Hover a unit for its name/HP/weapon. **End turn** hands control onward; enemies act automatically. A second move/main action in the same turn must not apply.
6. On a Roadwarden turn, **Guard · protect adjacent ally**; on Wayfinder, attack an enemy adjacent to another companion and look for Opening Strike +4 in the log. On Lantern, select **Lantern Spark**, **Binding Step** or **Mending Thread**, then the appropriate target; inspect HP/Focus and save/control messages. The action panel scrolls and follows keyboard focus (Tab/arrows/Enter).
7. During a player turn use **Main menu** (or Escape), then **Resume Expedition**. Quit/relaunch and resume again. Expect exact positions, turn, HP, action tokens and remaining Focus, not a fresh battle.
8. Win → **Return to regional play** → expect the named site result, 10 XP per companion, event recorded → **Return to hometown**. Expect a Completed lead and continuing local accounts; click a companion row to read its history. Re-entering this encounter must not be offered.
9. In a separate new campaign, choose **Withdraw · defeat**, or deliberately end party turns until enemies win. Return to regional play and home. Expect a clear failure, 0 XP, recorded histories, a Withdrawn lead and HP at least 1. Revisit and investigate that lead normally; battle memory must survive.

Capture screenshots of companion cards, first board, each ability's visible effect/log, paused/resumed board, victory regional result, defeat regional result and returned histories. Include Godot output and describe any unexpected button/target behaviour; compare whether movement, ally protection and ranged positioning create useful decisions. Evaluate readability and encounter feel manually. Passing automation and toy AI victory are not evidence of final class balance or fun.

## Automated validation

With the repository-supported world-generation helper installed and `GAME76_HELPER_ROOT` set to its root:

```sh
python3 tests/adventure/run-tests.py --work-dir /tmp/trhgd-adventure --visual
```

Requires Godot 4.6, Node/helper for real party/local content, and `xvfb-run` for `--visual`. Omit `--visual` for headless logic/campaign checks. Output includes per-stage timing/exit status, logs, separate-process save/reload checks and rendered screenshots under the work directory. The visual test clicks the real site/board/actions/menu/resume/return controls. See `VALIDATION.md` for this change's actual results.
