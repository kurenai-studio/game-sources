extends RefCounted
## General preferences only. Economic and operator controls live in separate domains.
var catalog: Array = []
var values := {}
var profiles := {}
var added_keys: Array[String] = []

func _init() -> void:
	add("Display","window_mode","Window mode","choice","Windowed",["Windowed","Maximized","Fullscreen"])
	add("Display","resolution","Window resolution","choice","1440 x 900",["1280 x 720","1440 x 900","1920 x 1080","2560 x 1440"])
	add("Display","ui_scale","Interface scale","number",1.0,[0.75,1.75,0.05])
	add("Display","palette","Color style","choice","Original",["Original","Enhanced","High contrast","Muted"])
	add("Display","brightness","Brightness","number",1.0,[0.5,1.5,0.05])
	add("Display","contrast","Contrast","number",1.0,[0.5,1.5,0.05])
	add("Display","show_firmware","Show firmware version","bool",true)
	add("Display","show_clock","Show clock","bool",false)
	add("Display","show_round","Show race number","bool",true)
	add("Display","cabinet_lights","Cabinet lights","bool",true)
	add("Display","light_intensity","Cabinet light intensity","number",0.7,[0.0,1.0,0.05])
	add("Display","background_style","Betting background","choice","Classic",["Classic","Dark","Minimal"])
	add("Race Control","race_lead_changes","Lead changes","number",0.5,[0.0,1.0,0.05])
	add("Race Control","race_spread","Average field separation","number",1.0,[0.0,1.5,0.05])
	add("Race Control","photo_frequency","Photo-finish target","number",20,[1,30,1])
	add("Race Playback","race_seconds","Nominal race duration, seconds","number",35.0,[10.0,120.0,1.0])
	add("Race Playback","post_finish_seconds","Post-finish movement, seconds","number",2.5,[2.0,3.0,0.1])
	add("Race Playback","horse_animation","Mechanical horse animation","bool",true)
	add("Race Playback","horse_scale","Mechanical horse size","number",1.55,[1.0,2.0,0.05])
	add("Race Playback","lane_spacing","Visual lane spacing","number",56.0,[40.0,68.0,2.0])
	add("Race Playback","animation_frames","Horse animation frames","number",4,[3,4,1])
	add("Race Playback","stepping_strength","Mechanical stepping strength","number",0.5,[0.0,1.0,0.05])
	add("Race Playback","show_horse_numbers","Show horse numbers","bool",true)
	add("Race Playback","number_size","Horse number scale","number",1.0,[0.75,2.0,0.05])
	add("Race Playback","leader_indicator","Leader indicator","bool",false)
	add("Race Playback","position_strip","Running order strip","bool",true)
	add("Race Playback","nose_guides","Horse-colored position guides","bool",true)
	add("Race Playback","guide_opacity","Position guide brightness","number",0.25,[0.05,0.6,0.05])
	add("Race Playback","finish_line_width","Finish line width","number",3,[1,8,1])
	add("Camera","camera_mode","Camera direction","choice","Automatic",["Automatic","Seated fixed","Finish fixed","Follow contest"])
	add("Camera","camera_height","Seated camera height","number",1.0,[0.6,1.5,0.05])
	add("Camera","zoom","Camera zoom","number",1.0,[0.65,1.7,0.05])
	add("Camera","pan_speed","Camera movement speed","number",0.6,[0.1,1.5,0.05])
	add("Camera","transition_seconds","Camera transition, seconds","number",1.2,[0.0,3.0,0.1])
	add("Camera","camera_cuts","Allow cinematic cuts","bool",true)
	add("Camera","picture_in_picture","Runaway leader picture in picture","bool",true)
	add("Camera","pip_position","Picture in picture position","choice","Top right",["Top right","Top left","Bottom right","Bottom left"])
	add("Camera","pip_scale","Picture in picture size","number",0.25,[0.15,0.4,0.01])
	add("Camera","follow_priority","Follow priority","choice","Second-place contest",["Second-place contest","Leading group","Wide field"])
	add("Replay","replay_seconds","Photo replay duration","number",5.0,[1.0,10.0,0.5])
	add("Replay","replay_lengths","Replay travel, horse lengths","number",1.0,[0.5,3.0,0.1])
	add("Replay","photo_hold_seconds","Photo decision hold, seconds","number",4.0,[1.0,15.0,0.5])
	add("Replay","photo_monochrome","Monochrome photo finish","bool",true)
	add("Replay","photo_numbers","Enlarge photo numbers","bool",true)
	add("Replay","photo_highlight","Highlight second-place horse","bool",true)
	add("Replay","photo_include_trailers","Include nearby fourth and fifth","bool",true)
	add("Replay","manual_replay","Offer replay after results","bool",true)
	add("Audio","master_volume","Master volume","number",0.8,[0.0,1.0,0.05])
	add("Audio","race_mute","Mute race announcer","bool",false)
	add("Audio","house_mute","Mute house announcer","bool",false)
	add("Audio","race_volume","Race announcer volume","number",0.85,[0.0,1.0,0.05])
	add("Audio","house_volume","House announcer volume","number",0.65,[0.0,1.0,0.05])
	add("Audio","music_enabled","Music enabled","bool",true)
	add("Audio","music_volume","Music volume","number",0.3,[0.0,1.0,0.05])
	add("Audio","music_style","Music style","choice","Classic arcade",["Classic arcade","Lounge","None"])
	add("Audio","start_signal","Race start signal","choice","Bell",["Bell","Horn","Horn and bell","Off"])
	add("Audio","bell_seconds","School bell duration","number",0.5,[0.1,1.0,0.05])
	add("Audio","start_signal_volume","Start signal volume","number",0.65,[0.0,1.0,0.05])
	add("Audio","mechanical_enabled","Mechanical sounds","bool",true)
	add("Audio","mechanical_volume","Mechanical volume","number",0.45,[0.0,1.0,0.05])
	add("Audio","ui_sounds","Button sounds","bool",true)
	add("Audio","ui_volume","Button sound volume","number",0.35,[0.0,1.0,0.05])
	add("Audio","win_volume","Win celebration volume","number",0.7,[0.0,1.0,0.05])
	add("Audio","duck_music","Lower music during speech","bool",true)
	add("Announcers","race_talk","Race talkativeness","number",0.5,[0.0,1.0,0.05])
	add("Announcers","house_talk","House talkativeness","number",0.25,[0.0,1.0,0.05])
	add("Announcers","teasing","Playful teasing","number",0.2,[0.0,1.0,0.05])
	add("Announcers","use_nicknames","Say player nicknames","bool",true)
	add("Announcers","recognition","Player recognition frequency","number",0.15,[0.0,1.0,0.05])
	add("Announcers","comic_trailers","Occasional trailing-horse humor","bool",true)
	add("Announcers","history_comments","Comments based on betting history","bool",true)
	add("Announcers","subtitles","Announcer subtitles","bool",true)
	add("Announcers","subtitle_size","Subtitle font size","number",22,[16,40,1])
	add("Announcers","speech_gap","Minimum gap between voices, seconds","number",0.8,[0.25,3.0,0.05])
	add("Players","credit_label","Credit label","choice","Credits",["Credits","Points","Tokens"])
	add("Players","compact_stations","Compact player stations","bool",true)
	add("Players","show_totals","Show total wager per station","bool",true)
	add("Players","show_last_win","Show previous win","bool",true)
	add("Players","confirm_clear","Confirm clearing all wagers","bool",true)
	add("Players","remember_nicknames","Remember nicknames","bool",true)
	add("Players","ready_highlight","Highlight ready stations","bool",true)
	add("Controls","bet_increment","Wager arrow increment","number",1,[1,5,1])
	add("Controls","wheel_betting","Mouse wheel wager changes","bool",false)
	add("Controls","keyboard_navigation","Keyboard navigation","bool",true)
	add("Controls","tooltips","Show tooltips","bool",true)
	add("Controls","tooltip_delay","Tooltip delay, seconds","number",0.7,[0.0,2.0,0.1])
	add("Controls","haptics","Controller haptics when supported","bool",false)
	add("Controls","haptic_strength","Haptic strength","number",0.3,[0.0,1.0,0.05])
	add("Accessibility","large_text","Larger interface text","bool",false)
	add("Accessibility","reduced_motion","Reduced camera and UI motion","bool",false)
	add("Accessibility","reduce_flashing","Reduce flashing lights","bool",false)
	add("Accessibility","colorblind_mode","Color accessibility","choice","Standard",["Standard","Deuteranopia","Protanopia","Tritanopia","Monochrome"])
	add("Accessibility","focus_outline","Strong keyboard focus outline","bool",true)
	add("Accessibility","always_numbers","Always identify horses by number","bool",true)
	add("Accessibility","large_targets","Larger button targets","bool",false)
	add("Reminders","inactivity_enabled","Single inactivity reminder","bool",true)
	add("Reminders","inactivity_seconds","Inactivity delay, seconds","number",60.0,[30.0,300.0,5.0])
	add("Reminders","reminder_text","Show reminder text","bool",true)
	add("Performance","frame_limit","Frame rate limit","choice","60",["30","60","120","144","Unlimited"])
	add("Performance","vsync","Vertical synchronization","bool",true)
	add("Performance","antialiasing","Smooth edges","bool",true)
	add("Performance","background_fps","Unfocused frame rate","number",15,[5,60,1])
	add("Logging","trace_sample_percent","Detailed race trace sampling, percent","number",1,[0,100,1])
	add("Logging","anomaly_traces","Keep anomalous race traces","bool",true)
	add("Logging","camera_events","Log significant camera events","bool",true)
	add("Logging","announcer_events","Log announcer events","bool",true)
	var additions: Array = [
		["Audio","hoof_enabled","Hoofbeat sound","bool",true,[]],
		["Audio","hoof_volume","Hoofbeat volume","number",0.55,[0.0,1.0,0.05]],
		["Modes and skins","presentation_mode","Presentation preset","choice","SD mode",["SD mode","Live Track","Off-Track TV"]],
		["Modes and skins","operating_preset","Operating preset","choice","Fun",["Fun","Protected Table"]],
		["Modes and skins","single_player","Single-player fun mode","bool",true,[]],
		["Modes and skins","horse_style","Horse appearance","choice","Mechanical",["Mechanical","Cartoon realistic","Detailed realistic","Simple silhouettes"]],
		["Modes and skins","console_style","Betting-console skin","choice","Machine",["Machine","Track window","Off-track terminal","Minimal"]],
		["Modes and skins","track_surface","Track surface","choice","Classic tan",["Classic tan","Dirt","Turf","Synthetic","Night track"]],
		["Modes and skins","cabinet_palette","Cabinet color scheme","choice","Gold and burgundy",["Gold and burgundy","Brushed silver","Dark wood","Custom colors"]],
		["Modes and skins","custom_cabinet_color","Custom cabinet color","choice","Preset",["Preset","Custom color picker"]],
		["Modes and skins","custom_track_color","Custom track color","choice","Preset",["Preset","Custom color picker"]],
		["Modes and skins","custom_infield_color","Custom infield color","choice","Preset",["Preset","Custom color picker"]],
		["Modes and skins","custom_rail_color","Custom rail color","choice","Preset",["Preset","Custom color picker"]],
		["Modes and skins","lighting_preset","Lighting preset","choice","Indoor",["Indoor","Daylight","Dusk","Night"]],
		["Performance","quality_preset","Computer performance preset","choice","Balanced",["Low power","Balanced","High detail","Automatic test"]],
		["Performance","match_horse_quality","Match horse detail to computer","bool",true,[]],
		["Performance","av_preview","Audio and visual performance sample","choice","Not run",["Not run","Run sample test"]],
		["Profiles and previews","sample_race","Settings-only sample race","choice","Not running",["Not running","Preview current settings"]],
		["Profiles and previews","unlimited_profiles","Unlimited named settings profiles","bool",true,[]],
		["Profiles and previews","save_game_slots","Named game saves","choice","Current session",["Current session","Choose save slot"]],
		["Profiles and previews","preview_audio","Test selected audio and announcers","choice","Silent",["Silent","Play sample"]],
		["Wager types","enable_win","Single horse: Win","bool",false,[]],
		["Wager types","enable_place","Single horse: Place","bool",false,[]],
		["Wager types","enable_show","Single horse: Show","bool",false,[]],
		["Wager types","enable_quinella","Quinella","bool",true,[]],
		["Wager types","enable_exacta","Exacta","bool",false,[]],
		["Wager types","enable_exacta_box","Exacta Box","bool",false,[]],
		["Wager types","enable_trifecta","Trifecta","bool",false,[]],
		["Wager types","enable_trifecta_box","Trifecta Box","bool",false,[]],
		["Wager types","enable_superfecta","Superfecta","bool",false,[]],
		["Wager types","enable_superfecta_box","Superfecta Box","bool",false,[]],
		["Wager types","enable_full_order","Exact full five-horse order","bool",false,[]],
		["Virtual players","virtual_enabled","Allow virtual players","bool",false,[]],
		["Virtual players","virtual_style","Private numbered betting-style preset","choice","Style 2",["Style 1","Style 2","Style 3","Style 4","Style 5","Style 6","Style 7","Style 8","Style 9","Style 10"]],
		["Virtual players","virtual_rebuy","Automatic virtual-player rebuy","bool",true,[]],
		["Virtual players","virtual_rebuy_amount","Virtual rebuy credits","number",100,[1,10000,1]],
		["Virtual style factors","virtual_appetite","Betting appetite","number",0.3,[0.0,1.0,0.05]],
		["Virtual style factors","virtual_risk","Longshot preference","number",0.3,[0.0,1.0,0.05]],
		["Virtual style factors","virtual_spread","Spread across combinations","number",0.5,[0.0,1.0,0.05]],
		["Virtual style factors","virtual_randomness","Random choice strength","number",0.5,[0.0,1.0,0.05]],
		["Virtual style factors","virtual_variation","Race-to-race variation","number",0.4,[0.0,1.0,0.05]],
		["Virtual style factors","virtual_sit_out","Chance of sitting out","number",0.05,[0.0,1.0,0.05]],
		["Virtual style factors","virtual_repeat","Repeat previous choices","number",0.2,[0.0,1.0,0.05]],
		["Virtual style factors","virtual_history","Response to public results","number",0.0,[0.0,1.0,0.05]],
		["Virtual style factors","virtual_balance_fraction","Maximum fraction of balance","number",0.2,[0.0,1.0,0.05]],
		["Virtual style factors","virtual_max_bets","Maximum selections per race","number",5,[1,120,1]],
		["Virtual style factors","virtual_min_odds","Minimum preferred odds","number",1,[1,1000,1]],
		["Virtual style factors","virtual_max_odds","Maximum preferred odds","number",1000,[1,1000,1]],
		["Virtual style factors","virtual_reset_style","Restore selected style defaults","choice","Keep current",["Keep current","Restore default"]],
		["Announcers","race_voice","Race voice selection","choice","Automatic race",["Automatic race","Automatic female","Voice 1","Voice 2","Voice 3"]],
		["Announcers","race_humor","Race humor","number",0.3,[0.0,1.0,0.05]],
		["Announcers","race_sarcasm","Race sarcasm","number",0.1,[0.0,1.0,0.05]],
		["Announcers","race_energy","Race energy","number",0.8,[0.0,1.0,0.05]],
		["Announcers","race_detail","Race commentary detail","number",0.5,[0.0,1.0,0.05]],
		["Announcers","house_voice","House voice selection","choice","Automatic female",["Automatic female","Automatic race","Voice 1","Voice 2","Voice 3"]],
		["Announcers","house_humor","House humor","number",0.3,[0.0,1.0,0.05]],
		["Announcers","house_sarcasm","House sarcasm","number",0.1,[0.0,1.0,0.05]],
		["Announcers","house_energy","House energy","number",0.7,[0.0,1.0,0.05]],
		["Announcers","house_detail","House commentary detail","number",0.5,[0.0,1.0,0.05]],
		["Audio","crowd_enabled","Crowd ambience","bool",true,[]],
		["Audio","motor_pitch_enabled","Motor pitch follows race pace","bool",true,[]],
		["Audio","crowd_volume","Crowd volume","number",0.3,[0.0,1.0,0.05]],
	]
	for entry in additions:
		add(entry[0],entry[1],entry[2],entry[3],entry[4],entry[5])
		added_keys.append(entry[1])
	var centered := ["race_spread","race_lead_changes","photo_frequency","race_talk","race_seconds","replay_seconds","replay_lengths","bell_seconds","race_humor","race_sarcasm","race_energy","race_detail","house_humor","house_sarcasm","house_energy","house_detail"]
	for item in catalog:
		if item.key in centered and item.default>item.limits[0] and item.default<item.limits[1]: item.center=float(item.default)
	reset_all()

