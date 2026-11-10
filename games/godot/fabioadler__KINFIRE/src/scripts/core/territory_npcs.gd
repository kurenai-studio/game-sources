class_name TerritoryNpcs
extends RefCounted
## Moradores das capitais raciais (tarefa 2.5, MECANICAS #3, LORE #X/#6):
## o líder + 3 gente comum com ganho-de-vida próprio por raça.
## Os diálogos são GERADOS POR TEMPLATE a partir do TerritoryData
## (economia, cultura, líder, capital) e registrados no cache do DB -
## nada de 56 .tres escritos à mão; o Npc resolve o resto por duck-typing.

## Nome e sexo da gente comum de cada capital (LORE #X) - determinístico
const COMMONERS := {
	&"humano": [["Tomas", "m"], ["Isabel", "f"], ["Roderick", "m"]],
	&"alto_elfo": [["Caelwyn", "m"], ["Seraphina", "f"], ["Elirion", "m"]],
	&"elfo_floresta": [["Faelin", "m"], ["Sylvenna", "f"], ["Musgo", "m"]],
	&"drow": [["Zarketh", "m"], ["Vaelith", "f"], ["Nilissa", "f"]],
	&"anao_montanha": [["Borin", "m"], ["Helga", "f"], ["Torvald", "m"]],
	&"anao_colinas": [["Milo", "m"], ["Berta", "f"], ["Osric", "m"]],
	&"halfling": [["Bando", "m"], ["Rosie", "f"], ["Peregrin", "m"]],
	&"meio_orc": [["Ghesh", "m"], ["Yevelda", "f"], ["Krukk", "m"]],
	&"tiefling": [["Mordai", "m"], ["Vex", "f"], ["Zephiros", "m"]],
	&"draconato": [["Sarthax", "m"], ["Ignara", "f"], ["Voroth", "m"]],
	&"gnomo": [["Fizzle", "m"], ["Bimble", "f"], ["Cogsworth", "m"]],
	&"meio_elfo": [["Aldric", "m"], ["Liora", "f"], ["Dain", "m"]],
	&"tabaxi": [["Sombra", "m"], ["Mingal", "f"], ["Whiskers", "m"]],
	&"golias": [["Kavaki", "m"], ["Aunaki", "f"], ["Thalai", "m"]],
}

## Ganho-de-vida por raça (LORE #X - coluna "Economia", #6 cultura viva)
const ROLES := {
	&"humano": ["Contratante da Guilda", "Leiloeira do Porto", "Carregador do Cais"],
	&"alto_elfo": ["Engarrafador de Mana", "Encantadora sob Encomenda", "Pesquisador Arcano"],
	&"elfo_floresta": ["Coletora de Ervas Raras", "Tecelão de Nós", "Apicultor de Gigantes"],
	&"drow": ["Corretora de Segredos", "Alquimista de Venenos", "Fiandeiro de Seda"],
	&"anao_montanha": ["Forjador", "Mineira de Profundezas", "Engenheiro de Cerco"],
	&"anao_colinas": ["Agricultor", "Cervejeira", "Guardiã de Conservas"],
	&"halfling": ["Carteiro Interestadual", "Mestra dos Dados", "Doceira"],
	&"meio_orc": ["Escolta de Caravana", "Caçadora de Bestas", "Mestre da Arena"],
	&"tiefling": ["Comerciante de Amaldiçoados", "Alquimista de Sangue", "Limpa-Cinzas"],
	&"draconato": ["Mercenária de Elite", "Colecionador de Escamas", "Lapidador de Gemas"],
	&"gnomo": ["Inventora", "Registrador de Patentes", "Reparador de Impossíveis"],
	&"meio_elfo": ["Diplomata", "Tradutora Juramentada", "Artesão Híbrido"],
	&"tabaxi": ["Guia de Expedição", "Caçadora de Raridades", "Mercador de Especiarias"],
	&"golias": ["Carregador de Carga", "Mineira de Altitude", "Guardião das Pedras"],
}

