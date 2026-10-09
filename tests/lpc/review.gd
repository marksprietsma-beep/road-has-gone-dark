extends SceneTree
## Actual production scene, resolved commands; isolated fixtures never write campaign saves.
var engine := TacticalCombat.new()
var source := {}
var initial := {}
var ui: Control
var output: String
var visual := false
var checks := 0
var failures := 0
var cases := []
func _initialize() -> void:call_deferred("run")
func check(value: bool, why: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(why)
func settle() -> void:
 for i in 8:await process_frame
 if visual:await RenderingServer.frame_post_draw
func shot(name: String) -> void:
 if visual:
  await RenderingServer.frame_post_draw
  check(root.get_texture().get_image().save_png(output.path_join(name+".png"))==OK,"real viewport capture "+name)
func apply(b: Dictionary) -> void:
 ui.state=source.duplicate(true);ui.state.first_adventure={"battle":b,"result":{}}
 ui.message="";ui.refresh();await settle()
func controlled(actor: String) -> Dictionary:
 var b: Dictionary=initial.duplicate(true)
 b.units[source.party_ids[0]].position=[2,2]
 b.units[source.party_ids[1]].position=[1,3]
 b.units[source.party_ids[2]].position=[1,4]
 b.units["bandit-blade"].position=[3,2];b.units["bandit-bow"].position=[6,3]
 b.cursor=b.order.find(actor);return engine.seal(b)
func trial(kind: String, actor: String, target: String, result_kind: String="hit") -> Dictionary:
 var b := controlled(actor)
 if kind=="spark":b.units[target].position=[3,4]
 if result_kind=="down":b.units[target].record.runtime.hp=1
 for i in 100:
  # Authored diagnostic seeds only; presentation never uses this or changes a command.
  b.rng=RulesRng.initial("game94-animation-"+result_kind+"-"+str(i));b=engine.seal(b)
  var command := {"revision":b.revision,"actor_id":actor,"kind":kind,"target_id":target}
  var result := engine.command(b,command)
  if not result.ok:check(false,"legal animation fixture: "+str(result));return {}
  var delta: int=int(result.battle.units[target].record.runtime.hp)-int(b.units[target].record.runtime.hp)
  if (result_kind=="miss" and result.battle.log.back().ends_with(", miss.")) or (result_kind=="down" and not engine.alive(result.battle.units[target])) or (result_kind=="hit" and delta<0):
   return {"before":b,"after":result.battle,"command":command}
 check(false,"diagnostic resolved outcome exists");return {}
func capture(name: String, event: Dictionary, clip: String) -> void:
 if event.is_empty():return
 await apply(event.before)
 var actor: String=event.command.actor_id
 var old_pawn: CombatPawn=ui.pawns[actor]
 var before_bytes := RulesJson.canonical(event.before)
 await apply(event.after)
 check(ui.pawns[actor]==old_pawn,"refresh retains actual pawn/timeline")
 ui.animate_committed(event.before);await process_frame;await process_frame
 var committed := RulesJson.canonical(ui.battle());var samples := []
 var observed_frames := {};var feedbacks := [];var positions := {}
 for i in 40:
  await create_timer(0.05).timeout
  if visual:await shot("%s-%03d"%[name,i])
  var pawn: CombatPawn=ui.pawns[actor]
  var layer: Dictionary=pawn.recipe.animations[pawn.animation][0]
  var frame := pawn.frame_index(layer)
  if pawn.animation==clip:observed_frames[frame]=true
  positions[str(pawn.travel)]=true
  var reactions := {}
  for id in ui.pawns:
   var p: CombatPawn=ui.pawns[id]
   if not p.feedback.is_empty():feedbacks.append(p.feedback)
   reactions[id]={"clip":p.animation,"feedback":p.feedback,"hp":p.display_hp,"down":p.down}
  samples.append({"index":i,"clip":pawn.animation,"frame":frame,"facing":pawn.facing,"travel":[pawn.travel.x,pawn.travel.y],"targets":reactions})
 check(observed_frames.size()>=2,"native frames advance in live "+clip)
 check(RulesJson.canonical(ui.battle())==committed,"animation cannot change committed battle/log/RNG")
 check(RulesJson.canonical(event.before)==before_bytes,"animation cannot mutate previous authority")
 check(engine.validate(ui.battle()).is_empty(),"resolved diagnostic battle remains valid")
 if name=="movement":
  check(positions.size()>=3 and ui.pawns[actor].travel==Vector2.ZERO,"actual multi-tile interpolation settles")
  check(ui.pawns[actor].facing==3,"actual route faces east")
 if name=="miss":check(feedbacks.has("MISS"),"resolved miss shown distinctly")
 elif name!="movement":check(feedbacks.any(func(text: String):return text.begins_with("−")),"resolved damage feedback captured")
 if name=="defeat":
  var target: CombatPawn=ui.pawns[event.command.target_id]
  check(target.animation=="down" and target.frame_index(target.recipe.animations.down[0])==5,"native defeat freezes rather than idles")
  check(target.display_hp==0,"defeat HP settles")
 cases.append({"name":name,"command":event.command,"before_hash":event.before.state_hash,"after_hash":event.after.state_hash,"native_frames":observed_frames.keys(),"samples":samples})
func run() -> void:
 output=OS.get_environment("GAME94_LPC_ROOT")
 if output.is_empty():output=ProjectSettings.globalize_path("user://game94-lpc-proof")
 DirAccess.make_dir_recursive_absolute(output)
 visual=DisplayServer.get_name()!="headless"
 source=RulesJson.normalize(JSON.parse_string(FileAccess.get_file_as_string("res://tests/lpc/generated-party.json")))
 for id in source.party_ids:
  var record: Dictionary=source.mechanics.records[id]
  record.runtime.hp=int(engine.characters.derive_character(record).snapshot.stats.HP);record.runtime.statuses=[]
 initial=engine.create(source,source.site_id)
 check(initial.state_hash=="8ceb714a7c8fd390e23c3ef1a149ba1cd0f67b0d6d9d3bd96a9a02bbc6b11244","same generated party/encounter as PR72 baseline")
 check(engine.validate(initial).is_empty(),"unchanged authored 8x6 board")
 ui=load("res://scenes/combat/first_adventure.tscn").instantiate();root.add_child(ui);current_scene=ui;ui.set_process(false)
 root.size=Vector2i(1280,720);await apply(initial)
 var recipes := {};for id in ui.pawns:recipes[id]=ui.pawns[id].recipe.recipe_hash
 for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  root.size=resolution;await settle();await settle()
  check(ui.tiles.size()==48,"8x6 tile hitboxes")
  check(ui.end_button.get_global_rect().end.y<=root.size.y,"footer fits "+str(resolution))
  check(ui.grid.get_global_rect().end.x<=root.size.x,"board fits "+str(resolution))
  for tile in ui.tiles.values():check(tile.get_global_rect().has_point(tile.get_global_rect().get_center()),"accurate tile centre")
  await shot("after-%dx%d"%[resolution.x,resolution.y])
  if visual:
   # One real-render closeup per persistent identity, with source pixels intact.
   var image := root.get_texture().get_image()
   for id in ui.pawns:
    var rect: Rect2=ui.pawns[id].get_global_rect()
    image.get_region(Rect2i(rect)).save_png(output.path_join("closeup-%s-%dx%d.png"%[id.replace(":","-"),resolution.x,resolution.y]))
  ui.show_art_credits();await settle()
  for node in ui.get_children():
   if node is AcceptDialog:
    check(node.size.x<=root.size.x and node.size.y<=root.size.y,"credits dialog fits small/large viewport")
    if resolution.x==640:await shot("credits-640x360")
    node.queue_free()
 root.size=Vector2i(1280,720);await settle()
 var scout: String=source.party_ids[1]
 var walking := initial.duplicate(true);walking.cursor=walking.order.find(scout);walking=engine.seal(walking)
 var move := {"revision":0,"actor_id":scout,"kind":"move","destination":[4,2]}
 var moved := engine.command(walking,move);check(moved.ok,"actual legal movement command")
 await capture("movement",{"before":walking,"after":moved.battle,"command":move},"move")
 await capture("melee",trial("attack",source.party_ids[0],"bandit-blade"),"slash")
 await capture("ranged",trial("attack",scout,"bandit-bow"),"shoot")
 # Staff reach is one tile; reposition target only in the isolated diagnostic.
 var staff := controlled(source.party_ids[2]);staff.units["bandit-blade"].position=[2,4];staff=engine.seal(staff)
 var staff_result := {}
 for i in 100:
  staff.rng=RulesRng.initial("game94-staff-"+str(i));staff=engine.seal(staff)
  var c := {"revision":0,"actor_id":source.party_ids[2],"kind":"attack","target_id":"bandit-blade"}
  var r := engine.command(staff,c)
  if r.ok and r.battle.units["bandit-blade"].record.runtime.hp<staff.units["bandit-blade"].record.runtime.hp:staff_result={"before":staff,"after":r.battle,"command":c};break
 check(not staff_result.is_empty(),"actual staff hit command")
 await capture("staff",staff_result,"thrust")
 await capture("spell",trial("spark",source.party_ids[2],"bandit-blade"),"spell")
 await capture("miss",trial("attack",source.party_ids[0],"bandit-blade","miss"),"slash")
 await capture("defeat",trial("attack",source.party_ids[0],"bandit-blade","down"),"slash")
 # Rapid action refresh cancels visuals while authoritative HP always converges.
 var death: Dictionary=ui.battle().duplicate(true);var pawn: CombatPawn=ui.pawns[source.party_ids[0]]
 pawn.play_action("attack",Vector2.LEFT);ui.select_mode("move")
 check(ui.pawns[pawn.unit.id]==pawn and pawn.animation=="slash","harmless mode refresh preserves native animation")
 pawn.play_action("attack",Vector2.RIGHT);pawn.animate_route([Vector2(-80,0),Vector2.ZERO]);await create_timer(1.3).timeout
 check(pawn.animation=="idle" and pawn.travel==Vector2.ZERO and pawn.impulse==Vector2.ZERO,"rapid action/movement leaves no stale pose")
 check(RulesJson.canonical(ui.battle())==RulesJson.canonical(death),"rapid visual input leaves authoritative state unchanged")
 # Rebuild the actual scene from serialized state to exercise appearance persistence.
 var saved: Dictionary=RulesJson.normalize(JSON.parse_string(JSON.stringify(initial)))
 ui.queue_free();await process_frame
 ui=load("res://scenes/combat/first_adventure.tscn").instantiate();root.add_child(ui);current_scene=ui;ui.set_process(false);await apply(saved)
 for id in recipes:check(ui.pawns[id].recipe.recipe_hash==recipes[id],"saved identity restores full appearance")
 var proof := {"suite":"GAME94 live LPC animation","platform":OS.get_name(),"visual":visual,"checks":checks,"failures":failures,"initial_hash":initial.state_hash,"recipes":recipes,"cases":cases}
 FileAccess.open(output.path_join("lpc-proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof,"  ")+"\n")
 print("LPC LIVE PROOF ",checks," checks / ",failures," failures, actual commands: ",cases.size());quit(1 if failures else 0)
