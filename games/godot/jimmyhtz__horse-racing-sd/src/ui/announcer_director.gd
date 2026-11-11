extends Node
## Plans presentation from a copy of the already locked race. Never changes its RNG or movement.
signal caption_changed(text: String)
const MAX_DELIVERY_RATE := 1.6
var backend: RefCounted = preload("res://ui/speech_backend.gd").new()
var library := preload("res://ui/announcer_phrases.gd").new()
var preferences := {}
var phase := ""
var clock := 0.0
var last_call := -100.0
var ended := -100.0
var started := -100.0
var active_role := ""
var caption := ""
var leader := -1
var suspended := false
var sample := false
var cues: Array = []
var prepared := {}
var race_seconds := 35.0
var start_delay := 1.5
var close_finish := false
var official_called := false
var next_cue := 0
var call_duration := 0.0
var caption_only := false
var logged_failure := ""
var fitting_pending := false
var fitting_passes := 0
func trace_event(kind: String, details: Dictionary) -> void:
	if not has_meta("diagnostics"): return
	var recorder=get_meta("diagnostics")
	if is_instance_valid(recorder): recorder.record(kind,details)
func _ready() -> void:
	if backend.has_signal("playback_event"): backend.playback_event.connect(trace_event)
	if backend.has_method("attach"): backend.attach(self)
	if FileAccess.file_exists("user://announcer-history.json"):
		var saved=JSON.parse_string(FileAccess.get_file_as_string("user://announcer-history.json"))
		if saved is Array: library.recent=saved.slice(-48)
func configure(values: Dictionary) -> void:
	var changed := preferences!=values
	preferences=values.duplicate(true)
	if changed and not active_role.is_empty(): stop()
	caption_changed.emit(caption if preferences.get("subtitles",true) else "")
func resolve_voice(selected: String) -> String:
	var available: Array=backend.voices()
	if available.is_empty(): return ""
	for voice in available:
		if voice.id==selected: return voice.id
	if selected=="Automatic female":
		for voice in available:
			if "zira" in str(voice.name).to_lower() or "female" in str(voice.get("gender","")).to_lower(): return voice.id
		return available[-1].id
	if selected=="Automatic race":
		for voice in available:
			if "david" in str(voice.name).to_lower(): return voice.id
		return available[0].id
	var index := int(selected.trim_prefix("Voice "))-1 if selected.begins_with("Voice ") else 0
	return available[clampi(index,0,available.size()-1)].id
func stop() -> void:
	var had_call := not active_role.is_empty()
	if had_call: trace_event("speech_ended",{"role":active_role,"text":caption,"elapsed":clock-started,"duration":call_duration})
	backend.stop()
	active_role=""
	caption_only=false
	caption=""
	# A silent phase transition is not a spoken line and needs no inter-voice gap.
	if had_call: ended=clock
	caption_changed.emit("")
func pause_for_settings(value: bool) -> void:
	if suspended!=value:
		stop()
		sample=false
		suspended=value
func duration(role: String, text: String, rate: float=0.0) -> float:
	if rate<=0: rate=delivery_rate(role,text)
	if backend.has_method("duration"): return backend.duration(text,resolve_voice(preferences[role+"_voice"]),rate)
	return text.split(" ").size()/(2.6*rate)+0.45
func delivery_rate(role: String, text: String) -> float:
	var energy: float=clampf(float(preferences.get(role+"_energy",0.6)),0,1)
	return minf(MAX_DELIVERY_RATE,(1.12+0.14*energy if role=="race" else 1.04+0.08*energy)+(0.05 if "!" in text else 0.0))
func talk_interval(value: float) -> float:
	return lerpf(14.0,3.0,clampf(value*2.0,0,1)) if value<=0.5 else lerpf(3.0,1.1,clampf((value-0.5)*2.0,0,1))
func fit_delivery(role: String, text: String, available: float) -> Dictionary:
	var rate:=delivery_rate(role,text)
	while duration(role,text,rate)>available and rate<MAX_DELIVERY_RATE:
		rate=minf(MAX_DELIVERY_RATE,rate+0.05)
	var length:=duration(role,text,rate)
	return {"rate":rate,"duration":length,"fits":length<=available}
