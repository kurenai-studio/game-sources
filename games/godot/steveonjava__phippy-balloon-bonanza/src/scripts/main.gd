extends Node2D
class_name Main

const BG_TEX := preload("res://assets/pixel/phippy-rescue/island_background.png")
const SUN_TEX := preload("res://assets/pixel/phippy-rescue/sun.png")

const SCREEN_W := 1024.0
const SCREEN_H := 600.0
const GAME_TIME := 45.0

enum State { TITLE, PLAY, OVER }

var _state := State.TITLE
var _player: Player
var _balloon_parent: Node2D
var _spawn_timer: Timer
var _game_timer: Timer
var _score := 0
var _time_left := GAME_TIME
var _spawn_index := 0

# HUD
var _hud: CanvasLayer
var _score_label: Label
var _time_label: Label
var _title_panel: ColorRect
var _title_label: Label
var _over_panel: ColorRect
var _over_label: Label


func _ready() -> void:
	_setup_input()
	_build_world()
	_build_hud()
	_show_title()


func _setup_input() -> void:
	for a in ["move_left", "move_right", "restart"]:
		if not InputMap.has_action(a):
			InputMap.add_action(a)
	_add_key("move_left", KEY_LEFT)
	_add_key("move_left", KEY_A)
	_add_key("move_right", KEY_RIGHT)
	_add_key("move_right", KEY_D)
	_add_key("restart", KEY_R)


func _add_key(action: String, keycode: int) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action, ev)


func _build_world() -> void:
	# Background island, scaled to fill the screen (integer 4x for crisp pixels).
	var bg := Sprite2D.new()
	bg.texture = BG_TEX
	bg.centered = false
	bg.scale = Vector2(SCREEN_W / 256.0, SCREEN_H / 150.0)
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(bg)

	# A friendly sun in the corner.
	var sun := Sprite2D.new()
	sun.texture = SUN_TEX
	sun.scale = Vector2(2.0, 2.0)
	sun.position = Vector2(SCREEN_W - 80.0, 70.0)
	sun.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sun)

	# Container keeps the scene tree tidy.
	_balloon_parent = Node2D.new()
	_balloon_parent.name = "Balloons"
	add_child(_balloon_parent)

	# The hero.
	_player = Player.new()
	_player.screen_w = SCREEN_W
	_player.position = Vector2(SCREEN_W / 2.0, SCREEN_H - 70.0)
	add_child(_player)

	# Game countdown timer.
	_game_timer = Timer.new()
	_game_timer.wait_time = 0.1
	_game_timer.timeout.connect(_tick)
	add_child(_game_timer)

	# Balloon spawner.
	_spawn_timer = Timer.new()
	_spawn_timer.timeout.connect(_spawn_balloon)
	add_child(_spawn_timer)


func _build_hud() -> void:
	_hud = CanvasLayer.new()
	add_child(_hud)

	var font_size := 26

	_score_label = _make_label("Pods: 0", font_size)
	_score_label.position = Vector2(20, 12)
	_hud.add_child(_score_label)

	_time_label = _make_label("Time: %d" % int(GAME_TIME), font_size)
	_time_label.position = Vector2(SCREEN_W - 180.0, 12)
	_hud.add_child(_time_label)

	# Title overlay.
	_title_panel = ColorRect.new()
	_title_panel.color = Color(0.05, 0.08, 0.18, 0.78)
	_title_panel.size = Vector2(SCREEN_W, SCREEN_H)
	_hud.add_child(_title_panel)

	_title_label = Label.new()
	_title_label.text = "PHIPPY BALLOON BONANZA\n\nCatch the floating pods before time runs out!\n\nMove:  Left / Right  (or A / D)\n\nPress  SPACE  to start"
	_title_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 30)
	_title_label.size = Vector2(SCREEN_W, SCREEN_H)
	_title_label.position = Vector2(0, 0)
	_title_panel.add_child(_title_label)

	# Game-over overlay.
	_over_panel = ColorRect.new()
	_over_panel.color = Color(0.05, 0.08, 0.18, 0.82)
	_over_panel.size = Vector2(SCREEN_W, SCREEN_H)
	_over_panel.visible = false
	_hud.add_child(_over_panel)

	_over_label = Label.new()
	_over_label.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	_over_label.vertical_alignment = VerticalAlignment.VERTICAL_ALIGNMENT_CENTER
	_over_label.add_theme_font_size_override("font_size", 34)
	_over_label.size = Vector2(SCREEN_W, SCREEN_H)
	_over_panel.add_child(_over_label)


