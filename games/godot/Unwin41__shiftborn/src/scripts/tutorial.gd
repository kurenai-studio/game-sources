class_name Tutorial
extends CanvasLayer
## The guided first run. While it runs the normal waves wait; this node
## shows a prompt per [TutorialSteps] step and stages the enemies that
## step needs: a skull for the resistance lesson, sturdy spiders that
## live long enough to reach the player for the perfect shift.

## The tutorial is over (finished or skipped); the run may start.
signal finished

const LAYER := 5
const SKULL_SCENE := preload("res://scenes/enemy_skull.tscn")
const SPIDER_SCENE := preload("res://scenes/enemy.tscn")
const SKULL_DISTANCE := 120.0
const SPIDER_DISTANCE := 110.0
## Perfect-shift spiders must survive the attacks long enough to touch.
const SPIDER_HEALTH := 40.0
const MAX_SPIDERS := 2
const SPIDER_INTERVAL := 2.5
const PANEL_TOP := 56.0
const HINT_WIDTH := 360.0
## Seconds the closing message stays before the run starts.
const OUTRO_TIME := 1.6
const OUTRO_TEXT := "Survive until the boss at 4:30"
## Nobody dies in the tutorial: below this share of max HP, heal to full.
const SAFE_HEALTH_SHARE := 0.3

var _run: Run
var _player: Player
var _steps := TutorialSteps.new()
var _last_position: Vector2
var _staged: Array[Enemy] = []
var _spider_timer: float = 0.0
var _ending: bool = false
var _progress: Label
var _prompt: Label
var _hint: Label


func setup(run: Run, player: Player) -> void:
	_run = run
	_player = player


func _ready() -> void:
	layer = LAYER
	_build()
	_last_position = _player.global_position
	_player.form_changed.connect(func(_form: Player.Form) -> void: _on_event(&"shifted"))
	_player.perfect_shifted.connect(_on_event.bind(&"perfect"))
	_show_step()


func _physics_process(delta: float) -> void:
	if _ending:
		return
	if _player.health < _player.max_health * SAFE_HEALTH_SHARE:
		_player.heal(_player.max_health)
	var moved := _player.global_position.distance_to(_last_position)
	_last_position = _player.global_position
	if _steps.add_movement(moved):
		_advanced()
	if _steps.current == TutorialSteps.Step.PERFECT:
		_keep_spiders_coming(delta)


## Ends at once, e.g. from the pause menu.
func skip() -> void:
	if not _ending:
		_finish()


func _on_event(event: StringName) -> void:
	if not _ending and _steps.notify(event):
		_advanced()


func _advanced() -> void:
	AudioManager.play(&"card_pick")
	if _steps.is_done():
		_outro()
		return
	_show_step()
	if _steps.current == TutorialSteps.Step.RESIST:
		var skull := _stage(SKULL_SCENE, SKULL_DISTANCE)
		skull.died.connect(func(_enemy: Enemy) -> void: _on_event(&"resist_kill"))


func _keep_spiders_coming(delta: float) -> void:
	_spider_timer -= delta
	_staged = _staged.filter(func(enemy: Enemy) -> bool: return is_instance_valid(enemy) and enemy.health > 0.0)
	if _spider_timer > 0.0 or _staged.size() >= MAX_SPIDERS:
		return
	_spider_timer = SPIDER_INTERVAL
	var spider := _stage(SPIDER_SCENE, SPIDER_DISTANCE)
	spider.max_health = SPIDER_HEALTH
	spider.health = SPIDER_HEALTH


func _stage(scene: PackedScene, distance: float) -> Enemy:
	var enemy := _run.spawn_enemy(scene, distance)
	_staged.append(enemy)
	return enemy


func _show_step() -> void:
	_progress.text = ("Tutorial %s" % TutorialSteps.progress_text(_steps.current)).to_upper()
	_prompt.text = TutorialSteps.prompt(_steps.current).to_upper()
	_hint.text = TutorialSteps.hint(_steps.current).to_upper()


func _outro() -> void:
	_ending = true
	_progress.text = ""
	_prompt.text = "READY!"
	_hint.text = OUTRO_TEXT.to_upper()
	get_tree().create_timer(OUTRO_TIME, false).timeout.connect(_finish)


func _finish() -> void:
	_ending = true
	for enemy in _staged:
		if is_instance_valid(enemy):
			enemy.queue_free()
	_staged.clear()
	finished.emit()
	queue_free()


func _build() -> void:
	var column := UiKit.column()
	_progress = UiKit.label("", UiKit.SMALL_FONT_SIZE, UiKit.MUTED_COLOR)
	column.add_child(_progress)
	_prompt = UiKit.label("", UiKit.HEADER_FONT_SIZE, UiKit.ACCENT_COLOR)
	column.add_child(_prompt)
	_hint = UiKit.label("")
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size.x = HINT_WIDTH
	column.add_child(_hint)
	var panel := UiKit.panel(column)
	panel.modulate.a = 0.92
	# A full-width strip at the top that centers the panel in it.
	var anchor := CenterContainer.new()
	anchor.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	anchor.offset_top = PANEL_TOP
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor.add_child(panel)
	add_child(anchor)
