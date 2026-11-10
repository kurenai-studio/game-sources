class_name SkillTrees
extends RefCounted
## Dados das árvores de habilidades por classe (definidos em código para evitar problemas de parsing .tres).
## Fase 10.4 - Arvore de habilidades

const SkillTreeData := preload("res://scripts/data/skill_tree_data.gd")
const SkillNodeData := preload("res://scripts/data/skill_node_data.gd")

## Retorna uma SkillTreeData populada para a classe especificada
static func get_tree(class_id: StringName) -> SkillTreeData:
	var tree := SkillTreeData.new()
	tree.class_id = class_id
	var nodes_data: Array[Dictionary] = _get_nodes_data(class_id)
	var nodes: Array[SkillNodeData] = []
	for nd in nodes_data:
		var node := SkillNodeData.new()
		node.id = nd.id
		node.skill_id = nd.skill_id
		node.is_new_skill = nd.is_new_skill
		node.max_rank = nd.max_rank
		var req_array: Array[StringName] = []
		for r in nd.requires:
			req_array.append(StringName(r))
		node.requires = req_array
		var pr_dict: Dictionary[String, float] = {}
		for k in nd.per_rank:
			pr_dict[String(k)] = float(nd.per_rank[k])
		node.per_rank = pr_dict
		node.display_name = nd.display_name
		node.description = nd.description
		node.icon = nd.icon
		nodes.append(node)
	tree.nodes = nodes
	return tree


## Retorna o Array de dicionários de nós para uma classe específica
static func _get_nodes_data(class_id: StringName) -> Array[Dictionary]:
	match class_id:
		"barbaro": return _barbaro_nodes()
		"bardo": return _bardo_nodes()
		"bruxo": return _bruxo_nodes()
		"cacador": return _cacador_nodes()
		"clerigo": return _clerigo_nodes()
		"druida": return _druida_nodes()
		"feiticeiro": return _feiticeiro_nodes()
		"guerreiro": return _guerreiro_nodes()
		"ladino": return _ladino_nodes()
		"lamina_arcana": return _lamina_arcana_nodes()
		"mago": return _mago_nodes()
		"monge": return _monge_nodes()
		"necromante": return _necromante_nodes()
		"paladino": return _paladino_nodes()
		_: return []


# ----------------------------------------------------------------------
# BARBARO
# ----------------------------------------------------------------------
static func _barbaro_nodes() -> Array[Dictionary]:
	var n: Array[Dictionary] = []
	# Novas skills
	n.append({"id": "barbaro_raiva_primordial", "skill_id": "raiva_primordial", "is_new_skill": true, "max_rank": 1, "requires": [], "per_rank": {}, "display_name": "Raiva Primordial", "description": "Desbloqueia: Entra em fúria primal. +50% dano, -30% dano recebido, gera Fúria rápida. Dura 15s.", "icon": "S_Buff01"})
	n.append({"id": "barbaro_esmagar_terra", "skill_id": "esmagar_terra", "is_new_skill": true, "max_rank": 1, "requires": ["barbaro_raiva_primordial"], "per_rank": {}, "display_name": "Esmagar a Terra", "description": "Desbloqueia: Golpe de área 12m. Atordoa 1.5s, deixa zona de difícil terreno por 8s. Custa 40 Fúria.", "icon": "S_Earth01"})
	n.append({"id": "barbaro_frenesi_sanguinario", "skill_id": "frenesi_sanguinario", "is_new_skill": true, "max_rank": 1, "requires": ["barbaro_esmagar_terra"], "per_rank": {}, "display_name": "Frenesi Sanguinário", "description": "Desbloqueia: Ataques rápidos por 8s. +60% vel. ataque, cada acerto cura 8% vida máxima. Custa 30 Fúria.", "icon": "S_Buff03"})
	n.append({"id": "barbaro_tita_dos_antigos", "skill_id": "tita_dos_antigos", "is_new_skill": true, "max_rank": 1, "requires": ["barbaro_frenesi_sanguinario"], "per_rank": {}, "display_name": "Titã dos Antigos", "description": "Desbloqueia: Forma de titã por 20s. +100% vida máxima, imune a controle, ataques em área. Custa 100 Fúria.", "icon": "S_Buff10"})
	# Melhorias (ranks)
	n.append({"id": "barbaro_golpe_1", "skill_id": "golpe_brutal", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"damage": 0.15, "cooldown": -0.07}, "display_name": "Golpe Brutal I-III", "description": "Melhora: +15% dano, -7% cooldown por rank.", "icon": "S_Sword01"})
	n.append({"id": "barbaro_golpe_2", "skill_id": "golpe_brutal", "is_new_skill": false, "max_rank": 2, "requires": ["barbaro_golpe_1"], "per_rank": {"radius": 0.15, "stun": 0.15}, "display_name": "Golpe Brutal IV-V", "description": "Melhora: +15% raio, +0.15s atordoamento por rank.", "icon": "S_Sword01"})
	n.append({"id": "barbaro_martelo_1", "skill_id": "martelo_dos_antigos", "is_new_skill": false, "max_rank": 3, "requires": ["barbaro_golpe_1"], "per_rank": {"damage": 0.15, "cooldown": -0.07, "knockback": 0.2}, "display_name": "Martelo dos Antigos I-III", "description": "Melhora: +15% dano, -7% cooldown, +20% empurrão por rank.", "icon": "S_Axe01"})
	n.append({"id": "barbaro_salto_1", "skill_id": "salto_furioso", "is_new_skill": false, "max_rank": 2, "requires": [], "per_rank": {"cooldown": -0.1, "damage": 0.1}, "display_name": "Salto Furioso I-II", "description": "Melhora: -10% cooldown, +10% dano por rank.", "icon": "S_Buff01"})
	n.append({"id": "barbaro_grito_1", "skill_id": "grito_aterrador", "is_new_skill": false, "max_rank": 2, "requires": ["barbaro_golpe_1"], "per_rank": {"duration": 1.0, "radius": 0.15}, "display_name": "Grito Aterrador I-II", "description": "Melhora: +1s duração, +15% raio por rank.", "icon": "S_Buff06"})
	n.append({"id": "barbaro_turbilhao_1", "skill_id": "turbilhao", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"damage": 0.15, "cooldown": -0.07, "hits": 1}, "display_name": "Turbilhão I-III", "description": "Melhora: +15% dano, -7% cooldown, +1 acerto por rank.", "icon": "S_Sword02"})
	n.append({"id": "barbaro_furia_1", "skill_id": "furia_berserker", "is_new_skill": false, "max_rank": 2, "requires": ["barbaro_turbilhao_1"], "per_rank": {"duration": 5.0, "damage": 0.2}, "display_name": "Fúria Berserker I-II", "description": "Melhora: +5s duração, +20% dano por rank.", "icon": "S_Buff02"})
	# Mestres (requisitos cruzados)
	n.append({"id": "barbaro_mestre_furia", "skill_id": "furia_berserker", "is_new_skill": false, "max_rank": 1, "requires": ["barbaro_furia_1", "barbaro_raiva_primordial"], "per_rank": {"damage": 0.25, "duration": 10.0}, "display_name": "Mestre da Fúria", "description": "Melhora final: +25% dano em fúria, +10s duração. Fúria gera +50% mais Fúria.", "icon": "S_Buff06"})
	n.append({"id": "barbaro_mestre_terra", "skill_id": "esmagar_terra", "is_new_skill": false, "max_rank": 1, "requires": ["barbaro_esmagar_terra", "barbaro_frenesi_sanguinario"], "per_rank": {"damage": 0.3, "stun": 0.5}, "display_name": "Mestre da Terra", "description": "Melhora final: +30% dano, +0.5s stun. Esmagar a Terra deixa vulcão ativo.", "icon": "S_Earth02"})
	n.append({"id": "barbaro_deus_guerra", "skill_id": "tita_dos_antigos", "is_new_skill": false, "max_rank": 1, "requires": ["barbaro_tita_dos_antigos", "barbaro_mestre_furia", "barbaro_mestre_terra"], "per_rank": {"damage": 0.5, "duration": 10.0, "cooldown": -0.3}, "display_name": "Deus da Guerra", "description": "Capstone: Titã +50% dano, +10s duração, -30% CD. Fúria custa 0 enquanto ativo.", "icon": "S_Buff10"})
	return n


