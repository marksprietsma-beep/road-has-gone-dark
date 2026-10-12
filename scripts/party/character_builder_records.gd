class_name CharacterBuilderRecords
extends RefCounted
## Creator policy and source-backed identity validation, never a second rules engine.
const POLICY := "res://data/characters/builder-v1.json"
static func kernel(context: Dictionary = {}) -> RulesCharacter: return RulesCharacter.new(RulesRecords.registry(context))
static func reason(result: Dictionary) -> String:
 if result.get("ok",false): return ""
 if result.has("error"): return str(result.error)
 return "; ".join(result.get("errors",[]).map(func(e: Dictionary):
  var text := str(e.get("detail","Invalid choice"))
  if not str(e.get("id","")).is_empty():text=str(e.id).replace("-"," ")+": "+text
  if e.has("required"):text+=" · needs "+str(e.required)
  if e.has("current"):text+=" · current "+str(e.current)
  if e.has("actual"):text+=" · actual "+str(e.actual)
  if e.has("expected"):text+=" · expected "+str(e.expected)
  return text))
static func ancestry(people_id: String,context: Dictionary = {}) -> Array:
 var source := RulesRecords.registry(context)
 var rows := source.ids("ancestries").filter(func(id: String):return source.definition("ancestries",id).people_id==people_id)
 rows.sort_custom(func(a: String,b: String):return a.begins_with("heritage-") if a.begins_with("heritage-")!=b.begins_with("heritage-") else a<b)
 return rows
const CORE_POLICY := "res://data/characters/builder-v2.json"
static func policy(context: Dictionary) -> String:
 return CORE_POLICY if RulesRecords.registry(context).rules_ref().get("engine_schema")==3 else POLICY
static func threshold(level: int,context: Dictionary={}) -> int:
 var rows: Array=WorldOriginLore.read_json(policy(context)).xp_thresholds
 return int(rows[level-1]) if level>=1 and level<=rows.size() else RulesJson.LIMIT
static func xp(state: Dictionary,id: String) -> int:
 var amount := 0
 for progression_key in ["sandbox","first_adventure"]:
  var progression: Variant=state.get(progression_key,{})
  if not progression is Dictionary:return 0
  var characters: Variant=progression.get("characters",{})
  if not characters is Dictionary:return 0
  var character: Variant=characters.get(id,{})
  if not character is Dictionary or not RulesJson.integer(character.get("xp",0),0,RulesJson.LIMIT):return 0
  amount+=int(character.get("xp",0))
 return mini(amount,RulesJson.LIMIT)
static func record(state: Dictionary,id: String) -> Dictionary:
 return state.get("mechanics",{}).get("records",{}).get(id,state.get("character_builder",{}).get("drafts",{}).get(id,{}))
static func definition(record_value: Dictionary) -> Dictionary:
 var step: Dictionary=record_value.advancement_history[0]
 var definition := {"attributes":record_value.base_attributes.duplicate(true),"ancestry_ref":record_value.ancestry_ref,"background_ref":record_value.background_ref,"class_id":step.class_id,"skill_allocations":step.skill_allocations.duplicate(true),"feat_id":step.feat_id,"equipment":record_value.equipment.duplicate(),"prepared_abilities":record_value.choices.prepared_abilities.duplicate()}
 if record_value.rules_ref.get("engine_schema")==3:definition.spell_preparations=record_value.choices.spell_preparations.duplicate(true)
 if RulesCareer.enabled(RulesRecords.registry(record_value)):
  definition.specialisations=step.specialisations.duplicate(true);definition.bonus_feats=step.bonus_feats.duplicate()
 return definition
static func create(id: String,draft: Dictionary,context: Dictionary = {}) -> Dictionary:
 var core: bool=RulesRecords.registry(context).rules_ref().get("engine_schema")==3
 var career := RulesCareer.enabled(RulesRecords.registry(context))
 if draft.size()!=((11 if career else 9) if core else 8) or not draft.has_all(["attributes","ancestry_ref","background_ref","class_id","skill_allocations","feat_id","equipment","prepared_abilities"]) or not draft.attributes is Dictionary or not draft.skill_allocations is Dictionary or not draft.equipment is Array or not draft.prepared_abilities is Array: return {"ok":false,"error":"Exactly eight typed starting-build fields required"}
 for key in ["ancestry_ref","background_ref","class_id","feat_id"]:
  if not draft[key] is String:return {"ok":false,"error":"Build references must be content IDs"}
 var base := kernel(context).create(id,draft.attributes,draft.ancestry_ref,draft.background_ref)
 base.equipment=draft.equipment.duplicate()
 var choice := {"class_id":draft.class_id,"skill_allocations":draft.skill_allocations,"feat_id":draft.feat_id,"attribute_increase":""}
 if career:
  if not draft.get("specialisations") is Dictionary or not draft.get("bonus_feats") is Array:return {"ok":false,"error":"Review class specialisations and all feat grants"}
  choice.specialisations=draft.specialisations.duplicate(true);choice.bonus_feats=draft.bonus_feats.duplicate()
 var result := kernel(context).preview_advancement(base,choice)
 if not result.ok:return result
 if not result.candidate.equipment.any(func(item: Variant):return item is String and RulesRecords.registry(context).definition("equipment",item).get("kind")=="weapon"):return {"ok":false,"error":"Choose at least one starting weapon"}
 result.candidate.choices.prepared_abilities=draft.prepared_abilities.duplicate()
 if core:
  if not draft.get("spell_preparations") is Dictionary:return {"ok":false,"error":"Choose prepared spell copy counts"}
  result.candidate.choices.spell_preparations=draft.spell_preparations.duplicate(true)
  RulesCoreContent.refill_prepared(result.candidate,RulesRecords.registry(context))
 var derived := kernel(context).derive_character(result.candidate)
 if not derived.ok:return derived
 result.snapshot=derived.snapshot
 return result
