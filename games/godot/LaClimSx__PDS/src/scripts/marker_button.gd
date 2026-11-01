extends TextureButton
class_name MarkerButton

@export_group("Enum Textures")
@export var cross_texture: CompressedTexture2D
@export var square_texture: CompressedTexture2D
@export var triangle_texture: CompressedTexture2D
@export var circle_texture: CompressedTexture2D
@export_group("")

@onready var textures : Array[CompressedTexture2D] = [null, cross_texture, circle_texture, square_texture, triangle_texture]
var idx : int = 0
const LIAR_IDX = 1

func _on_pressed() -> void:
	idx = (idx + 1) % 5
	texture_normal = textures[idx]
