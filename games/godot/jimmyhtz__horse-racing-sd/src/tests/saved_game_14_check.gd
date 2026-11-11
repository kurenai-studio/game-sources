extends SceneTree
func _initialize() -> void:
	var path:=OS.get_environment("SD_CHECK_SAVE")
	var text:=FileAccess.get_file_as_string(path)
	var raw: Dictionary=bytes_to_var(Marshalls.base64_to_raw(JSON.parse_string(text).payload))
	var loaded=load("res://core/session_store.gd").new().load_session(path)
	var good: bool=loaded.ok
	if good:
		var actual: Dictionary=loaded.session.export_data()
		good=actual.credentials==raw.session.credentials and actual.player_profiles==raw.session.player_profiles and loaded.settings.valid_values(loaded.settings.values)
		var refunded:=0
		for i in range(8):
			var expected: int=raw.session.players[i].balance
			if raw.session.phase in ["RACING","RESULTS"]:
				for wager in raw.session.players[i].bets.values():
					expected+=int(wager); refunded+=int(wager)
			good=good and actual.players[i].balance==expected and actual.players[i].pending==raw.session.players[i].pending and actual.players[i].nickname==raw.session.players[i].nickname
		if raw.session.phase=="BETTING": good=good and actual.players==raw.session.players and actual.board==raw.session.board
		else: good=good and actual.phase=="BETTING" and actual.round==raw.session.round+1
		print("SAVED GAME: balances/PINs/profiles recovered correctly=",good," previous phase=",raw.session.phase," interrupted stakes refunded=",refunded," session schema=",actual.schema," settings schema=",loaded.settings.export_data().schema)
	else: printerr(loaded.error)
	quit(0 if good else 1)
