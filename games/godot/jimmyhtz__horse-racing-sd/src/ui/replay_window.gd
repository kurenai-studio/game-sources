extends RefCounted
## A window into recorded movement, measured by the runner-up's nose.
static func start_time(trace: Array, second: int, distance: float) -> float:
	if trace.size()<2: return 0.0
	var target := maxf(0.0,1000.0-distance)
	var low := 0
	var high := trace.size()-1
	while high-low>1:
		var middle := (low+high)/2
		if float(trace[middle].positions[second])<target: low=middle
		else: high=middle
	var a: Dictionary=trace[low]; var b: Dictionary=trace[high]
	var moved: float=float(b.positions[second])-float(a.positions[second])
	var alpha := clampf((target-float(a.positions[second]))/maxf(0.000001,moved),0.0,1.0)
	return lerpf(float(a.time),float(b.time),alpha)

static func at(start: float, finish: float, elapsed: float, duration: float) -> float:
	var progress := clampf(elapsed/maxf(0.001,duration),0.0,1.0)
	return lerpf(start,finish,1.0-pow(1.0-progress,2.0))
