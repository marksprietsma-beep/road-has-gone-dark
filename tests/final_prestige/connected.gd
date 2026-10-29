extends "res://tests/class_signatures/connected_driver.gd"
## Unedited earned identities, real commands and sole writer; no injected rewards.
func full_careers() -> bool:return OS.get_environment("FINAL_PRESTIGE_EARNED_FULL")=="1"
func earned_source_xp() -> int:return 1960 if full_careers()else 810
func wanted_actions() -> Dictionary:
 return {state.party_ids[0]:"eldritch-channel-wizard-enfeeble",state.party_ids[1]:"shadowdancer-technique-10"if full_careers()else"shadowdancer-technique-4",state.party_ids[2]:"dwarven-defender-technique-10"if full_careers()else"dwarven-defender-technique-4"}
func requires_manifestation() -> bool:return false
func signature_setup(battle: Dictionary,actor: Dictionary) -> Dictionary:
 var command: Dictionary={"actor_id":actor.id,"revision":battle.revision,"kind":"end"}
 if actor.id==state.party_ids[0]and not performed.has_all([state.party_ids[1],state.party_ids[2]]):return command
 if actor.id==state.party_ids[0]and not performed.has(actor.id):
  var engine:=TacticalAuras.new(state)
  for id in battle.order:
   var target: Dictionary=battle.units[id]
   if target.team==actor.team or not engine.alive(target):continue
   var attack: Dictionary={"actor_id":actor.id,"revision":battle.revision,"kind":wanted_actions()[actor.id],"target_id":id}
   if engine.command(battle,attack).ok:return attack
  if battle.budget.move==1:
   var paths: Array=engine.paths(battle,actor).values();var targets: Array=[]
   for target in battle.units.values():
    if target.team!=actor.team and engine.alive(target):targets.append(target)
   paths.sort_custom(func(a: Array,b: Array):return nearest(a.back(),targets)<nearest(b.back(),targets))
   if not paths.is_empty()and nearest(paths[0].back(),targets)<nearest(actor.position,targets):return {"actor_id":actor.id,"revision":battle.revision,"kind":"move","destination":paths[0].back()}
  return command
 return {}
func nearest(position: Array,targets: Array) -> int:
 var best := 1000
 for target in targets:best=mini(best,absi(int(position[0])-int(target.position[0]))+absi(int(position[1])-int(target.position[1])))
 return best