func _make_label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	return l


func _show_title() -> void:
	_state = State.TITLE
	_title_panel.visible = true
	_over_panel.visible = false
	_game_timer.stop()
	_spawn_timer.stop()


func _start_game() -> void:
	_score = 0
	_time_left = GAME_TIME
	_spawn_index = 0
	for b in _balloon_parent.get_children():
		b.queue_free()
	_player.position = Vector2(SCREEN_W / 2.0, SCREEN_H - 70.0)
	_update_hud()
	_title_panel.visible = false
	_over_panel.visible = false
	_state = State.PLAY
	_game_timer.start()
	_spawn_timer.start(_spawn_interval())


func _spawn_interval() -> float:
	# Pods come faster as the clock runs down.
	var progress := 1.0 - (_time_left / GAME_TIME)
	return lerpf(1.1, 0.45, progress)


func _spawn_balloon() -> void:
	if _state != State.PLAY:
		return
	var b := Balloon.new()
	b.screen_h = SCREEN_H
	b.fall_speed = randf_range(95.0, 170.0)
	b.color_index = _spawn_index
	_spawn_index += 1
	var margin := 70.0
	b.position = Vector2(randf_range(margin, SCREEN_W - margin), -70.0)
	_balloon_parent.add_child(b)
	b.scored.connect(_on_balloon_scored)
	_spawn_timer.start(_spawn_interval())


func _on_balloon_scored() -> void:
	# The signal arrives before the balloon moved, so use the player position for feedback.
	_score += 1
	_update_hud()
	var fx_pos := Vector2(_player.position.x, _player.position.y - 60.0)
	_pop_particles(fx_pos)
	_floating_score(fx_pos)


func _pop_particles(pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.5
	p.amount = 12
	p.direction = Vector2(0, -1)
	p.spread = 60.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 160.0
	p.gravity = Vector2(0, 240)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = Color(randf(), randf_range(0.6, 1.0), 1.0)
	_balloon_parent.add_child(p)
	# Clean up after the burst finishes.
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _floating_score(pos: Vector2) -> void:
	var l := _make_label("+1", 30)
	l.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	l.position = pos - Vector2(15, 0)
	_hud.add_child(l)
	var t := create_tween()
	t.tween_property(l, "position:y", l.position.y - 70.0, 0.8).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.8)
	t.tween_callback(l.queue_free)


func _tick() -> void:
	_time_left = maxf(0.0, _time_left - _game_timer.wait_time)
	_update_hud()
	if _time_left <= 0.0:
		_end_game()


func _update_hud() -> void:
	_score_label.text = "Pods: %d" % _score
	_time_label.text = "Time: %d" % int(ceilf(_time_left))


func _end_game() -> void:
	_state = State.OVER
	_game_timer.stop()
	_spawn_timer.stop()
	for b in _balloon_parent.get_children():
		if b is Balloon:
			b.set_process(false)
	_over_label.text = "GAME OVER!\n\nYou caught %d pods!\n\nPress  R  to play again" % _score
	_over_panel.visible = true


func _unhandled_input(_event: InputEvent) -> void:
	if _state == State.TITLE and Input.is_action_just_pressed("ui_accept"):
		_start_game()
	elif _state == State.OVER and Input.is_action_just_pressed("restart"):
		_start_game()
