extends RefCounted
## Changes the timing of existing steps without changing any finishing outcome.
## At the bridge boundary every horse has exactly its original distance and RNG
## state. No horse can reach the finish inside it, even if every step is two.
const Stream = preload("res://core/crypto_stream.gd")
var rounds := 0
var distance := 0
var steps: Array[PackedByteArray] = []
var controls := {}

static func normalized(prefs: Dictionary) -> Dictionary:
	var result := {}
	for key in ["race_lead_changes","race_spread"]:
		var value = prefs.get(key,0.0)
		result[key]=clampf(float(value),0.0,1.0) if (value is float or value is int) and is_finite(float(value)) else 0.0
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
	var cycles := 1.0+2.0*excitement
	var strength := 1.8*maxf(spread,0.7*excitement)
	for horse in range(5):
		var phase := TAU*float(pacing.raw())/4294967296.0
		var ranked: Array = []
		var high_count := 0
		var horse_steps := PackedByteArray()
		horse_steps.resize(rounds); horse_steps.fill(1)
		for turn in range(rounds):
			var draw: int=streams[horse].raw()
			if draw<thresholds[horse]: high_count+=1
			var progress := (turn+0.5)/rounds
			var wave := sin(TAU*cycles*progress+phase)
			# Fade modulation in/out smoothly to avoid an abrupt pace transition.
			var envelope := sin(PI*progress)
			ranked.append([float(draw)/4294967296.0-strength*wave*envelope,turn])
		ranked.sort_custom(func(a,b): return a[0]<b[0] if a[0]!=b[0] else a[1]<b[1])
		for index in range(high_count): horse_steps[ranked[index][1]]=2
		steps.append(horse_steps)

func summary() -> Dictionary:
	return {"version":"bounded-step-bridge-v1","controls":controls.duplicate(),"rounds":rounds,
		"distance":distance,"end_time":rounds*0.005,"preserves":"all finishers and crossing times"}
