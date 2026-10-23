extends Node
## Global state: progress (beaten maps / unlocked towers), current selection, settings.

const MapsData = preload("res://scripts/data/maps_data.gd")
const SAVE_PATH := "user://pixel_td_save.json"

var beaten := {}            # map_id -> Array of beaten difficulty indices
var sfx_volume := 0.8
var music_volume := 0.6
var fullscreen := false

# ---------------------------------------------------------------- key bindings
# Physical keys (layout independent: E stays E on a Russian layout). Esc / right click are fixed (cancel, back).
const ACTIONS := ["tower_1", "tower_2", "tower_3", "tower_4", "tower_5", "tower_6", "tower_7", "tower_8", "tower_9", "tower_10", "upgrade", "sell", "target",
	"next_wave", "speed", "pause"]
const ACTION_NAMES := {"tower_1": "Tower 1", "tower_2": "Tower 2", "tower_3": "Tower 3", "tower_4": "Tower 4",
	"tower_5": "Tower 5", "tower_6": "Tower 6", "tower_7": "Tower 7", "tower_8": "Tower 8", "tower_9": "Tower 9", "tower_10": "Tower 10", "upgrade": "Upgrade", "sell": "Sell", "target": "Targeting mode",
	"next_wave": "Next wave", "speed": "Game speed", "pause": "Pause"}
const DEFAULT_KEYS := {"tower_1": KEY_1, "tower_2": KEY_2, "tower_3": KEY_3, "tower_4": KEY_4, "tower_5": KEY_5,
	"tower_6": KEY_6, "tower_7": KEY_7, "tower_8": KEY_8, "tower_9": KEY_9, "tower_10": KEY_0, "upgrade": KEY_E, "sell": KEY_X, "target": KEY_T, "next_wave": KEY_SPACE, "speed": KEY_F, "pause": KEY_P}
var keys := DEFAULT_KEYS.duplicate()
var selected_map := "meadow"
var selected_difficulty := 1

# ---------------------------------------------------------------- map unlocks
# Battles pay out paper maps, the currency locked maps are bought with. Harder maps and difficulties pay
# more, so they can be farmed; a lost battle still pays a share for the waves survived.
const TIERS := ["Beginner", "Intermediate", "Advanced", "Expert"]
const START_MAPS := ["meadow"]
const TIER_REWARD := [10, 20, 35, 60]          # paper maps for a win, by map tier
const DIFF_REWARD_MULT := [1.0, 1.5, 2.5, 4.0, 6.0]  # Light, Medium, Difficult, Hardcore, Ultracore
const LOSS_SHARE := 0.4                        # a loss pays this share of a win, scaled by waves survived
const MAP_PRICE := [30, 60, 150, 300]          # by map tier
var unlocked_maps: Array = START_MAPS.duplicate()
var paper_maps := 0
var bought_towers: Array = []   # towers bought with paper maps (beating their map only puts them up for sale)
var all_maps_open := false      # dev flag --unlock-all
var last_reward := 0            # paper maps paid by the last finished battle

# ---------------------------------------------------------------- seasonal events
# Halloween: maps with a "halloween" variant (Green Meadow) get their autumn look. Gameplay is unchanged.
# Dev flags --halloween / --no-halloween force it on or off.
const HALLOWEEN_FROM := 1010   # month * 100 + day, inclusive: Oct 10 - Nov 7
const HALLOWEEN_TO := 1107
var halloween := false

var _tex_cache := {}


var _cursor_scale := 0
var _real_beaten = null
var save_fake := false   # dev flag --save-fake: progress from cheats / --unlock-all is written to the save
var cheats := false      # dev flag --cheats: Cheats buttons in the main menu and the pause menu
var _cheat_snapshot := {}   # real progress from before the first menu cheat: what gets saved (unless --save-fake)
var _no_save := false     # dev flag --reset-data without --save-fake: play with a clean slate, never touch the save


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	save_fake = args.has("--save-fake")
	cheats = args.has("--cheats")
	load_progress()
	var today := Time.get_date_dict_from_system()
	var md := int(today["month"]) * 100 + int(today["day"])
	halloween = md >= HALLOWEEN_FROM and md <= HALLOWEEN_TO
	if args.has("--halloween"):
		halloween = true
	elif args.has("--no-halloween"):
		halloween = false
	if args.has("--reset-data"):
		_reset_data()
	if DisplayServer.get_name() != "headless":
		get_window().size_changed.connect(_update_cursor)
		_update_cursor()
		if fullscreen:
			set_fullscreen(true)
	if args.has("--unlock-all"):
		if not save_fake:
			_real_beaten = beaten.duplicate(true)   # dev flag: never written to the save file
		for m in MapsData.ORDER:
			beaten[m] = range(Defs.DIFFICULTIES.size())
		all_maps_open = true
		if save_fake:
			unlocked_maps = MapsData.ORDER.duplicate()
			save_progress()


