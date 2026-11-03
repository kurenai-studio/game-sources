extends Node2D

#Preloads ?
const KERNO_SCENE = preload("res://scenes/kerno/kerno.tscn")

# Minimum and maximum X boundaries (inside the container walls)
@export var min_x: float = 460.0
@export var max_x: float = 820.0

#exporting to gui dashing line
@export var dash_lenght: float = 12.0
@export var aimguide_color: Color = Color(0.008, 0.093, 0.428, 0.898)

#also exporting firing rate
@export var drop_cooldown: float = 0.5

#internal vars
var can_drop: bool = true
var current_kerno_tier: int = 0

func _process(_delta: float) -> void:
	var mouse_x: float = get_global_mouse_position().x
	# Clamp the dropper's X position between the vial walls
	global_position.x = clampf(mouse_x, min_x, max_x)

func _draw() -> void:
	#aim lines have to be dashed gorsh dan it
	draw_dashed_line(Vector2.ZERO, Vector2(0, 540), aimguide_color, 2.0, dash_lenght)
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if can_drop:
			drop_kerno()
			
func drop_kerno() -> void:
	can_drop = false
	
	var kerno = KERNO_SCENE.instantiate()
	kerno.tier = current_kerno_tier
	kerno.global_position = global_position
	
	get_parent().add_child(kerno)
	Events.kerno_dropped.emit(current_kerno_tier)
	
	await get_tree().create_timer(drop_cooldown).timeout
	can_drop = true

func set_current_kerno_tier(new_tier: int) -> void:
	current_kerno_tier = new_tier
	if not Kerno.TIER_DATA.has(new_tier):
		return
	Kerno.setup_visual($PreviewKerno, current_kerno_tier, Vector2(0.0, 60.0))
	
	queue_redraw()
