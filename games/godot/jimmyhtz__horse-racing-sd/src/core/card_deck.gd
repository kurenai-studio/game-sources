extends RefCounted
## Cards and their selection history are independent of wagers and race results.
const PAIRS := [[0,1],[0,2],[0,3],[0,4],[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]]
const MASS := 281474976710656
static var data: Dictionary={}
static var cache: Dictionary={}

static func catalog() -> Dictionary:
	if data.is_empty():
		data=JSON.parse_string(FileAccess.get_file_as_string("res://data/card_math_v1.json"))
		assert(data.schema==1 and data.cards.size()==48)
	return data

static func content_id(payoffs: Array) -> String:
	var values: PackedStringArray=[]
	for value in payoffs: values.append(str(int(value)))
	return ",".join(values).sha256_text().left(24)

func make_board(percent: int, mode: String, payoffs: Array, labels: Array, source_id: String="") -> Dictionary:
	var payouts: Dictionary={}
	var integers: Array=[]
	for value in payoffs: integers.append(int(value))
	for i in range(10):
		var pair: Array=[labels[PAIRS[i][0]]+1,labels[PAIRS[i][1]]+1]
		pair.sort()
		payouts["%d-%d" % pair]=integers[i]
	return {"schema":3,"model_version":"card-derived-step-mixture-v1","requested_rtp":percent,"deck_mode":mode,"canonical_payoffs":integers,"payouts":payouts,"permutation":labels.duplicate(),"card_id":content_id(integers),"source_id":source_id,"calibrated":true,"payout_semantics":"total return including original stake"}

func valid_board(board: Variant, percent: int) -> bool:
	if not board is Dictionary or board.get("schema")!=3 or percent<70 or percent>200: return false
	if board.get("requested_rtp")!=percent or not board.get("deck_mode") in ["SD","Variable"]: return false
	if board.deck_mode=="SD" and percent!=80: return false
	if not board.get("source_id") is String or not board.get("canonical_payoffs") is Array or board.canonical_payoffs.size()!=10: return false
	for value in board.canonical_payoffs:
		if not value is int or value<2 or value>200: return false
	if not board.get("permutation") is Array or board.permutation.size()!=5: return false
	for h in range(5):
		if not board.permutation[h] is int or board.permutation.count(h)!=1: return false
	if board.deck_mode=="Variable":
		for value in board.canonical_payoffs:
			if board.canonical_payoffs.count(value)!=1: return false
	return board==make_board(percent,board.deck_mode,board.canonical_payoffs,board.permutation,board.source_id) and not calibration(board).is_empty()

func fit(payoffs: Array) -> Dictionary:
	var key:=content_id(payoffs)
	if cache.has(key): return cache[key]
	var inverse_sum:=0.0
	for value in payoffs: inverse_sum+=1.0/float(value)
	var card_return:=1.0/inverse_sum
	var targets: Array=[]
	for value in payoffs: targets.append(card_return/float(value))
	for component in range(catalog().basis.size()):
		var basis: Dictionary=data.basis[component]
		var weights: Array=[]
		for row in basis.inverse:
			var weight:=0.0
			for j in range(10): weight+=float(row[j])*targets[j]
			weights.append(weight)
		if weights.min() < -0.0000000001: continue
		var total:=0.0
		for i in range(10):
			weights[i]=maxf(weights[i],0.0)
			total+=weights[i]
		var units: Array=[]
		var fractions: Array=[]
		var used:=0
		for i in range(10):
			var scaled: float=weights[i]/total*MASS
			units.append(int(floorf(scaled)))
			used+=units.back()
			fractions.append(scaled-floorf(scaled))
		var priority: Array=range(10)
		priority.sort_custom(func(a,b): return fractions[a]>fractions[b])
		if MASS-used<0 or MASS-used>10: continue
		for i in range(MASS-used): units[priority[i]]+=1
		var ordered: Array=[]
		var wins: Array=[]
		for i in range(5):
			var row: Array=[]
			var win:=0.0
			for j in range(5):
				var probability:=0.0
				for k in range(10): probability+=float(units[k])/MASS*float(basis.orders[k][i][j])
				row.append(probability)
				win+=probability
			ordered.append(row)
			wins.append(win)
		var pairs: Array=[]
		var error:=0.0
		for i in range(10):
			var probability: float=ordered[PAIRS[i][0]][PAIRS[i][1]]+ordered[PAIRS[i][1]][PAIRS[i][0]]
			pairs.append(probability)
			error=maxf(error,absf(probability*float(payoffs[i])-card_return))
		if error>0.000001: continue
		var result: Dictionary={"payoffs":payoffs.duplicate(),"component":component,"profile_units":units,"pairs":pairs,"ordered":ordered,"wins":wins,"card_return":card_return,"max_return_error":error}
		if cache.size()>=256: cache.erase(cache.keys()[0])
		cache[key]=result
		return result
	return {}

func calibration(board: Dictionary) -> Dictionary:
	return fit(board.canonical_payoffs)

