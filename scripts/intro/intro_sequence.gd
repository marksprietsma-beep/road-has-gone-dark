class_name IntroSequence
extends Control

signal intro_finished

const CARD_DATA_PATH := "res://data/intro/intro_cards.json"

@export_range(0.0, 5.0, 0.05) var fade_duration := 0.45

@onready var card_view: IntroCardView = %IntroCardView

var _cards: Array[Dictionary] = []
var _card_index := 0
var _transitioning := false
var _finished := false


func _ready() -> void:
	_cards = IntroCardLoader.load_cards(CARD_DATA_PATH)
	card_view.modulate.a = 0.0
	if _cards.is_empty():
		_show_end_message()
		return
	card_view.display_card(_cards[0])
	await _fade_to(1.0)


func _input(event: InputEvent) -> void:
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
	await _fade_to(0.0)
	_card_index += 1
	if _card_index >= _cards.size():
		card_view.display_end_message()
		_finished = true
		intro_finished.emit()
	else:
		card_view.display_card(_cards[_card_index])
	await _fade_to(1.0)
	_transitioning = false


func _skip_intro() -> void:
	if _transitioning or _finished:
		return
	_transitioning = true
	await _fade_to(0.0)
	card_view.display_end_message()
	_finished = true
	intro_finished.emit()
	await _fade_to(1.0)
	_transitioning = false


func _show_end_message() -> void:
	_finished = true
	card_view.display_end_message()
	intro_finished.emit()
	await _fade_to(1.0)


func _fade_to(target_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(card_view, "modulate:a", target_alpha, fade_duration)
	await tween.finished
