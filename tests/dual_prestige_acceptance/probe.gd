extends "res://tests/dual_prestige_acceptance/base.gd"
## Pinned28 diagnostics. A passing diagnostic is not career acceptance.
var observed := {}
func run() -> void:
 base=OS.get_environment("DUAL_ROOT");DirAccess.make_dir_recursive_absolute(base)
 source=RulesRegistry.new();check(source.load_pack("res://data/rules/trhgd-character-v28.json").ok,"original immutable28 diagnostic source")
 kernel=RulesCharacter.new(source)
 fixtures.fighter=build("fighter",20)
 var aggregate := route(["wizard","sorcerer","sorcerer","cleric","cleric","cleric"],DUAL_ARRAY)
 if not aggregate.is_empty():
  var permanent: Dictionary=kernel._replay(aggregate).context
  observed.aggregate={"casting":permanent.casting,"actual_tiers":RulesCompleteness.spell_tiers(aggregate,permanent,source),"offered":kernel.available_advancement(aggregate).classes["mystic-theurge"].ok}
  check(observed.aggregate.casting.arcane>=3 and observed.aggregate.actual_tiers.arcane==1 and observed.aggregate.offered,"reproduce aggregate arcane score qualifying without real tier2 access")
 var parents := route(repeated("beguiler",6)+repeated("cleric",3),WIZARD_ARRAY)
 if not parents.is_empty():
  var groups := RulesCareer.groups(source,"mystic-theurge",1)
  var legal := []
  for option in groups[0].options:
   if RulesCareer.option_eligibility(source,"mystic-theurge",1,option,kernel._replay(parents).context).ok:legal.append(option.id)
  observed.missing_parent={"offered":kernel.available_advancement(parents).classes["mystic-theurge"].ok,"legal_arcane_parents":legal}
  check(observed.missing_parent.offered and legal.is_empty(),"reproduce eligible Beguiler/divine build without a selectable arcane parent")
 var prefix := repeated("wizard",3)+repeated("cleric",3)
 var advanced := route(prefix+repeated("mystic-theurge",5))
 if not advanced.is_empty():
  var proposed := kernel.suggested_choice(advanced,"mystic-theurge")
  observed.cap={"max_level":source.definition("classes","mystic-theurge").max_level,"sixth_rejected":not kernel.preview_advancement(advanced,proposed.choice).ok}
  check(observed.cap.max_level==5 and observed.cap.sixth_rejected,"original Theurge really stops at5, not10")
 var junior := route(prefix+["sorcerer","mystic-theurge"],DUAL_ARRAY,"mystic-theurge",{"mystic-theurge-arcane":"sorcerer"})
 if not junior.is_empty():
  var d := kernel.derive_character(junior)
  observed.junior={"casting_levels":d.snapshot.casting_levels,"sorcerer_tier2_slots":int(d.snapshot.resource_capacities.get("sorcerer-slots-2",0))}
  check(d.snapshot.casting_levels.wizard==3 and d.snapshot.casting_levels.sorcerer==2 and observed.junior.sorcerer_tier2_slots==0,"preserve legitimate junior-parent advancement without borrowing Wizard tiers or slots")
 var theurge := route(prefix+["mystic-theurge"])
 var champion := route(repeated("duskblade",6)+["abjurant-champion"],MARTIAL_ARRAY,"abjurant-champion",{"abjurant-doctrine-1":"retaliation"})
 var druid := prep(build("druid",20),"druid-wildheart-mantle")
 for spec in [["theurge",theurge,"mystic-theurge-power-1"],["champion",champion,"abjurant-retaliation-1"]]:
  if spec[1].is_empty():continue
  var form := use(druid,spec[1],"druid-wildheart-mantle")
  check(form.ok,"real ally body transformation before diagnostic "+spec[0])
  if not form.ok:continue
  var b := encounter(form.target);var engine := TacticalAuras.new(form.target)
  b.rng=attack_seed(19);b=engine.seal(b)
  var command := order(b,spec[2])
  if spec[0]=="theurge":command.target_id="a"
  var out := engine.command(b,command)
  observed[spec[0]+"_transformed_action"]={"ok":out.ok,"tags":source.definition("abilities",spec[2]).tags,"error":out.get("error","")}
  check(out.ok,"reproduce untyped magical technique executing in suppressed body "+spec[0]+str(out.get("error","")))
  if out.ok:check(out.battle.budget.main==0,"diagnostic was an actual paid tactical action")
 var report := {"checks":checks,"failures":failures,"rules_ref":source.rules_ref(),"observed":observed,"development_fixtures":true,"earned_xp":false,"scope":"Pinned28 diagnostics, not native-export acceptance or readiness promotion"}
 FileAccess.open(base.path_join("probe-proof.json"),FileAccess.WRITE).store_string(JSON.stringify(RulesJson.string_keys(report),"  "))
 print("DUAL_PRESTIGE_BASELINE ",checks," failures ",failures);get_tree().quit(1 if failures else 0)