## Sexo do líder de cada capital (LORE #X) - só afeta sprite/retrato
const LEADER_SEX := {
	&"humano": "f", &"alto_elfo": "f", &"elfo_floresta": "f", &"drow": "f",
	&"anao_montanha": "m", &"anao_colinas": "f", &"halfling": "f", &"meio_orc": "m",
	&"tiefling": "f", &"draconato": "m", &"gnomo": "m", &"meio_elfo": "m",
	&"tabaxi": "f", &"golias": "m",
}

## Posição relativa ao centro da capital (px)
const LEADER_OFFSET := Vector2(18.0, -12.0)
const COMMONER_OFFSETS := [Vector2(-24.0, 12.0), Vector2(26.0, 18.0), Vector2(-8.0, -26.0)]


## Popula uma capital: líder + 3 gente comum ao redor do centro.
## `out_nodes` não vazio registra os NPCs como conteúdo do chunk (liberados
## no unload); vazio = persistentes (capital do jogador, como Marn/Bree).
static func populate(ow: Overworld, race: StringName, center: Vector2, out_nodes: Array = []) -> void:
	var t: TerritoryData = DB.territory(race)
	if t == null or not COMMONERS.has(race):
		return
	_ensure_dialogues(race, t)
	var leader := NpcData.new()
	leader.id = _id(race, "lider")
	leader.display_name = t.leader_name
	leader.role = "Líder de %s" % t.capital_name
	leader.race_id = race
	leader.sex = LEADER_SEX.get(race, "m")
	leader.dialogue_id = _id(race, "lider")
	var pos := ow.last_free_point(center, center + LEADER_OFFSET)
	var n := Npc.create(ow, leader, pos)
	if not out_nodes.is_empty():
		out_nodes.append(n)
	for i in COMMONERS[race].size():
		var person: Array = COMMONERS[race][i]
		var nd := NpcData.new()
		nd.id = _id(race, "comum%d" % i)
		nd.display_name = person[0]
		nd.role = ROLES[race][i]
		nd.race_id = race
		nd.sex = person[1]
		nd.dialogue_id = _id(race, "comum%d" % i)
		pos = ow.last_free_point(center, center + COMMONER_OFFSETS[i])
		n = Npc.create(ow, nd, pos)
		if not out_nodes.is_empty():
			out_nodes.append(n)


static func _id(race: StringName, suffix: String) -> StringName:
	return StringName("capital_%s_%s" % [race, suffix])


## Registra os diálogos gerados no cache do DB (o loader lazy encontra sem arquivo)
static func _ensure_dialogues(race: StringName, t: TerritoryData) -> void:
	var lead_id := _id(race, "lider")
	if not DB.dialogues.has(lead_id):
		DB.dialogues[lead_id] = _leader_dialogue(race, t)
	for i in COMMONERS[race].size():
		var cid := _id(race, "comum%d" % i)
		if not DB.dialogues.has(cid):
			DB.dialogues[cid] = _commoner_dialogue(race, t, i)


# ------------------------------------------------------------------ LIDER

