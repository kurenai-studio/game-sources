class_name Run
extends Node2D
## Run controller: wires player, spawner and HUD, turns kills into XP and
## level-up card picks. Normal waves (with two mini-bosses) run until
## [constant BOSS_TIME]; then the final boss arrives. Killing it wins the
## run, dying loses it.

const BOSS_TIME := 270.0
const BOSS_SCENE := preload("res://scenes/boss.tscn")
## The boss appears this far from the player, inside the screen edge.
const BOSS_SPAWN_DISTANCE := 190.0
## Mini-bosses by run time. Spawned here rather than by a SpawnWave, so
## the spawner's alive cap can never drop them.
const MINI_BOSSES: Array[Dictionary] = [
	{time = 105.0, scene = preload("res://scenes/enemy_cyclops.tscn")},
	{time = 195.0, scene = preload("res://scenes/enemy_giant_spirit.tscn")},
]
## Mini-bosses appear this far away, just off screen.
const MINI_BOSS_SPAWN_DISTANCE := 260.0
## Start with the boss: `godot --path . -- --boss`. For testing the fight.
const BOSS_FLAG := "--boss"
## Wave enemies spawned at time t get 1 + t / this many times their health.
## About 4x by the boss: a short run has fewer upgrades to keep up with.
const HEALTH_GROWTH_SECONDS := 90.0
const OFFER_COUNT := 3
const HURT_HITSTOP := 0.06
const DEATH_HITSTOP := 0.2
const TITLE_SCENE := "res://scenes/title.tscn"
## Real seconds between the run ending and the results screen, so the
## death or the boss's fall plays out first.
const RESULTS_DELAY := 1.2
## "PERFECT" appears this far from the player, above the head.
const PERFECT_POPUP_OFFSET := Vector2(0, -14)
const SHIFT_RING_PARTICLES := 12
const SHIFT_RING_SPEED := 90.0
const DEATH_BURST_SPEED := 70.0
const PERFECT_PARTICLES := 24
const PERFECT_PARTICLE_SPEED := 150.0
const LEVEL_UP_PARTICLES := 18
const LEVEL_UP_PARTICLE_SPEED := 60.0
const LEVEL_UP_COLOR := Color(1.0, 0.82, 0.35)
## Perfect shift flashes the screen white at this alpha, fading out.
const PERFECT_FLASH_ALPHA := 0.3
const PERFECT_FLASH_TIME := 0.25
## Split pieces land this far from the corpse.
const SPLIT_SPREAD := 8.0

@onready var player: Player = $Player
@onready var spawner: HordeSpawner = $HordeSpawner
@onready var status_label: Label = %StatusLabel
@onready var xp_bar: XpBar = %XpBar
@onready var energy_bars: EnergyBars = %EnergyBars
@onready var boss_bar: BossBar = %BossBar
@onready var damage_numbers: DamageNumbers = $DamageNumbers
@onready var world_environment: WorldEnvironment = $WorldEnvironment

var kills: int = 0
var experience := Experience.new()
var upgrade_pool := UpgradePool.new(UpgradeCatalog.build())
var level_up_menu: LevelUpMenu
var pause_menu: PauseMenu
var results_screen: ResultsScreen
var tutorial: Tutorial
var particles: ParticleBursts
var stats := RunStats.new()
var achievement_toast: AchievementToast
var _flash: ColorRect
var _run_over: bool = false
var _rng := RandomNumberGenerator.new()
## Level-ups earned but not picked yet; several can arrive in one frame.
var _pending_level_ups: int = 0
var _level_up_active: bool = false
var _hitstop: Hitstop
var boss: Boss
var _next_mini_boss: int = 0


static func format_time(seconds: float) -> String:
	var whole := int(seconds)
	return "%02d:%02d" % [whole / 60, whole % 60]


