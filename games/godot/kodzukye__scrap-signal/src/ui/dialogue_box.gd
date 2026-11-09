class_name DialogueBox
extends CanvasLayer

signal dialogue_finished()

@onready var speaker_name  : Label        = $SpeakerName
@onready var dialogue_text : RichTextLabel = $Panel/DialogueText
@onready var continue_hint : Label = $Panel/ContinueHint

const TYPEWRITER_SPEED: float = 0.03  # secondes par caractère

var _lines    : Array[Dictionary]  = []
var _index    : int    = 0
var _typing   : bool   = false
var _finished : bool = false

func _ready() -> void:
	get_tree().paused = false
	add_to_group("dialogue_box")
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

func start(lines: Array[Dictionary]) -> void:
	_lines  = lines
	_index  = 0
	show()
	get_tree().paused = true
	_show_line()

func _show_line() -> void:
	if _index >= _lines.size():
		_finish()
		return
	var line : Dictionary = _lines[_index]
	speaker_name.text  = line.get("name", "")
	dialogue_text.text = ""
	_typing = true
	_typewrite(line.get("text", ""))

func _typewrite(text: String) -> void:
	continue_hint.visible = false
	dialogue_text.text = ""
	for i in text.length():
		if not _typing:
			dialogue_text.text = text
			continue_hint.visible = true
			return
		dialogue_text.text += text[i]
		await get_tree().create_timer(TYPEWRITER_SPEED).timeout
	_typing = false
	continue_hint.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if _typing:
			_typing = false
		else:
			_index += 1
			_show_line()

func _finish() -> void:
	get_tree().paused = false
	hide()
	dialogue_finished.emit()
