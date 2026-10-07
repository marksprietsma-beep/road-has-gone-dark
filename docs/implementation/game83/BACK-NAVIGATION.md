# Restoring the hometown viewport

The Linux failure in run 37563269371 was reproduced against the unchanged GAME-75 input/render test: 109 checks, one failure. The selection and source burg identity survived Back. At 1280×720, however, the responsive layout gave the hometown list 200 logical units; all 192 units of content fitted, so the old regression's required positive scroll offset was zero. This was a layout/test-precondition mismatch, not a lost selection.

The hometown list is now a compact shortlist capped at 152 logical units, leaving room for its longer public memory and tradition text. Political lists still grow with the window. Every hometown remains available. Layout changes defer `ensure_current_is_visible()` until the updated list dimensions can be used, including live window resizing.

The original test and its assertion are unchanged. A diagnostic subclass records the actual viewport and runs all 109 original checks: **109 passed, zero failures**. At 1280×720 the restored seventh entry has a scroll offset of 24 and is visible within the 152-unit list.

`tests/ui_system/list-visibility.gd` additionally checks the selected row's actual rectangle, source identity, keyboard focus, Back via Escape and live resizing at 640×360, 1280×720 and 2560×1440: **28 passed, zero failures**. It also verifies that browsing creates no saved slot. This prevents a positive scrollbar value alone from being mistaken for proof of visibility.

Reproduce with Godot 4.6.3 and a display:

```sh
godot --path . --audio-driver Dummy --script tests/ui_system/back-navigation.gd
godot --path . --audio-driver Dummy --script tests/ui_system/list-visibility.gd
```
