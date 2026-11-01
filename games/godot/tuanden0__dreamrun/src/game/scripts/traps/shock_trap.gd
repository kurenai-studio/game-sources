## Arcing electricity over the ground. On trigger it crackles for `active_time`, holding every monster in the
## zone stunned for as long as it lasts. Harmless to the player.
class_name ShockTrap
extends Trap

@export var active_time := 2.5
@export var arc_color := Color(0.75, 0.85, 1.0)

var _left := 0.0
var _arcs: Array[Line2D] = []
var _glow: PointLight2D
var _flicker := 0.0


func _ready() -> void:
	super()
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	var taper := Curve.new()
	taper.add_point(Vector2(0.0, 0.3))
	taper.add_point(Vector2(0.5, 1.0))
	taper.add_point(Vector2(1.0, 0.3))
	for i in 3:  # a bright main bolt and two thinner, dimmer branches
		var arc := Line2D.new()
		arc.width = 5.0 if i == 0 else 2.0
		arc.default_color = arc_color if i == 0 else Color(arc_color, 0.55)
		arc.width_curve = taper
		arc.joint_mode = Line2D.LINE_JOINT_ROUND
		arc.begin_cap_mode = Line2D.LINE_CAP_ROUND
		arc.end_cap_mode = Line2D.LINE_CAP_ROUND
		arc.material = unshaded
		add_child(arc)
		_arcs.append(arc)
	_glow = PointLight2D.new()
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	_glow.texture = texture
	_glow.texture_scale = 2.5
	_glow.color = arc_color
	_glow.position = Vector2(0.0, -size.y * 0.3)
	add_child(_glow)
	_restore()


func _fire() -> void:
	_left = active_time
	_set_visible(true)
	set_physics_process(true)


func _restore() -> void:
	_left = 0.0
	_set_visible(false)
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		_restore()
		return
	_stun_zone()
	_flicker -= delta
	if _flicker <= 0.0:  # re-roll the bolts ~20x/s; every frame reads as noise
		_flicker = 0.05
		var half := size.x * 0.5
		_arcs[0].points = _bolt(Vector2(-half, -randf_range(10.0, 60.0)), Vector2(half, -randf_range(10.0, 60.0)), size.y * 0.25)
		_arcs[1].points = _bolt(Vector2(-half * randf(), -size.y * 0.5), Vector2(half * randf_range(0.3, 1.0), -randf_range(0.0, 30.0)), size.y * 0.15)
		_arcs[2].points = _bolt(Vector2(half * randf_range(-1.0, 0.0), 0.0), Vector2(half * randf(), -size.y * 0.45), size.y * 0.15)
		_glow.energy = randf_range(0.6, 1.2)


func _set_visible(value: bool) -> void:
	for arc in _arcs:
		arc.visible = value
	_glow.visible = value


## Midpoint displacement: a jagged line from a to b whose kinks halve in size each pass.
func _bolt(a: Vector2, b: Vector2, spread: float) -> PackedVector2Array:
	var points := PackedVector2Array([a, b])
	for pass_index in 4:
		var next := PackedVector2Array()
		for i in points.size() - 1:
			var mid := (points[i] + points[i + 1]) * 0.5
			mid.y += randf_range(-spread, spread)
			next.append(points[i])
			next.append(mid)
		next.append(points[points.size() - 1])
		points = next
		spread *= 0.5
	return points
