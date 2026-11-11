extends SceneTree
var failures:=0
func check(ok: bool, caption: String) -> void:
	if not ok:
		failures+=1
		printerr("FAIL: "+caption)
func _initialize() -> void:
	var Game=load("res://core/game_session.gd")
	var game=Game.new()
	game.fund_demo(); game.configure_pins("1234","4321")
	var snapshot: Dictionary=game.export_data()
	check(snapshot.has("card_history"),"every save contains its own rotation")
	if snapshot.has("card_history"):
		var restored=Game.new()
		check(restored.restore(snapshot),"rotation save reloads")
		check(restored.export_data().card_history==snapshot.card_history,"save preserves entire cycle and cursor")
		check(restored.board==game.board,"save preserves current quoted card")
		var other=Game.new()
		check(other.export_data().card_history!=snapshot.card_history,"new game has a separately randomized rotation")
		var quoted: Dictionary=game.board.duplicate(true)
		game.edit_bet(0,"1-2",2)
		check(game.set_rtp(83,"4321","Variable"),"83 percent change queues")
		check(game.board==quoted and game.export_data().card_history==snapshot.card_history,"midgame change cannot reprice current wagers or rotate early")
		game.set_ready(0,true)
		check(game.start_race("rotation-account-test".sha256_text()),"card-derived race starts")
		var result: Dictionary=game.create_visual_race().run()
		check(game.finish_race(result) and game.announce_result(),"movement-derived finish settles")
		check(game.next_round(),"changed payout opens following card")
		var next: Dictionary=game.export_data()
		check(next.card_history.percent==83 and next.card_history.mode=="Variable" and next.card_history.recent.size()==1,"new payout starts separate fresh card history")
		check(game.validate_state().is_empty(),"new cycle and accounts validate")
		var bad: Dictionary=next.duplicate(true)
		bad.card_history.index=-1
		check(not Game.new().restore(bad),"invalid saved cycle cursor is rejected")
		bad=next.duplicate(true)
		bad.card_history.index=(bad.card_history.index+1)%bad.card_history.cycle.size()
		check(not Game.new().restore(bad),"in-range cursor must match the quoted card")
	print("ROTATION SAVE 14: ",failures," failures")
	quit(1 if failures else 0)
