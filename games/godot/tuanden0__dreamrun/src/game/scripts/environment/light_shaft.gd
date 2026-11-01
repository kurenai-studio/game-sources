## A real light shaft: a PointLight2D whose texture is a soft beam, so occluders cut it and
## CanvasModulate darkness does not swallow it. The node position is the beam origin, the beam
## points along local +y (rotate the node to aim it).
class_name LightShaft
extends PointLight2D

## World length of the beam in px.
@export var length := 520.0
## World width at the far end in px.
@export var width := 260.0
## Width at the origin relative to the far end.
@export_range(0.05, 1.0) var start_width_ratio := 0.35
## 0 = hard edge, 1 = fully feathered.
@export_range(0.05, 1.0) var edge_softness := 0.6
## Brightness wobble (fraction of energy) and speed (Hz); 0 amount = steady.
@export var flicker_amount := 0.08
@export var flicker_rate := 0.3

## The brightness the flicker wobbles around; set it (or tween it) to fade the shaft in or out.
var base_energy := 0.0
var _time := randf() * 10.0


## The origin sits at the vertical centre of the image (top half black) so no texture offset is needed.
static func build_image(img_width: int, half_height: int, start_ratio: float, softness: float) -> Image:
	var img := Image.create(img_width, half_height * 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.BLACK)
	for y in range(half_height, half_height * 2):
		var t := float(y - half_height) / half_height
		var half_w := lerpf(start_ratio, 1.0, t) * 0.5
		var along := smoothstep(0.0, 0.08, t) * (1.0 - t)
		for x in img_width:
			var u := absf(float(x) / img_width - 0.5) / half_w
			var v := (1.0 - smoothstep(1.0 - softness, 1.0, u)) * along
			img.set_pixel(x, y, Color(v, v, v, 1.0))
	return img


func _ready() -> void:
	var half_height := 128
	var img_width := maxi(int(half_height * width / length), 16)
	texture = ImageTexture.create_from_image(build_image(img_width, half_height, start_width_ratio, edge_softness))
	texture_scale = length / half_height
	base_energy = energy
	set_process(flicker_amount > 0.0)


func _process(delta: float) -> void:
	_time += delta
	energy = base_energy * (1.0 + sin(_time * flicker_rate * TAU) * flicker_amount)
