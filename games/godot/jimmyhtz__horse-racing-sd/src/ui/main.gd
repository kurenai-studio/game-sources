extends Control
const GameSession = preload("res://core/game_session.gd")
const GameSettings = preload("res://core/game_settings.gd")
const SessionStore = preload("res://core/session_store.gd")
const RaceEntropy = preload("res://core/race_entropy.gd")
const TrackView = preload("res://ui/track_view.gd")
const SettingsPanel = preload("res://ui/settings_panel.gd")
const PlayerFlow = preload("res://core/player_flow.gd")
const BettingPanel = preload("res://ui/betting_panel.gd")
const Sigma = preload("res://ui/sigma_style.gd")
const MetalPanel = preload("res://ui/machine_panel.gd")
const RaceDisplay = preload("res://ui/race_display.gd")
var instance_guard = preload("res://ui/instance_guard.gd").new()
var frame_budget = preload("res://ui/frame_budget.gd").new()
var race_entropy = RaceEntropy.new()
var announcers: Node
var subtitles: Label
var preview_note: Label
var outer_margin: MarginContainer
var marquee: PanelContainer
var betting_payouts: HBoxContainer
var flow: RefCounted
var countdown_elapsed := 0.0
var session := GameSession.new()
var preferences := GameSettings.new()
var storage := SessionStore.new()
var game_library := preload("res://core/game_library.gd").new()
var save_path := "user://session.json"
var blocked := false
var selected_pair := "1-2"
var root_box: VBoxContainer
var body: VBoxContainer
var message: Label
var header: Label
var version_label: Label
var settings_panel: AcceptDialog
var help_panel: AcceptDialog
var track: Control
var payout_screen: PanelContainer
var race_screen: VBoxContainer
var start_signal: Node
var preparation_elapsed := 0.0
var result_elapsed := 0.0
var snapshots: Array = []
var visual_race: RefCounted
var visual_result := {}
var playback := {}
var race_elapsed := 0.0
var post_elapsed := 0.0
var replay_elapsed := 0.0
var replay_start := -1.0
var display_phase := "BETTING"
var inactivity := 0.0
var reminded := false
var pair_buttons := {}
var clock_label: Label
var body_scroll: ScrollContainer
var footer_row: HBoxContainer
var applied_window_mode := ""
var applied_resolution := ""
var applied_window_resolution := ""
var before_fullscreen := "Windowed"
var reload_from := {}
var diagnostics: Node
var _logged_settings := {}
var _diagnostic_warning := false

func attach_diagnostics() -> void:
	diagnostics.begin(session.game_id)
	session.diagnostic_event.connect(diagnostics.record)
	diagnostics.record("session_opened",{"session":session.export_data(),"settings":preferences.export_data()})
	diagnostics.record("settings_snapshot",settings_snapshot("session_opened"))

func settings_snapshot(reason: String) -> Dictionary:
	var clean=preload("res://core/diagnostics.gd")
	var identities: Array=[]
	for i in range(session.players.size()):
		var identity: Dictionary=clean.clean(session.player_profiles[i])
		identity["nickname"]=session.players[i].nickname
		identity["access_code_enabled"]=session.access.credentials.has("player_%d" % i)
		identity["custom_image_present"]=not str(session.player_profiles[i].get("image","")).is_empty()
		identity["virtual_selection"]=session.virtual_choice(i)
		identities.append(identity)
	var snapshot := {"reason":reason,"round":session.round_number,"settings_schema":preferences.export_data().schema,
		"preferences":preferences.values.duplicate(true),"profiles":preferences.profiles.duplicate(true),
		"operator":{"manager_only_start":session.manager_only_start,"start_countdown":session.start_countdown,
			"payback":session._rtp,"next_payback":session._next_rtp,"card_mode":session._deck_mode,"next_card_mode":session._next_deck_mode},
		"players":identities,"virtual_styles":clean.clean(session.virtual_config),
		"access_codes_enabled":{"settings":session.access.credentials.has("operator"),"payout":session.access.credentials.has("rtp"),"start":session.access.credentials.has("start")},
		"locked_movement":session._race_controls.duplicate(),"automatic_speech":{"maximum_rate":1.6,"manual_speed":false}}
	var configuration:=snapshot.duplicate()
	configuration.erase("reason"); configuration.erase("round")
	snapshot["fingerprint"]=JSON.stringify(configuration).sha256_text()
	return snapshot

func watch_control(node: Node) -> void:
	if not is_instance_valid(node) or not is_ancestor_of(node) or diagnostics==null: return
	if node is BaseButton and not node.has_meta("diagnostic_hook"):
		node.set_meta("diagnostic_hook",true)
		node.pressed.connect(func():
			if is_instance_valid(diagnostics) and is_instance_valid(node): diagnostics.record("button_pressed",{"control":str(node.name),"label":node.text,"screen":display_phase,"active_player":flow.active_player}))
	if node is Range:
		node.value_changed.connect(func(value): diagnostics.record("control_value",{"control":str(node.name),"value":value}))
	if node is OptionButton:
		node.item_selected.connect(func(index): diagnostics.record("option_selected",{"control":str(node.name),"index":index}))

