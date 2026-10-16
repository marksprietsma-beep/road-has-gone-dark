extends SceneTree
## Focused continuation of the saved lawful histories; no full-suite repetition.
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var worker: Node=load("res://tests/character_wave_five/mechanics_driver.gd").new()
 worker.source=RulesRegistry.new()
 var loaded: Dictionary=worker.source.load_pack("res://data/rules/trhgd-character-v15.json")
 if not loaded.ok:worker.free();quit(1);return
 worker.kernel=RulesCharacter.new(worker.source)
 var saved: Dictionary=WorldOriginLore.read_json(OS.get_environment("GAME112W5_TEST_ROOT").path_join("saved.json"))
 worker.fixtures=saved.records
 worker.test_new_path_effects()
 print("PRESTIGE EFFECTS ",worker.checks," checks ",worker.failures," failures")
 var result: int=worker.failures;worker.free();quit(1 if result else 0)
