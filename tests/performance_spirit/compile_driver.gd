extends SceneTree
## Compile every dynamic review phase before any long native export.
func _initialize() -> void:
 var text := FileAccess.get_file_as_string("res://tests/performance_spirit/native_launch.gd")
 var pattern := RegEx.new();pattern.compile('"(res://[^"\\n]+\\.gd)"')
 var failed := false;var count := 0
 for entry in pattern.search_all(text):
  var path: String=entry.get_string(1);var script: GDScript=load(path);count+=1
  if script==null or not script.can_instantiate():failed=true;push_error("Uncompilable native phase: "+path)
 if count<2:failed=true;push_error("Native phase preflight did not find every launcher script")
 print("GAME149 phase compilation: ",count," scripts; failed=",failed)
 quit(1 if failed else 0)
