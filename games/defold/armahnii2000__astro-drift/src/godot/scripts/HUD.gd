class_name HUD
extends CanvasLayer

const CONTROLS_TEXT := "← → rotate   ·   ↑ thrust   ·   ↓ brake   ·   Del fire   ·   Ins CRT   ·   End restart   ·   Esc quit"

var _score_label: Label
var _lives_label: Label
var _message_label: Label
var _controls_label: Label

func _ready() -> void:
	_score_label = _make_label(Vector2(20, 14), 26, Color(0.92, 0.96, 1.0))
	_lives_label = _make_label(Vector2(20, 48), 20, Color(0.85, 0.9, 1.0))
	_message_label = _make_label(Vector2(0, 280), 32, Color(1.0, 0.9, 0.7))
	_message_label.size = Vector2(1280, 160)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_controls_label = _make_label(Vector2(0, 688), 16, Color(0.62, 0.7, 0.85))
	_controls_label.size = Vector2(1280, 24)
	_controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controls_label.text = CONTROLS_TEXT

func _make_label(pos: Vector2, size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	add_child(lbl)
	return lbl

func update_stats(score: int, lives: int) -> void:
	_score_label.text = "Score: %d" % score
	_lives_label.text = "Lives: %d" % lives

func show_message(msg: String) -> void:
	_message_label.text = msg