## Dev flag --reset-data: start from default progress and settings. With --save-fake the save file is
## deleted, otherwise the real save is left alone and nothing is written this session.
func _reset_data() -> void:
	beaten = {}
	sfx_volume = 0.8
	music_volume = 0.6
	fullscreen = false
	keys = DEFAULT_KEYS.duplicate()
	unlocked_maps = START_MAPS.duplicate()
	paper_maps = 0
	bought_towers = []
	if save_fake:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	else:
		_no_save = true


## Pixel cursors, scaled with the window so they keep the same size as the game's pixels.
func _update_cursor() -> void:
	var w := get_window().size
	var sc := maxi(1, int(minf(w.x / 640.0, w.y / 360.0)))
	if sc == _cursor_scale:
		return
	_cursor_scale = sc
	for c in [["arrow", Input.CURSOR_ARROW, Vector2(1, 1)], ["hand", Input.CURSOR_POINTING_HAND, Vector2(3, 1)],
			["cross", Input.CURSOR_CROSS, Vector2(5, 5)]]:
		var img: Image = (load("res://assets/ui/cursor_%s.png" % c[0]) as Texture2D).get_image()
		img.convert(Image.FORMAT_RGBA8)
		img.resize(img.get_width() * sc, img.get_height() * sc, Image.INTERPOLATE_NEAREST)
		Input.set_custom_mouse_cursor(ImageTexture.create_from_image(img), c[1], c[2] * sc)


func set_cursor(shape: int) -> void:
	if Input.get_current_cursor_shape() != shape:
		Input.set_default_cursor_shape(shape)


func tex(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path)
	return _tex_cache[path]


# ---------------------------------------------------------------- progress
## Ultracore opens on a map once Hardcore is beaten there.
func is_diff_open(map_id: String, diff: int) -> bool:
	var needs := int(Defs.DIFFICULTIES[diff].get("needs", -1))
	return needs < 0 or is_beaten(map_id, needs)


func is_beaten(map_id: String, diff: int) -> bool:
	return beaten.has(map_id) and (beaten[map_id] as Array).has(diff)


func best_beaten(map_id: String) -> int:
	var best := -1
	if beaten.has(map_id):
		for d in beaten[map_id]:
			best = maxi(best, int(d))
	return best


func is_tower_unlocked(tower_id: String) -> bool:
	var u: Dictionary = Defs.TOWERS[tower_id]["unlock"]
	return u.is_empty() or all_maps_open or bought_towers.has(tower_id)


## Beating the tower's map on its difficulty (or a harder one) puts it up for sale in the Armory; a tower
## with a price but no map (the Soldier) is on sale from the start.
func is_tower_for_sale(tower_id: String) -> bool:
	var u: Dictionary = Defs.TOWERS[tower_id]["unlock"]
	if is_tower_unlocked(tower_id):
		return false
	return not u.has("map") or best_beaten(u["map"]) >= int(u["difficulty"])


func tower_price(tower_id: String) -> int:
	return int(Defs.TOWERS[tower_id]["unlock"].get("price", 0))


func buy_tower(tower_id: String) -> bool:
	if not is_tower_for_sale(tower_id) or paper_maps < tower_price(tower_id):
		return false
	paper_maps -= tower_price(tower_id)
	bought_towers.append(tower_id)
	save_progress()
	return true


func unlock_text(tower_id: String) -> String:
	var u: Dictionary = Defs.TOWERS[tower_id]["unlock"]
	if u.is_empty():
		return ""
	if not u.has("map"):
		return "Buy it for %d paper maps" % tower_price(tower_id)
	return "Beat %s on %s, then buy it for %d paper maps" % [MapsData.MAPS[u["map"]]["name"],
		Defs.DIFFICULTIES[u["difficulty"]]["name"], tower_price(tower_id)]


