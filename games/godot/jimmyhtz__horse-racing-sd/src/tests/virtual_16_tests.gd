extends SceneTree
var failures:=0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void:
	var s=load("res://core/game_session.gd").new(); s.fund_demo()
	if not s.has_method("set_virtual_choice"):
		check(false,"V lifecycle exists independently of human funds"); quit(1); return
	s.edit_bet(0,"1-2",3); s.set_ready(0,true)
	var human=s.players[0].duplicate(true)
	check(s.set_virtual_choice(0,1) and s.players[0].state=="READY","human enters V Ready")
	for choice in range(1,13):
		check(s.set_virtual_choice(0,choice) and s.virtual_choice(0)==choice,"all numbered and random choices selectable")
	check(s.set_virtual_choice(0,0) and s.players[0]==human,"same-card V exit restores human account and bets")
	s.players[1].balance=0; s.record("test_zero",1,-100)
	check(s.set_virtual_choice(1,1) and s.players[1].state=="READY" and not s.players[1].bets.is_empty(),"zero-credit Out seat can simulate without funding")
	check(s.set_out(1) and s.virtual_choice(1)==0 and s.players[1].balance==0 and s.players[1].state=="OUT","Out cancels V without credit changes")
	check(s.validate_state().is_empty(),"idle V ledger validates")
	for i in range(8): check(s.set_virtual_choice(i,1+i%10),"all seats can be virtual")
	var balances=s.players.map(func(p): return p.balance)
	var saved=load("res://core/game_session.gd").new()
	check(saved.restore(s.export_data()) and saved.virtual_choice(0)==1,"V and human snapshots survive saving")
	check(s.start_race(41),"all-V race starts")
	check(not s.set_virtual_choice(0,0) and not s.set_out(0),"locked race rejects V and Out")
	check(s.players.map(func(p): return p.balance)==balances,"V stakes never debit human funds")
	var interrupted=load("res://core/game_session.gd").new()
	check(interrupted.restore(s.export_data()) and interrupted.players.map(func(p): return p.balance)==balances,"interrupted V race gives no false credit refund")
	check(s.finish_race(s._race.run()) and s.announce_result(),"V race settles")
	check(s.players.map(func(p): return p.balance)==balances and s.validate_state().is_empty(),"V wins and losses leave reconciled human balances untouched")
	check(s.race_logs.back().virtual_seats.all(func(v): return v),"result records which wins are simulations")
	check(s.next_round() and s.set_virtual_choice(0,0),"return to human on later card")
	check(s.players[0].balance==human.balance and s.players[0].bets.is_empty() and s.players[0].state=="BETTING","old-card wagers are not carried to new payoffs")
	var malformed=s.export_data(); malformed.virtual_config.seats[2].human_snapshot={}
	check(not load("res://core/game_session.gd").new().restore(malformed),"V save missing protected human snapshot rejected")
	var mixed=load("res://core/game_session.gd").new(); mixed.fund_demo()
	for pair in mixed.board.payouts: mixed.edit_bet(0,pair,1)
	mixed.set_ready(0,true)
	mixed.virtual_config.styles[0].spread=1.0; mixed.virtual_config.styles[0].appetite=1.0
	mixed.set_virtual_choice(1,1)
	var held: int=mixed.players[1].balance
	check(mixed.start_race(77) and mixed.validate_state().is_empty(),"mixed locked stakes validate")
	check(mixed.players[0].balance==90 and mixed.players[1].balance==held,"only human stakes debited")
	var bad_locked=mixed.export_data(); bad_locked.locked_virtual[1]=false
	check(not load("res://core/game_session.gd").new().restore(bad_locked),"mismatched locked V flags rejected")
	mixed.finish_race(mixed._race.run()); var pair: String=mixed.current_result().pair
	check(mixed.announce_result() and mixed.players[0].balance==90+mixed.board.payouts[pair],"human winner paid normally beside V")
	check(mixed.players[1].balance==held and mixed.race_logs.back().accounting[1]>0,"virtual winner displayed without a credited award")
	check(mixed.validate_state().is_empty(),"mixed settlement ledger reconciles")
	var legacy=load("res://core/game_session.gd").new(); legacy.fund_demo(); legacy.edit_bet(0,"1-2",1)
	var old=legacy.export_data(); old.schema=6; old.virtual_config.seats[0].enabled=true
	for seat in old.virtual_config.seats: seat.erase("human_snapshot")
	var migrated=load("res://core/game_session.gd").new()
	check(migrated.restore(old) and migrated.players[0].balance==100 and migrated.virtual_choice(0)==1,"legacy V preserves current credits and migrates to simulation")
	check(migrated.set_virtual_choice(0,0) and migrated.players[0].bets=={"1-2":1},"legacy reserved wagers preserved in protected snapshot")
	var pending=load("res://core/game_session.gd").new(); pending.fund_demo()
	pending.request_cash_out(0); pending.confirm_cash_out(0)
	check(pending.set_virtual_choice(0,1) and pending.validate_state().is_empty(),"pending human claim can remain frozen beneath V")
	check(pending.set_out(0) and pending.players[0].state=="PENDING PAYOUT" and pending.players[0].pending==100,"cancelling V cannot erase a pending cash-out")
	var cap=load("res://core/game_session.gd").new(); cap.fund_demo(); cap.access.set_pin("operator","1234")
	cap.adjust_balance(0,cap.MAX_BALANCE,"set","1234"); cap.set_virtual_choice(0,1)
	var overflow=cap.export_data(); overflow.virtual_config.seats[0].human_snapshot.bets={"1-2":20}
	check(not load("res://core/game_session.gd").new().restore(overflow),"import rejects protected wagers that would overflow on V exit")
	for flags in [[],[true],"bad",[0,0,0,0,0,0,0,0]]:
		var invalid_log=cap.export_data()
		invalid_log.race_logs.append({"announced":true,"accounting":[0,0,0,0,0,0,0,0],"virtual_seats":flags})
		check(not load("res://core/game_session.gd").new().restore(invalid_log),"import rejects malformed historical V flags")
	var old_log=cap.export_data(); old_log.race_logs.append({"announced":true,"accounting":[1,0,0,0,0,0,0,0]})
	check(load("res://core/game_session.gd").new().restore(old_log),"older history without V flags remains readable")
	print("Virtual 16 failures: ",failures); quit(1 if failures else 0)
