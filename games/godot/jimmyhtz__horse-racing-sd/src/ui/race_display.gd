extends VBoxContainer
const RaceAudio = preload("res://ui/race_audio.gd")
const MiniBets = preload("res://ui/mini_bets.gd")
const Banner = preload("res://ui/player_banner.gd")
const Track = preload("res://ui/track_view.gd")
const Sigma = preload("res://ui/sigma_style.gd")
const LED = preload("res://ui/led_display.gd")
const Identity = preload("res://core/player_identity.gd")
const Odds = preload("res://core/odds_model.gd")
var audio: Node
var minis: Array = []
var track: Control
var game: RefCounted
var player_summaries: GridContainer
var payout_panels := {}
var winning_pair := ""
var flash_clock := 0.0
var prefs := {}
var race_bets: Array = []
var sitting_out: Array = []
var _flash_state: Array = []
var payout_started := false
var payout_complete := false
var payout_elapsed := 0.0
var payout_seconds := 3.0
var awards: Array = []
var counters := {}
var cards: Array = []
var payout_note: Label
var result_audio: Node
var payout_kind := "none"

func configure(session: RefCounted, preferences: Dictionary) -> void:
	audio = RaceAudio.new()
	audio.preferences = preferences
	add_child(audio)
	game = session
	prefs = preferences
	if game != null:
		for player in game.players:
			race_bets.append(player.bets.duplicate())
			sitting_out.append(player.state == "OUT")
	size_flags_vertical = SIZE_EXPAND_FILL
	size_flags_horizontal = SIZE_EXPAND_FILL
	add_theme_constant_override("separation",6)
	var board: Dictionary = Odds.new().board() if game == null else game.board
	var strip := HBoxContainer.new()
	strip.name = "RacePayoutStrip"
	strip.add_theme_constant_override("separation",4)
	add_child(strip)
	var ordered_pairs: Array = board.payouts.keys()
	ordered_pairs.sort()
	for pair in ordered_pairs:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel",Sigma.plate(Sigma.GOLD,Color("6f381c"),3))
		panel.size_flags_horizontal = SIZE_EXPAND_FILL
		strip.add_child(panel)
		payout_panels[pair] = panel
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",6)
		panel.add_child(row)
		var caption := Label.new()
		caption.text = pair
		caption.add_theme_font_size_override("font_size",13)
		caption.add_theme_color_override("font_color",Sigma.INK)
		row.add_child(caption)
		var display := LED.new()
		display.value = board.payouts[pair]
		display.digits = 3 if display.value >= 100 else 2
		display.custom_minimum_size = Vector2(40,25)
		display.size_flags_horizontal = SIZE_EXPAND_FILL
		display.ink = Color("ff4150") if display.value >= 50 else (Color("ffe037") if display.value >= 10 else Color("63f17b"))
		row.add_child(display)
	payout_note = Label.new()
	payout_note.name = "PayoutNote"
	payout_note.custom_minimum_size.y = 32
	payout_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	payout_note.add_theme_font_size_override("font_size",21)
	payout_note.add_theme_color_override("font_color",Color("fff2bd"))
	var scene := HBoxContainer.new()
	scene.name = "RaceScene"
	scene.size_flags_vertical = SIZE_EXPAND_FILL
	scene.add_theme_constant_override("separation",8)
	add_child(scene)
	track = Track.new()
	track.preferences = preferences
	scene.add_child(track)
	track.add_child(payout_note)
	payout_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	payout_note.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	payout_note.offset_top = -36
	payout_note.offset_bottom = 0
	payout_note.add_theme_stylebox_override("normal",Sigma.plate(Color("35151d"),Color("35151d"),2))
	payout_note.hide()
	if game != null:
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size.x = 380
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scene.add_child(scroll)
		player_summaries = GridContainer.new()
		player_summaries.columns = 2
		player_summaries.name = "RacePlayerSummaries"
		player_summaries.size_flags_horizontal = SIZE_EXPAND_FILL
		scroll.add_child(player_summaries)
		refresh_players()

