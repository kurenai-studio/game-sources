class_name LightPrism
extends Node2D
# Призма (Кристальные пещеры): висит в воздухе и делит проходящий луч света на три.

const R := 20.0

func _ready() -> void:
	add_to_group("prisms")
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(DeepArt.prism_image())
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = Vector2(3, 3)
	add_child(s)
	Shimmer.apply(s, 0.3, 0.9)
	var g := Torch.make_glow(130.0, Color(0.8, 0.85, 1.0, 0.45))
	add_child(g)

func _process(_d: float) -> void:
	position.y += sin(Time.get_ticks_msec() * 0.002 + position.x) * 0.15
	rotation = sin(Time.get_ticks_msec() * 0.0013 + position.x) * 0.08
