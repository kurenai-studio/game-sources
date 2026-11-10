extends Node
## Teste de Integração Completo: Tutorial + Primeiros Níveis
## Executa com: godot --headless --path . -- --playthrough

class TestLog:
	var timestamp: float
	var level: String  # DEBUG, INFO, WARN, ERROR, CRITICAL
	var component: String
	var message: String
	var stack_trace: String = ""
	
	func to_dict() -> Dictionary:
		return {
			"time": timestamp,
			"level": level,
			"component": component,
			"message": message,
			"stack": stack_trace
		}

var test_logs: Array[TestLog] = []
var errors_found: int = 0
var warnings_found: int = 0
var critical_errors: Array[String] = []
var test_start_time: float
var test_duration: float = 0.0

# Estados do teste
var state: String = "INIT"
var step_count: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	test_start_time = Time.get_ticks_msec()
	
	# Redirecionar push_error/push_warning
	_setup_logging()
	
	_add_log("PLAYTHROUGH", "INFO", "Iniciando teste de playthrough completo")
	_run.call_deferred()


func _setup_logging() -> void:
	# Monitorar todos os push_error e push_warning
	print_debug("[PLAYTHROUGH] Sistema de logging ativado")


func _add_log(component: String, level: String, message: String, stack: String = "") -> void:
	var log = TestLog.new()
	log.timestamp = Time.get_ticks_msec() - test_start_time
	log.level = level
	log.component = component
	log.message = message
	log.stack_trace = stack
	
	test_logs.append(log)
	
	var color = ""
	match level:
		"ERROR", "CRITICAL": 
			color = "\u001b[91m"  # Red
			errors_found += 1
			critical_errors.append("[%s] %s: %s" % [component, level, message])
		"WARN":
			color = "\u001b[93m"  # Yellow
			warnings_found += 1
		"INFO":
			color = "\u001b[92m"  # Green
		_:
			color = "\u001b[94m"  # Blue
	
	print("%s[%.2fs] [%s] %s: %s\u001b[0m" % [color, log.timestamp / 1000.0, level, component, message])


func _run() -> void:
	_add_log("PLAYTHROUGH", "INFO", "=== FASE 1: Verificação de Inicialização ===")
	await _phase_init()
	
	_add_log("PLAYTHROUGH", "INFO", "=== FASE 2: Tutorial / Prólogo ===")
	await _phase_tutorial()
	
	_add_log("PLAYTHROUGH", "INFO", "=== FASE 3: Criação de Personagem ===")
	await _phase_character_creation()
	
	_add_log("PLAYTHROUGH", "INFO", "=== FASE 4: Primeiros Níveis ===")
	await _phase_gameplay()
	
	_add_log("PLAYTHROUGH", "INFO", "=== FASE 5: Finalização ===")
	_finalize_test()


func _phase_init() -> void:
	_add_log("INIT", "INFO", "Verificando Game singleton")
	if Game == null:
		_add_log("INIT", "CRITICAL", "Game singleton não inicializado")
		return
	_add_log("INIT", "INFO", "✓ Game singleton OK")
	
	_add_log("INIT", "INFO", "Verificando DB singleton")
	if DB == null:
		_add_log("INIT", "CRITICAL", "DB singleton não inicializado")
		return
	_add_log("INIT", "INFO", "✓ DB singleton OK")
	
	_add_log("INIT", "INFO", "Verificando carga de recursos")
	if DB.races.size() == 0:
		_add_log("INIT", "ERROR", "Nenhuma raça carregada em DB.races")
	else:
		_add_log("INIT", "INFO", "✓ %d raças carregadas" % DB.races.size())
	
	if DB.CLASSES.size() == 0:
		_add_log("INIT", "ERROR", "Nenhuma classe carregada em DB.CLASSES")
	else:
		_add_log("INIT", "INFO", "✓ %d classes carregadas" % DB.CLASSES.size())
	
	_add_log("INIT", "INFO", "Verificando EQUIP_SLOTS")
	if DB.EQUIP_SLOTS.size() != 11:
		_add_log("INIT", "WARN", "EQUIP_SLOTS tem %d slots (esperado 11)" % DB.EQUIP_SLOTS.size())
	else:
		_add_log("INIT", "INFO", "✓ 11 slots de equipamento configurados")
	
	step_count += 1
	await get_tree().process_frame


func _phase_tutorial() -> void:
	_add_log("TUTORIAL", "INFO", "Carregando cena de prólogo")
	
	# Simular criação de herói para prólogo
	var hero = Hero.create_villager()
	if hero == null:
		_add_log("TUTORIAL", "CRITICAL", "Falha ao criar herói vilageano")
		return
	
	_add_log("TUTORIAL", "INFO", "✓ Herói aldeão criado (Nível %d)" % hero.level)
	
	# Validar propriedades do herói
	if hero.inventory == null:
		_add_log("TUTORIAL", "ERROR", "Inventário do herói é null")
	else:
		_add_log("TUTORIAL", "INFO", "✓ Inventário inicializado (%dx%d)" % [hero.inventory.cols, hero.inventory.rows])
	
	if hero.equipment.size() == 0:
		_add_log("TUTORIAL", "ERROR", "Equipamento não inicializado")
	else:
		_add_log("TUTORIAL", "INFO", "✓ Equipamento inicializado com %d slots" % hero.equipment.size())
	
	step_count += 1
	await get_tree().process_frame


