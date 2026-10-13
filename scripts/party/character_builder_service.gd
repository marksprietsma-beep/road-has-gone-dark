class_name CharacterBuilderService
extends RulesService
## Deliberate player edits share the campaign's existing lock/journal/save owner.
func _operate_locked(entry: Dictionary,slot: String,operation: String,member: int,changes: Dictionary) -> Dictionary:
 if not operation.begins_with("builder_"):return super._operate_locked(entry,slot,operation,member,changes)
 var loaded := recover(slot,entry.world)
 if not loaded.ok:return loaded
 var state: Dictionary=loaded.state
 if operation=="builder_open":
  if state.get("party",{}).get("status")=="ready" or state.has("character_builder"):return loaded
  if not state.has("party"):
   loaded=super._operate_locked(entry,slot,"generate",1,{})
   if not loaded.ok:return loaded
   state=loaded.state
  var candidate := state.duplicate(true)
  var shadow := state.duplicate(true)
  shadow.party.status="ready";shadow.onboarding_stage="party_ready"
  var prepared := RulesRecords.preview_preparation(shadow)
  if not prepared.ok:return prepared
  candidate.party.schema_version=2;candidate.party.generator_version="player-party-1"
  for m in candidate.party.members:m.generated_facts.public_relationship.kind="party-companions"
  candidate.character_builder={"version":1,"rules_ref":prepared.candidate.mechanics.rules_ref,"revision":1,"confirmed":[],"drafts":prepared.candidate.mechanics.records,"advancements":[],"policy_sha":FileAccess.get_sha256(CharacterBuilderRecords.POLICY),"initial_levels":{}}
  for id in candidate.party_ids:candidate.character_builder.initial_levels[id]=1
  return commit(slot,candidate,entry.world)
 if changes.get("before_hash")!=RulesJson.digest(state):return fail("builder.stale: Campaign changed after your preview. Reload before saving.")
 if operation=="builder_advance":
  if not changes.get("choice") is Dictionary or not changes.get("character_id") is String:return fail("A structured advancement choice is required")
  var preview := CharacterBuilderRecords.preview_advancement(state,changes.character_id,changes.choice)
  if not preview.ok:return preview
  if preview.candidate_hash!=changes.get("candidate_hash"):return fail("Advancement differs from the reviewed preview")
  return commit(slot,preview.candidate,entry.world)
 if not state.has("character_builder") or state.party.status!="draft" or state.has("mechanics") or state.has("expedition"):return fail("Starting characters are already committed. Use advancement; identities are preserved.")
 var candidate := state.duplicate(true)
 var b: Dictionary=candidate.character_builder
 if operation=="builder_content":
  if not b.confirmed.is_empty():return fail("Choose a content pack before saving any adventurer. Confirmed identities and builds will not be replaced.")
  if changes.get("pack_id")!=RulesRecords.NEW_PACK:return fail("Unknown reviewed character pack")
  var source := RulesRecords.new_character_registry()
  if not source.ready():return fail("Character content pack unavailable")
  var shadow := state.duplicate(true);shadow.party.status="ready"
  var prepared := RulesRecords.preview_preparation(shadow,source.rules_ref())
  if not prepared.ok:return prepared
  b.rules_ref=source.rules_ref();b.drafts=prepared.candidate.mechanics.records;b.revision+=1
  return commit(slot,candidate,entry.world)
 if operation=="builder_ready":
  if b.confirmed.size()!=3:return fail("Review and save each of your three adventurers first")
  candidate.party.status="ready";candidate.onboarding_stage="party_ready"
  candidate.mechanics={"schema_version":1,"rules_ref":b.rules_ref,"revision":1,"source_party_sha":RulesJson.digest(candidate.party),"records":b.drafts.duplicate(true)}
  b.drafts.clear();b.revision+=1
  return commit(slot,candidate,entry.world)
 if operation!="builder_save" or member<1 or member>3 or not changes.get("identity") is Dictionary or not changes.get("build") is Dictionary:return fail("A complete starting-character choice is required")
 var identity: Dictionary=changes.identity
 if identity.size()!=5 or not identity.has_all(["name","people_id","role_id","origin_burg","occupation_id"]) or not identity.name is String or not identity.people_id is String or not identity.role_id is String or not identity.occupation_id is String or not RulesJson.integer(identity.origin_burg,1,RulesJson.LIMIT):return fail("Invalid identity choices")
 var id: String=state.party_ids[member-1]
 var created := CharacterBuilderRecords.create(id,changes.build,state)
 if not created.ok:return created
 if not CharacterBuilderRecords.ancestry(identity.people_id,state).has(created.candidate.ancestry_ref):return fail("Choose a valid heritage for this ancestry")
 var c := CharacterBuilderRecords.context(entry.world,int(identity.origin_burg))
 if c.is_empty():return fail("Choose an eligible source-world personal origin")
 var jobs := CharacterBuilderRecords.backgrounds(entry.world,int(identity.origin_burg)).filter(func(row: Dictionary):return row.id==identity.occupation_id)
 if jobs.size()!=1:return fail("That background is unavailable in the chosen origin")
 # The existing pinned helper supplies public source facts, not mechanical builds.
 var scratch := state.duplicate(true)
 scratch.erase("party")
 scratch.origin={"state_id":c.cell.state,"home_burg_id":c.home.i,"province_id":c.cell.province,"home_id":entry.world.entity_id("burg",int(c.home.i))}
 var generated := _helper(entry,{"operation":"generate","campaign":scratch})
 if not generated.ok:return generated
 scratch.party=generated.party
 var edited := _helper(entry,{"operation":"edit","campaign":scratch,"slot":member,"changes":{"name":identity.name,"people_id":identity.people_id,"role_id":identity.role_id}})
 if not edited.ok:return edited
 var m: Dictionary=edited.party.members[member-1]
 var job: Dictionary=jobs[0]
 var f: Dictionary=m.generated_facts
 f.occupation_id=job.id;f.foundation_occupation_id=job.get("foundation",job.id)
 f.background.occupation=f.foundation_occupation_id
 var foundation := WorldOriginLore.read_json("res://data/world_enrichment/trhgd-expanded-v1.json")
 var basic: Dictionary=foundation.occupations.filter(func(row: Dictionary):return row.id==f.foundation_occupation_id)[0]
 var tags: Dictionary=c.tags.duplicate()
 for tag in basic.get("provides",[]):tags[tag]=true
 var training: Array=foundation.training.filter(func(row: Dictionary):return row.id==f.background.training and PartyRecords.satisfies(row.get("requires"),tags))
 if training.is_empty():training=foundation.training.filter(func(row: Dictionary):return PartyRecords.satisfies(row.get("requires"),tags))
 if training.is_empty():return fail("No compatible background training is available")
 f.background.training=training[0].id
 f.public_relationship={"kind":"party-companions","other_character_ids":state.party_ids.filter(func(other: String):return other!=id)}
 f.provenance.generator="Player-selected identity using pinned source-world public facts"
 m.biography="%s grew up in %s and worked as a %s. %s %s"%[m.name,c.home.name,str(job.get("label",job.get("key",job.id))).replace("-"," "),AdventureRecords.foundation_label("training",f.background.training),AdventureRecords.foundation_label("motivation",f.background.motivation)]
 candidate.party.members[member-1]=m
 for key in ["name","people_id","role_id","background_id"]:candidate.characters[member-1][key]=m[key]
 b.drafts[id]=created.candidate
 if not b.confirmed.has(id):b.confirmed.append(id)
 b.revision+=1
 return commit(slot,candidate,entry.world)
