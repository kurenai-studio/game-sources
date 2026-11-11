extends RefCounted
signal diagnostic_event(kind: String, details: Dictionary)
const VirtualPlayers = preload("res://core/virtual_players.gd")
var virtual_config := VirtualPlayers.defaults()
var game_id := Crypto.new().generate_random_bytes(16).hex_encode()
const OddsModel = preload("res://core/calibrated_odds.gd")
const LegacyOdds = preload("res://core/odds_model.gd")
const RaceEngine = preload("res://core/calibrated_race.gd")
const LegacyRace = preload("res://core/race_engine.gd")
const OperatorAccess = preload("res://core/operator_access.gd")
const PlayerIdentity = preload("res://core/player_identity.gd")
const MAX_BALANCE := 1000000000
var players: Array = []
var phase := "BETTING"
var round_number := 1
var audit: Array = []
var race_logs: Array = []
var board: Dictionary
var access = OperatorAccess.new()
var error := ""
var _race: RefCounted
var _race_seed: Variant
var _result := {}
var _locked_bets: Array = []
var _locked_virtual: Array = []
var _cash_requests := {}
var _rtp := 90
var player_profiles: Array = PlayerIdentity.defaults()
var manager_only_start := false
var start_countdown := 0
var _next_rtp := 90
var _deck_mode := "SD"
var _next_deck_mode := "SD"
var _card_history: Dictionary={}

func fund_demo() -> bool:
	if not audit.is_empty():
		return reject("Initial demonstration credits have already been assigned")
	for i in range(8):
		players[i].balance = 100
		players[i].state = "BETTING" if i == 0 else "OUT"
		record("initial_virtual_credits",i,100)
	return true

func set_out(index: int) -> bool:
	if phase=="BETTING" and valid_player(index) and virtual_config.seats[index].enabled:
		if not set_virtual_choice(index,0): return false
		if players[index].state=="PENDING PAYOUT": return true
	if not mutable_player(index):
		return reject("Player cannot sit out now")
	for pair in players[index].bets.keys():
		edit_bet(index,pair,0)
	players[index].state = "OUT"
	record("out",index)
	return true

func _init() -> void:
	for i in range(8):
		players.append({"nickname":"Player %d" % (i+1),"balance":0,"bets":{},"state":"OUT","pending":0})
	board = OddsModel.new().fresh_board(_rtp,_deck_mode,_card_history)

func reject(message: String) -> bool:
	error = message
	diagnostic_event.emit("action_rejected",{"reason":message,"round":round_number,"phase":phase})
	return false

func valid_player(index: int) -> bool:
	return index >= 0 and index < 8

func integer(value: Variant) -> bool:
	return value is int and value >= 0 and value <= MAX_BALANCE

func configure_pins(operator_pin: String, rtp_pin: String) -> bool:
	return access.setup(operator_pin,rtp_pin)

func authorize(domain: String, pin: String) -> bool:
	var accepted: bool=access.verify(domain,pin)
	diagnostic_event.emit("access_checked",{"domain":domain,"accepted":accepted})
	return accepted

func wager_total(index: int) -> int:
	var total := 0
	for amount in players[index].bets.values():
		total += amount
	return total

func available(index: int) -> int:
	if virtual_config.seats[index].enabled: return 0
	return players[index].balance - wager_total(index) if phase == "BETTING" else players[index].balance

func virtual_choice(index: int) -> int:
	var seat: Dictionary=virtual_config.seats[index]
	if not seat.enabled: return 0
	return seat.preset+1 if seat.mode==VirtualPlayers.MODES[0] else virtual_config.styles.size()+VirtualPlayers.MODES.find(seat.mode)

