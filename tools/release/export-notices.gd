extends SceneTree
## Build-only notices from the exact Godot version used for the export.
func _initialize() -> void:
 var args := OS.get_cmdline_user_args()
 if args.size() != 2 or args[0] != "--output":
  printerr("Required -- --output <distribution directory>")
  quit(1)
  return
 var output: String = args[1]
 var licence := FileAccess.open(output.path_join("GODOT-LICENSE.txt"),FileAccess.WRITE)
 licence.store_string(Engine.get_license_text() + "\n")
 licence.close()
 var third_party := FileAccess.open(output.path_join("GODOT-THIRD-PARTY.json"),FileAccess.WRITE)
 third_party.store_string(JSON.stringify({"godot":Engine.get_version_info().string,"copyright":Engine.get_copyright_info(),"licences":Engine.get_license_info()},"  ") + "\n")
 third_party.close()
 quit(0)