func _ready() -> void:
	player.enemy_group = spawner.enemy_group
	player.died.connect(_on_player_died)
	_hitstop = Hitstop.new()
	add_child(_hitstop)
	player.hurt_feedback.connect(_hitstop.trigger.bind(HURT_HITSTOP))
	player.perfect_shifted.connect(_on_perfect_shift)
	_apply_quality()
	AudioManager.play_music(AudioManager.RUN_MUSIC)
	spawner.enemy_spawned.connect(_on_enemy_spawned)
	spawner.enemy_spawned.connect(_scale_enemy_health)
	GameSettings.current()
	_add_effects()
	achievement_toast = AchievementToast.new()
	add_child(achievement_toast)
	player.form_changed.connect(func(_form: Player.Form) -> void:
		stats.shifts += 1
		_check_achievements())
	_rng.randomize()
	level_up_menu = LevelUpMenu.new()
	add_child(level_up_menu)
	level_up_menu.chosen.connect(_on_upgrade_chosen)
	level_up_menu.closed.connect(_open_level_up)
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause_menu.restart_requested.connect(restart)
	pause_menu.main_menu_requested.connect(go_to_title)
	results_screen = ResultsScreen.new()
	add_child(results_screen)
	results_screen.retry_requested.connect(restart)
	results_screen.main_menu_requested.connect(go_to_title)
	if BOSS_FLAG in OS.get_cmdline_user_args():
		spawn_boss.call_deferred()
	elif not GameSettings.current().tutorial_done:
		_start_tutorial()


## Spawns the pieces of [param enemy], with the same health scaling as
## wave enemies spawned now.
func _split(enemy: Enemy) -> void:
	var at := enemy.global_position
	for offset in split_offsets(enemy.split_count):
		var piece := enemy.split_scene.instantiate() as Enemy
		piece.target = player
		piece.add_to_group(spawner.enemy_group)
		_on_enemy_spawned(piece)
		_scale_enemy_health(piece)
		enemy.get_parent().add_child.call_deferred(piece)
		piece.position = at + offset


## Particles above the enemies, a white flash on the HUD, the player's
## pop-in and the shift rings.
func _add_effects() -> void:
	particles = ParticleBursts.new()
	# Bursts finish while the level-up or pause menu is open.
	particles.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(particles)
	_flash = ColorRect.new()
	_flash.color = Color.WHITE
	_flash.modulate.a = 0.0
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$HUD.add_child(_flash)
	player.form_changed.connect(func(new_form: Player.Form) -> void:
		particles.ring(player.global_position, Player.ui_color(new_form), SHIFT_RING_PARTICLES, SHIFT_RING_SPEED))
	player.play_intro()
	particles.ring(player.global_position, Color.WHITE, SHIFT_RING_PARTICLES * 2, SHIFT_RING_SPEED)


## The guided first run: waves and the run clock wait until it ends.
func _start_tutorial() -> void:
	spawner.stop()
	tutorial = Tutorial.new()
	tutorial.setup(self, player)
	add_child(tutorial)
	tutorial.finished.connect(_on_tutorial_finished)
	pause_menu.set_tutorial_active(true)
	pause_menu.skip_tutorial_requested.connect(tutorial.skip)


func _on_tutorial_finished() -> void:
	var settings := GameSettings.current()
	settings.tutorial_done = true
	settings.save()
	pause_menu.set_tutorial_active(false)
	player.heal(player.max_health)
	spawner.reset()
	spawner.start()


func _process(_delta: float) -> void:
	# Capitals via to_upper(), which ignores the OS locale; see LevelUpMenu.
	status_label.text = ("%s   %s   HP %d/%d   Kills %d" % [
		format_time(spawner.elapsed),
		player.form_name(),
		ceili(player.health),
		int(player.max_health),
		kills,
	]).to_upper()
	xp_bar.set_progress(experience.level, experience.progress())
	energy_bars.show_levels(player.energy_level(Player.Form.KNIGHT), player.energy_level(Player.Form.MAGE), player.form)
	if not _run_over:
		_spawn_due_mini_bosses()
	if not _run_over and boss == null and spawner.elapsed >= BOSS_TIME:
		spawn_boss()
	if is_instance_valid(boss):
		boss_bar.show_boss(boss.health, boss.max_health, Enemy.weak_form_for(boss.resisted_form))


