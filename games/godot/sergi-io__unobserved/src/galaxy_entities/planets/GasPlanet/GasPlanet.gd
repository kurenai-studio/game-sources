extends Node2D

@export var relative_scale: float = 1.0
@export var gui_zoom: float = 1.0

func set_pixels(amount):
	$Cloud.material.set_shader_parameter("pixels", amount)
	$Cloud2.material.set_shader_parameter("pixels", amount)
	$Cloud.size = Vector2(amount, amount)
	$Cloud2.size = Vector2(amount, amount)

func set_light(pos):
	$Cloud.material.set_shader_parameter("light_origin", pos)
	$Cloud2.material.set_shader_parameter("light_origin", pos)

func set_seed(sd):
	var converted_seed = sd%1000/100.0
	$Cloud.material.set_shader_parameter("seed", converted_seed)
	$Cloud2.material.set_shader_parameter("seed", converted_seed)
	$Cloud2.material.set_shader_parameter("cloud_cover", randf_range(0.28, 0.5))

func set_rotates(r):
	$Cloud.material.set_shader_parameter("rotation", r)
	$Cloud2.material.set_shader_parameter("rotation", r)
	
func update_time(t):
	$Cloud.material.set_shader_parameter("time", t * Planet.visual_get_multiplier($Cloud.material) * 0.005)
	$Cloud2.material.set_shader_parameter("time", t * Planet.visual_get_multiplier($Cloud2.material) * 0.005)
	
func set_custom_time(t):
	$Cloud.material.set_shader_parameter("time", t * Planet.visual_get_multiplier($Cloud.material))
	$Cloud2.material.set_shader_parameter("time", t * Planet.visual_get_multiplier($Cloud2.material))

func get_colors():
	return Planet.visual_get_colors_from_shader($Cloud.material) + Planet.visual_get_colors_from_shader($Cloud2.material)

func set_colors(colors):
	Planet.visual_set_colors_on_shader($Cloud.material, colors.slice(0, 4))
	Planet.visual_set_colors_on_shader($Cloud2.material, colors.slice(4, 8))

func randomize_colors():
	var seed_colors = Planet.visual_generate_new_colorscheme(8 + randi()%4, randf_range(0.3, 0.8), 1.0)
	var cols1= []
	var cols2= []
	for i in 4:
		var new_col = seed_colors[i].darkened(i/6.0).darkened(0.7)
#		new_col = new_col.lightened((1.0 - (i/4.0)) * 0.2)
		cols1.append(new_col)
	
	for i in 4:
		var new_col = seed_colors[i+4].darkened(i/4.0)
		new_col = new_col.lightened((1.0 - (i/4.0)) * 0.5)
		cols2.append(new_col)

	set_colors(cols1 + cols2)
