extends PanelContainer
var lights := false
var light_intensity := 0.7
func _draw() -> void:
	for y in range(10,int(size.y)-10,4):
		draw_line(Vector2(5,y),Vector2(size.x-5,y),Color(1,1,1,0.055),1)
	for point in [Vector2(9,9),Vector2(size.x-9,9),Vector2(9,size.y-9),Vector2(size.x-9,size.y-9)]:
		draw_circle(point,4,Color("77736a"))
		draw_line(point-Vector2(2,2),point+Vector2(2,2),Color("3e3931"),1)
	if lights:
		for x in range(20,int(size.x)-15,30):
			for y in [6.0,size.y-6]:
				draw_circle(Vector2(x,y),5,Color("8f541c"))
				draw_circle(Vector2(x,y),3,Color("fff2b2").lerp(Color("a88749"),1.0-light_intensity))
