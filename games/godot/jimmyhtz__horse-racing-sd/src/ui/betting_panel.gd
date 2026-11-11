extends HBoxContainer
const Identity = preload("res://core/player_identity.gd")
const Avatar = preload("res://ui/player_avatar.gd")
const Sigma = preload("res://ui/sigma_style.gd")
const MetalPanel = preload("res://ui/machine_panel.gd")
const LED = preload("res://ui/led_display.gd")
const MiniBets = preload("res://ui/mini_bets.gd")
const Banner = preload("res://ui/player_banner.gd")
const SplitBet = preload("res://ui/split_bet_button.gd")
const Wager = preload("res://ui/led_wager.gd")
var app: Control
var flow: RefCounted

func configure(owner_app: Control, controller: RefCounted) -> void:
	app = owner_app
	flow = controller
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	add_theme_constant_override("separation",18)
	var left := section(1.2)
	left.name = "PlayerConsole"
	var right := section(1.0)
	right.name = "PlayerSummaries"
	build_left(left)
	build_right(right)

func section(ratio: float) -> VBoxContainer:
	var panel := MetalPanel.new()
	panel.size_flags_horizontal = SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = ratio
	var style := Sigma.plate()
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",10)
	panel.add_child(box)
	return box

func build_left(box: VBoxContainer) -> void:
	if flow.screen == "start_pin":
		box.add_child(app.label("MANAGER START",23))
		pin_prompt(box,true)
		return
	if flow.active_player >= 0:
		var index: int = flow.active_player
		var profile: Dictionary = app.session.player_profiles[index]
		var title := Banner.new()
		title.name = "PlayerBanner"
		title.configure(profile,"PLAYER %d  |  %s" % [index+1,app.session.players[index].nickname],64,app.scaled_font(22))
		box.add_child(title)
		var panel_style: StyleBoxFlat = box.get_parent().get_theme_stylebox("panel").duplicate()
		panel_style.border_color = Color(Identity.PALETTES[profile.color][1])
		panel_style.set_border_width_all(4)
		box.get_parent().add_theme_stylebox_override("panel",panel_style)
		if flow.screen == "pin":
			box.add_child(virtual_button(index,true))
			pin_prompt(box,false)
			return
	else:
		var idle := VBoxContainer.new()
		idle.name = "IdleConsole"
		idle.size_flags_vertical = SIZE_EXPAND_FILL
		idle.alignment = BoxContainer.ALIGNMENT_CENTER
		idle.add_theme_constant_override("separation",20)
		box.add_child(idle)
		for line in ["WELCOME TO THE TRACK","Select your player on the right","Choose your combinations, then press READY.","The payouts for this race are shown above."]:
			var prompt = app.label(line,26 if line == "WELCOME TO THE TRACK" else 18)
			prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			idle.add_child(prompt)
		return
	if flow.screen in ["virtual","inactive"]:
		var i: int=flow.active_player
		box.add_child(app.label("V MODE  |  Always In and Ready" if flow.screen=="virtual" else "OUT  |  Reload credits or try V mode",22))
		if flow.screen=="virtual":
			var mini := MiniBets.new()
			mini.name="VirtualMini"
			mini.configure(app.session.players[i].bets,0,0,2,false,true,"Credits",true)
			mini.show_simulation(app.session.last_display_win(i),app.session.players[i].bets)
			box.add_child(mini)
			box.add_child(app.label("Simulated bets and wins only. Your human credits are untouched.",16))
		var controls := HBoxContainer.new()
		box.add_child(controls)
		controls.add_child(virtual_button(i,true))
		if flow.screen=="virtual":
			var inside=app.button("IN",func(): app.toggle_player_out(i))
			inside.name="PlayerOut"; mark_in(inside,i); controls.add_child(inside)
		else: controls.add_child(app.button("Reload",func(): app.protected_panel(false)))
		controls.add_child(app.button("Back",func(): flow.back(); app.show_betting()))
		return
	var meters := HBoxContainer.new()
	meters.add_theme_constant_override("separation",14)
	box.add_child(meters)
	var player_index: int = flow.active_player
	var last_win: int=app.session.last_display_win(player_index)
	meter(meters,"WIN",last_win,4)
	meter(meters,app.preferences.values.credit_label.to_upper(),app.session.available(player_index) if player_index >= 0 else 0,4)
	if app.preferences.values.show_totals:
		meter(meters,"COINS BET",app.session.wager_total(player_index) if player_index >= 0 else 0,3)
	var choices := HBoxContainer.new()
	choices.add_theme_constant_override("separation",14)
	box.add_child(choices)
	bet_column(choices,["1-2","1-3","1-4","1-5","2-3"])
	bet_column(choices,["2-4","2-5","3-4","3-5","4-5"])
	var footer = app.label("BET ON ANY VARIETY OF HORSE COMBINATIONS",13)
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(footer)
	var spacer := Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	box.add_child(spacer)
	player_actions(box)