# ----------------------------------------------------------------------
# BARDO
# ----------------------------------------------------------------------
static func _bardo_nodes() -> Array[Dictionary]:
	var n: Array[Dictionary] = []
	n.append({"id": "bardo_canto_sereia", "skill_id": "canto_sereia", "is_new_skill": true, "max_rank": 1, "requires": [], "per_rank": {}, "display_name": "Canto da Sereia", "description": "Desbloqueia: Canção que encanta inimigos em 10m. Eles lutam pelo bardo por 8s. Custa 40 Música.", "icon": "S_Buff06"})
	n.append({"id": "bardo_maestro_eterno", "skill_id": "maestro_eterno", "is_new_skill": true, "max_rank": 1, "requires": ["bardo_canto_sereia"], "per_rank": {}, "display_name": "Maestro Eterno", "description": "Desbloqueia: Aumenta dano dos aliados em 30% e reduz cooldowns em 20% por 15s. Custa 60 Música.", "icon": "S_Buff08"})
	n.append({"id": "bardo_marchada_guerra", "skill_id": "marchada_guerra", "is_new_skill": true, "max_rank": 1, "requires": ["bardo_maestro_eterno"], "per_rank": {}, "display_name": "Marchada de Guerra", "description": "Desbloqueia: Aliados ganham +30% vel. movimento e +25% dano por 12s. Custa 50 Música.", "icon": "S_Buff05"})
	n.append({"id": "bardo_sinfonia_caos", "skill_id": "sinfonia_caos", "is_new_skill": true, "max_rank": 1, "requires": ["bardo_marchada_guerra"], "per_rank": {}, "display_name": "Sinfonia do Caos", "description": "Desbloqueia: Explosão sonora 15m. Inimigos ficam confusos 6s, tomam dano sonoro 4x. Custa 100 Música.", "icon": "S_Buff10"})
	n.append({"id": "bardo_apoiar_1", "skill_id": "apoiar", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"heal": 0.2, "cooldown": -0.07}, "display_name": "Apoiar I-III", "description": "Melhora: +20% cura, -7% cooldown por rank.", "icon": "S_Holy01"})
	n.append({"id": "bardo_apoiar_2", "skill_id": "apoiar", "is_new_skill": false, "max_rank": 2, "requires": ["bardo_apoiar_1"], "per_rank": {"radius": 0.15, "resource_gain": 5}, "display_name": "Apoiar IV-V", "description": "Melhora: +15% raio, +5 Música devolvida por rank.", "icon": "S_Holy01"})
	n.append({"id": "bardo_cantico_1", "skill_id": "cantico_inspiracao", "is_new_skill": false, "max_rank": 3, "requires": ["bardo_apoiar_1"], "per_rank": {"damage": 0.15, "duration": 3.0}, "display_name": "Cântico de Inspiração I-III", "description": "Melhora: +15% dano, +3s duração por rank.", "icon": "S_Buff06"})
	n.append({"id": "bardo_sonata_1", "skill_id": "sonata_curativa", "is_new_skill": false, "max_rank": 2, "requires": [], "per_rank": {"heal": 0.15, "duration": 2.0}, "display_name": "Sonata Curativa I-II", "description": "Melhora: +15% cura/s, +2s duração por rank.", "icon": "S_Holy04"})
	n.append({"id": "bardo_mestre_canto", "skill_id": "canto_sereia", "is_new_skill": false, "max_rank": 1, "requires": ["bardo_canto_sereia", "bardo_apoiar_2"], "per_rank": {"duration": 8.0, "damage": 0.2}, "display_name": "Mestre do Canto", "description": "Melhora final: Canto da Sereia dura +8s, alvos encantados causam +20% dano.", "icon": "S_Buff06"})
	n.append({"id": "bardo_mestre_ritmo", "skill_id": "marchada_guerra", "is_new_skill": false, "max_rank": 1, "requires": ["bardo_marchada_guerra", "bardo_sonata_1"], "per_rank": {"damage": 0.25, "cooldown": -0.15}, "display_name": "Mestre do Ritmo", "description": "Melhora final: +25% dano em marcha, -15% CD. Marcha concede imunidade a medo.", "icon": "S_Buff07"})
	n.append({"id": "bardo_maestro_supremo", "skill_id": "sinfonia_caos", "is_new_skill": false, "max_rank": 1, "requires": ["bardo_sinfonia_caos", "bardo_mestre_canto", "bardo_mestre_ritmo"], "per_rank": {"damage": 0.5, "duration": 10.0, "cooldown": -0.3}, "display_name": "Maestro Supremo", "description": "Capstone: Sinfonia +50% dano, +10s duração, -30% CD. Aliados não são afetados pelo caos.", "icon": "S_Buff10"})
	return n


# ----------------------------------------------------------------------
# BRUXO
# ----------------------------------------------------------------------
static func _bruxo_nodes() -> Array[Dictionary]:
	var n: Array[Dictionary] = []
	n.append({"id": "bruxo_olho_do_vazio", "skill_id": "olho_do_vazio", "is_new_skill": true, "max_rank": 1, "requires": [], "per_rank": {}, "display_name": "Olho do Vazio", "description": "Desbloqueia: Revela área 20m por 20s. Inimigos revelados tomam +20% dano de todas as fontes. Custa 30 Mana.", "icon": "S_Shadow03"})
	n.append({"id": "bruxo_pacto_sangue", "skill_id": "pacto_sangue", "is_new_skill": true, "max_rank": 1, "requires": ["bruxo_olho_do_vazio"], "per_rank": {}, "display_name": "Pacto de Sangue", "description": "Desbloqueia: Sacrifica 20% vida máxima para ganhar 60 Mana instantaneamente e +40% dano por 10s.", "icon": "S_Shadow04"})
	n.append({"id": "bruxo_avatar_elemental", "skill_id": "avatar_elemental", "is_new_skill": true, "max_rank": 1, "requires": ["bruxo_pacto_sangue"], "per_rank": {}, "display_name": "Avatar Elemental", "description": "Desbloqueia: Forma elemental por 20s. Todos os elementos ativos, mana infinito, cooldowns -50%. Custa 100 Mana.", "icon": "S_Buff10"})
	n.append({"id": "bruxo_lorde_sombras", "skill_id": "lorde_sombras", "is_new_skill": true, "max_rank": 1, "requires": ["bruxo_avatar_elemental"], "per_rank": {}, "display_name": "Lorde das Sombras", "description": "Desbloqueia: Forma de sombra por 25s. Imune a dano físico, teleporte ao atacar, minions de sombra. Custa 120 Mana.", "icon": "S_Shadow07"})
	n.append({"id": "bruxo_raio_1", "skill_id": "raio_da_morte", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"damage": 0.15, "cooldown": -0.07, "pierce": 1}, "display_name": "Raio da Morte I-III", "description": "Melhora: +15% dano, -7% cooldown, +1 perfuração por rank.", "icon": "S_Shadow01"})
	n.append({"id": "bruxo_maldicao_1", "skill_id": "maldicao_fraqueza", "is_new_skill": false, "max_rank": 3, "requires": ["bruxo_raio_1"], "per_rank": {"duration": 3.0, "radius": 0.15, "damage": 0.1}, "display_name": "Maldição da Fraqueza I-III", "description": "Melhora: +3s duração, +15% raio, +10% dano por rank.", "icon": "S_Shadow02"})
	n.append({"id": "bruxo_nevoa_1", "skill_id": "nevoa_pestilenta", "is_new_skill": false, "max_rank": 2, "requires": ["bruxo_maldicao_1"], "per_rank": {"damage": 0.15, "duration": 2.0, "radius": 0.1}, "display_name": "Névoa Pestilenta I-II", "description": "Melhora: +15% dano, +2s duração, +10% raio por rank.", "icon": "S_Shadow04"})
	n.append({"id": "bruxo_espectro_1", "skill_id": "chamar_espectro", "is_new_skill": false, "max_rank": 2, "requires": [], "per_rank": {"duration": 10.0, "damage": 0.2}, "display_name": "Chamar Espectro I-II", "description": "Melhora: +10s duração, +20% dano do espectro por rank.", "icon": "S_Holy02"})
	n.append({"id": "bruxo_mestre_sombra", "skill_id": "raio_da_morte", "is_new_skill": false, "max_rank": 1, "requires": ["bruxo_raio_1", "bruxo_olho_do_vazio"], "per_rank": {"damage": 0.25, "pierce": 2}, "display_name": "Mestre das Sombras", "description": "Melhora final: +25% dano sombra, +2 perfuração. Olho do Vazio aumenta dano em 30%.", "icon": "S_Shadow05"})
	n.append({"id": "bruxo_mestre_pacto", "skill_id": "pacto_sangue", "is_new_skill": false, "max_rank": 1, "requires": ["bruxo_pacto_sangue", "bruxo_espectro_1"], "per_rank": {"damage": 0.3, "heal": 0.2}, "display_name": "Mestre do Pacto", "description": "Melhora final: +30% dano, Pacto cura 20% vida máxima ao lançar.", "icon": "S_Shadow06"})
	n.append({"id": "bruxo_arque_sombrio", "skill_id": "lorde_sombras", "is_new_skill": false, "max_rank": 1, "requires": ["bruxo_lorde_sombras", "bruxo_mestre_sombra", "bruxo_mestre_pacto"], "per_rank": {"damage": 0.5, "duration": 15.0, "cooldown": -0.3}, "display_name": "Arque das Sombras", "description": "Capstone: Lorde +50% dano, +15s duração, -30% CD sombra. Sombra consome inimigos.", "icon": "S_Buff10"})
	return n


