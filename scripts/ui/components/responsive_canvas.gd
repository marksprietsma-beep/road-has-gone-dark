extends Node
## Keep 640×360 usable, add layout room at larger sizes, and bound reading scale.
## Attached only to player screens; the intro keeps its original viewport policy.
var window: Window
func _ready() -> void:
 window = get_window()
 window.min_size = Vector2i(640, 360)
 window.size_changed.connect(update_size)
 update_size()
func update_size() -> void:
 if not is_instance_valid(window): return
 var physical := Vector2(window.size)
 var ratio := minf(physical.x / 640.0, physical.y / 360.0)
 var reading_scale := clampf(sqrt(maxf(1.0, ratio)), 1.0, 2.0)
 var canvas := Vector2i(roundi(physical.x / reading_scale), roundi(physical.y / reading_scale))
 if window.content_scale_size != canvas: window.content_scale_size = canvas
func _exit_tree() -> void:
 if is_instance_valid(window) and window.size_changed.is_connected(update_size): window.size_changed.disconnect(update_size)
