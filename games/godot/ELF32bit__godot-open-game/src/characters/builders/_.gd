extends MapperUtilities

@warning_ignore("unused_parameter")
static func build(map: MapperMap, entity: MapperEntity) -> Node:
	var node := preload("func_group.gd").build_animated_geometry(map, entity)
	return (node if node else Marker3D.new())
