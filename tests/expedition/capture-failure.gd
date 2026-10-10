extends "res://tests/expedition/capture-flow.gd"

# Expected-failure probes for the exact render-driver lifecycle regression.
func run() -> void:
 if OS.get_environment("GAME97_CAPTURE_FAILURE") == "assertion":
  check(false,"GAME97 expected assertion failure")
 else:
  var target := Button.new()
  target.name = "OffscreenProbe"
  target.position = Vector2(-10000,-10000)
  target.size = Vector2(80,24)
  root.add_child(target)
  await click(target)
 # The inherited failure must terminate Godot; do not supply our own quit.
 while true: await process_frame