func tier_of(map_id: String) -> int:
	return TIERS.find(MapsData.MAPS[map_id]["tier"])


## Current season of a map: "halloween" or "" (normal look).
func map_variant(map_id: String) -> String:
	if halloween and (MapsData.MAPS[map_id]["variants"] as Dictionary).has("halloween"):
		return "halloween"
	return ""


func map_bg(map_id: String) -> String:
	var v := map_variant(map_id)
	return MapsData.MAPS[map_id]["variants"][v]["bg"] if v != "" else MapsData.MAPS[map_id]["bg"]


func map_thumb(map_id: String) -> String:
	var v := map_variant(map_id)
	return MapsData.MAPS[map_id]["variants"][v]["thumb"] if v != "" else MapsData.MAPS[map_id]["thumb"]


func is_map_unlocked(map_id: String) -> bool:
	return all_maps_open or unlocked_maps.has(map_id) or beaten.has(map_id)


func map_price(map_id: String) -> int:
	return MAP_PRICE[tier_of(map_id)]


func win_reward(map_id: String, diff: int) -> int:
	return roundi(TIER_REWARD[tier_of(map_id)] * DIFF_REWARD_MULT[diff])


func loss_reward(map_id: String, diff: int, waves_survived: int, total_waves: int) -> int:
	return floori(win_reward(map_id, diff) * LOSS_SHARE * clampf(float(waves_survived) / total_waves, 0.0, 1.0))


func buy_map(map_id: String) -> bool:
	if is_map_unlocked(map_id) or paper_maps < map_price(map_id):
		return false
	paper_maps -= map_price(map_id)
	unlocked_maps.append(map_id)
	save_progress()
	return true


## Pays the paper maps for a lost battle (see last_reward).
func record_loss(map_id: String, diff: int, waves_survived: int, total_waves: int) -> void:
	last_reward = loss_reward(map_id, diff, waves_survived, total_waves)
	paper_maps += last_reward
	save_progress()


## Records a victory, pays its paper maps (see last_reward) and returns the tower ids that just went on sale.
func record_win(map_id: String, diff: int) -> Array:
	var before := {}
	for t in Defs.TOWER_ORDER:
		before[t] = is_tower_for_sale(t)
	last_reward = win_reward(map_id, diff)
	paper_maps += last_reward
	if not unlocked_maps.has(map_id):
		unlocked_maps.append(map_id)
	if not beaten.has(map_id):
		beaten[map_id] = []
	if not (beaten[map_id] as Array).has(diff):
		beaten[map_id].append(diff)
	save_progress()
	var newly := []
	for t in Defs.TOWER_ORDER:
		if not before[t] and is_tower_for_sale(t):
			newly.append(t)
	return newly


func save_progress() -> void:
	# checks the flags directly too: a `godot -s` test script can call this before _ready() has run
	var args := OS.get_cmdline_user_args()
	if _no_save or (args.has("--reset-data") and not args.has("--save-fake")):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		var real: Dictionary = _cheat_snapshot if not _cheat_snapshot.is_empty() else {
			"beaten": beaten if _real_beaten == null else _real_beaten, "unlocked_maps": unlocked_maps,
			"paper_maps": paper_maps, "bought_towers": bought_towers}
		f.store_string(JSON.stringify({"beaten": real["beaten"], "sfx_volume": sfx_volume, "music_volume": music_volume, "fullscreen": fullscreen,
			"keys": keys, "unlocked_maps": real["unlocked_maps"], "paper_maps": real["paper_maps"],
			"bought_towers": real["bought_towers"]}))


# ---------------------------------------------------------------- cheats (dev flag --cheats)
# Menu cheats change progress for this session only: the save keeps the real progress from before the first
# cheat, and anything earned afterwards this session isn't saved either. With --save-fake it is all saved.
func _cheat_begin() -> void:
	if save_fake or not _cheat_snapshot.is_empty():
		return
	_cheat_snapshot = {"beaten": (beaten if _real_beaten == null else _real_beaten).duplicate(true),
		"unlocked_maps": unlocked_maps.duplicate(), "paper_maps": paper_maps, "bought_towers": bought_towers.duplicate()}


