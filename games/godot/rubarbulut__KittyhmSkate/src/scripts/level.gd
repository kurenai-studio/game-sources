extends RefCounted
## An authored chart. Beats are shared by the music, lane and street.

const BPM: float = 128.0
const BEAT: float = 60.0 / BPM
const BEATS: int = 96
const DURATION: float = BEATS * BEAT
const PERFECT: float = 0.065
const GOOD: float = 0.145
const STREET_SPEED: float = 180.0
const NOTE_SPEED: float = 185.0

const TRACKS: Array[Dictionary] = [
	{"title": "ALLEY SHIFT", "tag": "FIND YOUR FLOW", "bpm": 128.0, "beats": 96, "speed": 180.0, "drop_start": 48.0, "drop_end": 80.0, "audio": "res://assets/audio/alley_shift.wav", "mechanic": "TAP + OLLIE"},
	{"title": "ROOFTOP RADIO", "tag": "HOLD IT TOGETHER", "bpm": 136.0, "beats": 128, "speed": 190.0, "drop_start": 64.0, "drop_end": 112.0, "audio": "res://assets/audio/rooftop_radio.wav", "mechanic": "HOLD + GRIND"},
	{"title": "MIDNIGHT OVERDRIVE", "tag": "OWN THE WHOLE CITY", "bpm": 148.0, "beats": 160, "speed": 215.0, "drop_start": 80.0, "drop_end": 144.0, "audio": "res://assets/audio/midnight_overdrive.wav", "mechanic": "THE FULL MIX"}
]
const WARMUP: Dictionary = {"title": "LEARN TO RIDE", "tag": "NO PRESSURE. JUST PRACTICE.", "bpm": 96.0, "beats": 48, "speed": 155.0, "drop_start": 40.0, "drop_end": 48.0, "audio": "res://assets/audio/warmup.wav", "mechanic": "SPACE + SHIFT"}

static func spec(index: int = 0) -> Dictionary:
	var result: Dictionary = (WARMUP if index < 0 else TRACKS[clampi(index,0,2)]).duplicate()
	result["beat"] = 60.0/float(result["bpm"])
	result["duration"] = float(result["beats"])*float(result["beat"])
	return result

static func notes(index: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var track: Dictionary = spec(index)
	var beat_length: float = track["beat"]
	if index < 0:
		for beat in [8,10,12,14,20,22,24,26,32,36,40,42]:
			result.append(_note(float(beat),beat_length,2.0 if beat == 32 or beat == 36 else 0.0))
		return result
	var hold_beats: Array = []
	if index == 1:
		hold_beats = [24,40,56,76,92,108]
	elif index == 2:
		hold_beats = [24,40,56,76,92,116,140]
	var occupied_until: float = -1.0
	# First eight beats are a count-in. Teach quarter notes before syncopation.
	for beat in range(8, int(track["beats"])-8):
		if beat % 8 == 7 or float(beat) < occupied_until:
			continue
		var hold: float = (1.5 if index == 2 and beat%8 == 4 else 2.0) if beat in hold_beats else 0.0
		result.append(_note(float(beat),beat_length,hold))
		if hold > 0.0:
			occupied_until = float(beat)+hold+0.25
			continue
		if beat >= float(track["drop_start"]) and beat < float(track["drop_end"]) and beat % 4 == 2:
			result.append(_note(float(beat)+0.5,beat_length))
		elif index == 2 and beat >= 48 and beat%8 == 4:
			result.append(_note(float(beat)+0.5,beat_length))
	return result

static func _note(beat: float, beat_length: float, hold: float = 0.0) -> Dictionary:
	return {"time": beat*beat_length,"beat": beat,"state": 0,"hold": hold*beat_length,"end": (beat+hold)*beat_length,"quality": 0,"award": 0}

static func obstacles(index: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var times: Array = [16,24,32,40,48,54,60,66,72,78,84]
	if index < 0:
		times = [20,26,40]
	elif index == 1:
		times = [16,24,40,56,72,80,96,112]
	elif index == 2:
		times = [16,24,44,52,60,76,84,88,108,116,124,140,148]
	var beat_length: float = spec(index)["beat"]
	for beat in times:
		result.append({"time": beat*beat_length,"hit": false,"cleared": false})
	return result

static func rails(index: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var times: Array = [32,48,64,88,104] if index == 1 else ([32,64,96,128] if index == 2 else [])
	var beat_length: float = spec(index)["beat"]
	for beat in times:
		result.append({"time": beat*beat_length,"end": (beat+(6 if index == 2 else 4))*beat_length,"entered": false,"cleared": false})
	return result

static func section(beat: float, index: int = 0) -> String:
	if index < 0:
		if beat < 16:
			return "01 / FIND THE BEAT"
		if beat < 28:
			return "02 / OLLIE OVER IT"
		if beat < 40:
			return "03 / HOLD THE FLOW"
		return "04 / PUT IT TOGETHER"
	if index > 0:
		if beat < 8:
			return "GET READY TO RIDE"
		if beat < 28:
			return "HOLD THE LONG DIAMONDS"
		if beat < 40:
			return "LAND ON CYAN RAILS"
		if beat >= float(spec(index)["drop_start"]) and beat < float(spec(index)["drop_end"]):
			return "SHIFT DIMENSION"
		if beat >= float(spec(index)["beats"])-8:
			return "COAST TO THE FINISH"
		return "ROOFTOP FLOW" if index == 1 else "MIDNIGHT OVERDRIVE"
	if beat < 8:
		return "FIND YOUR FEET"
	if beat < 32:
		return "01 / ALLEY CAT"
	if beat < 48:
		return "BUILD IT UP"
	if beat < 80:
		return "02 / SHIFT DIMENSION"
	if beat < 88:
		return "ONE LAST RUN"
	return "COAST TO THE FINISH"
