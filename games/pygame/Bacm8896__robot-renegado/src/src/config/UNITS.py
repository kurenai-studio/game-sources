"""Diccionario maestro de estadísticas de Robot Renegado (Biblia del Juego, versión 3.0).

Es la ÚNICA fuente de números de unidades, estructuras, drones, recursos y mejoras: Enemy, Building, los drones,
Player, ResourceManager y config.py leen de aquí, nunca llevan cifras propias. `src/verify_balance.py` compara este
archivo con la tabla de la Biblia y avisa de cualquier discrepancia.

Convenciones: distancias en px, tiempos en s, velocidades en px/s. Recursos: Chatarra ("cost", = metal del juego),
Núcleos de Plasma ("cores") y Energía ("energy": consumo de la torreta contra la capacidad de la red). Las claves
marcadas con `# (derivado)` no las fija la Biblia: son valores de diseño necesarios para que la mecánica funcione.
"""

# --- Recursos ------------------------------------------------------------------------
# Economía separada: cada recurso tiene UN uso y ningún método mezcla los pools (ResourceManager lo hace cumplir).
#   Chatarra (scrap)      -> moneda táctica del mapa: construir estructuras in situ, mejorar muros, rutas y reparar.
#   Núcleos de Plasma     -> exclusivos del árbol de habilidades del Operador (desbloqueos del traje).
#   Aleación Militar      -> exclusiva del Terminal Táctico: mejoras permanentes de drones (y, en el futuro,
#                            especializaciones de torretas). Persiste en CampaignRun.
RESOURCES = {
    "scrap": {"name": "Chatarra", "symbol": "⚙", "initial_act1": 150, "initial_act2": 100, "use": "tactical"},
    "cores": {"name": "Núcleos Plasma", "symbol": "🔷", "initial": 0, "use": "operator_tree"},
    "alloy": {"name": "Aleación Militar", "symbol": "▣", "initial": 0, "use": "terminal"},
    "energy": {"name": "Energía", "symbol": "⚡", "initial_capacity": 50},
}
# Conversión al separar la economía (derivado): cada núcleo que costaba una compra táctica pasa a +20 de chatarra, y
# cada nodo del árbol cuesta sus núcleos de antes + 1 por cada 50 de chatarra que costaba.
CORE_TO_SCRAP = 20
# Fuentes de Aleación Militar (derivado, mínimas mientras llegan sus usos futuros): +1 por base enemiga destruida
# (ENEMY_BASES["destroy_reward"]) y +2/+3/+4 la primera vez que se gana cada mapa (CAMPAIGN_MAP_ALLOY).

# Consumo de energía por torreta ACTIVA (y capacidad que aporta cada nodo de la red: ver BUILDINGS[...]["energy_output"])
ENERGY_COSTS = {"twin_autocannon": 5, "balista": 12, "tesla": 15, "lanzallamas": 8}

# Qué suelta cada enemigo al morir: chatarra (rango y probabilidad), Núcleos de Plasma y caja de munición.
ENEMY_DROPS = {
    "scout": {"scrap": (3, 5), "scrap_chance": 0.40, "cores": 0, "core_chance": 0.0, "ammo_prob": 0.3},
    "soldier": {"scrap": (8, 12), "scrap_chance": 0.40, "cores": 0, "core_chance": 0.0, "ammo_prob": 0.3},
    "ariete": {"scrap": (25, 35), "scrap_chance": 0.50, "cores": (1, 1), "core_chance": 0.50, "ammo_prob": 0.4},
    "tank": {"scrap": (50, 70), "scrap_chance": 0.50, "cores": (2, 2), "core_chance": 0.50, "ammo_prob": 0.4},
}

# Tablero de incursiones del Terminal Táctico: 5 operaciones en cadena. Superar una abre la siguiente (1 -> 2 -> 3 -> 4 -> 5)
# y las superadas se pueden repetir siempre (farmeo de chatarra, aleación y núcleos). La primera vez que se supera una
# operación: su bono de misión, +1 al nivel de incursión (desbloqueos) y, desde la Op 2, +1 de alerta (tope OP_ALERT_CAP).
# Todo el botín (también núcleos, aleación, el Módulo y los planos) va en riesgo hasta extraer con vida. (derivado)
#   "level": dificultad de los enemigos (+10% por nivel); "replay_level": la de las repeticiones si cambia.
#   objetivos: loot (saquear los alijos) · drill (defender el taladro) · convoy (abatir los Arietes antes de que escapen) ·
#              hack (hackear la terminal del nido) · timed (saquear los alijos antes de que acabe el tiempo).
INCURSION_OPS = {
    "recon": {"index": 1, "name": "Reconocimiento de Perímetro", "level": 1, "layout": "eco", "objective": "loot",
              "summary": "Saquea los 3 depósitos de chatarra (solo Scouts) y extrae.",
              "loot_text": "350-500 de chatarra · 1-3 núcleos (alijo de plasma)", "first_bonus": 100},
    "drill": {"index": 2, "name": "Saqueo de Yacimiento", "level": 1, "replay_level": 2, "layout": "tech", "objective": "drill",
              "summary": "Activa el taladro y defiéndelo 90 s de las oleadas; luego extrae.",
              "loot_text": "150-220 de chatarra · 1-2 núcleos", "first_bonus": 75,
              "drill_time": 90.0, "drill_hp": 900, "wave_every": 15.0, "scrap": (150, 220), "cores": (1, 2)},
    "convoy": {"index": 3, "name": "Intercepción de Convoy Blindado", "level": 2, "layout": "eco", "objective": "convoy",
               "summary": "Abate los 2 Arietes escoltados antes de que lleguen a su salida.",
               "loot_text": "250-350 de chatarra pesada · 2-3 núcleos", "first_bonus": 75,
               "rams": 2, "escorts": 3, "ram_hp_mult": 0.6, "ram_speed_mult": 0.5, "scrap": (250, 350), "cores": (2, 3)},
    "tech": {"index": 4, "name": "Infiltración en Complejo Tecnológico", "level": 3, "layout": "tech", "objective": "hack",
             "summary": "Hackea la terminal del nido, custodiada por Tanques, y extrae.",
             "loot_text": "Planos de Fábrica + Módulo · 2 aleación · 2 núcleos", "first_bonus": 75,
             "tanks": 2, "cores": (2, 2), "alloy": 2},
    "recovery": {"index": 5, "name": "Recuperación Crítica", "level": 3, "layout": "eco", "objective": "timed",
                 "summary": "Saquea los 3 alijos en 3 min, con guardia reforzada, y extrae.",
                 "loot_text": "Alijos + 4-5 núcleos · 2 aleación", "first_bonus": 75,
                 "time_limit": 180.0, "extra_guards": 2, "cores": (4, 5), "alloy": 2},
}
OPS_ORDER = sorted(INCURSION_OPS, key=lambda k: INCURSION_OPS[k]["index"])
OP_ALERT_CAP = 2                      # la alerta del asedio sube como mucho +2 por superar operaciones (igual que las 2 expediciones)

# Puntos de plasma de las incursiones (son puntos del MAPA que se capturan, no edificios del jugador): alijos especiales
# (1-3 Núcleos) y extractores de plasma enemigos (+5, peligrosos). Los Núcleos nunca los genera un edificio.
PLASMA_POINTS = {
    "cache_cores": (1, 3), "extractor_cores": 5,
    "capture_time": 4.0, "capture_radius": 70,          # (derivado) hay que mantenerse en el punto
    "extractor_min_level": 2, "guard_extra": 2,         # (derivado) aparece desde el nivel 2 con 2 guardias pesados extra
    "boss_core_drop": 1,                                # (derivado) el Ariete Ligero del 1.2 suelta 1 Núcleo seguro
}

# --- Escala de las unidades -------------------------------------------------------------------------------
# Todas las unidades (Operador, Scout, Soldado, Ariete, Tanque y Carroñero) miden un 17% menos que en la versión
# anterior, en colisión y en sprite: despeja los pasillos y se leen mejor en pantalla. Los centros no cambian (todo se
# dibuja y colisiona alrededor de `pos`). Las medidas de hitbox de aquí abajo ya están escaladas.
ENTITY_SCALE = 0.83


def scaled(px):
    """Medida en píxeles de la versión anterior -> la actual (redondeada, mínimo 1)."""
    return max(1, round(px * ENTITY_SCALE))