# ----------------------------------------------------------------------
# CACADOR
# ----------------------------------------------------------------------
static func _cacador_nodes() -> Array[Dictionary]:
	var n: Array[Dictionary] = []
	n.append({"id": "cacador_ler_o_vento", "skill_id": "ler_o_vento", "is_new_skill": true, "max_rank": 1, "requires": [], "per_rank": {}, "display_name": "Ler o Vento", "description": "Desbloqueia: +50% alcance de detecção, críticos garantidos contra alvos surpresos. Dura 15s. Custa 30 Foco.", "icon": "S_Earth03"})
	n.append({"id": "cacador_alfa_da_matilha", "skill_id": "alfa_da_matilha", "is_new_skill": true, "max_rank": 1, "requires": ["cacador_ler_o_vento"], "per_rank": {}, "display_name": "Alfa da Matilha", "description": "Desbloqueia: Invoca lobo alfa. Lidera outros lobos, +50% dano da matilha, uivo atordoante. Custa 50 Foco.", "icon": "S_Holy02"})
	n.append({"id": "cacador_guardiao_da_floresta", "skill_id": "guardiao_da_floresta", "is_new_skill": true, "max_rank": 1, "requires": ["cacador_alfa_da_matilha"], "per_rank": {}, "display_name": "Guardião da Floresta", "description": "Desbloqueia: Invoca Espírito da Floresta. Cura aliados 10%/s, raízes prendem inimigos. Custa 60 Foco.", "icon": "S_Holy02"})
	n.append({"id": "cacador_atirador_elite", "skill_id": "atirador_elite", "is_new_skill": true, "max_rank": 1, "requires": ["cacador_guardiao_da_floresta"], "per_rank": {}, "display_name": "Atirador de Elite", "description": "Desbloqueia: Tiro de precisão extremo. 10x dano, crítico garantido, ignora armadura. Custa 100 Foco.", "icon": "S_Bow03"})
	n.append({"id": "cacador_flecha_1", "skill_id": "flecha_rapida", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"damage": 0.15, "cooldown": -0.07, "projectile_count": 1}, "display_name": "Flecha Rápida I-III", "description": "Melhora: +15% dano, -7% cooldown, +1 projétil por rank.", "icon": "S_Bow01"})
	n.append({"id": "cacador_tiro_1", "skill_id": "tiro_perfurante", "is_new_skill": false, "max_rank": 3, "requires": ["cacador_flecha_1"], "per_rank": {"damage": 0.15, "cooldown": -0.07, "pierce": 1}, "display_name": "Tiro Perfurante I-III", "description": "Melhora: +15% dano, -7% cooldown, +1 perfuração por rank.", "icon": "S_Bow02"})
	n.append({"id": "cacador_armadilha_1", "skill_id": "armadilha_explosiva", "is_new_skill": false, "max_rank": 2, "requires": ["cacador_tiro_1"], "per_rank": {"damage": 0.2, "radius": 0.15}, "display_name": "Armadilha Explosiva I-II", "description": "Melhora: +20% dano, +15% raio por rank.", "icon": "S_Earth02"})
	n.append({"id": "cacador_rajada_1", "skill_id": "rajada", "is_new_skill": false, "max_rank": 2, "requires": [], "per_rank": {"damage": 0.15, "cooldown": -0.07, "hits": 1}, "display_name": "Rajada I-II", "description": "Melhora: +15% dano, -7% cooldown, +1 acerto por rank.", "icon": "S_Bow03"})
	n.append({"id": "cacador_mestre_flecha", "skill_id": "flecha_rapida", "is_new_skill": false, "max_rank": 1, "requires": ["cacador_flecha_1", "cacador_ler_o_vento"], "per_rank": {"damage": 0.25, "cooldown": -0.15}, "display_name": "Mestre da Flecha", "description": "Melhora final: +25% dano, -15% cooldown. Flecha rápida nunca erra alvos marcados.", "icon": "S_Bow04"})
	n.append({"id": "cacador_mestre_matilha", "skill_id": "alfa_da_matilha", "is_new_skill": false, "max_rank": 1, "requires": ["cacador_alfa_da_matilha", "cacador_rajada_1"], "per_rank": {"summon_count": 2, "damage": 0.3, "duration": 15.0}, "display_name": "Mestre da Matilha", "description": "Melhora final: +2 lobos, +30% dano da matilha, +15s duração. Alfa cura a matilha.", "icon": "S_Holy02"})
	n.append({"id": "cacador_caçador_supremo", "skill_id": "atirador_elite", "is_new_skill": false, "max_rank": 1, "requires": ["cacador_atirador_elite", "cacador_mestre_flecha", "cacador_mestre_matilha"], "per_rank": {"damage": 0.5, "cooldown": -0.5, "duration": 10.0}, "display_name": "Caçador Supremo", "description": "Capstone: Atirador de Elite +50% dano, -50% CD, +10s. Tiro não consome munição.", "icon": "S_Buff10"})
	return n


# ----------------------------------------------------------------------
# CLERIGO
# ----------------------------------------------------------------------
static func _clerigo_nodes() -> Array[Dictionary]:
	var n: Array[Dictionary] = []
	n.append({"id": "clerigo_bencao_da_aurora", "skill_id": "bencao_da_aurora", "is_new_skill": true, "max_rank": 1, "requires": [], "per_rank": {}, "display_name": "Bênção da Aurora", "description": "Desbloqueia: Aura de cura 15m por 15s. Aliados regeneram 5% vida/s e ganham +15% resistências. Custa 30 Fé.", "icon": "S_Holy03"})
	n.append({"id": "clerigo_intervencao_divina", "skill_id": "intervencao_divina", "is_new_skill": true, "max_rank": 1, "requires": ["clerigo_bencao_da_aurora"], "per_rank": {}, "display_name": "Intervenção Divina", "description": "Desbloqueia: Impede a morte de aliados em 10m por 5s. Cura 50% vida máxima ao ativar. Custa 60 Fé.", "icon": "S_Holy05"})
	n.append({"id": "clerigo_coro_angelical", "skill_id": "coro_angelical", "is_new_skill": true, "max_rank": 1, "requires": ["clerigo_intervencao_divina"], "per_rank": {}, "display_name": "Coro Angelical", "description": "Desbloqueia: Invoca 3 espíritos curadores por 12s. Cada um cura alvo aleatório por 8% vida/s. Custa 50 Fé.", "icon": "S_Holy02"})
	n.append({"id": "clerigo_avatar_da_luz", "skill_id": "avatar_da_luz", "is_new_skill": true, "max_rank": 1, "requires": ["clerigo_coro_angelical"], "per_rank": {}, "display_name": "Avatar da Luz", "description": "Desbloqueia: Forma angelical 20s. Voa, imune a controle, cura em área 20% vida/s. Skills custam 0 Fé. Custa 100 Fé.", "icon": "S_Buff10"})
	n.append({"id": "clerigo_cura_maior_1", "skill_id": "cura_maior", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"heal": 0.2, "cooldown": -0.07}, "display_name": "Cura Maior I-III", "description": "Melhora: +20% cura, -7% cooldown por rank.", "icon": "S_Holy01"})
	n.append({"id": "clerigo_cura_maior_2", "skill_id": "cura_maior", "is_new_skill": false, "max_rank": 2, "requires": ["clerigo_cura_maior_1"], "per_rank": {"radius": 0.15, "resource_gain": 5}, "display_name": "Cura Maior IV-V", "description": "Melhora: +15% raio, +5 Fé devolvida por rank.", "icon": "S_Holy01"})
	n.append({"id": "clerigo_escudo_1", "skill_id": "escudo_divino", "is_new_skill": false, "max_rank": 3, "requires": ["clerigo_cura_maior_1"], "per_rank": {"duration": 2.0, "radius": 0.1}, "display_name": "Escudo Divino I-III", "description": "Melhora: +2s duração, +10% raio por rank.", "icon": "S_Buff04"})
	n.append({"id": "clerigo_martelo_1", "skill_id": "martelo_da_fe", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"damage": 0.15, "cooldown": -0.07, "stun": 0.15}, "display_name": "Martelo da Fé I-III", "description": "Melhora: +15% dano, -7% cooldown, +0.15s atordoamento por rank.", "icon": "S_Axe01"})
	n.append({"id": "clerigo_palavra_1", "skill_id": "palavra_de_poder", "is_new_skill": false, "max_rank": 2, "requires": ["clerigo_martelo_1"], "per_rank": {"damage": 0.2, "radius": 0.2}, "display_name": "Palavra de Poder I-II", "description": "Melhora: +20% dano, +20% raio por rank.", "icon": "S_Magic02"})
	n.append({"id": "clerigo_santuario_1", "skill_id": "santuario", "is_new_skill": false, "max_rank": 2, "requires": ["clerigo_escudo_1"], "per_rank": {"heal": 0.15, "duration": 2.0}, "display_name": "Santúário I-II", "description": "Melhora: +15% cura/s, +2s duração por rank.", "icon": "S_Holy04"})
	n.append({"id": "clerigo_ressurrecao_1", "skill_id": "ressurrecao", "is_new_skill": false, "max_rank": 1, "requires": ["clerigo_santuario_1"], "per_rank": {"heal": 0.5}, "display_name": "Ressurreição", "description": "Melhora: Ressuscita com 50% vida (era 25%).", "icon": "S_Holy06"})
	n.append({"id": "clerigo_mestre_cura", "skill_id": "cura_maior", "is_new_skill": false, "max_rank": 1, "requires": ["clerigo_cura_maior_2", "clerigo_bencao_da_aurora"], "per_rank": {"heal": 0.3, "cooldown": -0.15}, "display_name": "Mestre da Cura", "description": "Melhora final: +30% cura, -15% cooldown. Cura remove debuffs.", "icon": "S_Holy07"})
	n.append({"id": "clerigo_mestre_guerra", "skill_id": "martelo_da_fe", "is_new_skill": false, "max_rank": 1, "requires": ["clerigo_martelo_1", "clerigo_intervencao_divina"], "per_rank": {"damage": 0.25, "stun": 0.3}, "display_name": "Mestre da Guerra Santa", "description": "Melhora final: +25% dano sagrado, atordoamento base +0.3s. Intervenção concede imunidade a stun.", "icon": "S_Axe01"})
	n.append({"id": "clerigo_santo_supremo", "skill_id": "avatar_da_luz", "is_new_skill": false, "max_rank": 1, "requires": ["clerigo_avatar_da_luz", "clerigo_mestre_cura", "clerigo_mestre_guerra"], "per_rank": {"heal": 0.3, "duration": 10.0, "damage": 0.3}, "display_name": "Santo Supremo", "description": "Capstone: Avatar +30% cura/s, +10s duração, +30% dano. Aliados imunes a morte.", "icon": "S_Buff10"})
	return n


