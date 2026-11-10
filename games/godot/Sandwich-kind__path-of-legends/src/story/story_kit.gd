class_name StoryKit
extends HeroKit
# ---------- Набор героя Истории ----------
# Ближний бой — тем, что в руке (или кулаками), дальний — тем, что за спиной,
# снаряды берутся из рюкзака. Способности из свитков тратят ману, ульта
# копится в бою. Каждый удар даёт опыт навыку того оружия, которым нанесён.

var mode                      # StoryMode (без типа, чтобы не было циклической ссылки)
var data: Dictionary
var stats := {}
var mana := 0.0
var max_mana := 40.0
var src := ""                 # каким навыком нанесён текущий удар
var rage_t := 0.0
var _crit_now := false
var _combo := 0
var _combo_t := 0.0
var _ranged_cd := 0.0
var _draw_t := -1.0
var _draw_len := 0.2
var _alt_t := 0.0
var _last_hp := -1
var _regen := 0.0

const FIST := {"name": "Кулаки", "sub": "fist", "dmg": 6, "cd": 0.34, "reach": 70.0}
const ACTS := {"fist": ["punch", "punch"], "sword": ["cut1", "cut2", "cut3"], "dagger": ["cut4", "punch"],
		"blunt": ["hammer1", "hammer2"], "greatsword": ["big_cut"], "scythe": ["cut1", "cut2"]}
const DELAY := {"fist": 0.07, "sword": 0.12, "dagger": 0.06, "blunt": 0.17, "greatsword": 0.24, "scythe": 0.15}
const ULT_NEED := 220.0

func _ready() -> void:
	hero = "story"

# Пересчитать всё после смены вещей, уровня или навыков
func refresh() -> void:
	stats = StoryStats.derive(data)
	p.max_hp = int(stats["hp"])
	p.hp = mini(p.hp, p.max_hp)
	max_mana = float(stats["mana"])
	mana = minf(mana, max_mana)
	p.armor_mult = StoryStats.reduce(float(stats["armor"])) * (0.7 if rage_t > 0.0 else 1.0)
	p.abilities = (data["slots"] as Array).duplicate()
	for i in 3:
		p.ability_cds[i] = float(StoryAbilities.get_def(String(p.abilities[i])).get("cd", 1.0))
	p.ult = String(data.get("ult", ""))
	p.ult_need = ULT_NEED
	if p._hp_fill:
		p.heal(0)

func melee_def() -> Dictionary:
	var id: String = data["equipped"].get("melee", "")
	return Items.get_def(id) if id != "" else FIST

func ranged_def() -> Dictionary:
	var id: String = data["equipped"].get("ranged", "")
	return Items.get_def(id) if id != "" else {}

func ranged_skill() -> String:
	var r := ranged_def()
	return String(r["sub"]) if not r.is_empty() else "magic"

func _rage() -> float:
	return 1.6 if rage_t > 0.0 else 1.0

# ---------- Ближний бой ----------
func weapon(delta: float, shoot: bool) -> void:
	p.ammo = p.clip_size
	p._reloading = 0.0
	_combo_t -= delta
	if _combo_t <= 0.0:
		_combo = 0
	if not shoot or p._cooldown_left > 0.0 or _draw_t >= 0.0:
		return
	var w := melee_def()
	var sub: String = w["sub"]
	var acts: Array = ACTS.get(sub, ["punch"])
	var a: String = acts[_combo % acts.size()]
	_combo += 1
	_combo_t = 0.9
	p._anim(a)
	_after(float(DELAY.get(sub, 0.1)), _melee_hit.bind(w, a))
	p._cooldown_left = float(w["cd"]) * (0.8 if rage_t > 0.0 else 1.0)

