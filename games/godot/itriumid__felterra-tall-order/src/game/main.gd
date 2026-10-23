extends Node
## The game: the title over the forest path to the cats' village, the village itself, and the runs
## out from it into the clearing, where the horde comes out of the jungle under the canopy.
##
## Development aids: --horde=<count> starts with that many in the clearing; --no-spawn stops more
## coming; --at=<x>,<y> starts the cat there, in meters; --gear=<0 to 2> picks the gear; --sturdy keeps the cat alive; --screenshot=<path> saves
## --dogs=<count> starts with guard dogs close by, --chainsaw=<count> with chainsaw workers; --giant=<count> starts with giants close by, --giant-from=<x>,<y> that far from him; --start=<nunchaku or handgun, or any weapon> skips choosing; --no-blood starts with blood off; --screenshot=<path> saves
## a frame after --screenshot-after seconds (default 4) and quits; --frames=<count> saves that
## many, a twentieth of a second apart, as <path>_1.png and on; --walk=<x>,<y> steers the cat
## that way on his own; --fallen=<count> scatters that many bodies; --mutations=<id>,<id> gives
## him those dodge mutations, a common card of each; --dodge-every=<seconds> dodges on his own;
## --offer=<id>,<id>,<id> hands him a card of those choices, common, uncommon and rare;
## --support=<id>,<id> puts those on his back; --machine starts with a feller buncher close by;
## --cage=<count> sets that many cages around him, the first right beside him, the rest far off;
## --village starts in the village instead of a fight; --intro tells the story's opening again;
## --area=<id> starts a liberation run in that area, --freed as if it's been freed already, --boss
## with its goal done and its boss on the way;
## --villagers=<count> puts that many rescued cats in it, for this run only; --restored=<all, or
## names> shows those buildings brought back from ruin; --salvage=<count> and --cloth=<count> give
## the village that much to spend; --liberated=<ids> has those areas freed already; --at-door=<building>
## stands him at its door; --shop opens what that door holds.

## The light under the canopy in the clearing, and at the village, where it's open to the sky.
const SHADE := Color(0.62, 0.68, 0.62)
const VILLAGE_SHADE := Color(0.82, 0.86, 0.8)
## Sun through the canopy's gaps: where it reaches the ground, in meters.
const SHAFTS: Array[Vector2] = [
	Vector2(8.0, 6.0), Vector2(19.0, 10.0), Vector2(30.0, 7.0), Vector2(13.0, 17.0), Vector2(27.0, 18.0),
]
## Gear to try on with G, until upgrades hand it out: the start, then upgraded sets. An empty
## weapon list keeps whatever he started with.
const OUTFITS: Array[Dictionary] = [
	{"weapons": []},
	{"body": "vest", "head": "hard_hat", "neck": "bell_collar", "eyes": "goggles", "paws": "gloves", "feet": "boots", "waist": "jamu_flask", "weapons": []},
	{"body": "vest", "head": "caping", "neck": "scarf", "weapons": ["knife", "submachine_gun"]},
]
## The menus, as pages of choices. The title runs a world behind it; the pause menu and the
## summary of a run stop it (solo; online, the pause menu opens over a world that keeps running).
const PAGES := {
	"title": ["play", "settings", "leave"],
	"pause": ["carry_on", "settings", "start_again", "village", "leave"],
	"village_pause": ["carry_on", "settings", "title", "leave"],
	"summary": ["home", "go_again", "leave"],
}
## The story's opening, told once, as he walks into the village the first time, and the Elder
## walks out to meet him. Nobody knows yet what's wrong; finding out is the story.
const INTRO: Array = [
	"This forest has been ours for as long as anyone remembers.",
	"Lately, it doesn't feel like ours.",
	{"by": "elder", "mood": "happy", "text": "There you are. Welcome home, or what's left of it."},
	{"by": "elder", "mood": "worried", "text": "Rats where there never were any. A smell of oil in the stream."},
	{"by": "elder", "mood": "sad", "text": "Cats have gone out foraging and never come home."},
	{"by": "elder", "mood": "worried", "text": "Something is wrong out there. Someone has to go and look."},
	{"by": "tompel", "mood": "determined", "text": "Then I'll go and look."},
	{"by": "elder", "mood": "happy", "text": "And this is Jogiboy. He lives next door to me, and he's decided you're his friend."},
	{"by": "jogiboy", "mood": "happy", "text": "I'll look after the village while you're out. I'm good at finding things."},
	{"by": "elder", "text": "The gate's that way, past the board. Start at the edge, past the last huts."},
]
## How far he walks into a run before it starts, in meters.
const ENTRANCE := 5.0
## After a boss falls, how long before the area's free, even with nothing to tell.
const FREED_PAUSE := 2.5

## The tabs of the smithy and the pack: what kind of thing each shows, and what it's called.
const THING_TABS: Array[Array] = [["weapon", "Weapons"], ["gear", "Gear"], ["support", "Support"], ["mutation", "Dodge mutations"]]

## The settings page: each row's section, setting and name, by section.
const SETTING_ROWS: Array[Array] = [
	["graphics", "full_screen", "Full screen"], ["graphics", "window_scale", "Window size"],
	["graphics", "vsync", "Vertical sync"],
	["audio", "master", "Volume"], ["audio", "music", "Music"], ["audio", "effects", "Effects"],
	["audio", "interface", "Interface"],
	["gameplay", "aim", "Aim"], ["gameplay", "blood", "Blood"], ["gameplay", "story_waits", "Story lines"],
	["progress", "reset", "Reset all progress"],
	["", "back", "Back"],
]
## There's no online play yet; when there is, the menu won't stop the world there.
const ONLINE := false

var arena: Arena
var cat: Cat
var _world: Node2D
var _camera: Camera2D
var _overlay: Overlay
var _muzzle_light: PointLight2D
var _entities: EntitiesView
var _audio: AudioDirector
var _music: MusicDirector
var _ground: GroundView
var _outfit := 0
## The weapon he starts with, once chosen: until then the run waits.
var _start_weapon := ""
## Which page is showing ("" while playing), the page the settings return to, and the rows chosen.
var _page := ""
var _settings_from := "pause"
var _setting_choice := 0
var records := Records.new()
## The village and what's been brought home to it; and the reset's question: "" before it's
## asked, "asking" once it has been, "done" after.
var village := Village.new()
var _reset_state := ""
## Where he is: on the "title", "arriving" in the village (walking in, a cutscene), in the
## "village", "leaving" it (seen off, a cutscene), or on a "run".
var _place := "run"
var village_map: VillageMap
var _village_view: VillageView
var _arena_layer: Node2D
var _village_layer: Node2D
var _shade: CanvasModulate
## The cutscene playing, if one is: the walk into the village, with or without the opening told
## over it.
var _cutscene: Cutscene
var _open_village_first := false
## Whether the runs this session go out from the village, so starting again keeps its rules.
var _ran_from_village := false
## The run under way: an area's id, or "endless"; whether its story is being told going in, or
## the area is being freed; and how long the freeing has left at least.
var _run_kind := ""
var _briefing := false
## Walking into the run, from where he came in to where the run starts, and how fast.
var _entering := false
var _entering_to := Vector2.ZERO
var _entering_pace := Cat.SPEED
var _freeing := false
var _free_for := 0.0
var _dev_area := ""
var _dev_freed := false
var _dev_boss := false
var _at_door := ""
## Which forged weapon the start choice's third card shows.
var _start_extra := 0
var _open_shop_first := false
## A line the village says (what was restored, or why not), and for how long more; and the row
## chosen in a shop.
var _village_message := ""
var _village_message_for := 0.0
var _shop_choice := 0
var _shop_tab := 0
## Buildings the story has brought back since he last walked into the village: told, and shown
## coming back, as he walks home.
var _just_restored: Array[String] = []
## What's new since he last walked in, as {title, text}: set out once the walk in is done.
var _news: Array[Dictionary] = []
## Whether Jogiboy has something to give him once he's walked in.
var _found_by_jogiboy := false
var _force_intro := false
## Which of the last run's numbers beat the best.
var _beaten: Array[String] = []
var settings := Settings.new()
## Settings and records are read and written only in a real session: a development flag never
## touches them.
var _keeping_settings := false
var _open_settings_first := false
var _open_menu_first := false
var _open_title_first := false
## For screenshots: he goes down this many seconds into the run (never, below 0).
var _down_after := -1.0
var _menu_after := -1.0
## For screenshots: show the cards' explanations as if Tab were held.
var _always_reading := false
var _menu_choice := 0
var _start := Arena.SIZE / 2.0
var _fallen := 0
var _giants := 0
var _dogs := 0
var _chainsaws := 0
var _mutations: PackedStringArray = []
var _dodge_every := 0.0
var _offer: PackedStringArray = []
var _support: PackedStringArray = []
var _machine := false
var _cages := 0
var _since_dodge := 0.0
var _giant_from := Vector2(3.5, -1.0)
var _walk := Vector2.ZERO
var _frames := 1
var _frames_saved := 0
var _sturdy := false
var _behind := 0.0
var _screenshot_path := ""
var _screenshot_after := 4.0


