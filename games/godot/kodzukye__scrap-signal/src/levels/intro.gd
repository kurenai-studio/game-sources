extends Node

const LOGS: Array[String] = [
	"INITIALIZING SYSTEM...",
	"LAST SAVE: 847 DAYS AGO.",
	"MISSING DATA: 847 DAYS.",
	"UNIT SCRAP-09... BACK ONLINE.",
]

const CHAR_DELAY: float = 0.04
const LINE_PAUSE: float = 2.0
const CURSOR: String = "_"

var _full_text: String = ""
var _cursor_visible: bool = true

@onready var log_label: RichTextLabel = $CanvasLayer/LogLabel
@onready var background: ColorRect = $CanvasLayer/Background

func _ready() -> void:
	log_label.text = ""
	_start_cursor_blink()
	_play_sequence()

func _start_cursor_blink() -> void:
	var t: Tween = create_tween().set_loops()
	t.tween_callback(_toggle_cursor).set_delay(0.5)

func _toggle_cursor() -> void:
	_cursor_visible = !_cursor_visible
	log_label.text = _full_text + (CURSOR if _cursor_visible else " ")

func _play_sequence() -> void:
	for line in LOGS:
		await _type_line(line)
		await get_tree().create_timer(LINE_PAUSE).timeout
		_full_text += "\n"

	await get_tree().create_timer(1).timeout

	# Fade out
	var tween: Tween = create_tween()
	tween.tween_property(background, "modulate:a", 0.0, 1.2)
	await tween.finished
	if OS.get_name() == "Web":
		JavaScriptBridge.eval("document.querySelector('canvas').focus()")
	get_tree().change_scene_to_file("res://levels/entrepot/entrepot.tscn")

func _type_line(line: String) -> void:
	for i in line.length():
		_full_text += line[i]
		log_label.text = _full_text + CURSOR
		await get_tree().create_timer(CHAR_DELAY).timeout
