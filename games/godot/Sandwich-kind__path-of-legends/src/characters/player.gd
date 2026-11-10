class_name Player
extends CharacterBody2D
# ---------- Герой (игрок или бот) ----------

signal died(index: int)

const SIZE := Vector2(40, 60)      # размер героя по умолчанию
const GRENADE_FULL := 1.0      # за сколько секунд набирается полный бросок
const GRENADE_CANCEL := 2.0    # после скольких секунд бросок отменяется
const MINIGUN_TIME := 6.0
const MINIGUN_GRENADE_EVERY := 1.5   # как часто миниган сам бросает гранату
const LEAP_FORCE := 1150.0           # сила прыжка способности 3 (обычный прыжок 750)
const PHASE_TIME := 2.0              # сколько секунд можно проходить сквозь блоки снизу вверх
const NORMAL_MASK := Layer.WORLD | Layer.PLAYER | Layer.FRAG
const HURT_MIN := 50.0              # ниже этого противник получает «мишень» повыше (см. _ready)
const PARA_OPEN_HEIGHT := 450.0      # на какой высоте над поверхностью раскрывается парашют
const PARA_FALL_SPEED := 170.0       # скорость спуска под куполом
const FREE_FALL_MAX := 1100.0        # предельная скорость свободного падения
const PHASE_MASK := Layer.FRAME | Layer.PLAYER | Layer.FRAG   # без разрушаемых блоков

var prefix := "p1"
var index := 0
var team := 0
var color := Color.WHITE
var outline := Color(0, 0, 0, 0)
var team_color := Color(0.2, 0.5, 1.0)   # цвет щита
var spawn := Vector2.ZERO
var spawn_points: Array = []
var facing := 1
var map_w := 1152.0
var body_size := SIZE          # у ботов бывает другой: шустрики меньше, танки и боссы больше
var decor := ""                # украшение внешности: helmet, armor, visor, band, cap, crown, horns
var eye_color := Color.BLACK

var speed := 400.0
var jump_force := 750.0
var gravity := 1800.0
var max_hp := 100
var hp := 100

# Оружие
var bullet_speed := 600.0
var bullet_damage := 10
var bullet_blast := 0.0
var fire_cooldown := 0.3
var bullet_size := 10.0
var clip_size := 20
var reload_time := 1.5
var ammo := 20

# Способности и ульта
var abilities: Array = ["", "", ""]
var ability_cds: Array = [8.0, 8.0, 8.0]
var ult := ""
var ult_need := 300.0          # сколько урона нужно нанести для ульты
var ult_charge := 0.0
var ui := {}                   # экранные кнопки этого игрока

# Возрождение и раунды
var spawn_picker: Callable     # если задано — выбирает место возрождения (режим на двоих)
var last_spawn := Vector2(INF, INF)
var last_spawn_kind := ""
var frozen := false            # между раундами и во время отсчёта управление отключено

# Бот
var is_bot := false
var target = null
var _think_timer := 0.0
var keep_min := 150.0          # бот держится на расстоянии от keep_min до keep_max
var keep_max := 350.0
var jumpiness := 0.2           # как часто прыгает просто так
var shoot_range := 800.0
var melee_dmg := 0             # урон вплотную (шустрики кусаются)
var bot_abilities := {}        # способность -> перезарядка в секундах
var mortar_count := 12         # сколько снарядов в залпе
var respawn := true            # false — после смерти исчезает (боты Арены)
var respawn_protect := 0.0     # неуязвимость после возрождения (мигает)
var _bot_cd := {}
var _melee_cd := 0.0
var _mortar_target_x := NAN
var _protect := 0.0
var _bar_w := 50.0

var _cd: Array = [0.0, 0.0, 0.0]
var _cooldown_left := 0.0
var _reloading := 0.0
var _hold := -1.0
var _forced_time := 0.0
var _forced_vx := 0.0
var _forced_no_gravity := false
var _invuln := 0.0
var _ult_left := 0.0
var _ult_grenade := 0.0
var _phase_left := 0.0
var _phasing := false
var _shurikens_ready := false     # бросить сюрикены в верхней точке прыжка
var _phase_query: PhysicsShapeQueryParameters2D
var _shield = null
var _alive := true
var _col: CollisionShape2D
var _eye: ColorRect
var _gun: ColorRect
var _hp_fill: ColorRect
var _ammo_fill: ColorRect
var _charge_fill: ColorRect
var _charge_bg: ColorRect
var _body: ColorRect
var _aim: Node2D               # стрелка и траектория броска гранаты
var _aim_line: Line2D
var _aim_head: Polygon2D
var _aim_dots: Array = []
var _para := 0                 # парашют: 0 — нет, 1 — свободное падение, 2 — под куполом
var _canopy: Node2D

# ----- Баффы (Арена) -----
var mega_cd := 2.0             # (старое: откат при МЕГА-«Откате»; сейчас откат задают Buffs.CD_SPEED*)
var buffs := {}                # бафф -> {"t": сколько осталось, "mega": МЕГА или нет}
var _jump_boost_t := 0.0       # МЕГА-рывок: прыжок выше
var _wallwalk_t := 0.0         # МЕГА-рывок: вбок сквозь стены и колонны
var _hover_t := 0.0            # МЕГА-прыжок: парение
var _hover_pending := false
var _hover_throw := 0.0
var _air_jumps := 0            # МЕГА-«Ветер»: прыжок в воздухе
var _aura_t := 0.0
var _armor_bubble: Polygon2D
var _ww_floor := false

# ----- Особые свойства боссов и гоблинов Арены -----
var gun_kind := ""             # "" — пули, "spear" — бросок дугой (копьё, бомба, дым, семя)
var payload := ""              # что бросает при gun_kind = "spear"
var front_armor := 0.0         # какая доля урона спереди поглощается бронёй (Колосс)
var turn_time := 0.0           # сколько секунд нужно, чтобы развернуться (Колосс)
var invulnerable := false      # неуязвим (Энт, пока целы тотемы)
var stun_mult := 2.0           # во сколько раз больше урона, пока оглушён
var on_lethal: Callable        # если задан и вернул true — смертельный удар не убивает (вторая фаза босса)
var stay_dead := false         # после смерти не возрождается и ждёт (Арена вдвоём)
var summon: Callable           # призвать помощников: summon.call(kind, count, pos)
var allies: Callable           # список своих (для лечения шаманом)
var _stun_t := 0.0
var _stun_fx: Node2D
var _turn_acc := 0.0
var _charging := 0.0
var _immune_fx := 0.0
var flying := false            # летает (летучая мышь): без гравитации, кружит над целью
var swing_dmg := 20            # урон удара оружием вблизи (меч, трезубец, посох)
var cutscene_walk := 0.0       # кат-сцена: босс идёт сам (направление)
var cutscene_shield := false   # босс в кат-сцене появления: его нельзя ранить и выбрать целью
# навигация ботов: спрыгивание с платформ, выход из тупиков
var ground_only := false       # огромные боссы ходят только по земле (сквозь сквозные платформы)
var _nav_drop_cd := 0.0
var _nav_sample_t := 0.6
var _nav_last := Vector2.ZERO
var _nav_stuck := 0
var _detour_t := 0.0
var _detour_dir := 0.0
var _smash_cd := 0.0
var _slow_t := 0.0             # герой опутан сетью или паутиной — медленнее
var slip_t := 0.0              # стоит на наледи: скользит по инерции (Ледяная тропа)
var _slide_vx := 0.0
var _ext_vx := 0.0             # порыв ветра толкает (Храм шторма)
var _ext_t := 0.0
var _freeze_t := 0.0           # вмёрз в лёд: стоит как оглушённый, но урон не удваивается
var _ice_block: Node2D
var _frost_fx: Node2D
var _slow_mult := 1.0
var _slow_fx: Node2D
var _mud_fx: Node2D
var _dive_t := 0.0
var _dive_v := Vector2.ZERO
var _pounce_t := 0.0
# ----- Новые легенды (Чемпион, Терновник, Мортис) и общие состояния -----
var _shadow: Polygon2D
var _shadow_t := 0.0
var mega_mode := false        # куплено и включено «МЕГА» — способности всегда МЕГА
var kit: Node                  # набор способностей легенды (HeroKit)
var rig_kind := ""             # модель из частей для героя
var rig_spec := {}
var back_mult := 1.0           # урон в спину сильнее (котёл Барона Грызя)
var crust := 0.0               # самоцветная / кристальная корка: принимает урон на себя
var crust_burst := false       # корка взрывается осколками, когда ломается (МЕГА-«Преломление» Призмы)
var _crust_t := 0.0
var _crust_fx: Polygon2D
var on_hurt: Callable          # получил урон: on_hurt.call(amount, attacker) (мозги особых противников)
var stagger_max := 0.0         # >0 — босс Арены: копит «пошатывание» от урона и потом оглушается
var stagger := 0.0
var _stagger_cd := 0.0
var aware := true              # бот заметил цель (false — стоит и не нападает)
var aggro_radius := 0.0        # >0 — замечает цель только ближе этого расстояния
var alert_cb: Callable         # заметил — позвать своих (История: шайка разбойников)
var _lose_t := 0.0             # своё описание модели (герой Истории)
var _rig_root: Node2D          # держатель модели: через него герой растёт/уменьшается
var move_mult := 1.0           # множитель скорости (форма Энта)
var armor_mult := 1.0          # множитель получаемого урона (форма Энта, мраморный Чемпион)
var bonus_mult := 1.0          # усиление урона (Рёв толпы, высокий тотем)
var _bonus_t := 0.0
var fly_free := false          # Призрачный шаг: летает в любую сторону
var anchored := false          # часть огромного босса (голова и руки Воплощения Тьмы): двигает её «мозг», не физика
var map_top := -400.0          # выше этого не улететь
var _root_t := 0.0             # опутан корнями — не может ходить и прыгать
var _no_jump_t := 0.0          # сеть — не может прыгать
var _poison_t := 0.0
var _burn_t := 0.0             # поджог (раскалённый молот Кузнеца)
var _burn_dps := 0.0
var _burn_tick := 0.0
var _burn_by = null
var _poison_dps := 0.0
var _poison_tick := 0.0
var bone_shields := 0          # кости-обереги Мортиса: каждая блокирует один удар
var _bones: Node2D
var is_minion := false         # призванный союзник (скелеты Мортиса, деревца Терновника)
var minion_owner: Node
var calm_jumps := false         # Арена: бот реже скачет без дела (в него проще попасть)
var bullet_style := ""          # вид пуль бота: kunai, shuriken, arrow (пусто — обычные)
var lifetime := 0.0            # через сколько секунд призванный исчезнет (0 — никогда)
var _retarget_t := 0.0
var _drop_t := 0.0             # спрыгивает с платформы вниз
var _drop_body: Node
var _marker: Polygon2D
var allow_mega := true         # дуэль: можно ли получить МЕГА-бафф повторным подбором
var bar_lift := 0.0            # насколько поднять полоски над головой (рога, гребень, крона)
var rig: Node2D               # модель бота из частей (голова, туловище, руки, ноги)

