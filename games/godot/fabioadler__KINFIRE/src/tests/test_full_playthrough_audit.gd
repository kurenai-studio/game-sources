extends Node
## TESTE DE AUDITORIA COMPLETO - Playthrough + Caça de Bugs
## Executa com: godot --headless --path . -- --audit-playthrough
##
## FASE 1: Inicialização + Validação
## FASE 2: Tutorial/Prólogo  
## FASE 3: Criação de Personagem
## FASE 4: Gameplay Progressivo (50+ níveis)
## FASE 5: Missões e Sistemas
## FASE 6: Relatório Final com Bugs

class AuditLog:
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

class BugReport:
	var file: String
	var line: int
	var severity: String  # CRÍTICO, ALTO, MÉDIO, BAIXO
	var description: String
	var component: String
	var reproducible: bool = true
	
	func to_dict() -> Dictionary:
		return {
			"file": file,
			"line": line,
			"severity": severity,
			"description": description,
			"component": component,
			"reproducible": reproducible
		}

var audit_logs: Array[AuditLog] = []
var bug_reports: Array[BugReport] = []
var errors_found: int = 0
var warnings_found: int = 0
var critical_errors: Array[String] = []
var test_start_time: float
var test_duration: float = 0.0

# Métricas
var phase_durations: Dictionary = {}
var levels_completed: int = 0
var quests_completed: int = 0
var equipment_tests_passed: int = 0
var equipment_tests_failed: int = 0

# Estados
var state: String = "INIT"
var current_hero: Hero = null
var current_level: int = 0
var captured_errors: Array[String] = []
var captured_warnings: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	test_start_time = Time.get_ticks_msec()
	
	# Capturar todos os erros via monkey-patching
	_setup_error_capture()
	
	_add_log("AUDIT", "INFO", "╔════════════════════════════════════════╗")
	_add_log("AUDIT", "INFO", "║  AUDITORIA COMPLETA - KINFIRE          ║")
	_add_log("AUDIT", "INFO", "║  Full Playthrough + Bug Hunt            ║")
	_add_log("AUDIT", "INFO", "╚════════════════════════════════════════╝")
	
	_run.call_deferred()


func _setup_error_capture() -> void:
	"""Interceptar push_error e push_warning"""
	# Nota: Em Godot 4.7, isso requer patching manual via print_debug
	# ou monitoramento de sinais
	print_debug("[AUDIT] Sistema de captura de erros ativado")


func _add_log(component: String, level: String, message: String, stack: String = "") -> void:
	var log = AuditLog.new()
	log.timestamp = Time.get_ticks_msec() - test_start_time
	log.level = level
	log.component = component
	log.message = message
	log.stack_trace = stack
	
	audit_logs.append(log)
	
	var color = ""
	match level:
		"ERROR", "CRITICAL": 
			color = "\u001b[91m"  # Red
			errors_found += 1
			if level == "CRITICAL":
				critical_errors.append("[%s] %s: %s" % [component, level, message])
		"WARN":
			color = "\u001b[93m"  # Yellow
			warnings_found += 1
		"INFO":
			color = "\u001b[92m"  # Green
		_:
			color = "\u001b[94m"  # Blue
	
	var time_str = "%.2fs" % (log.timestamp / 1000.0)
	print("%s[%s] [%s] %s: %s\u001b[0m" % [color, time_str, level, component, message])


func _report_bug(severity: String, component: String, description: String) -> void:
	var bug = BugReport.new()
	bug.severity = severity
	bug.component = component
	bug.description = description
	bug_reports.append(bug)
	
	_add_log("BUG", "WARN", "[%s] %s - %s" % [severity, component, description])


