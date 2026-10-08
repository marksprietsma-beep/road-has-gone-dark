# GAME-34 — manual tactical controller and presentation

Proposed independently reviewable ticket contract. Depends on GAME-33 command/observation/events and GAME-32 definitions. Own readable input/presentation; it does not own simulation rules.

## Player interaction

Present the permitted observer's board, units, uncertain appearances, objective, initiative queue, current HP and relevant resources. Selecting an actor shows remaining move/main/reaction and affordable abilities. Path preview distinguishes ordinary move, dash, charge, occupied routes and known departure risks. Ability preview shows cost, range/LOS, area/friendly fire, locked delayed target and resolution activation. Unknown targets/cover remain uncertain rather than leaking truth through highlights/tooltips.

A keyboard or pointer action submits the same command envelope. Require deliberate confirmation for friendly-fire area effects and irreversible end-turn/retreat choices. Cancelling a UI selection consumes nothing; a committed investigate/decoy attack consumes its real action. A reaction prompt names the one shared reaction and competing choices; declining does not spend it. Resolve pending prompts consistently when switching control.

Animations consume ordered engine events; they cannot independently damage, move, roll or expire statuses. Skip/fast-forward changes presentation time only. A spell telegraph remains visible until the authoritative resolve/cancel event. Selection and target IDs survive redraw; invalidated selections clear with a reason.

## Manual/auto transition

Switch at a stable command boundary using the same encounter/revision/observer state. No free turn, refreshed resource, altered seed or pending-spell reset. A queued but uncommitted command is discarded; committed commands finish through the same engine. Record controller switch as provenance, not a combat buff. Auto can hand control back with the same pending reaction state.

## Readability and accessibility

Follow the established retro visual/UI direction. Use readable labelled budget icons and colour-independent range/cover/hazard cues. At minimum support keyboard navigation, pointer input, tooltip focus, cancel/back and the project's normal 1280×720 display. Inspect minimum logical layout without obscuring selected action or costs. Avoid a permanent wall of rules text: show concise consequence previews and an expandable exact event/roll log.

## Acceptance evidence

- Execute a 3v3 battle using pointer and keyboard, including move+attack, dash, disengage, guard, delayed burst and an illusion interaction. Compare captured command replay hashes with headless engine hashes.
- At known boundaries switch manual→auto→manual; resource counts, reaction, initiative and observer knowledge remain identical to the engine state.
- Show screenshots/video from actual production Godot UI only once it exists. Research diagrams are not gameplay screenshot evidence.
- Reaction prompts correctly share a single budget; warning/confirmation for friendly fire names affected known allies; pending tile and resolution order are legible.
- Inspect a concealed/illusory target under two observer states; highlights, path feedback, logs and tooltips do not reveal hidden truth or secret IDs.
- Simulate stale selection/state revision, cancelled menus, save/reload and skipped animations; none causes duplicate commands, lost main actions or changed outcomes.

Out of scope: implementing a second engine, modifying AI heuristics to make screenshots succeed, final class balance, finished spell catalogue and a new combat art pipeline. Research recommendation approval does not merge this future implementation ticket.
