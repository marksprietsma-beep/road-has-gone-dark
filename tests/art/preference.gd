extends SceneTree
func _initialize() -> void:
 CombatArt.preference_path=OS.get_environment("GAME93_PREF")
 var phase := OS.get_environment("GAME93_PHASE")
 if phase=="write":
  if CombatArt.remember("navinius")!=OK: push_error("preference write failed");quit(1);return
 elif CombatArt.preferred()!="lpc": push_error("preference did not survive restart");quit(1);return
 var legacy := ConfigFile.new()
 if phase=="write":legacy.set_value("combat","art_style","navinius");legacy.save(CombatArt.preference_path)
 print("PASS legacy non-LPC preference gracefully defaults to LPC "+phase);quit()
