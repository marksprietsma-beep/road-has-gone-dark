# Wave Three engineering assessment

Base: main `7f2e02aea3269a9e5076f294b29c9efa0079f01e`. Wave Two PRs #96/#97 are merged and its full post-merge workflow succeeded. Historical packs v1–v12 will remain byte-for-byte unchanged.

The implementation reuses GAME-32's ordered career choices, requirements, resource pools, effects and deterministic tactical commands. Psychic powers learned through scheduled choices will remain in the existing advancement history; a derived known-power list will explain them without adding another save owner. Augmentation will select authored variants through the same ability command, with manifesting-level/cost validation. A versioned catalogue will declare tiers, disciplines and class access.

Ardent and Lurk are the first new careers. Ardent mantles restrict access and grant real capabilities; Lurk combines a smaller psychic pool with costed precision/control. A shared psychic progression formula supports multiclass characters. All of this applies only to v13.

Existing owned-creature records, legal adjacent placement, action budgets and round expiry remain authoritative. Add distinct creature actions and class choices; extend permanent bond growth through validated data rather than a second pet engine. Add form descriptors to the existing equipment suppression/reversion mechanism; power suppression must match spell suppression. Permanent companion prerequisites distinguish the beast prestige path from temporary summons. The researched Cerebremancer concept is a suitable hybrid psychic/arcane path.

Creator controls reuse bounded popups and ordered choice groups. Show power explanations, costs and eligibility; avoid presenting every augmentation variant as a separate combat button. Keep high-level development fixtures separate from ordinary earned-XP journey evidence.

Delivery gates: content/reference validation; frozen rules and historical pins; negative eligibility and exhaustion tests; creature/form replay and separate-process reload; existing creator input regressions and earned-XP journey; native Windows/Linux exports; actual Godot screenshots; current-head CI and post-merge CI. Coverage remains candidate until native gameplay is verified. No new options are claimed playable at this assessment checkpoint.

The full catalogue remains open in #82. No world, quest or map expansion is included.
