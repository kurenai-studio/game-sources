extends RefCounted
## Original gameplay VFX inspired by the feel of Ridiculous Coding.
## No plugin code/assets. Render behind and around the timing landmarks.

const INK: Color = Color("10121f")
const LIME: Color = Color("dcff50")
const CYAN: Color = Color("2bcbd4")
const PINK: Color = Color("f776a7")
const PAPER: Color = Color("eee9d4")
const MAX_SHARDS: int = 144
const MAX_GLYPHS: int = 18
const MAX_RINGS: int = 8

var shards: Array[Dictionary] = []
var glyphs: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var punch: float = 0.0
var punch_at: Vector2 = Vector2.ZERO
var shake: float = 0.0
var heat: float = 0.0
var banner_time: float = 0.0
var banner: String = ""
var banner_combo: int = 0
var elapsed: float = 0.0

func clear() -> void:
	shards.clear()
	glyphs.clear()
	rings.clear()
	punch = 0.0
	shake = 0.0
	heat = 0.0
	banner_time = 0.0
	banner = ""

func hit(at: Vector2, perfect: bool, combo: int) -> void:
	var power: float = minf(float(combo)/25.0,2.0)
	var color: Color = LIME if perfect else CYAN
	heat = maxf(heat,0.25+power*0.25)
	punch_at = at
	punch = 1.0 if perfect else 0.55
	shake = maxf(shake,0.75+power*0.6 if perfect else 0.35)
	if rings.size() >= MAX_RINGS:
		rings.pop_front()
	rings.append({"at": at,"age": 0.0,"duration": 0.26,"color": color,"power": power})
	_emit(at,9+int(power*5)+(4 if perfect else 0),color,75.0+power*25.0)
	for i in range(3 if perfect else 1):
		if glyphs.size() >= MAX_GLYPHS:
			glyphs.pop_front()
		glyphs.append({"at": at+Vector2(randf_range(-22,22),randf_range(-16,0)),"velocity": Vector2(randf_range(-40,30),randf_range(-80,-45)),"life": 0.42,"char": ["+","!","*"][i%3],"color": color})
	if combo > 0 and combo%10 == 0:
		banner_combo = combo
		banner = "SWAG!" if combo < 20 else ("CAT ON FIRE!" if combo < 40 else "UNTOUCHABLE!")
		banner_time = 0.85
		shake = 2.5
		heat = 1.0
		# Fireworks stay above the playable corridor, away from upcoming notes.
		_emit(Vector2(414,113),30,PINK,125.0)
		_emit(Vector2(527,105),18,CYAN,100.0)

func _emit(at: Vector2, count: int, color: Color, speed: float) -> void:
	for i in range(count):
		if shards.size() >= MAX_SHARDS:
			shards.pop_front()
		var angle: float = randf_range(-PI,PI)
		var velocity: Vector2 = Vector2.from_angle(angle)*randf_range(speed*0.45,speed)
		shards.append({"at": at,"velocity": velocity,"life": randf_range(0.20,0.45),"total": 0.45,"color": color if i%4 else PAPER,"kind": i%3})

func tick(delta: float) -> void:
	elapsed += delta
	punch = maxf(0.0,punch-delta*6.5)
	shake = maxf(0.0,shake-delta*14.0)
	heat = maxf(0.0,heat-delta*2.0)
	banner_time = maxf(0.0,banner_time-delta)
	for ring in rings:
		ring["age"] += delta
	for shard in shards:
		shard["life"] -= delta
		shard["at"] += shard["velocity"]*delta
		shard["velocity"].y += delta*85.0
	for glyph in glyphs:
		glyph["life"] -= delta
		glyph["at"] += glyph["velocity"]*delta
		glyph["velocity"].y += delta*60.0
	rings = rings.filter(func(r: Dictionary) -> bool: return r["age"] < r["duration"])
	shards = shards.filter(func(s: Dictionary) -> bool: return s["life"] > 0.0)
	glyphs = glyphs.filter(func(g: Dictionary) -> bool: return g["life"] > 0.0)

