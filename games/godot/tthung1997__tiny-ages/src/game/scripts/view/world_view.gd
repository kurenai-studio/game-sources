class_name WorldView
extends Node2D
## Draws the settlement from the simulation: the backdrop, always-present props, buildings and
## their construction sites as the world says, the strange flower, villagers walking and
## working, and the light through the day. It only reads WorldState; it never changes it.
## Call `on_world_changed()` after the simulation advances. Clicking a villager (a press and
## release without dragging) reports `villager_clicked`; resting the pointer on a named thing
## reports `hover_changed`.
##
## The world is three pages wide (WorldLayout): pages west and east of the camp have their own
## art, drawn by tools/art/cave_pages.js.

signal villager_clicked(villager_id: StringName)
## A right click on the strip: the game opens its menu.
signal menu_requested
## The pointer has rested on something long enough for its name to show (`text`, with the pointer
## at `at` in viewport pixels), or it has moved on (`text` is empty).
signal hover_changed(text: String, at: Vector2)

## How far the pointer may move between press and release and still be a click, in art pixels.
const CLICK_SLOP: float = 3.0
## How much room round the pointer still counts as resting on a thin piece, in art pixels.
const HOVER_REACH: int = 1
## How often the pointer's target is looked at again while it rests (people and the tide move).
const HOVER_REFRESH_SECONDS: float = 0.1
## A pointer that has sent no motion for this long is checked against the real mouse, because the
## desktop stops sending it once it leaves the clickable region.
const HOVER_STALE_MSEC: int = 150
## How far the real mouse may be from the last known pointer before the pointer has left, in art
## pixels.
const HOVER_LEFT_DISTANCE: float = 6.0

var _sim: Simulation
var _window: DesktopWindow
var _planner: VillagerPlanner = VillagerPlanner.new()
var _full_scene: bool = true
var _clip: Control = Control.new()
var _world: Node2D = Node2D.new()
var _ui: ScrollUi = ScrollUi.new()
var _camera: ScrollCamera = ScrollCamera.new(
	float(WorldLayout.WORLD_LEFT), float(WorldLayout.WORLD_RIGHT - WorldLayout.VIEW_SIZE.x), 0.0
)
var _backdrop: Dictionary = {}
var _static_layers: Array[Sprite2D] = []
var _buildings: Dictionary = {}
var _sites: Dictionary = {}
var _props: Dictionary = {}
var _layout: LaneLayout = LaneLayout.new()
var _art_era: int = -1
var _outfit: StringName = VillagerOutfit.FUR
var _flower_sprout: Sprite2D
var _flower_bloom: Sprite2D
var _fire_pit: Sprite2D
var _fire_glow: Sprite2D
var _beacon_glow: Sprite2D
var _glow_key: String = ""
var _skyline_tops: PackedInt32Array = PackedInt32Array()
var _skyline_stamp: int = 0
var _beacon_frames: Array[Texture2D] = []
var _beacon_frame: int = 0
var _beacon_clock: float = 0.0
var _fire_frames: Array[Texture2D] = []
var _fire_frame: int = 0
var _fire_clock: float = 0.0
var _sea: Sprite2D
var _sea_frames: Array[Texture2D] = []
var _sea_sets: Array = []
var _sea_state: int = WeatherLook.SEA_CALM
var _sea_frame: int = 0
var _sea_clock: float = 0.0
var _flats: Sprite2D
var _flats_sets: Array = []
var _flats_step: int = 0
var _life: Sprite2D
var _life_west: Sprite2D
var _life_west_frames: Array[Texture2D] = []
var _life_frames: Array[Texture2D] = []
var _life_frame: int = 0
var _life_clock: float = 0.0
var _deer: Sprite2D
var _deer_frames: Array[Texture2D] = []
var _stars: Sprite2D
var _sun: Sprite2D
var _moon: Sprite2D
var _actors: Dictionary = {}
var _tint: CanvasModulate = CanvasModulate.new()
var _signature: String = ""
var _dragging: bool = false
var _drag_mouse_x: float = 0.0
var _press_position: Vector2 = Vector2.ZERO
var _drag_camera_x: float = 0.0
var _applied_pixel: int = -999999
var _season_ground: ShaderMaterial = ShaderMaterial.new()
var _season_trees: ShaderMaterial = ShaderMaterial.new()
var _applied_season: int = -1
var _season_overlays: Array[Sprite2D] = []
var _weather: WeatherLayer = WeatherLayer.new()
var _landmark_sources: Dictionary = {}
var _alpha: AlphaHit = AlphaHit.new()
var _dwell: HoverDwell = HoverDwell.new()
var _pointer: Vector2 = Vector2.ZERO
var _pointer_in: bool = false
var _pointer_pinned: bool = false
var _pointer_msec: int = 0
var _hover_text: String = ""
var _hover_clock: float = 0.0
var _hover_suppressed: bool = false
var _tip_text: String = ""

const SEASON_SHADER: String = "res://assets/world/season_palette.gdshader"


