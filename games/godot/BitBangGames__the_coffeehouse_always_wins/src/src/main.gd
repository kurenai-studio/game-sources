# The Coffeehouse Always Wins
# Copyright (C) 2026 StudioGuma

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

class_name Main
extends Node

static var __singleton: Main = null

var __barista: Barista
var __map: TileMapLayer

var __save: Save = Save.new()
var __settings: ConfigFile = ConfigFile.new()

var __coffee_maker_area: Area2D
var __espresso_area: Area2D
var __bean_bag_area: Area2D
var __minifridge_area: Area2D
var __managers_note_area: Area2D

var __main_text_box: Label
var __time_box: Label
var __points_box: Label
var __cups_box: Label
var __description_box: Label
var __confirm_button: Label
var __cancel_button: Label

var __cur_state: Consts.State
var __fullscreen: bool = true

var __click_timer: int = 0
var __espresso: bool
var __menu: bool
var __selected_idx: int = 0
var __inv_areas: Array[Area2D]
var __items_to_use: PackedByteArray
var __selector: Sprite2D

var __dialogue: PackedStringArray
var __dialogue_idx: int

var __sound_player: AudioStreamPlayer = AudioStreamPlayer.new()
var __music_player: AudioStreamPlayer = AudioStreamPlayer.new()

func _init() -> void:
	if (__singleton == null):
		__singleton = self

		add_child(__sound_player)
		add_child(__music_player)

		var err: Error = __settings.load(Consts.SETTINGS_PATH)
		if (err):
			__settings.set_value("Settings", "music", 1.0)
			__settings.set_value("Settings", "sfx", 1.0)
			if (__settings.save(Consts.SETTINGS_PATH)):
				play_sound("sfx_bonk")

		var sfx_vol: float =__settings.get_value("Settings", "sfx")
		__sound_player.set_volume_linear(sfx_vol)
		var music_vol: float =__settings.get_value("Settings", "music")
		__music_player.set_volume_linear(music_vol)

		print("The Coffeehouse Always Wins v1.02 by StudioGuma")
		print("https://godotengine.org/license")

	elif (__singleton != self):
		queue_free()

func _ready() -> void:
	__map = get_node("Map")
	__coffee_maker_area = get_node("CoffeeMakerArea")
	__espresso_area = get_node("EspressoArea")
	__bean_bag_area = get_node("BeanBagArea")
	__minifridge_area = get_node("MinifridgeArea")
	__managers_note_area = get_node("ManagersNoteArea")

	__barista = preload("res://src/barista.tscn").instantiate()
	add_child(__barista)

	add_child(preload("res://src/ui.tscn").instantiate())


	__main_text_box = preload("res://src/text_box.tscn").instantiate()
	__main_text_box.set_size(Vector2i(Consts.SCREEN_SIZE.x, 0b110000))
	__main_text_box.set_position(Vector2(
		0, Consts.SCREEN_SIZE.y - __main_text_box.get_size().y
	))
	__main_text_box.set_visible(false)
	add_child(__main_text_box)

	set_state(Consts.State.TITLE_STATE)

func _input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion and __menu):
		set_menu(false)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			__singleton = null
			print_orphan_nodes()

		NOTIFICATION_WM_CLOSE_REQUEST:
			exit()