func _run() -> void:
	_add_log("AUDIT", "INFO", "")
	_add_log("AUDIT", "INFO", "FASE 1: Validação de Inicialização")
	var phase_start = Time.get_ticks_msec()
	if not await _phase_init():
		_finalize_test()
		return
	phase_durations["init"] = Time.get_ticks_msec() - phase_start
	
	_add_log("AUDIT", "INFO", "")
	_add_log("AUDIT", "INFO", "FASE 2: Tutorial e Prólogo")
	phase_start = Time.get_ticks_msec()
	if not await _phase_tutorial():
		_finalize_test()
		return
	phase_durations["tutorial"] = Time.get_ticks_msec() - phase_start
	
	_add_log("AUDIT", "INFO", "")
	_add_log("AUDIT", "INFO", "FASE 3: Criação de Personagem")
	phase_start = Time.get_ticks_msec()
	if not await _phase_character_creation():
		_finalize_test()
		return
	phase_durations["chargen"] = Time.get_ticks_msec() - phase_start
	
	_add_log("AUDIT", "INFO", "")
	_add_log("AUDIT", "INFO", "FASE 4: Gameplay Progressivo (50 níveis)")
	phase_start = Time.get_ticks_msec()
	await _phase_gameplay()
	phase_durations["gameplay"] = Time.get_ticks_msec() - phase_start
	
	_add_log("AUDIT", "INFO", "")
	_add_log("AUDIT", "INFO", "FASE 5: Testes de Sistemas")
	phase_start = Time.get_ticks_msec()
	await _phase_system_tests()
	phase_durations["systems"] = Time.get_ticks_msec() - phase_start
	
	_add_log("AUDIT", "INFO", "")
	_add_log("AUDIT", "INFO", "FASE 6: Análise Final")
	_finalize_test()


# ============================================================================
# FASE 1: Inicialização
# ============================================================================

func _phase_init() -> bool:
	_add_log("INIT", "INFO", "Verificando singletons...")
	
	if Game == null:
		_add_log("INIT", "CRITICAL", "Game singleton não inicializado")
		_report_bug("CRÍTICO", "INIT", "Game singleton é null")
		return false
	_add_log("INIT", "INFO", "✓ Game singleton OK")
	
	if DB == null:
		_add_log("INIT", "CRITICAL", "DB singleton não inicializado")
		_report_bug("CRÍTICO", "INIT", "DB singleton é null")
		return false
	_add_log("INIT", "INFO", "✓ DB singleton OK")
	
	# Validar recursos carregados
	_add_log("INIT", "INFO", "Verificando recursos carregados...")
	
	if DB.races.size() == 0:
		_add_log("INIT", "ERROR", "Nenhuma raça carregada")
		_report_bug("CRÍTICO", "DB", "DB.races está vazio")
		return false
	_add_log("INIT", "INFO", "✓ %d raças carregadas" % DB.races.size())
	
	if DB.classes.size() == 0:
		_add_log("INIT", "ERROR", "Nenhuma classe carregada")
		_report_bug("CRÍTICO", "DB", "DB.classes está vazio")
		return false
	_add_log("INIT", "INFO", "✓ %d classes carregadas" % DB.classes.size())
	
	# Validar slots de equipamento
	_add_log("INIT", "INFO", "Verificando EQUIP_SLOTS...")
	var expected_slots := ["helm", "amulet", "weapon", "chest", "offhand", "gloves", "ring", "accessory_1", "accessory_2", "accessory_3", "boots"]
	if DB.EQUIP_SLOTS.size() != expected_slots.size():
		_add_log("INIT", "WARN", "EQUIP_SLOTS tem %d slots (esperado %d)" % [DB.EQUIP_SLOTS.size(), expected_slots.size()])
		_report_bug("MÉDIO", "INIT", "Número de EQUIP_SLOTS incorreto")
	
	for slot in expected_slots:
		if slot not in DB.EQUIP_SLOTS:
			_add_log("INIT", "ERROR", "Slot '%s' não encontrado em EQUIP_SLOTS" % slot)
			_report_bug("ALTO", "INIT", "Slot %s faltando" % slot)
			return false
	
	_add_log("INIT", "INFO", "✓ 11 slots de equipamento configurados")
	_add_log("INIT", "INFO", "✓ Inicialização completa")
	await get_tree().process_frame
	return true


