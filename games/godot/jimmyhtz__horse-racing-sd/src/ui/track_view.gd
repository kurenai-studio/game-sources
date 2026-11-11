extends Control
const Geometry = preload("res://core/track_geometry.gd")
const FINISH_PHASE := 0.24
const COLORS := [Color("e5473e"),Color("f8f1de"),Color("3a7dda"),Color("f4c52e"),Color("43ad69")]
var positions := [0.0,0.0,0.0,0.0,0.0]
var preferences: Dictionary
var close_up := false
var photo_focus := 2.0
var photo := false
var photo_hold := false
var highlight := -1
var highlights: Array = []
var moving := true
var directional := true
var _animation_clock := 0.0
var _highlight_clock := 0.0
var geometry := Geometry.new()
var _last_draw_state: Array = []
var _photo_start: Array = []
var _photo_end: Array = []
var _photo_cache_key: Array = []
var _photo_frame_cache := {}

func _ready() -> void:
	geometry.straight_half = 210.0
	geometry.inner_radius = 90.0
	geometry.lane_width = preferences.get("lane_spacing",56.0)
	custom_minimum_size = Vector2(700,470)
	clip_contents = true
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _process(delta: float) -> void:
	if moving:
		_animation_clock += delta
	_highlight_clock += delta
	var steady: bool = preferences.get("reduce_flashing",false) or preferences.get("reduced_motion",false)
	var flash: bool = (highlights.is_empty() and highlight < 0) or steady or fposmod(_highlight_clock,1.2)<0.6
	var state := [positions.duplicate(),size,preferences.hash(),close_up,photo_focus,photo,photo_hold,highlight,highlights.duplicate(),directional,flash]
	if moving or state != _last_draw_state:
		_last_draw_state = state
		queue_redraw()

func view_scale() -> float:
	var outer := geometry.inner_radius+4.6*geometry.lane_width
	return minf((size.x-90.0)/(2*(geometry.straight_half+outer)),(size.y-100.0)/(2*outer*0.87))*preferences.get("zoom",1.0)

func project(point: Vector2) -> Vector2:
	var scale_factor := view_scale()
	return Vector2(size.x*0.5+point.x*scale_factor,size.y*0.54+point.y*scale_factor*0.87*preferences.get("camera_height",1.0))

func display_point(progress: float, lane: int) -> Vector2:
	return geometry.point(progress+FINISH_PHASE,lane)

func display_finish_point(lane: int) -> Vector2:
	return display_point(0.0,lane)

func outline(radius: float) -> PackedVector2Array:
	var border := Geometry.new()
	border.straight_half = geometry.straight_half
	border.inner_radius = radius
	var points := PackedVector2Array()
	for sample in range(241):
		points.append(project(border.point(float(sample)/240.0,0)))
	return points

