extends CanvasLayer

var home_color: Color
var away_color: Color
var skater_textures: Dictionary = {}
var home_textures: Dictionary = {}
var away_textures: Dictionary = {}
var referee_textures: Dictionary = {}
var home_goalie_textures: Dictionary = {}
var away_goalie_textures: Dictionary = {}
var home_shader_material: ShaderMaterial = ShaderMaterial.new()
var away_shader_material: ShaderMaterial = ShaderMaterial.new()
var fan_textures: Dictionary = {}

var ticks: int = 0
var period_length: float = 120.0
var  helmet_color: Color = Color.from_rgba8(16, 100, 174)
var shirt_color: Color = Color.from_rgba8(96, 176, 248)
var skate_color: Color = Color.from_rgba8(96, 255, 248)
const hair_color = Color("5B3225FF")
const eye_color = Color("086D40FF")
const skin_tone = Color("F88070FF")
const nose_color = Color("C3694DFF")

var player_devices: Array[int] = []
var player_teams: Array[int] = []
var player_auto_swap: Array[bool] = []
var player_colors: Array[Color] = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW]
var player_colors_map = {}

var scorer_stats: Dictionary = {}
var assist_stats: Dictionary = {}
var shot_stats: Dictionary = {}
var faceoff_won_stats: Dictionary = {}
var penalty_stats: Dictionary = {}
var check_stats: Dictionary = {}
var hit_stats: Dictionary = {}
var down_stats: Dictionary = {}
var match_home_score: int = 0
var match_away_score: int = 0

var home_team_index: int = 0
var away_team_index: int = 1
var allow_goalie_control: bool = false
var home_ai_difficulty: int = 0
var away_ai_difficulty: int = 0
var sounds: Dictionary[String, AudioStreamPlayer2D] = {}
var menu_opened: bool = false
var manager: Manager = null

var save_path = "user://settings.cfg"
var use_onscreen_controls: bool = DisplayServer.is_touchscreen_available()

func _init() -> void:
	load_settings()
	var sprites = [
		"Skate Left", "Skate Down", "Skate Up", "Glide Left", "Check Left", "Check Down", "Check Up",
		"Grab Left", "Grab Down", "Grab Up", "Pummel Down", "Pummel Up", "Shoot Left", "Die 1"
	]
	for t in ["light", "medium", "heavy"]:
		for s in sprites:
			var tex = load("res://sprites/" + t + "/" + s + ".png")
			skater_textures[t + "/" + s] = tex
	update_team_textures()
	generate_referee_textures()
	for x in range(0, len(player_colors)):
		player_colors_map["Player %d" % [x + 1]] = player_colors[x].to_html(false)
	home_shader_material.shader = preload("res://shaders/skater.gdshader")
	home_shader_material.set("shader_parameter/helmet", helmet_color);
	home_shader_material.set("shader_parameter/shirt", shirt_color);
	home_shader_material.set("shader_parameter/pants", skate_color);
	away_shader_material.shader = preload("res://shaders/skater.gdshader")
	away_shader_material.set("shader_parameter/helmet", helmet_color);
	away_shader_material.set("shader_parameter/shirt", shirt_color);
	away_shader_material.set("shader_parameter/pants", skate_color);
func skater_texture(size, action) -> Texture2D:
	return skater_textures[size + "/" + action]#.duplicate()

func generate_referee_textures() -> void:
	var sprites = [
		"Skate Left", "Skate Down", "Skate Up", "Glide Left", "Check Left", "Check Down", "Check Up",
		"Grab Left", "Grab Down", "Grab Up", "Pummel Down", "Pummel Up", "Shoot Left", "Die 1"
	]
	for s in sprites:
		var tex = skater_texture("medium", s)
		if tex:
			referee_textures[s] = swap_colors_in_texture_referee(tex)

func _ready() -> void:
	for s in get_node("Sounds").get_children():
		sounds[s.name] = s

func color_to_vec4(color: Color) -> Vector4: 
	return Vector4(color.r, color.g, color.b, color.a)

