extends RefCounted
static func from_current(current: RefCounted, preferences: RefCounted) -> Dictionary:
	var fresh=preload("res://core/game_session.gd").new()
	fresh._rtp=current._next_rtp; fresh._next_rtp=current._next_rtp
	fresh._deck_mode=current._next_deck_mode; fresh._next_deck_mode=current._next_deck_mode
	fresh._card_history={}
	fresh.board=preload("res://core/calibrated_odds.gd").new().fresh_board(fresh._rtp,fresh._deck_mode,fresh._card_history)
	if fresh.board.is_empty(): return {"ok":false,"error":"Could not prepare the new game. The current game is unchanged."}
	fresh.fund_demo()
	fresh.access.credentials=current.access.credentials.duplicate(true)
	fresh.player_profiles=current.player_profiles.duplicate(true)
	fresh.manager_only_start=current.manager_only_start
	fresh.start_countdown=current.start_countdown
	fresh.virtual_config.styles=current.virtual_config.styles.duplicate(true)
	for i in range(8):
		fresh.players[i].nickname=current.players[i].nickname
		var previous_state: String=current.players[i].state
		if current.virtual_choice(i)>0: previous_state=current.virtual_config.seats[i].human_snapshot.state
		fresh.players[i].state="BETTING" if previous_state in ["BETTING","READY"] else "OUT"
		if current.virtual_choice(i)>0: fresh.set_virtual_choice(i,current.virtual_choice(i))
	var settings=preload("res://core/game_settings.gd").new()
	if not settings.restore(preferences.export_data()): return {"ok":false,"error":"Current settings could not be copied."}
	var invalid: String=fresh.validate_state()
	if not invalid.is_empty(): return {"ok":false,"error":invalid}
	return {"ok":true,"session":fresh,"settings":settings}
