class_name RulesHooks
extends RefCounted
## Content can name a vetted hook, never a script path or executable expression.
const REGISTERED := ["veil_echo_v1"]

static func invoke(id: String, context: Dictionary) -> Dictionary:
 if not id in REGISTERED: return {"ok":false,"errors":[RulesJson.issue("hook.unregistered",id,"No registered deterministic handler")]}
 if context.get("trigger")!="illusion_disbelieved" or not context.get("source_character_id") is String or not context.get("apparent_id") is String or not context.get("observer_id") is String:
  return {"ok":false,"errors":[RulesJson.issue("hook.context",id,"Required illusion-disbelief context is missing")]}
 # GAME-33 may consume this descriptor through the same shared reaction cost.
 # It does not globally rewrite observer knowledge or create a physical creature.
 return {"ok":true,"effects":[{"op":"apparent_effect","descriptor":{"kind":"false_target","apparent_id":context.apparent_id+":echo","source_character_id":context.source_character_id,"intended_observer":context.observer_id,"senses":["sight"],"duration":{"type":"activation","amount":1,"expiry":"source_activation_start"},"collision":false}}],"events":[{"type":"feature_triggered","hook":id,"source_character_id":context.source_character_id}]}
