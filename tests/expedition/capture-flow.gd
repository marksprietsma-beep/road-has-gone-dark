extends SceneTree
var checks:=0
var failures:=0
var ui: Control
var output: String="res://docs/implementation/game84/screenshots"
var base: String
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(why)
func _initialize() -> void: call_deferred("run")
func frames() -> void:
 for i in 5: await process_frame
 await RenderingServer.frame_post_draw
func key(code: int) -> void:
 for down in [true,false]:
  var e:=InputEventKey.new()
  e.keycode=code;e.pressed=down
  root.push_input(e)
  await process_frame
 await frames()
func click(control: Control) -> void:
 await frames()
 for down in [true,false]:
  var e:=InputEventMouseButton.new()
  e.button_index=MOUSE_BUTTON_LEFT
  e.position=control.get_global_rect().get_center()
  e.pressed=down
  root.push_input(e,true)
 await frames()
func wait_job() -> void:
 var deadline:=Time.get_ticks_msec()+180000
 while ui.thread!=null and Time.get_ticks_msec()<deadline: await process_frame
 check(ui.thread==null and not ui.state.is_empty() and ui.message.is_empty(),"real async save/generation: "+ui.message)
 await frames()
func shot(name: String) -> void:
 # Allow font-atlas uploads and resized canvas layout to settle on software GL.
 for i in 60:await process_frame
 await frames()
 check(ui.menu_button.get_global_rect().end.y<=root.get_visible_rect().size.y-4,"footer fits: "+name)
 check(ui.map.size.y>=200,"map has useful space: "+name)
 check(not ui.status.text.contains("ERROR"),"no false-success/error text")
 var picture:=root.get_texture().get_image()
 var scale:=Vector2(picture.get_size())/root.get_visible_rect().size
 for heading in [ui.title,ui.reminder,ui.status]:
  var rect:=Rect2i(Rect2(heading.get_global_rect().position*scale,heading.size*scale))
  var ink:=0
  for y in range(rect.position.y,mini(rect.end.y,picture.get_height())):
   for x in range(rect.position.x,mini(rect.end.x,picture.get_width())):
    if x>=0 and y>=0 and picture.get_pixel(x,y).r>0.3:ink+=1
  check(ink>heading.text.length()*5*scale.x*scale.y,"actual header ink after rendering: "+name)
 picture.save_png(output.path_join(name+".png"))
func mount(entry: Dictionary,slot: String) -> void:
 PartyService.handoff={"entry":entry,"slot":slot,"save_root":base.path_join("saves"),"library_root":base.path_join("library"),"cache_root":base.path_join("cache")}
 change_scene_to_file("res://scenes/gameplay/expedition.tscn")
 while current_scene==null or current_scene.scene_file_path!="res://scenes/gameplay/expedition.tscn": await process_frame
 ui=current_scene
 await wait_job()
