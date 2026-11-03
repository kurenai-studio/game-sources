extends RefCounted

const EDGES: Array[float] = [0.20, 0.46, 0.73, 1.0]
const NAMES := ["little", "middle", "big"]


static func ring_for(magnitude: float) -> int:
	if magnitude < EDGES[0]:
		return -1
	for i in 3:
		if magnitude <= EDGES[i + 1]:
			return i
	return 2