# ----------------------------------------------------------------------
# DRUIDA
# ----------------------------------------------------------------------
static func _druida_nodes() -> Array[Dictionary]:
	var n: Array[Dictionary] = []
	n.append({"id": "druida_caminho_seiva", "skill_id": "caminho_da_seiva", "is_new_skill": true, "max_rank": 1, "requires": [], "per_rank": {}, "display_name": "Caminho da Seiva", "description": "Desbloqueia: Caminho de seiva conecta aliados em 15m por 15s. Cura e Mana fluem entre eles. Custa 30 Mana.", "icon": "S_Earth03"})
	n.append({"id": "druida_furia_selvagem", "skill_id": "furia_selvagem", "is_new_skill": true, "max_rank": 1, "requires": ["druida_caminho_seiva"], "per_rank": {}, "display_name": "Fúria Selvagem", "description": "Desbloqueia: Aliados em 15m ganham +40% vel. ataque, +25% dano, sangramento nos acertos. 10s.", "icon": "S_Buff05"})
	n.append({"id": "druida_guardiao_floresta", "skill_id": "guardiao_da_floresta", "is_new_skill": true, "max_rank": 1, "requires": ["druida_furia_selvagem"], "per_rank": {}, "display_name": "Guardião da Floresta", "description": "Desbloqueia: Invoca Ancião da Floresta por 30s. Tanque massivo, aura cura 10%/s, raízes prendem inimigos. Custa 60 Mana.", "icon": "S_Holy02"})
	n.append({"id": "druida_arquidruida", "skill_id": "arquidruida", "is_new_skill": true, "max_rank": 1, "requires": ["druida_guardiao_floresta"], "per_rank": {}, "display_name": "Arquidruida", "description": "Desbloqueia: Forma de Arquidruida 20s. Todas formas ativas, mana infinito, cooldowns -50%. Custa 100 Mana.", "icon": "S_Buff10"})
	n.append({"id": "druida_toque_1", "skill_id": "toque_da_natureza", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"heal": 0.2, "cooldown": -0.07}, "display_name": "Toque da Natureza I-III", "description": "Melhora: +20% cura, -7% cooldown por rank.", "icon": "S_Earth01"})
	n.append({"id": "druida_toque_2", "skill_id": "toque_da_natureza", "is_new_skill": false, "max_rank": 2, "requires": ["druida_toque_1"], "per_rank": {"radius": 0.15, "resource_gain": 5}, "display_name": "Toque da Natureza IV-V", "description": "Melhora: +15% raio, +5 Mana devolvida por rank.", "icon": "S_Earth01"})
	n.append({"id": "druida_raizes_1", "skill_id": "raizes_prendentes", "is_new_skill": false, "max_rank": 3, "requires": ["druida_toque_1"], "per_rank": {"duration": 0.5, "radius": 0.1, "damage": 0.1}, "display_name": "Raízes Prendentes I-III", "description": "Melhora: +0.5s duração, +10% raio, +10% dano por rank.", "icon": "S_Earth02"})
	n.append({"id": "druida_formas_1", "skill_id": "formas_fera", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"duration": 3.0, "damage": 0.15}, "display_name": "Formas da Fera I-III", "description": "Melhora: +3s duração, +15% dano por rank.", "icon": "S_Buff04"})
	n.append({"id": "druida_tempestade_1", "skill_id": "tempestade_natureza", "is_new_skill": false, "max_rank": 2, "requires": ["druida_raizes_1"], "per_rank": {"damage": 0.15, "radius": 0.15}, "display_name": "Tempestade da Natureza I-II", "description": "Melhora: +15% dano, +15% raio por rank.", "icon": "S_Wind01"})
	n.append({"id": "druida_urso_1", "skill_id": "chamar_urso", "is_new_skill": false, "max_rank": 2, "requires": ["druida_formas_1"], "per_rank": {"duration": 10.0, "damage": 0.2}, "display_name": "Chamar Urso I-II", "description": "Melhora: +10s duração, +20% dano do urso por rank.", "icon": "S_Holy02"})
	n.append({"id": "druida_renovacao_1", "skill_id": "renovacao", "is_new_skill": false, "max_rank": 2, "requires": ["druida_caminho_seiva"], "per_rank": {"heal": 0.15, "duration": 2.0}, "display_name": "Renovação I-II", "description": "Melhora: +15% cura/s, +2s duração por rank.", "icon": "S_Earth04"})
	n.append({"id": "druida_mestre_cura", "skill_id": "toque_da_natureza", "is_new_skill": false, "max_rank": 1, "requires": ["druida_toque_2", "druida_caminho_seiva"], "per_rank": {"heal": 0.3, "radius": 0.25}, "display_name": "Mestre da Cura Natural", "description": "Melhora final: +30% cura, +25% raio. Cura espalha para aliados próximos.", "icon": "S_Earth05"})
	n.append({"id": "druida_mestre_feras", "skill_id": "formas_fera", "is_new_skill": false, "max_rank": 1, "requires": ["druida_formas_1", "druida_guardiao_floresta"], "per_rank": {"damage": 0.3, "duration": 10.0}, "display_name": "Mestre das Feras", "description": "Melhora final: +30% dano em formas, +10s duração. Urso vira Ancião permanente.", "icon": "S_Buff06"})
	n.append({"id": "druida_senhor_natureza", "skill_id": "arquidruida", "is_new_skill": false, "max_rank": 1, "requires": ["druida_arquidruida", "druida_mestre_cura", "druida_mestre_feras"], "per_rank": {"damage": 0.4, "heal": 0.25, "duration": 10.0, "cooldown": -0.3}, "display_name": "Senhor da Natureza", "description": "Capstone: Arquidruida +40% dano, +25% cura, +10s, -30% CD. Formas não custam mana.", "icon": "S_Buff10"})
	return n


# ----------------------------------------------------------------------
# FEITICEIRO
# ----------------------------------------------------------------------
static func _feiticeiro_nodes() -> Array[Dictionary]:
	var n: Array[Dictionary] = []
	n.append({"id": "feiticeiro_inferno", "skill_id": "inferno", "is_new_skill": true, "max_rank": 1, "requires": [], "per_rank": {}, "display_name": "Inferno", "description": "Desbloqueia: Chuva de meteoros em área 15m. 8 impactos, 2.5x fogo, queima 8s. Custa 60 Mana.", "icon": "S_Fire04"})
	n.append({"id": "feiticeiro_zero_absoluto", "skill_id": "zero_absoluto", "is_new_skill": true, "max_rank": 1, "requires": ["feiticeiro_inferno"], "per_rank": {}, "display_name": "Zero Absoluto", "description": "Desbloqueia: Explosão de gelo 12m. Congela 4s, -50% vel, dano 3x gelo. Custa 60 Mana.", "icon": "S_Ice03"})
	n.append({"id": "feiticeiro_tempestade_perfeita", "skill_id": "tempestade_perfeita", "is_new_skill": true, "max_rank": 1, "requires": ["feiticeiro_zero_absoluto"], "per_rank": {}, "display_name": "Tempestade Perfeita", "description": "Desbloqueia: Tempestade de raios 20m por 10s. Raio/s em inimigo aleatório, 2x raio, encadeia 3x.", "icon": "S_Holy01"})
	n.append({"id": "feiticeiro_avatar_elemental", "skill_id": "avatar_elemental", "is_new_skill": true, "max_rank": 1, "requires": ["feiticeiro_tempestade_perfeita"], "per_rank": {}, "display_name": "Avatar Elemental", "description": "Desbloqueia: Forma elemental 20s. Todos elementos ativos, mana infinito, cooldowns -50%. Custa 100 Mana.", "icon": "S_Buff10"})
	n.append({"id": "feiticeiro_raio_1", "skill_id": "raio_de_fogo", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"damage": 0.15, "cooldown": -0.07, "pierce": 1}, "display_name": "Raio de Fogo I-III", "description": "Melhora: +15% dano, -7% cooldown, +1 perfuração por rank.", "icon": "S_Fire01"})
	n.append({"id": "feiticeiro_bola_1", "skill_id": "bola_de_fogo", "is_new_skill": false, "max_rank": 3, "requires": ["feiticeiro_raio_1"], "per_rank": {"damage": 0.15, "cooldown": -0.07, "radius": 0.1}, "display_name": "Bola de Fogo I-III", "description": "Melhora: +15% dano, -7% cooldown, +10% raio por rank.", "icon": "S_Fire02"})
	n.append({"id": "feiticeiro_nova_1", "skill_id": "nova_gelida", "is_new_skill": false, "max_rank": 2, "requires": ["feiticeiro_bola_1"], "per_rank": {"damage": 0.2, "duration": 2.0}, "display_name": "Nova Gelada I-II", "description": "Melhora: +20% dano, +2s duração por rank.", "icon": "S_Ice01"})
	n.append({"id": "feiticeiro_corrente_1", "skill_id": "corrente_de_relampagos", "is_new_skill": false, "max_rank": 2, "requires": [], "per_rank": {"damage": 0.15, "cooldown": -0.07, "hits": 1}, "display_name": "Corrente de Raios I-II", "description": "Melhora: +15% dano, -7% cooldown, +1 encadeamento por rank.", "icon": "S_Holy01"})
	n.append({"id": "feiticeiro_mestre_fogo", "skill_id": "raio_de_fogo", "is_new_skill": false, "max_rank": 1, "requires": ["feiticeiro_raio_1", "feiticeiro_inferno"], "per_rank": {"damage": 0.25, "cooldown": -0.15}, "display_name": "Mestre do Fogo", "description": "Melhora final: +25% dano fogo, -15% cooldown. Inferno causa queimadura adicional.", "icon": "S_Fire03"})
	n.append({"id": "feiticeiro_mestre_gelo", "skill_id": "nova_gelida", "is_new_skill": false, "max_rank": 1, "requires": ["feiticeiro_nova_1", "feiticeiro_zero_absoluto"], "per_rank": {"damage": 0.3, "duration": 10.0}, "display_name": "Mestre do Gelo", "description": "Melhora final: +30% dano gelo, Zero Absoluto congela por +5s.", "icon": "S_Ice02"})
	n.append({"id": "feiticeiro_arca_mago", "skill_id": "avatar_elemental", "is_new_skill": false, "max_rank": 1, "requires": ["feiticeiro_avatar_elemental", "feiticeiro_mestre_fogo", "feiticeiro_mestre_gelo"], "per_rank": {"damage": 0.5, "duration": 10.0, "cooldown": -0.3}, "display_name": "Arca Mago", "description": "Capstone: Avatar Elemental +50% dano, +10s duração, -30% CD. Todos custam 0 Mana.", "icon": "S_Buff10"})
	return n


