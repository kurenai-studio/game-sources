extends Node
## Teste de Integração Completo: Tutorial + 50 Níveis
## Executa com: godot --headless --path . -- --playthrough-50

class TestMetrics:
	var total_logs: int = 0
	var errors: int = 0
	var warnings: int = 0
	var critical: int = 0
	var test_duration: float = 0.0
	var levels_completed: int = 0
	var memory_samples: Array[float] = []

class TestLog:
	var timestamp: float
	var level: String
	var component: String
	var message: String
	
	func to_dict() -> Dictionary:
		return {"time": timestamp, "level": level, "component": component, "message": message}

var metrics: TestMetrics = TestMetrics.new()
var logs: Array[TestLog] = []
var test_start_time: float
var current_level: int = 0
var critical_errors: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	test_start_time = Time.get_ticks_msec()
	_log("PLAYTHROUGH", "INFO", "=== TESTE DE 50 NÍVEIS INICIADO ===")
	_run.call_deferred()

func _log(component: String, level: String, message: String) -> void:
	var log = TestLog.new()
	log.timestamp = (Time.get_ticks_msec() - test_start_time) / 1000.0
	log.level = level
	log.component = component
	log.message = message
	logs.append(log)
	
	metrics.total_logs += 1
	match level:
		"ERROR":
			metrics.errors += 1
		"WARN":
			metrics.warnings += 1
		"CRITICAL":
			metrics.critical += 1
			critical_errors.append("[%s] %s: %s" % [component, level, message])
	
	var color = ""
	match level:
		"CRITICAL": color = "\u001b[91m"
		"ERROR": color = "\u001b[91m"
		"WARN": color = "\u001b[93m"
		"INFO": color = "\u001b[92m"
		_: color = "\u001b[94m"
	
	print("%s[%.2fs] [%s] %s: %s\u001b[0m" % [color, log.timestamp, level, component, message])

func _run() -> void:
	_log("PLAYTHROUGH", "INFO", "Fase 1: Validação de Inicialização")
	if not _validate_init():
		_finalize()
		return
	
	_log("PLAYTHROUGH", "INFO", "Fase 2: Prólogo e Tutorial")
	if not _run_tutorial():
		_finalize()
		return
	
	_log("PLAYTHROUGH", "INFO", "Fase 3: Criação de Personagem")
	if not _create_character():
		_finalize()
		return
	
	_log("PLAYTHROUGH", "INFO", "Fase 4: Simulação de 50 Níveis")
	await _simulate_50_levels()
	
	_log("PLAYTHROUGH", "INFO", "Fase 5: Análise de Performance")
	_analyze_performance()
	
	_finalize()

func _validate_init() -> bool:
	_log("INIT", "INFO", "Verificando singletons...")
	if Game == null or DB == null:
		_log("INIT", "CRITICAL", "Singletons não inicializados")
		return false
	
	if DB.EQUIP_SLOTS.size() != 11:
		_log("INIT", "ERROR", "EQUIP_SLOTS: %d slots (esperado 11)" % DB.EQUIP_SLOTS.size())
		return false
	
	_log("INIT", "INFO", "✓ Inicialização OK")
	return true

func _run_tutorial() -> bool:
	var hero = Hero.create_villager()
	if hero == null:
		_log("TUTORIAL", "CRITICAL", "Falha ao criar herói aldeão")
		return false
	
	if hero.inventory == null or hero.equipment.size() == 0:
		_log("TUTORIAL", "ERROR", "Inventário ou equipment não inicializados")
		return false
	
	_log("TUTORIAL", "INFO", "✓ Tutorial OK")
	return true

func _create_character() -> bool:
	var race = DB.races.pick_random()
	var cls = DB.CLASSES.pick_random()
	
	if race == null or cls == null:
		_log("CHARGEN", "CRITICAL", "Raça ou classe não disponível")
		return false
	
	var hero = Hero.create(
		"Herói Teste 50Lvl",
		race,
		cls,
		"m" if randf() > 0.5 else "f",
		Color(randf(), randf(), randf()),
		{"str": 15, "dex": 12, "con": 13, "int": 10, "wis": 11, "cha": 10}
	)
	
	if hero == null:
		_log("CHARGEN", "CRITICAL", "Falha ao criar herói")
		return false
	
	Game.hero = hero
	_log("CHARGEN", "INFO", "✓ Personagem: %s (%s/%s)" % [hero.hero_name, race.name, cls.name])
	return true

