extends Control
class_name HUDController

@onready var mode_label: Label = $ModePanel/ModeLabel
@onready var mode_desc: Label = $ModePanel/ModeDesc
@onready var crosshair: CenterContainer = $Crosshair
@onready var held_info_panel: PanelContainer = $HeldInfoPanel
@onready var held_scale_label: Label = $HeldInfoPanel/VBoxContainer/ScaleLabel
@onready var held_weight_label: Label = $HeldInfoPanel/VBoxContainer/WeightLabel
@onready var chamber_title: Label = $TopBar/ChamberTitle
@onready var chamber_desc: Label = $TopBar/ChamberDesc
@onready var shifts_count_label: Label = $TopBar/ShiftsLabel
@onready var help_panel: PanelContainer = $HelpPanel
@onready var victory_panel: PanelContainer = $VictoryPanel
@onready var victory_stats: Label = $VictoryPanel/VBox/StatsLabel

var shifts_count: int = 0
var current_held_cube: ShiftCube = null

func _ready():
	held_info_panel.visible = false
	help_panel.visible = false
	victory_panel.visible = false
	update_mode_display(false)

func _process(_delta):
	if is_instance_valid(current_held_cube) and current_held_cube.is_held:
		held_info_panel.visible = true
		held_scale_label.text = "SCALE: %.2fx" % current_held_cube.current_scale
		held_weight_label.text = "MASS: %.1f kg" % current_held_cube.mass
	else:
		held_info_panel.visible = false

func _ensure_nodes():
	if not mode_label:
		mode_label = get_node_or_null("ModePanel/ModeLabel")
	if not mode_desc:
		mode_desc = get_node_or_null("ModePanel/ModeDesc")
	if not chamber_title:
		chamber_title = get_node_or_null("TopBar/ChamberTitle")
	if not chamber_desc:
		chamber_desc = get_node_or_null("TopBar/ChamberDesc")
	if not shifts_count_label:
		shifts_count_label = get_node_or_null("TopBar/ShiftsLabel")
	if not held_info_panel:
		held_info_panel = get_node_or_null("HeldInfoPanel")
	if not help_panel:
		help_panel = get_node_or_null("HelpPanel")
	if not victory_panel:
		victory_panel = get_node_or_null("VictoryPanel")

func update_mode_display(is_ortho: bool):
	_ensure_nodes()
	if is_ortho:
		if mode_label:
			mode_label.text = "PROJECTION: ORTHOGRAPHIC"
			mode_label.modulate = Color(1.0, 0.85, 0.2) # Amber / Gold
		if mode_desc:
			mode_desc.text = "DEPTH COLLAPSED • ALIGNED GAPS BRIDGED • FORCED SCALE ACTIVE"
			mode_desc.modulate = Color(1.0, 0.9, 0.5)
	else:
		if mode_label:
			mode_label.text = "PROJECTION: PERSPECTIVE"
			mode_label.modulate = Color(0.2, 0.9, 1.0) # Cyan
		if mode_desc:
			mode_desc.text = "STANDARD 3D EUCLIDEAN SPACE"
			mode_desc.modulate = Color(0.6, 0.8, 1.0)

func increment_shifts():
	_ensure_nodes()
	shifts_count += 1
	if shifts_count_label:
		shifts_count_label.text = "SHIFTS: %d" % shifts_count

func set_chamber_info(title: String, desc: String):
	_ensure_nodes()
	if chamber_title:
		chamber_title.text = title
	if chamber_desc:
		chamber_desc.text = desc

func on_cube_grabbed(cube: ShiftCube):
	current_held_cube = cube

func on_cube_released():
	current_held_cube = null

func toggle_help():
	help_panel.visible = not help_panel.visible

func show_victory(total_time: float, total_shifts: int):
	victory_panel.visible = true
	var mins = int(total_time) / 60
	var secs = int(total_time) % 60
	victory_stats.text = "COMPLETION TIME: %02d:%02d\nTOTAL PROJECTION SHIFTS: %d\n\nALL TEST CHAMBERS CLEARED!" % [mins, secs, total_shifts]
