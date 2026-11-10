extends Node2D

enum GameState { READY, RUNNING, WON, LOST }
enum LobbyPage { HOME, STAGES, INVENTORY, TALENTS }

const ARENA_SIZE := Vector2(3600.0, 2400.0)
const ENDLESS_ARENA_SIZE := Vector2(6000.0, 4000.0)
const ENDLESS_BOSS_INTERVAL := 5
const VIEW_SIZE := Vector2(1280.0, 720.0)
const PIXEL_CANVAS_SCALE := 0.5
const MAX_ENEMIES := 220
const MAX_WEAPONS := 18
const MAX_WEAPON_RANK := 5
const COPPER_DROP_CHANCE := 0.78
const LAST_RUN_REPORT_PATH := "user://zhenye_last_run_report.json"
const INVENTORY_FILTER_NAMES := {
	"": "全部",
	"weapon": "法器",
	"head": "道冠",
	"robe": "法袍",
	"belt": "腰饰",
	"boots": "云履",
	"charm": "护符",
}
const TALENT_NODE_POSITIONS := {
	"unbound_evolution": Vector2(1095, 20),
	"mastery": Vector2(1095, 180),
	"opening_arsenal": Vector2(650, 400),
	"cooldown": Vector2(940, 400),
	"magnet": Vector2(1250, 400),
	"soul_vacuum": Vector2(1550, 400),
	"rebirth": Vector2(260, 640),
	"boss_hunter": Vector2(570, 640),
	"spirit": Vector2(870, 640),
	"fortune": Vector2(1190, 640),
	"shop_discount": Vector2(1620, 640),
	"regeneration": Vector2(230, 900),
	"warding": Vector2(540, 900),
	"power": Vector2(860, 900),
	"agility": Vector2(1180, 900),
	"prosperity": Vector2(1500, 900),
	"vitality": Vector2(1020, 1120),
}
const TALENT_NODE_SIZE := Vector2(260, 96)
const TALENT_CANVAS_SIZE := Vector2(2100, 1250)

const STAGE_DATA := [
	{
		"name": "荒村鬼夜",
		"subtitle": "纸傀游街，百目傩君坐镇荒村",
		"waves": 8,
		"duration": 30.0,
		"spawn_rate": 1.0,
		"enemy_hp": 1.0,
		"boss_hp": 3700.0,
		"boss_name": "百目傩君",
		"event_name": "纸傀夜行",
		"event_interval": 22.0,
		"floor_tint": Color("71805d"),
		"bg": Color("17140f"),
		"grid": Color("2c271e"),
		"border": Color("6b5738"),
	},
	{
		"name": "乱葬阴山",
		"subtitle": "古坟开裂，白骨夫人唤醒亡骸",
		"waves": 10,
		"duration": 30.0,
		"spawn_rate": 1.16,
		"enemy_hp": 1.22,
		"boss_hp": 5500.0,
		"boss_name": "白骨夫人",
		"event_name": "群坟开棺",
		"event_interval": 20.0,
		"floor_tint": Color("61706b"),
		"bg": Color("111718"),
		"grid": Color("223032"),
		"border": Color("53696a"),
	},
	{
		"name": "锁妖古刹",
		"subtitle": "佛灯倒燃，无相鬼佛镇守锁妖殿",
		"waves": 12,
		"duration": 30.0,
		"spawn_rate": 1.32,
		"enemy_hp": 1.5,
		"boss_hp": 8000.0,
		"boss_name": "无相鬼佛",
		"event_name": "古刹业火",
		"event_interval": 18.0,
		"floor_tint": Color("8c7168"),
		"bg": Color("1b1010"),
		"grid": Color("35201d"),
		"border": Color("784236"),
	},
	{
		"name": "幽都水乡",
		"subtitle": "冥河倒灌，无渡河伯截断往生水路",
		"waves": 14,
		"duration": 30.0,
		"spawn_rate": 1.42,
		"enemy_hp": 1.75,
		"boss_hp": 10800.0,
		"boss_name": "无渡河伯",
		"event_name": "黄泉倒灌",
		"event_interval": 17.0,
		"floor_tint": Color("5d8581"),
		"bg": Color("0d1b1b"),
		"grid": Color("183738"),
		"border": Color("4f8680"),
	},
	{
		"name": "寒狱雪岭",
		"subtitle": "北风封山，玄霜狱主驱使冰尸镇守天关",
		"waves": 16,
		"duration": 30.0,
		"spawn_rate": 1.54,
		"enemy_hp": 2.0,
		"boss_hp": 14500.0,
		"boss_name": "玄霜狱主",
		"event_name": "万壑雪崩",
		"event_interval": 15.5,
		"floor_tint": Color("b9cad2"),
		"bg": Color("101821"),
		"grid": Color("263746"),
		"border": Color("7793a7"),
	},
]

const COLOR_BG := Color("17140f")
const COLOR_GRID := Color("2c271e")
const COLOR_BORDER := Color("6b5738")
const COLOR_PLAYER := Color("67c9a5")
const COLOR_PLAYER_CORE := Color("f3dda0")
const COLOR_PROJECTILE := Color("f1d479")
const COLOR_XP := Color("7bd6ad")
const COLOR_DANGER := Color("d84b3e")
const COLOR_TALISMAN := Color("efb15e")
const COLOR_LIGHTNING := Color("91bfff")
const COLOR_FRIENDLY_SHOT := Color("62e6d1")
const COLOR_ENEMY_SHOT := Color("ff315f")

const WEAPON_DATA := {
	"sword": ["飞剑", "御剑追敌，提高飞剑数量、伤害与穿透"],
	"talisman": ["符火", "掷出朱砂火符，命中后伤害一片敌人"],
	"thunder": ["雷印", "周期引落天雷，同时打击多个目标"],
	"bell": ["镇魂铃", "周期震荡近身邪祟并将其击退"],
	"coin": ["铜钱镖", "在敌群之间连续弹射，擅长处理中等密度目标"],
	"orb": ["阴阳玉", "环绕自身持续碾过近身邪祟"],
	"chain": ["缚妖索", "将附近邪祟串联起来并逐个造成伤害"],
	"banner": ["招魂幡", "展开持续伤害领域，压制靠近的邪祟"],
	"paper_doll": ["纸人术", "放出会自行追敌的纸傀分身"],
	"mirror": ["八卦镜", "射出持续旋转的破邪镜光"],
	"tide_gourd": ["潮生葫", "喷涌宽阔潮浪，贯穿成群邪祟并在高阶折返"],
	"ferry_oar": ["引渡桨", "挥动大范围扇击并留下破邪船痕"],
	"nether_lotus": ["冥河莲灯", "在敌群中布下持续脉冲的引魂莲灯"],
	"ice_needles": ["玄冰针", "发射高速穿透冰针，覆盖中远距离扇面"],
	"frost_stele": ["寒狱碑", "预警后落下寒碑，造成高额范围爆发"],
	"snow_umbrella": ["六花伞", "旋转伞面扫击近敌并清除敌方弹体"],
	"judge_brush": ["判官笔", "挥出贯穿敌阵的朱墨判词，覆盖狭长区域"],
	"soul_lantern": ["照夜灯", "在数处敌群中点亮魂灯，牵引并震荡周围邪祟"],
}
const WEAPON_ORDER := ["sword", "talisman", "thunder", "bell", "coin", "orb", "chain", "banner", "paper_doll", "mirror", "tide_gourd", "ferry_oar", "nether_lotus", "ice_needles", "frost_stele", "snow_umbrella", "judge_brush", "soul_lantern"]

const PASSIVE_DATA := {
	"sword_art": ["养剑诀", "法器攻击频率 +8%，飞剑进化所需"],
	"flame_heart": ["真火心法", "所有伤害 +12%，符火进化所需"],
	"footwork": ["踏罡步", "移动速度 +8%"],
	"vitality": ["护心镜", "生命上限 +20，并恢复 25 点生命"],
	"magnet": ["聚灵玉", "残魂拾取范围 +30"],
	"breathing": ["调息法", "法器与镇魂阵冷却缩短 6%"],
	"insight": ["洞玄法眼", "对精英与首领伤害 +8%，判官笔进化所需"],
	"soul_feast": ["吞煞诀", "每镇伏一只邪祟恢复 0.1 生命，照夜灯进化所需"],
}

const EVOLUTION_DATA := {
	"evolve_sword": ["万剑归宗", "飞剑化作剑阵：剑数、射速与穿透大幅提高"],
	"evolve_talisman": ["三昧真火", "符火一化为三，爆炸范围和威力大幅提高"],
	"evolve_thunder": ["九霄雷狱", "天雷化作雷狱，连续轰击并波及目标周围"],
	"evolve_bell": ["黄泉镇魂钟", "钟声震彻黄泉，范围、威力与击退大幅提高"],
	"evolve_coin": ["落宝金钱", "同时掷出四枚金钱，在邪祟间长距离连环弹射"],
	"evolve_orb": ["两仪轮转", "阴阳玉化作内外双环，持续碾压近身邪祟"],
	"evolve_chain": ["天罗缚妖阵", "缚妖索结成天罗，连接更多邪祟并在末端引爆"],
	"evolve_banner": ["万魂归幡", "魂幡领域大幅扩张，持续噬魂并反哺自身"],
	"evolve_paper_doll": ["撒豆成兵", "五尊高速纸将持续追猎并穿透成群邪祟"],
	"evolve_mirror": ["八门金光镜", "六道破邪镜光同时旋转，扫荡四面八方"],
	"evolve_tide_gourd": ["煮海吞江葫", "三道巨浪往返席卷，返程保持完整威力"],
	"evolve_ferry_oar": ["一苇渡幽冥", "桨风横扫周身并留下两道相反船痕"],
	"evolve_nether_lotus": ["黄泉引魂莲", "三盏莲灯持续引魂，终脉冲反哺生命"],
	"evolve_ice_needles": ["太阴万劫针", "九针连发并轻度追敌，贯穿整片敌潮"],
	"evolve_frost_stele": ["万载寒狱碑", "三碑齐落并向四方扩散寒狱裂痕"],
	"evolve_snow_umbrella": ["六花回天伞", "伞幕覆盖整圈，持续扫敌并化解弹幕"],
	"evolve_judge_brush": ["生死判牒", "五道巨幅判词横贯战场，朱墨尽头追加爆裂"],
	"evolve_soul_lantern": ["万象长明灯", "四盏长明灯同时镇压敌群，持续牵引并反哺生命"],
}
const EVOLUTION_RECIPES := {
	"sword": "sword_art",
	"talisman": "flame_heart",
	"thunder": "breathing",
	"bell": "vitality",
	"coin": "magnet",
	"orb": "footwork",
	"chain": "magnet",
	"banner": "flame_heart",
	"paper_doll": "footwork",
	"mirror": "breathing",
	"tide_gourd": "flame_heart",
	"ferry_oar": "footwork",
	"nether_lotus": "magnet",
	"ice_needles": "sword_art",
	"frost_stele": "vitality",
	"snow_umbrella": "breathing",
	"judge_brush": "insight",
	"soul_lantern": "soul_feast",
}
const WEAPON_SFX_INTERVALS := {
	"sword": 0.22,
	"talisman": 0.45,
	"thunder": 0.8,
	"bell": 0.9,
	"coin": 0.32,
	"orb": 0.7,
	"chain": 0.55,
	"banner": 1.0,
	"paper_doll": 0.8,
	"mirror": 0.9,
	"tide_gourd": 0.55,
	"ferry_oar": 0.65,
	"nether_lotus": 0.9,
	"ice_needles": 0.42,
	"frost_stele": 0.85,
	"snow_umbrella": 0.38,
	"judge_brush": 0.52,
	"soul_lantern": 0.82,
}
const WEAPON_SYNERGIES := [
	{"weapons": ["sword", "mirror"], "name": "剑镜同辉", "effect": "镜光伤害+25%"},
	{"weapons": ["talisman", "banner"], "name": "离火幡阵", "effect": "魂幡伤害+25%，显化火阵"},
	{"weapons": ["thunder", "chain"], "name": "雷索天引", "effect": "缚妖索末端追加雷击"},
	{"weapons": ["coin", "orb"], "name": "财气两仪", "effect": "铜钱+1，阴阳玉伤害+20%"},
	{"weapons": ["bell", "paper_doll"], "name": "纸将听令", "effect": "钟波扩大，纸傀伤害+20%"},
	{"weapons": ["tide_gourd", "talisman"], "name": "水火既济", "effect": "潮浪伤害+20%，符火击退敌人"},
	{"weapons": ["ferry_oar", "bell"], "name": "潮音震岸", "effect": "桨击范围+20%，钟波击退增强"},
	{"weapons": ["nether_lotus", "banner"], "name": "万魂归灯", "effect": "莲灯伤害+25%，终脉冲恢复生命"},
	{"weapons": ["ice_needles", "chain"], "name": "寒索穿心", "effect": "缚妖索末端追加三枚玄冰针"},
	{"weapons": ["frost_stele", "thunder"], "name": "雷霆裂冰", "effect": "寒碑落地追加范围雷击"},
	{"weapons": ["snow_umbrella", "mirror"], "name": "镜雪回光", "effect": "伞面化解弹幕后反射镜光"},
	{"weapons": ["judge_brush", "talisman"], "name": "朱笔判火", "effect": "判词尽头追加符火爆裂"},
	{"weapons": ["soul_lantern", "bell"], "name": "灯钟引渡", "effect": "魂灯扩大并震退周围邪祟"},
]
const ENDLESS_ENEMY_POOL := ["ghost", "paper", "stone", "lantern", "jiangshi", "splitter", "paper_summoner", "revenant", "warden", "algae_drowned", "river_lantern", "headless_boatman", "soul_netter", "leech_medium", "snow_stalker", "ice_coffin", "gale_wraith", "frost_jailer"]
const ENDLESS_ENEMY_MODIFIERS := ["swift", "giant", "warded", "vengeful"]
const ENDLESS_BOSS_MODIFIERS := ["frenzy", "iron", "summoner", "calamity"]

var rng := RandomNumberGenerator.new()
var meta: MetaProgression
var pixel_assets: Dictionary = {}
var state := GameState.READY
var lobby_page := LobbyPage.HOME
var game_paused := false

var arena_size := ARENA_SIZE
var player_position := ARENA_SIZE * 0.5
var player_radius := 21.0
var move_speed := 285.0
var max_health := 100.0
var health := 100.0
var pickup_radius := 62.0
var hurt_timer := 0.0
var player_slow_timer := 0.0
var last_aim_direction := Vector2.RIGHT

var weapon_levels: Dictionary = {"sword": 1}
var passive_levels: Dictionary = {}
var evolved_weapons: Dictionary = {}
var weapon_timers: Dictionary = {}
var orbit_angle := 0.0
var equipment_damage_bonus := 0.0
var equipment_cooldown_bonus := 0.0
var experience_multiplier := 1.0
var loot_luck := 0.0
var damage_reduction := 0.0
var copper_bonus := 0.0
var life_steal := 0.0
var health_regen := 0.0
var life_steal_heal_budget := 0.0
var life_steal_effect_timer := 0.0
var player_walk_phase := 0.0
var player_moving := false

var ability_cooldown := 8.0
var ability_timer := 0.0
var pulse_visual_timer := 0.0
var pulse_origin := Vector2.ZERO

var elapsed := 0.0
var wave := 1
var spawn_timer := 0.0
var stage_event_timer := 18.0
var selected_stage := 0
var selected_endless_mode := false
var endless_mode := false
var endless_wave_started_at := 0.0
var endless_bosses_defeated := 0
var endless_boss_cleared_wave := 0
var endless_extracted := false
var next_enemy_id := 1
var boss_spawned := false
var pending_victory := false
var defeated := 0

var level := 1
var experience := 0
var experience_needed := 6
var pending_upgrades := 0
var choosing_upgrade := false
var upgrade_choices: Array[String] = []
var shopping := false
var run_copper := 0
var shop_rerolls := 0
var shop_goods: Array[Dictionary] = []
var active_run_rules: Dictionary = {}
var emergency_guard_charges := 0
var rebirth_available := false
var shop_free_reroll_available := false

var enemies: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var enemy_projectiles: Array[Dictionary] = []
var xp_orbs: Array[Dictionary] = []
var area_effects: Array[Dictionary] = []
var loot_orbs: Array[Dictionary] = []
var run_loot: Array = []
var run_settled := false
var attack_telegraphs: Array[Dictionary] = []
var run_damage_dealt := 0.0
var run_damage_taken := 0.0
var run_weapon_damage: Dictionary = {}
var run_damage_taken_sources: Dictionary = {}
var current_wave_damage_sources: Dictionary = {}
var wave_records: Array[Dictionary] = []
var wave_start_elapsed := 0.0
var wave_start_damage := 0.0
var wave_start_taken := 0.0
var wave_start_defeated := 0

var camera: Camera2D
var pixel_theme: Theme
var sfx_players: Dictionary = {}
var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var weapon_sfx_last_played: Dictionary = {}
var weapon_sfx_global_time := -100.0
var health_bar: ProgressBar
var xp_bar: ProgressBar
var health_label: Label
var wave_label: Label
var time_label: Label
var level_label: Label
var enemy_label: Label
var ability_label: Label
var build_label: Label
var synergy_label: Label
var copper_label: Label
var banner_label: Label
var boss_health_bar: ProgressBar
var boss_health_label: Label
var banner_timer := 0.0

var ready_overlay: ColorRect
var ready_tint: ColorRect
var stage_overlay: ColorRect
var stage_tint: ColorRect
var stage_buttons: Array[Button] = []
var stage_description_label: Label
var endless_mode_button: Button
var stage_enter_button: Button
var lobby_currency_label: Label
var stage_currency_label: Label
var talent_overlay: ColorRect
var talent_tree_scroll: ScrollContainer
var talent_tree_canvas: Control
var talent_buttons: Dictionary = {}
var talent_currency_label: Label
var talent_detail_label: Label
var talent_upgrade_button: Button
var selected_talent_id := "vitality"
var upgrade_panel: PanelContainer
var upgrade_buttons: Array[Button] = []
var upgrade_synergy_codex: RichTextLabel
var shop_panel: PanelContainer
var shop_buttons: Array[Button] = []
var shop_lock_buttons: Array[CheckButton] = []
var shop_copper_label: Label
var shop_reroll_button: Button
var result_overlay: ColorRect
var result_title: Label
var result_detail: Label
var pause_overlay: ColorRect
var pause_synergy_codex: RichTextLabel
var pause_home_button: Button
var inventory_overlay: ColorRect
var inventory_grid: GridContainer
var inventory_detail_icon: TextureRect
var inventory_detail_label: Label
var inventory_currency_label: Label
var inventory_slot_buttons: Array[Button] = []
var inventory_filter_buttons: Array[Button] = []
var inventory_filter_slot := ""
var selected_item_uid := 0


func _ready() -> void:
	rng.randomize()
	meta = MetaProgression.new()
	pixel_assets = PixelArtFactory.build_assets()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_camera()
	if DisplayServer.get_name() != "headless" and OS.get_environment("ZHENYE_CAPTURE").is_empty():
		_setup_audio()
	_setup_ui()
	_update_hud()
	_refresh_lobby()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if state != GameState.RUNNING or game_paused or choosing_upgrade or shopping:
		return

	elapsed += delta
	hurt_timer = maxf(0.0, hurt_timer - delta)
	player_slow_timer = maxf(0.0, player_slow_timer - delta)
	ability_timer = maxf(0.0, ability_timer - delta)
	pulse_visual_timer = maxf(0.0, pulse_visual_timer - delta)
	life_steal_effect_timer = maxf(0.0, life_steal_effect_timer - delta)
	life_steal_heal_budget = minf(max_health * 0.02, life_steal_heal_budget + max_health * 0.02 * delta)
	if health_regen > 0.0 and health > 0.0:
		health = minf(max_health, health + health_regen * delta)
	banner_timer = maxf(0.0, banner_timer - delta)
	banner_label.visible = banner_timer > 0.0

	_update_wave()
	if shopping:
		_update_hud()
		queue_redraw()
		return
	_update_player(delta)
	_update_spawning(delta)
	_update_stage_events(delta)
	_update_enemies(delta)
	_update_attack_telegraphs(delta)
	_update_weapons(delta)
	_update_projectiles(delta)
	_update_enemy_projectiles(delta)
	_update_xp_orbs(delta)
	_update_loot_orbs(delta)
	_update_area_effects(delta)

	if pending_victory:
		_finish_game(true)
		return
	if health <= 0.0:
		_finish_game(false)
		return
	if pending_upgrades > 0 and not choosing_upgrade:
		_show_upgrade_choices()

	_update_camera(delta)
	_update_hud()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if state == GameState.READY:
			if lobby_page == LobbyPage.STAGES:
				_close_stage_select()
			elif lobby_page == LobbyPage.INVENTORY:
				_close_inventory()
			elif lobby_page == LobbyPage.TALENTS:
				_close_talent_tree()
			else:
				get_tree().quit()
		elif state in [GameState.WON, GameState.LOST]:
			_return_to_lobby()
		else:
			if game_paused:
				_resume_game()
			elif not choosing_upgrade and not shopping:
				_pause_game()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			if state == GameState.READY:
				if lobby_page == LobbyPage.HOME:
					_open_stage_select()
				elif lobby_page == LobbyPage.STAGES:
					_start_game()
			elif state == GameState.RUNNING and not choosing_upgrade:
				_use_pulse()
		if event.keycode == KEY_R and state in [GameState.WON, GameState.LOST]:
			_return_to_lobby()


func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.position = player_position
	camera.zoom = Vector2(PIXEL_CANVAS_SCALE, PIXEL_CANVAS_SCALE)
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(arena_size.x)
	camera.limit_bottom = int(arena_size.y)
	camera.limit_smoothed = true
	add_child(camera)
	camera.make_current()


func _setup_audio() -> void:
	var volumes := {
		"weapon_sword": -19.0,
		"weapon_talisman": -20.0,
		"weapon_thunder": -17.0,
		"weapon_bell": -18.0,
		"weapon_coin": -18.0,
		"weapon_orb": -19.0,
		"weapon_chain": -18.0,
		"weapon_banner": -20.0,
		"weapon_paper_doll": -14.0,
		"weapon_mirror": -20.0,
		"weapon_tide_gourd": -19.0,
		"weapon_ferry_oar": -19.0,
		"weapon_nether_lotus": -20.0,
		"weapon_ice_needles": -19.0,
		"weapon_frost_stele": -18.0,
		"weapon_snow_umbrella": -20.0,
		"weapon_judge_brush": -19.0,
		"weapon_soul_lantern": -20.0,
		"evolution": -11.0,
		"hit": -17.0,
		"death": -13.0,
		"hurt": -9.0,
		"pickup": -18.0,
		"level_up": -9.0,
		"purchase": -10.0,
		"boss": -7.0,
		"menu": -12.0,
	}
	for sound_name in volumes:
		var player := AudioStreamPlayer.new()
		player.stream = pixel_assets["audio"][sound_name]
		player.volume_db = float(volumes[sound_name])
		if sound_name == "weapon_judge_brush":
			player.pitch_scale = 0.82
		elif sound_name == "weapon_soul_lantern":
			player.pitch_scale = 1.16
		player.max_polyphony = 1 if String(sound_name).begins_with("weapon_") else 3
		add_child(player)
		sfx_players[sound_name] = player
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	ambient_player = AudioStreamPlayer.new()
	add_child(ambient_player)


func _play_sfx(sound_name: String) -> void:
	if not sfx_players.has(sound_name):
		return
	var player: AudioStreamPlayer = sfx_players[sound_name]
	if player.playing and sound_name in ["hit", "death", "pickup"]:
		return
	player.play()


func _play_weapon_sfx(weapon: String) -> void:
	if elapsed - weapon_sfx_global_time < 0.16:
		return
	var interval := float(WEAPON_SFX_INTERVALS.get(weapon, 0.6))
	if elapsed - float(weapon_sfx_last_played.get(weapon, -100.0)) < interval:
		return
	weapon_sfx_global_time = elapsed
	weapon_sfx_last_played[weapon] = elapsed
	_play_sfx("weapon_%s" % weapon)


func _start_chapter_audio() -> void:
	if music_player == null or ambient_player == null:
		return
	music_player.stop()
	ambient_player.stop()
	var content_stage := _content_stage_index()
	music_player.stream = pixel_assets["audio"]["stage_music"][content_stage]
	music_player.volume_db = [-23.0, -24.0, -25.0, -24.0, -25.0][content_stage]
	if music_player.stream is AudioStreamOggVorbis:
		music_player.stream.loop = true
	ambient_player.stream = pixel_assets["audio"]["stage_ambient"][content_stage]
	ambient_player.volume_db = [-32.0, -34.0, -36.0, -34.0, -36.0][content_stage]
	if ambient_player.stream is AudioStreamWAV:
		ambient_player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music_player.play()
	ambient_player.play()


func _build_pixel_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = load("res://assets/fonts/fusion-pixel-12px-zh_hans.ttf")
	theme.default_font_size = 24
	theme.set_stylebox("normal", "Button", _pixel_texture_box(pixel_assets["ui"]["button_normal"], 2.0, 10.0))
	theme.set_stylebox("hover", "Button", _pixel_texture_box(pixel_assets["ui"]["button_hover"], 2.0, 10.0))
	theme.set_stylebox("pressed", "Button", _pixel_texture_box(pixel_assets["ui"]["button_pressed"], 2.0, 10.0))
	theme.set_stylebox("disabled", "Button", _pixel_texture_box(pixel_assets["ui"]["button_disabled"], 2.0, 10.0))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", Color("442819"))
	theme.set_color("font_hover_color", "Button", Color("2b1a12"))
	theme.set_color("font_pressed_color", "Button", Color("fff4cf"))
	theme.set_color("font_disabled_color", "Button", Color("786d59"))
	theme.set_stylebox("panel", "PanelContainer", _pixel_texture_box(pixel_assets["ui"]["panel"], 5.0, 14.0))
	theme.set_stylebox("background", "ProgressBar", _pixel_style_box(Color("15130f"), Color("4d402d"), 2))
	theme.set_stylebox("fill", "ProgressBar", _pixel_style_box(Color("67c9a5"), Color("a5e4c9"), 1))
	theme.set_color("font_color", "CheckButton", Color("d9cba9"))
	theme.set_color("font_hover_color", "CheckButton", Color("f0dfb0"))
	theme.set_constant("outline_size", "Label", 0)
	theme.set_constant("outline_size", "Button", 0)
	return theme


func _pixel_texture_box(texture: Texture2D, margin: float, content_margin: float) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = texture
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_texture_margin(side, margin)
		box.set_content_margin(side, content_margin)
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	return box