# ----------------------------------------------------------------------
# GUERREIRO
# ----------------------------------------------------------------------
static func _guerreiro_nodes() -> Array[Dictionary]:
	var n: Array[Dictionary] = []
	n.append({"id": "guerreiro_espada_escudo", "skill_id": "espada_e_escudo", "is_new_skill": true, "max_rank": 1, "requires": [], "per_rank": {}, "display_name": "Espada e Escudo", "description": "Desbloqueia: Postura defensiva. Bloqueia 50% dano, contra-ataca ao bloquear. Dura 15s. Custa 30 Vigor.", "icon": "S_Buff04"})
	n.append({"id": "guerreiro_brado_de_guerra", "skill_id": "brado_de_guerra", "is_new_skill": true, "max_rank": 1, "requires": ["guerreiro_espada_escudo"], "per_rank": {}, "display_name": "Brado de Guerra", "description": "Desbloqueia: Brado que intimida inimigos em 10m. -30% dano deles, aliados +20% dano. Custa 40 Vigor.", "icon": "S_Buff06"})
	n.append({"id": "guerreiro_guardiao_de_ferro", "skill_id": "guardiao_de_ferro", "is_new_skill": true, "max_rank": 1, "requires": ["guerreiro_brado_de_guerra"], "per_rank": {}, "display_name": "Guardião de Ferro", "description": "Desbloqueia: Forma de aço por 20s. +100% armadura, imune a derrube, contra-ataque causa stun. Custa 80 Vigor.", "icon": "S_Buff10"})
	n.append({"id": "guerreiro_golpe_mortal", "skill_id": "golpe_mortal", "is_new_skill": true, "max_rank": 1, "requires": ["guerreiro_guardiao_de_ferro"], "per_rank": {}, "display_name": "Golpe Mortal", "description": "Desbloqueia: Ataque executor. 5x dano se alvo <30% vida, atordoa 3s. Custa 100 Vigor.", "icon": "S_Sword03"})
	n.append({"id": "guerreiro_golpe_largo_1", "skill_id": "golpe_largo", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"damage": 0.15, "cooldown": -0.07, "hits": 1}, "display_name": "Golpe Largo I-III", "description": "Melhora: +15% dano, -7% cooldown, +1 alvo por rank.", "icon": "S_Sword01"})
	n.append({"id": "guerreiro_golpe_escudo_1", "skill_id": "golpe_de_escudo", "is_new_skill": false, "max_rank": 3, "requires": ["guerreiro_golpe_largo_1"], "per_rank": {"damage": 0.15, "cooldown": -0.07, "stun": 0.2}, "display_name": "Golpe de Escudo I-III", "description": "Melhora: +15% dano, -7% cooldown, +0.2s stun por rank.", "icon": "S_Buff04"})
	n.append({"id": "guerreiro_investida_1", "skill_id": "investida", "is_new_skill": false, "max_rank": 2, "requires": ["guerreiro_golpe_escudo_1"], "per_rank": {"damage": 0.2, "cooldown": -0.1}, "display_name": "Investida I-II", "description": "Melhora: +20% dano, -10% cooldown por rank.", "icon": "S_Buff01"})
	n.append({"id": "guerreiro_postura_1", "skill_id": "postura_defensiva", "is_new_skill": false, "max_rank": 2, "requires": [], "per_rank": {"duration": 5.0, "damage_reduction": 0.1}, "display_name": "Postura Defensiva I-II", "description": "Melhora: +5s duração, +10% redução de dano por rank.", "icon": "S_Buff04"})
	n.append({"id": "guerreiro_redemoinho_1", "skill_id": "redemoinho_de_aco", "is_new_skill": false, "max_rank": 2, "requires": ["guerreiro_golpe_largo_1"], "per_rank": {"damage": 0.15, "hits": 1}, "display_name": "Redemoinho de Aço I-II", "description": "Melhora: +15% dano, +1 acerto por rank.", "icon": "S_Sword02"})
	n.append({"id": "guerreiro_mestre_defesa", "skill_id": "espada_e_escudo", "is_new_skill": false, "max_rank": 1, "requires": ["guerreiro_espada_escudo", "guerreiro_postura_1"], "per_rank": {"damage_reduction": 0.15, "stun": 0.5}, "display_name": "Mestre da Defesa", "description": "Melhora final: +15% redução, Espada e Escudo causa stun ao bloquear.", "icon": "S_Buff04"})
	n.append({"id": "guerreiro_mestre_ofensa", "skill_id": "golpe_largo", "is_new_skill": false, "max_rank": 1, "requires": ["guerreiro_golpe_largo_1", "guerreiro_golpe_mortal"], "per_rank": {"damage": 0.3, "crit": 0.2}, "display_name": "Mestre da Ofensa", "description": "Melhora final: +30% dano, +20% crítico. Golpe Mortal executa <40% vida.", "icon": "S_Sword04"})
	n.append({"id": "guerreiro_campeao", "skill_id": "golpe_mortal", "is_new_skill": false, "max_rank": 1, "requires": ["guerreiro_golpe_mortal", "guerreiro_mestre_defesa", "guerreiro_mestre_ofensa"], "per_rank": {"damage": 0.5, "duration": 10.0, "cooldown": -0.3}, "display_name": "Campeão", "description": "Capstone: Golpe Mortal +50% dano, sempre crítico, -30% CD. Vitória garantida.", "icon": "S_Buff10"})
	return n


# ----------------------------------------------------------------------
# LADINO
# ----------------------------------------------------------------------
static func _ladino_nodes() -> Array[Dictionary]:
	var n: Array[Dictionary] = []
	n.append({"id": "ladino_danca_sombras", "skill_id": "danca_das_sombras", "is_new_skill": true, "max_rank": 1, "requires": [], "per_rank": {}, "display_name": "Dança das Sombras", "description": "Desbloqueia: Entra nas sombras. Invisível 4s, próximo ataque critica e ignora armadura. Custa 30 Sombrio.", "icon": "S_Shadow02"})
	n.append({"id": "ladino_golpe_cirurgico", "skill_id": "golpe_cirurgico", "is_new_skill": true, "max_rank": 1, "requires": ["ladino_danca_sombras"], "per_rank": {}, "display_name": "Golpe Cirúrgico", "description": "Desbloqueia: Ataque preciso. 4x dano, crítico garantido, causa sangramento. Custa 40 Sombrio.", "icon": "S_Sword03"})
	n.append({"id": "ladino_veneno_mortal", "skill_id": "veneno_mortal", "is_new_skill": true, "max_rank": 1, "requires": ["ladino_golpe_cirurgico"], "per_rank": {}, "display_name": "Veneno Mortal", "description": "Desbloqueia: Lâminas envenenadas. +15% dano, veneno causa 8% vida/s por 10s. Custa 50 Sombrio.", "icon": "S_Earth04"})
	n.append({"id": "ladino_mestre_assassino", "skill_id": "mestre_assassino", "is_new_skill": true, "max_rank": 1, "requires": ["ladino_veneno_mortal"], "per_rank": {}, "display_name": "Mestre Assassino", "description": "Desbloqueia: Estado de assassino por 20s. Todos golpes críticos, invisibilidade parcial, +100% dano às costas. Custa 100 Sombrio.", "icon": "S_Buff10"})
	n.append({"id": "ladino_apunhalar_1", "skill_id": "apunhalar", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"damage": 0.15, "cooldown": -0.07, "crit": 0.1}, "display_name": "Apunhalar I-III", "description": "Melhora: +15% dano, -7% cooldown, +10% crítico por rank.", "icon": "S_Dagger02"})
	n.append({"id": "ladino_leque_1", "skill_id": "leque_de_laminas", "is_new_skill": false, "max_rank": 3, "requires": ["ladino_apunhalar_1"], "per_rank": {"damage": 0.15, "cooldown": -0.07, "radius": 0.1}, "display_name": "Leque de Lâminas I-III", "description": "Melhora: +15% dano, -7% cooldown, +10% raio por rank.", "icon": "S_Dagger02"})
	n.append({"id": "ladino_passo_1", "skill_id": "passo_sombrio", "is_new_skill": false, "max_rank": 2, "requires": ["ladino_leque_1"], "per_rank": {"cooldown": -0.1, "reach": 0.2}, "display_name": "Passo Sombrio I-II", "description": "Melhora: -10% cooldown, +20% alcance por rank.", "icon": "S_Buff01"})
	n.append({"id": "ladino_frasco_1", "skill_id": "frasco_venenoso", "is_new_skill": false, "max_rank": 2, "requires": [], "per_rank": {"duration": 5.0, "damage": 0.15}, "display_name": "Frasco Venenoso I-II", "description": "Melhora: +5s duração, +15% dano veneno por rank.", "icon": "S_Earth03"})
	n.append({"id": "ladino_bomba_1", "skill_id": "bomba_de_fumaca", "is_new_skill": false, "max_rank": 2, "requires": ["ladino_passo_1"], "per_rank": {"duration": 3.0, "radius": 0.15}, "display_name": "Bomba de Fumaça I-II", "description": "Melhora: +3s duração, +15% raio por rank.", "icon": "S_Earth04"})
	n.append({"id": "ladino_mestre_lamina", "skill_id": "apunhalar", "is_new_skill": false, "max_rank": 1, "requires": ["ladino_apunhalar_1", "ladino_danca_sombras"], "per_rank": {"damage": 0.25, "crit": 0.15}, "display_name": "Mestre da Lâmina", "description": "Melhora final: +25% dano, +15% crítico. Dança das Sombras dura +5s.", "icon": "S_Dagger03"})
	n.append({"id": "ladino_mestre_veneno", "skill_id": "veneno_mortal", "is_new_skill": false, "max_rank": 1, "requires": ["ladino_veneno_mortal", "ladino_bomba_1"], "per_rank": {"damage": 0.3, "duration": 10.0}, "display_name": "Mestre do Veneno", "description": "Melhora final: +30% dano veneno, Veneno Mortal nunca falha aplicação.", "icon": "S_Earth05"})
	n.append({"id": "ladino_assassino_sombrio", "skill_id": "mestre_assassino", "is_new_skill": false, "max_rank": 1, "requires": ["ladino_mestre_assassino", "ladino_mestre_lamina", "ladino_mestre_veneno"], "per_rank": {"damage": 0.5, "cooldown": -0.5, "duration": 10.0}, "display_name": "Assassino Sombrio", "description": "Capstone: Mestre Assassino +50% dano, -50% CD, +10s. Ataque das costas é instantâneo.", "icon": "S_Buff10"})
	return n


