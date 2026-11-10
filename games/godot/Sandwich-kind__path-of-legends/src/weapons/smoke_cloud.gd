class_name SmokeCloud
extends Node2D
# Облако дыма от дымовой бомбы гоблинов: густое, поверх всего — сквозь него
# ничего не видно (ни героев, ни врагов). Держится несколько секунд и тает.

var radius := 230.0
var duration := 6.0
var _puffs: Array = []
var _t := 0.0

func _ready() -> void:
	z_index = 60
	for i in 26:
		var p := Polygon2D.new()
		var r := randf_range(60.0, 110.0)
		p.polygon = Util.circle(r, 14)
		var g := randf_range(0.48, 0.62)
		p.color = Color(g, g + 0.02, g, 0.92)
		var a := randf() * TAU
		var d := sqrt(randf()) * radius * 0.75
		p.position = Vector2(cos(a) * d, sin(a) * d * 0.7 - 40.0)
		p.scale = Vector2.ZERO
		p.set_meta("drift", Vector2(randf_range(-12, 12), randf_range(-14, 2)))
		add_child(p)
		_puffs.append(p)
		var t := p.create_tween()
		t.tween_property(p, "scale", Vector2.ONE, randf_range(0.25, 0.5)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_t += delta
	for p in _puffs:
		p.position += p.get_meta("drift") * delta
		p.rotation += delta * 0.2
	if _t > duration:
		modulate.a -= delta / 1.2
		if modulate.a <= 0.0:
			queue_free()
