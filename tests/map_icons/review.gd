extends "res://tests/sandbox/review-flow.gd"
## Executes production map controls; render fixtures are separate from live campaign proof.
class MissingProvider extends MapIconProvider:
 func texture_for(_role: String) -> Texture2D:return null
var mappings: Array=[]
func run() -> void:
 base=OS.get_environment("GAME98_TEST_ROOT")
 visual=DisplayServer.get_name()!="headless"
 proof={"platform":OS.get_name(),"visual":visual,"source_helper_override":not OS.get_environment("GAME76_HELPER_ROOT").is_empty(),"empty_path":OS.get_environment("PATH").is_empty(),"regions":[]}
 DirAccess.make_dir_recursive_absolute(base)
 tree.create_timer(600).timeout.connect(func():push_error("GAME98 watchdog");tree.quit(1))
 var icons:=MapIconProvider.new()
 for role in MapIconProvider.ROLES+MapIconProvider.MARKER_TYPES+["unidentified"]:
  var resolved: String=MapIconRoles.marker(role) if role in MapIconProvider.MARKER_TYPES else role
  var texture:=icons.texture_for(resolved)
  check(texture!=null and not texture.get_image().is_empty(),"actual approved SVG decodes: "+resolved)
 check(icons.errors.is_empty(),"no unavailable approved icons")
 check(icons.texture_for("unsupported-body-of-fiction")==null,"undeclared role cannot borrow artwork")
 for kind in ["camp","clearing","roadside","dangerous_woods"]:check(MapIconRoles.site(kind)=="encounters","no unsupported sacred/bridge/fort meaning")
 check(MapIconRoles.site("unknown-fiction")=="unidentified","neutral unknown semantic fallback")
 for role in MapIconRoles.data().settlement_roles:check(MapIconRoles.settlement({"group":role})==role,"source settlement role "+role)
 var specs: Array=JSON.parse_string(FileAccess.get_file_as_string(base.path_join("contexts.json")))
 for index in specs.size():await region(specs[index],index)
 await existing_campaign()
 proof.regions=mappings
 proof.checks=checks;proof.failures=failures
 FileAccess.open(base.path_join("map-icons-proof.json"),FileAccess.WRITE).store_string(JSON.stringify(proof,"  ")+"\n")
 print("GAME98 ICON PROOF ",checks," checks / ",failures," failures; six regions, all resolutions, existing campaign")
 tree.quit(1 if failures else 0)