func _melee_hit(w: Dictionary, act: String) -> void:
	if not p.is_alive():
		return
	var sub: String = w["sub"]
	var reach: float = float(w.get("reach", 90.0))
	var half_h := 55.0
	var dmg := float(w["dmg"]) * StoryStats.dmg_mult(data, sub, "melee") * _rage()
	var world := p.get_parent()
	var any := false
	for e in _enemies():
		var to: Vector2 = e.global_position - p.global_position
		if (signf(to.x) == p.facing or absf(to.x) < 20.0) and absf(to.x) < reach + e.body_size.x / 2 \
				and absf(to.y) < half_h + e.body_size.y / 2:
			_crit_now = randf() < float(stats.get("crit", 0.0))
			src = sub
			e.take_damage(int(round(dmg * (1.75 if _crit_now else 1.0))), p)
			src = ""
			_crit_now = false
			if e.speed > 0.0:
				e.velocity = Vector2(p.facing * (320.0 if sub in ["blunt", "greatsword"] else 160.0), -120.0)
			any = true
	for n in world.get_children():
		if n is Destructible and not n.background and n.global_position.distance_to(p.global_position) < 500.0:
			n.hit(p.global_position + Vector2(p.facing * reach * 0.7, -6), Vector2(p.facing, 0), int(dmg * 1.2), 4.0, p.team,
					{"strict": true, "attacker": p, "power": 0.4})
	# след удара
	var c := p.global_position + Vector2(p.facing * 26.0, -8.0)
	if sub == "fist":
		Util.flash(world, p.global_position + Vector2(p.facing * (reach * 0.8), -8), 16.0 if any else 10.0, Color(1, 1, 0.9, 0.6))
	else:
		var a0 := -1.4 if act != "cut2" else 1.0
		var a1 := 0.9 if act != "cut2" else -1.2
		if p.facing < 0:
			a0 = PI - a0
			a1 = PI - a1
		var col := Color(1.0, 0.55, 0.3, 0.75) if rage_t > 0.0 else Color(1.0, 1.0, 0.95, 0.6)
		Fx.arc(world, c, reach * 0.75, a0, a1, col, 0.18, 16.0 if sub != "greatsword" else 26.0)

# ---------- Дальний бой ----------
func _start_ranged() -> void:
	var w := ranged_def()
	if w.is_empty():
		mode.toast("Нет оружия дальнего боя")
		_ranged_cd = 0.6
		return
	var ammo_id: String = w.get("ammo", "")
	if ammo_id != "" and mode.count(ammo_id) <= 0:
		mode.toast("Закончились: " + Items.item_name(ammo_id))
		_ranged_cd = 0.6
		return
	if p.rig:
		p.rig.alt = "ranged"
	_alt_t = 0.55
	if w["sub"] == "bow":
		if p.rig:
			p.rig.hold = "draw"
		_draw_len = 0.22
	else:
		p._anim("throw")
		_draw_len = 0.12
	_draw_t = 0.0
	_ranged_cd = float(w["cd"]) * (0.8 if rage_t > 0.0 else 1.0)

func _fire_ranged() -> void:
	if p.rig:
		p.rig.hold = ""
	var w := ranged_def()
	if w.is_empty() or not p.is_alive():
		return
	var ammo_id: String = w.get("ammo", "")
	if ammo_id != "":
		mode.remove_item(ammo_id, 1)
	var sub: String = w["sub"]
	var crit := randf() < float(stats.get("crit", 0.0))
	var dmg := int(round(float(w["dmg"]) * StoryStats.dmg_mult(data, sub, "ranged") * _rage() * (1.75 if crit else 1.0)))
	var from: Vector2 = p.rig.muzzle() if p.rig else p.global_position
	var spd: float = float(w.get("speed", 1000.0))
	if sub == "bow":
		var a := Arrow.new()
		a.shooter = p
		a.team = p.team
		a.damage = dmg
		a.velocity = Vector2(p.facing * spd, -70.0)
		a.position = from
		p.get_parent().add_child(a)
	else:
		var b := StoryBolt.new()
		b.kit = self
		b.kind = "stone"
		b.damage = dmg
		b.velocity = Vector2(p.facing * spd, -180.0)
		b.position = from
		p.get_parent().add_child(b)

# ---------- Способности ----------
func handle_ability(i: int, ab: String, action: String, delta: float) -> void:
	p._cd[i] = maxf(0.0, p._cd[i] - delta)
	if not Input.is_action_just_pressed(action) or p._cd[i] > 0.0:
		return
	var d := StoryAbilities.get_def(ab)
	if d.is_empty():
		return
	var cost := float(d.get("mana", 0))
	if mana < cost:
		mode.toast("Не хватает маны")
		return
	mana -= cost
	use(ab)
	p._cd[i] = float(d["cd"])
	mode.skill_xp("magic", 4)