func _ready() -> void:
	InputActions.register()
	var horde := 0
	var spawning := true
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--horde="):
			horde = argument.trim_prefix("--horde=").to_int()
		elif argument.begins_with("--at="):
			var parts := argument.trim_prefix("--at=").split(",")
			_start = Vector2(parts[0].to_float(), parts[1].to_float())
		elif argument.begins_with("--fallen="):
			_fallen = argument.trim_prefix("--fallen=").to_int()
		elif argument.begins_with("--walk="):
			var parts := argument.trim_prefix("--walk=").split(",")
			_walk = Vector2(parts[0].to_float(), parts[1].to_float())
		elif argument.begins_with("--frames="):
			_frames = argument.trim_prefix("--frames=").to_int()
		elif argument.begins_with("--giant-from="):
			var parts := argument.trim_prefix("--giant-from=").split(",")
			_giant_from = Vector2(parts[0].to_float(), parts[1].to_float())
		elif argument.begins_with("--chainsaw="):
			_chainsaws = argument.trim_prefix("--chainsaw=").to_int()
		elif argument.begins_with("--cage="):
			_cages = argument.trim_prefix("--cage=").to_int()
		elif argument.begins_with("--villagers="):
			for index in argument.trim_prefix("--villagers=").to_int():
				village.cats.append({"name": Cage.NAMES[index % Cage.NAMES.size()], "coat": Cage.COATS[index % Cage.COATS.size()]})
		elif argument.begins_with("--salvage="):
			village.salvage = argument.trim_prefix("--salvage=").to_int()
		elif argument.begins_with("--cloth="):
			village.cloth = argument.trim_prefix("--cloth=").to_int()
		elif argument.begins_with("--at-door="):
			_at_door = argument.trim_prefix("--at-door=")
		elif argument == "--shop":
			_open_shop_first = true
		elif argument.begins_with("--restored="):
			var names := argument.trim_prefix("--restored=")
			village.restored.assign(VillageMap.building_names() if names == "all" else Array(names.split(",", false)))
		elif argument.begins_with("--liberated="):
			# Freed, as if by the story: what freeing them teaches, and where the next run goes.
			for id in argument.trim_prefix("--liberated=").split(",", false):
				village.liberated.append(id)
			village.next_run = village.next_area()
		elif argument.begins_with("--area="):
			_dev_area = argument.trim_prefix("--area=")
		elif argument == "--freed":
			_dev_freed = true
		elif argument == "--boss":
			_dev_boss = true
		elif argument == "--village":
			_open_village_first = true
		elif argument == "--intro":
			_force_intro = true
		elif argument == "--machine":
			_machine = true
		elif argument.begins_with("--support="):
			_support = argument.trim_prefix("--support=").split(",", false)
		elif argument.begins_with("--offer="):
			_offer = argument.trim_prefix("--offer=").split(",", false)
		elif argument.begins_with("--dodge-every="):
			_dodge_every = argument.trim_prefix("--dodge-every=").to_float()
		elif argument.begins_with("--mutations="):
			_mutations = argument.trim_prefix("--mutations=").split(",", false)
		elif argument.begins_with("--dogs="):
			_dogs = argument.trim_prefix("--dogs=").to_int()
		elif argument.begins_with("--giant="):
			_giants = argument.trim_prefix("--giant=").to_int()
		elif argument == "--no-spawn":
			spawning = false
		elif argument.begins_with("--gear="):
			_outfit = clampi(argument.trim_prefix("--gear=").to_int(), 0, OUTFITS.size() - 1)
		elif argument.begins_with("--start="):
			_start_weapon = argument.trim_prefix("--start=")
		elif argument == "--no-blood":
			settings.set_value("gameplay", "blood", false)
		elif argument == "--reading":
			_always_reading = true
		elif argument == "--menu":
			_open_menu_first = true
		elif argument == "--title":
			_open_title_first = true
		elif argument.begins_with("--down-after="):
			_down_after = argument.trim_prefix("--down-after=").to_float()
		elif argument == "--settings":
			_open_settings_first = true
		elif argument.begins_with("--menu-after="):
			_menu_after = argument.trim_prefix("--menu-after=").to_float()
		elif argument == "--sturdy":
			_sturdy = true
		elif argument.begins_with("--screenshot="):
			_screenshot_path = argument.trim_prefix("--screenshot=")
		elif argument.begins_with("--screenshot-after="):
			_screenshot_after = argument.trim_prefix("--screenshot-after=").to_float()
	# A screenshot can't wait for someone to choose, unless it's of the choice itself.
	if not _screenshot_path.is_empty() and _start_weapon.is_empty() and not "--choose" in OS.get_cmdline_user_args():
		_start_weapon = "handgun"
	_keeping_settings = OS.get_cmdline_user_args().is_empty()
	if _keeping_settings:
		settings.load_from()
		records.load_from()
		village.load_from()
		# A village kept before the story brought buildings back: whatever it's earned stands.
		village.catch_up()
	settings.apply()
	# A development run is silent unless asked: screenshots shouldn't blast whoever's nearby.
	AudioServer.set_bus_mute(0, not _keeping_settings and not "--sound" in OS.get_cmdline_user_args())
	_build_scene()
	_entities.blood = settings.get_value("gameplay", "blood")
	# A real session opens on the title; a development run goes straight into the fight it set up.
	if _keeping_settings or _open_title_first:
		_show_title()
	elif _open_village_first:
		_enter_village(VillageMap.HOME_SPOT)
		_place = "village"
		for building in village_map.buildings:
			if building.name == _at_door:
				var footprint: Rect2 = building.footprint
				village_map.cat.body.position = Vector2(footprint.get_center().x, footprint.end.y + 0.45)
		if _open_shop_first and not _at_door.is_empty():
			_use(_at_door)
		if _force_intro:
			_enter_village(VillageMap.TITLE_SPOT)
			_arrive(true)
	else:
		_begin(horde, spawning)
		if not _dev_area.is_empty():
			if _dev_freed:
				village.liberated.append(_dev_area)
				village.told.append_array(["intro:" + _dev_area, "outro:" + _dev_area])
			_set_up_run(_dev_area)
			if _dev_boss:
				arena.goal_done = true
				arena._bring_in_the_boss()
		if _open_menu_first or _open_settings_first:
			_open_page("pause")
			if _open_settings_first:
				_settings_from = "pause"
				_page = "settings"