func _draw() -> void:
	if preferences.is_empty():
		return
	geometry.lane_width = preferences.get("lane_spacing",56.0)
	draw_style_box(background(),Rect2(Vector2.ZERO,size))
	if close_up:
		draw_close_finish()
		return
	var outer := geometry.inner_radius+4.5*geometry.lane_width
	var inner := geometry.inner_radius-0.5*geometry.lane_width
	draw_colored_polygon(outline(outer+12),Color("aaa997") if photo else Color("a5aa82"))
	draw_colored_polygon(outline(outer),Color("a7a7a1") if photo else Color("b69a70"))
	draw_colored_polygon(outline(inner),Color("606b5e") if photo else Color("627c40"))
	for lane in range(5):
		var path := PackedVector2Array()
		for sample in range(241):
			path.append(project(geometry.point(float(sample)/240.0,lane)))
		draw_polyline(path,Color("302a25"),2.8,true)
	for radius in [inner-6,outer+8]:
		draw_polyline(outline(radius),Color("eee7cc"),3.5,true)
		var rail := Geometry.new()
		rail.straight_half = geometry.straight_half
		rail.inner_radius = radius
		for post in range(48):
			var point := project(rail.point(float(post)/48.0,0))
			draw_line(point,point-Vector2(0,7),Color("f2edda"),2)
	draw_infield()
	var start_inner := project(display_finish_point(0))
	var start_outer := project(display_finish_point(4))
	draw_line(start_inner-Vector2(0,12),start_outer+Vector2(0,12),Color("fff6dc"),float(preferences.get("finish_line_width",3)))
	draw_string(ThemeDB.fallback_font,start_outer+Vector2(-20,26),"FINISH",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ffe7a1"))
	var display_order := range(5)
	display_order.sort_custom(func(a,b): return project(display_point(positions[a]/1000.0,a)).y < project(display_point(positions[b]/1000.0,b)).y)
	if preferences.get("nose_guides",true):
		for horse in display_order: draw_nose_guide(horse)
	for horse in display_order:
		draw_horse(horse)
	# Draw number overlays after every figure so another horse cannot cover a winner.
	for horse in display_order:
		if not horse in highlights: draw_number(horse)
	for horse in highlights: draw_number(horse)
	draw_string(ThemeDB.fallback_font,Vector2(24,29),"SD MODE  /  MECHANICAL TRACK",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("f4d185"))
	if not highlights.is_empty():
		for rank in range(highlights.size()):
			var result := "%s  %d" % ["1ST" if rank == 0 else "2ND",highlights[rank]+1]
			var point := Vector2(size.x-280+rank*140,37)
			draw_string_outline(ThemeDB.fallback_font,point,result,HORIZONTAL_ALIGNMENT_LEFT,-1,28,5,Color("16130e"))
			draw_string(ThemeDB.fallback_font,point,result,HORIZONTAL_ALIGNMENT_LEFT,-1,28,number_color(highlights[rank]))

func draw_infield() -> void:
	var center := project(Vector2.ZERO)
	draw_rect(Rect2(center+Vector2(-36,-21),Vector2(72,42)),Color("ded7bb"))
	draw_rect(Rect2(center+Vector2(-39,-28),Vector2(78,12)),Color("884538"))
	draw_rect(Rect2(center+Vector2(-10,1),Vector2(18,20)),Color("594c37"))
	for x in [-145.0,-115.0,115.0,145.0]:
		var point := project(Vector2(x,0))
		draw_line(point+Vector2(0,10),point-Vector2(0,15),Color("554333"),4)
		draw_circle(point-Vector2(0,20),12,Color("365532"))
		draw_circle(point-Vector2(3,25),8,Color("49683b"))

func nose_offset(horse: int) -> Vector2:
	var scale_factor: float=photo_scale() if close_up else preferences.get("horse_scale",1.55)*clampf(view_scale(),0.4,1.25)
	return (Vector2(24*horse_facing(horse),-16*0.7)*scale_factor).rotated(horse_rotation(horse))

func horse_facing(horse: int) -> float:
	if close_up or not directional: return 1.0
	var progress: float=positions[horse]/1000.0
	var here := display_point(progress,horse)
	return -1.0 if display_point(progress+0.0001,horse).x<here.x else 1.0

func horse_rotation(horse: int) -> float:
	if close_up: return -PI/4.0
	# Rock the figurine around its nose. Vertical bobbing must not move the
	# apparent race progress, particularly on lanes with different bend radii.
	var scale_factor: float=preferences.get("horse_scale",1.55)*clampf(view_scale(),0.4,1.25)
	return -atan2(horse_bounce(horse),48.0*scale_factor)*horse_facing(horse)

func nose_guide(horse: int) -> PackedVector2Array:
	# Equal logical progress is one common cross-section across every lane.
	# Do not infer phase from sprite offsets, bounce, or lane circumference.
	var rail := Geometry.new()
	rail.straight_half=geometry.straight_half
	var ends := PackedVector2Array()
	for edge in [-0.5,4.5]:
		rail.inner_radius=geometry.inner_radius+edge*geometry.lane_width
		ends.append(project(rail.point(positions[horse]/1000.0+FINISH_PHASE,0)))
	return ends

func draw_nose_guide(horse: int) -> void:
	var ink: Color=COLORS[horse]
	ink.a=preferences.get("guide_opacity",0.25)
	draw_polyline(nose_guide(horse),ink,1.4,true)

func draw_horse(horse: int) -> void:
	var point := horse_point(horse)
	var scale_factor: float = photo_scale() if close_up else preferences.get("horse_scale",1.55)*clampf(view_scale(),0.4,1.25)
	var step := horse_bounce(horse)
	var facing := horse_facing(horse)
	draw_set_transform(point,horse_rotation(horse),Vector2(facing,0.7)*scale_factor)
	var coat: Color = [Color("81502d"),Color("ae8452"),Color("4e3527"),Color("bd9a68"),Color("795038")][horse]
	var color := horse_color(horse)
	if photo:
		coat = Color("8b8982")
		color = Color.from_hsv(0,0,0.45+horse*0.1)
	# Metal carriage, rigid legs and a modeled horse body, like a cabinet figurine.
	draw_style_box(base_plate(),Rect2(-19,9,39,5))
	for leg in [-11,9]:
		draw_line(Vector2(leg,-1),Vector2(leg+step,10),coat.darkened(0.15),3.5)
	draw_colored_polygon(PackedVector2Array([Vector2(-16,-9),Vector2(-11,-14),Vector2(8,-13),Vector2(14,-22),Vector2(21,-22),Vector2(24,-16),Vector2(15,-13),Vector2(13,-3),Vector2(6,0),Vector2(-12,-1)]),coat)
	draw_line(Vector2(-15,-9),Vector2(-24,-3),Color("31261f"),3)
	draw_line(Vector2(10,-13),Vector2(16,-22),Color("30251c"),2)
	draw_colored_polygon(PackedVector2Array([Vector2(16,-22),Vector2(16,-28),Vector2(20,-23)]),coat)
	draw_circle(Vector2(20,-20),1,Color("181816"))
	draw_rect(Rect2(-7,-14,14,12),color)
	draw_line(Vector2(-3,-19),Vector2(1,-13),color,6)
	draw_circle(Vector2(-4,-23),3.5,Color("e7c89f"))
	draw_arc(Vector2(-4,-24),4,PI,TAU,10,color,3,true)
	draw_line(Vector2(-2,-18),Vector2(12,-17),Color("d4b592"),2)
	draw_set_transform(Vector2.ZERO)

func horse_bounce(horse: int) -> float:
	if close_up or not moving or positions[horse] >= 1000.0 or not preferences.get("horse_animation",true) or preferences.get("reduced_motion",false) or photo:
		return 0.0
	var frames: float = preferences.get("animation_frames",12)
	var phase := floorf(_animation_clock*2.2*frames)/frames*TAU
	return sin(phase+horse)*preferences.get("stepping_strength",0.5)*8.0

func draw_number(horse: int) -> void:
	if number_visible(horse):
		var point := horse_point(horse)
		var font_size := horse_number_font_size(horse)
		var text := str(horse+1)
		var width := ThemeDB.fallback_font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		var number_point := point+Vector2(-width/2.0,0)
		draw_string_outline(ThemeDB.fallback_font,number_point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,6,Color("16130e"))
		draw_string(ThemeDB.fallback_font,number_point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,number_color(horse))

func number_visible(horse: int) -> bool:
	return preferences.get("show_horse_numbers",true) or preferences.get("always_numbers",true) or horse in highlights or horse == highlight

func number_font_size() -> int:
	var font_size := int((30 if close_up else 20)*preferences.get("number_size",1.0))
	if not highlights.is_empty(): return maxi(font_size,34)
	return maxi(font_size,30) if photo_hold and preferences.get("photo_numbers",true) else font_size

func horse_number_font_size(horse: int) -> int:
	if horse in highlights or horse == highlight or (photo_hold and preferences.get("photo_numbers",true)):
		return number_font_size()
	return int((30 if close_up else 20)*preferences.get("number_size",1.0))

func number_color(horse: int) -> Color:
	var rank := highlights.find(horse)
	if rank < 0 and horse == highlight:
		rank = 1
	if rank < 0:
		return Color("fff9e9")
	var bright: bool = preferences.get("reduce_flashing",false) or preferences.get("reduced_motion",false) or fposmod(_highlight_clock,1.2) < 0.6
	return (Color("53ff3f") if rank == 0 else Color("fff12d")) if bright else (Color("206a1a") if rank == 0 else Color("877815"))

func base_plate() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("a9a596")
	style.border_color = Color("514d43")
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style

func background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("354c31") if not photo else Color("3a3b37")
	style.border_color = Color("a47a40")
	style.set_border_width_all(7)
	style.set_corner_radius_all(8)
	return style

func horse_color(horse: int) -> Color:
	match preferences.get("colorblind_mode","Standard"):
		"Deuteranopia", "Protanopia":
			return [Color("0072b2"),Color("eeeeee"),Color("e69f00"),Color("cc79a7"),Color("56b4e9")][horse]
		"Tritanopia":
			return [Color("d81b60"),Color("ffffff"),Color("1e88e5"),Color("ffc107"),Color("666666")][horse]
		"Monochrome":
			return Color.from_hsv(0,0,0.35+horse*0.15)
	return COLORS[horse]

func photo_scale() -> float:
	return photo_frame().scale

func horse_length_units() -> float:
	var live_figure: float=preferences.get("horse_scale",1.55)*clampf(view_scale(),0.4,1.25)
	return 48.0*live_figure/(maxf(0.001,view_scale())*geometry.straight_half*8.0/1000.0)

func configure_photo_frame(start: Array, end: Array) -> void:
	_photo_start=start.duplicate(); _photo_end=end.duplicate()
	_photo_cache_key=[]
	close_up=true

func photo_safe_rect() -> Rect2:
	return Rect2(24,58,maxf(1,size.x-72),maxf(1,size.y-94))

func photo_relative(progress: float, lane: float) -> Vector2:
	var live_figure: float=preferences.get("horse_scale",1.55)*clampf(view_scale(),0.4,1.25)
	var scale_factor := view_scale()/live_figure
	var forward := Vector2(1,-1).normalized()
	var across := Vector2(1,1).normalized()
	var per_tick := geometry.straight_half*8.0/1000.0
	var lane_step: float=preferences.get("lane_spacing",56.0)*0.87*preferences.get("camera_height",1.0)
	return forward*((progress-1000.0)*per_tick*scale_factor)+across*((lane-photo_focus)*lane_step*scale_factor)

func photo_figure_bounds() -> Rect2:
	var corners: Array[Vector2]=[]
	var nose_offset := Vector2(24,-16*0.7).rotated(-PI/4.0)
	for x in [-28.0,28.0]:
		for y in [-36.0,18.0]: corners.append(Vector2(x,y*0.7).rotated(-PI/4.0)-nose_offset)
	var box := Rect2(corners[0],Vector2.ZERO)
	for corner in corners: box=box.expand(corner)
	return box

func photo_frame() -> Dictionary:
	var key := [size,preferences.hash(),photo_focus,_photo_start,_photo_end]
	if key==_photo_cache_key and not _photo_frame_cache.is_empty(): return _photo_frame_cache
	_photo_cache_key=key.duplicate(true)
	var nominal := clampf(minf(size.x/1050.0,size.y/650.0)*3.6,2.0,5.0)
	if _photo_start.size()!=5 or _photo_end.size()!=5:
		_photo_frame_cache={"scale":nominal,"origin":Vector2(size.x*0.53,size.y*0.43)}
		return _photo_frame_cache
	var figure := photo_figure_bounds()
	var bounds := Rect2(photo_relative(_photo_start[0],0)+figure.position,figure.size)
	for row in [_photo_start,_photo_end]:
		for h in range(5): bounds=bounds.merge(Rect2(photo_relative(row[h],h)+figure.position,figure.size))
	var available := photo_safe_rect()
	# Number glyphs use screen-sized fonts, so reserve their extent separately.
	var font_pad := maxf(34.0,30.0*preferences.get("number_size",1.0))+8.0
	var scale_factor := minf(nominal,minf((available.size.x-font_pad*2)/maxf(1,bounds.size.x),(available.size.y-font_pad*2)/maxf(1,bounds.size.y)))
	scale_factor=maxf(0.05,scale_factor)
	_photo_frame_cache={"scale":scale_factor,"origin":available.get_center()-bounds.get_center()*scale_factor}
	return _photo_frame_cache

func photo_horse_bounds(horse: int) -> Rect2:
	var scale_factor := photo_scale()
	var nose := photo_nose(positions[horse],horse)
	var figure := photo_figure_bounds()
	var bounds := Rect2(nose+figure.position*scale_factor,figure.size*scale_factor)
	var point := nose-Vector2(24,-16*0.7).rotated(-PI/4.0)*scale_factor
	var font_size := maxf(34.0,30.0*preferences.get("number_size",1.0))+8.0
	return bounds.merge(Rect2(point-Vector2(font_size/2,font_size),Vector2(font_size,font_size+8)))

func photo_distance_scale() -> float:
	# Match live distance in horse lengths, including its small-window size clamp.
	var live_figure: float=preferences.get("horse_scale",1.55)*clampf(view_scale(),0.4,1.25)
	return view_scale()*photo_scale()/live_figure

func photo_nose(progress: float, lane: float) -> Vector2:
	# An oblique finish camera: forward motion and lane spacing are separate axes.
	# The recorded crossing is the NOSE at the tape, not the carriage center.
	var frame := photo_frame()
	return frame.origin+photo_relative(progress,lane)*frame.scale

func horse_point(horse: int) -> Vector2:
	if close_up:
		var nose_offset := Vector2(24,-16*0.7).rotated(-PI/4.0)*photo_scale()
		return photo_nose(positions[horse],horse)-nose_offset
	return project(display_point(positions[horse]/1000.0,horse))-nose_offset(horse)

func draw_close_finish() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("85847e") if photo else Color("ac8d66"))
	var rail := Color("e7dfc8")
	var extent := size.length()/(geometry.straight_half*8.0/1000.0*photo_distance_scale())
	for lane in range(6):
		var a := photo_nose(1000.0-extent,lane-0.5)+Vector2(0,38*photo_scale()/3.6)
		var b := photo_nose(1000.0+extent,lane-0.5)+Vector2(0,38*photo_scale()/3.6)
		draw_line(a,b,Color("36312d"),3,true)
		if lane in [0,5]: draw_line(a-Vector2(0,18),b-Vector2(0,18),rail,5,true)
	var order := range(5)
	order.sort_custom(func(a,b): return horse_point(a).y<horse_point(b).y)
	for horse in order: draw_horse(horse)
	var tape_a := photo_nose(1000.0,-0.5)
	var tape_b := photo_nose(1000.0,4.5)
	draw_line(tape_a,tape_b,Color("181716"),7,true)
	draw_line(tape_a,tape_b,Color("fffbea"),3,true)
	for horse in order:
		if not horse in highlights: draw_number(horse)
	for horse in highlights: draw_number(horse)
	var heading := "PHOTO FINISH  |  SECOND HORSE AT THE LINE" if photo_hold else "PHOTO FINISH  |  SLOW MOTION"
	draw_string_outline(ThemeDB.fallback_font,Vector2(22,34),heading,HORIZONTAL_ALIGNMENT_LEFT,-1,20,5,Color("24201a"))
	draw_string(ThemeDB.fallback_font,Vector2(22,34),heading,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("fff3bf"))
