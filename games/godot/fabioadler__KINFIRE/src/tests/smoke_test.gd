extends Node
## Teste de fumaça automatizado. Execute com:
##   godot --headless --path . -- --smoke
## Percorre menus, cria um herói de cada classe, usa todas as habilidades,
## mexe no inventário e desce um nível. Erros aparecem no console.


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


## Salva screenshot se SMOKE_SHOTS apontar para uma pasta
func _shot(shot_name: String) -> void:
	var dir := OS.get_environment("SMOKE_SHOTS")
	if dir == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(dir.path_join(shot_name + ".png"))


func _wait(t: float) -> void:
	await get_tree().create_timer(t, true, false, true).timeout


## Fase 6.5: espera uma condição virar verdadeira com prazo em RELÓGIO DE
## PAREDE (Time.get_ticks_msec). Os SceneTreeTimers do engine podem disparar
## cedo em headless sob carga (delta idle inflado — medimos 0.35s pedidos
## disparando em 25ms reais), então asserts que dependem de tempo decorrido
## (fim de uma animação de pop_out, liberação de popup etc.) devem usar isto.
func _wait_until(cond: Callable, timeout_ms := 3000) -> bool:
	var t0 := Time.get_ticks_msec()
	while not cond.call():
		if Time.get_ticks_msec() - t0 > timeout_ms:
			return false
		await get_tree().create_timer(0.05, true, false, true).timeout
	return true


func _run() -> void:
	print("[smoke] multiplayer manager initialization")
	# Tarefa 14.1: Testar MultiplayerManager singleton
	assert(MultiplayerManager != null, "MultiplayerManager autoload existe")
	assert(not MultiplayerManager.is_multiplayer(), "não está em modo multiplayer inicialmente")
	assert(not MultiplayerManager.server_running, "servidor não está rodando")
	assert(MultiplayerManager.connected_peers.size() == 0, "nenhum peer conectado")
	assert(MultiplayerManager.player_chars.size() == 0, "nenhum herói carregado")
	assert(MultiplayerManager.damage_tracker.size() == 0, "damage tracker vazio")
	assert(MultiplayerManager.kill_credit.size() == 0, "kill credit vazio")
	print("[smoke] multiplayer manager state OK")
	
	print("[smoke] rpc protocol definition")
	# Tarefa 14.2: Testar RPC Protocol
	assert(MultiplayerRPC.RPC_SYNC_ENEMY_POSITION != "", "RPC_SYNC_ENEMY_POSITION definido")
	assert(MultiplayerRPC.RPC_ENEMY_DIED != "", "RPC_ENEMY_DIED definido")
	assert(MultiplayerRPC.RPC_PLAYER_JOINED != "", "RPC_PLAYER_JOINED definido")
	assert(MultiplayerRPC.RPC_DAMAGE_PLAYER != "", "RPC_DAMAGE_PLAYER definido")
	assert(MultiplayerRPC.get_authority_type(MultiplayerRPC.RPC_SYNC_ENEMY_POSITION) == "authority", "RPC authority correto")
	assert(MultiplayerRPC.get_call_type(MultiplayerRPC.RPC_SYNC_ENEMY_POSITION) == "call_remote_unreliable", "RPC type correto")
	print("[smoke] rpc protocol OK")
	
	print("[smoke] world synchronizer")
	# Tarefa 14.3: Testar WorldSynchronizer
	var test_snapshot = {
		"timestamp": Time.get_ticks_msec(),
		"world_time": 0.5,
		"difficulty": 0,
		"enemies": [],
		"loot": [],
		"environment": {},
	}
	assert(WorldSynchronizer.validate_snapshot(test_snapshot), "snapshot válido passa em validação")
	
	# Snapshot inválido (sem campo obrigatório)
	var invalid_snapshot = {
		"timestamp": Time.get_ticks_msec(),
		"world_time": 0.5,
		# falta "difficulty"
		"enemies": [],
		"loot": [],
		"environment": {},
	}
	assert(not WorldSynchronizer.validate_snapshot(invalid_snapshot), "snapshot inválido falha em validação")
	print("[smoke] world synchronizer OK")
	
	print("[smoke] migracao v3 -> v4")
	var v3_save := {"version": 3, "depth": 2, "hero": {"name": "Velho", "race": "humano", "class": "guerreiro", "level": 5},
		"world_seed": 7, "world_time": 0.5, "in_dungeon": false}
	var v4_save: Dictionary = Game._migrate(v3_save)
	assert(int(v4_save.version) == 4)
	assert(v4_save.phase == Game.PHASE_CREATED)
	assert(int(v4_save.ignorance) == 0)
	assert(v4_save.hero.level == 5 and v4_save.world_seed == 7)  # nada perdido
	print("[smoke] aldeao do prologo")
	var villager := Hero.create_villager()
	assert(villager.level == 0 and villager.cls.id == &"aldeao")
	assert(villager.xp_to_next() == 20)
	assert(villager.skill_bar[0] == &"golpe_de_lenhador")
	villager.add_xp(20)
	assert(villager.level == 1 and villager.unspent_points == 1)
	print("[smoke] menu principal")
	await _wait(2.5)
	await _shot("01_menu")
	var menu := get_tree().current_scene
	# 6.3: menu moderno — névoa, brasas do rodapé e brasas subindo do logo
	assert(menu._logo_embers is CPUParticles2D, "brasas no logo")
	assert(menu._logo_embers.amount > 0, "emissor de brasas ativo")
	assert(menu._embers.color_ramp != null, "ramp de brasas no rodape")
	assert(menu._fog.material is ShaderMaterial, "shader de nevoa")
	print("[smoke]   menu moderno ok (logo com brasas proprias)")
	menu._on_credits()
	await _wait(1.5)
	await _shot("01b_creditos")
	menu._on_options()
	await _wait(0.5)
	await _shot("01c_opcoes")
	Game.change_scene(Game.CHARACTER_CREATION)
	await _wait(1.5)
	await _shot("02_criacao")
	var cc := get_tree().current_scene
	cc._randomize()
	await _wait(0.5)
	await _shot("02b_criacao_aleatorio")
	print("[smoke] criação de personagem ok")
	await _test_prologue()
	await _test_dialogue()
	await _test_overworld()
	# --smoke-quick: para logo após o overworld (o loop das 14 classes é lento)
	if "--smoke-quick" in OS.get_cmdline_user_args():
		print("[smoke] SMOKE-QUICK OK")
		get_tree().quit(0)
		return

	for i in DB.classes.size():
		var cls: ClassData = DB.classes[i]
		var race: RaceData = DB.races[i % DB.races.size()]
		var h := Hero.create("Teste", race, cls, ["m", "f"][i % 2], Color.WHITE, {"str": 14, "dex": 14, "con": 14, "int": 12, "wis": 12, "cha": 10}, {"con": 1}, DB.BACKGROUNDS.keys()[i % DB.BACKGROUNDS.size()], i % 4, false)
		h.level = 10
		h.refresh_skill_bar()
		Game.hero = h
		Game.depth = 3 if i == 0 else 1
		Game.in_dungeon = true
		Game.dungeon_level = 1 + i % 3
		Game.dungeon_name = "Masmorra de Teste"
		Game.change_scene(Game.WORLD)
		await _wait(1.5)
		var world: World = get_tree().get_first_node_in_group("world")
		assert(world != null)
		var p := world.player
		if i == 0 or i == 4 or i == 9:
			await _shot("03_jogo_%d" % i)
		print("[smoke] %s/%s em jogo — inimigos: %d" % [race.display_name, cls.display_name, get_tree().get_nodes_in_group("enemies").size()])
		for s in cls.skills:
			p.cooldowns.clear()
			p.resource = p.max_resource
			p.state = Player.State.IDLE
			var target := p.global_position + Vector2(40, 0)
			var e := _nearest_enemy(world, p.global_position)
			if e:
				p.global_position = world.last_free_point(e.global_position, e.global_position + Vector2(20, 0))
				target = e.hit_center()
			var slot := h.skill_bar.find(s.id)
			if slot < 0:
				h.assign_skill(2, s.id)
				slot = 2
			print("[smoke]   skill ", s.id)
			p._request_cast(slot, target)
			await _wait(0.7)
			if (i == 4 or i == 5 or i == 9) and s == cls.skills[4]:
				await _shot("04_combate_%d" % i)
		if h.racial_skill():
			p.cooldowns.clear()
			p._request_cast(Player.RACIAL_SLOT, p.global_position + Vector2(30, 0))
			await _wait(0.4)
		print("[smoke]   pocao/inventario")
		p.use_potion()
		p.add_buff("damage", 0.3, 2.0, "Teste", Color.RED)
		# Inventário e equipamento
		for k in 8:
			h.inventory.add(DB.roll_item(5, 0.5, cls))
		for it in h.inventory.items.duplicate():
			if h.equip_problem(it) == "":
				world.hud.inventory.equip_from_inventory(it)
				break
		var hud := world.hud
		hud.toggle_inventory()
		hud.toggle_character()
		hud.toggle_skills()
		await _wait(0.3)
		if i == 0:
			await _shot("05_paineis")
			_report_wide(hud.skills, 0)
			hud.toggle_skills()       # fecha a janela unificada
			hud.toggle_inventory()    # reabre direto na aba Inventário
			await _wait(0.2)
			await _shot("05b_inventario")
			hud.toggle_inventory()    # fecha
			if OS.get_environment("SMOKE_QUICK") != "":
				get_tree().quit()
		if not h.inventory.items.is_empty():
			hud.inventory.equip_from_inventory(h.inventory.items[0])
		hud.inventory._sell_junk()
		h.add_xp(5000)
		h.spend_point("str")
		await _wait(0.3)
		hud.toggle_inventory()
		hud.toggle_character()
		hud.toggle_skills()
		print("[smoke]   loot")
		# Mata inimigos para gerar loot
		for k in 3:
			LootDrop.drop_item(world, p.global_position + Vector2(0, 20), DB.roll_item(5, 0.8))
		for e in world.enemies_near(p.global_position, 99999.0).slice(0, 12):
			e.take_damage(999999.0, true, p.global_position, 50.0)
		await _wait(1.0)
		if i == 0:
			await _shot("06_loot")
		for n in get_tree().get_nodes_in_group("interactables"):
			if n is LootDrop:
				n.interact(p)
				break
		for n in get_tree().get_nodes_in_group("interactables"):
			if n is Interactable and n.kind in [Interactable.Kind.CHEST, Interactable.Kind.SHRINE]:
				n.interact(p)
		await _wait(0.5)
		print("[smoke]   morte")
		# Dano e morte (desativa passivas que evitam a morte)
		p.cheat_death_cd = 999.0
		p.auto_dodge_cd = 999.0
		p._invuln = 0.0
		p.take_damage(999999.0)
		if not p.is_dead():
			p._die()
		await _wait(0.6)
		world.respawn_player()
		if hud._death_layer:
			hud._death_layer.queue_free()
			hud._death_layer = null
		hud.toggle_pause()
		await _wait(0.3)
		hud.toggle_pause()
		Game.save_game()

	print("[smoke] descendo")
	Game.descend()
	await _wait(1.5)
	assert(Game.load_game())
	Game.quit_to_menu()
	await _wait(1.5)
	print("[smoke] SMOKE OK")
	get_tree().quit()


func _test_prologue() -> void:
	print("[smoke] prologo")
	Game.delete_save()
	Game.new_prologue()
	await _wait(2.5)
	var pro: Prologue = get_tree().current_scene
	assert(pro is Prologue)
	assert(Game.phase == Game.PHASE_PROLOGUE)
	assert(Game.hero.level == 0 and Game.hero.cls.id == &"aldeao")
	assert(pro._gate_wall != null)
	# 9.3: o tutorial é uma missão visível desde o primeiro segundo
	# (painel J + tracker da HUD — o jogador nunca fica sem saber o que fazer)
	assert(Game.quest_log.is_active(&"prologo_tutorial"), "quest do tutorial ativa no diario")
	assert(Game.quest_log.tracked_quest() != null and Game.quest_log.tracker_line() != "",
		"tracker da HUD mostra o objetivo do tutorial")
	assert(Game.quest_log.tracked == &"prologo_tutorial",
		"prólogo fixa a missão do tutorial no tracker desde o 1º segundo")
	print("[smoke]   prologo carregou — passo %d" % pro.tut_step)
	# 6.4: onboarding visual — seta-guia aponta o objetivo do passo
	assert(pro._guide is Polygon2D, "seta-guia criada")
	assert(pro._guide_target() == Vector2.ZERO, "passo MOVE: livre, sem seta")
	# Regressão: com o portão aberto, todos os lobos devem ser alcançáveis a pé
	# (BFS no grid a partir de START_CELL — a parede do portão não entra no grid)
	var reachable := {Prologue.START_CELL: true}
	var queue: Array[Vector2i] = [Prologue.START_CELL]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + d
			if not reachable.has(n) and pro.gen.is_floor(n):
				reachable[n] = true
				queue.append(n)
	for wc in Prologue.WOLF_CELLS:
		assert(reachable.has(wc), "lobo em %s alcançável a pé com o portão aberto" % str(wc))
	print("[smoke]   floresta ok — %d células alcançáveis, %d lobos acessíveis" % [reachable.size(), Prologue.WOLF_CELLS.size()])
	# Passo 1: mover
	pro._moved = Prologue.MOVE_DIST
	await _wait(0.3)
	assert(pro.tut_step == Prologue.TutStep.ATTACK)
	assert(pro._guide_target() == pro._espantalho.global_position, "seta aponta o espantalho")
	# passo demorado -> dica contextual
	pro._step_time = Prologue.HINT_DELAY + 0.1
	await _wait(0.4)
	assert(pro._hint_shown, "dica contextual após o atraso")
	# destaque de HUD: passo EQUIP pulsa o botão I, POTION pulsa a cura simples (Q)
	assert(pro.hud._bar_buttons.has("I") and pro.hud._bar_buttons.has("K"), "botões de barra registrados")
	pro.hud.pulse_hint("I")
	pro.hud.pulse_hint("Q")
	await _wait(0.2)
	# Passo 2: atacar — espantalho cai e solta a Espada de Treino
	pro._espantalho.take_damage(999999.0, true, Vector2.ZERO, 0.0)
	await _wait(0.5)
	assert(pro.tut_step == Prologue.TutStep.COLLECT)
	# Passo 3: coletar a Espada de Treino
	var sword: Item = null
	for n in get_tree().get_nodes_in_group("interactables"):
		if n is LootDrop and n.item and n.item.base_id == &"wood_sword":
			sword = n.item
			n.interact(pro.player)
			break
	assert(sword != null)
	await _wait(0.3)
	assert(pro.tut_step == Prologue.TutStep.EQUIP)
	print("[smoke]   atacar/coletar ok")
	# Passo 4: equipar
	pro.hud.inventory.equip_from_inventory(sword)
	await _wait(0.3)
	assert(pro.tut_step == Prologue.TutStep.POTION)
	assert(Game.hero.equipment.weapon != null)
	# Passo 5: cura simples (Q)
	pro.player.simple_heal_cd = 0.1
	await _wait(0.3)
	assert(pro.tut_step == Prologue.TutStep.CAMPFIRE)
	assert(pro._guide_target() == pro.cell_to_world(Prologue.CAMPFIRE_CELL), "seta aponta a fogueira")
	# Passo 6: fogueira — portão de névoa abre e lobos surgem na floresta
	var fire: Interactable = null
	for n in get_tree().get_nodes_in_group("interactables"):
		if n is Interactable and n.kind == Interactable.Kind.CAMPFIRE:
			fire = n
			break
	assert(fire != null)
	# Usa E para interagir com a fogueira
	pro.player._try_interact()
	await _wait(0.3)
	assert(pro.tut_step == Prologue.TutStep.DONE)
	print("[smoke]   tutorial completo — portao aberto")
	# 9.3: o diário acompanhou cada passo — agora no estágio final (espelho)
	assert(int(Game.quest_log.state(&"prologo_tutorial")["stage"]) == 6,
		"diario no ultimo estagio (espelho) apos a fogueira")
	# 6.4: fim do tutorial — a seta se recolhe
	assert(not pro._guide.visible, "seta se esconde ao concluir o tutorial")
	print("[smoke]   onboarding ok (seta-guia por passo, dica apos atraso, destaque na HUD)")
	# As duas lutas: lobos dão XP para alcançar o nível 1
	var wolves := 0
	for e in pro.enemies_near(pro.player.global_position, 99999.0):
		if e.data.id == &"lobo_sombrio":
			wolves += 1
	assert(wolves >= 3)
	for e in pro.enemies_near(pro.player.global_position, 99999.0):
		if e.data.id == &"lobo_sombrio":
			e.take_damage(999999.0, true, Vector2.ZERO, 0.0)
	await _wait(1.0)
	assert(Game.hero.level == 1)
	assert(pro._level1_seen)
	print("[smoke]   nivel 1 alcancado (%d lobos)" % wolves)
	# Save v4 do prólogo sobrevive a um roundtrip
	Game.save_game()
	assert(Game.load_game())
	assert(Game.phase == Game.PHASE_PROLOGUE and Game.hero.level == 1)
	# Espelho: nível 1 + tutorial completo → cutscene → criação (MECANICAS §11)
	var mirror: Interactable = null
	for n in get_tree().get_nodes_in_group("interactables"):
		if n is Interactable and n.kind == Interactable.Kind.MIRROR:
			mirror = n
			break
	assert(mirror != null)
	mirror.interact(pro.player)
	await _wait(5.0)
	var cc := get_tree().current_scene
	assert(cc != null and cc.has_method("_on_start") and cc.has_method("_on_next"))
	assert(Game.phase == Game.PHASE_PROLOGUE)
	assert(Game.quest_log.is_completed(&"prologo_tutorial"), "quest do tutorial concluida no espelho")
	print("[smoke]   espelho -> criacao de personagem")
	# Wizard sequencial: raça → classe → atributos (27 pts) → nome — todos obrigatórios
	cc._randomize()
	assert(cc._step == 0 and cc._can_continue())
	cc._on_next()
	assert(cc._step == 1 and cc._can_continue())
	cc._on_next()
	assert(cc._step == 2 and cc._can_continue())
	cc._on_next()
	assert(cc._step == 3 and cc._can_continue())
	cc._on_next()  # passo final = _on_start → finish_prologue
	await _wait(3.0)
	assert(Game.phase == Game.PHASE_CREATED)
	assert(Game.ignorance == 10)
	assert(Game.hero.level == 1 and Game.hero.cls.id != &"aldeao")
	var ow := get_tree().get_first_node_in_group("world")
	assert(ow != null and ow.has_method("travel_to"))
	assert(Game.awakened_from_prologue == false)  # diálogo de despertar consumido pela 1.5
	print("[smoke]   wizard concluido — %s %s acorda no acampamento" % [Game.hero.race.display_name, Game.hero.cls.display_name])
	# 2.2: diálogo ramificado real do despertar, via DialogueBox/UI (motor)
	var box: DialogueBox = ow.hud._dialogue_box
	assert(box != null and box.engine.current != null)
	box.engine.advance()  # acorda: página 2
	box.engine.advance()  # -> escolhas (ignorância 10 > 5: versão leiga, 2 visíveis)
	assert(box.engine.visible_choices().size() == 2)
	box.engine.choose(0)  # "O que é este lugar?" -> ignorancia -1
	assert(Game.ignorance == 9 and box.engine.current.id == &"lugar")
	box.engine.advance()  # lugar: 1 página -> escolhas
	box.engine.choose(0)  # "…e o que aconteceu comigo?"
	assert(box.engine.current.id == &"aconteceu")
	box.engine.advance()  # aconteceu: página 2
	box.engine.advance()  # -> escolhas
	box.engine.choose(0)  # "E agora?" -> adeus
	assert(box.engine.current.id == &"adeus")
	box.engine.advance()  # adeus: 1 página -> escolhas
	box.engine.choose(0)  # "(Partir)" -> encerra + flag
	assert(box.engine.current == null)
	assert(bool(Game.flags.get("cinzento_primeiro_dialogo", false)))
	await _wait(1.0)
	assert(ow.hud._dialogue_box == null)  # caixa fechou e se libertou
	print("[smoke]   dialogo de despertar concluido (ignorancia %d)" % Game.ignorance)
	# Fix missão inicial: o Cinzento não é mais efêmero — permanece no
	# acampamento como interactable (quem fechar antes da despedida,
	# ou chegar ao estágio "volte ao Cinzento", o reencontra)
	assert(ow._cinzento != null and ow._cinzento.interactive)
	assert(ow._cinzento.is_in_group("interactables"))
	assert(ow._cinzento.display_name() == "Cinzento")
	assert(ow.get_interactable_at(ow._cinzento.global_position + Vector2(0, -8)) == ow._cinzento,
		"hover no Cinzento o encontra como interactable")
	# Fecha o diálogo ANTES da despedida (ESC): flag ainda não setada, mas o
	# jogador não fica preso — pode re-conversar (quest_log.start é idempotente)
	ow._cinzento.interact(ow.player)
	await _wait(0.3)
	var box2: DialogueBox = ow.hud._dialogue_box
	assert(box2 != null and box2.engine.current != null)
	box2.engine.stop()
	await _wait(1.0)
	assert(ow.hud._dialogue_box == null)
	assert(ow._cinzento != null and is_instance_valid(ow._cinzento),
		"o Cinzento continua no mundo após fechar o diálogo cedo")
	print("[smoke]   cinzento persistente: reencontravel apos fechar o dialogo cedo")
	print("[smoke] prologo ok")


