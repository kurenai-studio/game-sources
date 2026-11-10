class_name Destructible
extends RigidBody2D
# ---------- Разрушаемый объект из клеток ----------

signal cells_removed(count: int, attacker, at: Vector2)   # выбиты клетки (самоцветы дают золото, фонарь гаснет)

var cell := 20.0
var cols := 1
var rows := 1
var color := Color.WHITE
var cell_hp := 20
var density := 20.0          # сколько «пробития» отнимает у пробивающих снарядов
var family := 0              # общий номер для объекта и его обломков
var shield_team := -1        # для щита: чья команда может стрелять сквозь него
var lifetime := 0.0          # для щита: через сколько секунд исчезнет
var anchored := false
var anchors: Array = []
var cells := {}
var cell_colors := {}        # свой цвет для отдельных клеток (если нужен)
var background := false      # фон: герои, пули и гранаты проходят насквозь
var ghost := false           # задняя стена: никогда не становится осязаемой
var flammable := false       # клетки загораются от огня и огонь перекидывается на соседние
var one_way := false         # платформа: снизу можно пропрыгнуть насквозь, сверху — стоять
var mat_kind := ""           # из чего объект (crate, stone, wood...): определяет текстуру; пусто — по цвету
var _tex: Texture2D          # цельная картинка объекта, клетки берут из неё свои кусочки
var _tp := 8                 # пикселей рисунка на клетку
var _img: Image

const BURN_TIME := 3.0       # сколько горит одна клетка
const BURN_TICK := 0.4
const BURN_DAMAGE := 6
const BURN_SPREAD := 0.15    # шанс поджечь соседнюю клетку за такт
const FIRE_COLOR := Color(1.0, 0.45, 0.1)

var _burning := {}           # горящие клетки -> сколько ещё гореть
var _burn_tick := 0.0
var _nodes := {}
var _pending: Array = []
var _last_speed := 0.0
var _hurt_cd := 0.0

func _ready() -> void:
	if family == 0:
		family = get_instance_id()
	if background:
		collision_layer = Layer.BACK
		collision_mask = 0
		z_index = -6 if ghost else -5
		modulate = Color(0.78, 0.78, 0.86)    # фон чуть темнее
	else:
		collision_layer = Layer.WORLD
		collision_mask = Layer.WORLD | Layer.PLAYER | Layer.BOT
	if cells.is_empty():
		for x in cols:
			for y in rows:
				cells[Vector2i(x, y)] = cell_hp
	_build_texture()
	for c in cells:
		_create_cell_nodes(c)
	_refresh_mass()
	can_sleep = false
	body_entered.connect(_on_body_entered)
	if anchored:
		freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
		freeze = true
	else:
		contact_monitor = true
		max_contacts_reported = 4
	if lifetime > 0.0:
		var t := create_tween()
		t.tween_interval(lifetime)
		t.tween_property(self, "modulate:a", 0.0, 0.4)
		t.tween_callback(queue_free)

func _physics_process(delta: float) -> void:
	_last_speed = linear_velocity.length()
	_hurt_cd -= delta
	if not _burning.is_empty():
		_burn_tick -= delta
		if _burn_tick <= 0.0:
			_burn_tick = BURN_TICK
			_burn_step()

func _process(_delta: float) -> void:
	if _burning.is_empty():
		return
	var t := Time.get_ticks_msec() / 1000.0
	for c in _burning:
		if _nodes.has(c):
			var k := 0.45 + 0.3 * sin(t * 18.0 + c.x * 1.7 + c.y * 2.3)
			_nodes[c][1].modulate = _cell_color(c).lerp(FIRE_COLOR, k)

