extends RefCounted
const MODES := ["Numbered style","Random Style: Fixed","Random Style: Each Race"]
const FACTORS := [
	["appetite","Amount to bet",0.0,1.0,0.05], ["risk","Favorites to longshots",0.0,1.0,0.05],
	["spread","Spread across combinations",0.0,1.0,0.05], ["randomness","Random choice strength",0.0,1.0,0.05],
	["variation","Amount variation",0.0,1.0,0.05],
	["repeat","Repeat previous selections",0.0,1.0,0.05], ["history","Follow last winning pair",0.0,1.0,0.05],
	["max_bets","Maximum combinations",1,10,1],
	["min_odds","Minimum preferred payoff",2,200,1], ["max_odds","Maximum preferred payoff",2,200,1]]

static func default_styles() -> Array:
	var styles: Array=[]
	var profiles := [[0.25,0.05,0.2],[0.4,0.3,0.5],[0.5,0.8,0.3],[0.7,0.5,0.9],[0.2,1.0,0.1],[0.35,0.1,0.8],[0.8,0.65,0.5],[0.5,0.5,0.5],[0.3,0.25,0.4],[0.6,0.9,0.7]]
	for i in range(10):
		styles.append({"appetite":profiles[i][0],"risk":profiles[i][1],"spread":profiles[i][2],"randomness":0.25 if i!=7 else 1.0,"variation":0.35,"sit_out":0.0,"repeat":0.5 if i==8 else 0.1,"history":0.7 if i==9 else 0.0,"balance_fraction":0.2,"max_bets":10,"min_odds":2,"max_odds":200})
	return styles

static func defaults() -> Dictionary:
	var seats: Array=[]
	for i in range(8): seats.append({"enabled":false,"mode":MODES[0],"preset":i,"rebuy":false,"rebuy_credits":100,"paused":false,"processed_round":-1,"hidden_style":{},"previous_bets":{},"human_snapshot":{}})
	return {"styles":default_styles(),"seats":seats}

static func valid_style(style: Variant) -> bool:
	if not style is Dictionary: return false
	for factor in FACTORS:
		var value: Variant=style.get(factor[0])
		if not (value is float or value is int) or not is_finite(float(value)) or value<factor[2] or value>factor[3]: return false
	return style.min_odds<=style.max_odds

static func valid(config: Variant) -> bool:
	if not config is Dictionary or not config.get("styles") is Array or config.styles.size()!=10 or not config.get("seats") is Array or config.seats.size()!=8: return false
	for style in config.styles:
		if not valid_style(style): return false
	for seat in config.seats:
		if not seat is Dictionary: return false
		for key in ["enabled","rebuy","paused"]:
			if not seat.get(key) is bool: return false
		if seat.get("mode") not in MODES or not seat.get("preset") is int or seat.preset<0 or seat.preset>=10: return false
		if not seat.get("rebuy_credits") is int or seat.rebuy_credits<1 or seat.rebuy_credits>10000: return false
		if not seat.get("processed_round") is int or seat.processed_round< -1: return false
		if not seat.get("hidden_style") is Dictionary or (not seat.hidden_style.is_empty() and not valid_style(seat.hidden_style)): return false
		if not seat.get("previous_bets") is Dictionary: return false
		for pair in seat.previous_bets:
			if pair not in ["1-2","1-3","1-4","1-5","2-3","2-4","2-5","3-4","3-5","4-5"] or not seat.previous_bets[pair] is int or seat.previous_bets[pair]<1 or seat.previous_bets[pair]>20: return false
	return true

static func random_style(rng: RandomNumberGenerator) -> Dictionary:
	var style: Dictionary=default_styles()[0]
	for factor in FACTORS:
		if factor[0] in ["min_odds","max_odds"]: continue
		style[factor[0]]=rng.randi_range(1,10) if factor[0]=="max_bets" else rng.randf()
	style.sit_out*=0.2
	style.balance_fraction=lerpf(0.05,0.5,float(style.balance_fraction))
	return style

static func plan(payouts: Dictionary, maximum_total: int, style: Dictionary, previous: Dictionary, last_pair: String, rng: RandomNumberGenerator) -> Dictionary:
	# Only public information is accepted here. No seed, probability table or future result.
	if maximum_total<=0 or float(style.appetite)<=0: return {}
	# This is a simulated stake ceiling, never a player's balance.
	var limit := mini(200,maximum_total)
	var budget := mini(limit,maxi(1,roundi(limit*float(style.appetite)*lerpf(1.0,rng.randf_range(0.4,1.6),float(style.variation)))))
	if budget<=0: return {}
	var candidates: Array=[]
	for pair in payouts:
		if payouts[pair]>=style.min_odds and payouts[pair]<=style.max_odds: candidates.append(pair)
	if candidates.is_empty(): return {}
	var count := mini(mini(budget,int(style.max_bets)),maxi(1,roundi(lerpf(1.0,float(candidates.size()),float(style.spread)))))
	var chosen: Array=[]
	while chosen.size()<count and not candidates.is_empty():
		var weights: Array=[]; var total:=0.0
		for pair in candidates:
			var weight := pow(float(payouts[pair]),(float(style.risk)-0.5)*3.0)
			weight=lerpf(weight,1.0,float(style.randomness))
			if previous.has(pair): weight*=1.0+float(style.repeat)*8.0
			if pair==last_pair: weight*=1.0+float(style.history)*8.0
			weights.append(weight); total+=weight
		var draw := rng.randf()*total; var selected:=candidates.size()-1
		for i in range(candidates.size()):
			draw-=weights[i]
			if draw<=0: selected=i; break
		chosen.append(candidates[selected]); candidates.remove_at(selected)
	var bets := {}
	for pair in chosen: bets[pair]=1; budget-=1
	while budget>0 and not chosen.is_empty():
		var pair: String=chosen[rng.randi_range(0,chosen.size()-1)]
		if bets[pair]>=20: chosen.erase(pair); continue
		bets[pair]+=1; budget-=1
	return bets

static func place_bets(session: RefCounted, generator: RandomNumberGenerator=null) -> void:
	if session.phase!="BETTING": return
	var rng := generator
	if rng==null: rng=RandomNumberGenerator.new(); rng.randomize()
	var last_pair: String="" if session.race_logs.is_empty() else str(session.race_logs.back().pair)
	for i in range(8):
		var seat: Dictionary=session.virtual_config.seats[i]
		if not seat.enabled or seat.processed_round==session.round_number: continue
		seat.processed_round=session.round_number
		if seat.mode==MODES[2] or (seat.mode==MODES[1] and seat.hidden_style.is_empty()): seat.hidden_style=random_style(rng)
		var style: Dictionary=session.virtual_config.styles[seat.preset] if seat.mode==MODES[0] else seat.hidden_style
		session.players[i].bets=plan(session.board.payouts,200,style,seat.previous_bets,last_pair,rng)
		seat.previous_bets=session.players[i].bets.duplicate()
		session.players[i].state="READY"
		session.record("virtual_bets_prepared",i,0,{"mode":seat.mode,"preset":seat.preset+1,"bets":session.players[i].bets})
