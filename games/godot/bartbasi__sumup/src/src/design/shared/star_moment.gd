extends RefCounted
## The timeline of one star moment (DESIGN_SYSTEM.md 3.6): when each earned
## star starts its flight, when it lands (the count goes up by one), and
## which landings make the count a multiple of 3, so star_convert plays and
## the free boosters held go up. The skin's HUD builds one per notice with
## stars and draws it from one clock, so any moment can be shown (a test, a
## review capture) and a running one can jump to its end.
##
## Rules:
##   the first star starts delay after the notice; each next one stagger
##     after the one before, but never before the conversion before it ends;
##   a star lands flight after it starts;
##   a landing on a multiple of 3 converts: the free count goes up
##     free_delay after the landing, and the conversion lasts convert_length;
##   tail is how long the last landing's or conversion's decoration runs on.

var count_before: int = 0
var free_before: int = 0
var stars: int = 0
## While the offer has the HUD's place, the stars rise and fade on the notice
## layer and the counter shows its end values at once (7.5).
var offer: bool = false
## Flight start and landing, per star.
var starts: PackedFloat32Array = PackedFloat32Array()
var lands: PackedFloat32Array = PackedFloat32Array()
## 1 where that star's landing converts, else 0.
var converts: PackedInt32Array = PackedInt32Array()
var flight: float = 0.0
var free_delay: float = 0.0
var convert_length: float = 0.0
## The moment's whole length, decoration included.
var total: float = 0.0


## Plans the stars' flights. With 0 stars nothing happens and total is 0.
func plan(p_count_before: int, p_free_before: int, p_stars: int, delay: float, p_flight: float, stagger: float, p_free_delay: float, p_convert_length: float, tail: float) -> void:
	count_before = p_count_before
	free_before = p_free_before
	stars = maxi(p_stars, 0)
	flight = p_flight
	free_delay = p_free_delay
	convert_length = p_convert_length
	starts.clear()
	lands.clear()
	converts.clear()
	total = 0.0
	var earliest: float = 0.0
	for i: int in stars:
		var start: float = maxf(delay + stagger * float(i), earliest)
		var land: float = start + flight
		var converting: bool = (count_before + i + 1) % 3 == 0
		starts.append(start)
		lands.append(land)
		converts.append(1 if converting else 0)
		var ends: float = land + tail
		if converting:
			earliest = land + convert_length
			ends = maxf(ends, land + free_delay + tail)
			ends = maxf(ends, land + convert_length)
		total = maxf(total, ends)


## The count once every star has landed.
func final_count() -> int:
	return count_before + stars


## The free boosters held once every conversion has arrived.
func final_free() -> int:
	var made: int = 0
	for flag: int in converts:
		made += flag
	return free_before + made


## Whether set_stars(count, free_held) asks for exactly what this moment
## ends on, so it may play on.
func delivers(count: int, free_held: int) -> bool:
	return count == final_count() and free_held == final_free()


## The count shown at time t: one more at each landing.
func count_at(t: float) -> int:
	var count: int = count_before
	for land: float in lands:
		if t >= land:
			count += 1
	return count


## The free boosters shown at time t: one more free_delay after each
## converting landing.
func free_at(t: float) -> int:
	var held: int = free_before
	for i: int in lands.size():
		if converts[i] == 1 and t >= lands[i] + free_delay:
			held += 1
	return held


## The index of the last landing at or before t, or -1.
func last_landing(t: float) -> int:
	var found: int = -1
	for i: int in lands.size():
		if t >= lands[i]:
			found = i
	return found


## The index of the conversion running at t (from its landing to
## convert_length after), or -1.
func converting_at(t: float) -> int:
	for i: int in lands.size():
		if converts[i] == 1 and t >= lands[i] and t < lands[i] + convert_length:
			return i
	return -1


## A motion's eased progress at p (0 to 1) on the skin's curve for it.
static func eased(skin: SkinData, motion_name: StringName, p: float) -> float:
	var spec: Dictionary = skin.motion_spec(motion_name)
	var trans: Tween.TransitionType = int(spec.get("trans", Tween.TRANS_LINEAR)) as Tween.TransitionType
	var curve: Tween.EaseType = int(spec.get("ease", Tween.EASE_IN_OUT)) as Tween.EaseType
	return float(Tween.interpolate_value(0.0, 1.0, clampf(p, 0.0, 1.0), 1.0, trans, curve))


## A number extra of a motion, or fallback when the skin has none.
static func extra(skin: SkinData, motion_name: StringName, key: String, fallback: float) -> float:
	return float(skin.motion_spec(motion_name).get(key, fallback))
