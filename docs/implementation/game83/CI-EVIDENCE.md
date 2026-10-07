# Cross-platform verification and review build

Implementation SHA: `bfbdf48b4ae26dd1fc516cd8641177ee63fc4bd5`.

The final source run is [37599062997](https://github.com/marksprietsma-beep/road-has-gone-dark/actions/runs/37599062997). Windows and Linux are in progress at this evidence checkpoint. This record will be completed with native artifact links and checksums before handoff; no pending job is being reported as passed.

The complete Windows artifact is named `game83-complete-Windows`. It contains the application, matching offline helper and checksums. Extract the artifact, then its inner game archive, keeping the helper beside the executable. No separately installed Node or Godot is required.

The earlier run 37563269371 passed Windows and native packaging but failed the reproduced Linux Back assertion. It is superseded, not the final review build. Intermediate runs 37598570153 and 37598913776 were cancelled after small visual-review corrections; they are not claimed as successful verification.
