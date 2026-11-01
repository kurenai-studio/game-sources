## The end credits: white text rolling up a black screen, a soft chord underneath. When the roll is done (or after a
## button press, once it has been going for a moment) it asks for the first chapter again.
## Every CC-BY asset in ASSETS.md must be credited in THIRD_PARTY (a test checks the ledger against this file).
class_name Credits
extends CanvasLayer

signal finished
signal scene_requested(path: String)

## One line per third-party asset that needs a credit, e.g. "Rain loop by Jane Doe (CC-BY 4.0), freesound.org/s/123".
## There is none yet: every sound in the game is generated (tools/gen_audio.sh).
const THIRD_PARTY: Array[String] = []

@export var seconds_per_line := 1.1
@export_file("*.tscn") var next_scene := "res://levels/chapter1.tscn"
@export var change_scenes := true
## Seconds before a key press may skip the roll.
@export var skip_after := 2.0

var is_done := false

var _column: VBoxContainer
var _tween: Tween
var _age := 0.0
var _pad: AudioStreamPlayer


func lines() -> Array[String]:
	var all: Array[String] = [
		"DREAMRUN", "", "",
		"Created by", "tuanden0", "github.com/tuanden0", "",
		"Developed with", "Claude Code", "by Anthropic", "",
		"Made with Godot Engine", "godotengine.org", "",
		"Sound", "Generated for this game", "", ""]
	if not THIRD_PARTY.is_empty():
		all.append("With thanks to")
		all.append_array(THIRD_PARTY)
		all.append_array(["", ""])
	all.append_array(["Thank you for playing"])
	return all


func _ready() -> void:
	var back := ColorRect.new()
	back.color = Color.BLACK
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	_column = VBoxContainer.new()
	_column.name = "Column"
	_column.alignment = BoxContainer.ALIGNMENT_BEGIN
	_column.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_column.custom_minimum_size = Vector2(900.0, 0.0)
	_column.add_theme_constant_override(&"separation", 18)
	back.add_child(_column)
	for text in lines():
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override(&"font_size", 56 if text == "DREAMRUN" else 28)
		label.add_theme_color_override(&"font_color", Color(0.86, 0.87, 0.92))
		_column.add_child(label)
	var height := get_viewport().get_visible_rect().size.y
	_column.position.y = height
	_pad = AudioManager.add_loop(self, "room.ogg", -80.0)
	var roll := seconds_per_line * lines().size() + 4.0
	_tween = create_tween()
	_tween.tween_property(_pad, "volume_db", -20.0, 3.0)
	_tween.parallel().tween_property(_column, "position:y", -(lines().size() * 46.0 + 120.0), roll)
	_tween.tween_interval(1.5)
	_tween.tween_callback(_finish)


func _process(delta: float) -> void:
	_age += delta


func _unhandled_input(event: InputEvent) -> void:
	if _age >= skip_after and not is_done and (event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"pause") or event.is_action_pressed(&"interact")):
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	if is_done:
		return
	is_done = true
	if _tween != null:
		_tween.kill()
	finished.emit()
	scene_requested.emit(next_scene)
	if change_scenes and next_scene != "":
		get_tree().change_scene_to_file(next_scene)
