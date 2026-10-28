extends Node
var checks := 0
var failures := 0
var source := RulesRegistry.new()
var kernel: RulesCharacter
var base := ""
var observations := []
var saved := {}
func _ready() -> void:call_deferred("run")
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures+=1;print("ASSERTION_FAILED ",label)
func record(id: String,cls: String,ancestry := "heritage-human") -> Dictionary:
 var attrs := {"STR":10,"DEX":13,"CON":12,"INT":14,"WIS":15,"CHA":8}
 if cls=="sorcerer":attrs={"STR":8,"DEX":15,"CON":13,"INT":12,"WIS":10,"CHA":14}
 if cls=="knight":attrs={"STR":15,"DEX":8,"CON":13,"INT":14,"WIS":12,"CHA":10}
 var r := kernel.create(id,attrs,ancestry);var choice := kernel.suggested_choice(r,cls,"steady-study")
 check(choice.ok,"lawful starting "+cls)
 if not choice.ok:return {}
 if cls=="druid":choice.choice.specialisations["druid-companion"]="wolf"
 var out := kernel.preview_advancement(r,choice.choice);check(out.ok,"legal level-one history "+cls)
 if not out.ok:return {}
 r=out.candidate;r.equipment=source.definition("classes",cls).recommended_equipment.duplicate()
 if cls=="druid":r.choices.prepared_abilities=["druid-summon-sentinel"];r.choices.spell_preparations={"druid-summon-sentinel":1}
 if cls=="sorcerer":r.choices.prepared_abilities=["sorcerer-arcane-bolt"]
 var derived := kernel.derive_character(r);check(derived.ok,"selected known/prepared loadout "+cls+JSON.stringify(derived.get("errors",[])))
 if not derived.ok:return {}
 r.runtime=RulesEffects.new(source).refresh_resources(r.runtime,derived.snapshot.resource_capacities,"eligible_rest").runtime
 RulesCoreContent.refill_prepared(r,source);r.runtime.hp=int(derived.snapshot.stats.HP)
 return RulesJson.string_keys(r)
func command(engine: TacticalAuras,b: Dictionary,kind: String,target := "",destination: Array=[]) -> Dictionary:
 var input := {"actor_id":engine.current(b).id,"revision":b.revision,"kind":kind}
 if not target.is_empty():input.target_id=target
 if not destination.is_empty():input.destination=destination
 var out := engine.command(b,input);check(out.ok,"fixture real command "+kind+" "+str(out.get("error","")))
 return out.get("battle",b)
func fixture() -> Dictionary:
 var records := {"sorcerer":record("sorcerer","sorcerer"),"knight":record("knight","knight"),"druid":record("druid","druid","heritage-ogre")}
 if failures:return {}
 var state := {"world_ref":{},"origin":{},"party_ids":["sorcerer","knight","druid"],"party":{"members":[{"character_id":"sorcerer","name":"Sorcerer"},{"character_id":"knight","name":"Knight"},{"character_id":"druid","name":"Ogre Druid"}]},"mechanics":{"rules_ref":source.rules_ref(),"records":records}}
 var engine := TacticalAuras.new(state);var b := engine.create(state,"game165-sanitized-reproduction")
 var wolf := RulesEntities.identity("druid");check(b.units.has(wolf),"actual permanent Wolf created")
 # Authored diagnostic turn order; not claimed to be the private save's seed,
 # geography or identities. Preserve all subsequent commands and authority.
 b.order=["sorcerer",wolf,"druid","knight","bandit-blade","bandit-bow"];b.cursor=0;b=engine.seal(b)
 b=command(engine,b,"move","",[2,2]);b=command(engine,b,"sorcerer-arcane-bolt","bandit-blade");b=command(engine,b,"end")
 b=command(engine,b,"move","",[0,4]);b=command(engine,b,"end")
 b=command(engine,b,"move","",[2,3]);saved.before_summon=b.duplicate(true)
 b=command(engine,b,"druid-summon-sentinel","druid")
 check(b.revision==7 and b.cursor==2 and b.round==1 and b.status=="active"and b.budget=={"main":0,"move":0},"actual reported revision7/exhausted Druid state")
 var summon: Dictionary=b.units[b.order[3]]
 check(summon.entity.kind=="summon"and summon.entity.remaining==3 and summon.record.runtime.hp==12 and engine.current(b).id=="druid","three-round12HP Sentinel inserted immediately after unchanged caster")
 check(engine.alive(b.units["bandit-blade"])and engine.alive(b.units["bandit-bow"])and engine.alive(b.units[wolf]),"both opponents and permanent Wolf coexist")
 check(engine.validate(b).is_empty(),"sanitized battle validates under exact immutable33")
 saved.post_summon=b;saved.state=state
 return b