func add(category: String, key: String, label: String, type: String, default_value: Variant, limits: Array = []) -> void:
	catalog.append({"category":category,"key":key,"label":label,"type":type,"default":default_value,"limits":limits})

func valid(item: Dictionary, value: Variant) -> bool:
	if item.key in ["race_voice","house_voice"]:
		return value is String and not value.is_empty() and value.length()<=1024 and not "\n" in value and not "\r" in value
	if item.type == "bool":
		return value is bool
	if item.type == "choice":
		return value is String and value in item.limits
	if not (value is int or value is float) or not is_finite(float(value)):
		return false
	if value < item.limits[0] or value > item.limits[1]:
		return false
	if item.default is int and float(value) != floorf(value):
		return false
	return true

func set_value(key: String, value: Variant) -> bool:
	for item in catalog:
		if item.key == key:
			if not valid(item,value):
				return false
			values[key] = int(value) if item.default is int else value
			return true
	return false

func reset_all() -> void:
	for item in catalog:
		values[item.key] = item.default

func reset_category(category: String) -> void:
	for item in catalog:
		if item.category == category:
			values[item.key] = item.default

func save_profile(profile_name: String) -> bool:
	var cleaned := profile_name.strip_edges()
	if not valid_profile_name(cleaned):
		return false
	profiles[cleaned] = values.duplicate(true)
	return true