func setup(sim: Simulation, window: DesktopWindow) -> void:
	_sim = sim
	_window = window
	_clip.size = Vector2(WorldLayout.VIEW_SIZE)
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_clip)
	_clip.add_child(_world)
	var shader: Shader = load(SEASON_SHADER) as Shader
	if shader == null:
		push_error("Missing season shader: %s" % SEASON_SHADER)
	_season_ground.shader = shader
	_season_trees.shader = shader
	_world.material = _season_ground
	_stars = _make_sky_sprite(_load_art(WorldLayout.STARS))
	_sun = _make_sky_sprite(_celestial(0))
	_moon = _make_sky_sprite(_celestial(1))
	add_child(_weather)
	_weather.setup(_clip)
	add_child(_tint)
	for index: int in WorldLayout.BACKDROP.size():
		var layer: StringName = WorldLayout.BACKDROP[index]
		_backdrop[layer] = _make_backdrop_pages(layer, -100 + index)
		if layer == &"trees":
			for trees: Sprite2D in _backdrop[layer]:
				trees.use_parent_material = false
				trees.material = _season_trees
	_sea = _make_sprite(
		WorldLayout.sea_frame_name(0), WorldLayout.SEA_Z, float(WorldLayout.SIDE_PAGES["east_"])
	)
	for state: int in WorldLayout.SEA_STATE_PREFIX.size():
		var frames: Array[Texture2D] = []
		for frame: int in WorldLayout.SEA_FRAMES:
			frames.append(_load_art(WorldLayout.sea_frame_name(frame, state)))
		_sea_sets.append(frames)
	_sea_frames = _sea_sets[WeatherLook.SEA_CALM]
	var east_x: float = float(WorldLayout.SIDE_PAGES["east_"])
	_flats = _make_sprite(WorldLayout.flats_frame_name(1, 0), WorldLayout.FLATS_Z, east_x)
	for step: int in range(1, WorldLayout.FLATS_STEPS + 1):
		var flats_frames: Array[Texture2D] = []
		for frame: int in WorldLayout.FLATS_FRAMES:
			flats_frames.append(_load_art(WorldLayout.flats_frame_name(step, frame)))
		_flats_sets.append(flats_frames)
	_life = _make_sprite(WorldLayout.life_frame_name(0), WorldLayout.LIFE_Z, east_x)
	_deer = _make_sprite(WorldLayout.deer_frame_name(0), WorldLayout.DEER_Z, east_x)
	_life_west = _make_sprite(WorldLayout.life_frame_name(0), WorldLayout.LIFE_Z, WorldLayout.LIFE_WEST_X)
	for frame: int in WorldLayout.LIFE_FRAMES:
		_life_frames.append(_load_art(WorldLayout.life_frame_name(frame)))
		var half: AtlasTexture = AtlasTexture.new()
		half.atlas = _life_frames[frame]
		half.region = Rect2(0, 0, WorldLayout.LIFE_WEST_WIDTH, WorldLayout.VIEW_SIZE.y)
		_life_west_frames.append(half)
	_life_west.texture = _life_west_frames[1]
	for frame: int in WorldLayout.DEER_FRAMES:
		_deer_frames.append(_load_art(WorldLayout.deer_frame_name(frame)))
	for layer: StringName in WorldLayout.STATIC_Z:
		var camp_layer: Sprite2D = _make_sprite(layer, WorldLayout.STATIC_Z[layer])
		camp_layer.set_meta(&"layer", layer)
		_static_layers.append(camp_layer)
		_landmark_sources[layer] = camp_layer
	for prefix: String in WorldLayout.SIDE_PAGES:
		for layer: StringName in WorldLayout.SIDE_STATIC[prefix]:
			var side: Sprite2D = _make_sprite(
				StringName(prefix + layer), WorldLayout.STATIC_Z[layer],
				float(WorldLayout.SIDE_PAGES[prefix])
			)
			side.set_meta(&"layer", StringName(prefix + layer))
			_static_layers.append(side)
	for building_id: StringName in WorldLayout.BUILDINGS:
		var z: int = WorldLayout.BUILDINGS[building_id]["z"]
		var lift: Vector2 = WorldLayout.building_offset(building_id)
		_buildings[building_id] = _make_piece(
			StringName("building_%s" % building_id), z, lift.x, lift.y
		)
		_sites[building_id] = _make_piece(StringName("site_%s" % building_id), z, lift.x, lift.y)
	for prop_id: StringName in SceneProps.ids():
		_props[prop_id] = _make_piece(
			prop_id, SceneProps.z_of(prop_id), SceneProps.at_x_of(prop_id), SceneProps.at_y_of(prop_id)
		)
	_flower_sprout = _make_sprite(&"flower_sprout", WorldLayout.FLOWER_Z)
	_flower_bloom = _make_sprite(&"flower_bloom", WorldLayout.FLOWER_Z)
	_fire_pit = _make_sprite(WorldLayout.fire_frame_name(0), WorldLayout.FIRE_PIT_Z)
	for frame: int in WorldLayout.FIRE_FRAMES:
		_fire_frames.append(_load_art(WorldLayout.fire_frame_name(frame)))
	_fire_glow = _make_sprite(WorldLayout.FIRE_GLOW, WorldLayout.FIRE_GLOW_Z)
	var additive: CanvasItemMaterial = CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_fire_glow.material = additive
	_fire_glow.use_parent_material = false
	_beacon_glow = _make_piece(
		WorldLayout.BEACON_GLOW, WorldLayout.FIRE_GLOW_Z, float(WorldLayout.SIDE_PAGES["east_"])
	)
	_beacon_glow.material = additive
	_beacon_glow.use_parent_material = false
	for frame: int in WorldLayout.BEACON_FRAMES:
		_beacon_frames.append(_load_piece(WorldLayout.beacon_frame_name(frame), WorldLayout.ERA_DIRS.size() - 1))
	_ui.layout(float(WorldLayout.VIEW_SIZE.x))
	_ui.z_index = 1000
	_ui.pan_requested.connect(func(direction: int) -> void: pan_by(direction * WorldLayout.PAN_STEP))
	add_child(_ui)
	_apply_camera()
	on_world_changed()