# ----------------------------------------------------------------------
# LAMINA ARCANA
# ----------------------------------------------------------------------
static func _lamina_arcana_nodes() -> Array[Dictionary]:
	var n: Array[Dictionary] = []
	n.append({"id": "lamina_lamina_vazio", "skill_id": "lamina_do_vazio", "is_new_skill": true, "max_rank": 1, "requires": [], "per_rank": {}, "display_name": "Lâmina do Vazio", "description": "Desbloqueia: Arma se torna etérea. Atravessa inimigos, ignora armadura, rouba vida. Dura 15s.", "icon": "S_Shadow03"})
	n.append({"id": "lamina_corte_destino", "skill_id": "corte_do_destino", "is_new_skill": true, "max_rank": 1, "requires": ["lamina_lamina_vazio"], "per_rank": {}, "display_name": "Corte do Destino", "description": "Desbloqueia: Ataque que corta o destino. Crítico garantido, ignora esquiva, executa <20%. Custa 40 Mana.", "icon": "S_Shadow04"})
	n.append({"id": "lamina_passo_eterio", "skill_id": "passo_etereo", "is_new_skill": true, "max_rank": 1, "requires": ["lamina_corte_destino"], "per_rank": {}, "display_name": "Passo Etéreo", "description": "Desbloqueia: Teleporte curto que deixa clone. Clone explode causando dano arcano. 3 cargas. Custa 25 Mana.", "icon": "S_Magic09"})
	n.append({"id": "lamina_arquimago_da_lamina", "skill_id": "arquimago_da_lamina", "is_new_skill": true, "max_rank": 1, "requires": ["lamina_passo_eterio"], "per_rank": {}, "display_name": "Arquimago da Lâmina", "description": "Desbloqueia: Forma suprema 20s. 6 lâminas orbitais auto-atacam, teleporte livre, CD 0. Custa 100 Mana.", "icon": "S_Buff10"})
	n.append({"id": "lamina_lamina_1", "skill_id": "lamina_eterea", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"damage": 0.15, "cooldown": -0.07, "lifesteal": 0.02}, "display_name": "Lâmina Etérea I-III", "description": "Melhora: +15% dano, -7% cooldown, +2% roubo de vida por rank.", "icon": "S_Sword01"})
	n.append({"id": "lamina_lamina_2", "skill_id": "lamina_eterea", "is_new_skill": false, "max_rank": 2, "requires": ["lamina_lamina_1"], "per_rank": {"damage": 0.1, "radius": 0.15}, "display_name": "Lâmina Etérea IV-V", "description": "Melhora: +10% dano, +15% raio em acertos múltiplos por rank.", "icon": "S_Sword01"})
	n.append({"id": "lamina_corte_1", "skill_id": "corte_dimensional", "is_new_skill": false, "max_rank": 3, "requires": ["lamina_lamina_1"], "per_rank": {"damage": 0.15, "cooldown": -0.07, "pierce": 1}, "display_name": "Corte Dimensional I-III", "description": "Melhora: +15% dano, -7% cooldown, +1 perfuração por rank.", "icon": "S_Sword02"})
	n.append({"id": "lamina_teleporte_1", "skill_id": "teleporte_lamina", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"cooldown": -0.1, "reach": 0.15}, "display_name": "Teleporte da Lâmina I-III", "description": "Melhora: -10% cooldown, +15% alcance por rank.", "icon": "S_Magic09"})
	n.append({"id": "lamina_escudo_1", "skill_id": "escudo_arcano", "is_new_skill": false, "max_rank": 2, "requires": ["lamina_teleporte_1"], "per_rank": {"duration": 2.0, "radius": 0.1}, "display_name": "Escudo Arcano I-II", "description": "Melhora: +2s duração, +10% raio por rank.", "icon": "S_Buff04"})
	n.append({"id": "lamina_danca_1", "skill_id": "danca_das_laminas", "is_new_skill": false, "max_rank": 2, "requires": ["lamina_corte_1"], "per_rank": {"damage": 0.15, "hits": 1}, "display_name": "Dança das Lâminas I-II", "description": "Melhora: +15% dano, +1 acerto por rank.", "icon": "S_Sword03"})
	n.append({"id": "lamina_estilo_1", "skill_id": "estilo_arcano", "is_new_skill": false, "max_rank": 2, "requires": ["lamina_lamina_vazio"], "per_rank": {"damage": 0.2, "duration": 3.0}, "display_name": "Estilo Arcano I-II", "description": "Melhora: +20% dano, +3s duração por rank.", "icon": "S_Buff09"})
	n.append({"id": "lamina_mestre_vazio", "skill_id": "lamina_eterea", "is_new_skill": false, "max_rank": 1, "requires": ["lamina_lamina_2", "lamina_lamina_vazio"], "per_rank": {"damage": 0.25, "lifesteal": 0.05}, "display_name": "Mestre do Vazio", "description": "Melhora final: +25% dano etéreo, +5% roubo. Lâmina do Vazio dura +5s.", "icon": "S_Shadow05"})
	n.append({"id": "lamina_mestre_destino", "skill_id": "corte_dimensional", "is_new_skill": false, "max_rank": 1, "requires": ["lamina_corte_1", "lamina_corte_destino"], "per_rank": {"damage": 0.3, "crit": 0.2}, "display_name": "Mestre do Destino", "description": "Melhora final: +30% dano dimensional, +20% crítico. Corte do Destino executa <30% vida.", "icon": "S_Shadow06"})
	n.append({"id": "lamina_senhor_laminas", "skill_id": "arquimago_da_lamina", "is_new_skill": false, "max_rank": 1, "requires": ["lamina_arquimago_da_lamina", "lamina_mestre_vazio", "lamina_mestre_destino"], "per_rank": {"damage": 0.5, "cooldown": -0.5, "duration": 10.0}, "display_name": "Senhor das Lâminas", "description": "Capstone: Arquimago +50% dano, -50% CD, +10s. 6 lâminas orbitais auto-atacam.", "icon": "S_Buff10"})
	return n


# ----------------------------------------------------------------------
# MAGO
# ----------------------------------------------------------------------
static func _mago_nodes() -> Array[Dictionary]:
	var n: Array[Dictionary] = []
	n.append({"id": "mago_arquimago", "skill_id": "arquimago", "is_new_skill": true, "max_rank": 1, "requires": [], "per_rank": {}, "display_name": "Arquimago", "description": "Desbloqueia: Forma de Arquimago por 20s. Todos feitiços custam 0 Mana, cooldowns -50%. Custa 100 Mana.", "icon": "S_Buff10"})
	n.append({"id": "mago_bola_caos", "skill_id": "bola_caos", "is_new_skill": true, "max_rank": 1, "requires": ["mago_arquimago"], "per_rank": {}, "display_name": "Bola do Caos", "description": "Desbloqueia: Bola de energia caótica. Dano tipo aleatório, 6x dano base, explode em secundários. Custa 60 Mana.", "icon": "S_Magic03"})
	n.append({"id": "mago_rasgo_dimensional", "skill_id": "rasgo_dimensional", "is_new_skill": true, "max_rank": 1, "requires": ["mago_bola_caos"], "per_rank": {}, "display_name": "Rasgo Dimensional", "description": "Desbloqueia: Rasgo no espaço 15m. Puxa inimigos, causa dano arcano 5x, silencia 4s. Custa 80 Mana.", "icon": "S_Shadow07"})
	n.append({"id": "mago_tempo_parado", "skill_id": "tempo_parado", "is_new_skill": true, "max_rank": 1, "requires": ["mago_rasgo_dimensional"], "per_rank": {}, "display_name": "Tempo Parado", "description": "Desbloqueia: Para o tempo por 3s. Você pode agir livremente, inimigos congelados. Custa 120 Mana.", "icon": "S_Buff10"})
	n.append({"id": "mago_raio_1", "skill_id": "raio_de_fogo", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"damage": 0.15, "cooldown": -0.07, "pierce": 1}, "display_name": "Raio de Fogo I-III", "description": "Melhora: +15% dano, -7% cooldown, +1 perfuração por rank.", "icon": "S_Fire01"})
	n.append({"id": "mago_bola_1", "skill_id": "bola_de_fogo", "is_new_skill": false, "max_rank": 3, "requires": ["mago_raio_1"], "per_rank": {"damage": 0.15, "cooldown": -0.07, "radius": 0.1}, "display_name": "Bola de Fogo I-III", "description": "Melhora: +15% dano, -7% cooldown, +10% raio por rank.", "icon": "S_Fire02"})
	n.append({"id": "mago_nova_1", "skill_id": "nova_gelida", "is_new_skill": false, "max_rank": 2, "requires": ["mago_bola_1"], "per_rank": {"damage": 0.2, "duration": 2.0}, "display_name": "Nova Gelada I-II", "description": "Melhora: +20% dano, +2s duração por rank.", "icon": "S_Ice01"})
	n.append({"id": "mago_relampago_1", "skill_id": "raio_de_relampago", "is_new_skill": false, "max_rank": 2, "requires": [], "per_rank": {"damage": 0.15, "cooldown": -0.07, "hits": 1}, "display_name": "Raio de Relâmpago I-II", "description": "Melhora: +15% dano, -7% cooldown, +1 alvo por rank.", "icon": "S_Holy01"})
	n.append({"id": "mago_mestre_elementos", "skill_id": "raio_de_fogo", "is_new_skill": false, "max_rank": 1, "requires": ["mago_raio_1", "mago_arquimago"], "per_rank": {"damage": 0.25, "cooldown": -0.15}, "display_name": "Mestre dos Elementos", "description": "Melhora final: +25% dano elemental, Arquimago custa 50% menos Mana.", "icon": "S_Magic04"})
	n.append({"id": "mago_mestre_caos", "skill_id": "bola_caos", "is_new_skill": false, "max_rank": 1, "requires": ["mago_bola_caos", "mago_rasgo_dimensional"], "per_rank": {"damage": 0.3, "duration": 10.0}, "display_name": "Mestre do Caos", "description": "Melhora final: +30% dano caos, Bola do Caos sempre causa efeito secundário.", "icon": "S_Magic05"})
	n.append({"id": "mago_arca_tempo", "skill_id": "tempo_parado", "is_new_skill": false, "max_rank": 1, "requires": ["mago_tempo_parado", "mago_mestre_elementos", "mago_mestre_caos"], "per_rank": {"damage": 0.5, "duration": 5.0, "cooldown": -0.3}, "display_name": "Arca do Tempo", "description": "Capstone: Tempo Parado +5s, +50% dano durante, -30% CD. Realidade se dobra.", "icon": "S_Buff10"})
	return n


