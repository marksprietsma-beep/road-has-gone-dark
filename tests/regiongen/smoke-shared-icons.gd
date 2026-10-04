extends SceneTree

func _initialize() -> void:
	var provider := MapIconProvider.new()
	for role in ["town", "hamlet", "inns", "fort", "monastery", "ruins", "cave", "mine", "encounters", "statues", "sacred-forests", "brigands", "hill-monsters"]:
		var texture: Texture2D = provider.texture_for(role)
		assert(texture != null)
		assert(texture.get_width() == 64 and texture.get_height() == 64)
	assert(provider.errors.is_empty())
	print("PASS: Godot loads all shared local and encounter Game-icons assets")
	quit(0)
