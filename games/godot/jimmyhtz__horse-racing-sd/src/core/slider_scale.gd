extends RefCounted
## A preferred real value can sit at the visual midpoint without losing endpoints.
static func to_position(item: Dictionary, value: float) -> float:
	if not item.has("center"): return value
	var center: float=item.center
	if value<=center: return 0.5*inverse_lerp(float(item.limits[0]),center,value)
	return 0.5+0.5*inverse_lerp(center,float(item.limits[1]),value)

static func from_position(item: Dictionary, position: float) -> float:
	if not item.has("center"): return position
	var center: float=item.center
	var value: float=lerpf(float(item.limits[0]),center,position*2.0) if position<=0.5 else lerpf(center,float(item.limits[1]),(position-0.5)*2.0)
	return clampf(snappedf(value-float(item.limits[0]),float(item.limits[2]))+float(item.limits[0]),float(item.limits[0]),float(item.limits[1]))