# --- Operador --------------------------------------------------------------------
PLAYER_STATS = PLAYER = {
    "hp_base": 100, "speed": 300,
    "ammo_capacity": 150, "ammo_per_mag": 50, "reload_time": 0.8,          # Acto 2+: 3 cargadores de 50
    "shoot_range": 270, "shoot_damage": 12, "shoot_cooldown": 0.15, "shoot_speed": 600,
    # Clic izquierdo: disparo (sin munición, también golpea). Clic derecho en las escenas del Operador (Acto 1 e
    # incursiones): golpe cuerpo a cuerpo hacia el cursor, con o sin munición: 25 de daño, alcance 70, empuje 50, uno cada
    # 0,4 s. En el nivel de los drones (Acto 2) el clic derecho es para ellos (reservado a órdenes de escuadrón).
    "melee_range": 70, "melee_damage": 25, "melee_cooldown": 0.4, "melee_knockback": 50,
    "dash_speed_mult": 2.8, "dash_duration": 0.15, "dash_cooldown": 1.4,
    "repair_range": 100, "repair_cost": 6, "repair_fraction": 0.25, "repair_delay": 0.25,
    "regen_delay": 3.0, "regen_rate": 2.5,     # AURA: +2,5 HP/s extra; toda regeneración espera 3,0 s seguidos sin daño
    # Vida segmentada: la vida máxima se reparte en `health_blocks` bloques. El daño parcial de un bloque se regenera solo
    # (block_regen_rate HP/s, más la de AURA y los rewards) tras regen_delay s sin daño; un bloque vaciado del todo se
    # pierde y solo lo devuelve un botiquín. La Celda Vital (Supervivencia, nivel 4) añade un 4º bloque.
    "health_blocks": 3, "block_regen_rate": 5.0,          # (derivado) 5 HP/s: un bloque de 33 HP en ~7 s
    # Asistencia de apuntado: si el cursor queda a menos de `aim_assist_cone` grados de un enemigo dentro del alcance del
    # rifle, la bala se corrige magnéticamente hacia él (el más alineado; a igualdad, el más cercano).
    "aim_assist_cone": 15,
    "scrap_pickup_range": 120,          # (derivado) alcance de la tecla E para recoger chatarra y núcleos
    "hitbox_radius": 11,                # (derivado) colisión física circular: 13 x 0,83 (el sprite: 100 -> 83 px)
}

# Botiquines del Operador: se guardan en el bolsillo (máximo `max`, persisten en la campaña) y [H] consume uno para
# devolver un bloque de vida perdido. Salen de los alijos de las incursiones y como botín de los enemigos. (derivado)
MEDKITS = {
    "max": 5, "key": "H", "lifetime": 30.0,
    "cache_chance": 0.6,                  # depósito de chatarra saqueado: 60% de un botiquín
    "vault_count": 1,                     # cámara fuerte (Infiltración Tecnológica) y alijo de plasma: 1 seguro
    "enemy_chance": {"scout": 0.03, "soldier": 0.08, "ariete": 0.15, "tank": 0.20},
}

# Árbol de mejoras del Operador (Terminal Táctico, persistente en CampaignRun). DOS ramas lineales (3 y 4 nodos), pagadas
# SOLO con Núcleos de Plasma (cost = chatarra = 0): cada nodo exige haber comprado el anterior de su rama. El golpe cuerpo a
# cuerpo de emergencia (clic derecho) no tiene mejoras.
#   Ofensiva · Balística:    A1 Gatillo Automático (1) -> A2 Calibre Perforante I (3) -> A3 Sobrecarga Balística (5)
#   Supervivencia · Exotraje: B1 Impulso Doble (1) -> B2 Blindaje de Titanio (3) -> B3 Celda Vital I (4): 4º bloque de vida
#                             -> B4 Celda Vital II (6): 5º bloque de vida.  Total del árbol: 9 + 14 = 23 Núcleos.
# (La Nanoregeneración Acelerada se retiró: las partidas que la tenían recuperan sus 3 Núcleos, ver LEGACY_NODE_REFUND.)
OPERATOR_TREE = {
    "gatillo_automatico": {"branch": "offensive", "tier": 1, "label": "Gatillo Automático", "cost": 0, "cores": 1,
                           "requires": None, "desc": "Mantén el clic izquierdo y el rifle dispara solo, a máxima cadencia",
                           "effect": "Fuego continuo · 1 disparo cada 0,15 s"},
    "calibre_perforante": {"branch": "offensive", "tier": 2, "label": "Calibre Perforante I", "cost": 0, "cores": 3,
                           "requires": "gatillo_automatico", "desc": "Munición de mayor calibre: más daño y atraviesa",
                           "effect": "Daño 12 -> 16 · perfora 1 enemigo más"},
    "sobrecarga_balistica": {"branch": "offensive", "tier": 3, "label": "Sobrecarga Balística", "cost": 0, "cores": 5,
                             "requires": "calibre_perforante", "desc": "El rifle trabaja al límite de su mecanismo",
                             "effect": "Daño 20 · 1 disparo cada 0,12 s"},
    "impulso_doble": {"branch": "survival", "tier": 1, "label": "Impulso Doble", "cost": 0, "cores": 1,
                      "requires": None, "desc": "Dos cargas de Dash en rápida sucesión, cada una con su i-frame y su recarga",
                      "effect": "2 cargas de Dash independientes"},
    "blindaje_titanio": {"branch": "survival", "tier": 2, "label": "Blindaje de Titanio", "cost": 0, "cores": 3,
                         "requires": "impulso_doble", "desc": "Placas de titanio: cada impacto pierde fuerza",
                         "effect": "+4 de armadura plana pasiva"},
    "celda_vital": {"branch": "survival", "tier": 3, "label": "Celda Vital I", "cost": 0, "cores": 4,
                    "requires": "blindaje_titanio", "desc": "Una celda de energía extra en el exotraje: un bloque de vida más",
                    "effect": "4º bloque de vida (133 HP en total)"},
    "celda_vital_2": {"branch": "survival", "tier": 4, "label": "Celda Vital II", "cost": 0, "cores": 6,
                      "requires": "celda_vital", "desc": "Segunda celda de energía: el exotraje aguanta otro bloque completo",
                      "effect": "5º bloque de vida (166 HP en total)"},
}
UPGRADES_TREE = {
    "offensive": ["gatillo_automatico", "calibre_perforante", "sobrecarga_balistica"],
    "survival": ["impulso_doble", "blindaje_titanio", "celda_vital", "celda_vital_2"],
}
OPERATOR_EFFECTS = {
    "rifle_damage_tier2": 16, "rifle_damage_tier3": 20,   # daño del rifle con A2 y A3 (base: PLAYER["shoot_damage"] = 12)
    "rifle_pierce_tier2": 2,                              # objetivos que atraviesa con A2/A3 (1 adicional; base 1)
    "overload_cooldown": 0.12,                            # A3: segundos entre disparos (base PLAYER["shoot_cooldown"] = 0,15)
    "dash_charges": 2,                                    # B1: cargas de Dash (base 1), con recarga independiente
    "flat_armor": 4,                                      # B2: armadura plana por impacto
    "extra_blocks": 1,                                    # B3 / B4 Celda Vital I y II: +1 bloque de vida cada una (3 -> 4 -> 5)
    "vital_cells": ("celda_vital", "celda_vital_2"),
}

# Árbol anterior (partidas guardadas): al cargar, los nodos que ya no existen se devuelven en Núcleos (su coste de entonces) y
# el Disparador Automático se conserva como Gatillo Automático. Solo se usa en CampaignRun.from_dict.
LEGACY_OPERATOR_NODES = {"disparador_automatico": "gatillo_automatico"}
LEGACY_NODE_REFUND = {"nanoregeneracion": 3, "modulo_iman": 3, "cargadores_ampliados": 3, "cadencia_extrema": 3, "radio_magnetico": 3,
                      "velocidad_reparacion": 1, "sobre_escudo": 3, "armadura_ligera": 2, "blindaje_reactivo": 3,
                      "regeneracion_mejorada": 5, "placas_reactivas": 4, "extension_escudo": 6}

# Bonus de cada nodo en el vocabulario del UpgradeManager (P5). Es una vista de lo que ya hacen los nodos: las cifras que
# coinciden con OPERATOR_EFFECTS las comprueba verify_balance. "name" = identificador público del nodo en la UI/tests.
OPERATOR_BONUSES = {
    "gatillo_automatico": {"name": "Gatillo_Automatico", "bonus": {"auto_fire": True}},
    "calibre_perforante": {"name": "Calibre_Perforante_I", "bonus": {"bullet_damage": 4, "bullet_pierce": 1}},
    "sobrecarga_balistica": {"name": "Sobrecarga_Balistica", "bonus": {"bullet_damage": 4, "fire_cooldown": 0.12}},
    "impulso_doble": {"name": "Impulso_Doble", "bonus": {"dash_charges": 1}},
    "blindaje_titanio": {"name": "Blindaje_Titanio", "bonus": {"flat_armor": OPERATOR_EFFECTS["flat_armor"]}},
    "celda_vital": {"name": "Celda_Vital_I", "bonus": {"health_blocks": OPERATOR_EFFECTS["extra_blocks"]}},
    "celda_vital_2": {"name": "Celda_Vital_II", "bonus": {"health_blocks": OPERATOR_EFFECTS["extra_blocks"]}},
}
# Nodo de recompensa (P4) -> id público del nodo en el árbol de la UI
REWARD_NODE_NAMES = {"PLAYER_UPGRADE_1": "Armor_Light", "PLAYER_UPGRADE_2": "Speed_Boost", "PLAYER_UPGRADE_3": "Extended_Ammo",
                     "PLAYER_UPGRADE_4": "Regen_Enhanced", "PLAYER_UPGRADE_5": "Vision_Tactical",
                     "PLAYER_UPGRADE_6": "Health_Reinforced"}