func _process(_delta: float) -> void:
	if (Input.is_action_just_pressed("music")):
		__music_player.set_volume_linear(1.0 - __music_player.get_volume_linear())
		__settings.set_value("Settings", "music", __music_player.get_volume_linear())
		if (__settings.save(Consts.SETTINGS_PATH)):
			play_sound("sfx_bonk")

	if (Input.is_action_just_pressed("sfx")):
		__sound_player.set_volume_linear(1.0 - __sound_player.get_volume_linear())
		play_sound("sfx_select")
		__settings.set_value("Settings", "sfx", __sound_player.get_volume_linear())
		if (__settings.save(Consts.SETTINGS_PATH)):
			play_sound("sfx_bonk")

	if (Input.is_action_just_pressed("fullscreen")):
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED if (__fullscreen)
			else DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		)
		__fullscreen = not __fullscreen

	if (Input.is_action_just_released("click") and __click_timer == 0):
		__click_timer = 0b1000
	if (__click_timer > 0):
		__click_timer -= 1
	
	if (__menu):
		menu_loop()

	if (
		__confirm_button
		and __confirm_button.is_visible()
		and is_area_clicked(__confirm_button.get_child(0) as Area2D
	)):
		Input.action_press("confirm")
	if (
		__cancel_button
		and __cancel_button.is_visible()
		and is_area_clicked(__cancel_button.get_child(0) as Area2D
	)):
		Input.action_press("cancel")

	match __cur_state:
		Consts.State.TITLE_STATE:
			if (not __sound_player.is_playing()):
				play_sound("sfx_talking", 0.875)

			if (Input.is_action_just_pressed("load")):
				__dialogue = Consts.TUTORIAL
				(get_node("TitleScreen") as Node2D).set_visible(false)
				set_state(Consts.State.DIALOGUE_STATE)

			if (Input.is_action_just_pressed("confirm")
			or Input.is_action_just_pressed("click")):
				get_node("TitleScreen").queue_free()
				
				__barista.get_sprite().play("win't")
				
				__time_box = get_node("UI/TimeBox")
				__cups_box = get_node("UI/CupsBox")
				__points_box = get_node("UI/PointsBox")
				__description_box = get_node("UI/DescriptionBox")
				__confirm_button = get_node("UI/ConfirmButton")
				__cancel_button = get_node("UI/CancelButton")

				__inv_areas.push_back(get_node("UI/InventoryBox/InvArea1"))
				__inv_areas.push_back(get_node("UI/InventoryBox/InvArea2"))
				__inv_areas.push_back(get_node("UI/InventoryBox/InvArea3"))
				__inv_areas.push_back(get_node("UI/InventoryBox/InvArea4"))
				__inv_areas.push_back(get_node("UI/InventoryBox/InvArea5"))
				__inv_areas.push_back(get_node("UI/InventoryBox/InvArea6"))
				__selector = get_node("UI/InventoryBox/Selector")

				play_music("mus_coffeehouse")

				set_state(Consts.State.GAME_STATE)
				__save.init_round()

		Consts.State.GAME_STATE:
			if (Input.is_action_just_pressed("load")
			or (__click_timer > 0 and Input.is_action_just_pressed("click"))):
				if (load_game()):
					play_sound("sfx_bonk")
				else:
					play_sound("sfx_drink")

			if (Input.is_action_just_pressed("cancel")):
				set_state(Consts.State.INVENTORY_STATE)

			if (is_area_selected(__coffee_maker_area)):
				__description_box.set_text("Drip Coffee (x2)")
			elif (is_area_selected(__espresso_area)):
				__description_box.set_text("Espresso (x0.5)")
			elif (is_area_selected(__bean_bag_area)):
				__description_box.set_text("Bean Bag")
			elif (is_area_selected(__minifridge_area)):
				__description_box.set_text("Minifridge")
			elif (is_area_selected(__managers_note_area)):
				__description_box.set_text("Manager's Note")
			else:
				__description_box.set_text("")

			if (is_area_clicked(__bean_bag_area)):
				__save.stock_beans()

			elif (is_area_clicked(__minifridge_area)):
				__save.stock_ingrs()

			elif (is_area_clicked(__coffee_maker_area)):
				if (__save.inv_is_empty()):
					play_sound("sfx_bonk")
				else:
					__espresso = false
					set_state(Consts.State.BREWING_STATE)

			elif (is_area_clicked(__espresso_area)):
				if (__save.inv_is_empty()):
					play_sound("sfx_bonk")
				else:
					__espresso = true
					set_state(Consts.State.BREWING_STATE)

			elif (is_area_clicked(__managers_note_area)):
				(get_node("UI") as Node2D).set_visible(false)
				set_state(Consts.State.DIALOGUE_STATE)

			if (__save.get_points() >= __save.get_min()
			and __save.get_points() < (__save.get_min() << 1)):
				if (__save.get_round() == Consts.MAX_ROUND):
					set_state(Consts.State.END_STATE)
					__time_box.set_text("2:00 PM")
					__barista.get_sprite().play("down_walk")
					play_sound("sfx_applause")

				else:
					__save.init_round(__save.get_round() + 1)
			elif (__save.get_cups() == 0):
				game_over()

		Consts.State.INVENTORY_STATE:
			if (Input.is_action_just_pressed("right") or Input.is_action_just_pressed("left")):
				set_menu(true)
			if (Input.is_action_just_pressed("cancel")):
				set_state(Consts.State.GAME_STATE)

		Consts.State.DIALOGUE_STATE:
			if (
				Input.is_action_just_pressed("confirm")
				or Input.is_action_just_pressed("click")
				or Input.is_action_pressed("cancel")
			):
					step_dialogue()

		Consts.State.BREWING_STATE:
			if (Input.is_action_just_pressed("right") or Input.is_action_just_pressed("left")):
				set_menu(true)

			for i: int in Consts.INVENTORY_SIZE:
				if (is_area_clicked(__inv_areas[i])):
					if (__save.get_inventory()[i] == Consts.Item.NONE):
						play_sound("sfx_bonk")
					else:
						var result: bool = __items_to_use.push_back(
							__save.get_inventory()[i]
						)
						if (result):
							play_sound("sfx_bonk")
						else:
							__save.get_inventory().set(i, Consts.Item.NONE)
							update_inventory()
							play_sound("sfx_select")

			if (
				Input.is_action_just_pressed("cancel")
				or __save.inv_is_empty()
			):
				if (__items_to_use.is_empty()):
					play_sound("sfx_bonk")
				else:
					set_state(Consts.State.BREWED_STATE)

		Consts.State.BREWED_STATE:
			if (Input.is_action_just_pressed("confirm")):
				for i: int in __items_to_use.size():
					__save.item_effect(__items_to_use[i])
				__save.set_points(
					__save.get_points() >> 1 if (__espresso) else __save.get_points() << 1
				)
				play_sound("sfx_select")

				set_state(Consts.State.GAME_STATE)

			elif (Input.is_action_just_pressed("cancel")):
				if (__save.save_game()):
					play_sound("sfx_bonk")
				else:
					play_sound("sfx_drink")

				set_state(Consts.State.GAME_STATE)

		Consts.State.END_STATE:
			if (Input.is_action_just_pressed("confirm")):
				__music_player.set_stream_paused(false)
				__map.set_visible(true)
				__save.init_round()
				set_state(Consts.State.GAME_STATE)
			elif (Input.is_action_just_pressed("cancel")):
				exit()
	
	for i: int in __inv_areas.size():
		if (is_area_selected(__inv_areas[i])):
			set_selected_idx(i)
			__description_box.set_text(Consts.ITEM_DESCS.get(__save.get_inventory()[i]))
			__selector.set_visible(true)
			break
		else:
			__selector.set_visible(false)

