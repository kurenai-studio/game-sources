extends Area2D


export var scene = ""


func _ready():
	pass


func _on_teleporter_body_entered(body):
	if body.ignore_teleport:
		return
	get_node("/root/root").call_deferred("load_scene", scene)
