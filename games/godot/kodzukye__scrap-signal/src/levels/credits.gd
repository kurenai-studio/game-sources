extends Control

const SCROLL_SPEED: float = 20.0

const CREDITS: Array[String] = [
	"SCRAP SINGAL",
	"",
	"A game made for the Gamedev.js Jam 2026",
	"",
	"",
	"DEVELOPMENT",
	"kodzukye",
	"",
	"",
	"AMBIENT MUSIC",
	"MAC Senjah",
	"",
	"",
	"TOOLS",
	"Godot 4.6  -  Aseprite  -  Bandlab  -  Pixel Studio",
	"",
	"",
	"Thank you for playing.",
]

var _scrolling: bool = false

@onready var scroll: ScrollContainer = $ScrollContainer
@onready var credits_lbl: Label = $ScrollContainer/CreditsLabel
@onready var fade_rect: ColorRect = $FadeRect

func _ready() -> void:
	credits_lbl.text = "\n".join(CREDITS)
	credits_lbl.add_theme_constant_override("line_spacing", 12)

	# Démarre sous l'écran
	scroll.scroll_vertical = 0
	credits_lbl.position.y = get_viewport_rect().size.y

	fade_rect.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.2)
	tween.tween_callback(func(): _scrolling = true)

func _process(delta: float) -> void:
	if not _scrolling:
		return

	credits_lbl.position.y -= SCROLL_SPEED * delta

	# Fin du scroll — tout le texte est passé
	if credits_lbl.position.y + credits_lbl.size.y < 0:
		_end_credits()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_end_credits()
	if event is InputEventJoypadButton and event.pressed:
		_end_credits()

func _end_credits() -> void:
	if not _scrolling:
		return
	_scrolling = false
	var tween: Tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 1.0)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://levels/main_menu.tscn")
	)
