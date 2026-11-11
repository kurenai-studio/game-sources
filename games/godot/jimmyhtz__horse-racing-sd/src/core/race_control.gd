extends RefCounted
## Changes the timing of existing steps without changing any finishing outcome.
## At the bridge boundary every horse has exactly its original distance and RNG
## state. Its preserved positive-step total is always below the finish distance.
const Stream = preload("res://core/crypto_stream.gd")
var rounds := 0
var distance := 0
var steps: Array[PackedFloat64Array] = []
var controls := {}

static func normalized(prefs: Dictionary) -> Dictionary:
	var result := {}
	for key in ["race_lead_changes","race_spread"]:
		var value = prefs.get(key,0.0)
		result[key]=clampf(float(value),0.0,1.5 if key=="race_spread" else 1.0) if (value is float or value is int) and is_finite(float(value)) else 0.0
	return result

func _init(master: String, streams: Array, thresholds: Array, finish_distance: int, prefs: Dictionary) -> void:
	controls=normalized(prefs)
	distance=finish_distance
	var spread: float=controls.race_spread
	var excitement: float=controls.race_lead_changes
	if maxf(spread,excitement)<=0.0: return
	rounds=(distance-1)/2
	var pacing=Stream.new(master,"race-control-v1:pacing")
	# Coherent bursts create separation; shorter phases create more exchanges.
	# These schedules are independent of standings, wagers and future finishers.
	# Internal strength stays independent of the centered display scale.
	# Wider strides use binary units and preserve the original per-horse total.
	var extension := clampf((spread-0.5)*2.0,0,2)
	var cycles := 1.0+4.0*excitement if excitement<=0.5 else 3.0+2.0*(excitement-0.5)
	var strength := 1.8*maxf(minf(1,spread*2.0),0.7*minf(1,excitement*2.0))+0.9*extension
	var low_units := roundi(64.0*maxf(0.125,1.0-0.75*extension))
	var high_units := roundi(64.0*(2.0+1.25*extension))
	var capacity := high_units-low_units
	for horse in range(5):
		var phase := TAU*float(pacing.raw())/4294967296.0
		var ranked: Array = []
		var high_count := 0
		var horse_steps := PackedFloat64Array()
		horse_steps.resize(rounds); horse_steps.fill(float(low_units)/64.0)
		for turn in range(rounds):
			var draw: int=streams[horse].raw()
			if draw<thresholds[horse]: high_count+=1
			var progress := (turn+0.5)/rounds
			var wave := sin(TAU*cycles*progress+phase)
			# Fade modulation in/out smoothly to avoid an abrupt pace transition.
			var envelope := sin(PI*progress)
			ranked.append([float(draw)/4294967296.0-strength*wave*envelope,turn])
		ranked.sort_custom(func(a,b): return a[0]<b[0] if a[0]!=b[0] else a[1]<b[1])
		var budget := (rounds+high_count)*64-rounds*low_units
		var full_steps: int=budget/capacity
		var remainder: int=budget%capacity
		for index in range(full_steps): horse_steps[ranked[index][1]]=float(high_units)/64.0
		if remainder>0: horse_steps[ranked[full_steps][1]]=float(low_units+remainder)/64.0
		steps.append(horse_steps)

func summary() -> Dictionary:
	return {"version":"bounded-step-bridge-v3","controls":controls.duplicate(),"subdivisions":64,"rounds":rounds,
		"distance":distance,"end_time":rounds*0.005,"preserves":"all finishers and crossing times"}
