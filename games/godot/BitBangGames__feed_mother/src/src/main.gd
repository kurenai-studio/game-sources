# Feed Mother
# Copyright (C) 2026 Bit Bang Games

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

var __fullscreen: bool = true
var __map: StaticBody3D
var __state: int
var __endings: PackedByteArray = [false, false, false]

var __sound_player: AudioStreamPlayer = AudioStreamPlayer.new()
var __music_player: AudioStreamPlayer = AudioStreamPlayer.new()

static func get_singleton() -> Main:
	if (__singleton == null):
		__singleton = Main.new()

	return __singleton

func _init() -> void:
	if (__singleton != null and __singleton != self):
		queue_free()

	__singleton = self

	add_child(__sound_player)
	add_child(__music_player)

	print("Feed Mother by Bit Bang Games")
	print("Source code: https://github.com/BitBangGames/feed_mother")
	print("https://godotengine.org/license")

func _ready() -> void:
	set_state(Consts.TITLE_STATE)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			__singleton = null
			print_orphan_nodes()

		NOTIFICATION_WM_CLOSE_REQUEST:
			exit()

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseMotion or event is InputEventMouseButton):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(_delta: float) -> void:
	if (Input.is_action_just_pressed("fullscreen")):
		set_fullscreen(not __fullscreen)

	if (get_state() == Consts.TITLE_STATE and (
		Input.is_action_just_pressed("confirm")
		or Input.is_action_just_pressed("click")
	)):
		set_state(Consts.GAME_STATE)

func set_fullscreen(val: bool) -> void:
	__fullscreen = val
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if (__fullscreen)
		else DisplayServer.WINDOW_MODE_WINDOWED
	)

func set_state(val: int) -> void:
	__state = val
	match val:
		Consts.TITLE_STATE:
			if (__map):
				__map.queue_free()
			add_child(preload("res://src/title_screen.tscn").instantiate())
			(get_node("./TitleScreen/EndingsBox") as Label).set_text(
				"Endings: " + str(__endings.count(true)) + "/4"
			)

			play_music(Consts.MUS_HEARTBEAT)

		Consts.GAME_STATE:
			get_node("./TitleScreen").queue_free()
			__map = preload("res://map/map.tscn").instantiate()
			add_child(__map)

			__map.add_child(Player.get_singleton())
			__map.add_child(Mother.get_singleton())
			__map.add_child(TextBox.get_singleton())

			play_music(Consts.MUS_MOTHER)

		Consts.ENDING_STATE:
			Player.get_singleton().set_velocity(Vector3(0, Player.get_singleton().get_vel_y(), 0))
			Player.get_singleton().get_anim_player().play("front")
			TextBox.get_singleton().set_text("")

func get_state() -> int:
	return __state

func init_ending(ending: int) -> void:
	stop_music()
	set_state(Consts.ENDING_STATE)

	match ending:
		Consts.FEED_ENDING:
			Mother.get_singleton().get_anim_player().play("mouth_open")
			await get_tree().create_timer(2.0).timeout

			play_sound(Consts.SFX_LAUGH)
			Mother.get_singleton().get_anim_player().play("laugh")
			await get_tree().create_timer(2.0).timeout

		Consts.DEVOUR_ENDING:
			play_sound(Consts.SFX_EATING)
			Player.get_singleton().get_anim_player().play("devour")
			await get_tree().create_timer(4.0).timeout

		Consts.FALL_ENDING:
			if not (Mother.get_singleton().is_broken()):
				Mother.get_singleton().get_anim_player().play("eye_open")
			await get_tree().create_timer(2.0).timeout

			play_sound(Consts.SFX_BONK)
			for canvas_item: CanvasItem in get_node(Consts.MAP_CANVAS_PATH).get_children():
				if not (canvas_item.is_visible()):
					canvas_item.set_visible(true)
				elif (canvas_item is Sprite2D):
					canvas_item.set_visible(false)

		Consts.TRUE_ENDING:
			var readme: FileAccess = FileAccess.open(Consts.README_PATH, FileAccess.WRITE_READ)
			if not (readme.store_string(Consts.README_TEXT)):
				printerr("Failed to create README file")
			await get_tree().create_timer(8.0).timeout

			if (OS.get_name() == "Web"):
				JavaScriptBridge.download_buffer(
					FileAccess.get_file_as_bytes(Consts.README_PATH), "README", "text/plain"
				)
			else:
				var err: Error = OS.shell_open(ProjectSettings.globalize_path("user://"))
				if (err):
					exit(err)

			exit()

	if (ending != Consts.TRUE_ENDING):
		__endings[ending] = true

		await get_tree().create_timer(4.0).timeout
		set_state(Consts.TITLE_STATE)

func play_sound(idx: int, speed: float = 1.0) -> void:
	var stream: AudioStreamWAV = load(Consts.SFX_PATHS[idx])
	__sound_player.set_stream(stream)
	__sound_player.set_pitch_scale(speed)
	__sound_player.play()
	
func play_music(idx: int, speed: float = 1.0) -> void:
	var stream: AudioStreamOggVorbis = load(Consts.MUSIC_PATHS[idx])
	__music_player.set_stream(stream)
	__music_player.set_pitch_scale(speed)
	__music_player.play()

func stop_music() -> void:
	__music_player.set_stream_paused(true)

func exit(err: Error = Error.OK) -> void:
	queue_free()
	get_tree().quit(err)