func refresh_players() -> void:
	if game == null: return
	_flash_state.clear()
	minis.clear()
	cards.clear()
	counters.clear()
	for child in player_summaries.get_children():
		player_summaries.remove_child(child)
		child.queue_free()
	for index in range(8):
		var player: Dictionary = game.players[index]
		var palette: Array = Identity.PALETTES[game.player_profiles[index].color]
		var card := PanelContainer.new()
		card.size_flags_horizontal = SIZE_EXPAND_FILL
		var plate := Sigma.plate(Sigma.SILVER,Color(palette[1]),4)
		plate.set_content_margin_all(3)
		plate.set_border_width_all(3)
		card.add_theme_stylebox_override("panel",plate)
		player_summaries.add_child(card)
		cards.append(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation",2)
		card.add_child(box)
		var banner := Banner.new()
		banner.configure(game.player_profiles[index],"%d  %s%s" % [index+1,player.nickname," [V]" if game.virtual_config.seats[index].enabled else (" OUT" if sitting_out[index] else "")],28,13)
		box.add_child(banner)
		var count := LED.new()
		count.name = "AwardCount%d" % index
		count.digits = maxi(4,str(awards[index]).length()) if payout_started else 4
		count.compact = true
		count.custom_minimum_size = Vector2(100,24)
		count.ink = Color("fff573") if payout_started and awards[index] > 0 else Color("53474a")
		count.self_modulate.a = 1.0 if payout_started else 0.0
		box.add_child(count)
		counters[index] = count
		var mini := MiniBets.new()
		mini.tight = true
		mini.name = "RaceMini%d" % index
		var win := 0
		if game.phase == "SETTLED" and not game.race_logs.is_empty() and game.race_logs.back().announced:
			win = game.race_logs.back().accounting[index]
		mini.configure(race_bets[index],game.available(index),win,2,true,true,prefs.get("credit_label","Credits"),prefs.get("show_totals",true))
		if game.virtual_config.seats[index].enabled: mini.show_simulation(win,race_bets[index])
		elif player.state == "PENDING PAYOUT": mini.show_pending(player.pending)
		box.add_child(mini)
		minis.append(mini)
		if payout_started: update_meter(index,0)
	if game.phase == "SETTLED" and not game.race_logs.is_empty() and game.race_logs.back().announced:
		set_winning_pair(game.race_logs.back().pair)

func set_winning_pair(pair: String) -> void:
	if winning_pair != pair:
		winning_pair = pair
		flash_clock = 0.0
	update_flash()

func _process(delta: float) -> void:
	audio.update_playback(track.moving,track.close_up)
	flash_clock += delta
	update_flash()

func update_flash() -> void:
	var steady: bool = prefs.get("reduce_flashing",false) or prefs.get("reduced_motion",false)
	var lit: bool = winning_pair.is_empty() or steady or fmod(flash_clock,1.2)<0.6
	var state := [winning_pair,lit]
	if state == _flash_state: return
	_flash_state = state
	for pair in payout_panels:
		var style: StyleBoxFlat = payout_panels[pair].get_theme_stylebox("panel")
		payout_panels[pair].get_child(0).modulate = Color(0.18,0.18,0.18) if pair == winning_pair and not lit else Color.WHITE
		style.bg_color = Color("fff58a") if pair == winning_pair and lit else Sigma.GOLD
		style.border_color = Color("fffbc8") if pair == winning_pair else Color("6f381c")
	for mini in minis:
		mini.highlight_pair(winning_pair,lit)

func begin_payouts() -> void:
	if payout_started or game == null or game.phase != "SETTLED": return
	payout_started = true
	awards = game.race_logs.back().accounting.duplicate()
	var largest: int = awards.max()
	payout_kind = "none" if largest == 0 else ("jackpot" if game.board.payouts[winning_pair] >= 50 or largest >= 500 else "small")
	payout_seconds = 6.0 if payout_kind == "jackpot" else (0.0 if payout_kind == "none" else 3.0)
	payout_note.show()
	payout_note.text = "No winners this race" if largest == 0 else ("JACKPOT! Counting your winnings" if payout_kind == "jackpot" else "Counting your winnings")
	refresh_players()
	if prefs.get("reduced_motion",false): payout_elapsed = payout_seconds
	result_audio = preload("res://ui/result_audio.gd").new()
	add_child(result_audio)
	result_audio.play_result(payout_kind,prefs)

func update_meter(index: int, shown: int) -> void:
	if game.virtual_config.seats[index].enabled:
		minis[index].show_simulation(shown,race_bets[index]); return
	var credits: int = game.players[index].balance - int(awards[index]) + shown
	minis[index].get_child(0).text = "WIN %d   CREDITS %d" % [shown,credits]

func advance_payouts(delta: float) -> void:
	if not payout_started or payout_complete: return
	payout_elapsed += maxf(delta,0.0)
	var fraction := 1.0 if payout_seconds == 0 else clampf(payout_elapsed/payout_seconds,0.0,1.0)
	# Smooth count-up is presentation only; balances were settled atomically once.
	for index in counters:
		var shown := roundi(int(awards[index])*(1.0-pow(1.0-fraction,2.0)))
		counters[index].value = shown
		counters[index].queue_redraw()
		update_meter(index,shown)
		if awards[index] > 0:
			var plate: StyleBoxFlat = cards[index].get_theme_stylebox("panel")
			plate.border_color = Color("fff52e") if prefs.get("reduce_flashing",false) or prefs.get("reduced_motion",false) or fmod(payout_elapsed,0.8)<0.4 else Color("f1a634")
			plate.set_border_width_all(4)
	if payout_elapsed >= payout_seconds+2.5:
		payout_complete = true
		payout_note.text = "No winners this race. Return to betting when ready." if payout_kind == "none" else "Results complete. Return to betting when ready."

func update_preferences(values: Dictionary) -> void:
	prefs=values
	audio.preferences=values
	if result_audio != null:
		result_audio.player.volume_linear=values.master_volume*values.win_volume
	if values.reduced_motion and payout_started and not payout_complete:
		payout_elapsed=maxf(payout_elapsed,payout_seconds)