func game_file_action(operation: String) -> void:
	if session.phase in ["RACING","RESULTS"]: return
	if operation=="New Game":
		settings_panel.confirm_action("Start a new game using the current settings? The current game will be saved first. Player names, images, PINs, active seats and virtual styles are kept. Each player starts with 100 credits; wagers, results and card rotation start fresh.",start_new_game)
		return
	if operation=="Load Game":
		var library_panel:=preload("res://ui/saved_games.gd").new()
		settings_panel.add_child(library_panel); library_panel.configure(self); library_panel.popup_centered()
		return
	if operation=="Save Game":
		var dialog:=ConfirmationDialog.new(); dialog.name="SaveGameName"; dialog.title="Save game"
		dialog.get_ok_button().text="Save Game"
		var box:=VBoxContainer.new(); box.custom_minimum_size=Vector2(520,100); dialog.add_child(box)
		var explanation:=Label.new(); explanation.custom_minimum_size.x=520
		explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		explanation.text="Save this game with its current players, credits, wagers and settings."
		box.add_child(explanation)
		box.add_child(button("Help",func(): show_help("Saved games",dialog)))
		var name_box:=LineEdit.new(); name_box.name="GameName"; name_box.max_length=48
		name_box.text=game_library.title_for(session.game_id); name_box.custom_minimum_size=Vector2(520,38)
		box.add_child(name_box); settings_panel.add_child(dialog)
		dialog.confirmed.connect(func(): save_named_game(name_box.text))
		dialog.canceled.connect(dialog.queue_free); dialog.popup_centered(); name_box.select_all(); name_box.grab_focus()
		return
	var picker := preload("res://ui/file_picker.gd").make()
	picker.access=FileDialog.ACCESS_FILESYSTEM
	picker.file_mode=FileDialog.FILE_MODE_OPEN_FILE if operation=="Import Game" else FileDialog.FILE_MODE_SAVE_FILE
	picker.filters=PackedStringArray(["*.zip ; Diagnostic log"] if operation=="Export Log" else ["*.sdgame ; Saved game"])
	picker.current_file="race-log.zip" if operation=="Export Log" else "horse-racing.sdgame"
	settings_panel.add_child(picker)
	picker.file_selected.connect(func(path):
		picker.queue_free()
		if operation=="Import Game":
			settings_panel.confirm_action("Save the current game and import this file as a separate game? The imported settings and progress will be restored. Existing games and named profiles remain available.",func(): load_named_game(path,true))
		elif operation=="Export Game":
			settings_panel.return_to_game()
			if flow.settings_open: return
			diagnostics.record("game_save",{"round":session.round_number})
			if storage.save(session,preferences,path): notice("Game saved, including players, credits, wagers and card rotation.")
			else: notice(storage.error)
		else:
			diagnostics.record("log_export",{"round":session.round_number})
			if diagnostics.export_bundle(path,{"session":session.export_data(),"settings":preferences.export_data()}): settings_panel.show_message("Cumulative diagnostic log exported. You can send that ZIP for review.")
			else: settings_panel.show_message(diagnostics.error))
	picker.canceled.connect(picker.queue_free)
	picker.popup_centered_ratio(0.75)

func commit_settings_for_game_action() -> bool:
	if flow.settings_open:
		settings_panel.return_to_game()
		if flow.settings_open: return false
	return not blocked

func save_named_game(title_text: String) -> bool:
	if not game_library.valid_title(title_text):
		settings_panel.show_message("Use a game name of 1 to 48 characters."); return false
	if not commit_settings_for_game_action(): return false
	if not game_library.save_game(session,preferences,title_text): notice(game_library.error); return false
	diagnostics.record("game_save",{"round":session.round_number,"managed":true})
	notice("Game saved. Open Load Game in Settings to restore it.")
	return true

func start_new_game() -> bool:
	if session.phase in ["RACING","RESULTS"] or not commit_settings_for_game_action(): return false
	var fresh: Dictionary=preload("res://core/new_game.gd").from_current(session,preferences)
	if not fresh.ok: notice(fresh.error); return false
	if not game_library.save_game(session,preferences): notice(game_library.error); return false
	return activate_saved_game(fresh)

func load_named_game(path: String, import_copy: bool=false) -> bool:
	if session.phase in ["RACING","RESULTS"]: return false
	var loaded := storage.load_session(path,false)
	if not loaded.ok: notice(loaded.error); return false
	if import_copy:
		loaded.session.game_id=Crypto.new().generate_random_bytes(16).hex_encode()
	elif loaded.session.game_id==session.game_id:
		notice("This game is already open. Use Import game file to restore an older file as a separate copy."); return false
	if not commit_settings_for_game_action(): return false
	if not game_library.save_game(session,preferences):
		notice("Current game could not be saved. Load cancelled. "+game_library.error); return false
	game_library.keep_profile_library(loaded.settings,preferences)
	return activate_saved_game(loaded)

func activate_saved_game(loaded: Dictionary) -> bool:
	# Commit the destination before changing any live references.
	if not storage.save(loaded.session,loaded.settings,save_path): notice(storage.error); return false
	diagnostics.record("game_switch",{"destination_game":loaded.session.game_id})
	diagnostics.flush()
	if announcers!=null: announcers.stop()
	if is_instance_valid(settings_panel): settings_panel.hide(); settings_panel.queue_free()
	session=loaded.session
	preferences=loaded.settings
	flow=PlayerFlow.new(session,preferences)
	attach_diagnostics()
	apply_settings()
	show_betting()
	return true