func speak(role: String, text: String, essential: bool=false, rate: float=0.0) -> void:
	rate=clampf(rate if rate>0 else delivery_rate(role,text),1.0,MAX_DELIVERY_RATE)
	if preferences.get(role+"_mute",false):
		trace_event("speech_skipped",{"reason":"role muted","role":role,"text":text}); return
	# Live cues must already exist: a late synthesis job must never announce stale action.
	var can_play: bool=essential or not backend.has_method("ready_clip") or backend.ready_clip(text,resolve_voice(preferences[role+"_voice"]),rate)
	if not essential and (not active_role.is_empty() or clock-ended<float(preferences.speech_gap)):
		trace_event("speech_skipped",{"reason":"previous call active" if not active_role.is_empty() else "inter-call gap","role":role,"text":text}); return
	if essential: stop()
	active_role=role
	caption_only=not can_play
	caption=("Race: " if role=="race" else "House: ")+text
	started=clock
	last_call=clock
	call_duration=duration(role,text,rate)
	caption_changed.emit(caption if preferences.subtitles else "")
	var volume := roundi(float(preferences.master_volume)*float(preferences[role+"_volume"])*100.0)
	trace_event("speech_started",{"role":role,"text":text,"duration":call_duration,"voice":resolve_voice(preferences[role+"_voice"]),"volume":volume,"caption_only":caption_only,"rate":rate,"rate_limit":MAX_DELIVERY_RATE,"automatic_rate":true})
	if volume>0 and can_play: backend.say(text,resolve_voice(preferences[role+"_voice"]),volume,rate)
func preview(role: String) -> void:
	sample=true
	speak(role,"They're off! Horse three takes the lead. Here comes the finish!" if role=="race" else "A big result on a little racetrack! Congratulations to our winners.",true)
func advance(delta: float) -> void:
	clock+=maxf(delta,0.0)
	if backend.has_method("tick"): backend.tick(delta)
	if "failure" in backend and backend.failure!=logged_failure:
		logged_failure=backend.failure
		if not logged_failure.is_empty(): trace_event("speech_error",{"reason":logged_failure})
	if not active_role.is_empty():
		var silent := caption_only or resolve_voice(preferences[active_role+"_voice"]).is_empty() or float(preferences.master_volume)*float(preferences[active_role+"_volume"])==0.0
		var minimum := minf(call_duration,3.5) if silent else 0.15
		if clock-started>minimum and not backend.speaking(): stop()
		elif clock-started>30.0: stop()
func speaking_result() -> bool:
	return active_role=="race"
func preparing() -> bool:
	if backend.has_method("preparing") and backend.preparing(): return true
	if not fitting_pending: return false
	var retry: Array=[]
	for i in range(cues.size()):
		var cue: Dictionary=cues[i]
		var delivery_end: float=cue.deadline
		if i+1<cues.size(): delivery_end=minf(delivery_end,cues[i+1].at-float(preferences.speech_gap))
		var available: float=delivery_end-cue.at-0.3
		var measured:=duration("race",cue.text,cue.rate)
		if measured<=available: continue
		if fitting_passes<2 and cue.rate<MAX_DELIVERY_RATE:
			cue.rate=minf(MAX_DELIVERY_RATE,maxf(cue.rate+0.08,cue.rate*measured/maxf(0.1,available)*1.05))
			retry.append(clip("race",cue.text,cue.rate))
		elif cue.has("historical_fallback"):
			# A measured voice can outlast a live-order window. Keep the observed
			# facts but say they were recent, using the original action deadline.
			var fallback: Dictionary=cue.historical_fallback
			cue.erase("historical_fallback")
			cue.category=fallback.category; cue.historical=true
			cue.text=fallback.text; cue.short_text=fallback.text; cue.deadline=fallback.deadline
			var fallback_end: float=cue.deadline
			if i+1<cues.size(): fallback_end=minf(fallback_end,cues[i+1].at-float(preferences.speech_gap))
			cue.deadline=fallback_end
			cue.rate=fit_delivery("race",cue.text,fallback_end-cue.at-0.3).rate
			retry.append(clip("race",cue.text,cue.rate))
		elif cue.has("short_text") and cue.short_text!=cue.text:
			cue.text=cue.short_text; cue.rate=MAX_DELIVERY_RATE
			retry.append(clip("race",cue.text,cue.rate))
	fitting_passes+=1
	if not retry.is_empty() and fitting_passes<=3 and backend.has_method("prepare"):
		trace_event("speech_refit",{"pass":fitting_passes,"clips":retry,"rate_limit":MAX_DELIVERY_RATE})
		backend.prepare(retry)
		return preparing()
	fitting_pending=false
	trace_event("speech_plan_final",{"cues":cues,"rate_limit":MAX_DELIVERY_RATE,"fit_passes":fitting_passes})
	return false
func record_position(trace: Array, target: float) -> Array:
	var low := 0
	var high := trace.size()-1
	while high-low>1:
		var middle := (low+high)/2
		if trace[middle].time<=target: low=middle
		else: high=middle
	var alpha := clampf((target-trace[low].time)/maxf(0.00001,trace[high].time-trace[low].time),0.0,1.0)
	var result: Array=[]
	for h in range(5): result.append(lerpf(trace[low].positions[h],trace[high].positions[h],alpha))
	return result

func ranked(positions: Array) -> Array:
	var order := range(5)
	order.sort_custom(func(a,b): return positions[a]>positions[b] if positions[a]!=positions[b] else a<b)
	return order

