class_name CellState

var ground: GroundType.Type = GroundType.Type.SOIL


func duplicate() -> CellState:
	var s := CellState.new()
	s.ground = ground
	return s