func _ready() -> void:
	position = spawn
	hp = max_hp
	ammo = clip_size
	if is_bot:
		collision_layer = Layer.BOT          # боты проходят сквозь героя и друг сквозь друга
		collision_mask = Layer.WORLD | Layer.FRAG
	else:
		collision_layer = Layer.PLAYER
		collision_mask = NORMAL_MASK
	var bs := body_size
	_col = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = bs
	_col.shape = rs
	if is_bot and bs.y < HURT_MIN:
		# низкий противник: «мишень» выше него самого, чтобы в него попадали пули,
		# летящие на уровне груди героя (ноги остаются на месте, у летунов — по центру)
		rs.size = Vector2(maxf(bs.x, 30.0), HURT_MIN)
		_col.position.y = 0.0 if flying else -(HURT_MIN - bs.y) / 2.0
	add_child(_col)

	if outline.a > 0.0:
		var o := ColorRect.new()
		o.size = bs + Vector2(8, 8)
		o.position = -bs / 2 - Vector2(4, 4)
		o.color = outline
		add_child(o)
	_body = ColorRect.new()
	_body.size = bs
	_body.position = -bs / 2
	_body.color = color
	add_child(_body)
	if (is_bot and has_meta("kind")) or rig_kind != "":
		# у ботов и новых легенд вместо прямоугольника — модель из частей с анимациями
		_body.visible = false
		var k: String = rig_kind if rig_kind != "" else String(get_meta("kind"))
		if k in CreatureRig.KINDS:
			var cr := CreatureRig.new()
			cr.bot = self
			cr.kind = k
			rig = cr
		elif k in DeepRig.KINDS:
			var dr := DeepRig.new()
			dr.bot = self
			dr.kind = k
			rig = dr
		elif k in WildRig.KINDS:
			var wr := WildRig.new()
			wr.bot = self
			wr.kind = k
			rig = wr
		else:
			var br := BotRig.new()
			br.bot = self
			br.kind = k
			br.custom_spec = rig_spec
			rig = br
		_rig_root = Node2D.new()
		_rig_root.position = Vector2(0, bs.y / 2)     # растёт от ступней
		add_child(_rig_root)
		rig.position = Vector2(0, -bs.y / 2)
		_rig_root.add_child(rig)
	else:
		_add_decor()
	if rig_kind != "":
		for c in get_children():
			if c is ColorRect and c.color == outline and c != _body:
				c.visible = false             # прямоугольная обводка не нужна
	if rig_kind != "" and outline.a > 0.0:
		# у легенд с моделью цвет игрока — треугольник над головой
		_marker = Polygon2D.new()
		_marker.polygon = PackedVector2Array([Vector2(-9, 0), Vector2(9, 0), Vector2(0, 11)])
		_marker.color = outline
		_marker.position = Vector2(0, -bs.y / 2 - 48)
		add_child(_marker)
	if kit:
		add_child(kit)
	if rig and not flying:
		# мягкая тень под ногами (у легенд и противников с моделью)
		_shadow = Polygon2D.new()
		var sp := Util.circle(1.0, 18)
		for i in sp.size():
			sp[i] = sp[i] * Vector2(bs.x * 0.55, 6.0)
		_shadow.polygon = sp
		_shadow.color = Color(0, 0, 0, 0.28)
		_shadow.z_index = -1
		_shadow.position = Vector2(0, bs.y / 2)
		add_child(_shadow)
		move_child(_shadow, 0)

	_eye = ColorRect.new()
	var es := clampf(bs.x * 0.2, 6.0, 18.0)
	_eye.size = Vector2(es, es)
	_eye.color = eye_color
	add_child(_eye)
	_eye.visible = rig == null
	_gun = ColorRect.new()           # миниган во время ульты
	_gun.size = Vector2(36, 12)
	_gun.color = Color(0.25, 0.25, 0.28)
	_gun.visible = false
	add_child(_gun)
	_update_eye()

	var top := -bs.y / 2 - bar_lift
	_bar_w = maxf(50.0, bs.x + 10.0)
	_hp_fill = _make_bar(top - 22.0, 6.0, Color(0.3, 1.0, 0.3))
	_ammo_fill = _make_bar(top - 14.0, 4.0, Color(1.0, 0.85, 0.2))
	_charge_fill = _make_bar(top - 32.0, 6.0, Color(1.0, 0.7, 0.2))
	_charge_bg = _charge_fill.get_meta("bg")
	_charge_fill.visible = false
	_charge_bg.visible = false
	if "grenade" in abilities or ult == "minigun":
		_make_aim()

	# чуть уменьшенная фигура героя — для проверки «застрял ли внутри блока»
	var small := RectangleShape2D.new()
	small.size = bs - Vector2(8, 8)
	_phase_query = PhysicsShapeQueryParameters2D.new()
	_phase_query.shape = small
	_phase_query.collision_mask = Layer.WORLD

func _make_aim() -> void:
	_aim = Node2D.new()
	_aim.visible = false
	add_child(_aim)
	for i in 14:
		var d := Polygon2D.new()
		d.polygon = Util.circle(3.0, 8)
		_aim.add_child(d)
		_aim_dots.append(d)
	_aim_line = Line2D.new()
	_aim_line.width = 5.0
	_aim.add_child(_aim_line)
	_aim_head = Polygon2D.new()
	_aim.add_child(_aim_head)

func _make_bar(y: float, h: float, c: Color) -> ColorRect:
	var bg := ColorRect.new()
	bg.size = Vector2(_bar_w, h)
	bg.position = Vector2(-_bar_w / 2, y)
	bg.color = Color(0, 0, 0, 0.6)
	add_child(bg)
	var fill := ColorRect.new()
	fill.size = Vector2(_bar_w, h)
	fill.position = Vector2(-_bar_w / 2, y)
	fill.color = c
	add_child(fill)
	fill.set_meta("bg", bg)
	return fill

func is_alive() -> bool:
	return _alive

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_invuln = maxf(0.0, _invuln - delta)
	if _crust_t > 0.0:
		_crust_t -= delta
		if _crust_t <= 0.0 and crust > 0.0:
			_break_crust()                  # время вышло — корка тоже раскалывается
	if stagger_max > 0.0:
		_stagger_cd = maxf(0.0, _stagger_cd - delta)
		stagger = maxf(0.0, stagger - stagger_max * 0.05 * delta)     # без давления понемногу спадает
	if _protect > 0.0:             # защита после возрождения — герой мигает
		_protect -= delta
		modulate.a = 1.0 if _protect <= 0.0 else 0.45 + 0.45 * absf(sin(_protect * 14.0))
	var dir := 0.0
	var jump := false
	var shoot := false
	if _stun_t > 0.0:
		_stun_t -= delta
		if _stun_fx:
			_stun_fx.rotation += delta * 5.0
			_stun_fx.visible = _stun_t > 0.0
	if anchored:
		velocity = Vector2.ZERO
		_tick_status(delta)
		_tick_buffs(delta)
		_update_bars()
		return
	if is_bot:
		var r := _bot_think(delta)
		dir = r[0]
		jump = r[1]
		shoot = r[2]
	else:
		dir = Input.get_axis(prefix + "_left", prefix + "_right")
		jump = Input.is_action_just_pressed(prefix + "_jump")
		shoot = Input.is_action_pressed(prefix + "_shoot")
	if frozen or _stun_t > 0.0:
		dir = 0.0
		jump = false
		shoot = false
	if cutscene_walk != 0.0:
		dir = cutscene_walk            # кат-сцена: босс выходит сам
	if _root_t > 0.0:
		_root_t -= delta
		dir = 0.0
		jump = false
	if _no_jump_t > 0.0:
		_no_jump_t -= delta
		jump = false
	_tick_status(delta)
	var down := false
	if not is_bot and not frozen:
		down = Input.is_action_pressed(prefix + "_down")
		if Input.is_action_just_pressed(prefix + "_down") and not fly_free:
			_try_drop()

	_tick_buffs(delta)
	var move_speed := speed * move_mult
	if _slow_t > 0.0:
		_slow_t -= delta
		move_speed *= _slow_mult
		if _slow_fx and _slow_t <= 0.0:
			_slow_fx.visible = false
		if _mud_fx and _slow_t <= 0.0:
			_mud_fx.visible = false
	if _ult_left > 0.0 and ult == "minigun":
		move_speed *= 0.6       # с миниганом герой медленнее
	if has_buff("speed"):
		move_speed *= 1.6 if is_mega("speed") else 1.35
	var jf := jump_force
	if has_buff("speed"):
		jf *= 1.3 if is_mega("speed") else 1.2
	if _jump_boost_t > 0.0:
		jf *= 1.45

	if flying and not frozen:
		_fly(delta)
	elif fly_free and _forced_time <= 0.0:
		# Призрачный шаг: невесомость, летит в любую сторону
		var up := 0.0
		if not frozen and _root_t <= 0.0:
			up = (1.0 if down else 0.0) - (1.0 if Input.is_action_pressed(prefix + "_jump") else 0.0)
		velocity = velocity.move_toward(Vector2(dir, up).normalized() * move_speed * 1.1, 3000.0 * delta)
		if dir != 0:
			facing = 1 if dir > 0 else -1
			_update_eye()
	elif _forced_time > 0.0:
		# рывок, прыжок способности или «укоренение» на месте
		_forced_time -= delta
		velocity.x = _forced_vx
		if _forced_no_gravity:
			velocity.y = 0.0
		elif _phasing or not is_on_floor():
			velocity.y += gravity * delta
	else:
		_forced_no_gravity = false
		# во время сквозного прыжка герой точно в воздухе
		var on_floor := (_ww_floor if _wallwalk_t > 0.0 else is_on_floor()) and not _phasing
		if not on_floor:
			velocity.y += gravity * delta
		else:
			_air_jumps = 1
		var base_vx := dir * move_speed
		if slip_t > 0.0:
			# на льду не остановиться и не развернуться сразу — катится
			slip_t -= delta
			_slide_vx = move_toward(_slide_vx, base_vx, 950.0 * delta)
			base_vx = _slide_vx
		else:
			_slide_vx = base_vx
		if _ext_t > 0.0:
			_ext_t -= delta
			base_vx += _ext_vx * (1.35 if not on_floor else 1.0)
		velocity.x = base_vx
		if jump and on_floor:
			velocity.y = -jf
		elif jump and is_mega("speed") and _air_jumps > 0:
			_air_jumps -= 1          # МЕГА-«Ветер»: прыжок прямо в воздухе
			velocity.y = -jf
		if is_bot and is_instance_valid(target) and _stun_t <= 0.0 and aware:
			var want := 1 if target.global_position.x > global_position.x else -1
			if absf(target.global_position.x - global_position.x) < body_size.x * 0.35:
				want = facing                 # цель почти над/под ним — не дёргается туда-сюда
			if want != facing and turn_time > 0.0:
				_turn_acc += delta         # тяжёлый босс разворачивается медленно
				if _turn_acc >= turn_time:
					_turn_acc = 0.0
					facing = want
			else:
				_turn_acc = 0.0
				facing = want
			_update_eye()
		elif dir != 0:
			facing = 1 if dir > 0 else -1
			_update_eye()
	if _shurikens_ready and velocity.y > -60.0:
		_shurikens_ready = false
		_throw_shurikens()            # в верхней точке прыжка
	_update_hover(delta)
	_update_parachute(delta)
	_update_phase(delta)
	if _wallwalk_t > 0.0 and not _phasing:
		_wall_move(delta)
	elif _phasing:
		_phase_move(delta)
	else:
		var want_vx := velocity.x
		var want_vy := velocity.y
		_clear_head()
		move_and_slide()
		_push_bodies(want_vx, want_vy)
	if _para != 0 and is_on_floor():
		_land()
	if _charging > 0.0:
		_update_charge(delta)
	if _pounce_t > 0.0:
		_update_pounce(delta)
	if fly_free:
		# за пределы карты улететь нельзя
		global_position.x = clampf(global_position.x, 30.0, map_w - 30.0)
		global_position.y = maxf(global_position.y, map_top)
	if _drop_t > 0.0:
		_drop_t -= delta
		if _drop_t <= 0.0 and _drop_body and is_instance_valid(_drop_body):
			remove_collision_exception_with(_drop_body)
			_drop_body = null

	_handle_weapon(delta, shoot)
	if not is_bot:
		if not frozen:
			_handle_abilities(delta)
		_update_buttons()
	_update_bars()
	_update_aura(delta)
	_update_shadow(delta)

# ----- Оружие -----
func _handle_weapon(delta: float, shoot: bool) -> void:
	_cooldown_left -= delta
	if kit:
		kit.weapon(delta, shoot)
		return
	if _ult_left > 0.0 and ult == "minigun":
		_ult_left -= delta
		_gun.visible = _ult_left > 0.0
		_ult_grenade -= delta
		if _ult_grenade <= 0.0 and _ult_left > 0.0:
			_ult_grenade = MINIGUN_GRENADE_EVERY
			# граната сама, без способности; при МЕГА-способностях раскалывается на 3
			_throw_grenade(randf_range(0.5, 0.9), 3 if _mega_ab() else 0)
		if shoot and _cooldown_left <= 0.0:
			if _mega_ab():           # МЕГА-миниган: ещё быстрее и веером
				_shoot_bullet(1500.0, 5, 0.0, 7.0, randf_range(-0.35, 0.35))
				_cooldown_left = 0.035
			else:
				_shoot_bullet(1000.0, 5, 0.0, 7.0, randf_range(-0.12, 0.12))
				_cooldown_left = 0.05
		return
	if has_buff("rapid"):
		# «Шквал»: без патронов и перезарядки, стрельба быстрее; МЕГА — пули пробивают врагов
		_reloading = 0.0
		ammo = clip_size
		if shoot and _cooldown_left <= 0.0:
			var mega := is_mega("rapid")
			var b := _shoot_bullet(bullet_speed * (1.3 if mega else 1.0), bullet_damage, bullet_blast,
					bullet_size * (1.4 if mega else 1.0), 0.0)
			if mega:
				b.pierce = 3
			_cooldown_left = fire_cooldown * (0.33 if mega else 0.5)
		return
	if _reloading > 0.0:
		_reloading -= delta
		if _reloading <= 0.0:
			_reloading = 0.0
			ammo = clip_size
	elif not is_bot and Input.is_action_just_pressed(prefix + "_reload") and ammo < clip_size:
		_reloading = reload_time
	if shoot and _cooldown_left <= 0.0 and _reloading <= 0.0:
		if ammo > 0:
			if gun_kind == "spear":
				_throw_spear(payload)
			else:
				_shoot_bullet(bullet_speed, bullet_damage, bullet_blast, bullet_size, 0.0)
			ammo -= 1
			_cooldown_left = fire_cooldown
		if ammo <= 0:
			_reloading = reload_time