static func context(world: GameWorldTemplate,burg: int) -> Dictionary:
 var home := world.get_record("burg",burg)
 if home.is_empty() or not world.validate_origin(int(home.state),burg):return {}
 var cell := world.get_record("cell",int(home.cell))
 var profiles: Dictionary=WorldOriginLore.read_json(OriginProfiles.directory(world).path_join("enrichment.json")).get("profiles",{})
 var local: Dictionary=profiles.get("hometowns",{}).get(str(burg),{})
 if local.is_empty():return {}
 var tags := {}
 for tag in local.source_context.tags:tags[tag]=true
 if int(cell.get("religion",0))>0:tags["religion"]=true
 var region: Dictionary=profiles.get("regions",{}).get(str(local.parents.region),{})
 if region.get("source_context",{}).get("tags",[]).has("mine"):tags["regional-mine"]=true
 return {"home":home,"cell":cell,"tags":tags}
static func backgrounds(world: GameWorldTemplate,burg: int) -> Array:
 var c := context(world,burg)
 if c.is_empty():return []
 var foundation := WorldOriginLore.read_json("res://data/world_enrichment/trhgd-expanded-v1.json")
 var pack := WorldOriginLore.read_json(WorldPeoples.PACK)
 var rows: Array=foundation.occupations.duplicate(true)+pack.occupations.duplicate(true)
 return rows.filter(func(row: Dictionary):
  var basic: Array=foundation.occupations.filter(func(b: Dictionary):return b.id==row.get("foundation",row.id))
  return basic.size()==1 and PartyRecords.satisfies(row.get("requires"),c.tags) and PartyRecords.satisfies(basic[0].get("requires"),c.tags))
static func validate_party(state: Dictionary,world: GameWorldTemplate) -> String:
 var p: Variant=state.get("party")
 if not p is Dictionary or p.size()!=7 or (p.get("schema_version")!=2 and p.get("schema_version")!=3) or p.get("generator_version")!=("player-party-2" if p.get("schema_version")==3 else "player-party-1") or not p.get("members") is Array or p.members.size()!=3 or not state.get("characters") is Array or state.characters.size()!=3 or not state.get("party_ids") is Array or state.party_ids.size()!=3:return "builder.party: Invalid player-party schema"
 # The v1 contract is shared; only player parties opt into personal origins.
 for i in 3:
  var m: Variant=p.members[i]
  if not state.characters[i] is Dictionary or not m is Dictionary or not m.get("origin_refs") is Dictionary or m.get("character_id")!=state.characters[i].get("id") or m.get("slot")!=i+1 or m.character_id!=state.party_ids[i] or not m.get("generated_facts") is Dictionary or m.get("name")!=state.characters[i].get("name"):return "builder.identity: Invalid personal identity"
  if not m.get("character_id") is String or not state.party_ids[i] is String or not RulesJson.integer(m.origin_refs.get("burg_id"),1,RulesJson.LIMIT) or not RulesJson.integer(m.get("background_variant"),0,RulesJson.LIMIT):return "builder.identity: Invalid typed origin/identity"
  for key in ["people_id","role_id","background_id"]:
   if m.get(key)!=state.characters[i].get(key):return "builder.identity: Underlying character mirror changed"
  if not m.get("name") is String or range(m.name.length()).any(func(character_index: int):return m.name.unicode_at(character_index)<32) or m.name.contains("<") or m.name.contains(">"):return "builder.name: Use a readable character name"
  var expected_background: String=m.character_id+":background:"+JSON.stringify(["trhgd-party-1",p.get("content_pack_sha"),int(m.get("background_variant",-1)),m.get("people_id"),m.get("role_id")]).sha256_text().left(20)
  if m.get("background_id")!=expected_background:return "builder.background: Invalid stable background identity"
  var home := world.get_record("burg",int(m.origin_refs.get("burg_id",-1)))
  if home.is_empty() or not world.validate_origin(int(home.get("state",-1)),int(home.i)):return "builder.origin: Origin is not an eligible source-world hometown"
  if m.generated_facts.get("public_relationship")!={"kind":"party-companions","other_character_ids":state.party_ids.filter(func(id: String):return id!=m.character_id)}:return "builder.relationship: Invalid companion references"
 return PartyRecords.validate_legacy(state,world,true,p.schema_version==3)
