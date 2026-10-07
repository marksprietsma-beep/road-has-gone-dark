extends "res://tests/origin_context/capture-context.gd"
## Execute the existing regression unchanged and expose the actual row viewport.
func _initialize() -> void:
 output="res://docs/implementation/game83/back-navigation"
 super._initialize()

func check(value: bool, reason: String) -> void:
 if reason=="Back reveals selected name below the initial list viewport":
  var ui: Control=current_scene
  var selected: int=ui.options.get_selected_items()[0]
  var bar: VScrollBar=ui.options.get_v_scroll_bar()
  print("BACK_VIEWPORT ",JSON.stringify({"selected":selected,"list_size":[ui.options.size.x,ui.options.size.y],"row":str(ui.options.get_item_rect(selected)),"scroll":bar.value,"page":bar.page,"maximum":bar.max_value,"canvas":str(root.content_scale_size)}))
 super.check(value,reason)
