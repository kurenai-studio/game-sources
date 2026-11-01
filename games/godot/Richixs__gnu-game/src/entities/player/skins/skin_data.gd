extends Resource
class_name SkinData

@export var skin_name: String
@export var animations: SpriteFrames

@export_group("Collision Settings")
@export var standing_size: Vector2 = Vector2(20, 30)
@export var standing_offset: Vector2 = Vector2(0, 0)

@export var ducking_size: Vector2 = Vector2(30, 15)
@export var ducking_offset: Vector2 = Vector2(0, 7.5)
