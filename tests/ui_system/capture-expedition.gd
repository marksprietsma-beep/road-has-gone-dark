extends "res://tests/expedition/capture-flow.gd"

func _initialize() -> void:
 Engine.max_fps = 60
 output = "res://docs/implementation/game83/" + OS.get_environment("GAME83_STAGE") + "/expedition"
 super._initialize()

func wait_job() -> void:
 await super.wait_job()
 if OS.get_environment("GAME83_STAGE")!="after" or ui.state.is_empty(): return
 var focused := root.gui_get_focus_owner()
 check(focused!=null and focused.is_visible_in_tree(),"completed transition retains visible keyboard focus")

func shot(name: String) -> void:
 await super.shot(name)
 if OS.get_environment("GAME83_STAGE")!="after": return
 check(not ui.status.text.contains("verified"),"routine persistence detail removed from primary text")
 check(ui.footer.text.begins_with("Party at "),"party location uses explicit player wording")
 if ui.state.expedition.active.get("phase")=="result":
  check(ui.content.get_parent().scroll_vertical==0,"result opens at its heading rather than previous action scroll")
 var frame: Rect2=ui.map.map_rect()
 for i in ui.map.get_child_count():
  var marker: Control=ui.map.get_child(i)
  var site: Dictionary=ui.public_view.sites[i]
  var expected: Vector2=frame.position+Vector2(site.position[0],site.position[1])*frame.size/1000
  check((marker.position+marker.size/2).distance_to(expected)<0.01,"site hit target retains exact source-derived location")
  check(marker.text.is_empty() and marker.tooltip_text.contains(site.name),"semantic marker retains named keyboard/mouse target")
 if root.size.x>640: check(root.content_scale_size.x>640,"desktop uses additional layout space")
