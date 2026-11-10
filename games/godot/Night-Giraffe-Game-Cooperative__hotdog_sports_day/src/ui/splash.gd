class_name Splash
extends Control
## The Night Giraffe Game Cooperative's card, as the studio's other games have
## it: the logo comes out of the dark to its tuning-up music. A tap skips it.
## The logo is drawn at the screen's full sharpness (the game itself is drawn
## small and scaled up, which would blur it), so while it shows the window
## scales its contents smoothly instead.

signal finished

var logo: TextureRect
var _done := false
var _mode := Window.CONTENT_SCALE_MODE_VIEWPORT


func _ready() -> void:
	var w := get_window()
	_mode = w.content_scale_mode
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	Kit.fill(self)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.04)
	Kit.fill(bg)
	add_child(bg)
	logo = TextureRect.new()
	logo.texture = load("res://assets/night_giraffe_logo.png")
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	Kit.pin(logo, Vector2(0.5, 0.5), Vector2(-90, -90), Vector2(180, 180))
	logo.pivot_offset = Vector2(90, 90)
	logo.modulate.a = 0.0
	logo.scale = Vector2(0.94, 0.94)
	add_child(logo)
	if ResourceLoader.exists("res://assets/audio/boot_tuning.mp3"):
		var p := AudioStreamPlayer.new()
		p.stream = load("res://assets/audio/boot_tuning.mp3")
		p.volume_db = linear_to_db(maxf(0.0001, Profile.music_volume))
		add_child(p)
		p.play()
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(logo, "modulate:a", 1.0, 1.4)
	tw.tween_property(logo, "scale", Vector2.ONE, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(1.8)
	tw.chain().tween_property(logo, "modulate:a", 0.0, 0.9)
	tw.chain().tween_callback(_go)


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch and event.pressed) or (event is InputEventKey and event.pressed):
		_go()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		_go()


func _go() -> void:
	if _done:
		return
	_done = true
	get_window().content_scale_mode = _mode
	finished.emit()
