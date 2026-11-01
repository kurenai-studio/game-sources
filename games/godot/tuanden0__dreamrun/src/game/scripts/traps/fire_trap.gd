## A line of flames along the ground. On trigger the fire catches, burns for `active_time` and holds every monster in the
## zone stunned for as long as it burns. Harmless to the player (like the electric trap), so a lever beside it is safe.
## The tongues are drawn once and only scaled while burning, so a burning trap costs next to nothing.
class_name FireTrap
extends Trap

@export var active_time := 3.5
@export var flame_color := Color(1.0, 0.45, 0.1, 0.92)
@export var core_color := Color(1.0, 0.8, 0.3, 0.95)
## Spacing of the flame tongues (px).
@export var tongue_spacing := 30.0

var _left := 0.0
var _age := 0.0
var _tongues: Array[Node2D] = []
var _phases := PackedFloat32Array()
var _glow: PointLight2D


func _ready() -> void:
	super()
	var additive := CanvasItemMaterial.new()
	additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var count := maxi(int(size.x / tongue_spacing), 3)
	for i in count:
		var tongue := Node2D.new()
		tongue.position = Vector2(lerpf(-size.x * 0.5, size.x * 0.5, (i + 0.5) / count) + rng.randf_range(-6.0, 6.0), 0.0)
		var height := rng.randf_range(70.0, 130.0)
		var width := rng.randf_range(20.0, 30.0)
		for layer in 2:  # outer flame and a hotter core inside it
			var poly := Polygon2D.new()
			var k := 1.0 if layer == 0 else 0.55
			poly.polygon = PackedVector2Array([
				Vector2(-width * 0.5 * k, 0.0), Vector2(-width * 0.42 * k, -height * 0.3 * k), Vector2(-width * 0.2 * k, -height * 0.65 * k),
				Vector2(rng.randf_range(-4.0, 4.0), -height * k), Vector2(width * 0.2 * k, -height * 0.62 * k),
				Vector2(width * 0.44 * k, -height * 0.3 * k), Vector2(width * 0.5 * k, 0.0)])
			poly.color = flame_color if layer == 0 else core_color
			poly.material = additive
			poly.antialiased = true
			tongue.add_child(poly)
		add_child(tongue)
		_tongues.append(tongue)
		_phases.append(rng.randf() * TAU)
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
	_glow.texture_scale = 3.0
	_glow.color = Color(1.0, 0.6, 0.25)
	_glow.position = Vector2(0.0, -50.0)
	add_child(_glow)
	_restore()


func is_burning() -> bool:
	return _left > 0.0


func _fire() -> void:
	_left = active_time
	_age = 0.0
	set_physics_process(true)


func _restore() -> void:
	_left = 0.0
	for tongue in _tongues:
		tongue.visible = false
	_glow.visible = false
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	_left -= delta
	_age += delta
	if _left <= 0.0:
		_restore()
		return
	_stun_zone()
	var strength := clampf(minf(_age / 0.3, _left / 0.5), 0.0, 1.0)  # catches quickly, dies down at the end
	_glow.visible = true
	_glow.energy = strength * (0.9 + 0.25 * sin(_age * 23.0))
	for i in _tongues.size():
		var tongue := _tongues[i]
		tongue.visible = true
		var wobble := 0.75 + 0.25 * sin(_age * 9.0 + _phases[i]) + 0.12 * sin(_age * 21.0 + _phases[i] * 2.0)
		tongue.scale = Vector2(1.0 + 0.1 * sin(_age * 13.0 + _phases[i]), strength * wobble)
