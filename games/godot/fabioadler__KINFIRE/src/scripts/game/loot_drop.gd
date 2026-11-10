class_name LootDrop
extends Node2D
## Item, ouro, globo de vida ou essência no chão.

enum Kind { ITEM, GOLD, GLOBE, ESSENCE }

var kind: Kind = Kind.ITEM
var item: Item
var gold := 0
var essence := 0
var world: World
var _t := 0.0
var _label: Label
var _icon: Sprite2D
var _beam: PointLight2D
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _landed := false


static func drop_item(w: World, pos: Vector2, it: Item) -> LootDrop:
	var l := LootDrop.new()
	l.kind = Kind.ITEM
	l.item = it
	return _spawn(w, l, pos)


static func drop_gold(w: World, pos: Vector2, amount: int) -> LootDrop:
	var l := LootDrop.new()
	l.kind = Kind.GOLD
	l.gold = amount
	return _spawn(w, l, pos)


static func drop_globe(w: World, pos: Vector2) -> LootDrop:
	var l := LootDrop.new()
	l.kind = Kind.GLOBE
	return _spawn(w, l, pos)


## Essência: moeda rara de Campeão/Lendário/Chefe (REGRAS #9)
static func drop_essence(w: World, pos: Vector2, amount: int) -> LootDrop:
	var l := LootDrop.new()
	l.kind = Kind.ESSENCE
	l.essence = amount
	return _spawn(w, l, pos)


static func _spawn(w: World, l: LootDrop, pos: Vector2) -> LootDrop:
	l.world = w
	l._from = pos
	var target := pos + Vector2.from_angle(randf() * TAU) * randf_range(6, 20)
	l._to = w.last_free_point(pos, target)
	l.position = pos
	w.entities.add_child(l)
	return l


func _ready() -> void:
	if kind == Kind.ITEM:
		add_to_group("interactables")
		_icon = Sprite2D.new()
		_icon.texture = DB.icon(item.icon)
		_icon.position = Vector2(0, -6)
		_icon.scale = Vector2.ONE * (13.0 / maxf(_icon.texture.get_width(), 1.0))
		_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(_icon)
		_label = Label.new()
		_label.text = item.name
		_label.add_theme_font_override("font", UIKit.FONT_BODY)
		_label.add_theme_font_size_override("font_size", 24)
		_label.add_theme_color_override("font_color", item.rarity_color())
		var sb := UIKit.box(Color(0, 0, 0, 0.75), Color(item.rarity_color(), 0.6), 1, 2)
		sb.content_margin_top = 1
		sb.content_margin_bottom = 1
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		_label.add_theme_stylebox_override("normal", sb)
		_label.scale = Vector2.ONE / 3.0
		_label.z_index = 20
		add_child(_label)
		_label.reset_size()
		_label.position = Vector2(-_label.size.x / 6.0, -24)
		if item.rarity >= Item.Rarity.RARE:
			# 7.3: energia >1 para florescer no glow (HDR 2D, #14.3)
			_beam = Fx.make_light(item.rarity_color(), 0.5, 1.35)
			_beam.position = Vector2(0, -6)
			add_child(_beam)
		Sfx.play(&"drop", -6.0)
		if item.rarity == Item.Rarity.LEGENDARY:
			Sfx.play(&"levelup", -6.0)
	elif kind == Kind.GOLD:
		Sfx.play(&"coins", -10.0)
	elif kind == Kind.ESSENCE:
		# Beam roxo - visível de longe (drop raro)
		_beam = Fx.make_light(Color(0.75, 0.5, 1.0), 0.7, 0.9)
		_beam.position = Vector2(0, -6)
		add_child(_beam)
		Sfx.play(&"magic", -10.0)


## Empilha rótulos de itens próximos para não ficarem sobrepostos
func _avoid_label_overlap() -> void:
	if _label == null:
		return
	var my: Rect2 = Rect2(global_position + _label.position, _label.size / 3.0)
	for i in 12:
		var moved := false
		for n in get_tree().get_nodes_in_group("interactables"):
			if n == self or not n is LootDrop or n._label == null:
				continue
			var other: Rect2 = Rect2(n.global_position + n._label.position, n._label.size / 3.0)
			if my.intersects(other):
				_label.position.y -= other.end.y - my.position.y + 0.5
				my = Rect2(global_position + _label.position, _label.size / 3.0)
				moved = true
		if not moved:
			break


