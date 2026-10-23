extends Node

const MAX_COLLIDERS: int = 8

@export var enabled := true:
	set(value):
		set_physics_process(value)
		enabled = value

@export_range(0.001, 1000.0, 0.001, "suffix:kg") var mass: float = 80.0
@export_range(0.0, 1.0) var bounce: float = 0.2

@onready var character: CharacterBody3D = get_parent()

var _array: Array = []
func _array_get_collider_index(collider: RigidBody3D) -> int:
	for index in range(1, 1 + _array[0] * 8, 8):
		if _array[index + 0] == collider: return index
	if _array[0] + 1 > MAX_COLLIDERS:
		return -1

	_array[0] += 1
	_array[1 + (_array[0] - 1) * 8] = collider
	return 1 + (_array[0] - 1) * 8


func _ready() -> void:
	assert("velocity_before_collision" in character)
	_array.resize(1 + MAX_COLLIDERS * 8)
	self.enabled = enabled

@warning_ignore("unused_parameter")
func _physics_process(delta: float) -> void:
	_array.fill(0)
	for ii in range(character.get_slide_collision_count()):
		var collision := character.get_slide_collision(ii)
		for i in range(collision.get_collision_count()):
			var collider := collision.get_collider(i)
			if not is_instance_valid(collider): continue
			if not collider is RigidBody3D: continue

			var index := _array_get_collider_index(collider)
			if index < 0: continue

			var position := collision.get_position(i)
			var normal := collision.get_normal(i)
			_array[index + 1] += position.x
			_array[index + 2] += position.y
			_array[index + 3] += position.z
			_array[index + 4] += normal.x
			_array[index + 5] += normal.y
			_array[index + 6] += normal.z
			_array[index + 7] += 1.0

	var character_push_velocity := Vector3.ZERO
	for index in range(1, 1 + _array[0] * 8, 8):
		var collider: RigidBody3D = _array[index + 0]
		var count: float = _array[index + 7]

		var position := Vector3.ZERO
		position.x = _array[index + 1] / count
		position.y = _array[index + 2] / count
		position.z = _array[index + 3] / count

		var direction := Vector3.ZERO
		direction.x = _array[index + 4]
		direction.y = _array[index + 5]
		direction.z = _array[index + 6]
		direction = direction.normalized()

		var m1: float = mass
		var m2: float = collider.mass
		var v1: float = character.velocity_before_collision.dot(direction)
		var v2: float = collider.linear_velocity.dot(direction)

		var collider_push_velocity := m1 * (1.0 + bounce) * v1
		collider_push_velocity += (m2 - m1 * bounce) * v2
		collider_push_velocity /= (m1 + m2)

		var push_velocity := (m1 - m2 * bounce) * v1
		push_velocity += m2 * (1.0 + bounce) * v2
		push_velocity /= (m1 + m2)

		collider.apply_impulse(direction *
			collider.mass * collider_push_velocity,
			position - collider.global_position)

		character_push_velocity += direction * push_velocity
	if not character_push_velocity.is_zero_approx():
		character.velocity += character_push_velocity