func _build_scene() -> void:
	# The menu and the interface keep running when the world is paused; the world doesn't.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_world = Node2D.new()
	_world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_world)
	# The forest floor under the canopy is dim; the sun only reaches it in shafts.
	_shade = CanvasModulate.new()
	_shade.color = SHADE
	_world.add_child(_shade)
	# The clearing's views on one layer, the village's on another: one shows at a time.
	_arena_layer = Node2D.new()
	_world.add_child(_arena_layer)
	_village_layer = Node2D.new()
	_village_layer.visible = false
	_world.add_child(_village_layer)
	_village_view = VillageView.new()
	_village_layer.add_child(_village_view)
	_ground = GroundView.new()
	_arena_layer.add_child(_ground)
	_entities = EntitiesView.new()
	_arena_layer.add_child(_entities)
	var canopy := CanopyView.new()
	_arena_layer.add_child(canopy)
	var shaft_texture := _soft_light(Vector2i(220, 120))
	for spot in SHAFTS:
		var shaft := PointLight2D.new()
		shaft.texture = shaft_texture
		shaft.position = spot * World.PIXELS_PER_METER
		# Slanting in from the top left.
		shaft.rotation = deg_to_rad(-30.0)
		shaft.color = Palette.BRASS_LIGHT
		shaft.energy = 0.7
		shaft.height = 60.0
		_arena_layer.add_child(shaft)
	_muzzle_light = PointLight2D.new()
	_muzzle_light.texture = _soft_light(Vector2i(96, 96))
	_muzzle_light.color = Palette.SPARK
	_muzzle_light.height = 12.0
	_muzzle_light.energy = 0.0
	_arena_layer.add_child(_muzzle_light)
	_camera = Camera2D.new()
	_world.add_child(_camera)
	_audio = AudioDirector.new()
	add_child(_audio)
	_audio.setup(_world)
	_music = MusicDirector.new()
	add_child(_music)
	_music.setup()
	var interface := CanvasLayer.new()
	interface.layer = 10
	add_child(interface)
	_overlay = Overlay.new()
	interface.add_child(_overlay)


func _begin(horde: int, spawning: bool) -> void:
	_place = "run"
	_show_layer(false)
	_music.place = "run"
	arena = Arena.new()
	arena.spawning = spawning
	cat = arena.add_cat(_start)
	cat.aim_mode = settings.get_value("gameplay", "aim")
	_dress()
	for mutation in _mutations:
		if Upgrades.MUTATIONS.has(mutation):
			Upgrades.apply(cat, {"id": "mutation:" + mutation, "rarity": Upgrades.Rarity.COMMON})
		else:
			push_warning("There's no dodge mutation called %s." % mutation)
	for support in _support:
		if Upgrades.SUPPORT.has(support):
			Upgrades.apply(cat, {"id": "support:" + support, "rarity": Upgrades.Rarity.COMMON})
		else:
			push_warning("There's no support called %s." % support)
	if not _offer.is_empty():
		var choices: Array[Dictionary] = []
		for index in mini(_offer.size(), Upgrades.CHOICES):
			choices.append({"id": _offer[index], "rarity": mini(index, Upgrades.Rarity.LEGENDARY)})
		cat.offers.append(choices)
	if _sturdy:
		cat.health = 1.0e9
	for index in horde:
		arena.add_creature(arena.edge_point() * 0.7 + Arena.SIZE * 0.15)
	for index in _giants:
		arena.add_giant(_start + _giant_from + Vector2(index, index))
	for index in _chainsaws:
		arena.add_giant(_start + _giant_from + Vector2(-index, index), "chainsaw")
	if _machine:
		arena.add_machine(_start + Vector2(6.5, 1.5), PI)
	for index in _cages:
		arena.add_cage((_start + (Vector2(0.5, 0.0) if index == 0 else Vector2.from_angle(index * 2.4) * 12.0)).clamp(Vector2.ONE * 1.5, Arena.SIZE - Vector2.ONE * 1.5))
	for index in _dogs:
		arena.add_creature(_start + Vector2.from_angle(index * 2.1) * 4.0, "dog")
	for index in _fallen:
		var body := Body.new()
		body.radius = 0.08
		body.position = _start + Vector2(arena.random.randf_range(-7.0, 7.0), arena.random.randf_range(-4.0, 4.0))
		arena.fallen.append(body)
	_watch(arena, cat)
	# The view starts on him, even if a menu opens before the first frame moves it.
	_camera.position = World.to_screen(cat.body.position)


## Every view follows this arena, and this cat (or none, behind the title).
func _watch(watched: Arena, watched_cat: Cat) -> void:
	_entities.arena = watched
	_ground.arena = watched
	_audio.watch(watched)
	_music.arena = watched
	_music.cat = watched_cat
	_overlay.arena = watched
	_overlay.cat = watched_cat


## The title, over the forest path into the village, with him on it.
func _show_title() -> void:
	_enter_village(VillageMap.TITLE_SPOT)
	village_map.cat.facing = Vector2.RIGHT
	_place = "title"
	_music.place = "intro"
	_open_page("title")


## Into the village, with everyone he's brought home in it, and him standing at a spot.
func _enter_village(spot: Vector2) -> void:
	village_map = VillageMap.new(village.cats, village.restored)
	village_map.cat.body.position = spot
	village_map.cat.coat = village.coat
	_village_view.banners = village.banners
	_village_view.village = village_map
	_village_view.village_record = village
	_show_layer(true)
	_music.place = "village"
	# Nothing to fight here: the clearing's views watch an empty one, out of sight.
	arena = Arena.new()
	arena.spawning = false
	cat = null
	_watch(arena, null)
	_overlay.village_map = village_map
	_start_weapon = ""
	_outfit = 0
	_camera.position = _village_camera()


func _show_layer(village_showing: bool) -> void:
	_village_layer.visible = village_showing
	_arena_layer.visible = not village_showing
	_shade.color = VILLAGE_SHADE if village_showing else SHADE
	_overlay.place = "village" if village_showing else "run"
	if not village_showing:
		_overlay.village_map = null
		_cutscene = null
		_overlay.intro = ""
		_overlay.cutscene = false


## He walks into the village, a cutscene: from the forest path, the first time with the Elder
## out to meet him and the story's opening told as he goes; or home from a run, with whatever
## has happened since told on the way in: what an area freed teaches him, from the cat who
## teaches it, and what's been restored. Whoever has something to say comes over to say it. Then
## what's new is set out, a line on each.
func _arrive(from_the_forest: bool) -> void:
	_place = "arriving"
	var telling := from_the_forest and (not village.intro_seen or _force_intro)
	var spot := VillageMap.HOME_SPOT if from_the_forest else VillageMap.RETURN_SPOT
	if telling:
		# The Elder comes out to meet him where he walks into the village.
		spot = VillageMap.MEETING_SPOT
	var lines: Array = []
	_news.clear()
	if telling:
		lines = INTRO.duplicate()
		_news.append({"title": "The village", "text": "Walk with W A S D. At a door, Enter uses what's inside; a ruin's door says what brings it back."})
		_news.append({"title": "The gate", "text": "Walk out through the gate, on the right, to set out. The board beside it chooses where."})
	elif not from_the_forest:
		for area_id in _lessons_due():
			var teaches: Dictionary = Areas.named(area_id).teaches
			lines.append_array(teaches.lines)
			for mutation: String in teaches.mutations:
				_news.append({"title": Upgrades.MUTATIONS[mutation].name, "text": "A dodge mutation, on your cards from now on. " + Upgrades.MUTATIONS[mutation].explain + "."})
			var after := Areas.ids().find(area_id) + 1
			if after < Areas.ids().size() and not Areas.ids()[after] in village.liberated:
				_news.append({"title": "On the map: " + (Areas.named(Areas.ids()[after]).name as String).to_lower(), "text": "Choose it at the board by the gate."})
		lines.append_array(village.restored_lines(_just_restored))
		# Jogiboy, the village's finder, has dug something up while he was gone.
		village.salvage += Village.JOGIBOY_FINDS
		_found_by_jogiboy = true
		for building in _just_restored:
			_news.append({"title": _building_name(building).capitalize(), "text": Village.EXPLAINS[building]})
	_cutscene = Cutscene.new(lines, settings.get_value("gameplay", "story_waits"))
	for building in _just_restored:
		_village_view.restoring(building)
	_just_restored.clear()
	village_map.walk_to(spot)
	for line: Variant in lines:
		var who: String = line.get("by", "") if line is Dictionary else ""
		if who == "elder":
			village_map.elder_meets(spot)
		elif not who.is_empty():
			village_map.call_over(who, spot)
	# The opening's own music plays on through its walk; any other walk in has the village's.
	_music.place = "intro" if telling else "village"
	if not lines.is_empty():
		# Slow enough that he reaches the spot as the last line ends, if it's left to run.
		village_map.stroll_speed = minf(village_map.walking_to.distance_to(village_map.cat.body.position) / _cutscene.length(), VillageMap.WALK_IN_SPEED)
	_overlay.cutscene = true