func run() -> void:
 base=OS.get_environment("GAME84_TEST_ROOT")
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
 var service:=ExpeditionService.new()
 service.library.library_root=base.path_join("library")
 service.store.save_root=base.path_join("saves")
 service.library.save_root=service.store.save_root
 service.cache_root=base.path_join("cache")
 var entries:=service.library.discover()
 var candidates: Array=[]
 for name in DirAccess.get_files_at(service.store.save_root):
  if not name.ends_with(".json"): continue
  var state:=WorldOriginLore.read_json(service.store.save_root.path_join(name))
  if state.get("expedition",{}).get("revision")==1: candidates.append(state)
 check(candidates.size()>=2,"independent unplayed campaigns available")
 if candidates.is_empty():quit(1);return
 var pristine: Dictionary=candidates[0]
 var slot: String=pristine.playthrough_id
 var entry: Dictionary=entries.filter(func(e: Dictionary):return e.id==pristine.world_ref.id)[0]
 root.size=Vector2i(1280,720)
 PartyService.handoff={"entry":entry,"slot":slot,"save_root":base.path_join("saves"),"library_root":base.path_join("library"),"cache_root":base.path_join("cache")}
 change_scene_to_file("res://scenes/ui/party_creation.tscn")
 while current_scene==null or current_scene.scene_file_path!="res://scenes/ui/party_creation.tscn":await process_frame
 ui=current_scene
 while ui.thread!=null:await process_frame
 check(ui.ready_view,"actual persisted party-ready screen")
 await frames()
 root.get_texture().get_image().save_png(output.path_join("party-ready-handoff.png"))
 await click(ui.finish_button)
 while current_scene==null or current_scene.scene_file_path!="res://scenes/gameplay/expedition.tscn":await process_frame
 ui=current_scene
 await wait_job()
 if ui.state.is_empty():quit(1);return
 check(ui.state.party_ids==pristine.party_ids,"Enter hometown button carries the same three adventurers")
 for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  root.size=resolution
  root.content_scale_size=Vector2i(640,360)
  var file:=FileAccess.open(service.store._slot_path(slot),FileAccess.WRITE)
  file.store_string(JSON.stringify(pristine,"  "))
  file.close()
  await mount(entry,slot)
  var suffix: String="-%dx%d"%[resolution.x,resolution.y]
  await shot("hometown"+suffix)
  var known: String=ui.public_view.leads[0].id
  await click(ui.action_buttons[known])
  check(ui.action_buttons.has("accept"),"mouse selection exposes accepted-lead action")
  await shot("lead"+suffix)
  if resolution==Vector2i(1280,720):await shot("known-site-map")
  await click(ui.action_buttons.leads)
  var rumour: String=ui.public_view.leads[1].id
  await click(ui.action_buttons[rumour])
  await click(ui.action_buttons.accept)
  await wait_job()
  ui.action_buttons.depart.grab_focus()
  var focused: Control=root.gui_get_focus_owner()
  await key(KEY_TAB)
  check(root.gui_get_focus_owner()!=focused,"Tab moves actual keyboard focus")
  await key(KEY_UP)
  check(root.gui_get_focus_owner()!=null,"arrow navigation retains an actionable control")
  ui.action_buttons.depart.grab_focus()
  await key(KEY_ENTER)
  await wait_job()
  check(ui.state.expedition.active.phase=="map","keyboard depart enters actual local map")
  check(ui.public_view.sites.size()==2,"rumoured location has no marker")
  await shot("rumour-before"+suffix)
  await click(ui.action_buttons.scout)
  await wait_job()
  check(ui.public_view.sites.size()==3,"scouting adds discovered marker")
  await shot("rumour-discovered"+suffix)
  check(ui.map.get_child_count()==3,"only known locations are interactive markers")
  await click(ui.map.get_child(1))
  await click(ui.action_buttons.travel)
  await wait_job()
  check(ui.state.expedition.active.phase=="site","mouse travel reaches site")
  await shot("site-options"+suffix)
  ui.action_buttons.leave.grab_focus()
  await frames()
  var scroll: ScrollContainer=ui.content.get_parent()
  check(ui.action_buttons.leave.get_global_rect().end.y<=scroll.get_global_rect().end.y,"keyboard focus reveals the fourth/withdrawal option")
  ui.action_buttons.survey.grab_focus()
  await frames()
  await click(ui.action_buttons.survey)
  await wait_job()
  check(ui.state.expedition.active.phase=="result" and ui.state.expedition.leads.size()==4,"actual consequence and new rumour")
  await shot("consequence"+suffix)
  await key(KEY_ESCAPE)
  await frames()
  check(current_scene.scene_file_path=="res://scenes/ui/main_menu.tscn","Escape returns to menu without losing progress")
  var menu: Control=current_scene
  menu.refresh_party_resume(service)
  check(menu.menu_content.get_node("ResumePartyButton").text=="Resume Expedition","main menu recognises active expedition")
  check(menu.party_resume.slot==slot,"latest validated campaign selected")
  if resolution==Vector2i(1280,720):
   await frames()
   root.get_texture().get_image().save_png(output.path_join("main-menu-resume-expedition.png"))
  await click(menu.menu_content.get_node("ResumePartyButton"))
  while current_scene==null or current_scene.scene_file_path!="res://scenes/gameplay/expedition.tscn": await process_frame
  ui=current_scene
  await wait_job()
  check(ui.state.expedition.active.phase=="result","actual scene reload resumes consequence")
  await shot("resumed-result"+suffix)
  await click(ui.action_buttons["return"])
  await wait_job()
  check(ui.state.expedition.active.is_empty() and ui.state.expedition.leads[1].status=="completed","return home persists completed lead")
  await shot("returned-hometown"+suffix)
 # At least one genuinely fresh source world is shown, never a fixture substitute.
 var fresh: Array=candidates.filter(func(s: Dictionary):return s.world_ref.seed.begins_with("game84-expedition-"))
 if not fresh.is_empty():
  var state: Dictionary=fresh[0]
  var e: Dictionary=entries.filter(func(x: Dictionary):return x.id==state.world_ref.id)[0]
  await mount(e,state.playthrough_id)
  for i in 60:await process_frame
  await shot("fresh-generated-world")
 print("GAME-84 real input/render: ",checks," checks, ",failures," failures")
 quit(1 if failures else 0)