## Only the opaque window shows the sky; on the desktop it would cover other apps, so strip and
## corner mode keep the far mountains, near hills, tree line and ground.
func set_full_scene(full: bool) -> void:
	_full_scene = full
	for layer: StringName in _backdrop:
		var shown: bool = full or WorldLayout.DESKTOP_BACKDROP.has(layer)
		for sprite: Sprite2D in _backdrop[layer]:
			sprite.visible = shown
	if _sim != null:
		_weather.apply(_sim.world, _full_scene)
		_seat_light()
		update_light()


## Glides the camera by `amount` art pixels (negative is west).
func pan_by(amount: float) -> void:
	_camera.pan_by(amount)
	_apply_camera()


## Puts the camera's left edge at camp pixel `x` straight away.
func jump_camera(x: float) -> void:
	_camera.jump_to(x)
	_apply_camera()


func recenter() -> void:
	_camera.glide_to(0.0)
	_apply_camera()


## The whole-pixel left edge of the viewport, in camp pixels (0 is the camp page).
func camera_x() -> int:
	return _camera.pixel_x()


## Areas that must stay clickable in strip mode (the pan arrows), in viewport art pixels.
func clickable_regions() -> Array[Rect2i]:
	var regions: Array[Rect2i] = _ui.clickable_regions()
	if covers_sky():
		regions.append(Rect2i(Vector2i.ZERO, WorldLayout.VIEW_SIZE))
	return regions


## Whether rain or snow is falling across the whole viewport with no sky drawn behind it (strip and
## corner mode), so the viewport is drawn, and therefore clickable, while it lasts.
func covers_sky() -> bool:
	return _weather.covers_sky()


func on_world_changed() -> void:
	_refresh_season()
	_refresh_life()
	_refresh_props()
	_refresh_actors()
	_weather.apply(_sim.world, _full_scene)
	update_light()
	_refresh_hover()


## Re-tints the scene for the current time of day, season and weather. Cheap enough to call every
## frame.
func update_light() -> void:
	var hour: float = DayNight.hour_of_world(_sim.world, _sim.config)
	var lit: bool = _sim.world.has_fire()
	var season: int = _sim.config.season_at(_sim.world.tick)
	var tint: Color = DayNight.tint(hour, lit) * SeasonLook.tint(season) \
			* WeatherLook.tint(_sim.world.weather)
	_tint.color = tint
	_sea.modulate = SeasonLook.sea_tint(season) * WeatherLook.sea_tint(_sim.world.weather)
	_set_sea_state(WeatherLook.sea_state(_sim.world.weather))
	# The tint dims every piece, so the glow is boosted back to its own colour and only fades
	# in with the dark.
	var strength: float = DayNight.night_amount(hour) if lit else 0.0
	_fire_glow.visible = strength > 0.0
	_fire_glow.modulate = Color(
		1.0 / tint.r, 1.0 / tint.g, 1.0 / tint.b,
		strength * WorldLayout.FIRE_GLOW_FLICKER[_fire_frame]
	)
	# The beacon burns on its own, fire in the camp or not, so its light only needs the dark.
	var night: float = DayNight.night_amount(hour)
	_beacon_glow.visible = night > 0.0 and _east_light_shown()
	_beacon_glow.modulate = Color(
		1.0 / tint.r, 1.0 / tint.g, 1.0 / tint.b,
		night * WorldLayout.FIRE_GLOW_FLICKER[_beacon_frame]
	)
	_update_sky(hour, tint)


## The sun and the moon cross the sky and the stars come out, but only where the sky is drawn
## (the opaque window); on the desktop none of it exists. The moon and the stars are boosted back
## to their own colour like the glow; the sun takes the tint, so it reddens at dawn and dusk.
func _update_sky(hour: float, tint: Color) -> void:
	var sun_at: Vector2 = DayNight.sun_position(hour) if _full_scene else Vector2.INF
	var moon_at: Vector2 = DayNight.moon_position(hour) if _full_scene else Vector2.INF
	_place_body(_sun, sun_at)
	_place_body(_moon, moon_at)
	var stars: float = DayNight.star_alpha(hour) if _full_scene else 0.0
	_stars.visible = stars > 0.0
	var boost: Color = Color(1.0 / tint.r, 1.0 / tint.g, 1.0 / tint.b)
	_stars.modulate = Color(boost.r, boost.g, boost.b, stars)
	_moon.modulate = boost


## Puts a sky body's centre at `at` on whole pixels, or hides it if it is below the horizon.
func _place_body(body: Sprite2D, at: Vector2) -> void:
	body.visible = at.is_finite()
	if body.visible:
		body.position = (at - Vector2(WorldLayout.CELESTIAL_CELL) / 2.0).round()


## The fire flickers by swapping its flame frame on a slow clock. It does nothing at all while
## there is no fire or none of the light is on screen.
func _animate_fire(delta: float) -> void:
	if not _fire_pit.visible:
		return
	var left: float = float(_camera.pixel_x())
	if left > WorldLayout.FIRE_LIGHT_X.y or left + float(WorldLayout.VIEW_SIZE.x) < WorldLayout.FIRE_LIGHT_X.x:
		return
	_fire_clock += delta
	if _fire_clock < WorldLayout.FIRE_FRAME_SECONDS:
		return
	_fire_clock = 0.0
	set_fire_frame(_fire_frame + 1)


## The beacon's flame dances on the fire's clock: it sleeps unless the beacon is lit and some of its
## light is on screen.
func _animate_beacon(delta: float) -> void:
	if not _east_light_shown():
		return
	var lit_x: Vector2 = WorldLayout.LIGHTHOUSE_LIGHT_X \
			if _light_carrier() == &"east_harbour" else WorldLayout.BEACON_LIGHT_X
	lit_x += Vector2(_light_shift(), _light_shift())
	var left: float = float(_camera.pixel_x())
	if left > lit_x.y or left + float(WorldLayout.VIEW_SIZE.x) < lit_x.x:
		return
	_beacon_clock += delta
	if _beacon_clock < WorldLayout.FIRE_FRAME_SECONDS:
		return
	_beacon_clock = 0.0
	set_beacon_frame(_beacon_frame + 1)