func set_virtual_choice(index: int, choice: int) -> bool:
	if phase!="BETTING" or not valid_player(index) or choice<0 or choice>virtual_config.styles.size()+2:
		return reject("V mode can change only on the betting screen.")
	var seat: Dictionary=virtual_config.seats[index]
	var current:=virtual_choice(index)
	if current==choice: return true
	_cash_requests.erase(index)
	if choice==0:
		var human: Dictionary=seat.human_snapshot
		players[index].state=human.state
		players[index].bets=human.bets.duplicate() if human.round==round_number else {}
		if human.round!=round_number and human.state in ["BETTING","READY"]:
			players[index].state="BETTING" if players[index].balance>0 else "OUT"
		seat.enabled=false; seat.human_snapshot={}
	else:
		if not seat.enabled:
			seat.human_snapshot={"state":players[index].state,"bets":players[index].bets.duplicate(),"round":round_number}
		seat.enabled=true; seat.paused=false
		seat.mode=VirtualPlayers.MODES[0] if choice<=virtual_config.styles.size() else VirtualPlayers.MODES[choice-virtual_config.styles.size()]
		if choice<=virtual_config.styles.size(): seat.preset=choice-1
		seat.hidden_style={}; seat.processed_round=-1
		VirtualPlayers.place_bets(self)
	record("virtual_mode_changed",index,0,{"before":current,"after":choice})
	return true

func last_display_win(index: int) -> int:
	for i in range(race_logs.size()-1,-1,-1):
		var entry: Dictionary=race_logs[i]
		if not entry.get("announced",false) or entry.get("accounting",[]).size()!=8: continue
		var simulated: bool=entry.get("virtual_seats",[false,false,false,false,false,false,false,false])[index]
		if simulated==virtual_config.seats[index].enabled: return entry.accounting[index]
	return 0

func settlement_fits(balance: int, bets: Dictionary) -> bool:
	var total := 0
	var maximum_award := 0
	for pair in bets:
		total += bets[pair]
		maximum_award = maxi(maximum_award,bets[pair] * board.payouts[pair])
	return balance - total + maximum_award <= MAX_BALANCE

func mutable_player(index: int) -> bool:
	return valid_player(index) and phase == "BETTING" and players[index].state != "PENDING PAYOUT"

func refresh_state(index: int) -> void:
	if virtual_config.seats[index].enabled:
		players[index].state="READY"
		return
	if players[index].state == "PENDING PAYOUT":
		return
	players[index].state = "OUT" if players[index].balance == 0 and wager_total(index) == 0 else "BETTING"

func record(kind: String, player: int = -1, delta: int = 0, details: Dictionary = {}) -> void:
	audit.append({"sequence":audit.size()+1,"round":round_number,"kind":kind,"player":player,"delta":delta,"balance":players[player].balance if player >= 0 else 0,"details":details.duplicate(true)})
	diagnostic_event.emit(kind,audit.back())

func edit_bet(index: int, pair: String, amount: Variant) -> bool:
	if valid_player(index) and virtual_config.seats[index].enabled: return reject("V wagers are simulated and read-only.")
	if not mutable_player(index) or not integer(amount) or amount > 20 or not board.payouts.has(pair):
		return reject("Bet is unavailable or invalid")
	var old: int = players[index].bets.get(pair,0)
	if wager_total(index) - old + amount > players[index].balance:
		return reject("Insufficient available credits")
	var candidate: Dictionary = players[index].bets.duplicate()
	candidate[pair] = amount
	if not settlement_fits(players[index].balance,candidate):
		return reject("Potential win exceeds the credit limit; reduce the balance or wager")
	if amount == old:
		return true
	if amount == 0:
		players[index].bets.erase(pair)
	else:
		players[index].bets[pair] = amount
	_cash_requests.erase(index)
	refresh_state(index)
	record("bet_edited",index,0,{"pair":pair,"before":old,"after":amount})
	return true

func rename_player(index: int, nickname: String) -> bool:
	if not mutable_player(index) or nickname.strip_edges().is_empty() or nickname.length() > 24:
		return reject("Nickname must contain 1 to 24 characters")
	if players[index].nickname == nickname.strip_edges():
		return true
	players[index].nickname = nickname.strip_edges()
	record("nickname",index,0,{"nickname":players[index].nickname})
	return true

