extends AcceptDialog
const SliderScale = preload("res://core/slider_scale.gd")
const PlayerSettings = preload("res://ui/player_settings.gd")
const SettingsStyle = preload("res://ui/settings_style.gd")
var flow: RefCounted
var on_return: Callable
var page_history: Array[int] = []
var feedback: Label
var preferences: RefCounted
var on_change: Callable
var container: VBoxContainer
var tabs: TabContainer
var profile_name: LineEdit
var profile_picker: OptionButton
var navigation: ItemList
var search: LineEdit
var rows: Array = []
var selected_category := 0
var search_results: VBoxContainer
var search_summary: Label
var search_index := -1
var search_origin := 0
var test_voice: Callable
var stop_voice: Callable
var help_requested: Callable
var game_action: Callable

func configure(settings: RefCounted, callback: Callable, controller: RefCounted = null, return_callback: Callable = Callable()) -> void:
	preferences = settings
	on_change = callback
	flow = controller
	on_return = return_callback
	theme = SettingsStyle.make(clampi(roundi(16.0*preferences.values.ui_scale*(1.15 if preferences.values.large_text else 1.0)),16,22))
	title = "Game Settings"
	size = Vector2i(1120,740)
	min_size = Vector2i(900,560)
	get_ok_button().text = "Return to Game"
	dialog_hide_on_ok = false
	confirmed.connect(return_to_game)
	canceled.connect(return_to_game)
	window_input.connect(func(event):
		if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F1:
			set_input_as_handled()
			open_help())
	if flow != null and flow.settings_player >= 0:
		selected_category = 1
	build()