func _test_dialogue() -> void:
	print("[smoke] dialogo")
	# Herói de teste com ignorância alta (versão "leiga" dos diálogos)
	var hero := Hero.create("Testador", DB.races[0], DB.classes[0], "m", Color.WHITE, {"str": 14, "dex": 12, "con": 14, "int": 10, "wis": 10, "cha": 10})
	Game.hero = hero
	Game.ignorance = 10
	Game.reputation = {}
	Game.flags = {}
	var gold_before := hero.gold
	# Grafo: raiz (2 páginas) -> escolhas condicionais -> nó final sem escolhas
	var n_root := DialogueNode.new()
	n_root.id = &"raiz"
	n_root.pages = PackedStringArray(["Primeira página.", "Segunda página."])
	var c_ignorante := DialogueChoice.new()
	c_ignorante.text = "O que é uma guilda?"
	c_ignorante.next_id = &"explica"
	c_ignorante.condition = "ignorancia > 5"
	c_ignorante.effects = "ignorancia -1\nflag perguntou_guilda\ngold 25\nrep humano +1"
	var c_sabido := DialogueChoice.new()
	c_sabido.text = "Sigo meu caminho."
	c_sabido.condition = "ignorancia <= 5"
	n_root.choices = [c_ignorante, c_sabido]
	var n_explica := DialogueNode.new()
	n_explica.id = &"explica"
	n_explica.text = "É onde gente de ofício se junta — e onde memória vira salário."
	var d := DialogueData.new()
	d.id = &"teste"
	d.portrait = "k:121"
	d.start_id = &"raiz"
	d.nodes = [n_root, n_explica]
	# Motor: paginação
	var eng := DialogueEngine.new()
	# Lambdas capturam locais POR VALOR: mutações (append/índice) são visíveis
	# fora, mas rebinding (x = ...) não — por isso o estado vai num Dictionary.
	var st := {"pages": [], "choices": [], "ended": false}
	eng.page_shown.connect(func(t: String, portrait: String): st["pages"].append([t, portrait]))
	eng.choices_shown.connect(func(cs: Array): st["choices"] = cs)
	eng.dialogue_ended.connect(func(): st["ended"] = true)
	eng.start(d)
	assert(st["pages"].size() == 1 and st["pages"][0][0] == "Primeira página." and st["pages"][0][1] == "k:121")
	eng.advance()
	assert(st["pages"].size() == 2 and st["pages"][1][0] == "Segunda página.")
	# Escolhas: ignorância 10 > 5 -> só a versão leiga é visível
	eng.advance()
	assert(st["choices"].size() == 1 and st["choices"][0].text == "O que é uma guilda?")
	# Efeitos: ignorância, flag, ouro, reputação
	eng.choose(0)
	assert(Game.ignorance == 9)
	assert(bool(Game.flags.get("perguntou_guilda", false)))
	assert(hero.gold == gold_before + 25)
	assert(int(Game.reputation.get(&"humano", 0)) == 1)
	assert(st["pages"].size() == 3 and st["pages"][2][0] == "É onde gente de ofício se junta — e onde memória vira salário.")
	# Nó sem escolhas: advance na única página encerra
	assert(not st["ended"])
	eng.advance()
	assert(st["ended"])
	# Condições do resolver: raca/classe/item/nivel/negacao/AND
	assert(ConditionResolver.eval("raca = %s" % hero.race.id))
	assert(ConditionResolver.eval("classe = %s" % hero.cls.id))
	assert(not ConditionResolver.eval("raca = %s" % hero.race.id + ", !flag perguntou_guilda"))
	assert(ConditionResolver.eval("flag perguntou_guilda, ignorancia <= 9"))
	assert(ConditionResolver.eval("nivel >= 1, item wood_sword"))
	assert(not ConditionResolver.eval("item espada_inexistente"))
	assert(ConditionResolver.eval(""))
	print("[smoke] dialogo ok")