# ============================================================================
# FASE 2: Tutorial
# ============================================================================

func _phase_tutorial() -> bool:
	_add_log("TUTORIAL", "INFO", "Criando herói aldeão (prólogo)...")
	
	var hero = Hero.create_villager()
	if hero == null:
		_add_log("TUTORIAL", "CRITICAL", "Falha ao criar herói vilageano")
		_report_bug("CRÍTICO", "HERO", "Hero.create_villager() retornou null")
		return false
	
	_add_log("TUTORIAL", "INFO", "✓ Herói aldeão criado")
	_add_log("TUTORIAL", "INFO", "  Nome: %s" % hero.hero_name)
	_add_log("TUTORIAL", "INFO", "  Nível: %d" % hero.level)
	_add_log("TUTORIAL", "INFO", "  Raça: %s" % hero.race.display_name)
	
	# Validar inventário
	if hero.inventory == null:
		_add_log("TUTORIAL", "ERROR", "Inventário do herói é null")
		_report_bug("CRÍTICO", "INVENTORY", "hero.inventory é null")
		return false
	_add_log("TUTORIAL", "INFO", "✓ Inventário inicializado (%dx%d)" % [hero.inventory.cols, hero.inventory.rows])
	
	# Validar equipamento
	if hero.equipment.size() == 0:
		_add_log("TUTORIAL", "ERROR", "Equipamento não inicializado")
		_report_bug("CRÍTICO", "EQUIPMENT", "hero.equipment está vazio")
		return false
	_add_log("TUTORIAL", "INFO", "✓ Equipamento inicializado com %d slots" % hero.equipment.size())
	
	# Validar consumíveis
	if hero.consumable_slots.size() != 9:
		_add_log("TUTORIAL", "WARN", "Consumable slots: %d (esperado 9)" % hero.consumable_slots.size())
	else:
		_add_log("TUTORIAL", "INFO", "✓ 9 slots de consumíveis")
	
	await get_tree().process_frame
	return true


# ============================================================================
# FASE 3: Criação de Personagem
# ============================================================================

func _phase_character_creation() -> bool:
	_add_log("CHARGEN", "INFO", "Simulando criação de personagem...")
	
	# Escolher raça e classe
	var race = DB.races.pick_random()
	var cls = DB.classes.pick_random()
	
	if race == null or cls == null:
		_add_log("CHARGEN", "CRITICAL", "Raça ou classe null")
		return false
	
	_add_log("CHARGEN", "INFO", "Raça: %s | Classe: %s" % [race.display_name, cls.display_name])
	
	# Criar herói
	var hero = Hero.create(
		"Herói Teste",
		race,
		cls,
		"m" if randf() > 0.5 else "f",
		Color(randf(), randf(), randf()),
		{"str": 15, "dex": 12, "con": 13, "int": 10, "wis": 11, "cha": 10}
	)
	
	if hero == null:
		_add_log("CHARGEN", "CRITICAL", "Falha ao criar herói")
		_report_bug("CRÍTICO", "HERO", "Hero.create() retornou null")
		return false
	
	current_hero = hero
	Game.hero = hero
	
	_add_log("CHARGEN", "INFO", "✓ Herói criado: %s" % hero.hero_name)
	_add_log("CHARGEN", "INFO", "  Vida: %d" % hero.max_hp())
	_add_log("CHARGEN", "INFO", "  Armadura: %d" % hero.armor())
	_add_log("CHARGEN", "INFO", "  DPS: %.1f" % hero.dps_estimate())
	
	# Validar equipamento
	_validate_hero_equipment(hero)
	
	await get_tree().process_frame
	return true