func set_ready(index: int, ready: bool) -> bool:
	if phase=="BETTING" and valid_player(index) and virtual_config.seats[index].enabled:
		return true if ready else reject("V mode is always Ready.")
	if not mutable_player(index) or (players[index].balance == 0 and wager_total(index) == 0):
		return reject("Player is not participating")
	players[index].state = "READY" if ready else "BETTING"
	_cash_requests.erase(index)
	record("ready",index,0,{"ready":ready})
	return true

func can_start() -> bool:
	if phase != "BETTING":
		return false
	var ready := false
	for player in players:
		if player.state == "BETTING":
			return false
		ready = ready or player.state == "READY"
	return ready

var _race_controls := {}

func start_race(seed_value: Variant, controls: Dictionary = {}) -> bool:
	if not can_start():
		return reject("Every participating player must be READY")
	if not seed_value is int and not (seed_value is String and seed_value.length()==64 and seed_value.is_valid_hex_number(false)):
		return reject("A valid full-width race seed is required")
	if not _valid_board():
		return reject("Payout card is invalid; race cannot start")
	_race_seed=seed_value
	_race_controls=preload("res://core/race_control.gd").normalized(controls)
	_locked_bets.clear()
	_locked_virtual.clear()
	for i in range(8):
		_locked_bets.append(players[i].bets.duplicate())
		_locked_virtual.append(virtual_config.seats[i].enabled)
		var stake := wager_total(i)
		if _locked_virtual[i]:
			record("virtual_stake_displayed",i,0,{"bets":players[i].bets.duplicate(),"simulated_stake":stake})
			continue
		players[i].balance -= stake
		if stake > 0:
			record("stake_locked",i,-stake,{"bets":players[i].bets.duplicate()})
	phase = "RACING"
	_cash_requests.clear()
	_race = _make_race()
	record("race_started",-1,0,{"seed":seed_value,"board":board,"race_controls":_race_controls.duplicate()})
	return true

func _make_race() -> RefCounted:
	if board.get("schema")==1:
		var old_seed: int=_race_seed if _race_seed is int else str(_race_seed).substr(0,8).hex_to_int()
		return LegacyRace.new(old_seed)
	var master: String=_race_seed if _race_seed is String else ("controlled-test-seed:%d" % _race_seed).sha256_text()
	return RaceEngine.new(master,board,_race_controls)

func create_visual_race() -> RefCounted:
	assert(phase=="RACING" and _race!=null)
	return _make_race()

func _valid_board() -> bool:
	if _rtp<70 or _rtp>200: return false
	if board.get("schema")==1: return board==LegacyOdds.new().board(_rtp)
	return OddsModel.new().valid_board(board,_rtp)

func advance_race() -> Dictionary:
	if phase != "RACING":
		return {}
	_race.advance_event()
	return _race.snapshot()

func finish_race(result: Dictionary) -> bool:
	if phase != "RACING":
		return reject("No racing round")
	# Validate against this round's actual engine, never trust an externally chosen pair.
	var actual: Dictionary = _race.run()
	if result != actual:
		return reject("Result does not match the locked seeded race")
	_result = actual
	phase = "RESULTS"
	var log_entry := actual.duplicate(true)
	log_entry.merge({"round":round_number,"odds":board.duplicate(true),"bets":_locked_bets.duplicate(true),"virtual_seats":_locked_virtual.duplicate(),"replay":_race.replay_events(),"announced":false,"accounting":[]})
	race_logs.append(log_entry)
	record("race_finished",-1,0,{"first":actual.first,"second":actual.second,"pair":actual.pair,"margin":actual.margin})
	return true

func current_result() -> Dictionary:
	return _result.duplicate(true)

