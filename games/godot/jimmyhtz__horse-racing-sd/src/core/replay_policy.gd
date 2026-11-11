extends RefCounted
## Independent conditional-state reference, transformed by the active stride model.
## No current race or wagers enter calibration. Replay travel is independent.
static var reference: Dictionary={}
static var distributions: Dictionary={}
static func distribution(controls: Dictionary={}, component: int=0) -> PackedFloat64Array:
	if reference.is_empty():
		reference=JSON.parse_string(FileAccess.get_file_as_string("res://data/replay_reference_v2.json"))
	var normalized: Dictionary=preload("res://core/race_control.gd").normalized(controls)
	component=clampi(component,0,reference.components.size()-1)
	var key:=str(component)+"|"+JSON.stringify(normalized)
	if distributions.has(key):return distributions[key]
	var pacing=preload("res://core/full_course_pacing.gd").new("0".repeat(64),[],[],int(reference.distance),normalized)
	var gaps:=PackedFloat64Array()
	for row in reference.components[component]:
		var closest:=0.0
		for h in range(3):
			pacing.phases[h]=TAU*float(row[h+3])/4294967296.0
			closest=maxf(closest,pacing.position(h,float(row[h])))
		gaps.append(1000.0-closest)
	gaps.sort()
	if distributions.size()>=32:distributions.erase(distributions.keys()[0])
	distributions[key]=gaps
	return gaps

static func configuration(percent: float, controls: Dictionary={}, component: int=0) -> Dictionary:
	var rows:=distribution(controls,component)
	var target: float=clampf(percent,1.0,30.0)*rows.size()/100.0
	var index:=clampi(ceili(target)-1,0,rows.size()-1)
	var threshold: float=rows[index]
	var before:=index;var after:=index+1
	while before>0 and absf(rows[before-1]-threshold)<=0.00001:before-=1
	while after<rows.size() and absf(rows[after]-threshold)<=0.00001:after+=1
	return {"threshold":threshold,"tie_fraction":clampf((target-before)/(after-before),0,1),"target_percent":clampf(percent,1,30),
		"calibration":"conditional-gap-v2","samples":rows.size(),"component":component,
		"controls":preload("res://core/race_control.gd").normalized(controls),"calibration_fraction":target/rows.size(),
		"gap_definition":"closest remaining nose when second crosses"}

static func calibrated_fraction(config: Dictionary) -> float:
	var count:=0.0
	var rows:=distribution(config.get("controls",{}),int(config.get("component",0)))
	for gap in rows:
		if gap<config.threshold-0.00001: count+=1
		elif absf(gap-config.threshold)<=0.00001: count+=config.tie_fraction
	return count/rows.size()

static func decide(result: Dictionary, config: Dictionary) -> Dictionary:
	var third:=-1
	for h in range(5):
		if h in [result.first,result.second]: continue
		if third<0 or result.positions[h]>result.positions[third]: third=h
	var gap: float=float(result.positions[result.second])-float(result.positions[third])
	# A repeatable, separate draw only resolves equal gaps at the boundary.
	# It cannot feed back into movement, cards, wagers or account balances.
	var identity: String=str(result.get("seed",JSON.stringify(result)))
	var tie_draw:=float(("photo-replay-v1|"+identity).sha256_text().left(8).hex_to_int())/4294967296.0
	var selected: bool=gap<config.threshold-0.00001 or (absf(gap-config.threshold)<=0.00001 and tie_draw<config.tie_fraction)
	var decision: Dictionary=config.duplicate()
	decision.merge({"second":result.second,"third":third,"gap":gap,"replay":selected,"rule":"second versus third only"})
	return decision