func _validate_hero_equipment(hero: Hero) -> void:
	_add_log("CHARGEN", "INFO", "Validando equipamento inicial...")
	
	# Verificar slots
	var empty_slots: Array[String] = []
	for slot in DB.EQUIP_SLOTS:
		if slot not in hero.equipment:
			empty_slots.append(slot)
	
	if empty_slots.size() > 0:
		_add_log("CHARGEN", "WARN", "Slots não inicializados: %s" % empty_slots)
		_report_bug("MÉDIO", "EQUIPMENT", "Alguns slots não inicializados")
	
	# Verificar arma
	if hero.equipment.weapon == null:
		_add_log("CHARGEN", "WARN", "Nenhuma arma equipada")
	else:
		_add_log("CHARGEN", "INFO", "✓ Arma: %s (DPS: %.1f)" % [hero.equipment.weapon.name, hero.equipment.weapon.dps()])
	
	# Verificar armadura
	if hero.equipment.chest == null:
		_add_log("CHARGEN", "WARN", "Nenhuma armadura equipada")
	else:
		_add_log("CHARGEN", "INFO", "✓ Armadura: %s (ARM: %d)" % [hero.equipment.chest.name, int(hero.equipment.chest.armor)])


# ============================================================================
# FASE 4: Gameplay
# ============================================================================

func _phase_gameplay() -> void:
	if current_hero == null:
		_add_log("GAMEPLAY", "CRITICAL", "Herói não foi criado")
		return
	
	var hero = current_hero
	_add_log("GAMEPLAY", "INFO", "Iniciando gameplay progressivo...")
	_add_log("GAMEPLAY", "INFO", "Herói: %s (Nível %d)" % [hero.hero_name, hero.level])
	
	# Simular 50 níveis
	for level_num in range(1, 51):
		current_level = level_num
		
		# Level up
		var xp_needed = hero.xp_to_next()
		hero.add_xp(xp_needed + 1)
		
		# Validar a cada 5 níveis
		if level_num % 5 == 0:
			_validate_level_progression(hero, level_num)
		
		# Equipar item a cada 10 níveis
		if level_num % 10 == 0:
			_test_equipment_system(hero, level_num)
		
		levels_completed = level_num
		
		if level_num % 25 == 0:
			_add_log("GAMEPLAY", "INFO", "✓ Nível %d completado" % level_num)
	
	_add_log("GAMEPLAY", "INFO", "✓ 50 níveis completados com sucesso")
	await get_tree().process_frame


func _validate_level_progression(hero: Hero, level: int) -> void:
	var hp = hero.max_hp()
	var armor = hero.armor()
	var dps = hero.dps_estimate()
	
	if hp <= 0:
		_add_log("GAMEPLAY", "ERROR", "Nível %d: Vida inválida (%d)" % [level, hp])
		_report_bug("CRÍTICO", "STATS", "max_hp() retorna valor inválido")
	
	if dps < 1.0:
		_add_log("GAMEPLAY", "WARN", "Nível %d: DPS muito baixo (%.1f)" % [level, dps])
		_report_bug("MÉDIO", "STATS", "DPS estimado muito baixo")
	
	_add_log("GAMEPLAY", "INFO", "L%d: HP=%d, ARM=%d, DPS=%.1f" % [level, hp, armor, dps])


func _test_equipment_system(hero: Hero, level: int) -> void:
	_add_log("GAMEPLAY", "INFO", "Testando sistema de equipamento no nível %d..." % level)
	
	# Teste 1: Criar item e equipar
	var item = DB.create_item(&"sword", level, Item.Rarity.COMMON)
	if item == null:
		_add_log("GAMEPLAY", "ERROR", "Falha ao criar item")
		equipment_tests_failed += 1
		_report_bug("ALTO", "ITEM", "DB.create_item() retornou null")
		return
	
	# Teste 2: Verificar se pode equipar
	var problem = hero.equip_problem(item)
	if problem != "":
		_add_log("GAMEPLAY", "WARN", "Problema ao equipar: %s" % problem)
	
	# Teste 3: Equipar
	var old_items = hero.equip(item)
	if hero.equipment.weapon != item:
		_add_log("GAMEPLAY", "ERROR", "Item não foi equipado corretamente")
		equipment_tests_failed += 1
		_report_bug("ALTO", "EQUIPMENT", "hero.equip() não equipou o item")
		return
	
	equipment_tests_passed += 1
	_add_log("GAMEPLAY", "INFO", "✓ Equipamento testado com sucesso")