func _test_overworld() -> void:
	var h := Hero.create("Explorador", DB.races[0], DB.classes[3], "m", Color.WHITE, {"str": 15, "dex": 13, "con": 14, "int": 12, "wis": 10, "cha": 8})
	h.level = 8
	h.refresh_skill_bar()
	Game.new_game(h)
	await _wait(2.5)
	var ow: Overworld = get_tree().get_first_node_in_group("world")
	assert(ow != null)
	print("[smoke] mundo aberto: chunks=%d inimigos=%d" % [ow.chunks.size(), get_tree().get_nodes_in_group("enemies").size()])
	# 2.3: NPCs conversáveis — ignorância decai, NPCs lembram (flags), reputação por raça
	Game.ignorance = 10
	var marn: Npc = null
	var bree: Npc = null
	for n in get_tree().get_nodes_in_group("npcs"):
		if n is Npc:
			if n.data.id == &"marn_vigia":
				marn = n
			elif n.data.id == &"bree_cozinheira":
				bree = n
	assert(marn != null and bree != null)
	assert(marn.display_name() == "Marn — Vigia do Acampamento")
	# hover duck-typed: o mundo encontra o NPC como interactable
	assert(ow.get_interactable_at(marn.global_position + Vector2(0, -8)) == marn)
	marn.interact(ow.player)
	var box: DialogueBox = ow.hud._dialogue_box
	assert(box != null and box.engine.current.id == &"inicio")
	# primeira conversa: só "(Cumprimentar)" (flag não setada)
	assert(box.engine.visible_choices().size() == 1)
	box.engine.advance()  # 1 página: advance arma as escolhas
	box.engine.choose(0)
	assert(box.engine.current.id == &"apresentacao" and bool(Game.flags.get("marn_apresentado", false)))
	box.engine.advance()
	box.engine.advance()
	assert(box.engine.visible_choices().size() == 1)  # (Continuar)
	box.engine.choose(0)
	assert(box.engine.current.id == &"menu")
	# ignorância 10: lugar, territórios (leigo), promessa, partir — patrulla fica oculta
	var vc := box.engine.visible_choices()
	assert(vc.size() == 4)
	box.engine.advance()  # menu 1 página -> escolhas
	box.engine.choose(2)  # "O acampamento está seguro comigo."
	assert(bool(Game.flags.get("marn_promessa", false)))
	assert(int(Game.reputation.get(&"humano", 0)) == 1)
	assert(box.engine.current.id == &"promessa")
	box.engine.advance()
	box.engine.choose(1)  # (Partir)
	await _wait(1.2)
	assert(ow.hud._dialogue_box == null)
	# segunda conversa: Marn lembra — "(Falar de novo)"; promessa já feita some do menu
	marn.interact(ow.player)
	box = ow.hud._dialogue_box
	assert(box.engine.visible_choices().size() == 1 and box.engine.visible_choices()[0].text == "(Falar de novo)")
	box.engine.advance()  # 1 página -> escolhas
	box.engine.choose(0)
	assert(box.engine.current.id == &"menu" and box.engine.visible_choices().size() == 3)
	box.engine.advance()  # menu 1 página -> escolhas
	box.engine.choose(1)  # "O que são 'territórios'?" (leigo) -> ignorância decai
	assert(Game.ignorance == 9 and box.engine.current.id == &"territorios")
	box.engine.stop()
	await _wait(1.2)
	assert(ow.hud._dialogue_box == null)
	# Bree: sopa de cortesia (uma única vez, flag-gated)
	bree.interact(ow.player)
	box = ow.hud._dialogue_box
	assert(box.engine.visible_choices().size() == 2)  # sopa + cumprimentar
	box.engine.advance()  # inicio: página 1 -> 2
	box.engine.advance()  # página 2 -> escolhas armadas
	box.engine.choose(0)
	assert(bool(Game.flags.get("bree_sopa", false)) and box.engine.current.id == &"sopa")
	box.engine.advance()
	box.engine.advance()
	box.engine.choose(1)  # (Partir)
	await _wait(1.2)
	assert(ow.hud._dialogue_box == null)
	print("[smoke]   npcs conversam (ignorancia %d, rep humano %d)" % [Game.ignorance, int(Game.reputation.get(&"humano", 0))])
	# 2.4: territórios raciais — 14 capitais, Voronoi determinístico, Vale neutro
	var terr: Territories = ow.territories
	assert(terr != null and terr.capitals.size() == 14)
	# capital do jogador na origem; acampamento promovido a capital
	assert(terr.capital_of(h.race.id) == Vector2.ZERO)
	var camp := ""
	for n in get_tree().get_nodes_in_group("interactables"):
		if n is Interactable and n.kind == Interactable.Kind.CAMPFIRE:
			camp = n.label
	assert(camp == DB.territory(h.race.id).capital_name)
	# espaçamento mínimo garantido + sem líquido + bioma válido
	var races_list: Array = terr.capitals.keys()
	var og := ow.og
	for i in races_list.size():
		var ci: Vector2 = terr.capitals[races_list[i]]
		var biome: String = og.biome_at(Vector2i(roundi(ci.x), roundi(ci.y)))
		assert(not og.liquid_at(Vector2i(roundi(ci.x), roundi(ci.y)), biome))
		for j in range(i + 1, races_list.size()):
			assert(ci.distance_to(terr.capitals[races_list[j]]) >= Territories.CAPITAL_MIN_GAP)
		# a vizinhança da capital pertence ao seu território (nome da capital na HUD)
		assert(terr.region_name_at(Vector2i(roundi(ci.x), roundi(ci.y))).begins_with(DB.territory(races_list[i]).capital_name))
	# Vale do Centro: neutro até o raio, território de alguém depois
	assert(terr.territory_at(Vector2i(30, 0)) == &"")
	assert(terr.territory_at(Vector2i(50, 0)) != &"")
	assert(terr.region_name_at(Vector2i(30, 0)) == "Vale do Centro — a Kinfire apagada" or terr.region_name_at(Vector2i(30, 0)).begins_with(DB.territory(h.race.id).capital_name))
	# determinismo: mesma semente + raça => mesmas capitais
	var terr2 := Territories.new(Game.world_seed, h.race.id)
	for race in terr.capitals:
		assert(terr.capitals[race] == terr2.capitals[race])
	# level_at integra o modificador do território
	assert(ow.level_at(ow.player.global_position) == 1)  # capital: nível 1
	print("[smoke]   territorios ok (%d capitais, gap >= %d)" % [terr.capitals.size(), Territories.CAPITAL_MIN_GAP])
	# 2.5: NPCs por território — líder + gente comum com ganho-de-vida (LORE §X)
	var leader: Npc = null
	var comuns := 0
	for n in get_tree().get_nodes_in_group("npcs"):
		if not n is Npc:
			continue
		if n.data.dialogue_id == &"capital_humano_lider":
			leader = n
		elif n.data.dialogue_id in [&"capital_humano_comum0", &"capital_humano_comum1", &"capital_humano_comum2"]:
			comuns += 1
	assert(leader != null and comuns == 3)
	assert(leader.display_name() == "Guildmaster Eleanor Vane — Líder de Porto Franco")
	leader.interact(ow.player)
	box = ow.hud._dialogue_box
	assert(box.engine.current.id == &"inicio")
	box.engine.advance()  # 1 página -> escolhas
	box.engine.choose(0)  # (Apresentar-se)
	assert(box.engine.current.id == &"apresentacao" and bool(Game.flags.get("capital_humano_apresentado", false)))
	box.engine.advance()  # apresentação: página 2
	box.engine.advance()  # -> escolhas
	box.engine.choose(0)  # (Continuar) -> menu
	assert(box.engine.current.id == &"menu" and box.engine.visible_choices().size() == 6)  # + (Negociar) da 5.5
	box.engine.advance()  # menu: 1 página -> escolhas
	box.engine.choose(4)  # (Oferecer ajuda ao território)
	assert(bool(Game.flags.get("capital_humano_promessa", false)))
	assert(int(Game.reputation.get(&"humano", 0)) == 2)  # 1 (Marn) + 1 (líder)
	assert(box.engine.current.id == &"promessa")
	box.engine.stop()
	await _wait(1.2)
	assert(ow.hud._dialogue_box == null)
	# território não-jogador: o template gera diálogo coeso a partir do TerritoryData
	TerritoryNpcs.populate(ow, &"drow", ow.player.global_position + Vector2(140, -60))
	var drow: Npc = null
	for n in get_tree().get_nodes_in_group("npcs"):
		if n is Npc and n.data.dialogue_id == &"capital_drow_comum0":
			drow = n
	assert(drow != null)
	drow.interact(ow.player)
	box = ow.hud._dialogue_box
	assert(box.engine.current.id == &"inicio")
	box.engine.advance()  # 1 página -> escolhas
	assert(box.engine.visible_choices().size() == 3)  # trabalho + lugar (leigo) + partir
	box.engine.choose(0)  # "No que você trabalha?"
	assert(box.engine.current.id == &"trabalho")
	assert(box.engine.current.page(0).contains("venenos, seda de aranha-gigante"))  # economia do TerritoryData drow
	box.engine.stop()
	await _wait(1.2)
	assert(ow.hud._dialogue_box == null)
	print("[smoke]   capital povoada (lider + %d comuns, rep humano %d, ignorancia %d)" % [comuns, int(Game.reputation.get(&"humano", 0)), Game.ignorance])
	# 2.6: aceitação da Fase 2 — cada raça com capital, 4 NPCs únicos,
	# diálogo ramificado e economia própria (validação permanente dos templates)
	var races_ok := 0
	for race_res in DB.races:
		var race: RaceData = race_res
		var td: TerritoryData = DB.territory(race.id)
		assert(td != null, "territorio %s ausente" % race.id)
		assert(td.capital_name != "" and td.leader_name != "" and td.economy != "" and td.culture != "",
			"territorio %s com campo vazio" % race.id)
		assert(terr.capital_of(race.id) != Vector2.INF, "capital de %s sem posicao" % race.id)
		TerritoryNpcs._ensure_dialogues(race.id, td)
		for suffix in ["lider", "comum0", "comum1", "comum2"]:
			var dd: DialogueData = DB.dialogue(TerritoryNpcs._id(race.id, suffix))
			assert(dd != null, "dialogo %s/%s nulo" % [race.id, suffix])
			assert(dd.node(dd.start_id) != null, "dialogo %s/%s start quebrado" % [race.id, suffix])
			var has_branch := false
			for n in dd.nodes:
				assert(n.page_count() >= 1, "dialogo %s/%s no %s vazio" % [race.id, suffix, n.id])
				for c in n.choices:
					assert(c.next_id == &"" or dd.node(c.next_id) != null,
						"dialogo %s/%s no %s -> %s inexistente" % [race.id, suffix, n.id, c.next_id])
					if c.condition != "" or c.next_id != &"":
						has_branch = true
			assert(has_branch, "dialogo %s/%s sem ramificacao" % [race.id, suffix])
		races_ok += 1
	assert(races_ok == 14)
	print("[smoke]   aceitacao fase 2: %d racas com capital + 4 NPCs + dialogo ramificado + economia" % races_ok)
	# 3.1: raridades de monstro — multiplicadores, títulos e roll (REGRAS §6)
	var goblin: EnemyData = DB.get_enemy(&"goblin")
	var diff: Dictionary = Game.hero.difficulty_data()
	var base_hp: float = goblin.max_hp * (1.0 + 0.4 * (5 - 1)) * diff.hp
	var e_lend: Enemy = ow.spawn_enemy(goblin, ow.player.global_position + Vector2(2400, 0), Enemy.Rarity.LENDARIO, 5)
	assert(e_lend.rarity == Enemy.Rarity.LENDARIO)
	assert(is_equal_approx(e_lend.max_hp, base_hp * 10.0))
	assert(e_lend.display_name.ends_with(", o Lendário"))
	var e_camp: Enemy = ow.spawn_enemy(goblin, ow.player.global_position + Vector2(2500, 0), Enemy.Rarity.CAMPEAO, 5)
	assert(is_equal_approx(e_camp.max_hp, base_hp * 5.0))
	assert(is_equal_approx(e_camp.damage, goblin.damage * (1.0 + 0.25 * 4.0) * diff.dmg * 1.8))
	assert(e_camp.display_name.begins_with("Campeão "))
	var e_elite: Enemy = ow.spawn_enemy(goblin, ow.player.global_position + Vector2(2600, 0), Enemy.Rarity.ELITE, 5)
	assert(is_equal_approx(e_elite.max_hp, base_hp * 2.5) and e_elite.xp == int(goblin.xp * (1.0 + 0.3 * 4)) * 3)
	var azkhar: EnemyData = DB.get_enemy(&"azkhar")
	var e_chefe: Enemy = ow.spawn_enemy(azkhar, ow.player.global_position + Vector2(2700, 0), Enemy.Rarity.CHEFE, 1)
	assert(e_chefe.is_boss() and e_chefe.rarity == Enemy.Rarity.CHEFE)
	assert(is_equal_approx(e_chefe.max_hp, azkhar.max_hp * diff.hp))  # tabela não multiplica chefe (roteirizado)
	e_lend.queue_free()
	e_camp.queue_free()
	e_elite.queue_free()
	e_chefe.queue_free()
	# roll: distribuição estatística (20k rolagens, nível 1, Normal)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var counts := [0, 0, 0, 0, 0]
	for i in 20000:
		counts[Enemy.roll_rarity(1, 0.0, rng)] += 1
	assert(counts[Enemy.Rarity.LENDARIO] >= 30 and counts[Enemy.Rarity.LENDARIO] <= 90)     # ~0.3%
	assert(counts[Enemy.Rarity.CAMPEAO] >= 300 and counts[Enemy.Rarity.CAMPEAO] <= 500)    # ~2%
	assert(counts[Enemy.Rarity.ELITE] >= 1500 and counts[Enemy.Rarity.ELITE] <= 2100)      # ~9%
	# bônus de dificuldade (Inferno +28%) aumenta as raridades
	rng.seed = 42
	var raros := 0
	for i in 20000:
		if Enemy.roll_rarity(1, 0.28, rng) >= Enemy.Rarity.ELITE:
			raros += 1
	assert(raros > 6000)  # ~40% vs ~11% sem bônus
	print("[smoke]   raridades ok (elite x2.5, campeao x5, lendario x10; roll distribuido)")
	# 3.2: afixos de Campeão (MECANICAS §5.2) — roll determinístico e efeitos
	var pp := ow.player.global_position
	var rng3 := RandomNumberGenerator.new()
	rng3.seed = 99
	var a1 := Enemy.roll_affixes(rng3, 4)
	assert(a1.size() == 4)
	for i in a1.size():
		assert(a1[i] >= 0 and a1[i] <= Enemy.Affix.CAMPEAO_DAS_SOMBRAS, "afixo fora do enum")
		for j in range(i + 1, a1.size()):
			assert(a1[i] != a1[j], "afixo repetido no roll")
	assert(Enemy.roll_affixes(rng3, 8).size() == 8)  # todos os 8 sem repetição
	# affixes_for: Comum/Chefe sem afixos; Campeão 1–2; Lendário 2–3; Inferno +1 a Elite+
	rng3.seed = 99
	assert(Enemy.affixes_for(Enemy.Rarity.COMUM, rng3).is_empty())
	assert(Enemy.affixes_for(Enemy.Rarity.ELITE, rng3).is_empty())
	assert(Enemy.affixes_for(Enemy.Rarity.ELITE, rng3, true).size() == 1)  # Inferno +1
	assert(Enemy.affixes_for(Enemy.Rarity.CHEFE, rng3, true).is_empty())    # chefe roteirizado
	var sizes := [0, 0, 0, 0, 0]
	for i in 500:
		sizes[Enemy.affixes_for(Enemy.Rarity.CAMPEAO, rng3).size()] += 1
	assert(sizes[0] == 0 and sizes[3] == 0 and sizes[4] == 0 and sizes[1] > 0 and sizes[2] > 0)
	sizes = [0, 0, 0, 0, 0]
	for i in 500:
		sizes[Enemy.affixes_for(Enemy.Rarity.LENDARIO, rng3).size()] += 1
	assert(sizes[0] == 0 and sizes[1] == 0 and sizes[4] == 0 and sizes[2] > 0 and sizes[3] > 0)
	for i in 200:
		var n := Enemy.affixes_for(Enemy.Rarity.LENDARIO, rng3, true).size()
		assert(n == 3 or n == 4)  # Inferno: Lendário 3–4
	# inimigos de teste: longe do jogador para não interferir
	var test_es: Array[Enemy] = []
	# TELÚRICO: knockback ignorado
	var e_ctl: Enemy = ow.spawn_enemy(goblin, pp + Vector2(2800, 0), Enemy.Rarity.COMUM, 5)
	var e_tel: Enemy = ow.spawn_enemy(goblin, pp + Vector2(2900, 0), Enemy.Rarity.COMUM, 5, [Enemy.Affix.TELURICO])
	test_es.append(e_ctl)
	test_es.append(e_tel)
	e_ctl.take_damage(5.0, false, e_ctl.global_position + Vector2(100, 0), 100.0)
	e_tel.take_damage(5.0, false, e_tel.global_position + Vector2(100, 0), 100.0)
	assert(e_ctl._knock.length() > 1.0, "controle deveria sofrer knockback")
	assert(e_tel._knock == Vector2.ZERO, "TELÚRICO imune a knockback")
	assert(e_tel.affix_names() == ["Telúrico"])
	# FURIOSO: recarga de ataque 30% mais rápida
	var e_fur: Enemy = ow.spawn_enemy(goblin, pp + Vector2(3050, -200), Enemy.Rarity.COMUM, 5, [Enemy.Affix.FURIOSO])
	test_es.append(e_fur)
	assert(absf(e_fur._reset_attack_cd(1.0) - 0.7) < 0.001)
	assert(absf(e_ctl._reset_attack_cd(1.0) - 1.0) < 0.001)  # sem afixo: base cheia
	# MESTRE-DE-ENXAME: invoca 3 lacaios COMUM a 50% de HP
	var e_swm: Enemy = ow.spawn_enemy(goblin, pp + Vector2(2950, 200), Enemy.Rarity.COMUM, 5, [Enemy.Affix.MESTRE_DE_ENXAME])
	test_es.append(e_swm)
	e_swm.take_damage(e_swm.max_hp * 0.6, false, Vector2.INF, 0.0)
	# consulta direta ao grupo: o hash espacial só reconstrói a cada frame de física
	var swarm := 0
	for n in get_tree().get_nodes_in_group("enemies"):
		var en := n as Enemy
		if en != null and en.global_position.distance_to(e_swm.global_position) < 100.0:
			swarm += 1
			if not test_es.has(en):
				test_es.append(en)
	assert(swarm >= 4, "enxame deveria ter 3 lacaios + o mestre")
	# ARDENTE: deixa piso em chamas a cada 1,5s
	var e_ard: Enemy = ow.spawn_enemy(goblin, pp + Vector2(3150, 200), Enemy.Rarity.COMUM, 5, [Enemy.Affix.ARDENTE])
	test_es.append(e_ard)
	await _wait(0.2)
	assert(ow.fire_zones.size() >= 1, "ARDENTE deveria criar zona de fogo")
	# VENENOSO: golpe aplica veneno; veneno tica a cada 1s (dano direto)
	var e_ven: Enemy = ow.spawn_enemy(goblin, pp + Vector2(3250, 0), Enemy.Rarity.COMUM, 5, [Enemy.Affix.VENENOSO])
	test_es.append(e_ven)
	e_ven._hit_target(ow.player, 5.0)
	assert(ow.player.is_poisoned(), "VENENOSO deveria envenenar o alvo")
	ow.player._combat_timer = 4.0  # sem regeneração fora de combate no teste
	ow.player.hp = ow.player.max_hp
	ow.player.apply_poison(10.0, 1.5)
	await _wait(1.15)
	assert(ow.player.hp <= ow.player.max_hp - 10.0, "tique de veneno deveria ferir 10")
	# ESCUDO ARCANO: absorve antes do HP e regenera a cada 5s
	var e_esc: Enemy = ow.spawn_enemy(goblin, pp + Vector2(3100, 0), Enemy.Rarity.CAMPEAO, 5, [Enemy.Affix.ESCUDO_ARCANO])
	test_es.append(e_esc)
	var esc_max: float = e_esc.max_hp * 0.1
	assert(is_equal_approx(e_esc._shield, esc_max), "escudo inicial 10% do HP")
	var shield_before: float = e_esc._shield
	var ret_esc := e_esc.take_damage(20.0, false, Vector2.INF, 0.0)
	assert(ret_esc == 0.0 and e_esc.hp == e_esc.max_hp, "escudo absorve antes do HP")
	assert(e_esc._shield < shield_before and e_esc._shield > 0.0)
	await _wait(5.3)
	assert(is_equal_approx(e_esc._shield, esc_max), "escudo regenera a cada 5s")
	# FANTASMA: ~20% de esquiva (100 golpes)
	var e_fan: Enemy = ow.spawn_enemy(goblin, pp + Vector2(3000, 0), Enemy.Rarity.CAMPEAO, 5, [Enemy.Affix.FANTASMA])
	test_es.append(e_fan)
	var esquivas := 0
	for i in 100:
		var hp_antes: float = e_fan.hp
		if e_fan.take_damage(1.0, false, Vector2.INF, 0.0) == 0.0 and e_fan.hp == hp_antes:
			esquivas += 1
	assert(esquivas >= 8 and esquivas <= 32, "FANTASMA ~20%% de esquiva (foi %d)" % esquivas)
	# CAMPEÃO-DAS-SOMBRAS: teleporta para perto do alvo a cada 6s
	var e_shd: Enemy = ow.spawn_enemy(goblin, pp + Vector2(3200, -200), Enemy.Rarity.COMUM, 5, [Enemy.Affix.CAMPEAO_DAS_SOMBRAS])
	test_es.append(e_shd)
	e_shd.state = Enemy.State.CHASE
	assert(e_shd.global_position.distance_to(ow.player.global_position) > 2000.0)
	await _wait(3.5)
	assert(e_shd.global_position.distance_to(ow.player.global_position) < 200.0, "SOMBRAS deveria teleportar")
	for e in test_es:
		if is_instance_valid(e):
			e.queue_free()
	print("[smoke]   afixos ok (roll sem repeticao; furioso/escudo/telurico/venenoso/fantasma/enxame/ardente/sombras)")
	# 3.3: LootTableData por raridade (REGRAS §6) + essência (REGRAS §9)
	assert(DB.loot_tables.size() == 5, "uma tabela de loot por raridade")
	assert(is_equal_approx(DB.loot_tables[Enemy.Rarity.COMUM].item_chance, 0.10))
	assert(DB.loot_tables[Enemy.Rarity.ELITE].guaranteed == [Item.Rarity.MAGIC])
	assert(DB.loot_tables[Enemy.Rarity.CAMPEAO].guaranteed == [Item.Rarity.RARE])
	assert(is_equal_approx(DB.loot_tables[Enemy.Rarity.CAMPEAO].essence_chance, 0.5))
	assert(DB.loot_tables[Enemy.Rarity.LENDARIO].guaranteed == [Item.Rarity.LEGENDARY])
	assert(is_equal_approx(DB.loot_tables[Enemy.Rarity.LENDARIO].essence_chance, 1.0))
	assert(DB.loot_tables[Enemy.Rarity.CHEFE].guaranteed.size() == 2)
	assert(DB.loot_tables[Enemy.Rarity.CHEFE].essence_amount == 2)
	var drops33 := func(kind33: int, pos33: Vector2) -> Array:
		var out := []
		for n33 in ow.entities.get_children():
			var d33 := n33 as LootDrop
			if d33 != null and not d33.is_queued_for_deletion() and d33.kind == kind33 \
					and d33.global_position.distance_to(pos33) < 60.0:
				out.append(d33)
		return out
	var limpar33 := func(pos33: Vector2) -> void:
		for n33 in ow.entities.get_children():
			var d33 := n33 as LootDrop
			if d33 != null and d33.global_position.distance_to(pos33) < 80.0:
				ow.entities.remove_child(n33)
				n33.queue_free()
	var e33: Enemy = ow.spawn_enemy(goblin, pp + Vector2(3400, 0), Enemy.Rarity.COMUM, 5)
	e33.take_damage(99999.0, false, Vector2.INF, 0.0)
	assert(drops33.call(LootDrop.Kind.ESSENCE, e33.global_position).is_empty(), "COMUM nao dropa essencia")
	limpar33.call(e33.global_position)
	e33 = ow.spawn_enemy(goblin, pp + Vector2(3450, 0), Enemy.Rarity.ELITE, 5)
	e33.take_damage(99999.0, false, Vector2.INF, 0.0)
	var tem_magico := false
	for l33 in drops33.call(LootDrop.Kind.ITEM, e33.global_position):
		if (l33 as LootDrop).item.rarity >= Item.Rarity.MAGIC:
			tem_magico = true
	assert(tem_magico, "ELITE garante >=1 item magico")
	assert(drops33.call(LootDrop.Kind.ESSENCE, e33.global_position).is_empty(), "ELITE nao dropa essencia")
	limpar33.call(e33.global_position)
	# afixos explícitos: FANTASMA tem 20% de esquiva (enemy.gd) e faria o
	# take_damage determinístico falhar aleatoriamente
	e33 = ow.spawn_enemy(goblin, pp + Vector2(3500, 0), Enemy.Rarity.CAMPEAO, 5, [Enemy.Affix.FURIOSO, Enemy.Affix.VENENOSO])
	e33.take_damage(99999.0, false, Vector2.INF, 0.0)
	var tem_raro := false
	for l33 in drops33.call(LootDrop.Kind.ITEM, e33.global_position):
		if (l33 as LootDrop).item.rarity >= Item.Rarity.RARE:
			tem_raro = true
	assert(tem_raro, "CAMPEAO garante >=1 item raro")
	limpar33.call(e33.global_position)
	e33 = ow.spawn_enemy(goblin, pp + Vector2(3550, 0), Enemy.Rarity.LENDARIO, 5, [Enemy.Affix.FURIOSO, Enemy.Affix.VENENOSO])
	e33.take_damage(99999.0, false, Vector2.INF, 0.0)
	var tem_lend := false
	for l33 in drops33.call(LootDrop.Kind.ITEM, e33.global_position):
		if (l33 as LootDrop).item.rarity == Item.Rarity.LEGENDARY:
			tem_lend = true
	assert(tem_lend, "LENDARIO garante >=1 item lendario")
	assert(drops33.call(LootDrop.Kind.ESSENCE, e33.global_position).size() == 1, "LENDARIO dropa 1 essencia")
	limpar33.call(e33.global_position)
	e33 = ow.spawn_enemy(azkhar, pp + Vector2(3600, 0), Enemy.Rarity.CHEFE, 1)
	e33.take_damage(999999.0, false, Vector2.INF, 0.0)
	var raros33 := 0
	var lends33 := 0
	for l33 in drops33.call(LootDrop.Kind.ITEM, e33.global_position):
		if (l33 as LootDrop).item.rarity >= Item.Rarity.RARE:
			raros33 += 1
		if (l33 as LootDrop).item.rarity == Item.Rarity.LEGENDARY:
			lends33 += 1
	assert(raros33 >= 2, "CHEFE garante >=2 itens raros+")
	assert(lends33 >= 1, "CHEFE dropa >=1 lendario")
	var ess33: Array = drops33.call(LootDrop.Kind.ESSENCE, e33.global_position)
	assert(ess33.size() == 1 and (ess33[0] as LootDrop).essence == 2, "CHEFE dropa essencia x2")
	limpar33.call(e33.global_position)
	# estatístico: 40 campeões → ~50% dropam essência
	var ess_cont := 0
	for i in 40:
		e33 = ow.spawn_enemy(goblin, pp + Vector2(3650 + i * 4, 0), Enemy.Rarity.CAMPEAO, 5)
		e33.take_damage(99999.0, false, Vector2.INF, 0.0)
		ess_cont += drops33.call(LootDrop.Kind.ESSENCE, e33.global_position).size()
		limpar33.call(e33.global_position)
	assert(ess_cont >= 12 and ess_cont <= 28, "essencia ~50%% em campeoes (foi %d)" % ess_cont)
	# pickup magnético de essência + HUD
	var ess_antes: int = Game.hero.essence
	LootDrop.drop_essence(ow, ow.player.global_position, 3)
	var coletou := false
	for i in 30:
		await _wait(0.1)
		if Game.hero.essence == ess_antes + 3:
			coletou = true
			break
	assert(coletou, "essencia deveria ser coletada pelo ima")
	assert(ow.hud._essence.text.contains(str(ess_antes + 3)), "HUD deveria mostrar a essencia")
	print("[smoke]   loot por raridade ok (5 tabelas; elite magico, campeao raro+50% ess, lendario lendario, chefe raro x2+unico+ess x2; ima e HUD)")
	# 3.4: HUD/minimapa/mensagens refletem as novas raridades (REGRAS §6)
	var e34: Enemy = ow.spawn_enemy(goblin, pp + Vector2(3900, 0), Enemy.Rarity.CAMPEAO, 5, [Enemy.Affix.FURIOSO, Enemy.Affix.VENENOSO])
	assert(e34._spawn_beam == null, "beam de spawn e exclusivo do Lendario")
	ow.hud.show_target(e34)
	assert(ow.hud._target_affixes.visible, "target box deveria mostrar a linha de afixos")
	assert(ow.hud._target_affixes.text.contains("Furioso") and ow.hud._target_affixes.text.contains("Venenoso"),
		"afixos do Campeao deveriam aparecer no target box")
	var e34c: Enemy = ow.spawn_enemy(goblin, pp + Vector2(3950, 0), Enemy.Rarity.COMUM, 5)
	ow.hud.show_target(e34c)
	assert(not ow.hud._target_affixes.visible, "comum sem afixos deveria esconder a linha")
	e34.queue_free()
	e34c.queue_free()
	# Lendário: beam de spawn + aviso na HUD + kill anunciado (inimigo diferente => texto único)
	var aranha34: EnemyData = DB.get_enemy(&"aranha_gigante")
	var e34l: Enemy = ow.spawn_enemy(aranha34, pp + Vector2(4000, 0), Enemy.Rarity.LENDARIO, 5, [Enemy.Affix.FURIOSO, Enemy.Affix.VENENOSO])
	assert(e34l._spawn_beam != null, "Lendario deveria ter beam de spawn visivel de longe")
	var aviso34 := false
	for m34 in ow.hud._messages.get_children():
		if m34 is Label and (m34 as Label).text.contains(aranha34.display_name) and (m34 as Label).text.contains("surge nas redondezas"):
			aviso34 = true
	assert(aviso34, "spawn de Lendario deveria ser anunciado na HUD")
	e34l.take_damage(999999.0, false, Vector2.INF, 0.0)
	var kill34 := false
	for m34 in ow.hud._messages.get_children():
		if m34 is Label and (m34 as Label).text.contains(aranha34.display_name) and (m34 as Label).text.contains("Espólios lendários"):
			kill34 = true
	assert(kill34, "kill de Lendario deveria ser anunciado na HUD")
	print("[smoke]   hud/mensagens por raridade ok (afixos no target box, beam+sting+aviso de spawn do Lendario, kill anunciado)")
	# 4.1: QuestData/QuestLog (Fase 4) — eventos, estágios, recompensas, save
	var q41: QuestData = DB.quest(&"ato1_1")
	assert(q41 != null and q41.stages.size() == 3, "ato1_1 deveria existir com 3 estagios")
	# Reinicia o estado (o despertar/Marn/Bree dos blocos anteriores podem ter progredido)
	Game.quests.erase(&"ato1_1")
	Game.quest_log.tracked = &""
	assert(Game.quest_log.available(q41), "ato1_1 deveria estar disponivel")
	Game.quest_log.start(q41)
	assert(Game.quest_log.is_active(&"ato1_1") and int(Game.quest_log.state(&"ato1_1")["stage"]) == 0)
	assert(Game.quest_log.tracked_quest() != null and Game.quest_log.tracker_line() != "")
	# Estágio 1 (TALK): um não basta; dois avançam
	Game.quest_log.notify_talk(&"marn_vigia")
	assert(int(Game.quest_log.state(&"ato1_1")["stage"]) == 0, "falta a Bree")
	Game.quest_log.notify_talk(&"bree_cozinheira")
	assert(int(Game.quest_log.state(&"ato1_1")["stage"]) == 1, "estagio 1 deveria avancar")
	# Estágio 2 (KILL x3): inimigo errado não conta
	Game.quest_log.notify_kill(&"goblin")
	assert(int(Game.quest_log.state(&"ato1_1")["stage"]) == 1, "kill de goblin nao conta")
	for i in 3:
		Game.quest_log.notify_kill(&"lobo_sombrio")
	assert(int(Game.quest_log.state(&"ato1_1")["stage"]) == 2, "estagio 2 deveria avancar")
	# Estágio 3 (TALK): conclui + recompensas da REGRAS §12
	Game.hero.xp = 0  # determinismo: 40 XP não cruza o limite do nível
	var gold41: int = Game.hero.gold
	var n41: int = Game.hero.inventory.items.size()
	Game.quest_log.notify_talk(&"cinzento_acampamento")
	assert(Game.quest_log.is_completed(&"ato1_1"), "ato1_1 deveria concluir")
	assert(Game.hero.xp == int(40 * q41.quest_level * q41.act * Game.hero.xp_multiplier()),
		"XP da formula 40 x nivel x ato (REGRAS §12)")
	assert(Game.hero.gold == gold41 + q41.rewards.gold, "ouro da recompensa")
	assert(Game.hero.inventory.items.size() == n41 + 1, "item de recompensa")
	var it41: Item = Game.hero.inventory.items[-1]
	assert(it41.rarity >= maxi(Item.Rarity.MAGIC, mini(q41.act, Item.Rarity.LEGENDARY)), "raridade minima do ato")
	# Autosave ao concluir quest (REGRAS §13) persiste o estado no arquivo
	var sj41: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Game.SAVE_PATH))
	var sq41: Dictionary = sj41.get("quests", {}).get("ato1_1", {})
	assert(bool(sq41.get("done", false)) and int(sq41.get("stage", -1)) == 3,
		"save deveria persistir a quest concluida (autosave REGRAS §13)")
	# Fragments/final: logica do Final Dourado (REGRAS §12)
	assert(Game.quest_log.fragments() == 0 and not Game.quest_log.golden_ending_unlocked())
	Game.fragmentos.append(&"teste1")
	Game.quest_log.notify_flag(&"__smoke__")  # auto-inicio por flag é coberto pelo despertar
	assert(Game.quest_log.fragments() == 1)
	print("[smoke]   quest log ok (TALK/KILL/FLAG/REACH/COLLECT, estagios, recompensas REGRAS §12, autosave)")
	# 4.2: UI de quest log + tracker no HUD
	# limpa mensagens antigas (show_message deduplica por texto exato)
	for m42 in ow.hud._messages.get_children():
		ow.hud._messages.remove_child(m42)
		m42.queue_free()
	Game.quests.clear()  # 4.3: completar ato1_1 auto-inicia ato1_2 — limpa tudo
	Game.quest_log.tracked = &""
	Game.quest_log.start(DB.quest(&"ato1_1"))
	await _wait(0.1)  # _process da HUD atualiza o tracker
	assert(ow.hud._quest_tracker.visible, "tracker lateral deveria aparecer")
	assert(ow.hud._quest_title.text.contains("O Eco do Primeiro Passo"), "tracker deveria mostrar o titulo")
	assert(ow.hud._quest_obj.text.length() > 0, "tracker deveria mostrar o objetivo atual")
	var nova42 := false
	for m42 in ow.hud._messages.get_children():
		if m42 is Label and (m42 as Label).text.contains("Nova missão"):
			nova42 = true
	assert(nova42, "inicio de quest deveria ser anunciado na HUD")
	# painel: labels ficam dentro de VBoxContainers — busca descendente;
	# um frame para o queue_free dos labels do refresh anterior completar
	ow.hud.toggle_quests()
	await _wait(0.1)
	var labels42: Array = []
	for l42 in ow.hud.questlog.find_children("*", "Label", true, false):
		labels42.append((l42 as Label).text)
	assert(ow.hud.questlog.visible, "painel de missoes deveria abrir (J)")
	assert(labels42.has("O Eco do Primeiro Passo"), "painel deveria listar a quest ativa")
	var obj42 := false
	var frag42 := false
	for t42 in labels42:
		if t42.contains("Apresente-se a Marn"):
			obj42 = true
		if t42.contains("1/8"):
			frag42 = true
	assert(obj42, "painel deveria listar o objetivo atual")
	assert(frag42, "painel deveria contar os fragmentos (1 do bloco 4.1)")
	# progresso avanca no painel e no tracker: estagio 2 (KILL) mostra '0/3'
	Game.quest_log.notify_talk(&"marn_vigia")
	Game.quest_log.notify_talk(&"bree_cozinheira")
	ow.hud.questlog.refresh()
	await _wait(0.1)
	var prog42 := false
	for l42 in ow.hud.questlog.find_children("*", "Label", true, false):
		if (l42 as Label).text.contains("0/3"):
			prog42 = true
	assert(prog42, "painel deveria mostrar o progresso 0/3 do objetivo de kill")
	assert(ow.hud._quest_obj.text.contains("0/3"), "tracker deveria mostrar o progresso 0/3")
	# toggle fecha
	ow.hud.toggle_quests()
	assert(not ow.hud.questlog.visible, "painel deveria fechar")
	print("[smoke]   quest ui ok (tracker lateral com titulo+objetivo, aviso de nova missao, painel com progresso e fragmentos, tecla J)")
	# 4.3: cadeia principal Ato 1 — "A Estranha" (LORE §XI): 7 quests encadeadas,
	# auto-inicio por flag + next, objetivos TALK com wildcard any: (glob com *)
	Game.quests.clear()
	Game.quest_log.tracked = &""
	var db_ok43 := true
	for i43 in 7:
		if DB.quest(StringName("ato1_%d" % (i43 + 1))) == null:
			db_ok43 = false
	assert(db_ok43, "Ato 1 completo no DB (7 quests)")
	Game.quest_log.notify_flag(&"cinzento_primeiro_dialogo")
	assert(Game.quest_log.is_active(&"ato1_1"), "ato1_1 inicia pela flag do primeiro dialogo")
	# ato1_1: Marn + Bree -> 3 lobos -> Cinzento (auto-inicia ato1_2 ao concluir)
	Game.quest_log.notify_talk(&"marn_vigia")
	Game.quest_log.notify_talk(&"bree_cozinheira")
	for i43 in 3:
		Game.quest_log.notify_kill(&"lobo_sombrio")
	Game.quest_log.notify_talk(&"cinzento_acampamento")
	assert(Game.quest_log.is_completed(&"ato1_1") and Game.quest_log.is_active(&"ato1_2"),
		"concluir ato1_1 deve auto-iniciar ato1_2")
	# ato1_2: TALK any:capital_*_lider (wildcard: lider de OUTRA raca conta)
	Game.quest_log.notify_talk(&"capital_drow_lider")
	assert(int(Game.quest_log.state(&"ato1_2")["stage"]) == 1, "wildcard any:capital_*_lider casa qualquer lider")
	# ato1_2: TALK any:_comum (plebeu de qualquer capital) + KILL goblin x5 -> Cinzento
	Game.quest_log.notify_talk(&"capital_anao_colinas_comum1")
	assert(int(Game.quest_log.state(&"ato1_2")["stage"]) == 1, "plebeu entra no estagio dos goblins")
	for i43 in 5:
		Game.quest_log.notify_kill(&"goblin")
	Game.quest_log.notify_talk(&"cinzento_acampamento")
	assert(Game.quest_log.is_completed(&"ato1_2") and Game.quest_log.is_active(&"ato1_3"))
	# ato1_3: REACH golias + KILL anao_saqueador x4 -> TALK lider
	Game.quest_log.notify_reach(&"golias")
	for i43 in 4:
		Game.quest_log.notify_kill(&"anao_saqueador")
	Game.quest_log.notify_talk(&"capital_humano_lider")
	assert(Game.quest_log.is_completed(&"ato1_3") and Game.quest_log.is_active(&"ato1_4"))
	# ato1_4: TALK lider -> KILL orc_mascarado x3 -> TALK lider
	Game.quest_log.notify_talk(&"capital_humano_lider")
	for i43 in 3:
		Game.quest_log.notify_kill(&"orc_mascarado")
	Game.quest_log.notify_talk(&"capital_tabaxi_lider")
	assert(Game.quest_log.is_completed(&"ato1_4") and Game.quest_log.is_active(&"ato1_5"))
	# ato1_5: KILL esqueleto x6 -> TALK lider
	for i43 in 6:
		Game.quest_log.notify_kill(&"esqueleto")
	Game.quest_log.notify_talk(&"capital_draconato_lider")
	assert(Game.quest_log.is_completed(&"ato1_5") and Game.quest_log.is_active(&"ato1_6"))
	# ato1_6: TALK lider -> KILL anjo_caido (recompensa RARE — ato 1 so na 4.4+; aqui MAGIC min)
	Game.quest_log.notify_talk(&"capital_gnomo_lider")
	Game.quest_log.notify_kill(&"anjo_caido")
	assert(Game.quest_log.is_completed(&"ato1_6") and Game.quest_log.is_active(&"ato1_7"))
	# ato1_7: REACH draconato + KILL guerreiro_orc x4 + cavaleiro_renegado x2 -> TALK lider
	Game.quest_log.notify_reach(&"draconato")
	for i43 in 4:
		Game.quest_log.notify_kill(&"guerreiro_orc")
	for i43 in 2:
		Game.quest_log.notify_kill(&"cavaleiro_renegado")
	Game.quest_log.notify_talk(&"capital_humano_lider")
	assert(Game.quest_log.is_completed(&"ato1_7"), "ato1_7 (ultima) conclui")
	var ato1_ok43 := true
	for qid43 in [&"ato1_1", &"ato1_2", &"ato1_3", &"ato1_4", &"ato1_5", &"ato1_6", &"ato1_7"]:
		if not Game.quest_log.is_completed(qid43):
			ato1_ok43 = false
	assert(ato1_ok43, "Ato 1 inteiro concluido")
	# autoflow por pre-requisito: ato2_1 abre sozinha quando ato1_7 completa
	assert(Game.quest_log.is_active(&"ato2_1"), "ato2_1 auto-inicia por prereq (autoflow)")
	assert(Game.quest_log.tracker_line() != "", "tracker segue a main (ato2_1)")
	print("[smoke]   cadeia ato1 ok (7 quests: flag->next auto-inicio, wildcard any:capital_*_lider e any:_comum, REACH, autoflow abre ato2_1)")
	# 4.4: Ato 2 — O Tabuleiro (LORE §XII): 8 pazes, cada par de territórios
	# descobre a mentira específica que sustenta aquele ódio.
	# Estrutura de cada paz: REACH as duas capitais -> KILL dos que lucram
	# com a discórdia -> TALK com dois líderes (wildcard any:capital_*_lider)
	var paz44 := func(a44: StringName, b44: StringName, vilao44: StringName, n44: int, qid44: StringName) -> void:
		assert(Game.quest_log.is_active(qid44), "%s deveria estar ativa" % qid44)
		Game.quest_log.notify_reach(a44)
		Game.quest_log.notify_reach(b44)
		for k44 in n44:
			Game.quest_log.notify_kill(vilao44)
		Game.quest_log.notify_talk(&"capital_humano_lider")
		Game.quest_log.notify_talk(&"capital_drow_lider")
		assert(Game.quest_log.is_completed(qid44), "%s deveria concluir" % qid44)
	paz44.call(&"humano", &"alto_elfo", &"arqueiro_bandido", 5, &"ato2_1")
	paz44.call(&"elfo_floresta", &"drow", &"fantasma", 5, &"ato2_2")
	paz44.call(&"anao_montanha", &"anao_colinas", &"anao_saqueador", 5, &"ato2_3")
	paz44.call(&"halfling", &"meio_elfo", &"arqueiro_bandido", 5, &"ato2_4")
	paz44.call(&"meio_orc", &"tiefling", &"orc_mascarado", 5, &"ato2_5")
	paz44.call(&"draconato", &"gnomo", &"diabrete", 5, &"ato2_6")
	paz44.call(&"tabaxi", &"golias", &"aranha_gigante", 6, &"ato2_7")
	# O Concílio Reunido: convocação de três líderes + revelação do Cinzento
	assert(Game.quest_log.is_active(&"ato2_8"), "ato2_8 auto-iniciada por prereq ato2_7")
	Game.quest_log.notify_talk(&"capital_humano_lider")
	Game.quest_log.notify_talk(&"capital_golias_lider")
	Game.quest_log.notify_talk(&"capital_tiefling_lider")
	Game.quest_log.notify_talk(&"cinzento_acampamento")
	assert(Game.quest_log.is_completed(&"ato2_8"), "concilio conclui o Ato 2")
	var ato2_ok44 := true
	for i44 in 8:
		if not Game.quest_log.is_completed(StringName("ato2_%d" % (i44 + 1))):
			ato2_ok44 = false
	assert(ato2_ok44, "Ato 2 inteiro concluido")
	print("[smoke]   cadeia ato2 ok (8 pazes: REACH pares, KILL dos que lucram, concilio; autoflow por prereq)")
	# 4.5: Ato 3 — A Verdade (LORE §XIII): religar as 7 Chamas + o final.
	# Cada Chama = confronto com a versao corrompida do seu Guardiao
	# (nao chefe — tragedia jogavel; narrativa nas descriptions).
	assert(Game.quest_log.is_active(&"ato3_1"), "ato3_1 auto-inicia por prereq ato2_8 (autoflow)")
	var chama45 := func(v1: StringName, n1: int, v2: StringName, n2: int, qid: StringName) -> void:
		assert(Game.quest_log.is_active(qid), "%s deveria estar ativa" % qid)
		for k45 in n1:
			Game.quest_log.notify_kill(v1)
		for k45 in n2:
			Game.quest_log.notify_kill(v2)
		Game.quest_log.notify_talk(&"capital_humano_lider")
		assert(Game.quest_log.is_completed(qid), "%s deveria concluir" % qid)
	chama45.call(&"putrefato", 4, &"aranha_gigante", 5, &"ato3_1")      # Raiz (Sylvaris)
	chama45.call(&"escorpiao", 6, &"chort", 3, &"ato3_2")              # Areia
	chama45.call(&"zumbi_gelido", 7, &"zumbi_gelido", 0, &"ato3_3")    # Gelo
	chama45.call(&"lodo", 5, &"lesma_acida", 4, &"ato3_4")            # Pantano (Vaelora)
	chama45.call(&"caranguejo_infernal", 6, &"diabrete", 4, &"ato3_5")  # Brasa (Kragoth)
	chama45.call(&"morcego", 6, &"chort", 3, &"ato3_6")                # Vento
	chama45.call(&"fantasma", 6, &"cavaleiro_renegado", 4, &"ato3_7")  # Sombra (Xal'atath)
	# O Fogo dos Laços (FINAL): Maldrach, a Ausencia que Anda + a Escolha Real
	assert(Game.quest_log.is_active(&"ato3_8"), "quest final ativa")
	assert(DB.quest(&"ato3_8").is_final(), "ato3_8 e a quest final (is_final)")
	Game.quest_log.notify_kill(&"azkhar")
	Game.quest_log.notify_talk(&"cinzento_acampamento")
	assert(Game.quest_log.is_completed(&"ato3_8"), "quest final conclui")
	var main_ativas45 := false
	for qid45 in Game.quests.keys():
		var q45: QuestData = DB.quest(qid45)
		if q45 != null and q45.is_main() and Game.quest_log.is_active(qid45):
			main_ativas45 = true
	assert(not main_ativas45, "historia principal encerra sem quests ativas")
	print("[smoke]   cadeia ato3 ok (7 Chamas + final O Fogo dos Lacos; prereq ato2_8; is_final)")
	# 4.6: os 8 Mistérios (LORE §XIV) — "regra sagrada: o jogo nunca diz
	# mistério aqui": abrem sem alarde por pré-requisitos das quests da
	# principal que narrativamente os destravam; cada um rende 1 Fragmento
	# da Verdade (8 destravam o Final Dourado, REGRAS §12).
	# Durante os drives anteriores, misterio_2 completou sozinho (os 5
	# fantasmas do Ato 2) e os demais ficaram nos objetivos que nenhum
	# drive anterior cobre — este bloco completa o que falta de cada um.
	Game.fragmentos.erase(&"teste1")  # remove o fragmento de teste do bloco 4.1
	assert(Game.quest_log.fragments() == 1, "so misterio_2 completou sozinho durante o Ato 2")
	assert(Game.quest_log.is_completed(&"misterio_2"), "misterio_2 (prereq ato1_2) concluida")
	for qid46 in [&"misterio_1", &"misterio_3", &"misterio_4", &"misterio_5", &"misterio_6", &"misterio_7"]:
		assert(Game.quest_log.is_active(qid46), "%s ativa por autoflow (prereqs da principal)" % qid46)
	# misterio_1: O Sussurro nos Mapas — mapa errado do cartógrafo
	Game.quest_log.notify_talk(&"capital_humano_comum0")
	for k46 in 3:
		Game.quest_log.notify_kill(&"chort")
	assert(Game.quest_log.is_completed(&"misterio_1"), "misterio_1 conclui")
	# misterio_3: A Cura Que Envenena — médicos sem registro + vítimas sem nome
	for k46 in 4:
		Game.quest_log.notify_kill(&"medico_da_peste")
	for k46 in 5:
		Game.quest_log.notify_kill(&"zumbi")
	assert(Game.quest_log.is_completed(&"misterio_3"), "misterio_3 conclui")
	# misterio_4: O Enigma de Salomé — a canção denuncia as emboscadas
	Game.quest_log.notify_talk(&"capital_humano_comum1")
	for k46 in 6:
		Game.quest_log.notify_kill(&"arqueiro_bandido")
	assert(Game.quest_log.is_completed(&"misterio_4"), "misterio_4 conclui")
	# misterio_5: As Sete Relíquias — agente do colecionador + profanadores
	# (os necromantes também alimentam o misterio_7, ativo desde o fim do Ato 2)
	Game.quest_log.notify_talk(&"capital_humano_comum2")
	for k46 in 4:
		Game.quest_log.notify_kill(&"necromante_profano")
	assert(Game.quest_log.is_completed(&"misterio_5"), "misterio_5 conclui")
	# misterio_6: A Torre sem Portas — o 5º cavaleiro + a carta ao Cinzento
	Game.quest_log.notify_kill(&"cavaleiro_renegado")
	Game.quest_log.notify_talk(&"cinzento_acampamento")
	assert(Game.quest_log.is_completed(&"misterio_6"), "misterio_6 conclui")
	# misterio_7: O Diário de Ithariel — páginas guardadas + confronto
	for k46 in 6:
		Game.quest_log.notify_kill(&"necromante_profano")
	Game.quest_log.notify_talk(&"cinzento_acampamento")
	assert(Game.quest_log.is_completed(&"misterio_7"), "misterio_7 conclui")
	assert(Game.quest_log.is_active(&"misterio_8"), "misterio_8 auto-inicia com os 7 concluidos")
	# misterio_8: A Vila que Ninguém Lembrava — lobos da primeira floresta
	for k46 in 3:
		Game.quest_log.notify_kill(&"lobo_sombrio")
	Game.quest_log.notify_talk(&"cinzento_acampamento")
	assert(Game.quest_log.is_completed(&"misterio_8"), "misterio_8 (oculto) conclui")
	assert(Game.quest_log.fragments() == 8, "8 Fragmentos da Verdade coletados")
	assert(Game.quest_log.golden_ending_unlocked(), "Final Dourado destravado (REGRAS §12)")
	print("[smoke]   misterios ok (8 cadeias ocultas por prereqs, 1 fragmento cada, Final Dourado destravado)")
	# 5.1: VendorData — estoque rotativo diário + especialidades regionais
	assert(DB.vendor_ids().size() == 14, "14 fornecedores (um por territorio)")
	var v51: VendorData = DB.vendor(&"anao_montanha")
	assert(v51 != null and v51.specialties.has(&"axe"), "Forja-Coracao produz machados")
	assert(DB.vendor(&"humano") != null and DB.vendor(&"humano").specialties.is_empty(),
		"Porto Franco e generalista (comercio inter-territorios)")
	var s_a51: Array = v51.stock_for(3, 10)
	assert(s_a51 == v51.stock_for(3, 10), "mesmo dia = mesmo estoque (deterministico por id+dia)")
	assert(v51.stock_for(4, 10) != s_a51, "virada do dia re-estoca (REGRAS §14: 06:00)")
	var valido51 := true
	for e51 in s_a51:
		if not DB.BASES.has(e51["base"]) or e51["level"] < 1 \
				or e51["price"] != VendorData._base_value(e51["level"], e51["rarity"]):
			valido51 = false
	assert(valido51, "entradas validas (base existe, nivel >= 1, preco REGRAS §8)")
	# especialidades: ~45% dos slots vem das categorias produzidas (vs taxa base
	# ~2/12 no resto do pool); agregando 30 dias o sinal e inequivoco
	var spec51 := 0
	var total51 := 0
	for d51 in 30:
		for e51 in v51.stock_for(d51, 10):
			total51 += 1
			if DB.BASES[e51["base"]].get("cat", &"") in v51.specialties:
				spec51 += 1
	assert(float(spec51) / total51 > 0.35, "especialidades dominam o estoque local (foi %.0f%%)" % (100.0 * spec51 / total51))
	print("[smoke]   vendors ok (14 territorios, estoque rotativo diario deterministico, especialidades regionais, preco REGRAS §8)")
	# 5.2: preços dinâmicos por oferta/demanda (REGRAS §10)
	Game.market = {}
	assert(Market.demand(&"anao_montanha", &"sword") == 1.0, "demanda inicia neutra")
	Market.on_sell(&"anao_montanha", &"sword", 5)
	assert(is_equal_approx(Market.demand(&"anao_montanha", &"sword"), 0.85), "vender 5 derruba 15%")
	Market.on_buy(&"anao_montanha", &"sword", -1, 1)
	assert(is_equal_approx(Market.demand(&"anao_montanha", &"sword"), 0.88), "comprar 1 eleva 3%")
	Market.on_sell(&"anao_montanha", &"sword", 100)
	assert(Market.demand(&"anao_montanha", &"sword") == Market.DEMAND_MIN, "clamp no piso 0.6 (inundado)")
	Market.on_buy(&"anao_montanha", &"sword", -1, 100)
	assert(Market.demand(&"anao_montanha", &"sword") == Market.DEMAND_MAX, "clamp no teto 1.5 (escasso)")
	Market.on_buy(&"anao_montanha", &"sword", 0)
	assert(Market.is_sold(&"anao_montanha", 0), "slot do estoque consumido")
	Market.new_day()
	assert(not Market.is_sold(&"anao_montanha", 0), "virada do dia re-estoca (sold limpo)")
	# recuperação: bow (escasso na Forja) saturado 1.5 → 4 dias = 1.3 exato
	Game.market = {}
	Market.on_buy(&"anao_montanha", &"bow", -1, 17)
	for d52 in 4:
		Market.new_day()
	assert(is_equal_approx(Market.demand(&"anao_montanha", &"bow"), 1.3),
		"escasso recupera 5%%/dia ao natural 1.3")
	# sword (produzido na Forja) inundado 0.6 → 2 dias = 0.7 exato
	Market.on_sell(&"anao_montanha", &"sword", 14)
	for d52 in 2:
		Market.new_day()
	assert(is_equal_approx(Market.demand(&"anao_montanha", &"sword"), 0.7),
		"produzido recupera ao natural 0.7")
	# rota comercial: produtor barato → escasso caro (MECANICAS §10)
	Game.market = {}
	var espada52 := {"base": &"sword", "level": 10, "rarity": 0, "price": 35}
	var item52 := DB.create_item(&"sword", 10, 0)
	var compra52 := Market.buy_price(&"anao_montanha", espada52)
	var venda52 := Market.sell_price(&"elfo_floresta", item52)
	assert(compra52 == 16, "Forja: 35×1.0×0.45 = 16 (foi %d)" % compra52)
	assert(venda52 == 18, "elfo_floresta: 35×0.40×1.25 = 18 (foi %d)" % venda52)
	assert(venda52 > compra52, "rota produtor→escasso lucra +%d" % (venda52 - compra52))
	Market.on_sell(&"anao_montanha", &"sword", 14)      # produtor inundado
	Market.on_buy(&"elfo_floresta", &"sword", -1, 10)   # comprador aquecido
	assert(Market.buy_price(&"anao_montanha", espada52) == 9
		and Market.sell_price(&"elfo_floresta", item52) == 23,
		"assentado: compra 9 < venda 23")
	assert(Market.rep_discount(4) == 0.20, "plumbing reputação: tier 4 = 20%")
	# dia de mercado vira às 06:00 (REGRAS §14)
	var wt52 := Game.world_time
	Game.world_time = 0.9
	assert(Market.market_day() == 0, "antes das 06:00 e dia anterior")
	Game.world_time = 1.3
	assert(Market.market_day() == 1, "vira as 06:00 do dia seguinte")
	Game.world_time = wt52
	Game.market = {}
	print("[smoke]   mercado dinamico ok (demanda ±3%/item, clamps 0.6/1.5, recuperacao 5%/dia ao natural, rotas produtor→escasso, dia vira as 06:00)")
	# 5.3: desconto por reputação (0/5/10/15/20% por tier — MECANICAS §10)
	var tiers53 := ["Estranho", "Conhecido", "Respeitado", "Honrado", "Laço"]
	for rep53 in 5:
		assert(Market.tier_name(rep53) == tiers53[rep53], "tier %d = %s" % [rep53, tiers53[rep53]])
		assert(Market.rep_discount(rep53) == 0.05 * rep53, "desconto %d%% no tier %d" % [5 * rep53, rep53])
	# arco lvl10 (35 ouro, escasso na Forja = sem fator produtor): preços por tier
	var arco53 := {"base": &"bow", "level": 10, "rarity": 0, "price": 35}
	var esperado53 := [35, 33, 32, 30, 28]
	for rep53 in 5:
		assert(Market.buy_price(&"anao_montanha", arco53, rep53) == esperado53[rep53],
			"tier %d paga %d (foi %d)" % [rep53, esperado53[rep53], Market.buy_price(&"anao_montanha", arco53, rep53)])
	# sem rep explícito usa a reputação COM O TERRITÓRIO do vendor (não a raça
	# do herói): Forja tier 3 = 15% off; reputação com outro povo não valem lá
	var rep_backup53 := Game.reputation.duplicate()
	Game.market = {}
	Game.reputation = {}
	Game.reputation[&"anao_montanha"] = 3
	assert(Market.buy_price(&"anao_montanha", arco53) == 30,
		"reputação com a Forja (tier 3) derruba o preço para 30")
	Game.reputation = {}
	Game.reputation[&"humano"] = 4
	assert(Market.buy_price(&"anao_montanha", arco53) == 35,
		"reputação com Porto Franco não vale na Forja (35)")
	Game.reputation = rep_backup53
	Game.market = {}
	print("[smoke]   reputacao ok (tiers Estranho→Laco, desconto 0/5/10/15/20%, reputação e por territorio do vendor)")
	# 5.4: casa de leilões (REGRAS §9) — 6 slots Raro+ rotativos por dia
	Game.auction = {}
	var s54: Array = Auction.slots()
	assert(s54.size() == Auction.SLOT_COUNT, "6 slots diários")
	var raro54 := true
	var ess54 := 0
	for e54 in s54:
		if int(e54["rarity"]) < Item.Rarity.RARE or not DB.BASES.has(e54["base"]):
			raro54 = false
		if String(e54["currency"]) == "essence":
			ess54 += 1
	assert(raro54 and ess54 == 1, "todos Raro+ com base válida, 1 slot em essência")
	for e54 in s54:
		var exp54: int = ceili(float(e54["value"]) / float(Auction.ESSENCE_DIVISOR)) \
			if String(e54["currency"]) == "essence" \
			else ceili(float(e54["value"]) * Auction.BID_PREMIUM)
		assert(int(e54["min_bid"]) == exp54, "lance inicial: prêmio ×1.2 (essência = valor/20)")
	var snap54 := []
	for e54 in s54:
		snap54.append(e54["base"])
	Game.auction = {}
	var s54b: Array = Auction.slots()
	var mesmo54 := true
	for i54 in Auction.SLOT_COUNT:
		if s54b[i54]["base"] != snap54[i54]:
			mesmo54 = false
	assert(mesmo54, "mesmo dia = mesmo leilão (determinístico por dia)")
	s54 = s54b  # re-rolou acima: opera sobre os dicts atuais
	# lances: rivais contra-lançam (+10% no mínimo); (rivais+1) lances vencem
	var gold54 := h.gold
	h.gold = 100000
	# o herói chega aqui com o inventário cheio (itens de ~28 quests) —
	# liberar espaço para os arremates
	for it54 in h.inventory.items.duplicate():
		if it54 != null:
			h.inventory.remove(it54)
	var bid54: int = int(s54[0]["min_bid"])
	var rivais54: int = int(s54[0]["rivals_left"])
	var won54 := false
	var last54 := ""
	for i54 in rivais54 + 3:
		var r54 := Auction.place_bid(0)
		last54 = String(r54["result"])
		if String(r54["result"]) == "outbid":
			assert(int(s54[0]["min_bid"]) == ceili(bid54 * 1.10), "contra-lance eleva 10%")
			bid54 = int(s54[0]["min_bid"])
		elif String(r54["result"]) == "won":
			won54 = true
			break
		else:
			won54 = false
			break
	assert(won54 and bool(s54[0]["sold"]), "lance vence após %d rivais (último: %s)" % [rivais54, last54])
	assert(h.gold == 100000 - bid54, "ouro cobrado só na vitória")
	assert(String(Auction.place_bid(0)["result"]) == "sold", "slot vendido é final")
	h.gold = 0
	assert(String(Auction.place_bid(1)["result"]) == "broke", "sem ouro, sem lance")
	# slot em essência cobra essência (REGRAS §9: moeda dura)
	var ess54b := h.essence
	h.essence = 500
	while String(Auction.place_bid(Auction.ESSENCE_INDEX)["result"]) == "outbid":
		pass
	assert(bool(s54[Auction.ESSENCE_INDEX]["sold"]), "slot de essência vencível")
	assert(h.essence == 500 - int(s54[Auction.ESSENCE_INDEX]["min_bid"]), "essência cobrada")
	h.essence = ess54b
	h.gold = gold54
	Game.auction = {}
	print("[smoke]   leilao ok (6 slots Raro+ rotativos por dia, 1 em essencia, rivais +10% por contra-lance, deterministico)")
	# 5.5: UI de comércio unificada — abas Comprar/Vender/Leilão
	Game.market = {}
	var tp55: TradePanel = ow.hud.open_trade(&"anao_montanha")
	await _wait(0.2)
	assert(tp55._tab == TradePanel.TAB_BUY, "abre na aba Comprar")
	assert(tp55._content.get_child_count() >= 7, "introdução + estoque do dia listado")
	var stock55: Array = DB.vendor(&"anao_montanha").stock_for(Market.market_day(), tp55.region_level)
	var cat55: StringName = Market.category_of(stock55[0]["base"])
	var dem55 := Market.demand(&"anao_montanha", cat55)
	var gold55 := h.gold
	tp55.do_buy(0)
	assert(h.gold < gold55 and Market.is_sold(&"anao_montanha", 0), "compra via UI desconta e consome o slot")
	assert(Market.demand(&"anao_montanha", cat55) > dem55, "compra aquece a demanda (preço dinâmico na UI)")
	tp55._show_tab(TradePanel.TAB_SELL)
	var it55 := DB.create_item(&"sword", 5, 0)
	assert(h.inventory.add(it55), "espaço para vender")
	var gold55b := h.gold
	tp55.do_sell(it55)
	assert(h.gold > gold55b and not h.inventory.items.has(it55), "venda via UI soma ouro e remove o item")
	tp55._show_tab(TradePanel.TAB_AUCTION)
	assert(tp55._tab == TradePanel.TAB_BUY, "sem leilão fora de Porto Franco")
	tp55.close()
	await _wait(0.3)
	# efeito `comercio` no diálogo do líder abre a janela (Fase 5.5)
	TerritoryNpcs._ensure_dialogues(&"anao_montanha", DB.territory(&"anao_montanha"))
	var lider55: DialogueData = DB.dialogue(&"capital_anao_montanha_lider")
	var tem55 := false
	for n55 in lider55.nodes:
		for c55 in n55.choices:
			if String(c55.effects).contains("comercio anao_montanha"):
				tem55 = true
	assert(tem55, "diálogo do líder oferece Negociar (efeito comercio)")
	var abriu55 := {}
	var latch55 := func(r55: StringName): abriu55["race"] = r55
	Game.trade_requested.connect(latch55)
	DialogueEngine.apply_effects("comercio humano")
	Game.trade_requested.disconnect(latch55)
	assert(StringName(abriu55.get("race", &"")) == &"humano", "efeito comercio emite Game.trade_requested")
	# Porto Franco: aba de leilão presente
	var tp56: TradePanel = ow.hud.open_trade(&"humano")
	await _wait(0.2)
	tp56._show_tab(TradePanel.TAB_AUCTION)
	assert(tp56._tab == TradePanel.TAB_AUCTION, "Porto Franco negocia com a Guilda (leilão)")
	await _shot("09_comercio_leilao")
	tp56.close()
	await _wait(0.3)
	Game.market = {}
	print("[smoke]   comercio ok (abas comprar/vender/leilao pelo dialogo do lider, tooltips de preco, efeito comercio→HUD)")
	# 6.1: HUD moderna (MECANICAS §9.2) — barras segmentadas, anel de XP,
	# chips de moeda, minimapa redondo, cooldown radial, tracker recolhível
	assert(ow.hud._hp_bar is VitalsBar and ow.hud._res_bar is VitalsBar, "barras de vida/recurso segmentadas")
	assert(absf(ow.hud._hp_bar.value - clampf(ow.player.hp / ow.player.max_hp, 0, 1)) < 0.02,
		"barra de vida reflete o player")
	ow.hud._hp_bar.flash_damage()  # flash de dano não explode
	assert(ow.hud._badge is LevelBadge and ow.hud._badge.level == h.level, "emblema de nível")
	assert(absf(ow.hud._badge.xp_frac - clampf(float(h.xp) / float(h.xp_to_next()), 0, 1)) < 0.01,
		"anel de XP preenche com a experiência")
	assert(ow.hud._gold_chip is PanelContainer and ow.hud._gold.text.contains("●"), "chips de ouro/essência")
	assert(ow.hud._quest_title is Button, "tracker com cabeçalho clicável")
	ow.hud.toggle_tracker()
	assert(ow.hud._tracker_collapsed and not ow.hud._quest_body.visible, "tracker recolhe")
	ow.hud.toggle_tracker()
	assert(not ow.hud._tracker_collapsed and ow.hud._quest_body.visible, "tracker expande")
	var poly61 := SkillSlot._radial_points(Vector2(26, 26), 30.0, 0.5)
	assert(poly61.size() == 34 and poly61[0] == Vector2(26, 26), "recarga radial (varredura em cone)")
	var mm61: Minimap = ow.hud._root.get_node("Minimap")
	assert(mm61.material is ShaderMaterial, "minimapa com máscara circular")
	var bc61 := BuffChip.new()
	assert(bc61.custom_minimum_size == Vector2(44, 44), "chip de buff com anel de tempo")
	var enemies61: Array = get_tree().get_nodes_in_group("enemies")
	if not enemies61.is_empty():
		var e61: Enemy = enemies61[0]
		ow.hud.show_target(e61)
		assert(ow.hud._target_fill.bg_color == Enemy.RARITY_COLORS[e61.rarity],
			"barra do alvo colorida pela raridade")
		if e61.rarity >= Enemy.Rarity.ELITE:
			assert(ow.hud._target_name.text.begins_with("♛ "), "coroa para campeão+")
	await _shot("10_hud_moderna")
	print("[smoke]   hud moderna ok (barras segmentadas, anel XP, chips, minimapa redondo, cooldown radial, tracker recolhivel)")
	# 6.2: painel do jogador unificado com abas (MECANICAS §9.3)
	assert(ow.hud._unified is UnifiedPanel and ow.hud._unified.panels.size() == 5,
		"janela única com 5 abas")
	ow.hud.toggle_inventory()
	assert(ow.hud._unified.is_open() and ow.hud._unified.current == 1,
		"I abre direto na aba Inventário")
	await _wait(0.2)
	await _shot("11_painel_unificado")
	ow.hud.toggle_character()
	assert(ow.hud._unified.current == 0 and ow.hud.character.visible and not ow.hud.inventory.visible,
		"P troca para Personagem (mesma janela)")
	ow.hud.toggle_skills()
	assert(ow.hud._unified.current == 2 and ow.hud.skills.visible, "K troca para Habilidades")
	ow.hud.toggle_skill_tree()
	assert(ow.hud._unified.current == 3 and ow.hud.skill_tree.visible, "B troca para Árvore")
	ow.hud.toggle_quests()
	assert(ow.hud._unified.current == 4 and ow.hud.questlog.visible, "J troca para Missões")
	# Scroll: os painéis rolam quando o conteúdo passa da altura da janela
	# (missões acumulam, inventário tem boneco+grade, ficha tem atributos)
	var qs := _first_scroll(ow.hud.questlog)
	assert(qs != null and qs.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
		"aba Missões tem scroll vertical")
	var iscr := _first_scroll(ow.hud.inventory)
	assert(iscr != null and iscr.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED,
		"Inventário tem scroll vertical")
	var cs := _first_scroll(ow.hud.character)
	assert(cs != null, "ficha tem scroll (aba Atributos)")
	var ss := _first_scroll(ow.hud.skills)
	assert(ss != null, "Habilidades mantém o scroll")
	print("[smoke]   scroll ok (Missoes, Inventario, Personagem, Habilidades rolam quando o conteudo passa da janela)")
	ow.hud.toggle_quests()
	assert(not ow.hud._unified.is_open(), "mesma tecla fecha a janela")
	print("[smoke]   painel unificado ok (Personagem/Inventario/Habilidades/Arvore/Missoes na mesma janela, I/P/K/B/J)")
	
	# Task 6: shift+clique no inventário equipa instantaneamente (sem perda de item)
	ow.hud.toggle_inventory()
	await _wait(0.15)
	var inv_panel := ow.hud.inventory
	var eq_item: Item = null
	for it in h.inventory.items:
		if h.equip_problem(it) == "" and it.slot == "weapon":
			eq_item = it
			break
	if eq_item == null:
		# cria uma espada usável
		var base6 := DB.random_base_for(h.cls)
		while true:
			var test_it := DB.create_item(base6, 5, 0)
			if h.equip_problem(test_it) == "" and test_it.slot == "weapon":
				eq_item = test_it
				break
			base6 = DB.random_base_for(h.cls)
		assert(h.inventory.add(eq_item), "item de teste entra na mochila")
	
	var gv := inv_panel._grid_view
	var ev6 := InputEventMouseButton.new()
	ev6.button_index = MOUSE_BUTTON_LEFT
	ev6.pressed = true
	ev6.shift_pressed = true
	ev6.position = Vector2(eq_item.grid_pos) * InventoryPanel.CELL + Vector2(InventoryPanel.CELL, InventoryPanel.CELL) * 0.5
	gv._gui_input(ev6)
	assert(h.equipment.weapon == eq_item, "shift+clique equipa o item no slot")
	assert(not h.inventory.items.has(eq_item), "item saiu da mochila ao equipar")
	
	# desequipa com shift+clique no slot e volta pra mochila
	var ev6b := InputEventMouseButton.new()
	ev6b.button_index = MOUSE_BUTTON_LEFT
	ev6b.pressed = true
	ev6b.shift_pressed = true
	ev6b.position = Vector2(10, 10)
	inv_panel._equip_views["weapon"]._gui_input(ev6b)
	assert(h.equipment.weapon == null and h.inventory.items.has(eq_item), "shift+clique no slot desequipa pra mochila")
	
	# re-equipa via shift+clique e fecha o painel sem perder item
	# (a grade pode ter guardado o item em outra célula após desequipar)
	ev6.position = Vector2(eq_item.grid_pos) * InventoryPanel.CELL + Vector2(InventoryPanel.CELL, InventoryPanel.CELL) * 0.5
	gv._gui_input(ev6)
	assert(h.equipment.weapon == eq_item, "re-equipa via shift+clique")
	ow.hud.toggle_inventory()  # fecha
	await _wait(0.1)
	assert(h.equipment.weapon == eq_item and not h.inventory.items.has(eq_item), "fechar painel não perde item equipado")
	
	print("[smoke]   shift+clique inventário ok (equipa/desequipa instantâneo, zero perda ao fechar)")

	# Regressão: drag-and-drop completo (gesto press -> motion -> release):
	# grade -> slot de arma EQUIPA, slot -> grade DESEQUIPA
	inv_panel.unequip_to_inventory("weapon")
	assert(h.equipment.weapon == null and h.inventory.items.has(eq_item), "item de teste de volta na mochila")
	var wv: Control = inv_panel._equip_views["weapon"]
	var gv_dyn: Variant = inv_panel._grid_view

	# EQUIPAR: press na célula do item -> motion sobre o slot -> release no slot
	var cell_center := Vector2(eq_item.grid_pos) * InventoryPanel.CELL + Vector2(InventoryPanel.CELL, InventoryPanel.CELL) * 0.5
	var ev_press := InputEventMouseButton.new()
	ev_press.button_index = MOUSE_BUTTON_LEFT
	ev_press.pressed = true
	ev_press.position = cell_center
	ev_press.global_position = cell_center
	gv._gui_input(ev_press)
	assert(inv_panel.is_dragging() and inv_panel._drag.source == "grid", "press na grade inicia o arraste")
	var ev_motion := InputEventMouseMotion.new()
	ev_motion.position = Vector2(10, 10)
	wv._gui_input(ev_motion)
	var ev_rel := InputEventMouseButton.new()
	ev_rel.button_index = MOUSE_BUTTON_LEFT
	ev_rel.pressed = false
	ev_rel.position = Vector2(10, 10)
	wv._gui_input(ev_rel)
	assert(h.equipment.weapon == eq_item and not h.inventory.items.has(eq_item),
		"drag grade->slot equipa o item")

	# DESEQUIPAR: press no slot -> motion sobre célula livre da grade -> release na grade
	var ev_press2 := InputEventMouseButton.new()
	ev_press2.button_index = MOUSE_BUTTON_LEFT
	ev_press2.pressed = true
	ev_press2.position = Vector2(10, 10)
	wv._gui_input(ev_press2)
	assert(inv_panel.is_dragging() and inv_panel._drag.source == "equip", "press no slot inicia arraste do equipado")
	var free_cell := h.inventory.find_space(eq_item)
	assert(free_cell.x >= 0, "há espaço livre na grade para o item")
	var drop_local := Vector2(free_cell) * InventoryPanel.CELL + Vector2(5, 5)
	var ev_motion2 := InputEventMouseMotion.new()
	ev_motion2.position = drop_local
	gv._gui_input(ev_motion2)
	assert(gv_dyn._drop_target_cell == free_cell and gv_dyn._drop_valid, "motion marca a célula de drop como válida")
	var ev_rel2 := InputEventMouseButton.new()
	ev_rel2.button_index = MOUSE_BUTTON_LEFT
	ev_rel2.pressed = false
	ev_rel2.position = drop_local
	gv._gui_input(ev_rel2)
	assert(h.equipment.weapon == null and h.inventory.items.has(eq_item) and eq_item.grid_pos == free_cell,
		"drag slot->grade desequipa para a mochila")
	print("[smoke]   drag-and-drop ok (grade->slot equipa, slot->grade desequipa)")

	# Task 7: árvore de habilidades — canvas procedural com pan/zoom, nós com ícone e rank 0/N
	ow.hud.toggle_skill_tree()
	await _wait(0.15)
	var st7 = ow.hud.skill_tree
	var tree7 := DB.get_skill_tree(h.cls.id)
	assert(tree7 != null and tree7.nodes.size() > 0, "árvore da classe tem nós")
	var nodes7: Dictionary = st7.get("_nodes_ui")
	assert(nodes7.size() == tree7.nodes.size(), "um nó de UI por nó da árvore")
	var root7 = null
	for n7 in tree7.nodes:
		if n7.requires.is_empty() and not n7.is_new_skill:
			root7 = n7
			break
	if root7 == null:
		for n7 in tree7.nodes:
			if n7.requires.is_empty():
				root7 = n7
				break
	assert(root7 != null, "existe nó raiz")
	var ui7: Dictionary = nodes7[root7.id]
	assert(ui7.get("button") is Button and ui7.get("icon") is TextureRect and ui7["icon"].texture != null,
		"nó = Button + TextureRect(DB.icon)")
	var rank7 = ui7.get("rank")
	assert(rank7 is Label and rank7.text == "0/%d" % root7.max_rank, "label de rank mostra 0/N antes da compra")
	var child7 = null
	for n7 in tree7.nodes:
		if root7.id in n7.requires:
			child7 = n7
			break
	if child7 != null:
		assert(nodes7[child7.id]["pos"].x > ui7["pos"].x, "layout: pré-requisito à esquerda do dependente")
	# zoom por roda do mouse, clamp 0.75–1.5
	var wheel7 := InputEventMouseButton.new()
	wheel7.pressed = true
	wheel7.position = Vector2(100, 100)
	wheel7.button_index = MOUSE_BUTTON_WHEEL_UP
	for i in 30:
		st7.call("_on_canvas_input", wheel7)
	assert(is_equal_approx(float(st7.get("_zoom")), 1.5), "zoom máximo 1.5")
	wheel7.button_index = MOUSE_BUTTON_WHEEL_DOWN
	for i in 60:
		st7.call("_on_canvas_input", wheel7)
	assert(is_equal_approx(float(st7.get("_zoom")), 0.75), "zoom mínimo 0.75")
	# pan com botão do meio
	var world7: Control = st7.get("_world")
	var p0: Vector2 = world7.position if world7 else Vector2.ZERO
	var press7 := InputEventMouseButton.new()
	press7.button_index = MOUSE_BUTTON_MIDDLE
	press7.pressed = true
	st7.call("_on_canvas_input", press7)
	var drag7 := InputEventMouseMotion.new()
	drag7.relative = Vector2(-25, -15)
	drag7.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	st7.call("_on_canvas_input", drag7)
	assert(world7 != null and world7.position != p0, "arrastar com botão do meio faz pan")
	# comprar nó raiz: gasta 1 ponto, rank vira 1/N, nó fica dourado
	var pts0 := h.tree_points
	h.tree_points = 5
	ui7["button"].pressed.emit()
	assert(h.get_tree_node_rank(root7.id) == 1 and h.tree_points == 4, "clicar no nó gasta 1 ponto")
	assert(rank7.text == "1/%d" % root7.max_rank, "label de rank vira 1/N após compra")
	var style7 = ui7.get("style")
	assert(style7 != null and style7.border_color == UIKit.ACCENT_GOLD, "nó desbloqueado fica dourado")
	h.respec_tree()
	h.tree_points = pts0
	st7.call("refresh")
	ow.hud.toggle_skill_tree()  # fecha a aba
	print("[smoke]   arvore de habilidades ok (canvas procedural, pan/zoom 0.75-1.5, rank 0/N, compra gasta ponto)")
	
	# 6.5: micro-interações — pop ao abrir/fechar; reabrir cancela o fechamento.
	# Esperas por fim de animação usam _wait_until (relógio de parede): os
	# timers do engine disparam cedo em headless sob carga.
	ow.hud.toggle_inventory()
	ow.hud.toggle_inventory()
	assert(not ow.hud._unified.is_open() and ow.hud._unified.visible,
		"fecha com pop_out (logica imediata, animacao em curso)")
	var hidden65 := await _wait_until(func(): return not ow.hud._unified.visible)
	assert(hidden65, "janela some ao fim do pop_out")
	# reabrir no meio de um fechamento: mata o tween e cancela o callback
	ow.hud.toggle_inventory()   # abre (pop_in)
	ow.hud.toggle_inventory()   # fecha (pop_out em curso)…
	ow.hud.toggle_inventory()   # …e reabre no MESMO frame, cancelando tudo
	assert(ow.hud._unified.is_open(), "reabrir no meio do pop_out reabre a janela")
	var shown65 := await _wait_until(func():
		return ow.hud._unified.visible and absf(ow.hud._unified.modulate.a - 1.0) < 0.05)
	assert(shown65, "reaberta plenamente visivel (tween de fechamento morto, sem callback zumbi)")
	ow.hud.toggle_inventory()
	assert(not ow.hud._unified.is_open() and ow.hud._unified.visible, "fecha de novo (animacao em curso)")
	var hidden65b := await _wait_until(func(): return not ow.hud._unified.visible)
	assert(hidden65b, "janela some ao fim do segundo pop_out")
	# popups do mundo fecham com pop_out e libertam após a animação
	ow.hud.open_merchant()
	await _wait(0.1)
	var pop65 := ow.hud._popup
	var pop65_ref: WeakRef = weakref(pop65)
	ow.hud.close_popup()
	assert(ow.hud._popup == null and is_instance_valid(pop65),
		"close_popup solta a referencia e deixa o popup animar")
	var freed65 := await _wait_until(func(): return pop65_ref.get_ref() == null)
	assert(freed65, "popup libertado apos o pop_out")
	print("[smoke]   micro-interacoes ok (pop_in/pop_out na janela unificada e nos popups, reabertura cancela o fechamento)")
	# 7.1: relógio na HUD e ciclo dia/noite rico (MECANICAS §14.1)
	var chip71 := ClockChip.new()
	chip71.set_time(0.5)     # meio-dia
	assert(chip71.time_text() == "12:00" and chip71.is_day, "chip mostra 12:00 de dia")
	chip71.set_time(0.0)     # meia-noite exata
	assert(chip71.time_text() == "00:00" and not chip71.is_day, "chip mostra 00:00 de noite")
	chip71.set_time(0.26)    # 06:14 — madrugada ainda conta como noite? 0.26 > 0.25 -> dia
	assert(chip71.is_day, "dia comeca as 06:00 (0.25)")
	assert(ow.hud._clock is ClockChip and ow.hud._clock.visible, "chip de relogio na HUD sob o minimapa")
	# color grading por keyframes: meio-dia neutro, meia-noite azul-profundo
	assert(ow._day_color(0.5).is_equal_approx(Color(0.8, 0.78, 0.74)), "meio-dia neutro (keyframe)")
	assert(ow._day_color(0.0).is_equal_approx(Color(0.22, 0.26, 0.45)), "meia-noite azul-profundo")
	assert(ow._day_color(0.31).b > ow._day_color(0.27).b and ow._day_color(0.31).b < 0.74,
		"interpolacao suave entre amanhecer e meio-dia")
	# signal hour_changed + autosave "A Vela Virou" na virada da meia-noite
	var hora71 := {"h": -1}
	var latch71 := func(h: int): hora71["h"] = h
	Game.hour_changed.connect(latch71)
	ow._time = float(int(ow._time)) + 0.001   # meia-noite e um minuto
	ow._last_hour = 23
	var virou71 := await _wait_until(func(): return hora71["h"] == 0)
	Game.hour_changed.disconnect(latch71)
	assert(virou71 and int(fmod(ow._time, 1.0) * 24.0) == 0, "meia-noite emite hour_changed(0) e autosava")
	# dormir na fogueira até o amanhecer: salto até 06:00 + cura
	ow._time = float(int(ow._time)) + 0.92    # 22:04 da noite
	assert(ow._is_night(), "22:04 e noite")
	ow._offer_sleep()
	assert(ow.hud._popup != null, "fogueira acesa a noite oferece Dormir/Viajar")
	ow.hud.close_popup()
	ow.player.hp = 1.0
	ow._sleep_until_dawn()
	var amanheceu71 := await _wait_until(func():
		return absf(fmod(ow._time, 1.0) - 0.25) < 0.002)
	assert(amanheceu71 and not ow._is_night(), "dormir avanca ate 06:00 (0.25)")
	assert(absf(ow.player.hp - ow.player.max_hp) < 0.5, "dormir cura toda a vida")
	print("[smoke]   relogio/ciclo ok (chip HH:MM + arco, keyframes de cor, hour_changed na vela, dormir cura e avanca)")
	# 7.2: sombras dinâmicas 2D (MECANICAS §14.2) — oclusão por tile,
	# tremulação por fonte, orçamento de 8 sombras e lanterna do herói
	var ts72: TileSet = ow.wall_layer.tile_set
	assert(ts72.get_occlusion_layers_count() == 1, "tileset do mundo tem camada de oclusao")
	var alt72 := ow._alt(Vector2i(11, 14), Color(1.0, 0.7, 0.5), true)
	assert(ow._src.get_tile_data(Vector2i(11, 14), alt72).get_occluder(0) != null,
		"tile solido (tronco/rocha/muro) projeta sombra")
	var alt72b := ow._alt(Vector2i(28, 10), Color.WHITE, false)
	assert(ow._src.get_tile_data(Vector2i(28, 10), alt72b).get_occluder(0) == null,
		"chao/prop livre nao bloqueia a luz")
	var alt72c := ow._alt(Vector2i(28, 10), Color.WHITE, false, true)
	assert(ow._src.get_tile_data(Vector2i(28, 10), alt72c).get_occluder(0) == null,
		"copa de arvore nao bloqueia a luz (so o tronco)")
	# fogueira do acampamento: tremulação FIRE registrada (§14.2)
	var fire72: Interactable = null
	for n72 in get_tree().get_nodes_in_group("interactables"):
		if n72 is Interactable and (n72 as Interactable).kind == Interactable.Kind.CAMPFIRE \
				and (n72 as Interactable)._light != null:
			fire72 = n72
			break
	assert(fire72 != null, "fogueira do acampamento com luz viva")
	assert(LightFx.flicker_of(fire72._light) == LightFx.Flicker.FIRE, "fogueira oscila (FIRE)")
	# orçamento: no máx. 8 luzes com sombra; além de 720px degrada
	var center72 := Vector2(1000000, 1000000)
	var test72: Array[PointLight2D] = []
	for i72 in 12:
		var l72 := Fx.make_light(Color.WHITE, 0.5, 1.0, LightFx.Flicker.NONE, true)
		ow.add_child(l72)
		l72.global_position = center72 + Vector2(i72 * 60.0, 0)
		test72.append(l72)
	LightFx.update(center72, 1.0)
	var on72 := 0
	for l72 in test72:
		if l72.shadow_enabled:
			on72 += 1
	assert(on72 == LightFx.SHADOW_BUDGET, "orcamento concede sombra a apenas %d luzes" % LightFx.SHADOW_BUDGET)
	assert(test72[0].shadow_enabled and test72[7].shadow_enabled and not test72[8].shadow_enabled,
		"as 8 MAIS PROXIMAS ganham sombra, o resto degrada")
	assert(test72[0].shadow_filter == PointLight2D.SHADOW_FILTER_PCF5, "preset Medio = PCF5")
	var far72 := Fx.make_light(Color.WHITE, 0.5, 1.0, LightFx.Flicker.NONE, true)
	ow.add_child(far72)
	far72.global_position = center72 + Vector2(750.0, 0)
	LightFx.update(center72, 1.0)
	assert(not far72.shadow_enabled, "luz alem de 720px do centro fica sem sombra")
	# presets: Alto = PCF13; Desligadas = nenhuma sombra
	Game.settings.shadows = 2
	LightFx.update(center72, 1.0)
	assert(test72[0].shadow_filter == PointLight2D.SHADOW_FILTER_PCF13, "preset Alto = PCF13")
	Game.settings.shadows = 0
	LightFx.update(center72, 1.0)
	var any72 := false
	for l72 in test72:
		any72 = any72 or l72.shadow_enabled
	assert(not any72, "preset Desligadas desliga TODAS as sombras")
	Game.settings.shadows = 1
	# tremulação viva: energia muda com o tempo e fica na faixa da fonte
	var fl72 := Fx.make_light(Color(1, 0.6, 0.25), 2.2, 1.3, LightFx.Flicker.FIRE, true)
	ow.add_child(fl72)
	fl72.global_position = center72
	LightFx.update(center72, 10.0)
	var e72 := fl72.energy
	LightFx.update(center72, 10.37)
	assert(not is_equal_approx(fl72.energy, e72), "tremulacao FIRE muda a energia ao vivo")
	assert(absf(fl72.energy - 1.3) <= 1.3 * 0.14, "tremulacao FIRE fica em ±13% da base")
	assert(LightFx._flicker(LightFx.Flicker.LAVA, 1.0, 0.0) != LightFx._flicker(LightFx.Flicker.LAVA, 2.0, 0.0),
		"lava pulsa (lenta)")
	assert(LightFx._flicker(LightFx.Flicker.TORCH, 1.0, 0.0) != LightFx._flicker(LightFx.Flicker.TORCH, 2.0, 0.0),
		"tocha crepita (rapida)")
	# lanterna do herói: acesa de noite, apagada de dia, sempre com sombra
	var t72 := ow._time
	ow._time = float(int(t72)) + 0.95
	ow._update_daylight()
	assert(ow._lantern != null and ow._lantern.energy > 0.9, "22:48: lanterna do herói acesa")
	ow._time = float(int(t72)) + 0.5
	ow._update_daylight()
	assert(ow._lantern.energy < 0.01, "meio-dia: lanterna apagada")
	ow._time = t72
	ow._update_daylight()
	LightFx.update(ow.player.global_position, 1.0)
	assert(ow._lantern.shadow_enabled, "lanterna colada no herói sempre tem sombra")
	# limpeza: luzes de teste saem do mundo (o registry filtra inválidos)
	for l72 in test72:
		l72.queue_free()
	far72.queue_free()
	fl72.queue_free()
	print("[smoke]   sombras ok (oclusao por tile, fogueira FIRE, orcamento 8/720px, presets PCF5/PCF13, lanterna)")
	# 7.3: materiais e pós-processo 2D (MECANICAS §14.3) — glow HDR, rim light
	# nos sprites, vinheta e temperatura por bioma
	# (headless não faz parse de uniforms — asserts usam _atmos_preset e o código
	# do shader, não get_shader_parameter)
	assert(ProjectSettings.get_setting("rendering/viewport/hdr_2d") == true, "HDR 2D ligado para o glow")
	assert(ow._world_env != null and ow._world_env.environment.glow_enabled,
		"WorldEnvironment com bloom/glow no mundo")
	assert(ow._world_env.environment.glow_hdr_threshold > 1.0, "so luzes >1.0 florescem")
	assert(ow._atmos is ColorRect and (ow._atmos.material as ShaderMaterial).shader != null,
		"camada de vinheta com shader fullscreen")
	assert(ow._atmos_layer.layer < ow.hud.layer, "vinheta fica entre o mundo e a HUD")
	assert(ow._atmos.mouse_filter == Control.MOUSE_FILTER_IGNORE, "vinheta nao bloqueia o mouse")
	# temperatura por bioma: tundra fria-azul, areias quentes, corrompidas roxas
	ow._apply_atmos(ow.BIOME_ATMOS[&"tundra"])
	var tt73: Color = ow._atmos_preset.get("tint")
	assert(tt73.b > tt73.r, "tundra fria-azul")
	ow._apply_atmos(ow.BIOME_ATMOS[&"deserto"])
	tt73 = ow._atmos_preset.get("tint")
	assert(tt73.r > tt73.b, "areias quentes")
	ow._apply_atmos(ow.BIOME_ATMOS[&"corrompido"])
	assert(float(ow._atmos_preset.get("desat", 0.0)) > 0.2, "terras corrompidas dessaturadas")
	var vc73: Color = ow._atmos_preset.get("vig_color", Color.BLACK)
	assert(vc73.b > vc73.r and vc73.b > vc73.g, "vinheta roxa nas corrompidas")
	# atualização automática: teleporta à tundra e volta — a atmosfera segue
	var camp73 := ow.player.global_position
	var cell73 := _find_biome(ow, "tundra")
	assert(cell73 != Vector2i(999999, 999999), "bioma tundra existe")
	ow.player.global_position = ow.cell_to_world(cell73)
	ow._update_atmos()
	tt73 = ow._atmos_preset.get("tint")
	assert(tt73.b > tt73.r, "teleporte à tundra aplica atmosfera fria")
	ow.player.global_position = camp73
	ow._update_atmos()
	# rim light direcional: herói e inimigos carregam o hit_flash com light() (§14.3)
	var sh73: Shader = (ow.player.body_sprite.material as ShaderMaterial).shader
	assert(sh73 != null and String(sh73.code).contains("void light()")
		and String(sh73.code).contains("rim_strength"),
		"herói com rim light direcional")
	var foe73: Enemy = null
	for e73 in get_tree().get_nodes_in_group("enemies"):
		var m73 := (e73 as Enemy).sprite.material as ShaderMaterial
		if m73 != null and m73.shader != null and String(m73.shader.code).contains("rim_strength"):
			foe73 = e73
			break
	assert(foe73 != null, "inimigos com rim light direcional")
	# feixe de loot Raro+ e aura de Campeão florescem no glow (energia >1)
	var drop73 := LootDrop.new()
	drop73.kind = LootDrop.Kind.ITEM
	drop73.item = DB.roll_item_of(6, Item.Rarity.RARE, h.cls)
	drop73.position = ow.player.global_position + Vector2(2000, 0)
	ow.entities.add_child(drop73)
	assert(drop73._beam != null and drop73._beam.energy >= 1.2,
		"feixe de loot Raro+ passa do threshold do glow")
	drop73.queue_free()
	var g73: EnemyData = DB.get_enemy(&"goblin")
	var champ73: Enemy = ow.spawn_enemy(g73, ow.player.global_position + Vector2(2500, 0),
		Enemy.Rarity.CAMPEAO, 5)
	assert(champ73._aura != null and champ73._aura.energy >= 1.2,
		"aura de Campeao+ floresce no glow (HDR 2D)")
	assert(LightFx.flicker_of(champ73._aura) == -1, "aura nao tremula (constancia ameacadora)")
	print("[smoke]   pos-processo ok (glow HDR 2D, rim light nos sprites, vinheta/temperatura por bioma)")
	# 7.4: sistema de vento global (MECANICAS §14.5) — coerência, navegação,
	# forecast, desvio de flechas, "Ler o Vento" e calmaria de campeões
	# (determinismo: override fixa o vento; noise testado com t explícito)
	WindField.override = Vector2(1.0, 0.0)
	var far74 := Vector2(1000000, 1000000)
	assert(WindField.at(far74) == Vector2(1.0, 0.0), "override fixa o vento em qualquer lugar")
	assert(WindField.at(far74) == WindField.at(far74), "coerencia: mesma consulta, mesmo vento")
	# navegação (§14.5.1): ±10% andando com/contra a ventania; lateral não muda
	assert(WindField.speed_factor(far74, Vector2(1, 0)) > 1.05, "a favor da ventania acelera ~10%")
	assert(WindField.speed_factor(far74, Vector2(-1, 0)) < 0.95, "contra a ventania freia ~10%")
	assert(is_equal_approx(WindField.speed_factor(far74, Vector2(0, 1)), 1.0), "vento lateral nao muda a velocidade")
	# custo de rota (§14.5.4): a favor é mais barato, contra custa mais
	assert(WindField.path_factor(far74, far74 + Vector2(100, 0)) < 1.0, "rota a favor do vento custa menos")
	assert(WindField.path_factor(far74, far74 + Vector2(-100, 0)) > 1.0, "rota contra o vento custa mais")
	# noise coerente com o tempo (§14.5.1): 6 ticks distintos, determinísticos
	WindField.override = Vector2.ZERO
	var samples74: Array = []
	for k74 in 6:
		var t74 := k74 * WindField.TICK * 3.0 + 5.0
		var w74 := WindField.at(ow.player.global_position, t74)
		samples74.append(w74)
		assert(w74 == WindField.at(ow.player.global_position, t74), "vento deterministico por (pos, t)")
		assert(w74.length() <= 1.0 + 0.001, "forca do vento nunca passa de 1")
	var kinds74 := {}
	for w74 in samples74:
		kinds74[w74] = true
	assert(kinds74.size() >= 2, "o vento varia com o tempo (value-noise em ticks)")
	# forecast do dia (§14.5.1): evento válido e determinístico por dia
	var seen74 := {}
	for day74 in 60:
		var f74: StringName = WindField.forecast(day74)
		assert(f74 in [&"calmaria", &"ventania", &"frente", &"normal"], "evento de vento valido")
		assert(f74 == WindField.forecast(day74), "forecast deterministico por dia")
		assert(not WindField.presagio(day74) or f74 == &"calmaria", "presagio so na calmaria")
		seen74[f74] = true
	assert(seen74.size() >= 2, "60 dias veem pelo menos dois eventos de vento")
	# desvio de flechas (§14.5.4): vento lateral empurra o projétil físico;
	# "Ler o Vento" (§14.5.5, Caçador) faz a flecha voar reta
	# (is_solid para a flecha em chunk descarregado — disparamos numa faixa
	# livre escaneada perto do herói; pierce=99 + hit vazio atravessa inimigos)
	WindField.override = Vector2(1.0, 0.0)
	var noop74 := func(_e: Node, _p: Node) -> void: pass
	var lane74 := Vector2i(999999, 999999)
	var base74 := ow.world_to_cell(ow.player.global_position)
	for r74 in 40:
		var c74 := base74 + Vector2i(r74, 0)
		if not ow.is_floor(c74):
			continue
		var clear74 := true
		for k74 in 12:
			if not ow.is_floor(c74 + Vector2i(0, -k74 - 1)):
				clear74 = false
				break
		if clear74:
			lane74 = c74
			break
	assert(lane74 != Vector2i(999999, 999999), "existe faixa livre para a flecha")
	var from74 := ow.cell_to_world(lane74) + Vector2(0, -2)
	var arrow74 := Projectile.fire(ow, from74, Vector2(0, -1), 300.0, Color.WHITE, false, noop74, "weapon_arrow")
	arrow74.pierce = 99
	var flew74 := await _wait_until(func(): return is_instance_valid(arrow74) and arrow74._travelled > 120.0)
	assert(flew74, "flecha percorreu 120px")
	if flew74:
		assert(absf(arrow74.position.x - from74.x) > 3.0, "vento lateral desvia a flecha (>3px)")
	arrow74.queue_free()
	ow.player.add_buff("wind_reader", 1.0, 30.0, "Ler o Vento", Color(0.6, 0.9, 1.0))
	var arrow74b := Projectile.fire(ow, from74, Vector2(0, -1), 300.0, Color.WHITE, false, noop74, "weapon_arrow")
	arrow74b.pierce = 99
	var flew74b := await _wait_until(func(): return is_instance_valid(arrow74b) and arrow74b._travelled > 120.0)
	assert(flew74b, "flecha do leitor de vento percorreu 120px")
	if flew74b:
		assert(absf(arrow74b.position.x - from74.x) <= 2.0, "Ler o Vento faz a flecha voar reta")
	arrow74b.queue_free()
	# calmaria sobrenatural (§14.5.2): campeão PARA o vento ao redor de si
	var cc74 := WindField.calm_count()
	var champ74: Enemy = ow.spawn_enemy(g73, ow.player.global_position + Vector2(0, 5000),
		Enemy.Rarity.CAMPEAO, 5)
	assert(WindField.calm_count() == cc74 + 1, "campeao registrado no vento (calmaria)")
	assert(WindField.has_calm(champ74.get_instance_id()), "calmaria viva sob o campeao")
	assert(WindField.at(champ74.global_position).length() < 0.02, "calmaria sobrenatural para o vento")
	assert(WindField.at(ow.player.global_position + Vector2(0, 3000)).length() > 0.9, "alem do raio o vento volta")
	assert(WindField.at(ow.player.global_position) == Vector2(1.0, 0.0), "fora da calmaria o override manda")
	var cid74 := champ74.get_instance_id()
	champ74.queue_free()
	var gone74 := await _wait_until(func(): return not WindField.has_calm(cid74))
	assert(gone74, "a calmaria morre com o campeao")
	WindField.override = Vector2.ZERO
	print("[smoke]   vento ok (coerencia, forecast, ±10% navegacao, flecha desvia, Ler o Vento reto, calmaria de campeao)")
	# 7.5: áudio adaptativo (MECANICAS §15) — buses novos, ambiência por bioma,
	# música base do mundo, vento no bus Ambience, sting, camada de combate e
	# ducking de diálogo (o update_world tica a cada 0.5s no _process do World)
	assert(AudioServer.get_bus_index("Ambience") >= 0, "bus Ambience existe")
	assert(AudioServer.get_bus_index("UI") >= 0, "bus UI existe")
	assert(Game.settings.has("ambience_volume") and Game.settings.has("ui_volume"),
		"sliders de ambiência e interface existem nas settings")
	# vento quase zero via override mínimo (§15.1: bus Ambience = setting + vento)
	WindField.override = Vector2(0.01, 0.0)
	await _wait(0.8)
	assert(Audio.amb_gain_db() < -5.0, "calmaria quase total dá gain ≤ -5dB")
	await _wait(0.8)  # um tick do update_world
	assert(Audio.base_path().contains("mus_overworld"), "música base do mundo aberto")
	assert(Audio.ambience_path().begins_with(Audio.AMB) and Audio.ambience_path().contains("amb_"),
		"ambiência por bioma tocando")
	# vento controla o bus Ambience (§15.1): ventania sobe, calmaria desce
	WindField.override = Vector2(1.0, 0.0)
	await _wait(0.8)
	assert(Audio.amb_gain_db() > 2.0, "ventania sobe o gain da ambiência")
	var champ75: Enemy = ow.spawn_enemy(g73, ow.player.global_position + Vector2(60, 0),
		Enemy.Rarity.CAMPEAO, 5)
	await _wait(0.8)
	assert(Audio.amb_gain_db() < -5.0, "calmaria do campeão silencia a ambiência")
	assert(WindField.has_calm(champ75.get_instance_id()), "sting e calmaria no mesmo spawn")
	# sting por raridade (§15.2): Campeão/Lendário avisam; comum é mudo
	assert(Audio.sting(Enemy.Rarity.CAMPEAO) and Audio.sting(Enemy.Rarity.LENDARIO))
	assert(not Audio.sting(Enemy.Rarity.COMUM))
	champ75.take_damage(999999.0, false, Vector2.INF, 0.0)
	WindField.override = Vector2.ZERO
	# camada de combate (§15.2): aggro perto aciona mus_combate; kill desliga
	var foe75: Enemy = ow.spawn_enemy(g73, ow.player.global_position + Vector2(24, 0),
		Enemy.Rarity.COMUM, 5)
	await _wait(0.8)
	assert(Audio.layer_path().contains("mus_combate"), "combate aciona a camada de música")
	foe75.take_damage(999999.0, false, Vector2.INF, 0.0)
	await _wait(0.8)
	assert(not Audio.layer_path().contains("mus_combate"), "fim do combate solta a camada")
	# ducking de diálogo (§15.1): música −6dB aberto, volume de volta fechado
	var bus_m75 := AudioServer.get_bus_index("Music")
	var vol75 := AudioServer.get_bus_volume_db(bus_m75)
	var dlg75 := ow.hud.open_dialogue(DB.dialogue(&"marn_vigia"), "Marn")
	await _wait(0.3)
	assert(AudioServer.get_bus_volume_db(bus_m75) < vol75 - 5.0, "diálogo abaixa a música (−6dB)")
	dlg75.engine.stop()
	await _wait(0.8)
	assert(absf(AudioServer.get_bus_volume_db(bus_m75) - vol75) < 0.5, "fechar o diálogo devolve o volume")
	print("[smoke]   som adaptativo ok (buses Ambience/UI, base+ambiencia por bioma, vento no bus, sting, camada de combate, ducking de dialogo)")
	# 7.6: clima e partículas ambientais (MECANICAS §14.4) — emissor por bioma,
	# vagalumes noturnos, névoa parallax, chuva determinística + relâmpago
	assert(Weather.rain_on(3) == Weather.rain_on(3), "chuva determinística por dia")
	var wet76 := 0
	for d76 in 60:
		if Weather.rain_on(d76):
			wet76 += 1
	assert(wet76 >= 1 and wet76 <= 30, "60 dias têm dias de chuva E de sol (~20%)")
	assert(Weather.emitter_of(&"floresta") == &"leaf" and Weather.emitter_of(&"tundra") == &"snow",
		"emissor por bioma (folha na floresta, neve na tundra)")
	assert(Weather.fireflies_at(&"planicie", true) and not Weather.fireflies_at(&"deserto", true),
		"vagalumes só à noite em planície/floresta")
	assert(Weather.fog_at(&"pantano") and Weather.fog_at(&"corrompido") and not Weather.fog_at(&"planicie"),
		"névoa volumétrica só no pântano e Terras Corrompidas")
	assert(ow.weather != null, "camada de clima existe no mundo aberto")
	await _wait(0.8)  # um tick do _update_atmos
	assert(ow.weather.current_biome() == ow.og.biome_at(ow.world_to_cell(ow.player.global_position)),
		"camada de clima conhece o bioma do herói")
	assert(ow.weather.active_emitters().has(Weather.emitter_of(ow.weather.current_biome())),
		"emissor do bioma ativo")
	# névoa + chuva no pântano (configure direto — o tick restaura o estado real)
	ow.weather.configure(&"pantano", false, true, ow)
	assert(ow.weather.fog_visible(), "pântano tem névoa parallax")
	assert(ow.weather.active_emitters().has(&"spore") and ow.weather.active_emitters().has(&"rain"),
		"esporos do pântano + chuva ativos")
	# vagalumes noturnos na planície; sem névoa; sem chuva
	ow.weather.configure(&"planicie", true, false, ow)
	assert(ow.weather.active_emitters().has(&"dust") and ow.weather.active_emitters().has(&"firefly"),
		"planície noturna tem poeira E vagalumes")
	assert(not ow.weather.fog_visible(), "planície sem névoa")
	# relâmpago (§14.4): flash conta e trovão dispara
	var fc76 := ow.weather.flash_count()
	ow.weather.trigger_lightning()
	assert(ow.weather.flash_count() == fc76 + 1, "relâmpago conta o flash")
	# restore: o _update_atmos real no próximo tick traz o bioma verdadeiro de volta
	print("[smoke]   clima ok (chuva deterministica, emissor por bioma, vagalumes noturnos, nevoa parallax, relampago)")
	# 7.7: FSR 2.2 + MSAA + presets de qualidade de vídeo (§14.6)
	for k77 in ["fsr_mode", "msaa", "texture_filter", "particle_amount", "glow"]:
		assert(Game.settings.has(k77), "setting de vídeo 7.7 existe: " + k77)
	assert(int(Game.settings.fsr_mode) == 2 and int(Game.settings.msaa) == 1 and Game.settings.glow,
		"defaults de vídeo 7.7: FSR Equilibrado, MSAA 2×, glow ligado")
	assert(Game.settings.texture_filter == 0, "filtro default = nearest (pixel-art nítida)")
	assert(Game.particle_mult() == 0.75, "partículas 75% no default")
	Game.settings.particle_amount = 0
	assert(Game.particle_mult() == 0.5, "partículas 50% no modo econômico")
	Game.settings.particle_amount = 2
	assert(Game.particle_mult() == 1.0, "partículas 100% no modo alto")
	Game.settings.particle_amount = 1
	# FSR reflete no viewport raiz (§14.6) — API nativa scaling_3d
	var vp77 := get_viewport()
	Game.settings.fsr_mode = 3
	Game.apply_settings()
	assert(is_equal_approx(vp77.scaling_3d_scale, 0.5), "FSR Desempenho = 0.5 no viewport")
	Game.settings.fsr_mode = 0
	Game.apply_settings()
	assert(vp77.scaling_3d_mode == Viewport.SCALING_3D_MODE_BILINEAR and is_equal_approx(vp77.scaling_3d_scale, 1.0),
		"FSR desligado = bilinear 1.0 (nativo)")
	Game.settings.fsr_mode = 2
	Game.apply_settings()
	assert(vp77.scaling_3d_mode == Viewport.SCALING_3D_MODE_FSR2 and is_equal_approx(vp77.scaling_3d_scale, 0.67),
		"FSR Equilibrado = FSR2 a 0.67")
	assert(vp77.msaa_2d == Viewport.MSAA_2X, "MSAA 2× aplicado no viewport")
	# presets aplicam a combinação certa (§14.6) e o glow reage em runtime
	var presets77: Array = [
		{"shadows": 0, "fsr_mode": 3, "msaa": 0, "glow": false, "particle_amount": 0},
		{"shadows": 1, "fsr_mode": 2, "msaa": 1, "glow": true, "particle_amount": 1},
		{"shadows": 2, "fsr_mode": 1, "msaa": 2, "glow": true, "particle_amount": 2},
	]
	for p77 in presets77:
		for k77: String in p77:
			Game.settings[k77] = p77[k77]
		Game.apply_settings()   # roda sem erro com cada preset
		assert(bool(ow._world_env.environment.glow_enabled) == bool(p77["glow"]), "glow reage ao preset em runtime")
		assert(vp77.msaa_2d == [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][int(p77["msaa"])],
			"MSAA do preset aplicado")
		assert(Game.particle_mult() == [0.5, 0.75, 1.0][int(p77["particle_amount"])],
			"partículas do preset aplicadas")
	assert(ow._world_env.environment.glow_enabled, "preset Alto deixa o glow ligado")
	# volta ao default (Equilibrado) para o resto do smoke — e o glow volta junto
	Game.settings.shadows = 1
	Game.settings.fsr_mode = 2
	Game.settings.msaa = 1
	Game.settings.glow = false
	Game.apply_settings()
	assert(not ow._world_env.environment.glow_enabled, "desligar o glow na opção desliga o bloom")
	Game.settings.glow = true
	Game.apply_settings()
	assert(ow._world_env.environment.glow_enabled, "religar o glow na opção religa o bloom")
	Game.settings.particle_amount = 1
	Game.apply_settings()
	print("[smoke]   video ok (FSR 2.2 no viewport, MSAA 2x/4x, filtro nearest, particulas 50/75/100%, presets Baixo/Medio/Alto, glow reativo)")
	# 8.2: balanceamento pass — números conferem com REGRAS_DO_JOGO.md
	# REGRAS §3: undead ×1.5 holy, demon imune a shadow / weak a holy
	var ud82 := EnemyData.new()
	ud82.elemental_type = EnemyData.ElementalType.UNDEAD
	assert(Enemy._resist_calc(100.0, "holy", ud82) == 150.0, "undead leva ×1.5 holy (REGRAS §3)")
	assert(Enemy._resist_calc(100.0, "shadow", ud82) == 100.0, "undead sem resist a shadow")
	assert(Enemy._resist_calc(100.0, "physical", ud82) == 100.0, "undead dano físico normal")
	var dm82 := EnemyData.new()
	dm82.elemental_type = EnemyData.ElementalType.DEMON
	assert(Enemy._resist_calc(100.0, "holy", dm82) == 150.0, "demon fraco a holy ×1.5")
	assert(Enemy._resist_calc(100.0, "shadow", dm82) == 0.0, "demon imune a shadow")
	# data-driven: 12 undead + 6 demon marcados nos .tres
	var ud_count := 0
	var dm_count := 0
	for e82 in DB.enemies:
		if e82.elemental_type == EnemyData.ElementalType.UNDEAD:
			ud_count += 1
		elif e82.elemental_type == EnemyData.ElementalType.DEMON:
			dm_count += 1
	assert(ud_count == 12, "12 mortos-vivos marcados nos .tres")
	assert(dm_count == 6, "6 demônios marcados nos .tres")
	# REGRAS §2: XP para o próximo nível = 20 × nível^1.5
	for l82 in [1, 5, 10, 20, 60]:
		var old82 := h.level
		h.level = l82
		assert(h.xp_to_next() == int(20 * pow(l82, 1.5)), "XP nível %d = 20×n^1.5" % l82)
		h.level = old82
	# REGRAS §2: +1 ponto de atributo a cada 4 níveis (1, 5, 9, 13…)
	for l82 in [1, 5, 9, 13, 21]:
		assert(l82 % 4 == 1, "nível %d da ponto de atributo" % l82)
	# REGRAS §7: morte gold loss por dificuldade 10/20/30/30%
	var loss82 := [0.10, 0.20, 0.30, 0.30]
	for i82 in 4:
		assert(DB.DIFFICULTIES[i82].death_gold_loss == loss82[i82],
			"%s: -%.0f%% ouro" % [DB.DIFFICULTIES[i82].name, loss82[i82] * 100])
	# REGRAS §7: multiplicadores de dificuldade
	assert(DB.DIFFICULTIES[1].hp == 1.6 and DB.DIFFICULTIES[1].dmg == 1.35 and DB.DIFFICULTIES[1].xp == 1.25,
		"Difícil: 1.6 HP / 1.35 dmg / 1.25 XP")
	assert(DB.DIFFICULTIES[3].hp == 4.0 and DB.DIFFICULTIES[3].dmg == 2.5 and DB.DIFFICULTIES[3].xp == 2.0,
		"Inferno: 4.0 HP / 2.5 dmg / 2.0 XP")
	# REGRAS §8: valor de venda = (5 + lvl×3) × (1 + rar×2)
	var it82 := Item.new()
	it82.item_level = 10
	it82.rarity = 2  # Raro
	assert(it82.sell_value() == (5 + 10 * 3) * (1 + 2 * 2), "sell_value = (5+lvl×3)×(1+rar×2)")
	# REGRAS §10: desconto de reputação 0/5/10/15/20% por tier
	for t82 in 5:
		assert(Market.rep_discount(t82) == 0.05 * t82, "rep tier %d = %.0f%%" % [t82, t82 * 5])
	# REGRAS §6: multiplicadores de raridade (HP/dano/XP/ouro)
	assert(Enemy.RARITY_HP == [1.0, 2.5, 5.0, 10.0, 1.0], "raridade HP 1/2.5/5/10 (REGRAS §6)")
	assert(Enemy.RARITY_DMG == [1.0, 1.3, 1.8, 2.5, 1.0], "raridade dmg 1/1.3/1.8/2.5")
	assert(Enemy.RARITY_REWARD == [1, 3, 6, 15, 1], "raridade XP/ouro 1/3/6/15")
	# REGRAS §6: chances de spawn por raridade — distribuição sobre 10k rolagens
	var rng82 := RandomNumberGenerator.new()
	rng82.seed = 42
	var count82 := {Enemy.Rarity.LENDARIO: 0, Enemy.Rarity.CAMPEAO: 0, Enemy.Rarity.ELITE: 0, Enemy.Rarity.COMUM: 0}
	for i82 in 10000:
		count82[Enemy.roll_rarity(1, 0.0, rng82)] += 1
	# tolerância estatística (p=0.3%/2%/9%): ±0.3% / ±0.6% / ±1.2%
	assert(absf(count82[Enemy.Rarity.LENDARIO] / 10000.0 - 0.003) < 0.003, "Lendário ~0.3%")
	assert(absf(count82[Enemy.Rarity.CAMPEAO] / 10000.0 - 0.02) < 0.006, "Campeão ~2%")
	assert(absf(count82[Enemy.Rarity.ELITE] / 10000.0 - 0.09) < 0.012, "Elite ~9% (8%+1% nível)")
	print("[smoke]   balance ok (undead/demon resist, 12+6 marcados, XP curva, pontos a cada 4 niveis, dificuldade, sell_value, rep 5%/tier, raridade)")
	await _shot("07_mundo_acampamento")
	h.gold = 5000
	ow.hud.open_merchant()
	await _wait(0.4)
	await _shot("08_mercador")
	ow.hud.close_popup()
	# Visita cada bioma (procura uma célula de cada tipo em espiral)
	for biome in OverworldGen.BIOME_IDS:
		var target := _find_biome(ow, biome)
		if target == Vector2i(999999, 999999):
			print("[smoke] bioma não encontrado: ", biome)
			continue
		ow.player.global_position = ow.cell_to_world(target)
		await _wait(1.6)
		# Coloca o jogador num chão livre perto
		for r in 30:
			var c := target + Vector2i(r, 0)
			if ow.is_floor(c):
				ow.player.global_position = ow.cell_to_world(c)
				break
		await _wait(0.8)
		print("[smoke] bioma %s em %s: chunks=%d inimigos=%d nível=%d" % [biome, target, ow.chunks.size(), get_tree().get_nodes_in_group("enemies").size(), ow.level()])
		await _shot("07_bioma_" + biome)
	# Usa uma habilidade e anda um pouco no mundo
	ow.player._request_cast(0, ow.player.global_position + Vector2(20, 0))
	await _wait(0.5)
	# Viagem rápida
	ow.hud.open_waypoints()
	await _wait(0.3)
	await _shot("08b_viagem")
	ow.hud.close_popup()
	# Entra numa masmorra e volta
	var entrance: Interactable = null
	for k in [Vector2i(1, 0)]:
		ow.player.global_position = ow.cell_to_world(k * OverworldGen.CHUNK + Vector2i(16, 16))
	await _wait(2.0)
	for n in get_tree().get_nodes_in_group("interactables"):
		if n is Interactable and n.kind == Interactable.Kind.DUNGEON_ENTRANCE:
			entrance = n
			break
	if entrance:
		print("[smoke] entrando em: ", entrance.display_name())
		entrance.interact(ow.player)
		await _wait(2.5)
		var dw: World = get_tree().get_first_node_in_group("world")
		assert(not dw is Overworld)
		# 7.2: camada de oclusão da masmorra — paredes bloqueiam luz, chão não
		var dts72: TileSet = dw.wall_layer.tile_set
		assert(dts72.get_occlusion_layers_count() == 1, "masmorra tem camada de oclusao")
		var dsrc72 := dts72.get_source(0) as TileSetAtlasSource
		assert(dsrc72.get_tile_data(dw._tile_index["wall_mid"], 0).get_occluder(0) != null,
			"paredes da masmorra projetam sombra")
		assert(dsrc72.get_tile_data(dw._tile_index["floor_1"], 0).get_occluder(0) == null,
			"chao da masmorra nao bloqueia a luz")
		await _shot("09_masmorra")
		# 7.5: masmorra = reverb fake no bus SFX/Ambience + ping (§15.3)
		assert(Audio.has_reverb(), "masmorra liga o reverb fake")
		assert(Audio.ambience_path().contains("amb_masmorra"), "ambiência de masmorra")
		for n in get_tree().get_nodes_in_group("interactables"):
			if n is Interactable and n.kind == Interactable.Kind.DUNGEON_EXIT:
				n.interact(dw.player)
				break
		await _wait(2.5)
		assert(get_tree().get_first_node_in_group("world") is Overworld)
		assert(not Audio.has_reverb(), "voltar ao mundo desliga o reverb")
		print("[smoke] voltou ao mundo aberto")
	else:
		print("[smoke] ERRO: nenhuma entrada de masmorra encontrada")
	# regressão: spawn de chunk à noite aplica +10% aggro por instância (REGRAS #6) sem erro
	var ow_n: Overworld = get_tree().get_first_node_in_group("world")
	var wt_n := Game.world_time
	ow_n._time = 0.9  # 21:36 — noite
	Game.world_time = 0.9
	assert(ow_n._is_night(), "mundo em noite no teste")
	var base_k := ow_n._chunk_of(ow_n.player.global_position)
	for dk in [Vector2i(50, 50), Vector2i(51, 50), Vector2i(50, 51), Vector2i(51, 51), Vector2i(52, 52)]:
		ow_n._generate_chunk(base_k + dk)
	var com_bonus := 0
	for en_n in get_tree().get_nodes_in_group("enemies"):
		if en_n.aggro_mult > 1.09:
			com_bonus += 1
	assert(com_bonus > 0, "bônus noturno de aggro aplicado por instância nos spawns novos")
	print("[smoke] spawn noturno ok — %d inimigos novos com aggro x1.1" % com_bonus)
	ow_n._time = wt_n
	Game.world_time = wt_n
	Game.save_game()
	assert(Game.load_game())


func _find_biome(ow: Overworld, biome: String) -> Vector2i:
	for r in range(1, 120):
		for a in 16:
			var ang := a * TAU / 16.0
			var c := Vector2i(Vector2(cos(ang), sin(ang)) * r * 24.0)
			if ow.og.biome_at(c) == biome:
				return c
	return Vector2i(999999, 999999)


func _report_wide(c: Node, depth: int) -> void:
	if c is Control and (c as Control).size.x > 640:
		print("[wide] ", "  ".repeat(depth), c.get_class(), " ", c.name, " ", (c as Control).size, " min=", (c as Control).get_combined_minimum_size())
	for ch in c.get_children():
		_report_wide(ch, depth + 1)


func _nearest_enemy(world: World, pos: Vector2) -> Enemy:
	var best: Enemy
	var bd := INF
	for e in world.enemies_near(pos, 99999.0):
		var d := e.global_position.distance_to(pos)
		if d < bd:
			bd = d
			best = e
	return best


## Primeiro ScrollContainer da árvore de um controle (asserts de scroll)
func _first_scroll(c: Node) -> ScrollContainer:
	if c is ScrollContainer:
		return c
	for ch in c.get_children():
		var r := _first_scroll(ch)
		if r != null:
			return r
	return null