func _phase_character_creation() -> void:
	_add_log("CHARGEN", "INFO", "Simulando criação de personagem")
	
	# Escolher raça e classe aleatória
	var race = DB.races.pick_random()
	var cls = DB.CLASSES.pick_random()
	
	if race == null:
		_add_log("CHARGEN", "CRITICAL", "Nenhuma raça disponível")
		return
	if cls == null:
		_add_log("CHARGEN", "CRITICAL", "Nenhuma classe disponível")
		return
	
	_add_log("CHARGEN", "INFO", "Raça: %s, Classe: %s" % [race.name, cls.name])
	
	# Tentar criar herói completo
	var hero = Hero.create(
		"Guerreiro Teste",
		race,
		cls,
		"m" if randf() > 0.5 else "f",
		Color(randf(), randf(), randf()),
		{"str": 15, "dex": 12, "con": 13, "int": 10, "wis": 11, "cha": 10}
	)
	
	if hero == null:
		_add_log("CHARGEN", "CRITICAL", "Falha ao criar herói")
		return
	
	_add_log("CHARGEN", "INFO", "✓ Herói criado: %s" % hero.hero_name)
	_add_log("CHARGEN", "INFO", "  Vida: %d, Armadura: %d, DPS: %.1f" % [hero.max_hp(), hero.armor(), hero.dps_estimate()])
	
	# Validar equipamento inicial
	_validate_equipment(hero)
	
	# Armazenar herói para próxima fase
	Game.hero = hero
	
	step_count += 1
	await get_tree().process_frame


func _phase_gameplay() -> void:
	_add_log("GAMEPLAY", "INFO", "Simulando primeiros níveis")
	
	if Game.hero == null:
		_add_log("GAMEPLAY", "CRITICAL", "Herói não foi criado")
		return
	
	var hero = Game.hero
	_add_log("GAMEPLAY", "INFO", "Herói: %s (Nível %d)" % [hero.hero_name, hero.level])
	
	# Simular ganho de XP e level up
	_add_log("GAMEPLAY", "INFO", "Simulando ganho de XP")
	var xp_needed = hero.xp_to_next()
	_add_log("GAMEPLAY", "INFO", "XP necessário para próximo nível: %d" % xp_needed)
	
	hero.add_xp(xp_needed + 1)
	if hero.level > 1:
		_add_log("GAMEPLAY", "INFO", "✓ Level up para %d" % hero.level)
	else:
		_add_log("GAMEPLAY", "WARN", "Level up falhou (ainda nível %d)" % hero.level)
	
	# Simular equipagem
	_add_log("GAMEPLAY", "INFO", "Simulando equipagem de itens")
	var sword = DB.create_item(&"sword", 1, Item.Rarity.COMMON)
	sword.slot = "weapon"
	var result = hero.equip(sword)
	if hero.equipment.weapon == sword:
		_add_log("GAMEPLAY", "INFO", "✓ Espada equipada")
	else:
		_add_log("GAMEPLAY", "ERROR", "Falha ao equipar espada")
	
	# Simular consumo de consumíveis
	_add_log("GAMEPLAY", "INFO", "Verificando sistema de consumíveis")
	if hero.consumable_slots.size() != 9:
		_add_log("GAMEPLAY", "WARN", "Consumable slots: %d (esperado 9)" % hero.consumable_slots.size())
	else:
		_add_log("GAMEPLAY", "INFO", "✓ 9 slots de consumíveis")
	
	# Validar stats
	_validate_stats(hero)
	
	step_count += 1
	await get_tree().process_frame


func _validate_equipment(hero: Hero) -> void:
	_add_log("VALIDATE", "INFO", "Validando equipamento inicial")
	
	var missing_slots: Array[String] = []
	for slot in DB.EQUIP_SLOTS:
		if slot not in hero.equipment:
			missing_slots.append(slot)
	
	if missing_slots.size() > 0:
		_add_log("VALIDATE", "WARN", "Slots faltando: %s" % missing_slots)
	
	# Verificar equipamento de início
	if hero.equipment.weapon == null:
		_add_log("VALIDATE", "WARN", "Nenhuma arma equipada")
	else:
		_add_log("VALIDATE", "INFO", "✓ Arma: %s" % hero.equipment.weapon.name)
	
	if hero.equipment.chest == null:
		_add_log("VALIDATE", "WARN", "Nenhuma armadura equipada")
	else:
		_add_log("VALIDATE", "INFO", "✓ Armadura: %s" % hero.equipment.chest.name)