func _pixel_style_box(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.border_width_left = width
	box.border_width_top = width
	box.border_width_right = width
	box.border_width_bottom = width
	box.corner_radius_top_left = 0
	box.corner_radius_top_right = 0
	box.corner_radius_bottom_left = 0
	box.corner_radius_bottom_right = 0
	box.content_margin_left = 10.0
	box.content_margin_top = 8.0
	box.content_margin_right = 10.0
	box.content_margin_bottom = 8.0
	return box


func _setup_ui() -> void:
	pixel_theme = _build_pixel_theme()
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	canvas.transform = Transform2D(Vector2(PIXEL_CANVAS_SCALE, 0.0), Vector2(0.0, PIXEL_CANVAS_SCALE), Vector2.ZERO)
	add_child(canvas)

	var hud := Control.new()
	_place_control(hud, 0, 0, VIEW_SIZE.x, VIEW_SIZE.y)
	hud.theme = pixel_theme
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hud)

	var top_strip := ColorRect.new()
	top_strip.color = Color(0.07, 0.055, 0.035, 0.94)
	_place_control(top_strip, 0, 0, 1280, 78)
	hud.add_child(top_strip)

	health_label = _make_label("生命", 18, Color.WHITE)
	_place_control(health_label, 28, 15, 250, 24)
	hud.add_child(health_label)
	health_bar = ProgressBar.new()
	health_bar.show_percentage = false
	health_bar.max_value = 100.0
	_place_control(health_bar, 28, 43, 250, 13)
	hud.add_child(health_bar)

	wave_label = _make_label("第 1 波", 22, Color("ead8a6"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(wave_label, 475, 12, 330, 28)
	hud.add_child(wave_label)
	time_label = _make_label("00:00", 17, Color("a99875"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(time_label, 475, 42, 330, 22)
	hud.add_child(time_label)
	copper_label = _make_label("铜钱 0", 17, Color("d6a84d"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(copper_label, 820, 25, 160, 26)
	hud.add_child(copper_label)

	level_label = _make_label("等级 1", 18, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	_place_control(level_label, 1000, 15, 250, 24)
	hud.add_child(level_label)
	xp_bar = ProgressBar.new()
	xp_bar.show_percentage = false
	xp_bar.max_value = experience_needed
	_place_control(xp_bar, 1000, 43, 250, 13)
	hud.add_child(xp_bar)

	enemy_label = _make_label("镇伏 0", 16, Color("b6a681"))
	_place_control(enemy_label, 28, 676, 260, 24)
	hud.add_child(enemy_label)
	ability_label = _make_label("空格键  镇魂阵已就绪", 16, COLOR_PLAYER, HORIZONTAL_ALIGNMENT_RIGHT)
	_place_control(ability_label, 910, 676, 340, 24)
	hud.add_child(ability_label)
	build_label = _make_label("法器：飞剑 一阶", 13, Color("d7c188"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(build_label, 310, 676, 660, 24)
	hud.add_child(build_label)
	synergy_label = _make_label("", 13, Color("a9d8ce"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(synergy_label, 360, 646, 560, 24)
	hud.add_child(synergy_label)

	boss_health_label = _make_label("", 16, Color("f0b39d"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(boss_health_label, 430, 82, 420, 26)
	hud.add_child(boss_health_label)
	boss_health_bar = ProgressBar.new()
	boss_health_bar.show_percentage = false
	boss_health_bar.add_theme_stylebox_override("background", _pixel_style_box(Color("1c1110"), Color("704137"), 2))
	boss_health_bar.add_theme_stylebox_override("fill", _pixel_style_box(Color("b93631"), Color("f06b4f"), 1))
	_place_control(boss_health_bar, 430, 109, 420, 13)
	hud.add_child(boss_health_bar)
	boss_health_label.hide()
	boss_health_bar.hide()

	banner_label = _make_label("第 1 波", 38, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	banner_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	banner_label.add_theme_constant_override("shadow_offset_x", 3)
	banner_label.add_theme_constant_override("shadow_offset_y", 3)
	_place_control(banner_label, 390, 138, 500, 58)
	hud.add_child(banner_label)

	_setup_ready_overlay(canvas)
	_setup_stage_overlay(canvas)
	_setup_talent_overlay(canvas)
	_setup_upgrade_panel(canvas)
	_setup_shop_panel(canvas)
	_setup_result_overlay(canvas)
	_setup_inventory_overlay(canvas)
	_setup_pause_overlay(canvas)


func _setup_ready_overlay(canvas: CanvasLayer) -> void:
	ready_overlay = ColorRect.new()
	ready_overlay.theme = pixel_theme
	ready_overlay.color = Color.TRANSPARENT
	_place_control(ready_overlay, 0, 0, 1280, 720)
	canvas.add_child(ready_overlay)

	var background := TextureRect.new()
	background.texture = pixel_assets["menu_background"]
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.modulate = Color("a5b2ac")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(background, 0, 0, 1280, 720)
	ready_overlay.add_child(background)

	ready_tint = ColorRect.new()
	ready_tint.color = Color(0.018, 0.027, 0.035, 0.46)
	ready_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(ready_tint, 0, 0, 1280, 720)
	ready_overlay.add_child(ready_tint)

	var atmosphere := Control.new()
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(atmosphere, 0, 0, 1280, 720)
	atmosphere.draw.connect(_draw_lobby_atmosphere.bind(atmosphere))
	ready_overlay.add_child(atmosphere)

	var top_rule := ColorRect.new()
	top_rule.color = Color("9c3e2f")
	top_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(top_rule, 0, 0, 1280, 6)
	ready_overlay.add_child(top_rule)

	var eyebrow := _make_label("东方志怪 · 生存镇邪", 17, COLOR_PLAYER)
	_place_control(eyebrow, 90, 106, 520, 32)
	ready_overlay.add_child(eyebrow)
	var title := _make_label("镇 夜 录", 60, Color("f5e6bc"))
	title.add_theme_color_override("font_shadow_color", Color(0.03, 0.02, 0.015, 0.95))
	title.add_theme_constant_override("shadow_offset_x", 5)
	title.add_theme_constant_override("shadow_offset_y", 5)
	_place_control(title, 84, 142, 610, 94)
	ready_overlay.add_child(title)
	var subtitle := _make_label("孤灯照夜，万邪退散。", 20, Color("c6b48b"))
	_place_control(subtitle, 92, 235, 520, 36)
	ready_overlay.add_child(subtitle)

	var lore_panel := PanelContainer.new()
	lore_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(lore_panel, 82, 304, 500, 145)
	ready_overlay.add_child(lore_panel)
	var lore := _make_label("夜幕降临，百鬼离巢。\n你是道观最后的镇夜人，携诸般法器踏入五处凶地，\n以残魂养术，以铜钱换命。", 16, Color("d8c9a5"))
	lore.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lore.custom_minimum_size = Vector2(470, 120)
	lore_panel.add_child(lore)

	var hero := TextureRect.new()
	hero.texture = pixel_assets["player"][0]
	hero.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(hero, 522, 335, 230, 230)
	ready_overlay.add_child(hero)
	var ghost := TextureRect.new()
	ghost.texture = pixel_assets["enemies"]["ghost"][0]
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.modulate = Color(0.75, 0.88, 0.9, 0.72)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(ghost, 685, 410, 130, 130)
	ready_overlay.add_child(ghost)

	var menu_panel := PanelContainer.new()
	menu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(menu_panel, 830, 150, 360, 430)
	ready_overlay.add_child(menu_panel)
	var menu_title := _make_label("道 观 夜 签", 24, Color("ead8a6"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(menu_title, 865, 190, 290, 40)
	ready_overlay.add_child(menu_title)
	var menu_rule := ColorRect.new()
	menu_rule.color = Color("8f3b2f")
	menu_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(menu_rule, 900, 239, 220, 4)
	ready_overlay.add_child(menu_rule)

	var start_button := Button.new()
	start_button.text = "开始镇夜"
	start_button.add_theme_font_size_override("font_size", _pixel_font_size(21))
	_place_control(start_button, 875, 260, 270, 58)
	start_button.pressed.connect(_open_stage_select)
	ready_overlay.add_child(start_button)
	var talent_button := Button.new()
	talent_button.text = "道行命盘"
	talent_button.add_theme_font_size_override("font_size", _pixel_font_size(18))
	_place_control(talent_button, 875, 330, 270, 56)
	talent_button.pressed.connect(_open_talent_tree)
	ready_overlay.add_child(talent_button)
	var inventory_button := Button.new()
	inventory_button.text = "整备行囊"
	inventory_button.add_theme_font_size_override("font_size", _pixel_font_size(18))
	_place_control(inventory_button, 875, 398, 270, 56)
	inventory_button.pressed.connect(_open_inventory)
	ready_overlay.add_child(inventory_button)
	var exit_button := Button.new()
	exit_button.text = "离开道观"
	exit_button.add_theme_font_size_override("font_size", _pixel_font_size(17))
	_place_control(exit_button, 875, 466, 270, 52)
	exit_button.pressed.connect(_quit_game)
	ready_overlay.add_child(exit_button)
	lobby_currency_label = _make_label("", 15, Color("d8bd74"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(lobby_currency_label, 850, 536, 320, 32)
	ready_overlay.add_child(lobby_currency_label)

	var controls := _make_label("WASD / 方向键移动   ·   空格键施放镇魂阵", 15, Color("9fb4ad"))
	_place_control(controls, 88, 625, 660, 28)
	ready_overlay.add_child(controls)
	var hint := _make_label("按空格键翻开章节册", 14, Color("718c99"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(hint, 870, 595, 280, 32)
	ready_overlay.add_child(hint)


func _setup_stage_overlay(canvas: CanvasLayer) -> void:
	stage_overlay = ColorRect.new()
	stage_overlay.theme = pixel_theme
	stage_overlay.color = Color.TRANSPARENT
	_place_control(stage_overlay, 0, 0, 1280, 720)
	canvas.add_child(stage_overlay)

	var background := TextureRect.new()
	background.texture = pixel_assets["menu_background"]
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.modulate = Color("71807c")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(background, 0, 0, 1280, 720)
	stage_overlay.add_child(background)
	stage_tint = ColorRect.new()
	stage_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(stage_tint, 0, 0, 1280, 720)
	stage_overlay.add_child(stage_tint)

	var top_strip := ColorRect.new()
	top_strip.color = Color(0.035, 0.03, 0.025, 0.92)
	top_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(top_strip, 0, 0, 1280, 92)
	stage_overlay.add_child(top_strip)
	var back_button := Button.new()
	back_button.text = "返回主页"
	_place_control(back_button, 38, 24, 170, 48)
	back_button.pressed.connect(_close_stage_select)
	stage_overlay.add_child(back_button)
	var title := _make_label("镇 夜 行 卷", 34, Color("f0dfb0"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(title, 390, 20, 500, 58)
	stage_overlay.add_child(title)
	stage_currency_label = _make_label("", 15, Color("d8bd74"), HORIZONTAL_ALIGNMENT_RIGHT)
	_place_control(stage_currency_label, 925, 32, 315, 30)
	stage_overlay.add_child(stage_currency_label)

	for index in STAGE_DATA.size():
		var stage_button := Button.new()
		stage_button.add_theme_font_size_override("font_size", _pixel_font_size(18))
		stage_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var column := index % 3
		var row := floori(float(index) / 3.0)
		_place_control(stage_button, 92 + column * 370, 118 + row * 200, 356, 188)
		stage_button.pressed.connect(_select_stage.bind(index))
		stage_overlay.add_child(stage_button)
		stage_buttons.append(stage_button)

	var description_panel := PanelContainer.new()
	description_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(description_panel, 155, 525, 970, 76)
	stage_overlay.add_child(description_panel)
	stage_description_label = _make_label("", 16, Color("d8c9a5"), HORIZONTAL_ALIGNMENT_CENTER)
	stage_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stage_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stage_description_label.custom_minimum_size = Vector2(940, 54)
	description_panel.add_child(stage_description_label)

	endless_mode_button = Button.new()
	endless_mode_button.add_theme_font_size_override("font_size", _pixel_font_size(18))
	_place_control(endless_mode_button, 325, 625, 300, 62)
	endless_mode_button.pressed.connect(_toggle_endless_mode)
	stage_overlay.add_child(endless_mode_button)
	stage_enter_button = Button.new()
	stage_enter_button.add_theme_font_size_override("font_size", _pixel_font_size(20))
	_place_control(stage_enter_button, 655, 625, 300, 62)
	stage_enter_button.pressed.connect(_start_game)
	stage_overlay.add_child(stage_enter_button)
	stage_overlay.hide()
	_select_stage(0)


func _setup_talent_overlay(canvas: CanvasLayer) -> void:
	talent_overlay = ColorRect.new()
	talent_overlay.theme = pixel_theme
	talent_overlay.color = Color.TRANSPARENT
	_place_control(talent_overlay, 0, 0, 1280, 720)
	canvas.add_child(talent_overlay)

	var background := TextureRect.new()
	background.texture = pixel_assets["floors"][2]
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.modulate = Color("4b5551")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(background, 0, 0, 1280, 720)
	talent_overlay.add_child(background)
	var tint := ColorRect.new()
	tint.color = Color(0.025, 0.03, 0.035, 0.84)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(tint, 0, 0, 1280, 720)
	talent_overlay.add_child(tint)
	var top_strip := ColorRect.new()
	top_strip.color = Color(0.035, 0.03, 0.025, 0.94)
	top_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(top_strip, 0, 0, 1280, 82)
	talent_overlay.add_child(top_strip)

	var back_button := Button.new()
	back_button.text = "返回主页"
	_place_control(back_button, 36, 20, 170, 48)
	back_button.pressed.connect(_close_talent_tree)
	talent_overlay.add_child(back_button)
	var title := _make_label("道 行 命 盘", 34, Color("f0dfb0"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(title, 390, 4, 500, 54)
	talent_overlay.add_child(title)
	var scroll_hint := _make_label("滚轮上下浏览 · 拖动底部横条左右移动", 14, Color("948a72"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(scroll_hint, 340, 55, 600, 28)
	talent_overlay.add_child(scroll_hint)
	talent_currency_label = _make_label("", 16, Color("e2bb61"), HORIZONTAL_ALIGNMENT_RIGHT)
	_place_control(talent_currency_label, 970, 30, 270, 30)
	talent_overlay.add_child(talent_currency_label)

	talent_tree_scroll = ScrollContainer.new()
	talent_tree_scroll.follow_focus = true
	_place_control(talent_tree_scroll, 24, 94, 1232, 492)
	talent_overlay.add_child(talent_tree_scroll)

	talent_tree_canvas = Control.new()
	talent_tree_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	talent_tree_canvas.custom_minimum_size = TALENT_CANVAS_SIZE
	_place_control(talent_tree_canvas, 0, 0, TALENT_CANVAS_SIZE.x, TALENT_CANVAS_SIZE.y)
	talent_tree_canvas.draw.connect(_draw_talent_connections.bind(talent_tree_canvas))
	talent_tree_scroll.add_child(talent_tree_canvas)

	for talent_id in MetaProgression.TALENT_ORDER:
		var button := Button.new()
		button.add_theme_font_size_override("font_size", _pixel_font_size(20))
		button.add_theme_constant_override("outline_size", 2)
		button.add_theme_color_override("font_outline_color", Color("0b0c0d"))
		button.icon = _talent_icon(talent_id)
		button.clip_text = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_select_talent.bind(talent_id))
		var position: Vector2 = TALENT_NODE_POSITIONS[talent_id]
		_place_control(button, position.x, position.y, TALENT_NODE_SIZE.x, TALENT_NODE_SIZE.y)
		talent_tree_canvas.add_child(button)
		talent_buttons[talent_id] = button

	var detail_panel := PanelContainer.new()
	_place_control(detail_panel, 36, 600, 910, 98)
	talent_overlay.add_child(detail_panel)
	talent_detail_label = _make_label("", 18, Color("efe2bd"))
	talent_detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	talent_detail_label.custom_minimum_size = Vector2(880, 74)
	detail_panel.add_child(talent_detail_label)
	talent_upgrade_button = Button.new()
	talent_upgrade_button.add_theme_font_size_override("font_size", _pixel_font_size(18))
	_place_control(talent_upgrade_button, 966, 610, 278, 78)
	talent_upgrade_button.pressed.connect(_upgrade_selected_talent)
	talent_overlay.add_child(talent_upgrade_button)
	talent_overlay.hide()


func _setup_upgrade_panel(canvas: CanvasLayer) -> void:
	upgrade_panel = PanelContainer.new()
	upgrade_panel.theme = pixel_theme
	_place_control(upgrade_panel, 180, 34, 920, 652)
	canvas.add_child(upgrade_panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	upgrade_panel.add_child(content)
	var title := _make_label("择 法 修 行", 30, Color("f0dfb0"), HORIZONTAL_ALIGNMENT_CENTER)
	title.custom_minimum_size.y = 54
	content.add_child(title)
	var subtitle := _make_label("选择一门法器或心法，抉择期间万物凝滞。", 16, Color("a99875"), HORIZONTAL_ALIGNMENT_CENTER)
	subtitle.custom_minimum_size.y = 30
	content.add_child(subtitle)

	var choices := HBoxContainer.new()
	choices.add_theme_constant_override("separation", 14)
	choices.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(choices)
	for index in 3:
		var button := Button.new()
		button.custom_minimum_size = Vector2(238, 188)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", _pixel_font_size(17))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_on_upgrade_pressed.bind(index))
		choices.add_child(button)
		upgrade_buttons.append(button)
	var synergy_title := _make_label("法器联动图鉴 · 双方三阶激活 · 滚轮查看", 17, Color("e4c982"), HORIZONTAL_ALIGNMENT_CENTER)
	synergy_title.custom_minimum_size.y = 32
	content.add_child(synergy_title)
	upgrade_synergy_codex = _make_synergy_codex_label()
	upgrade_synergy_codex.custom_minimum_size.y = 245
	content.add_child(upgrade_synergy_codex)
	upgrade_panel.hide()


func _setup_shop_panel(canvas: CanvasLayer) -> void:
	shop_panel = PanelContainer.new()
	shop_panel.theme = pixel_theme
	_place_control(shop_panel, 150, 105, 980, 515)
	canvas.add_child(shop_panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	shop_panel.add_child(content)
	var title := _make_label("鬼 市", 31, Color("f0dfb0"), HORIZONTAL_ALIGNMENT_CENTER)
	title.custom_minimum_size.y = 48
	content.add_child(title)
	shop_copper_label = _make_label("持有铜钱：0", 17, Color("d6a84d"), HORIZONTAL_ALIGNMENT_CENTER)
	shop_copper_label.custom_minimum_size.y = 28
	content.add_child(shop_copper_label)
	var goods_row := HBoxContainer.new()
	goods_row.add_theme_constant_override("separation", 12)
	goods_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(goods_row)
	for index in 4:
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(222, 305)
		var button := Button.new()
		button.custom_minimum_size = Vector2(222, 258)
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", _pixel_font_size(16))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(_buy_shop_good.bind(index))
		card.add_child(button)
		shop_buttons.append(button)
		var lock_button := CheckButton.new()
		lock_button.text = "锁定此物"
		lock_button.add_theme_font_size_override("font_size", _pixel_font_size(14))
		card.add_child(lock_button)
		shop_lock_buttons.append(lock_button)
		goods_row.add_child(card)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 18)
	content.add_child(actions)
	shop_reroll_button = Button.new()
	shop_reroll_button.custom_minimum_size = Vector2(220, 46)
	shop_reroll_button.pressed.connect(_reroll_shop)
	actions.add_child(shop_reroll_button)
	var continue_button := Button.new()
	continue_button.text = "离开鬼市，继续镇守"
	continue_button.custom_minimum_size = Vector2(260, 46)
	continue_button.pressed.connect(_close_shop)
	actions.add_child(continue_button)
	shop_panel.hide()


func _setup_result_overlay(canvas: CanvasLayer) -> void:
	result_overlay = ColorRect.new()
	result_overlay.theme = pixel_theme
	result_overlay.color = Color(0.055, 0.045, 0.03, 0.95)
	_place_control(result_overlay, 0, 0, 1280, 720)
	canvas.add_child(result_overlay)

	result_title = _make_label("试玩结束", 52, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(result_title, 290, 215, 700, 70)
	result_overlay.add_child(result_title)
	result_detail = _make_label("", 20, Color("c6b893"), HORIZONTAL_ALIGNMENT_CENTER)
	result_detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(result_detail, 290, 292, 700, 145)
	result_overlay.add_child(result_detail)
	var restart_button := Button.new()
	restart_button.text = "返回道观"
	restart_button.add_theme_font_size_override("font_size", _pixel_font_size(20))
	_place_control(restart_button, 500, 455, 280, 58)
	restart_button.pressed.connect(_return_to_lobby)
	result_overlay.add_child(restart_button)
	var hint := _make_label("整备装备后可再次进入章节", 14, Color("6f86a3"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(hint, 500, 525, 280, 24)
	result_overlay.add_child(hint)
	result_overlay.hide()


func _setup_inventory_overlay(canvas: CanvasLayer) -> void:
	inventory_overlay = ColorRect.new()
	inventory_overlay.theme = pixel_theme
	inventory_overlay.color = Color.TRANSPARENT
	_place_control(inventory_overlay, 0, 0, 1280, 720)
	canvas.add_child(inventory_overlay)

	var background := TextureRect.new()
	background.texture = pixel_assets["floors"][2]
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.modulate = Color("66544e")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(background, 0, 0, 1280, 720)
	inventory_overlay.add_child(background)
	var tint := ColorRect.new()
	tint.color = Color(0.035, 0.027, 0.022, 0.82)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(tint, 0, 0, 1280, 720)
	inventory_overlay.add_child(tint)
	var top_strip := ColorRect.new()
	top_strip.color = Color(0.055, 0.042, 0.03, 0.94)
	top_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(top_strip, 0, 0, 1280, 78)
	inventory_overlay.add_child(top_strip)

	var title := _make_label("道 观 · 行 囊 整 备", 32, Color("f0dfb0"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(title, 360, 24, 560, 48)
	inventory_overlay.add_child(title)
	inventory_currency_label = _make_label("", 15, Color("d7c188"), HORIZONTAL_ALIGNMENT_RIGHT)
	_place_control(inventory_currency_label, 900, 30, 340, 30)
	inventory_overlay.add_child(inventory_currency_label)
	var close_button := Button.new()
	close_button.text = "返回主页"
	_place_control(close_button, 35, 22, 165, 46)
	close_button.pressed.connect(_close_inventory)
	inventory_overlay.add_child(close_button)

	var slots_title := _make_label("已穿戴", 20, Color("d9cba9"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(slots_title, 35, 86, 245, 32)
	inventory_overlay.add_child(slots_title)
	for index in MetaProgression.SLOT_ORDER.size():
		var slot_button := Button.new()
		slot_button.add_theme_font_size_override("font_size", _pixel_font_size(15))
		slot_button.add_theme_stylebox_override("normal", _pixel_style_box(Color("252019"), Color("64513a"), 2))
		slot_button.add_theme_stylebox_override("hover", _pixel_style_box(Color("382b20"), Color("b4783d"), 3))
		slot_button.add_theme_stylebox_override("pressed", _pixel_style_box(Color("4a2d1f"), Color("d69a50"), 3))
		slot_button.add_theme_color_override("font_color", Color("d9cba9"))
		slot_button.add_theme_color_override("font_hover_color", Color("f4dfa9"))
		slot_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		slot_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_place_control(slot_button, 35, 124 + index * 74, 245, 62)
		var slot: String = MetaProgression.SLOT_ORDER[index]
		slot_button.pressed.connect(_select_equipped_slot.bind(slot))
		inventory_overlay.add_child(slot_button)
		inventory_slot_buttons.append(slot_button)

	var bag_title := _make_label("行囊", 20, Color("d9cba9"))
	_place_control(bag_title, 318, 86, 82, 32)
	inventory_overlay.add_child(bag_title)
	var filter_slots: Array[String] = ["", "weapon", "head", "robe", "belt", "boots", "charm"]
	for index in filter_slots.size():
		var filter_slot := filter_slots[index]
		var filter_button := Button.new()
		filter_button.add_theme_font_size_override("font_size", _pixel_font_size(13))
		filter_button.add_theme_stylebox_override("normal", _pixel_style_box(Color("201c17"), Color("554938"), 1))
		filter_button.add_theme_stylebox_override("hover", _pixel_style_box(Color("39291e"), Color("b4783d"), 2))
		filter_button.add_theme_stylebox_override("pressed", _pixel_style_box(Color("4a2d1f"), Color("d6a84d"), 2))
		filter_button.add_theme_color_override("font_color", Color("bfb293"))
		filter_button.add_theme_color_override("font_hover_color", Color("f4dfa9"))
		_place_control(filter_button, 400 + index * 116, 82, 106, 36)
		filter_button.pressed.connect(_set_inventory_filter.bind(filter_slot))
		inventory_overlay.add_child(filter_button)
		inventory_filter_buttons.append(filter_button)
	var scroll := ScrollContainer.new()
	_place_control(scroll, 310, 122, 930, 342)
	inventory_overlay.add_child(scroll)
	inventory_grid = GridContainer.new()
	inventory_grid.columns = 3
	inventory_grid.add_theme_constant_override("h_separation", 10)
	inventory_grid.add_theme_constant_override("v_separation", 10)
	inventory_grid.custom_minimum_size = Vector2(900, 360)
	scroll.add_child(inventory_grid)

	var detail_panel := PanelContainer.new()
	_place_control(detail_panel, 310, 480, 650, 210)
	inventory_overlay.add_child(detail_panel)
	var detail_content := HBoxContainer.new()
	detail_content.add_theme_constant_override("separation", 16)
	detail_panel.add_child(detail_content)
	inventory_detail_icon = TextureRect.new()
	inventory_detail_icon.custom_minimum_size = Vector2(112, 178)
	inventory_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	inventory_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	inventory_detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	inventory_detail_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_content.add_child(inventory_detail_icon)
	inventory_detail_label = _make_label("选择一件装备查看详情", 16, Color("d9cba9"))
	inventory_detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inventory_detail_label.custom_minimum_size = Vector2(480, 178)
	inventory_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_content.add_child(inventory_detail_label)

	var equip_button := Button.new()
	equip_button.text = "穿戴"
	_place_control(equip_button, 990, 530, 220, 44)
	equip_button.pressed.connect(_equip_selected_item)
	inventory_overlay.add_child(equip_button)
	var upgrade_button := Button.new()
	upgrade_button.text = "强化（消耗器魄）"
	_place_control(upgrade_button, 990, 585, 220, 44)
	upgrade_button.pressed.connect(_upgrade_selected_item)
	inventory_overlay.add_child(upgrade_button)
	var dismantle_button := Button.new()
	dismantle_button.text = "分解为器魄"
	_place_control(dismantle_button, 990, 640, 220, 44)
	dismantle_button.pressed.connect(_dismantle_selected_item)
	inventory_overlay.add_child(dismantle_button)
	inventory_overlay.hide()


func _setup_pause_overlay(canvas: CanvasLayer) -> void:
	pause_overlay = ColorRect.new()
	pause_overlay.theme = pixel_theme
	pause_overlay.color = Color(0.015, 0.018, 0.02, 0.82)
	_place_control(pause_overlay, 0, 0, 1280, 720)
	canvas.add_child(pause_overlay)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(panel, 120, 70, 1040, 580)
	pause_overlay.add_child(panel)
	var title := _make_label("夜 巡 暂 止", 36, Color("f0dfb0"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(title, 160, 98, 960, 60)
	pause_overlay.add_child(title)
	var subtitle := _make_label("风止灯凝，万邪暂歇", 16, Color("93afa4"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(subtitle, 160, 160, 960, 32)
	pause_overlay.add_child(subtitle)
	var codex_panel := PanelContainer.new()
	_place_control(codex_panel, 160, 205, 600, 435)
	pause_overlay.add_child(codex_panel)
	var codex_content := VBoxContainer.new()
	codex_content.add_theme_constant_override("separation", 8)
	codex_panel.add_child(codex_content)
	var codex_title := _make_label("法器联动图鉴 · 滚轮查看", 19, Color("e4c982"), HORIZONTAL_ALIGNMENT_CENTER)
	codex_title.custom_minimum_size.y = 40
	codex_content.add_child(codex_title)
	pause_synergy_codex = _make_synergy_codex_label()
	pause_synergy_codex.custom_minimum_size.y = 355
	codex_content.add_child(pause_synergy_codex)
	var resume_button := Button.new()
	resume_button.text = "继续镇守"
	resume_button.add_theme_font_size_override("font_size", _pixel_font_size(20))
	_place_control(resume_button, 820, 245, 280, 62)
	resume_button.pressed.connect(_resume_game)
	pause_overlay.add_child(resume_button)
	pause_home_button = Button.new()
	pause_home_button.text = "返回主页"
	pause_home_button.add_theme_font_size_override("font_size", _pixel_font_size(18))
	_place_control(pause_home_button, 820, 345, 280, 58)
	pause_home_button.pressed.connect(_leave_current_run)
	pause_overlay.add_child(pause_home_button)
	var exit_button := Button.new()
	exit_button.text = "退出游戏"
	exit_button.add_theme_font_size_override("font_size", _pixel_font_size(17))
	_place_control(exit_button, 820, 441, 280, 56)
	exit_button.pressed.connect(_quit_game)
	pause_overlay.add_child(exit_button)
	var hint := _make_label("再次按 ESC 继续", 14, Color("718c99"), HORIZONTAL_ALIGNMENT_CENTER)
	_place_control(hint, 810, 535, 300, 30)
	pause_overlay.add_child(hint)
	pause_overlay.hide()


func _make_label(text_value: String, font_size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", _pixel_font_size(font_size))
	label.add_theme_color_override("font_color", color)
	return label


func _make_synergy_codex_label() -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = false
	label.scroll_active = true
	label.selection_enabled = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("normal_font_size", _pixel_font_size(14))
	label.add_theme_font_size_override("bold_font_size", _pixel_font_size(14))
	label.add_theme_constant_override("line_separation", 3)
	return label


func _pixel_font_size(requested_size: int) -> int:
	if requested_size >= 45:
		return 72
	if requested_size >= 28:
		return 48
	return 24


func _place_control(control: Control, x: float, y: float, width: float, height: float) -> void:
	control.position = Vector2(x, y)
	control.size = Vector2(width, height)


func _draw_lobby_atmosphere(canvas: Control) -> void:
	var moon_position := Vector2(1005, 106)
	canvas.draw_circle(moon_position, 78.0, Color(0.65, 0.15, 0.11, 0.78))
	canvas.draw_circle(moon_position, 66.0, Color(0.82, 0.28, 0.17, 0.35))
	canvas.draw_circle(moon_position + Vector2(-22, 9), 13.0, Color(0.25, 0.06, 0.055, 0.2))
	canvas.draw_circle(moon_position + Vector2(24, -19), 8.0, Color(0.25, 0.06, 0.055, 0.18))
	for index in 5:
		var y := 76.0 + index * 104.0
		var x := 610.0 + (index % 2) * 70.0
		canvas.draw_line(Vector2(x, y), Vector2(x + 190, y), Color(0.58, 0.72, 0.7, 0.08), 8.0)
		canvas.draw_line(Vector2(x + 62, y + 13), Vector2(x + 260, y + 13), Color(0.58, 0.72, 0.7, 0.055), 5.0)
	canvas.draw_rect(Rect2(72, 278, 520, 3), Color(0.58, 0.23, 0.18, 0.8))
	canvas.draw_rect(Rect2(0, 674, 1280, 46), Color(0.018, 0.02, 0.022, 0.72))


func _stage_data() -> Dictionary:
	return STAGE_DATA[_content_stage_index()]


func _content_stage_index() -> int:
	if endless_mode:
		return (selected_stage + floori(float(maxi(0, wave - 1)) / float(ENDLESS_BOSS_INTERVAL))) % STAGE_DATA.size()
	return selected_stage


func _endless_cycle() -> int:
	return floori(float(maxi(0, wave - 1)) / float(ENDLESS_BOSS_INTERVAL)) if endless_mode else 0


func _is_boss_wave(wave_number: int) -> bool:
	return wave_number % ENDLESS_BOSS_INTERVAL == 0 if endless_mode else wave_number == _boss_wave()


func _boss_wave() -> int:
	return int(STAGE_DATA[selected_stage]["waves"]) + 1


func _wave_duration() -> float:
	return float(_stage_data()["duration"])


func _wave_progress() -> float:
	if endless_mode:
		return clampf(float((wave - 1) % ENDLESS_BOSS_INTERVAL) / float(ENDLESS_BOSS_INTERVAL - 1), 0.0, 1.0)
	return clampf(float(wave - 1) / float(maxi(1, _boss_wave() - 2)), 0.0, 1.0)


func _current_spawn_interval() -> float:
	var pressure := pow(_wave_progress(), 2.0)
	var cycle_pressure := 1.0 + _endless_cycle() * 0.1
	return maxf(0.14, lerpf(1.12, 0.22, pressure) / (float(_stage_data()["spawn_rate"]) * cycle_pressure))


func _extra_spawn_chance() -> float:
	return minf(0.72, lerpf(0.04, 0.5, pow(_wave_progress(), 2.0)) + _endless_cycle() * 0.035)


func _enemy_hp_curve() -> float:
	return lerpf(0.82, 1.72, pow(_wave_progress(), 1.9)) * (1.0 + _endless_cycle() * 0.34)


func _enemy_damage_curve() -> float:
	return lerpf(0.72, 1.4, pow(_wave_progress(), 1.8)) * (1.0 + _content_stage_index() * 0.08) * (1.0 + _endless_cycle() * 0.18)


func _enemy_speed_curve() -> float:
	return minf(1.78, lerpf(0.94, 1.4, pow(_wave_progress(), 1.8)) * (1.0 + _endless_cycle() * 0.035))


func _select_stage(index: int) -> void:
	selected_stage = clampi(index, 0, STAGE_DATA.size() - 1)
	var chapter_names: Array[String] = ["第壹章", "第贰章", "第叁章", "第肆章", "第伍章"]
	var card_fills: Array[Color] = [Color("2d271b"), Color("1d2b2c"), Color("321d1a"), Color("173333"), Color("273441")]
	var card_borders: Array[Color] = [Color("9b7642"), Color("66878a"), Color("a8503e"), Color("58a39a"), Color("88a8bd")]
	for button_index in stage_buttons.size():
		var data: Dictionary = STAGE_DATA[button_index]
		var is_selected := button_index == selected_stage
		var marker: String = "◆ 已选此卷" if button_index == selected_stage else chapter_names[button_index]
		stage_buttons[button_index].text = "%s\n\n%s\n\n镇守 %d 波\n终关 · %s" % [marker, data["name"], data["waves"], data["boss_name"]]
		stage_buttons[button_index].add_theme_stylebox_override("normal", _pixel_style_box(card_fills[button_index].lightened(0.08) if is_selected else card_fills[button_index], card_borders[button_index].lightened(0.22) if is_selected else card_borders[button_index], 4 if is_selected else 2))
		stage_buttons[button_index].add_theme_stylebox_override("hover", _pixel_style_box(card_fills[button_index].lightened(0.12), card_borders[button_index].lightened(0.28), 4))
		stage_buttons[button_index].add_theme_stylebox_override("pressed", _pixel_style_box(card_fills[button_index].lightened(0.18), Color("f0c776"), 4))
		stage_buttons[button_index].add_theme_color_override("font_color", Color("dfd1ad"))
		stage_buttons[button_index].add_theme_color_override("font_hover_color", Color("fff0c4"))
		stage_buttons[button_index].add_theme_color_override("font_pressed_color", Color("fff4cf"))
	var selected_data: Dictionary = STAGE_DATA[selected_stage]
	if selected_endless_mode:
		stage_description_label.text = "无尽轮回 · 6000×4000 · 每 5 波迎战首领并轮换地域\n起始地域：%s · 五章敌群混合来袭" % selected_data["name"]
		endless_mode_button.text = "◆ 无尽轮回已开启"
		stage_enter_button.text = "踏入无尽轮回"
	else:
		stage_description_label.text = "%s\n地图异变 · %s" % [selected_data["subtitle"], selected_data["event_name"]]
		endless_mode_button.text = "开启无尽轮回"
		stage_enter_button.text = "踏入此卷"
	var mode_fill := Color("30243d") if selected_endless_mode else Color("24211b")
	var mode_border := Color("b68bdd") if selected_endless_mode else Color("6f624b")
	endless_mode_button.add_theme_stylebox_override("normal", _pixel_style_box(mode_fill, mode_border, 3 if selected_endless_mode else 2))
	endless_mode_button.add_theme_color_override("font_color", Color("ead5ff") if selected_endless_mode else Color("d8c9a5"))
	var overlay_color: Color = selected_data["bg"]
	overlay_color.a = 0.68
	stage_tint.color = overlay_color


func _toggle_endless_mode() -> void:
	selected_endless_mode = not selected_endless_mode
	_select_stage(selected_stage)


func _talent_icon(talent_id: String) -> Texture2D:
	match talent_id:
		"vitality", "regeneration":
			return pixel_assets["equipment"]["robe"]
		"power", "mastery":
			return pixel_assets["equipment"]["weapon"][0]
		"boss_hunter":
			return pixel_assets["equipment"]["weapon"][2]
		"agility":
			return pixel_assets["equipment"]["boots"]
		"warding", "rebirth":
			return pixel_assets["equipment"]["robe"]
		"spirit", "soul_vacuum":
			return pixel_assets["equipment"]["charm"]
		"fortune", "prosperity", "shop_discount":
			return pixel_assets["equipment"]["weapon"][4]
		"opening_arsenal":
			return pixel_assets["equipment"]["weapon"][8]
		"unbound_evolution":
			return pixel_assets["equipment"]["weapon"][6]
		"cooldown":
			return pixel_assets["equipment"]["weapon"][1]
		_:
			return pixel_assets["equipment"]["weapon"][5]


func _draw_talent_connections(canvas: Control) -> void:
	var node_center := TALENT_NODE_SIZE * 0.5
	var root_position: Vector2 = TALENT_NODE_POSITIONS["vitality"] + node_center
	canvas.draw_line(root_position, Vector2(root_position.x, TALENT_CANVAS_SIZE.y), Color(0.04, 0.03, 0.02, 0.96), 42.0, false)
	canvas.draw_line(root_position, Vector2(root_position.x, TALENT_CANVAS_SIZE.y), Color(0.31, 0.21, 0.1, 0.72), 14.0, false)
	for talent_id in MetaProgression.TALENT_ORDER:
		var requirements: Dictionary = MetaProgression.TALENT_DATA[talent_id]["requires"]
		var target_position: Vector2 = TALENT_NODE_POSITIONS[talent_id] + node_center
		for required_id in requirements:
			var source_position: Vector2 = TALENT_NODE_POSITIONS[required_id] + node_center
			var bend_y := (source_position.y + target_position.y) * 0.5
			if source_position.y - target_position.y > 300.0:
				bend_y = source_position.y - 100.0
			var path := PackedVector2Array([
				source_position,
				Vector2(source_position.x, bend_y),
				Vector2(target_position.x, bend_y),
				target_position,
			])
			var requirement_met := meta.talent_rank(String(required_id)) >= int(requirements[required_id])
			canvas.draw_polyline(path, Color(0.01, 0.012, 0.015, 0.96), 16.0, false)
			canvas.draw_polyline(path, Color("c69a4d") if requirement_met else Color("48545d"), 6.0, false)


func _talent_requirement_text(talent_id: String) -> String:
	var requirements: Dictionary = MetaProgression.TALENT_DATA[talent_id]["requires"]
	if requirements.is_empty():
		return "无前置要求"
	var parts := PackedStringArray()
	for required_id in requirements:
		parts.append("%s %d阶" % [MetaProgression.TALENT_DATA[required_id]["name"], int(requirements[required_id])])
	return "前置：" + "、".join(parts)


func _refresh_talent_tree() -> void:
	if talent_currency_label == null:
		return
	talent_currency_label.text = "持有香火  %d" % int(meta.currencies["incense"])
	for talent_id in MetaProgression.TALENT_ORDER:
		var talent: Dictionary = MetaProgression.TALENT_DATA[talent_id]
		var rank: int = meta.talent_rank(talent_id)
		var max_rank: int = talent["max_rank"]
		var unlocked: bool = meta.talent_requirements_met(talent_id)
		var selected: bool = String(talent_id) == selected_talent_id
		var is_capstone := max_rank == 1 and talent.has("rule_at_max")
		var status: String
		if rank >= max_rank:
			status = "已参悟" if is_capstone else "已修至满阶"
		elif unlocked:
			status = "可参悟 · %d 香火" % meta.talent_cost(talent_id)
		else:
			status = "前置未满足"
		var button: Button = talent_buttons[talent_id]
		button.text = ("◆ %s\n%s" if is_capstone else "%s　%d/%d 阶\n%s") % ([talent["name"], status] if is_capstone else [talent["name"], rank, max_rank, status])
		button.tooltip_text = "%s\n%s\n%s" % [talent["name"], talent["description"], _talent_requirement_text(talent_id)]
		var fill: Color = (Color("342540") if is_capstone else Color("382b1d")) if unlocked else Color("20272b")
		var border: Color = Color("f0c45f") if selected else ((Color("b68bdd") if is_capstone else Color("967b4c")) if unlocked else Color("59666f"))
		button.add_theme_stylebox_override("normal", _pixel_style_box(fill, border, 4 if selected else 2))
		button.add_theme_stylebox_override("hover", _pixel_style_box(fill.lightened(0.1), border.lightened(0.18), 4))
		button.add_theme_stylebox_override("pressed", _pixel_style_box(fill.lightened(0.16), Color("f0c776"), 4))
		button.add_theme_color_override("font_color", Color("ffe4a3") if unlocked else Color("b1bbc0"))
		button.add_theme_color_override("font_hover_color", Color("fff0c4"))

	var selected_talent: Dictionary = MetaProgression.TALENT_DATA[selected_talent_id]
	var selected_rank: int = meta.talent_rank(selected_talent_id)
	var total_bonus: float = float(selected_talent["value"]) * selected_rank * 100.0
	var selected_max_rank: int = selected_talent["max_rank"]
	if selected_max_rank == 1 and selected_talent.has("rule_at_max"):
		talent_detail_label.text = "%s　·　%s\n单点神通：%s　　%s" % [selected_talent["name"], selected_talent["description"], "已激活" if selected_rank == 1 else "尚未参悟", _talent_requirement_text(selected_talent_id)]
	elif String(selected_talent["stat"]) == "health_regen":
		talent_detail_label.text = "%s　·　%s\n当前累计：每秒生命恢复 +%.1f　　%s" % [selected_talent["name"], selected_talent["description"], float(selected_talent["value"]) * selected_rank, _talent_requirement_text(selected_talent_id)]
	else:
		talent_detail_label.text = "%s　·　%s\n当前累计：%s +%.1f%%　　%s" % [selected_talent["name"], selected_talent["description"], MetaProgression.STAT_NAMES[selected_talent["stat"]], total_bonus, _talent_requirement_text(selected_talent_id)]
	if selected_rank >= selected_max_rank:
		talent_upgrade_button.text = "已修至满阶"
		talent_upgrade_button.disabled = true
	elif not meta.talent_requirements_met(selected_talent_id):
		talent_upgrade_button.text = "前置尚未满足"
		talent_upgrade_button.disabled = true
	elif int(meta.currencies["incense"]) < meta.talent_cost(selected_talent_id):
		talent_upgrade_button.text = "香火不足 · %d" % meta.talent_cost(selected_talent_id)
		talent_upgrade_button.disabled = true
	else:
		talent_upgrade_button.text = "参悟 · 香火 %d" % meta.talent_cost(selected_talent_id)
		talent_upgrade_button.disabled = false
	talent_tree_canvas.queue_redraw()


func _select_talent(talent_id: String) -> void:
	selected_talent_id = talent_id
	_refresh_talent_tree()


func _upgrade_selected_talent() -> void:
	if meta.upgrade_talent(selected_talent_id):
		_refresh_talent_tree()
		_refresh_lobby()


func _refresh_lobby() -> void:
	if lobby_currency_label != null:
		lobby_currency_label.text = meta.currency_text()
	if stage_currency_label != null:
		stage_currency_label.text = meta.currency_text()
	if talent_currency_label != null:
		talent_currency_label.text = "持有香火  %d" % int(meta.currencies["incense"])


func _open_stage_select() -> void:
	_play_sfx("menu")
	lobby_page = LobbyPage.STAGES
	ready_overlay.hide()
	inventory_overlay.hide()
	talent_overlay.hide()
	stage_overlay.show()
	_refresh_lobby()


func _close_stage_select() -> void:
	lobby_page = LobbyPage.HOME
	stage_overlay.hide()
	ready_overlay.show()
	_refresh_lobby()


func _open_talent_tree() -> void:
	_play_sfx("menu")
	lobby_page = LobbyPage.TALENTS
	selected_talent_id = "vitality"
	ready_overlay.hide()
	stage_overlay.hide()
	inventory_overlay.hide()
	talent_overlay.show()
	_refresh_talent_tree()
	talent_tree_scroll.set_deferred("scroll_horizontal", 220)
	talent_tree_scroll.set_deferred("scroll_vertical", 758)


func _close_talent_tree() -> void:
	lobby_page = LobbyPage.HOME
	talent_overlay.hide()
	ready_overlay.show()
	_refresh_lobby()


func _open_inventory() -> void:
	_play_sfx("menu")
	lobby_page = LobbyPage.INVENTORY
	selected_item_uid = 0
	inventory_filter_slot = ""
	_refresh_inventory_ui()
	ready_overlay.hide()
	stage_overlay.hide()
	talent_overlay.hide()
	inventory_overlay.show()


func _close_inventory() -> void:
	lobby_page = LobbyPage.HOME
	inventory_overlay.hide()
	ready_overlay.show()
	_refresh_lobby()


func _quit_game() -> void:
	get_tree().quit()


func _pause_game() -> void:
	if state != GameState.RUNNING or choosing_upgrade or shopping:
		return
	game_paused = true
	pause_home_button.text = "结束无尽并结算" if endless_mode else "返回主页"
	_refresh_synergy_codex()
	pause_overlay.show()


func _resume_game() -> void:
	if state != GameState.RUNNING:
		return
	game_paused = false
	pause_overlay.hide()


func _equipment_icon(item: Dictionary) -> Texture2D:
	if item.is_empty():
		return null
	var slot: String = item["slot"]
	if slot == "weapon":
		var icons: Array = pixel_assets["equipment"]["weapon"]
		return icons[clampi(int(item.get("template", 0)), 0, icons.size() - 1)]
	var template := int(item.get("template", 0))
	if template >= 6 and pixel_assets["equipment_new"].has(slot):
		var new_icons: Array = pixel_assets["equipment_new"][slot]
		return new_icons[clampi(template - 6, 0, new_icons.size() - 1)]
	return pixel_assets["equipment"][slot]


func _slot_icon(slot: String) -> Texture2D:
	if slot == "weapon":
		return pixel_assets["equipment"]["weapon"][0]
	return pixel_assets["equipment"][slot]


func _inventory_detail_text(item: Dictionary) -> String:
	var lines := PackedStringArray([
		String(item["name"]),
		"%s · %s　　强化 +%d / +5" % [MetaProgression.RARITY_NAMES[int(item["rarity"])], MetaProgression.SLOT_NAMES[item["slot"]], int(item["level"])],
	])
	if item.has("weapon_key"):
		lines.append("开局法器：%s" % WEAPON_DATA[String(item["weapon_key"])][0])
	var rule := String(item.get("rule", ""))
	if not rule.is_empty():
		lines.append("特性·%s：%s" % [MetaProgression.RULE_AFFIX_DATA[rule][0], MetaProgression.RULE_AFFIX_DATA[rule][1]])
	var stats := PackedStringArray()
	var multiplier := 1.0 + int(item["level"]) * 0.08
	for key in item["stats"].keys():
		stats.append("%s +%.1f%%" % [MetaProgression.STAT_NAMES[key], float(item["stats"][key]) * multiplier * 100.0])
	for index in range(0, stats.size(), 2):
		var row := stats[index]
		if index + 1 < stats.size():
			row += "　　%s" % stats[index + 1]
		lines.append(row)
	return "\n".join(lines)


func _refresh_inventory_ui() -> void:
	inventory_currency_label.text = meta.currency_text()
	for index in inventory_filter_buttons.size():
		var filter_slot: String = "" if index == 0 else MetaProgression.SLOT_ORDER[index - 1]
		var filter_selected := filter_slot == inventory_filter_slot
		inventory_filter_buttons[index].text = "%s%s" % ["◆ " if filter_selected else "", INVENTORY_FILTER_NAMES[filter_slot]]
		inventory_filter_buttons[index].add_theme_stylebox_override("normal", _pixel_style_box(Color("3b2a1d") if filter_selected else Color("201c17"), Color("d6a84d") if filter_selected else Color("554938"), 3 if filter_selected else 1))
		inventory_filter_buttons[index].add_theme_color_override("font_color", Color("f3d994") if filter_selected else Color("bfb293"))
	for index in MetaProgression.SLOT_ORDER.size():
		var slot: String = MetaProgression.SLOT_ORDER[index]
		var item := meta.equipped_item(slot)
		var item_name := "未装备" if item.is_empty() else "%s +%d" % [item["name"], int(item["level"])]
		inventory_slot_buttons[index].text = "%s\n%s" % [MetaProgression.SLOT_NAMES[slot], item_name]
		inventory_slot_buttons[index].icon = _slot_icon(slot) if item.is_empty() else _equipment_icon(item)
		var slot_color := Color("d9cba9") if item.is_empty() else Color(MetaProgression.RARITY_COLORS[int(item["rarity"])])
		inventory_slot_buttons[index].add_theme_color_override("font_color", slot_color)
		var filter_highlighted := slot == inventory_filter_slot
		inventory_slot_buttons[index].add_theme_stylebox_override("normal", _pixel_style_box(Color("35261b") if filter_highlighted else Color("252019"), Color("e0a84d") if filter_highlighted else slot_color.darkened(0.35), 3 if filter_highlighted else 2))
	for child in inventory_grid.get_children():
		inventory_grid.remove_child(child)
		child.queue_free()
	var visible_item_count := 0
	for item in meta.inventory:
		if not inventory_filter_slot.is_empty() and String(item["slot"]) != inventory_filter_slot:
			continue
		visible_item_count += 1
		var button := Button.new()
		button.custom_minimum_size = Vector2(290, 88)
		button.add_theme_font_size_override("font_size", _pixel_font_size(14))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.icon = _equipment_icon(item)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var equipped_marker := "【已穿戴】\n" if int(meta.equipped[item["slot"]]) == int(item["uid"]) else ""
		button.text = "%s%s · %s\n强化 +%d" % [equipped_marker, MetaProgression.RARITY_NAMES[int(item["rarity"])], item["name"], int(item["level"])]
		var rarity_color := Color(MetaProgression.RARITY_COLORS[int(item["rarity"])])
		button.add_theme_stylebox_override("normal", _pixel_style_box(Color("241f19"), rarity_color.darkened(0.35), 2))
		button.add_theme_stylebox_override("hover", _pixel_style_box(Color("362a20"), rarity_color, 3))
		button.add_theme_stylebox_override("pressed", _pixel_style_box(Color("493023"), rarity_color.lightened(0.18), 3))
		button.add_theme_color_override("font_color", rarity_color)
		button.add_theme_color_override("font_hover_color", rarity_color.lightened(0.2))
		button.set_meta("item_slot", String(item["slot"]))
		button.pressed.connect(_select_inventory_item.bind(int(item["uid"])))
		inventory_grid.add_child(button)
	if visible_item_count == 0:
		var empty_label := _make_label("此部位暂无可用装备", 16, Color("81765f"), HORIZONTAL_ALIGNMENT_CENTER)
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.custom_minimum_size = Vector2(900, 90)
		inventory_grid.add_child(empty_label)
	var selected := meta.get_item(selected_item_uid)
	if selected.is_empty():
		inventory_detail_icon.texture = null
		inventory_detail_label.text = "选择一件装备查看详情\n背包容量：%d / %d" % [meta.inventory.size(), MetaProgression.MAX_INVENTORY]
	else:
		inventory_detail_icon.texture = _equipment_icon(selected)
		inventory_detail_label.text = _inventory_detail_text(selected)


func _select_inventory_item(uid: int) -> void:
	selected_item_uid = uid
	_refresh_inventory_ui()


func _set_inventory_filter(slot: String) -> void:
	inventory_filter_slot = slot
	selected_item_uid = 0
	_refresh_inventory_ui()


func _select_equipped_slot(slot: String) -> void:
	inventory_filter_slot = slot
	var item := meta.equipped_item(slot)
	if item.is_empty():
		selected_item_uid = 0
		_refresh_inventory_ui()
		return
	selected_item_uid = int(item["uid"])
	_refresh_inventory_ui()


func _equip_selected_item() -> void:
	if selected_item_uid == 0:
		return
	meta.equip_item(selected_item_uid)
	_refresh_inventory_ui()


func _upgrade_selected_item() -> void:
	if selected_item_uid == 0:
		return
	meta.upgrade_item(selected_item_uid)
	_refresh_inventory_ui()


func _dismantle_selected_item() -> void:
	if selected_item_uid == 0:
		return
	meta.dismantle_item(selected_item_uid)
	selected_item_uid = 0
	_refresh_inventory_ui()


func _return_to_lobby() -> void:
	state = GameState.READY
	lobby_page = LobbyPage.HOME
	game_paused = false
	if music_player != null:
		music_player.stop()
	if ambient_player != null:
		ambient_player.stop()
	result_overlay.hide()
	upgrade_panel.hide()
	shop_panel.hide()
	pause_overlay.hide()
	stage_overlay.hide()
	inventory_overlay.hide()
	talent_overlay.hide()
	shopping = false
	ready_overlay.show()
	enemies.clear()
	projectiles.clear()
	enemy_projectiles.clear()
	attack_telegraphs.clear()
	xp_orbs.clear()
	loot_orbs.clear()
	area_effects.clear()
	endless_mode = false
	arena_size = ARENA_SIZE
	camera.limit_right = int(arena_size.x)
	camera.limit_bottom = int(arena_size.y)
	_refresh_lobby()
	queue_redraw()


func _start_game() -> void:
	endless_mode = selected_endless_mode
	endless_extracted = false
	arena_size = ENDLESS_ARENA_SIZE if endless_mode else ARENA_SIZE
	wave = 1
	state = GameState.RUNNING
	lobby_page = LobbyPage.HOME
	game_paused = false
	_start_chapter_audio()
	ready_overlay.hide()
	stage_overlay.hide()
	inventory_overlay.hide()
	talent_overlay.hide()
	pause_overlay.hide()
	result_overlay.hide()
	upgrade_panel.hide()
	shop_panel.hide()
	choosing_upgrade = false
	shopping = false

	var equipment_stats := meta.aggregate_stats()
	active_run_rules.clear()
	for rule in equipment_stats["rules"]:
		active_run_rules[String(rule)] = true
	emergency_guard_charges = int(active_run_rules.has("emergency_guard")) + int(active_run_rules.has("celestial_guard"))
	rebirth_available = active_run_rules.has("rebirth")
	player_position = arena_size * 0.5
	camera.limit_right = int(arena_size.x)
	camera.limit_bottom = int(arena_size.y)
	move_speed = 285.0 * (1.0 + minf(0.45, float(equipment_stats["move_speed"])))
	max_health = 100.0 * (1.0 + minf(1.0, float(equipment_stats["health"])))
	health = max_health
	pickup_radius = 62.0 * (1.0 + minf(1.2, float(equipment_stats["pickup"])))
	hurt_timer = 0.0
	player_slow_timer = 0.0
	last_aim_direction = Vector2.RIGHT
	var starting_weapon: String = equipment_stats["starting_weapon"]
	weapon_levels = {starting_weapon: 1}
	if active_run_rules.has("opening_arsenal"):
		var arsenal_candidates: Array[String] = []
		for weapon in WEAPON_ORDER:
			if weapon != starting_weapon:
				arsenal_candidates.append(weapon)
		_shuffle_strings(arsenal_candidates)
		for index in mini(3, arsenal_candidates.size()):
			weapon_levels[arsenal_candidates[index]] = 1
	passive_levels.clear()
	evolved_weapons.clear()
	weapon_timers.clear()
	for weapon in weapon_levels:
		weapon_timers[weapon] = 0.15
	orbit_angle = 0.0
	player_walk_phase = 0.0
	player_moving = false
	equipment_damage_bonus = minf(0.75, float(equipment_stats["damage"]))
	equipment_cooldown_bonus = minf(0.45, float(equipment_stats["cooldown"]))
	experience_multiplier = 1.0 + minf(0.75, float(equipment_stats["experience"]))
	loot_luck = minf(1.5, float(equipment_stats["luck"]))
	damage_reduction = minf(0.4, float(equipment_stats["damage_reduction"]))
	copper_bonus = minf(0.75, float(equipment_stats["copper_bonus"]))
	life_steal = minf(0.005, float(equipment_stats["life_steal"]))
	health_regen = minf(2.0, float(equipment_stats["health_regen"]))
	life_steal_heal_budget = max_health * 0.02
	life_steal_effect_timer = 0.0
	ability_cooldown = 8.0 * (1.0 - equipment_cooldown_bonus)
	ability_timer = 0.0
	pulse_visual_timer = 0.0

	elapsed = 0.0
	wave = 1
	spawn_timer = 0.25
	stage_event_timer = float(_stage_data()["event_interval"]) * 0.75
	next_enemy_id = 1
	boss_spawned = false
	pending_victory = false
	endless_wave_started_at = 0.0
	endless_bosses_defeated = 0
	endless_boss_cleared_wave = 0
	run_settled = false
	run_loot.clear()
	run_damage_dealt = 0.0
	run_damage_taken = 0.0
	run_weapon_damage.clear()
	run_damage_taken_sources.clear()
	current_wave_damage_sources.clear()
	wave_records.clear()
	wave_start_elapsed = 0.0
	wave_start_damage = 0.0
	wave_start_taken = 0.0
	wave_start_defeated = 0
	weapon_sfx_last_played.clear()
	weapon_sfx_global_time = -100.0
	defeated = 0
	level = 1
	experience = 0
	experience_needed = 6
	pending_upgrades = 0
	run_copper = 0
	if active_run_rules.has("opening_purse"):
		run_copper += 20
	if active_run_rules.has("opening_choice"):
		pending_upgrades += 1
	shop_rerolls = 0
	shop_free_reroll_available = false
	shop_goods.clear()
	for lock_button in shop_lock_buttons:
		lock_button.button_pressed = false

	enemies.clear()
	projectiles.clear()
	enemy_projectiles.clear()
	attack_telegraphs.clear()
	xp_orbs.clear()
	loot_orbs.clear()
	area_effects.clear()

	camera.position = player_position
	banner_label.text = "%s · %s" % ["无尽轮回" if endless_mode else _stage_data()["name"], "第 1 波"]
	banner_timer = 1.8
	_update_hud()
	queue_redraw()


func _leave_current_run() -> void:
	if state == GameState.RUNNING and endless_mode:
		endless_extracted = true
		_finish_game(false)
	else:
		_return_to_lobby()


func _update_player(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var wasd := Vector2(
		float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
		float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	)
	if wasd.length_squared() > 0.0:
		direction = wasd.normalized()
	player_moving = direction.length_squared() > 0.0
	if player_moving:
		player_walk_phase += delta * 7.0
	var current_move_speed := move_speed * (0.58 if player_slow_timer > 0.0 else 1.0)
	if active_run_rules.has("swift_start") and elapsed < 20.0:
		current_move_speed *= 1.12
	player_position += direction.limit_length(1.0) * current_move_speed * delta
	player_position.x = clampf(player_position.x, 44.0, arena_size.x - 44.0)
	player_position.y = clampf(player_position.y, 44.0, arena_size.y - 44.0)


func _update_wave() -> void:
	var new_wave: int
	if endless_mode:
		if _is_boss_wave(wave):
			if endless_boss_cleared_wave != wave:
				return
		elif elapsed - endless_wave_started_at < _wave_duration():
			return
		new_wave = wave + 1
	else:
		new_wave = mini(int(elapsed / _wave_duration()) + 1, _boss_wave())
	if new_wave == wave:
		return
	var previous_content_stage := _content_stage_index()
	_record_wave_summary(wave)
	wave = new_wave
	endless_wave_started_at = elapsed
	pending_upgrades += 1
	if active_run_rules.has("wave_heal"):
		health = minf(max_health, health + max_health * 0.05)
		area_effects.append({"kind": "bell", "position": player_position, "radius": 82.0, "life": 0.35, "max_life": 0.35})
	if _is_boss_wave(wave):
		boss_spawned = false
		banner_label.text = "%s现身" % _stage_data()["boss_name"]
		banner_label.add_theme_color_override("font_color", COLOR_DANGER)
	else:
		banner_label.text = "第 %d 波" % wave
		banner_label.add_theme_color_override("font_color", Color.WHITE)
		if wave % 3 == 0:
			_spawn_elite()
	banner_timer = 2.0
	if endless_mode and previous_content_stage != _content_stage_index():
		_start_chapter_audio()
	if _is_boss_wave(wave) or wave <= 3 or wave % 2 == 1:
		_show_shop()


func _update_spawning(delta: float) -> void:
	if _is_boss_wave(wave):
		if not boss_spawned:
			_spawn_boss()
		return
	spawn_timer -= delta
	if spawn_timer > 0.0 or enemies.size() >= MAX_ENEMIES:
		return
	var interval := _current_spawn_interval()
	spawn_timer = interval
	_spawn_regular_enemy()
	if wave >= 3 and rng.randf() < _extra_spawn_chance() and enemies.size() < MAX_ENEMIES:
		_spawn_regular_enemy()


func _update_stage_events(delta: float) -> void:
	if _is_boss_wave(wave) or wave <= 1:
		return
	stage_event_timer -= delta
	if stage_event_timer > 0.0:
		return
	stage_event_timer = maxf(14.0, float(_stage_data()["event_interval"]) - wave * 0.35)
	banner_label.text = _stage_data()["event_name"]
	banner_label.add_theme_color_override("font_color", COLOR_TALISMAN)
	banner_timer = 1.8
	match _content_stage_index():
		0:
			for index in mini(14, 6 + wave):
				_spawn_regular_enemy("paper")
		1:
			for index in mini(10, 4 + wave):
				_spawn_regular_enemy("splitter" if index % 3 == 0 else "stone")
			for index in 4:
				var grave_position := player_position + Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(120.0, 380.0)
				grave_position.x = clampf(grave_position.x, 70.0, arena_size.x - 70.0)
				grave_position.y = clampf(grave_position.y, 70.0, arena_size.y - 70.0)
				_queue_area_telegraph(grave_position, 82.0, 14.0 + wave, 1.0)
		2:
			for index in 5 + floori(float(wave) / 2.0):
				var angle := TAU * float(index) / float(5 + floori(float(wave) / 2.0))
				var origin := player_position + Vector2.from_angle(angle) * 620.0
				origin.x = clampf(origin.x, 25.0, arena_size.x - 25.0)
				origin.y = clampf(origin.y, 25.0, arena_size.y - 25.0)
				_queue_aimed_telegraph(origin, (player_position - origin).normalized(), 285.0, 13.0, 9.0, 0.7)
			for index in 3:
				_spawn_regular_enemy("lantern")
		3:
			_queue_tide_event()
			for index in 2 + floori(float(wave) / 5.0):
				_spawn_regular_enemy("river_lantern")
		4:
			_queue_avalanche_event()
			for index in 2 + floori(float(wave) / 6.0):
				_spawn_regular_enemy("snow_stalker")


func _queue_tide_event() -> void:
	var horizontal := rng.randf() < 0.5
	var direction := Vector2.RIGHT if horizontal else Vector2.DOWN
	var perpendicular := direction.orthogonal()
	var safe_lane := rng.randi_range(0, 4)
	for lane_index in 5:
		if lane_index == safe_lane:
			continue
		attack_telegraphs.append({
			"kind": "tide_lane",
			"position": player_position + perpendicular * (float(lane_index - 2) * 118.0),
			"direction": direction,
			"width": 76.0,
			"damage": 14.0 + wave * 0.8,
			"life": 1.05,
			"max_life": 1.05,
			"source_id": 0,
		})


func _queue_avalanche_event() -> void:
	var direction: Vector2 = [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP][rng.randi_range(0, 3)]
	var gap_index := rng.randi_range(2, 8)
	attack_telegraphs.append({"kind": "avalanche", "position": player_position, "direction": direction, "gap_index": gap_index, "damage": 13.0 + wave * 0.9, "life": 1.25, "max_life": 1.25, "source_id": 0})
	if wave >= 9:
		attack_telegraphs.append({"kind": "avalanche", "position": player_position, "direction": -direction, "gap_index": gap_index, "damage": 13.0 + wave * 0.9, "life": 2.05, "max_life": 2.05, "source_id": 0})


func _spawn_regular_enemy(forced_type: String = "", position_override: Vector2 = Vector2(-1, -1)) -> void:
	if enemies.size() >= MAX_ENEMIES:
		return
	var enemy_type := forced_type
	if enemy_type.is_empty():
		enemy_type = _roll_enemy_type(rng.randf())
	var position := position_override if position_override.x >= 0.0 else _random_spawn_position()
	var enemy: Dictionary
	match enemy_type:
		"algae_drowned":
			enemy = _make_enemy(position, 18.0, 82.0, 24.0 + wave * 4.0, 12.0, 2, Color("4f9d87"), "algae_drowned")
			enemy["role"] = "algae_drowned"
		"river_lantern":
			enemy = _make_enemy(position, 19.0, 68.0, 30.0 + wave * 5.0, 9.0, 3, Color("66b6c0"), "river_lantern")
			enemy["role"] = "river_shooter"
			enemy["attack_timer"] = rng.randf_range(0.7, 1.5)
		"headless_boatman":
			enemy = _make_enemy(position, 24.0, 72.0, 58.0 + wave * 8.0, 17.0, 4, Color("557f68"), "headless_boatman")
			enemy["role"] = "boatman"
			enemy["dash_timer"] = rng.randf_range(1.8, 2.8)
			enemy["trail_spawned"] = false
		"soul_netter":
			enemy = _make_enemy(position, 21.0, 64.0, 44.0 + wave * 7.0, 10.0, 4, Color("557c8c"), "soul_netter")
			enemy["role"] = "netter"
			enemy["control_timer"] = rng.randf_range(1.4, 2.5)
		"leech_medium":
			enemy = _make_enemy(position, 22.0, 60.0, 52.0 + wave * 8.0, 11.0, 4, Color("6fa2a4"), "leech_medium")
			enemy["role"] = "healer"
			enemy["heal_timer"] = rng.randf_range(2.0, 3.5)
		"snow_stalker":
			enemy = _make_enemy(position, 22.0, 115.0, 32.0 + wave * 5.0, 15.0, 3, Color("b5d6e5"), "snow_stalker")
			enemy["role"] = "snow_stalker"
			enemy["dash_timer"] = rng.randf_range(1.3, 2.0)
		"ice_coffin":
			enemy = _make_enemy(position, 28.0, 52.0, 75.0 + wave * 10.0, 19.0, 4, Color("8ab5d0"), "ice_coffin")
			enemy["role"] = "ice_coffin"
		"gale_wraith":
			enemy = _make_enemy(position, 19.0, 86.0, 36.0 + wave * 6.0, 11.0, 3, Color("8fb6d7"), "gale_wraith")
			enemy["role"] = "cross_shooter"
			enemy["attack_timer"] = rng.randf_range(0.6, 1.4)
		"frost_jailer":
			enemy = _make_enemy(position, 25.0, 58.0, 60.0 + wave * 9.0, 12.0, 5, Color("7696b5"), "frost_jailer")
			enemy["role"] = "frost_jailer"
		"paper_summoner":
			enemy = _make_enemy(position, 20.0, 62.0, 46.0 + wave * 7.0, 10.0, 4, Color("d5b168"), "paper")
			enemy["role"] = "summoner"
			enemy["summon_timer"] = rng.randf_range(2.2, 3.2)
		"revenant":
			enemy = _make_enemy(position, 24.0, 78.0, 58.0 + wave * 8.0, 17.0, 4, Color("7c9b83"), "jiangshi")
			enemy["role"] = "revenant"
			enemy["dash_timer"] = rng.randf_range(1.6, 2.5)
		"warden":
			enemy = _make_enemy(position, 21.0, 66.0, 44.0 + wave * 7.0, 11.0, 4, Color("806f9e"), "lantern")
			enemy["role"] = "controller"
			enemy["control_timer"] = rng.randf_range(2.0, 3.2)
		"paper":
			enemy = _make_enemy(position, 14.0, 145.0, 13.0 + wave * 2.0, 8.0, 1, Color("d7b96f"), "paper")
		"stone":
			enemy = _make_enemy(position, 27.0, 58.0, 64.0 + wave * 9.0, 18.0, 3, Color("75675e"), "stone")
		"lantern":
			enemy = _make_enemy(position, 19.0, 72.0, 25.0 + wave * 4.0, 10.0, 2, Color("69a6ad"), "lantern")
			enemy["attack_timer"] = rng.randf_range(0.5, 1.4)
		"jiangshi":
			enemy = _make_enemy(position, 22.0, 88.0, 42.0 + wave * 6.0, 16.0, 2, Color("9eac63"), "jiangshi")
			enemy["dash_timer"] = rng.randf_range(1.2, 2.4)
		"splitter":
			enemy = _make_enemy(position, 21.0, 96.0, 34.0 + wave * 5.0, 12.0, 2, Color("9b72a1"), "splitter")
			enemy["split"] = 2
		_:
			enemy = _make_enemy(position, 18.0, 82.0, 17.0 + wave * 3.0, 11.0, 1, Color("709989"), "ghost")
	var hp_multiplier := float(_stage_data()["enemy_hp"]) * _enemy_hp_curve()
	enemy["hp"] = float(enemy["hp"]) * hp_multiplier
	enemy["max_hp"] = enemy["hp"]
	enemy["damage"] = float(enemy["damage"]) * _enemy_damage_curve()
	enemy["speed"] = float(enemy["speed"]) * _enemy_speed_curve()
	if endless_mode and wave >= 2 and rng.randf() < minf(0.68, 0.16 + wave * 0.018):
		var modifier: String = ENDLESS_ENEMY_MODIFIERS[rng.randi_range(0, ENDLESS_ENEMY_MODIFIERS.size() - 1)]
		enemy["modifier"] = modifier
		match modifier:
			"swift":
				enemy["speed"] = float(enemy["speed"]) * 1.25
				enemy["damage"] = float(enemy["damage"]) * 1.1
			"giant":
				enemy["radius"] = float(enemy["radius"]) * 1.3
				enemy["hp"] = float(enemy["hp"]) * 1.8
				enemy["max_hp"] = enemy["hp"]
				enemy["damage"] = float(enemy["damage"]) * 1.3
				enemy["speed"] = float(enemy["speed"]) * 0.82
				enemy["xp"] = int(enemy["xp"]) + 2
			"warded":
				enemy["ward_charges"] = 1
				enemy["hp"] = float(enemy["hp"]) * 1.25
				enemy["max_hp"] = enemy["hp"]
	enemies.append(enemy)


func _roll_enemy_type(roll: float) -> String:
	if endless_mode:
		var unlocked_count := mini(ENDLESS_ENEMY_POOL.size(), 6 + wave)
		return ENDLESS_ENEMY_POOL[mini(unlocked_count - 1, floori(roll * unlocked_count))]
	match _content_stage_index():
		0:
			if wave >= 4 and roll < 0.08:
				return "paper_summoner"
			if wave >= 7 and roll < 0.15:
				return "splitter"
			if wave >= 4 and roll < 0.26:
				return "lantern"
			if wave >= 3 and roll < 0.38:
				return "stone"
			if wave >= 2 and roll < 0.76:
				return "paper"
			return "ghost"
		1:
			if wave >= 4 and roll < 0.12:
				return "revenant"
			if wave >= 5 and roll < 0.26:
				return "jiangshi"
			if wave >= 4 and roll < 0.46:
				return "splitter"
			if wave >= 2 and roll < 0.82:
				return "stone"
			return "ghost"
		2:
			if wave >= 4 and roll < 0.1:
				return "warden"
			if wave >= 5 and roll < 0.25:
				return "jiangshi"
			if wave >= 4 and roll < 0.35:
				return "splitter"
			if wave >= 2 and roll < 0.72:
				return "lantern"
			if wave >= 3 and roll < 0.84:
				return "stone"
			return "ghost"
		3:
			if wave >= 6 and roll < 0.1:
				return "leech_medium"
			if wave >= 4 and roll < 0.25:
				return "soul_netter"
			if wave >= 3 and roll < 0.43:
				return "headless_boatman"
			if wave >= 2 and roll < 0.68:
				return "river_lantern"
			return "algae_drowned"
		_:
			if wave >= 5 and roll < 0.14:
				return "frost_jailer"
			if wave >= 3 and roll < 0.36:
				return "gale_wraith"
			if wave >= 2 and roll < 0.62:
				return "ice_coffin"
			return "snow_stalker"


func _spawn_elite() -> void:
	if enemies.size() >= MAX_ENEMIES:
		return
	var elite_types := ["paper", "stone", "jiangshi", "headless_boatman", "ice_coffin"]
	var elite_type: String = ENDLESS_ENEMY_POOL[rng.randi_range(0, ENDLESS_ENEMY_POOL.size() - 1)] if endless_mode else elite_types[_content_stage_index()]
	_spawn_regular_enemy(elite_type)
	var elite := enemies[enemies.size() - 1]
	elite["elite"] = true
	elite["radius"] = float(elite["radius"]) * 1.45
	elite["hp"] = float(elite["hp"]) * 4.0
	elite["max_hp"] = elite["hp"]
	elite["damage"] = float(elite["damage"]) * 1.45
	elite["xp"] = 12
	enemies[enemies.size() - 1] = elite
	banner_label.text = "精英邪祟来袭"
	banner_label.add_theme_color_override("font_color", COLOR_TALISMAN)
	banner_timer = 1.6


func _spawn_boss() -> void:
	boss_spawned = true
	_play_sfx("boss")
	var position := _random_spawn_position()
	var boss_variant := _content_stage_index()
	var boss_cycle := endless_bosses_defeated if endless_mode else 0
	var boss_modifier: String = ENDLESS_BOSS_MODIFIERS[boss_cycle % ENDLESS_BOSS_MODIFIERS.size()] if endless_mode else ""
	var boss_hp := float(STAGE_DATA[boss_variant]["boss_hp"]) * (1.0 + boss_cycle * 0.62)
	var boss_damage := (25.0 + boss_variant * 5.0) * (1.0 + boss_cycle * 0.22)
	if boss_modifier == "iron":
		boss_hp *= 1.5
	var boss := _make_enemy(position, 58.0 + boss_variant * 6.0, 52.0 * (1.22 if boss_modifier == "frenzy" else 1.0), boss_hp, boss_damage, 24 + boss_cycle * 5, COLOR_DANGER, "boss")
	boss["boss"] = true
	boss["boss_variant"] = boss_variant
	boss["boss_phase"] = 1
	boss["attack_timer"] = 1.6
	boss["boss_modifier"] = boss_modifier
	enemies.append(boss)
	if endless_mode:
		banner_label.text = "%s · %s" % [STAGE_DATA[boss_variant]["boss_name"], _boss_modifier_name(boss_modifier)]
		banner_label.add_theme_color_override("font_color", COLOR_DANGER)
		banner_timer = 2.2
	if boss_modifier == "summoner":
		for index in 3:
			_spawn_regular_enemy(ENDLESS_ENEMY_POOL[rng.randi_range(0, ENDLESS_ENEMY_POOL.size() - 1)])


func _make_enemy(position: Vector2, radius: float, speed: float, hp: float, damage: float, xp_value: int, color: Color, kind: String = "ghost") -> Dictionary:
	var enemy := {
		"id": next_enemy_id,
		"position": position,
		"radius": radius,
		"speed": speed,
		"hp": hp,
		"max_hp": hp,
		"damage": damage,
		"xp": xp_value,
		"color": color,
		"kind": kind,
		"phase": rng.randf_range(0.0, TAU),
		"hit_flash": 0.0,
		"boss": false,
		"boss_variant": 0,
		"boss_phase": 1,
		"elite": false,
		"split": 0,
		"dash_timer": 0.0,
		"attack_count": 0,
		"attack_timer": 0.0,
		"cast_timer": 0.0,
		"role": "",
		"summon_timer": 0.0,
		"control_timer": 0.0,
		"revived": false,
		"revive_timer": 0.0,
		"dash_warning": false,
		"dash_direction": Vector2.ZERO,
		"modifier": "",
		"ward_charges": 0,
	}
	next_enemy_id += 1
	return enemy


func _random_spawn_position() -> Vector2:
	var candidate := Vector2.ZERO
	var progress := _wave_progress()
	var minimum_distance := lerpf(740.0, 560.0, progress)
	var maximum_distance := lerpf(900.0, 720.0, progress)
	for attempt in 8:
		var angle := rng.randf_range(0.0, TAU)
		candidate = player_position + Vector2.from_angle(angle) * rng.randf_range(minimum_distance, maximum_distance)
		candidate.x = clampf(candidate.x, 30.0, arena_size.x - 30.0)
		candidate.y = clampf(candidate.y, 30.0, arena_size.y - 30.0)
		if candidate.distance_to(player_position) > minimum_distance - 40.0:
			break
	return candidate


func _update_enemies(delta: float) -> void:
	var contact_damage := 0.0
	for index in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[index]
		enemy["hit_flash"] = maxf(0.0, float(enemy["hit_flash"]) - delta)
		enemy["cast_timer"] = maxf(0.0, float(enemy["cast_timer"]) - delta)
		var offset: Vector2 = player_position - Vector2(enemy["position"])
		var direction := offset.normalized()
		var sway := direction.orthogonal() * sin(elapsed * 1.8 + float(enemy["phase"])) * 0.13
		var movement := (direction + sway).normalized() * float(enemy["speed"])
		var enemy_kind: String = enemy["kind"]
		var enemy_role: String = enemy["role"]
		if float(enemy["revive_timer"]) > 0.0:
			enemy["revive_timer"] = maxf(0.0, float(enemy["revive_timer"]) - delta)
			if float(enemy["revive_timer"]) <= 0.0:
				enemy["hp"] = float(enemy["max_hp"]) * 0.55
				enemy["hit_flash"] = 0.2
			enemies[index] = enemy
			continue
		if enemy_role == "summoner":
			if offset.length() < 260.0:
				movement = -direction * float(enemy["speed"])
			elif offset.length() < 390.0:
				movement = direction.orthogonal() * float(enemy["speed"]) * 0.55
			enemy["summon_timer"] = float(enemy["summon_timer"]) - delta
			if float(enemy["summon_timer"]) <= 0.0:
				for summon_index in 3:
					if enemies.size() >= MAX_ENEMIES:
						break
					var summon_position := Vector2(enemy["position"]) + Vector2.from_angle(TAU * float(summon_index) / 3.0) * 42.0
					summon_position.x = clampf(summon_position.x, 30.0, arena_size.x - 30.0)
					summon_position.y = clampf(summon_position.y, 30.0, arena_size.y - 30.0)
					_spawn_regular_enemy("paper", summon_position)
				enemy["summon_timer"] = rng.randf_range(4.2, 5.2)
				enemy["cast_timer"] = 0.5
		elif enemy_role == "array_eye":
			movement = Vector2.ZERO
			enemy["attack_timer"] = float(enemy["attack_timer"]) - delta
			if float(enemy["attack_timer"]) <= 0.0:
				_queue_aimed_telegraph(Vector2(enemy["position"]), direction, 310.0, 11.0 + float(enemy.get("array_power", 1)) * 2.0, 8.0, 0.58, int(enemy["id"]))
				enemy["cast_timer"] = 0.58
				enemy["attack_timer"] = maxf(1.15, 2.05 - float(enemy.get("array_power", 1)) * 0.18)
		elif enemy_role == "river_shooter":
			if offset.length() < 250.0:
				movement = -direction * float(enemy["speed"])
			elif offset.length() < 390.0:
				movement = direction.orthogonal() * float(enemy["speed"]) * 0.65
			enemy["attack_timer"] = float(enemy["attack_timer"]) - delta
			if float(enemy["attack_timer"]) <= 0.0:
				for shot_offset in [-0.16, 0.0, 0.16]:
					_queue_aimed_telegraph(Vector2(enemy["position"]), direction.rotated(shot_offset), 255.0, 9.0, 7.0, 0.55, int(enemy["id"]))
				enemy["cast_timer"] = 0.55
				enemy["attack_timer"] = 2.3
		elif enemy_role == "cross_shooter":
			if offset.length() < 260.0:
				movement = -direction * float(enemy["speed"])
			elif offset.length() < 410.0:
				movement = direction.orthogonal() * float(enemy["speed"]) * 0.7
			enemy["attack_timer"] = float(enemy["attack_timer"]) - delta
			if float(enemy["attack_timer"]) <= 0.0:
				for shot_direction in [direction, -direction, direction.orthogonal(), -direction.orthogonal()]:
					_queue_aimed_telegraph(Vector2(enemy["position"]), shot_direction, 290.0, 11.0, 8.0, 0.52, int(enemy["id"]))
				enemy["cast_timer"] = 0.52
				enemy["attack_timer"] = 2.0
		elif enemy_role == "netter":
			if offset.length() < 280.0:
				movement = -direction * float(enemy["speed"])
			enemy["control_timer"] = float(enemy["control_timer"]) - delta
			if float(enemy["control_timer"]) <= 0.0:
				_queue_area_telegraph(player_position, 95.0, 0.0, 0.85, "snare", int(enemy["id"]))
				enemy["cast_timer"] = 0.85
				enemy["control_timer"] = 3.6
		elif enemy_role == "healer":
			if offset.length() < 300.0:
				movement = -direction * float(enemy["speed"]) * 0.7
			enemy["heal_timer"] = float(enemy.get("heal_timer", 1.0)) - delta
			if float(enemy["heal_timer"]) <= 0.0:
				var healed := 0
				for ally_index in enemies.size():
					if healed >= 4 or bool(enemies[ally_index]["boss"]):
						continue
					if Vector2(enemies[ally_index]["position"]).distance_to(Vector2(enemy["position"])) <= 230.0:
						enemies[ally_index]["hp"] = minf(float(enemies[ally_index]["max_hp"]), float(enemies[ally_index]["hp"]) + float(enemies[ally_index]["max_hp"]) * 0.08)
						healed += 1
				area_effects.append({"kind": "heal", "position": enemy["position"], "radius": 230.0, "life": 0.5, "max_life": 0.5})
				enemy["cast_timer"] = 0.7
				enemy["heal_timer"] = 4.5
		elif enemy_role == "boatman" or enemy_role == "snow_stalker":
			if enemy_role == "snow_stalker" and offset.length() < 210.0 and float(enemy["dash_timer"]) > 0.6:
				movement = direction.orthogonal() * float(enemy["speed"])
			enemy["dash_timer"] = float(enemy["dash_timer"]) - delta
			if float(enemy["dash_timer"]) <= 0.78 and not bool(enemy["dash_warning"]):
				enemy["dash_warning"] = true
				enemy["dash_direction"] = direction
				enemy["trail_spawned"] = false
			if float(enemy["dash_timer"]) < 0.38:
				movement = Vector2(enemy["dash_direction"]) * float(enemy["speed"]) * (4.0 if enemy_role == "snow_stalker" else 3.2)
				if enemy_role == "boatman" and not bool(enemy.get("trail_spawned", false)):
					var wake_end := Vector2(enemy["position"]) + Vector2(enemy["dash_direction"]) * 300.0
					area_effects.append({"kind": "boat_wake", "position": enemy["position"], "end": wake_end, "radius": 28.0, "damage": 12.0, "life": 1.4, "max_life": 1.4})
					enemy["trail_spawned"] = true
			if float(enemy["dash_timer"]) <= 0.0:
				enemy["dash_timer"] = 3.0 if enemy_role == "boatman" else 1.6
				enemy["dash_warning"] = false
		elif enemy_role == "frost_jailer":
			movement *= 0.78
			if offset.length() <= 160.0:
				player_slow_timer = maxf(player_slow_timer, 0.25)
		elif enemy_role == "controller":
			if offset.length() < 290.0:
				movement = -direction * float(enemy["speed"])
			elif offset.length() < 430.0:
				movement = direction.orthogonal() * float(enemy["speed"]) * 0.5
			enemy["control_timer"] = float(enemy["control_timer"]) - delta
			if float(enemy["control_timer"]) <= 0.0:
				_queue_area_telegraph(player_position, 105.0, 0.0, 0.9, "snare", int(enemy["id"]))
				enemy["control_timer"] = rng.randf_range(4.4, 5.4)
				enemy["cast_timer"] = 0.9
		elif enemy_kind == "lantern":
			if offset.length() < 235.0:
				movement = -direction * float(enemy["speed"])
			elif offset.length() < 350.0:
				movement = direction.orthogonal() * float(enemy["speed"]) * 0.7
			enemy["attack_timer"] = float(enemy["attack_timer"]) - delta
			if float(enemy["attack_timer"]) <= 0.0:
				_queue_aimed_telegraph(Vector2(enemy["position"]), direction, 225.0, 8.0, 7.0, 0.48, int(enemy["id"]))
				enemy["cast_timer"] = 0.48
				enemy["attack_timer"] = rng.randf_range(1.7, 2.35)
		elif enemy_kind == "jiangshi":
			enemy["dash_timer"] = float(enemy["dash_timer"]) - delta
			if float(enemy["dash_timer"]) <= 0.78 and not bool(enemy["dash_warning"]):
				enemy["dash_warning"] = true
				enemy["dash_direction"] = direction
			if float(enemy["dash_timer"]) < 0.38:
				movement = Vector2(enemy["dash_direction"]) * float(enemy["speed"]) * 3.6
			if float(enemy["dash_timer"]) <= 0.0:
				enemy["dash_timer"] = rng.randf_range(2.0, 3.0)
				enemy["dash_warning"] = false
		elif bool(enemy["boss"]):
			var health_ratio := float(enemy["hp"]) / float(enemy["max_hp"])
			var boss_phase := 3 if health_ratio <= 0.32 else (2 if health_ratio <= 0.66 else 1)
			if boss_phase > int(enemy["boss_phase"]):
				enemy["boss_phase"] = boss_phase
				enemy["attack_timer"] = minf(float(enemy["attack_timer"]), 0.55)
				banner_label.text = "%s · 第 %d 阶段" % [_stage_data()["boss_name"], boss_phase]
				banner_label.add_theme_color_override("font_color", COLOR_DANGER)
				banner_timer = 2.0
				_play_sfx("boss")
				_queue_boss_phase_mechanic(Vector2(enemy["position"]), int(enemy["boss_variant"]), boss_phase, int(enemy["id"]))
				if String(enemy.get("boss_modifier", "")) == "calamity":
					_queue_tide_event()
					_queue_avalanche_event()
			movement *= 0.78 + (boss_phase - 1) * 0.11 + sin(elapsed * 1.3) * 0.12
			enemy["attack_timer"] = float(enemy["attack_timer"]) - delta
			if float(enemy["attack_timer"]) <= 0.0:
				enemy["attack_count"] = int(enemy["attack_count"]) + 1
				var boss_variant := int(enemy["boss_variant"])
				var attack_count := int(enemy["attack_count"])
				if not (boss_variant == 2 and attack_count % 2 == 0):
					_queue_boss_telegraph(Vector2(enemy["position"]), boss_variant, attack_count, direction, int(enemy["id"]), boss_phase)
				_queue_boss_mechanic(Vector2(enemy["position"]), boss_variant, attack_count, boss_phase, int(enemy["id"]))
				enemy["cast_timer"] = 0.78
				var attack_interval := maxf(0.82 if endless_mode else 1.05, 2.2 - int(enemy["boss_variant"]) * 0.25 - (boss_phase - 1) * 0.2)
				if String(enemy.get("boss_modifier", "")) == "frenzy":
					attack_interval *= 0.72
				enemy["attack_timer"] = maxf(0.72, attack_interval)
		if float(enemy["cast_timer"]) > 0.0:
			movement *= 0.12
		if bool(enemy["elite"]):
			movement *= 1.12
		enemy["position"] = Vector2(enemy["position"]) + movement * delta
		var combined_radius := player_radius + float(enemy["radius"])
		if Vector2(enemy["position"]).distance_squared_to(player_position) < combined_radius * combined_radius:
			contact_damage = maxf(contact_damage, float(enemy["damage"]))
		enemies[index] = enemy

	if contact_damage > 0.0 and hurt_timer <= 0.0:
		_take_damage(contact_damage, "contact")


func _queue_aimed_telegraph(origin: Vector2, direction: Vector2, speed: float, damage: float, radius: float, duration: float, source_id: int = 0) -> void:
	attack_telegraphs.append({
		"kind": "aimed",
		"position": origin,
		"direction": direction.normalized(),
		"speed": speed,
		"damage": damage,
		"radius": radius,
		"life": duration,
		"max_life": duration,
		"source_id": source_id,
	})


func _queue_boss_telegraph(origin: Vector2, variant: int, attack_count: int, direction: Vector2, source_id: int, boss_phase: int = 1) -> void:
	attack_telegraphs.append({
		"kind": "boss",
		"position": origin,
		"direction": direction.normalized(),
		"variant": variant,
		"attack_count": attack_count,
		"boss_phase": boss_phase,
		"life": 0.78,
		"max_life": 0.78,
		"source_id": source_id,
	})


func _queue_boss_phase_mechanic(origin: Vector2, variant: int, boss_phase: int, source_id: int) -> void:
	match variant:
		0:
			_queue_eye_cross(player_position, boss_phase, source_id, PI * 0.25 if boss_phase >= 3 else 0.0)
		1:
			_queue_boss_summon(origin, variant, boss_phase, source_id)
			if boss_phase >= 3:
				_queue_bone_cage(player_position, boss_phase, source_id, boss_phase)
		2:
			_queue_boss_summon(origin, variant, boss_phase, source_id)
			_queue_void_wheel(origin, boss_phase, source_id)
		3:
			_queue_boss_summon(origin, variant, boss_phase, source_id)
			_queue_tide_event()
		4:
			_queue_boss_summon(origin, variant, boss_phase, source_id)
			_queue_avalanche_event()


func _queue_boss_mechanic(origin: Vector2, variant: int, attack_count: int, boss_phase: int, source_id: int) -> void:
	match variant:
		0:
			var cadence := 4 if boss_phase == 1 else 3
			if attack_count % cadence == 0:
				_queue_eye_cross(player_position, boss_phase, source_id, PI * 0.25 if attack_count % 2 == 0 else 0.0)
		1:
			if boss_phase >= 2 and attack_count % 4 == 0:
				_queue_boss_summon(origin, variant, boss_phase, source_id)
			if boss_phase >= 2 and attack_count % 3 == 0:
				_queue_bone_cage(player_position, boss_phase, source_id, attack_count)
		2:
			if attack_count % 2 == 0:
				_queue_void_wheel(origin, boss_phase, source_id)
			if boss_phase >= 3 and attack_count % 5 == 0:
				_queue_boss_summon(origin, variant, boss_phase, source_id)
		3:
			if attack_count % 2 == 0:
				_queue_tide_event()
			if boss_phase >= 2 and attack_count % 4 == 0:
				_queue_boss_summon(origin, variant, boss_phase, source_id)
		4:
			if attack_count % 2 == 0:
				_queue_avalanche_event()
			if boss_phase >= 2 and attack_count % 4 == 0:
				_queue_boss_summon(origin, variant, boss_phase, source_id)


func _queue_eye_cross(center: Vector2, boss_phase: int, source_id: int, rotation: float) -> void:
	attack_telegraphs.append({
		"kind": "boss_cross",
		"position": center,
		"direction": Vector2.from_angle(rotation),
		"width": 38.0 + boss_phase * 7.0,
		"damage": 15.0 + boss_phase * 4.0,
		"life": 1.0,
		"max_life": 1.0,
		"source_id": source_id,
	})


func _queue_boss_summon(origin: Vector2, variant: int, boss_phase: int, source_id: int) -> void:
	attack_telegraphs.append({
		"kind": "boss_summon",
		"position": origin,
		"direction": Vector2.ZERO,
		"variant": variant,
		"boss_phase": boss_phase,
		"life": 1.05,
		"max_life": 1.05,
		"source_id": source_id,
	})


func _queue_void_wheel(origin: Vector2, boss_phase: int, source_id: int) -> void:
	attack_telegraphs.append({
		"kind": "boss_wheel",
		"position": origin,
		"direction": (player_position - origin).normalized(),
		"safe_angle": (player_position - origin).angle(),
		"boss_phase": boss_phase,
		"life": 1.05,
		"max_life": 1.05,
		"source_id": source_id,
	})


func _queue_bone_cage(center: Vector2, boss_phase: int, source_id: int, pattern_index: int) -> void:
	var node_count := 12 + boss_phase * 2
	var safe_index := posmod(pattern_index * 3, node_count)
	var cage_radius := 165.0 + boss_phase * 18.0
	for index in node_count:
		var gap_distance := mini(posmod(index - safe_index, node_count), posmod(safe_index - index, node_count))
		if gap_distance <= 1:
			continue
		var position := center + Vector2.from_angle(TAU * float(index) / float(node_count)) * cage_radius
		position.x = clampf(position.x, 65.0, arena_size.x - 65.0)
		position.y = clampf(position.y, 65.0, arena_size.y - 65.0)
		_queue_area_telegraph(position, 52.0, 10.0 + boss_phase * 3.0, 0.95, "bone_wall", source_id)


func _queue_area_telegraph(position: Vector2, radius: float, damage: float, duration: float, effect_type: String = "grave", source_id: int = 0) -> void:
	attack_telegraphs.append({
		"kind": "area",
		"position": position,
		"direction": Vector2.ZERO,
		"radius": radius,
		"damage": damage,
		"effect": effect_type,
		"life": duration,
		"max_life": duration,
		"source_id": source_id,
	})


func _update_attack_telegraphs(delta: float) -> void:
	for index in range(attack_telegraphs.size() - 1, -1, -1):
		var telegraph := attack_telegraphs[index]
		telegraph["life"] = float(telegraph["life"]) - delta
		if float(telegraph["life"]) <= 0.0:
			var source_id := int(telegraph.get("source_id", 0))
			if source_id == 0 or _enemy_index_from_id(source_id) >= 0:
				match String(telegraph["kind"]):
					"aimed":
						_spawn_aimed_shot(Vector2(telegraph["position"]), Vector2(telegraph["direction"]), float(telegraph["speed"]), float(telegraph["damage"]), float(telegraph["radius"]))
					"boss_cross":
						_trigger_eye_cross(telegraph)
					"boss_summon":
						if int(telegraph["variant"]) == 1:
							_spawn_bone_guards(Vector2(telegraph["position"]), int(telegraph["boss_phase"]))
						elif int(telegraph["variant"]) == 3:
							_spawn_chapter_guards(Vector2(telegraph["position"]), int(telegraph["boss_phase"]), "river_lantern")
						elif int(telegraph["variant"]) == 4:
							_spawn_chapter_guards(Vector2(telegraph["position"]), int(telegraph["boss_phase"]), "ice_coffin")
						else:
							_spawn_array_eyes(Vector2(telegraph["position"]), int(telegraph["boss_phase"]))
					"boss_wheel":
						_trigger_void_wheel(telegraph)
					"ice_burst":
						for burst_index in 8:
							_spawn_aimed_shot(Vector2(telegraph["position"]), Vector2.from_angle(TAU * float(burst_index) / 8.0), 285.0, 13.0, 8.0)
					"tide_lane":
						var tide_direction: Vector2 = telegraph["direction"]
						var tide_closest := Geometry2D.get_closest_point_to_segment(player_position, Vector2(telegraph["position"]) - tide_direction * 700.0, Vector2(telegraph["position"]) + tide_direction * 700.0)
						if player_position.distance_to(tide_closest) <= float(telegraph["width"]) + player_radius and hurt_timer <= 0.0:
							_take_damage(float(telegraph["damage"]), "grave")
							player_position += tide_direction * 140.0
						area_effects.append({"kind": "tide_lane", "position": telegraph["position"], "direction": tide_direction, "radius": telegraph["width"], "life": 0.5, "max_life": 0.5})
					"avalanche":
						var avalanche_direction: Vector2 = telegraph["direction"]
						var avalanche_perpendicular := avalanche_direction.orthogonal()
						for shot_index in 11:
							if absi(shot_index - int(telegraph["gap_index"])) <= 1:
								continue
							var shot_origin := Vector2(telegraph["position"]) - avalanche_direction * 700.0 + avalanche_perpendicular * float(shot_index - 5) * 95.0
							_spawn_aimed_shot(shot_origin, avalanche_direction, 330.0, float(telegraph["damage"]), 18.0)
					"area":
						var effect_type := String(telegraph.get("effect", "grave"))
						if player_position.distance_to(Vector2(telegraph["position"])) <= float(telegraph["radius"]) + player_radius:
							if effect_type == "snare":
								player_slow_timer = maxf(player_slow_timer, 2.2)
							elif hurt_timer <= 0.0:
								_take_damage(float(telegraph["damage"]), "grave")
						var effect_life := 2.8 if effect_type == "bone_wall" else 0.45
						area_effects.append({"kind": effect_type, "position": telegraph["position"], "radius": telegraph["radius"], "damage": telegraph["damage"], "life": effect_life, "max_life": effect_life})
					_:
						_trigger_boss_attack(Vector2(telegraph["position"]), int(telegraph["variant"]), int(telegraph["attack_count"]), Vector2(telegraph["direction"]), int(telegraph.get("boss_phase", 1)))
			attack_telegraphs.remove_at(index)
		else:
			attack_telegraphs[index] = telegraph


func _spawn_boss_burst(origin: Vector2, shot_count: int = 14, speed: float = 245.0, damage: float = 13.0, radius: float = 8.0) -> void:
	var spin := elapsed * 0.45
	for index in shot_count:
		var direction := Vector2.from_angle(spin + TAU * float(index) / float(shot_count))
		enemy_projectiles.append({
			"position": origin + direction * 65.0,
			"velocity": direction * speed,
			"radius": radius,
			"damage": damage,
			"life": 5.0,
		})


func _spawn_aimed_shot(origin: Vector2, direction: Vector2, speed: float, damage: float, radius: float) -> void:
	enemy_projectiles.append({
		"position": origin + direction * 24.0,
		"velocity": direction * speed,
		"radius": radius,
		"damage": damage,
		"life": 5.0,
	})


func _trigger_eye_cross(telegraph: Dictionary) -> void:
	var center: Vector2 = telegraph["position"]
	var direction: Vector2 = Vector2(telegraph["direction"]).normalized()
	var offset := player_position - center
	var width := float(telegraph["width"]) + player_radius
	if offset.length() <= 760.0 and (absf(offset.cross(direction)) <= width or absf(offset.dot(direction)) <= width) and hurt_timer <= 0.0:
		_take_damage(float(telegraph["damage"]), "boss")
	area_effects.append({"kind": "boss_cross", "position": center, "direction": direction, "radius": 720.0, "life": 0.38, "max_life": 0.38})


func _spawn_bone_guards(origin: Vector2, boss_phase: int) -> void:
	var existing_guards := 0
	for enemy in enemies:
		if bool(enemy.get("boss_guard", false)):
			existing_guards += 1
	var desired_guards := mini(4, boss_phase + 1)
	for index in range(existing_guards, desired_guards):
		if enemies.size() >= MAX_ENEMIES:
			break
		var position := origin + Vector2.from_angle(TAU * float(index) / float(desired_guards)) * 145.0
		position.x = clampf(position.x, 35.0, arena_size.x - 35.0)
		position.y = clampf(position.y, 35.0, arena_size.y - 35.0)
		_spawn_regular_enemy("revenant", position)
		var guard := enemies[enemies.size() - 1]
		guard["boss_guard"] = true
		guard["hp"] = float(guard["hp"]) * 0.78
		guard["max_hp"] = guard["hp"]
		enemies[enemies.size() - 1] = guard


func _spawn_chapter_guards(origin: Vector2, boss_phase: int, enemy_type: String) -> void:
	var existing_guards := 0
	for enemy in enemies:
		if bool(enemy.get("boss_guard", false)) and String(enemy["kind"]) == enemy_type:
			existing_guards += 1
	var desired_guards := mini(6, boss_phase + (2 if enemy_type == "ice_coffin" else 1))
	for index in range(existing_guards, desired_guards):
		if enemies.size() >= MAX_ENEMIES:
			break
		var position := origin + Vector2.from_angle(TAU * float(index) / float(desired_guards)) * (175.0 + boss_phase * 20.0)
		position.x = clampf(position.x, 35.0, arena_size.x - 35.0)
		position.y = clampf(position.y, 35.0, arena_size.y - 35.0)
		_spawn_regular_enemy(enemy_type, position)
		var guard := enemies[enemies.size() - 1]
		guard["boss_guard"] = true
		guard["hp"] = float(guard["hp"]) * 0.72
		guard["max_hp"] = guard["hp"]
		enemies[enemies.size() - 1] = guard


func _spawn_array_eyes(origin: Vector2, boss_phase: int) -> void:
	var existing_eyes := 0
	for enemy in enemies:
		if String(enemy.get("role", "")) == "array_eye":
			existing_eyes += 1
	var desired_eyes := 2 + boss_phase
	for index in range(existing_eyes, desired_eyes):
		if enemies.size() >= MAX_ENEMIES:
			break
		var position := origin + Vector2.from_angle(TAU * float(index) / float(desired_eyes) + PI * 0.25) * (210.0 + boss_phase * 18.0)
		position.x = clampf(position.x, 35.0, arena_size.x - 35.0)
		position.y = clampf(position.y, 35.0, arena_size.y - 35.0)
		var eye := _make_enemy(position, 18.0, 0.0, 135.0 + boss_phase * 65.0, 0.0, 4, Color("c6815b"), "lantern")
		eye["role"] = "array_eye"
		eye["array_power"] = boss_phase
		eye["attack_timer"] = 0.45 + index * 0.22
		enemies.append(eye)


func _trigger_void_wheel(telegraph: Dictionary) -> void:
	var origin: Vector2 = telegraph["position"]
	var boss_phase := int(telegraph["boss_phase"])
	var safe_angle := float(telegraph["safe_angle"])
	var shot_count := 20 + boss_phase * 4
	var safe_half_width := 0.34 - boss_phase * 0.025
	for index in shot_count:
		var angle := TAU * float(index) / float(shot_count) + elapsed * 0.18
		var angle_distance := absf(wrapf(angle - safe_angle + PI, 0.0, TAU) - PI)
		if angle_distance < safe_half_width:
			continue
		_spawn_aimed_shot(origin, Vector2.from_angle(angle), 255.0 + boss_phase * 34.0, 13.0 + boss_phase * 3.0, 8.0 + boss_phase)
	area_effects.append({"kind": "boss_wheel", "position": origin, "safe_angle": safe_angle, "radius": 130.0, "life": 0.42, "max_life": 0.42})


func _trigger_boss_attack(origin: Vector2, variant: int, attack_count: int, locked_direction: Vector2 = Vector2.ZERO, boss_phase: int = 1) -> void:
	var aimed_direction := locked_direction if locked_direction != Vector2.ZERO else (player_position - origin).normalized()
	if variant == 0:
		_spawn_boss_burst(origin, 12 + boss_phase * 3, 225.0 + boss_phase * 28.0, 11.0 + boss_phase * 2.0, 7.0 + boss_phase)
		if boss_phase >= 2:
			for index in 1 + boss_phase:
				_spawn_aimed_shot(origin, aimed_direction.rotated((float(index) - float(boss_phase) * 0.5) * 0.2), 280.0 + boss_phase * 20.0, 11.0 + boss_phase * 2.0, 8.0)
		return
	if variant == 1:
		if attack_count % 2 == 0:
			_spawn_boss_burst(origin, 12 + boss_phase * 3, 235.0 + boss_phase * 24.0, 12.0 + boss_phase * 2.0, 8.0)
		else:
			var fan_count := 5 + boss_phase * 2
			for index in fan_count:
				_spawn_aimed_shot(origin, aimed_direction.rotated((float(index) - float(fan_count - 1) * 0.5) * 0.12), 270.0 + boss_phase * 24.0, 13.0 + boss_phase * 2.0, 8.0 + boss_phase)
		if boss_phase >= 3:
			_spawn_boss_burst(origin, 10, 315.0, 15.0, 8.0)
		return
	_spawn_boss_burst(origin, 10 + boss_phase * 3, 245.0 + boss_phase * 28.0, 13.0 + boss_phase * 2.0, 8.0 + boss_phase)
	var fan_count := 3 + boss_phase * 2
	for index in fan_count:
		_spawn_aimed_shot(origin, aimed_direction.rotated((float(index) - float(fan_count - 1) * 0.5) * 0.17), 315.0 + boss_phase * 28.0, 15.0 + boss_phase * 2.0, 9.0 + boss_phase)


func _update_weapons(delta: float) -> void:
	if enemies.is_empty():
		return
	for weapon_key in weapon_levels.keys():
		var weapon: String = weapon_key
		var weapon_level: int = weapon_levels[weapon]
		var timer := float(weapon_timers.get(weapon, 0.0)) - delta
		if timer <= 0.0:
			_fire_weapon(weapon, weapon_level)
			timer = _weapon_cooldown(weapon, weapon_level)
		weapon_timers[weapon] = timer


func _has_weapon_synergy(first: String, second: String) -> bool:
	return int(weapon_levels.get(first, 0)) >= 3 and int(weapon_levels.get(second, 0)) >= 3


func _active_weapon_synergies() -> PackedStringArray:
	var active := PackedStringArray()
	for synergy in WEAPON_SYNERGIES:
		var weapons: Array = synergy["weapons"]
		if _has_weapon_synergy(String(weapons[0]), String(weapons[1])):
			active.append(String(synergy["name"]))
	return active


func _synergy_codex_text(include_effects: bool = true) -> String:
	var entries := PackedStringArray()
	for synergy in WEAPON_SYNERGIES:
		var weapons: Array = synergy["weapons"]
		var first: String = weapons[0]
		var second: String = weapons[1]
		var first_level := int(weapon_levels.get(first, 0))
		var second_level := int(weapon_levels.get(second, 0))
		var first_name: String = WEAPON_DATA[first][0]
		var second_name: String = WEAPON_DATA[second][0]
		var first_state := "%s未有" % first_name if first_level == 0 else "%s%d阶" % [first_name, first_level]
		var second_state := "%s未有" % second_name if second_level == 0 else "%s%d阶" % [second_name, second_level]
		var conditions := PackedStringArray()
		if first_level == 0:
			conditions.append("缺少%s" % first_name)
		elif first_level < 3:
			conditions.append("%s%d→3阶" % [first_name, first_level])
		if second_level == 0:
			conditions.append("缺少%s" % second_name)
		elif second_level < 3:
			conditions.append("%s%d→3阶" % [second_name, second_level])
		var status := "[color=#67c9a5]● 已激活[/color]"
		if not conditions.is_empty():
			status = "[color=#efb15e]◆ 可激活[/color]" if first_level > 0 and second_level > 0 else "[color=#817969]○ 待收集[/color]"
		var entry := "%s  [color=#f0dfb0]%s[/color]  %s + %s" % [status, synergy["name"], first_state, second_state]
		if include_effects:
			entry += "\n[color=#9da99c]   %s[/color]" % synergy["effect"]
		entries.append(entry)
	return "\n".join(entries)


func _refresh_synergy_codex() -> void:
	if is_instance_valid(upgrade_synergy_codex):
		upgrade_synergy_codex.text = _synergy_codex_text(false)
	if is_instance_valid(pause_synergy_codex):
		pause_synergy_codex.text = _synergy_codex_text(true)


func _weapon_synergy_hint(weapon: String) -> String:
	for synergy in WEAPON_SYNERGIES:
		var weapons: Array = synergy["weapons"]
		if weapon not in weapons:
			continue
		var other: String = weapons[1] if String(weapons[0]) == weapon else weapons[0]
		return "与%s均达三阶：%s" % [WEAPON_DATA[other][0], synergy["name"]]
	return ""


func _fire_weapon(weapon: String, weapon_level: int) -> void:
	_play_weapon_sfx(weapon)
	match weapon:
		"sword":
			_fire_swords(weapon_level)
		"talisman":
			_fire_talismans(weapon_level)
		"thunder":
			_cast_thunder(weapon_level)
		"bell":
			_ring_bell(weapon_level)
		"coin":
			_throw_coins(weapon_level)
		"orb":
			_spin_orbs(weapon_level)
		"chain":
			_cast_chain(weapon_level)
		"banner":
			_cast_banner(weapon_level)
		"paper_doll":
			_release_paper_dolls(weapon_level)
		"mirror":
			_cast_mirror(weapon_level)
		"tide_gourd":
			_cast_tide_gourd(weapon_level)
		"ferry_oar":
			_swing_ferry_oar(weapon_level)
		"nether_lotus":
			_cast_nether_lotus(weapon_level)
		"ice_needles":
			_fire_ice_needles(weapon_level)
		"frost_stele":
			_cast_frost_stele(weapon_level)
		"snow_umbrella":
			_spin_snow_umbrella(weapon_level)
		"judge_brush":
			_cast_judge_brush(weapon_level)
		"soul_lantern":
			_cast_soul_lantern(weapon_level)


func _weapon_cooldown(weapon: String, weapon_level: int) -> float:
	var cooldown := 1.0
	match weapon:
		"sword":
			cooldown = 0.58 - float(weapon_level - 1) * 0.055
			if evolved_weapons.has("sword"):
				cooldown = 0.22
		"talisman":
			cooldown = 1.7 - float(weapon_level - 1) * 0.13
			if evolved_weapons.has("talisman"):
				cooldown = 0.9
		"thunder":
			cooldown = 2.35 - float(weapon_level - 1) * 0.14
			if evolved_weapons.has("thunder"):
				cooldown = 1.05
		"bell":
			cooldown = 2.8 - float(weapon_level - 1) * 0.16
			if evolved_weapons.has("bell"):
				cooldown = 1.25
		"coin":
			cooldown = 1.05 - float(weapon_level - 1) * 0.07
			if evolved_weapons.has("coin"):
				cooldown = 0.58
		"orb":
			cooldown = 0.32
			if evolved_weapons.has("orb"):
				cooldown = 0.24
		"chain":
			cooldown = 1.7 - float(weapon_level - 1) * 0.1
			if evolved_weapons.has("chain"):
				cooldown = 0.88
		"banner":
			cooldown = 0.72 - float(weapon_level - 1) * 0.035
			if evolved_weapons.has("banner"):
				cooldown = 0.4
		"paper_doll":
			cooldown = 1.95 - float(weapon_level - 1) * 0.12
			if evolved_weapons.has("paper_doll"):
				cooldown = 0.78
		"mirror":
			cooldown = 0.27
			if evolved_weapons.has("mirror"):
				cooldown = 0.16
		"tide_gourd":
			cooldown = 1.3 - float(weapon_level - 1) * 0.07
			if evolved_weapons.has("tide_gourd"):
				cooldown = 0.7
		"ferry_oar":
			cooldown = 1.65 - float(weapon_level - 1) * 0.1
			if evolved_weapons.has("ferry_oar"):
				cooldown = 0.78
		"nether_lotus":
			cooldown = 2.8 - float(weapon_level - 1) * 0.1
			if evolved_weapons.has("nether_lotus"):
				cooldown = 1.45
		"ice_needles":
			cooldown = 1.05 - float(weapon_level - 1) * 0.06
			if evolved_weapons.has("ice_needles"):
				cooldown = 0.52
		"frost_stele":
			cooldown = 2.9 - float(weapon_level - 1) * 0.15
			if evolved_weapons.has("frost_stele"):
				cooldown = 1.45
		"snow_umbrella":
			cooldown = 0.62 - float(weapon_level - 1) * 0.03
			if evolved_weapons.has("snow_umbrella"):
				cooldown = 0.34
		"judge_brush":
			cooldown = 1.42 - float(weapon_level - 1) * 0.08
			if evolved_weapons.has("judge_brush"):
				cooldown = 0.72
		"soul_lantern":
			cooldown = 2.25 - float(weapon_level - 1) * 0.11
			if evolved_weapons.has("soul_lantern"):
				cooldown = 1.05
	var attack_speed := pow(0.92, int(passive_levels.get("sword_art", 0)))
	var breathing := pow(0.94, int(passive_levels.get("breathing", 0)))
	return maxf(0.12, cooldown * attack_speed * breathing * (1.0 - equipment_cooldown_bonus))


func _damage_multiplier() -> float:
	return (1.0 + float(passive_levels.get("flame_heart", 0)) * 0.12) * (1.0 + equipment_damage_bonus)


func _cast_judge_brush(weapon_level: int) -> void:
	var target_position := _nearest_enemy_position()
	var direction := (target_position - player_position).normalized()
	if direction == Vector2.ZERO:
		return
	var evolved := evolved_weapons.has("judge_brush")
	var stroke_count := 5 if evolved else 1 + int(weapon_level >= 3) + int(weapon_level >= 5)
	var length := 920.0 if evolved else 520.0 + weapon_level * 48.0
	var width := 29.0 if evolved else 12.0 + weapon_level * 2.6
	var damage := (14.0 + weapon_level * 7.0) * _damage_multiplier() * (1.4 if evolved else 1.0)
	for index in stroke_count:
		var offset := float(index) - float(stroke_count - 1) * 0.5
		var stroke_direction := direction.rotated(offset * (0.15 if evolved else 0.12))
		var endpoint := player_position + stroke_direction * length
		_apply_line_damage(player_position, endpoint, width, damage, "judge_brush")
		area_effects.append({"kind": "ink_stroke", "position": player_position, "end": endpoint, "radius": width, "life": 0.3, "max_life": 0.3})
		if _has_weapon_synergy("judge_brush", "talisman"):
			var burst_position := player_position + stroke_direction * minf(length, player_position.distance_to(target_position))
			_apply_area_damage(burst_position, 78.0, damage * 0.45, 12.0, "judge_brush")
			area_effects.append({"kind": "fire", "position": burst_position, "radius": 78.0, "life": 0.3, "max_life": 0.3})


func _cast_soul_lantern(weapon_level: int) -> void:
	var evolved := evolved_weapons.has("soul_lantern")
	var lantern_count := 4 if evolved else 1 + int(weapon_level >= 3) + int(weapon_level >= 5)
	var target_positions := PackedVector2Array()
	for enemy_index in _nearest_enemy_indices(lantern_count):
		target_positions.append(Vector2(enemies[enemy_index]["position"]))
	var radius := 108.0 + weapon_level * 15.0 + (48.0 if evolved else 0.0)
	var damage := (11.0 + weapon_level * 7.0) * _damage_multiplier() * (0.88 if evolved else 1.0)
	var knockback := 42.0 if _has_weapon_synergy("soul_lantern", "bell") else 0.0
	if knockback > 0.0:
		radius += 28.0
	for target in target_positions:
		if evolved:
			_pull_enemies(target, radius * 1.2, 18.0)
		_apply_area_damage(target, radius, damage, knockback, "soul_lantern")
		area_effects.append({"kind": "soul_burst", "position": target, "radius": radius, "life": 0.55, "max_life": 0.55})
	if evolved and not target_positions.is_empty():
		health = minf(max_health, health + 0.5)


func _fire_swords(weapon_level: int) -> void:
	var target_position := _nearest_enemy_position()
	var direction := (target_position - player_position).normalized()
	if direction == Vector2.ZERO:
		return
	last_aim_direction = direction
	var evolved := evolved_weapons.has("sword")
	var sword_count := 7 if evolved else 1 + floori(float(weapon_level - 1) / 2.0)
	var pierce := 4 if evolved else 1 + floori(float(weapon_level - 1) / 2.0)
	var damage := (11.0 + float(weapon_level) * 5.0) * _damage_multiplier()
	if evolved:
		damage *= 1.3
	for index in sword_count:
		var offset := float(index) - float(sword_count - 1) * 0.5
		var shot_direction := direction.rotated(offset * (0.105 if evolved else 0.13))
		projectiles.append({
			"kind": "sword",
			"position": player_position + shot_direction * 30.0,
			"velocity": shot_direction * (820.0 if evolved else 720.0 + weapon_level * 35.0),
			"damage": damage,
			"radius": 7.0,
			"life": 1.8,
			"hits_left": pierce,
			"hit_ids": {},
			"aoe": 0.0,
		})


func _fire_talismans(weapon_level: int) -> void:
	var target_position := _nearest_enemy_position()
	var direction := (target_position - player_position).normalized()
	if direction == Vector2.ZERO:
		return
	var evolved := evolved_weapons.has("talisman")
	var talisman_count := 3 if evolved else (2 if weapon_level >= 3 else 1)
	var damage := (16.0 + float(weapon_level) * 9.0) * _damage_multiplier()
	var area := 82.0 + float(weapon_level) * 11.0
	if weapon_level >= 5:
		area += 28.0
	if evolved:
		damage *= 1.35
		area += 48.0
	for index in talisman_count:
		var offset := float(index) - float(talisman_count - 1) * 0.5
		var shot_direction := direction.rotated(offset * 0.24)
		projectiles.append({
			"kind": "talisman",
			"position": player_position + shot_direction * 26.0,
			"velocity": shot_direction * 510.0,
			"damage": damage,
			"radius": 11.0,
			"life": 2.1,
			"hits_left": 1,
			"hit_ids": {},
			"aoe": area,
		})


func _cast_thunder(weapon_level: int) -> void:
	var target_ids: Array[int] = []
	for enemy in enemies:
		target_ids.append(int(enemy["id"]))
	for index in target_ids.size():
		var swap_index := rng.randi_range(index, target_ids.size() - 1)
		var temporary := target_ids[index]
		target_ids[index] = target_ids[swap_index]
		target_ids[swap_index] = temporary
	var evolved := evolved_weapons.has("thunder")
	var strike_count := 1 + (1 if weapon_level >= 2 else 0) + (1 if weapon_level >= 4 else 0) + (1 if weapon_level >= 5 else 0)
	if evolved:
		strike_count += 3
	strike_count = mini(target_ids.size(), strike_count)
	var damage := (13.0 + float(weapon_level) * 8.0) * _damage_multiplier()
	for index in strike_count:
		var enemy_index := _enemy_index_from_id(target_ids[index])
		if enemy_index < 0:
			continue
		var target_position: Vector2 = enemies[enemy_index]["position"]
		area_effects.append({
			"kind": "lightning",
			"position": target_position,
			"radius": 68.0 if evolved else 0.0,
			"life": 0.18,
			"max_life": 0.18,
		})
		if evolved:
			_apply_area_damage(target_position, 68.0, damage * 0.95, 0.0, "thunder")
		else:
			_damage_enemy(enemy_index, damage, "thunder")


func _ring_bell(weapon_level: int) -> void:
	var radius := 145.0 + float(weapon_level) * 24.0
	var damage := (8.0 + float(weapon_level) * 6.0) * _damage_multiplier()
	if _has_weapon_synergy("bell", "paper_doll"):
		radius += 24.0
	if weapon_level >= 3:
		damage *= 1.12
	if weapon_level >= 5:
		radius += 42.0
	var evolved := evolved_weapons.has("bell")
	if evolved:
		radius += 78.0
		damage *= 1.55
	var knockback := (72.0 if evolved else 34.0) + weapon_level * 7.0
	if _has_weapon_synergy("ferry_oar", "bell"):
		knockback *= 1.25
	_apply_area_damage(player_position, radius, damage, knockback, "bell")
	area_effects.append({
		"kind": "bell",
		"position": player_position,
		"radius": radius,
		"life": 0.45,
		"max_life": 0.45,
	})


func _throw_coins(weapon_level: int) -> void:
	var direction := (_nearest_enemy_position() - player_position).normalized()
	if direction == Vector2.ZERO:
		return
	var evolved := evolved_weapons.has("coin")
	var coin_count := 4 if evolved else (2 if weapon_level >= 3 else 1)
	if _has_weapon_synergy("coin", "orb"):
		coin_count += 1
	var coin_speed := 650.0 if evolved else 575.0
	for index in coin_count:
		var shot_direction := direction.rotated((float(index) - float(coin_count - 1) * 0.5) * 0.18)
		projectiles.append({
			"kind": "coin",
			"position": player_position + shot_direction * 27.0,
			"velocity": shot_direction * coin_speed,
			"damage": (10.0 + weapon_level * 5.0) * _damage_multiplier() * (1.3 if evolved else 1.0),
			"radius": 9.0,
			"life": 4.0,
			"hits_left": 7 + weapon_level if evolved else 2 + weapon_level,
			"hit_ids": {},
			"aoe": 0.0,
			"bounce_speed": coin_speed,
		})


func _spin_orbs(weapon_level: int) -> void:
	orbit_angle += 0.31
	var evolved := evolved_weapons.has("orb")
	var damage := (4.0 + weapon_level * 2.4) * _damage_multiplier() * (1.65 if evolved else 1.0)
	if _has_weapon_synergy("coin", "orb"):
		damage *= 1.2
	for orb_position in _orb_positions(weapon_level):
		_apply_area_damage(orb_position, 27.0 if evolved else 19.0, damage, 0.0, "orb")


func _orb_positions(weapon_level: int) -> PackedVector2Array:
	var positions := PackedVector2Array()
	var outer_count := 3 + (1 if weapon_level >= 3 else 0) + (1 if weapon_level >= 5 else 0)
	var outer_radius := 72.0 + weapon_level * 10.0
	if evolved_weapons.has("orb"):
		outer_count = 6
		outer_radius += 34.0
	for index in outer_count:
		var angle := orbit_angle + TAU * float(index) / float(outer_count)
		positions.append(player_position + Vector2.from_angle(angle) * outer_radius)
	if evolved_weapons.has("orb"):
		for index in 4:
			var angle := -orbit_angle * 1.25 + TAU * float(index) / 4.0
			positions.append(player_position + Vector2.from_angle(angle) * 70.0)
	return positions


func _cast_chain(weapon_level: int) -> void:
	var evolved := evolved_weapons.has("chain")
	var selected: Dictionary = {}
	var points := PackedVector2Array([player_position])
	var current_position := player_position
	var link_count := mini(enemies.size(), 2 + weapon_level + (2 if weapon_level >= 3 else 0) + (2 if weapon_level >= 5 else 0) + (5 if evolved else 0))
	for link in link_count:
		var best_index := -1
		var best_distance := INF
		for index in enemies.size():
			var enemy_id: int = enemies[index]["id"]
			if selected.has(enemy_id):
				continue
			var distance := current_position.distance_squared_to(Vector2(enemies[index]["position"]))
			if distance < best_distance:
				best_distance = distance
				best_index = index
		if best_index < 0:
			break
		var target_id: int = enemies[best_index]["id"]
		current_position = Vector2(enemies[best_index]["position"])
		selected[target_id] = true
		points.append(current_position)
		_damage_enemy(best_index, (8.0 + weapon_level * 4.5) * _damage_multiplier() * (1.42 if evolved else 1.0), "chain")
	if points.size() > 1:
		area_effects.append({
			"kind": "chain",
			"position": player_position,
			"points": points,
			"radius": 0.0,
			"life": 0.22,
			"max_life": 0.22,
		})
		if evolved:
			_apply_area_damage(current_position, 92.0, (10.0 + weapon_level * 4.0) * _damage_multiplier(), 0.0, "chain")
			area_effects.append({"kind": "fire", "position": current_position, "radius": 92.0, "life": 0.32, "max_life": 0.32})
		if _has_weapon_synergy("thunder", "chain"):
			_apply_area_damage(current_position, 72.0, (8.0 + weapon_level * 3.0) * _damage_multiplier(), 0.0, "chain")
			area_effects.append({"kind": "lightning", "position": current_position, "radius": 72.0, "life": 0.18, "max_life": 0.18})
		if _has_weapon_synergy("ice_needles", "chain"):
			for needle_index in 3:
				var needle_direction := Vector2.from_angle(TAU * float(needle_index) / 3.0)
				projectiles.append({"kind": "ice_needles", "position": current_position, "velocity": needle_direction * 700.0, "damage": (7.0 + int(weapon_levels.get("ice_needles", 3)) * 3.0) * _damage_multiplier() * 0.6, "radius": 5.0, "life": 0.9, "hits_left": 2, "hit_ids": {}, "aoe": 0.0, "homing": false})


func _cast_banner(weapon_level: int) -> void:
	var radius := 125.0 + weapon_level * 24.0
	var evolved := evolved_weapons.has("banner")
	if evolved:
		radius += 92.0
	var damage := (4.0 + weapon_level * 2.5) * _damage_multiplier() * (1.5 if evolved else 1.0)
	if _has_weapon_synergy("talisman", "banner"):
		damage *= 1.25
		area_effects.append({"kind": "fire", "position": player_position, "radius": radius, "life": 0.28, "max_life": 0.28})
	_apply_area_damage(player_position, radius, damage, 0.0, "banner")
	if weapon_level >= 5 or evolved:
		health = minf(max_health, health + (0.8 if evolved else 0.35))


func _release_paper_dolls(weapon_level: int) -> void:
	var evolved := evolved_weapons.has("paper_doll")
	var doll_count := 5 if evolved else 1 + floori(float(weapon_level) / 2.0)
	var synergy_damage := 1.2 if _has_weapon_synergy("bell", "paper_doll") else 1.0
	var base_direction := (_nearest_enemy_position() - player_position).normalized()
	for index in doll_count:
		var offset := float(index) - float(doll_count - 1) * 0.5
		var direction := base_direction.rotated(offset * 0.38)
		projectiles.append({
			"kind": "paper_doll",
			"position": player_position + direction * 30.0,
			"velocity": direction * (530.0 if evolved else (470.0 if weapon_level >= 5 else 390.0)),
			"damage": (12.0 + weapon_level * 5.5) * _damage_multiplier() * (1.35 if evolved else 1.0) * synergy_damage,
			"radius": 13.0,
			"life": 3.2,
			"hits_left": 8 if evolved else 2 + floori(float(weapon_level) / 2.0) + (2 if weapon_level >= 5 else 0),
			"hit_ids": {},
			"aoe": 0.0,
		})


func _cast_mirror(weapon_level: int) -> void:
	var evolved := evolved_weapons.has("mirror")
	var beam_count := 6 if evolved else 1 + (1 if weapon_level >= 3 else 0) + (1 if weapon_level >= 5 else 0)
	var synergy_damage := 1.25 if _has_weapon_synergy("sword", "mirror") else 1.0
	var base_direction := Vector2.from_angle(elapsed * 1.85)
	var width := 18.0 + weapon_level * 3.0 + (10.0 if evolved else 0.0)
	for index in beam_count:
		var direction := base_direction.rotated(TAU * float(index) / float(beam_count))
		var endpoint := player_position + direction * (350.0 + weapon_level * 28.0 + (150.0 if evolved else 0.0))
		_apply_line_damage(player_position, endpoint, width, (4.0 + weapon_level * 2.8) * _damage_multiplier() * (1.32 if evolved else 1.0) * synergy_damage, "mirror")
		area_effects.append({
			"kind": "mirror",
			"position": player_position,
			"end": endpoint,
			"radius": width,
			"life": 0.2,
			"max_life": 0.2,
		})


func _cast_tide_gourd(weapon_level: int) -> void:
	var direction := (_nearest_enemy_position() - player_position).normalized()
	if direction == Vector2.ZERO:
		return
	var evolved := evolved_weapons.has("tide_gourd")
	var wave_count := 3 if evolved else (2 if weapon_level >= 3 else 1)
	var damage := (9.0 + weapon_level * 5.0) * _damage_multiplier()
	if _has_weapon_synergy("tide_gourd", "talisman"):
		damage *= 1.2
	for index in wave_count:
		var offset := float(index) - float(wave_count - 1) * 0.5
		var wave_direction := direction.rotated(offset * (0.2 if evolved else 0.28))
		projectiles.append({
			"kind": "tide_gourd",
			"position": player_position + wave_direction * 34.0,
			"velocity": wave_direction * 420.0,
			"damage": damage,
			"radius": 40.0 if evolved else 28.0,
			"life": 0.9,
			"hits_left": 999,
			"hit_ids": {},
			"aoe": 0.0,
			"returns": weapon_level >= 5,
			"returning": false,
			"return_damage": 1.0 if evolved else 0.65,
		})


func _swing_ferry_oar(weapon_level: int) -> void:
	var direction := (_nearest_enemy_position() - player_position).normalized()
	if direction == Vector2.ZERO:
		direction = last_aim_direction
	var evolved := evolved_weapons.has("ferry_oar")
	var radius := 220.0 + weapon_level * 10.0
	if _has_weapon_synergy("ferry_oar", "bell"):
		radius *= 1.2
	var damage := (12.0 + weapon_level * 6.0) * _damage_multiplier() * (1.3 if evolved else 1.0)
	if evolved:
		_apply_area_damage(player_position, radius, damage, 55.0, "ferry_oar")
	else:
		_apply_cone_damage(player_position, direction, radius, deg_to_rad(60.0), damage, 45.0, "ferry_oar")
		if weapon_level >= 3:
			_apply_cone_damage(player_position, -direction, radius * 0.9, deg_to_rad(60.0), damage * 0.6, 28.0, "ferry_oar")
	if weapon_level >= 5 or evolved:
		var endpoint := player_position + direction * 330.0
		_apply_line_damage(player_position, endpoint, 28.0, damage * 0.55, "ferry_oar")
		if evolved:
			_apply_line_damage(player_position, player_position - direction * 330.0, 28.0, damage * 0.55, "ferry_oar")
	area_effects.append({"kind": "oar", "position": player_position, "direction": direction, "radius": radius, "life": 0.28, "max_life": 0.28, "full": evolved})


func _cast_nether_lotus(weapon_level: int) -> void:
	var evolved := evolved_weapons.has("nether_lotus")
	var lotus_limit := 3 if evolved else (2 if weapon_level >= 3 else 1)
	var lotus_count := 0
	for effect in area_effects:
		if String(effect["kind"]) == "lotus":
			lotus_count += 1
	if lotus_count >= lotus_limit:
		return
	var damage := (3.0 + weapon_level * 1.7) * _damage_multiplier()
	if _has_weapon_synergy("nether_lotus", "banner"):
		damage *= 1.25
	area_effects.append({
		"kind": "lotus",
		"position": _nearest_enemy_position(),
		"radius": 175.0 if evolved else 100.0 + weapon_level * 8.0 + (20.0 if weapon_level >= 3 else 0.0),
		"damage": damage,
		"tick_timer": 0.05,
		"tick_interval": 0.5 if evolved else 0.7,
		"final_damage": damage * 2.2,
		"heals": _has_weapon_synergy("nether_lotus", "banner"),
		"bursts": weapon_level >= 5 or evolved,
		"pulls": evolved,
		"life": 5.4 if evolved else 4.2,
		"max_life": 5.4 if evolved else 4.2,
	})


func _fire_ice_needles(weapon_level: int) -> void:
	var direction := (_nearest_enemy_position() - player_position).normalized()
	if direction == Vector2.ZERO:
		return
	var evolved := evolved_weapons.has("ice_needles")
	var needle_count := 9 if evolved else (7 if weapon_level >= 5 else (5 if weapon_level >= 3 else 3))
	var pierce := 4 if evolved else (3 if weapon_level >= 5 else (2 if weapon_level >= 3 else 1))
	for index in needle_count:
		var offset := float(index) - float(needle_count - 1) * 0.5
		var needle_direction := direction.rotated(offset * deg_to_rad((28.0 if weapon_level >= 5 else 36.0) / float(maxi(1, needle_count - 1))))
		projectiles.append({
			"kind": "ice_needles",
			"position": player_position + needle_direction * 28.0,
			"velocity": needle_direction * 760.0,
			"damage": (7.0 + weapon_level * 3.0) * _damage_multiplier() * (1.18 if evolved else 1.0),
			"radius": 5.0,
			"life": 1.35,
			"hits_left": pierce,
			"hit_ids": {},
			"aoe": 0.0,
			"homing": evolved,
		})


func _cast_frost_stele(weapon_level: int) -> void:
	var evolved := evolved_weapons.has("frost_stele")
	var stele_count := 3 if evolved else (2 if weapon_level >= 3 else 1)
	var targets: Array[int] = _nearest_enemy_indices(stele_count)
	for target_index in targets:
		var position: Vector2 = enemies[target_index]["position"]
		area_effects.append({
			"kind": "frost_warning",
			"position": position,
			"radius": 180.0 if evolved else 100.0 + weapon_level * 10.0,
			"damage": (22.0 + weapon_level * 11.0) * _damage_multiplier() * (1.25 if evolved else 1.0),
			"cracks": weapon_level >= 5,
			"thunder": _has_weapon_synergy("frost_stele", "thunder"),
			"life": 0.7,
			"max_life": 0.7,
		})


func _spin_snow_umbrella(weapon_level: int) -> void:
	var evolved := evolved_weapons.has("snow_umbrella")
	var direction := Vector2.from_angle(elapsed * 2.8)
	var radius := 220.0 if evolved else 175.0
	var damage := (4.0 + weapon_level * 2.4) * _damage_multiplier() * (1.35 if evolved else 1.0)
	if evolved:
		_apply_area_damage(player_position, radius, damage, 12.0, "snow_umbrella")
	else:
		var half_angle := deg_to_rad(80.0 if weapon_level >= 3 else 55.0)
		_apply_cone_damage(player_position, direction, radius, half_angle, damage, 12.0, "snow_umbrella")
		if weapon_level >= 5:
			_apply_cone_damage(player_position, -direction, radius, half_angle, damage, 12.0, "snow_umbrella")
	var removed := 0
	if weapon_level >= 3:
		removed = _clear_enemy_projectiles_in_cone(direction, radius, PI if evolved else deg_to_rad(80.0 if weapon_level >= 3 else 55.0), 2 if weapon_level >= 5 else 1)
	if removed > 0 and _has_weapon_synergy("snow_umbrella", "mirror"):
		for reflection_index in removed:
			var target := _nearest_enemy_position()
			if target != Vector2.ZERO:
				var endpoint := player_position + (target - player_position).normalized().rotated((reflection_index - float(removed - 1) * 0.5) * 0.12) * 260.0
				_apply_line_damage(player_position, endpoint, 18.0, damage * 1.4, "snow_umbrella")
				area_effects.append({"kind": "mirror", "position": player_position, "end": endpoint, "radius": 18.0, "life": 0.18, "max_life": 0.18})
	area_effects.append({"kind": "umbrella", "position": player_position, "direction": direction, "radius": radius, "life": 0.22, "max_life": 0.22, "full": evolved})


func _apply_cone_damage(origin: Vector2, direction: Vector2, radius: float, half_angle: float, damage: float, knockback: float, source: String) -> void:
	for index in range(enemies.size() - 1, -1, -1):
		var offset: Vector2 = Vector2(enemies[index]["position"]) - origin
		if offset.length() > radius + float(enemies[index]["radius"]):
			continue
		if absf(wrapf(offset.angle() - direction.angle() + PI, 0.0, TAU) - PI) > half_angle:
			continue
		if knockback > 0.0 and not bool(enemies[index]["boss"]):
			enemies[index]["position"] = Vector2(enemies[index]["position"]) + offset.normalized() * knockback
		_damage_enemy(index, damage, source)


func _clear_enemy_projectiles_in_cone(direction: Vector2, radius: float, half_angle: float, maximum: int) -> int:
	var removed := 0
	for index in range(enemy_projectiles.size() - 1, -1, -1):
		var offset: Vector2 = Vector2(enemy_projectiles[index]["position"]) - player_position
		if offset.length() > radius:
			continue
		if half_angle < PI and absf(wrapf(offset.angle() - direction.angle() + PI, 0.0, TAU) - PI) > half_angle:
			continue
		enemy_projectiles.remove_at(index)
		removed += 1
		if removed >= maximum:
			break
	return removed


func _apply_line_damage(start: Vector2, end: Vector2, width: float, damage: float, source: String = "") -> void:
	for index in range(enemies.size() - 1, -1, -1):
		var position: Vector2 = enemies[index]["position"]
		var closest := Geometry2D.get_closest_point_to_segment(position, start, end)
		if position.distance_to(closest) <= width + float(enemies[index]["radius"]):
			_damage_enemy(index, damage, source)


func _nearest_enemy_position() -> Vector2:
	var nearest := Vector2.ZERO
	var best_distance := INF
	for enemy in enemies:
		if float(enemy.get("revive_timer", 0.0)) > 0.0:
			continue
		var distance := player_position.distance_squared_to(Vector2(enemy["position"]))
		if distance < best_distance:
			best_distance = distance
			nearest = Vector2(enemy["position"])
	return nearest


func _nearest_enemy_indices(limit: int) -> Array[int]:
	var result: Array[int] = []
	for selection in mini(limit, enemies.size()):
		var best_index := -1
		var best_distance := INF
		for index in enemies.size():
			if index in result or float(enemies[index].get("revive_timer", 0.0)) > 0.0:
				continue
			var distance := player_position.distance_squared_to(Vector2(enemies[index]["position"]))
			if distance < best_distance:
				best_distance = distance
				best_index = index
		if best_index >= 0:
			result.append(best_index)
	return result


func _enemy_index_from_id(enemy_id: int) -> int:
	for index in enemies.size():
		if int(enemies[index]["id"]) == enemy_id:
			return index
	return -1


func _record_damage(source: String, amount: float) -> void:
	if amount <= 0.0:
		return
	run_damage_dealt += amount
	var source_key := source if not source.is_empty() else "unknown"
	run_weapon_damage[source_key] = float(run_weapon_damage.get(source_key, 0.0)) + amount
	if life_steal > 0.0 and health < max_health and life_steal_heal_budget > 0.0:
		var recovered := minf(amount * life_steal, minf(life_steal_heal_budget, max_health - health))
		health += recovered
		life_steal_heal_budget -= recovered
		if recovered > 0.0 and life_steal_effect_timer <= 0.0 and area_effects.size() < 120:
			area_effects.append({"kind": "heal", "position": player_position, "radius": 46.0, "life": 0.35, "max_life": 0.35})
			life_steal_effect_timer = 0.3


func _damage_source_name(source: String) -> String:
	return {"contact": "邪祟接触", "projectile": "敌方弹幕", "grave": "场景危险", "boss": "首领术法"}.get(source, source)


func _dominant_taken_source(sources: Dictionary) -> String:
	var dominant_source := ""
	var dominant_damage := 0.0
	for source in sources:
		if float(sources[source]) > dominant_damage:
			dominant_source = String(source)
			dominant_damage = float(sources[source])
	return "无" if dominant_source.is_empty() else _damage_source_name(dominant_source)


func _record_wave_summary(completed_wave: int) -> void:
	if completed_wave <= 0 or (not wave_records.is_empty() and int(wave_records[-1]["wave"]) == completed_wave):
		return
	wave_records.append({
		"wave": completed_wave,
		"duration": elapsed - wave_start_elapsed,
		"level": level,
		"copper": run_copper,
		"defeated": defeated - wave_start_defeated,
		"damage_dealt": run_damage_dealt - wave_start_damage,
		"damage_taken": run_damage_taken - wave_start_taken,
		"main_damage_source": _dominant_taken_source(current_wave_damage_sources),
		"damage_sources": current_wave_damage_sources.duplicate(true),
	})
	if wave_records.size() > 120:
		wave_records.pop_front()
	wave_start_elapsed = elapsed
	wave_start_damage = run_damage_dealt
	wave_start_taken = run_damage_taken
	wave_start_defeated = defeated
	current_wave_damage_sources.clear()


func _save_run_report(won: bool) -> void:
	if DisplayServer.get_name() == "headless" or not OS.get_environment("ZHENYE_CAPTURE").is_empty():
		return
	var file := FileAccess.open(LAST_RUN_REPORT_PATH, FileAccess.WRITE)
	if file == null:
		return
	var report := {
		"stage": _stage_data()["name"],
		"mode": "endless" if endless_mode else "chapter",
		"won": won,
		"highest_wave": wave,
		"bosses_defeated": endless_bosses_defeated,
		"arena_size": [arena_size.x, arena_size.y],
		"elapsed": elapsed,
		"level": level,
		"defeated": defeated,
		"damage_dealt": run_damage_dealt,
		"damage_taken": run_damage_taken,
		"damage_sources": run_damage_taken_sources,
		"weapon_damage": run_weapon_damage,
		"waves": wave_records,
	}
	file.store_string(JSON.stringify(report, "\t"))
	print("逐波战报已保存：", ProjectSettings.globalize_path(LAST_RUN_REPORT_PATH))


func _dominant_damage_text() -> String:
	var dominant_source := ""
	var dominant_damage := 0.0
	for source in run_weapon_damage:
		if float(run_weapon_damage[source]) > dominant_damage:
			dominant_source = String(source)
			dominant_damage = float(run_weapon_damage[source])
	var source_name := "无"
	if dominant_source == "pulse":
		source_name = "镇魂阵"
	elif WEAPON_DATA.has(dominant_source):
		source_name = String(WEAPON_DATA[dominant_source][0])
	elif not dominant_source.is_empty():
		source_name = dominant_source
	return "%s %d" % [source_name, roundi(dominant_damage)]


func _damage_enemy(index: int, amount: float, source: String = "") -> void:
	if index < 0 or index >= enemies.size():
		return
	var enemy := enemies[index]
	if float(enemy.get("revive_timer", 0.0)) > 0.0:
		return
	if int(enemy.get("ward_charges", 0)) > 0:
		enemy["ward_charges"] = int(enemy["ward_charges"]) - 1
		enemy["hit_flash"] = 0.18
		enemies[index] = enemy
		area_effects.append({"kind": "ward_break", "position": enemy["position"], "radius": float(enemy["radius"]) + 16.0, "life": 0.28, "max_life": 0.28})
		return
	if bool(enemy["boss"]) and active_run_rules.has("boss_hunter"):
		amount *= 1.25
	if bool(enemy["boss"]) or bool(enemy["elite"]):
		amount *= 1.0 + int(passive_levels.get("insight", 0)) * 0.08
	_record_damage(source, minf(amount, maxf(0.0, float(enemy["hp"]))))
	enemy["hp"] = float(enemy["hp"]) - amount
	enemy["hit_flash"] = 0.1
	enemies[index] = enemy
	_play_sfx("hit")
	if float(enemy["hp"]) <= 0.0:
		_kill_enemy(index)


func _apply_area_damage(origin: Vector2, radius: float, damage: float, knockback: float = 0.0, source: String = "") -> void:
	var hit_any := false
	for index in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[index]
		if float(enemy.get("revive_timer", 0.0)) > 0.0:
			continue
		var offset: Vector2 = Vector2(enemy["position"]) - origin
		if offset.length() > radius + float(enemy["radius"]):
			continue
		hit_any = true
		if int(enemy.get("ward_charges", 0)) > 0:
			enemy["ward_charges"] = int(enemy["ward_charges"]) - 1
			enemy["hit_flash"] = 0.18
			enemies[index] = enemy
			area_effects.append({"kind": "ward_break", "position": enemy["position"], "radius": float(enemy["radius"]) + 16.0, "life": 0.28, "max_life": 0.28})
			continue
		var applied_damage := damage * (1.25 if bool(enemy["boss"]) and active_run_rules.has("boss_hunter") else 1.0)
		if bool(enemy["boss"]) or bool(enemy["elite"]):
			applied_damage *= 1.0 + int(passive_levels.get("insight", 0)) * 0.08
		_record_damage(source, minf(applied_damage, maxf(0.0, float(enemy["hp"]))))
		enemy["hp"] = float(enemy["hp"]) - applied_damage
		enemy["hit_flash"] = 0.1
		if knockback > 0.0 and not bool(enemy["boss"]):
			enemy["position"] = Vector2(enemy["position"]) + offset.normalized() * knockback
		enemies[index] = enemy
		if float(enemy["hp"]) <= 0.0:
			_kill_enemy(index)
	if hit_any:
		_play_sfx("hit")


func _update_projectiles(delta: float) -> void:
	for projectile_index in range(projectiles.size() - 1, -1, -1):
		var projectile := projectiles[projectile_index]
		if (String(projectile["kind"]) == "paper_doll" or bool(projectile.get("homing", false))) and not enemies.is_empty():
			var doll_target := _nearest_enemy_position_from(Vector2(projectile["position"]), projectile["hit_ids"])
			if doll_target != Vector2.ZERO:
				var current_velocity: Vector2 = projectile["velocity"]
				var desired_velocity := (doll_target - Vector2(projectile["position"])).normalized() * current_velocity.length()
				projectile["velocity"] = current_velocity.lerp(desired_velocity, minf(1.0, delta * 4.5))
		projectile["position"] = Vector2(projectile["position"]) + Vector2(projectile["velocity"]) * delta
		projectile["life"] = float(projectile["life"]) - delta
		var remove_projectile := float(projectile["life"]) <= 0.0
		if remove_projectile and String(projectile["kind"]) == "tide_gourd" and bool(projectile.get("returns", false)) and not bool(projectile.get("returning", false)):
			projectile["returning"] = true
			projectile["life"] = 0.9
			projectile["velocity"] = (player_position - Vector2(projectile["position"])).normalized() * 420.0
			projectile["damage"] = float(projectile["damage"]) * float(projectile.get("return_damage", 0.65))
			projectile["hit_ids"] = {}
			remove_projectile = false
		var hit_ids: Dictionary = projectile["hit_ids"]
		if remove_projectile and String(projectile["kind"]) == "talisman":
			_explode_talisman(projectile)

		if not remove_projectile:
			for enemy_index in range(enemies.size() - 1, -1, -1):
				var enemy := enemies[enemy_index]
				var enemy_id: int = enemy["id"]
				if hit_ids.has(enemy_id):
					continue
				var hit_radius := float(projectile["radius"]) + float(enemy["radius"])
				if Vector2(projectile["position"]).distance_squared_to(Vector2(enemy["position"])) > hit_radius * hit_radius:
					continue
				if String(projectile["kind"]) == "talisman":
					_explode_talisman(projectile)
					remove_projectile = true
					break
				hit_ids[enemy_id] = true
				projectile["hits_left"] = int(projectile["hits_left"]) - 1
				_damage_enemy(enemy_index, float(projectile["damage"]), String(projectile["kind"]))
				if String(projectile["kind"]) == "coin" and int(projectile["hits_left"]) > 0:
					var bounce_target := _nearest_enemy_position_from(Vector2(projectile["position"]), hit_ids)
					if bounce_target != Vector2.ZERO:
						projectile["velocity"] = (bounce_target - Vector2(projectile["position"])).normalized() * float(projectile.get("bounce_speed", 575.0))
					else:
						remove_projectile = true
				if int(projectile["hits_left"]) <= 0:
					remove_projectile = true
					break

		if remove_projectile:
			projectiles.remove_at(projectile_index)
		else:
			projectile["hit_ids"] = hit_ids
			projectiles[projectile_index] = projectile


func _nearest_enemy_position_from(origin: Vector2, excluded_ids: Dictionary) -> Vector2:
	var nearest := Vector2.ZERO
	var best_distance := INF
	for enemy in enemies:
		if float(enemy.get("revive_timer", 0.0)) > 0.0:
			continue
		if excluded_ids.has(int(enemy["id"])):
			continue
		var distance := origin.distance_squared_to(Vector2(enemy["position"]))
		if distance < best_distance:
			best_distance = distance
			nearest = Vector2(enemy["position"])
	return nearest


func _explode_talisman(projectile: Dictionary) -> void:
	var position: Vector2 = projectile["position"]
	var radius: float = projectile["aoe"]
	_apply_area_damage(position, radius, float(projectile["damage"]), 20.0 if _has_weapon_synergy("tide_gourd", "talisman") else 0.0, "talisman")
	area_effects.append({
		"kind": "fire",
		"position": position,
		"radius": radius,
		"life": 0.38,
		"max_life": 0.38,
	})


func _update_enemy_projectiles(delta: float) -> void:
	for index in range(enemy_projectiles.size() - 1, -1, -1):
		var shot := enemy_projectiles[index]
		shot["position"] = Vector2(shot["position"]) + Vector2(shot["velocity"]) * delta
		shot["life"] = float(shot["life"]) - delta
		var remove_shot := float(shot["life"]) <= 0.0
		var hit_radius := player_radius + float(shot["radius"])
		if Vector2(shot["position"]).distance_squared_to(player_position) < hit_radius * hit_radius:
			if hurt_timer <= 0.0:
				_take_damage(float(shot["damage"]), "projectile")
			remove_shot = true
		if remove_shot:
			enemy_projectiles.remove_at(index)
		else:
			enemy_projectiles[index] = shot


func _update_area_effects(delta: float) -> void:
	for index in range(area_effects.size() - 1, -1, -1):
		var effect := area_effects[index]
		var effect_kind := String(effect["kind"])
		if effect_kind == "bone_wall" and player_position.distance_to(Vector2(effect["position"])) <= float(effect["radius"]) + player_radius and hurt_timer <= 0.0:
			_take_damage(float(effect.get("damage", 12.0)), "boss")
		elif effect_kind == "algae_pool" and player_position.distance_to(Vector2(effect["position"])) <= float(effect["radius"]) + player_radius:
			player_slow_timer = maxf(player_slow_timer, 0.25)
		elif effect_kind == "boat_wake":
			var wake_closest := Geometry2D.get_closest_point_to_segment(player_position, Vector2(effect["position"]), Vector2(effect["end"]))
			if player_position.distance_to(wake_closest) <= float(effect["radius"]) + player_radius and hurt_timer <= 0.0:
				_take_damage(float(effect.get("damage", 12.0)), "grave")
		elif effect_kind == "lotus":
			effect["tick_timer"] = float(effect["tick_timer"]) - delta
			if float(effect["tick_timer"]) <= 0.0:
				_apply_area_damage(Vector2(effect["position"]), float(effect["radius"]), float(effect["damage"]), 0.0, "nether_lotus")
				if bool(effect.get("pulls", false)):
					_pull_enemies(Vector2(effect["position"]), float(effect["radius"]), 12.0)
				effect["tick_timer"] = float(effect["tick_interval"])
		effect["life"] = float(effect["life"]) - delta
		if float(effect["life"]) <= 0.0:
			if effect_kind == "lotus" and bool(effect.get("bursts", false)):
				_apply_area_damage(Vector2(effect["position"]), float(effect["radius"]) * 1.15, float(effect["final_damage"]), 0.0, "nether_lotus")
				if bool(effect.get("heals", false)):
					health = minf(max_health, health + 0.5)
				area_effects.append({"kind": "lotus_burst", "position": effect["position"], "radius": float(effect["radius"]) * 1.15, "life": 0.4, "max_life": 0.4})
			elif effect_kind == "frost_warning":
				var frost_position: Vector2 = effect["position"]
				var frost_radius := float(effect["radius"])
				var frost_damage := float(effect["damage"])
				_apply_area_damage(frost_position, frost_radius, frost_damage, 0.0, "frost_stele")
				if bool(effect.get("cracks", false)):
					for crack_direction in [Vector2.RIGHT, Vector2.DOWN]:
						_apply_line_damage(frost_position - crack_direction * 220.0, frost_position + crack_direction * 220.0, 18.0, frost_damage * 0.45, "frost_stele")
				if bool(effect.get("thunder", false)):
					_apply_area_damage(frost_position, 72.0, frost_damage * 0.55, 0.0, "frost_stele")
					area_effects.append({"kind": "lightning", "position": frost_position, "radius": 72.0, "life": 0.18, "max_life": 0.18})
				area_effects.append({"kind": "frost_stele", "position": frost_position, "radius": frost_radius, "life": 0.45, "max_life": 0.45})
			area_effects.remove_at(index)
		else:
			area_effects[index] = effect


func _pull_enemies(origin: Vector2, radius: float, amount: float) -> void:
	for index in enemies.size():
		if bool(enemies[index]["boss"]):
			continue
		var offset: Vector2 = origin - Vector2(enemies[index]["position"])
		if offset.length() <= radius:
			enemies[index]["position"] = Vector2(enemies[index]["position"]) + offset.normalized() * amount


func _kill_enemy(index: int) -> void:
	if index < 0 or index >= enemies.size():
		return
	var enemy := enemies[index]
	if String(enemy.get("role", "")) == "revenant" and not bool(enemy.get("revived", false)):
		enemy["revived"] = true
		enemy["revive_timer"] = 1.6
		enemy["hp"] = 1.0
		enemy["dash_warning"] = false
		enemies[index] = enemy
		area_effects.append({"kind": "revive", "position": enemy["position"], "radius": enemy["radius"], "life": 1.6, "max_life": 1.6})
		return
	if String(enemy.get("modifier", "")) == "vengeful":
		_queue_area_telegraph(Vector2(enemy["position"]), 92.0, 12.0 * (1.0 + _endless_cycle() * 0.15), 0.85, "grave")
	_play_sfx("death")
	if area_effects.size() < 120:
		area_effects.append({
			"kind": "death",
			"position": enemy["position"],
			"radius": enemy["radius"],
			"life": 0.3,
			"max_life": 0.3,
		})
	var orb_count := mini(int(enemy["xp"]), 6)
	var orb_value := ceili(float(enemy["xp"]) / float(orb_count))
	for orb_index in orb_count:
		var angle := TAU * float(orb_index) / float(maxi(orb_count, 1))
		xp_orbs.append({
			"position": Vector2(enemy["position"]) + Vector2.from_angle(angle) * float(orb_index) * 4.0,
			"value": orb_value,
		})
	defeated += 1
	var soul_feast_rank := int(passive_levels.get("soul_feast", 0))
	if soul_feast_rank > 0:
		health = minf(max_health, health + soul_feast_rank * 0.1)
	if bool(enemy["elite"]):
		run_copper += 14
	elif rng.randf() < COPPER_DROP_CHANCE:
		run_copper += 1
		if rng.randf() < copper_bonus:
			run_copper += 1
	if bool(enemy["boss"]):
		run_loot.append(meta.generate_item(int(enemy.get("boss_variant", selected_stage)), "boss"))
		if endless_mode:
			endless_bosses_defeated += 1
			endless_boss_cleared_wave = wave
			boss_spawned = false
			pending_upgrades += 1
			run_copper += 20 + endless_bosses_defeated * 4
			enemy_projectiles.clear()
			attack_telegraphs.clear()
			banner_label.text = "轮回首领伏诛 · 即将进入第 %d 轮" % (endless_bosses_defeated + 1)
			banner_label.add_theme_color_override("font_color", COLOR_XP)
			banner_timer = 2.4
		else:
			pending_victory = true
	elif bool(enemy["elite"]):
		loot_orbs.append({"position": enemy["position"], "source": "elite"})
	elif rng.randf() < 0.004 * (1.0 + loot_luck):
		loot_orbs.append({"position": enemy["position"], "source": "normal"})
	if String(enemy.get("role", "")) == "algae_drowned":
		var algae_count := 0
		for effect in area_effects:
			if String(effect["kind"]) == "algae_pool":
				algae_count += 1
		if algae_count < 8:
			area_effects.append({"kind": "algae_pool", "position": enemy["position"], "radius": 75.0, "life": 2.4, "max_life": 2.4})
	if String(enemy.get("role", "")) == "ice_coffin":
		attack_telegraphs.append({"kind": "ice_burst", "position": enemy["position"], "direction": Vector2.ZERO, "life": 0.8, "max_life": 0.8, "source_id": 0})
	enemies.remove_at(index)
	for child_index in int(enemy["split"]):
		if enemies.size() >= MAX_ENEMIES:
			break
		var child_position := Vector2(enemy["position"]) + Vector2.from_angle(TAU * float(child_index) / float(maxi(1, int(enemy["split"])))) * 22.0
		var child := _make_enemy(child_position, 11.0, 138.0 * _enemy_speed_curve(), 13.0 * float(_stage_data()["enemy_hp"]) * _enemy_hp_curve(), 7.0 * _enemy_damage_curve(), 1, Color("b487b5"), "wisp")
		enemies.append(child)


func _update_xp_orbs(delta: float) -> void:
	for index in range(xp_orbs.size() - 1, -1, -1):
		var orb := xp_orbs[index]
		var position: Vector2 = orb["position"]
		var distance := position.distance_to(player_position)
		if active_run_rules.has("soul_vacuum") or distance < pickup_radius * 3.0:
			var pull := 980.0 if active_run_rules.has("soul_vacuum") else lerpf(160.0, 760.0, 1.0 - clampf(distance / (pickup_radius * 3.0), 0.0, 1.0))
			position = position.move_toward(player_position, pull * delta)
			orb["position"] = position
		if position.distance_to(player_position) < player_radius + 10.0:
			_gain_experience(int(orb["value"]))
			_play_sfx("pickup")
			xp_orbs.remove_at(index)
		else:
			xp_orbs[index] = orb


func _update_loot_orbs(delta: float) -> void:
	for index in range(loot_orbs.size() - 1, -1, -1):
		var orb := loot_orbs[index]
		var position: Vector2 = orb["position"]
		var distance := position.distance_to(player_position)
		if distance < pickup_radius * 4.0:
			position = position.move_toward(player_position, 520.0 * delta)
			orb["position"] = position
		if position.distance_to(player_position) < player_radius + 14.0:
			run_loot.append(meta.generate_item(_content_stage_index(), String(orb["source"])))
			_play_sfx("pickup")
			loot_orbs.remove_at(index)
		else:
			loot_orbs[index] = orb


func _gain_experience(amount: int) -> void:
	var previous_level := level
	experience += maxi(1, roundi(amount * experience_multiplier))
	while experience >= experience_needed:
		experience -= experience_needed
		level += 1
		experience_needed = 6 + (level - 1) * 4
		pending_upgrades += 1
	if level > previous_level:
		_play_sfx("level_up")


func _show_shop() -> void:
	shopping = true
	shop_rerolls = 0
	shop_free_reroll_available = active_run_rules.has("free_reroll")
	_generate_shop_goods(not shop_goods.is_empty())
	shop_panel.show()


func _can_evolve_weapon(weapon: String) -> bool:
	if not EVOLUTION_RECIPES.has(weapon):
		return false
	var passive: String = EVOLUTION_RECIPES[weapon]
	var recipe_met := int(passive_levels.get(passive, 0)) > 0 or active_run_rules.has("unbound_evolution")
	return int(weapon_levels.get(weapon, 0)) >= MAX_WEAPON_RANK and recipe_met and not evolved_weapons.has(weapon)


func _available_evolutions() -> Array[String]:
	var evolutions: Array[String] = []
	for weapon_key in EVOLUTION_RECIPES.keys():
		var weapon: String = weapon_key
		if _can_evolve_weapon(weapon):
			evolutions.append("evolve:%s" % weapon)
	_shuffle_strings(evolutions)
	return evolutions


func _shop_candidates() -> Array[String]:
	var candidates := _available_evolutions()
	for weapon_key in WEAPON_DATA.keys():
		var weapon: String = weapon_key
		if not weapon_levels.has(weapon) and weapon_levels.size() >= MAX_WEAPONS:
			continue
		if int(weapon_levels.get(weapon, 0)) < MAX_WEAPON_RANK:
			candidates.append("weapon:%s" % weapon)
	for passive_key in PASSIVE_DATA.keys():
		var passive: String = passive_key
		if int(passive_levels.get(passive, 0)) < 3:
			candidates.append("passive:%s" % passive)
	candidates.append_array(["service:heal", "service:power", "service:speed", "service:fortune"])
	return candidates


func _is_shop_choice_available(choice: String) -> bool:
	var parts := choice.split(":")
	match parts[0]:
		"weapon":
			var weapon: String = parts[1]
			return int(weapon_levels.get(weapon, 0)) < MAX_WEAPON_RANK and (weapon_levels.has(weapon) or weapon_levels.size() < MAX_WEAPONS)
		"passive":
			return int(passive_levels.get(parts[1], 0)) < 3
		"evolve":
			return _can_evolve_weapon(parts[1])
		_:
			return true


func _generate_shop_goods(preserve_locked: bool) -> void:
	var candidates := _shop_candidates()
	var new_goods: Array[Dictionary] = []
	for index in 4:
		if preserve_locked and index < shop_goods.size() and shop_lock_buttons[index].button_pressed and not bool(shop_goods[index].get("sold", false)) and _is_shop_choice_available(String(shop_goods[index]["choice"])):
			new_goods.append(shop_goods[index])
			candidates.erase(String(shop_goods[index]["choice"]))
		else:
			new_goods.append({})
	_shuffle_strings(candidates)
	for index in 4:
		if not new_goods[index].is_empty():
			continue
		var choice: String = candidates.pop_back()
		new_goods[index] = {"choice": choice, "cost": _shop_good_cost(choice), "sold": false}
		shop_lock_buttons[index].button_pressed = false
	shop_goods = new_goods
	_refresh_shop_ui()


func _shop_good_cost(choice: String) -> int:
	var parts := choice.split(":")
	var base_cost := 20
	match parts[0]:
		"weapon":
			base_cost = 18 + int(weapon_levels.get(parts[1], 0)) * 8
		"passive":
			base_cost = 16 + int(passive_levels.get(parts[1], 0)) * 7
		"evolve":
			base_cost = 72
		_:
			base_cost = {"heal": 12, "power": 28, "speed": 24, "fortune": 20}.get(parts[1], 20)
	return maxi(1, roundi(base_cost * (0.75 if active_run_rules.has("shop_discount") else 1.0)))


func _shop_good_text(choice: String) -> String:
	if choice.begins_with("service:"):
		match choice.get_slice(":", 1):
			"heal":
				return "回春丹\n\n恢复 45 点生命"
			"power":
				return "破煞符\n\n本局所有伤害 +8%"
			"speed":
				return "神行符\n\n本局移动速度 +5%"
			_:
				return "寻宝香\n\n本局装备掉率提高"
	return _upgrade_choice_text(choice)


func _refresh_shop_ui() -> void:
	shop_copper_label.text = "持有铜钱：%d" % run_copper
	var reroll_cost := 0 if shop_free_reroll_available else 6 + shop_rerolls * 4
	shop_reroll_button.text = "首次免费刷新" if reroll_cost == 0 else "刷新货物（%d 铜钱）" % reroll_cost
	for index in 4:
		var good := shop_goods[index]
		if bool(good["sold"]):
			shop_buttons[index].text = "已售出"
			shop_buttons[index].disabled = true
			shop_lock_buttons[index].disabled = true
		else:
			shop_buttons[index].text = "%s\n\n价格：%d 铜钱" % [_shop_good_text(good["choice"]), int(good["cost"])]
			shop_buttons[index].disabled = false
			shop_lock_buttons[index].disabled = false


func _buy_shop_good(index: int) -> void:
	if index < 0 or index >= shop_goods.size() or bool(shop_goods[index]["sold"]):
		return
	var cost := int(shop_goods[index]["cost"])
	if run_copper < cost:
		return
	run_copper -= cost
	var choice: String = shop_goods[index]["choice"]
	if choice.begins_with("service:"):
		match choice.get_slice(":", 1):
			"heal":
				health = minf(max_health, health + 45.0)
			"power":
				equipment_damage_bonus += 0.08
			"speed":
				move_speed *= 1.05
			"fortune":
				loot_luck += 0.2
	else:
		_apply_upgrade(choice)
	if not choice.begins_with("evolve:"):
		_play_sfx("purchase")
	shop_goods[index]["sold"] = true
	_refresh_shop_ui()
	_update_hud()


func _reroll_shop() -> void:
	var cost := 0 if shop_free_reroll_available else 6 + shop_rerolls * 4
	if run_copper < cost:
		return
	run_copper -= cost
	shop_free_reroll_available = false
	shop_rerolls += 1
	_generate_shop_goods(true)
	_update_hud()


func _close_shop() -> void:
	shopping = false
	shop_panel.hide()
	banner_label.text = "%s现身" % _stage_data()["boss_name"] if _is_boss_wave(wave) else "%s · 第 %d 波" % [_stage_data()["name"], wave]
	banner_timer = 1.4


func _show_upgrade_choices() -> void:
	choosing_upgrade = true
	upgrade_choices.clear()
	var evolutions := _available_evolutions()

	var candidates: Array[String] = []
	for weapon_key in WEAPON_DATA.keys():
		var weapon: String = weapon_key
		if not weapon_levels.has(weapon) and weapon_levels.size() >= MAX_WEAPONS:
			continue
		if int(weapon_levels.get(weapon, 0)) < MAX_WEAPON_RANK:
			candidates.append("weapon:%s" % weapon)
	for passive_key in PASSIVE_DATA.keys():
		var passive: String = passive_key
		if int(passive_levels.get(passive, 0)) < 3:
			candidates.append("passive:%s" % passive)
	_shuffle_strings(candidates)
	candidates = evolutions + candidates
	if candidates.is_empty():
		choosing_upgrade = false
		pending_upgrades = maxi(0, pending_upgrades - 1)
		run_copper += 15
		upgrade_panel.hide()
		banner_label.text = "修行已臻圆满 · 转化 15 铜钱"
		banner_label.add_theme_color_override("font_color", COLOR_TALISMAN)
		banner_timer = 1.6
		return
	for index in upgrade_buttons.size():
		upgrade_buttons[index].visible = index < mini(3, candidates.size())
	for index in mini(3, candidates.size()):
		var choice := candidates[index]
		upgrade_choices.append(choice)
		upgrade_buttons[index].text = _upgrade_choice_text(choice)
	_refresh_synergy_codex()
	upgrade_panel.show()


func _on_upgrade_pressed(index: int) -> void:
	if not choosing_upgrade or index < 0 or index >= upgrade_choices.size():
		return
	var choice := upgrade_choices[index]
	_apply_upgrade(choice)
	pending_upgrades -= 1
	choosing_upgrade = false
	upgrade_panel.hide()
	if pending_upgrades > 0:
		_show_upgrade_choices()
	_update_hud()


func _shuffle_strings(values: Array[String]) -> void:
	for index in values.size():
		var swap_index := rng.randi_range(index, values.size() - 1)
		var temporary := values[index]
		values[index] = values[swap_index]
		values[swap_index] = temporary


func _upgrade_choice_text(choice: String) -> String:
	var parts := choice.split(":")
	var category := parts[0]
	var key := parts[1]
	if category == "weapon":
		var data: Array = WEAPON_DATA[key]
		var current_level := int(weapon_levels.get(key, 0))
		var action := "获得法器" if current_level == 0 else "提升至%s" % _rank_name(current_level + 1)
		var rank_effect := _weapon_rank_effect(key, current_level + 1)
		if current_level + 1 == 3:
			var synergy_hint := _weapon_synergy_hint(key)
			if not synergy_hint.is_empty():
				rank_effect = "%s\n%s" % [rank_effect, synergy_hint] if not rank_effect.is_empty() else synergy_hint
		return "%s\n%s\n\n%s" % [data[0], action, rank_effect if not rank_effect.is_empty() else data[1]]
	if category == "passive":
		var data: Array = PASSIVE_DATA[key]
		var next_level := int(passive_levels.get(key, 0)) + 1
		return "%s\n%s\n\n%s" % [data[0], _rank_name(next_level), data[1]]
	var evolution_data: Array = EVOLUTION_DATA["evolve_%s" % key]
	return "法器进化\n%s\n\n%s" % [evolution_data[0], evolution_data[1]]


func _weapon_rank_effect(weapon: String, rank: int) -> String:
	match weapon:
		"sword":
			return "本阶变化：追加飞剑与穿透" if rank in [3, 5] else ""
		"talisman":
			if rank == 3:
				return "本阶变化：同时投出两道火符"
			if rank == 5:
				return "本阶变化：爆炸范围额外扩大"
		"thunder":
			return "本阶变化：额外轰击一个目标" if rank in [2, 4, 5] else ""
		"bell":
			if rank == 3:
				return "本阶变化：钟波伤害强化"
			if rank == 5:
				return "本阶变化：钟波范围大幅扩张"
		"coin":
			if rank == 3:
				return "本阶变化：同时掷出两枚铜钱"
			if rank == 5:
				return "本阶变化：增加弹射次数"
		"orb":
			return "本阶变化：增加一枚环绕阴阳玉" if rank in [3, 5] else ""
		"chain":
			return "本阶变化：额外连接两只邪祟" if rank in [3, 5] else ""
		"banner":
			if rank == 5:
				return "本阶变化：魂幡伤敌时缓慢恢复生命"
		"paper_doll":
			if rank in [2, 4]:
				return "本阶变化：增加一尊追敌纸傀"
			if rank == 5:
				return "本阶变化：纸傀加速并增加穿透"
		"mirror":
			return "本阶变化：增加一道旋转镜光" if rank in [3, 5] else ""
		"tide_gourd":
			return "本阶变化：潮浪一分为二" if rank == 3 else ("本阶变化：潮浪抵达尽头后折返" if rank == 5 else "")
		"ferry_oar":
			return "本阶变化：追加反向回桨" if rank == 3 else ("本阶变化：挥桨后留下破邪船痕" if rank == 5 else "")
		"nether_lotus":
			return "本阶变化：可同时维持两盏莲灯" if rank == 3 else ("本阶变化：莲灯消失时释放终脉冲" if rank == 5 else "")
		"ice_needles":
			return "本阶变化：五针齐发并增加穿透" if rank == 3 else ("本阶变化：七针齐发并再次增加穿透" if rank == 5 else "")
		"frost_stele":
			return "本阶变化：同时锁定两个落碑点" if rank == 3 else ("本阶变化：寒碑向四方扩散裂痕" if rank == 5 else "")
		"snow_umbrella":
			return "本阶变化：伞面扩大并可化解弹幕" if rank == 3 else ("本阶变化：追加反向伞面并多化解一弹" if rank == 5 else "")
		"judge_brush":
			return "本阶变化：追加一道并行判词" if rank in [3, 5] else ""
		"soul_lantern":
			return "本阶变化：额外点亮一盏照夜灯" if rank in [3, 5] else ""
	return ""


func _apply_upgrade(choice: String) -> void:
	var parts := choice.split(":")
	var category := parts[0]
	var key := parts[1]
	if category == "weapon":
		weapon_levels[key] = mini(MAX_WEAPON_RANK, int(weapon_levels.get(key, 0)) + 1)
		if not weapon_timers.has(key):
			weapon_timers[key] = 0.1
		return
	if category == "evolve":
		evolved_weapons[key] = true
		weapon_timers[key] = 0.05
		_play_sfx("evolution")
		return

	passive_levels[key] = int(passive_levels.get(key, 0)) + 1
	match key:
		"footwork":
			move_speed *= 1.08
		"vitality":
			max_health += 20.0
			health = minf(max_health, health + 25.0)
		"magnet":
			pickup_radius += 30.0
		"breathing":
			ability_cooldown = maxf(3.8, ability_cooldown * 0.94)


func _rank_name(rank: int) -> String:
	var names := ["零阶", "一阶", "二阶", "三阶", "四阶", "五阶"]
	return names[clampi(rank, 0, names.size() - 1)]


func _use_pulse() -> void:
	if ability_timer > 0.0:
		return
	ability_timer = ability_cooldown
	pulse_visual_timer = 0.4
	pulse_origin = player_position
	_apply_area_damage(player_position, 260.0, 28.0 * _damage_multiplier(), 68.0, "pulse")


func _take_damage(amount: float, source: String = "") -> void:
	amount *= 1.0 - damage_reduction
	var guard_triggered := amount >= health and emergency_guard_charges > 0
	var rebirth_triggered := amount >= health and not guard_triggered and rebirth_available
	var applied_damage := maxf(0.0, health - 1.0) if guard_triggered else minf(amount, health)
	if guard_triggered:
		health = 1.0
		emergency_guard_charges -= 1
		hurt_timer = 1.0
		banner_label.text = "护命生效 · 避过致命一击"
		banner_label.add_theme_color_override("font_color", COLOR_PLAYER)
		banner_timer = 2.0
		area_effects.append({"kind": "bell", "position": player_position, "radius": 125.0, "life": 0.5, "max_life": 0.5})
	elif rebirth_triggered:
		health = max_health * 0.35
		rebirth_available = false
		hurt_timer = 2.0
		enemy_projectiles.clear()
		banner_label.text = "九转还魂 · 复生"
		banner_label.add_theme_color_override("font_color", COLOR_PLAYER_CORE)
		banner_timer = 2.4
		area_effects.append({"kind": "bell", "position": player_position, "radius": 210.0, "life": 0.7, "max_life": 0.7})
	else:
		health = maxf(0.0, health - amount)
		hurt_timer = 0.42
	run_damage_taken += applied_damage
	var source_key := source if not source.is_empty() else "unknown"
	run_damage_taken_sources[source_key] = float(run_damage_taken_sources.get(source_key, 0.0)) + applied_damage
	current_wave_damage_sources[source_key] = float(current_wave_damage_sources.get(source_key, 0.0)) + applied_damage
	_play_sfx("hurt")


func _update_camera(delta: float) -> void:
	camera.position = player_position.round()
	if hurt_timer > 0.28:
		camera.offset = Vector2(rng.randi_range(-4, 4), rng.randi_range(-4, 4))
	else:
		camera.offset = camera.offset.lerp(Vector2.ZERO, delta * 12.0)


func _finish_game(won: bool) -> void:
	state = GameState.WON if won else GameState.LOST
	game_paused = false
	if music_player != null:
		music_player.stop()
	if ambient_player != null:
		ambient_player.stop()
	choosing_upgrade = false
	shopping = false
	upgrade_panel.hide()
	shop_panel.hide()
	pause_overlay.hide()
	result_overlay.show()
	_record_wave_summary(wave)
	_save_run_report(won)
	if endless_mode:
		result_title.text = "无尽镇守 · 收束归观" if endless_extracted else "无尽轮回终止"
		result_title.add_theme_color_override("font_color", COLOR_XP if endless_extracted else COLOR_DANGER)
	elif won:
		result_title.text = "%s已伏诛" % _stage_data()["boss_name"]
		result_title.add_theme_color_override("font_color", COLOR_XP)
	else:
		result_title.text = "战斗失败"
		result_title.add_theme_color_override("font_color", COLOR_DANGER)
	var rewards: Dictionary = meta.settle_run(won, selected_stage, defeated, run_loot) if not run_settled else {}
	run_settled = true
	var item_names := PackedStringArray()
	for item in rewards.get("items", []):
		if item_names.size() >= 4:
			break
		item_names.append("%s·%s" % [MetaProgression.RARITY_NAMES[int(item["rarity"])], item["name"]])
	var loot_text := "无装备" if item_names.is_empty() else "、".join(item_names)
	var endless_result := "最高第 %d 波　伏诛首领 %d\n" % [wave, endless_bosses_defeated] if endless_mode else ""
	result_detail.text = "%s镇守时间 %s　修为 %d　镇伏邪祟 %d\n总输出 %d　承受伤害 %d　主力 %s\n带回装备：%s\n香火 +%d　器魄 +%d　玄铁 +%d　残卷 +%d" % [
		endless_result, _format_time(elapsed), level, defeated, roundi(run_damage_dealt), roundi(run_damage_taken), _dominant_damage_text(), loot_text,
		int(rewards.get("incense", 0)), int(rewards.get("essence", 0)), int(rewards.get("iron", 0)), int(rewards.get("scroll", 0)),
	]
	_refresh_lobby()
	queue_redraw()


func _update_hud() -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	health_label.text = "生命  %d / %d" % [ceili(health), ceili(max_health)]
	xp_bar.max_value = experience_needed
	xp_bar.value = experience
	level_label.text = "修为 %d   残魂 %d / %d" % [level, experience, experience_needed]
	if endless_mode:
		wave_label.text = "%s · 无尽第 %d 波 · 轮回 %d%s" % [_stage_data()["name"], wave, _endless_cycle() + 1, " · 首领战" if _is_boss_wave(wave) else ""]
	else:
		wave_label.text = "%s · 首领战" % _stage_data()["name"] if _is_boss_wave(wave) else "%s · 第 %d / %d 波" % [_stage_data()["name"], wave, _boss_wave() - 1]
	time_label.text = _format_time(elapsed)
	copper_label.text = "铜钱 %d" % run_copper
	enemy_label.text = "镇伏  %d     场上邪祟  %d" % [defeated, enemies.size()]
	var boss_enemy: Dictionary = {}
	for enemy in enemies:
		if bool(enemy["boss"]):
			boss_enemy = enemy
			break
	if boss_enemy.is_empty():
		boss_health_label.hide()
		boss_health_bar.hide()
	else:
		var boss_variant := int(boss_enemy.get("boss_variant", _content_stage_index()))
		var modifier_text := " · %s" % _boss_modifier_name(String(boss_enemy.get("boss_modifier", ""))) if not String(boss_enemy.get("boss_modifier", "")).is_empty() else ""
		boss_health_label.text = "%s%s · 第 %d 阶段　%d / %d" % [STAGE_DATA[boss_variant]["boss_name"], modifier_text, int(boss_enemy.get("boss_phase", 1)), ceili(float(boss_enemy["hp"])), ceili(float(boss_enemy["max_hp"]))]
		boss_health_bar.max_value = float(boss_enemy["max_hp"])
		boss_health_bar.value = maxf(0.0, float(boss_enemy["hp"]))
		boss_health_label.show()
		boss_health_bar.show()
	var equipped: PackedStringArray = []
	for weapon in WEAPON_ORDER:
		if not weapon_levels.has(weapon):
			continue
		var weapon_name: String = WEAPON_DATA[weapon][0]
		if evolved_weapons.has(weapon):
			weapon_name = EVOLUTION_DATA["evolve_%s" % weapon][0]
			equipped.append(weapon_name)
		else:
			equipped.append("%s %s" % [weapon_name, _rank_name(int(weapon_levels[weapon]))])
	if equipped.size() <= 6:
		build_label.text = "法器  " + "  ·  ".join(equipped)
	else:
		var max_rank_count := 0
		for weapon_level in weapon_levels.values():
			if int(weapon_level) >= MAX_WEAPON_RANK:
				max_rank_count += 1
		build_label.text = "法器 %d / %d  ·  五阶 %d  ·  已进化 %d" % [equipped.size(), MAX_WEAPONS, max_rank_count, evolved_weapons.size()]
	var active_synergies := _active_weapon_synergies()
	synergy_label.visible = not active_synergies.is_empty()
	if active_synergies.size() <= 3:
		synergy_label.text = "法器联动  " + "  ·  ".join(active_synergies)
	else:
		synergy_label.text = "法器联动 %d / %d  ·  %s" % [active_synergies.size(), WEAPON_SYNERGIES.size(), "全部激活" if active_synergies.size() == WEAPON_SYNERGIES.size() else "查看暂停图鉴"]
	if ability_timer <= 0.0:
		ability_label.text = "空格键  镇魂阵已就绪"
		ability_label.add_theme_color_override("font_color", COLOR_PLAYER)
	else:
		ability_label.text = "空格键  镇魂阵调息  %.1f 秒" % ability_timer
		ability_label.add_theme_color_override("font_color", Color("81765f"))


func _boss_modifier_name(modifier: String) -> String:
	return {"frenzy": "狂怒", "iron": "铁壁", "summoner": "召魂", "calamity": "灾变"}.get(modifier, "")


func _format_time(value: float) -> String:
	var total_seconds := floori(value)
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]


func _draw() -> void:
	var stage: Dictionary = _stage_data()
	var content_stage := _content_stage_index()
	var stage_border: Color = stage["border"]
	var floor_tint: Color = stage["floor_tint"]
	draw_texture_rect(pixel_assets["floors"][content_stage], Rect2(Vector2.ZERO, arena_size), false, floor_tint)
	var altar := arena_size * 0.5
	match content_stage:
		0:
			draw_arc(altar, 185.0, 0, TAU, 72, Color("3a3021"), 3.0, false)
			draw_arc(altar, 132.0, 0, TAU, 64, Color("2d4a3e"), 2.0, false)
			for index in 8:
				var direction := Vector2.from_angle(TAU * float(index) / 8.0)
				draw_line(altar + direction * 138.0, altar + direction * 178.0, Color("594526"), 4.0)
			for shrine_position in [altar + Vector2(-1050, -680), altar + Vector2(1050, -680), altar + Vector2(-1050, 680), altar + Vector2(1050, 680)]:
				draw_rect(Rect2(shrine_position - Vector2(42, 28), Vector2(84, 56)), Color("3c3425"), true)
				draw_arc(shrine_position, 58.0, 0, TAU, 24, Color("7b6134"), 4.0, false)
		1:
			var grave_rows := floori((arena_size.y - 340.0) / 330.0) + 1
			var grave_columns := floori((arena_size.x - 360.0) / 300.0) + 1
			for row in grave_rows:
				for column in grave_columns:
					var grave_position := Vector2(180 + column * 300 + (row % 2) * 70, 170 + row * 330)
					draw_rect(Rect2(grave_position - Vector2(26, 16), Vector2(52, 32)), Color("273536"), true)
					draw_line(grave_position + Vector2(0, -34), grave_position + Vector2(0, 14), Color("536465"), 5.0)
					draw_line(grave_position + Vector2(-14, -18), grave_position + Vector2(14, -18), Color("536465"), 4.0)
		2:
			draw_rect(Rect2(altar - Vector2(235, 175), Vector2(470, 350)), Color("3b211c"), false, 8.0)
			draw_arc(altar, 148.0, 0, TAU, 64, Color("784236"), 5.0)
			for pillar_position in [Vector2(330, 270), Vector2(arena_size.x - 330, 270), Vector2(330, arena_size.y - 270), arena_size - Vector2(330, 270)]:
				draw_circle(pillar_position, 42.0, Color("43251f"))
				draw_arc(pillar_position, 50.0, 0, TAU, 32, Color("8c4b35"), 5.0)
		3:
			for channel in floori(arena_size.y / 470.0):
				var channel_y := 260.0 + channel * 470.0
				draw_line(Vector2(80, channel_y), Vector2(arena_size.x - 80, channel_y), Color(0.12, 0.35, 0.38, 0.55), 70.0, false)
				draw_line(Vector2(80, channel_y), Vector2(arena_size.x - 80, channel_y), Color(0.35, 0.68, 0.67, 0.42), 4.0, false)
			for lamp_index in 12:
				var lamp_position := Vector2(220.0 + (lamp_index % 6) * 620.0, 470.0 + floori(float(lamp_index) / 6.0) * 1150.0)
				draw_circle(lamp_position, 18.0, Color(0.86, 0.55, 0.25, 0.5))
				draw_arc(lamp_position, 28.0, 0, TAU, 18, Color(0.92, 0.73, 0.38, 0.65), 3.0, false)
		4:
			for ridge_index in floori(arena_size.x / 520.0):
				var ridge_center := Vector2(280.0 + ridge_index * 520.0, 420.0 + (ridge_index % 2) * 1450.0)
				draw_colored_polygon(PackedVector2Array([ridge_center + Vector2(-150, 90), ridge_center + Vector2(0, -120), ridge_center + Vector2(150, 90)]), Color(0.5, 0.65, 0.75, 0.22))
				draw_line(ridge_center + Vector2(-150, 90), ridge_center + Vector2(0, -120), Color(0.75, 0.88, 0.94, 0.45), 5.0)
				draw_line(ridge_center + Vector2(0, -120), ridge_center + Vector2(150, 90), Color(0.75, 0.88, 0.94, 0.45), 5.0)
	if endless_mode:
		for marker_index in 12:
			var marker_radius := 1050.0 if marker_index % 2 == 0 else 1720.0
			var marker_position := altar + Vector2.from_angle(TAU * float(marker_index) / 12.0) * marker_radius
			draw_rect(Rect2(marker_position - Vector2(28, 38), Vector2(56, 76)), Color(0.12, 0.1, 0.16, 0.72), true)
			draw_arc(marker_position, 48.0, 0, TAU, 24, Color(0.68, 0.48, 0.86, 0.5), 4.0, false)
			draw_line(marker_position + Vector2(-16, 0), marker_position + Vector2(16, 0), Color(0.86, 0.68, 0.42, 0.72), 4.0, false)
	draw_rect(Rect2(Vector2.ZERO, arena_size), stage_border, false, 5.0)
	for telegraph in attack_telegraphs:
		_draw_attack_telegraph(telegraph)

	for orb in xp_orbs:
		var position: Vector2 = orb["position"]
		draw_circle(position + Vector2(0, 5), 9.0, Color(0.25, 0.75, 0.55, 0.08))
		var points := PackedVector2Array([
			position + Vector2(0, -10),
			position + Vector2(6, 1),
			position + Vector2(0, 8),
			position + Vector2(-6, 1),
		])
		draw_colored_polygon(points, COLOR_XP)

	for loot_orb in loot_orbs:
		var loot_position: Vector2 = loot_orb["position"]
		draw_circle(loot_position, 22.0, Color(0.95, 0.7, 0.2, 0.1))
		_draw_pixel_texture(pixel_assets["weapons"]["chest"], loot_position + Vector2(0, sin(elapsed * 4.0) * 3.0), 0.0, 2.0)

	if weapon_levels.has("banner"):
		var banner_level := int(weapon_levels["banner"])
		var banner_radius := 125.0 + banner_level * 24.0 + (92.0 if evolved_weapons.has("banner") else 0.0)
		draw_circle(player_position, banner_radius, Color(0.48, 0.16, 0.12, 0.045))
		draw_arc(player_position, banner_radius, 0, TAU, 64, Color(0.72, 0.28, 0.18, 0.24), 2.0)
		draw_line(player_position + Vector2(-42, 20), player_position + Vector2(-42, -52), Color("7b5530"), 5.0)
		draw_colored_polygon(PackedVector2Array([
			player_position + Vector2(-40, -50),
			player_position + Vector2(-10, -42),
			player_position + Vector2(-40, -20),
		]), Color("8f3028"))

	if weapon_levels.has("orb"):
		var orb_level := int(weapon_levels["orb"])
		for combat_orb_position in _orb_positions(orb_level):
			var angle := (combat_orb_position - player_position).angle()
			_draw_pixel_texture(pixel_assets["weapons"]["orb"], combat_orb_position, angle, 1.7)

	for projectile in projectiles:
		var position: Vector2 = projectile["position"]
		var direction := Vector2(projectile["velocity"]).normalized()
		var projectile_radius := float(projectile["radius"])
		draw_line(position - direction * 28.0, position - direction * 8.0, Color(0.22, 0.9, 0.8, 0.16), projectile_radius + 7.0, false)
		draw_line(position - direction * 22.0, position - direction * 5.0, Color(0.55, 1.0, 0.88, 0.7), 3.0, false)
		draw_circle(position, projectile_radius + 5.0, Color(0.2, 0.95, 0.82, 0.13))
		draw_arc(position, projectile_radius + 4.0, 0, TAU, 12, COLOR_FRIENDLY_SHOT, 2.0, false)
		match String(projectile["kind"]):
			"talisman":
				_draw_pixel_texture(pixel_assets["weapons"]["talisman"], position, direction.angle() + PI * 0.5, 1.7)
			"coin":
				_draw_pixel_texture(pixel_assets["weapons"]["coin"], position, elapsed * 8.0, 1.5)
			"paper_doll":
				_draw_pixel_texture(pixel_assets["weapons"]["paper_doll"], position, 0.0, 2.0)
			"tide_gourd":
				_draw_pixel_texture(pixel_assets["weapons"]["tide_gourd"], position, direction.angle(), 2.0)
			"ice_needles":
				_draw_pixel_texture(pixel_assets["weapons"]["ice_needles"], position, direction.angle(), 1.8)
			_:
				_draw_pixel_texture(pixel_assets["weapons"]["sword"], position, direction.angle(), 2.0)

	for enemy in enemies:
		_draw_enemy(enemy)

	for effect in area_effects:
		_draw_area_effect(effect)

	for shot in enemy_projectiles:
		_draw_enemy_projectile(shot)

	if pulse_visual_timer > 0.0:
		var progress := 1.0 - pulse_visual_timer / 0.4
		var seal_radius := lerpf(42.0, 280.0, progress)
		var seal_color := COLOR_TALISMAN
		seal_color.a = 1.0 - progress
		draw_arc(pulse_origin, seal_radius, 0, TAU, 64, seal_color, 7.0, false)
		draw_arc(pulse_origin, seal_radius * 0.62, 0, TAU, 48, seal_color, 3.0, false)
		for index in 8:
			var direction := Vector2.from_angle(TAU * float(index) / 8.0)
			draw_line(pulse_origin + direction * seal_radius * 0.68, pulse_origin + direction * seal_radius * 0.93, seal_color, 3.0)

	if hurt_timer > 0.0:
		draw_circle(player_position, 58.0 + hurt_timer * 36.0, Color(0.95, 0.08, 0.08, hurt_timer * 0.18))
	if player_slow_timer > 0.0:
		draw_arc(player_position, 46.0, 0, TAU, 24, Color(0.68, 0.38, 0.9, 0.72), 4.0, false)
		for index in 4:
			var slow_direction := Vector2.from_angle(TAU * float(index) / 4.0 + elapsed)
			draw_circle(player_position + slow_direction * 40.0, 4.0, Color(0.75, 0.5, 0.95, 0.8))
	draw_rect(Rect2(player_position + Vector2(-17, 18), Vector2(34, 6)), Color(0, 0, 0, 0.36), true)
	var player_frame: int = floori(player_walk_phase) % pixel_assets["player"].size() if player_moving else 0
	var player_modulate := Color(1.8, 1.8, 1.8, 1.0) if hurt_timer > 0.28 else Color.WHITE
	_draw_pixel_texture(pixel_assets["player"][player_frame], player_position - Vector2(0, 6), 0.0, 2.0, player_modulate)
	draw_arc(player_position, pickup_radius, 0, TAU, 56, Color(0.4, 0.8, 0.62, 0.07), 1.0)


func _draw_enemy(enemy: Dictionary) -> void:
	var position: Vector2 = enemy["position"]
	var radius: float = enemy["radius"]
	if bool(enemy.get("dash_warning", false)):
		var dash_direction: Vector2 = enemy["dash_direction"]
		var warning_color := Color(1.0, 0.2, 0.18, 0.52 + sin(elapsed * 16.0) * 0.18)
		draw_line(position, position + dash_direction * 190.0, Color(0.2, 0.02, 0.02, 0.7), 12.0, false)
		draw_line(position, position + dash_direction * 190.0, warning_color, 4.0, false)
		draw_arc(position, radius + 8.0, 0, TAU, 20, warning_color, 3.0, false)
	if float(enemy.get("cast_timer", 0.0)) > 0.0:
		var cast_color := Color(1.0, 0.42, 0.18, 0.72)
		draw_arc(position, radius + 12.0, elapsed * 5.0, elapsed * 5.0 + PI * 1.4, 20, cast_color, 4.0, false)
	draw_arc(position + Vector2(0, radius * 0.48), radius * 0.86, 0.12, PI - 0.12, 16, Color(0.82, 0.12, 0.16, 0.5), 3.0, false)
	draw_rect(Rect2(position + Vector2(-radius * 0.72, radius * 0.58), Vector2(radius * 1.44, 6.0)), Color(0, 0, 0, 0.34), true)
	if bool(enemy["boss"]):
		draw_arc(position, radius + 13.0, 0, TAU, 28, Color(0.95, 0.17, 0.2, 0.52), 4.0, false)
		if not String(enemy.get("boss_modifier", "")).is_empty():
			draw_arc(position, radius + 21.0, elapsed * 0.7, elapsed * 0.7 + PI * 1.55, 32, Color(0.75, 0.52, 1.0, 0.78), 5.0, false)
	if bool(enemy["elite"]):
		var marker := radius + 10.0
		draw_line(position + Vector2(-marker, -marker), position + Vector2(-marker + 10, -marker), COLOR_TALISMAN, 4.0)
		draw_line(position + Vector2(marker - 10, marker), position + Vector2(marker, marker), COLOR_TALISMAN, 4.0)
	match String(enemy.get("modifier", "")):
		"swift":
			for marker_index in 3:
				var swift_offset := Vector2(-radius - 11.0 - marker_index * 6.0, -8.0 + marker_index * 8.0)
				draw_line(position + swift_offset, position + swift_offset + Vector2(10, 0), Color("72e0d1"), 3.0, false)
		"giant":
			draw_arc(position, radius + 8.0, 0, TAU, 24, Color(0.95, 0.62, 0.25, 0.72), 4.0, false)
		"warded":
			if int(enemy.get("ward_charges", 0)) > 0:
				draw_arc(position, radius + 9.0, 0, TAU, 28, Color(0.48, 0.82, 1.0, 0.78), 4.0, false)
		"vengeful":
			draw_arc(position, radius + 8.0, elapsed * 2.2, elapsed * 2.2 + PI * 1.45, 22, Color(1.0, 0.28, 0.24, 0.78), 4.0, false)
	var enemy_role := String(enemy.get("role", ""))
	if enemy_role == "summoner":
		draw_colored_polygon(PackedVector2Array([position + Vector2(0, -radius - 18), position + Vector2(8, -radius - 6), position + Vector2(-8, -radius - 6)]), Color("e8bd58"))
	elif enemy_role == "revenant":
		draw_circle(position + Vector2(0, -radius - 11), 7.0, Color("7ee0b0"))
	elif enemy_role == "controller":
		var marker_position := position + Vector2(0, -radius - 12)
		draw_colored_polygon(PackedVector2Array([marker_position + Vector2(0, -8), marker_position + Vector2(8, 0), marker_position + Vector2(0, 8), marker_position + Vector2(-8, 0)]), Color("b27bd6"))
	elif enemy_role == "array_eye":
		var eye_marker := position + Vector2(0, -radius - 13)
		draw_arc(eye_marker, 9.0, 0, TAU, 16, Color("f2a35f"), 3.0, false)
		draw_circle(eye_marker, 3.5, Color("fff0bc"))
	elif enemy_role == "healer":
		draw_arc(position, radius + 11.0, elapsed * 2.0, elapsed * 2.0 + PI * 1.5, 18, Color(0.4, 0.95, 0.58, 0.75), 3.0, false)
	elif enemy_role == "frost_jailer":
		draw_circle(position, 160.0, Color(0.35, 0.65, 0.88, 0.055))
		draw_arc(position, 160.0, 0, TAU, 42, Color(0.52, 0.75, 0.92, 0.3), 3.0, false)
	if float(enemy.get("revive_timer", 0.0)) > 0.0:
		var revive_progress := 1.0 - float(enemy["revive_timer"]) / 1.6
		draw_arc(position, radius + 12.0 + revive_progress * 18.0, 0, TAU, 24, Color(0.45, 0.95, 0.7, 0.85), 5.0, false)
	var frames: Array
	if bool(enemy["boss"]):
		frames = pixel_assets["bosses"][int(enemy["boss_variant"])]
	else:
		frames = pixel_assets["enemies"][String(enemy["kind"])]
	var frame := floori(elapsed * 5.0 + float(enemy["phase"])) % frames.size()
	var texture: Texture2D = frames[frame]
	var modulate := Color(1.8, 1.8, 1.8, 1.0) if float(enemy["hit_flash"]) > 0.0 else Color.WHITE
	if float(enemy.get("revive_timer", 0.0)) > 0.0:
		modulate = Color(0.55, 0.9, 0.7, 0.42)
	_draw_pixel_texture(texture, position - Vector2(0, 4), 0.0, 2.0, modulate)
	if float(enemy["hp"]) < float(enemy["max_hp"]):
		var width := radius * 2.0
		var ratio := maxf(0.0, float(enemy["hp"]) / float(enemy["max_hp"]))
		draw_rect(Rect2(position + Vector2(-radius, -radius - 13), Vector2(width, 5)), Color("351b17"))
		draw_rect(Rect2(position + Vector2(-radius, -radius - 13), Vector2(width * ratio, 5)), COLOR_DANGER)


func _draw_attack_telegraph(telegraph: Dictionary) -> void:
	var position: Vector2 = telegraph["position"]
	var direction: Vector2 = telegraph["direction"]
	var progress := 1.0 - float(telegraph["life"]) / float(telegraph["max_life"])
	var alpha := 0.3 + progress * 0.55
	var warning_color := Color(1.0, 0.2, 0.16, alpha)
	if String(telegraph["kind"]) == "boss_cross":
		var cross_direction := direction.normalized()
		var cross_width := float(telegraph["width"])
		for beam_direction in [cross_direction, cross_direction.orthogonal()]:
			draw_line(position - beam_direction * 720.0, position + beam_direction * 720.0, Color(0.18, 0.01, 0.02, alpha * 0.72), cross_width + 15.0, false)
			draw_line(position - beam_direction * 720.0, position + beam_direction * 720.0, Color(0.95, 0.18, 0.12, alpha), 5.0 + progress * 4.0, false)
		draw_arc(position, 44.0 + progress * 16.0, 0, TAU, 24, warning_color, 5.0, false)
		return
	if String(telegraph["kind"]) == "boss_summon":
		var summon_color := Color(0.52, 0.95, 0.68, alpha) if int(telegraph["variant"]) == 1 else Color(0.95, 0.56, 0.3, alpha)
		draw_circle(position, 105.0, Color(summon_color.r, summon_color.g, summon_color.b, 0.05 + progress * 0.08))
		draw_arc(position, 78.0 + progress * 28.0, elapsed * 2.5, elapsed * 2.5 + PI * 1.55, 30, summon_color, 6.0, false)
		for index in 6:
			var rune_direction := Vector2.from_angle(TAU * float(index) / 6.0 + elapsed)
			draw_circle(position + rune_direction * 82.0, 6.0, summon_color)
		return
	if String(telegraph["kind"]) == "boss_wheel":
		var safe_angle := float(telegraph["safe_angle"])
		var boss_phase := int(telegraph["boss_phase"])
		var safe_half_width := 0.34 - boss_phase * 0.025
		for index in 28:
			var ray_angle := TAU * float(index) / 28.0
			var angle_distance := absf(wrapf(ray_angle - safe_angle + PI, 0.0, TAU) - PI)
			if angle_distance < safe_half_width:
				continue
			var ray_direction := Vector2.from_angle(ray_angle)
			draw_line(position + ray_direction * 78.0, position + ray_direction * (128.0 + progress * 48.0), warning_color, 4.0, false)
		var safe_color := Color(0.35, 0.95, 0.66, alpha)
		for edge in [-safe_half_width, safe_half_width]:
			var safe_direction := Vector2.from_angle(safe_angle + edge)
			draw_line(position + safe_direction * 62.0, position + safe_direction * 230.0, safe_color, 5.0, false)
		draw_arc(position, 72.0 + progress * 14.0, 0, TAU, 32, warning_color, 5.0, false)
		return
	if String(telegraph["kind"]) == "ice_burst":
		var ice_color := Color(0.55, 0.82, 1.0, alpha)
		draw_arc(position, 38.0 + progress * 18.0, 0, TAU, 20, ice_color, 5.0, false)
		for index in 8:
			var ice_direction := Vector2.from_angle(TAU * float(index) / 8.0)
			draw_line(position + ice_direction * 26.0, position + ice_direction * 82.0, ice_color, 3.0, false)
		return
	if String(telegraph["kind"]) == "tide_lane":
		var tide_color := Color(0.25, 0.78, 0.88, alpha)
		draw_line(position - direction * 700.0, position + direction * 700.0, Color(0.06, 0.28, 0.34, 0.12 + progress * 0.12), float(telegraph["width"]) * 2.0, false)
		draw_line(position - direction * 700.0, position + direction * 700.0, tide_color, 5.0, false)
		return
	if String(telegraph["kind"]) == "avalanche":
		var avalanche_perpendicular := direction.orthogonal()
		var snow_color := Color(0.72, 0.9, 1.0, alpha)
		for shot_index in 11:
			var marker := position - direction * 520.0 + avalanche_perpendicular * float(shot_index - 5) * 95.0
			if absi(shot_index - int(telegraph["gap_index"])) <= 1:
				draw_line(marker - avalanche_perpendicular * 35.0, marker + avalanche_perpendicular * 35.0, Color(0.38, 0.95, 0.68, alpha), 5.0, false)
				continue
			draw_line(marker, marker + direction * (95.0 + progress * 55.0), snow_color, 9.0, false)
		return
	if String(telegraph["kind"]) == "area":
		var radius := float(telegraph["radius"])
		var effect_type := String(telegraph.get("effect", "grave"))
		var is_snare := effect_type == "snare"
		var is_bone_wall := effect_type == "bone_wall"
		var area_color := Color(0.9, 0.72, 0.5, alpha) if is_bone_wall else (Color(0.72, 0.38, 0.9, alpha) if is_snare else Color(0.5, 0.82, 0.72, alpha))
		var area_fill := Color(0.48, 0.28, 0.12, 0.05 + progress * 0.08) if is_bone_wall else (Color(0.35, 0.12, 0.5, 0.05 + progress * 0.08) if is_snare else Color(0.18, 0.45, 0.38, 0.05 + progress * 0.08))
		draw_circle(position, radius, area_fill)
		draw_arc(position, radius, 0, TAU, 28, area_color, 4.0, false)
		draw_line(position + Vector2(-radius * 0.7, 0), position + Vector2(radius * 0.7, 0), area_color, 3.0, false)
		draw_line(position + Vector2(0, -radius * 0.7), position + Vector2(0, radius * 0.7), area_color, 3.0, false)
		return
	if String(telegraph["kind"]) == "aimed":
		draw_line(position, position + direction * 470.0, Color(0.2, 0.01, 0.01, alpha * 0.72), 10.0, false)
		draw_line(position, position + direction * 470.0, warning_color, 3.0, false)
		draw_arc(position, 20.0 + progress * 8.0, 0, TAU, 18, warning_color, 3.0, false)
		return
	var variant := int(telegraph["variant"])
	var attack_count := int(telegraph["attack_count"])
	if variant == 0 or attack_count % 2 == 0 or variant == 2:
		draw_circle(position, 76.0, Color(0.85, 0.05, 0.1, 0.05 + progress * 0.08))
		draw_arc(position, 64.0 + progress * 13.0, 0, TAU, 32, warning_color, 5.0, false)
		for index in 8:
			var ray := Vector2.from_angle(TAU * float(index) / 8.0)
			draw_line(position + ray * 80.0, position + ray * 120.0, warning_color, 3.0, false)
	if variant > 0 and (attack_count % 2 == 1 or variant == 2):
		for offset in [-0.42, 0.42]:
			draw_line(position, position + direction.rotated(offset) * 520.0, warning_color, 4.0, false)
		draw_colored_polygon(PackedVector2Array([
			position,
			position + direction.rotated(-0.42) * 270.0,
			position + direction.rotated(0.42) * 270.0,
		]), Color(0.9, 0.05, 0.12, 0.035 + progress * 0.045))


func _draw_enemy_projectile(shot: Dictionary) -> void:
	var position: Vector2 = shot["position"]
	var direction := Vector2(shot["velocity"]).normalized()
	var radius := maxf(6.0, float(shot["radius"]) * 0.78)
	var pulse := 0.8 + sin(elapsed * 11.0 + position.x * 0.02) * 0.5
	var tail_end := position - direction * (18.0 + radius)
	draw_line(tail_end, position - direction * radius * 0.45, Color(0.13, 0.01, 0.035, 0.82), 7.0, false)
	draw_line(tail_end, position - direction * radius * 0.35, Color(1.0, 0.08, 0.3, 0.78), 3.0, false)
	draw_circle(position, radius + 4.0 + pulse, Color(1.0, 0.03, 0.22, 0.13))
	draw_arc(position, radius + 2.0 + pulse, 0, TAU, 14, Color(1.0, 0.18, 0.33, 0.92), 2.0, false)
	var outer := PackedVector2Array([
		position - direction * radius,
		position + direction.orthogonal() * radius * 0.72,
		position + direction * radius,
		position - direction.orthogonal() * radius * 0.72,
	])
	draw_colored_polygon(outer, Color("4b071a"))
	var inner_radius := radius * 0.68
	var inner := PackedVector2Array([
		position - direction * inner_radius,
		position + direction.orthogonal() * inner_radius * 0.7,
		position + direction * inner_radius,
		position - direction.orthogonal() * inner_radius * 0.7,
	])
	draw_colored_polygon(inner, COLOR_ENEMY_SHOT)
	draw_circle(position, maxf(2.0, radius * 0.25), Color("fff0d2"))


func _draw_pixel_texture(texture: Texture2D, position: Vector2, rotation: float = 0.0, scale: float = 2.0, modulate: Color = Color.WHITE) -> void:
	draw_set_transform(position.round(), rotation, Vector2(scale, scale))
	draw_texture(texture, -texture.get_size() * 0.5, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_area_effect(effect: Dictionary) -> void:
	var position: Vector2 = effect["position"]
	var progress := 1.0 - float(effect["life"]) / float(effect["max_life"])
	match String(effect["kind"]):
		"algae_pool":
			var algae_color := Color(0.2, 0.55, 0.38, 0.32 * (1.0 - progress * 0.35))
			draw_circle(position, float(effect["radius"]), algae_color)
			draw_arc(position, float(effect["radius"]), 0, TAU, 24, Color(0.45, 0.8, 0.5, 0.55), 3.0, false)
		"boat_wake":
			var wake_color := Color(0.3, 0.78, 0.85, 0.5 * (1.0 - progress))
			draw_line(position, Vector2(effect["end"]), Color(0.1, 0.35, 0.42, 0.2 * (1.0 - progress)), float(effect["radius"]) * 2.0, false)
			draw_line(position, Vector2(effect["end"]), wake_color, 5.0, false)
		"heal":
			var heal_radius := float(effect["radius"]) * (0.4 + progress * 0.6)
			draw_arc(position, heal_radius, 0, TAU, 36, Color(0.35, 0.95, 0.58, 0.72 * (1.0 - progress)), 5.0, false)
		"ward_break":
			var ward_radius := float(effect["radius"]) * (0.75 + progress * 0.65)
			draw_arc(position, ward_radius, 0, TAU, 28, Color(0.48, 0.82, 1.0, 0.82 * (1.0 - progress)), 6.0, false)
		"ink_stroke":
			var ink_color := Color(0.86, 0.18, 0.14, 0.82 * (1.0 - progress))
			draw_line(position, Vector2(effect["end"]), Color(0.12, 0.015, 0.02, 0.28 * (1.0 - progress)), float(effect["radius"]) * 2.4, false)
			draw_line(position, Vector2(effect["end"]), ink_color, float(effect["radius"]) * (1.0 - progress * 0.55), false)
		"soul_burst":
			var soul_radius := float(effect["radius"]) * (0.45 + progress * 0.65)
			draw_circle(position, soul_radius, Color(0.32, 0.2, 0.55, 0.11 * (1.0 - progress)))
			draw_arc(position, soul_radius, elapsed * 1.6, elapsed * 1.6 + PI * 1.75, 40, Color(0.75, 0.58, 1.0, 0.78 * (1.0 - progress)), 6.0, false)
			_draw_pixel_texture(pixel_assets["weapons"]["soul_lantern"], position, elapsed * 0.4, 1.7, Color(1.0, 1.0, 1.0, 1.0 - progress))
		"lotus":
			var lotus_radius := float(effect["radius"])
			draw_circle(position, lotus_radius, Color(0.22, 0.52, 0.58, 0.09))
			draw_arc(position, lotus_radius, elapsed * 0.7, elapsed * 0.7 + PI * 1.6, 40, Color(0.4, 0.9, 0.82, 0.58), 4.0, false)
			for petal_index in 6:
				var petal_direction := Vector2.from_angle(TAU * float(petal_index) / 6.0 + elapsed * 0.4)
				draw_circle(position + petal_direction * 24.0, 8.0, Color(0.75, 0.9, 0.7, 0.65))
		"lotus_burst":
			var lotus_burst_radius := float(effect["radius"]) * progress
			draw_arc(position, lotus_burst_radius, 0, TAU, 42, Color(0.55, 1.0, 0.82, 0.75 * (1.0 - progress)), 7.0, false)
		"frost_warning":
			var warning_radius := float(effect["radius"])
			draw_circle(position, warning_radius, Color(0.35, 0.65, 0.88, 0.05 + progress * 0.08))
			draw_arc(position, warning_radius, 0, TAU, 32, Color(0.65, 0.88, 1.0, 0.45 + progress * 0.45), 5.0, false)
			draw_line(position + Vector2(-warning_radius, 0), position + Vector2(warning_radius, 0), Color(0.75, 0.92, 1.0, 0.5), 3.0, false)
			draw_line(position + Vector2(0, -warning_radius), position + Vector2(0, warning_radius), Color(0.75, 0.92, 1.0, 0.5), 3.0, false)
		"frost_stele":
			var stele_radius := float(effect["radius"]) * (0.45 + progress * 0.7)
			draw_circle(position, stele_radius, Color(0.35, 0.7, 0.95, 0.18 * (1.0 - progress)))
			draw_arc(position, stele_radius, 0, TAU, 32, Color(0.75, 0.94, 1.0, 0.8 * (1.0 - progress)), 7.0, false)
		"oar":
			var oar_direction: Vector2 = effect["direction"]
			var oar_color := Color(0.5, 0.9, 0.82, 0.68 * (1.0 - progress))
			draw_arc(position, float(effect["radius"]), oar_direction.angle() - (PI if bool(effect["full"]) else PI / 3.0), oar_direction.angle() + (PI if bool(effect["full"]) else PI / 3.0), 42, oar_color, 8.0, false)
		"umbrella":
			var umbrella_direction: Vector2 = effect["direction"]
			var umbrella_color := Color(0.72, 0.9, 1.0, 0.7 * (1.0 - progress))
			draw_arc(position, float(effect["radius"]), umbrella_direction.angle() - (PI if bool(effect["full"]) else PI * 0.45), umbrella_direction.angle() + (PI if bool(effect["full"]) else PI * 0.45), 44, umbrella_color, 7.0, false)
		"tide_lane":
			var tide_direction: Vector2 = effect["direction"]
			draw_line(position - tide_direction * 700.0, position + tide_direction * 700.0, Color(0.25, 0.75, 0.86, 0.35 * (1.0 - progress)), float(effect["radius"]) * 2.0, false)
		"bone_wall":
			var wall_radius := float(effect["radius"])
			var wall_alpha := 0.45 + sin(elapsed * 8.0) * 0.12
			draw_circle(position, wall_radius, Color(0.32, 0.19, 0.12, wall_alpha * 0.45))
			draw_arc(position, wall_radius, 0, TAU, 20, Color(0.9, 0.75, 0.55, wall_alpha), 6.0, false)
			draw_line(position + Vector2(-18, -22), position + Vector2(18, 22), Color(0.95, 0.86, 0.68, wall_alpha), 5.0, false)
			draw_line(position + Vector2(18, -22), position + Vector2(-18, 22), Color(0.95, 0.86, 0.68, wall_alpha), 5.0, false)
		"boss_cross":
			var cross_direction: Vector2 = effect["direction"]
			var cross_color := Color(1.0, 0.28, 0.18, 0.72 * (1.0 - progress))
			for beam_direction in [cross_direction, cross_direction.orthogonal()]:
				draw_line(position - beam_direction * float(effect["radius"]), position + beam_direction * float(effect["radius"]), cross_color, 16.0 * (1.0 - progress), false)
		"boss_wheel":
			var wheel_radius := float(effect["radius"]) * (0.8 + progress * 0.45)
			var wheel_color := Color(0.95, 0.3, 0.18, 0.68 * (1.0 - progress))
			draw_arc(position, wheel_radius, 0, TAU, 32, wheel_color, 7.0, false)
		"snare":
			var snare_radius := float(effect["radius"]) * (0.8 + progress * 0.2)
			var snare_color := Color(0.72, 0.42, 0.95, 0.75 * (1.0 - progress))
			draw_circle(position, snare_radius, Color(0.38, 0.12, 0.55, 0.13 * (1.0 - progress)))
			draw_arc(position, snare_radius, 0, TAU, 24, snare_color, 5.0, false)
		"revive":
			var revive_radius := float(effect["radius"]) * (1.0 + progress)
			draw_arc(position, revive_radius, 0, TAU, 20, Color(0.45, 0.95, 0.68, 0.65 * (1.0 - progress)), 4.0, false)
		"grave":
			var grave_radius := float(effect["radius"]) * (0.65 + progress * 0.5)
			var grave_color := Color(0.55, 0.95, 0.78, 0.75 * (1.0 - progress))
			draw_circle(position, grave_radius, Color(0.1, 0.45, 0.28, 0.16 * (1.0 - progress)))
			draw_arc(position, grave_radius, 0, TAU, 24, grave_color, 5.0, false)
		"death":
			var burst_radius := float(effect["radius"]) * (0.7 + progress * 1.2)
			var burst_color := Color(0.92, 0.28, 0.18, 0.7 * (1.0 - progress))
			draw_arc(position, burst_radius, 0, TAU, 16, burst_color, 4.0, false)
			for index in 6:
				var direction := Vector2.from_angle(TAU * float(index) / 6.0)
				draw_line(position + direction * burst_radius * 0.45, position + direction * burst_radius * 1.35, burst_color, 3.0, false)
		"fire":
			var fire_color := COLOR_TALISMAN
			fire_color.a = 0.8 * (1.0 - progress)
			draw_circle(position, float(effect["radius"]) * progress, Color(0.85, 0.2, 0.08, 0.12 * (1.0 - progress)))
			draw_arc(position, float(effect["radius"]) * progress, 0, TAU, 48, fire_color, 6.0, false)
		"bell":
			var bell_color := COLOR_PLAYER_CORE
			bell_color.a = 0.72 * (1.0 - progress)
			draw_arc(position, float(effect["radius"]) * progress, 0, TAU, 56, bell_color, 5.0, false)
			draw_arc(position, float(effect["radius"]) * progress * 0.72, 0, TAU, 48, bell_color, 2.0, false)
		"lightning":
			var points := PackedVector2Array([
				position + Vector2(-34, -190),
				position + Vector2(12, -148),
				position + Vector2(-18, -105),
				position + Vector2(15, -62),
				position + Vector2(-6, -27),
				position,
			])
			var lightning_color := COLOR_LIGHTNING
			lightning_color.a = 1.0 - progress
			draw_polyline(points, lightning_color, 7.0, false)
			draw_polyline(points, Color(0.9, 0.95, 1.0, 1.0 - progress), 2.0, false)
			if float(effect["radius"]) > 0.0:
				draw_arc(position, float(effect["radius"]) * (0.7 + progress * 0.3), 0, TAU, 28, lightning_color, 4.0, false)
		"chain":
			var chain_color := COLOR_TALISMAN
			chain_color.a = 1.0 - progress
			draw_polyline(PackedVector2Array(effect["points"]), chain_color, 5.0, false)
			for point in PackedVector2Array(effect["points"]):
				draw_circle(point, 5.0, chain_color)
		"mirror":
			var mirror_color := COLOR_PLAYER_CORE
			mirror_color.a = 0.78 * (1.0 - progress)
			draw_line(position, Vector2(effect["end"]), Color(0.8, 0.95, 0.78, 0.12 * (1.0 - progress)), float(effect["radius"]) * 2.2, false)
			draw_line(position, Vector2(effect["end"]), mirror_color, 5.0, false)
