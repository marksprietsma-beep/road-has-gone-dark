class_name MapLayer
extends Node2D

var model: MapRenderModel
var zoom_band := 1

func setup(value: MapRenderModel) -> void:
	model = value
	queue_redraw()

func set_zoom_band(value: int) -> void:
	if zoom_band == value: return
	zoom_band = value
	queue_redraw()
