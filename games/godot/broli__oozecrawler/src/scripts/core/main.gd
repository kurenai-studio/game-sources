extends Node2D

# References to child nodes
@onready var dropper: Node2D = $Dropper
@onready var queue_display: Control = $HUD/NextSlimePanel/QueueDisplay
@onready var score_value_label: Label = $HUD/ScorePanel/ScoreValueLabel
@onready var container: GameContainer = $Container
@onready var merge_audio_player: AudioStreamPlayer = $MergeAudioPlayer
@onready var kill_plane: Area2D = $KillPlane
@onready var game_over_panel: Panel = $HUD/GameOverPanel
@onready var stats_rich_text: RichTextLabel = $HUD/GameOverPanel/StatsRT
@onready var game_over_restart_button: Button = $HUD/GameOverPanel/HBoxContainer/RestartButton
@onready var game_over_main_menu_button: Button = $HUD/GameOverPanel/HBoxContainer/MainMenuButton


# Load audio files
var first_half_tier_merge_sound = preload("res://assets/audio/firsthalftiermerge.wav")
var second_half_tier_merge_sound = preload("res://assets/audio/secondhalftiermerge.wav")

#preload particles
var merge_particles_scene: PackedScene = preload("res://scenes/levels/merge_particles.tscn")


var level_stats: LevelStats
var queue_manager: QueueManager

var is_game_over = false

func _ready() -> void:
	# Dynamically read beaker boundaries from its collision shapes
	var bounds: Vector2 = container.get_drop_bounds(0.0)
	dropper.min_x = bounds.x
	dropper.max_x = bounds.y
	
	# Set dropper height right above the flask opening
	dropper.global_position.y = container.get_opening_y() - 150.0
	
	# put att he bottom
	kill_plane.global_position.y = get_viewport_rect().size.y + 100
	
	# hide game over panel
	game_over_panel.visible = false
	#game_over_panel.position = Vector2(0.0, 0.0)
	#game_over_panel.size = get_viewport().get_visible_rect().size

	queue_manager = QueueManager.new()
	level_stats = LevelStats.new()
		
	# Give the dropper its first kerno
	dropper.set_current_kerno_tier(self.queue_manager.get_next())
	queue_display.update_queue([queue_manager.peek(0), queue_manager.peek(1), queue_manager.peek(2), queue_manager.peek(3)] as Array[int])

	#messaging and listening block
	#listen for kerno drop
	Events.kerno_dropped.connect(_on_kerno_dropped)
	#listen for kill plane collision
	kill_plane.body_entered.connect(_on_kill_plane_body_entered)
	#listen for merge event
	Events.kerno_merged.connect(_on_kerno_merged)
	#listen for game over
	Events.game_over_endless_mode.connect(_on_game_over_endless_mode)
	
	#listen for button press
	game_over_restart_button.pressed.connect(_on_restart_button_pressed)
	game_over_main_menu_button.pressed.connect(_on_main_menu_button_pressed)


func _on_kerno_merged(tier: int, earned_score: int, location: Vector2) -> void:
	level_stats.add_score(earned_score)
	level_stats.add_merge(tier)
	score_value_label.text = str(level_stats.score)
	
	if tier < 6:
		merge_audio_player.stream = first_half_tier_merge_sound
		merge_audio_player.pitch_scale = 0.9 + (tier * 0.05)
	else:
		merge_audio_player.stream = second_half_tier_merge_sound
		merge_audio_player.pitch_scale = 0.9 + ((tier - 5) * 0.05)
	merge_audio_player.play()

	#party poopers! 
	var merge_particles = merge_particles_scene.instantiate()
	merge_particles.global_position = location
	merge_particles.setup_tier(tier)
	merge_particles.emitting = true
	add_child(merge_particles)

	
func _on_kerno_dropped(_tier: int) -> void:
	level_stats.add_kerno_dropped()
	dropper.set_current_kerno_tier(self.queue_manager.get_next())
	queue_display.update_queue([queue_manager.peek(0), queue_manager.peek(1), queue_manager.peek(2), queue_manager.peek(3)] as Array[int])


func _on_kill_plane_body_entered(body: Node) -> void:
	if is_game_over:
		return
	is_game_over = true
	Events.kerno_fell_out_of_bounds.emit(body.tier)
	body.queue_free()
	Events.game_over_endless_mode.emit(level_stats)


func _on_game_over_endless_mode(stats: LevelStats) -> void:
	get_tree().paused = true
	game_over_panel.visible = true

	#populate stats
	stats_rich_text.text = stats.to_rich_text()
	stats_rich_text.visible_ratio = 0.0
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(stats_rich_text, "visible_ratio", 1.0, 1.0)

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