func _simulate_50_levels() -> void:
	var hero = Game.hero
	
	for level_num in range(1, 51):
		current_level = level_num
		
		# Simular XP e level up
		var xp_needed = hero.xp_to_next()
		hero.add_xp(xp_needed + 1)
		
		# Validar stats a cada 10 níveis
		if level_num % 10 == 0:
			_validate_hero_stats(hero, level_num)
			_sample_memory()
		
		# Simular equipagem de item a cada 5 níveis
		if level_num % 5 == 0:
			_equip_random_item(hero)
		
		# Simular combate
		if level_num % 3 == 0:
			_simulate_combat(hero)
		
		if level_num % 10 == 0:
			_log("GAMEPLAY", "INFO", "Nível %d completado" % level_num)
	
	metrics.levels_completed = 50
	_log("GAMEPLAY", "INFO", "✓ 50 níveis completados")

func _validate_hero_stats(hero: Hero, level: int) -> void:
	var hp = hero.max_hp()
	var armor = hero.armor()
	var dps = hero.dps_estimate()
	
	if hp <= 0:
		_log("VALIDATE", "ERROR", "Nível %d: Vida inválida (%d)" % [level, hp])
	
	if dps < 1.0:
		_log("VALIDATE", "WARN", "Nível %d: DPS muito baixo (%.1f)" % [level, dps])
	
	_log("GAMEPLAY", "INFO", "L%d: HP=%d, ARM=%d, DPS=%.1f" % [level, hp, armor, dps])

func _equip_random_item(hero: Hero) -> void:
	var item = DB.create_item(&"sword", hero.level, [Item.Rarity.MAGIC, Item.Rarity.RARE, Item.Rarity.LEGENDARY].pick_random() if randf() > 0.7 else Item.Rarity.COMMON)
	var result = hero.equip(item)
	if result.size() > 0:
		_log("GAMEPLAY", "INFO", "Item desequipado: %s" % result[0].name)

func _simulate_combat(hero: Hero) -> void:
	# Simular dano recebido
	var damage = randf_range(5.0, hero.max_hp() * 0.3)
	hero.take_damage(damage)
	
	if hero.is_dead():
		hero.hp = hero.max_hp()  # Reviver para continuar teste

func _sample_memory() -> void:
	if OS.get_static_memory_usage() > 0:
		metrics.memory_samples.append(float(OS.get_static_memory_usage()) / (1024 * 1024))

func _analyze_performance() -> void:
	_log("PERF", "INFO", "Analisando performance...")
	
	if metrics.memory_samples.size() > 0:
		var max_mem = metrics.memory_samples.max()
		var avg_mem = metrics.memory_samples.reduce(func(a, b): return a + b) / metrics.memory_samples.size()
		_log("PERF", "INFO", "Memory: Max=%.1fMB, Avg=%.1fMB" % [max_mem, avg_mem])

func _finalize() -> void:
	metrics.test_duration = (Time.get_ticks_msec() - test_start_time) / 1000.0
	
	print("\n" + "═".repeat(60))
	print("RELATÓRIO FINAL - TESTE DE 50 NÍVEIS")
	print("═".repeat(60))
	print("\nDuração: %.2fs" % metrics.test_duration)
	print("Níveis Completados: %d/50" % metrics.levels_completed)
	print("Total de Logs: %d" % metrics.total_logs)
	print("Erros: %d" % metrics.errors)
	print("Avisos: %d" % metrics.warnings)
	print("Críticos: %d" % metrics.critical)
	
	if critical_errors.size() > 0:
		print("\n❌ ERROS CRÍTICOS:")
		for err in critical_errors:
			print("  - %s" % err)
	
	if metrics.levels_completed == 50 and metrics.critical == 0 and metrics.errors == 0:
		print("\n✅ TESTE PASSOU COM SUCESSO!")
		print("Todos os 50 níveis foram completados sem erros críticos.")
	else:
		print("\n⚠️ TESTE FALHOU")
	
	print("\n" + "═".repeat(60))
	
	_save_report()
	get_tree().quit()

func _save_report() -> void:
	var report = {
		"timestamp": Time.get_datetime_string_from_system(),
		"duration": metrics.test_duration,
		"levels": metrics.levels_completed,
		"logs": metrics.total_logs,
		"errors": metrics.errors,
		"warnings": metrics.warnings,
		"critical": metrics.critical,
		"log_entries": []
	}
	
	for log in logs:
		report.log_entries.append(log.to_dict())
	
	var file = FileAccess.open("user://playthrough_50_report.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		print("✓ Relatório salvo: user://playthrough_50_report.json")
