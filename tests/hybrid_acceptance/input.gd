extends Node
var checks := 0
var failures := 0
func check(value: bool,label: String) -> void:
 checks+=1
 if not value:failures+=1;push_error(label)
func _ready() -> void:call_deferred("run")
func run() -> void:
 var base := OS.get_environment("HYBRID_ROOT")
 var saved: Dictionary=RulesJson.normalize(WorldOriginLore.read_json(base.path_join("saved.json")))
 var source := RulesRecords.registry(saved.records.duskblade3);var kernel := RulesCharacter.new(source)
 var creator := BuildEditor.new();add_child(creator);creator.setup(saved.records.duskblade1,false)
 check(creator.class_options().has("duskblade") and not creator.class_options().has("archmage"),"real creator shows base class but excludes prestige")
 creator.queue_free()
 var book := SpellbookEditor.new();add_child(book);book.setup(saved.records.duskblade20)
 check(book.controls.has("duskblade-storm-brand") and not book.controls.has("channel-duskblade-storm-brand"),"real known-spell selector offers original, never wrapper as separate knowledge")
 book.repertoire_search.text="tier 5";book.repertoire_search.text_changed.emit("tier 5")
 check(book.controls["duskblade-storm-brand"].visible,"actual later-tier spell search")
 book.queue_free()
 for cls in ["wizard","sorcerer"]:
  var original: Dictionary=saved.records[cls+":qualified13"];var before := RulesJson.digest(original)
  var advance := BuildEditor.new();add_child(advance);advance.setup(original,true)
  var index := find(advance.class_picker,"archmage")
  check(index>=0 and not advance.class_picker.is_item_disabled(index),"actual qualified prestige is optional advancement "+cls)
  if index>=0:advance.class_picker.select(index);advance.class_picker.item_selected.emit(index)
  check(advance.career_pickers.has("archmage-casting") and advance.career_pickers.has("high-arcana-1"),"actual path choices visible "+cls)
  if advance.career_pickers.has("high-arcana-1"):
   var choice: OptionButton=advance.career_pickers["high-arcana-1"];var ward := find(choice,"ward")
   check(ward>=0 and not choice.is_item_disabled(ward),"deliberate ward alternative offered")
   if ward>=0:choice.select(ward);choice.item_selected.emit(ward)
   var proposed := advance.choice()
   check(proposed.specialisations["high-arcana-1"]=="ward" and proposed.specialisations["archmage-casting"]==cls,"actual production controls persist selected parent and advanced ability")
   check(kernel.preview_advancement(original,proposed).ok,"production choice is accepted by actual authority")
  check(RulesJson.digest(original)==before,"exploring controls grants no prestige, resources or progress")
  advance.queue_free()
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 var record: Dictionary=saved.records.duskblade3.duplicate(true);record.character_id="a";record.choices.prepared_abilities=["duskblade-searing-grasp"];record.equipment=["shortblade","mail"]
 record.runtime.resources=kernel._replay(record).context.capacities.duplicate()
 var b: Dictionary=saved.battles["duskblade-searing-grasp:19"].duplicate(true);b.units.a.record=record;b.units.a.weapon="shortblade";b.cursor=b.order.find("a");b.budget={"main":1,"move":1}
 ui.engine=TacticalAuras.new(record);b=ui.engine.seal(b);var wrapper: String="channel-duskblade-searing-grasp"
 show(ui,b,wrapper)
 var p: Array=b.units["bandit-blade"].position
 check(not ui.action_buttons[wrapper].disabled and ui.tiles[str(p)].target_tile,"actual legal melee channel enabled/highlighted")
 ui.choose_tile(p)
 check(ui.sent.kind==wrapper and ui.sent.target=="bandit-blade","real target click keeps exact channel intent and enemy identity")
 var cast: Dictionary=ui.engine.command(b,{"actor_id":"a","revision":b.revision,"kind":ui.sent.kind,"target_id":ui.sent.target})
 check(cast.ok,"real UI intent executes through existing command authority")
 if cast.ok:
  show(ui,cast.battle,wrapper);ui.sent={};ui.choose_tile(p)
  check(ui.action_buttons[wrapper].disabled and not ui.tiles[str(p)].target_tile and ui.sent.is_empty(),"spent main has no misleading channel target or illegal UI intent")
 for reason in ["bow","empty-slots"]:
  var blocked: Dictionary=b.duplicate(true)
  if reason=="bow":blocked.units.a.record.equipment=["bow","mail"];blocked.units.a.weapon="bow"
  else:blocked.units.a.record.runtime.resources["duskblade-slots-1"]=0
  blocked=ui.engine.seal(blocked);show(ui,blocked,wrapper);ui.sent={};ui.choose_tile(p)
  check(ui.action_buttons[wrapper].disabled and not ui.tiles[str(p)].target_tile and ui.sent.is_empty(),"unavailable channel is consistently disabled/untargetable "+reason)
  check(not ui.engine.command(blocked,{"actor_id":"a","revision":blocked.revision,"kind":wrapper,"target_id":"bandit-blade"}).ok,"authoritative rejection preserved "+reason)
 ui.queue_free()
 FileAccess.open(base.path_join("input-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"scope":"Actual production base/advanced choices, spellbook, legal and unavailable channel buttons/highlights/click intents. Development fixtures; no XP granted."}))
 print("HYBRID_INPUT ",checks," failures ",failures);get_tree().quit(1 if failures else 0)
func find(picker: OptionButton,id: String) -> int:
 for i in picker.item_count:
  if picker.get_item_metadata(i)==id:return i
 return -1
func show(ui: Control,b: Dictionary,mode: String) -> void:
 ui.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}};ui.mode=mode;ui.refresh()
