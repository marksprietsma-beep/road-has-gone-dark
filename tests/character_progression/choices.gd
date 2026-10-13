extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(why)
func _initialize():call_deferred("run")
func run():
 var source := RulesRecords.new_character_registry();var kernel := RulesCharacter.new(source)
 for cls in source.ids("classes"):
  if source.definition("classes",cls).class_kind!="base":continue
  var record := kernel.create("options:"+cls,source.recommendation("adept").attributes,"heritage-human")
  for n in 5:
   var next := kernel.preview_advancement(record,kernel.suggested_choice(record,cls).choice)
   check(next.ok,"prior ordered build "+cls);record=next.candidate
  for level in [1,6]:
   var before := record if level==6 else kernel.create("options:"+cls,source.recommendation("adept").attributes,"heritage-human")
   for group in RulesCareer.groups(source,cls,level):
    for option in group.options:
     if level==6 and cls in ["wizard","sorcerer"]:
      before=record.duplicate(true);before.advancement_history[0].specialisations[cls+"-choice-1"]=option.id
     var proposal := kernel.suggested_choice(before,cls)
     proposal.choice.specialisations[group.id]=option.id
     var result := kernel.preview_advancement(before,proposal.choice)
     check(result.ok,"every actual selectable option "+cls+" "+option.id+str(level))
     if not result.ok:continue
     var actor: Dictionary=result.candidate
     actor.runtime.hp=1;actor.runtime.resources=result.snapshot.resource_capacities.duplicate()
     var target := kernel.create("target",source.recommendation("vanguard").attributes,"heritage-human")
     target=kernel.preview_advancement(target,kernel.suggested_choice(target,"fighter").choice).candidate
     target.runtime.hp=1
     for f in option.features:
      for id in source.definition("features",f).abilities:
       var ability := source.definition("abilities",id)
       if ability.tags.has("weapon_strike"):
        check(result.snapshot.abilities.has(id),"weapon technique granted; attack effects covered by tactical suite");continue
       var self_target: bool=ability.targeting.kind=="self" or int(ability.targeting.get("radius",0))>0
       var original: Dictionary=actor if self_target else target
       var rng := RulesRng.initial("choice:"+id)
       var used := RulesEffects.new(source).use_ability(actor,original,id,{"main":1,"move":1,"reaction":1},rng)
       check(used.ok,"selected choice actual effect "+id)
       if not used.ok:continue
       check(not used.events.is_empty(),"effect emits authoritative events "+id)
       var replay := RulesEffects.new(source).use_ability(actor,original,id,{"main":1,"move":1,"reaction":1},rng)
       check(RulesJson.digest(used)==RulesJson.digest(replay),"option resources/events/RNG exact replay "+id)
       check(used.actor!=actor or used.target!=original,"mechanical change, not decorative "+id)
 # malformed definitions/choices fail without exceptions.
 var invalid := source.source_data();invalid.classes[0].career_choices[0].options[0].features=["missing"]
 check(not RulesRegistry.new().load_data(invalid).ok,"undefined option feature rejected")
 invalid=source.source_data();invalid.classes[0].career_choices.append(invalid.classes[0].career_choices[0])
 check(not RulesRegistry.new().load_data(invalid).ok,"duplicate choice group rejected")
 var record := kernel.create("bad",source.recommendation("adept").attributes,"heritage-human")
 var proposal := kernel.suggested_choice(record,"wizard")
 proposal.choice.specialisations=[];check(not kernel.preview_advancement(record,proposal.choice).ok,"malformed choice safely rejected")
 # Actual visible creator retains a deliberately selected school on save/review.
 record.equipment=["staff"]
 var valid := kernel.preview_advancement(record,kernel.suggested_choice(record,"wizard").choice)
 var editor := BuildEditor.new();root.add_child(editor);editor.setup(valid.candidate)
 check(editor.career_pickers.has("wizard-choice-1"),"visible school control")
 editor.select_id(editor.career_pickers["wizard-choice-1"],"abjuration")
 editor.career_pickers["wizard-choice-1"].item_selected.emit(editor.career_pickers["wizard-choice-1"].selected)
 check(editor.preview.ok and editor.preview.snapshot.abilities.has("wizard-abjuration-1"),"visible selection builds actual school ability: "+CharacterBuilderRecords.reason(editor.preview))
 editor.setup(editor.preview.candidate)
 check(editor.specialisations["wizard-choice-1"]=="abjuration","creator review/reopen retains deliberate option")
 editor.queue_free()
 print("GAME119 CHOICES ",checks," / ",failures)
 quit(1 if failures else 0)
