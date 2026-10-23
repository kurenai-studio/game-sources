class_name LAYERS

const PHYSICS_3D: Dictionary = {
	"func_liquid/Node3D/Area3D": [(1<<1), (1<<2)],
	"func_liquid/Node3D/Area3D-Objects!": [(1<<2), null],
	"func_liquid/Node3D/AnimatableBody3D": [(1<<3), 0],

	"func_rotor/Node3D/AnimatableBody3D": [(1<<0), 0],
	"func_signpost/AnimatableBody3D": [(1<<0) | (1<<31), 0],
	"func_breakable/Node3D/RigidBody3D": [
		(1<<8) | (1<<2) | (1<<18) | (1<<19),
		(1<<8) | (1<<0)],

	# triggers
	"trigger_presence/Area3D": [0, (1<<20)],
	"trigger_presence/Area3D-Objects!": [(1<<20), null],

	# survival
	"survival_rock/Node3D/Area3D": [0, (1<<24)],
	"survival_rock/Node3D/Area3D-Objects!": [(1<<24), null],
	"survival_rock/Node3D/AnimatableBody3D": [(1<<0) | (1<<31), 0],

	"survival_tree/Node3D/Area3D": [0, (1<<24)],
	"survival_tree/Node3D/Area3D-Objects!": [(1<<24), null],
	"survival_tree/Node3D/AnimatableBody3D": [(1<<0) | (1<<31), 0],

	# mining
	"mining_coal/Node3D/Area3D": [0, (1<<24)],
	"mining_coal/Node3D/Area3D-Objects!": [(1<<24), null],
	"mining_coal/Node3D/AnimatableBody3D": [(1<<0) | (1<<31), 0],

	"mining_iron/Node3D/Area3D": [0, (1<<24)],
	"mining_iron/Node3D/Area3D-Objects!": [(1<<24), null],
	"mining_iron/Node3D/AnimatableBody3D": [(1<<0) | (1<<31), 0],

	"mining_silver/Node3D/Area3D": [0, (1<<24)],
	"mining_silver/Node3D/Area3D-Objects!": [(1<<24), null],
	"mining_silver/Node3D/AnimatableBody3D": [(1<<0) | (1<<31), 0],

	"mining_gold/Node3D/Area3D": [0, (1<<24)],
	"mining_gold/Node3D/Area3D-Objects!": [(1<<24), null],
	"mining_gold/Node3D/AnimatableBody3D": [(1<<0) | (1<<31), 0],
}


static func set_audio_stream_player_area_mask(node: AudioStreamPlayer3D) -> void:
	node.area_mask = PHYSICS_3D["func_liquid/Node3D/Area3D"][0]