func _shoot_bullet(spd: float, dmg: int, blast: float, size: float, spread: float) -> Bullet:
	var b := Bullet.new()
	b.shooter = self
	b.team = team
	b.direction = Vector2(facing, 0).rotated(spread)
	b.speed = spd
	b.damage = dmg
	b.blast = blast
	b.size = size
	b.color = color.lightened(0.4)
	b.position = position + Vector2(facing * 30, -5)
	if rig:
		b.position = rig.muzzle()
		_anim("shoot" if bullet_style == "" else "throw")
	if bullet_style != "":
		b.style = bullet_style
	if has_meta("chill_shots"):
		b.chill = float(get_meta("chill_shots"))       # ледяные стрелы Морозного лучника
	if has_meta("burn_shots"):
		b.burn_t = float(get_meta("burn_shots"))
	if not is_bot and kit != null and Balance.arena(self):   # только на Арене; TESTIK-и (без набора) не трогаем
		b.direction = assist_dir(b.position, b.direction)
	get_parent().add_child(b)
	return b

# ----- Помощь в прицеливании (только на Арене, по противникам-ботам) -----
# Герой стреляет «прямо», но если впереди, в узком конусе, есть враг — снаряд
# немного доворачивается на него: попадёшь и в низкого паучка, и в прыгуна,
# и в мышь под потолком. В Дуэли по живому сопернику доводки нет — там решает умение.
# speed и grav — для стрел по дуге: целимся чуть выше, чтобы стрела не упала раньше.
const ASSIST_ANGLE := 0.45           # до ~26° вверх или вниз
const ASSIST_RANGE := 1100.0

func assist_dir(from: Vector2, dir: Vector2, speed := 0.0, grav := 0.0) -> Vector2:
	var best := dir
	var best_score := INF
	for n in get_parent().get_children():
		if not (n is Player) or not n.is_bot or n.team == team or not n.is_alive() or n.cutscene_shield:
			continue
		var c: Vector2 = n.hurt_center()
		var to: Vector2 = c - from
		var dist := to.length()
		if dist > ASSIST_RANGE or dist < 8.0 or to.x * dir.x <= 0.0:
			continue
		if speed > 0.0 and grav > 0.0:
			var t := dist / speed
			to.y -= 0.5 * grav * t * t          # стрела падает — целимся чуть выше
		var a := absf(dir.angle_to(to))
		if a > ASSIST_ANGLE:
			continue
		var score := a + dist / ASSIST_RANGE * 0.12   # ближние важнее
		if score < best_score:
			best_score = score
			best = to.normalized()
	return best

# Середина «мишени»: у низких врагов мишень выше их самих (см. HURT_MIN)
func hurt_center() -> Vector2:
	if _col:
		return global_position + _col.position
	return global_position

func _anim(n: String) -> void:
	if rig:
		rig.play(n)

# ----- Способности -----
func _handle_abilities(delta: float) -> void:
	for i in 3:
		_cd[i] = maxf(0.0, _cd[i] - delta * _cd_speed())
	for i in 3:
		var ab: String = abilities[i]
		if ab == "":
			continue
		var action := prefix + "_a" + str(i + 1)
		if kit:
			kit.handle_ability(i, ab, action, delta)
			continue
		if ab == "grenade":
			_handle_grenade(i, action, delta)
		elif Input.is_action_just_pressed(action) and _cd[i] <= 0.0:
			_use_ability(ab)
			_cd[i] = ability_cds[i]
			if ab == "dash":
				# рывок сбрасывает перезарядку остальных способностей и заряжает оружие
				for j in 3:
					if j != i:
						_cd[j] = 0.0
				ammo = clip_size
				_reloading = 0.0
	# ульта копится от урона и понемногу сама
	if not (kit and kit.has_method("ulting") and kit.ulting()):
		ult_charge = minf(ult_need, ult_charge + delta * 3.0)
	if kit and kit.has_method("ult_recast") and Input.is_action_just_pressed(prefix + "_ult") and kit.ult_recast():
		return                     # повторное нажатие ульты (Ассасин: рывок к отмеченной цели)
	if ult != "" and Input.is_action_just_pressed(prefix + "_ult") \
			and ult_charge >= ult_need and _ult_left <= 0.0:
		ult_charge = 0.0
		_start_ult()

func _handle_grenade(i: int, action: String, delta: float) -> void:
	var pressed := Input.is_action_just_pressed(action)
	var held := Input.is_action_pressed(action)
	if pressed and _cd[i] <= 0.0:
		_hold = 0.0
	if _hold >= 0.0:
		if held:
			_hold += delta
			if _hold > GRENADE_CANCEL:
				_hold = -1.0           # держал слишком долго — отмена
		else:
			var charge := minf(_hold / GRENADE_FULL, 1.0)
			if _mega_ab():
				# МЕГА: три гранаты веером, каждая раскалывается на 5 мини-гранат
				for k in [-0.15, 0.0, 0.15]:
					_throw_grenade(clampf(charge + k, 0.0, 1.0), 5)
			else:
				_throw_grenade(charge)
			_cd[i] = ability_cds[i]
			_hold = -1.0
	var show := _hold >= 0.0
	_charge_fill.visible = show
	_charge_bg.visible = show
	_aim.visible = show
	if show:
		var charge := minf(_hold / GRENADE_FULL, 1.0)
		var c := Color(1.0, 0.25, 0.2) if _hold > GRENADE_FULL else Color(1.0, 0.8, 0.2)
		_charge_fill.size.x = _bar_w * charge
		_charge_fill.color = c
		_update_aim(charge, c)

# Стрелка направления и пунктир траектории будущей гранаты
func _update_aim(charge: float, c: Color) -> void:
	var start := _grenade_start()
	var v := _grenade_velocity(charge)
	var g := 980.0                      # гравитация физических тел
	for i in _aim_dots.size():
		var t := 0.1 * (i + 1)
		var p := start + v * t + Vector2(0, 0.5 * g * t * t)
		_aim_dots[i].position = p
		_aim_dots[i].color = Color(c.r, c.g, c.b, 0.8 - i * 0.05)
	var d := v.normalized()
	var tip := start + d * (35.0 + 55.0 * charge)
	_aim_line.points = PackedVector2Array([start, tip])
	_aim_line.default_color = c
	var side := Vector2(-d.y, d.x) * 9.0
	_aim_head.polygon = PackedVector2Array([tip + d * 14.0, tip + side, tip - side])
	_aim_head.color = c

func _grenade_start() -> Vector2:
	return Vector2(facing * 25, -25)

func _grenade_velocity(charge: float) -> Vector2:
	return Vector2(facing, -0.9).normalized() * lerpf(250.0, 1000.0, charge)

func _use_ability(ab: String) -> void:
	match ab:
		"shell":
			_fire_shell()
		"dash":
			_dash()
		"leap":
			_leap()
		"shield":
			_place_shield()
		"barrage":
			_barrage()

func _throw_grenade(charge: float, split := 0) -> void:
	_anim("throw")
	var g := Grenade.new()
	g.team = team
	g.attacker = self
	g.split = split
	g.position = position + _grenade_start()
	g.linear_velocity = _grenade_velocity(charge)
	g.angular_velocity = facing * 8.0
	get_parent().add_child(g)
	g.add_collision_exception_with(self)

func _dash() -> void:
	_forced_time = 0.18
	_forced_vx = facing * 1300.0
	_forced_no_gravity = true
	_invuln = 0.25
	Util.flash(get_parent(), global_position, 30.0, color.lightened(0.5))
	if _mega_ab():
		# МЕГА-рывок: неуязвимость, прыжок выше и проход сквозь стены и колонны
		_protect = maxf(_protect, 2.0)
		_jump_boost_t = 4.0
		_wallwalk_t = 3.0
		Util.flash(get_parent(), global_position, 70.0, Color(1.0, 0.9, 0.4))

# Способность 3: мощный прыжок. Первые секунды можно пролетать
# сквозь разрушаемые блоки снизу вверх (вниз и вбок — нельзя).
func _leap() -> void:
	velocity.y = -LEAP_FORCE
	_phase_left = PHASE_TIME
	if _mega_ab():
		_hover_pending = true       # МЕГА: в верхней точке зависает и сыплет сюрикенами
	else:
		_shurikens_ready = true

func _update_phase(delta: float) -> void:
	_phase_left = maxf(0.0, _phase_left - delta)
	var want := false
	if _phasing or _phase_left > 0.0:
		var inside := _inside_block()
		if inside and _phasing:
			# уже внутри блока — выбирается только наверх
			want = true
			velocity.y = minf(velocity.y, -300.0)
			velocity.x = 0.0
		elif _phase_left > 0.0 and velocity.y < 0.0:
			want = true                 # летит вверх — блоки не мешают
	if want != _phasing:
		# маску меняем только при переключении: если выставлять её каждый кадр,
		# физика теряет контакты, и падающие блоки проходят сквозь героя
		collision_mask = PHASE_MASK if want else NORMAL_MASK
		_body.modulate.a = 0.55 if want else 1.0
	_phasing = want

# Движение во время сквозного прыжка: вбок блоки мешают как обычно,
# а вверх — только неразрушаемая рамка карты.
func _phase_move(delta: float) -> void:
	if velocity.x != 0.0:
		collision_mask = NORMAL_MASK
		if move_and_collide(Vector2(velocity.x * delta, 0)):
			velocity.x = 0.0
		collision_mask = PHASE_MASK
	if move_and_collide(Vector2(0, velocity.y * delta)) and velocity.y < 0.0:
		velocity.y = 0.0

func _inside_block() -> bool:
	_phase_query.transform = global_transform
	_phase_query.exclude = [get_rid()]
	return not get_world_2d().direct_space_state.intersect_shape(_phase_query, 1).is_empty()

func _throw_shurikens() -> void:
	if not _alive:
		return
	for a_deg in [20.0, 35.0, 50.0, 65.0, 80.0]:
		var a := deg_to_rad(a_deg)
		var s := Shuriken.new()
		s.shooter = self
		s.team = team
		s.direction = Vector2(facing * cos(a), sin(a))
		s.position = position + Vector2(facing * 20, 10)
		get_parent().add_child(s)

func _fire_shell() -> void:
	_anim("shoot_big")
	var s := Shell.new()
	s.shooter = self
	s.team = team
	s.mega = _mega_ab()
	s.direction = Vector2(facing, 0)
	s.position = position + Vector2(facing * 40, -5)
	get_parent().add_child(s)

func _place_shield() -> void:
	_anim("shield")
	if _shield != null and is_instance_valid(_shield):
		_shield.queue_free()
	var mega := _mega_ab()
	var d := Destructible.new()
	d.cell = 25.0
	d.cols = 3 if mega else 2      # толщина щита — 2 клетки (МЕГА — 3)
	d.rows = 6 if mega else 4      # высота — 4 клетки (МЕГА — 6)
	d.cell_hp = 70 if mega else 40
	d.density = 60.0 if mega else 40.0
	d.color = Color(team_color.r, team_color.g, team_color.b, 0.75)
	if mega:
		d.color = d.color.lightened(0.25)
	d.shield_team = team
	d.lifetime = 12.0 if mega else 8.0
	d.anchored = true
	for x in d.cols:
		for y in d.rows:
			d.anchors.append(Vector2i(x, y))
	var feet := position.y + body_size.y / 2
	d.position = Vector2(position.x + facing * (65.0 + (12.0 if mega else 0.0)), feet - d.rows * d.cell / 2)
	get_parent().add_child(d)
	add_collision_exception_with(d)     # хозяин проходит сквозь свой щит
	d.add_collision_exception_with(self)
	_shield = d

const BARRAGE_COUNT := 12

func _barrage() -> void:
	_anim("cast")
	var mega := _mega_ab()
	var n := mortar_count * (2 if mega else 1)   # МЕГА: вдвое больше и с самонаведением
	_forced_time = 0.75 + (0.6 if mega else 0.0)  # стоит на месте, пока стреляет
	_forced_vx = 0.0
	_forced_no_gravity = false
	for k in n:
		_after(0.05 + k * 0.05, _fire_mortar.bind(mega))

func _fire_mortar(homing := false) -> void:
	if not _alive:
		return
	var m := Mortar.new()
	m.shooter = self
	m.team = team
	m.homing = homing
	m.facing = facing
	m.ground_y = position.y + body_size.y / 2
	m.target_x = _mortar_target_x
	m.map_w = map_w
	m.position = position + Vector2(facing * 15, -40)
	get_parent().add_child(m)