func update_team_textures() -> void:
	var home_team = StatBook.TEAMS[home_team_index]
	var away_team = StatBook.TEAMS[away_team_index]

	home_color = home_team["body_color"]
	away_color = away_team.get("away_body_color", away_team["body_color"])
	fan_textures = {}
	for gm in ["-X", "-F", "-M"]:
		for s in ["", "-Side"]:
			for p in ["Sit", "Stand"]:
				fan_textures[p + s + gm] = load("res://sprites/fan/" + p + s + gm + ".png")
	var sprites = [
		"Skate Left", "Skate Down", "Skate Up", "Glide Left", "Check Left", "Check Down", "Check Up",
		"Grab Left", "Grab Down", "Grab Up", "Pummel Down", "Pummel Up", "Shoot Left", "Die 1"
	]
	for t in ["light", "medium", "heavy"]:
		home_textures[t] = {}
		away_textures[t] = {}
		for s in sprites:
			var tex = skater_texture(t, s)
			if tex:
				home_textures[t][s] = tex # swap_colors_in_texture_multi(tex, home_team["head_color"], home_team["body_color"], home_team["foot_color"])
				away_textures[t][s] = tex # swap_colors_in_texture_multi(tex, away_team.get("away_head_color", away_team["head_color"]), away_team.get("away_body_color", away_team["body_color"]), away_team.get("away_foot_color", away_team["foot_color"]))
	home_shader_material.set("shader_parameter/replace_helmet", home_team["head_color"]);
	home_shader_material.set("shader_parameter/replace_shirt", home_team["body_color"]);
	home_shader_material.set("shader_parameter/replace_sleeve", home_team["body_color"]);
	home_shader_material.set("shader_parameter/replace_pants", home_team["foot_color"]);
	away_shader_material.set("shader_parameter/replace_helmet", away_team["away_head_color"]);
	away_shader_material.set("shader_parameter/replace_shirt", away_team["away_body_color"]);
	away_shader_material.set("shader_parameter/replace_sleeve", away_team["body_color"]);
	away_shader_material.set("shader_parameter/replace_pants", away_team["away_foot_color"]);
		
	for s in ["Stand", "Skate", "Block Puck", "Bump Player"]:
		var tex = load("res://sprites/goalie/" + s + ".png")
		if tex:
			home_goalie_textures[s] = tex # swap_colors_in_texture_multi(tex, home_team["head_color"], home_team["body_color"], home_team["foot_color"])
			away_goalie_textures[s] = tex # swap_colors_in_texture_multi(tex, away_team.get("away_head_color", away_team["head_color"]), away_team.get("away_body_color", away_team["body_color"]), away_team.get("away_foot_color", away_team["foot_color"]))


func _physics_process(_delta: float) -> void:
	ticks += 1

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://menu/main_menu.tscn")

func get_closest_node(from_position: Vector2, group_name: String) -> Node2D:
	var nodes = get_tree().get_nodes_in_group(group_name)
	if nodes.is_empty():
		return null
	var closest_node = null
	var min_distance: float = INF
	for node in nodes:
		var distance = from_position.distance_squared_to(node.global_position)
		if distance < min_distance:
			min_distance = distance
			closest_node = node
	return closest_node

func swap_colors_in_texture_referee(tex: Texture2D) -> ImageTexture:
	var img: Image = tex.get_image().duplicate()
	for x in range(img.get_width()):
		for y in range(img.get_height()):
			var current_color = img.get_pixel(x, y)
			if current_color.is_equal_approx(shirt_color) or current_color.is_equal_approx(helmet_color) or current_color.is_equal_approx(skate_color):
				var to_col = Color(0.01, 0.01, 0.01)
				if int(x / 6.0) % 2 == 0 and y > 95 and y < 120:
					to_col = Color.LIGHT_GRAY
				img.set_pixel(x, y, to_col)
	return ImageTexture.create_from_image(img)

func swap_colors_in_texture(tex: Texture2D, to_col: Color) -> ImageTexture:
	return swap_colors_in_texture_multi(tex, to_col.darkened(0.3), to_col, to_col.darkened(0.6))

func swap_colors_in_texture_multi(tex: Texture2D, head: Color, body: Color, foot: Color) -> ImageTexture:
	return swap_color_in_texture(
		swap_color_in_texture(
			swap_color_in_texture(
				tex, shirt_color, body
			), helmet_color, head
		), skate_color, foot
	)