func hover_check(mouse: Vector2) -> bool:
	if kind != Kind.ITEM or _label == null:
		return false
	var lr: Rect2 = Rect2(global_position + _label.position, _label.size / 3.0)
	return (_label.visible and lr.grow(1).has_point(mouse)) or (global_position + Vector2(0, -6)).distance_to(mouse) < 8.0


func interact(player: Player) -> void:
	if kind != Kind.ITEM:
		return
	if player.hero.inventory.add(item):
		Sfx.play(&"pickup", -4.0)
		queue_free()
	else:
		world.hud.show_message("Inventário cheio", Color(1, 0.5, 0.4))


func _process(delta: float) -> void:
	_t += delta
	# Animação de "pulo" ao cair
	if _t < 0.4:
		var k := _t / 0.4
		position = _from.lerp(_to, k) + Vector2(0, -sin(k * PI) * 14.0)
	elif not _landed:
		position = _to
		_landed = true
		_avoid_label_overlap()
	if _beam:
		_beam.energy = 0.8 + sin(_t * 4.0) * 0.3
	if _label:
		_label.visible = Game.settings.always_show_loot or Input.is_action_pressed("show_loot")
	queue_redraw()
	if _t < 0.4 or world.player == null or world.player.is_dead():
		return
	var d := global_position.distance_to(world.player.global_position)
	match kind:
		Kind.GOLD:
			if d < 30.0:
				global_position = global_position.move_toward(world.player.global_position, 160 * delta)
			if d < 6.0:
				world.player.hero.add_gold(gold)
				Sfx.play(&"coins", -4.0)
				DamageNumber.spawn(world.fx_layer, global_position, gold, false, Color(1, 0.85, 0.3))
				queue_free()
		Kind.GLOBE:
			if d < 12.0:
				world.player.heal(world.player.max_hp * 0.2)
				Sfx.play(&"potion", -6.0)
				Fx.burst(world.fx_layer, global_position, Color(1, 0.2, 0.2), 10, 40.0)
				queue_free()
		Kind.ESSENCE:
			if d < 30.0:
				global_position = global_position.move_toward(world.player.global_position, 160 * delta)
			if d < 6.0:
				world.player.hero.add_essence(essence)
				Sfx.play(&"magic", -4.0)
				DamageNumber.spawn_text(world.fx_layer, global_position, "+%d ◆" % essence, Color(0.75, 0.55, 1.0))
				queue_free()


func _draw() -> void:
	match kind:
		Kind.GOLD:
			var n := clampi(gold / 5 + 1, 1, 5)
			for i in n:
				var o: Vector2 = Vector2((i % 3) * 4.0 - 6.0, -float(i / 3) * 3.0 - 8.0)
				var tex := DB.dt2_texture("coin_anim_f%d" % ((int(_t * 8.0) + i) % 4))
				if tex:
					draw_texture(tex, o)
		Kind.GLOBE:
			var pulse := 1.0 + sin(_t * 6.0) * 0.12
			draw_circle(Vector2(0, -4), 5.0 * pulse, Color(1, 0.1, 0.1, 0.25))
			draw_circle(Vector2(0, -4), 3.2, Color(0.8, 0.05, 0.05))
			draw_circle(Vector2(-1, -5), 1.2, Color(1, 0.6, 0.6))
		Kind.ITEM:
			draw_set_transform(Vector2(0, -0.5), 0, Vector2(1, 0.4))
			draw_circle(Vector2.ZERO, 5.0, Color(0, 0, 0, 0.35))
			draw_set_transform(Vector2.ZERO)
		Kind.ESSENCE:
			# Losango roxo pulsante
			var pulse := 1.0 + sin(_t * 5.0) * 0.15
			var pts := PackedVector2Array()
			for k in 4:
				pts.append(Vector2(0, -6) + Vector2.from_angle(TAU * k / 4.0 + PI / 4.0) * 4.5 * pulse)
			draw_colored_polygon(pts, Color(0.62, 0.38, 0.95))
			draw_circle(Vector2(0, -6), 1.5, Color(0.95, 0.85, 1.0))
