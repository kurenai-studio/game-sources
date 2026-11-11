extends Control
var compact := false
var quiet := false
var value := 0
var digits := 3
var ink := Color("ff2452")
const MASKS := [63,6,91,79,102,109,125,7,127,111]

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	custom_minimum_size = custom_minimum_size.max(Vector2(30,14) if compact else Vector2(58,34))
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("170e13"))
	draw_rect(Rect2(Vector2.ZERO,size),Color("30252a") if quiet else Color("6e6259"),false,2)
	var text := str(maxi(0,value)).pad_zeros(digits)
	var padding := 4.0 if compact else 12.0
	var vertical_padding := 2.0 if compact else 8.0
	var unit := minf((size.x-padding)/(text.length()*17.0), (size.y-vertical_padding)/28.0)
	var offset := Vector2((size.x-text.length()*17*unit)*0.5,(size.y-28*unit)*0.5)
	for i in range(text.length()):
		draw_set_transform(offset+Vector2(i*17*unit,0),0,Vector2.ONE*unit)
		var mask: int = MASKS[int(text[i])]
		for segment in range(7):
			var tint := ink if mask & (1<<segment) else ink.darkened(0.88)
			match segment:
				0: horizontal(3,1,tint)
				1: vertical(12,3,tint)
				2: vertical(12,15,tint)
				3: horizontal(3,26,tint)
				4: vertical(1,15,tint)
				5: vertical(1,3,tint)
				6: horizontal(3,13,tint)
	draw_set_transform(Vector2.ZERO)

func horizontal(x: float,y: float,color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(x-1,y),Vector2(x+1,y-1.4),Vector2(x+7,y-1.4),Vector2(x+9,y),Vector2(x+7,y+1.4),Vector2(x+1,y+1.4)]),color)
func vertical(x: float,y: float,color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(x,y-1),Vector2(x+1.4,y+1),Vector2(x+1.4,y+7),Vector2(x,y+9),Vector2(x-1.4,y+7),Vector2(x-1.4,y+1)]),color)