func cheat_paper_maps(amount: int) -> void:
	_cheat_begin()
	paper_maps = maxi(0, paper_maps + amount)
	save_progress()


func cheat_set_map_open(map_id: String, open: bool) -> void:
	_cheat_begin()
	if open and not unlocked_maps.has(map_id):
		unlocked_maps.append(map_id)
	elif not open:
		unlocked_maps.erase(map_id)
	save_progress()


## Owns a tower (or not) as if it had been bought with paper maps.
func cheat_set_tower_bought(tower_id: String, on: bool) -> void:
	_cheat_begin()
	if on and not bought_towers.has(tower_id):
		bought_towers.append(tower_id)
	elif not on:
		bought_towers.erase(tower_id)
	save_progress()


## Marks one difficulty of one map as beaten (or not); towers unlock from this like from a real win.
func cheat_set_beaten(map_id: String, diff: int, on: bool) -> void:
	_cheat_begin()
	var list: Array = beaten.get(map_id, [])
	if on and not list.has(diff):
		list.append(diff)
	elif not on:
		list.erase(diff)
	if list.is_empty():
		beaten.erase(map_id)
	else:
		beaten[map_id] = list
	save_progress()


func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	var b = data.get("beaten", {})
	if typeof(b) == TYPE_DICTIONARY:
		for k in b:
			var arr := []
			for d in b[k]:
				arr.append(int(d))
			beaten[k] = arr
	if data.has("unlocked_maps"):
		for m in data.get("unlocked_maps", []):
			if MapsData.MAPS.has(m) and not unlocked_maps.has(m):
				unlocked_maps.append(m)
		paper_maps = int(data.get("paper_maps", 0))
		for k in data.get("map_keys", []):
			# save from the map key days: an unused key is worth the price of a map one tier up
			paper_maps += MAP_PRICE[mini(int(k) + 1, MAP_PRICE.size() - 1)]
	else:
		# save from before map unlocks: every beaten map stays open, past wins are paid out
		for m in beaten:
			if MapsData.MAPS.has(m) and not (beaten[m] as Array).is_empty():
				if not unlocked_maps.has(m):
					unlocked_maps.append(m)
				for d in beaten[m]:
					paper_maps += win_reward(m, int(d))
	if data.has("bought_towers"):
		for t in data["bought_towers"]:
			if Defs.TOWERS.has(t) and not bought_towers.has(t):
				bought_towers.append(t)
	else:
		# save from before towers were bought: everything its wins unlocked stays unlocked
		for t in Defs.TOWER_ORDER:
			if is_tower_for_sale(t):
				bought_towers.append(t)
	sfx_volume = float(data.get("sfx_volume", 0.8))
	music_volume = float(data.get("music_volume", 0.6))
	fullscreen = bool(data.get("fullscreen", false))
	var k = data.get("keys", {})
	if typeof(k) == TYPE_DICTIONARY:
		for a in k:
			if ACTIONS.has(a):
				keys[a] = int(k[a])


## Which action (if any) this key press triggers.
func action_for(event: InputEvent) -> String:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return ""
	var pk: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	for a in ACTIONS:
		if keys[a] == pk:
			return a
	return ""


## Human readable name of the key bound to an action, as printed on the user's keyboard.
func key_label(action: String) -> String:
	var pk: int = keys.get(action, 0)
	if pk == 0:
		return "-"
	var shown := pk
	if DisplayServer.get_name() != "headless":
		shown = DisplayServer.keyboard_get_keycode_from_physical(pk)
	return OS.get_keycode_string(shown)


## Bind a key; if another action already uses it, the two actions swap keys.
func bind_key(action: String, physical_key: int) -> void:
	for a in ACTIONS:
		if a != action and keys[a] == physical_key:
			keys[a] = keys[action]
	keys[action] = physical_key
	save_progress()


func reset_keys() -> void:
	keys = DEFAULT_KEYS.duplicate()
	save_progress()


func set_fullscreen(on: bool) -> void:
	fullscreen = on
	if DisplayServer.get_name() == "headless":
		return
	get_window().mode = Window.MODE_FULLSCREEN if on else Window.MODE_WINDOWED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		set_fullscreen(not fullscreen)
		save_progress()
