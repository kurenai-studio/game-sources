class_name Rock extends Area2D

## Map of rock image names to the collision node they should keep
const ROCK_COLLISION_MAP: Dictionary[String, String] = {
	"Rock1": "SmallRockCollision",
	"Rock2": "SmallRockCollision",
	"Rock3": "SmallRockCollision",
	"Rock4": "BigRockCollision",
}

## The type of placement this rock uses.
enum Placement {
	## Place the rock somewhere in the north quarter of the map.
	NORTH,
	## Place the rock somewhere in the south quarter of the map.
	SOUTH,
	## Place the rock somewhere in the east quarter of the map.
	EAST,
	## Place the rock somewhere in the west quarter of the map.
	WEST,
	## Place the rock randomly in the map.
	RANDOM
}

@export var placement: Placement

@onready
var rock_shader: ShaderMaterial = $Sprite.material as ShaderMaterial

## Whether the collision rectangle has been built yet.
var built_collision_rect: bool = false
## The collision rectangle for this rock.
var collision_rect: Rect2
## Whether this rock is currently in light.
var in_light: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Randomly roll a rock type
	var rock_name: String = ROCK_COLLISION_MAP.keys()[randi_range(0, len(ROCK_COLLISION_MAP) - 1)]
	var collision_name: String = ROCK_COLLISION_MAP[rock_name]
	
	# Remove collision not corresponding to rock type
	var to_remove: Array[Node] = []
	for child: Node in get_children():
		if child is CollisionShape2D:
			if child.name == collision_name:
				self.collision_rect = child.shape.get_rect()
			else:
				to_remove.append(child)
	for child: Node in to_remove:
		remove_child(child)
	
	# Set rock texture based on name
	var texture = load("res://Images/Rock/" + rock_name + ".png")
	$Sprite.texture = texture


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Update rock shader based on lighthouse info.
	rock_shader.set_shader_parameter("circle_center", Global.lighthouse.get_light_center())
	rock_shader.set_shader_parameter("radius_squared", Global.lighthouse.get_light_radius_squared())
	queue_redraw()
