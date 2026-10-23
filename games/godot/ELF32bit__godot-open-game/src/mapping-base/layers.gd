const RENDER_3D: Dictionary = {
	"worldspawn/StaticBody3D/MeshInstance3D": (1<<0) | (1<<1),
	"func_plat/Node3D/AnimatableBody3D/MeshInstance3D": (1<<0) | (1<<1),
	"func_train/Node3D/AnimatableBody3D/MeshInstance3D": (1<<0) | (1<<1),
}

const PHYSICS_3D: Dictionary = {
	"worldspawn/StaticBody3D": [(1<<0), 0],

	"func_door/Node3D/Area3D": [0, (1<<4)],
	"func_door/Node3D/Area3D-Objects!": [(1<<4), null],
	"func_door/Node3D/AnimatableBody3D": [(1<<0), 0],

	"func_plat/Node3D/Area3D": [0, (1<<5)],
	"func_plat/Node3D/Area3D-Objects!": [(1<<5), null],
	"func_plat/Node3D/AnimatableBody3D": [(1<<0), 0],

	"func_door_secret/Node3D/AnimatableBody3D": [(1<<0), 0],
	"func_train/Node3D/AnimatableBody3D": [(1<<0), 0],
	"func_button/Node3D/AnimatableBody3D": [
		(1<<0) | (1<<31), 0],

	"trigger_once/Area3D": [0, (1<<16)],
	"trigger_once/Area3D-Objects!": [(1<<16), null],

	"trigger_multiple/Area3D": [0, (1<<17)],
	"trigger_multiple/Area3D-Objects!": [(1<<17), null],

	"trigger_teleport/Area3D": [0, (1<<18)],
	"trigger_teleport/Area3D-Objects!": [(1<<18), null],

	"trigger_push/Area3D": [0, (1<<19)],
	"trigger_push/Area3D-Objects": [(1<<19), null],
}
