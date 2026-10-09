extends SceneTree
func _initialize() -> void:
 CombatArt.preference_path=OS.get_environment("GAME93_PREF")
 var phase := OS.get_environment("GAME93_PHASE")
 if phase=="write":
  if CombatArt.remember("navinius")!=OK: push_error("preference write failed");quit(1);return
 elif CombatArt.preferred()!="navinius": push_error("preference did not survive restart");quit(1);return
 print("PASS preference "+phase);quit()
