extends Node2D

onready var light_node = get_node("/root/root/light")
onready var light_mask_viewport = get_node("/root/root/light_mask_viewport")

onready var player = get_node("player")

var player_start_pos

var current_scene = null
var current_scene_name = "hub"

var total_lights = 50
var current_scene_lights = 0
var lights_collected = {"hub" : 0}

var paused = true

func _ready():
	player_start_pos = player.position
	light_node.texture = light_mask_viewport.get_texture()
	get_node("light").visible = true
	current_scene = get_node("hub")
	
	if OS.get_name() == "HTML5":
		get_node("gui/title/container").visible = false
	
	update_lights_counter(get_lights_count())


func play():
	get_node("gui/count").visible = true
	get_node("gui/menu").visible = false
	player.can_move = true
	paused = false


func pause():
	if paused:
		return
	paused = true
	get_node("gui/count").visible = false
	get_node("gui/menu").visible = true
	get_node("gui/menu").restart_button_active(current_scene_name != "hub")
	get_node("gui/menu").grab_focus()
	player.can_move = false


func restart():
	play()
	current_scene_lights = 0
	update_lights_counter(get_lights_count())
	load_scene(current_scene_name)


func on_light_collect():
	current_scene_lights += 1
	var counter = get_lights_count()
	var diff = current_scene_lights - lights_collected[current_scene_name]
	update_lights_counter(counter, diff if diff > 0 else 0)


func update_lights_counter(count, plus = 0):
	if plus == 0:
		get_node("gui/count/text").text = "%d/%d" % [count, total_lights]
	else:
		get_node("gui/count/text").text = "%d(+%d)/%d" % [count, plus, total_lights]

func get_lights_count():
	var sum = 0
	for val in lights_collected.values():
		sum += val
	return sum


func load_scene(scene_name):
	lights_collected[current_scene_name] = max(lights_collected[current_scene_name], current_scene_lights)
	update_lights_counter(get_lights_count())
	if not scene_name in lights_collected:
		lights_collected[scene_name] = 0
	current_scene_lights = 0
	var prev_name = current_scene_name
	current_scene_name = scene_name
	# clearing viewport lights
	for n in light_mask_viewport.get_children():
		light_mask_viewport.remove_child(n)
		n.queue_free()
	if current_scene:
		remove_child(current_scene)
		current_scene.queue_free()
	var scene = load("res://scene/" + scene_name + ".tscn").instance()
	add_child(scene)
	current_scene = scene
	if scene_name == "hub":
		player.global_position = current_scene.get_node("exit/" + prev_name).global_position
	else:
		player.global_position = current_scene.get_node("light_exit").global_position
	player.ignore_teleport = true

func _process(_delta):
	if Input.is_action_just_pressed("ui_pause"):
		pause()
	if Input.is_action_just_pressed("restart") and current_scene_name != "hub" and not paused:
		restart()
