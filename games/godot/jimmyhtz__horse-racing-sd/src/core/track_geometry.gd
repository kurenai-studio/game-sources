extends RefCounted
## Equal phase is shared by all lanes, rather than equal physical distance.
var straight_half := 240.0
var inner_radius := 100.0
var lane_width := 18.0

func point(progress: float, lane: int) -> Vector2:
	assert(lane >= 0 and lane < 5)
	var phase := fposmod(progress, 1.0) * 4.0
	var radius := inner_radius + lane * lane_width
	if phase < 1.0:
		return Vector2(lerpf(-straight_half, straight_half, phase), radius)
	if phase < 2.0:
		var angle := PI / 2.0 - (phase - 1.0) * PI
		return Vector2(straight_half, 0) + Vector2(cos(angle),sin(angle)) * radius
	if phase < 3.0:
		return Vector2(lerpf(straight_half,-straight_half,phase-2.0),-radius)
	var angle := -PI / 2.0 - (phase - 3.0) * PI
	return Vector2(-straight_half,0) + Vector2(cos(angle),sin(angle)) * radius

func curve_center(progress: float) -> Vector2:
	return Vector2(straight_half if fposmod(progress,1.0) < 0.5 else -straight_half, 0)

func lane_length(lane: int) -> float:
	return straight_half * 4.0 + TAU * (inner_radius + lane * lane_width)