func background_offset() -> Vector2:
	# Only scenery moves. Judgement column, notes, cat and barriers stay stable.
	return Vector2(roundf(sin(elapsed*97.0)*shake),roundf(cos(elapsed*83.0)*shake*0.55))

func draw_back(c: CanvasItem) -> void:
	if punch > 0.0:
		var points := PackedVector2Array()
		for i in range(20):
			var radius: float = (39.0 if i%2 == 0 else 20.0)*(0.7+punch*0.3)
			points.append(punch_at+Vector2.from_angle(float(i)/20.0*TAU-0.2)*radius)
		c.draw_colored_polygon(points,Color(LIME,punch*0.18))
	if heat > 0.0:
		# Peripheral streaks leave the y=180..260 timing corridor clear.
		for i in range(10):
			var x: float = fposmod(640.0-float(i*83)-elapsed*650.0,700.0)-30.0
			var y: float = float(68+(i*29)%92)
			var length: float = 10.0+heat*35.0
			c.draw_line(Vector2(x,y),Vector2(x+length,y),Color(CYAN,heat*0.32),1)

func draw_front(c: CanvasItem, font: Font) -> void:
	for ring in rings:
		var age: float = float(ring["age"])/float(ring["duration"])
		var at: Vector2 = ring["at"]
		var color: Color = ring["color"]
		color.a = (1.0-age)*0.8
		var radius: float = 7.0+sqrt(age)*(28.0+float(ring["power"])*8.0)
		c.draw_arc(at,radius,0,TAU,32,color,1)
		if float(ring["power"]) >= 0.8:
			c.draw_arc(at,radius*0.7,-PI*0.8,PI*0.8,24,Color(PINK,color.a*0.6),1)
	for shard in shards:
		var at: Vector2 = shard["at"]
		at = at.round()
		var color: Color = shard["color"]
		color.a = minf(1.0,float(shard["life"])*5.0)
		var velocity: Vector2 = shard["velocity"]
		match int(shard["kind"]):
			0:
				c.draw_line(at,at-velocity.normalized()*5.0,color,1)
			1:
				c.draw_rect(Rect2(at,Vector2(3,3)),color)
			2:
				c.draw_line(at-Vector2(2,0),at+Vector2(2,0),color,1)
				c.draw_line(at-Vector2(0,2),at+Vector2(0,2),color,1)
	for glyph in glyphs:
		var color: Color = glyph["color"]
		color.a = minf(1.0,float(glyph["life"])*5.0)
		var at: Vector2 = glyph["at"]
		c.draw_string_outline(font,at.round(),glyph["char"],HORIZONTAL_ALIGNMENT_LEFT,-1,10,3,INK)
		c.draw_string(font,at.round(),glyph["char"],HORIZONTAL_ALIGNMENT_LEFT,-1,10,color)
	if banner_time > 0.0:
		_draw_banner(c,font)

func _draw_banner(c: CanvasItem, font: Font) -> void:
	var age: float = 0.85-banner_time
	var opacity: float = minf(1.0,banner_time*6.0)
	var scale: float = 1.0+maxf(0.0,1.0-age*9.0)*0.2
	c.draw_set_transform(Vector2(433,105),-0.055,Vector2.ONE*scale)
	var width: float = font.get_string_size(banner,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x+20.0
	var points := PackedVector2Array([Vector2(-width/2-5,-26),Vector2(width/2+7,-22),Vector2(width/2+2,4),Vector2(-width/2-9,1)])
	c.draw_colored_polygon(points,Color(INK,opacity*0.95))
	c.draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[3],points[0]]),Color(PINK,opacity),1)
	var label: String = "%d COMBO" % banner_combo
	var label_width: float = font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
	c.draw_string(font,Vector2(-label_width/2,-30),label,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color(CYAN,opacity))
	var text_width: float = font.get_string_size(banner,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x
	c.draw_string(font,Vector2(-text_width/2,-3),banner,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(LIME,opacity))
	c.draw_set_transform(Vector2.ZERO)