static func get_singleton() -> Main:
	if (__singleton == null):
		__singleton = Main.new()

	return __singleton

func get_state() -> Consts.State:
	return __cur_state

func set_state(state: Consts.State) -> void:
	__cur_state = state

	match __cur_state:
		Consts.State.TITLE_STATE:
			(get_node("TitleScreen") as Node2D).set_visible(true)

		Consts.State.GAME_STATE:
			(get_node("UI") as Node2D).set_visible(true)

			set_menu(false)
			__confirm_button.set_visible(false)
			__cancel_button.set_visible(false)
			(get_node("UI/BrewedBox") as Label).set_visible(false)

			__items_to_use = []

		Consts.State.INVENTORY_STATE:
			set_menu(true)

		Consts.State.DIALOGUE_STATE:
			__dialogue_idx = 0
			__main_text_box.set_visible(true)
			step_dialogue()

		Consts.State.BREWING_STATE:
			set_menu(true)
			__cancel_button.set_visible(true)
			__cancel_button.set_text("Cancel: Brew")

		Consts.State.BREWED_STATE:
			set_menu(false)
			__save.set_cups(__save.get_cups() - 1
			)
			__confirm_button.set_visible(true)
			(get_node("UI/BrewedBox") as Label).set_visible(true)

			__confirm_button.set_text("Confirm: Serve")
			__cancel_button.set_text("Cancel: Drink (Save)")

			play_sound("sfx_brew")

		Consts.State.END_STATE:
			__confirm_button.set_visible(true)
			__cancel_button.set_visible(true)
			__confirm_button.set_text("Confirm: New Shift")
			__cancel_button.set_text("Cancel: Exit")

func set_menu(val: bool) -> void:
	__menu = val
	__selector.set_visible(__menu)

func menu_loop() -> void:
	if (Input.is_action_just_pressed("right")):
		set_selected_idx(__selected_idx + 1)
		if (__selected_idx >= __save.get_inventory().size()):
			set_selected_idx(0)

	elif (Input.is_action_just_pressed("left")):
		set_selected_idx(__selected_idx - 1)
		if (__selected_idx < 0):
			set_selected_idx(__save.get_inventory().size() - 1)