# Горение: клетки теряют прочность, огонь перекидывается на соседние
func _burn_step() -> void:
	var removed: Array = []
	var ignite: Array = []
	for c in _burning.keys():
		if not cells.has(c):
			_burning.erase(c)
			continue
		_burning[c] -= BURN_TICK
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if cells.has(n) and not _burning.has(n) and randf() < BURN_SPREAD:
				ignite.append(n)
		cells[c] -= BURN_DAMAGE
		if cells[c] <= 0:
			cells.erase(c)
			_burning.erase(c)
			var p := to_global(_cell_center(c))
			removed.append([c, {"point": p, "dir": Vector2.UP, "dmg": BURN_DAMAGE, "team": -1,
					"radial": true, "power": 0.3, "origin": p + Vector2(0, 10),
					"attacker": null, "ember": true}])
		elif _burning[c] <= 0.0:
			_burning.erase(c)
			_nodes[c][1].modulate = _cell_color(c)
	for n in ignite:
		_burning[n] = BURN_TIME
	_finish_removal(removed)
# Тяжёлый падающий кусок бьёт того, на кого упал
func _on_body_entered(body: Node) -> void:
	if freeze or _hurt_cd > 0.0 or _last_speed < 300.0 or mass < 1.0:
		return
	if body.has_method("take_damage"):
		body.take_damage(int(clampf(mass * _last_speed / 80.0, 5.0, 30.0)))
		_hurt_cd = 0.5

func _cell_center(c: Vector2i) -> Vector2:
	var origin := -Vector2(cols, rows) * cell / 2.0
	return origin + (Vector2(c) + Vector2(0.5, 0.5)) * cell

# Оттенок клетки поверх текстуры: свой цвет клетки и потемнение от повреждений
func _cell_color(c: Vector2i) -> Color:
	var m := Color.WHITE
	if cell_colors.has(c):
		var own: Color = cell_colors[c]
		m = Color(clampf(own.r / maxf(color.r, 0.05), 0.3, 2.2), clampf(own.g / maxf(color.g, 0.05), 0.3, 2.2),
				clampf(own.b / maxf(color.b, 0.05), 0.3, 2.2))
	var hp_part := float(cells.get(c, cell_hp)) / cell_hp
	return m.darkened(0.35 * (1.0 - hp_part))

# Текстура всего объекта (общая для отколовшихся кусков)
func _build_texture() -> void:
	_tp = Tex.texel(cell)
	if _tex != null:
		return
	if mat_kind == "":
		mat_kind = "energy" if shield_team >= 0 and color.a < 0.99 else Tex.material_for(color)
	_img = Tex.object_image(mat_kind, cells, cols, rows, _tp, color, family)
	_tex = ImageTexture.create_from_image(_img)

# Средний цвет кусочка клетки (для осколков)
func _cell_avg(c: Vector2i) -> Color:
	if _img == null:
		return color
	var sum := Color(0, 0, 0, 0)
	var n := 0
	for y in range(0, _tp, 2):
		for x in range(0, _tp, 2):
			var px := c.x * _tp + x
			var py := c.y * _tp + y
			if px < _img.get_width() and py < _img.get_height():
				sum += _img.get_pixel(px, py)
				n += 1
	return (sum / maxf(n, 1)) * _cell_color(c) if n > 0 else color

# Кусочек текстуры для клетки
func cell_texture(c: Vector2i) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = _tex
	at.region = Rect2(c.x * _tp, c.y * _tp, _tp, _tp)
	return at

# Трещины на повреждённой клетке
func _update_cracks(c: Vector2i) -> void:
	if not _nodes.has(c):
		return
	var spr: Sprite2D = _nodes[c][1]
	var hp_part := float(cells.get(c, cell_hp)) / cell_hp
	var stage := 0 if hp_part > 0.65 else (1 if hp_part > 0.35 else 2)
	var cr: Sprite2D = spr.get_node_or_null("Cracks")
	if stage == 0:
		if cr:
			cr.queue_free()
		return
	if cr == null:
		cr = Sprite2D.new()
		cr.name = "Cracks"
		cr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cr.use_parent_material = true
		spr.add_child(cr)
	cr.texture = Tex.cracks(_tp, stage)