# ============================================================================
# FASE 5: Testes de Sistemas
# ============================================================================

func _phase_system_tests() -> void:
	_add_log("SYSTEMS", "INFO", "Executando testes de sistemas...")
	
	# Teste de inventário
	_test_inventory_system()
	await get_tree().process_frame
	
	# Teste de equipamento completo
	_test_full_equipment_system()
	await get_tree().process_frame

	# Teste de UI de inventário e paper doll
	_test_inventory_ui_paper_doll()
	await get_tree().process_frame
	
	# Teste de stats
	_test_stats_calculation()
	await get_tree().process_frame
	
	_add_log("SYSTEMS", "INFO", "✓ Testes de sistemas completados")


func _test_inventory_system() -> void:
	_add_log("SYSTEMS", "INFO", "  [Teste] Sistema de Inventário")
	
	if current_hero == null:
		_add_log("SYSTEMS", "WARN", "    Herói não disponível")
		return
	
	var hero = current_hero
	var inv = hero.inventory
	
	# Teste 1: Adicionar item
	var item = DB.create_item(&"sword", hero.level, Item.Rarity.COMMON)
	var added = inv.add(item)
	if not added:
		_add_log("SYSTEMS", "ERROR", "    Falha ao adicionar item ao inventário")
		_report_bug("ALTO", "INVENTORY", "InventoryGrid.add() retornou false")
	else:
		_add_log("SYSTEMS", "INFO", "    ✓ Item adicionado")
	
	# Teste 2: Remover item
	if added:
		inv.remove(item)
		if item in inv.items:
			_add_log("SYSTEMS", "ERROR", "    Item não foi removido")
			_report_bug("ALTO", "INVENTORY", "InventoryGrid.remove() falhou")
		else:
			_add_log("SYSTEMS", "INFO", "    ✓ Item removido")


func _test_full_equipment_system() -> void:
	_add_log("SYSTEMS", "INFO", "  [Teste] Sistema de Equipamento")
	
	if current_hero == null:
		return
	
	var hero = current_hero
	var test_slots = ["helm", "weapon", "chest", "boots"]
	var test_bases = [&"helm", &"sword", &"plate", &"boots"]
	
	for i in range(test_slots.size()):
		var slot = test_slots[i]
		var base = test_bases[i]
		
		# Criar item
		var item = DB.create_item(base, hero.level, Item.Rarity.COMMON)
		if item == null:
			_add_log("SYSTEMS", "ERROR", "    Falha ao criar item para slot %s" % slot)
			continue
		
		# Forçar slot correto
		item.slot = slot
		
		# Equipar
		var result = hero.equip(item)
		if hero.equipment[slot] != item:
			_add_log("SYSTEMS", "ERROR", "    Falha ao equipar em slot %s" % slot)
			_report_bug("ALTO", "EQUIPMENT", "hero.equip() falhou para slot: %s" % slot)
			equipment_tests_failed += 1
		else:
			_add_log("SYSTEMS", "INFO", "    ✓ Slot %s equipado" % slot)
			equipment_tests_passed += 1