## The areas freed whose lessons haven't been taught yet: they're taught at home, the first time
## he walks in after.
func _lessons_due() -> Array[String]:
	var due: Array[String] = []
	for area_id in village.liberated:
		if not ("teach:" + area_id) in village.told and not (Areas.named(area_id).get("teaches", {}).get("lines", []) as Array).is_empty():
			due.append(area_id)
	return due


## The walk in plays on its own. Enter hurries the lines along; Escape skips the whole scene, and
## he's simply there. With nothing (left) to tell, he walks in at his full pace. Then what's new.
func _arriving(delta: float) -> void:
	var skip := Input.is_action_just_pressed("pause")
	_cutscene.step(delta, Input.is_action_just_pressed("menu_choose"), skip)
	_overlay.intro = _cutscene.written()
	_overlay.speaker = _cutscene.speaker()
	_overlay.mood = _cutscene.mood()
	if _cutscene.done() or _cutscene.lines.is_empty():
		village_map.stroll_speed = VillageMap.WALK_IN_SPEED
		_music.place = "village"
	if skip and village_map.walking():
		village_map.cat.body.position = village_map.walking_to
		village_map.walking_to = Vector2.INF
	_step_village(delta)
	if not village_map.walking() and _cutscene.done() or skip:
		# Told, or skipped: either way it's been told.
		if not _cutscene.lines.is_empty() and not village.intro_seen:
			village.intro_seen = true
		for area_id in _lessons_due():
			village.told.append("teach:" + area_id)
		_keep_village()
		_place = "village"
		_cutscene = null
		_overlay.intro = ""
		_overlay.speaker = ""
		_overlay.cutscene = false
		village_map.elder_home()
		village_map.let_go()
		if _found_by_jogiboy:
			_found_by_jogiboy = false
			_say("Jogiboy dug up %d salvage for you while you were out." % Village.JOGIBOY_FINDS)
		if not _news.is_empty():
			_overlay.news = _news.duplicate()
			_open_page("news")