# ----------------------------------------------------------------------
# MONGE
# ----------------------------------------------------------------------
static func _monge_nodes() -> Array[Dictionary]:
	var n: Array[Dictionary] = []
	n.append({"id": "monge_estilo_bebado", "skill_id": "estilo_bebado", "is_new_skill": true, "max_rank": 1, "requires": [], "per_rank": {}, "display_name": "Estilo Bêbado", "description": "Desbloqueia: Movimentos imprevisíveis. +50% esquiva, contra-ataca ao esquivar. Dura 10s. Custa 30 Chi.", "icon": "S_Buff07"})
	n.append({"id": "monge_palma_coracao", "skill_id": "palma_do_coracao", "is_new_skill": true, "max_rank": 1, "requires": ["monge_estilo_bebado"], "per_rank": {}, "display_name": "Palma do Coração", "description": "Desbloqueia: Golpe que para o coração. 3x dano, atordoa 2s, se matar recupera todo Chi. Custa 50 Chi.", "icon": "S_Sword03"})
	n.append({"id": "monge_vo_dragao", "skill_id": "vo_dragao", "is_new_skill": true, "max_rank": 1, "requires": ["monge_palma_coracao"], "per_rank": {}, "display_name": "Vôo do Dragão", "description": "Desbloqueia: Salta e cai como meteoro. Area 10m, 4x dano, onda de choque atordoa 3s. Custa 60 Chi.", "icon": "S_Fire03"})
	n.append({"id": "monge_mestre_artes", "skill_id": "mestre_das_artes", "is_new_skill": true, "max_rank": 1, "requires": ["monge_vo_dragao"], "per_rank": {}, "display_name": "Mestre das Artes", "description": "Desbloqueia: Estado de fluxo 20s. Todos golpes críticos, Chi infinito, imune a controle. Custa 100 Chi.", "icon": "S_Buff10"})
	n.append({"id": "monge_palma_1", "skill_id": "palma_do_dragao", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"damage": 0.15, "cooldown": -0.07, "heal": 0.05}, "display_name": "Palma do Dragão I-III", "description": "Melhora: +15% dano, -7% cooldown, +5% cura por rank.", "icon": "S_Magic01"})
	n.append({"id": "monge_palma_2", "skill_id": "palma_do_dragao", "is_new_skill": false, "max_rank": 2, "requires": ["monge_palma_1"], "per_rank": {"projectile_count": 1, "radius": 0.1}, "display_name": "Palma do Dragão IV-V", "description": "Melhora: +1 onda de choque, +10% raio por rank.", "icon": "S_Magic01"})
	n.append({"id": "monge_chute_1", "skill_id": "chute_giratorio", "is_new_skill": false, "max_rank": 3, "requires": ["monge_palma_1"], "per_rank": {"damage": 0.15, "cooldown": -0.07, "hits": 1}, "display_name": "Chute Giratório I-III", "description": "Melhora: +15% dano, -7% cooldown, +1 acerto por rank.", "icon": "S_Buff01"})
	n.append({"id": "monge_onda_1", "skill_id": "onda_de_choque", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"damage": 0.15, "cooldown": -0.07, "radius": 0.1}, "display_name": "Onda de Choque I-III", "description": "Melhora: +15% dano, -7% cooldown, +10% raio por rank.", "icon": "S_Earth01"})
	n.append({"id": "monge_meditacao_1", "skill_id": "meditacao_profunda", "is_new_skill": false, "max_rank": 2, "requires": ["monge_onda_1"], "per_rank": {"duration": 3.0, "resource_gain": 10}, "display_name": "Meditação Profunda I-II", "description": "Melhora: +3s duração, +10 Chi/s por rank.", "icon": "S_Buff08"})
	n.append({"id": "monge_passo_1", "skill_id": "passo_do_vento", "is_new_skill": false, "max_rank": 2, "requires": ["monge_chute_1"], "per_rank": {"cooldown": -0.1, "reach": 0.2}, "display_name": "Passo do Vento I-II", "description": "Melhora: -10% cooldown, +20% alcance por rank.", "icon": "S_Buff01"})
	n.append({"id": "monge_punho_1", "skill_id": "punho_de_ferro", "is_new_skill": false, "max_rank": 2, "requires": ["monge_estilo_bebado"], "per_rank": {"damage": 0.2, "stun": 0.2}, "display_name": "Punho de Ferro I-II", "description": "Melhora: +20% dano, +0.2s atordoamento por rank.", "icon": "S_Sword02"})
	n.append({"id": "monge_mestre_palma", "skill_id": "palma_do_dragao", "is_new_skill": false, "max_rank": 1, "requires": ["monge_palma_2", "monge_estilo_bebado"], "per_rank": {"damage": 0.25, "heal": 0.15}, "display_name": "Mestre da Palma", "description": "Melhora final: +25% dano, +15% cura. Palma aplica queimadura.", "icon": "S_Fire01"})
	n.append({"id": "monge_mestre_ferro", "skill_id": "punho_de_ferro", "is_new_skill": false, "max_rank": 1, "requires": ["monge_punho_1", "monge_vo_dragao"], "per_rank": {"damage": 0.3, "stun": 0.5}, "display_name": "Mestre do Ferro", "description": "Melhora final: +30% dano, +0.5s stun. Vôo do Dragão ignora armadura.", "icon": "S_Sword04"})
	n.append({"id": "monge_grande_mestre", "skill_id": "mestre_das_artes", "is_new_skill": false, "max_rank": 1, "requires": ["monge_mestre_artes", "monge_mestre_palma", "monge_mestre_ferro"], "per_rank": {"damage": 0.5, "cooldown": -0.5, "duration": 10.0}, "display_name": "Grande Mestre", "description": "Capstone: Mestre das Artes +50% dano, -50% CD global, +10s. Golpes curam 10% dano causado.", "icon": "S_Buff10"})
	return n


