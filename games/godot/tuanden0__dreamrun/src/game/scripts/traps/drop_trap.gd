## A boulder held above the path. On trigger it falls and pins the monster it lands on (the zone is checked
## at the moment of impact, so the player has to time it). It lands as a solid obstacle the player has to hop
## over, and crushes anyone standing under it as it lands. The monster stays pinned for `stun_time`, long
## enough to cover the rest of a section; the checkpoint lifts the boulder again.
class_name DropTrap
extends Trap

@export var drop_height := 700.0
@export var fall_time := 0.55
@export var rock_size := Vector2(130.0, 110.0)

var _rock: SolidProp
var _collision: CollisionPolygon2D
var _tween: Tween


func _init() -> void:
	stun_time = 30.0


func _ready() -> void:
	super()
	_rock = SolidProp.new()
	_rock.kind = SolidProp.Kind.ROCK
	_rock.size = rock_size
	_rock.shape_seed = 5
	_rock.roughness = 18.0
	# lighter than the monster's pure black, with a pale top edge, so it reads as a separate shape when it lies on it
	_rock.color = Color(0.07, 0.07, 0.085)
	_rock.rim_color = Color(0.32, 0.33, 0.37)
	add_child(_rock)
	_collision = _rock.get_node("Collision")
	# Unlit pale edge along the top: scene lighting is too dark for the fill alone to separate the rock from the
	# monster it lands on.
	var outline := SolidProp.build_outline(SolidProp.Kind.ROCK, rock_size, _rock.shape_seed, _rock.roughness)
	var top := outline.slice(outline.size() / 2 + 1)
	top.append(outline[0])
	var edge := Line2D.new()
	edge.points = top
	edge.width = 3.0
	edge.default_color = Color(0.55, 0.57, 0.64, 0.7)
	edge.begin_cap_mode = Line2D.LINE_CAP_ROUND
	edge.end_cap_mode = Line2D.LINE_CAP_ROUND
	edge.joint_mode = Line2D.LINE_JOINT_ROUND
	edge.material = CanvasItemMaterial.new()
	edge.material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_rock.add_child(edge)
	_restore()


func _fire() -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_rock, "position:y", 0.0, fall_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_land)


func _land() -> void:
	_stun_zone()
	# a little narrower than the rock: its rounded sides are low
	var crush := Rect2(-rock_size.x * 0.4, -rock_size.y, rock_size.x * 0.8, rock_size.y)
	for player: Node2D in get_tree().get_nodes_in_group(&"player"):
		if crush.has_point(to_local(player.global_position + Vector2(0.0, -20.0))) and player.has_method(&"die"):
			player.die()
	_collision.disabled = false


func _rearm() -> void:  # winched back up rather than vanishing
	_collision.disabled = true
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_rock, "position:y", -drop_height, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _restore() -> void:
	if _tween != null:
		_tween.kill()
	_collision.disabled = true  # the boulder only blocks the way once it has landed
	_rock.position = Vector2(0.0, 0.0 if not armed else -drop_height)
