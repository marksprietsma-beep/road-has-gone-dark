extends Control

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

@onready var content: VBoxContainer = %Content
@onready var back_button: Button = %BackButton


func _ready() -> void:
	GameUI.install(self)
	back_button.pressed.connect(_return_to_menu)
	content.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(content, "modulate:a", 1.0, 0.35)
	await tween.finished
	back_button.grab_focus()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_return_to_menu()


func _return_to_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