func swap_color_in_texture(tex: Texture2D, from_col: Color, to_col: Color) -> ImageTexture:
	# Convert Texture2D to an Image you can edit
	var img: Image = tex.get_image().duplicate()
	#img.lock() # Required for fast pixel manipulation in some contexts
	 # Loop through every pixel coordinates (x, y)
	for x in range(img.get_width()):
		for y in range(img.get_height()):
			var current_color = img.get_pixel(x, y)
			# Optional: add a small tolerance check if dealing with compressed/anti-aliased art
			if current_color.is_equal_approx(from_col):
				img.set_pixel(x, y, to_col)
	#img.unlock()
	# Create a new ImageTexture from the modified Image
	return ImageTexture.create_from_image(img)

func play_sound_at(sound: String, place: Vector2, twang: bool = true) -> void:
	sounds[sound].global_position = place
	if twang:
		sounds[sound].pitch_scale = randf_range(0.9, 1.1)
	sounds[sound].play()

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(save_path)
	if err == OK:
		use_onscreen_controls = config.get_value(
			"Settings", "use_onscreen_controls", DisplayServer.is_touchscreen_available()
		)
		home_team_index = config.get_value("Settings", "home_team_index", 0)
		away_team_index = config.get_value("Settings", "away_team_index", 1)

func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("Settings", "use_onscreen_controls", use_onscreen_controls)
	config.set_value("Settings", "home_team_index", home_team_index)
	config.set_value("Settings", "away_team_index", away_team_index)
	config.save(save_path)

func random_hair_color() -> Color: 	
	var h: float = 0.0 
	var s: float = 0.0
	var v: float = 0.0 	 	
	var hair_type_roll = randf() 	
	if hair_type_roll < 0.40: 
		h = randf_range(0.05, 0.09) 
		s = randf_range(0.40, 0.70) 
		v = randf_range(0.15, 0.40) 
	elif hair_type_roll < 0.75: 
		h = randf_range(0.05, 0.10) 
		s = randf_range(0.10, 0.30) 
		v = randf_range(0.05, 0.15) 
	elif hair_type_roll < 0.92: 
		h = randf_range(0.08, 0.14) 
		s = randf_range(0.30, 0.60) 
		v = randf_range(0.60, 0.90) 
	else: 
		h = randf_range(0.00, 0.06) 
		s = randf_range(0.60, 0.85) 
		v = randf_range(0.30, 0.70)
	return Color.from_hsv(h, s, v)

var hair_bucket = [] #I realize I could have just used a counter and kept 1 copy of the color, to reduce memory, but who cares
func generate_random_hair_color() -> Color:
	if hair_bucket.is_empty():
		var val = random_hair_color()
		for I in randi_range(1, 6):
			hair_bucket.push_back(val)
	return hair_bucket.pop_back()

func random_eye_color() -> Color: 
	var roll = randf() 
	if roll < 0.70: 
		return Color.from_hsv(randf_range(0.05, 0.11), randf_range(0.5, 0.8), randf_range(0.2, 0.5)) 
	elif roll < 0.85: 
		return Color.from_hsv(randf_range(0.52, 0.64), randf_range(0.2, 0.5), randf_range(0.6, 0.9)) 
	elif roll < 0.95: 
		return Color.from_hsv(randf_range(0.09, 0.14), randf_range(0.4, 0.6), randf_range(0.3, 0.6)) 
	else: 
		return Color.from_hsv(randf_range(0.20, 0.36), randf_range(0.3, 0.6), randf_range(0.4, 0.7))

var eye_bucket = []
func generate_random_eye_color() -> Color: 
	if eye_bucket.is_empty():
		var val = random_eye_color()
		for I in randi_range(1, 6):
			eye_bucket.push_back(val)
	return eye_bucket.pop_back()

func random_skin_tone() -> Array[Color]:
	var s = (pow(randf()*.99, 7))
	return [Globals.skin_tone.darkened(s), Globals.nose_color.darkened(s)]

var skin_bucket = []
func generate_random_skin_tone() -> Array[Color]:
	if skin_bucket.is_empty():
		var val = random_skin_tone()
		for I in randi_range(1, 6):
			skin_bucket.push_back(val)
	return skin_bucket.pop_back()