func _start_ult() -> void:
	if kit:
		kit.ult()
		return
	match ult:
		"minigun":
			_ult_left = MINIGUN_TIME
			_ult_grenade = 0.5
			_cooldown_left = 0.0
			_gun.visible = true
		"quake":
			_anim("stomp")
			_forced_time = 0.8
			_forced_vx = 0.0
			_forced_no_gravity = false
			var mega := _mega_ab()
			# МЕГА: взрывы в обе стороны, крупнее и сильнее
			for d in ([facing, -facing] if mega else [facing]):
				var em := Eruptor.new()
				em.team = team
				em.attacker = self
				em.dir = d
				em.mega = mega
				em.feet = Vector2(position.x, position.y + body_size.y / 2)
				em.map_w = map_w
				get_parent().add_child(em)
			Util.flash(get_parent(), Vector2(position.x, position.y + body_size.y / 2),
					70.0 if mega else 40.0, Color(1.0, 0.5, 0.1))

func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)
	_hp_fill.size.x = _bar_w * maxi(hp, 0) / max_hp

func heal_full() -> void:
	hp = max_hp
	ammo = clip_size
	_reloading = 0.0
	_hp_fill.size.x = _bar_w

func add_ult(amount: float) -> void:
	if kit and kit.has_method("ulting") and kit.ulting():
		return                     # пока горит ульта Призмы, новая не копится
	ult_charge = minf(ult_need, ult_charge + amount)

func _after(time: float, fn: Callable) -> void:
	if time <= 0.0:
		fn.call()
		return
	var t := Timer.new()
	t.one_shot = true
	t.wait_time = time
	add_child(t)
	t.timeout.connect(fn)
	t.timeout.connect(t.queue_free)
	t.start()

# ----- Интерфейс героя -----
func _update_bars() -> void:
	if _ult_left > 0.0 and ult == "minigun":
		_ammo_fill.color = Color(0.8, 0.4, 1.0)
		_ammo_fill.size.x = _bar_w * _ult_left / MINIGUN_TIME
	elif _reloading > 0.0:
		_ammo_fill.color = Color(0.8, 0.8, 0.8)
		_ammo_fill.size.x = _bar_w * (1.0 - _reloading / reload_time)
	else:
		_ammo_fill.color = Color(1.0, 0.85, 0.2)
		_ammo_fill.size.x = _bar_w * ammo / clip_size

func _update_buttons() -> void:
	for i in 3:
		var key := "a" + str(i + 1)
		if ui.has(key) and abilities[i] != "":
			var ratio := 1.0
			if ability_cds[i] > 0.0:
				ratio = 1.0 - _cd[i] / ability_cds[i]
			TouchControls.set_state(ui[key], ratio, false, _cd[i])
			if ui.has("_ind") and ui["_ind"].has(key):
				TouchControls.set_state(ui["_ind"][key], ratio, false, _cd[i])
	if ui.has("ult") and ult != "":
		TouchControls.set_state(ui["ult"], ult_charge / ult_need, true)
		if ui.has("_ind") and ui["_ind"].has("ult"):
			TouchControls.set_state(ui["_ind"]["ult"], ult_charge / ult_need, true)

func _update_eye() -> void:
	var es := _eye.size.x
	_eye.position = Vector2(facing * body_size.x * 0.25 - es / 2, -body_size.y * 0.3 - es / 2)
	_gun.position = Vector2(8 if facing > 0 else -44, 2)

# ----- Бот -----
# Бот держит дистанцию keep_min..keep_max, прыгает через препятствия и за
# противником, стреляет, когда тот на одной высоте, и пользуется своими
# способностями (у каждого вида ботов — свои).
func _bot_think(delta: float) -> Array:
	if is_minion:
		_minion_tick(delta)
	if target == null or not is_instance_valid(target) or not target.is_alive() or frozen \
			or _stun_t > 0.0:
		return [0.0, false, false]
	if aggro_radius > 0.0:
		var dist := global_position.distance_to(target.global_position)
		if not aware:
			if dist < aggro_radius:
				become_aware()
			else:
				return [0.0, false, false]        # ещё не заметил — стоит на месте
		elif dist > aggro_radius * 3.0:
			_lose_t += delta
			if _lose_t > 5.0:                      # цель давно далеко — потерял из виду
				_lose_t = 0.0
				aware = false
				return [0.0, false, false]
		else:
			_lose_t = 0.0
	var to: Vector2 = target.global_position - global_position
	var d := absf(to.x)
	var dir := 0.0
	if d > keep_max:
		dir = signf(to.x)
	elif d < keep_min:
		dir = -signf(to.x)
	var jump := false
	_think_timer -= delta
	if _think_timer <= 0.0:
		_think_timer = randf_range(0.5, 1.2)
		if calm_jumps:
			# Арена: прыгает за героем наверх, только если тот рядом по горизонтали, и не каждый раз
			if (to.y < -80.0 and absf(to.x) < 320.0 and randf() < 0.6) or randf() < jumpiness * 0.35:
				jump = true
		elif to.y < -80.0 or randf() < jumpiness:
			jump = true
	if is_on_wall() and dir != 0.0:
		jump = true
	if not flying and speed > 0.0:              # стоячие (тотемы) никуда не ходят и не спрыгивают
		var nav := _bot_navigate(delta, to, dir)
		dir = nav[0]
		jump = (jump or nav[1]) and not ground_only
	var shoot := absf(to.y) < 40.0 + body_size.y * 0.3 and d < shoot_range
	if gun_kind == "spear":
		shoot = to.length() < shoot_range       # бросает дугой — достаёт и выше, и ниже
	# урон вплотную
	_melee_cd -= delta
	if melee_dmg > 0 and _melee_cd <= 0.0 and d < (body_size.x + target.body_size.x) / 2 + 14.0 \
			and absf(to.y) < 60.0:
		target.take_damage(melee_dmg, self)
		_melee_cd = 0.6
		_anim("punch")
	_bot_use_abilities(delta, to)
	return [dir, jump, shoot]

func _bot_use_abilities(delta: float, to: Vector2) -> void:
	for ab in bot_abilities:
		if not _bot_cd.has(ab):
			_bot_cd[ab] = randf_range(1.5, bot_abilities[ab])   # первый раз — не сразу
		_bot_cd[ab] -= delta
		if _bot_cd[ab] <= 0.0 and _bot_try(ab, to):
			_bot_cd[ab] = bot_abilities[ab] * randf_range(0.85, 1.15)

func _bot_try(ab: String, to: Vector2) -> bool:
	var d := absf(to.x)
	match ab:
		"grenade":
			if d > 150.0 and d < 900.0:
				# скорость броска под расстояние до цели (дальность ≈ v² / g)
				var v := sqrt(d * 985.0)
				_throw_grenade(clampf((v - 250.0) / 750.0, 0.0, 1.0))
				return true
		"shell":
			if d < 1000.0 and absf(to.y) < 90.0:
				_fire_shell()
				return true
		"shield":
			if d < 800.0 and absf(to.y) < 120.0 and is_on_floor():
				_place_shield()
				return true
		"barrage":
			if d > 300.0:
				_mortar_target_x = target.global_position.x
				_barrage()
				return true
		"quake":
			if d < 1500.0 and absf(to.y) < 160.0 and is_on_floor():
				_start_ult()
				if has_meta("quake_stun"):
					# Колосс выдыхается после землетрясения — можно зайти со спины
					_after(1.0, stun.bind(float(get_meta("quake_stun"))))
				return true
		"swing":
			# удар мечом вблизи: замах, потом рубящий удар
			if d < body_size.x / 2 + 120.0 and absf(to.y) < 90.0 + body_size.y * 0.3 and is_on_floor() and _charging <= 0.0:
				_anim("swing")
				_forced_time = 0.6
				_forced_vx = 0.0
				_after(0.38, func():
					if not _alive or _stun_t > 0.0 or not is_instance_valid(target):
						return
					var dd: Vector2 = target.global_position - global_position
					Util.flash(get_parent(), global_position + Vector2(facing * (body_size.x / 2 + 40), -10), 30.0 + body_size.x * 0.25, Color(1, 1, 1, 0.6))
					if signf(dd.x) == facing and absf(dd.x) < body_size.x / 2 + 130.0 and absf(dd.y) < 100.0 + body_size.y * 0.3:
						target.take_damage(swing_dmg, self))
				return true
		"net":
			if to.length() < 600.0:
				_anim("throw_smoke")
				_after(0.12, _release_spear.bind("net", 0.0))
				return true
		"web":
			if to.length() < 700.0:
				_anim("spit")
				_after(0.1, _release_spear.bind("web", 0.0))
				return true
		"web_volley":
			if to.length() < 900.0:
				_anim("spit")
				for k in 3:
					_after(0.1 + k * 0.12, _release_spear.bind("web", (k - 1) * 110.0))
				return true
		"pounce":
			if d > 90.0 and d < 520.0 and is_on_floor():
				_anim("pounce")
				_forced_time = 0.25
				_forced_vx = 0.0
				_after(0.25, func():
					if not _alive or _stun_t > 0.0:
						return
					velocity.y = -620.0
					_forced_time = 0.6
					_forced_vx = facing * minf(d * 1.6, 820.0)
					_pounce_t = 0.6)
				return true
		"dive":
			if is_instance_valid(target) and to.length() < 600.0:
				_anim("punch")
				_dive_t = 0.55
				_dive_v = to.normalized() * 720.0
				return true
		"raise":
			# некромант поднимает мертвецов, когда на арене почти никого не осталось
			if allies.is_valid() and summon.is_valid():
				var others := 0
				for a in allies.call():
					if is_instance_valid(a) and a.is_alive() and a != self:
						others += 1
				if others <= 1:
					_anim("cast")
					_forced_time = 0.7
					_forced_vx = 0.0
					_after(0.5, func():
						if _alive:
							summon.call("skeleton", 2, global_position))
					return true
		"bone_wave":
			# Король бьёт мечом в землю — по земле бежит волна костяных шипов
			if d < 900.0 and absf(to.y) < 200.0 and is_on_floor():
				_anim("slam")
				_forced_time = 0.8
				_forced_vx = 0.0
				var dirx := facing
				for k in 7:
					_after(0.45 + k * 0.12, _spawn_bone_spike.bind(global_position.x + dirx * (80.0 + k * 85.0)))
				return true
		"bone_storm":
			if to.length() < 1200.0:
				_anim("roar")
				for k in 7:
					_after(0.3 + k * 0.08, _release_spear.bind("bone", (k - 3) * 90.0))
				return true
		"charge":
			if d > 200.0 and d < 1300.0 and absf(to.y) < 120.0 and is_on_floor():
				_start_charge()
				return true
		"smoke":
			if to.length() < 900.0:
				_throw_spear("smoke")
				return true
		"bombs":
			if to.length() < 900.0:
				for k in 3:
					_after(k * 0.4, _throw_spear.bind("bomb", randf_range(-90.0, 90.0)))
				return true
		"volley":
			if to.length() < 1100.0:
				_anim("volley")
				for k in 5:
					_after(0.12 + k * 0.06, _throw_spear.bind("", (k - 2) * 70.0, false))
				return true
		"heal_allies":
			if allies.is_valid():
				var any := false
				for a in allies.call():
					if is_instance_valid(a) and a.is_alive() and a.hp < a.max_hp \
							and a.global_position.distance_to(global_position) < 450.0:
						a.heal(int(a.max_hp * 0.3))
						Util.flash(get_parent(), a.global_position, a.body_size.x, Color(0.4, 1.0, 0.4, 0.8))
						any = true
				if any:
					_anim("cast")
					Util.flash(get_parent(), global_position, 60.0, Color(0.4, 1.0, 0.4, 0.6))
				return any
		"warcry":
			if allies.is_valid():
				for a in allies.call():
					if is_instance_valid(a) and a.is_alive() and a != self:
						a.heal(int(a.max_hp * 0.25))
						a.add_buff("speed")
						a.add_buff("damage")
				add_buff("damage")
				_anim("roar")
				Util.flash(get_parent(), global_position, 120.0, Color(1.0, 0.5, 0.2, 0.7))
				return true
		"summon":
			if summon.is_valid():
				_anim("summon")
				summon.call(get_meta("summons", "goblin"), 2, global_position)
				Util.flash(get_parent(), global_position, 90.0, Color(0.5, 1.0, 0.3, 0.7))
				return true
		"slam":
			if d < 220.0 and absf(to.y) < 100.0 and is_on_floor():
				_forced_time = 0.5
				_forced_vx = 0.0
				_anim("slam")
				_after(0.45, func():
					if _alive:
						var feet := global_position + Vector2(0, body_size.y / 2)
						Util.explode(get_parent(), feet, 170.0, 22, 30, team, self)
						Util.flash(get_parent(), feet, 90.0, Color(0.8, 0.6, 0.3)))
				return true
		"roots":
			if is_instance_valid(target):
				_anim("roots")
				_forced_time = 0.9
				_forced_vx = 0.0
				for k in 3:
					_after(0.3 + k * 0.35, _spawn_root.bind(k))
				return true
		"spores":
			if to.length() < 1000.0:
				_anim("spores")
				for k in 2:
					_after(0.2 + k * 0.3, _throw_spear.bind("smoke", randf_range(-200.0, 200.0), false))
				return true
		_:
			# способности противников глубин, леса, деревни и Колизея
			return DeepAbilities.try(self, ab, to) or RaidAbilities.try(self, ab, to) or FarAbilities.try(self, ab, to)
	return false