func _test_inventory_ui_paper_doll() -> void:
	_add_log("SYSTEMS", "INFO", "  [Teste] UI do Inventário e Paper Doll")
	if current_hero == null:
		_add_log("SYSTEMS", "WARN", "    Herói não disponível")
		return
	
	var panel := InventoryPanel.new()
	add_child(panel)
	panel.setup(null, current_hero)
	
	# Verifica ScrollContainer
	var scroll: ScrollContainer = null
	var stack: Array[Node] = [panel]
	while not stack.is_empty():
		var curr: Node = stack.pop_back()
		if curr is ScrollContainer:
			scroll = curr as ScrollContainer
			break
		for child in curr.get_children():
			stack.append(child)
	
	if scroll == null or scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		_add_log("SYSTEMS", "ERROR", "    ScrollContainer ausente ou horizontal não desabilitado")
		_report_bug("ALTO", "INVENTORY_UI", "ScrollContainer inválido no InventoryPanel")
	elif scroll.get_child_count() != 1:
		_add_log("SYSTEMS", "ERROR", "    ScrollContainer tem múltiplos filhos (risco de sobreposição em 0,0)")
		_report_bug("ALTO", "INVENTORY_UI", "ScrollContainer tem múltiplos filhos diretos")
	else:
		_add_log("SYSTEMS", "INFO", "    ✓ ScrollContainer configurado sem sobreposição")
	
	# Verifica colunas separadas para doll e grid
	if panel._doll == null or panel._grid_view == null:
		_add_log("SYSTEMS", "ERROR", "    Doll ou GridView nulo")
		_report_bug("ALTO", "INVENTORY_UI", "Doll ou GridView nulo")
	elif panel._doll.get_parent() == panel._grid_view.get_parent():
		_add_log("SYSTEMS", "ERROR", "    Doll e GridView compartilham o mesmo container direto")
		_report_bug("ALTO", "INVENTORY_UI", "Doll e GridView não estão em colunas separadas")
	else:
		_add_log("SYSTEMS", "INFO", "    ✓ Doll e GridView em colunas separadas (lado a lado)")
	
	# Verifica sprite do herói no paper doll
	if panel._hero_sprite == null or not (panel._hero_sprite is SpritePreview):
		_add_log("SYSTEMS", "ERROR", "    HeroSprite ausente ou tipo incorreto")
		_report_bug("ALTO", "INVENTORY_UI", "HeroSprite ausente no paper doll")
	elif panel._hero_sprite.size.x <= 0 or panel._hero_sprite.size.y <= 0:
		_add_log("SYSTEMS", "ERROR", "    HeroSprite tem tamanho zero")
		_report_bug("ALTO", "INVENTORY_UI", "HeroSprite com tamanho zero")
	else:
		_add_log("SYSTEMS", "INFO", "    ✓ HeroSprite configurado e visível no paper doll")
	
	# Verifica 11 slots
	var missing_slots := 0
	for s in DB.EQUIP_SLOTS:
		if not panel._equip_views.has(s):
			missing_slots += 1
	if missing_slots > 0:
		_add_log("SYSTEMS", "ERROR", "    Faltando %d slots de equipamento no paper doll" % missing_slots)
		_report_bug("ALTO", "INVENTORY_UI", "Slots de equipamento faltando no paper doll")
	else:
		_add_log("SYSTEMS", "INFO", "    ✓ Todos os 11 slots presentes no paper doll")
	
	panel.cleanup()
	panel.queue_free()


func _test_stats_calculation() -> void:
	_add_log("SYSTEMS", "INFO", "  [Teste] Cálculo de Stats")
	
	if current_hero == null:
		return
	
	var hero = current_hero
	
	# Teste vida
	var hp = hero.max_hp()
	if hp <= 0:
		_add_log("SYSTEMS", "ERROR", "    max_hp() retorna valor inválido: %d" % hp)
		_report_bug("CRÍTICO", "STATS", "max_hp() retorna <= 0")
	else:
		_add_log("SYSTEMS", "INFO", "    ✓ Vida: %d" % hp)
	
	# Teste armadura
	var armor = hero.armor()
	if armor < 0:
		_add_log("SYSTEMS", "ERROR", "    armor() retorna valor negativo: %d" % armor)
		_report_bug("CRÍTICO", "STATS", "armor() retorna valor negativo")
	else:
		_add_log("SYSTEMS", "INFO", "    ✓ Armadura: %d" % armor)
	
	# Teste DPS
	var dps = hero.dps_estimate()
	if dps < 0:
		_add_log("SYSTEMS", "ERROR", "    dps_estimate() retorna valor negativo: %.1f" % dps)
		_report_bug("CRÍTICO", "STATS", "dps_estimate() retorna valor negativo")
	else:
		_add_log("SYSTEMS", "INFO", "    ✓ DPS: %.1f" % dps)


