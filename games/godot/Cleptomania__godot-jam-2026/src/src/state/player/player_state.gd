class_name PlayerState extends State

const IDLE = "PlayerStateIdle"
const MOVING = "PlayerStateMoving"

var player: Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await owner.ready
	player = owner as Player
	assert(player != null, "The owner of a PlayerState state type must be a Player node")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
