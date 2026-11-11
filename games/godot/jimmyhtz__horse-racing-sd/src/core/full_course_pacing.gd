extends RefCounted
## Causal stride maps fix the finish and never inspect standings or results.
const Stream = preload("res://core/crypto_stream.gd")
var rounds := 0
var steps: Array = []
var distance := 0
var controls := {}
var phases: Array = []
var cycles := 3
var amplitude := 0.0
var finish_weight := 0.0
var active := false
const CENTER := 0.93
const SHARPNESS := 40.0
var _floor := 0.0
var _normalizer := 1.0

func _init(master: String, _streams: Array, _thresholds: Array, finish_distance: int, prefs: Dictionary) -> void:
	controls=preload("res://core/race_control.gd").normalized(prefs); distance=finish_distance
	var spread: float=controls.race_spread
	var excitement: float=controls.race_lead_changes
	active=maxf(spread,excitement)>0.0
	cycles=2+roundi(2.0*excitement)
	amplitude=minf(0.038*spread+0.008*excitement,0.90/(TAU*cycles))
	finish_weight=clampf(0.45*spread,0.0,0.65)
	_floor=softplus(-SHARPNESS*CENTER)
	_normalizer=softplus(SHARPNESS*(1.0-CENTER))-_floor
	var pacing=Stream.new(master,"race-control-v2:course")
	for h in range(5): phases.append(TAU*pacing.unit())

static func softplus(x: float) -> float:
	return x if x>30.0 else log(1.0+exp(x))

func common_slope(x: float) -> float:
	return 1.0-finish_weight+finish_weight*SHARPNESS/(1.0+exp(-SHARPNESS*(x-CENTER)))/_normalizer

func common(x: float) -> float:
	if not active or finish_weight==0.0: return x
	if x<=0.0: return x*common_slope(0.0)
	if x>=1.0: return 1.0+(x-1.0)*common_slope(1.0)
	return (1.0-finish_weight)*x+finish_weight*(softplus(SHARPNESS*(x-CENTER))-_floor)/_normalizer

func pace(horse: int, x: float) -> float:
	if not active: return x
	var slope: float=1.0+amplitude*TAU*cycles*cos(phases[horse])
	if x<=0.0: return x*slope
	if x>=1.0: return 1.0+(x-1.0)*slope
	return x+amplitude*(sin(TAU*cycles*x+phases[horse])-sin(phases[horse]))

func position(horse: int, effort: float) -> float:
	return 1000.0*pace(horse,common(effort/float(distance)))

func clock(effort_time: float) -> float:
	if not active: return effort_time
	var nominal_duration: float=distance*0.005/1.5
	return nominal_duration*common(effort_time/nominal_duration)

func summary() -> Dictionary:
	return {"version":"full-course-positive-stride-v1","controls":controls.duplicate(),"distance":distance,
		"cycles":cycles,"amplitude":amplitude,"finish_weight":finish_weight,"coverage":"start through finish",
		"minimum_pace_slope":1.0-amplitude*TAU*cycles,"preserves":"all five finish identities and all win/pair probabilities",
		"effort_round_seconds":0.005,"shared_monotone_clock":true}