## The east shore's light: the beacon from the Iron Age, and from the Classical Age the lighthouse of
## the harbour, which takes its place (and its night light, `east_beacon_glow` in the Classical folder).
## It only burns while its piece has a space and is drawn.
func _east_light_shown() -> bool:
	return _light_carrier() != &""


func set_beacon_frame(frame: int) -> void:
	_beacon_frame = posmod(frame, WorldLayout.BEACON_FRAMES)
	(_props[WorldLayout.BEACON] as Sprite2D).texture = _beacon_frames[_beacon_frame]
	update_light()


func set_fire_frame(frame: int) -> void:
	_fire_frame = posmod(frame, WorldLayout.FIRE_FRAMES)
	_fire_pit.texture = _fire_frames[_fire_frame]
	update_light()


## Swaps to the frames of a calmer or rougher sea, keeping the phase so the swell does not jump.
func _set_sea_state(state: int) -> void:
	if state == _sea_state:
		return
	_sea_state = state
	_sea_frames = _sea_sets[state]
	_sea.texture = _sea_frames[_sea_frame]


## The sea swaps its surf and swell phase on a slow clock. It does nothing while the view is
## hidden or none of the sea is on screen.
func _animate_sea(delta: float) -> void:
	if not visible or not _sea.visible:
		return
	if float(_camera.pixel_x()) + float(WorldLayout.VIEW_SIZE.x) <= WorldLayout.SEA_X.x:
		return
	_sea_clock += delta
	if _sea_clock < WorldLayout.SEA_FRAME_SECONDS * WeatherLook.swell_scale(_sim.world.weather):
		return
	_sea_clock = 0.0
	_sea_frame = posmod(_sea_frame + 1, WorldLayout.SEA_FRAMES)
	_sea.texture = _sea_frames[_sea_frame]
	_show_flats_frame()


## The flats' foam laps in step with the sea's swell.
func _show_flats_frame() -> void:
	if _flats_step > 0:
		_flats.texture = _flats_sets[_flats_step - 1][_sea_frame]


## The fish and birds swap frames on a slow clock, and do nothing while none of the river's far
## side is on screen.
func _animate_life(delta: float) -> void:
	if not visible:
		return
	var left: float = float(_camera.pixel_x())
	var right: float = left + float(WorldLayout.VIEW_SIZE.x)
	if right <= WorldLayout.LIFE_X.x or left >= WorldLayout.LIFE_X.y:
		return
	_life_clock += delta
	if _life_clock < WorldLayout.LIFE_FRAME_SECONDS:
		return
	_life_clock = 0.0
	_life_frame += 1
	_life.texture = _life_frames[posmod(_life_frame, WorldLayout.LIFE_FRAMES)]
	_life_west.texture = _life_west_frames[posmod(_life_frame + 1, WorldLayout.LIFE_FRAMES)]
	_deer.texture = _deer_frames[posmod(floori(float(_life_frame) / 2.0), WorldLayout.DEER_FRAMES)]


## The deer comes down to drink at dawn and dusk; the tide bares the flats and covers them again.
## Both are decided by the world's clock, so there is nothing to animate.
func _refresh_life() -> void:
	var hour: float = DayNight.hour_of_world(_sim.world, _sim.config)
	_deer.visible = RiverLife.deer_visible(hour)
	var step: int = TideLook.flats_step(_sim.config.tide_at(_sim.world.tick))
	_flats.visible = step > 0
	if step != _flats_step:
		_flats_step = step
		_show_flats_frame()


func _process(delta: float) -> void:
	if _camera.step(delta):
		_apply_camera()
	_animate_fire(delta)
	_animate_beacon(delta)
	_animate_sea(delta)
	_animate_life(delta)
	_update_hover(delta)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		_stop_hover()


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null:
		_handle_button(button)
		return
	var motion := event as InputEventMouseMotion
	if motion != null:
		if _dragging:
			_camera.jump_to(_drag_camera_x - (motion.position.x - _drag_mouse_x))
			_apply_camera()
		_pointer_pinned = false
		_track_pointer(motion.position)


func _handle_button(button: InputEventMouseButton) -> void:
	_hover_suppressed = true
	_dwell.clear()
	_sync_tooltip()
	match button.button_index:
		MOUSE_BUTTON_LEFT:
			if not button.pressed:
				var was_dragging: bool = _dragging
				_dragging = false
				if was_dragging and button.position.distance_to(_press_position) <= CLICK_SLOP:
					_report_click(button.position)
			elif _clip.get_global_rect().has_point(button.position):
				_dragging = true
				_press_position = button.position
				_drag_mouse_x = button.position.x
				_drag_camera_x = _camera.shown
		MOUSE_BUTTON_RIGHT:
			if button.pressed and _clip.get_global_rect().has_point(button.position):
				menu_requested.emit()
		MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT:
			if button.pressed:
				pan_by(WorldLayout.WHEEL_STEP)
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT:
			if button.pressed:
				pan_by(-WorldLayout.WHEEL_STEP)


func _report_click(at: Vector2) -> void:
	var id: StringName = villager_at(at)
	if id != &"":
		villager_clicked.emit(id)


## The villager standing at a point of the window (art pixels), or &"" if none. When two overlap
## the one in front, whose feet are lower on screen, wins. Hidden (asleep or away) villagers
## cannot be clicked.
func villager_at(at: Vector2) -> StringName:
	return _front_villager(_world.to_local(at))