# ----------------------------------------------------------------------
# NECROMANTE
# ----------------------------------------------------------------------
static func _necromante_nodes() -> Array[Dictionary]:
	var n: Array[Dictionary] = []
	n.append({"id": "necromante_senhor_mortos", "skill_id": "senhor_dos_mortos", "is_new_skill": true, "max_rank": 1, "requires": [], "per_rank": {}, "display_name": "Senhor dos Mortos", "description": "Desbloqueia: Comando absoluto. Minions ganham +100% vida/dano, herdam seus buffs, explodem ao morrer. 20s.", "icon": "S_Holy02"})
	n.append({"id": "necromante_ritual_ruina", "skill_id": "ritual_da_ruina", "is_new_skill": true, "max_rank": 1, "requires": ["necromante_senhor_mortos"], "per_rank": {}, "display_name": "Ritual da Ruína", "description": "Desbloqueia: Canaliza por 3s. Explosão 15m: 5x dano sombra, cura minions 50% vida, ressuscita caídos. Custa 80 Mana.", "icon": "S_Shadow07"})
	n.append({"id": "necromante_legiao_eterna", "skill_id": "legiao_eterna", "is_new_skill": true, "max_rank": 1, "requires": ["necromante_ritual_ruina"], "per_rank": {}, "display_name": "Legião Eterna", "description": "Desbloqueia: Invoca 10 esqueletos + 1 lich. Lich lança raio da morte. Exército dura 30s. Custa 100 Mana.", "icon": "S_Holy02"})
	n.append({"id": "necromante_lorde_morte", "skill_id": "lorde_da_morte", "is_new_skill": true, "max_rank": 1, "requires": ["necromante_legiao_eterna"], "per_rank": {}, "display_name": "Lorde da Morte", "description": "Desbloqueia: Forma de Lich 25s. Imune a veneno/sangramento/medo, mana infinito, minions não morrem. Custa 120 Mana.", "icon": "S_Buff10"})
	n.append({"id": "necromante_drenar_1", "skill_id": "drenar_vida", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"damage": 0.15, "cooldown": -0.07, "heal": 0.1}, "display_name": "Drenar Vida I-III", "description": "Melhora: +15% dano, -7% cooldown, +10% cura por rank.", "icon": "S_Shadow01"})
	n.append({"id": "necromante_raio_1", "skill_id": "raio_da_morte", "is_new_skill": false, "max_rank": 3, "requires": ["necromante_drenar_1"], "per_rank": {"damage": 0.15, "cooldown": -0.07, "pierce": 1}, "display_name": "Raio da Morte I-III", "description": "Melhora: +15% dano, -7% cooldown, +1 perfuração por rank.", "icon": "S_Shadow02"})
	n.append({"id": "necromante_esqueletos_1", "skill_id": "invocar_esqueletos", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"duration": 10.0, "summon_count": 1}, "display_name": "Invocar Esqueletos I-III", "description": "Melhora: +10s duração, +1 esqueleto por rank.", "icon": "S_Holy02"})
	n.append({"id": "necromante_maldicao_1", "skill_id": "maldicao_fraqueza", "is_new_skill": false, "max_rank": 2, "requires": ["necromante_esqueletos_1"], "per_rank": {"duration": 3.0, "radius": 0.15}, "display_name": "Maldição da Fraqueza I-II", "description": "Melhora: +3s duração, +15% raio por rank.", "icon": "S_Shadow03"})
	n.append({"id": "necromante_nevoa_1", "skill_id": "nevoa_pestilenta", "is_new_skill": false, "max_rank": 2, "requires": ["necromante_raio_1"], "per_rank": {"damage": 0.15, "duration": 2.0, "radius": 0.1}, "display_name": "Névoa Pestilenta I-II", "description": "Melhora: +15% dano, +2s duração, +10% raio por rank.", "icon": "S_Shadow04"})
	n.append({"id": "necromante_golpe_1", "skill_id": "golpe_spectral", "is_new_skill": false, "max_rank": 2, "requires": ["necromante_maldicao_1"], "per_rank": {"damage": 0.2, "heal": 0.1}, "display_name": "Golpe Espectral I-II", "description": "Melhora: +20% dano, +10% cura por rank.", "icon": "S_Sword01"})
	n.append({"id": "necromante_mestre_drenar", "skill_id": "drenar_vida", "is_new_skill": false, "max_rank": 1, "requires": ["necromante_drenar_1", "necromante_senhor_mortos"], "per_rank": {"damage": 0.25, "heal": 0.2}, "display_name": "Mestre da Drenagem", "description": "Melhora final: +25% dano, +20% cura. Drenar aplica maldição de fraqueza.", "icon": "S_Shadow05"})
	n.append({"id": "necromante_mestre_minions", "skill_id": "invocar_esqueletos", "is_new_skill": false, "max_rank": 1, "requires": ["necromante_esqueletos_1", "necromante_legiao_eterna"], "per_rank": {"summon_count": 3, "damage": 0.3, "duration": 15.0}, "display_name": "Mestre dos Minions", "description": "Melhora final: +3 esqueletos base, +30% dano minions, +15s duração. Esqueletos viram arqueiros.", "icon": "S_Holy02"})
	n.append({"id": "necromante_mestre_ruina", "skill_id": "raio_da_morte", "is_new_skill": false, "max_rank": 1, "requires": ["necromante_raio_1", "necromante_ritual_ruina"], "per_rank": {"damage": 0.35, "pierce": 2}, "display_name": "Mestre da Ruína", "description": "Melhora final: +35% dano sombra, +2 perfuração. Ritual da Ruína custa 50% menos Mana.", "icon": "S_Shadow06"})
	n.append({"id": "necromante_deus_morte", "skill_id": "lorde_da_morte", "is_new_skill": false, "max_rank": 1, "requires": ["necromante_lorde_morte", "necromante_mestre_drenar", "necromante_mestre_minions", "necromante_mestre_ruina"], "per_rank": {"damage": 0.5, "duration": 15.0, "cooldown": -0.3}, "display_name": "Deus da Morte", "description": "Capstone: Lorde +50% dano, +15s duração, -30% CD sombra. Minions imortais. Drenar cura 100% dano.", "icon": "S_Buff10"})
	return n


# ----------------------------------------------------------------------
# PALADINO
# ----------------------------------------------------------------------
static func _paladino_nodes() -> Array[Dictionary]:
	var n: Array[Dictionary] = []
	n.append({"id": "paladino_coluna_de_fe", "skill_id": "coluna_de_fe", "is_new_skill": true, "max_rank": 1, "requires": [], "per_rank": {}, "display_name": "Coluna de Fé", "description": "Desbloqueia: Coluna de luz sagrada. Cura aliados 15% vida/s, danifica inimigos 2x sagrado. Dura 15s. Custa 40 Fé.", "icon": "S_Holy04"})
	n.append({"id": "paladino_julgamento", "skill_id": "julgamento", "is_new_skill": true, "max_rank": 1, "requires": ["paladino_coluna_de_fe"], "per_rank": {}, "display_name": "Julgamento", "description": "Desbloqueia: Julgamento sagrado. 4x dano, atordoa 2s, marca alvo para execução. Custa 50 Fé.", "icon": "S_Axe01"})
	n.append({"id": "paladino_martirio", "skill_id": "martirio", "is_new_skill": true, "max_rank": 1, "requires": ["paladino_julgamento"], "per_rank": {}, "display_name": "Martírio", "description": "Desbloqueia: Sacrifica vida para curar aliados. Cura 2x dano sofrido, gera escudo absorção. Custa 60 Fé.", "icon": "S_Holy05"})
	n.append({"id": "paladino_avatar_da_luz", "skill_id": "avatar_da_luz", "is_new_skill": true, "max_rank": 1, "requires": ["paladino_martirio"], "per_rank": {}, "display_name": "Avatar da Luz", "description": "Desbloqueia: Forma angelical 20s. Voa, imune a controle, cura em área 20% vida/s. Skills custam 0 Fé. Custa 100 Fé.", "icon": "S_Buff10"})
	n.append({"id": "paladino_golpe_sagrado_1", "skill_id": "golpe_sagrado", "is_new_skill": false, "max_rank": 3, "requires": [], "per_rank": {"damage": 0.15, "cooldown": -0.07, "heal": 0.05}, "display_name": "Golpe Sagrado I-III", "description": "Melhora: +15% dano, -7% cooldown, +5% cura por rank.", "icon": "S_Sword01"})
	n.append({"id": "paladino_escudo_sagrado_1", "skill_id": "escudo_sagrado", "is_new_skill": false, "max_rank": 3, "requires": ["paladino_golpe_sagrado_1"], "per_rank": {"duration": 2.0, "radius": 0.1}, "display_name": "Escudo Sagrado I-III", "description": "Melhora: +2s duração, +10% raio por rank.", "icon": "S_Buff04"})
	n.append({"id": "paladino_aura_1", "skill_id": "aura_protecao", "is_new_skill": false, "max_rank": 2, "requires": ["paladino_escudo_sagrado_1"], "per_rank": {"duration": 5.0, "damage_reduction": 0.1}, "display_name": "Aura de Proteção I-II", "description": "Melhora: +5s duração, +10% redução de dano por rank.", "icon": "S_Buff04"})
	n.append({"id": "paladino_luz_divina_1", "skill_id": "luz_divina", "is_new_skill": false, "max_rank": 2, "requires": [], "per_rank": {"heal": 0.15, "cooldown": -0.07}, "display_name": "Luz Divina I-II", "description": "Melhora: +15% cura, -7% cooldown por rank.", "icon": "S_Holy01"})
	n.append({"id": "paladino_consagracao_1", "skill_id": "consagracao", "is_new_skill": false, "max_rank": 2, "requires": ["paladino_aura_1"], "per_rank": {"damage": 0.2, "duration": 3.0}, "display_name": "Consagração I-II", "description": "Melhora: +20% dano sagrado, +3s duração por rank.", "icon": "S_Holy03"})
	n.append({"id": "paladino_mestre_luz", "skill_id": "golpe_sagrado", "is_new_skill": false, "max_rank": 1, "requires": ["paladino_golpe_sagrado_1", "paladino_coluna_de_fe"], "per_rank": {"damage": 0.25, "heal": 0.15}, "display_name": "Mestre da Luz", "description": "Melhora final: +25% dano sagrado, +15% cura. Golpe Sagrado remove debuffs.", "icon": "S_Holy06"})
	n.append({"id": "paladino_mestre_escudo", "skill_id": "escudo_sagrado", "is_new_skill": false, "max_rank": 1, "requires": ["paladino_escudo_sagrado_1", "paladino_avatar_da_luz"], "per_rank": {"damage": 0.3, "duration": 10.0}, "display_name": "Mestre do Escudo", "description": "Melhora final: +30% dano, Avatar da Luz concede imunidade a morte.", "icon": "S_Buff04"})
	n.append({"id": "paladino_cruzado", "skill_id": "avatar_da_luz", "is_new_skill": false, "max_rank": 1, "requires": ["paladino_avatar_da_luz", "paladino_mestre_luz", "paladino_mestre_escudo"], "per_rank": {"damage": 0.5, "duration": 10.0, "cooldown": -0.3}, "display_name": "Cruzado", "description": "Capstone: Avatar +50% dano, +10s duração, -30% CD. Aliados imunes a morte.", "icon": "S_Buff10"})
	return n