func new_cycle(stream: RefCounted, counts: Array) -> Array:
	var cycle: Array=[]
	for i in range(counts.size()):
		for count in range(int(counts[i])): cycle.append(i)
	var order: Array=stream.permutation(cycle.size())
	var shuffled: Array=[]
	for index in order: shuffled.append(cycle[index])
	var n:=shuffled.size()
	for i in range(n):
		var next: int=(i+1)%n
		if shuffled[i]!=shuffled[next]: continue
		var start: int=stream.index(n)
		for offset in range(n):
			var j: int=(start+offset)%n
			if j in [i,next,(next+1)%n] or (j+1)%n==next: continue
			if shuffled[j] in [shuffled[i],shuffled[(next+1)%n]]: continue
			if shuffled[next] in [shuffled[(j+n-1)%n],shuffled[(j+1)%n]]: continue
			var temp: int=shuffled[next]
			shuffled[next]=shuffled[j]
			shuffled[j]=temp
			break
	for i in range(n): assert(shuffled[i]!=shuffled[(i+1)%n])
	return shuffled

func card_return(payoffs: Array) -> float:
	var total:=0.0
	for value in payoffs: total+=1.0/float(value)
	return 1.0/total

func valid_history(history: Variant) -> bool:
	if not history is Dictionary: return false
	if history.is_empty(): return true
	if not history.get("percent") is int or history.percent<70 or history.percent>200 or not history.get("mode") in ["SD","Variable"]: return false
	if not history.get("recent") is Array or history.recent.size()>48: return false
	for id in history.recent:
		if not id is String: return false
	if not history.get("revision") is String or not history.get("cycle") is Array or not history.get("index") is int: return false
	var n: int=history.cycle.size()
	if n<768 or n>1536 or history.index<0 or history.index>=n: return false
	var size:=48 if history.mode=="SD" else 128
	var counts: Array=[]
	counts.resize(size); counts.fill(0)
	for i in range(n):
		var value=history.cycle[i]
		if not value is int or value<0 or value>=size or value==history.cycle[(i+1)%n]: return false
		counts[value]+=1
	if history.mode=="SD":
		if history.percent!=80 or n!=1000: return false
		if history.revision==catalog().revision:
			for i in range(48):
				if counts[i]!=int(data.cycle_counts[i]): return false
	else:
		if not history.get("cards") is Array or history.cards.size()!=128: return false
		var mean:=0.0
		var ids: Dictionary={}
		for i in range(128):
			var values=history.cards[i]
			if not values is Array or values.size()!=10 or counts[i]<3: return false
			for value in values:
				if not value is int or value<2 or value>200 or values.count(value)!=1: return false
			var id:=content_id(values)
			if ids.has(id): return false
			ids[id]=true
			var actual:=card_return(values)
			if absf(actual-history.percent/100.0)>0.02500001: return false
			mean+=counts[i]*actual/n
		if absf(mean-history.percent/100.0)>0.000000001: return false
	return true

func next_board(percent: int, requested_mode: String, previous: Dictionary, stream: RefCounted, history: Dictionary={}) -> Dictionary:
	var mode: String="SD" if requested_mode=="SD" and percent==80 else "Variable"
	var revision: String=catalog().revision if mode=="SD" else "variable-cycle-v1"
	if history.get("percent")!=percent or history.get("mode")!=mode or history.get("revision")!=revision:
		var fresh: Dictionary={"percent":percent,"mode":mode,"recent":[],"index":0,"revision":revision}
		if mode=="SD": fresh.cycle=new_cycle(stream,data.cycle_counts)
		else:
			var collection:=variable_collection(percent,stream)
			if collection.is_empty(): return {}
			fresh.cards=collection.cards
			fresh.cycle=new_cycle(stream,collection.counts)
		var first: Array=data.cards[fresh.cycle[0]].payoffs if mode=="SD" else fresh.cards[fresh.cycle[0]]
		if content_id(first)==previous.get("card_id",""): fresh.cycle.append(fresh.cycle.pop_front())
		history.clear()
		history.merge(fresh)
	var row: int=history.cycle[history.index]
	var payoffs: Array=data.cards[row].payoffs if mode=="SD" else history.cards[row]
	var source: String=data.cards[row].id if mode=="SD" else "generated-%d" % row
	history.index=(history.index+1)%history.cycle.size()
	var board:=make_board(percent,mode,payoffs,stream.permutation(5),source)
	history.recent.append(board.card_id)
	if history.recent.size()>48: history.recent.pop_front()
	return board

