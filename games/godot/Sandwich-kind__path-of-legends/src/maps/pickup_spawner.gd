class_name PickupSpawner
extends Node2D
# Неразрушаемая станция, которая выдаёт шарики.
#   heal — станция лечения: сердце появляется раз в HEAL_RESPAWN секунд.
#   buff — алтарь баффов: после подбора новый бафф через BUFF_RESPAWN секунд;
#          если бафф долго не забирают, он сменяется другим.

signal picked(text: String, color: Color, where: Vector2)

const HEAL_RESPAWN := 10.0
const BUFF_RESPAWN := 15.0
const BUFF_SWAP := 18.0

var kind := "heal"
var fixed := ""               # всегда один и тот же бафф (карта TEST_BUFFS)
var mega := false             # и сразу МЕГА
var respawn := 0.0            # своя пауза между появлениями (0 — обычная)
var mega_chance := 0.0        # шанс, что бафф сразу МЕГА (алтарь в домике на дереве)
var _orb: Pickup
var _t := 2.0
var _age := 0.0
var _last := ""
var _crystal: Polygon2D

func _ready() -> void:
	z_index = -1
	# подставка
	# резной каменный алтарь: основание, ствол, верхняя плита
	var stone := Color(0.50, 0.47, 0.56) if kind == "buff" else Color(0.58, 0.48, 0.45)
	for part in [[Vector2(52, 6), -3.0], [Vector2(34, 8), -10.0], [Vector2(44, 5), -16.5]]:
		var sl := Tex.slab(part[0], "stone", stone, int(part[0].x))
		sl.position = Vector2(0, part[1])
		add_child(sl)
	var cc := Color(1.0, 0.4, 0.5) if kind == "heal" else Color(0.6, 0.9, 1.0)
	_crystal = Polygon2D.new()                 # гранёный кристалл
	_crystal.polygon = PackedVector2Array([Vector2(-7, -19), Vector2(0, -32), Vector2(7, -19), Vector2(0, -15)])
	_crystal.color = cc
	add_child(_crystal)
	var facet := Polygon2D.new()
	facet.polygon = PackedVector2Array([Vector2(-7, -19), Vector2(0, -32), Vector2(0, -15)])
	facet.color = Color(1, 1, 1, 0.35)
	_crystal.add_child(facet)
	var shine := Polygon2D.new()
	shine.polygon = PackedVector2Array([Vector2(-3, -22), Vector2(-1, -28), Vector2(0, -22)])
	shine.color = Color(1, 1, 1, 0.8)
	_crystal.add_child(shine)
	if kind == "buff":
		_t = randf_range(3.0, 6.0)
	if fixed != "":
		_t = 0.3

func _process(delta: float) -> void:
	_crystal.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() / 250.0)
	if _orb != null and is_instance_valid(_orb):
		_age += delta
		if kind == "buff" and fixed == "" and _age > BUFF_SWAP:
			_orb.queue_free()            # долго не берут — бафф сменяется другим
			_spawn()
		return
	_t -= delta
	if _t <= 0.0:
		_spawn()

func _spawn() -> void:
	_age = 0.0
	_orb = Pickup.new()
	if kind == "heal":
		_orb.kind = "heal"
		_t = HEAL_RESPAWN
	elif fixed != "":
		_orb.kind = fixed
		_orb.mega = mega
		_t = BUFF_RESPAWN
	else:
		_orb.kind = Buffs.random_type(_last)
		_last = _orb.kind
		_orb.mega = randf() < mega_chance
		_t = BUFF_RESPAWN
	if respawn > 0.0:
		_t = respawn
	_orb.position = position + Vector2(0, -60)
	_orb.picked.connect(func(text, color): picked.emit(text, color, position + Vector2(0, -60)))
	get_parent().add_child(_orb)

func _exit_tree() -> void:
	if _orb != null and is_instance_valid(_orb):
		_orb.queue_free()