# ----- Особые атаки ботов -----
func _throw_spear(kind: String, offset := 0.0, anim := true) -> void:
	if not _alive or not is_instance_valid(target):
		return
	if anim:
		_anim("throw_smoke" if kind in ["smoke", "net"] else ("spit" if kind == "web" else "throw"))
	# снаряд вылетает, когда рука доходит до броска
	_after(0.12 if rig and anim else 0.0, _release_spear.bind(kind, offset))

func _release_spear(kind: String, offset: float) -> void:
	if not _alive or not is_instance_valid(target):
		return
	var s := Spear.new()
	s.shooter = self
	s.team = team
	s.payload = kind
	s.damage = bullet_damage if kind in ["", "seed", "stone", "bone", "firebottle", "mud", "branch", "snowball", "ice_arrow", "lava"] else (16 if kind == "bomb" else 0)
	if kind == "bone" and bullet_damage <= 0:
		s.damage = 10
	if kind == "seed":
		s.payload = "seed"
	var from := global_position + Vector2(facing * 20, -body_size.y * 0.3)
	if rig:
		from = rig.muzzle()
	var to: Vector2 = target.global_position + Vector2(offset + randf_range(-30, 30), 0)
	var t := clampf(from.distance_to(to) / (950.0 if kind == "stone" else 650.0), 0.35, 1.3)
	s.velocity = Spear.aim(from, to, t)
	s.position = from
	get_parent().add_child(s)

func _spawn_root(k: int) -> void:
	if not _alive or not is_instance_valid(target) or not target.is_alive():
		return
	var x: float = target.global_position.x + (k - 1) * 40.0 * signf(randf() - 0.5)
	var q := PhysicsRayQueryParameters2D.create(Vector2(x, target.global_position.y),
			Vector2(x, target.global_position.y + 900.0), Layer.WORLD)
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return
	var r := RootSpike.new()
	r.team = team
	r.attacker = self
	r.position = hit["position"]
	get_parent().add_child(r)

# Разбег Гладиатора: замах, потом бег напролом. Врезался в стену — оглушён.
func _start_charge() -> void:
	_anim("windup")
	_forced_time = 0.6
	_forced_vx = 0.0
	Util.flash(get_parent(), global_position, body_size.x, Color(1.0, 0.3, 0.2, 0.8))
	_after(0.6, func():
		if not _alive or _stun_t > 0.0:
			return
		_forced_time = 1.6
		_forced_vx = facing * 820.0
		_charging = 1.6)

func _update_charge(delta: float) -> void:
	_charging -= delta
	if _forced_time <= 0.0:
		_charging = 0.0
		return
	if is_on_wall():
		_charging = 0.0
		_forced_time = 0.0
		Util.flash(get_parent(), global_position + Vector2(facing * body_size.x / 2, 0), 80.0, Color(1.0, 0.9, 0.5))
		stun(3.5)
		return
	if is_instance_valid(target) and target.is_alive():
		var to: Vector2 = target.global_position - global_position
		if absf(to.x) < (body_size.x + target.body_size.x) / 2 + 6.0 and absf(to.y) < body_size.y / 2 + 20.0:
			target.take_damage(26, self)
			target._forced_time = 0.25
			target._forced_vx = facing * 750.0
			target._forced_no_gravity = false
			target.velocity.y = -420.0
			_charging = 0.0
			_forced_time = 0.15