func matches_history(board: Dictionary, history: Dictionary, requested_mode: String) -> bool:
	if board.get("schema")!=3: return history.is_empty()
	var mode: String="SD" if requested_mode=="SD" and board.requested_rtp==80 else "Variable"
	if history.is_empty() or history.percent!=board.requested_rtp or history.mode!=mode or board.deck_mode!=mode: return false
	if history.recent.is_empty() or history.recent.back()!=board.card_id: return false
	# An updated source library cannot reprice the card already on the table.
	# Finish that card, then next_board replaces the old revision's rotation.
	if mode=="SD" and history.revision!=catalog().revision: return true
	var n: int=history.cycle.size()
	for offset in range(history.recent.size()):
		var index: int=(history.index-1-offset+n)%n
		var row: int=history.cycle[index]
		var values: Array=data.cards[row].payoffs if mode=="SD" else history.cards[row]
		if content_id(values)!=history.recent[-1-offset]: return false
	return true

func candidate(percent: int, stream: RefCounted) -> Array:
	var target:=float(percent)/100.0
	var strengths: Array=[]
	var sum:=0.0
	for h in range(5):
		var value: float=exp(-3.0*stream.unit())
		strengths.append(value)
		sum+=value
	for h in range(5): strengths[h]/=sum
	var scale: float=0.94+0.12*stream.unit()
	var payoffs: Array=[]
	for pair in PAIRS:
		var a: float=strengths[pair[0]]
		var b: float=strengths[pair[1]]
		var probability: float=a*b/(1.0-a)+b*a/(1.0-b)
		var value:=clampi(roundi(target*scale/probability),2,200)
		if value in payoffs:
			for distance in range(1,200):
				if value+distance<=200 and not value+distance in payoffs:
					value+=distance; break
				if value-distance>=2 and not value-distance in payoffs:
					value-=distance; break
		payoffs.append(value)
	if absf(card_return(payoffs)-target)>0.025: return []
	if fit(payoffs).is_empty(): return []
	return payoffs

func variable_collection(percent: int, stream: RefCounted) -> Dictionary:
	var cards: Array=[]
	var ids: Dictionary={}
	var returns: Array=[]
	for attempt in range(20000):
		var values:=candidate(percent,stream)
		if values.is_empty(): continue
		var id:=content_id(values)
		if ids.has(id): continue
		ids[id]=true
		cards.append(values)
		returns.append(card_return(values))
		if cards.size()==128: break
	if cards.size()!=128: return {}
	var target:=float(percent)/100.0
	if returns.min()>=target or returns.max()<=target: return {}
	var counts:=balance_counts(returns,target)
	return {} if counts.is_empty() else {"cards":cards,"counts":counts}

func balance_counts(returns: Array, target: float) -> Array:
	var n:=returns.size()
	var differences: Array=[]
	for a in range(n):
		for b in range(n):
			if a!=b: differences.append([returns[b]-returns[a],a,b])
	differences.sort_custom(func(a,b): return a[0]<b[0])
	for size in range(768,1537):
		var counts:=initial_counts(returns,target,size)
		if counts.is_empty(): continue
		for iteration in range(12):
			var residual: float=target*size
			for i in range(n): residual-=counts[i]*returns[i]
			if absf(residual/size)<0.0000000001: return counts
			var error:=absf(residual)
			var best: Array=[]
			for change in differences:
				var a: int=change[1]
				var b: int=change[2]
				if counts[a]<=3: continue
				var wanted: float=residual-change[0]
				var left:=0
				var right:=differences.size()
				while left<right:
					var middle:=int((left+right)/2)
					if differences[middle][0]<wanted: left=middle+1
					else: right=middle
				for index in [left-1,left]:
					if index<0 or index>=differences.size(): continue
					var other: Array=differences[index]
					var c: int=other[1]
					var d: int=other[2]
					if counts[c] <= (4 if c==a else 3): continue
					var next_error: float=absf(wanted-other[0])
					if next_error<error:
						error=next_error; best=[a,b,c,d]
			if best.is_empty(): break
			counts[best[0]]-=1; counts[best[1]]+=1
			counts[best[2]]-=1; counts[best[3]]+=1
	return []

func initial_counts(returns: Array, target: float, size: int) -> Array:
	var base_sum:=0.0
	for value in returns: base_sum+=3.0*value
	var remaining:=size-3*returns.size()
	var needed: float=(target*size-base_sum)/remaining
	if needed<=returns.min() or needed>=returns.max(): return []
	var lower: float=-2000.0
	var upper: float=2000.0
	var weights: Array=[]
	var total:=0.0
	for iteration in range(50):
		var tilt: float=(lower+upper)/2.0
		weights.clear(); total=0.0
		var weighted:=0.0
		for value in returns:
			var weight:=exp(tilt*(float(value)-target))
			weights.append(weight); total+=weight; weighted+=weight*value
		if weighted/total<needed: lower=tilt
		else: upper=tilt
	var counts: Array=[]
	var fractions: Array=[]
	var assigned:=0
	for weight in weights:
		var scaled: float=weight/total*remaining
		var amount:=int(floorf(scaled))
		counts.append(3+amount); assigned+=amount
		fractions.append(scaled-amount)
	var order: Array=range(returns.size())
	order.sort_custom(func(a,b): return fractions[a]>fractions[b])
	for i in range(remaining-assigned): counts[order[i]]+=1
	if counts.max()>=size/2: return []
	return counts
