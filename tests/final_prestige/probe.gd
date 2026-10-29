extends "res://tests/grove_summoner/mechanics.gd"
## Released34 diagnostic histories only; no campaign XP or native-release claim.
const STEALTH_ARRAY := {"STR":10,"DEX":15,"CON":13,"INT":14,"WIS":12,"CHA":8}
func lawful_route(sequence: Array,attrs: Dictionary,path: String,ancestry := "heritage-human",options: Dictionary={}) -> Dictionary:
 var planner: Node=load("res://tests/nature_repertoires/caster_planner.gd").new();planner.source=source;planner.kernel=kernel
 var goals: Dictionary=planner.requirements(path,0);var record: Dictionary=kernel.create("final-prestige-development",attrs,ancestry)
 for cls in sequence:
  var proposed: Dictionary=planner.advance(record,str(cls),goals)
  check(proposed.ok,"lawful released route "+str(cls)+str(record.advancement_history.size()+1)+JSON.stringify(proposed.get("errors",[])))
  if not proposed.ok:planner.free();return {}
  var choice: Dictionary=proposed.candidate.advancement_history.back().duplicate(true);choice.erase("level");var changed := false
  for group in choice.specialisations:
   if options.has(group)and choice.specialisations[group]!=options[group]:choice.specialisations[group]=options[group];changed=true
  if changed:
   proposed=kernel.preview_advancement(record,choice);check(proposed.ok,"explicit existing parent choice")
   if not proposed.ok:planner.free();return {}
  record=learn(proposed.candidate,proposed.snapshot)
  if record.is_empty():planner.free();return {}
 planner.free();record.equipment=source.definition("classes",sequence[0]).recommended_equipment.duplicate()
 var derived: Dictionary=kernel.derive_character(record);check(derived.ok,"complete lawful route and original equipment")
 if not derived.ok:return {}
 record.runtime.hp=int(derived.snapshot.stats.HP);return RulesJson.string_keys(record)