# --- Chasis de AURA (Prioridad 2): utilidad de los componentes instalados en la Base Central -----------------
AURA_CHASSIS = {
    "scan_parts": 3,          # 3/6: escaneo táctico (el radar marca todos los depósitos, el alijo y el extractor de plasma)
    "drone_parts": 6,         # 6/6: AURA combate en el Acto 2 como dron autónomo
}

# --- V.U.L.C.A.N.O.: auto-reparación de la base ------------------------------------------------------------
# Repara UNA estructura a la vez a `repair_rate` HP/s, solo las que bajaron del `threshold` de su vida (y hasta dejarlas
# completas), pagando `scrap_per_hp` de chatarra proporcional a dt. Se detiene en seco si la chatarra queda en
# `scrap_reserve` o menos: nunca la deja negativa ni se come la reserva básica del jugador. Orden de prioridad:
#   1) Centro de Control  2) red activa: pilones y torretas  3) bloqueo: muros y compuertas  4) el resto.
# Dentro de cada nivel, primero la que tenga menos vida (proporción).
VULCANO = {
    "repair_rate": 80, "threshold": 0.5, "scrap_per_hp": 0.095, "scrap_reserve": 25,   # 80 HP/s: sin cuello de botella
    "speed": 170, "work_range": 70,     # (derivado) VULCANO como constructor de la Base Central: px/s y alcance de obra
    "priority": (("core",), ("pylon", "tower", "balista"), ("wall", "compuerta")),
}

# --- Sub-acto 1.4 (Prioridad 2): proteger a VULCANO mientras suelda la compuerta del búnker --------------------
VULCANO_DEFENSE = {
    "duration": 25.0, "vulcano_hp": 200, "cinematic": 2.0,
    # Fase 6: la oleada es FIJA ("fixed_profile"); los muros reparados ya no la agrandan: dan cobertura. Cada muro del
    # búnker que estaba reparado al empezar y sigue en pie hace que los rezagados reciban +5% de daño (3 muros = +15%).
    "fixed_profile": "medium",
    "cover_bonus_per_wall": 0.05,
    # Escudo de gracia: VULCANO no recibe daño durante la cinemática y los `grace_time` s siguientes (da tiempo a ponerse a
    # su lado); después es vulnerable. Por debajo de `low_hp_warning` de su vida avisa una vez y su barra pasa a rojo.
    "grace_time": 3.0, "low_hp_warning": 0.3,   # (derivado)
    "profiles": {
        "small": {"scout": 4},
        "medium": {"scout": 6, "soldier": 1},
        "large": {"scout": 8, "soldier": 2, "light_ram": 1},
    },
    "second_group_at": 10.0,  # (derivado) la mitad de los rezagados llega al principio y el resto a los 10 s
    # Escape interactivo (Bloque 3.A): al terminar la soldadura entra una horda masiva y hay que evacuar por la compuerta.
    "final_horde": {"scout": 8, "soldier": 3},
    "overload_line_at": 5.0,  # segundos tras el inicio de la soldadura: VULCANO avisa del sobrecalentamiento
}

# Sistema de munición: Acto 1 infinita y semiautomática (1 clic = 1 disparo); Acto 2+ limitada en cargadores.
AMMO_SYSTEM = {
    "infinite_act1": True,
    "limited_act2_plus": True,
    "crit_threshold_low": 30,           # < 30 balas: HUD amarillo
    "crit_threshold_critical": 10,      # < 10 balas: HUD rojo + mensaje
    "ammo_drop_chance": 0.30,           # probabilidad base de caja de munición (cada enemigo: ENEMY_DROPS[...]["ammo_prob"])
    "ammo_drop_amount": 50,             # balas por caja
    "box_lifetime": 30.0,               # (derivado) segundos que dura la caja en el suelo
}

# Rescates anti-softlock: si falta chatarra para la tarea del sub-acto, aparecen alijos.
RESCUES = {
    "vulcano_sub_1_4": {
        "trigger_scrap_less_than": 80,  # umbral de CHATARRA a la entrada del 1.4 (antes "trigger_ammo_less_than")
        "alijo_1_amount": 100,
        "alijo_2_amount": 50,
    }
}

# --- Enemigos ----------------------------------------------------------------------
ENEMIES = {
    # Scout: flanqueador cuerpo a cuerpo. Su contacto es CONTINUO (melee_dps * dt mientras toca al Operador, a un dron o
    # a una estructura). Lejos converge con un leve desvío; en rango medio rodea (componente tangencial) buscando el
    # costado o la espalda; cerca va directo a morder.
    "scout": {
        "hp": 45, "armor": 0, "speed": 180, "melee_dps": 8, "contact": "continuous",
        "attack_cooldown": 1.0,         # (derivado) solo para el contacto por golpes (sin dt)
        "flank_angle": 22,              # (derivado) desvío con el que se acerca desde lejos
        "flank_far": 320, "flank_close": 70, "orbit_strength": 1.2,   # (derivado) banda de rodeo y fuerza tangencial
        # (derivado) contra una estructura (el Centro de Control) rodea mucho menos: con 1,2 los Scouts daban la vuelta a la
        # base y entraban por donde no hay torretas (balance_sim alerta 3: medio y grande caían en las oleadas 2-3).
        # Con 0,3 la defensa queda como antes (grande supera las 5; medio cae en la 5) y contra el Operador rodean a fondo.
        "orbit_strength_structures": 0.3,
        "size": 15,                     # 18 x 0,83
    },
    # Soldado: tirador. Debe entrar en el alcance del Operador (270) para abrir fuego: 160 px. Ráfagas de 3 balas de 12
    # (cada 0,12 s) y 2 s de pausa en la que mantiene la distancia o se desplaza de lado.
    # Nerf de los enemigos a distancia: -20% de vida (180 -> 144) y -18% de alcance (195 -> 160).
    "soldier": {
        "hp": 144, "armor": 4, "speed": 100, "range": 160, "burst": 3, "shot_damage": 12,
        "burst_gap": 0.12, "burst_cooldown": 2.0,
        "reposition_speed": 0.6, "keep_min": 0.7,   # (derivado) en la pausa: 60% de velocidad; retrocede si < 70% del alcance
        "melee_dps": 12, "attack_cooldown": 1.0,    # (derivado) si le tocan
        "size": 22,                     # 26 x 0,83
    },
    "ariete": {
        # Ajuste de balance: con 950 HP y -80% de frente era inmortal para las defensas estándar; ahora 680 HP y -45%
        # (fuego concentrado de torretas y drones lo derriba)
        "hp": 680, "armor": 0, "front_reduction": 0.45, "weak_mult": 3.0,
        "speed": 70, "charge_speed": 220, "impact": 300,
        "front_arc": 60,                # (derivado) semiángulo del "frente": de frente x0,55; costados y espalda x3
        "charge_trigger": 320, "windup": 0.5, "recover": 1.2, "impact_vs_units": 40,   # (derivado)
        # (derivado) durante la preparación apenas gira (120 °/s: 60° como mucho en 0,5 s) y embiste hacia donde quedó
        # mirando; durante la embestida no gira nada: sin correcciones antinaturales de trayectoria.
        "windup_turn_rate": 120,
        "melee_dps": 40, "attack_cooldown": 1.0,    # (derivado)
        "size": 38,                     # 46 x 0,83
    },
    "tank": {                           # nerf a distancia: -20% de vida (1400 -> 1120) y -18% de alcance (380 -> 312)
        "hp": 1120, "armor": 8, "speed": 45, "range": 312, "cannon_damage": 120, "cannon_cooldown": 3.5,
        "splash_radius": 70, "shell_speed": 360, "player_splash": 0.5,   # (derivado) contra el Operador el obús hace la mitad
        # Torreta pesada: gira como mucho 65 °/s (180° en 2,77 s). Solo dispara alineado (8°) y tras apuntar 0,8 s con el
        # punto de impacto ya fijado (aviso en pantalla): da margen para salir con el Dash. (derivado)
        "turn_rate": 65, "aim_time": 0.8, "aim_tolerance": 8,
        "melee_dps": 25, "attack_cooldown": 1.0,    # (derivado)
        "size": 33,                     # 40 x 0,83
    },
}

