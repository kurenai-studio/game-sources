## Root of a chapter: when the player reaches the exit it fades to black, emits `completed`, and then asks for the next
## scene (the wake-up cutscene). Tests turn `change_scenes` off and listen to `scene_requested` instead.
class_name Chapter
extends Node2D

signal completed
signal scene_requested(path: String)

@export var fade_time := 2.5
@export_file("*.tscn") var next_scene := "res://scenes/wake_up.tscn"
@export var change_scenes := true

var is_complete := false


func finish() -> void:
	if is_complete:
		return
	is_complete = true
	var layer := CanvasLayer.new()
	layer.layer = 30
	var veil := ColorRect.new()
	veil.color = Color(0.0, 0.0, 0.0, 0.0)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(veil)
	add_child(layer)
	var tween := create_tween()
	tween.tween_property(veil, "color:a", 1.0, fade_time)
	tween.tween_interval(0.8)
	tween.tween_callback(_go_next)
	completed.emit()


func _go_next() -> void:
	scene_requested.emit(next_scene)
	if change_scenes and next_scene != "":
		get_tree().change_scene_to_file(next_scene)
