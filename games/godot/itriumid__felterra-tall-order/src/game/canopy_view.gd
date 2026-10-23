class_name CanopyView
extends Node2D
## The canopy overhead: leaves hanging out over the clearing from the jungle around it, thinning
## toward the middle. It's above everyone's heads, so nothing collides with it, and it's drawn
## over everything. The lights don't touch it: it's the shade.

var _clusters: Array[Dictionary] = []


func _ready() -> void:
	light_mask = 0
	var random := RandomNumberGenerator.new()
	random.seed = 11
	var size := Arena.SIZE * World.PIXELS_PER_METER
	for index in 160:
		var side := random.randi_range(0, 3)
		var reach := absf(random.randfn(0.0, 34.0))
		var center: Vector2
		match side:
			0: center = Vector2(random.randf() * size.x, -14.0 + reach)
			1: center = Vector2(size.x + 14.0 - reach, random.randf() * size.y)
			2: center = Vector2(random.randf() * size.x, size.y + 14.0 - reach)
			_: center = Vector2(-14.0 + reach, random.randf() * size.y)
		var picture := EnvironmentArt.leaves(random.randi_range(12, 24), random.randi(), random.randf() < 0.65)
		_clusters.append({"texture": ImageTexture.create_from_image(picture), "at": (center - Vector2(picture.get_size()) / 2.0).round()})


func _draw() -> void:
	for cluster in _clusters:
		draw_texture(cluster.texture, cluster.at)
