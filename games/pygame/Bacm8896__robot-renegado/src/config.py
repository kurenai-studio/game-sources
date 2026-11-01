"""Constantes globales de Robot Renegado.

Las estadísticas de unidades, estructuras, drones y mejoras NO viven aquí: se leen de
`src/config/UNITS.py` (fuente única, verificada por `src/verify_balance.py`)."""
from src.config import UNITS as U

# --- Display -----------------------------------------------------------------
WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720
FPS = 60
TITLE = "Robot Renegado"
HUD_FADE_HOLD = 7.0           # s que el reporte de VULCANO y las ayudas de la Base Central quedan visibles ([H] los recupera)
HUD_FADE_TIME = 1.5           # s del desvanecimiento (también al cerrar o saltar la explicación del Mentor VULCANO)

# --- Colores (paleta ciberpunk neon) -----------------------------------------
CYAN = (0, 255, 200)
MAGENTA = (255, 0, 255)
YELLOW = (255, 255, 0)
RED = (255, 50, 50)
DARK_GRAY = (100, 100, 100)
BLACK = (20, 20, 20)
WHITE = (235, 240, 245)
GREEN = (60, 255, 120)
ORANGE = (255, 140, 0)
BG_COLOR = (10, 10, 20)
PANEL_COLOR = (12, 16, 30)

# --- Gameplay ----------------------------------------------------------------
STARTING_METAL_ACT1 = U.RESOURCES["scrap"]["initial_act1"]     # chatarra con la que arranca la campaña
STARTING_METAL_ACT2 = U.RESOURCES["scrap"]["initial_act2"]     # minimo garantizado al iniciar la defensa
ACT2_DEPLOY_BONUS = 40       # chatarra extra al desplegar cada mapa del 2.1 (sin rifle: una torreta de cobertura más)
RESCUE_METAL = 120            # presupuesto al reintentar el sub-acto 2.1
STARTING_ENERGY = U.RESOURCES["energy"]["initial_capacity"]       # capacidad inicial de la red
PLAYER_START_HP = U.PLAYER["hp_base"]
CONTROL_CENTER_HP = U.BUILDINGS["core"]["hp"]
PLAYER_SPEED = U.PLAYER["speed"]                 # px/s
PLAYER_SHOOT_RATE = U.PLAYER["shoot_cooldown"]   # segundos entre disparos
PLAYER_BULLET_DAMAGE = U.PLAYER["shoot_damage"]
PLAYER_BULLET_RANGE = U.PLAYER["shoot_range"]    # px de alcance del disparo del jugador
PLAYER_BULLET_SPEED = U.PLAYER["shoot_speed"]    # px/s
PLAYER_MAG_SIZE = U.PLAYER["ammo_per_mag"]       # cargador del rifle
PLAYER_AMMO_CAPACITY = U.PLAYER["ammo_capacity"] # balas en total (3 cargadores)
PLAYER_RELOAD_TIME = U.PLAYER["reload_time"]     # recarga automatica al vaciarse el cargador
PLAYER_MELEE_RANGE = U.PLAYER["melee_range"]
PLAYER_MELEE_DAMAGE = U.PLAYER["melee_damage"]
PLAYER_MELEE_COOLDOWN = U.PLAYER["melee_cooldown"]
PLAYER_MELEE_KNOCKBACK = U.PLAYER["melee_knockback"]
PLAYER_REGEN_DELAY = U.PLAYER["regen_delay"]
PLAYER_REGEN_RATE = U.PLAYER["regen_rate"]       # hp/s aportados por la IA
PLAYER_HEALTH_BLOCKS = U.PLAYER["health_blocks"]  # bloques de vida del Operador (4 con la Celda Vital)
PLAYER_BLOCK_REGEN = U.PLAYER["block_regen_rate"]  # hp/s con que se rellena el bloque dañado
MEDKIT_MAX = U.MEDKITS["max"]                     # botiquines que caben en el bolsillo del Operador
REPAIR_RANGE = U.PLAYER["repair_range"]          # px: edificios reparables alrededor del jugador
REPAIR_COST = U.PLAYER["repair_cost"]
REPAIR_FRACTION = U.PLAYER["repair_fraction"]
REPAIR_DELAY = U.PLAYER["repair_delay"]
SCRAP_PICKUP_RANGE = U.PLAYER["scrap_pickup_range"]   # tecla E
AUDIO_SFX_VOLUME = 0.6       # volumen general de los efectos (0-1), aparte del de la música
AUTO_COLLECT_DELAY = 6.0     # Acto 2 (Comandante): s que lo caído espera en el suelo antes de que la base lo recoja sola
AUDIO_MUSIC_VOLUME = 0.3     # volumen de la música (0-1)