func region(spec: Dictionary,index: int) -> void:
 var w:=GameWorldTemplate.new();check(w.load_fixture(spec.world),w.error)
 var packet: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.packet))
 var generated:=SandboxGenerator.generate(w,int(spec.home_id),packet.content)
 var original:=RulesJson.digest(generated)
 var knowledge: Dictionary={};var results: Dictionary={}
 for i in generated.sites.size():knowledge[generated.sites[i].id]="rumoured" if i==1 else "discovered"
 var record: Dictionary={"base":generated,"knowledge":knowledge,"results":results}
 var projection:=SandboxRecords.projection(record)
 check(projection.sites.size()==3,"rumour omitted by established public projection")
 var home:=MapIconRoles.home(w.get_record("burg",int(spec.home_id)))
 var sheet:=Control.new();sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);tree.root.add_child(sheet)
 var background:=ColorRect.new();background.color=Color("101410");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);sheet.add_child(background)
 var title:=GameUI.label(str(spec.home_name)+" · "+str(spec.biome),16);title.position=Vector2(12,8);title.size=Vector2(620,30);sheet.add_child(title)
 var legend:=GameUI.label("Production expedition map component\nParchment icon = known site\nGold rim = selected destination\nPennant = party · Tick = completed\n\n"+"\n".join(projection.sites.map(func(s: Dictionary):return str(s.name))),12)
 legend.position=Vector2(386,50);legend.size=Vector2(242,285);sheet.add_child(legend)
 var map: Variant=load("res://scripts/expedition/expedition_map.gd").new();map.position=Vector2(12,42);map.size=Vector2(360,306);sheet.add_child(map)
 var seen: Array=[];map.chosen.connect(func(id: String):seen.append(id))
 var rows: Array=[]
 for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  tree.root.size=resolution;await frames()
  map.setup(packet.svg,projection,"", "",home);await frames()
  check(map.markers.size()==4 and not map.markers.has(generated.sites[1].id),"rumour has no texture, tooltip or hitbox")
  check(map.markers.hometown.icon_role==MapIconRoles.settlement(w.get_record("burg",int(spec.home_id))),"same actual atlas/hometown role")
  for s: Dictionary in projection.sites:
   var b: Variant=map.markers[s.id]
   check(b.icon_texture!=null and b.icon_role==MapIconRoles.site(s.kind),"correct real icon for "+s.kind)
   check((b.position+b.size/2).is_equal_approx(map.screen_point(s.position)),"projected coordinates remain exact")
   check(b.size.is_equal_approx(Vector2(32,32)),"independent readable rectangular mouse target "+str(b.size))
  await capture("region-%02d-normal-%dx%d"%[index,resolution.x,resolution.y])
  var first: Dictionary=projection.sites[0];var button: Variant=map.markers[first.id];var instance: int=button.get_instance_id();var position: Vector2=button.position
  await click(button)
  check(not seen.is_empty() and seen.back()==first.id,"real mouse selects exact public site ID")
  if visual:
   for down in [true,false]:
    var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=button.get_global_rect().position+Vector2(2,2);event.pressed=down;tree.root.push_input(event,true)
   await frames()
   check(seen.back()==first.id,"transparent SVG corner remains a valid rectangular click target")
  map.setup(packet.svg,projection,"",first.id,home);await frames()
  check(map.markers[first.id].get_instance_id()==instance and map.markers[first.id].position==position,"selection retains button and source coordinate; no flicker/relocation")
  check(map.markers[first.id].selected,"gold destination state")
  await capture("region-%02d-selected-%dx%d"%[index,resolution.x,resolution.y])
  rows.append({"resolution":[resolution.x,resolution.y],"map_rect":[map.map_rect().position.x,map.map_rect().position.y,map.map_rect().size.x,map.map_rect().size.y],"site_id":first.id,"role":map.markers[first.id].icon_role})
 knowledge[generated.sites[1].id]="discovered";projection=SandboxRecords.projection(record)
 map.setup(packet.svg,projection,"", "",home);check(map.markers.has(generated.sites[1].id),"scouting reveals exact public position and kind")
 await frames();await capture("region-%02d-discovered"%index)
 var private_projection:=projection.duplicate(true);private_projection.sites.append({"id":"private-test","name":"DO NOT REVEAL","kind":"portals","knowledge":"unknown","position":[500,500]})
 map.setup(packet.svg,private_projection,"", "",home);check(not map.markers.has("private-test"),"renderer rejects unknown projection rows before creating controls")
 var provider: MapIconProvider=map.icons;map.icons=MissingProvider.new()
 map.setup(packet.svg,projection,"", "",home)
 check(map.markers[projection.sites[0].id].icon_texture==null and map.markers[projection.sites[0].id].tooltip_text.contains("Icon unavailable"),"missing SVG uses visible neutral placeholder and keeps site clickable")
 if index==0:await frames();await capture("missing-resource-neutral-placeholder")
 map.icons=provider;map.setup(packet.svg,projection,"", "",home)
 check(RulesJson.digest(generated)==original,"appearance never mutates authoritative generated base")
 mappings.append({"home_id":spec.home_id,"biome":spec.biome,"world_sha":w.source_sha256,"content_sha":packet.content.sha,"home_role":home.role,"sites":projection.sites.map(func(s: Dictionary):return {"id":s.id,"role":MapIconRoles.site(s.kind),"position":s.position}),"checks":rows})
 sheet.queue_free();await frames()
 if visual:
  tree.root.size=Vector2i(1280,720)
  var atlas: Variant=load("res://scenes/debug/map_renderer/fantasy_map_layers.tscn").instantiate();tree.root.add_child(atlas)
  atlas.display_fixture(w._raw,str(spec.world).replace(".json",".relief.svg"),str(spec.world).replace(".json",".vegetation.svg"));atlas.set_zoom(3.0);atlas.scale=Vector2(0.47,0.39);atlas.position=Vector2(20,20)
  atlas.select_at(Vector2(w.get_record("burg",int(spec.home_id)).x,w.get_record("burg",int(spec.home_id)).y))
  await frames();await capture("region-%02d-atlas-reference"%index)
  atlas.queue_free();await frames()
func capture(name: String) -> void:
 if not visual:return
 for i in 12:await tree.process_frame
 await RenderingServer.frame_post_draw
 check(tree.root.get_texture().get_image().save_png(base.path_join(name+".png"))==OK,"actual Godot capture "+name)
