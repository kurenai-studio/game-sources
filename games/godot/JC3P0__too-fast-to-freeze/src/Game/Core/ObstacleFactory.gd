## ObstacleFactory.gd
## Factory pattern — centralizes all obstacle instantiation.
## Spawner (and any future system) calls ObstacleFactory.create() instead of
## preloading scenes and calling .instantiate() directly.
##
## Usage:
##   var obs = ObstacleFactory.create(ObstacleFactory.ObstacleType.TREE_L, spawn_pos)
##   obstacle_holder.add_child(obs)

class_name ObstacleFactory
extends Node

enum ObstacleType {
	TREE_S,
	TREE_M,
	TREE_L,
	SNOW_POOF_S,
	SNOW_POOF_M,
	SNOW_POOF_L,
	SNOW_BARRIER,
	BOULDER,
	COFFEE,
	AXE,
	SAW_PICKUP,
	HAMMER,
}

const _SCENES: Dictionary = {
	ObstacleType.TREE_S:       preload("res://Game/Obstacles/Tree/tree_s.tscn"),
	ObstacleType.TREE_M:       preload("res://Game/Obstacles/Tree/tree_m.tscn"),
	ObstacleType.TREE_L:       preload("res://Game/Obstacles/Tree/tree_l.tscn"),
	ObstacleType.SNOW_POOF_S:  preload("res://Game/Obstacles/SnowPoofs/snow_poof_s.tscn"),
	ObstacleType.SNOW_POOF_M:  preload("res://Game/Obstacles/SnowPoofs/snow_poof_m.tscn"),
	ObstacleType.SNOW_POOF_L:  preload("res://Game/Obstacles/SnowPoofs/snow_poof_l.tscn"),
	ObstacleType.SNOW_BARRIER: preload("res://Game/Obstacles/SnowBarrier/snow_barrier.tscn"),
	ObstacleType.BOULDER:      preload("res://Game/Obstacles/boulder.tscn"),
	ObstacleType.COFFEE:       preload("res://Game/Obstacles/coffee.tscn"),
	ObstacleType.AXE:          preload("res://Game/Obstacles/Axe/axe_pickup.tscn"),
	ObstacleType.SAW_PICKUP:   preload("res://Game/Obstacles/SawBlade/saw_blade_pickup.tscn"),
	ObstacleType.HAMMER:       preload("res://Game/Obstacles/Hammer/hammer_pickup.tscn"),
}


## Instantiate an obstacle of the given type at the given world position.
## position is applied as local position before the node enters the tree.
## Add the returned node to a parent before relying on global_position.
func create(type: ObstacleType, position: Vector3) -> Node3D:
	var scene: PackedScene = _SCENES.get(type)
	if scene == null:
		push_error("ObstacleFactory: unknown ObstacleType %d" % type)
		return null
	var instance: Node3D = scene.instantiate()
	instance.position = position
	return instance
