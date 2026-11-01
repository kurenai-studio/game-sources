## The ending: the child wakes up in a bedroom. Everything before was dark, grey and cold; this is bright and warm. The
## room is built from the same organic outlines as the rest of the game (SolidProp), a light shaft falls from the window,
## birds sing. About ten seconds, no text, no input; then it fades out and asks for the credits.
## Tests turn `change_scenes` off and listen to `scene_requested`.
class_name WakeUp
extends Node2D

signal finished
signal scene_requested(path: String)

@export var duration := 10.5
@export_file("*.tscn") var next_scene := "res://scenes/credits.tscn"
@export var change_scenes := true
## The room's light once the child is awake (CanvasModulate): warm and bright, the opposite of the chapter's.
@export var warm_light := Color(1.0, 0.94, 0.86)
@export var dark_light := Color(0.06, 0.05, 0.05)

const WOOD := Color(0.30, 0.18, 0.12)
const WOOD_RIM := Color(0.55, 0.36, 0.24)

var modulate_node: CanvasModulate

var _child: Node2D
var _blanket: Node2D
var _veil: ColorRect
var _birds: AudioStreamPlayer
var _room: AudioStreamPlayer


func _ready() -> void:
	modulate_node = CanvasModulate.new()
	modulate_node.color = dark_light
	add_child(modulate_node)
	_build_room()
	_build_bed_and_child()
	_build_lights()
	var camera := Camera2D.new()
	camera.position = Vector2(0.0, -230.0)
	camera.zoom = Vector2(1.5, 1.5)
	add_child(camera)
	var layer := CanvasLayer.new()
	layer.layer = 30
	_veil = ColorRect.new()
	_veil.color = Color(0.0, 0.0, 0.0, 1.0)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_veil)
	add_child(layer)
	_room = AudioManager.add_loop(self, "room.ogg")
	_birds = AudioManager.add_loop(self, "birds.ogg")
	_play()


func _solid(node_name: String, pos: Vector2, kind: SolidProp.Kind, size: Vector2, seed_value: int, color: Color, rim: Color) -> SolidProp:
	var prop := SolidProp.new()
	prop.name = node_name
	prop.position = pos
	prop.kind = kind
	prop.size = size
	prop.shape_seed = seed_value
	prop.color = color
	prop.rim_color = rim
	prop.solid = false
	prop.casts_shadow = false
	add_child(prop)
	return prop