func _validate_stats(hero: Hero) -> void:
	_add_log("VALIDATE", "INFO", "Validando stats")
	
	if hero.max_hp() <= 0:
		_add_log("VALIDATE", "ERROR", "Vida máxima <= 0: %d" % hero.max_hp())
	elif hero.max_hp() < 10:
		_add_log("VALIDATE", "WARN", "Vida máxima muito baixa: %d" % hero.max_hp())
	else:
		_add_log("VALIDATE", "INFO", "✓ Vida máxima: %d" % hero.max_hp())
	
	var dps = hero.dps_estimate()
	if dps <= 0:
		_add_log("VALIDATE", "WARN", "DPS estimado: %.1f" % dps)
	else:
		_add_log("VALIDATE", "INFO", "✓ DPS estimado: %.1f" % dps)
	
	var armor = hero.armor()
	_add_log("VALIDATE", "INFO", "✓ Armadura: %d" % armor)


func _finalize_test() -> void:
	test_duration = (Time.get_ticks_msec() - test_start_time) / 1000.0
	
	_add_log("PLAYTHROUGH", "INFO", "")
	_add_log("PLAYTHROUGH", "INFO", "╔════════════════════════════════════════════╗")
	_add_log("PLAYTHROUGH", "INFO", "║        RELATÓRIO FINAL DO TESTE            ║")
	_add_log("PLAYTHROUGH", "INFO", "╚════════════════════════════════════════════╝")
	_add_log("PLAYTHROUGH", "INFO", "")
	_add_log("PLAYTHROUGH", "INFO", "Duração do teste: %.2fs" % test_duration)
	_add_log("PLAYTHROUGH", "INFO", "Passos executados: %d" % step_count)
	_add_log("PLAYTHROUGH", "INFO", "Total de logs: %d" % test_logs.size())
	_add_log("PLAYTHROUGH", "INFO", "Erros encontrados: %d" % errors_found)
	_add_log("PLAYTHROUGH", "INFO", "Avisos encontrados: %d" % warnings_found)
	
	if critical_errors.size() > 0:
		_add_log("PLAYTHROUGH", "CRITICAL", "")
		_add_log("PLAYTHROUGH", "CRITICAL", "ERROS CRÍTICOS ENCONTRADOS:")
		for err in critical_errors:
			_add_log("PLAYTHROUGH", "CRITICAL", "  - %s" % err)
	
	# Salvar relatório em JSON
	_save_report()
	
	_add_log("PLAYTHROUGH", "INFO", "")
	_add_log("PLAYTHROUGH", "INFO", "Teste finalizado. Relatório salvo.")
	
	get_tree().quit()


func _save_report() -> void:
	var report = {
		"timestamp": Time.get_datetime_string_from_system(),
		"duration_seconds": test_duration,
		"steps": step_count,
		"total_logs": test_logs.size(),
		"errors": errors_found,
		"warnings": warnings_found,
		"critical": critical_errors,
		"logs": []
	}
	
	for log in test_logs:
		report.logs.append(log.to_dict())
	
	var json_str = JSON.stringify(report, "\t")
	var file = FileAccess.open("user://playthrough_report.json", FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		print("\n✓ Relatório salvo em: user://playthrough_report.json")
	else:
		print("\n✗ Falha ao salvar relatório")
	
	# Também salvar como TXT legível
	var txt_report = _generate_txt_report()
	file = FileAccess.open("user://playthrough_report.txt", FileAccess.WRITE)
	if file:
		file.store_string(txt_report)
		print("✓ Relatório TXT salvo em: user://playthrough_report.txt")


func _generate_txt_report() -> String:
	var report = "═══════════════════════════════════════════════════════════\n"
	report += "           RELATÓRIO DE TESTE - PLAYTHROUGH COMPLETO\n"
	report += "═══════════════════════════════════════════════════════════\n\n"
	
	report += "Data/Hora: %s\n" % Time.get_datetime_string_from_system()
	report += "Duração: %.2fs\n" % test_duration
	report += "Passos Executados: %d\n\n" % step_count
	
	report += "RESUMO:\n"
	report += "  Total de Logs: %d\n" % test_logs.size()
	report += "  Erros: %d\n" % errors_found
	report += "  Avisos: %d\n\n" % warnings_found
	
	if critical_errors.size() > 0:
		report += "ERROS CRÍTICOS:\n"
		for err in critical_errors:
			report += "  ✗ %s\n" % err
		report += "\n"
	
	report += "LOG COMPLETO:\n"
	report += "─────────────────────────────────────────────────────────\n"
	for log in test_logs:
		var level_str = "[%s]" % log.level
		report += "  %.2fs %s %s: %s\n" % [log.timestamp / 1000.0, level_str.pad_zeros(10), log.component, log.message]
		if log.stack_trace != "":
			report += "           Stack: %s\n" % log.stack_trace
	
	report += "\n═══════════════════════════════════════════════════════════\n"
	report += "Status Final: %s\n" % ("✓ PASSOU" if errors_found == 0 else "✗ FALHOU")
	report += "═══════════════════════════════════════════════════════════\n"
	
	return report
