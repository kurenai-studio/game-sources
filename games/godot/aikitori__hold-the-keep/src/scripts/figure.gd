class_name Figure
extends Node3D
## Animierte Figur. Figuren mit Skelett (Mini Dungeon) zeichnen manche Handy-Browser nicht: Skinning läuft
## dort nicht. Darum werden ihre Animationen einmal vorab in feste Meshes umgerechnet und als Daumenkino
## abgespielt. Figuren ohne Skelett (Graveyard Kit) behalten ihren AnimationPlayer.

const FPS := 15.0
const BAKED: Array[String] = ["walk", "idle", "die"]

## key -> {anim: [ [Mesh je Teil], ... je Bild ]}
static var _frames: Dictionary = {}
## key -> [Transform3D je Teil]
static var _parts: Dictionary = {}

var speed_scale := 1.0
var _key: String
var _player: AnimationPlayer
var _instances: Array[MeshInstance3D] = []
var _anim := ""
var _time := 0.0
var _loop := true


static func create(key: String) -> Figure:
	var figure := Figure.new()
	figure._key = key
	var model := Models.make(key)
	var skinned := false
	for node in model.find_children("*", "MeshInstance3D", true, false):
		skinned = skinned or (node as MeshInstance3D).skin != null
	# Ohne Grafik (Tests mit --headless) gibt es kein Skelett zum Umrechnen.
	if not skinned or DisplayServer.get_name() == "headless":
		figure.add_child(model)
		for node in model.find_children("*", "AnimationPlayer", true, false):
			figure._player = node
			break
		return figure
	model.free()
	_bake(key)
	for t: Transform3D in _parts[key]:
		var part := MeshInstance3D.new()
		part.transform = t
		figure.add_child(part)
		figure._instances.append(part)
	figure._show(BAKED[1], 0)
	return figure


## Jede Animation in Bilder zu FPS zerlegen, jedes Bild als festes Mesh je Teil.
static func _bake(key: String) -> void:
	if _frames.has(key):
		return
	# Skinning braucht den Szenenbaum. Während die Hauptszene aufgebaut wird, nimmt root keine Kinder an,
	# darum kommt das Modell unter den Autoload FigureStage.
	var model := Models.make(key)
	var stage: Node = (Engine.get_main_loop() as SceneTree).root.get_node("FigureStage")
	stage.add_child(model)
	var meshes: Array[MeshInstance3D] = []
	var transforms: Array[Transform3D] = []
	for node in model.find_children("*", "MeshInstance3D", true, false):
		meshes.append(node)
		transforms.append(Models._relative(node, model))
	var player: AnimationPlayer = model.find_children("*", "AnimationPlayer", true, false)[0]
	var anims := {}
	for anim in BAKED:
		var length := player.get_animation(anim).length
		var count := maxi(2, roundi(length * FPS))
		var frames: Array = []
		player.play(anim)
		for i in count:
			player.seek(length * i / count if anim != "die" else length * i / (count - 1), true)
			var parts: Array[Mesh] = []
			for mi in meshes:
				if mi.skin == null:
					parts.append(mi.mesh)
					continue
				(mi.get_node(mi.skeleton) as Skeleton3D).force_update_all_bone_transforms()
				var baked := mi.bake_mesh_from_current_skeleton_pose()
				for surface in baked.get_surface_count():
					baked.surface_set_material(surface, mi.get_active_material(surface))
				parts.append(baked)
			frames.append(parts)
		anims[anim] = frames
	_frames[key] = anims
	_parts[key] = transforms
	model.free()


func has_animation(anim: String) -> bool:
	return _player.has_animation(anim) if _player != null else _frames[_key].has(anim)


func play(anim: String) -> void:
	if _player != null:
		_player.speed_scale = speed_scale
		_player.play(anim)
		return
	_anim = anim
	_time = 0.0
	_loop = anim != "die"
	_show(anim, 0)


func _process(delta: float) -> void:
	if _player != null:
		_player.speed_scale = speed_scale
		return
	if _anim == "":
		return
	var frames: Array = _frames[_key][_anim]
	_time += delta * speed_scale
	var index := int(_time * FPS)
	index = index % frames.size() if _loop else mini(index, frames.size() - 1)
	_show(_anim, index)


func _show(anim: String, index: int) -> void:
	var parts: Array = _frames[_key][anim][index]
	for i in _instances.size():
		_instances[i].mesh = parts[i]