## Brings in the final boss near the player and switches to boss music.
func spawn_boss() -> void:
	if boss != null or _run_over:
		return
	boss = spawn_enemy(BOSS_SCENE, BOSS_SPAWN_DISTANCE) as Boss
	boss.died.connect(_on_boss_died)
	AudioManager.play(&"boss_roar")
	AudioManager.play_music(AudioManager.BOSS_MUSIC, 0.5)


func _spawn_due_mini_bosses() -> void:
	while _next_mini_boss < MINI_BOSSES.size() and spawner.elapsed >= MINI_BOSSES[_next_mini_boss].time:
		var mini := spawn_enemy(MINI_BOSSES[_next_mini_boss].scene, MINI_BOSS_SPAWN_DISTANCE)
		mini.died.connect(func(_enemy: Enemy) -> void:
			stats.mini_bosses_killed += 1
			_check_achievements())
		AudioManager.play(&"boss_roar")
		_next_mini_boss += 1


## Adds [param scene] like the spawner would (target, group, signals) at a
## random point [param distance] away from the player.
func spawn_enemy(scene: PackedScene, distance: float) -> Enemy:
	var enemy := scene.instantiate() as Enemy
	enemy.target = player
	enemy.add_to_group(spawner.enemy_group)
	_on_enemy_spawned(enemy)
	var parent := spawner.get_node(spawner.spawn_parent_path) if not spawner.spawn_parent_path.is_empty() else self
	parent.add_child(enemy)
	enemy.global_position = player.global_position + Vector2.from_angle(_rng.randf() * TAU) * distance
	return enemy