func _ready() -> void:
	if not instance_guard.allow_launch(get_tree()):
		set_process(false)
		return
	add_child(frame_budget)
	get_window().title = "Horse racing | SD mode"
	RenderingServer.set_default_clear_color(Color("111b29"))
	theme = Sigma.theme()
	if FileAccess.file_exists(save_path):
		var saved := storage.load_session(save_path)
		if saved.ok:
			session = saved.session
			preferences = saved.settings
		else:
			blocked = true
			call_deferred("notice",saved.error)
	elif FileAccess.file_exists(save_path+".bak") or FileAccess.file_exists(save_path+".tmp"):
		blocked = true
		call_deferred("notice","An interrupted save needs recovery. Existing files were preserved. Play is blocked to protect balances.")
	if not blocked and not FileAccess.file_exists(save_path):
		session.fund_demo()
	diagnostics=preload("res://core/diagnostics.gd").new()
	add_child(diagnostics)
	attach_diagnostics()
	get_tree().node_added.connect(func(node): call_deferred("watch_control",node))
	flow = PlayerFlow.new(session,preferences)
	var margin := MarginContainer.new()
	outer_margin = margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+edge,24)
	add_child(margin)
	root_box = VBoxContainer.new()
	root_box.add_theme_constant_override("separation",12)
	margin.add_child(root_box)
	var top := HBoxContainer.new()
	marquee = MetalPanel.new()
	var marquee_style := Sigma.plate(Color("efb839"),Color("792a1d"),7)
	marquee_style.content_margin_top = 8
	marquee_style.content_margin_bottom = 8
	marquee.add_theme_stylebox_override("panel",marquee_style)
	root_box.add_child(marquee)
	var marquee_box := VBoxContainer.new()
	marquee.add_child(marquee_box)
	marquee_box.add_child(top)
	header = label("HORSE RACING",38)
	var marquee_font := SystemFont.new()
	marquee_font.font_names = PackedStringArray(["Georgia","Times New Roman"])
	marquee_font.font_weight = 800
	header.add_theme_font_override("font",marquee_font)
	header.add_theme_color_override("font_color",Color("741c1d"))
	header.size_flags_horizontal = SIZE_EXPAND_FILL
	top.add_child(header)
	top.add_child(button("Settings  F8",show_settings))
	top.add_child(button("Help  F1",func(): show_help()))
	version_label = label("SD MODE\nVersion 0.22.0",14)
	top.add_child(version_label)
	clock_label = label("",14)
	top.add_child(clock_label)
	preview_note = label("DEVELOPMENT PREVIEW   |   Virtual credits only",16)
	preview_note.add_theme_color_override("font_color",Color("741c1d"))
	preview_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	marquee_box.add_child(preview_note)
	betting_payouts = preload("res://ui/betting_payout_banner.gd").new()
	betting_payouts.name = "BettingPayoutBanner"
	marquee_box.add_child(betting_payouts)
	message = label("Click your player window on the right. Choose wagers on the left, then press READY or OUT.",18)
	message.add_theme_color_override("font_color",Color("fff0cb"))
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root_box.add_child(message)
	announcers=preload("res://ui/announcer_director.gd").new()
	add_child(announcers)
	announcers.set_meta("diagnostics",diagnostics)
	subtitles=Label.new()
	subtitles.name="AnnouncerSubtitles"
	subtitles.mouse_filter=Control.MOUSE_FILTER_IGNORE
	subtitles.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	subtitles.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	subtitles.add_theme_color_override("font_color",Color.WHITE)
	var subtitle_background := StyleBoxFlat.new()
	subtitle_background.bg_color=Color(0.03,0.03,0.03,0.9)
	subtitle_background.set_content_margin_all(8)
	subtitles.add_theme_stylebox_override("normal",subtitle_background)
	subtitles.z_index=10
	add_child(subtitles)
	subtitles.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	subtitles.offset_left=18
	subtitles.offset_right=-18
	subtitles.offset_top=-110
	subtitles.offset_bottom=-60
	subtitles.hide()
	announcers.caption_changed.connect(func(text):
		subtitles.text=text
		subtitles.visible=not text.is_empty())
	body = VBoxContainer.new()
	body.size_flags_horizontal = SIZE_EXPAND_FILL
	body.size_flags_vertical = SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12)
	body_scroll = ScrollContainer.new()
	body_scroll.size_flags_vertical = SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.follow_focus = true
	root_box.add_child(body_scroll)
	body_scroll.add_child(body)
	footer_row = HBoxContainer.new()
	root_box.add_child(footer_row)
	apply_settings()
	show_betting()
	if not blocked:
		save_state()

func label(text: String, font_size: int = 18) -> Label:
	var control := Label.new()
	control.text = text
	control.set_meta("base_font_size",font_size)
	control.add_theme_font_size_override("font_size",scaled_font(font_size))
	return control

func button(text: String, callback: Callable) -> Button:
	var control := Button.new()
	control.text = text
	control.custom_minimum_size.y = 38
	if preferences.values.large_targets:
		control.custom_minimum_size.y = 52
	control.focus_mode = FOCUS_ALL if preferences.values.keyboard_navigation else FOCUS_NONE
	control.pressed.connect(callback)
	return control

func clear_body() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	for child in footer_row.get_children():
		footer_row.remove_child(child)
		child.queue_free()
	pair_buttons.clear()
	track = null
	payout_screen = null
	race_screen = null

func show_betting() -> void:
	if not blocked:
		var before: int=session.audit.size()
		session.VirtualPlayers.place_bets(session)
		if session.audit.size()!=before: save_state()
	betting_payouts.set_board(session.board.payouts)
	preview_note.text = "DEVELOPMENT PREVIEW   |   Virtual credits only"
	if session.board.get("schema")==1:
		preview_note.text += "   |   Existing wagers retain their previous payoff card for this round"
	clear_body()
	set_race_layout(false)
	display_phase = "BETTING"
	var console := BettingPanel.new()
	body.add_child(console)
	console.configure(self,flow)

func select_player(index: int) -> void:
	if blocked:
		return
	if flow.screen == "betting" and flow.active_player == index:
		return
	if flow.select_player(index):
		inactivity = 0.0
		save_state()
		show_betting()
	else:
		message.text = flow.error

func submit_player_pin(pin: String) -> void:
	if not blocked and flow.enter_pin(pin):
		save_state()
		show_betting()