func build() -> void:
	if container != null:
		remove_child(container)
		container.queue_free()
	container = VBoxContainer.new()
	# AcceptDialog owns child layout. Full-rect anchors create a resize feedback loop.
	container.custom_minimum_size = Vector2(850,500)
	add_child(container)
	var shortcuts := HFlowContainer.new()
	container.add_child(shortcuts)
	shortcuts.add_child(action_button("Back",go_back))
	shortcuts.add_child(action_button("Settings Home",func(): navigate(0)))
	shortcuts.add_child(action_button("Help  F1",open_section_help))
	if flow != null:
		shortcuts.add_child(action_button("Players and PINs",func(): navigate(1)))
		shortcuts.add_child(action_button("Manager PINs",func(): navigate(2)))
	if game_action.is_valid():
		for operation in ["New Game","Save Game","Load Game","Export Log"]:
			var action := action_button(operation,func(): game_action.call(operation))
			action.name=operation.replace(" ","")
			action.disabled=flow!=null and flow.session.phase in ["RACING","RESULTS"]
			action.tooltip_text="Available before or after a race. Settings profiles remain in Saved profiles."
			shortcuts.add_child(action)
	feedback = Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.add_theme_color_override("font_color",Color("a52431"))
	container.add_child(feedback)
	feedback.hide()
	var note := Label.new()
	# Autowrap needs a width before the dialog's first minimum-size negotiation.
	# Otherwise the one-character-wide initial label can expand the whole window.
	note.custom_minimum_size.x=800
	note.text = "Changes apply immediately. Player and PIN edits apply on Return to Game. Planned controls are dimmed."
	note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	container.add_child(note)
	search = LineEdit.new()
	search.placeholder_text = "Search all settings"
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.text_changed.connect(filter_rows)
	var browse := HBoxContainer.new()
	container.add_child(browse)
	browse.add_child(search)
	navigation = ItemList.new()
	navigation.name = "SettingsSection"
	navigation.custom_minimum_size.x = 235
	navigation.size_flags_vertical = Control.SIZE_EXPAND_FILL
	navigation.add_theme_constant_override("v_separation",10)
	navigation.tooltip_text = "Choose a settings section"
	var workspace := HBoxContainer.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	workspace.add_theme_constant_override("separation",18)
	container.add_child(workspace)
	workspace.add_child(navigation)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.tabs_visible = false
	workspace.add_child(tabs)
	rows.clear()
	navigation.item_selected.connect(navigate)
	var home := special_page("Settings Home")
	if flow != null:
		var players_page := special_page("Players and PINs")
		var player_editor := PlayerSettings.new()
		players_page.add_child(player_editor)
		player_editor.configure(flow)
		build_manager(special_page("Manager PINs"))
	build_profiles(special_page("Saved profiles"))
	if flow!=null:
		var virtual_page := special_page("Virtual player styles")
		var virtual_editor := preload("res://ui/virtual_settings.gd").new()
		virtual_page.add_child(virtual_editor)
		virtual_editor.configure(flow)
		virtual_page.add_child(action_button("Help with virtual styles", func(): request_help("Virtual player styles")))
	var categories := {}
	for item in preferences.catalog:
		if flow!=null and item.category in ["Virtual players","Virtual style factors"]: continue
		if not categories.has(item.category):
			var scroll := ScrollContainer.new()
			scroll.name = item.category
			scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			tabs.add_child(scroll)
			navigation.add_item(item.category)
			var list := VBoxContainer.new()
			list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			list.add_theme_constant_override("separation",3)
			scroll.add_child(list)
			categories[item.category] = list
			if item.category=="Race Control":
				var control_note := Label.new()
				control_note.name="RaceControlNotice"
				control_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
				control_note.text="Pacing applies from start to finish without changing winning chances. Set both pacing sliders to True random for original movement. Replay target is the approximate share of races reviewed for a close second place. Travel and duration are on the Replay page."
				list.add_child(control_note)
			elif item.category=="Replay":
				var replay_note := Label.new()
				replay_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
				replay_note.text="Travel sets how many horse lengths the second-place horse covers. Duration sets how slowly you see that recorded movement. These two controls do not change replay frequency. All five horses remain in frame, and the replay stops when second place reaches the tape."
				list.add_child(replay_note)
		var row := setting_row(item)
		categories[item.category].add_child(row)
		rows.append({"node":row,"parent":categories[item.category],"text":(item.label+" "+item.key+" "+item.category).to_lower()})
	var voice_actions := HFlowContainer.new()
	categories["Announcers"].add_child(voice_actions)
	for role in ["race","house"]:
		var test_button := action_button("Test "+role+" voice",func():
			if test_voice.is_valid(): test_voice.call(role))
		test_button.name="Test"+role.capitalize()+"Voice"
		test_button.disabled=not test_voice.is_valid()
		voice_actions.add_child(test_button)
	voice_actions.add_child(action_button("Stop sample",func():
		if stop_voice.is_valid(): stop_voice.call()))
	var voice_note := Label.new()
	voice_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	voice_note.text="Two voices with blended humor, wit, energy and detail. Speed adjusts automatically to fit each call, up to 1.6x. The tested setup sits at the midpoint; the upper half adds shorter, more frequent calls. Betting stays silent."
	if preload("res://ui/speech_backend.gd").new().voices().is_empty():
		voice_note.text="No system voices available. Subtitles still work. Install or configure a system speech voice and restart the game."
	categories["Announcers"].add_child(voice_note)
	var first_rows := ["race_voice","house_voice","race_talk","house_talk","speech_gap","subtitles","subtitle_size"]
	for i in range(first_rows.size()):
		categories["Announcers"].move_child(find_child("Setting_"+first_rows[i],true,false),i)
	categories["Announcers"].move_child(voice_note,0)
	categories["Announcers"].move_child(voice_actions,0)
	build_home(home)
	var support_page:=special_page("Optional support")
	support_page.add_child(preload("res://ui/support_panel.gd").new())
	search_results = special_page("Search results")
	search_index = tabs.get_tab_count()-1
	search_summary = Label.new()
	search_summary.text = "Type in Search all settings to find a control."
	search_results.add_child(search_summary)
	selected_category = mini(selected_category,tabs.get_tab_count()-1)
	navigation.select(selected_category)
	tabs.current_tab = selected_category