# Navegación de los enemigos entre muros de nivel (las estructuras del jugador no: contra ellas chocan y las atacan). (derivado)
#  - Colisión: el choque contra un muro se resuelve por la normal del punto de contacto; la componente de la velocidad a lo
#    largo de la pared se conserva (fricción tangencial cero): desliza hacia el espacio libre, nunca se clava de frente.
#  - Bigotes: dos rayos a ±`whisker_angle`° del rumbo, de `whisker_len` px más allá del cuerpo. Si solo uno toca muro, el
#    rumbo gira suavemente (`whisker_turn`°, el doble si el muro está a menos de la mitad) hacia el lado libre.
#  - Persecución: con la recta al objetivo bloqueada sigue el campo de flujo (mirando hasta `lookahead` celdas por delante);
#    el Scout solo rodea (flanqueo) cuando tiene línea de visión limpia.
#  - Desatasco: si en `stuck_time` s su avance neto no llega al `stuck_ratio` de lo que intentó, se desvía de forma sostenida
#    entre `unstick_angle` grados durante `unstick_time` s (esquinas cóncavas y atascos con vibración).
ENEMY_STEERING = {"whisker_angle": 30, "whisker_len": 30, "whisker_turn": 25, "lookahead": 4,
                  "stuck_time": 0.4, "stuck_ratio": 0.2, "unstick_time": 0.7, "unstick_angle": (45, 90)}

# Carroñero (no ataca al Operador). Prioridades: 1) chatarra (o núcleos) del suelo: va al botín más cercano, se acopla
# `latch_time` s (ventana para derribarlo) y se lo lleva; 2) si no queda botín en el suelo, va al pilón más cercano y al
# tocarlo lo apaga `sabotage_time` s; 3) con lo robado (o tras sabotear) huye por el borde del mapa más cercano.
# Si cae antes de escapar suelta lo robado (stolen_scrap) más su drop base.
SCAVENGER = {
    "hp": 25, "armor": 0, "speed": 250, "flee_mult": 1.3, "latch_time": 1.2,
    "sabotage_time": 8.0,               # segundos exactos que un pilón saboteado queda apagado
    "rescan": 0.25,                     # (derivado) cada cuánto reevalúa el botín más cercano
    "contact_radius": 20,               # (derivado) distancia a la que alcanza el botín o el pilón
    "base_drop": (3, 5),                # (derivado) chatarra propia que suelta siempre al caer
}

# --- Trasfondo (lore) oficial de las dos inteligencias aliadas ------------------------
LORE = {
    "AURA": {"acronym": "A.U.R.A.", "full": "Arquitectura Unificada de Reconocimiento y Análisis"},
    "VULCANO": {"acronym": "V.U.L.C.A.N.O.",
                "full": "Vector de Unión, Logística y Construcción de Activos Nucleares y Operativos"},
}


def lore_title(name):
    """«A.U.R.A. // Arquitectura Unificada de Reconocimiento y Análisis» (subtítulos de la interfaz)."""
    return f"{LORE[name]['acronym']} // {LORE[name]['full']}"


def lore_intro(name):
    """«A.U.R.A. (Arquitectura Unificada de Reconocimiento y Análisis)»: la sigla con el desglose en su primera intervención."""
    return f"{LORE[name]['acronym']} ({LORE[name]['full']})"


# Capacidad dinámica de la flota: CADA Fábrica de Drones operativa (en pie, ensamblada y conectada a la red) suma 8 al
# límite de drones vivos en el mapa (1 fábrica = 8, 2 = 16...). El límite cuenta los drones de todas las fábricas: vender y
# reconstruir una no lo reinicia. Si una fábrica cae, sus drones sobreviven, pero no se fabrican reemplazos mientras la flota
# supere la capacidad de las que quedan.
DRONES_PER_FACTORY = 8

# --- Estructuras y torretas (Biblia 4.0) -----------------------------------------------
# "cost" = Chatarra, "cores" = Núcleos de Plasma, "energy" = consumo mientras está activa,
# "energy_output" = capacidad de energía que aporta a la red. Solo hay 2 torretas base (Ligera y Pesada); Tesla y
# Lanzallamas ya no son edificios: son las rutas B de la Pesada y de la Ligera (ver TURRET_ROUTES).
TOWERS_BASE = {
    "tower": {                          # Torreta Ligera = Twin-Autocannon
        "cost": 45, "cores": 0, "energy": ENERGY_COSTS["twin_autocannon"], "hp": 300, "range": 200, "damage": 14,
        "fire_rate": 0.35, "priority": "scout", "bullet_speed": 700,   # (derivado)
    },
    "balista": {                        # Torreta Pesada = Balista
        "cost": 100, "cores": 0, "energy": ENERGY_COSTS["balista"], "hp": 450, "range": 320, "damage": 160,
        "fire_rate": 1.8, "pierce": 2, "priority": "armor", "bullet_speed": 900,   # (derivado)
    },
}
# Búnker de Mando (Paso B): se ensambla una sola vez en el sitio de obra de la Base Central. Excepción a la economía separada:
# cuesta chatarra Y núcleos, y exige el Módulo de Mando de la Infiltración Tecnológica. HP, huella 3x3 y posición (derivado).
BUNKER = {
    "cost": 400, "cores": 2, "hp": 800, "cells": 3,
    "offsets": ((-300, 140), (300, 140), (-300, -140), (300, -140)),   # desde el Centro de Control: el primero que quepa
    "site_label": "Montar el Búnker de Mando - Requiere: 400 de chatarra, 2 núcleos y Módulo de Mando",
    "console_label": "Iniciar Asedio Táctico a la Fortaleza Enemiga",               # la consola de la Base Central (Comandante)
    "console_label_remote": "Consola de Mando Táctico (se maneja desde la Base Central)",   # donde no se puede iniciar el asedio
}
STRUCTURES = {
    "bunker": {"cost": BUNKER["cost"], "cores": BUNKER["cores"], "energy": 0, "hp": BUNKER["hp"]},
    # Muro: sin consumo base; las mejoras (clic derecho o E) lo refuerzan y luego lo electrifican (2 de energía).
    # Balance P1: 15 -> 30 de chatarra (40 castigaba demasiado al perfil medio en la simulación de balance).
    "wall": {"cost": 30, "cores": 0, "energy": 0, "hp": 400, "sell": 0.70, "break_blinks": 3, "break_time": 0.6},
    # Pilón: la ÚNICA estructura de red (el Generador se eliminó: hacía lo mismo). Lleva la energía del Centro de Control en
    # cadena y cada pilón energizado amplía la capacidad.
    "pylon": {"cost": 30, "cores": 0, "energy": 1, "hp": 120, "range": 160, "energy_output": 5},   # mantenimiento 1; hp (derivado)
    "extractor": {"cost": 60, "cores": 0, "energy": 8, "hp": 120, "income": 5, "interval": 1.2},   # chatarra; (derivado) tasa x2.5 (antes cada 3.0 s)
    # Foco Vigía: +30 px de alcance a las torretas dentro de `range` (160) y revela 320 px de niebla. Detección temprana:
    # todo Carroñero que entre en esos 320 px queda revelado y es el blanco prioritario de las torretas enlazadas.
    "foco": {
        "cost": 50, "cores": 0, "energy": 3, "hp": 150, "range": 160, "range_bonus": 30, "reveal_radius": 320,   # hp (derivado)
    },
    # Centro de Control: en modo Comandante (Acto 2 y asedio) lleva un cañón centinela de pulso ligero integrado, de corto
    # alcance, para abatir Scouts y Carroñeros que se cuelan a morderlo sin apoyo (no gasta energía). (derivado)
    "core": {"cost": 0, "cores": 0, "energy": 0, "hp": 500, "energy_output": 50,
             "defense_range": 150, "defense_damage": 15, "defense_fire_rate": 0.5, "defense_bullet_speed": 700},
    # Fábrica de Drones: 2x2 celdas. Se despliega en 20 s; después fabrica drones (10 s cada uno, cola propia de 4) gastando
    # 3 de energía SOLO mientras fabrica. Se pueden construir varias; cada una operativa aporta DRONES_PER_FACTORY a la flota.
    "fabrica": {"cost": 220, "cores": 0, "energy": 3, "hp": 600, "build_time": 20.0, "production_time": 10.0,
                "drones_per_factory": DRONES_PER_FACTORY, "production_queue_size": 4, "size": 80},
    # Compuerta Blindada: 1x2 celdas conectada a la red. Con energía se abre sola ante el Operador, los drones y VULCANO
    # y se cierra 2 s después de que pasen; bloquea siempre a los enemigos (tienen que destruirla). Sin energía (corte,
    # sabotaje o red saturada) queda congelada CERRADA y sólida para todos hasta que vuelva la red.
    "compuerta": {"cost": 45, "cores": 0, "energy": 1, "hp": 500, "width": 40, "height": 80, "open_range": 70,
                  "auto_close_delay": 2.0, "auto_opens_for": ("player", "drones"), "blocks_enemies": True},
}
BUILDINGS = {**TOWERS_BASE, **STRUCTURES}
SELL_REFUND = 0.70                      # venta/desmantelado: devuelve el 70% del costo