func bet_column(parent: Control, keys: Array) -> void:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",6)
	parent.add_child(grid)
	for heading in ["PAIR","PAYOUT","BET","ADJUST"]:
		var title = app.label(heading,12)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(title)
	for pair in keys:
		var odds: int = app.session.board.payouts[pair]
		var caption = app.label(pair.replace("-"," - "),19)
		caption.name = "Pair_"+pair.replace("-","_")
		caption.custom_minimum_size.x = 58
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.size_flags_vertical = SIZE_SHRINK_CENTER
		grid.add_child(caption)
		var odds_display := LED.new()
		odds_display.value = odds
		odds_display.digits = 2
		odds_display.ink = Color("ff4150") if odds >= 50 else (Color("ffe037") if odds >= 10 else Color("63f17b"))
		odds_display.tooltip_text = "%dx total return" % odds if app.preferences.values.tooltips else ""
		var odds_row := HBoxContainer.new()
		odds_row.name = "Payout_"+pair.replace("-","_")
		odds_row.size_flags_vertical = SIZE_SHRINK_CENTER
		grid.add_child(odds_row)
		odds_row.add_child(odds_display)
		odds_row.add_child(app.label("x",14))
		app.pair_buttons[pair] = caption
		if flow.screen == "betting":
			var index: int = flow.active_player
			var amount := Wager.new()
			amount.name = "Wager_" + pair.replace("-","_")
			amount.max_value = 20
			amount.step = 1
			amount.custom_arrow_step = app.preferences.values.bet_increment
			amount.value = app.session.players[index].bets.get(pair,0)
			amount.select_all_on_focus = true
			amount.editable = not app.blocked
			amount.size_flags_vertical = SIZE_SHRINK_CENTER
			amount.tooltip_text = "Type whole credits. Arrows use your chosen increment." if app.preferences.values.tooltips else ""
			amount.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
					amount.accept_event()
					if app.preferences.values.wheel_betting and event.pressed:
						var direction := 1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1
						amount.value = clampi(int(amount.value)+direction*int(app.preferences.values.bet_increment),0,20))
			amount.value_changed.connect(func(value): app.change_bet(index,pair,int(value)))
			grid.add_child(amount)
		else:
			var amount := LED.new()
			amount.digits = 2
			amount.custom_minimum_size = Vector2(78,42)
			amount.size_flags_vertical = SIZE_SHRINK_CENTER
			grid.add_child(amount)
		var adjust := HBoxContainer.new()
		adjust.name = "Adjust_"+pair.replace("-","_")
		adjust.size_flags_vertical = SIZE_SHRINK_CENTER
		adjust.add_theme_constant_override("separation",2)
		grid.add_child(adjust)
		var bet := SplitBet.new()
		bet.text = "BET"
		bet.focus_mode = FOCUS_ALL if app.preferences.values.keyboard_navigation else FOCUS_NONE
		bet.pressed.connect(func():
			if flow.screen == "betting":
				var index: int = flow.active_player
				app.change_bet(index,pair,clampi(int(app.session.players[index].bets.get(pair,0))+int(app.preferences.values.bet_increment),0,20)))
		bet.name = "BetUp_"+pair.replace("-","_")
		bet.disabled = flow.screen != "betting" or app.blocked
		Sigma.bet_button(bet)
		adjust.add_child(bet)
		bet.custom_minimum_size = Vector2(64,64)
		bet.alignment = HORIZONTAL_ALIGNMENT_CENTER
		for state in ["normal","hover","pressed","disabled"]:
			var style: StyleBoxFlat = bet.get_theme_stylebox(state).duplicate()
			style.set_corner_radius_all(32)
			style.content_margin_left = 4
			if state in ["normal","hover","pressed"]: style.bg_color = Color("efbd31")
			bet.add_theme_stylebox_override(state,style)
		var arrow := Label.new()
		arrow.name = "BetArrowUp_"+pair.replace("-","_")
		arrow.text = "▲"
		arrow.add_theme_font_size_override("font_size",11)
		arrow.add_theme_color_override("font_color",Sigma.INK)
		arrow.mouse_filter = MOUSE_FILTER_IGNORE
		arrow.position = Vector2(27,5)
		bet.add_child(arrow)
		var down = app.button("▼",func():
			if flow.screen == "betting":
				var index: int = flow.active_player
				app.change_bet(index,pair,clampi(int(app.session.players[index].bets.get(pair,0))-int(app.preferences.values.bet_increment),0,20)))
		down.name = "BetDown_"+pair.replace("-","_")
		down.disabled = bet.disabled
		down.custom_minimum_size = Vector2.ZERO
		down.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		down.anchor_left = 0.0
		down.anchor_right = 1.0
		down.anchor_top = SplitBet.DOWN_START
		down.add_theme_font_size_override("font_size",11)
		for state in ["normal","hover","pressed","disabled"]:
			down.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
			down.add_theme_color_override(state,Sigma.INK)
		bet.add_child(down)
		bet.connect_down(down)

