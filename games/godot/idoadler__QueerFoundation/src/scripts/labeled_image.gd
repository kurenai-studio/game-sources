class_name LabledImage
extends Sprite2D

@export var label:Label
@export var conversation:Conversation
@export var id:int

func set_response():
	conversation.set_response(id)
