# Creator popup regression

Current-head Linux party/UI/rules aggregate jobs failed seven unchanged GAME81 assertions on712b5b1. The failed checks concerned Human/Orc popup opening, keyboard focus/selection and the deliberate Wizard INT/skill/preparation dependency. Raw logs are retained outside the checkout and final evidence will reference the original jobs.

The21-entry ancestry popup grows over its opener. A focused production-scene experiment reproduces opening on mouse press and immediate accidental Dwarf selection on release. It occurs with both Viewport-injected test events and normal Input.parse_input_event events; merely adding pointer motion or frames does not fix it. Bounding popup height keeps the menu open in all three cases.

The existing shared GameUI now constrains creator/build OptionButton popup height to42% of window height,96–300 pixels, before opening. Godot provides scrolling; all options, metadata and keyboard navigation remain. No rule/save/action logic or test assertion is changed.

The unchanged full actual-input/render flow passes182 fresh-campaign checks and141 pinned-legacy checks on Linux after the correction. A preliminary local-only run passed the input portion but lacked the generated-world fixture required by the final section; the complete rerun used cached original generated worlds and passed. No original world was regenerated to hide a failure.

Current implementation3eca310 passed both Windows/Linux native matrices and all three inherited rules/party/UI aggregate workflows. See DELIVERY.md and retained failed logs plus passing proofs.