## The one villager that both clicking and hovering name at a world point: the lowest feet win,
## and the first of two level villagers wins, so the tooltip never names someone else.
func _front_villager(point: Vector2) -> StringName:
	var found: StringName = &""
	var front: float = -INF
	for id: StringName in _actors:
		var actor: VillagerActor = _actors[id]
		if actor.visible and actor.hit_rect().has_point(point) and actor.position.y > front:
			front = actor.position.y
			found = id
	return found


## The front-most named thing at a point of the window (art pixels), or null if there is none:
## props, buildings and their sites, the fire, the flower, the river's life, the camp's landmarks
## and villagers. Only what is drawn counts, so nothing the group has not earned is ever named. The
## one in front wins, as clicking does; a villager wins a tie with a prop.
func thing_at(at: Vector2) -> HoverHit:
	var point: Vector2 = _world.to_local(at)
	var found: HoverHit = null
	for prop_id: StringName in _props:
		found = HoverHit.in_front(found, _sprite_hit(
			_props[prop_id], point, StringName("prop:%s" % prop_id), SceneProps.name_of(prop_id)
		))
	for building_id: StringName in _buildings:
		var label: String = _building_name(building_id)
		found = HoverHit.in_front(found, _sprite_hit(
			_buildings[building_id], point, StringName("building:%s" % building_id), label
		))
		found = HoverHit.in_front(found, _sprite_hit(
			_sites[building_id], point, StringName("site:%s" % building_id),
			"%s, being built" % label if not label.is_empty() else ""
		))
	var flower: Sprite2D = _flower_bloom if _flower_bloom.visible else _flower_sprout
	found = HoverHit.in_front(found, _sprite_hit(flower, point, &"flower", _flower_name()))
	if WorldLayout.FIRE_HIT.has_point(point):
		found = HoverHit.in_front(found, _sprite_hit(_fire_pit, point, &"fire", "Fire"))
	found = HoverHit.in_front(found, _sprite_hit(_deer, point, &"deer", "Deer"))
	for landmark_id: StringName in WorldLandmarks.ids():
		found = HoverHit.in_front(found, _landmark_hit(landmark_id, point))
	var villager: StringName = _front_villager(point)
	if villager != &"":
		found = HoverHit.in_front(found, HoverHit.make(
			StringName("villager:%s" % villager), _villager_name(villager),
			int((_actors[villager] as VillagerActor).position.y)
		))
	return found


## A hit on a sprite that is showing and has an opaque pixel (give or take `HOVER_REACH`) under the
## point, or null.
func _sprite_hit(sprite: Sprite2D, point: Vector2, key: StringName, text: String) -> HoverHit:
	if not sprite.visible or text.is_empty():
		return null
	if not _alpha.opaque_near(sprite.texture, point - sprite.position, HOVER_REACH):
		return null
	return HoverHit.make(key, text, sprite.z_index)


func _landmark_hit(id: StringName, point: Vector2) -> HoverHit:
	if not WorldLandmarks.contains(id, point):
		return null
	var source: Sprite2D = _landmark_sources.get(WorldLandmarks.source_of(id))
	if source != null and not _alpha.opaque_near(
		source.texture, point - source.position, HOVER_REACH
	):
		return null
	return HoverHit.make(
		StringName("landmark:%s" % id), WorldLandmarks.name_of(id, _sim.world.era_order),
		WorldLandmarks.z_of(id)
	)


func _building_name(building_id: StringName) -> String:
	var def: BuildingDef = _sim.content.get_building(building_id)
	return def.display_name if def != null else ""


func _flower_name() -> String:
	if _sim.world.plants.is_empty():
		return ""
	var def: PlantDef = _sim.content.get_plant(_sim.world.plants[0].def_id)
	return def.display_name if def != null else ""


func _villager_name(id: StringName) -> String:
	for villager: VillagerState in _sim.world.villagers:
		if villager.id == id:
			return VillagerPresenter.tooltip_for(villager)
	return ""


## The pointer moved to `at`. A tooltip is only for a pointer resting over the view.
func _track_pointer(at: Vector2) -> void:
	_hover_suppressed = false
	_pointer_msec = Time.get_ticks_msec()
	if _dragging or not _clip.get_global_rect().has_point(at):
		_stop_hover()
		return
	_pointer = at
	_pointer_in = true
	_refresh_hover()


## Looks at what is under the pointer; a different thing starts the wait for its tooltip again.
func _refresh_hover() -> void:
	if not _pointer_in or _hover_suppressed or _dragging:
		return
	var hit: HoverHit = thing_at(_pointer)
	_hover_text = hit.text if hit != null else ""
	_dwell.point_at(hit.key if hit != null else &"")
	_sync_tooltip()


## For looking at tooltips (--hover=): rests the pointer at `at` (viewport pixels) and shows what it
## names straight away. It stays there however the real mouse moves.
func rest_pointer_at(at: Vector2) -> void:
	_pointer_pinned = true
	_track_pointer(at + _clip.global_position)
	_dwell.advance(HoverDwell.DELAY_SECONDS)
	_sync_tooltip()


## Puts away whatever the world was naming, because something else (the strip's icons) names now.
func release_pointer() -> void:
	_stop_hover()


func _stop_hover() -> void:
	_pointer_in = false
	_dwell.clear()
	_sync_tooltip()


## Does nothing at all unless the pointer is over the view.
func _update_hover(delta: float) -> void:
	if not _pointer_in:
		return
	_hover_clock += delta
	if _hover_clock >= HOVER_REFRESH_SECONDS:
		_hover_clock = 0.0
		if _pointer_has_left():
			_stop_hover()
			return
		_refresh_hover()
	_dwell.advance(delta)
	_sync_tooltip()