func player_ready() -> void:
	if not blocked:
		act(flow.ready())

func player_out() -> void:
	if not blocked:
		act(flow.out())

func toggle_player_out(index: int) -> void:
	if blocked or display_phase!="BETTING":
		return
	if flow.request_out_toggle(index):
		inactivity = 0.0
		save_state()
	else:
		message.text = flow.error
	# Avoid destroying a nested summary button during its own input signal.
	call_deferred("refresh_betting")

func cycle_virtual(index: int) -> void:
	if blocked or display_phase!="BETTING": return
	var was_active: bool=flow.active_player==index
	if not flow.cycle_virtual(index): message.text=flow.error; return
	inactivity=0.0
	save_state()
	if not was_active and body.get_child_count()>0 and body.get_child(0).has_method("refresh_right"):
		body.get_child(0).call_deferred("refresh_right")
	else: call_deferred("refresh_betting")

func toggle_player_ready(index: int) -> void:
	if blocked or display_phase!="BETTING": return
	var current_player: int=flow.active_player
	if flow.request_ready_toggle(index):
		inactivity = 0.0
		save_state()
	else:
		message.text = flow.error
	if current_player!=index and body.get_child_count()>0 and body.get_child(0).has_method("refresh_right"):
		body.get_child(0).call_deferred("refresh_right")
	else: call_deferred("refresh_betting")

func set_race_layout(racing: bool) -> void:
	footer_row.custom_minimum_size.y = 64 if racing else 0
	message.custom_minimum_size.y = 0
	message.autowrap_mode = TextServer.AUTOWRAP_OFF if racing else TextServer.AUTOWRAP_WORD_SMART
	message.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS if racing else TextServer.OVERRUN_NO_TRIMMING
	marquee.visible = not racing
	preview_note.visible = not racing
	root_box.add_theme_constant_override("separation",4 if racing else 8)
	for edge in ["left","right","top","bottom"]:
		outer_margin.add_theme_constant_override("margin_"+edge,8 if racing or edge in ["top","bottom"] else 24)

func change_bet(index: int, pair: String, amount: int) -> void:
	if blocked or flow.settings_open or flow.screen != "betting" or flow.active_player != index:
		return
	if not session.valid_player(index) or session.virtual_config.seats[index].enabled:
		session.reject("Virtual player bets are read-only.")
		return
	var count := session.audit.size()
	var success := session.edit_bet(index,pair,amount)
	if success:
		if session.audit.size() != count:
			inactivity = 0.0
		save_state()
	else:
		message.text = session.error
	# Keep the emitting SpinBox alive until its value_changed signal completes.
	call_deferred("refresh_betting")

func refresh_betting() -> void:
	if display_phase == "BETTING" and not flow.settings_open:
		show_betting()

func act(success: bool, meaningful: bool = true) -> void:
	if blocked:
		return
	if success:
		if meaningful:
			inactivity = 0
		save_state()
	else:
		message.text = session.error
	if display_phase == "BETTING":
		show_betting()

func save_state() -> void:
	if diagnostics!=null: diagnostics.record("autosave_requested",{"round":session.round_number,"phase":session.phase})
	if blocked:
		return
	if not storage.save(session,preferences,save_path):
		blocked = true
		notice("Saving failed. Play is blocked to protect your balances. " + storage.error)