static func validate(state: Dictionary) -> String:
 if not state.has("character_builder"):return "builder.missing: Player party requires creator records" if (state.get("party",{}).get("schema_version")==2 or state.get("party",{}).get("schema_version")==3) else ""
 var b: Variant=state.character_builder
 if not b is Dictionary or b.size()!=8 or not b.has_all(["version","rules_ref","revision","confirmed","drafts","advancements","policy_sha","initial_levels"]) or b.version!=1 or RulesJson.normalize(b.rules_ref)!=RulesRecords.registry(state).rules_ref() or b.policy_sha!=FileAccess.get_sha256(policy(state)) or not RulesJson.integer(b.revision,1,RulesJson.LIMIT) or not b.confirmed is Array or not b.drafts is Dictionary or not b.advancements is Array or not b.initial_levels is Dictionary:return "builder.schema: Invalid creator policy/schema"
 if b.confirmed.size()!=RulesRegistry._unique_count(b.confirmed) or not b.confirmed.all(func(id: Variant):return id is String and state.party_ids.has(id)):return "builder.confirmation: Invalid saved confirmation"
 var ready: bool=state.party.status=="ready"
 if ready and (state.party.schema_version==2 or state.party.schema_version==3) and state.get("mechanics",{}).get("source_party_sha")!=RulesJson.digest(state.party):return "builder.identity: Committed party identity changed"
 if ready and not b.drafts.is_empty() or not ready and b.drafts.size()!=3:return "builder.authority: Drafts must be transferred into mechanics exactly once"
 if (state.party.schema_version==2 or state.party.schema_version==3) and ready and b.confirmed.size()!=3:return "builder.confirmation: Confirm every starting adventurer"
 for m in state.party.members:
  var r := record(state,m.character_id)
  if r.is_empty() or r.get("character_id")!=m.character_id or not kernel(state).validate_build(r).ok:return "builder.build: Invalid exact-pinned build"
  if not ancestry(m.people_id,state).has(r.ancestry_ref):return "builder.ancestry: Mechanical heritage conflicts with selected ancestry"
  if not ready and r.advancement_history.size()!=1:return "builder.start: Starting level is exactly one"
  if not b.initial_levels.has(m.character_id) or not RulesJson.integer(b.initial_levels[m.character_id],1,r.advancement_history.size()):return "builder.history: Missing grandfathered initial level"
 var levels: Dictionary=b.initial_levels.duplicate(true)
 for a in b.advancements:
  if not a is Dictionary or a.size()!=4 or not a.has_all(["character_id","level","xp","choice_sha"]) or not levels.has(a.character_id) or a.level!=int(levels[a.character_id])+1 or not RulesJson.integer(a.xp,threshold(int(a.level),state),xp(state,a.character_id)):return "builder.progression: Unfunded or repeated advancement"
  var r := record(state,a.character_id)
  if int(a.level)>r.advancement_history.size() or a.choice_sha!=RulesJson.digest(r.advancement_history[int(a.level)-1]):return "builder.progression: Class history changed"
  levels[a.character_id]=int(a.level)
 for id in levels:
  if int(levels[id])!=record(state,id).advancement_history.size():return "builder.progression: Unrecorded advancement"
 return ""
static func preview_advancement(state: Dictionary,id: String,choice: Dictionary) -> Dictionary:
 if AdventureService.away(state):return {"ok":false,"error":"Return home before advancing a character"}
 var r := record(state,id)
 if r.is_empty():return {"ok":false,"error":"Saved mechanics required"}
 var next: int=r.advancement_history.size()+1
 if xp(state,id)<threshold(next,state):return {"ok":false,"error":"Level %d requires %d total journey XP; this character has %d"%[next,threshold(next,state),xp(state,id)]}
 var result := RulesRecords.preview_advancement(state,id,choice)
 if not result.ok:return result
 if not result.candidate.has("character_builder"):
  result.candidate.character_builder={"version":1,"rules_ref":RulesRecords.registry(state).rules_ref(),"revision":1,"confirmed":[],"drafts":{},"advancements":[],"policy_sha":FileAccess.get_sha256(policy(state)),"initial_levels":{}}
  for character in state.characters:result.candidate.character_builder.initial_levels[character.id]=state.mechanics.records[character.id].advancement_history.size()
 var b: Dictionary=result.candidate.character_builder
 b.revision+=1
 b.advancements.append({"character_id":id,"level":next,"xp":xp(state,id),"choice_sha":RulesJson.digest(result.candidate.mechanics.records[id].advancement_history.back())})
 result.candidate_hash=RulesJson.digest(result.candidate)
 return result
