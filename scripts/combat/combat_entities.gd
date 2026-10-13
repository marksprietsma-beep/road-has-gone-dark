class_name CombatEntities
extends RefCounted
## Owned actors share the tactical turn list, commands, RNG and campaign journal.
static func placement(engine: TacticalCombat,battle: Dictionary,owner: Dictionary) -> Array:
 for tile in engine.neighbours(owner.position):
  if engine.inside(battle,tile) and engine.occupant(battle,tile).is_empty():return tile
 return []
static func add_permanent(engine: TacticalCombat,battle: Dictionary) -> bool:
 var owners: Array=battle.order.duplicate()
 for id in owners:
  var owner: Dictionary=battle.units[id]
  if owner.team!="party":continue
  for pet_id in owner.record.runtime.companions:
   var saved: Dictionary=owner.record.runtime.companions[pet_id]
   if int(saved.record.runtime.hp)<=0:continue
   var tile := placement(engine,battle,owner)
   if tile.is_empty():return false
   var definition := engine.registry.definition("creatures",saved.definition_id)
   var pet := engine.unit(pet_id,owner.name+"'s "+str(definition.name),owner.team,tile,saved.record.duplicate(true),definition.weapon_id)
   pet.entity={"owner_id":id,"definition_id":saved.definition_id,"kind":"companion","remaining":0,"active":true}
   battle.units[pet_id]=pet;battle.order.append(pet_id)
 return true
static func summon(engine: TacticalCombat,battle: Dictionary,actor: Dictionary,event: Dictionary) -> String:
 if actor.has("entity"):return "Owned creatures cannot summon other creatures."
 var active: Array=battle.units.values().filter(func(u: Dictionary):return u.get("entity",{}).get("owner_id")==actor.id and u.get("entity",{}).get("kind")=="summon" and engine.alive(u))
 if not active.is_empty():return "Dismiss or wait for your existing summon; one active summon per character."
 if battle.units.size()>=32:return "This encounter has reached its creature history limit."
 var tile := placement(engine,battle,actor)
 if tile.is_empty():return "No adjacent clear tile for the summoned creature."
 var definition := engine.registry.definition("creatures",event.definition_id)
 var snap: Dictionary=engine.characters.derive_character(actor.record).snapshot
 var level: int=clampi(int(snap.level)/2,1,10)
 var id: String=actor.id+":summon:"+str(battle.revision)
 var record := RulesEntities.creature_record(id,event.definition_id,level,engine.registry)
 if record.is_empty():return "Summon definition could not be resolved."
 var creature := engine.unit(id,actor.name+"'s "+str(definition.name),actor.team,tile,record,definition.weapon_id)
 creature.entity={"owner_id":actor.id,"definition_id":event.definition_id,"kind":"summon","remaining":int(event.rounds),"active":true}
 battle.units[id]=creature
 # A new summon acts after its caster; insertion leaves the caster's cursor unchanged.
 battle.order.insert(int(battle.cursor)+1,id)
 battle.log.append(actor.name+" summons "+str(definition.name)+" for "+str(event.rounds)+" global rounds.")
 return ""
static func round_start(engine: TacticalCombat,battle: Dictionary) -> void:
 for u in battle.units.values():
  if not u.has("entity") or not u.entity.active:continue
  if u.entity.kind=="summon":
   u.entity.remaining=maxi(0,int(u.entity.remaining)-1)
   if u.entity.remaining==0:u.entity.active=false;battle.log.append(u.name+" expires.")
  if not engine.alive(battle.units[u.entity.owner_id]):u.entity.active=false;battle.log.append(u.name+" withdraws with its fallen owner.")
static func capture(battle: Dictionary) -> void:
 for u in battle.units.values():
  if u.get("entity",{}).get("kind")!="companion":continue
  var owner: Dictionary=battle.units[u.entity.owner_id]
  owner.record.runtime.companions[u.id].record=u.record.duplicate(true)
static func validate(engine: TacticalCombat,battle: Dictionary) -> String:
 var owned := {};var summoned := {};var base: Array=[]
 if battle.get("entities_version")!=1:return "Owned-creature contract missing"
 for id in battle.order:
  var u: Dictionary=battle.units[id]
  if not u.has("entity"):base.append(id);continue
  var e: Variant=u.entity
  if not e is Dictionary or e.size()!=5 or not e.has_all(["owner_id","definition_id","kind","remaining","active"]) or not e.active is bool or e.kind not in ["companion","summon"] or not RulesJson.integer(e.remaining,0,20) or not battle.units.has(e.owner_id) or battle.units[e.owner_id].has("entity") or u.team!=battle.units[e.owner_id].team:return "Invalid creature ownership"
  var definition := engine.registry.definition("creatures",str(e.definition_id))
  if definition.is_empty() or u.weapon!=definition.weapon_id:return "Unknown creature definition"
  var owner: Dictionary=battle.units[e.owner_id]
  if owner.team!="party":return "Only adventurers own creatures"
  if e.kind=="companion":
   if id!=RulesEntities.identity(e.owner_id) or not owner.record.runtime.companions.has(id) or owner.record.runtime.companions[id].definition_id!=e.definition_id or RulesJson.digest(owner.record.runtime.companions[id].record)!=RulesJson.digest(u.record) or e.remaining!=0 or owned.has(e.owner_id):return "Persistent companion mismatch"
   owned[e.owner_id]=true
  else:
   if id!=str(e.owner_id)+":summon:"+str(id.get_slice(":summon:",1)) or not id.begins_with(str(e.owner_id)+":summon:") or not id.get_slice(":summon:",1).is_valid_int():return "Invalid summon identity"
   if u.record.advancement_history.size()!=clampi(int(engine.characters.derive_character(owner.record).snapshot.level)/2,1,10) or u.record.base_attributes!=definition.attributes or u.record.equipment!=[] or u.record.runtime.granted_features!=[definition.feature_id] or u.record.advancement_history.any(func(step: Dictionary):return step.class_id!="bond-creature") or not u.record.runtime.companions.is_empty():return "Invalid summon mechanics"
   if e.active and e.remaining==0:return "Expired summon still active"
   if engine.alive(u):
    if summoned.has(e.owner_id):return "Duplicate active summon"
    summoned[e.owner_id]=true
 for id in base:
  var owner: Dictionary=battle.units[id]
  if owner.team=="party":
   for pet_id in owner.record.runtime.companions:
    if int(owner.record.runtime.companions[pet_id].record.runtime.hp)>0 and not battle.units.has(pet_id):return "Missing living permanent companion"
 if base.size()!=3+battle.board.enemies.size():return "Original roster changed"
 for enemy in battle.board.enemies:
  if not base.has(enemy.id) or battle.units[enemy.id].team!="enemy":return "Authored enemy changed"
 return ""
