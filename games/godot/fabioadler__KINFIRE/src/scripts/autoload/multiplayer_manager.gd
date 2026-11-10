## Multiplayer Manager Singleton
## Gerencia conexões servidor/cliente via MultiplayerAPI (ENet)
## Host: roda state do mundo
## Clientes: sincronizam com host via RPC

extends Node

# Estado da conexão
var is_server: bool = false
var is_client: bool = false
var server_running: bool = false

# Peers conectados
var connected_peers: Dictionary = {}  # peer_id -> {"name": str, "hero": Hero}
var player_chars: Dictionary = {}     # peer_id -> Hero node

# Gerenciadores de state
var enemy_instances: Dictionary = {}  # enemy_id -> Enemy node
var loot_drops: Dictionary = {}       # drop_id -> LootDrop node
var damage_tracker: Dictionary = {}   # enemy_id -> {peer_id: damage_done}
var kill_credit: Dictionary = {}      # enemy_id -> peer_id (last hitter)

# Network settings
const PORT: int = 7777
const MAX_PLAYERS: int = 4

# Sinais
signal peer_connected(peer_id: int)
signal peer_disconnected(peer_id: int)
signal connected_to_server
signal connection_failed
signal server_started
signal server_stopped

## ============================================================================
## INICIALIZACAO
## ============================================================================

func _ready() -> void:
	# Conectar sinais do multiplayer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

## ============================================================================
## SERVIDOR
## ============================================================================

## Inicia servidor na porta 7777
func start_server(port: int = PORT, max_players: int = MAX_PLAYERS) -> bool:
	if server_running:
		push_warning("Servidor já está rodando!")
		return false
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, max_players)
	
	if error:
		push_error("Erro ao criar servidor: %s" % error)
		return false
	
	multiplayer.multiplayer_peer = peer
	is_server = true
	server_running = true
	
	print("[MULTIPLAYER] Servidor iniciado em 0.0.0.0:%d (max %d players)" % [port, max_players])
	server_started.emit()
	return true

## Para o servidor
func stop_server() -> void:
	if not server_running:
		return
	
	multiplayer.multiplayer_peer = null
	is_server = false
	server_running = false
	connected_peers.clear()
	player_chars.clear()
	
	print("[MULTIPLAYER] Servidor parado")
	server_stopped.emit()

## ============================================================================
## CLIENTE
## ============================================================================

## Conecta cliente ao servidor
func create_client(host_ip: String, port: int = PORT) -> bool:
	if is_server or is_client:
		push_warning("Já conectado/servidor rodando!")
		return false
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(host_ip, port)
	
	if error:
		push_error("Erro ao criar cliente: %s" % error)
		connection_failed.emit()
		return false
	
	multiplayer.multiplayer_peer = peer
	is_client = true
	
	print("[MULTIPLAYER] Conectando a %s:%d..." % [host_ip, port])
	return true

## ============================================================================
## CALLBACKS - PEERS
## ============================================================================

func _on_peer_connected(peer_id: int) -> void:
	print("[MULTIPLAYER] Peer conectado: %d" % peer_id)
	peer_connected.emit(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	print("[MULTIPLAYER] Peer desconectado: %d" % peer_id)
	
	# Limpar state do peer
	if peer_id in connected_peers:
		connected_peers.erase(peer_id)
	if peer_id in player_chars:
		player_chars.erase(peer_id)
	
	peer_disconnected.emit(peer_id)

func _on_connected_to_server() -> void:
	print("[MULTIPLAYER] Conectado ao servidor!")
	is_client = true
	connected_to_server.emit()

func _on_connection_failed() -> void:
	print("[MULTIPLAYER] Falha na conexão!")
	is_client = false
	connection_failed.emit()

## ============================================================================
## WORLD STATE - SNAPSHOT/RESTORE
## ============================================================================

## Salva snapshot do estado do mundo (host only)
func get_world_snapshot() -> Dictionary:
	var snapshot: Dictionary = {
		"enemies": {},
		"loot": {},
		"environment": {}
	}
	
	# Snapshot de inimigos
	for enemy_id in enemy_instances.keys():
		var enemy: Enemy = enemy_instances[enemy_id]
		snapshot["enemies"][enemy_id] = {
			"position": enemy.global_position,
			"hp": enemy.hp,
			"rarity": enemy.rarity,
			"biome": enemy.current_biome if enemy.has_meta("current_biome") else "planicie"
		}
	
	# Snapshot de loot
	for drop_id in loot_drops.keys():
		var drop: LootDrop = loot_drops[drop_id]
		snapshot["loot"][drop_id] = {
			"position": drop.global_position,
			"item": drop.item
		}
	
	return snapshot

## Restaura mundo do snapshot (cliente only)
func restore_world_from_snapshot(snapshot: Dictionary) -> void:
	print("[MULTIPLAYER] Restaurando mundo do snapshot...")
	# Implementado na Tarefa 14.3
	pass

## ============================================================================
## DAMAGE TRACKING
## ============================================================================

## Rastreia dano de um player contra um inimigo
func track_damage(enemy_id: int, peer_id: int, damage: float) -> void:
	if enemy_id not in damage_tracker:
		damage_tracker[enemy_id] = {}
	
	damage_tracker[enemy_id][peer_id] = damage_tracker[enemy_id].get(peer_id, 0.0) + damage

## Retorna contribuições de dano para um inimigo
func get_damage_contributors(enemy_id: int) -> Dictionary:
	return damage_tracker.get(enemy_id, {})

## Retorna dano total sofrido por um inimigo
func get_total_damage(enemy_id: int) -> float:
	var total: float = 0.0
	for damage in damage_tracker.get(enemy_id, {}).values():
		total += damage
	return total

## Registra último golpista (kill credit)
func register_kill(enemy_id: int, peer_id: int) -> void:
	kill_credit[enemy_id] = peer_id

## Retorna quem deu o último golpe
func get_killer(enemy_id: int) -> int:
	return kill_credit.get(enemy_id, -1)

## Limpa tracking de um inimigo (ao morrer)
func clear_enemy_tracking(enemy_id: int) -> void:
	damage_tracker.erase(enemy_id)
	kill_credit.erase(enemy_id)

## ============================================================================
## UTILITARIOS
## ============================================================================

## Retorna se está em modo multiplayer
func is_multiplayer() -> bool:
	return is_server or is_client

## Retorna peer_id local
func get_local_peer_id() -> int:
	return multiplayer.get_unique_id()

## Retorna IP local (aproximado)
func get_local_ip() -> String:
	# Simplificado - em produção usaria socket real
	return "192.168.1.100"

## Debug - imprime estado
func debug_print_state() -> void:
	print("\n=== MULTIPLAYER STATE ===")
	print("Is Server: %s" % is_server)
	print("Is Client: %s" % is_client)
	print("Server Running: %s" % server_running)
	print("Connected Peers: %d" % connected_peers.size())
	print("Player Chars: %d" % player_chars.size())
	print("Enemy Instances: %d" % enemy_instances.size())
	print("Loot Drops: %d" % loot_drops.size())
	print("======================\n")
