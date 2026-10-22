extends "res://tests/psychic_support/helpers.gd"
func run() -> void:
 base=OS.get_environment("GAME127_ROOT");DirAccess.make_dir_recursive_absolute(base)
 check(source.load_pack("res://data/rules/trhgd-character-v25.json").ok,"unchanged25 reproduction")
 kernel=RulesCharacter.new(source)
 records.foe=build("foe",route("fighter",20),PSI)
 var adept := cognition("heritage-ogre",1)
 if adept.is_empty():finish_reproduction();return
 var engine := TacticalAuras.new(adept);var b := encounter(adept)
 b.units["bandit-blade"].position=[2,2];b=engine.seal(b)
 check(engine.validate(b).is_empty(),"lawful clear two-tile inherited reach fixture "+engine.validate(b))
 var accepted := command(engine,b,"cognition-strike-1")
 check(accepted.ok,"REPRODUCTION: adjacent cognition strike inherits two-tile reach")
 traces={"nonadjacent_cognition_accepted":accepted.ok,"distance":engine.distance(b.units.a.position,b.units["bandit-blade"].position),"ordinary_weapon_range":engine.weapon_range(b.units.a)}
 # Independent presentation defect: an adjacent-only descriptor displays inherited
 # weapon range. The existing v25 Lurk authority correctly rejects that target.
 var lurk := kernel.create("lurk",PSI,"heritage-ogre")
 for n in 4:
  var suggestion := kernel.suggested_choice(lurk,"lurk");check(suggestion.ok,"lawful large Lurk")
  if not suggestion.ok:finish_reproduction();return
  var advanced := kernel.preview_advancement(lurk,suggestion.choice);check(advanced.ok,"lawful large Lurk advancement")
  if not advanced.ok:finish_reproduction();return
  lurk=advanced.candidate
 lurk.runtime.hp=int(kernel.derive_character(lurk).snapshot.stats.HP);lurk.runtime.resources=kernel._replay(lurk).context.capacities.duplicate(true)
 var veil := use(lurk,lurk,"lurk-veil");check(veil.ok,"actual prior veil")
 if not veil.ok:finish_reproduction();return
 b=encounter(veil.actor);engine=TacticalAuras.new(lurk);b.units["bandit-blade"].position=[2,2];b=engine.seal(b)
 check(not command(engine,b,"lurk-psychic-ambush").ok,"current25 already rejects distant ambush")
 var ui: Control=load("res://tests/spell_repertoires/combat_input_probe.gd").new();PartyService.handoff={};add_child(ui);ui.set_process(false)
 ui.engine=engine;ui.state={"first_adventure":{"battle":b},"party_ids":["a","b","c"],"party":{"members":[]}};ui.mode="lurk-psychic-ambush";ui.refresh()
 var caption: String=ui.action_buttons["lurk-psychic-ambush"].text
 check("range 2" in caption,"REPRODUCTION: adjacent-only action advertises range2")
 traces["adjacent_caption"]=caption;traces["distant_lurk_rejected"]=true
 ui.queue_free();finish_reproduction()
func finish_reproduction() -> void:
 FileAccess.open(base.path_join("baseline-proof.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"traces":traces,"development_fixtures":true,"earned_xp":false}))
 get_tree().quit(1 if failures else 0)