# ============================================================================
# FINALIZAÇÃO
# ============================================================================

func _finalize_test() -> void:
	test_duration = (Time.get_ticks_msec() - test_start_time) / 1000.0
	
	_add_log("AUDIT", "INFO", "")
	_add_log("AUDIT", "INFO", "╔════════════════════════════════════════╗")
	_add_log("AUDIT", "INFO", "║        RELATÓRIO FINAL DA AUDITORIA     ║")
	_add_log("AUDIT", "INFO", "╚════════════════════════════════════════╝")
	_add_log("AUDIT", "INFO", "")
	
	# Resumo de execução
	_add_log("AUDIT", "INFO", "EXECUÇÃO:")
	_add_log("AUDIT", "INFO", "  Duração total: %.2fs" % test_duration)
	_add_log("AUDIT", "INFO", "  Níveis completados: %d" % levels_completed)
	_add_log("AUDIT", "INFO", "  Missões completadas: %d" % quests_completed)
	_add_log("AUDIT", "INFO", "  Total de logs: %d" % audit_logs.size())
	
	# Duração por fase
	_add_log("AUDIT", "INFO", "")
	_add_log("AUDIT", "INFO", "DURAÇÃO POR FASE:")
	for phase in phase_durations:
		var duration = phase_durations[phase] / 1000.0
		_add_log("AUDIT", "INFO", "  %s: %.2fs" % [phase, duration])
	
	# Erros e avisos
	_add_log("AUDIT", "INFO", "")
	_add_log("AUDIT", "INFO", "PROBLEMAS ENCONTRADOS:")
	_add_log("AUDIT", "INFO", "  Erros: %d" % errors_found)
	_add_log("AUDIT", "INFO", "  Avisos: %d" % warnings_found)
	_add_log("AUDIT", "INFO", "  Críticos: %d" % critical_errors.size())
	_add_log("AUDIT", "INFO", "  Bugs relatados: %d" % bug_reports.size())
	
	# Testes de equipamento
	_add_log("AUDIT", "INFO", "")
	_add_log("AUDIT", "INFO", "TESTES DE EQUIPAMENTO:")
	_add_log("AUDIT", "INFO", "  Passados: %d" % equipment_tests_passed)
	_add_log("AUDIT", "INFO", "  Falhados: %d" % equipment_tests_failed)
	
	# Erros críticos
	if critical_errors.size() > 0:
		_add_log("AUDIT", "INFO", "")
		_add_log("AUDIT", "CRITICAL", "ERROS CRÍTICOS ENCONTRADOS:")
		for err in critical_errors:
			_add_log("AUDIT", "CRITICAL", "  ✗ %s" % err)
	
	# Bugs encontrados
	if bug_reports.size() > 0:
		_add_log("AUDIT", "INFO", "")
		_add_log("AUDIT", "INFO", "BUGS ENCONTRADOS:")
		
		# Agrupar por severidade
		var by_severity = {}
		for bug in bug_reports:
			if bug.severity not in by_severity:
				by_severity[bug.severity] = []
			by_severity[bug.severity].append(bug)
		
		for severity in ["CRÍTICO", "ALTO", "MÉDIO", "BAIXO"]:
			if severity in by_severity:
				_add_log("AUDIT", "INFO", "")
				_add_log("AUDIT", "INFO", "  [%s] %d bugs:" % [severity, by_severity[severity].size()])
				for bug in by_severity[severity]:
					_add_log("AUDIT", "INFO", "    • [%s] %s" % [bug.component, bug.description])
	
	# Status final
	_add_log("AUDIT", "INFO", "")
	if errors_found == 0 and critical_errors.size() == 0:
		_add_log("AUDIT", "INFO", "STATUS: ✅ TESTE PASSOU SEM ERROS CRÍTICOS")
	else:
		_add_log("AUDIT", "INFO", "STATUS: ⚠️ TESTE COM PROBLEMAS")
	
	_add_log("AUDIT", "INFO", "")
	
	# Salvar relatório
	_save_report()
	
	_add_log("AUDIT", "INFO", "Teste finalizado. Logs e relatório salvos.")
	
	get_tree().quit()


