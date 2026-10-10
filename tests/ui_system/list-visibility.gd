extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:
 Engine.max_fps=60
 call_deferred("run")
func check(ok: bool, why: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(why)
func settle() -> void:
 for i in 6: await process_frame
func visible_selection(ui: Control, context: String) -> void:
 var list: ItemList=ui.options
 var chosen: int=list.get_selected_items()[0]
 var row := list.get_item_rect(chosen)
 var bar := list.get_v_scroll_bar()
 var panel := list.get_theme_stylebox("panel")
 var top := panel.get_content_margin(SIDE_TOP)
 var bottom := list.size.y-panel.get_content_margin(SIDE_BOTTOM)
 # ItemList item rectangles are content-local (scroll is applied by drawing).
 var y := row.position.y-bar.value
 check(y>=top-1 and y+row.size.y<=bottom+1, "selected row actually visible: "+context)
 check(ui.burg_id==int(ui.candidates[chosen].id),"visible row retains source hometown: "+context)
func run() -> void:
 change_scene_to_file("res://scenes/ui/new_game_origin.tscn")
 await settle()
 var ui: Control=current_scene
 ui.choose_world(0)
 var home := -1
 for state in ui.states():
  var candidates: Array=ui.worlds[0].home_candidates(int(state.i),-1,8)
  if candidates.size()==8:
   ui.choose_state(int(state.i))
   ui.choose_province(-1)
   home=int(candidates[-1].id)
   break
 check(home>0,"real eight-town candidate set found")
 for resolution in [Vector2i(2560,1440),Vector2i(1280,720),Vector2i(640,360)]:
  root.size=resolution
  ui.page=2
  ui.burg_id=home
  ui.show_page()
  await settle()
  visible_selection(ui,"initial last town "+str(resolution))
  ui.advance()
  await settle()
  check(ui.page==3,"confirmation shown")
  for down in [true,false]:
   var event := InputEventKey.new()
   event.keycode=KEY_ESCAPE
   event.pressed=down
   root.push_input(event)
   await process_frame
  await settle()
  check(ui.page==2 and ui.burg_id==home,"Escape preserves hometown")
  check(root.gui_get_focus_owner()==ui.options,"Back restores list keyboard focus")
  check(ui.options.get_v_scroll_bar().value>0,"compact shortlist scrolls to restored late choice")
  visible_selection(ui,"after Back "+str(resolution))
 # Also resize a live list without rebuilding the page.
 root.size=Vector2i(2560,1440)
 await settle()
 root.size=Vector2i(640,360)
 await settle()
 visible_selection(ui,"live resize")
 check(ui.saved_slot.is_empty(),"browsing/back creates no save")
 print("GAME-83 list visibility: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