func notice(text: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "Horse racing"
	dialog.dialog_text = text
	dialog.min_size = Vector2i(550,180)
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

func setup_access() -> void:
	show_settings()

func request_cash_out(index: int) -> void:
	if blocked or not session.request_cash_out(index):
		return
	var confirm := ConfirmationDialog.new()
	confirm.title = "Confirm virtual cash-out"
	confirm.dialog_text = "Freeze %s with %d credits pending operator settlement?\nUnconfirmed wagers will be cancelled." % [session.players[index].nickname,session.players[index].balance]
	confirm.get_ok_button().text = "Confirm pending payout"
	confirm.min_size = Vector2i(620,210)
	add_child(confirm)
	confirm.popup_centered()
	confirm.confirmed.connect(func():
		var success := session.confirm_cash_out(index)
		if success and flow.active_player == index:
			flow.screen = "overview"
			flow.active_player = -1
		act(success)
		confirm.queue_free())
	confirm.canceled.connect(confirm.queue_free)

func show_settings() -> void:
	if blocked or display_phase!="BETTING" or session.phase!="BETTING":
		return
	if flow.settings_open and is_instance_valid(settings_panel):
		settings_panel.popup_centered()
		return
	if find_child("SettingsUnlock",true,false) != null:
		return
	if not session.access.credentials.has("operator"):
		open_settings("")
		return
	var unlock := AcceptDialog.new()
	unlock.name = "SettingsUnlock"
	unlock.title = "Manager Settings"
	unlock.min_size = Vector2i(420,180)
	unlock.dialog_hide_on_ok = false
	unlock.get_ok_button().text = "Open settings"
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(380,100)
	unlock.add_child(box)
	var pin := LineEdit.new()
	pin.name = "SettingsPin"
	pin.secret = true
	pin.max_length = 16 if not session.access.credentials.operator.has("digits") else 4
	pin.placeholder_text = "Settings PIN"
	box.add_child(pin)
	var feedback := label("",16)
	box.add_child(feedback)
	unlock.confirmed.connect(func():
		if flow.begin_settings(pin.text):
			pin.text = ""
			unlock.hide()
			unlock.queue_free()
			open_settings("")
		else:
			feedback.text = flow.error
			pin.select_all())
	pin.text_submitted.connect(func(_value): unlock.confirmed.emit())
	unlock.canceled.connect(unlock.queue_free)
	add_child(unlock)
	unlock.popup_centered()
	pin.grab_focus()

func open_settings(pin: String) -> void:
	if display_phase!="BETTING" or session.phase!="BETTING": return
	if not flow.settings_open and not flow.begin_settings(pin):
		return
	if is_instance_valid(settings_panel):
		settings_panel.queue_free()
	settings_panel = SettingsPanel.new()
	settings_panel.game_action=game_file_action
	settings_panel.help_requested=show_help
	if announcers!=null:
		announcers.pause_for_settings(true)
		settings_panel.test_voice=announcers.preview
		settings_panel.stop_voice=announcers.stop
	add_child(settings_panel)
	settings_panel.configure(preferences,func():
		apply_settings()
		save_state(),flow,func():
		save_state()
		apply_settings()
		if session.phase == "BETTING":
			show_betting()
		if not flow.settings_return_notice.is_empty():
			message.text = flow.settings_return_notice)
	settings_panel.popup_centered()
	if flow.settings_player >= 0:
		settings_panel.focus_context.call_deferred()
	else:
		settings_panel.get_ok_button().grab_focus()

func apply_settings() -> void:
	if diagnostics!=null and _logged_settings!=preferences.values:
		diagnostics.record("settings_changed",{"before":_logged_settings,"after":preferences.values})
		_logged_settings=preferences.values.duplicate(true)
	if diagnostics!=null: diagnostics.record("settings_snapshot",settings_snapshot("settings_applied"))
	if announcers!=null:
		announcers.configure(preferences.values)
		subtitles.add_theme_font_size_override("font_size",int(preferences.values.subtitle_size))
	if is_instance_valid(race_screen): race_screen.update_preferences(preferences.values)
	if is_instance_valid(track):
		track.get_parent().get_parent().audio.preferences = preferences.values
	version_label.visible = preferences.values.show_firmware
	clock_label.visible = preferences.values.show_clock
	theme.default_font_size = scaled_font(18)
	marquee.lights = preferences.values.cabinet_lights
	marquee.light_intensity = preferences.values.light_intensity
	marquee.queue_redraw()
	RenderingServer.set_default_clear_color(palette_color("background"))
	var focus_style := StyleBoxFlat.new()
	focus_style.bg_color = Color(0,0,0,0)
	focus_style.border_color = Color("ffd775")
	focus_style.set_border_width_all(3 if preferences.values.focus_outline else 1)
	focus_style.set_corner_radius_all(4)
	theme.set_stylebox("focus","Button",focus_style)
	theme.set_stylebox("focus","LineEdit",focus_style)
	for control in find_children("*","Label",true,false):
		if control.has_meta("base_font_size"):
			control.add_theme_font_size_override("font_size",scaled_font(control.get_meta("base_font_size")))
	ProjectSettings.set_setting("gui/timers/tooltip_delay_sec",preferences.values.tooltip_delay)
	frame_budget.configure(preferences.values)
	if applied_window_mode != preferences.values.window_mode or applied_resolution != preferences.values.resolution:
		if preferences.values.window_mode == "Fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		elif preferences.values.window_mode == "Maximized":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			if applied_window_resolution != preferences.values.resolution:
				var components: PackedStringArray = preferences.values.resolution.split(" x ")
				DisplayServer.window_set_size(Vector2i(int(components[0]),int(components[1])))
				applied_window_resolution = preferences.values.resolution
		applied_window_mode = preferences.values.window_mode
		applied_resolution = preferences.values.resolution

func scaled_font(base_size: int) -> int:
	# Keep the already large title stable, while body text follows accessibility preferences.
	if base_size >= 28:
		return base_size
	return roundi(base_size * preferences.values.ui_scale * (1.15 if preferences.values.large_text else 1.0))

func palette_color(role: String) -> Color:
	var palette := {"background":"35151d","panel":"c8c4b8","ready":"b6c39a"}
	match preferences.values.palette:
		"Enhanced":
			palette = {"background":"171329","panel":"30274d","ready":"205348"}
		"High contrast":
			palette = {"background":"000000","panel":"171717","ready":"204f30"}
		"Muted":
			palette = {"background":"242a30","panel":"343b43","ready":"3a4b43"}
	if role == "background" and preferences.values.background_style == "Dark":
		return Color("090b0e")
	if role == "background" and preferences.values.background_style == "Minimal":
		return Color("252525")
	return Color(palette[role])

func clear_player_bets(index: int) -> void:
	if blocked or not session.mutable_player(index):
		return
	if session.virtual_config.seats[index].enabled:
		session.reject("Virtual player bets are read-only.")
		return
	var action := func():
		if session.virtual_config.seats[index].enabled:
			session.reject("Virtual player bets are read-only.")
			return
		var count := session.audit.size()
		for pair in session.players[index].bets.keys():
			session.edit_bet(index,pair,0)
		act(true,session.audit.size() != count)
	if preferences.values.confirm_clear:
		var dialog := ConfirmationDialog.new()
		dialog.dialog_text = "Clear all wagers for " + session.players[index].nickname + "?"
		dialog.min_size = Vector2i(450,150)
		add_child(dialog)
		dialog.confirmed.connect(func():
			action.call()
			dialog.queue_free())
		dialog.canceled.connect(dialog.queue_free)
		dialog.popup_centered()
	else:
		action.call()

func toggle_fullscreen() -> void:
	if preferences.values.window_mode == "Fullscreen":
		preferences.set_value("window_mode",before_fullscreen)
	else:
		before_fullscreen = preferences.values.window_mode
		preferences.set_value("window_mode","Fullscreen")
	apply_settings()
	if not blocked:
		save_state()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		race_entropy.observe_pointer(event.position)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_F1:
		show_help()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F8:
		show_settings()
	elif event.keycode == KEY_F11:
		toggle_fullscreen()
		get_viewport().set_input_as_handled()
	elif event.ctrl_pressed and event.alt_pressed and event.shift_pressed and event.keycode == KEY_F9:
		protected_panel(true)
	elif event.ctrl_pressed and event.alt_pressed and event.keycode == KEY_O:
		protected_panel(false)

func show_help(context: String="", owner_window: Node=null) -> void:
	if is_instance_valid(help_panel):
		if not context.is_empty(): help_panel.open_context(context)
		help_panel.popup_centered()
		return
	if context.is_empty():
		context="Players and PINs" if flow.screen=="pin" else ("Betting" if display_phase=="BETTING" else "Race playback")
	help_panel=preload("res://ui/help_panel.gd").new()
	var host: Node=owner_window if is_instance_valid(owner_window) else (settings_panel if is_instance_valid(settings_panel) and settings_panel.visible else self)
	host.add_child(help_panel)
	help_panel.configure(context)
	help_panel.popup_centered()

func protected_panel(rtp: bool) -> void:
	if blocked or session.phase != "BETTING":
		notice("Operator changes are available between races, after settlement.")
		return
	if not session.access.credentials.has("rtp" if rtp else "operator"):
		setup_access()
		return
	var unlock := AcceptDialog.new()
	unlock.name = "ProtectedUnlock"
	unlock.title = "Unlock protected configuration" if rtp else "Unlock operator console"
	unlock.min_size = Vector2i(490,190)
	unlock.get_ok_button().text = "Unlock"
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(450,120)
	unlock.add_child(box)
	var pin := LineEdit.new()
	pin.name = "AccessPin"
	pin.secret = true
	pin.placeholder_text = "Enter the configuration PIN" if rtp else "Enter the operator PIN"
	box.add_child(pin)
	var feedback := label("",16)
	box.add_child(feedback)
	unlock.confirmed.connect(func():
		if session.authorize("rtp" if rtp else "operator",pin.text):
			unlock.hide()
			open_protected_console(rtp,pin.text)
			unlock.queue_free()
		else:
			feedback.text = "PIN not accepted, or access is temporarily locked."
			unlock.popup_centered())
	add_child(unlock)
	unlock.popup_centered()
	pin.grab_focus()

func open_protected_console(rtp: bool, authorized_pin: String) -> void:
	if blocked or session.phase != "BETTING":
		return
	var dialog := AcceptDialog.new()
	dialog.name = "ProtectedConsole"
	dialog.title = "Protected configuration" if rtp else "Operator console"
	dialog.window_input.connect(func(event):
		if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F1:
			show_help("Protected configuration" if rtp else "Operator console",dialog)
			dialog.set_input_as_handled())
	dialog.min_size = Vector2i(600,360)
	var box := VBoxContainer.new()
	box.position = Vector2(24,24)
	box.custom_minimum_size = Vector2(550,275)
	dialog.add_child(box)
	box.add_child(button("Help  F1",func(): show_help("Protected configuration" if rtp else "Operator console",dialog)))
	var pin := LineEdit.new()
	pin.secret = true
	pin.text = authorized_pin
	pin.visible = false
	box.add_child(pin)
	var amount := SpinBox.new()
	if rtp:
		box.add_child(label("Next-round average payout percentage",18))
		amount.min_value = 70
		amount.max_value = 200
		amount.value = session.board.requested_rtp
		box.add_child(amount)
		var deck_choice:=OptionButton.new()
		deck_choice.add_item("SD source cards at 80%; Variable otherwise")
		deck_choice.add_item("Variable cards at any percentage")
		deck_choice.select(1 if session.export_data().next_deck_mode=="Variable" else 0)
		box.add_child(deck_choice)
		box.add_child(label("Starts a new saved rotation for the next card. Existing bets keep their payouts.",14))
		box.add_child(button("Use for next round",func():
			act(session.set_rtp(int(amount.value),pin.text,"SD" if deck_choice.selected==0 else "Variable"))))
	else:
		var player := OptionButton.new()
		var operation := OptionButton.new()
		for account in session.players:
			player.add_item(account.nickname)
		player.select(maxi(0,flow.active_player))
		box.add_child(player)
		for choice in ["add","remove","set"]:
			operation.add_item(choice)
		box.add_child(operation)
		amount.min_value = 0
		amount.max_value = 1000000
		amount.step = 1
		amount.value = 100
		box.add_child(amount)
		box.add_child(button("Apply credit adjustment",func():
			var index := player.selected
			var before: int = session.available(index)
			if session.adjust_balance(index,int(amount.value),operation.get_item_text(operation.selected),pin.text):
				reload_from[index] = before
				act(true)
				dialog.hide()
				dialog.queue_free()
			else: notice(session.error)))
		box.add_child(button("Settle pending virtual payout",func():
			act(session.resolve_cash_out(player.selected,true,pin.text))))
		box.add_child(button("Cancel pending virtual payout",func():
			act(session.resolve_cash_out(player.selected,false,pin.text))))
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)