# --- Dash --------------------------------------------------------------------
DASH_SPEED_MULT = U.PLAYER["dash_speed_mult"]
DASH_DURATION = U.PLAYER["dash_duration"]
DASH_COOLDOWN = U.PLAYER["dash_cooldown"]

# --- Game feel ---------------------------------------------------------------
SHAKE_DURATION = 0.08
SHAKE_MAGNITUDE = (2, 4)      # px de desplazamiento del lienzo
HIT_FLASH_FRAMES = 1
SPARK_COUNT = (3, 5)
SPARK_LIFE = 0.2

# --- Enemigos ----------------------------------------------------------------
ENEMY_MIN_DISTANCE = 30       # px, separacion minima entre enemigos (suelo)
REPULSION_STRENGTH = 6.0      # empuje = (separacion_min - distancia) * fuerza
ENEMY_ATTACK_COOLDOWN = 1.0
KILL_METAL = 0               # la chatarra solo llega por los drops de cada enemigo (UNITS)
PATH_WALL_COST = 12           # coste de "atravesar" una celda con estructura (rodear si hay hueco)

# --- Nivel de alerta y expediciones -----------------------------------------
THREAT_LEVEL_BASE = 1
THREAT_LEVEL_MULTIPLIER = 0.2  # +20% enemigos por nivel sobre la base (las operaciones 2-5 suben la alerta: UNITS.OP_ALERT_CAP)

# --- Chatarra, carroñeros y Fundicion Renegada ------------------------------
SCRAP_DROP_CHANCE = 0.40
SCRAP_VALUE = 25              # metal
SCRAP_COLLECTION_RANGE = 48   # px: magnetismo base del jugador (sin Módulo Imán)
SCRAP_LIFETIME = 30           # segundos
SCAVENGER_SPEED = U.SCAVENGER["speed"]
SCAVENGER_FLEE_MULT = U.SCAVENGER["flee_mult"]
SCAVENGER_HP = U.SCAVENGER["hp"]
SCAVENGER_LATCH_TIME = U.SCAVENGER["latch_time"]    # s acoplado a la chatarra antes de huir
SCAVENGER_SABOTAGE_TIME = U.SCAVENGER["sabotage_time"]
SCAVENGER_DISPATCH_CHANCE = 0.75
SCAVENGER_DELAY = (2.0, 4.0)
FOUNDRY_SCRAP_STEP = 75       # cada 75 de metal robado: Ariete o asedio mas rapido
FOUNDRY_INTERVAL_STEP = 0.85  # factor sobre el intervalo de asedio
FOUNDRY_MIN_INTERVAL = 0.5    # factor minimo acumulado
INTERCEPT_WEAKNESS_STEP = 750 # metal interceptado para debilitar del todo (-40% enemigos)

# --- Oleadas (Acto 2) --------------------------------------------------------
TOTAL_WAVES_ACT2 = 5
WAVE_DURATION = 45            # segundos de referencia por oleada
WAVE_SPAWN_RATE = 3           # segundos entre apariciones
WAVE_SIZE_MULTIPLIER = U.WAVES["size_multiplier"]   # x enemigos por oleada; llegan en lotes dentro de WAVE_DURATION
PREPARATION_TIME = 20         # segundos para construir
PREP_DISCOUNT = 0.5
BREAK_TIME = 12.0             # Balance P1: 12 s reales de respiro entre oleadas (antes 4)
ASSAULT_RAID_INTERVAL = 25.0  # tras la oleada 5 la Fundicion sigue enviando incursiones
ASSAULT_RAID_SIZE = 0.4       # tamaño de esas incursiones respecto a la oleada 5

