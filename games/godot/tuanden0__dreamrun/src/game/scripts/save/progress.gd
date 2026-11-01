## Saves how far the player got and puts them back there. Child of the chapter. Every checkpoint the player lights is
## written to the save file; on the next start, an unfinished chapter resumes at the last lit checkpoint. The world is
## not saved, only the place: puzzles behind you are in their starting state, which is fine because the chapter only
## goes one way (the boss pen can be fought from either alcove, so resuming mid-fight cannot lock the player out).
## A finished chapter starts again from the beginning, and so does a start with the argument `--new-game`
## (`godot --path game -- --new-game`), which also forgets the old save.
class_name Progress
extends Node

signal restored(checkpoint: StringName)
signal saved(checkpoint: StringName)

@export var chapter_id := "chapter1"
## Empty = SaveGame.default_path().
@export var save_path := ""
## Forget the save and start from the beginning. Defaults to whether the game was started with `--new-game`.
var new_game := OS.get_cmdline_user_args().has("--new-game")


func _ready() -> void:
	_start.call_deferred()


func _start() -> void:
	var chapter := get_parent()
	var player := get_tree().get_first_node_in_group(&"player") as PlayerController
	if new_game:
		SaveGame.erase(save_path)
	var data := SaveGame.read(save_path)
	if player != null and data.get("chapter", "") == chapter_id and not data.get("completed", false):
		var checkpoint := chapter.get_node_or_null(NodePath(str(data.get("checkpoint", "")))) as Checkpoint
		if checkpoint != null:
			player.global_position = checkpoint.spawn_position()
			var camera := player.get_node_or_null(^"Camera") as Camera2D
			if camera != null:
				camera.reset_smoothing()
			restored.emit(checkpoint.name)
	for checkpoint: Checkpoint in get_tree().get_nodes_in_group(&"checkpoint"):
		checkpoint.activated.connect(_on_checkpoint)
	if chapter.has_signal(&"completed"):
		chapter.connect(&"completed", _on_completed)


func _on_checkpoint(checkpoint: Checkpoint) -> void:
	if SaveGame.write({"chapter": chapter_id, "checkpoint": String(checkpoint.name), "completed": false}, save_path):
		saved.emit(checkpoint.name)


func _on_completed() -> void:
	var data := SaveGame.read(save_path)
	data["chapter"] = chapter_id
	data["completed"] = true
	SaveGame.write(data, save_path)