func start_race() -> void:
	if blocked or not flow.can_start():
		return
	for child in get_children():
		if child is Window and child.visible:
			return
	if session.manager_only_start:
		flow.screen = "start_pin"
		show_betting()
	else:
		submit_start_pin("")

func submit_start_pin(pin: String) -> void:
	if blocked or not flow.authorize_start(pin):
		return
	_begin_race()

func _begin_race() -> void:
	var seed_value: String = race_entropy.new_seed()
	if seed_value.is_empty():
		message.text = "Random source unavailable. Race has not started."
		return
	if not session.start_race(seed_value,preferences.values):
		message.text = session.error
		return
	save_state()
	if blocked:
		return
	# Simulate movement once, then play its recorded time line at the chosen visual duration.
	var calculate_started := Time.get_ticks_usec()
	var tick_rows: Array=[]
	visual_race = session.create_visual_race()
	snapshots = [visual_race.snapshot()]
	while not visual_race.finished:
		visual_race.advance_event()
		snapshots.append(visual_race.snapshot())
		var event: Dictionary=visual_race.last_event()
		tick_rows.append([event.get("event",tick_rows.size()+1),event.get("round",0),event.get("slot",0),event.selected,event.end_time,event.end_positions])
	visual_result = visual_race.result()
	playback = preferences.values.duplicate(true)
	var replay_config: Dictionary=preload("res://core/replay_policy.gd").configuration(playback.photo_frequency,playback,int(visual_result.get("movement_component",0)))
	playback.photo_threshold=replay_config.threshold
	playback.photo_tie_fraction=replay_config.tie_fraction
	diagnostics.record("settings_snapshot",settings_snapshot("race_started"))
	diagnostics.record("race_motion",{"round":session.round_number,"columns":["event","movement_round","slot","horse_zero_based","logical_time","positions"],"ticks":tick_rows})
	if visual_race.has_method("race_control_summary"):
		diagnostics.record("race_control",visual_race.race_control_summary())
	diagnostics.record("race_calculated",{"round":session.round_number,"calculation_ms":(Time.get_ticks_usec()-calculate_started)/1000.0,"result":visual_result,"playback":playback,"replay":replay_decision()})
	diagnostics.queue_flush()
	race_elapsed = 0.0
	post_elapsed = 0.0
	replay_elapsed = 0.0
	replay_start = -1.0
	display_phase = "PREPARING"
	preparation_elapsed = 0.0
	countdown_elapsed = 0.0
	flow.screen = "overview"
	flow.active_player = -1
	clear_body()
	set_race_layout(true)
	var race_display := RaceDisplay.new()
	race_screen = race_display
	body.add_child(race_display)
	race_display.configure(session,playback)
	race_display.audio.preferences = preferences.values
	track = race_display.track
	track.moving = display_phase == "RACING"
	var largest := 0
	for player in session.players: largest = maxi(largest,int(player.bets.get(visual_result.pair,0))*int(session.board.payouts[visual_result.pair]))
	var award_kind := "none" if largest == 0 else ("jackpot" if session.board.payouts[visual_result.pair]>=50 or largest>=500 else "small")
	announcers.prepare_race(snapshots,visual_result,float(playback.race_seconds),needs_photo_finish(),award_kind)
	start_signal = preload("res://ui/start_signal.gd").new()
	race_display.add_child(start_signal)
	message.text = "Preparing race audio..."
	inactivity = 0.0

