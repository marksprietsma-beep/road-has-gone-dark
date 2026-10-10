extends "res://tests/lpc/review.gd"
## GAME95 real scene/preview, registered layout and independent frozen authority proof.
var oracle := Game94CombatOracle.new()
var layout_proof := {}
func run() -> void:
 output=OS.get_environment("GAME95_REVIEW_ROOT")
 if output.is_empty():output=ProjectSettings.globalize_path("user://game95-review-proof")
 DirAccess.make_dir_recursive_absolute(output);visual=DisplayServer.get_name()!="headless"
 var provenance: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/battlefields/oracle-provenance.json"))
 check(FileAccess.get_sha256("res://tests/battlefields/game94-oracle.gd")==provenance.test_snapshot_sha256,"independent GAME94 authority snapshot unchanged")
 source=RulesJson.normalize(JSON.parse_string(FileAccess.get_file_as_string("res://tests/lpc/generated-party.json")))
 source.characters=source.party_ids.map(func(id: String):return {"id":id})
 for id in source.party_ids:
  var record: Dictionary=source.mechanics.records[id]
  record.runtime.hp=int(engine.characters.derive_character(record).snapshot.stats.HP);record.runtime.statuses=[]
 var frozen_bytes := RulesJson.canonical(source)
 # Before mechanics are committed, use the existing pure build preparation on a copy.
 var draft: Dictionary=source.duplicate(true);draft.erase("mechanics");draft.party.status="draft"
 var draft_bytes := RulesJson.canonical(draft)
 var preview_units := CombatArt.party_units(draft)
 check(preview_units.size()==3 and RulesJson.canonical(draft)==draft_bytes,"draft preview does not prepare/save the campaign")
 var ready_copy: Dictionary=draft.duplicate(true);ready_copy.party.status="ready"
 var prepared := RulesRecords.preview_preparation(ready_copy)
 for member in draft.party.members:
  check(preview_units[member.character_id].record==prepared.candidate.mechanics.records[member.character_id],"preview uses actual preparation calculation")
 check(engine.create(source,source.site_id,"unknown").is_empty(),"unregistered/unbounded layouts rejected")
 for layout in CombatBattlefields.PATHS:
  var b := engine.create(source,source.site_id,layout)
  check(not b.is_empty() and engine.validate(b).is_empty(),"valid registered mechanical layout "+layout)
  check(b==engine.create(source,source.site_id,layout),"deterministic spawn/layout creation")
  check(b.rng==engine.create(source,source.site_id,CombatBattlefields.LEGACY).rng,"layout does not change original seed recipe")
  var board_copy: Dictionary=b.duplicate(true);board_copy.board.width+=1;board_copy=engine.seal(board_copy)
  check(not engine.validate(board_copy).is_empty(),"unregistered/tampered board rejected despite recalculated state hash")
  var original := RulesJson.canonical(b);var replay := b.duplicate(true);var old_replay := b.duplicate(true)
  var command_count := 0
  for i in 240:
   if replay.status!="active":break
   var command := engine.enemy_command(replay)
   check(command==oracle.enemy_command(old_replay),"new layout AI order identical to frozen GAME94 logic")
   var next := engine.command(replay,command);var old_next := oracle.command(old_replay,command)
   check(next==old_next and next.ok,"entire result/log/RNG/budget identical to frozen authority")
   replay=next.battle;old_replay=old_next.battle;command_count+=1
   var saved: Dictionary=RulesJson.normalize(JSON.parse_string(JSON.stringify(replay)))
   check(engine.validate(saved).is_empty() and RulesJson.canonical(saved)==RulesJson.canonical(replay),"every command survives JSON save/reload")
  check(replay.status!="active","authored layout reaches an outcome")
  check(RulesJson.canonical(b)==original,"replay never mutates initial state")
  layout_proof[layout]={"initial_hash":b.state_hash,"final_hash":replay.state_hash,"outcome":replay.status,"commands":command_count,"dimensions":[b.board.width,b.board.height],"rng_counter":replay.rng.counter}
 # Real party UI: same three generated identities, prepared gear and front-facing layers.
 PartyService.handoff={"entry":{},"slot":"isolated-preview"}
 var party: Control=load("res://scenes/ui/party_creation.tscn").instantiate();root.add_child(party);current_scene=party;party.set_process(false)
 party.state=source;party.ready_view=false;party.message="Same generated party · saved identities";party.refresh()
 party.origin.text="Party review · same Gaabuba, Luke and Hodbruth identities"
 var preview_recipes: Dictionary=party.preview_recipes.duplicate(true)
 check(preview_recipes.size()==3,"three actual generated paper-doll previews")
 for size in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  root.size=size;await settle();await settle()
  check(party.roster.get_item_rect(2).end.y<=party.roster.size.y,"three preview rows visible")
  check(party.finish_button.get_global_rect().end.y<=root.get_visible_rect().size.y,"party footer fits")
  for i in party.roster.rows.size():
   var row: Button=party.roster.rows[i];var portrait: TextureRect=row.get_child(0).get_child(0)
   check(portrait.texture!=null and portrait.texture.get_width()==64,"real native LPC thumbnail")
   var labels: VBoxContainer=row.get_child(0).get_child(1)
   check(labels.get_child(1).size.y>=28,"people/calling metadata has two readable lines")
  ui=party;await shot("party-after-%dx%d"%[size.x,size.y])
 # Existing keyboard/mouse contract remains; selection is presentation only here.
 party.roster.grab_focus()
 var key := InputEventKey.new();key.keycode=KEY_DOWN;key.pressed=true;root.push_input(key,true);await settle()
 check(party.selected==2,"roster keyboard selection")
 party.roster.rows[2].pressed.emit();await settle();check(party.selected==3,"roster mouse/activation selection")
 party.refresh();check(party.preview_recipes==preview_recipes,"preview stable across refresh/selection")
 check(RulesJson.canonical(source)==frozen_bytes,"party icons never change saved identities/mechanics")
 party.queue_free();await process_frame
 ui=load("res://scenes/combat/first_adventure.tscn").instantiate();root.add_child(ui);current_scene=ui;ui.set_process(false)
 for layout in CombatBattlefields.PATHS:
  initial=engine.create(source,source.site_id,layout)
  for size in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
   root.size=size;await apply(initial);await settle()
   check(ui.grid.columns==initial.board.width and ui.tiles.size()==initial.board.width*initial.board.height,"dynamic columns/rows/hitboxes")
   check(ui.grid.get_global_rect().end.x<=root.get_visible_rect().size.x,"board width fits")
   check(ui.grid.get_global_rect().end.y<=ui.targeting.get_global_rect().position.y,"target feedback below board")
   check(ui.end_button.get_global_rect().end.y<=root.get_visible_rect().size.y,"combat footer fits")
   for y in int(initial.board.height):
    for x in int(initial.board.width):
     var p := [x,y];var tile: BattlefieldTile=ui.tiles[str(p)]
     check(tile.terrain_blocked==engine.blocked(initial,p),"painted blocking agrees with authority")
     check(tile.get_global_rect().has_point(tile.get_global_rect().get_center()),"accurate actual tile hitbox")
     check(tile.size==Vector2(ui.tile_side,ui.tile_side),"uniform known animation pitch")
   for id in preview_recipes:check(ui.pawns[id].recipe.recipe_hash==preview_recipes[id],"paper doll exactly matches combat recipe")
   var before := RulesJson.canonical(initial)
   ui.select_mode("move");await settle()
   var actor := engine.current(initial);var paths := engine.paths(initial,actor)
   for y in int(initial.board.height):
    for x in int(initial.board.width):
     var p := [x,y];var expected: bool=paths.has(str(p)) and actor.position!=p
     check(ui.tiles[str(p)].move_tile==expected,"movement highlights use authority on every map")
   check(RulesJson.canonical(ui.battle())==before,"terrain/highlights never change battle/RNG")
   ui.select_mode("attack");await settle();await shot("%s-%dx%d"%[layout,size.x,size.y])
 initial=engine.create(source,source.site_id,CombatBattlefields.DEFAULT);root.size=Vector2i(1280,720);await apply(initial)
 var scout: String=source.party_ids[1]
 var walking := initial.duplicate(true);walking.cursor=walking.order.find(scout);walking=engine.seal(walking)
 var move := {"revision":0,"actor_id":scout,"kind":"move","destination":[6,4]}
 var moved := engine.command(walking,move);check(moved.ok,"real three-tile move on new Old Road")
 await capture("movement",{"before":walking,"after":moved.battle,"command":move},"move")
 await capture("melee",trial("attack",source.party_ids[0],"bandit-blade"),"slash")
 await capture("ranged",trial("attack",scout,"bandit-bow"),"shoot")
 var staff := controlled(source.party_ids[2]);staff.units["bandit-blade"].position=[2,4];staff=engine.seal(staff)
 var staff_result := {}
 for i in 100:
  staff.rng=RulesRng.initial("game94-staff-"+str(i));staff=engine.seal(staff)
  var c := {"revision":0,"actor_id":source.party_ids[2],"kind":"attack","target_id":"bandit-blade"}
  var r := engine.command(staff,c)
  if r.ok and r.battle.units["bandit-blade"].record.runtime.hp<staff.units["bandit-blade"].record.runtime.hp:staff_result={"before":staff,"after":r.battle,"command":c};break
 await capture("staff",staff_result,"thrust")
 await capture("spell",trial("spark",source.party_ids[2],"bandit-blade"),"spell")
 await capture("miss",trial("attack",source.party_ids[0],"bandit-blade","miss"),"slash")
 await capture("defeat",trial("attack",source.party_ids[0],"bandit-blade","down"),"slash")
 for event in cases:
  check(event.samples.any(func(s: Dictionary):return s.clip=="idle"),"action recovers rather than leaving stale actor")
 # Save/reload through a fresh actual scene; visual waits are not authoritative fields.
 var saved: Dictionary=RulesJson.normalize(JSON.parse_string(JSON.stringify(initial)))
 ui.queue_free();await process_frame
 ui=load("res://scenes/combat/first_adventure.tscn").instantiate();root.add_child(ui);current_scene=ui;ui.set_process(false);await apply(saved)
 check(not ui.is_presenting(),"save resume has no stale presentation gate")
 for id in preview_recipes:check(ui.pawns[id].recipe.recipe_hash==preview_recipes[id],"appearance stable after scene/save reload")
 var proof := {"suite":"GAME95 party/terrain/pacing","platform":OS.get_name(),"visual":visual,"checks":checks,"failures":failures,"layouts":layout_proof,"preview_recipes":preview_recipes,"initial_hash":initial.state_hash,"cases":cases,"timing":{"tile_seconds":CombatPacing.TILE_SECONDS,"projectile_seconds":CombatPacing.PROJECTILE_SECONDS,"max_beat_seconds":CombatPacing.MAX_BEAT_SECONDS}}
 FileAccess.open(output.path_join("game95-proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof,"  ")+"\n")
 print("GAME95 LIVE PROOF ",checks," checks / ",failures," failures; layouts ",layout_proof.keys(),"; animation cases ",cases.size());quit(1 if failures else 0)
