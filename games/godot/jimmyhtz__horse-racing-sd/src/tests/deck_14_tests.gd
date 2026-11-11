extends SceneTree
var failures:=0
var checks:=0
func check(ok: bool, caption: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+caption)
func _initialize() -> void:
	if not FileAccess.file_exists("res://core/card_deck.gd"):
		check(false,"card-derived weighted deck is implemented")
		quit(1)
		return
	var deck=load("res://core/card_deck.gd").new()
	var stream=load("res://core/crypto_stream.gd").new("deck-tests".sha256_text(),"cards")
	var previous: Dictionary={}
	var history: Dictionary={}
	for i in range(60):
		var board: Dictionary=deck.next_board(80,"SD",previous,stream,history)
		check(not board.is_empty(),"historical card opens")
		if board.is_empty(): break
		check(board.card_id!=previous.get("card_id",""),"same historical card never repeats immediately")
		check(deck.valid_board(board,80),"historical quoted card validates")
		var fit: Dictionary=deck.calibration(board)
		check(not fit.is_empty() and fit.max_return_error<0.000001,"all payouts fit movement-derived probabilities")
		check(absf(fit.wins.reduce(func(a,b): return a+b,0.0)-1.0)<0.0000001,"horse wins normalize")
		previous=board
	for percent in [70,80,90,100,150,200]:
		for i in range(3):
			var board: Dictionary=deck.next_board(percent,"Variable",previous,stream,history)
			check(not board.is_empty(),"variable card opens at %d" % percent)
			if board.is_empty(): continue
			check(deck.valid_board(board,percent),"variable card validates")
			var unique: Dictionary={}
			for value in board.payouts.values(): unique[value]=true
			check(unique.size()==10,"variable payouts are distinct")
			check(board.card_id!=previous.get("card_id",""),"variable card changes")
			previous=board
	check(deck.valid_history(history),"saved rotation validates")
	print("DECK 14: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
