extends RigidBody2D

class_name Kerno

#tier handling
@export var tier: int = 1
#blocks multi merging
var is_merging := false

#pop
@export var xpop_intensity_min := -30.0
@export var xpop_intensity_max := 30.0

@export var ypop_intensity_min := -30.0
@export var ypop_intensity_max := -90.0

#spin me baby
@export var angular_velocity_min := -2.0
@export var angular_velocity_max := 2.0

const TIER_DATA: Dictionary = {
	1: {"radius": 16.0, "color": Color("#7e9296"), "score": 10, "mass": 1.0}, # Faint Ghost Slate (0 wisps)
	2: {"radius": 22.0, "color": Color("#48cae4"), "score": 20, "mass": 1.8}, # Spirit Teal (1 wisp)
	3: {"radius": 28.0, "color": Color("#00b4d8"), "score": 40, "mass": 2.8}, # Luminous Cyan (2 wisps)
	4: {"radius": 36.0, "color": Color("#0077b6"), "score": 80, "mass": 4.2}, # Astral Blue (3 wisps)
	5: {"radius": 46.0, "color": Color("#7b2cbf"), "score": 160, "mass": 6.0}, # Arcane Lavender (4 wisps)
	6: {"radius": 58.0, "color": Color("#9d4edd"), "score": 320, "mass": 8.5}, # Royal Amethyst (5 wisps)
	7: {"radius": 72.0, "color": Color("#f72585"), "score": 640, "mass": 11.5}, # Void Magenta (6 wisps)
	8: {"radius": 88.0, "color": Color("#e63946"), "score": 1280, "mass": 15.0}, # Bloodstone Crimson (7 wisps)
	9: {"radius": 102.0, "color": Color("#f77f00"), "score": 2560, "mass": 19.5}, # Solar Amber (8 wisps)
	10: {"radius": 116.0, "color": Color("#fcbf49"), "score": 5120, "mass": 25.0}, # Supernal Citrine (9 wisps)
	11: {"radius": 130.0, "color": Color("#fff9db"), "score": 10240, "mass": 32.0}, # Astral Singularity (10 wisps)
}

# Static drawing helper callable from outside. not instance related, but class static
static func draw_visual(canvas: CanvasItem, center: Vector2, target_tier: int) -> void:
	if not TIER_DATA.has(target_tier):
		return
	
	var data: Dictionary = TIER_DATA[target_tier]
	var radius: float = data["radius"]
	var color: Color = data["color"]
	
	# Draw body centered on param vector, with tier data
	canvas.draw_circle(center, radius, color)
	
	# Draw eye / details
	var eye_offset := center + Vector2(radius * 0.35, -radius * 0.2)
	canvas.draw_circle(eye_offset, radius * 0.2, Color(1, 1, 1, 0.9))
	canvas.draw_circle(eye_offset, radius * 0.1, Color(0, 0, 0, 0.9))

func _ready() -> void:
	apply_tier_properties()
	#rng jesus spins
	self.angular_velocity = randf_range(angular_velocity_min, angular_velocity_max)
	# Connect the collision signal
	body_entered.connect(_on_body_entered)
	
func apply_tier_properties() -> void:
	if not TIER_DATA.has(tier):
		return
	
	#handle for current tier data
	var data: Dictionary = TIER_DATA[tier]
	
	Kerno.setup_visual($ColorRect, tier, Vector2.ZERO)
		
	# Update collision radius
	var col_shape := $CollisionShape2D.shape as CircleShape2D
	if col_shape:
		# Duplicate shape so changing this kerno doesn't alter other kernoj
		col_shape = col_shape.duplicate()
		col_shape.radius = data["radius"]
		$CollisionShape2D.shape = col_shape
		
	#change to new mass
	self.mass = data["mass"]
	
	# Request redraw with new color and radius
	queue_redraw()
	
func _on_body_entered(other_body: Node) -> void:
	if other_body is not Kerno:
		return
	
	var other_kerno := other_body as Kerno
	
	if is_merging or other_kerno.is_merging:
		return
	
	# Only merge if tiers match and this isn't the max tier
	if other_kerno.tier != tier or tier >= TIER_DATA.size():
		return
	
	# Arbitrate race condition: only one kerno handles the merge
	if get_instance_id() < other_kerno.get_instance_id():
		return
	
	# Lock both bodies
	is_merging = true
	other_kerno.is_merging = true
	
	# Perform merge
	call_deferred("_merge_with", other_kerno)
	
func _merge_with(other: Kerno) -> void:
	var next_tier := tier + 1
	var spawn_pos := (global_position + other.global_position) / 2.0
	
	# Instantiate higher tier kerno
	var kerno_scene: PackedScene = load(self.scene_file_path)
	var new_kerno: Kerno = kerno_scene.instantiate()
	new_kerno.tier = next_tier
	new_kerno.global_position = spawn_pos
	var rng_pop := Vector2(
		randf_range( # x random force.
			xpop_intensity_min,
			xpop_intensity_max
			),
		randf_range( # y random, upwards always force
			ypop_intensity_min,
			ypop_intensity_max
			) * self.mass
		) # closing vector2
	
	#score and signaling merge
	var score: int = TIER_DATA[new_kerno.tier]["score"]
	Events.kerno_merged.emit(new_kerno.tier, score, spawn_pos)
	
	# Add to scene
	get_parent().add_child(new_kerno)
	new_kerno.apply_central_impulse(rng_pop)
	
	# Remove old kernoj
	other.queue_free()
	queue_free()

static func setup_visual(rect: ColorRect, target_tier: int, center: Vector2 = Vector2.ZERO) -> void:
	if not TIER_DATA.has(target_tier):
		return
		
	var radius: float = TIER_DATA[target_tier]["radius"]
	var diameter: float = radius * 2.0
	
	# 1. Size and center the rect around the center point
	rect.size = Vector2(diameter, diameter)
	rect.position = center - Vector2(radius, radius)
	
	# 2. Update shader color
	var mat := rect.material as ShaderMaterial
	if mat:
		mat = mat.duplicate() # Creates a private copy for THIS specific rect
		rect.material = mat
		mat.set_shader_parameter("base_color", TIER_DATA[target_tier]["color"])
		mat.set_shader_parameter("tier", target_tier)
		mat.set_shader_parameter("core_radius", radius)