func build_profiles(list: VBoxContainer) -> void:
	var description := Label.new()
	description.text = "Save a named set of preferences, then load it whenever you like."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_child(description)
	var profile_row := HFlowContainer.new()
	list.add_child(profile_row)
	profile_name = LineEdit.new()
	profile_name.placeholder_text = "New profile name"
	profile_name.custom_minimum_size.x = 170
	profile_name.max_length = 40
	profile_row.add_child(profile_name)
	var save_button := Button.new()
	save_button.text = "Save profile"
	save_button.pressed.connect(func():
		var requested := profile_name.text.strip_edges()
		if preferences.profiles.has(requested):
			confirm_action("Replace saved profile " + requested + "?",func(): save_named_profile(requested))
		else:
			save_named_profile(requested))
	profile_row.add_child(save_button)
	profile_picker = OptionButton.new()
	profile_picker.custom_minimum_size.x = 170
	profile_row.add_child(profile_picker)
	refresh_profiles()
	var load_button := Button.new()
	load_button.text = "Load profile"
	load_button.pressed.connect(func():
		if profile_picker.item_count > 0 and preferences.load_profile(profile_picker.get_item_text(profile_picker.selected)):
			on_change.call()
			build())
	profile_row.add_child(load_button)
	profile_row.add_child(action_button("Rename",func():
		if profile_picker.item_count > 0:
			if preferences.rename_profile(chosen_profile(),profile_name.text.strip_edges()):
				on_change.call()
				refresh_profiles()
			else:
				show_message("Type a new, unused profile name before choosing Rename.")))
	profile_row.add_child(action_button("Delete",func():
		if profile_picker.item_count > 0:
			var selected := chosen_profile()
			confirm_action("Delete profile " + selected + "?",func():
				preferences.delete_profile(selected)
				on_change.call()
				refresh_profiles())))
	var utility := HFlowContainer.new()
	list.add_child(utility)
	utility.add_child(action_button("Import profile",import_file))
	utility.add_child(action_button("Export profile",export_file))

func build_home(home: VBoxContainer) -> void:
	var heading := Label.new()
	heading.text = "Choose a section on the left, search, or open a common section:"
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	home.add_child(heading)
	var common := GridContainer.new()
	common.columns = 3
	common.add_theme_constant_override("h_separation",10)
	common.add_theme_constant_override("v_separation",10)
	home.add_child(common)
	for caption in ["Display","Race Playback","Audio","Controls","Modes and skins","Performance"]:
		var link := action_button(caption,func():
			for i in range(navigation.item_count):
				if navigation.get_item_text(i) == caption: navigate(i))
		link.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		common.add_child(link)
	var heading_defaults := Label.new()
	heading_defaults.text = "Restore defaults"
	home.add_child(heading_defaults)
	var reset_row := HFlowContainer.new()
	home.add_child(reset_row)
	var category := OptionButton.new()
	category.name = "DefaultsCategory"
	category.custom_minimum_size.x = 270
	category.fit_to_longest_item = false
	var names := []
	for item in preferences.catalog:
		if not item.category in names:
			names.append(item.category)
			category.add_item(item.category)
	reset_row.add_child(category)
	reset_row.add_child(action_button("Restore section",func(): confirm_reset(category.get_item_text(category.selected))))
	reset_row.add_child(action_button("Reset to Original Settings",func(): confirm_reset("")))
	var note := Label.new()
	note.text = "Review the changes before confirming. Saved profiles, players, PINs, balances and wagers are kept."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	home.add_child(note)
	if flow != null:
		home.add_child(action_button("Revert this visit",func():
			confirm_action("Undo this Settings visit? General preferences and player edits return to their opening values. New PIN edits are discarded. Existing balances and wagers are kept.",func():
				flow.revert_settings()
				on_change.call()
				build())))

func display_value(item: Dictionary, value: Variant) -> String:
	if item.type == "bool": return "On" if value else "Off"
	if item.type == "number": return readable_value(item,float(value))
	return str(value)

func confirm_reset(category: String) -> void:
	var changes: Array[String] = []
	for item in preferences.catalog:
		if (category.is_empty() or item.category == category) and preferences.values[item.key] != item.default:
			changes.append("%s: %s -> %s" % [item.label,display_value(item,preferences.values[item.key]),display_value(item,item.default)])
	var scope := "all general settings" if category.is_empty() else category
	var caption := "Restore %s to defaults?\n%d preferences will change. Saved profiles, players, PINs, balances and wagers are kept." % [scope,changes.size()]
	var dialog := confirm_action(caption,func():
		if category.is_empty(): preferences.reset_all()
		else: preferences.reset_category(category)
		on_change.call()
		build(),"\n".join(changes) if not changes.is_empty() else "These preferences are already at their defaults.")
	dialog.name = "ResetConfirmation"