# Mejoras del muro (clic derecho o tecla E SOBRE EL MURO bajo el cursor: control táctico, sin distancia ni avatar):
# Nivel 1 base -> 2 Reforzado -> 3 Electrificado. El Electrificado solo refleja el daño mientras la red lo alimenta; sin
# energía actúa como Reforzado (conserva 1400 HP y el -30% a la embestida).
WALL_LEVELS = {
    2: {"name": "REFORZADO", "cost": 30, "cores": 0, "energy": 0, "hp": 900, "ram_reduction": 0.30,
        "desc": "900 HP y -30% al impacto del Ariete"},
    3: {"name": "ELECTRIFICADO", "cost": 60, "cores": 0, "energy": 2, "hp": 1400, "counter_damage": 20,
        "desc": "1400 HP y refleja 20 de daño a Scouts y Soldados que lo golpean cuerpo a cuerpo mientras haya energía "
                "(gasta 2); sin energía actúa como Reforzado"},
}

# Dual-build: al especializar una torreta (clic derecho) se elige UNA ruta, A o B. "set" son los atributos que cambian;
# "energy_extra" es el consumo adicional (la Tesla pasa de 12 a 27). El modo "tesla"/"flame" cambia su comportamiento.
TURRET_ROUTES = {
    "tower": {
        "A": {"name": "MINIGUN", "cost": 60, "cores": 0, "energy_extra": 0,
              "set": {"fire_rate": 0.20, "damage": 10, "armor_pierce": 4},      # Balance P1: perfora 4 de armadura
              "desc": "Cadencia 0.20 s, daño 10 y perforación de armadura (ignora 4): enjambres y Soldados"},
        "B": {"name": "LANZALLAMAS", "cost": 60, "cores": 0, "energy_extra": 3,   # (derivado) 5 + 3 = 8 en total
              "set": {"mode": "flame", "damage": 50, "fire_rate": 0.1, "range": 120, "cone": 70,
                      "armor_pierce": 99},                                    # Balance P1: daño elemental, ignora armadura
              "desc": "Cono de fuego continuo, 50 de daño por segundo, alcance 120; quema la zona e ignora la armadura"},
    },
    "balista": {
        "A": {"name": "PERFORANTE", "cost": 90, "cores": 0, "energy_extra": 0, "set": {"pierce": 4, "damage": 200},
              "desc": "Daño 200 y penetra 4 objetivos: atraviesa formaciones de blindaje"},
        "B": {"name": "TESLA", "cost": 110, "cores": 0, "energy_extra": 15,
              "set": {"mode": "tesla", "damage": 45, "fire_rate": 1.0, "range": 160, "jumps": 4, "stun_slow": 0.40,
                      "stun_time": 0.3, "chain_range": 110, "crowd_radius": 80},   # chain/crowd (derivado)
              "desc": "Arco que salta a 4 enemigos y aturde (-40% 0.3 s); consume +15 de energía (27 en total)"},
    },
}

# Texto de los tooltips de construcción: función y contra qué es efectiva.
TOOLTIPS = {
    "wall": {"function": "Bloque de acero: frena y absorbe el avance", "effective": "Todos (mejorable: Reforzado y Electrificado)"},
    "tower": {"function": "Autocañón gemelo rápido", "effective": "Scouts y enjambres (Minigun: perfora armadura; Lanzallamas: la ignora)",
              "routes": "RUTAS: Clic Der para especializar (Minigun / Lanzallamas)"},
    "balista": {"function": "Proyectil perforante, especialista pesado", "effective": "Tanques y Arietes flanqueados",
                "routes": "RUTAS: Clic Der para especializar (Perforante / Tesla)"},
    "pylon": {"function": "Nodo de la red: +5 de energía (mantenimiento 1)", "effective": "Sin él, las torretas lejanas se apagan"},
    "extractor": {"function": "Extrae chatarra de un depósito (gasta 8 de energía)", "effective": "Economía"},
    "foco": {"function": "Radar: +30 px de alcance a torretas cercanas, revela 320 px de niebla y marca a los Carroñeros "
                         "(gasta 3 de energía)",
             "effective": "Alerta contra Carroñeros: las torretas enlazadas les disparan primero"},
    "compuerta": {"function": "Puerta blindada: se abre sola para tus drones, V.U.L.C.A.N.O. y el Operador y bloquea a los "
                              "enemigos (gasta 1 de energía)",
                  "effective": "Cerrar accesos de la base; sin energía queda cerrada y sólida para todos"},
    "fabrica": {"function": "Fabrica drones autónomos (F1-F4): Explorador, Asalto, Bombardero y Soldado. Puedes construir varias",
                "effective": "Apoyo móvil; cada Fábrica operativa permite 8 drones (gasta 3 de energía mientras fabrica)"},
}

# --- Drones de la Fábrica (F1-F4) -----------------------------------------------------------------------------
# "layer": "air" = capa AÉREA (inmune al daño de contacto de los enemigos terrestres; vulnerable a proyectiles, obuses y
# torretas) o "ground" = capa TERRESTRE (colisiona con el terreno y las estructuras, y cruza las Compuertas aliadas).
# "shot_interval" = SEGUNDOS entre disparos. "cost" = chatarra (sin núcleos). Se pierden al caer: hay que volver a fabricarlos.
# Costes de la Fase 5 (menú de producción de la Fábrica y del Búnker): Asalto 40, Explorador 25, Bombardero 75, Soldado 50.
#   F1 Explorador (aéreo, logística con riesgo): vuela a la chatarra, la carga y la lleva al Centro de Control; si lo derriban
#      en tránsito la suelta. Tope por mapa EXPLORER_CAP. Sigue revelando 400 px de niebla.
#   F2 Dron de Asalto (aéreo): láser continuo, 12 de daño cada 0,5 s, alcance 190.
#   F3 Dron Bombardero (aéreo): sobrevuela enemigos agrupados y suelta bombas en caída libre (75 de daño, radio 60, cada 2,5 s).
#   F4 Soldado Dron (terrestre): rifle de repetición, 15 de daño cada 0,4 s, alcance 160, armadura 3.
DRONE_TYPES = {
    "recon": {"name": "Dron Explorador", "key": "F1", "cost": 25, "cores": 0, "hp": 70, "speed": 240, "layer": "air",
              "vision_range": 400, "ability": "scrap_courier", "damage": 0,
              "patrol_radius": 260, "scan_range": 450, "scan_interval": 0.5, "collect_radius": 14,   # (derivado)
              "upgrade_name": "Velocity_Recon", "upgrade_description": "Velocidad +50 px/s", "upgrade_bonus": {"speed": 50}},
    "attack": {"name": "Dron de Asalto", "key": "F2", "cost": 40, "cores": 0, "hp": 140, "speed": 170, "layer": "air",
               "damage": 16, "shot_interval": 0.5, "range": 190, "weapon": "laser", "engage_radius": 600,   # engage (derivado)
               "upgrade_name": "Damage_Attack", "upgrade_description": "Daño del láser +8", "upgrade_bonus": {"damage": 8}},
    "bomber": {"name": "Dron Bombardero", "key": "F3", "cost": 75, "cores": 0, "hp": 130, "speed": 130, "layer": "air",
               "bomb_damage": 75, "bomb_radius": 60, "bomb_cooldown": 2.5, "bomb_fall_time": 0.5,
               "engage_radius": 600,                                                                     # (derivado)
               "upgrade_name": "Payload_Bomber", "upgrade_description": "Daño de bomba +25",
               "upgrade_bonus": {"bomb_damage": 25}},
    "trooper": {"name": "Soldado Dron", "key": "F4", "cost": 50, "cores": 0, "hp": 220, "armor": 3, "speed": 110,
                "layer": "ground", "damage": 15, "shot_interval": 0.4, "range": 160, "weapon": "rifle",
                "engage_radius": 600, "body": 18,                                                        # (derivado)
                "upgrade_name": "Plating_Trooper", "upgrade_description": "Blindaje de campaña: +60 HP",
                "upgrade_bonus": {"hp": 60}},
}
# Menú de producción (clic der. sobre la Fábrica o el Búnker): orden de las filas [1]-[4]
PRODUCTION_MENU = ("attack", "recon", "bomber", "trooper")
# Tope de Exploradores vivos (y encargados) en todo el mapa, repartido entre todas las fábricas: 2 con una fábrica operativa
# y +1 por cada fábrica operativa adicional, hasta 4. Con el tope, F1 queda bloqueada hasta que caiga uno. (derivado)
EXPLORER_CAP = {"base": 2, "per_extra_factory": 1, "max": 4}
# Especializaciones de torreta (Tech-Tree): se DESBLOQUEAN una vez, con aleación, en el Terminal Táctico y duran toda la
# campaña (CampaignRun). Sin desbloquear, la opción aparece bloqueada en el menú de la torreta (clic derecho). Luego cada
# especialización se paga in situ con chatarra (TURRET_ROUTES). 2 de aleación cada una (derivado).
TURRET_TECH = {
    "tower_A": {"turret": "tower", "route": "A", "label": "Minigun", "alloy": 2},
    "tower_B": {"turret": "tower", "route": "B", "label": "Lanzallamas", "alloy": 2},
    "balista_A": {"turret": "balista", "route": "A", "label": "Perforante", "alloy": 2},
    "balista_B": {"turret": "balista", "route": "B", "label": "Tesla", "alloy": 2},
}
# Mejoras permanentes de los drones: se compran en el Terminal Táctico con ALEACIÓN MILITAR y duran toda la campaña.
DRONE_UPGRADES = {
    "Velocity_Recon": {"type": "recon", "bonus": {"speed": 50}, "cost": 0, "cores": 0, "alloy": 2},     # (derivado)
    "Damage_Attack": {"type": "attack", "bonus": {"damage": 8}, "cost": 0, "cores": 0, "alloy": 2},
    "Payload_Bomber": {"type": "bomber", "bonus": {"bomb_damage": 25}, "cost": 0, "cores": 0, "alloy": 2},
    "Plating_Trooper": {"type": "trooper", "bonus": {"hp": 60}, "cost": 0, "cores": 0, "alloy": 2},
}

