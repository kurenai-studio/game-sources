extends SceneTree
var failures:=0
var checks:=0
func check(ok: bool, caption: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+caption)
func _initialize() -> void:
	var Deck=load("res://core/card_deck.gd")
	var deck=Deck.new()
	var stream=load("res://core/crypto_stream.gd").new("all-percentages-rotation14".sha256_text(),"math")
	var catalog: Dictionary=deck.catalog()
	var worst:=0.0
	for row in catalog.cards:
		var fitted: Dictionary=deck.fit(row.payoffs)
		check(not fitted.is_empty(),"source card fits")
		if fitted.is_empty(): continue
		for i in range(10): check(absf(fitted.pairs[i]-row.pairs[i])<0.0000000001,"independent compiler and runtime fit agree")
		worst=maxf(worst,fitted.max_return_error)
	var report: Array=[]
	for percent in range(70,201):
		var started:=Time.get_ticks_usec()
		var history: Dictionary={}
		var board: Dictionary=deck.next_board(percent,"Variable",{},stream,history)
		check(not board.is_empty(),"generated rotation at %d percent" % percent)
		if board.is_empty(): continue
		check(deck.valid_history(history),"complete saved rotation validates")
		var mean:=0.0
		var counts: Dictionary={}
		for index in history.cycle: counts[index]=counts.get(index,0)+1
		for i in range(history.cards.size()):
			var fitted: Dictionary=deck.fit(history.cards[i])
			check(not fitted.is_empty(),"every generated card has a movement mixture")
			if fitted.is_empty(): continue
			mean+=counts[i]*fitted.card_return/history.cycle.size()
			check(absf(fitted.wins.reduce(func(a,b): return a+b,0.0)-1.0)<0.000000001,"individual wins sum to one")
			check(absf(fitted.pairs.reduce(func(a,b): return a+b,0.0)-1.0)<0.000000001,"combination probabilities sum to one")
			worst=maxf(worst,fitted.max_return_error)
		check(absf(mean-percent/100.0)<0.0000000001,"weighted cycle meets target tolerance")
		report.append({"percent":percent,"cards":history.cards.size(),"cycle_length":history.cycle.size(),"mean_return":mean,"error_percentage_points":100.0*(mean-percent/100.0),"build_seconds":float(Time.get_ticks_usec()-started)/1000000.0})
		if percent%10==0: print("Validated payout ",percent)
	var history: Dictionary={}
	var previous: Dictionary={}
	var sequence: Array=[]
	for i in range(2001):
		var board: Dictionary=deck.next_board(80,"SD",previous,stream,history)
		check(board.card_id!=previous.get("card_id",""),"no adjacent repeat including wrap")
		if i<1000: sequence.append(board.card_id)
		elif i<2000: check(board.card_id==sequence[i-1000],"saved rotation repeats same source sequence")
		previous=board
	check(deck.valid_history(history),"historical rotation validates after wrap")
	var payload: Dictionary={"result":"PASS" if failures==0 else "FAIL","checks":checks,"failures":failures,"historical_cycle_percent":catalog.cycle_return*100,"worst_card_return_fit_error":worst,"variable_rotations":report,"scope":"Deterministic movement-derived probability and cycle expectation checks, not observed winnings or a guarantee of finite-run payouts."}
	FileAccess.open("res://test-results/rotation14-math.json",FileAccess.WRITE).store_string(JSON.stringify(payload,"  "))
	print("DECK MATH 14: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
