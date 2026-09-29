class_name IntroSequence
extends Control

signal intro_finished

const CARD_DATA_PATH := "res://data/intro/intro_cards.json"
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

@export_range(0.0, 5.0, 0.05) var fade_duration := 0.45

@onready var card_view: IntroCardView = %IntroCardView
@onready var auto_advance_timer: Timer = %AutoAdvanceTimer

var _cards: Array[Dictionary] = []
var _card_index := 0
var _transitioning := false
var _finished := false


func _ready() -> void:
	_transitioning = true
	auto_advance_timer.timeout.connect(_on_auto_advance_timeout)
	_cards = IntroCardLoader.load_cards(CARD_DATA_PATH)
	card_view.modulate.a = 0.0

	if _cards.is_empty():
		await _finish_intro()
		return

	card_view.display_card(_cards[0])
	await _fade_to(1.0)
	_transitioning = false
	_start_auto_advance()


func _input(event: InputEvent) -> void:
	if _finished or _transitioning:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_skip_intro()
		elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			_advance()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		_advance()


func _advance() -> void:
	if _transitioning or _finished:
		return

	_transitioning = true
	auto_advance_timer.stop()
	await _fade_to(0.0)
	_card_index += 1

	if _card_index >= _cards.size():
		await _finish_intro(false)
		return

	card_view.display_card(_cards[_card_index])
	await _fade_to(1.0)
	_transitioning = false
	_start_auto_advance()


func _skip_intro() -> void:
	if _transitioning or _finished:
		return
	await _finish_intro()


func _finish_intro(fade_out_first: bool = true) -> void:
	if _finished:
		return

	_finished = true
	_transitioning = true
	auto_advance_timer.stop()

	if fade_out_first and card_view.modulate.a > 0.0:
		await _fade_to(0.0)

	intro_finished.emit()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _start_auto_advance() -> void:
	if _finished or _transitioning or _card_index >= _cards.size():
		return

	var duration := float(_cards[_card_index].get("display_duration", 0.0))
	if duration > 0.0:
		auto_advance_timer.start(duration)


func _on_auto_advance_timeout() -> void:
	_advance()


func _fade_to(target_alpha: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(card_view, "modulate:a", target_alpha, fade_duration)
	await tween.finished