## Tells the game when the tooltip should show or go away.
func _sync_tooltip() -> void:
	var text: String = _hover_text if _dwell.is_ready() else ""
	if text == _tip_text:
		return
	_tip_text = text
	hover_changed.emit(text, _pointer - _clip.global_position)


## The desktop sends no motion once the pointer is over the part of the strip that is click-through,
## so a pointer that has been quiet for a moment is checked against the real mouse. Only a window
## that floats on the desktop needs it.
func _pointer_has_left() -> bool:
	if _pointer_pinned or _window == null or not _window.is_inside_tree() \
			or _window.mode == DesktopWindow.Mode.WINDOW:
		return false
	if Time.get_ticks_msec() - _pointer_msec < HOVER_STALE_MSEC:
		return false
	var window: Window = _window.get_window()
	if window.content_scale_size.x <= 0 or window.content_scale_size.y <= 0:
		return false
	var ratio: Vector2 = Vector2(window.size) / Vector2(window.content_scale_size)
	var mouse: Vector2 = Vector2(DisplayServer.mouse_get_position() - window.position) / ratio
	return mouse.distance_to(_pointer) > HOVER_LEFT_DISTANCE


func _apply_camera() -> void:
	var pixel: int = _camera.pixel_x()
	_ui.update_state(
		_camera.can_go(-1), _camera.can_go(1), WorldLayout.PAGE_COUNT,
		_camera.page_index(float(WorldLayout.VIEW_SIZE.x)),
	)
	if pixel == _applied_pixel:
		return
	_applied_pixel = pixel
	_world.position.x = -float(pixel)
	if _window != null:
		_window.set_scroll(pixel - WorldLayout.WORLD_LEFT)
	_refresh_hover()


func _refresh_props() -> void:
	var world: WorldState = _sim.world
	if world.era_order != _art_era:
		_art_era = world.era_order
		_retexture_pieces()
	_layout = LanePlacer.place(world)
	var site: BuildingState = world.constructing()
	for building_id: StringName in _buildings:
		var placed: bool = _layout.is_placed(building_id)
		var building: Sprite2D = _buildings[building_id]
		var building_site: Sprite2D = _sites[building_id]
		building.visible = placed and WorldLayout.building_shown(building_id, world)
		building_site.visible = placed and site != null and site.def_id == building_id
		_seat(building, building_id)
		_seat(building_site, building_id)
	for prop_id: StringName in _props:
		var prop: Sprite2D = _props[prop_id]
		prop.visible = SceneProps.is_shown(prop_id, world) and _layout.is_drawn(prop_id)
		prop.position = _prop_pos(prop_id)
		prop.z_index = SceneProps.z_of(prop_id)
		if LanePieces.is_on_prop_foot(LanePieces.key_of(prop_id)) and _layout.is_placed(LanePieces.key_of(prop_id)):
			prop.z_index = mini(prop.z_index, WorldLayout.PROP_FOOT - 1)
	_seat_light()
	var planted: bool = not world.plants.is_empty()
	var bloomed: bool = planted and world.plants[0].flowered
	_flower_sprout.visible = planted and not bloomed
	_flower_bloom.visible = bloomed
	_fire_pit.visible = world.has_fire()
	var signature: String = _shape_signature()
	if signature != _signature:
		_signature = signature
		_rebuild_skyline()


## Puts a building's art in the middle of its spaces, if it has some (and on the prop foot row if
## it is a prop-lane piece, like the knapping spot).
func _seat(sprite: Sprite2D, building_id: StringName) -> void:
	if not _layout.is_placed(building_id):
		return
	var art: Rect2i = LanePieces.art_rect(sprite.get_meta(&"layer"), _art_era)
	if art.size.x > 0:
		sprite.position.x = _layout.sprite_x(building_id, art)
		if LanePieces.is_on_prop_foot(building_id):
			sprite.position.y = float(WorldLayout.PROP_FOOT - (art.end.y - 1))
			sprite.z_index = mini(sprite.z_index, WorldLayout.PROP_FOOT - 1)


## Where a prop's sprite goes: the middle of its spaces, on the prop foot row if it is on one; an
## overlay (the dyed cloth) moves with the piece under it; backdrop stays where it was drawn.
func _prop_pos(prop_id: StringName) -> Vector2:
	var home: Vector2 = Vector2(SceneProps.at_x_of(prop_id), SceneProps.at_y_of(prop_id))
	var spec: Dictionary = SceneProps.PROPS[prop_id]
	if spec.has("overlays"):
		var base: StringName = spec["overlays"]
		var base_home: Vector2 = Vector2(SceneProps.at_x_of(base), SceneProps.at_y_of(base))
		return _prop_pos(base) - base_home + home
	var key: StringName = LanePieces.key_of(prop_id)
	if LanePieces.has(prop_id) and _layout.is_placed(key):
		var art: Rect2i = LanePieces.art_rect(prop_id, _art_era)
		if art.size.x > 0:
			var y: float = home.y
			if LanePieces.is_on_prop_foot(key):
				y = float(WorldLayout.PROP_FOOT - (art.end.y - 1))
			return Vector2(_layout.sprite_x(key, art), y)
	return home


## The east shore's night light is drawn with its piece, so it moves with the piece it belongs to:
## the harbour's lighthouse once there is a harbour, else the beacon.
func _light_carrier() -> StringName:
	for id: StringName in [&"east_harbour", &"east_beacon"]:
		if (_props[id] as Sprite2D).visible:
			return id
	return &""


## How far the east shore's light has moved from where its art was drawn.
func _light_shift() -> float:
	var carrier: StringName = _light_carrier()
	if carrier == &"":
		return 0.0
	return (_props[carrier] as Sprite2D).position.x - SceneProps.at_x_of(carrier)