func announce_result() -> bool:
	if phase != "RESULTS":
		return reject("Result already settled or unavailable")
	var awards: Array = []
	for i in range(8):
		var award: int = _locked_bets[i].get(_result.pair,0) * board.payouts[_result.pair]
		if not _locked_virtual[i] and players[i].balance + award > MAX_BALANCE:
			return reject("Balance limit would be exceeded; settlement unchanged")
		awards.append(award)
	for i in range(8):
		if _locked_virtual[i]:
			record("virtual_win_displayed",i,0,{"pair":_result.pair,"simulated_award":awards[i],"stake":_locked_bets[i].get(_result.pair,0)})
		else:
			players[i].balance += awards[i]
			record("win",i,awards[i],{"pair":_result.pair,"stake":_locked_bets[i].get(_result.pair,0)})
		players[i].bets.clear()
		if players[i].balance == 0 and not _locked_virtual[i]: players[i].state = "OUT"
	phase = "SETTLED"
	race_logs.back().announced = true
	race_logs.back().accounting = awards
	record("result_announced")
	return true

func next_round() -> bool:
	if phase != "SETTLED":
		return reject("Round must be settled first")
	var history: Dictionary=_card_history.duplicate(true)
	var next: Dictionary=OddsModel.new().fresh_board(_next_rtp,_next_deck_mode,history,board)
	if next.is_empty(): return reject("Could not prepare the next card; current result is preserved")
	phase = "BETTING"
	round_number += 1
	_locked_bets.clear()
	_locked_virtual.clear()
	_result.clear()
	_race = null
	_race_seed = null
	_rtp = _next_rtp
	_deck_mode = _next_deck_mode
	board = next
	_card_history=history
	for i in range(8):
		if players[i].state != "OUT":
			refresh_state(i)
	record("round_opened")
	VirtualPlayers.place_bets(self)
	return true

func adjust_balance(index: int, amount: Variant, operation: String, pin: String) -> bool:
	if valid_player(index) and virtual_config.seats[index].enabled: return reject("Exit V mode before changing human credits.")
	if not mutable_player(index) or not integer(amount) or operation not in ["add","remove","set"] or not authorize("operator",pin):
		return reject("Operator action unavailable or unauthorized")
	var before: int = players[index].balance
	var after: int = amount if operation == "set" else before + (amount if operation == "add" else -amount)
	if after < wager_total(index) or after < 0 or after > MAX_BALANCE:
		return reject("Adjustment conflicts with reserved wagers or credit limits")
	if not settlement_fits(after,players[index].bets):
		return reject("Adjustment would leave insufficient capacity for a winning payout")
	players[index].balance = after
	_cash_requests.erase(index)
	refresh_state(index)
	record("operator_"+operation,index,after-before,{"amount":amount})
	return true

func request_cash_out(index: int) -> bool:
	if valid_player(index) and virtual_config.seats[index].enabled: return reject("Exit V mode before cashing out human credits.")
	if not mutable_player(index) or players[index].balance == 0:
		return reject("Cash-out unavailable")
	_cash_requests[index] = players[index].balance
	record("cash_out_requested",index)
	return true

func confirm_cash_out(index: int) -> bool:
	if not mutable_player(index) or not _cash_requests.has(index):
		return reject("A fresh cash-out request is required")
	players[index].bets.clear()
	players[index].pending = players[index].balance
	players[index].state = "PENDING PAYOUT"
	_cash_requests.erase(index)
	record("cash_out_confirmed",index,0,{"amount":players[index].pending})
	return true

func resolve_cash_out(index: int, settle: bool, pin: String) -> bool:
	if phase != "BETTING" or not valid_player(index) or players[index].state != "PENDING PAYOUT" or not authorize("operator",pin):
		return reject("Pending payout cannot be resolved now")
	var amount: int = players[index].pending if settle else 0
	players[index].balance -= amount
	players[index].pending = 0
	players[index].state = "BETTING"
	refresh_state(index)
	record("cash_out_settled" if settle else "cash_out_cancelled",index,-amount)
	return true