# --- Otros drones ----------------------------------------------------------------------
DRONES = {
    # Dron AURA (chasis 6/6): no reaparece; si cae, se pierde el resto del acto
    "aura": {"hp": 150, "pulse_interval": 5.0, "pulse_radius": 100, "stun_slow": 0.40, "stun_time": 1.5,
             "pulse_energy": 2, "speed": 170, "patrol": 160,           # speed/patrol (derivado)
             # chasis 6/6: unidad de combate con láser propio y escolta del Operador (o del Centro de Control) (derivado)
             "damage": 14, "range": 200, "shot_interval": 0.6, "escort_radius": 70},
}

# --- Bases enemigas con IA (Prioridad 3.A) ------------------------------------------------------------------
# Mini-bases que extraen su propio mineral (estilo StarCraft), construyen según su dificultad y contraatacan.
# La Fundición Renegada sigue siendo la base final; para ganar el Acto 2 hay que destruirlas TODAS.
ENEMY_BASES = {
    "core_hp": 1000, "core_size": 120,
    "start_scrap": 500, "start_cores": 3, "energy": 50, "energy_cap": 100, "energy_regen": 0.5,
    "ai_interval": 45.0, "first_decision": 10.0,        # segundos entre decisiones (la primera llega antes)
    "build_chance": 0.40, "repair_chance": 0.30,        # el resto de las veces espera
    "build_radius": 200, "min_dist_player_core": 400,
    "priority": {
        "easy": ["muro", "muro", "torreta_ligera", "muro"],
        "medium": ["muro", "torreta_pesada", "muro", "generador", "torreta_ligera"],
        "hard": ["torreta_pesada", "muro", "generador", "pilon", "torreta_pesada"],
    },
    "structures": {                                     # cifras de la IA (derivadas de las del jugador)
        "muro": {"cost": 30, "cores": 0, "energy": 0, "hp": 400},
        "torreta_ligera": {"cost": 45, "cores": 0, "energy": 5, "hp": 300, "range": 250, "damage": 10, "delay": 1.0},
        "torreta_pesada": {"cost": 80, "cores": 1, "energy": 12, "hp": 450, "range": 320, "damage": 30, "delay": 2.2},
        "generador": {"cost": 60, "cores": 0, "energy": 0, "hp": 200, "energy_cap": 25},
        "pilon": {"cost": 30, "cores": 0, "energy": 0, "hp": 150, "energy_cap": 10},
        "extractor": {"cost": 60, "cores": 0, "energy": 0, "hp": 200, "income": 5, "interval": 3.0},
    },
    "repair": {"threshold": 0.7, "amount": 50, "cost_per_hp": 0.1},
    "deposits": ((-150, -110), (150, 110)),             # depósitos de chatarra propios de cada base
    "by_alert": {1: (1, "easy"), 2: (1, "easy"), 3: (2, "medium"), 4: (3, "hard"), 5: (3, "hard")},
    "slots": ((1150, 250), (1150, 950), (820, 1030), (1450, 180), (1450, 1020)),   # 6+ bases: en círculo
    "destroy_reward": {"scrap": 100, "cores": 1, "alloy": 1},
    "counterattack": {"scouts": 2, "soldier_every": 2},   # 2 + escalada Scouts y 1 Soldado cada 2 de escalada
    # Fase 6 · guarnición inicial (gratis, se crea UNA vez): (tipo, desplazamiento respecto al núcleo, papel).
    # "generator" + al menos un "sentinel" vivos = núcleo invulnerable. Si una pieza cae sobre el núcleo, un depósito u otra
    # estructura, se desplaza hacia el frente (+y) de celda en celda hasta encontrar hueco.
    "garrison": {
        "easy": [("muro", (-100, 0), "wall"), ("muro", (100, 0), "wall"),
                 ("torreta_ligera", (0, 150), "sentinel"), ("generador", (0, -80), "generator")],
        "medium": [("muro", (-150, 0), "wall"), ("muro", (0, 0), "wall"), ("muro", (150, 0), "wall"),
                   ("torreta_ligera", (0, 200), "sentinel"), ("generador", (-100, -80), "generator")],
        "hard": [("muro", (-180, 0), "wall"), ("muro", (-60, 0), "wall"), ("muro", (60, 0), "wall"),
                 ("muro", (180, 0), "wall"), ("torreta_pesada", (-100, 220), "sentinel"),
                 ("torreta_pesada", (100, 220), "sentinel"), ("generador", (0, -100), "generator")],
    },
    # Fase 6 · al caer el núcleo: detonación (visual) y evacuación hacia el borde del mapa (no es una oleada).
    "evacuation": {
        "blast_radius": 300, "spawn_radius": 200,
        "roster": {"easy": {"scout": 4}, "medium": {"scout": 6, "soldier": 1},
                   "hard": {"scout": 8, "soldier": 2, "ariete": 1}},
    },
}

# --- Niebla de guerra del Acto 2 ------------------------------------------------------------------------------
FOG = {"cell": 40, "player_radius": 300, "recon_radius": 400, "core_radius": 450, "structure_radius": 160}

# --- Otros (no los cubre la Biblia: se conservan de la versión anterior) --------------
FOUNDRY = {"wall_hp": 160, "turret_hp": 140, "turret_range": 300, "turret_damage": 10, "turret_delay": 1.1, "core_hp": 700}
# Daño direccional del Ariete Ligero ("Tanque" del 1.2), según el ángulo del impacto medido desde el frente del chasis:
# arco trasero "rear_arc" (grados) x2 y crítico; frente (±45°) blindaje pesado x0,25; costados x0,5. Con menos de
# "smoke_below" de vida sale humo negro constante del radiador.
LIGHT_RAM = {"hp": 260, "trigger": 520, "windup": 0.9, "charge_speed": 560, "stun": 1.1, "contact_damage": 35,
             "rear_mult": 2.0, "front_mult": 0.25, "side_mult": 0.5, "rear_arc": (135, 225), "smoke_below": 0.30}

# --- Oleadas (composición base por oleada; Threat Level multiplica los conteos) ---------
WAVES = {
    "size_multiplier": 1.0,
    # (tipo, cantidad[, retraso_s]). Sin retraso: se baraja en la oleada. Con retraso 0: abre la oleada.
    # Con retraso > 0: entra a los N segundos de empezar (Balance P1: la oleada 5 ya no es un muro único).
    "composition": {
        1: [("scout", 6)],
        2: [("scout", 6), ("soldier", 2)],
        3: [("scout", 8), ("soldier", 3), ("ariete", 1)],
        4: [("scout", 8), ("soldier", 4), ("ariete", 1)],
        5: [("tank", 1, 0.0), ("scout", 8), ("soldier", 4), ("ariete", 2, 15.0)],
    },
}

# Alivio de los pesados por Nivel de Alerta (ajuste de balance con balance_sim): multiplica SOLO la cantidad de soldados,
# arietes y tanques de las oleadas del Acto 2 a esas alertas; scouts, composición base y stats de unidades no cambian.
# 1.0 = sin alivio. (derivado)
THREAT_HEAVY_RELIEF = {3: 0.82, 4: 0.85}
HEAVY_KINDS = ("soldier", "ariete", "tank")
# Alivio de la oleada 3 a alertas bajas (balance_sim: una defensa mínima de 2 torretas y 4 muros caía siempre aquí, porque
# su Ariete no muere con torretas ligeras y 2 embestidas de 300 tumban el Centro de Control): {oleada: {alerta: {...}}}.
# "skip" = tipos que no salen en esa oleada. Retrasar o espaciar las apariciones no cambiaba nada. Alertas 3-5 sin
# cambios; el Ariete sigue llegando en la oleada 4. (derivado)
WAVE_ALERT_RELIEF = {3: {1: {"skip": ("ariete",)}, 2: {"skip": ("ariete",)}}}


