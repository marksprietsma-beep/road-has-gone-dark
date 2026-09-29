class_name MainMenu
extends Control

const NEW_GAME_SCENE := "res://scenes/world/new_game_placeholder.tscn"
const SETTINGS_SCENE := "res://scenes/ui/settings_menu.tscn"

@export_range(0.0, 2.0, 0.05) var fade_duration := 0.45

@onready var menu_content: VBoxContainer = %MenuContent
@onready var new_game_button: Button = %NewGameButton
@onready var settings_button: Button = %SettingsButton
@onready var exit_button: Button = %ExitButton

var _transitioning := false


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	menu_content.modulate.a = 0.0
	await _fade_menu(1.0)
	new_game_button.grab_focus()


func _on_new_game_pressed() -> void:
	await _change_scene_with_fade(NEW_GAME_SCENE)


func _on_settings_pressed() -> void:
	await _change_scene_with_fade(SETTINGS_SCENE)


func _on_exit_pressed() -> void:
	if _transitioning:
		return
	get_tree().quit()


func _change_scene_with_fade(scene_path: String) -> void:
	if _transitioning:
		return

	_transitioning = true
	await _fade_menu(0.0)
	get_tree().change_scene_to_file(scene_path)


func _fade_menu(target_alpha: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(menu_content, "modulate:a", target_alpha, fade_duration)
	await tween.finished