## In the village: he walks where he's steered, and walking out on the path to the clearing
## starts a run.
func _in_village(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		_open_page("village_pause")
		return
	_village_message_for = maxf(_village_message_for - delta, 0.0)
	var door := village_map.at_door()
	_overlay.door = _door_prompt(door)
	_overlay.leads_to = Areas.named(village.next_run).get("name", "Endless").to_lower() if village.next_run != "endless" else "Endless"
	_overlay.message = _village_message if _village_message_for > 0.0 else ""
	_overlay.village_record = village
	if Input.is_action_just_pressed("menu_choose") and not door.is_empty():
		_use(door)
		return
	village_map.cat.steering = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _walk != Vector2.ZERO:
		village_map.cat.steering = _walk
	_step_village(delta)
	if village_map.leaving():
		_send_off()


## Out through the gate: the village sees him off, and he walks on into the forest. The first time
## he goes to an area, someone has a word for him on the way; any other time he just goes, at his
## own pace.
func _send_off() -> void:
	_note("seen off to %s" % village.next_run)
	_place = "leaving"
	_overlay.door = ""
	var scene := "send_off:" + village.next_run
	var lines: Array = []
	if village.next_run != "endless" and not scene in village.told:
		lines = (Areas.named(village.next_run).get("send_off", []) as Array).duplicate()
	_cutscene = Cutscene.new(lines, settings.get_value("gameplay", "story_waits"))
	village_map.see_off()
	village_map.stroll_speed = VillageMap.WALK_IN_SPEED
	if not lines.is_empty():
		village_map.stroll_speed = minf(VillageMap.WALK_IN_SPEED, village_map.cat.body.position.distance_to(VillageMap.OFF_INTO_THE_FOREST) / _cutscene.length())
	_overlay.cutscene = true


## Seen off: Enter hurries the word he's given, Escape skips the lot, and once he's out of sight
## the run starts.
func _leaving(delta: float) -> void:
	var skip := Input.is_action_just_pressed("pause")
	_cutscene.step(delta, Input.is_action_just_pressed("menu_choose"), skip)
	_overlay.intro = _cutscene.written()
	_overlay.speaker = _cutscene.speaker()
	_overlay.mood = _cutscene.mood()
	if _cutscene.done():
		village_map.stroll_speed = VillageMap.WALK_IN_SPEED
	_step_village(delta)
	if skip or (_cutscene.done() and not village_map.walking()):
		if not _cutscene.lines.is_empty():
			village.told.append("send_off:" + village.next_run)
			_keep_village()
		_cutscene = null
		_overlay.intro = ""
		_overlay.speaker = ""
		_overlay.cutscene = false
		_start_run(village.next_run)


## What Enter does at a building's door, in words: what it holds, or for a ruin, what will bring
## it back.
func _door_prompt(building: String) -> String:
	if building.is_empty():
		return ""
	var name := _building_name(building)
	if building != "board" and not village.is_restored(building):
		return "%s, in ruins: %s" % [name.capitalize(), Village.restored_when(building)]
	match building:
		"board": return "The map of the forest: choose where to go"
		"home": return "Your home: pack what you take"
		"smithy": return "The smithy: forge"
		"hut_0": return "The weaver's hut: looks"
		"longhouse": return "The Elder's longhouse: the book of stories"
		"watchtower": return "Jingga's watchtower: she tells you what's out there, on the board"
		"market": return "Kopi and Susu's market: trade"
		"healer": return "Bu Jamu's hut: a tonic for the next run"
	return "%s, home to two" % name.capitalize()


func _building_name(building: String) -> String:
	match building:
		"home": return "your home"
		"smithy": return "the smithy"
		"longhouse": return "the longhouse"
		"hut_0": return "the weaver's hut"
		"watchtower": return "the watchtower"
		"market": return "the market"
		"healer": return "the healer's hut"
	return "a hut"


## Enter at a door: a restored building is used (his pack, the smith's forge, the Elder's book,
## the weaver's looks); a ruin waits for the story to bring it back.
func _use(building: String) -> void:
	if building != "board" and not village.is_restored(building):
		_say("Not yet: %s" % Village.restored_when(building))
		_audio.interface("menu_back")
		return
	_shop_choice = 0
	_shop_tab = 0
	match building:
		"board":
			# The map opens on where the next run goes.
			_shop_choice = maxi(Areas.ids().find(village.next_run), 0) if village.next_run != "endless" else Areas.ids().size()
			_open_page("board")
		"home":
			_open_page("pack")
		"smithy":
			_open_page("forge")
		"longhouse":
			_open_page("book")
		"hut_0":
			_open_page("looks")
		"market":
			_open_page("market")
		"healer":
			_open_page("healer")
		"watchtower":
			_say("Jingga: \"Everything I see, I've put on the board by the gate.\"")


func _say(line: String) -> void:
	_village_message = line
	_village_message_for = 4.0


func _keep_village() -> void:
	if _keeping_settings:
		village.save()


## The shop pages' rows: what each is, where it stands, whether Enter can do anything with it,
## and its story. The board's are the map's places; the smithy's, one tab of what can be forged and
## packed; the looks'; and the book's, the story so far, a chapter a row.
func _shop_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if _page == "board":
		for area: Dictionary in Areas.LIST:
			var found := village.found(area.id)
			var free: bool = area.id in village.liberated
			var state: String = "free" if free else ("held by the company: " + area.goal.title.to_lower() if found else "not found yet")
			# From the watchtower, Jingga tells what's waiting there, and how to beat it.
			var told := ""
			if found and not free and village.is_restored("watchtower"):
				told = "%s. %s" % [Overlay.BOSS_NAMES.get(area.boss.type, area.boss.type), _sentence(area.boss.tip)]
			# Jogiboy sniffs out the caged cats there.
			var smelled := ""
			if found and not free:
				var caged := Village.caged_in(area.id)
				smelled = "Jogiboy smells %d caged %s here" % [caged, "cat" if caged == 1 else "cats"] if caged > 0 else "Jogiboy smells no cages here"
			rows.append({"id": area.id, "name": area.name if found else "Somewhere in the mist", "state": state, "can": found, "found": found, "free": free, "boss": told, "smelled": smelled})
		rows.append({"id": "endless", "name": "Endless", "state": "a fresh clearing every run", "can": true, "found": true, "free": false})
	elif _page in ["forge", "pack"]:
		var kind: String = _tabs()[_shop_tab][0]
		for id in Village.everything():
			# The pack holds what he has, and shows the mutations still to be taught, and where.
			if id.get_slice(":", 0) == kind and (_page == "forge" or kind == "mutation" or village.has(id)):
				rows.append(_forge_row(id) if _page == "forge" else _pack_row(id))
		if rows.is_empty():
			rows.append({"id": "", "name": "Nothing yet", "state": "forged at the smithy", "can": false, "story": ""})
	elif _page == "market":
		for for_what: String in Village.TRADES:
			var price: Dictionary = Village.TRADES[for_what]
			var give := "salvage" if for_what == "cloth" else "cloth"
			rows.append({"id": for_what, "name": "%d %s for %d %s" % [price[give], give, price[for_what], for_what], "state": "trade",
				"can": village.get(give) >= price[give], "story": "Kopi and Susu argue over every price, and you still get the same one."})
	elif _page == "healer":
		rows.append({"id": "tonic", "name": "Turmeric tonic", "state": "ready for the next run" if village.tonic_ready else "%d salvage" % Village.TONIC_COST,
			"can": not village.tonic_ready and village.salvage >= Village.TONIC_COST, "does": "The next run starts with %d more rerolls" % Village.TONIC_REROLLS,
			"story": "Bu Jamu's own recipe: turmeric, tamarind, and something she won't tell you. Bitter. It works."})
	elif _page == "book":
		for chapter in _chapters():
			var told: Array[String] = []
			for line: Variant in chapter.lines:
				# A line someone said is written down as theirs.
				told.append("%s: \"%s\"" % [_speaker_name(line.by), line.text] if line is Dictionary else str(line))
			rows.append({"id": chapter.name, "name": chapter.name, "state": "", "can": false, "story": " ".join(told)})
	else:
		for id: String in Village.LOOKS:
			var owned := id in village.looks
			var worn := (id == "coat:" + village.coat) or (id == "banners:" + village.banners)
			var state := "worn" if worn else ("owned: wear it?" if owned else "%d cloth" % Village.LOOKS[id].cloth)
			rows.append({"id": id, "name": Village.LOOKS[id].name, "state": state, "can": owned or village.cloth >= Village.LOOKS[id].cloth})
	return rows


## A thing at the smithy: forged already, or what forging it costs.
func _forge_row(id: String) -> Dictionary:
	var card := Upgrades.describe({"id": id, "rarity": Upgrades.Rarity.COMMON})
	var row := {"id": id, "name": card.name, "can": false, "story": card.story, "does": card.does}
	if id in Village.STARTING:
		row.state = "carried from the start"
	elif id in village.forged:
		row.state = "forged"
	else:
		row.state = "%d salvage" % Village.FORGE[id]
		row.can = village.salvage >= Village.FORGE[id]
	return row


## A thing in his pack at home, and where it stands: packed, worn from the start, or left home; or
## a dodge mutation not taught yet, and where it will be.
func _pack_row(id: String) -> Dictionary:
	var card := Upgrades.describe({"id": id, "rarity": Upgrades.Rarity.COMMON})
	var row := {"id": id, "name": card.name, "can": village.has(id) and not id in Village.ALWAYS_PACKED, "story": card.story, "does": card.does}
	if id in Village.ALWAYS_PACKED:
		row.state = "always packed"
	elif village.has(id):
		row.state = "worn from the start" if village.starting_piece == id else ("left home" if id in village.left_home else "packed")
	else:
		row.state = "not learned yet"
		for area: Dictionary in Areas.LIST:
			if id.trim_prefix("mutation:") in Areas.teaches(area.id) and village.found(area.id):
				row.state = "freeing %s teaches it" % (area.name as String).to_lower()
	return row


## The tabs of the page open: the smithy forges weapons, gear and support; the pack holds those and
## the dodge mutations.
func _tabs() -> Array[Array]:
	return THING_TABS.slice(0, 3) if _page == "forge" else THING_TABS


## A line with its first letter capitalized.
static func _sentence(text: String) -> String:
	return text.left(1).to_upper() + text.substr(1)


## Who said something, as the story writes them: the Elder, or a villager by name.
func _speaker_name(who: String) -> String:
	return "the Elder" if who == "elder" else who


## The story so far, as the book at the longhouse keeps it: the opening, then each area's going in
## and freeing, as far as they've been told.
func _chapters() -> Array[Dictionary]:
	var chapters: Array[Dictionary] = []
	if village.intro_seen:
		chapters.append({"name": "Something is wrong", "lines": INTRO})
	for area: Dictionary in Areas.LIST:
		if ("intro:" + area.id) in village.told:
			chapters.append({"name": "%s: going in" % area.name, "lines": area.before})
		if ("outro:" + area.id) in village.told:
			chapters.append({"name": "%s: freed" % area.name, "lines": area.after})
		if ("teach:" + area.id) in village.told:
			chapters.append({"name": "What %s taught" % _speaker_name(area.teaches.by), "lines": area.teaches.lines})
	if chapters.is_empty():
		chapters.append({"name": "Nothing written yet", "lines": ["The pages are empty. Go and find out what's wrong."]})
	return chapters


## A shop page: up and down choose (on the board, left and right too), left and right change the
## smithy's tab, Enter takes what's chosen (forges it, buys it, packs it, wears it, goes there), and
## Escape goes back to the village.
func _read_shop() -> void:
	var rows := _shop_rows()
	if Input.is_action_just_pressed("pause"):
		_close_page()
		_audio.interface("menu_back")
		return
	var back := Input.is_action_just_pressed("move_up")
	var on := Input.is_action_just_pressed("move_down")
	if _page == "board":
		back = back or Input.is_action_just_pressed("move_left")
		on = on or Input.is_action_just_pressed("move_right")
	elif _page in ["forge", "pack"] and (Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right")):
		_shop_tab = wrapi(_shop_tab + (1 if Input.is_action_just_pressed("move_right") else -1), 0, _tabs().size())
		_shop_choice = 0
		_audio.interface("menu_move")
		rows = _shop_rows()
	if back:
		_shop_choice = wrapi(_shop_choice - 1, 0, rows.size())
		_audio.interface("menu_move")
	if on:
		_shop_choice = wrapi(_shop_choice + 1, 0, rows.size())
		_audio.interface("menu_move")
	if Input.is_action_just_pressed("menu_choose") and _page != "book":
		var id: String = rows[_shop_choice].id
		var done := false
		if _page == "board":
			done = rows[_shop_choice].can
			if done:
				village.next_run = id
		elif _page == "forge":
			done = village.forge(id)
		elif _page == "market":
			done = village.trade(id)
		elif _page == "healer":
			done = village.brew_tonic()
		elif _page == "pack":
			# Too few of its kind packed: it stays, and the page says why.
			var why := village.cant_leave_home(id)
			var was_worn := village.starting_piece == id
			done = village.repack(id)
			if not done and village.has(id):
				_overlay.shop_note = "Not left home: " + why
			elif done and was_worn and not id in village.left_home:
				_overlay.shop_note = "Back in the pack: " + why
		else:
			done = village.buy_look(id) and village.wear_look(id)
		_audio.interface("menu_choose" if done else "menu_back")
		if done:
			_keep_village()
			village_map.cat.coat = village.coat
			_village_view.banners = village.banners
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right"):
		_overlay.shop_note = ""
	_overlay.shop_page = _page
	_overlay.shop_title = {"forge": "The smithy", "pack": "Your pack", "looks": "The weaver's hut", "board": "The map of the forest", "book": "The book of stories", "market": "The market", "healer": "The healer's hut"}[_page]
	_overlay.shop_tabs.clear()
	if _page in ["forge", "pack"]:
		for tab: Array in _tabs():
			_overlay.shop_tabs.append(tab[1])
	_overlay.shop_tab = _shop_tab
	_overlay.shop_rows = _shop_rows()
	_overlay.shop_choice = _shop_choice
	_overlay.next_run = village.next_run
	_overlay.village_record = village


func _step_village(delta: float) -> void:
	_behind = minf(_behind + delta, Arena.STEP * 5.0)
	while _behind >= Arena.STEP:
		_behind -= Arena.STEP
		village_map.step(Arena.STEP)
	_camera.position = _village_camera()


## The view follows him along the path, but never past either end; the village is a screen tall.
func _village_camera() -> Vector2:
	var screen := get_viewport().get_visible_rect().size
	var width := VillageMap.SIZE.x * World.PIXELS_PER_METER
	var x := clampf(World.to_screen(village_map.cat.body.position).x, screen.x / 2.0, width - screen.x / 2.0)
	return Vector2(x, VillageMap.SIZE.y * World.PIXELS_PER_METER / 2.0)


## Puts the outfit on him, with the weapon he chose to start with unless the outfit names its
## own.
func _dress() -> void:
	var outfit: Dictionary = OUTFITS[_outfit].duplicate()
	if (outfit.weapons as Array).is_empty():
		outfit.weapons = [_start_weapon if not _start_weapon.is_empty() else "handgun"]
	cat.wear(outfit)
	# The piece he starts in stays on: its stats were given once, when the run began.
	if _ran_from_village and not village.starting_piece.is_empty():
		var piece := village.starting_piece.trim_prefix("gear:")
		cat.gear[Upgrades.GEAR[piece].slot] = piece
		cat.gear_levels[piece] = 1


## A soft pool of light: the one smooth thing on screen.
func _soft_light(size: Vector2i) -> GradientTexture2D:
	var texture := GradientTexture2D.new()
	texture.width = size.x
	texture.height = size.y
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	texture.gradient = gradient
	return texture


func _process(delta: float) -> void:
	if not _page.is_empty():
		_read_page()
		if _page == "title":
			_step_village(delta)
		_take_screenshot(delta)
		return
	if _place == "arriving":
		_arriving(delta)
		_take_screenshot(delta)
		return
	if _place == "village":
		_in_village(delta)
		_take_screenshot(delta)
		return
	if _place == "leaving":
		_leaving(delta)
		_take_screenshot(delta)
		return
	if _briefing or _entering:
		_briefed(delta)
		_take_screenshot(delta)
		return
	if _freeing:
		_step_world(delta)
		_freeing_step(delta)
		_camera.position = World.to_screen(cat.body.position)
		_take_screenshot(delta)
		return
	_read_controls()
	if _menu_after >= 0.0 and arena.time >= _menu_after:
		_menu_after = -1.0
		_open_page("pause")
	_overlay.choosing = _start_weapon.is_empty()
	if _start_weapon.is_empty():
		_camera.position = World.to_screen(cat.body.position)
		_take_screenshot(delta)
		return
	if _down_after >= 0.0 and arena.time >= _down_after:
		_down_after = -1.0
		cat.health = 0.0
	_step_world(delta)
	# On his spot on the ground, not his height: a hop or a throw moves him in the frame.
	_camera.position = World.to_screen(cat.body.position)
	_muzzle_light.position = World.to_screen(cat.body.position, Cat.GUN_HEIGHT) + cat.aim * 10.0
	_muzzle_light.energy = 1.6 * _entities.flash.get(cat, 0.0)
	if arena.liberated and cat.alive():
		_begin_freeing()
	elif not cat.alive():
		_end_run()
	_overlay.goal = arena.goal_progress()
	_take_screenshot(delta)


## Steps the simulation to catch up with the time passed, and hands its hits to the blood and
## the sound.
func _step_world(delta: float) -> void:
	_behind = minf(_behind + delta, Arena.STEP * 5.0)
	var started := Time.get_ticks_usec()
	var steps := 0
	while _behind >= Arena.STEP:
		_behind -= Arena.STEP
		arena.step()
		steps += 1
	var events: Array[Dictionary] = arena.events.duplicate()
	arena.events.clear()
	_entities.take_events(events)
	_audio.take_events(events)
	if steps > 0:
		_overlay.step_milliseconds = (Time.get_ticks_usec() - started) / 1000.0 / steps


## He's down: the run's numbers go into the records, and its summary opens.
func _end_run() -> void:
	_note("he's down in %s" % (_run_kind if not _run_kind.is_empty() else "a development run"))
	# The best run is Endless's: a liberation run is the story, not a score.
	_beaten.clear()
	if _run_kind in ["", "endless"]:
		_beaten = records.record(Records.of(arena))
		if _keeping_settings:
			records.save()
	_bring_home()
	_overlay.summary = Records.of(arena)
	_overlay.summary.rescued = arena.rescued.size()
	_overlay.summary.salvage = arena.salvage
	_overlay.beaten = _beaten
	_open_page("summary")


## With the longhouse restored, a run from the village can start with any weapon forged.
func _forged_weapons() -> Array[String]:
	var weapons: Array[String] = []
	if not _ran_from_village or not village.is_restored("longhouse"):
		return weapons
	for id in village.forged:
		if id.begins_with("weapon:") and village.packed(id):
			weapons.append(id.trim_prefix("weapon:"))
	return weapons


## A run out from the village: into the area the map board says, or Endless. Endless is a fresh
## clearing every time; an area is the same place each time, wrecked while the company holds it
## and healed once it's free, and the first time he goes in, its story is told first.
func _start_run(run_kind: String) -> void:
	_note("run out to %s" % run_kind)
	_begin(0, true)
	_from_the_village()
	_set_up_run(run_kind)
	_enter()


## Into the run on foot, the way he came, not set down in the middle of it: the world holds still
## while he walks in, slowly enough with a story to tell for it to be told on the way, at his own
## pace without. Then he chooses what he starts with.
func _enter() -> void:
	_entering = true
	_entering_to = cat.body.position
	cat.body.position = _entering_to - Vector2(ENTRANCE, 0.0)
	cat.facing = Vector2.RIGHT
	if _cutscene == null:
		_cutscene = Cutscene.new([], settings.get_value("gameplay", "story_waits"))
	_entering_pace = Cat.SPEED
	if not _cutscene.lines.is_empty():
		_entering_pace = minf(Cat.SPEED, ENTRANCE / _cutscene.length())
	_overlay.cutscene = true
	_camera.position = World.to_screen(cat.body.position)


func _set_up_run(run_kind: String) -> void:
	_run_kind = run_kind
	_freeing = false
	if run_kind == "endless" or run_kind.is_empty():
		var fresh := randi()
		arena.random.seed = fresh
		_ground.paint("clearing", fresh, false)
		_overlay.area_name = ""
		return
	var area := Areas.named(run_kind)
	var goal_kept: bool = run_kind in village.goals_done and not run_kind in village.liberated
	arena.begin_area(run_kind, goal_kept)
	_ground.paint(area.ground, _area_seed(run_kind), run_kind in village.liberated)
	_entities._freed_areas = village.liberated
	_overlay.area_name = area.name
	# The first time in, its story; back in with its goal done before, a word on what's left.
	var lines: Array = []
	if not ("intro:" + run_kind) in village.told:
		lines = (area.before as Array).duplicate()
	elif goal_kept:
		lines = (area.get("again", []) as Array).duplicate()
	if not lines.is_empty():
		_cutscene = Cutscene.new(lines, settings.get_value("gameplay", "story_waits"))
		_briefing = true
		_music.place = "intro"


## Each area's ground is painted from its own seed, so it's the same place every time.
func _area_seed(run_kind: String) -> int:
	return absi(hash(run_kind)) % 100000


## Going in: the area's story told over it, the world held still, while he walks in if he's
## walking in. Enter hurries it; Escape skips it all, and he's there.
func _briefed(delta: float) -> void:
	var skip := Input.is_action_just_pressed("pause")
	_cutscene.step(delta, Input.is_action_just_pressed("menu_choose"), skip)
	_overlay.intro = _cutscene.written()
	_overlay.cutscene = true
	var arrived := true
	if _entering:
		if _cutscene.done():
			_entering_pace = Cat.SPEED
		var toward := _entering_to - cat.body.position
		arrived = skip or toward.length() <= _entering_pace * delta
		if arrived:
			cat.body.position = _entering_to
			cat.body.velocity = Vector2.ZERO
		else:
			cat.body.velocity = toward.normalized() * _entering_pace
			cat.body.position += cat.body.velocity * delta
	_camera.position = World.to_screen(cat.body.position)
	if (_cutscene.done() and arrived) or skip:
		if _briefing and _run_kind in Areas.ids() and not ("intro:" + _run_kind) in village.told:
			village.told.append("intro:" + _run_kind)
			_keep_village()
		_briefing = false
		_entering = false
		_cutscene = null
		_overlay.intro = ""
		_overlay.cutscene = false
		_music.place = "run"


## The boss is beaten: the horde scatters, the ground heals from where the boss fell, and the
## first time, the area's story going on is told to its own music. Then it's free.
func _begin_freeing() -> void:
	_freeing = true
	arena.spawning = false
	arena.fleeing = true
	var area := Areas.named(_run_kind)
	var first_time := not ("outro:" + _run_kind) in village.told
	var fell_at: Vector2 = arena.boss.body.position if arena.boss != null else cat.body.position
	if not _run_kind in village.liberated:
		_ground.heal(fell_at, area.ground, _area_seed(_run_kind))
	# What freeing it teaches him is taught at home, by the cat who shows him how.
	_cutscene = Cutscene.new(area.after if first_time else [], settings.get_value("gameplay", "story_waits"))
	_free_for = FREED_PAUSE
	_music.place = "freed"


func _freeing_step(delta: float) -> void:
	_free_for = maxf(_free_for - delta, 0.0)
	var skip := Input.is_action_just_pressed("pause")
	_cutscene.step(delta, Input.is_action_just_pressed("menu_choose"), skip)
	_overlay.intro = _cutscene.written()
	_overlay.cutscene = not _cutscene.lines.is_empty() and not _cutscene.done()
	# Skipped, it's over at once; left to run, it ends when its story's told and the pause is up.
	if skip or (_cutscene.done() and _free_for <= 0.0):
		_overlay.intro = ""
		_overlay.cutscene = false
		_end_liberation()


## Free: the village takes the area, and what freeing it brings the first time, and the summary
## says so.
func _end_liberation() -> void:
	_note("freed %s" % _run_kind)
	var first := village.liberate(_run_kind)
	if not ("outro:" + _run_kind) in village.told:
		village.told.append("outro:" + _run_kind)
	_bring_home()
	_overlay.summary = Records.of(arena)
	_overlay.summary.rescued = arena.rescued.size()
	_overlay.summary.salvage = arena.salvage
	_overlay.summary.freed = Areas.named(_run_kind).name
	_overlay.summary.first_time = first
	_overlay.summary.learned = []
	if first:
		for mutation in Areas.teaches(_run_kind):
			_overlay.summary.learned.append(Upgrades.MUTATIONS[mutation].name)
	_overlay.beaten.clear()
	_open_page("summary")


## A run out from the village carries what it gives: only what's packed can turn up on the cards
## (at first, what any village has lying about), he wears the piece he's chosen to start in, and his own
## coat.
func _from_the_village() -> void:
	_ran_from_village = true
	cat.coat = village.coat
	cat.locked.append_array(village.locked_for_run())
	# A tonic from the healer's hut, drunk on the way out.
	if village.tonic_ready:
		village.tonic_ready = false
		cat.rerolls += Village.TONIC_REROLLS
		_keep_village()
	if not village.starting_piece.is_empty():
		Upgrades.apply(cat, {"id": village.starting_piece, "rarity": Upgrades.Rarity.COMMON})


## What he's rescued and picked up goes home to the village, and the village is kept.
func _bring_home() -> void:
	village.bring_home(arena)
	# The goal done stays done, even if the boss still stands.
	if arena.goal_done and _run_kind in Areas.ids() and not _run_kind in village.liberated and not _run_kind in village.goals_done:
		village.goals_done.append(_run_kind)
	_just_restored.append_array(village.catch_up())
	if _keeping_settings:
		village.save()


## Home from a run: he walks back into the village on the path from the clearing.
func _go_home() -> void:
	_note("home to the village")
	_enter_village(Vector2(VillageMap.SIZE.x - 0.5, VillageMap.RETURN_SPOT.y))
	_arrive(false)


func _take_screenshot(delta: float) -> void:
	if _screenshot_path.is_empty():
		return
	_screenshot_after -= delta
	if _screenshot_after <= 0.0:
		if _frames_saved == 0:
			print("sounds played: ", _audio.played)
			print("%d frames a second, %.2f ms a step, %d in the horde" % [
				Engine.get_frames_per_second(), _overlay.step_milliseconds, arena.creatures.size()])
		_frames_saved += 1
		var path := _screenshot_path if _frames == 1 else _screenshot_path.replace(".png", "_%d.png" % _frames_saved)
		get_viewport().get_texture().get_image().save_png(path)
		_screenshot_after = 0.05
		if _frames_saved >= _frames:
			get_tree().quit()


## A line in the log for each move the game makes between places and pages, so a report of
## something going wrong can be traced: what was chosen, and where he went.
func _note(line: String) -> void:
	print("[flow] %s" % line)


func _open_page(page: String) -> void:
	_note("page %s, in %s" % [page, _place])
	_page = page
	_menu_choice = 0
	if not ONLINE or page == "summary":
		get_tree().paused = page != "title"
	_overlay.place = "village" if _place != "run" else "run"


func _close_page() -> void:
	_page = ""
	_overlay.shop_note = ""
	_overlay.shop_rows.clear()
	_overlay.page = ""
	_overlay.menu.clear()
	_overlay.setting_rows.clear()
	get_tree().paused = false


func _read_page() -> void:
	if _page == "news":
		# Read, and put away.
		if Input.is_action_just_pressed("menu_choose") or Input.is_action_just_pressed("pause"):
			_audio.interface("menu_choose")
			_overlay.news.clear()
			_close_page()
			return
		_overlay.page = "news"
		return
	if _page in ["forge", "pack", "looks", "board", "book", "market", "healer"]:
		_read_shop()
		_overlay.page = _page
		return
	if _page == "settings":
		_read_settings()
	else:
		_read_choices()
	# A choice can close its page (Play, Carry on): then there's no page left to show.
	if _page.is_empty():
		return
	_overlay.page = _page if _page != "settings" else _settings_from
	_overlay.menu = _menu_lines()
	_overlay.menu_choice = _menu_choice
	_overlay.setting_rows.clear()
	if _page == "settings":
		_overlay.setting_rows = _setting_lines()
	_overlay.setting_choice = _setting_choice


## A page of choices: up and down choose, Enter or Space takes it, Escape closes the pause menu.
func _read_choices() -> void:
	var choices: Array = PAGES[_page]
	if Input.is_action_just_pressed("pause") and _page in ["pause", "village_pause"]:
		_close_page()
		return
	if Input.is_action_just_pressed("move_up"):
		_menu_choice = wrapi(_menu_choice - 1, 0, choices.size())
		_audio.interface("menu_move")
	if Input.is_action_just_pressed("move_down"):
		_menu_choice = wrapi(_menu_choice + 1, 0, choices.size())
		_audio.interface("menu_move")
	if not Input.is_action_just_pressed("menu_choose"):
		return
	_audio.interface("menu_choose")
	_note("chose %s on %s" % [choices[_menu_choice], _page])
	match choices[_menu_choice]:
		"carry_on":
			_close_page()
		"settings":
			_settings_from = _page
			_page = "settings"
			_setting_choice = 0
		"play":
			_close_page()
			_arrive(true)
		"start_again", "go_again":
			_close_page()
			_start_weapon = ""
			_outfit = 0
			if _ran_from_village:
				_start_run(_run_kind)
			else:
				_begin(0, true)
				_set_up_run(_run_kind)
		"home":
			_close_page()
			_go_home()
		"village":
			# Giving up the run: he goes home with what he's carrying.
			_close_page()
			_bring_home()
			_go_home()
		"title":
			_close_page()
			_show_title()
		"leave":
			get_tree().quit()


## The settings page: up and down choose a row, left and right change it, Escape goes back.
func _read_settings() -> void:
	if Input.is_action_just_pressed("pause"):
		_page = _settings_from
		_reset_state = ""
		_audio.interface("menu_back")
		return
	if Input.is_action_just_pressed("move_up"):
		_setting_choice = wrapi(_setting_choice - 1, 0, SETTING_ROWS.size())
		_audio.interface("menu_move")
	if Input.is_action_just_pressed("move_down"):
		_setting_choice = wrapi(_setting_choice + 1, 0, SETTING_ROWS.size())
		_audio.interface("menu_move")
	if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("move_down") or Input.is_action_just_pressed("pause"):
		_reset_state = ""
	var row: Array = SETTING_ROWS[_setting_choice]
	var direction := 0
	if Input.is_action_just_pressed("move_left"):
		direction = -1
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("menu_choose"):
		direction = 1
	if direction == 0:
		return
	if row[1] == "back":
		if Input.is_action_just_pressed("menu_choose"):
			_page = _settings_from
		return
	if row[1] == "reset":
		if Input.is_action_just_pressed("menu_choose"):
			_reset_progress()
		return
	settings.step(row[0], row[1], direction)
	_settings_changed()
	_audio.interface("menu_choose" if direction > 0 else "menu_back")


## Reset all progress: the first press asks, the second does it. The village and the best run go
## back to nothing; the settings stay as they are. Choosing any other row first takes the
## question back.
func _reset_progress() -> void:
	if _reset_state != "asking":
		_reset_state = "asking"
		_audio.interface("menu_choose")
		return
	village.clear()
	records.clear()
	if _keeping_settings:
		village.save()
		records.save()
	_reset_state = "done"
	_audio.interface("banish")


## Puts changed settings into effect, in the run too, and keeps them.
func _settings_changed() -> void:
	settings.apply()
	if cat != null:
		cat.aim_mode = settings.get_value("gameplay", "aim")
	_entities.blood = settings.get_value("gameplay", "blood")
	if _keeping_settings:
		settings.save()


func _menu_lines() -> Array[String]:
	var lines: Array[String] = []
	var page := _page if _page != "settings" else _settings_from
	for item: String in PAGES[page]:
		lines.append({
			"play": "Play", "carry_on": "Carry on", "settings": "Settings", "start_again": "Start again",
			"go_again": "Straight back out", "title": "Back to the title", "leave": "Leave the game",
			"home": "Home to the village", "village": "Back to the village",
		}[item])
	return lines


## Each settings row as the page shows it: {section, name, value, volume}. A volume shows as a
## bar; the rest as words.
func _setting_lines() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for row: Array in SETTING_ROWS:
		var line := {"section": row[0], "name": row[2], "value": "", "volume": -1, "action": false}
		if row[1] == "reset":
			line.action = true
			line.value = {"": "", "asking": "Press again: it can't be undone", "done": "Done"}[_reset_state]
		elif row[1] != "back":
			var value: Variant = settings.get_value(row[0], row[1])
			match row[1]:
				"window_scale": line.value = "%d by %d" % [640 * int(value), 360 * int(value)]
				"aim": line.value = {"nearest": "Nearest", "toughest": "Toughest first", "crowd": "Thickest crowd"}[value]
				"blood": line.value = "On" if value else "Off: dust and fur instead"
				"story_waits": line.value = "Wait for Enter" if value else "Move on by themselves"
				_:
					if value is bool:
						line.value = "On" if value else "Off"
					else:
						line.volume = int(value)
		rows.append(line)
	return rows


func _read_controls() -> void:
	if _start_weapon.is_empty():
		var forged := _forged_weapons()
		if not forged.is_empty():
			if Input.is_action_just_pressed("move_left"):
				_start_extra = wrapi(_start_extra - 1, 0, forged.size())
				_audio.interface("menu_move")
			elif Input.is_action_just_pressed("move_right"):
				_start_extra = wrapi(_start_extra + 1, 0, forged.size())
				_audio.interface("menu_move")
		_overlay.start_extra = forged[_start_extra % forged.size()] if not forged.is_empty() else ""
		if Input.is_action_just_pressed("pick_1"):
			_start_weapon = "nunchaku"
		elif Input.is_action_just_pressed("pick_2"):
			_start_weapon = "handgun"
		elif Input.is_action_just_pressed("pick_3") and not forged.is_empty():
			_start_weapon = forged[_start_extra % forged.size()]
		if not _start_weapon.is_empty():
			_dress()
			_audio.interface("menu_choose")
		return
	cat.steering = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if _walk != Vector2.ZERO:
		cat.steering = _walk
	if Input.is_action_just_pressed("dodge"):
		cat.dodge()
	if _dodge_every > 0.0:
		_since_dodge += get_process_delta_time()
		if _since_dodge >= _dodge_every and cat.dodge():
			_since_dodge = 0.0
	if Input.is_action_just_pressed("change_gear"):
		_outfit = (_outfit + 1) % OUTFITS.size()
		_dress()
	# Cards: 1, 2 and 3 play a choice from the oldest offer; with X held, they banish it instead.
	for index in 3:
		if Input.is_action_just_pressed("pick_%d" % (index + 1)):
			if Input.is_action_pressed("banish"):
				if cat.banish(index, arena.random):
					_audio.interface("banish")
			elif cat.play(index):
				_audio.interface("card")
	if Input.is_action_just_pressed("reroll"):
		if cat.reroll(arena.random):
			_audio.interface("reroll")
	_overlay.reading = Input.is_action_pressed("read_cards") or _always_reading
	_overlay.banishing = Input.is_action_pressed("banish")
	# Shortcuts for settings: they change the saved settings, as the menu would.
	if Input.is_action_just_pressed("change_aim"):
		settings.step("gameplay", "aim", 1)
		_settings_changed()
	if Input.is_action_just_pressed("toggle_blood"):
		settings.step("gameplay", "blood", 1)
		_settings_changed()
	if Input.is_action_just_pressed("toggle_overlay"):
		_overlay.show_numbers = not _overlay.show_numbers
	if Input.is_action_just_pressed("show_kit"):
		_overlay.show_kit = not _overlay.show_kit
	if Input.is_action_just_pressed("toggle_fullscreen"):
		settings.step("graphics", "full_screen", 1)
		_settings_changed()
	if Input.is_action_just_pressed("pause"):
		_open_page("pause")