func meter(row: HBoxContainer, caption: String, number: int, digits: int) -> void:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(column)
	var title_label = app.label(caption,13)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var title_row := HBoxContainer.new()
	column.add_child(title_row)
	title_label.size_flags_horizontal=SIZE_EXPAND_FILL
	title_row.add_child(title_label)
	var display := LED.new()
	display.value = number
	display.digits = digits
	display.custom_minimum_size = Vector2(85,43)
	column.add_child(display)
	if caption == app.preferences.values.credit_label.to_upper() and app.reload_from.has(flow.active_player):
		var start: int = app.reload_from[flow.active_player]
		app.reload_from.erase(flow.active_player)
		display.value=start
		var animation := display.create_tween()
		animation.tween_method(func(value):
			display.value=roundi(value)
			display.queue_redraw(),float(start),float(number),0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func player_actions(box: VBoxContainer) -> void:
	if flow.screen == "betting":
		var controls := HFlowContainer.new()
		controls.add_theme_constant_override("h_separation",12)
		controls.add_theme_constant_override("v_separation",12)
		box.add_child(controls)
		var ready = app.button("READY",func(): app.player_ready())
		ready.name = "PlayerReady"
		controls.add_child(ready)
		var participating: bool = app.session.players[flow.active_player].state != "OUT"
		var out = app.button("IN" if participating else "OUT",func(): app.toggle_player_out(flow.active_player))
		out.name = "PlayerOut"
		Sigma.indicator(out,participating)
		controls.add_child(out)
		controls.add_child(virtual_button(flow.active_player,true))
		var clear = app.button("Clear bets",func(): app.clear_player_bets(flow.active_player))
		clear.name = "PlayerClear"
		controls.add_child(clear)
		var cash_out = app.button("Cash out",func(): app.request_cash_out(flow.active_player))
		cash_out.name = "PlayerCashOut"
		controls.add_child(cash_out)
		var reload = app.button("Reload",func(): app.protected_panel(false))
		reload.name = "PlayerReload"
		controls.add_child(reload)
		var palette: Array = Identity.PALETTES[app.session.player_profiles[flow.active_player].color]
		var width := 84.0
		for action in controls.get_children():
			action.add_theme_font_size_override("font_size",15)
			for state in ["normal","hover","pressed","hover_pressed","disabled"]:
				var style := Sigma.plate(Color(palette[1]),Color(palette[2]),6)
				style.content_margin_left=10
				style.content_margin_right=10
				if state == "hover": style.bg_color = style.bg_color.lightened(0.12)
				if state in ["pressed","hover_pressed"]:
					style.bg_color = Color(palette[1]).darkened(0.45)
					style.set_border_width_all(4)
					style.shadow_size = 0
				if state == "disabled": style.bg_color = Color(palette[1]).darkened(0.65)
				action.add_theme_stylebox_override(state,style)
			for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_disabled_color"]:
				action.add_theme_color_override(state,Color(palette[2]))
			var pressed_ink := Color.WHITE if Color(palette[1]).darkened(0.45).get_luminance() < 0.45 else Color("171717")
			action.add_theme_color_override("font_pressed_color",pressed_ink)
			action.add_theme_color_override("font_hover_pressed_color",pressed_ink)
			if action!=ready: width = maxf(width,action.get_combined_minimum_size().x)
		for action in controls.get_children():
			action.custom_minimum_size = Vector2(width,40)
			action.add_theme_font_size_override("font_size",15)
		ready.custom_minimum_size = Vector2(maxf(176,width*2.0),64)
		ready.add_theme_font_size_override("font_size",24)
		for state in ["normal","hover"]:
			var style: StyleBoxFlat=ready.get_theme_stylebox(state).duplicate()
			style.border_color=Color("fff02e")
			style.set_border_width_all(4)
			ready.add_theme_stylebox_override(state,style)


func pin_prompt(box: VBoxContainer, starting: bool) -> void:
	box.add_child(app.label("Enter the four-digit Start PIN" if starting else "Enter your four-digit PIN",18))
	var pin := LineEdit.new()
	pin.name = "StartPin" if starting else "PlayerPin"
	pin.secret = true
	pin.max_length = 4
	pin.placeholder_text = "****"
	pin.custom_minimum_size.y = 48
	box.add_child(pin)
	var feedback = app.label("",16)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(feedback)
	pin.text_changed.connect(func(value):
		if value.length() == 4:
			if starting:
				app.submit_start_pin(value)
			else:
				app.submit_player_pin(value)
			if flow.screen in ["pin","start_pin"]:
				feedback.text = flow.error
				pin.select_all())
	var back = app.button("Back",func():
		flow.back()
		app.show_betting())
	back.name = "PlayerBack"
	box.add_child(back)
	(func():
		if is_instance_valid(pin) and pin.is_inside_tree(): pin.grab_focus()).call_deferred()

func build_right(box: VBoxContainer) -> void:
	box.add_theme_constant_override("separation",6)
	box.add_child(app.label("PLAYERS  |  RACE %d" % app.session.round_number if app.preferences.values.show_round else "PLAYERS",21))
	var all_ready := true
	for player in app.session.players:
		all_ready = all_ready and player.state in ["READY","OUT","PENDING PAYOUT"]
	var light = app.label("ALL PLAYERS READY OR OUT" if all_ready else "WAITING FOR PLAYERS",17)
	light.name = "ReadyLight"
	light.add_theme_color_override("font_color",Color("176737") if all_ready else Color("68512a"))
	box.add_child(light)
	var start = app.button("START RACE" + ("  [PIN]" if app.session.manager_only_start else ""),app.start_race)
	start.name = "StartRace"
	start.custom_minimum_size.y = 70
	start.add_theme_font_size_override("font_size",28)
	start.disabled = app.blocked or not flow.can_start() or flow.screen == "start_pin"
	box.add_child(start)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",6)
	box.add_child(grid)
	for index in range(8):
		var player: Dictionary = app.session.players[index]
		var profile: Dictionary = app.session.player_profiles[index]
		var summary = app.button("",func(): app.select_player(index))
		summary.name = "PlayerSummary%d" % index
		summary.size_flags_horizontal = SIZE_EXPAND_FILL
		summary.custom_minimum_size = Vector2(150,92 if app.preferences.values.compact_stations else 122)
		summary.disabled = app.blocked or flow.settings_open or player.state == "PENDING PAYOUT"
		var color := Color(Identity.PALETTES[profile.color][1])
		var foreground := Color(Identity.PALETTES[profile.color][2])
		var highlighted: bool = index == flow.active_player or (player.state == "READY" and app.preferences.values.ready_highlight)
		for state in ["normal","hover","pressed","disabled"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("dbd4c2") if index != flow.active_player else Color("f6ebce")
			style.border_color = color
			style.set_border_width_all(4 if highlighted else 2)
			style.set_corner_radius_all(8)
			style.content_margin_left = 10
			style.content_margin_right = 10
			summary.add_theme_stylebox_override(state,style)
		var content := VBoxContainer.new()
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 10
		content.offset_right = -10
		content.offset_top = 7
		content.offset_bottom = -7
		content.mouse_filter = MOUSE_FILTER_IGNORE
		var name_plate := Banner.new()
		name_plate.configure(profile,player.nickname,44,app.scaled_font(16))
		name_plate.get_child(0).get_child(0).name = "SummaryAvatar%d" % index
		content.add_child(name_plate)
		var status_buttons := HBoxContainer.new()
		status_buttons.mouse_filter = MOUSE_FILTER_IGNORE
		status_buttons.alignment = BoxContainer.ALIGNMENT_END
		var ready_toggle = app.button("READY",func(): app.toggle_player_ready(index))
		ready_toggle.name = "ReadyToggle%d" % index
		ready_toggle.custom_minimum_size = Vector2(44,23)
		ready_toggle.add_theme_font_size_override("font_size",app.scaled_font(11))
		Sigma.indicator(ready_toggle,player.state == "READY")
		compact_button(ready_toggle)
		ready_toggle.disabled = summary.disabled or player.state == "OUT" or flow.screen == "start_pin" or app.session.virtual_config.seats[index].enabled
		status_buttons.add_child(ready_toggle)
		var out_toggle = app.button("OUT" if player.state == "OUT" else "IN",func(): app.toggle_player_out(index))
		out_toggle.name = "OutToggle%d" % index
		mark_in(out_toggle,index)
		compact_button(out_toggle)
		out_toggle.disabled = app.blocked or flow.settings_open or app.session.phase != "BETTING" or player.state == "PENDING PAYOUT"
		out_toggle.custom_minimum_size = Vector2(32,23)
		out_toggle.add_theme_font_size_override("font_size",app.scaled_font(12))
		out_toggle.tooltip_text = ("Click to join this race" if player.state == "OUT" else "Click to sit out and clear this race's wagers") if app.preferences.values.tooltips else ""
		status_buttons.add_child(out_toggle)
		status_buttons.add_child(virtual_button(index,false))
		if app.scaled_font(18) <= 22:
			name_plate.get_child(0).add_child(status_buttons)
		else:
			content.add_child(status_buttons)
		var win: int=app.session.last_display_win(index)
		var mini := MiniBets.new()
		mini.name = "BettingMini%d" % index
		mini.configure(player.bets,app.session.available(index),win,5,app.preferences.values.show_last_win,player.state != "BETTING",app.preferences.values.credit_label,app.preferences.values.show_totals)
		if app.session.virtual_config.seats[index].enabled: mini.show_simulation(win,player.bets)
		elif player.state == "PENDING PAYOUT": mini.show_pending(player.pending)
		content.add_child(mini)
		var bets: Array[String] = []
		for pair in player.bets: bets.append("%s:%d" % [pair,player.bets[pair]])
		summary.tooltip_text = "%s | %s\n%s" % [player.nickname,profile.avatar,"  ".join(bets)] if app.preferences.values.tooltips else ""
		summary.add_child(content)
		summary.custom_minimum_size.y = maxf(summary.custom_minimum_size.y,content.get_combined_minimum_size().y+14)
		content.minimum_size_changed.connect(func():
			summary.custom_minimum_size.y = maxf(92 if app.preferences.values.compact_stations else 122,content.get_combined_minimum_size().y+14))
		grid.add_child(summary)

func compact_button(control: Button) -> void:
	control.size_flags_vertical=SIZE_SHRINK_CENTER
	for state in ["normal","hover","pressed","hover_pressed","disabled"]:
		var style: StyleBoxFlat=control.get_theme_stylebox(state).duplicate()
		style.set_content_margin_all(2)
		style.shadow_size=1
		control.add_theme_stylebox_override(state,style)

func mark_in(control: Button, index: int) -> void:
	Sigma.indicator(control,app.session.players[index].state!="OUT")
	if app.session.virtual_config.seats[index].enabled:
		for state in ["normal","hover","pressed","hover_pressed","disabled"]:
			var style: StyleBoxFlat=control.get_theme_stylebox(state).duplicate()
			style.bg_color=Color("8edaff")
			style.border_color=Color("fff155") if state in ["hover","hover_pressed"] else Color("205a91")
			control.add_theme_stylebox_override(state,style)
		control.tooltip_text="V mode: click to cancel virtual play and go Out."

func virtual_button(index: int, large: bool) -> Button:
	var choice: int=app.session.virtual_choice(index)
	var count: int=app.session.virtual_config.styles.size()
	var caption: String="V" if choice==0 else ("V %d" % choice if choice<=count else ("VR1" if choice==count+1 else "VR2"))
	var control=app.button(caption,func(): app.cycle_virtual(index))
	control.name="PlayerVirtual" if large else "VirtualToggle%d" % index
	control.tooltip_text="V mode: off, styles 1-%d, VR1 (Random Fixed), VR2 (Random Each Race), off. Simulated wins do not affect credits." % count
	control.disabled=app.blocked or flow.settings_open or app.display_phase!="BETTING"
	Sigma.indicator(control,choice>0)
	compact_button(control)
	control.custom_minimum_size=Vector2(84,40) if large else Vector2(46,23)
	control.add_theme_font_size_override("font_size",15 if large else app.scaled_font(11))
	return control

func refresh_right() -> void:
	# Keep the active left console, input focus and any typed wager intact.
	var box := find_child("PlayerSummaries",true,false)
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
	build_right(box)

var _start_clock := 0.0
var _start_lit := false
func _process(delta: float) -> void:
	var start := find_child("StartRace",true,false)
	if start == null or start.disabled: return
	_start_clock+=delta
	var lit: bool=app.preferences.values.reduce_flashing or app.preferences.values.reduced_motion or fmod(_start_clock,1.2)<0.6
	if lit==_start_lit: return
	_start_lit=lit
	start.add_theme_stylebox_override("normal",Sigma.plate(Color("fff066") if lit else Sigma.GOLD,Color("fff9c4") if lit else Color("6f381c"),5))