# =============================================================================================================
# Mapas de campaña (Prioridad 3.B): escenarios alternativos del Acto 2, 100% guiados por datos.
# Para añadir un mapa basta con un bloque nuevo aquí: tamaño, bases enemigas (posición e id), oleadas, premios y tiempos.
# Reglas: hay un premio por base (el índice es el de la base en "enemy_spawn_positions"); se gana destruyendo TODAS las
# bases del mapa (y la Fundición si el mapa la incluye: "foundry": True). Las oleadas son de dos tamaños: "pequeñas"
# (la lista wave_small_sizes, en orden) y una "grande" cada wave_big_interval pequeñas (de wave_big_sizes, en orden).
# Cuando se acaba el calendario, la IA sigue enviando incursiones hasta que caigan las bases o se agote total_duration.
# Claves añadidas a la especificación: "player_base" (Centro de Control), "outer_deposits" (depósitos de chatarra fuera de la
# base, como desplazamientos desde el Centro de Control) y, si hay Fundición, "foundry_pos". Mapas ampliados un 25%.
# =============================================================================================================
CAMPAIGN_MAPS = {
    "map_1_infiltration": {
        "name": "Infiltración Inicial",
        "description": "Primera incursión: 1 base enemiga pequeña",
        "difficulty": "easy",
        "map_id": 1,
        "map_size": (2000, 1500),
        "enemy_bases": 1,
        "player_base": (1000, 1125),
        "outer_deposits": ((460, -430),),     # depósitos de chatarra exteriores (relativos al Centro de Control)
        "foundry": False,
        "enemy_spawn_positions": [
            {"x": 1000, "y": 188, "id": "base_1a"},
        ],
        "wave_small_sizes": [1, 1, 2, 1, 2, 2, 1],
        "wave_big_interval": 5,
        "wave_big_sizes": [3, 5, 8],
        "rewards": [
            {"type": "AURA_PART", "id": "AURA_PART_1"},
        ],
        "break_time": 30,
        "total_duration": 600,
    },
    "map_2_push": {
        "name": "Empuje Defensivo",
        "description": "Defensa dual: 2 bases enemigas coordinadas",
        "difficulty": "medium",
        "map_id": 2,
        "map_size": (2250, 1750),
        "enemy_bases": 2,
        "player_base": (1125, 1375),
        "outer_deposits": ((460, -430), (-300, -500)),
        "foundry": False,
        "enemy_spawn_positions": [
            {"x": 500, "y": 188, "id": "base_2a"},
            {"x": 1500, "y": 188, "id": "base_2b"},
        ],
        "wave_small_sizes": [2, 2, 3, 2, 3, 4, 3, 4],
        "wave_big_interval": 5,
        "wave_big_sizes": [5, 8, 12],
        "rewards": [
            {"type": "AURA_PART", "id": "AURA_PART_2"},
            {"type": "PLAYER_UPGRADE", "id": "PLAYER_UPGRADE_1"},
        ],
        "break_time": 30,
        "total_duration": 900,
    },
    "map_3_siege": {
        "name": "Asedio Final",
        "description": "Asedio triple: 3 bases enemigas y la Fundición Renegada",
        "difficulty": "hard",
        "map_id": 3,
        "map_size": (2500, 2000),
        "enemy_bases": 3,
        "player_base": (525, 1250),
        "outer_deposits": ((460, -430), (-300, -500)),
        "foundry": True,                      # además de las 3 bases hay que demoler la Fundición (flujo 2.1 -> 2.2)
        "foundry_pos": (2125, 1250),
        "enemy_spawn_positions": [
            {"x": 500, "y": 188, "id": "base_3a"},
            {"x": 1250, "y": 188, "id": "base_3b"},
            {"x": 2000, "y": 188, "id": "base_3c"},
        ],
        "wave_small_sizes": [3, 3, 4, 4, 5, 6, 6, 7],
        "wave_big_interval": 5,
        "wave_big_sizes": [8, 12, 15, 20],
        "rewards": [
            {"type": "AURA_PART", "id": "AURA_PART_3"},
            {"type": "PLAYER_UPGRADE", "id": "PLAYER_UPGRADE_2"},
            {"type": "DRONE_UPGRADE", "id": "DRONE_UPGRADE_ATTACK"},
        ],
        "break_time": 30,
        "total_duration": 1200,
    },
    # Plantilla para futuras expansiones: "map_4_convergence": {...}, "map_5_nexus": {...}
}

# Desbloqueo progresivo de estructuras (derivado): la Base Central solo empieza con Muro, Pilón y Torreta Ligera. El resto se
# desbloquea al cumplir su requisito: ("incursion", N) = alcanzar el nivel de incursión N (el 2 es completar la incursión
# inicial) o ("map", clave) = ganar ese mapa de campaña. Las especializaciones de torreta (Minigun...) siguen yendo por
# Aleación en el Terminal Táctico.
STARTER_STRUCTURES = ("wall", "tower", "pylon")
STRUCTURE_UNLOCKS = {
    "extractor": ("incursion", 3),
    "balista": ("map", "map_1_infiltration"),
    "foco": ("map", "map_2_push"),
    "fabrica": ("incursion", 2),          # planos de la Fábrica: al completar la incursión inicial (entrada al Acto 2)
    "compuerta": ("map", "map_3_siege"),
}

# =============================================================================================================
# Paso D · Guerra de Asedio: mapa de 3000 x 2000 px (derivado). La Base del jugador a la izquierda y la Fortaleza enemiga a la derecha
# (>= 2200 px entre ambas), con una Tierra de Nadie de barreras de escombros (cuellos de botella), terreno decorado y nodos de plasma.
# =============================================================================================================
SIEGE = {
    "map": (3000, 2000), "cell": 40,
    "player_base_x": 8, "fortress_x": 66, "base_dy": 8,            # columnas de celda de cada base y desvío vertical máximo (celdas)
    "barrier_x": (1000, 1500, 2000), "barrier_jitter": 1, "barrier_cells": 3,    # barreras de escombros de 120 px de espesor
    "gap_cells": (5, 7), "gaps_per_barrier": (1, 2),               # pasos de 200-280 px: pasan los Tanques
    "cover_piles": 14, "plasma_nodes": (2, 3), "min_separation": 2200,
    "max_enemies": 65,                                             # tope duro de enemigos vivos a la vez (60 FPS en la fase III)
    "free_structures": ("fabrica", "pylon", "balista"),            # el asedio las necesita (drones, red eléctrica y frenar Arietes)
    "kill_metal": 4,                                                # chatarra directa por baja en el asedio (los drones recuperan coste)
}
# Reloj de amenaza enemiga: la Fortaleza evoluciona con el tiempo de partida (en segundos de juego; la pausa lo detiene).
# Cada "stream" envía su pedido cada `interval` s desde `first` s tras activarse (a partir de su fase). target: core (Centro de
# Control) | pylon (el pilón más cercano) | scrap (el botín del suelo, para los Carroñeros). requires: "factory" = solo si la
# Factoría enemiga está en pie. A partir de `late_growth.after` s, +1 unidad del primer tipo cada `every` s (fase III en adelante).
THREAT_CLOCK = {
    "phase_starts": (0.0, 240.0, 480.0),
    "streams": (
        {"id": "raiders", "phase": 1, "interval": 25.0, "first": 12.0, "kinds": {"scout": 3}, "target": "core"},
        {"id": "scavengers", "phase": 1, "interval": 45.0, "first": 20.0, "kinds": {"scavenger": 1}, "target": "scrap"},
        {"id": "strike", "phase": 2, "interval": 45.0, "first": 8.0, "kinds": {"soldier": 2, "ariete": 1}, "target": "pylon"},
        {"id": "armor", "phase": 3, "interval": 75.0, "first": 10.0, "kinds": {"tank": 1, "soldier": 2}, "target": "core",
         "requires": "factory"},
    ),
    "late_growth": {"after": 480.0, "every": 120.0},
    "fortress": {
        "core_hp": 1200, "build_time": 20.0, "factory_hp": 700, "factory_size": 80,
        "rebuild_delay": {1: 60.0, 2: 45.0, 3: 30.0},              # una estructura destruida no reaparece al instante
        # (tipo, rol, desplazamiento desde el núcleo): la fortaleza mira hacia -x, donde está el jugador
        "phase_1": (("torreta_ligera", "turret", (-170, -100)), ("torreta_ligera", "turret", (-170, 100))),
        "phase_2": (("generador", "generator", (70, -150)), ("torreta_pesada", "sentinel", (-230, -150)),
                    ("torreta_pesada", "sentinel", (-230, 150))),
        "phase_3": (("fabrica", "factory", (140, 0)),),
    },
}
# Nodos de plasma de la Tierra de Nadie: se capturan con drones aliados cerca (y sin enemigos); reserva FINITA de Núcleos: 1 al
# capturarlos y un goteo hasta `drip_cores` más (máximo 3 por nodo); vacíos, pasan a dar un flujo modesto de chatarra.
# `campaign_cap` limita los Núcleos que dan los nodos en TODA la campaña (los reintentos no se pueden farmear).
PLASMA_NODE = {
    "radius": 110, "capture_time": 5.0, "first_cores": 1, "drip_cores": 2, "drip_interval": 45.0,
    "scrap_trickle": 5, "scrap_interval": 10.0, "campaign_cap": 9,
}