func _create_cell_nodes(c: Vector2i) -> void:
	var col := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(cell, cell)
	col.shape = rs
	col.position = _cell_center(c)
	col.one_way_collision = one_way
	add_child(col)
	var vis := Sprite2D.new()
	vis.texture = cell_texture(c)
	vis.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vis.position = _cell_center(c)
	vis.scale = Vector2(cell / _tp, cell / _tp) * 1.002       # без щелей между клетками
	vis.modulate = _cell_color(c)
	vis.use_parent_material = true        # перелив самоцветов (Shimmer) — общий на весь объект
	add_child(vis)
	_nodes[c] = [col, vis]
	if cells.get(c, cell_hp) < cell_hp:
		_update_cracks(c)

func _remove_cell_nodes(c: Vector2i) -> void:
	_burning.erase(c)
	var col: CollisionShape2D = _nodes[c][0]
	col.disabled = true
	col.queue_free()
	_nodes[c][1].queue_free()
	_nodes.erase(c)

func _refresh_mass() -> void:
	mass = max(0.1, cells.size() * 0.2)

# opts: strict — бить, только если попадание рядом; radial — осколки разлетаются от точки
# (или от origin); power — сила разлёта осколков; push — сила толчка; attacker — кто бил;
# fire — поджигает горючие клетки
func hit(point: Vector2, dir: Vector2, damage: int, blast: float, team: int, opts := {}) -> void:
	_pending.append([point, dir, damage, blast, team, opts])
	if _pending.size() == 1:
		call_deferred("_process_hits")

func _process_hits() -> void:
	if not is_inside_tree():
		return
	var hits := _pending.duplicate()
	_pending.clear()
	var removed: Array = []
	for h in hits:
		var point: Vector2 = h[0]
		var local := to_local(point)
		var dir: Vector2 = h[1]
		var dmg: int = h[2]
		var blast: float = h[3]
		var opts: Dictionary = h[5]
		var cm := Balance.cell_mult(opts.get("attacker", null))
		if cm != 1.0:
			dmg = int(round(dmg * cm))             # в Дуэли легенды крушат всё вокруг быстрее
		var nearest = null
		var best := INF
		for c in cells:
			var d := _cell_center(c).distance_to(local)
			if d < best:
				best = d
				nearest = c
		if nearest == null:
			continue
		if opts.get("strict", false) and best > blast + cell * 0.5:
			continue
		var info := {"point": point, "dir": dir, "dmg": dmg, "team": h[4],
				"radial": opts.get("radial", false), "power": opts.get("power", -1.0),
				"origin": opts.get("origin", point), "attacker": opts.get("attacker", null),
				"fire": opts.get("fire", false), "chance": opts.get("chance", 1.0)}
		_damage_cell(nearest, info, removed)
		if blast > 0.0:
			for c in cells.keys():
				if c != nearest and _cell_center(c).distance_to(local) <= blast:
					_damage_cell(c, info, removed)
		if not freeze:
			var push_dir := dir
			if info["radial"]:
				push_dir = (global_position - point).normalized()
			var push: float = opts.get("push", 1.0)
			apply_impulse(push_dir * mini(dmg, 60) * 12.0 * push, point - global_position)
	_finish_removal(removed)

# Выбитые клетки превращаются в осколки, остаток проверяется на разлом
func _finish_removal(removed: Array) -> void:
	if removed.is_empty():
		return
	for r in removed:
		_spawn_fragment(r[0], r[1])
		_remove_cell_nodes(r[0])
	cells_removed.emit(removed.size(), removed[0][1].get("attacker"), to_global(_cell_center(removed[0][0])))
	_wake_debris()
	if cells.is_empty():
		queue_free()
		return
	_check_split()
	_refresh_mass()

# лежащие сверху обломки «просыпаются» и падают, если опору выбили
func _wake_debris() -> void:
	var r := Vector2(cols, rows).length() * cell * 0.5 + 40.0
	for f in Fragment.all:
		if is_instance_valid(f) and f.sleeping and f.global_position.distance_to(global_position) < r:
			f.sleeping = false

func _damage_cell(c: Vector2i, info: Dictionary, removed: Array) -> void:
	if not cells.has(c):
		return
	if randf() > info.get("chance", 1.0):   # некоторые удары задевают клетку лишь с шансом
		return
	cells[c] -= info["dmg"]
	if cells[c] <= 0:
		cells.erase(c)
		removed.append([c, info])
	else:
		_nodes[c][1].modulate = _cell_color(c)
		_update_cracks(c)
		if flammable and info.get("fire", false):
			_burning[c] = BURN_TIME

