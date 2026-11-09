class_name Fan extends Node2D

var side: bool = false
var home_team: bool
var missing: bool
var stand_timer: int = 0
var sitstr: String = "Sit"
var standstr: String = "Stand"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var popularity = StatBook.TEAMS[Globals.home_team_index].get("popularity", 0.8)
	home_team = randf() < popularity
	missing = randf() < (0.24 / popularity)
	
	if Globals.manager.is_practice:
		home_team = true
		missing = randf() < 0.93
	
	if missing:
		$Person.visible = false
		
	Globals.manager.shot.connect(on_shot)
	if side:
		sitstr += "-Side"
		standstr += "-Side"
		$Chair.texture = preload("res://sprites/fan/Chair-Side.png")
	
	var gm = ["X", "F", "M"][randi_range(0, 2)]
	sitstr += "-" + gm
	standstr += "-" + gm
	
	$Person.texture = Globals.fan_textures[sitstr]
	var home_team_kit = StatBook.TEAMS[Globals.home_team_index]
	var away_team_kit = StatBook.TEAMS[Globals.away_team_index]
	var material = $Person.material.duplicate()
	$Person.material = material
	material.set("shader_parameter/original_0", Globals.color_to_vec4(Globals.helmet_color))
	material.set("shader_parameter/original_1", Globals.color_to_vec4(Globals.shirt_color))
	material.set("shader_parameter/original_2", Globals.color_to_vec4(Globals.skate_color))
	material.set("shader_parameter/original_3", Globals.color_to_vec4(Globals.skin_tone))
	var st = Globals.generate_random_skin_tone()
	material.set("shader_parameter/replace_3", Globals.color_to_vec4(st[0]))
	material.set("shader_parameter/original_4", Globals.color_to_vec4(Globals.hair_color))
	material.set("shader_parameter/replace_4", Globals.color_to_vec4(Globals.generate_random_hair_color()))
	material.set("shader_parameter/original_5", Globals.color_to_vec4(Globals.eye_color))
	material.set("shader_parameter/replace_5", Globals.color_to_vec4(Globals.generate_random_eye_color()))
	material.set("shader_parameter/original_6", Globals.color_to_vec4(Globals.nose_color))
	material.set("shader_parameter/replace_6", Globals.color_to_vec4(st[1]))

	if home_team:
		material.set("shader_parameter/replace_0", Globals.color_to_vec4(home_team_kit["head_color"]))
		material.set("shader_parameter/replace_1", Globals.color_to_vec4(home_team_kit["body_color"]))
		material.set("shader_parameter/replace_2", Globals.color_to_vec4(home_team_kit["foot_color"]))
	else:
		material.set("shader_parameter/replace_0", Globals.color_to_vec4(away_team_kit["away_head_color"]))
		material.set("shader_parameter/replace_1", Globals.color_to_vec4(away_team_kit["away_body_color"]))
		material.set("shader_parameter/replace_2", Globals.color_to_vec4(away_team_kit["away_foot_color"]))

func _physics_process(_delta: float) -> void:
	if stand_timer > 0:
		stand_timer -= 1
		if stand_timer <= 0:
			$Person.texture = Globals.fan_textures[sitstr]

func on_shot(shooting_team: bool, location: Vector2, velocity: Vector2):
	if (global_position.distance_to(location) < 3 * velocity.length()) and shooting_team == home_team:
		stand(120)
	if (shooting_team != home_team and velocity.length() == 0):
		stand(60)

func stand(timer: int = 180) -> void:
	stand_timer = timer
	$Person.texture = Globals.fan_textures[standstr]