static func _leader_dialogue(race: StringName, t: TerritoryData) -> DialogueData:
	var d := DialogueData.new()
	d.id = _id(race, "lider")
	d.display_name = t.leader_name
	var r: RaceData = DB.get_race(race)
	d.portrait = r.sprite_f if LEADER_SEX.get(race, "m") == "f" else r.sprite_m
	d.start_id = &"inicio"
	d.nodes = [
		_node(&"inicio",
			"%s não levanta da cadeira. Quem manda em %s não recebe ninguém de pé." % [t.leader_name, t.capital_name],
			[
				_choice("(Apresentar-se)", &"apresentacao", "!flag capital_%s_apresentado" % race, "flag capital_%s_apresentado" % race),
				_choice("(Falar de novo)", &"menu", "flag capital_%s_apresentado" % race),
			]),
		_node(&"apresentacao",
			"Sou %s, %s de %s." % [t.leader_name, t.leader_role, t.capital_name],
			[
				_choice("(Continuar)", &"menu"),
			],
			"Você tem nome, forasteiro? Aqui os nomes pesam menos que os laços - mas pesam."),
		_node(&"menu",
			"O que traz cinza à %s?" % t.capital_name,
			[
				_choice("Como o território sobrevive?", &"economia"),
				_choice("(Perguntar sobre a Chama apagada)", &"chama"),
				_choice("O povo está bem?", &"povo"),
				_choice("(Negociar com %s)" % t.capital_name, &"", "", "comercio %s" % race),
				_choice("(Oferecer ajuda ao território)", &"promessa",
					"!flag capital_%s_promessa" % race,
					"flag capital_%s_promessa\nrep %s +1" % [race, race]),
				_choice("(Partir)", &""),
			]),
		_node(&"economia",
			"%s vive de %s. O resto é conversa de fogueira." % [t.capital_name, t.economy],
			[_back(), _leave()]),
		_node(&"chama",
			"A Chama de %s está apagada desde a Noite em que o mundo esqueceu como amar. Enquanto as Sete não voltarem a bater juntas, cada território é só um pedaço esperando o frio." % t.capital_name,
			[_back(), _leave()]),
		_node(&"povo", t.culture, [_back(), _leave()]),
		_node(&"promessa",
			"Promessa de cinza... que seja. %s lembra quem estendeu a mão." % t.capital_name,
			[_back(), _leave()]),
	]
	return d


# ------------------------------------------------------------------ GENTE COMUM

static func _commoner_dialogue(race: StringName, t: TerritoryData, i: int) -> DialogueData:
	var person: Array = COMMONERS[race][i]
	var role: String = ROLES[race][i]
	var race_name: String = DB.get_race(race).display_name
	var d := DialogueData.new()
	d.id = _id(race, "comum%d" % i)
	d.display_name = person[0]
	var r: RaceData = DB.get_race(race)
	d.portrait = r.sprite_f if person[1] == "f" else r.sprite_m
	d.start_id = &"inicio"
	d.nodes = [
		_node(&"inicio",
			"%s para o que tem que fazer - %s não espera ninguém." % [person[0], t.capital_name],
			[
				_choice("No que você trabalha?", &"trabalho"),
				_choice("O que é este lugar?", &"lugar", "ignorancia > 5", "ignorancia -1"),
				_choice("Como é viver em %s?" % t.capital_name, &"vida", "ignorancia <= 5"),
				_choice("(Partir)", &""),
			]),
		_node(&"trabalho",
			"Aqui a gente vive de %s. %s não é título - é o que sobrou pra gente ser." % [t.economy, role],
			[_back(&"inicio"), _leave()]),
		_node(&"lugar",
			"Este é o território %s, e esta é a capital: %s. Quatorze povos, quatorze jeitos de não morrer." % [race_name, t.capital_name],
			[_back(&"inicio"), _leave()]),
		_node(&"vida", t.culture, [_back(&"inicio"), _leave()]),
	]
	return d


# ------------------------------------------------------------------ HELPERS

static func _node(nid: StringName, text: String, choices: Array = [], page2 := "", page3 := "") -> DialogueNode:
	var n := DialogueNode.new()
	n.id = nid
	if page2 != "":
		n.pages = PackedStringArray([text, page2])
		if page3 != "":
			n.pages.append(page3)
	else:
		n.text = text
	for c in choices:
		n.choices.append(c)
	return n


static func _choice(text: String, next: StringName, condition := "", effects := "") -> DialogueChoice:
	var c := DialogueChoice.new()
	c.text = text
	c.next_id = next
	c.condition = condition
	c.effects = effects
	return c


static func _back(target: StringName = &"menu") -> DialogueChoice:
	return _choice("(Voltar)", target)


static func _leave() -> DialogueChoice:
	return _choice("(Partir)", &"")
