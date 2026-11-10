class_name GuardianSpawner
extends Node

const GUARDIAN_SPAWN_POINTS = {
	&"mira_pe_leve": {
		"territory": &"halfling",
		"position": Vector2(100, 100),
		"npc_id": &"mira_pe_leve"
	},
	&"ashara_sussurra_magia": {
		"territory": &"elfo_floresta",
		"position": Vector2(150, 150),
		"npc_id": &"ashara_sussurra_magia"
	},
	&"lorelyn_espelho_agua": {
		"territory": &"humano",
		"position": Vector2(200, 200),
		"npc_id": &"lorelyn_espelho_agua"
	},
	&"theron_pedra_ressoante": {
		"territory": &"anao_montanha",
		"position": Vector2(250, 250),
		"npc_id": &"theron_pedra_ressoante"
	},
	&"kael_abismo": {
		"territory": &"drow",
		"position": Vector2(300, 300),
		"npc_id": &"kael_abismo"
	},
	&"khalid_areias_douradas": {
		"territory": &"draconato",
		"position": Vector2(350, 350),
		"npc_id": &"khalid_areias_douradas"
	},
	&"pyros_chama_ardente": {
		"territory": &"golias",
		"position": Vector2(400, 400),
		"npc_id": &"pyros_chama_ardente"
	},
}

func spawn_guardian(guardian_id: StringName) -> void:
	if guardian_id not in GUARDIAN_SPAWN_POINTS:
		return
	
	if not Game or not Game.flags:
		return
	
	var spawn_data = GUARDIAN_SPAWN_POINTS[guardian_id]
	# Flag guardian as available in world
	Game.flags.set(str(guardian_id) + "_available", true)