# --- Base Central y componentes del chasis de AURA ------------------------------
CHASSIS_TOTAL_PARTS = 6       # componentes que completan el chasis de combate de AURA
CHASSIS_INSTALL_COST = 0      # montar un componente es gratis: el coste real es extraerlo con vida
CHASSIS_HP_BONUS = 10         # vida maxima del piloto por componente instalado
BASE_REPAIR_METAL_PER_HP = 0.2
DEMOLISH_REFUND = U.SELL_REFUND
CAMERA_PAN_SPEED = 520        # px/s al desplazar la camara en la fase estrategica

# --- Mapa del Acto 2 ---------------------------------------------------------
ACT2_CC_POS = (420, 600)
ACT2_FOUNDRY_POS = (1880, 600)
ACT2_SPAWN_ZONE = (1600, 330, 130, 540)
ACT2_DEPOSIT_OFFSETS = ((220, -190), (220, 200), (-230, -260))
ACT2_W, ACT2_H = 2200, 1200
FOUNDRY_HP_CORE = U.FOUNDRY["core_hp"]
FOUNDRY_TURRETS = 6
FOUNDRY_WALL_HP = U.FOUNDRY["wall_hp"]
FOUNDRY_TURRET_HP = U.FOUNDRY["turret_hp"]
FOUNDRY_TURRET_RANGE = U.FOUNDRY["turret_range"]
FOUNDRY_TURRET_DAMAGE = U.FOUNDRY["turret_damage"]
FOUNDRY_TURRET_DELAY = U.FOUNDRY["turret_delay"]

# --- Construccion ------------------------------------------------------------
BUILD_GRID = 40
BUILD_DELAY = 0.12
POWER_RADIUS = U.BUILDINGS["pylon"]["range"]    # alcance de los pilones (y del Centro de Control)
PYLON_COST = U.BUILDINGS["pylon"]["cost"]
DEPOSIT_METAL = 300
EXTRACTOR_INCOME = U.BUILDINGS["extractor"]["income"]
EXTRACTOR_INTERVAL = U.BUILDINGS["extractor"]["interval"]
EXTRACTOR_COST = U.BUILDINGS["extractor"]["cost"]
ENERGY_CORE = U.BUILDINGS["core"]["energy_output"]          # capacidad de energía que aporta el Centro de Control
ENERGY_PYLON = U.BUILDINGS["pylon"]["energy_output"]
SELL_REFUND = U.SELL_REFUND
STUN_TIME = 1.0
STUN_SPEED_FACTOR = 0.3

# --- Drones aliados (Viper, Magneto, Aegis): estadísticas en UNITS.DRONES -------------------

# --- Acto 1: campaña por sub-actos ---------------------------------------------
LEVEL_CELL = 40               # px por celda en los mapas de los sub-actos
INTERACT_RADIUS = 80          # px para interactuar con E
AGGRO_RADIUS = 460
DEAGGRO_RADIUS = 760
AURA_CHARGE_TIME = 90         # s que AURA necesita en el sub-acto 1.3
SUPPLY_METAL_1_3 = 400        # metal minimo de suministro para el tutorial de fortificacion

