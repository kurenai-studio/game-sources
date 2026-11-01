class_name MobState extends State

const IDLE = "MobStateIdle"
const MOVING = "MobStateMoving"

var mob: Mob

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await owner.ready
	mob = owner.owner as Mob
	assert(mob != null, "The owner of a MobState state type must be a Mob node")