func set_rtp(percent: int, pin: String, mode: String="SD") -> bool:
	if phase!="BETTING" or percent < 70 or percent > 200 or not mode in ["SD","Variable"] or not authorize("rtp",pin):
		return reject("RTP configuration unavailable")
	_next_rtp = percent
	_next_deck_mode = mode
	record("rtp_queued",-1,0,{"requested_percent":percent,"calibrated":false})
	return true

func validate_state() -> String:
	if not VirtualPlayers.valid(virtual_config): return "Invalid virtual player settings"
	if not _deck_mode in ["SD","Variable"] or not _next_deck_mode in ["SD","Variable"] or not OddsModel.Deck.new().valid_history(_card_history):
		return "Invalid saved card rotation"
	if not OddsModel.Deck.new().matches_history(board,_card_history,_deck_mode):
		return "Saved card rotation does not match the quoted card"
	var identity_error := PlayerIdentity.validate(player_profiles)
	if not identity_error.is_empty():
		return identity_error
	if start_countdown < 0 or start_countdown > 10 or (manager_only_start and not access.credentials.has("start")):
		return "Invalid start controls"
	if players.size() != 8 or phase not in ["BETTING","RACING","RESULTS","SETTLED"]:
		return "Invalid session shape"
	if _rtp < 70 or _rtp > 200 or _next_rtp < 70 or _next_rtp > 200 or not _valid_board() or round_number < 1:
		return "Invalid stored round or payout board"
	var balances := [0,0,0,0,0,0,0,0]
	for i in range(audit.size()):
		if not audit[i] is Dictionary:
			return "Invalid audit shape"
		var entry: Dictionary = audit[i]
		if entry.get("sequence",0) != i+1 or not entry.get("delta") is int or not entry.get("player") is int:
			return "Invalid audit entry"
		var index: int = entry.player
		if index < -1 or index >= 8:
			return "Invalid audit player"
		if index >= 0:
			balances[index] += entry.delta
			if balances[index] != entry.get("balance",-1):
				return "Audit balance mismatch"
	for i in range(8):
		if not players[i] is Dictionary:
			return "Invalid account shape"
		var player: Dictionary = players[i]
		if not integer(player.get("balance")) or player.balance != balances[i] or player.get("state") not in ["BETTING","READY","OUT","PENDING PAYOUT"]:
			return "Invalid player balance or state"
		if not player.get("bets") is Dictionary or not integer(player.get("pending")) or not player.get("nickname") is String:
			return "Invalid account fields"
		var simulated: bool=virtual_config.seats[i].enabled
		var human: Variant=virtual_config.seats[i].get("human_snapshot")
		if not human is Dictionary: return "Missing protected human state"
		var account_state: String=player.state
		if simulated:
			if player.state!="READY" or human.get("state") not in ["BETTING","READY","OUT","PENDING PAYOUT"] or not human.get("bets") is Dictionary or not human.get("round") is int or human.round<1 or human.round>round_number:
				return "Invalid protected human state"
			account_state=human.state
			var reserved:=0
			for pair in human.bets:
				if not board.payouts.has(pair) or not integer(human.bets[pair]) or human.bets[pair]>20: return "Invalid protected human wager"
				reserved+=human.bets[pair]
			if reserved>player.balance or (account_state=="PENDING PAYOUT" and not human.bets.is_empty()): return "Invalid protected human reservations"
			if human.round==round_number and not settlement_fits(player.balance,human.bets): return "Protected human wagers could overflow settlement"
		elif not human.is_empty(): return "Unexpected protected human state"
		for pair in player.bets:
			if not board.payouts.has(pair) or not integer(player.bets[pair]) or player.bets[pair] > 20:
				return "Invalid stored wager"
		if not simulated and phase == "BETTING" and wager_total(i) > player.balance:
			return "Stored bets exceed available balance"
		if not simulated and phase == "BETTING" and not settlement_fits(player.balance,player.bets):
			return "Stored wagers could overflow settlement"
		if account_state == "PENDING PAYOUT" and (player.pending != player.balance or (not simulated and not player.bets.is_empty())):
			return "Invalid pending payout"
		if account_state != "PENDING PAYOUT" and player.pending != 0:
			return "Unexpected pending balance"
	if phase in ["RACING","RESULTS"]:
		if _locked_bets.size() != 8 or _locked_virtual.size()!=8:
			return "Missing locked bets"
		for i in range(8):
			if not _locked_virtual[i] is bool or _locked_virtual[i]!=virtual_config.seats[i].enabled: return "Locked V mode mismatch"
			if _locked_bets[i] != players[i].bets:
				return "Locked bets mismatch"
			var debits: Array = []
			for entry in audit:
				if entry.get("round") == round_number and entry.get("player") == i and entry.get("kind") == "stake_locked":
					debits.append(entry)
			var stake := wager_total(i)
			if _locked_virtual[i]:
				if not debits.is_empty(): return "Simulated wager has a credit debit"
				continue
			if stake == 0 and not debits.is_empty():
				return "Unexpected stake debit"
			if stake > 0:
				if debits.size() != 1 or debits[0].delta != -stake or not debits[0].get("details") is Dictionary or debits[0].details.get("bets") != _locked_bets[i]:
					return "Locked wagers do not match audited debits"
			if not settlement_fits(players[i].balance+stake,players[i].bets):
				return "Locked wager exceeds payout capacity"
	if not access.valid_credentials(access.credentials):
		return "Invalid credentials"
	return ""

