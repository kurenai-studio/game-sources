extends SkinBackdrop
## Nova backdrop (DESIGN_SYSTEM.md 6.7): deep space. A radial glow of bg_glow
## centered at (backdrop_glow_x, backdrop_glow_y) of the control, radius
## backdrop_glow_radius of its width, fading to bg; made once with a
## GradientTexture2D. On top, star_count star dust dots from the fixed
## star_seed, star_size_min to star_size_max px across, alpha star_alpha_min
## to star_alpha_max, none within star_clearance px of a text rect. Stars are
## placed once per size and per set of clear rects, never per frame.

const _TEXTURE_SIZE: int = 256

var _skin: SkinData = null
var _glow: GradientTexture2D = null
var _bg: Color = Color.BLACK
var _clear_rects: Array[Rect2] = []
var _star_points: PackedVector2Array = PackedVector2Array()
var _star_radii: PackedFloat32Array = PackedFloat32Array()
var _star_colors: PackedColorArray = PackedColorArray()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(skin: SkinData) -> void:
	_skin = skin
	_bg = skin.color(&"bg")
	var glow: Color = skin.color(&"bg_glow")
	var gradient: Gradient = Gradient.new()
	# A smooth falloff, so the glow has no visible edge.
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.6, 1.0])
	gradient.colors = PackedColorArray([glow, glow.lerp(_bg, 0.3), glow.lerp(_bg, 0.75), _bg])
	_glow = GradientTexture2D.new()
	_glow.gradient = gradient
	_glow.width = _TEXTURE_SIZE
	_glow.height = _TEXTURE_SIZE
	_glow.fill = GradientTexture2D.FILL_RADIAL
	_glow.fill_from = Vector2(0.5, 0.5)
	_glow.fill_to = Vector2(1.0, 0.5)
	_place_stars()


## Keeps star dust clear of text: every star within star_clearance px of one
## of these rects (global coordinates) is left out. The other stars keep
## their places, since every star is still drawn from the same seed.
func set_clear_rects(rects: Array[Rect2]) -> void:
	_clear_rects = rects.duplicate()
	_place_stars()


## Stars drawn now. For tests.
func star_count() -> int:
	return _star_points.size()


func _notification(what: int) -> void:
	# Also place on entering the tree: a control sized outside the tree gets no
	# resize notification, and the global transform is only known in the tree.
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_place_stars()


func _place_stars() -> void:
	if _skin == null:
		return
	var count: int = int(_skin.num(&"star_count"))
	var size_min: float = _skin.num(&"star_size_min")
	var size_max: float = _skin.num(&"star_size_max")
	var alpha_min: float = _skin.num(&"star_alpha_min")
	var alpha_max: float = _skin.num(&"star_alpha_max")
	var clearance: float = _skin.num(&"star_clearance")
	var star: Color = _skin.color(&"star")
	var to_global: Transform2D = get_global_transform() if is_inside_tree() else Transform2D.IDENTITY
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(_skin.num(&"star_seed"))
	_star_points.clear()
	_star_radii.clear()
	_star_colors.clear()
	for i: int in count:
		# Draw every random number, kept or not, so each star's place depends
		# only on the seed and its index.
		var point: Vector2 = Vector2(rng.randf() * size.x, rng.randf() * size.y)
		var radius: float = rng.randf_range(size_min, size_max) * 0.5
		var alpha: float = rng.randf_range(alpha_min, alpha_max)
		if _near_text(to_global * point, radius + clearance):
			continue
		_star_points.append(point)
		_star_radii.append(radius)
		_star_colors.append(Color(star, alpha))
	queue_redraw()


## Whether a global point is within distance of any clear rect.
func _near_text(point: Vector2, distance: float) -> bool:
	for rect: Rect2 in _clear_rects:
		var dx: float = maxf(maxf(rect.position.x - point.x, 0.0), point.x - rect.end.x)
		var dy: float = maxf(maxf(rect.position.y - point.y, 0.0), point.y - rect.end.y)
		if dx * dx + dy * dy <= distance * distance:
			return true
	return false


func _draw() -> void:
	if _skin == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), _bg)
	var radius: float = size.x * _skin.num(&"backdrop_glow_radius")
	var center: Vector2 = size * Vector2(_skin.num(&"backdrop_glow_x"), _skin.num(&"backdrop_glow_y"))
	draw_texture_rect(_glow, Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false)
	for i: int in _star_points.size():
		draw_circle(_star_points[i], _star_radii[i], _star_colors[i], true, -1.0, true)