# Летучая мышь: кружит над целью и пикирует
func _fly(delta: float) -> void:
	if _dive_t > 0.0:
		_dive_t -= delta
		velocity = _dive_v
	elif is_instance_valid(target):
		var tt := Time.get_ticks_msec() * 0.002 + get_instance_id() % 7
		var goal: Vector2 = target.global_position + Vector2(sin(tt) * 160.0, -130.0 + cos(tt * 1.7) * 40.0)
		var want := (goal - global_position)
		var v := want.normalized() * minf(speed, want.length() * 3.0)
		velocity = velocity.move_toward(v, 1400.0 * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
	if is_instance_valid(target):
		facing = 1 if target.global_position.x > global_position.x else -1
	# не вылетает за пределы арены и под потолок
	global_position.x = clampf(global_position.x, 90.0, map_w - 90.0)
	global_position.y = maxf(global_position.y, 60.0)

# Прыжок-бросок (лев, паук): в полёте врезается в цель
func _update_pounce(delta: float) -> void:
	_pounce_t -= delta
	if is_instance_valid(target) and target.is_alive():
		if global_position.distance_to(target.global_position) < (body_size.x + target.body_size.x) * 0.5 + 10.0:
			target.take_damage(maxi(melee_dmg * 2, 10), self)
			target.slow(0.6, 0.6)
			_pounce_t = 0.0
	if is_on_floor() and _pounce_t < 0.45:
		_pounce_t = 0.0

func _spawn_bone_spike(x: float) -> void:
	if not _alive:
		return
	var q := PhysicsRayQueryParameters2D.create(Vector2(x, global_position.y - 100.0),
			Vector2(x, global_position.y + 600.0), Layer.WORLD)
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return
	var r := RootSpike.new()
	r.team = team
	r.attacker = self
	r.bone = true
	r.damage = 20
	r.position = hit["position"]
	get_parent().add_child(r)

# Сеть или паутина: герой медленнее
func slow(t: float, mult: float, look := "web") -> void:
	_slow_t = maxf(_slow_t, t)
	_slow_mult = mult
	if look == "mud":
		# вязнет в грязи: бурые комья налипли на ноги (паутину не рисуем)
		if _mud_fx == null:
			_mud_fx = Node2D.new()
			var bs2 := body_size
			for i in 6:
				var m := Polygon2D.new()
				m.polygon = Util.circle(4.0 + (i % 3) * 1.5, 8)
				m.color = Color(0.30, 0.30, 0.17, 0.95) if i % 2 == 0 else Color(0.24, 0.26, 0.14, 0.95)
				m.position = Vector2(-bs2.x / 2 + 4 + i * (bs2.x - 8) / 5.0, bs2.y / 2 - 4 - (i % 2) * 7.0)
				_mud_fx.add_child(m)
			add_child(_mud_fx)
		_mud_fx.visible = true
		if _slow_fx:
			_slow_fx.visible = false
		return
	if _mud_fx:
		_mud_fx.visible = false
	if look == "frost":
		# иней: ледяные иголки на теле (паутину не рисуем)
		if _frost_fx == null:
			_frost_fx = Node2D.new()
			_frost_fx.z_index = 2
			var bs3 := body_size
			for i in 7:
				var sh := Polygon2D.new()
				var hgt := 6.0 + (i % 3) * 3.0
				sh.polygon = PackedVector2Array([Vector2(-3, 0), Vector2(0, -hgt), Vector2(3, 0)])
				sh.color = Color(0.75, 0.92, 1.0, 0.9)
				sh.position = Vector2(-bs3.x / 2 + 3 + i * (bs3.x - 6) / 6.0, bs3.y / 2 - 2 - (i % 2) * bs3.y * 0.35)
				sh.rotation = (i - 3) * 0.25
				_frost_fx.add_child(sh)
			add_child(_frost_fx)
		_frost_fx.visible = true
		if _slow_fx:
			_slow_fx.visible = false
		return
	if _frost_fx:
		_frost_fx.visible = false
	if _slow_fx == null:
		_slow_fx = Node2D.new()
		var bs := body_size
		for i in 5:
			var l := Line2D.new()
			l.width = 2.0
			l.default_color = Color(0.95, 0.95, 0.9, 0.8)
			l.points = PackedVector2Array([Vector2(-bs.x / 2 + i * bs.x / 4, -bs.y / 2), Vector2(-bs.x / 2 + (4 - i) * bs.x / 4, bs.y / 2)])
			_slow_fx.add_child(l)
		for i in 3:
			var l2 := Line2D.new()
			l2.width = 2.0
			l2.default_color = Color(0.95, 0.95, 0.9, 0.8)
			var yy := -bs.y / 3 + i * bs.y / 3
			l2.points = PackedVector2Array([Vector2(-bs.x / 2, yy), Vector2(bs.x / 2, yy)])
			_slow_fx.add_child(l2)
		add_child(_slow_fx)
	_slow_fx.visible = true

# ----- Общие состояния: яд, корни, кости-обереги, спрыгивание -----
func _tick_status(delta: float) -> void:
	if _freeze_t > 0.0:
		_freeze_t -= delta
		if _freeze_t <= 0.0 or not _alive:
			_unfreeze()
	if _frost_fx and _frost_fx.visible and _slow_t <= 0.0:
		_frost_fx.visible = false
	if _bonus_t > 0.0:
		_bonus_t -= delta
	if _poison_t > 0.0:
		_poison_t -= delta
		_poison_tick -= delta
		if _poison_tick <= 0.0:
			_poison_tick = 0.5
			take_damage(int(_poison_dps * 0.5))
			Util.flash(get_parent(), global_position + Vector2(randf_range(-10, 10), -10), 10.0, Color(0.4, 1.0, 0.3, 0.7))
	if _burn_t > 0.0:
		_burn_t -= delta
		_burn_tick -= delta
		if _burn_tick <= 0.0:
			_burn_tick = 0.4
			take_damage(maxi(1, int(_burn_dps * 0.4)), _burn_by if is_instance_valid(_burn_by) else null)
			Fx.sparks(get_parent(), global_position + Vector2(randf_range(-12, 12), 0), Color(1.0, 0.5, 0.15), 3, 120.0, 4.0, true)
	if _bones:
		_bones.rotation += delta * 4.0

func poison(t: float, dps: float) -> void:
	_poison_t = maxf(_poison_t, t)
	_poison_dps = maxf(_poison_dps if _poison_t > 0.0 else 0.0, dps)

# ----- Дальние локации: лёд и ветер -----
func slip(t: float) -> void:
	slip_t = maxf(slip_t, t)

func push_wind(vx: float) -> void:
	_ext_vx = vx
	_ext_t = 0.12

# Иней: замедлен, на теле — ледяные иголки
func chill(t: float, mult := 0.6) -> void:
	slow(t, mult, "frost")

func is_chilled() -> bool:
	return _slow_t > 0.0 and _frost_fx != null and _frost_fx.visible

# Вмёрз в глыбу льда: ни шагу, ни выстрела; лёд сам трескается через t секунд
func freeze(t: float) -> void:
	if not _alive:
		return
	stun(t)
	_freeze_t = t
	if _stun_fx:
		_stun_fx.visible = false
	if _ice_block == null:
		_ice_block = Node2D.new()
		_ice_block.z_index = 3
		var bs := body_size + Vector2(18, 14)
		var ice := Polygon2D.new()
		ice.polygon = PackedVector2Array([Vector2(-bs.x / 2, bs.y / 2), Vector2(-bs.x / 2 - 4, -bs.y * 0.1), Vector2(-bs.x / 2 + 6, -bs.y / 2),
				Vector2(bs.x * 0.1, -bs.y / 2 - 6), Vector2(bs.x / 2, -bs.y / 2 + 4), Vector2(bs.x / 2 + 4, bs.y * 0.2), Vector2(bs.x / 2, bs.y / 2)])
		ice.color = Color(0.65, 0.88, 1.0, 0.55)
		_ice_block.add_child(ice)
		var edge := Line2D.new()
		var ep := ice.polygon.duplicate()
		ep.append(ep[0])
		edge.points = ep
		edge.width = 2.0
		edge.default_color = Color(0.92, 0.98, 1.0, 0.9)
		_ice_block.add_child(edge)
		for k in 3:
			var gl := Line2D.new()
			gl.points = PackedVector2Array([Vector2(-bs.x * 0.3 + k * 12, -bs.y * 0.35), Vector2(-bs.x * 0.15 + k * 12, -bs.y * 0.1)])
			gl.width = 2.0
			gl.default_color = Color(1, 1, 1, 0.7)
			_ice_block.add_child(gl)
		add_child(_ice_block)
	_ice_block.visible = true
	_ice_block.scale = Vector2(0.6, 0.6)
	_ice_block.create_tween().tween_property(_ice_block, "scale", Vector2.ONE, 0.15)
	Fx.sparks(get_parent(), global_position, Color(0.75, 0.92, 1.0), 10, 160.0, 4.0)

func is_frozen_in_ice() -> bool:
	return _freeze_t > 0.0

func _unfreeze() -> void:
	_freeze_t = 0.0
	if _ice_block and _ice_block.visible:
		_ice_block.visible = false
		if is_inside_tree():
			Fx.sparks(get_parent(), global_position, Color(0.8, 0.95, 1.0), 14, 260.0, 5.0)

func burn(t: float, dps: float, by = null) -> void:
	_burn_t = maxf(_burn_t, t)
	_burn_dps = maxf(_burn_dps if _burn_t > 0.0 else 0.0, dps)
	_burn_by = by

func root(t: float) -> void:
	_root_t = maxf(_root_t, t)
	velocity.x = 0.0

func boost(mult: float, t: float) -> void:
	bonus_mult = mult
	_bonus_t = maxf(_bonus_t, t)

func add_bones(n: int) -> void:
	bone_shields = mini(3, bone_shields + n)
	_update_bones()

func _update_bones() -> void:
	if bone_shields <= 0:
		if _bones:
			_bones.visible = false
		return
	if _bones == null:
		_bones = Node2D.new()
		add_child(_bones)
	for c in _bones.get_children():
		c.queue_free()
	_bones.visible = true
	var r := maxf(body_size.x, body_size.y) * 0.6 + 8.0
	for i in bone_shields:
		var b := Polygon2D.new()
		b.polygon = PackedVector2Array([Vector2(-10, -2), Vector2(10, -2), Vector2(12, -5), Vector2(14, 0),
				Vector2(12, 5), Vector2(10, 2), Vector2(-10, 2), Vector2(-12, 5), Vector2(-14, 0), Vector2(-12, -5)])
		b.color = Color(0.95, 0.93, 0.85)
		var a := TAU * i / bone_shields
		b.position = Vector2(cos(a), sin(a)) * r
		b.rotation = a
		_bones.add_child(b)

# Модель героя: другая (форма Энта) или того же вида
func set_rig(kind_name: String) -> void:
	if _rig_root == null:
		return
	if rig:
		rig.queue_free()
	var br := BotRig.new()
	br.bot = self
	br.kind = kind_name
	br.custom_spec = rig_spec if kind_name == rig_kind else {}
	br.position = Vector2(0, -body_size.y / 2)
	rig = br
	_rig_root.add_child(br)

func set_visual_scale(s: float, time := 0.2) -> void:
	if _rig_root:
		_rig_root.create_tween().tween_property(_rig_root, "scale", Vector2(s, s), time)

func set_tint(c: Color) -> void:
	if _rig_root:
		_rig_root.modulate = c
	else:
		_body.modulate = c

# Вниз: спрыгнуть со сквозной платформы
func _try_drop() -> void:
	if not is_on_floor():
		return
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col.get_normal().y > -0.5:
			continue
		var body := col.get_collider()
		var one_way := false
		if body is Destructible:
			one_way = body.one_way
		elif body is StaticBody2D:
			for c in body.get_children():
				if c is CollisionShape2D and c.one_way_collision:
					one_way = true
		if one_way:
			add_collision_exception_with(body)
			_drop_body = body
			_drop_t = 0.3
			velocity.y = 120.0
			position.y += 2.0
			return

# Призванный союзник ищет ближайшего врага и живёт ограниченное время
func _minion_tick(delta: float) -> void:
	if lifetime > 0.0:
		lifetime -= delta
		if lifetime <= 0.0:
			take_damage(99999)
			return
	_retarget_t -= delta
	if _retarget_t > 0.0 and is_instance_valid(target) and target.is_alive():
		return
	_retarget_t = 0.5
	var best = null
	var bd := INF
	for n in get_parent().get_children():
		if n is Player and n.team != team and n.is_alive() and not n.invulnerable and not n.cutscene_shield:
			var d := global_position.distance_squared_to(n.global_position)
			if d < bd:
				bd = d
				best = n
	target = best

func stun(t: float) -> void:
	if not _alive:
		return
	_stun_t = t
	_forced_time = 0.0
	_charging = 0.0
	if _stun_fx == null:
		_stun_fx = Node2D.new()
		_stun_fx.position = Vector2(0, -body_size.y / 2 - 26 - bar_lift * 0.6)
		for i in 4:
			var st := Polygon2D.new()
			st.polygon = PackedVector2Array([Vector2(0, -7), Vector2(2, -2), Vector2(7, 0), Vector2(2, 2),
					Vector2(0, 7), Vector2(-2, 2), Vector2(-7, 0), Vector2(-2, -2)])
			st.color = Color(1.0, 0.9, 0.3)
			st.position = Vector2(cos(i * TAU / 4), sin(i * TAU / 4) * 0.4) * (body_size.x * 0.4)
			_stun_fx.add_child(st)
		add_child(_stun_fx)
	_stun_fx.visible = true

func is_stunned() -> bool:
	return _stun_t > 0.0


# ----- Внешний вид ботов -----
func _add_decor() -> void:
	var bs := body_size
	var dark := color.darkened(0.35)
	match decor:
		"helmet":      # солдат — каска
			_rect(Vector2(-bs.x / 2 - 3, -bs.y / 2 - 4), Vector2(bs.x + 6, bs.y * 0.22), dark)
		"band":        # шустрик — повязка
			_rect(Vector2(-bs.x / 2, -bs.y * 0.42), Vector2(bs.x, 5), Color(0.9, 0.15, 0.15))
		"armor":       # танк — броня и наплечники
			_rect(Vector2(-bs.x * 0.42, -bs.y * 0.05), Vector2(bs.x * 0.84, bs.y * 0.45), dark)
			_rect(Vector2(-bs.x / 2 - 6, -bs.y * 0.2), Vector2(12, 16), dark)
			_rect(Vector2(bs.x / 2 - 6, -bs.y * 0.2), Vector2(12, 16), dark)
		"visor":       # пробойщик — стекло шлема
			_rect(Vector2(-bs.x / 2, -bs.y * 0.38), Vector2(bs.x, bs.y * 0.18), Color(0.55, 0.85, 1.0))
		"cap":         # артиллерист — кепка
			_rect(Vector2(-bs.x / 2 - 2, -bs.y / 2 - 6), Vector2(bs.x + 4, 9), dark)
		"crown":       # Страж — золотая корона
			var c := Polygon2D.new()
			var w := bs.x * 0.8
			var y0 := -bs.y / 2
			c.polygon = PackedVector2Array([Vector2(-w / 2, y0), Vector2(-w / 2, y0 - 22),
					Vector2(-w / 4, y0 - 10), Vector2(0, y0 - 28), Vector2(w / 4, y0 - 10),
					Vector2(w / 2, y0 - 22), Vector2(w / 2, y0)])
			c.color = Color(1.0, 0.8, 0.2)
			add_child(c)
			_rect(Vector2(-bs.x * 0.4, bs.y * 0.05), Vector2(bs.x * 0.8, bs.y * 0.3), dark)
		"horns":       # Колосс — рога и броня
			for sx in [-1.0, 1.0]:
				var h := Polygon2D.new()
				var x0: float = sx * bs.x * 0.3
				h.polygon = PackedVector2Array([Vector2(x0 - 10, -bs.y / 2), Vector2(x0 + 10, -bs.y / 2),
						Vector2(x0 + sx * 26, -bs.y / 2 - 40)])
				h.color = Color(0.9, 0.85, 0.75)
				add_child(h)
			_rect(Vector2(-bs.x * 0.45, -bs.y * 0.1), Vector2(bs.x * 0.9, bs.y * 0.5), dark)
		"gladiator":   # Гладиатор — шлем с гребнем и наплечник
			_rect(Vector2(-bs.x / 2 - 3, -bs.y / 2 - 4), Vector2(bs.x + 6, bs.y * 0.2), Color(0.75, 0.68, 0.45))
			_poly([Vector2(-bs.x * 0.35, -bs.y / 2 - 4), Vector2(bs.x * 0.35, -bs.y / 2 - 4),
					Vector2(bs.x * 0.2, -bs.y / 2 - 26), Vector2(-bs.x * 0.3, -bs.y / 2 - 22)], Color(0.85, 0.15, 0.15))
			_rect(Vector2(-bs.x / 2 - 8, -bs.y * 0.18), Vector2(22, 18), Color(0.7, 0.62, 0.4))
			_rect(Vector2(-bs.x * 0.4, bs.y * 0.15), Vector2(bs.x * 0.8, 8), Color(0.4, 0.25, 0.12))
		"goblin", "brute", "chief":   # гоблины — острые уши
			for sx in [-1.0, 1.0]:
				_poly([Vector2(sx * bs.x / 2, -bs.y * 0.32), Vector2(sx * bs.x / 2, -bs.y * 0.18),
						Vector2(sx * (bs.x / 2 + bs.x * 0.45), -bs.y * 0.36)], color.lightened(0.1))
			if decor == "brute":
				_rect(Vector2(-bs.x / 2, bs.y * 0.08), Vector2(bs.x, 10), Color(0.35, 0.22, 0.12))
				_rect(Vector2(-6, bs.y * 0.08), Vector2(12, 10), Color(0.7, 0.7, 0.6))
			if decor == "chief":
				var cols := [Color(0.9, 0.2, 0.15), Color(1.0, 0.8, 0.2), Color(0.2, 0.6, 0.9)]
				for k in 5:
					var x0 := -bs.x * 0.4 + k * bs.x * 0.2
					_poly([Vector2(x0 - 6, -bs.y / 2), Vector2(x0 + 6, -bs.y / 2),
							Vector2(x0 + (k - 2) * 4.0, -bs.y / 2 - 30 + absf(k - 2) * 5.0)], cols[k % 3])
				_rect(Vector2(-bs.x / 2, -bs.y / 2), Vector2(bs.x, 8), Color(0.55, 0.3, 0.12))
		"hood":        # лазутчик — капюшон
			_poly([Vector2(-bs.x / 2 - 3, -bs.y * 0.2), Vector2(-bs.x / 2 - 3, -bs.y / 2),
					Vector2(0, -bs.y / 2 - 12), Vector2(bs.x / 2 + 3, -bs.y / 2), Vector2(bs.x / 2 + 3, -bs.y * 0.2)], dark)
		"goggles":     # подрывник — очки и сумка с бомбами
			_rect(Vector2(-bs.x / 2, -bs.y * 0.36), Vector2(bs.x, 9), Color(0.25, 0.2, 0.15))
			_rect(Vector2(-bs.x * 0.35, -bs.y * 0.35), Vector2(9, 7), Color(1.0, 0.8, 0.2))
			_rect(Vector2(bs.x * 0.1, -bs.y * 0.35), Vector2(9, 7), Color(1.0, 0.8, 0.2))
			_rect(Vector2(-bs.x / 2 - 4, bs.y * 0.05), Vector2(14, 14), Color(0.2, 0.2, 0.22))
		"mask":        # шаман — маска с перьями
			_rect(Vector2(-bs.x * 0.42, -bs.y * 0.45), Vector2(bs.x * 0.84, bs.y * 0.3), Color(0.92, 0.9, 0.8))
			_rect(Vector2(-bs.x * 0.3, -bs.y * 0.38), Vector2(bs.x * 0.6, 4), Color(0.8, 0.2, 0.2))
			for k in 3:
				_poly([Vector2(-8 + k * 8, -bs.y / 2), Vector2(-4 + k * 8, -bs.y / 2),
						Vector2(-10 + k * 10, -bs.y / 2 - 20)], Color(0.3, 0.8, 0.6))
		"treant":      # Энт — ветви, листва и кора
			for sx in [-1.0, 1.0]:
				_poly([Vector2(sx * bs.x * 0.2, -bs.y / 2), Vector2(sx * bs.x * 0.35, -bs.y / 2),
						Vector2(sx * bs.x * 0.7, -bs.y / 2 - 60), Vector2(sx * bs.x * 0.55, -bs.y / 2 - 62)], dark)
				var leaf := Polygon2D.new()
				leaf.polygon = Util.circle(30.0, 10)
				leaf.color = Color(0.25, 0.55, 0.2)
				leaf.position = Vector2(sx * bs.x * 0.62, -bs.y / 2 - 70)
				add_child(leaf)
			var crown := Polygon2D.new()
			crown.polygon = Util.circle(42.0, 12)
			crown.color = Color(0.3, 0.6, 0.22)
			crown.position = Vector2(0, -bs.y / 2 - 20)
			add_child(crown)
			for k in 5:
				_rect(Vector2(-bs.x / 2 + 10 + k * 22, -bs.y * 0.1), Vector2(5, bs.y * 0.55), dark)
		"totem":       # тотем — резные полосы
			for k in 4:
				_rect(Vector2(-bs.x / 2, -bs.y / 2 + 10 + k * 18), Vector2(bs.x, 4), dark)
			_poly([Vector2(-bs.x / 2 - 10, -bs.y / 2), Vector2(bs.x / 2 + 10, -bs.y / 2), Vector2(0, -bs.y / 2 - 18)],
					Color(0.3, 0.6, 0.25))

func _poly(pts: Array, c: Color) -> void:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array(pts)
	p.color = c
	add_child(p)

func _rect(pos: Vector2, size: Vector2, c: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = c
	add_child(r)

# ----- Урон и смерть -----
func take_damage(amount: int, attacker = null) -> void:
	if not _alive or _invuln > 0.0 or _protect > 0.0 or cutscene_shield:
		return
	var a := float(amount)
	if invulnerable:
		_immune_flash()
		return
	if bone_shields > 0 and amount > 0:
		# кость-оберег принимает удар на себя и колет обидчика
		bone_shields -= 1
		_update_bones()
		Util.flash(get_parent(), global_position, 26.0, Color(0.95, 0.92, 0.85, 0.9))
		if attacker != null and is_instance_valid(attacker) and attacker is Player and attacker != self \
				and attacker.team != team and attacker.is_alive():
			attacker.take_damage(6)
		return
	a *= armor_mult
	if attacker != null and is_instance_valid(attacker) and attacker is Player:
		a *= attacker.dmg_mult()                 # «Сила» у того, кто бьёт
		a *= float(attacker.get_meta("bal_dmg", 1.0))          # баланс режима (Balance)
		if stagger_max > 0.0:
			a *= float(attacker.get_meta("boss_dmg", 1.0))     # по боссам Арены
		if front_armor > 0.0 and _stun_t <= 0.0:
			var side := signf(attacker.global_position.x - global_position.x)
			if side == facing or side == 0.0:
				a *= 1.0 - front_armor           # броня спереди: бей в спину!
				_immune_flash()
		if back_mult != 1.0:
			var side2 := signf(attacker.global_position.x - global_position.x)
			if side2 == -facing:
				a *= back_mult                   # удар в спину (котёл буровой машины)
	if _stun_t > 0.0 and _freeze_t <= 0.0:
		a *= stun_mult
	if has_buff("armor"):
		a *= 0.0 if is_mega("armor") else 0.5    # «Броня» у того, кого бьют
	amount = int(round(a))
	if amount <= 0:
		return
	if is_bot and not aware:
		become_aware()                       # ударили — теперь точно заметил
	if crust > 0.0:
		var took := minf(crust, float(amount))
		crust -= took
		amount -= int(round(took))
		_update_crust()
		if crust <= 0.0:
			_break_crust()
		if amount <= 0:
			return
	if stagger_max > 0.0 and _stun_t <= 0.0 and _stagger_cd <= 0.0:
		var k := 1.0
		if attacker != null and is_instance_valid(attacker) and attacker is Player:
			k = float(attacker.get_meta("stagger", 1.0))
		stagger += amount * k
		if stagger >= stagger_max:
			stagger = 0.0
			_stagger_cd = Balance.STAGGER_COOLDOWN
			stun(Balance.STAGGER_STUN)
			_float_label("ОГЛУШЁН! урон ×%s" % str(stun_mult).trim_suffix(".0"), Color(1.0, 0.85, 0.3))
	hp -= amount
	if on_hurt.is_valid():
		on_hurt.call(amount, attacker)
	if rig:
		rig.hurt()
	if attacker != null and is_instance_valid(attacker) and attacker != self \
			and attacker.has_method("add_ult"):
		attacker.add_ult(float(amount))
		if attacker.kit and attacker.kit.has_method("on_dealt"):
			attacker.kit.on_dealt(amount, self)
	_hp_fill.size.x = _bar_w * maxi(hp, 0) / max_hp
	if hp <= 0:
		# вторая жизнь (Колосс пробуждается): обработчик сам решает, умирать ли
		if on_lethal.is_valid() and bool(on_lethal.call()):
			_hp_fill.size.x = _bar_w * maxi(hp, 0) / max_hp
			return
		_die()

# Корка (самоцветная от Гранильщика, кристальная броня Призмы): принимает урон вместо героя
func give_crust(amount: float, time: float, burst := false) -> void:
	crust = maxf(crust, amount)
	_crust_t = time
	crust_burst = burst or crust_burst
	_update_crust()

func _update_crust() -> void:
	if crust <= 0.0:
		if _crust_fx:
			_crust_fx.visible = false
		return
	if _crust_fx == null:
		_crust_fx = Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 10:
			var a := TAU * i / 10.0
			var r := (0.62 if i % 2 == 0 else 0.5)
			pts.append(Vector2(cos(a) * body_size.x * r * 1.2, sin(a) * body_size.y * r))
		_crust_fx.polygon = pts
		_crust_fx.z_index = 3
		add_child(_crust_fx)
		Shimmer.apply(_crust_fx, 0.3, 0.8)
	_crust_fx.visible = true
	_crust_fx.color = Color(0.6, 0.85, 1.0, 0.18 + minf(0.25, crust / 200.0))

func _break_crust() -> void:
	crust = 0.0
	_crust_t = 0.0
	_update_crust()
	Fx.sparks(get_parent(), global_position, Color(0.7, 0.9, 1.0), 14, 260.0, 4.0)
	if crust_burst:
		crust_burst = false
		Shards.burst(get_parent(), global_position, team, self, 10, 12)

func _float_label(t: String, c: Color) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", c)
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.size = Vector2(300, 36)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = global_position + Vector2(-150, -body_size.y / 2 - 80)
	l.z_index = 30
	get_parent().add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 40.0, 1.2)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.6).set_delay(0.8)
	tw.tween_callback(l.queue_free)