func export_data() -> Dictionary:
	return {"schema":7,"game_id":game_id,"virtual_config":virtual_config.duplicate(true),"deck_mode":_deck_mode,"next_deck_mode":_next_deck_mode,"card_history":_card_history.duplicate(true),"players":players.duplicate(true),"phase":phase,"round":round_number,"audit":audit.duplicate(true),"race_logs":race_logs.duplicate(true),"board":board.duplicate(true),"credentials":access.credentials.duplicate(true),"locked_virtual":_locked_virtual.duplicate(),"locked_bets":_locked_bets.duplicate(true),"result":_result.duplicate(true),"rtp":_rtp,"player_profiles":player_profiles.duplicate(true),"manager_only_start":manager_only_start,"start_countdown":start_countdown,"next_rtp":_next_rtp}

func restore(data: Dictionary) -> bool:
	var legacy_virtual: Array=[]
	if data.get("schema") not in [1,2,3,4,5,6,7] or not data.get("players") is Array or not data.get("audit") is Array or not data.get("board") is Dictionary:
		return reject("Unsupported or malformed saved session")
	for key in ["race_logs","locked_bets"]:
		if not data.get(key) is Array:
			return reject("Missing saved arrays")
	for key in ["credentials","result"]:
		if not data.get(key) is Dictionary:
			return reject("Missing saved objects")
	for entry in data.race_logs:
		if not entry is Dictionary: return reject("Invalid saved race log")
		if entry.has("virtual_seats"):
			if not entry.virtual_seats is Array or entry.virtual_seats.size()!=8: return reject("Invalid historical V modes")
			for simulated in entry.virtual_seats:
				if not simulated is bool: return reject("Invalid historical V mode")
	if not data.get("phase") is String or not data.get("round") is int or not data.get("rtp") is int:
		return reject("Invalid session metadata")
	if data.schema>=6:
		if not data.get("game_id") is String or data.game_id.length()!=32 or not data.game_id.is_valid_hex_number(false): return reject("Invalid saved game identity")
		game_id=data.game_id
		if not VirtualPlayers.valid(data.get("virtual_config")): return reject("Invalid saved virtual players")
		virtual_config=data.virtual_config.duplicate(true)
		if data.schema<7:
			for i in range(8):
				legacy_virtual.append(virtual_choice(i) if not virtual_config.seats[i].paused else 0)
				virtual_config.seats[i].enabled=false
				virtual_config.seats[i].human_snapshot={}
				virtual_config.seats[i].rebuy=false
				virtual_config.seats[i].paused=false
	else:
		game_id=(JSON.stringify(data.credentials)+JSON.stringify(data.audit.slice(0,8))).sha256_text().substr(0,32)
	players = data.players.duplicate(true)
	audit = data.audit.duplicate(true)
	board = data.board.duplicate(true)
	phase = data.get("phase","")
	round_number = data.get("round",0)
	race_logs = data.get("race_logs",[]).duplicate(true)
	access.credentials = data.get("credentials",{}).duplicate(true)
	_locked_bets = data.get("locked_bets",[]).duplicate(true)
	if data.schema>=7:
		if not data.get("locked_virtual") is Array: return reject("Missing locked V modes")
		_locked_virtual=data.locked_virtual.duplicate()
	else: _locked_virtual=[false,false,false,false,false,false,false,false] if phase in ["RACING","RESULTS"] else []
	_result = data.get("result",{}).duplicate(true)
	_rtp = data.get("rtp",90)
	if data.schema >= 2:
		if not data.get("player_profiles") is Array or not data.get("manager_only_start") is bool or not data.get("start_countdown") is int or not data.get("next_rtp") is int:
			return reject("Invalid saved player settings")
		player_profiles = data.player_profiles.duplicate(true)
		manager_only_start = data.manager_only_start
		start_countdown = data.start_countdown
		_next_rtp = data.next_rtp
	else:
		_next_rtp = _rtp
	if data.schema>=5:
		if not data.get("deck_mode") is String or not data.get("next_deck_mode") is String or not data.get("card_history") is Dictionary:
			return reject("Missing saved card rotation")
		_deck_mode=data.deck_mode
		_next_deck_mode=data.next_deck_mode
		_card_history=data.card_history.duplicate(true)
	else:
		_deck_mode="SD"; _next_deck_mode="SD"; _card_history={}
	var invalid := validate_state()
	if not invalid.is_empty():
		return reject(invalid)
	if phase in ["RACING","RESULTS"]:
		if _locked_bets.size() != 8:
			return reject("Missing locked wagers")
		for i in range(8):
			var refund := 0 if _locked_virtual[i] else wager_total(i)
			players[i].balance += refund
			players[i].bets.clear()
			record("interrupted_round_refund",i,refund)
		phase = "SETTLED"
		record("interrupted_round_voided")
	if phase == "SETTLED":
		next_round()
	var recovered_error := validate_state()
	if not recovered_error.is_empty():
		return reject(recovered_error)
	if not legacy_virtual.is_empty():
		for i in range(8):
			if legacy_virtual[i]>0: set_virtual_choice(i,legacy_virtual[i])
	if data.schema < 3 and phase == "BETTING":
		migrate_unused_demo_seats()
	if phase=="BETTING" and board.get("schema")==1:
		var any_wagers := false
		for i in range(8): any_wagers=any_wagers or wager_total(i)>0
		if not any_wagers:
			board=OddsModel.new().fresh_board(_rtp,_deck_mode,_card_history,board)
			record("payback_model_upgraded")
	return true

func migrate_unused_demo_seats() -> void:
	var defaults := PlayerIdentity.defaults()
	for i in range(1,8):
		if players[i].state != "BETTING" or not players[i].bets.is_empty() or players[i].nickname != "Player %d" % (i+1) or player_profiles[i] != defaults[i] or access.credentials.has("player_%d" % i):
			continue
		var demo := false
		var used := false
		for entry in audit:
			if entry.player == i:
				demo = demo or entry.kind == "initial_virtual_credits"
				if entry.kind not in ["initial_virtual_credits","ready","win","interrupted_round_refund"] or entry.delta != 0 and entry.kind != "initial_virtual_credits":
					used = true
		if demo and not used:
			players[i].state = "OUT"
			record("unused_demo_seat_out",i)