# Qué enemigos forman una oleada de N unidades según la dificultad del mapa: la unidad i-ésima (1, 2, 3...) es un Tanque si
# i es múltiplo de tank_every, si no un Ariete si lo es de ariete_every, si no un Soldado si lo es de soldier_every y si no
# un Scout (0 = nunca). Así los mapas fáciles son enjambres de Scouts y los difíciles meten blindados en las grandes.
CAMPAIGN_WAVE_MIX = {
    "easy": {"small": {"soldier_every": 0, "ariete_every": 0, "tank_every": 0},
             "big": {"soldier_every": 4, "ariete_every": 0, "tank_every": 0}},
    "medium": {"small": {"soldier_every": 3, "ariete_every": 0, "tank_every": 0},
               "big": {"soldier_every": 3, "ariete_every": 5, "tank_every": 0}},
    "hard": {"small": {"soldier_every": 2, "ariete_every": 0, "tank_every": 0},
             "big": {"soldier_every": 2, "ariete_every": 5, "tank_every": 8}},
}

# --- Prioridad 4: Rewards System ------------------------------------------------------------------------------
# Cada base enemiga destruida da 1 reward (ids en CAMPAIGN_MAPS[...]["rewards"]). Los rewards son permanentes y se
# acumulan entre mapas. AURA_PART = +1 componente del chasis; PLAYER_UPGRADE = mejora pasiva del Operador (nodos de
# recompensa, aparte de los comprables del árbol); DRONE_UPGRADE = versión mejorada de la mejora del dron (se suma al
# máximo de lo comprado). 6 AURA + 6 Operador + 4 drones = 16.
_AURA_PARTS = (
    ("Núcleo de procesamiento", "Habilita escaneo táctico"), ("Módulo de análisis", "Mejora precisión"),
    ("Unidad de control", "Activa dron autónomo"), ("Matriz de memoria", "Expansión datos"),
    ("Procesador de señal", "Mejora comunicación"), ("Cristal de poder", "Chasis completado"),
)
# Con las 6 piezas del chasis de AURA ya recuperadas (o en el suelo), lo que llevaría otra pieza suelta esto. (derivado)
CHASSIS_SURPLUS = {"scrap": 30, "cores": 1}
REWARD_DEFINITIONS = {
    **{f"AURA_PART_{i}": {"type": "aura_part", "name": f"Componente AURA #{i}", "description": f"{n} - {d}",
                          "icon": "⚡", "index": i} for i, (n, d) in enumerate(_AURA_PARTS, 1)},
    "PLAYER_UPGRADE_1": {"type": "player_upgrade", "name": "Armadura Ligera", "description": "Reduce daño recibido en 20%",
                         "operator_tree_node": "Armor_Light", "bonus": {"damage_reduction": 0.20}},
    "PLAYER_UPGRADE_2": {"type": "player_upgrade", "name": "Velocidad Aumentada", "description": "Movimiento +50 px/s",
                         "operator_tree_node": "Speed_Boost", "bonus": {"speed": 50}},
    "PLAYER_UPGRADE_3": {"type": "player_upgrade", "name": "Cargador Extendido", "description": "Munición +100 balas",
                         "operator_tree_node": "Extended_Ammo", "bonus": {"ammo_max": 100}},
    "PLAYER_UPGRADE_4": {"type": "player_upgrade", "name": "Regeneración Mejorada",
                         "description": "Exoesqueleto regenera +3 HP/s", "operator_tree_node": "Regen_Enhanced",
                         "bonus": {"regen_rate": 3}},
    "PLAYER_UPGRADE_5": {"type": "player_upgrade", "name": "Visión Táctica", "description": "Radio visión +100px",
                         "operator_tree_node": "Vision_Tactical", "bonus": {"vision_range": 100}},
    "PLAYER_UPGRADE_6": {"type": "player_upgrade", "name": "Chasis Reforzado", "description": "Salud base +50 HP",
                         "operator_tree_node": "Health_Reinforced", "bonus": {"health_max": 50}},
    "DRONE_UPGRADE_RECON": {"type": "drone_upgrade", "drone_type": "recon", "name": "Propulsores Mejorados",
                            "description": "Dron explorador +70px/s velocidad", "operator_tree_node": "Velocity_Recon",
                            "bonus": {"speed": 70}},
    "DRONE_UPGRADE_ATTACK": {"type": "drone_upgrade", "drone_type": "attack", "name": "Cañón Pesado de Asalto",
                             "description": "Dron de asalto +10 daño de láser", "operator_tree_node": "Damage_Attack",
                             "bonus": {"damage": 10}},
    "DRONE_UPGRADE_BOMBER": {"type": "drone_upgrade", "drone_type": "bomber", "name": "Carga Explosiva",
                             "description": "Dron bombardero +35 daño de bomba", "operator_tree_node": "Payload_Bomber",
                             "bonus": {"bomb_damage": 35}},
    "DRONE_UPGRADE_TROOPER": {"type": "drone_upgrade", "drone_type": "trooper", "name": "Blindaje de Campaña",
                              "description": "Soldado dron +80 HP", "operator_tree_node": "Plating_Trooper",
                              "bonus": {"hp": 80}},
}
REWARD_REGEN_DELAY = PLAYER["regen_delay"]   # s sin recibir daño antes de regenerar (la misma espera que la de AURA)
CAMPAIGN_REWARD_FALLBACK = {"cores": 2}      # si el premio ya lo tenías: núcleos de plasma de consolación
# Fase 6 · anti-farmeo: premio por GANAR un mapa, solo la primera vez (chatarra, núcleos). En un mapa ya ganado tampoco
# pagan las bases destruidas ni la consolación de premios repetidos. (derivado)
CAMPAIGN_MAP_REWARDS = {"map_1_infiltration": (100, 3), "map_2_push": (150, 4), "map_3_siege": (200, 5)}
CAMPAIGN_MAP_ALLOY = {"map_1_infiltration": 2, "map_2_push": 3, "map_3_siege": 4}     # Aleación del primer viaje (derivado)
# Aleación extra (solo la primera vez que se gana cada mapa, anti-farmeo): +1 garantizada al derribar un Tanque pesado desde la
# oleada "tank_min_wave", y +2 al superar el mapa con el Centro de Control por encima de "clear_core_hp" de vida. (derivado)
ALLOY_BONUS = {"tank_drop": 1, "tank_min_wave": 4, "clear_reward": 2, "clear_core_hp": 0.75}
# Fase 6 · reducción de daño del Operador: las fuentes se SUMAN (Armadura Ligera, su reward y cualquier bono externo) y
# el total no pasa de este tope.
DAMAGE_REDUCTION_CAP = 0.35


def campaign_wave_roster(size, difficulty, big=False):
    """Lista de tipos de enemigo de una oleada de `size` unidades (ver CAMPAIGN_WAVE_MIX)."""
    mix = CAMPAIGN_WAVE_MIX[difficulty]["big" if big else "small"]
    roster = []
    for i in range(1, size + 1):
        if mix["tank_every"] and i % mix["tank_every"] == 0:
            roster.append("tank")
        elif mix["ariete_every"] and i % mix["ariete_every"] == 0:
            roster.append("ariete")
        elif mix["soldier_every"] and i % mix["soldier_every"] == 0:
            roster.append("soldier")
        else:
            roster.append("scout")
    return roster


CAMPAIGN_SPAWN_INTERVAL = 0.3                # segundos entre apariciones dentro de una oleada (cada mapa puede fijar "spawn_interval")


def campaign_wave_entry(cfg, n):
    """Oleada nº `n` (1, 2, 3...) del mapa: (etiqueta, tamaño, lista de enemigos). Tras cada `wave_big_interval` pequeñas
    llega una grande. Las listas de tamaños se recorren en bucle; las grandes repiten la última (Stronghold Loop)."""
    interval = cfg["wave_big_interval"]
    cycle, pos = divmod(n - 1, interval + 1)
    if pos == interval:
        sizes = cfg["wave_big_sizes"]
        size = sizes[min(cycle, len(sizes) - 1)]
        return ("big", size, campaign_wave_roster(size, cfg["difficulty"], big=True))
    sizes = cfg["wave_small_sizes"]
    size = sizes[(cycle * interval + pos) % len(sizes)]
    return ("small", size, campaign_wave_roster(size, cfg["difficulty"]))


def campaign_assault_after(cfg):
    """Oleadas de la primera vuelta de tamaños pequeños: en los mapas con Fundición, tras ellas empieza el asalto."""
    n_small = len(cfg["wave_small_sizes"])
    return n_small + n_small // cfg["wave_big_interval"]


def campaign_wave_plan(cfg):
    """Primera vuelta del calendario: [(etiqueta, tamaño, lista de enemigos)] (el generador sigue más allá, en bucle)."""
    return [campaign_wave_entry(cfg, n) for n in range(1, campaign_assault_after(cfg) + 1)]