func interpolate_motion(time: float) -> Array:
	# Recorded time units differ between preserved legacy rounds and microturn races.
	# Search timestamps so both normal playback and replay follow the actual motion.
	var low := 0
	var high := snapshots.size()-1
	while high-low>1:
		var middle := (low+high)/2
		if snapshots[middle].time<=time: low=middle
		else: high=middle
	var index := mini(low,snapshots.size()-2)
	var start: Dictionary = snapshots[index]
	var end: Dictionary = snapshots[index+1]
	var alpha := clampf((time-start.time)/(end.time-start.time),0.0,1.0)
	var positions: Array = []
	for horse in range(5):
		positions.append(lerpf(start.positions[horse],end.positions[horse],alpha))
	return positions

func replay_time_at(elapsed: float) -> float:
	if replay_start<0.0:
		var length_units: float=track.horse_length_units() if is_instance_valid(track) else 48.0*playback.get("horse_scale",1.55)/1.68
		replay_start=preload("res://ui/replay_window.gd").start_time(snapshots,visual_result.second,length_units*playback.get("replay_lengths",1.0))
	return preload("res://ui/replay_window.gd").at(replay_start,float(visual_result.second_time),elapsed,float(playback.get("replay_seconds",5.0)))

func _process(delta: float) -> void:
	if diagnostics!=null:
		diagnostics.frame(delta,display_phase,track.positions if is_instance_valid(track) else [],race_elapsed)
		if not diagnostics.error.is_empty() and not _diagnostic_warning:
			_diagnostic_warning=true
			call_deferred("notice",diagnostics.error+". Play may continue, but the diagnostic record is incomplete.")
	if blocked or body == null:
		if blocked and announcers!=null: announcers.stop()
		return
	if announcers!=null:
		announcers.advance(delta)
		var window_open := false
		for child in get_children():
			if child is Window and child.visible: window_open=true
		announcers.pause_for_settings(window_open)
		var public_result: Dictionary=visual_result if display_phase in ["POST","REPLAY","PHOTO","SETTLED","PAYOUT"] else {}
		announcers.observe(display_phase,track.positions if is_instance_valid(track) else [],race_elapsed/float(playback.get("race_seconds",35.0)),public_result)
	if preferences.values.show_clock:
		clock_label.text = Time.get_time_string_from_system()
	if display_phase in ["SETTLED","PAYOUT"]:
		# Keep result screens in place while Settings or its PIN prompt is open.
		for child in get_children():
			if child is Window and child.visible: return
		if display_phase == "SETTLED":
			result_elapsed += delta
			if result_elapsed >= 2.0 and (announcers==null or not announcers.speaking_result()): show_payouts()
		elif is_instance_valid(race_screen):
			race_screen.advance_payouts(delta)
			var returning := footer_row.get_node_or_null("ReturnToBetting")
			if returning != null: returning.disabled = not race_screen.payout_complete or not announcers.active_role.is_empty()
		return
	if display_phase == "BETTING":
		var panel_open := false
		for child in get_children():
			if child is Window and child.visible:
				panel_open = true
		if not panel_open:
			inactivity += delta
		if not panel_open and preferences.values.inactivity_enabled and not reminded and inactivity >= preferences.values.inactivity_seconds:
			reminded = true
			if preferences.values.reminder_text:
				message.text = "Mark each participating player READY when their wagers are set."
	elif display_phase == "PREPARING":
		preparation_elapsed += delta
		if not announcers.preparing() or preparation_elapsed>=32.0:
			if session.start_countdown>0: display_phase="COUNTDOWN"
			else: begin_playback()
	elif display_phase == "COUNTDOWN":
		countdown_elapsed += delta
		message.text = "Starting in %d" % maxi(0,ceili(session.start_countdown-countdown_elapsed))
		if countdown_elapsed >= session.start_countdown:
			begin_playback()
	elif display_phase == "RACING":
		race_elapsed += delta
		var progress := clampf(race_elapsed/playback.race_seconds,0.0,1.0)
		track.positions = interpolate_motion(progress*visual_result.second_time)
		if race_elapsed>=0: message.text="They're off!"
		if progress >= 1.0:
			if not session.finish_race(visual_result):
				blocked = true
				notice(session.error)
				return
			save_state()
			display_phase = "POST"
			message.text = "Photo finish. Reviewing the recorded finish..." if needs_photo_finish() else "Across the line. Official result follows..."
	elif display_phase == "POST":
		post_elapsed += delta
		track.positions = visual_race.post_positions(post_elapsed*visual_result.second_time/playback.race_seconds)
		if post_elapsed >= playback.post_finish_seconds and not announcers.speaking_result():
			if needs_photo_finish():
				display_phase = "REPLAY"
				track.close_up = true
				track.photo_focus = (float(visual_result.second)+float(third_horse()))*0.5
				track.positions = interpolate_motion(replay_time_at(0.0))
				track.configure_photo_frame(track.positions,interpolate_motion(visual_result.second_time))
				diagnostics.record("replay_window",{"start_time":replay_start,"end_time":visual_result.second_time,"duration_seconds":playback.replay_seconds,"horse_lengths":playback.replay_lengths,"start_positions":track.positions,"end_positions":interpolate_motion(visual_result.second_time)})
			else:
				present_result()
	elif display_phase == "REPLAY":
		replay_elapsed += delta
		var replay_time: float = replay_time_at(replay_elapsed)
		track.positions = interpolate_motion(replay_time)
		if replay_time >= visual_result.second_time:
			display_phase = "PHOTO"
			post_elapsed = 0.0
			track.photo = playback.photo_monochrome
			track.photo_hold = true
			track.highlight = visual_result.second if playback.photo_highlight else -1
	elif display_phase == "PHOTO":
		post_elapsed += delta
		if post_elapsed >= playback.photo_hold_seconds:
			present_result()
	if is_instance_valid(track):
		track.moving = display_phase in ["POST","REPLAY"] or (display_phase=="RACING" and race_elapsed>=0)