func existing_campaign() -> void:
 AdventureService.legacy_review=false
 var service:=AdventureService.new();service.store.save_root=base.path_join("existing/saves");service.library.library_root=base.path_join("existing/library");service.library.save_root=service.store.save_root;service.cache_root=base.path_join("existing/cache")
 var old: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/map_icons/existing-game99-save.json"))
 var entries:=service.library.discover();var entry: Dictionary=entries.filter(func(e: Dictionary):return e.world.source_sha256==old.world_ref.sha256)[0]
 DirAccess.make_dir_recursive_absolute(service.store.save_root)
 var path:=service.store.save_root.path_join(old.playthrough_id+".json")
 var old_bytes:=FileAccess.get_file_as_bytes("res://tests/map_icons/existing-game99-save.json")
 FileAccess.open(path,FileAccess.WRITE).store_buffer(old_bytes)
 var cache:=service.cache_root.path_join(old.world_ref.sha256);DirAccess.make_dir_recursive_absolute(cache)
 var packet_path:=cache.path_join(str(int(old.origin.home_burg_id))+".json")
 FileAccess.open(packet_path,FileAccess.WRITE).store_buffer(FileAccess.get_file_as_bytes("res://tests/map_icons/existing-game99-packet.json"))
 FileAccess.open(packet_path+".sha",FileAccess.WRITE).store_string(FileAccess.get_sha256(packet_path))
 PartyService.handoff={"entry":entry,"slot":old.playthrough_id,"save_root":service.store.save_root,"library_root":service.library.library_root,"cache_root":service.cache_root}
 tree.root.size=Vector2i(1280,720)
 tree.change_scene_to_file("res://scenes/gameplay/expedition.tscn");await wait_scene("res://scenes/gameplay/expedition.tscn")
 check(FileAccess.get_file_as_bytes(path)==old_bytes,"old GAME99 campaign resumes with unchanged save bytes")
 check(ui.state.sandbox.base_sha==old.sandbox.base_sha and ui.state.party==old.party,"old generated sites and party unchanged")
 for site_id in ui.state.sandbox.results:
  check(ui.map.markers[site_id].completed,"actual saved resolved site retains identity with completion overlay")
  check(ui.map.markers[site_id].tooltip_text.contains("Completed"),"completed public tooltip")
 for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  tree.root.size=resolution;await frames()
  check(ui.map.size.x>=240 and ui.map.size.y>=200,"production map remains useful at "+str(resolution))
  for marker in ui.map.markers.values():check(marker.get_global_rect().intersects(ui.map.get_global_rect()),"production marker remains on map")
  await capture("existing-game99-completed-%dx%d"%[resolution.x,resolution.y])
 tree.root.size=Vector2i(1280,720);await frames()
 var candidates: Array=ui.state.sandbox.base.sites.filter(func(s: Dictionary):return not ui.state.sandbox.results.has(s.id))
 check(not candidates.is_empty(),"old campaign still has a playable opportunity")
 if candidates.is_empty():return
 var id: String=candidates[0].id
 var selection_bytes:=FileAccess.get_file_as_bytes(path)
 await click(ui.action_buttons[id])
 check(FileAccess.get_file_as_bytes(path)==selection_bytes and ui.state.sandbox==old.sandbox,"map selection does not write saves or alter combat/RNG/logs")
 await click(ui.action_buttons.sandbox_accept);await wait_job()
 if ui.action_buttons.has("sandbox_scout"):await click(ui.action_buttons.sandbox_scout);await wait_job()
 await click(ui.action_buttons.sandbox_travel);await wait_job();await click(ui.action_buttons.sandbox_fight);await wait_scene("res://scenes/combat/first_adventure.tscn")
 await play_fight();check(ui.battle().status=="victory","existing campaign actual combat victory")
 await capture("existing-game99-new-victory")
 await click(ui.return_button);await wait_scene("res://scenes/gameplay/expedition.tscn")
 check(ui.map.markers[id].completed and ui.map.markers[id].selected,"post-victory identity/selected state/overlay")
 var tooltip: String=ui.map.markers[id].tooltip_text
 check(ui.state.sandbox.results[id].xp_each==10,"existing journey XP authority unchanged")
 await capture("existing-game99-post-victory-local-map")
 await click(ui.home_button);await wait_job()
 var bytes:=FileAccess.get_file_as_bytes(path);var resumed:=service.operate(entry,old.playthrough_id,"resume")
 check(resumed.ok and FileAccess.get_file_as_bytes(path)==bytes,"post-result save/reload idempotence")
 ui.state=resumed.state;ui.refresh_sandbox();await frames()
 check(ui.map.markers[id].tooltip_text==tooltip.replace(" · Party position",""),"same semantic icon and tooltip after return/reload")
 proof.existing_campaign={"source":"Executed GAME99 Linux recovery fixture","party_ids":ui.state.party_ids,"base_sha":ui.state.sandbox.base_sha,"victory_site":id,"world_sha":ui.entry.world.source_sha256,"results":ui.state.sandbox.results}