func become_aware() -> void:
	if aware:
		return
	aware = true
	if alert_cb.is_valid():
		alert_cb.call(self)

func _die() -> void:
	_alive = false
	visible = false
	_hold = -1.0
	_ult_left = 0.0
	_forced_time = 0.0
	_phase_left = 0.0
	_phasing = false
	_shurikens_ready = false
	buffs.clear()
	_hover_t = 0.0
	_hover_pending = false
	_wallwalk_t = 0.0
	_jump_boost_t = 0.0
	if not is_bot:
		collision_mask = NORMAL_MASK
	_body.modulate.a = 1.0
	if _aim:
		_aim.visible = false
	_gun.visible = false
	if _canopy:
		_canopy.queue_free()
		_canopy = null
	_para = 0
	_col.set_deferred("disabled", true)
	_stun_t = 0.0
	_charging = 0.0
	_slow_t = 0.0
	_pounce_t = 0.0
	_root_t = 0.0
	_no_jump_t = 0.0
	_poison_t = 0.0
	_burn_t = 0.0
	_bonus_t = 0.0
	bone_shields = 0
	_update_bones()
	fly_free = false
	if kit and kit.has_method("on_death"):
		kit.on_death()
	_dive_t = 0.0
	cutscene_walk = 0.0
	if _slow_fx:
		_slow_fx.visible = false
	if _mud_fx:
		_mud_fx.visible = false
	if _stun_fx:
		_stun_fx.visible = false
	_death_burst()
	died.emit(index)
	if respawn and not stay_dead:
		_after(1.4 if get_meta("bal_mode", "") == "duel" else 2.0, _respawn)     # в Дуэли — обратно в бой быстрее
	elif not respawn:
		queue_free()

# Удар по неуязвимому или в броню — серая искра
func _immune_flash() -> void:
	if _immune_fx > 0.0:
		return
	_immune_fx = 0.15
	Util.flash(get_parent(), global_position + Vector2(facing * body_size.x * 0.4, 0), 18.0, Color(0.8, 0.8, 0.9, 0.8))
	_after(0.15, func(): _immune_fx = 0.0)

# Вернуть в бой (Арена вдвоём: выбывший напарник возвращается к следующей волне)
func revive(at: Vector2) -> void:
	if _alive:
		return
	stay_dead = false
	spawn = at
	_respawn()

# Герой разлетается на кусочки своего цвета
func _death_burst() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var n := 10 if body_size.x < 70.0 else 18
	for i in n:
		var f := Fragment.new()
		f.ghost = true
		f.size = Vector2.ONE * clampf(body_size.x / 4.0, 8.0, 22.0)
		f.color = color if i % 3 != 0 else color.darkened(0.3)
		f.position = global_position + Vector2(randf_range(-body_size.x, body_size.x) * 0.4,
				randf_range(-body_size.y, body_size.y) * 0.4)
		f.linear_velocity = Vector2(randf_range(-350, 350), randf_range(-550, -150))
		f.angular_velocity = randf_range(-12, 12)
		parent.add_child(f)
		f.z_index = 1

func _respawn() -> void:
	_unfreeze()
	slip_t = 0.0
	_ext_t = 0.0
	var p: Vector2 = spawn
	var parachute := false
	if spawn_picker.is_valid():
		var r: Dictionary = spawn_picker.call(self)
		p = r["pos"]
		parachute = r["parachute"]
	elif not spawn_points.is_empty():
		p = spawn_points.pick_random()
	position = p
	velocity = Vector2.ZERO
	_para = 1 if parachute else 0
	hp = max_hp
	ammo = clip_size
	_reloading = 0.0
	_hp_fill.size.x = _bar_w
	visible = true
	_col.set_deferred("disabled", false)
	_alive = true
	_protect = respawn_protect

# ----- Парашют -----
# Возрождение в небе: свободное падение, на высоте PARA_OPEN_HEIGHT над
# поверхностью раскрывается купол и герой плавно спускается. После приземления
# парашют падает рядом, складывается и остаётся лежать.
func _update_parachute(delta: float) -> void:
	if _para == 1:
		velocity.y = minf(velocity.y, FREE_FALL_MAX)
		if velocity.y > 0.0 and _height_above_ground() <= PARA_OPEN_HEIGHT:
			_open_parachute()
	elif _para == 2:
		velocity.y = move_toward(velocity.y, PARA_FALL_SPEED, 5500.0 * delta)   # купол резко тормозит
		velocity.x *= 0.6

func _height_above_ground() -> float:
	var q := PhysicsRayQueryParameters2D.create(global_position,
			global_position + Vector2(0, 3000))
	q.collision_mask = Layer.WORLD
	q.exclude = [get_rid()]
	var r := get_world_2d().direct_space_state.intersect_ray(q)
	if r.is_empty():
		return INF
	return r["position"].y - global_position.y - body_size.y / 2

func _open_parachute() -> void:
	_para = 2
	_canopy = Node2D.new()
	_canopy.position = Vector2(0, -95)
	var lines := Node2D.new()
	lines.name = "Lines"
	_canopy.add_child(lines)
	for pts in [[Vector2(-50, 0), Vector2(-14, 67)], [Vector2(50, 0), Vector2(14, 67)],
			[Vector2(-18, 0), Vector2(-6, 67)], [Vector2(18, 0), Vector2(6, 67)]]:
		var l := Line2D.new()
		l.points = PackedVector2Array(pts)
		l.width = 2.0
		l.default_color = Color(0.9, 0.9, 0.9, 0.8)
		lines.add_child(l)
	var dome := Polygon2D.new()
	var poly := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		poly.append(Vector2(cos(a) * 52.0, sin(a) * 42.0))
	dome.polygon = poly
	var c := team_color if outline.a > 0.0 else color
	dome.color = c.lightened(0.25)
	_canopy.add_child(dome)
	var stripe := Polygon2D.new()       # полоса посередине купола
	var sp := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		sp.append(Vector2(cos(a) * 16.0, sin(a) * 42.0))
	stripe.polygon = sp
	stripe.color = Color(1, 1, 1, 0.85)
	_canopy.add_child(stripe)
	add_child(_canopy)
	_canopy.scale = Vector2(0.2, 0.2)
	var t := _canopy.create_tween()
	t.tween_property(_canopy, "scale", Vector2.ONE, 0.25)

func _land() -> void:
	_para = 0
	if _canopy == null:
		return
	# купол отцепляется, ложится на землю рядом, складывается и остаётся лежать
	var cnp := _canopy
	_canopy = null
	var gp := cnp.global_position
	var ground_y := global_position.y + body_size.y / 2
	remove_child(cnp)
	get_parent().add_child(cnp)
	cnp.global_position = gp
	cnp.z_index = -1
	var lines := cnp.get_node("Lines")
	var drift := Vector2(-facing * randf_range(30.0, 60.0), 0)
	var t := cnp.create_tween()
	t.set_parallel(true)
	t.tween_property(lines, "modulate:a", 0.0, 0.3)
	t.tween_property(cnp, "global_position", Vector2(gp.x, ground_y) + drift, 0.7) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_property(cnp, "scale", Vector2(1.15, 0.16), 0.7)
	t.tween_property(cnp, "rotation", -facing * 0.08, 0.7)
	t.chain().tween_callback(lines.queue_free)
	# если опору под лежащим парашютом разрушат — он исчезает, а не висит в воздухе
	var spot := Vector2(gp.x, ground_y) + drift
	var check := Timer.new()
	check.wait_time = 0.5
	cnp.add_child(check)
	check.timeout.connect(func():
		var q := PhysicsRayQueryParameters2D.create(spot - Vector2(0, 4), spot + Vector2(0, 12))
		q.collision_mask = Layer.WORLD
		if cnp.get_world_2d().direct_space_state.intersect_ray(q).is_empty():
			check.stop()
			var ft := cnp.create_tween()
			ft.tween_property(cnp, "modulate:a", 0.0, 0.4)
			ft.tween_callback(cnp.queue_free))
	check.start()