func is_area_selected(area: Area2D) -> bool:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var coll_shape: CollisionShape2D = area.get_node("./CollisionShape2D") as CollisionShape2D
	var coll_size: Vector2 = coll_shape.get_shape().get_rect().size

	return (
		(
			abs(mouse_pos.x - coll_shape.get_global_position().x) < (int(coll_size.x) >> 1)
			and abs(mouse_pos.y - coll_shape.get_global_position().y) < (int(coll_size.y) >> 1)
		)
		or area.overlaps_body(__barista)
		or (__menu and (area == __inv_areas[__selected_idx]))
	)

func is_area_clicked(area: Area2D) -> bool:
	return is_area_selected(area) and (
		Input.is_action_just_pressed("confirm")
		or Input.is_action_just_pressed("click")
	)

func update_points() -> void:
	__points_box.set_text("%d (%d-%d)" % [
		__save.get_points(),
		__save.get_min(),
		__save.get_min() << 1
	])

func update_cups() -> void:
	__cups_box.set_text("%d/%d" % [__save.get_cups(), __save.get_max_cups()])

func update_time() -> void:
	match __save.get_round():
		1:
			__time_box.set_text("10:00 AM")
		0b10:
			__time_box.set_text("10:30 AM")
		0b11:
			__time_box.set_text("11:00 AM")
		0b100:
			__time_box.set_text("11:30 AM")
		0b101:
			__time_box.set_text("12:00 PM")
		0b110:
			__time_box.set_text("12:30 PM")
		0b111:
			__time_box.set_text("1:00 PM")
		0b1000:
			__time_box.set_text("1:30 PM")
		_:
			__time_box.set_text("OVERTIME")

func update_inventory() -> void:
	for i: int in __inv_areas.size():
		var sprite: Sprite2D = __inv_areas[i].get_node("Sprite2D")
		sprite.set_frame(__save.get_inventory()[i])

func set_selected_idx(val: int) -> void:
	__selected_idx = val
	__selector.set_position(Consts.SELECTOR_BASE_POS + Vector2i(__selected_idx << 0b100, 0))

func game_over() -> void:
	set_state(Consts.State.END_STATE)
	__barista.get_sprite().play("win't")
	__map.set_visible(false)
	play_sound("sfx_lose")
	__music_player.set_stream_paused(true)

func load_game() -> Error:
	if (not ResourceLoader.exists(Consts.SAVE_PATH)):
		return Error.ERR_FILE_NOT_FOUND

	__save = ResourceLoader.load(Consts.SAVE_PATH, "Resource", ResourceLoader.CACHE_MODE_IGNORE)
	update_inventory()
	update_time()
	update_cups()
	update_points()

	return DirAccess.remove_absolute(Consts.SAVE_PATH)

func init_managers_note() -> void:
	var selected_note: PackedStringArray = Consts.MANAGERS_NOTES.pick_random()
	while (selected_note == __dialogue):
		selected_note = Consts.MANAGERS_NOTES.pick_random()
	__dialogue = selected_note

func step_dialogue() -> void:
	if (__dialogue_idx >= __dialogue.size()):
		__main_text_box.set_visible(false)
		set_state(
			Consts.State.TITLE_STATE if (__dialogue == Consts.TUTORIAL) else Consts.State.GAME_STATE
		)
	else:
		__main_text_box.set_text(__dialogue[__dialogue_idx])
		__dialogue_idx += 1

func play_sound(key: String, speed: float = 1.0) -> void:
	var path: String = Consts.SFX_JSON.get(key)
	var stream: AudioStreamWAV = load(path)

	__sound_player.set_stream(stream)
	__sound_player.set_pitch_scale(speed)
	__sound_player.play()

func play_music(key: String, speed: float = 1.0) -> void:
	var music_dict: Dictionary = Consts.MUSIC_JSON.get(key)
	var path: String = music_dict.get("path")
	var loop: float = music_dict.get("loop")

	var stream: AudioStreamOggVorbis = load(path)
	stream.set_loop(true)
	stream.set_loop_offset(loop)
	
	__music_player.set_stream(stream)
	__music_player.set_pitch_scale(speed)
	__music_player.play()

func exit(err: Error = Error.OK) -> void:
	queue_free()
	get_tree().quit(err)