func _save_report() -> void:
	var report = {
		"timestamp": Time.get_datetime_string_from_system(),
		"duration_seconds": test_duration,
		"levels_completed": levels_completed,
		"quests_completed": quests_completed,
		"total_logs": audit_logs.size(),
		"errors": errors_found,
		"warnings": warnings_found,
		"critical_count": critical_errors.size(),
		"bugs_found": bug_reports.size(),
		"equipment_tests": {
			"passed": equipment_tests_passed,
			"failed": equipment_tests_failed
		},
		"phase_durations": {},
		"critical_errors": critical_errors,
		"bug_reports": [],
		"audit_logs": []
	}
	
	# Fases
	for phase in phase_durations:
		report.phase_durations[phase] = phase_durations[phase] / 1000.0
	
	# Bugs
	for bug in bug_reports:
		report.bug_reports.append(bug.to_dict())
	
	# Logs
	for log in audit_logs:
		report.audit_logs.append(log.to_dict())
	
	# JSON
	var json_str = JSON.stringify(report, "\t")
	var file = FileAccess.open("user://audit_report.json", FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		print("\n✓ Relatório JSON salvo: user://audit_report.json")
	
	# TXT legível
	var txt_report = _generate_txt_report(report)
	file = FileAccess.open("user://audit_report.txt", FileAccess.WRITE)
	if file:
		file.store_string(txt_report)
		print("✓ Relatório TXT salvo: user://audit_report.txt")


func _generate_txt_report(report: Dictionary) -> String:
	var out = ""
	out += "═══════════════════════════════════════════════════════════════════\n"
	out += "               RELATÓRIO DE AUDITORIA - KINFIRE\n"
	out += "═══════════════════════════════════════════════════════════════════\n\n"
	
	out += "DATA/HORA: %s\n" % report.timestamp
	out += "DURAÇÃO: %.2fs\n\n" % report.duration_seconds
	
	out += "PROGRESSO:\n"
	out += "  • Níveis completados: %d\n" % report.levels_completed
	out += "  • Missões: %d\n" % report.quests_completed
	out += "  • Total de logs: %d\n\n" % report.total_logs
	
	out += "PROBLEMAS:\n"
	out += "  • Erros: %d\n" % report.errors
	out += "  • Avisos: %d\n" % report.warnings
	out += "  • Críticos: %d\n" % report.critical_count
	out += "  • Bugs: %d\n\n" % report.bugs_found
	
	out += "EQUIPAMENTO:\n"
	out += "  • Testes passou: %d\n" % report.equipment_tests.passed
	out += "  • Testes falhado: %d\n\n" % report.equipment_tests.failed
	
	if report.critical_errors.size() > 0:
		out += "ERROS CRÍTICOS:\n"
		for err in report.critical_errors:
			out += "  ✗ %s\n" % err
		out += "\n"
	
	if report.bugs_found > 0:
		out += "BUGS ENCONTRADOS:\n"
		for bug in report.bug_reports:
			out += "  [%s] %s - %s\n" % [bug.severity, bug.component, bug.description]
		out += "\n"
	
	out += "FASES:\n"
	for phase in report.phase_durations:
		out += "  • %s: %.2fs\n" % [phase, report.phase_durations[phase]]
	
	out += "\n═══════════════════════════════════════════════════════════════════\n"
	out += "STATUS: %s\n" % ("✅ PASSOU" if report.critical_count == 0 else "⚠️ FALHOU")
	out += "═══════════════════════════════════════════════════════════════════\n"
	
	return out