func _polygon(parent: Node, outline: PackedVector2Array, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = outline
	poly.color = color
	poly.antialiased = true
	parent.add_child(poly)
	return poly


func _build_room() -> void:
	var wall := Sprite2D.new()
	wall.name = "Wall"
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color(0.98, 0.88, 0.74), Color(0.84, 0.68, 0.54)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 4
	texture.height = 512
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	wall.texture = texture
	wall.position = Vector2(0.0, -280.0)
	wall.scale = Vector2(500.0, 1.6)
	add_child(wall)
	_solid("Floor", Vector2(0.0, 0.0), SolidProp.Kind.GROUND, Vector2(3000.0, 300.0), 7, Color(0.42, 0.27, 0.17), Color(0.66, 0.46, 0.3))
	# window: a dark wood frame round a bright pane, with mullions
	_solid("WindowFrame", Vector2(330.0, -330.0), SolidProp.Kind.SLAB, Vector2(190.0, 240.0), 31, WOOD, WOOD_RIM)
	var pane := _solid("WindowPane", Vector2(330.0, -330.0), SolidProp.Kind.SLAB, Vector2(150.0, 200.0), 32, Color(1.0, 0.98, 0.88), Color(1.0, 1.0, 0.95))
	pane.roughness = 2.0
	for line in [[Vector2(330.0, -430.0), Vector2(330.0, -230.0)], [Vector2(255.0, -330.0), Vector2(405.0, -330.0)]]:
		var mullion := Line2D.new()
		mullion.points = PackedVector2Array(line)
		mullion.width = 7.0
		mullion.default_color = WOOD
		add_child(mullion)
	# furniture, all irregular like everything else
	_solid("Wardrobe", Vector2(-560.0, 0.0), SolidProp.Kind.PILLAR, Vector2(170.0, 340.0), 41, WOOD, WOOD_RIM)
	_solid("ToyBox", Vector2(-410.0, -28.0), SolidProp.Kind.SLAB, Vector2(64.0, 56.0), 42, Color(0.5, 0.3, 0.2), WOOD_RIM)
	_solid("BedsideTable", Vector2(190.0, -38.0), SolidProp.Kind.SLAB, Vector2(90.0, 76.0), 43, WOOD, WOOD_RIM)
	_solid("Lamp", Vector2(190.0, -100.0), SolidProp.Kind.ROCK, Vector2(34.0, 30.0), 44, Color(0.95, 0.85, 0.6), Color(1.0, 0.95, 0.8))


func _build_bed_and_child() -> void:
	_solid("Headboard", Vector2(-300.0, 0.0), SolidProp.Kind.PILLAR, Vector2(34.0, 160.0), 51, WOOD, WOOD_RIM)
	_solid("BedFrame", Vector2(-120.0, -42.0), SolidProp.Kind.SLAB, Vector2(360.0, 34.0), 52, WOOD, WOOD_RIM)
	_solid("Mattress", Vector2(-120.0, -78.0), SolidProp.Kind.SLAB, Vector2(340.0, 40.0), 53, Color(0.82, 0.76, 0.66), Color(0.95, 0.9, 0.8))
	_solid("Pillow", Vector2(-235.0, -98.0), SolidProp.Kind.ROCK, Vector2(84.0, 34.0), 54, Color(0.98, 0.96, 0.9), Color(1.0, 1.0, 0.97))
	# the child is a dark silhouette again, but a small and soft one; pivot at the hip, the body points along -y
	_child = Node2D.new()
	_child.name = "Child"
	_child.position = Vector2(-170.0, -100.0)
	_child.rotation = deg_to_rad(-90.0)  # lying with the head towards the pillow
	add_child(_child)
	var skin := Color(0.17, 0.11, 0.09)
	_polygon(_child, SolidProp.build_outline(SolidProp.Kind.PILLAR, Vector2(30.0, 50.0), 61, 2.0), skin)
	# the legs stay flat under the blanket whatever the body does, so they hang off the scene, not off the rotating torso
	var legs := Line2D.new()
	legs.name = "Legs"
	legs.position = _child.position
	legs.points = PackedVector2Array([Vector2(0.0, 5.0), Vector2(74.0, 5.0)])
	legs.width = 12.0
	legs.default_color = skin
	legs.begin_cap_mode = Line2D.LINE_CAP_ROUND
	legs.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(legs)
	var head := Node2D.new()
	head.name = "Head"
	head.position = Vector2(0.0, -46.0)
	_child.add_child(head)
	_polygon(head, SolidProp.build_outline(SolidProp.Kind.ROCK, Vector2(34.0, 38.0), 62, 4.0), skin)
	var hair := PackedVector2Array()
	for k in 7:  # spikes along the top of the head, as the player has
		var a := PI + PI * k / 6.0
		hair.append(Vector2.from_angle(a) * 19.0 + Vector2(0.0, 19.0))
		hair.append(Vector2.from_angle(a + PI / 14.0) * 25.0 + Vector2(0.0, 19.0))
	hair.append(Vector2(19.0, 19.0))
	_polygon(head, hair, skin).position = Vector2(0.0, -38.0)
	var arm := Line2D.new()
	arm.points = PackedVector2Array([Vector2(6.0, -38.0), Vector2(22.0, -22.0), Vector2(26.0, -4.0)])
	arm.width = 8.0
	arm.default_color = skin
	arm.begin_cap_mode = Line2D.LINE_CAP_ROUND
	arm.end_cap_mode = Line2D.LINE_CAP_ROUND
	_child.add_child(arm)
	# the blanket over the legs; it slides down when the child sits up
	_blanket = _solid("Blanket", Vector2(-40.0, -98.0), SolidProp.Kind.BOULDER, Vector2(250.0, 52.0), 71, Color(0.72, 0.58, 0.5), Color(0.88, 0.74, 0.64))


func _build_lights() -> void:
	var window_light := LightShaft.new()
	window_light.name = "WindowShaft"
	window_light.position = Vector2(330.0, -330.0)
	window_light.rotation = atan2(270.0, -450.0) - PI * 0.5  # the beam runs along local +y: aim it at the bed
	window_light.length = 760.0
	window_light.width = 360.0
	window_light.color = Color(1.0, 0.86, 0.6)
	window_light.energy = 0.0  # LightShaft starts its flicker from this; the cutscene fades base_energy up
	window_light.flicker_amount = 0.04
	add_child(window_light)
	var glow := PointLight2D.new()
	glow.name = "WindowGlow"
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	glow.texture = texture
	glow.texture_scale = 5.0
	glow.color = Color(1.0, 0.88, 0.65)
	glow.energy = 0.0
	glow.position = Vector2(330.0, -300.0)
	add_child(glow)


func _play() -> void:
	var window_light := get_node("WindowShaft") as LightShaft
	var glow := get_node("WindowGlow") as PointLight2D
	var head := _child.get_node("Head") as Node2D
	var tween := create_tween().set_parallel(true)
	# the light comes up, then the sound
	tween.tween_property(_veil, "color:a", 0.0, 1.5)
	tween.tween_property(modulate_node, "color", warm_light, 3.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(window_light, "base_energy", 1.3, 3.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(glow, "energy", 0.9, 3.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_room, "volume_db", -22.0, 4.0)
	tween.tween_property(_birds, "volume_db", -14.0, 5.0).set_delay(1.0)
	# stirs, then sits up and turns to the window
	tween.tween_property(head, "rotation", deg_to_rad(10.0), 1.2).set_delay(3.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_child, "rotation", deg_to_rad(-6.0), 2.2).set_delay(4.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_blanket, "position:x", 40.0, 2.2).set_delay(4.2).set_trans(Tween.TRANS_SINE)
	tween.tween_property(head, "rotation", deg_to_rad(-12.0), 1.6).set_delay(6.6).set_trans(Tween.TRANS_SINE)
	# and out
	tween.tween_property(_veil, "color:a", 1.0, 1.4).set_delay(duration - 1.4)
	tween.tween_property(_room, "volume_db", SILENT_DB, 1.4).set_delay(duration - 1.4)
	tween.tween_property(_birds, "volume_db", SILENT_DB, 1.4).set_delay(duration - 1.4)
	tween.chain().tween_callback(_done)


const SILENT_DB := -80.0


func _done() -> void:
	finished.emit()
	scene_requested.emit(next_scene)
	if change_scenes and next_scene != "":
		get_tree().change_scene_to_file(next_scene)