## The glow is drawn for the piece that carries it: the beacon's own light until the harbour's
## lighthouse takes its place, so a beacon still standing in the Classical Age keeps its own.
## On the desktop there is no sky and Windows draws only inside the click region, so the light is
## cut off above the skyline; otherwise it would show in the columns the icons add to the region.
func _seat_light() -> void:
	var carrier: StringName = _light_carrier()
	if carrier == &"":
		return
	var era: int = WorldLayout.BEACON_ERA if carrier == &"east_beacon" else _art_era
	_beacon_glow.position.x = float(WorldLayout.SIDE_PAGES["east_"]) + _light_shift()
	var key: String = "%s|%d|%d|%s|%d" % [
		carrier, era, int(_beacon_glow.position.x), _full_scene, _skyline_stamp
	]
	if key == _glow_key:
		return
	_glow_key = key
	var texture: Texture2D = _load_piece(WorldLayout.BEACON_GLOW, era)
	_beacon_glow.texture = texture if _full_scene else _above_skyline_cleared(texture)


## A copy of a full-page light with everything above the skyline cleared. The light's columns are
## the world's columns from where the glow sprite stands.
func _above_skyline_cleared(texture: Texture2D) -> Texture2D:
	var image: Image = texture.get_image()
	image.convert(Image.FORMAT_RGBA8)
	var origin: int = int(_beacon_glow.position.x) - WorldLayout.WORLD_LEFT
	for x: int in image.get_width():
		var column: int = origin + x
		var top: int = image.get_height()
		if column >= 0 and column < _skyline_tops.size():
			top = mini(_skyline_tops[column], top)
		for y: int in top:
			image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
	return ImageTexture.create_from_image(image)


## The season's palette on the scrolling world, and the few pieces it adds (snow, blossom,
## leaves). Only does anything when the season turns.
func _refresh_season() -> void:
	var season: int = _sim.config.season_at(_sim.world.tick)
	if season == _applied_season:
		return
	_applied_season = season
	for key: StringName in SeasonLook.params(season):
		_season_ground.set_shader_parameter(key, SeasonLook.params(season)[key])
	for key: StringName in SeasonLook.tree_params(season):
		_season_trees.set_shader_parameter(key, SeasonLook.tree_params(season)[key])
	_rebuild_season_overlays(season)


func _rebuild_season_overlays(season: int) -> void:
	for old: Sprite2D in _season_overlays:
		old.queue_free()
	_season_overlays.clear()
	for layer: StringName in SeasonOverlay.LAYERS:
		for sprite: Sprite2D in _backdrop.get(layer, []):
			var source: Image = sprite.texture.get_image() if sprite.texture != null else null
			if source == null or source.is_empty():
				continue
			var overlay: Image = SeasonOverlay.build(source, layer, season)
			if overlay == null:
				continue
			var piece: Sprite2D = Sprite2D.new()
			piece.centered = false
			piece.use_parent_material = true
			piece.position = sprite.position
			piece.z_index = sprite.z_index
			piece.texture = ImageTexture.create_from_image(overlay)
			_world.add_child(piece)
			_season_overlays.append(piece)


func _refresh_actors() -> void:
	var world: WorldState = _sim.world
	var outfit: StringName = VillagerOutfit.for_world(world)
	if outfit != _outfit:
		_outfit = outfit
		for existing: VillagerActor in _actors.values():
			existing.set_sheet(_sheet_for(existing.get_meta(&"look")))
	var present: Dictionary = {}
	for villager: VillagerState in world.villagers:
		present[villager.id] = true
	for id: StringName in _actors.keys():
		if not present.has(id):
			(_actors[id] as VillagerActor).queue_free()
			_actors.erase(id)
	var plans: Array[VillagerPlan] = []
	for slot: int in world.villagers.size():
		plans.append(_planner.plan(world.villagers[slot], world, _sim.config, slot, _layout))
	VillagerPlanner.spread(plans)
	for slot: int in world.villagers.size():
		var villager: VillagerState = world.villagers[slot]
		var actor: VillagerActor = _actors.get(villager.id)
		if actor == null:
			actor = _make_actor(villager)
		actor.set_role(villager.profession, _role_sheet(villager.profession))
		actor.apply_plan(plans[slot])


func _make_actor(villager: VillagerState) -> VillagerActor:
	var look: StringName = villager.look if villager.look != &"" else villager.id
	var actor: VillagerActor = VillagerActor.new()
	actor.set_meta(&"look", look)
	_world.add_child(actor)
	actor.setup(villager.id, _sheet_for(look))
	_actors[villager.id] = actor
	return actor


func _sheet_for(look: StringName) -> Texture2D:
	return load(WorldLayout.villager_sheet_path(look, _outfit)) as Texture2D


## The overlay a profession adds on top of the body, or null if it has none.
func _role_sheet(profession: StringName) -> Texture2D:
	var path: String = WorldLayout.role_sheet_path(profession)
	if path.is_empty():
		return null
	return load(path) as Texture2D


## The camp's backdrop layer plus the same layer of the west and east pages (art/cave_pages.js).
## Returns the camp's sprite first.
func _make_backdrop_pages(layer: StringName, z: int) -> Array[Sprite2D]:
	var sprites: Array[Sprite2D] = [_make_sprite(layer, z)]
	for prefix: String in WorldLayout.SIDE_PAGES:
		sprites.append(_make_sprite(
			StringName(prefix + layer), z, float(WorldLayout.SIDE_PAGES[prefix])
		))
	return sprites


