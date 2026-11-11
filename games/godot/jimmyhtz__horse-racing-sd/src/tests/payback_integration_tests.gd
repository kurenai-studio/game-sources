extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, description: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(description)
func _init() -> void:
	if not FileAccess.file_exists("res://core/calibrated_odds.gd"):
		check(false,"Verified whole-credit board is not integrated")
		quit(1)
		return
	var odds=load("res://core/calibrated_odds.gd").new()
	var game_type=load("res://core/game_session.gd")
	var legacy=load("res://core/odds_model.gd").new()
	for percent in range(70,201):
		var board: Dictionary=odds.board(percent)
		check(odds.valid_board(board,percent),"Every supported card is internally valid")
		check(not board.has("pair_targets") and not board.has("first_targets"),"Normal boards contain payoffs without true probabilities")
		for multiplier in board.payouts.values():
			check(multiplier is int and multiplier>=2 and multiplier<=200,"Awards remain whole credits")
	var master: String="integration-test".sha256_text()
	var game=game_type.new()
	game.fund_demo()
	game.configure_pins("1234","4321")
	game.edit_bet(0,"1-2",3)
	game.set_ready(0,true)
	var balance: int=game.players[0].balance
	check(game.start_race(master),"Full-width master accepted at a permitted start")
	var replay=game.create_visual_race()
	var result: Dictionary=replay.run()
	check(game.finish_race(result),"Displayed movement agrees with authoritative movement")
	var amount: int=3*game.board.payouts["1-2"] if result.pair=="1-2" else 0
	check(game.announce_result(),"Verified finish settles")
	check(game.players[0].balance==balance-3+amount,"Whole-credit settlement matches quoted payoff")
	check(not game.announce_result(),"No duplicate settlement")
	check(game.next_round(),"New corrected card opens after settlement")
	check(game.validate_state().is_empty(),"Corrected session validates")
	var saved: Dictionary=game.export_data()
	var restored=game_type.new()
	check(restored.restore(saved),"Corrected save reloads")
	check(restored.players==game.players and restored.board==game.board,"Reload preserves credits and quoted card")
	var old=game_type.new()
	old.fund_demo()
	old.board=legacy.board(90)
	var old_data: Dictionary=old.export_data()
	old_data.schema=3
	var migrated=game_type.new()
	check(migrated.restore(old_data),"Empty legacy round safely upgrades")
	check(migrated.board.schema==3 and migrated.players==old.players,"Upgrade preserves account values")
	check(migrated.validate_state().is_empty(),"Upgraded empty legacy round has a matching saved rotation")
	old.edit_bet(0,"1-2",2)
	old_data=old.export_data()
	old_data.schema=3
	check(migrated.restore(old_data),"Legacy round with wagers remains recoverable")
	check(migrated.board==old.board and migrated.players==old.players,"Existing quoted wagers are never repriced")
	var invalid: Dictionary=game.export_data()
	invalid.board.permutation=[0,0,2,3,4]
	check(not game_type.new().restore(invalid),"Corrupt permutation fails closed")
	var race_type=load("res://core/calibrated_race.gd")
	var canonical: Dictionary=race_type.new(master,odds.board(90)).run()
	for permutation in permutations([0,1,2,3,4]):
		var race=race_type.new(master,odds.board(90,permutation))
		var mapped: Dictionary=race.run()
		check(mapped.first==permutation[canonical.first] and mapped.second==permutation[canonical.second],"Whole-horse permutation preserves actual finish mapping")
		check(mapped.first_time==canonical.first_time and mapped.second_time==canonical.second_time,"Permuting labels leaves physical crossing times unchanged")
		check(mapped.calibrated and mapped.margin>=0,"Production result has verified model and nonnegative second-third margin")
		var post: Array=race.post_positions(2.0)
		check(absf((post[mapped.second]-post[mapped.order[2]])-mapped.margin)<0.00000001,"Post-finish preserves official second-third gap")
		var history: Array=race.replay_events()
		check(history.size()==10 and history.back().end_time==mapped.second_time,"Photo replay ends at official second crossing")
	print("PAYBACK INTEGRATION: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func permutations(values: Array) -> Array:
	if values.is_empty(): return [[]]
	var result: Array=[]
	for value in values:
		var rest:=values.duplicate()
		rest.erase(value)
		for tail in permutations(rest): result.append([value]+tail)
	return result
