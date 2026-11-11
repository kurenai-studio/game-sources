extends RefCounted
## Describes verified recent action when a changing order cannot support a long live assertion.
const ORDINALS := ["first","second","third","fourth","fifth"]
const LEADER_CATEGORIES := ["order","recent_order","lead_move","chase"]
const PLACE_CATEGORIES := ["order","recent_order","second","recent_places","place_move","place_chase"]
func build(director: Node, trace: Array, result: Dictionary, seconds: float) -> Array:
	var cues: Array=[]
	var talk: float=clampf(float(director.preferences.race_talk),0,1)
	var dense: float=clampf((talk-0.5)*2.0,0,1)
	var spacing: float=director.talk_interval(talk)+0.25
	var start_text: String=director.prepared.start
	var start_rate: float=director.delivery_rate("race",start_text)
	cues.append({"at":0.15,"deadline":minf(seconds*0.75,maxf(seconds*0.15,director.duration("race",start_text,start_rate)+0.5)),"text":start_text,"short_text":director.phrase("start",{},4),"category":"start","leader":-1,"rate":start_rate})
	var earliest: float=maxf(seconds*lerpf(0.18,0.07,dense),maxf(spacing,cues[0].at+director.duration("race",start_text,start_rate)+float(director.preferences.speech_gap)+0.3))
	var slot:=0
	var leader_calls:=0
	var place_calls:=0
	while talk>0 and earliest<seconds*0.96:
		var best := {}
		var best_score := -1.0
		var candidate_at := earliest
		while candidate_at<=minf(earliest+lerpf(2.5,0.75,dense),seconds*0.96):
			var event := context(director,trace,result,seconds,candidate_at,slot)
			# Repeated second-place moves must not crowd the leader out of the call.
			# Count only cues that fit, and retain the trace evidence and factual window.
			var needs_leader: bool=leader_calls==0 or place_calls>leader_calls+1
			var needs_place: bool=not needs_leader and (place_calls==0 or leader_calls>place_calls+1)
			if (needs_leader and event.category not in LEADER_CATEGORIES) or (needs_place and event.category not in PLACE_CATEGORIES):
				event.category="recent_order" if needs_leader else "recent_places"
				event.replacements={"leader":event.leader+1,"second":event.second+1,"third":event.evidence.order[2]+1}
				event.score=1.0
			if float(event.score)>best_score: best=event; best_score=event.score
			candidate_at+=0.25
		var at: float=best.at
		# Frequency is a minimum interval, not a maximum sentence length.
		# Recent-action calls have evidence; live order calls get a tighter deadline below.
		var deadline: float=minf(at+lerpf(8.0,3.5,dense),seconds*0.99)
		var text: String=director.phrase(best.category,best.replacements,8 if dense>0 else 0)
		# Use present-tense position calls when that order lasts for the full utterance.
		if best.category in ["recent_order","recent_places"]:
			var live_category := "order" if best.category=="recent_order" else "second"
			var live_text: String=director.phrase(live_category,best.replacements,8 if dense>0 else 0)
			var live := {"leader":best.leader,"second":best.second}
			var valid_until := order_deadline(director,trace,float(result.second_time),seconds,at,deadline,live)
			if director.fit_delivery("race",live_text,valid_until-at-0.35).fits:
				var fallback_text: String=director.phrase(best.category,best.replacements,8)
				best.historical_fallback={"category":best.category,"text":fallback_text,"deadline":deadline,"rate":director.delivery_rate("race",fallback_text)}
				best.category=live_category; best.historical=false; text=live_text
				# Native synthesis may return a longer clip than the initial estimate.
				# Keep the factual window so runtime checks the actual duration too.
				deadline=valid_until
		# Pick a short alternate within the same factual category if the first line cannot fit.
		var fit: Dictionary=director.fit_delivery("race",text,deadline-at-0.3)
		for attempt in range(12):
			if fit.fits: break
			text=director.phrase(best.category,best.replacements,8)
			fit=director.fit_delivery("race",text,deadline-at-0.3)
		if fit.fits:
			best.merge({"text":text,"short_text":director.phrase(best.category,best.replacements,8),"rate":fit.rate,"estimated_duration":fit.duration,"deadline":deadline,"latest_start":at+0.65,"historical":best.get("historical",true)})
			cues.append(best)
			if best.category in LEADER_CATEGORIES: leader_calls+=1
			if best.category in PLACE_CATEGORIES: place_calls+=1
			earliest=at+maxf(spacing,fit.duration+float(director.preferences.speech_gap)+0.4)
		else: earliest+=1.0
		slot+=1
	return cues

func order_deadline(director: Node, trace: Array, second_time: float, seconds: float, at: float, deadline: float, cue: Dictionary) -> float:
	if not director.cue_valid(cue,director.record_position(trace,second_time*at/seconds)): return at
	var previous:=at
	for point in trace:
		var time: float=float(point.time)*seconds/second_time
		if time<=at: continue
		if time>deadline:
			return deadline if director.cue_valid(cue,director.record_position(trace,second_time*deadline/seconds)) else previous
		# Linear interpolation cannot reverse the same first/second order between
		# two valid endpoints. Stop at the endpoint before its first change.
		if not director.cue_valid(cue,point.positions): return previous
		previous=time
	return deadline

func context(director: Node, trace: Array, result: Dictionary, seconds: float, at: float, slot: int) -> Dictionary:
	var now: Array=director.record_position(trace,float(result.second_time)*at/seconds)
	var before: Array=director.record_position(trace,float(result.second_time)*maxf(0.0,at-1.5)/seconds)
	var order: Array=director.ranked(now)
	var old: Array=director.ranked(before)
	var first: int=order[0]; var second: int=order[1]; var third: int=order[2]
	var category := "recent_order" if slot%2==0 else "recent_places"
	var replacements := {"leader":first+1,"second":second+1,"third":third+1}
	var score:=1.0
	if old[1]!=second and old.find(second)>1 and slot%2==1:
		var passed: int=old[1] if order.find(old[1])>1 else old[0]
		category="place_move"; replacements={"mover":second+1,"rival":passed+1}; score=4.0
	elif old[0]!=first:
		category="lead_move"; replacements={"mover":first+1,"rival":old[0]+1}; score=4.0 if slot%2==0 else 2.5
	elif old[1]!=second and old.find(second)>1:
		var passed: int=old[1] if order.find(old[1])>1 else old[0]
		category="place_move"; replacements={"mover":second+1,"rival":passed+1}; score=4.0 if slot%2==1 else 3.0
	elif before[first]-before[second]-(now[first]-now[second])>0.35:
		category="chase"; replacements={"leader":first+1,"second":second+1}; score=2.5
	elif before[second]-before[third]-(now[second]-now[third])>0.35:
		category="place_chase"; replacements={"second":second+1,"third":third+1}; score=3.0
	return {"at":at,"category":category,"score":score,"replacements":replacements,"leader":first,"second":second,"evidence":{"from_time":maxf(0.0,at-1.5),"to_time":at,"before":before,"positions":now,"old_order":old,"order":order}}