func click(point: Vector2) -> void:
 var motion := InputEventMouseMotion.new();motion.position=point;get_viewport().push_input(motion,true);await get_tree().process_frame
 for down in [true,false]:
  var event := InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=down;event.position=point;get_viewport().push_input(event,true);await get_tree().process_frame
func frames() -> void:
 for i in 5:await get_tree().process_frame
func run() -> void:
 base=OS.get_environment("SENTINEL_ROOT");DirAccess.make_dir_recursive_absolute(base)
 check(source.load_pack("res://data/rules/trhgd-character-v33.json").ok,"released33 pin")
 kernel=RulesCharacter.new(source);var b := fixture()
 if failures:finish();return
 var ui: Control=load("res://tests/sentinel_turn/ui_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 ui.engine=TacticalAuras.new(b.units.druid.record);ui.state=saved.state.duplicate(true);ui.state.first_adventure={"battle":b};ui.message="GAME-165 · released33 diagnostic · Druid summoned Sentinel · 0 action / 0 movement";ui.refresh()
 var any_clipped := false
 for size in [Vector2i(640,360),Vector2i(1280,720),Vector2i(2560,1440)]:
  get_window().mode=Window.MODE_WINDOWED;get_window().size=size;ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);await frames();ui.refresh();await frames()
  var view := get_viewport().get_visible_rect();var end_rect: Rect2=ui.end_button.get_global_rect();var retreat_rect: Rect2=ui.retreat_button.get_global_rect()
  var visible: bool=ui.end_button.is_visible_in_tree()and view.encloses(end_rect)
  any_clipped=any_clipped or not visible
  check(not ui.end_button.disabled and not ui.retreat_button.disabled and not ui.is_presenting(),"same enabled gating after completed presentation")
  ui.end_button.grab_focus();await frames()
  var before: int=ui.intents.size()
  await click(end_rect.get_center()if visible else Vector2(view.end.x-2,minf(view.end.y-2,end_rect.get_center().y)))
  var emitted: bool=ui.intents.size()>before and ui.intents.back().kind=="end"
  var image := get_viewport().get_texture().get_image();var name := "released33-post-summon-%dx%d.png"%[size.x,size.y];image.save_png(base.path_join(name))
  observations.append({"requested":[size.x,size.y],"viewport":str(view),"root":str(ui.get_global_rect()),"end":str(end_rect),"withdraw":str(retreat_rect),"end_on_screen":visible,"withdraw_on_screen":view.encloses(retreat_rect),"end_enabled":not ui.end_button.disabled,"focusable":ui.end_button.has_focus(),"genuine_visible_click_emits_end":emitted,"screenshot":name,"sha256":FileAccess.get_sha256(base.path_join(name))})
  var out: Dictionary=ui.engine.command(b,{"actor_id":"druid","revision":7,"kind":"end"});check(out.ok and ui.engine.current(out.battle).entity.kind=="summon","original authority ends0/0 Druid into Sentinel")
  ui.state.first_adventure.battle=b;ui.intents.clear();ui.refresh()
 check(any_clipped,"released UI reproduces inaccessible off-viewport End Turn")
 FileAccess.open(base.path_join("fixture.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(saved)))
 finish()
func finish() -> void:
 FileAccess.open(base.path_join("probe-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"private_save_used":false,"scope":"Sanitized deterministic production-control reproduction; no claim of private save access or repaired campaign outcome.","observations":observations}))
 print("GAME165_PROBE ",checks," failures ",failures);get_tree().quit(1 if failures else 0)