func _on_boss_died(_boss: Enemy) -> void:
	if _run_over:
		return
	boss_bar.show_boss(0.0, 1.0, 0)
	AudioManager.play(&"run_win")
	_end_run(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(PauseMenu.PAUSE_ACTION) and PauseMenu.can_open(_run_over, get_tree().paused):
		get_viewport().set_input_as_handled()
		pause_menu.open()
	elif _run_over and event.is_action_pressed(&"restart"):
		restart()


func restart() -> void:
	ScreenFade.go_to(get_tree())


func go_to_title() -> void:
	ScreenFade.go_to(get_tree(), TITLE_SCENE)


func _on_enemy_spawned(enemy: Node2D) -> void:
	if enemy is Enemy:
		enemy.died.connect(_on_enemy_died)
		enemy.damaged.connect(_on_enemy_damaged)


func _on_enemy_damaged(enemy: Enemy, amount: float, resisted: bool, crit: bool) -> void:
	damage_numbers.spawn(enemy.global_position, amount, resisted, crit)
	if crit and not resisted:
		AudioManager.play(&"crit")


## Health multiplier for wave enemies spawned [param elapsed] seconds in.
## Mini-bosses and the boss keep their own fixed health.
static func health_scale(elapsed: float) -> float:
	return 1.0 + elapsed / HEALTH_GROWTH_SECONDS


func _scale_enemy_health(enemy: Node2D) -> void:
	if enemy is Enemy:
		enemy.max_health *= health_scale(spawner.elapsed)
		enemy.health = enemy.max_health


## HDR 2D and glow only on HIGH; see [Quality]. The scene ships with glow
## off so nothing glows on web before this runs.
func _apply_quality() -> void:
	var high := Quality.is_high()
	get_viewport().use_hdr_2d = high
	world_environment.environment.glow_enabled = high


## Where the pieces of a split enemy land, around its corpse.
static func split_offsets(count: int) -> Array[Vector2]:
	var offsets: Array[Vector2] = []
	for i in count:
		offsets.append(Vector2.from_angle(TAU * i / maxi(count, 1)) * SPLIT_SPREAD)
	return offsets


func _on_enemy_died(enemy: Enemy) -> void:
	particles.burst(enemy.global_position, enemy.particle_color, enemy.particle_count, DEATH_BURST_SPEED)
	if enemy.split_scene != null and not _run_over:
		_split(enemy)
	if _run_over:
		return
	kills += 1
	stats.kills = kills
	_check_achievements()
	_pending_level_ups += experience.add(enemy.xp_value)
	if _pending_level_ups > 0 and not _level_up_active:
		_open_level_up()


## Shows the next pending level-up, skipping ones with nothing to offer.
## Pauses while the menu is open; unpauses once nothing is pending.
func _open_level_up() -> void:
	while _pending_level_ups > 0 and not _run_over:
		_pending_level_ups -= 1
		var offers := upgrade_pool.offer(OFFER_COUNT, _rng, UpgradeCatalog.tags_for_form(player.form))
		if offers.is_empty():
			continue
		var levels: Array[int] = []
		for upgrade in offers:
			levels.append(upgrade_pool.level_of(upgrade.id))
		_level_up_active = true
		get_tree().paused = true
		level_up_menu.open(offers, levels)
		AudioManager.play(&"level_up")
		particles.ring(player.global_position, LEVEL_UP_COLOR, LEVEL_UP_PARTICLES, LEVEL_UP_PARTICLE_SPEED)
		return
	_level_up_active = false
	get_tree().paused = false


func _on_upgrade_chosen(upgrade: Upgrade) -> void:
	AudioManager.play(&"card_pick")
	if not upgrade.requires_maxed.is_empty():
		stats.evolutions += 1
		_check_achievements()
	if upgrade_pool.apply(upgrade.id) > 0:
		UpgradeEffects.apply(player, upgrade.id)


func _on_perfect_shift() -> void:
	stats.perfects += 1
	_check_achievements()
	_hitstop.slow_motion(PerfectShift.SLOW_TIME, PerfectShift.SLOW_SCALE)
	particles.burst(player.global_position, PerfectShift.POPUP_COLOR, PERFECT_PARTICLES, PERFECT_PARTICLE_SPEED)
	_flash.modulate.a = PERFECT_FLASH_ALPHA
	# Real time: the flash should not crawl during the slow motion.
	create_tween().set_ignore_time_scale().tween_property(_flash, ^"modulate:a", 0.0, PERFECT_FLASH_TIME)
	damage_numbers.spawn_text(player.global_position + PERFECT_POPUP_OFFSET, PerfectShift.POPUP_TEXT, PerfectShift.POPUP_COLOR)


func _on_player_died() -> void:
	_hitstop.trigger(DEATH_HITSTOP)
	_end_run(false)


## Unlocks and announces every achievement the run has earned so far.
func _check_achievements() -> void:
	stats.seconds = spawner.elapsed
	var progress := Progress.current()
	var fresh := Achievements.newly_unlocked(stats, progress.unlocked)
	for id in fresh:
		progress.unlock(id)
		achievement_toast.show_unlocked(id)
	if not fresh.is_empty():
		progress.save()


func _end_run(won: bool) -> void:
	stats.won = won
	stats.health_share = player.health / maxf(player.max_health, 1.0)
	_check_achievements()
	AudioManager.stop_music(1.5)
	_run_over = true
	get_tree().call_group(EnemyBolt.GROUP, &"queue_free")
	_pending_level_ups = 0
	_level_up_active = false
	level_up_menu.cancel()
	get_tree().paused = false
	spawner.stop()
	player.is_dead = true
	get_tree().call_group(spawner.enemy_group, &"set_physics_process", false)
	# Real time, ignoring hitstop's time scale. A bound method rather than
	# an await, so a restart during the delay drops the call cleanly.
	get_tree().create_timer(RESULTS_DELAY, true, false, true).timeout.connect(_show_results.bind(won, spawner.elapsed))


func _show_results(won: bool, seconds: float) -> void:
	var owned := upgrade_pool.owned()
	var levels: Array[int] = []
	for upgrade in owned:
		levels.append(upgrade_pool.level_of(upgrade.id))
	results_screen.open(won, seconds, kills, experience.level, owned, levels)
	var progress := Progress.current()
	var score := stats.score()
	var new_best := progress.submit_score(score)
	progress.save()
	results_screen.show_score(score, stats.breakdown(), new_best)