func run() -> void:
 base=OS.get_environment("FINAL_PRESTIGE_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();var loaded: Dictionary=source.load_pack("res://data/rules/trhgd-character-v34.json")
 check(loaded.ok,"exact immutable released34 schema")
 if not loaded.ok:finish_released();return
 kernel=RulesCharacter.new(source);fixtures.fighter=build("fighter",12)
 var weak: Dictionary=lawful_route(["wizard"]+repeated("sorcerer",2)+repeated("fighter",3),DUAL_ARRAY,"eldritch-knight")
 if not weak.is_empty():
  var permanent: Dictionary=kernel._replay(weak).context
  observations.knight_shallow={"eligible":kernel.available_advancement(weak).classes["eldritch-knight"].ok,"casting":permanent.casting,"tiers":RulesCompleteness.spell_tiers(weak,permanent,source),"history":weak.advancement_history}
  check(observations.knight_shallow.eligible and observations.knight_shallow.tiers.arcane==1,"released34 aggregate arcane score permits Knight with actual tier1 magic")
 var stranded: Dictionary=lawful_route(repeated("beguiler",8),WIZARD_ARRAY,"eldritch-knight")
 if not stranded.is_empty():
  var permanent: Dictionary=kernel._replay(stranded).context;var parents := []
  for option in RulesCareer.groups(source,"eldritch-knight",1)[0].options:
   if RulesCareer.option_eligibility(source,"eldritch-knight",1,option,permanent).ok:parents.append(option.id)
  observations.knight_stranded={"eligible":kernel.available_advancement(stranded).classes["eldritch-knight"].ok,"parents":parents,"tiers":RulesCompleteness.spell_tiers(stranded,permanent,source),"history":stranded.advancement_history}
  check(observations.knight_stranded.eligible and observations.knight_stranded.tiers.arcane>=3 and parents.is_empty(),"released34 offers qualified Beguiler Knight entry without a legal authored parent")
 var knight: Dictionary=lawful_route(repeated("wizard",5)+repeated("fighter",2)+["eldritch-knight"],WIZARD_ARRAY,"eldritch-knight", "heritage-human",{"eldritch-knight-arcane":"wizard"})
 var shade: Dictionary=lawful_route(repeated("rogue",5)+["shadowdancer"],STEALTH_ARRAY,"shadowdancer")
 if not knight.is_empty():
  var snap: Dictionary=kernel.derive_character(knight).snapshot
  observations.knight_existing={"casting_levels":snap.casting_levels,"channels":snap.abilities.filter(func(id: String):return source.definition("abilities",id).has("channel_spell")),"surge":source.definition("abilities","eldritch-knight-power-1"),"history":knight.advancement_history}
  check(snap.casting_levels.wizard==6 and observations.knight_existing.channels.is_empty(),"preserve working chosen-parent progression; record missing martial spell-channel selection")
 var druid: Dictionary=prep(build("druid",20),"druid-wildheart-mantle")
 for item in [["knight",knight,"eldritch-knight-power-1","bandit-blade"],["shadow",shade,"shadowdancer-technique-1","a"]]:
  if item[1].is_empty():continue
  var altered: Dictionary=use(druid,item[1],"druid-wildheart-mantle")
  check(altered.ok,"real paid ally spell produces a magic-suppressed "+str(item[0])+" body")
  if not altered.ok:continue
  var battle: Dictionary=encounter(altered.target);var engine:=TacticalAuras.new(altered.target);var cast: Dictionary=execute(engine,battle,item[2],item[3])
  observations[str(item[0])+"_form"]={"accepted":cast.ok,"error":cast.get("error",""),"tags":source.definition("abilities",item[2]).tags,"form":RulesEntities.form(altered.target,source)}
  if item[0]=="shadow":check(cast.ok,"released34 untyped Shadow shroud bypasses transformed-body suppression")
  elif cast.ok:check(cast.battle.budget.main==0 and cast.battle.units.a.record.runtime.resources["eldritch-knight-uses"]==battle.units.a.record.runtime.resources["eldritch-knight-uses"]-1,"actual transformed Knight attempt pays its main action and reserve")
  else:check(not cast.error.is_empty(),"preserve explicit existing rejection diagnostics for transformed Knight equipment")
 var defender: Dictionary=lawful_route(repeated("fighter",5)+["dwarven-defender"],MARTIAL_ARRAY,"dwarven-defender","heritage-dwarf")
 if not defender.is_empty():
  var engine:=TacticalAuras.new(defender);var battle: Dictionary=encounter(defender);var original: int=int(engine.stats(battle.units.a).defence)
  var cast: Dictionary=execute(engine,battle,"dwarven-defender-technique-1","a");check(cast.ok,"existing real paid Defender stance")
  if cast.ok:
   var snap: Dictionary=kernel.derive_character(cast.battle.units.a.record).snapshot
   var triggers: Array=snap.abilities.filter(func(id: String):return source.definition("abilities",id).has("trigger"))
   observations.defender_existing={"before_defence":original,"after_defence":snap.stats.defence,"capabilities":snap.capabilities,"paths":engine.paths(cast.battle,cast.battle.units.a),"triggers":triggers,"cost_before":battle.units.a.record.runtime.resources["dwarven-defender-uses"],"cost_after":cast.battle.units.a.record.runtime.resources["dwarven-defender-uses"]}
   check(int(snap.stats.defence)==original+2 and snap.capabilities.immobile and int(snap.capabilities.resistances.physical)==3 and observations.defender_existing.paths.is_empty(),"preserve working armour-stacking defence, real immobility and physical resistance")
   check(triggers.is_empty(),"released34 Defender stance provides no defensive reaction ability; acceptance gap")
 finish_released()
func finish_released() -> void:
 var proof: Dictionary={"checks":checks,"failures":failures,"failed_checks":failed_checks,"observations":observations,"rules_ref":source.rules_ref(),"development_fixtures":true,"earned_xp":false,"production_changed":false}
 FileAccess.open(base.path_join("probe-proof.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(proof),"  "))
 print("FINAL_PRESTIGE_RELEASED34 ",checks," failures ",failures)
 if no_quit:completed.emit()
 else:get_tree().quit(1 if failures else 0)