# --- Ariete Ligero (mini-jefe del 1.2) -------------------------------------------
RAM_LIGHT_HP = U.LIGHT_RAM["hp"]
RAM_TRIGGER = U.LIGHT_RAM["trigger"]             # px a los que empieza a embestir
RAM_WINDUP = U.LIGHT_RAM["windup"]               # s de aviso antes de la embestida
RAM_CHARGE_SPEED = U.LIGHT_RAM["charge_speed"]
RAM_STUN = U.LIGHT_RAM["stun"]                   # s aturdido tras chocar con un muro
RAM_CONTACT_DAMAGE = U.LIGHT_RAM["contact_damage"]
RAM_REAR_MULT = U.LIGHT_RAM["rear_mult"]         # daño a su radiador trasero (crítico)
RAM_FRONT_MULT = U.LIGHT_RAM["front_mult"]       # blindaje frontal
RAM_SIDE_MULT = U.LIGHT_RAM["side_mult"]         # blindaje lateral
RAM_REAR_ARC = U.LIGHT_RAM["rear_arc"]           # grados (desde el frente) del arco trasero: 135-225
RAM_SMOKE_BELOW = U.LIGHT_RAM["smoke_below"]     # fracción de vida bajo la cual humea el radiador

# --- VULCANO (IA de mantenimiento) -----------------------------------------------
VULCANO_THRESHOLD = U.VULCANO["threshold"]          # repara estructuras por debajo del 50% de vida
VULCANO_REPAIR_RATE = U.VULCANO["repair_rate"]      # hp/s, sobre UNA estructura a la vez (cola de prioridad)
VULCANO_METAL_PER_HP = U.VULCANO["scrap_per_hp"]    # los 3 muros de demostración del 1.4 cuestan ~80 de chatarra
VULCANO_SPEED = U.VULCANO["speed"]                # px/s hasta el sitio de obra (Base Central)
VULCANO_WORK_RANGE = U.VULCANO["work_range"]      # a cuántos px del borde del sitio empieza a ensamblar
VULCANO_SCRAP_RESERVE = U.VULCANO["scrap_reserve"]  # con 25 de chatarra o menos, VULCANO no repara
BUNKER_RESERVE = 60           # metal de la reserva del búnker al reactivar a VULCANO

# --- Incursiones jugables (expediciones desde la Base Central) -----------------------
INCURSION_LEVEL_START = 1
INCURSION_COLS, INCURSION_ROWS = 60, 36          # celdas del mapa exterior (2400 x 1440 px)
INCURSION_ENEMY_SCALE = 0.10                     # +10% de vida y dano por nivel
INCURSION_DEPOSITS = 3                           # alijos de chatarra por incursion
INCURSION_LOOT_RANGE = (120, 180)                # metal por alijo a nivel 1 (multiplos de 5)
INCURSION_LOOT_TOTAL = (350, 500)                # metal de los alijos de una incursion completa a nivel 1
INCURSION_LOOT_GROWTH = 0.25                     # +25% de botin por nivel
INCURSION_SCRAP_GROWTH = 0.10                    # +10% de valor de la chatarra por nivel
INCURSION_SCRAP_DROP = 0.40
INCURSION_PART_BASE = 0.10                       # probabilidad de soltar una pieza del chasis
INCURSION_PART_GROWTH = 0.05
INCURSION_PART_MAX = 0.60
INCURSION_DEATH_KEEP = 0.5                       # fraccion del botin que se conserva al morir
INCURSION_EXTRACT_TIME = 1.5                     # s sobre la baliza para extraer
INCURSION_VISION = 420                           # px de vision (niebla de guerra)
# Infiltración Tecnológica: una cámara fuerte en un nido enemigo guarda el Módulo de Mando del Búnker
INCURSION_TECH_VAULT_LOOT = (150, 200)           # chatarra que suelta la cámara además del módulo (multiplos de 5)
INCURSION_TECH_HACK_TIME = 5.0                   # s cerca de la cámara para abrirla
INCURSION_TECH_HACK_RADIUS = 90                  # px de la cámara dentro de los que avanza el hackeo
INCURSION_TECH_NEST_EXTRA = 3                    # guardias del nido por encima del tamaño normal de grupo
INCURSION_TECH_NEST_BOOST = 2                    # el nido sale con la composición de 2 niveles por encima
INCURSION_TECH_NEST_HEAVY = 2                    # mínimo de unidades no-scout en el nido (guardia pesada desde el nivel 1)