## `at_x` is the sprite's left edge in camp pixels (0 for the camp page's own pieces).
func _make_sprite(layer: StringName, z: int, at_x: float = 0.0) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.use_parent_material = true
	sprite.z_index = z
	sprite.position.x = at_x
	sprite.texture = _load_art(layer)
	_world.add_child(sprite)
	return sprite


func _load_art(layer: StringName) -> Texture2D:
	var path: String = "%s%s.png" % [WorldLayout.ASSET_DIR, layer]
	if not ResourceLoader.exists(path):
		push_error("Missing world art: %s" % path)
		return null
	return load(path) as Texture2D


## A piece that an age may redraw (a building, its site, a prop): its art is the newest the
## current age has, and it is swapped when the age turns. `at_x` and `at_y` place its top-left
## corner (a piece is lifted onto its lane by a negative `at_y`).
func _make_piece(layer: StringName, z: int, at_x: float = 0.0, at_y: float = 0.0) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.use_parent_material = true
	sprite.z_index = z
	sprite.position = Vector2(at_x, at_y)
	sprite.visible = false
	sprite.set_meta(&"layer", layer)
	sprite.texture = _load_piece(layer, WorldLayout.ERA_DIRS.size() - 1)
	_world.add_child(sprite)
	return sprite


func _load_piece(layer: StringName, era_order: int) -> Texture2D:
	var path: String = WorldLayout.piece_path(layer, era_order)
	if path.is_empty():
		push_error("Missing world art: %s" % layer)
		return null
	return load(path) as Texture2D


## A piece with no art yet in the current age (a Settled prop while still in the Cave Age) keeps
## the texture it has: it is not shown until its age.
func _retexture_pieces() -> void:
	for group: Dictionary in [_buildings, _sites, _props]:
		for key: StringName in group:
			_retexture(group[key])
	for sprite: Sprite2D in _static_layers:
		_retexture(sprite)
	# The east light's glow is chosen by `_seat_light`, which knows what carries it.
	# The camp's signature building comes with its own fire pit: the Cave Age's has the firelight
	# in the cave's mouth, which would show through a wall.
	for frame: int in WorldLayout.FIRE_FRAMES:
		var layer: StringName = WorldLayout.fire_frame_name(frame)
		if not WorldLayout.piece_path(layer, _art_era).is_empty():
			_fire_frames[frame] = _load_piece(layer, _art_era)
	_fire_pit.texture = _fire_frames[_fire_frame]


func _retexture(sprite: Sprite2D) -> void:
	var layer: StringName = sprite.get_meta(&"layer")
	if not WorldLayout.piece_path(layer, _art_era).is_empty():
		sprite.texture = _load_piece(layer, _art_era)


## A piece of the sky, in the clip but not in the scrolling world, so it stays put as you pan.
func _make_sky_sprite(texture: Texture2D) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.centered = false
	sprite.z_index = WorldLayout.SKY_Z
	sprite.texture = texture
	sprite.visible = false
	_clip.add_child(sprite)
	return sprite


## One cell of the sun and moon sheet: 0 is the sun, 1 the moon.
func _celestial(cell: int) -> Texture2D:
	var sheet: Texture2D = _load_art(WorldLayout.CELESTIAL)
	if sheet == null:
		return null
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(
		Vector2(WorldLayout.CELESTIAL_CELL.x * cell, 0), Vector2(WorldLayout.CELESTIAL_CELL)
	)
	return atlas


## Which solid pieces are showing, so the click region is only rebuilt when it changes.
func _shape_signature() -> String:
	var parts: PackedStringArray = PackedStringArray()
	parts.append(str(_art_era))
	for building_id: StringName in _buildings:
		for sprite: Sprite2D in [_buildings[building_id], _sites[building_id]]:
			parts.append("b%d" % int(sprite.position.x) if sprite.visible else "-")
	for prop_id: StringName in _props:
		var prop: Sprite2D = _props[prop_id]
		parts.append("o%d" % int(prop.position.x) if prop.visible else "-")
	parts.append("f" if _flower_sprout.visible else "-")
	parts.append("F" if _flower_bloom.visible else "-")
	parts.append("p" if _fire_pit.visible else "-")
	parts.append("d" if _deer.visible else "-")
	return "".join(parts)


## What the player can click across the whole world: land and props that are currently drawn,
## desktop-mode backdrop only. The window reads the part that is in view.
func _rebuild_skyline() -> void:
	var skyline: Skyline = Skyline.new(WorldLayout.WORLD_WIDTH, WorldLayout.VIEW_SIZE.y)
	for layer: StringName in WorldLayout.DESKTOP_BACKDROP:
		for sprite: Sprite2D in _backdrop[layer]:
			skyline.add(sprite.texture, _world_column(sprite))
	for sprite: Sprite2D in _static_layers:
		skyline.add(sprite.texture, _world_column(sprite))
	for building_id: StringName in _buildings:
		for sprite: Sprite2D in [_buildings[building_id], _sites[building_id]]:
			if sprite.visible:
				skyline.add(sprite.texture, _world_column(sprite), false, int(sprite.position.y))
	for sprite: Sprite2D in _props.values():
		if sprite.visible:
			skyline.add(sprite.texture, _world_column(sprite), false, int(sprite.position.y))
	for sprite: Sprite2D in [_flower_sprout, _flower_bloom, _fire_pit, _life, _life_west, _deer]:
		if sprite.visible:
			skyline.add(sprite.texture, _world_column(sprite))
	_window.set_skyline(skyline.tops)
	_skyline_tops = skyline.tops
	_skyline_stamp += 1
	_seat_light()


## A sprite's left edge as a column of the whole world (which starts at WORLD_LEFT).
func _world_column(sprite: Sprite2D) -> int:
	return int(sprite.position.x) - WorldLayout.WORLD_LEFT
