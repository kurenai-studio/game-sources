extends Node2D

@export var relative_scale: float = 1.0
@export var gui_zoom: float = 1.0


func set_pixels(amount):
	$Land.material.set_shader_parameter("pixels", amount)
	$Land.size = Vector2(amount, amount)
func set_light(pos):
	$Land.material.set_shader_parameter("light_origin", pos)
func set_seed(sd):
	var converted_seed = sd%1000/100.0
	$Land.material.set_shader_parameter("seed", converted_seed)
func set_rotates(r):
	$Land.material.set_shader_parameter("rotation", r)
func update_time(t):
	$Land.material.set_shader_parameter("time", t * Planet.visual_get_multiplier($Land.material) * 0.02)
func set_custom_time(t):
	$Land.material.set_shader_parameter("time", t * Planet.visual_get_multiplier($Land.material))

func set_dither(d):
	$Land.material.set_shader_parameter("should_dither", d)

func get_dither():
	return $Land.material.get_shader_parameter("should_dither")

func get_colors():
	return Planet.visual_get_colors_from_shader($Land.material)

func set_colors(colors):
	Planet.visual_set_colors_on_shader($Land.material, colors)

func randomize_colors():
	var seed_colors = Planet.visual_generate_new_colorscheme(5 + randi()%3, randf_range(0.3, 0.65), 1.0)
	var cols=[]
	for i in 5:
		var new_col = seed_colors[i].darkened(i/5.0)
		new_col = new_col.lightened((1.0 - (i/5.0)) * 0.2)

		cols.append(new_col)

	set_colors(cols)