func load_profile(profile_name: String) -> bool:
	if not profiles.has(profile_name):
		return false
	return import_values(profiles[profile_name])

func import_values(candidate: Dictionary) -> bool:
	if not valid_values(candidate):
		return false
	values = candidate.duplicate(true)
	return true

func valid_values(candidate: Dictionary) -> bool:
	if candidate.size() != catalog.size():
		return false
	for item in catalog:
		if not candidate.has(item.key) or not valid(item,candidate[item.key]):
			return false
	return true

func export_data() -> Dictionary:
	return {"schema":10,"values":values.duplicate(true),"profiles":profiles.duplicate(true)}

func migrate_values(candidate: Dictionary, schema: int, current_game: bool=false) -> Dictionary:
	var result := candidate.duplicate(true)
	if schema <= 5 and result.get("photo_threshold",2.0)==2.0: result["photo_threshold"]=10.0
	if schema <= 4:
		result.erase("replay_events")
		result.erase("slow_motion")
		result["replay_seconds"]=7.5
		result["nose_guides"]=true
		result["guide_opacity"]=0.25
		if result.get("house_voice","Voice 1")=="Voice 1": result["house_voice"]="Automatic female"
		if result.get("race_voice","Voice 1")=="Voice 1": result["race_voice"]="Automatic race"
	if schema <= 3:
		for key in ["table_currency","denomination","custom_currency","show_money","bell_enabled"]: result.erase(key)
		result["start_signal"] = "Bell" if candidate.get("bell_enabled",true) else "Off"
		result["start_signal_volume"] = 0.65
	if schema == 1:
		for key in ["horse_scale","lane_spacing"]:
			if not result.has(key):
				result[key] = 1.55 if key == "horse_scale" else 56.0
	if schema <= 2:
		for item in catalog:
			if item.key in added_keys and not result.has(item.key): result[item.key] = item.default
	if schema<=6:
		for item in catalog:
			if item.key in ["race_lead_changes","race_spread","replay_lengths","bell_seconds"] and not result.has(item.key):
				result[item.key]=0.0 if item.key in ["race_lead_changes","race_spread"] else item.default
		if result.get("replay_seconds",7.5)==7.5: result.replay_seconds=5.0
	if schema<=7:
		for key in ["race_spread","race_lead_changes","race_talk"]:
			if result.has(key) and (result[key] is float or result[key] is int) and is_finite(float(result[key])) and result[key]>=0 and result[key]<=1:
				result[key]=float(result[key])*0.5
		result.erase("race_speech_rate"); result.erase("house_speech_rate")
	if schema<=8:
		result.erase("photo_threshold")
		result["photo_frequency"]=20
		# Apply the user's approved race setup once to the current game. Named
		# profiles keep their pacing values so intentional alternatives survive.
		if current_game and schema==8:
			for key in ["race_spread","race_lead_changes","race_talk","race_energy","house_energy","replay_seconds","replay_lengths"]:
				for item in catalog:
					if item.key==key: result[key]=item.default
	if schema==9 and current_game:
		# The user requested the revised, tested setup at the slider midpoints.
		result.race_spread=1.0;result.race_lead_changes=0.5;result.photo_frequency=20
	return result

