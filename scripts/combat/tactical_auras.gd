class_name TacticalAuras
extends TacticalCombat
## Thin v14 projection adapter. Frozen GAME-32 command/target/turn/RNG code is inherited.
func seal(b: Dictionary) -> Dictionary:
 if RulesWaveFour.enabled(registry):
  RulesWaveFour.project_auras(self,b)
  CombatEntities.capture(b)
 return super.seal(b)
func weapon_attack(b: Dictionary,a: Dictionary,t: Dictionary,reaction: bool,technique: String="") -> void:
 if RulesWaveFour.enabled(registry):RulesWaveFour.project_auras(self,b)
 super.weapon_attack(b,a,t,reaction,technique)
