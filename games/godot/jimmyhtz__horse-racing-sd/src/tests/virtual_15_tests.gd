extends SceneTree
var failures := 0
func check(ok: bool, why: String) -> void:
	if not ok: failures+=1; printerr("FAIL: "+why)
func _initialize() -> void:
	if not ResourceLoader.exists("res://core/virtual_players.gd"):
		check(false,"virtual player engine exists"); quit(1); return
	var v=load("res://core/virtual_players.gd")
	var s=load("res://core/game_session.gd").new(); s.fund_demo()
	s.set_virtual_choice(1,11)
	var rng=RandomNumberGenerator.new(); rng.seed=17
	v.place_bets(s,rng)
	check(s.players[1].state in ["READY","OUT"],"virtual seat prepares immediately")
	var first=s.virtual_config.duplicate(true); var bets=s.players[1].bets.duplicate()
	v.place_bets(s,rng)
	check(s.virtual_config==first and bets==s.players[1].bets,"refresh cannot reroll style or bets")
	var copy=load("res://core/game_session.gd").new()
	check(copy.restore(s.export_data()),"virtual settings restore")
	check(copy.virtual_config==s.virtual_config,"fixed random style survives save")
	var fixed=s.virtual_config.seats[1].hidden_style.duplicate()
	s.virtual_config.seats[1].processed_round=-1
	v.place_bets(s,rng)
	check(s.virtual_config.seats[1].hidden_style==fixed,"fixed mode retains personality")
	var payouts={"1-2":2,"1-3":3,"1-4":4,"1-5":6,"2-3":10,"2-4":20,"2-5":40,"3-4":80,"3-5":120,"4-5":200}
	check(not v.plan(payouts,1,v.default_styles()[0],{},"",rng).is_empty(),"one-unit simulated stake is supported")
	for style in v.default_styles():
		for balance in [0,1,3,100,1000000]:
			for trial in range(30):
				var planned=v.plan(payouts,balance,style,{},"",rng)
				var sum:=0
				for pair in planned:
					check(payouts.has(pair) and planned[pair]>0 and planned[pair]<=20,"only capped whole-unit simulated wagers")
					sum+=planned[pair]
				check(sum<=balance,"respects explicit simulated stake ceiling")
	check(v.valid(s.virtual_config),"configuration valid")
	s.virtual_config.seats[1].mode="invalid"
	check(not v.valid(s.virtual_config),"invalid imported virtual mode rejected")
	print("Virtual 15 failures: ",failures); quit(1 if failures else 0)