func setting_row(item: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Setting_"+item.key
	row.set_meta("help_context", item.key)
	row.custom_minimum_size.y = 34
	row.add_theme_constant_override("separation",10)
	var active := implemented(item.key)
	row.tooltip_text = item.category + (". Planned feature. This control does not affect the game yet." if not active else "")
	var label := Label.new()
	label.text = item.label + ("  [Planned]" if not active else "")
	label.size_flags_horizontal = Control.SIZE_FILL
	label.custom_minimum_size.x = 245
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	if item.key=="unlimited_profiles":
		var available:=Label.new()
		available.text="Available; no fixed count limit"
		row.add_child(available)
	elif item.type == "bool":
		var toggle := CheckButton.new()
		toggle.button_pressed = preferences.values[item.key]
		toggle.disabled = not active
		toggle.toggled.connect(func(value): change(item.key,value))
		toggle.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		row.add_child(toggle)
	elif item.type == "choice":
		var choice := OptionButton.new()
		choice.custom_minimum_size.x = 180
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.fit_to_longest_item = false
		var options: Array=item.limits.duplicate()
		if item.key in ["race_voice","house_voice"]:
			options=["Automatic race","Automatic female","Voice 1","Voice 2","Voice 3"]
			for alias in options: choice.add_item(alias if alias.begins_with("Automatic") else "Installed "+alias.to_lower())
			for voice in preload("res://ui/speech_backend.gd").new().voices():
				options.append(voice.id)
				choice.add_item(voice.name+" ("+voice.language+")")
			if not preferences.values[item.key] in options:
				options.append(preferences.values[item.key])
				choice.add_item("Unavailable voice (automatic fallback)")
		else:
			for option in options: choice.add_item(option)
		choice.select(options.find(preferences.values[item.key]))
		choice.disabled = not active
		choice.item_selected.connect(func(index): change(item.key,options[index]))
		row.add_child(choice)
	else:
		var slider := HSlider.new()
		slider.name = "VolumeSlider" if item.key.ends_with("_volume") else "ValueSlider"
		slider.custom_minimum_size.x = 120
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.min_value = 0.0 if item.has("center") else item.limits[0]
		slider.max_value = 1.0 if item.has("center") else item.limits[1]
		slider.step = 0.005 if item.has("center") else item.limits[2]
		slider.value = SliderScale.to_position(item,float(preferences.values[item.key]))
		if item.has("center"):
			slider.tick_count=3
			slider.ticks_on_borders=true
		slider.editable = active
		slider.focus_mode = Control.FOCUS_ALL if active else Control.FOCUS_NONE
		slider.tooltip_text = "From %s to %s. Arrow keys make small adjustments." % [readable_value(item,item.limits[0]),readable_value(item,item.limits[1])]
		if personality_key(item.key) or item.category=="Race Control":
			var blend := VBoxContainer.new()
			blend.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			row.add_child(blend)
			blend.add_child(slider)
			var ends := HBoxContainer.new()
			blend.add_child(ends)
			var captions: Array
			if item.category=="Race Control":
				captions=["1%","30%"] if item.key=="photo_frequency" else ["True random","More exciting" if item.key=="race_lead_changes" else "More separation"]
			else:
				captions={"humor":["Serious","Humorous"],"sarcasm":["Sincere","Dry wit"],"energy":["Calm","Excited"],"detail":["Brief","Descriptive"]}[item.key.get_slice("_",1)]
			for i in range(2):
				var endpoint := Label.new()
				endpoint.text=captions[i]
				endpoint.size_flags_horizontal=Control.SIZE_EXPAND_FILL
				endpoint.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT if i==0 else HORIZONTAL_ALIGNMENT_RIGHT
				endpoint.add_theme_font_size_override("font_size",12)
				ends.add_child(endpoint)
			slider.tooltip_text="Changes the pace pattern without changing finish results. Combines with the other Race Control slider." if item.category=="Race Control" else "Independent personality blend. Combines with the other sliders; does not change race results."
			if item.key=="photo_frequency": slider.tooltip_text="Approximate replay frequency across many races. Twenty percent is at the midpoint. Only the second/third gap is considered; race results do not change."
		else: row.add_child(slider)
		var amount := Label.new()
		amount.name = "ReadableValue"
		amount.custom_minimum_size.x = 80
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var show_amount: bool=item.key=="photo_frequency" or (not personality_key(item.key) and item.category!="Race Control")
		amount.text = readable_value(item,float(preferences.values[item.key])) if show_amount else ""
		row.add_child(amount)
		slider.value_changed.connect(func(value):
			var actual: float=SliderScale.from_position(item,value)
			amount.text = readable_value(item,actual) if show_amount else ""
			change(item.key,actual))
		if item.has("center"):
			slider.gui_input.connect(func(event):
				if not slider.editable or not event is InputEventKey or not event.pressed: return
				var next: float=float(preferences.values[item.key])
				match event.keycode:
					KEY_LEFT, KEY_DOWN: next-=float(item.limits[2])
					KEY_RIGHT, KEY_UP: next+=float(item.limits[2])
					KEY_HOME: next=float(item.limits[0])
					KEY_END: next=float(item.limits[1])
					_: return
				next=clampf(next,float(item.limits[0]),float(item.limits[1]))
				slider.set_value_no_signal(SliderScale.to_position(item,next))
				amount.text=readable_value(item,next) if show_amount else ""
				change(item.key,next)
				slider.accept_event())
	var help_button := action_button("?", func(): request_help(item.key))
	help_button.name = "SettingHelp"
	help_button.custom_minimum_size.x = 36
	help_button.tooltip_text = "Help for " + item.label
	row.add_child(help_button)
	if not active:
		for child in row.get_children():
			if child != help_button:
				child.modulate = Color(0.65, 0.65, 0.65)
	return row

func readable_value(item: Dictionary, value: float) -> String:
	var key: String = item.key
	if key=="replay_lengths": return "%s lengths" % String.num(value,1)
	if key.ends_with("_speech_rate"): return "%s x" % String.num(0.5+value,2)
	if key.ends_with("_seconds") or key in ["speech_gap","tooltip_delay"]:
		return "%s s" % String.num(value,2)
	if key == "background_fps": return "%d FPS" % roundi(value)
	if key == "photo_frequency": return "%d%% target" % roundi(value)
	if key == "lane_spacing" or key == "finish_line_width": return "%s px" % String.num(value,0)
	if key in ["subtitle_size"]: return "%d pt" % roundi(value)
	if key == "denomination": return "%s / credit" % String.num(value,2)
	if key in ["virtual_min_odds","virtual_max_odds"]: return "%d x" % roundi(value)
	if item.limits[2] < 1.0 and item.limits[1] <= 2.0:
		return "%d%%" % roundi(value*100.0)
	return String.num(value,0 if item.default is int else 2)

func special_page(caption: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = caption
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	tabs.add_child(scroll)
	navigation.add_item(caption)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation",10)
	scroll.add_child(list)
	return list

func navigate(index: int) -> void:
	if index < 0 or index >= tabs.get_tab_count(): return
	search.set_text("")
	filter_rows("")
	if index != selected_category: page_history.append(selected_category)
	selected_category = index
	tabs.current_tab = index
	navigation.select(index)


func go_back() -> void:
	var previous: int = 0 if page_history.is_empty() else page_history.pop_back()
	search.set_text("")
	filter_rows("")
	selected_category = previous
	tabs.current_tab = previous
	navigation.select(previous)


func focus_context() -> void:
	if flow != null and flow.settings_player >= 0:
		navigate(1)
		var pin := find_child("NewPin%d" % flow.settings_player,true,false)
		if pin != null:
			pin.grab_focus()

func return_to_game() -> void:
	if flow == null:
		hide()
		return
	if not flow.finish_settings():
		feedback.text = flow.error
		feedback.show()
		if not visible:
			popup_centered.call_deferred()
		focus_context.call_deferred()
		return
	hide()
	if on_return.is_valid():
		on_return.call()
	queue_free()

func build_manager(list: VBoxContainer) -> void:
	var note := Label.new()
	note.text = "All new PINs have four digits. Enter twice to replace a PIN.\nBlank fields keep the existing PIN. Changes finish on Return to Game."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_child(note)
	var start := CheckButton.new()
	start.text = "Manager Only Can Start Race"
	start.button_pressed = flow.manager_only
	start.toggled.connect(func(value): flow.manager_only = value)
	list.add_child(start)
	var countdown := SpinBox.new()
	countdown.prefix = "Optional countdown (0 = off): "
	countdown.max_value = 10
	countdown.value = flow.countdown
	countdown.value_changed.connect(func(value): flow.countdown = int(value))
	list.add_child(countdown)
	for entry in [["operator","Settings PIN"],["start","Manager Start PIN"],["rtp","Hidden Payout PIN"]]:
		var domain: String = entry[0]
		var title_label := Label.new()
		title_label.text = entry[1]
		list.add_child(title_label)
		var first := LineEdit.new()
		first.secret = true
		first.max_length = 4
		first.placeholder_text = "New four-digit PIN"
		first.text = flow.manager_pins[domain].pin
		first.text_changed.connect(func(value): flow.manager_pins[domain].pin = value)
		list.add_child(first)
		var second := LineEdit.new()
		second.secret = true
		second.max_length = 4
		second.placeholder_text = "Enter it again"
		second.text = flow.manager_pins[domain].confirm
		second.text_changed.connect(func(value): flow.manager_pins[domain].confirm = value)
		list.add_child(second)

func implemented(key: String) -> bool:
	if key in ["race_spread","race_lead_changes","replay_lengths","bell_seconds","photo_frequency"]: return true
	if personality_key(key) or key in ["replay_seconds","nose_guides","guide_opacity","unlimited_profiles"]: return true
	if key in ["start_signal","start_signal_volume"]: return true
	if key in ["race_voice","house_voice","race_volume","house_volume","race_mute","house_mute","race_talk","house_talk","subtitles","subtitle_size","speech_gap"]: return true
	if key == "win_volume": return true
	if key in ["master_volume","mechanical_enabled","mechanical_volume","hoof_enabled","hoof_volume","horse_scale","lane_spacing","cabinet_lights","light_intensity","reduce_flashing","reduced_motion","photo_numbers"]:
		return true
	return key in ["window_mode","resolution","ui_scale","palette","background_style","show_clock","show_firmware","show_round","race_seconds","post_finish_seconds","horse_animation","animation_frames","stepping_strength","show_horse_numbers","number_size","finish_line_width","zoom","camera_height","photo_threshold","replay_events","slow_motion","photo_hold_seconds","photo_monochrome","photo_highlight","credit_label","compact_stations","show_totals","show_last_win","confirm_clear","ready_highlight","bet_increment","wheel_betting","tooltips","tooltip_delay","keyboard_navigation","large_text","large_targets","focus_outline","always_numbers","colorblind_mode","inactivity_enabled","inactivity_seconds","reminder_text","frame_limit","vsync","background_fps"]

func change(key: String, value: Variant) -> void:
	if preferences.set_value(key,value):
		on_change.call()

func refresh_profiles() -> void:
	profile_picker.clear()
	for key in preferences.profiles:
		profile_picker.add_item(key)

func chosen_profile() -> String:
	return profile_picker.get_item_text(profile_picker.selected)

func action_button(caption: String, callback: Callable) -> Button:
	var control := Button.new()
	control.text = caption
	control.pressed.connect(callback)
	return control

func save_named_profile(requested: String) -> void:
	if preferences.save_profile(requested):
		on_change.call()
		refresh_profiles()
	else:
		show_message("Use a profile name of 1 to 40 characters.")

func personality_key(key: String) -> bool:
	return key in ["race_humor","race_sarcasm","race_energy","race_detail","house_humor","house_sarcasm","house_energy","house_detail"]

func open_help() -> void:
	var focused := control_help_context(gui_get_focus_owner())
	var hovered := control_help_context(gui_get_hovered_control())
	if not hovered.is_empty():
		request_help(hovered)
	elif not focused.is_empty():
		request_help(focused)
	else:
		open_section_help()

func control_help_context(control: Node) -> String:
	while control != null and control != self:
		if control.has_meta("help_context"):
			return str(control.get_meta("help_context"))
		if str(control.name).begins_with("VirtualFactor_"):
			return str(control.name)
		control = control.get_parent()
	return ""

func open_section_help() -> void:
	request_help(navigation.get_item_text(tabs.current_tab))

func request_help(context: String) -> void:
	if help_requested.is_valid():
		help_requested.call(context)

func filter_rows(query: String) -> void:
	var cleaned := query.strip_edges().to_lower()
	var searching := not cleaned.is_empty()
	if searching and tabs.current_tab != search_index:
		search_origin = selected_category
	var matches := 0
	for row in rows:
		var matched: bool = searching and cleaned in row.text
		var destination: Node = search_results if matched else row.parent
		if row.node.get_parent() != destination: row.node.reparent(destination)
		row.node.visible = not searching or matched
		if matched: matches += 1
	# Restore catalog order after repeated searches.
	for row in rows:
		if row.node.get_parent() == row.parent:
			row.parent.move_child(row.node,-1)
	if not searching:
		var page= tabs.get_node_or_null("Announcers")
		if page!=null:
			var first_rows := ["race_voice","house_voice","race_talk","house_talk","speech_gap","subtitles","subtitle_size"]
			for i in range(first_rows.size()):
				page.get_child(0).move_child(find_child("Setting_"+first_rows[i],true,false),i+2)
	if searching:
		search_summary.text = "%d matching settings across all categories" % matches
		tabs.current_tab = search_index
		navigation.select(search_index)
	elif tabs.current_tab == search_index:
		tabs.current_tab = search_origin
		navigation.select(search_origin)
		search_summary.text = "Type in Search all settings to find a control."

func confirm_action(caption: String, callback: Callable, details: String = "") -> ConfirmationDialog:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = caption
	dialog.dialog_autowrap = true
	dialog.min_size = Vector2i(650,180)
	if not details.is_empty():
		# AcceptDialog places custom controls over its built-in text label.
		# Keep both pieces in one container so they flow instead of overlapping.
		dialog.dialog_text = ""
		var content := VBoxContainer.new()
		content.custom_minimum_size.x = 620
		content.add_theme_constant_override("separation",12)
		dialog.add_child(content)
		var summary := Label.new()
		summary.name = "ResetSummary"
		summary.custom_minimum_size.x = 620
		summary.size.x = 620
		summary.text = caption
		summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(summary)
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(620,220)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		content.add_child(scroll)
		var description := Label.new()
		description.text = details
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(description)
	add_child(dialog)
	dialog.confirmed.connect(func():
		callback.call()
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()
	return dialog

func show_message(caption: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.dialog_text = caption
	dialog.min_size = Vector2i(500,170)
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.popup_centered()

func export_file() -> void:
	if profile_picker.item_count == 0:
		show_message("Save a profile first, then select it for export.")
		return
	var profile_data: Dictionary = preferences.export_profile(chosen_profile())
	var dialog := preload("res://ui/file_picker.gd").make()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json ; Settings profile"])
	dialog.current_file = "sigma-settings.json"
	dialog.file_selected.connect(func(path):
		var file := FileAccess.open(path,FileAccess.WRITE)
		if file == null:
			show_message("Could not write this profile. Choose a writable folder.")
		else:
			file.store_string(JSON.stringify(profile_data,"  "))
			file.flush()
			var status := file.get_error()
			file.close()
			if status != OK:
				show_message("Profile write did not finish successfully.")
		dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered_ratio(0.75)

func import_file() -> void:
	var requested := profile_name.text.strip_edges()
	if not preferences.valid_profile_name(requested):
		show_message("Type a name for the imported profile in New profile name first.")
		return
	var dialog := preload("res://ui/file_picker.gd").make()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json ; Settings profile"])
	dialog.file_selected.connect(func(path):
		var file := FileAccess.open(path,FileAccess.READ)
		if file == null or file.get_length() > 1048576:
			show_message("Profile is unreadable or larger than 1 MiB.")
			dialog.queue_free()
			return
		var parser := JSON.new()
		var result := parser.parse(file.get_as_text())
		file.close()
		if result != OK or not parser.data is Dictionary:
			show_message("This file is not a valid settings profile.")
		else:
			var import_action := func():
				if preferences.import_profile(requested,parser.data):
					on_change.call()
					refresh_profiles()
				else:
					show_message("Profile settings failed validation. Current settings were preserved.")
			if preferences.profiles.has(requested):
				confirm_action("Replace saved profile " + requested + "?",import_action)
			else:
				import_action.call()
		dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered_ratio(0.75)