# ----- Баффы -----
# Подобрал бафф. Если такой уже действует — он становится МЕГА. Возвращает true, если МЕГА.
func add_buff(type: String, force_mega := false, allow_mega := true) -> bool:
	if (force_mega or (buffs.has(type) and allow_mega)) and kit and kit.has_method("on_mega"):
		kit.on_mega()
	if force_mega or (buffs.has(type) and allow_mega):
		buffs[type] = {"t": Buffs.duration(type, true), "mega": true}
		return true
	if buffs.has(type) and buffs[type]["mega"]:
		buffs[type]["t"] = maxf(buffs[type]["t"], Buffs.duration(type, false))
		return true
	buffs[type] = {"t": Buffs.duration(type, false), "mega": false}
	return false

func has_buff(type: String) -> bool:
	return buffs.has(type)

func is_mega(type: String) -> bool:
	return buffs.has(type) and buffs[type]["mega"]

func _tick_buffs(delta: float) -> void:
	for k in buffs.keys():
		buffs[k]["t"] -= delta
		if buffs[k]["t"] <= 0.0:
			buffs.erase(k)
	_jump_boost_t = maxf(0.0, _jump_boost_t - delta)

# Множитель урона («Сила»)
func dmg_mult() -> float:
	var m := bonus_mult if _bonus_t > 0.0 else 1.0
	if not has_buff("damage"):
		return m
	return m * (2.5 if is_mega("damage") else 1.5)

# МЕГА-способности: куплен «МЕГА» в Лавке или действует бафф «МЕГА-усиление»
func _mega_ab() -> bool:
	return mega_mode or has_buff("boost")

# Во сколько раз быстрее восстанавливаются способности («Откат», МЕГА-«Откат»)
func _cd_speed() -> float:
	var k := 1.0
	if is_mega("cooldown"):
		k = Buffs.CD_SPEED_MEGA
	elif has_buff("cooldown"):
		k = Buffs.CD_SPEED
	if is_mega("boost"):
		k *= Buffs.BOOST_CD
	return k

# МЕГА-«Броня»: пузырь вокруг героя ранит ботов, которые его касаются
func _update_aura(delta: float) -> void:
	var on := has_buff("armor")
	if on and _armor_bubble == null:
		_armor_bubble = Polygon2D.new()
		_armor_bubble.polygon = Util.circle(maxf(body_size.x, body_size.y) * 0.75, 24)
		add_child(_armor_bubble)
	if _armor_bubble:
		_armor_bubble.visible = on
		if on:
			var mega := is_mega("armor")
			_armor_bubble.color = Color(1.0, 0.85, 0.3, 0.28) if mega else Color(0.7, 0.8, 1.0, 0.22)
	if not on or not is_mega("armor"):
		return
	_aura_t -= delta
	if _aura_t > 0.0:
		return
	_aura_t = 0.4
	for n in get_parent().get_children():
		if n is Player and n != self and n.team != team and n.is_alive() \
				and n.global_position.distance_to(global_position) < maxf(body_size.x, body_size.y) * 0.75 + n.body_size.x / 2:
			n.take_damage(12, self)

# МЕГА-прыжок: в верхней точке герой зависает и сыплет сюрикенами вниз
func _update_hover(delta: float) -> void:
	if _hover_pending and velocity.y > -80.0:
		_hover_pending = false
		_hover_t = 2.6
	if _hover_t <= 0.0:
		return
	_hover_t -= delta
	velocity.y = move_toward(velocity.y, 35.0, 3000.0 * delta)
	_hover_throw -= delta
	if _hover_throw <= 0.0:
		_hover_throw = 0.14
		for a_deg in [55.0 + randf() * 20.0, 80.0 + randf() * 20.0, 105.0 + randf() * 20.0]:
			var ang := deg_to_rad(a_deg)
			var sh := Shuriken.new()
			sh.shooter = self
			sh.team = team
			sh.direction = Vector2(cos(ang), sin(ang))
			sh.position = position + Vector2(0, body_size.y / 2)
			get_parent().add_child(sh)

# МЕГА-рывок: вбок герой проходит сквозь стены и колонны,
# а вверх и вниз сталкивается как обычно (на платформах стоит нормально)
func _wall_move(delta: float) -> void:
	_wallwalk_t -= delta
	_body.modulate = Color(1.3, 1.2, 0.7)
	# вбок — только неразрушаемая рамка карты мешает
	collision_mask = Layer.FRAME
	if move_and_collide(Vector2(velocity.x * delta, 0)):
		velocity.x = 0.0
	# вниз-вверх — обычно, но без блоков, в которых герой сейчас «застрял» боком
	collision_mask = NORMAL_MASK
	var inside := _overlapping_blocks()
	for b in inside:
		add_collision_exception_with(b)
	var col := move_and_collide(Vector2(0, velocity.y * delta))
	_ww_floor = false
	if col:
		if col.get_normal().y < -0.6:
			_ww_floor = true
		velocity.y = 0.0
	for b in inside:
		if is_instance_valid(b):
			remove_collision_exception_with(b)
	# закончился, а герой внутри блока — продлеваем, пока не выйдет
	if _wallwalk_t <= 0.0 and not inside.is_empty():
		_wallwalk_t = 0.05
	if _wallwalk_t <= 0.0:
		_body.modulate = Color.WHITE

func _overlapping_blocks() -> Array:
	_phase_query.transform = global_transform
	_phase_query.exclude = [get_rid()]
	var res: Array = []
	for r in get_world_2d().direct_space_state.intersect_shape(_phase_query, 8):
		var c = r["collider"]
		if c is Destructible and not res.has(c):
			res.append(c)
	return res

# ---------- Толкание предметов ----------
# Герой двигает подвижные (незакреплённые) объекты и осколки собой.
# Чем тяжелее объект, тем медленнее он едет. Осколок, упавший на голову,
# сбрасывается в сторону, чтобы не мешать прыгать.
const PUSH_POWER := 2.2

func _push_bodies(want_vx: float, _want_vy: float) -> void:
	var power := PUSH_POWER * maxf(1.0, body_size.x * body_size.y / 2400.0)
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var b = col.get_collider()
		if not (b is RigidBody2D) or b.freeze:
			continue
		var n := col.get_normal()
		var m: float = maxf(b.mass, 0.05)
		if absf(n.x) > 0.5 and absf(want_vx) > 1.0 and signf(want_vx) == -signf(n.x):
			# толкаем вбок: скорость объекта зависит от его массы
			var k := power / (power + m)
			var target := want_vx * k
			var cur: float = b.linear_velocity.x
			if absf(cur) < absf(target) or signf(cur) != signf(target):
				b.linear_velocity.x = target
			b.sleeping = false
			velocity.x = want_vx * maxf(k, 0.15)      # герой упирается и идёт медленнее

func _end_exception(b) -> void:
	if is_instance_valid(b):
		remove_collision_exception_with(b)
		b.remove_collision_exception_with(self)

# Предметы, лежащие на голове, соскальзывают в сторону и не держат героя
func _clear_head() -> void:
	var q := PhysicsShapeQueryParameters2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(body_size.x * 0.7, 10.0)
	q.shape = rs
	q.transform = Transform2D(0.0, global_position + Vector2(0, -body_size.y / 2.0 - 3.0))
	q.collision_mask = Layer.WORLD | Layer.FRAG
	q.exclude = [get_rid()]
	for hit in get_world_2d().direct_space_state.intersect_shape(q, 8):
		var b = hit["collider"]
		if not (b is RigidBody2D) or b.freeze or b.global_position.y > global_position.y - body_size.y / 2.0:
			continue
		var side := signf(b.global_position.x - global_position.x)
		if side == 0.0:
			side = 1.0 if randf() < 0.5 else -1.0
		var m: float = maxf(b.mass, 0.05)
		var k := clampf(PUSH_POWER / (PUSH_POWER + m), 0.35, 1.0)
		b.linear_velocity = Vector2(side * 260.0 * k,
				minf(b.linear_velocity.y, (velocity.y if velocity.y < 0.0 else 0.0) * k))
		b.sleeping = false
		add_collision_exception_with(b)
		b.add_collision_exception_with(self)
		get_tree().create_timer(0.35).timeout.connect(_end_exception.bind(b))

# ---------- Навигация ботов ----------
# Бот не должен застревать: если цель внизу — спрыгивает со сквозной платформы;
# если долго стоит на месте, упёршись в препятствие — прыгает, потом ломает
# его ударами, а если не выходит — обходит, отступив в другую сторону.
func _bot_navigate(delta: float, to: Vector2, dir: float) -> Array:
	var jump := false
	var on_floor := is_on_floor()
	_nav_drop_cd -= delta
	_smash_cd -= delta
	if on_floor and to.y > 90.0 + body_size.y * 0.2 and _nav_drop_cd <= 0.0 and _standing_on_one_way():
		_nav_drop_cd = 1.0
		_try_drop()
	if _detour_t > 0.0:
		_detour_t -= delta
		dir = _detour_dir
	_nav_sample_t -= delta
	if _nav_sample_t <= 0.0:
		_nav_sample_t = 0.5
		var moved := global_position.distance_to(_nav_last)
		_nav_last = global_position
		if dir != 0.0 and moved < 20.0 and _forced_time <= 0.0 and not frozen and cutscene_walk == 0.0:
			_nav_stuck += 1
		else:
			_nav_stuck = maxi(0, _nav_stuck - 1)
	if _nav_stuck >= 1 and dir != 0.0:
		jump = true
	if _nav_stuck >= 2 and dir != 0.0:
		if on_floor and _standing_on_one_way():
			_try_drop()
		elif _smash_cd <= 0.0:
			_smash_cd = 0.45
			_smash_front(dir)
	if _nav_stuck >= 5 and _detour_t <= 0.0:
		# тупик: отходим в обратную сторону и пробуем снова
		_detour_dir = -dir if dir != 0.0 else (1.0 if randf() < 0.5 else -1.0)
		_detour_t = 1.2
		_nav_stuck = 2
	return [dir, jump]

func _standing_on_one_way() -> bool:
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		if col.get_normal().y > -0.5:
			continue
		var body := col.get_collider()
		if body is Destructible and body.one_way:
			return true
		if body is StaticBody2D:
			for c in body.get_children():
				if c is CollisionShape2D and c.one_way_collision:
					return true
	return false

# Бот упёрся в разрушаемое препятствие — бьёт его, выбивая клетки перед собой
func _smash_front(dir: float) -> void:
	_anim("punch")
	var fx := global_position.x + dir * (body_size.x / 2.0 + 12.0)
	var power := int(clampf(body_size.x * 0.5, 18.0, 70.0))
	for n in get_parent().get_children():
		if n is Destructible and not n.background and n.shield_team != team \
				and absf(n.global_position.x - fx) < 400.0 and absf(n.global_position.y - global_position.y) < 400.0:
			var y := -body_size.y / 2.0 + 8.0
			while y < body_size.y / 2.0:
				n.hit(Vector2(fx, global_position.y + y), Vector2(dir, 0), power, 6.0, team,
						{"strict": true, "attacker": self, "power": 0.4})
				y += 18.0

# Огромные боссы проходят сквозь сквозные платформы (не запрыгивают и не застревают в них)
func ignore_one_way_platforms() -> void:
	ground_only = true
	for n in get_parent().get_children():
		var one_way := false
		if n is Destructible:
			one_way = n.one_way
		elif n is StaticBody2D:
			for c in n.get_children():
				if c is CollisionShape2D and c.one_way_collision:
					one_way = true
		if one_way:
			add_collision_exception_with(n)

# Тень лежит на земле под героем: в прыжке уменьшается и бледнеет
func _update_shadow(delta: float) -> void:
	if _shadow == null:
		return
	if is_on_floor():
		_shadow.position.y = body_size.y / 2
		_shadow.scale = Vector2.ONE
		_shadow.modulate.a = 1.0
		return
	_shadow_t -= delta
	if _shadow_t > 0.0:
		return
	_shadow_t = 0.05
	var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(
			global_position, global_position + Vector2(0, 400), Layer.WORLD | Layer.FRAME, [get_rid()]))
	if hit.is_empty():
		_shadow.modulate.a = 0.0
		return
	var dist: float = hit["position"].y - global_position.y - body_size.y / 2
	var k := clampf(1.0 - dist / 400.0, 0.2, 1.0)
	_shadow.position.y = hit["position"].y - global_position.y
	_shadow.scale = Vector2(k, k)
	_shadow.modulate.a = k