func use(ab: String) -> void:
	var world := p.get_parent()
	var d := StoryAbilities.get_def(ab)
	var magic := StoryStats.dmg_mult(data, "magic", "int")
	match ab:
		"fireball":
			p._anim("cast")
			var b := StoryBolt.new()
			b.kit = self
			b.kind = "fireball"
			b.damage = int(round(float(d["dmg"]) * magic * _rage()))
			b.velocity = Vector2(p.facing * 820.0, 0.0)
			b.position = (p.rig.muzzle() if p.rig else p.global_position) + Vector2(p.facing * 10.0, 0)
			world.add_child(b)
		"dash":
			p._anim("roll_f")
			p._forced_time = 0.22
			p._forced_vx = p.facing * 1350.0
			p._forced_no_gravity = true
			p._invuln = 0.32
			Fx.sparks(world, p.global_position, Color(0.6, 0.85, 1.0), 10, 200.0, 3.0)
		"heal":
			p._anim("cast")
			var amount := int(round(float(d["heal"]) * (1.0 + float(stats.get("int", 0.0)) * 0.04)))
			p.heal(amount)
			mode.float_text(p.global_position + Vector2(0, -60), "+%d" % amount, Color(0.5, 1.0, 0.55))
			Fx.ring(world, p.global_position, 70.0, Color(0.5, 1.0, 0.6, 0.9), 0.5, 6.0)
			Fx.sparks(world, p.global_position, Color(0.6, 1.0, 0.65), 12, 150.0, 3.0)

func ult() -> void:
	if p.ult != "rage":
		return
	p._anim("roar")
	rage_t = float(StoryAbilities.get_def("rage")["dur"])
	p.move_mult = 1.25
	p.set_tint(Color(1.35, 0.85, 0.75))
	refresh()
	var world := p.get_parent()
	Fx.ring(world, p.global_position, 120.0, Color(1.0, 0.3, 0.2, 0.9), 0.5, 8.0)
	Fx.sparks(world, p.global_position, Color(1.0, 0.45, 0.2), 20, 300.0, 4.0, true)
	mode.toast("Ярость предков!")

func _end_rage() -> void:
	rage_t = 0.0
	p.move_mult = 1.0
	p.set_tint(Color.WHITE)
	refresh()

# Урон нанесён (вызывает Player.take_damage у жертвы)
func on_dealt(amount: int, victim: Node) -> void:
	var skill := src if src != "" else ranged_skill()
	mode.on_dealt(victim, amount, skill, _crit_now)

func on_mega() -> void:
	pass

func on_death() -> void:
	if rage_t > 0.0:
		_end_rage()
	_draw_t = -1.0
	if p.rig:
		p.rig.hold = ""
		p.rig.alt = ""
	mode.on_hero_died()

func _physics_process(delta: float) -> void:
	if not p.is_alive():
		_last_hp = -1
		return
	# мана и немного здоровья восстанавливаются сами
	mana = minf(max_mana, mana + delta * (1.2 + float(stats.get("int", 0.0)) * 0.08))
	_regen += delta * 0.6
	if _regen >= 1.0 and p.hp < p.max_hp:
		_regen = 0.0
		p.heal(1)
	if rage_t > 0.0:
		rage_t -= delta
		if rage_t <= 0.0:
			_end_rage()
	# по герою попали — растёт стойкость
	if _last_hp >= 0 and p.hp < _last_hp:
		mode.skill_xp("toughness", maxi(1, (_last_hp - p.hp) / 3))
	_last_hp = p.hp
	# дальний бой
	_ranged_cd -= delta
	if _draw_t >= 0.0:
		_draw_t += delta
		if _draw_t >= _draw_len:
			_draw_t = -1.0
			_fire_ranged()
	if _alt_t > 0.0:
		_alt_t -= delta
		if _alt_t <= 0.0 and p.rig:
			p.rig.alt = ""
	if not p.frozen and Input.is_action_pressed("p1_ranged") and _ranged_cd <= 0.0 and _draw_t < 0.0 \
			and p._cooldown_left <= 0.0:
		_start_ranged()