func cue_valid(cue: Dictionary, positions: Array) -> bool:
	if cue.get("historical",false): return cue.has("evidence")
	var order := ranked(positions)
	for key in ["leader","second","third"]:
		var rank_index: int={"leader":0,"second":1,"third":2}[key]
		if cue.get(key,-1)>=0 and order[rank_index]!=cue[key]: return false
	return true

func phrase(category: String, replacements: Dictionary={}, max_words: int=0) -> String:
	var role := "house" if category in ["small","jackpot","none"] else "race"
	var quirks := {}
	for key in ["humor","sarcasm","energy","detail"]: quirks[key]=preferences.get(role+"_"+key,0.5)
	return library.choose_traits(category,replacements,quirks,max_words).text
func prepare_race(trace: Array, result: Dictionary, seconds: float, needs_photo: bool, award_kind: String) -> void:
	cues.clear()
	fitting_pending=true; fitting_passes=0
	prepared.clear()
	next_cue=0
	official_called=false
	race_seconds=seconds
	close_finish=needs_photo
	start_delay=0.15
	prepared.start=phrase("start",{},7)
	prepared.close=phrase("close")
	prepared.result=phrase("result",{"first":result.first+1,"second":result.second+1,"pair":result.pair.replace("-"," and ")})
	prepared.payout=phrase(award_kind)
	cues=preload("res://ui/race_call_plan.gd").new().build(self,trace,result,seconds)
	trace_event("speech_plan",{"cues":cues,"prepared":prepared,"seconds":seconds,"race_talk":preferences.race_talk,"rate_limit":MAX_DELIVERY_RATE,"automatic_rate":true})
	var clips: Array=[]
	for cue in cues:
		clips.append(clip("race",cue.text,cue.rate))
		if cue.has("short_text"): clips.append(clip("race",cue.short_text,MAX_DELIVERY_RATE))
		if cue.has("historical_fallback"): clips.append(clip("race",cue.historical_fallback.text,cue.historical_fallback.rate))
	for category in ["close","result"]: clips.append(clip("race",prepared[category]))
	clips.append(clip("house",prepared.payout))
	if backend.has_method("prepare"): backend.prepare(clips)
	var history := FileAccess.open("user://announcer-history.json",FileAccess.WRITE)
	if history != null: history.store_string(JSON.stringify(library.recent))
func clip(role: String, text: String, rate: float=0.0) -> Dictionary:
	return {"text":text,"voice":resolve_voice(preferences[role+"_voice"]) if not preferences.get(role+"_mute",false) else "","rate":clampf(rate if rate>0 else delivery_rate(role,text),1.0,MAX_DELIVERY_RATE)}
func observe(current_phase: String, positions: Array, progress: float, official: Dictionary) -> void:
	if suspended: return
	if current_phase!=phase:
		phase=current_phase
		if phase in ["BETTING","PREPARING","COUNTDOWN"]:
			stop()
			return
		if phase=="POST":
			stop()
			if close_finish: speak("race",prepared.get("close","A close finish. Let's see the replay."),true)
			elif official.has("first"):
				speak("race",prepared.get("result","%d first, %d second." % [official.first+1,official.second+1]),true)
				official_called=true
		elif phase=="SETTLED" and not official_called and official.has("first"):
			speak("race",prepared.get("result","%d first, %d second." % [official.first+1,official.second+1]),true)
			official_called=true
		elif phase=="PAYOUT" and float(preferences.house_talk)>0:
			speak("house",prepared.get("payout","The winnings are shown beside the track."),true)
	if phase!="RACING" or positions.size()!=5: return
	var elapsed := progress*race_seconds
	if cues.is_empty():
		# Legacy test and platform fallback still waits for the start signal.
		if progress>=0.05 and leader<0:
			speak("race","They're off!")
			leader=0
		return
	while next_cue<cues.size() and elapsed>=float(cues[next_cue].at):
		var cue: Dictionary=cues[next_cue]
		if (not active_role.is_empty() or clock-ended<float(preferences.speech_gap)) and elapsed<=float(cue.get("latest_start",cue.deadline)): break
		next_cue+=1
		var reason := ""
		if next_cue>1 and (float(preferences.race_talk)<=0 or clock-last_call<talk_interval(float(preferences.race_talk))): reason="frequency spacing"
		elif not active_role.is_empty(): reason="previous call active"
		elif elapsed>float(cue.get("latest_start",cue.deadline)): reason="event too old"
		elif elapsed+duration("race",cue.text,cue.get("rate",0.0))+0.25>float(cue.deadline): reason="audio exceeds window"
		elif not cue_valid(cue,positions): reason="positions changed"
		if not reason.is_empty():
			trace_event("speech_skipped",{"text":cue.text,"reason":reason,"race_seconds":elapsed,"cue":cue})
			continue
		speak("race",cue.text,false,cue.get("rate",0.0))

func _exit_tree() -> void:
	stop()
	if backend.has_method("shutdown"): backend.shutdown()