func present_result() -> void:
	if session.phase != "RESULTS": return
	message.text = "Official finish: %d first, %d second. Winning quinella: %s." % [visual_result.first+1,visual_result.second+1,visual_result.pair]
	if not session.announce_result():
		blocked = true
		notice(session.error)
		return
	display_phase = "SETTLED"
	result_elapsed = 0.0
	track.moving = false
	track.highlight = -1
	track.highlights = [visual_result.first,visual_result.second]
	track._highlight_clock = 0.0
	var race_display := track.get_parent().get_parent()
	if race_display.has_method("refresh_players"): race_display.refresh_players()
	save_state()


func show_payouts() -> void:
	if blocked or session.phase != "SETTLED" or display_phase != "SETTLED" or flow.settings_open or not is_instance_valid(race_screen): return
	display_phase = "PAYOUT"
	race_screen.begin_payouts()
	var returning := button("RETURN TO BETTING",return_to_betting)
	returning.name = "ReturnToBetting"
	returning.custom_minimum_size = Vector2(280,56)
	returning.disabled = true
	footer_row.add_child(returning)

func replay_decision() -> Dictionary:
	var config: Dictionary=preload("res://core/replay_policy.gd").configuration(playback.get("photo_frequency",20),playback,int(visual_result.get("movement_component",0)))
	config.threshold=playback.get("photo_threshold",config.threshold)
	config.tie_fraction=playback.get("photo_tie_fraction",config.tie_fraction)
	return preload("res://core/replay_policy.gd").decide(visual_result,config)

func needs_photo_finish() -> bool:
	return replay_decision().replay

func third_horse() -> int:
	var third := -1
	for horse in range(5):
		if horse in [visual_result.first,visual_result.second]: continue
		if third<0 or visual_result.positions[horse]>visual_result.positions[third]: third=horse
	return third

func begin_playback() -> void:
	display_phase="RACING"
	race_elapsed=-start_signal.play_signal(playback)
	track.moving=race_elapsed>=0
	message.text="Call to the post" if playback.start_signal in ["Horn","Horn and bell"] else "Ready at the start"
	diagnostics.record("start_signal",start_signal.schedule)

func return_to_betting() -> void:
	if blocked or display_phase != "PAYOUT" or flow.settings_open: return
	if is_instance_valid(race_screen) and (not race_screen.payout_complete or not announcers.active_role.is_empty()): return
	for child in get_children():
		if child is Window and child.visible: return
	if not session.next_round(): return
	reminded = false
	inactivity = 0.0
	flow.screen = "overview"
	flow.active_player = -1
	save_state()
	if blocked: return
	show_betting()
	message.text = "Previous winning pair: %s. Place your next wagers when ready." % visual_result.pair