func _spawn_fragment(c: Vector2i, info: Dictionary) -> void:
	var f := Fragment.new()
	f.size = Vector2(cell, cell)
	f.color = _cell_avg(c)
	f.tex = cell_texture(c)
	f.tex_mod = _cell_color(c)
	f.team = info["team"]
	f.attacker = info["attacker"]
	f.hurt = 0 if shield_team >= 0 or info.get("ember", false) else int(cell / 3.0)
	f.ghost = ghost              # осколки задней стены неосязаемы
	var center := _cell_center(c)
	var gpos := to_global(center)
	f.position = gpos
	f.rotation = rotation
	var power: float = info["power"]
	if power < 0.0:
		power = clampf(1.0 + info["dmg"] / 25.0, 1.0, 2.2)
	var v: Vector2
	if info["radial"]:
		var away: Vector2 = (gpos - info["origin"]).normalized()
		v = away * randf_range(300, 500) + Vector2(randf_range(-80, 80), randf_range(-200, -80))
	else:
		# 60% летят назад к стрелку, 40% — насквозь, на ту сторону
		var side := -1.0 if randf() < 0.6 else 1.0
		var outward := center.normalized().rotated(rotation)
		var d: Vector2 = info["dir"]
		v = d * side * randf_range(250, 400) \
				+ outward * randf_range(80, 200) \
				+ Vector2(randf_range(-120, 120), randf_range(-320, -150))
	f.linear_velocity = linear_velocity + v * power
	f.angular_velocity = randf_range(-15, 15)
	get_parent().add_child(f)
	f.add_collision_exception_with(self)

func _check_split() -> void:
	if anchored:
		var has_anchor := false
		for a in anchors:
			if cells.has(a):
				has_anchor = true
		if not has_anchor:
			anchored = false
			if background:
				_make_tangible()     # срубленное дерево становится осязаемым
			freeze = false
			contact_monitor = true
			max_contacts_reported = 4

	var groups := _find_groups()
	var detached: Array = []
	if anchored:
		for g in groups:
			var attached := false
			for a in anchors:
				if g.has(a):
					attached = true
			if not attached:
				detached.append(g)
	else:
		var largest := 0
		for i in groups.size():
			if groups[i].size() > groups[largest].size():
				largest = i
		for i in groups.size():
			if i != largest:
				detached.append(groups[i])

	for g in detached:
		_split_off(g)

func _find_groups() -> Array:
	var groups: Array = []
	var seen := {}
	for start in cells:
		if seen.has(start):
			continue
		var group: Array = []
		var stack: Array = [start]
		seen[start] = true
		while not stack.is_empty():
			var c: Vector2i = stack.pop_back()
			group.append(c)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n: Vector2i = c + d
				if cells.has(n) and not seen.has(n):
					seen[n] = true
					stack.append(n)
		groups.append(group)
	return groups

func _split_off(group: Array) -> void:
	var piece := Destructible.new()
	piece.cell = cell
	piece.cols = cols
	piece.rows = rows
	piece.color = color
	piece.cell_hp = cell_hp
	piece.density = density
	piece.family = family
	piece.shield_team = shield_team
	piece.cell_colors = cell_colors
	piece.mat_kind = mat_kind
	piece._tex = _tex                      # отколовшийся кусок — с той же текстурой
	piece._img = _img
	piece.flammable = flammable           # отвалившийся кусок фона — уже осязаемый
	for c in group:
		piece.cells[c] = cells[c]
		if _burning.has(c):
			piece._burning[c] = _burning[c]
		cells.erase(c)
		_remove_cell_nodes(c)
	piece.transform = transform
	piece.linear_velocity = linear_velocity
	piece.angular_velocity = angular_velocity
	get_parent().add_child(piece)

func _make_tangible() -> void:
	background = false
	collision_layer = Layer.WORLD
	collision_mask = Layer.WORLD | Layer.PLAYER | Layer.BOT
	z_index = 0
	modulate = Color.WHITE