func restore(data: Dictionary) -> bool:
	if data.get("schema") not in [1,2,3,4,5,6,7,8,9,10] or not data.get("values") is Dictionary or not data.get("profiles") is Dictionary:
		return false
	var restored_values := migrate_values(data.values,data.schema,true)
	var restored_profiles := {}
	if not valid_values(restored_values):
		return false
	for profile_name in data.profiles:
		if not profile_name is String or not valid_profile_name(profile_name) or not data.profiles[profile_name] is Dictionary:
			return false
		var profile := migrate_values(data.profiles[profile_name],data.schema)
		if not valid_values(profile):
			return false
		restored_profiles[profile_name] = profile
	values = restored_values
	profiles = restored_profiles
	return true

func valid_profile_name(profile_name: String) -> bool:
	return not profile_name.is_empty() and profile_name == profile_name.strip_edges() and profile_name.length() <= 40 and not "\n" in profile_name and not "\r" in profile_name

func rename_profile(old_name: String, new_name: String) -> bool:
	if not profiles.has(old_name) or not valid_profile_name(new_name) or profiles.has(new_name):
		return false
	profiles[new_name] = profiles[old_name]
	profiles.erase(old_name)
	return true

func delete_profile(profile_name: String) -> bool:
	return profiles.erase(profile_name)

func export_profile(profile_name: String) -> Dictionary:
	if not profiles.has(profile_name):
		return {}
	return {"schema":10,"values":profiles[profile_name].duplicate(true)}

func import_profile(profile_name: String, data: Dictionary) -> bool:
	if not valid_profile_name(profile_name) or data.get("schema") not in [1,2,3,4,5,6,7,8,9,10] or data.size() != 2 or not data.get("values") is Dictionary:
		return false
	var imported := migrate_values(data.values,data.schema)
	if not valid_values(imported):
		return false
	profiles[profile_name] = imported
	return true
