class_name Starfield
extends Node2D
## Two-layer scrolling starfield with soft nebula blobs.
## Pure _draw() — no textures needed.

var _stars: Array = []        # {pos: Vector2, speed: float, size: float, color: Color}
var _nebulas: Array = []      # {pos: Vector2, radius: float, color: Color, speed: float}
var _size := Vector2(720, 1280)
var scroll_speed := 60.0

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 987654
	for i in 110:
		var layer := rng.randf()
		_stars.append({
			"pos": Vector2(rng.randf() * _size.x, rng.randf() * _size.y),
			"speed": lerpf(28.0, 130.0, layer),
			"size": lerpf(1.0, 2.8, layer),
			"color": Color(1, 1, 1, lerpf(0.35, 1.0, layer)),
		})
	var nebula_colors := [Color(0.35, 0.2, 0.7, 0.10), Color(0.1, 0.5, 0.7, 0.08), Color(0.8, 0.25, 0.5, 0.07)]
	for i in 5:
		_nebulas.append({
			"pos": Vector2(rng.randf() * _size.x, rng.randf() * _size.y),
			"radius": rng.randf_range(120.0, 260.0),
			"color": nebula_colors[i % nebula_colors.size()],
			"speed": rng.randf_range(8.0, 18.0),
		})

func _process(delta: float) -> void:
	for s in _stars:
		var p: Vector2 = s["pos"]
		p.y += float(s["speed"]) * delta * (scroll_speed / 60.0)
		if p.y > _size.y + 4.0:
			p.y = -4.0
			p.x = randf() * _size.x
		s["pos"] = p
	for n in _nebulas:
		var np: Vector2 = n["pos"]
		np.y += float(n["speed"]) * delta
		if np.y - float(n["radius"]) > _size.y:
			np.y = -float(n["radius"])
		n["pos"] = np
	queue_redraw()

func _draw() -> void:
	for n in _nebulas:
		# Layered circles fake a soft glow.
		for i in range(4, 0, -1):
			var c: Color = n["color"]
			c.a *= float(i) / 4.0
			draw_circle(n["pos"], n["radius"] * float(i) / 4.0, c)
	for s in _stars:
		draw_circle(s["pos"], s["size"], s["color"])
