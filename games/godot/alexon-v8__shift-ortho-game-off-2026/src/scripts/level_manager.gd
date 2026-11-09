extends Node3D
class_name LevelManager

@export var player_node: PlayerController
@export var hud_node: HUDController
@export var chamber_container: Node3D

var current_chamber_idx: int = 0
var total_shifts: int = 0
var elapsed_time: float = 0.0
var current_chamber_instance: Node3D = null

var chamber_scenes = [
	"res://scenes/test_chamber_0.tscn",
	"res://scenes/test_chamber_1.tscn",
	"res://scenes/test_chamber_2.tscn",
	"res://scenes/test_chamber_3.tscn",
	"res://scenes/test_chamber_4.tscn"
]

var chamber_info = [
	{
		"title": "CHAMBER 00: SPATIAL FLATTENING",
		"desc": "Cross the impossible chasm. Press [SHIFT/Q] to collapse depth into Orthographic mode."
	},
	{
		"title": "CHAMBER 01: FORCED PERSPECTIVE SCALING",
		"desc": "Grab the micro-cube [E]. In Ortho mode, placing objects at distance multiplies their scale."
	},
	{
		"title": "CHAMBER 02: DIMENSIONAL ALIGNMENT",
		"desc": "Align disjointed floating pillars in screen-space [TAB/T to snap]. Walk across the aligned plane."
	},
	{
		"title": "CHAMBER 03: MASS MULTIPLIER",
		"desc": "The blast door requires 150 kg on the pressure plate. Scale up a cube to unlock the exit."
	},
	{
		"title": "CHAMBER 04: THE EXTRACTION CORE",
		"desc": "Synthesize all spatial shift protocols to access the final portal and conclude the trial."
	}
]

func _ready():
	if player_node:
		player_node.shift_toggled.connect(_on_player_shift_toggled)
		player_node.cube_grabbed.connect(_on_player_cube_grabbed)
		player_node.cube_released.connect(_on_player_cube_released)
		player_node.chamber_reset_requested.connect(_on_chamber_reset)
		
	load_chamber(0)

func _process(delta: float):
	elapsed_time += delta
	if Input.is_action_just_pressed("toggle_help") and hud_node:
		hud_node.toggle_help()

func load_chamber(idx: int):
	current_chamber_idx = idx
	if current_chamber_instance:
		current_chamber_instance.queue_free()
		current_chamber_instance = null
		
	if current_chamber_idx >= chamber_scenes.size():
		# Victory!
		if hud_node:
			hud_node.show_victory(elapsed_time, total_shifts)
		return
		
	var scene_path = chamber_scenes[current_chamber_idx]
	if ResourceLoader.exists(scene_path):
		var scene_res = load(scene_path)
		current_chamber_instance = scene_res.instantiate()
		chamber_container.add_child(current_chamber_instance)
		
		# Connect portal
		var portal = current_chamber_instance.find_child("ExitPortal", true, false)
		if portal and portal.has_signal("chamber_completed"):
			portal.chamber_completed.connect(_on_portal_completed)
			
		# Set player spawn
		var spawn_marker = current_chamber_instance.find_child("SpawnPoint", true, false)
		if spawn_marker and player_node:
			player_node.global_position = spawn_marker.global_position
			player_node.spawn_point = spawn_marker.global_position
			player_node.velocity = Vector3.ZERO
			
		# Reset camera to perspective
		if player_node and player_node.camera:
			player_node.camera.set_ortho_mode(false)
			
		# Update HUD
		if hud_node and current_chamber_idx < chamber_info.size():
			hud_node.set_chamber_info(
				chamber_info[current_chamber_idx]["title"],
				chamber_info[current_chamber_idx]["desc"]
			)

func _on_player_shift_toggled(is_ortho: bool):
	total_shifts += 1
	if hud_node:
		hud_node.update_mode_display(is_ortho)
		hud_node.increment_shifts()

func _on_player_cube_grabbed(cube: ShiftCube):
	if hud_node:
		hud_node.on_cube_grabbed(cube)

func _on_player_cube_released():
	if hud_node:
		hud_node.on_cube_released()

func _on_portal_completed():
	load_chamber(current_chamber_idx + 1)

func _on_chamber_reset():
	load_chamber(current_chamber_idx)
