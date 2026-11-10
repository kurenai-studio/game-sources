class_name Fragment
extends RigidBody2D
# ---------- Осколок ----------
# Первые 1.5 с — твёрдый и ранит. Потом лежит обломком.
# Если обломков больше MAX_DEBRIS, самые старые исчезают.

const SOLID_TIME := 1.5
const MAX_DEBRIS := 200
static var all: Array = []

var size := Vector2(15, 15)
var color := Color.WHITE
var team := -1
var attacker = null
var hurt := 5
var ghost := false           # осколок задней стены: ни с чем не сталкивается и тает
var _last_speed := 0.0
var _vis: ColorRect
var tex: Texture2D           # кусочек текстуры объекта, от которого откололся
var tex_mod := Color.WHITE
var _spr: Sprite2D
var _gone := false

func _ready() -> void:
	if ghost:
		_ready_ghost()
		return
	collision_layer = Layer.FRAG
	collision_mask = Layer.WORLD | Layer.PLAYER | Layer.BOT | Layer.FRAG
	contact_monitor = true
	max_contacts_reported = 2
	body_entered.connect(_on_body_entered)
	var col := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = size * 0.9
	col.shape = rs
	add_child(col)
	_vis = ColorRect.new()
	_vis.size = size
	_vis.position = -size / 2
	_vis.color = color
	add_child(_vis)
	if tex:
		_vis.visible = false
		_spr = Sprite2D.new()
		_spr.texture = tex
		_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_spr.scale = size / tex.get_size()
		_spr.modulate = tex_mod
		add_child(_spr)
	all.append(self)
	while all.size() > MAX_DEBRIS:
		var old = all.pop_front()
		if is_instance_valid(old):
			old.vanish()
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = SOLID_TIME
	add_child(t)
	t.timeout.connect(_become_debris)
	t.start()

func _ready_ghost() -> void:
	collision_layer = 0
	collision_mask = 0
	z_index = -6
	_vis = ColorRect.new()
	_vis.size = size
	_vis.position = -size / 2
	_vis.color = color.darkened(0.2)
	add_child(_vis)
	var t := create_tween()
	t.tween_interval(0.5)
	t.tween_property(self, "modulate:a", 0.0, 0.5)
	t.tween_callback(queue_free)

func _exit_tree() -> void:
	all.erase(self)

func _physics_process(_delta: float) -> void:
	_last_speed = linear_velocity.length()

func _on_body_entered(body: Node) -> void:
	if hurt <= 0 or _last_speed < 250.0:
		return
	if body.has_method("take_damage") and body.team != team:
		body.take_damage(hurt, attacker)
		hurt = 0

func _become_debris() -> void:
	if _gone:
		return
	collision_layer = Layer.DEBRIS
	collision_mask = Layer.WORLD     # лежит на земле, героям не мешает
	hurt = 0
	contact_monitor = false
	set_physics_process(false)
	_vis.color = _vis.color.darkened(0.25)
	if _spr:
		_spr.modulate = _spr.modulate.darkened(0.25)

func vanish() -> void:
	if _gone:
		return
	_gone = true
	collision_layer = 0
	collision_mask = 0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.5)
	t.tween_callback(queue_free)
