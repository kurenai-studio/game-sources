extends Control

@onready var press_label: Label = $CenterContainer/VBoxContainer/PressLabel
@onready var fade_rect: ColorRect = $FadeRect

var _can_start: bool = false

func _ready() -> void:
	AudioManager.stop_ambiance() 
	modulate.a = 1.0
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.modulate = Color(1, 1, 1, 1)
	fade_rect.modulate.a = 1.0
	fade_rect.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.2)
	tween.tween_callback(func(): _can_start = true)
	_blink_prompt()

func _blink_prompt() -> void:
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(press_label, "modulate:a", 0.0, 0.6)
	tween.tween_interval(0.1)
	tween.tween_property(press_label, "modulate:a", 1.0, 0.6)
	tween.tween_interval(0.2)

func _unhandled_input(event: InputEvent) -> void:
	if not _can_start:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_go_to_intro()
	if event is InputEventJoypadButton and event.pressed:
		_go_to_intro()

func _go_to_intro() -> void:
	_can_start = false
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.8)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://levels/intro.tscn")
	)
