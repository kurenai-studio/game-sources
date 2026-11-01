"""Tooltips contextuales: tarjetas que aparecen 0,5 s después de pasar el ratón por un botón, una estructura o una mejora.

No bloquean el juego y desaparecen en cuanto el ratón sale. `TooltipManager` solo lleva el temporizador;
las funciones `*_card` arman el contenido (el dibujo lo hace `HUD.draw_card`)."""
import pygame

import config as C
from src.config import UNITS as U

DELAY_MS = 500


class TooltipManager:
    def __init__(self):
        self.key = None
        self.since = 0

    def clear(self):
        self.key = None

    def hover(self, key):
        """Registra que el ratón está sobre `key`. Devuelve True cuando ya pasó el retardo y hay que mostrar la tarjeta."""
        now = pygame.time.get_ticks()
        if key != self.key:
            self.key, self.since = key, now
        return now - self.since >= DELAY_MS


def _stat_lines(stats, route=None):
    """Líneas de atributos de una torreta o estructura (solo los que aplican)."""
    lines = [f"HP: {stats['hp']}"]
    if stats.get("damage"):
        per_second = stats["damage"] if stats.get("fire_rate", 1) <= 0.1 else None
        lines[0] += f" | Daño: {stats['damage']}" + ("/s" if per_second else "")
        if stats.get("fire_rate") and not per_second:
            lines[0] += f" | Cadencia: {stats['fire_rate']}s"
    if stats.get("range"):
        lines.append(f"Rango: {stats['range']}px")
    if stats.get("energy_output"):
        lines.append(f"Genera: +{stats['energy_output']} de capacidad de energía")
    if stats.get("range_bonus") and not isinstance(stats["range_bonus"], float):
        lines.append(f"Bonus: +{stats['range_bonus']}px de rango a torretas cercanas")
    return lines


def building_card(btype, scrap, resources=None, energy_free=None):
    """Tarjeta del botón de construcción: costo (⚙ 🔷 ⚡), atributos, función, efectiva vs y acción."""
    from src.entities.building import Building
    stats = Building.STATS[btype]
    afford = (True, True, True)
    if resources is not None:
        afford = (resources.can_afford(scrap), resources.cores >= stats["cores"],
                  energy_free is None or stats["energy"] <= energy_free)
    info = U.TOOLTIPS.get(btype, {})
    rows = [("cost", scrap, stats["cores"], stats["energy"], afford), ("sep",)]
    for line in _stat_lines(stats):
        rows.append(("text", line, C.WHITE))
    rows += [("sep",), ("text", "FUNCIÓN: " + info.get("function", ""), C.WHITE),
             ("text", "EFECTIVA vs: " + info.get("effective", ""), C.YELLOW), ("sep",)]
    if info.get("routes"):
        rows.append(("text", info["routes"], C.MAGENTA))
    rows.append(("text", "[Click Izq] Construir", C.CYAN))
    return {"title": Building.LABELS[btype].upper(), "rows": rows}


def locked_card(btype, resources):
    """Tarjeta de una estructura bloqueada: qué hay que hacer para desbloquearla."""
    from src.entities.building import Building
    info = U.TOOLTIPS.get(btype, {})
    rows = [("text", "BLOQUEADA", C.RED), ("text", "Para desbloquearla: " + resources.structure_requirement(btype), C.ORANGE),
            ("sep",), ("text", "FUNCIÓN: " + info.get("function", ""), C.DARK_GRAY)]
    return {"title": Building.LABELS[btype].upper(), "rows": rows}


def bunker_site_card(resources):
    """Tarjeta del sitio de obra del Búnker: coste y requisito."""
    spec = U.BUNKER
    afford = (resources.can_afford(spec["cost"]), resources.cores >= spec["cores"], True)
    module = resources.command_module
    rows = [("cost", spec["cost"], spec["cores"], 0, afford), ("sep",),
            ("text", f"Requiere: {spec['cost']} de chatarra, {spec['cores']} núcleos de plasma y Módulo de Mando", C.WHITE),
            ("text", "Módulo de Mando: OBTENIDO" if module else "Requiere planos de Op 4: Complejo Tecnológico",
             C.GREEN if module else C.RED), ("sep",),
            ("text", f"HP {spec['hp']} · huella de {spec['cells']}x{spec['cells']} celdas · no se puede vender", C.WHITE),
            ("text", "[E] junto al sitio (Operador) · clic izq. (Comandante)", C.CYAN)]
    return {"title": "SITIO DE OBRA · BÚNKER DE MANDO", "rows": rows}


def site_card(site, res):
    """Tarjeta de una obra en cola: avance, chatarra consumida y estado."""
    from src.entities.building import Building
    state = ("EN ESPERA: falta chatarra" if site.waiting else "En cola: VULCANO la construye cuando le toca")
    rows = [("text", f"Avance: {round(site.fraction * 100)}% ({int(site.progress)}/{int(site.total)} HP)", C.WHITE),
            ("text", f"Chatarra consumida: {site.paid}/{site.scrap_cost}", C.YELLOW),
            ("text", f"Reserva: {res.metal}", C.WHITE if res.metal else C.RED),
            ("text", state, C.ORANGE if site.waiting else C.CYAN), ("sep",),
            ("text", "[Clic Der] Cancelar la obra (reembolsa lo gastado)", C.DARK_GRAY)]
    return {"title": f"OBRA: {Building.LABELS[site.btype].upper()}", "rows": rows}


def bunker_console_card(active=False, res=None):
    """Tarjeta de la consola del Búnker: en la Base Central inicia el asedio; en otras escenas solo se maneja desde allí."""
    if not active:
        return {"title": "CONSOLA DE MANDO TÁCTICO",
                "rows": [("text", "Se maneja desde la Base Central (modo Comandante)", C.ORANGE)]}
    rows = [("text", "[Clic / E] Iniciar Asedio Táctico a la Fortaleza Enemiga", C.GREEN),
            ("text", "Transfiere tus recursos de campaña y despliega el asedio", C.WHITE)]
    if res is not None:
        rows.append(("text", f"Recursos: {res.metal} de chatarra · {res.cores} núcleos de plasma", C.CYAN))
    return {"title": "CONSOLA DE MANDO TÁCTICO", "rows": rows}


def structure_card(b):
    """Tarjeta de una estructura del mapa: energía consumida, HP, rango y estado."""
    rows = [("text", f"HP: {max(0, int(b.hp))}/{b.max_hp}", C.WHITE)]
    if b.energy_cost:
        rows.append(("text", f"Energía consumida: {b.energy_cost}", C.YELLOW))
    if b.range:
        rows.append(("text", f"Rango: {int(b.effective_range())}px", C.WHITE))
    if b.building_type == "wall":
        names = {1: "Acero", 2: "REFORZADO", 3: "ELECTRIFICADO"}
        rows.append(("text", f"Nivel {b.level}: {names[b.level]}" + ("" if b.wall_upgrade() is None
                                                                      else " · [Clic Der / E] mejorar"), C.CYAN))
    if b.building_type == "compuerta":
        if not b.active:
            rows.append(("text", "Estado: CONGELADA CERRADA (sin energía): sólida para todos", C.RED))
        else:
            rows.append(("text", "Estado: " + ("ABIERTA (pasa un aliado)" if b.is_open else "CERRADA"),
                         C.GREEN if b.is_open else C.CYAN))
    if b.requires_power:
        state = "ACTIVA" if b.active else ("SIN ENERGÍA (red saturada)" if b.is_powered else "SIN CONEXIÓN A LA RED")
        rows.append(("text", f"Estado: {state}", C.GREEN if b.active else C.RED))
    if b.route is not None:
        spec = U.TURRET_ROUTES[b.building_type][b.route]
        rows.append(("text", f"Ruta {b.route}: {spec['name']}", C.CYAN))
    return {"title": b.label.upper(), "rows": rows}


ENEMY_NAMES = {"scout": "Scout Renegado", "soldier": "Soldado Renegado", "tank": "Tanque Renegado",
               "ariete": "Ariete Ligero"}
SCAVENGER_STATES = {"seek_scrap": "Buscando chatarra", "latching": "Robando chatarra", "seek_pylon": "Saboteando un pilón",
                    "fleeing": "Huyendo con el botín"}


def drone_type_card(kind):
    """Tarjeta de estadísticas de un tipo de dron (botón del menú de producción)."""
    s = U.DRONE_TYPES[kind]
    grey = (150, 156, 175)
    layer = "Aéreo (inmune al contacto)" if s.get("layer") == "air" else f"Terrestre · armadura {s.get('armor', 0)}"
    rows = [("cost", s["cost"], s["cores"], 0, (True, True, True)), ("sep",),
            ("text", f"HP: {s['hp']} · Velocidad: {s['speed']} px/s", C.WHITE), ("text", layer, grey)]
    if kind == "recon":
        rows.append(("text", f"Recoge chatarra a {s['scan_range']} px y la lleva al Centro de Control", C.WHITE))
        rows.append(("text", f"Revela {s['vision_range']} px de niebla", grey))
    elif kind == "bomber":
        rows.append(("text", f"Bombas: {s['bomb_damage']} de daño en {s['bomb_radius']} px cada {s['bomb_cooldown']} s", C.WHITE))
    else:
        rows.append(("text", f"Daño: {s['damage']} cada {s['shot_interval']} s · Alcance: {s['range']} px", C.WHITE))
    rows += [("sep",), ("text", f"Mejora del Terminal: {s['upgrade_description']}", C.MAGENTA),
             ("text", f"[{U.PRODUCTION_MENU.index(kind) + 1}] / clic izq.: encargar · {s['key']} desde el mapa", C.CYAN)]
    return {"title": s["name"].upper(), "rows": rows, "color": C.CYAN}


def unit_under(groups, world_pos, pad=8):
    """La unidad viva más cercana al ratón cuyo sprite (con `pad` px de margen) queda bajo él, o None."""
    best, best_d = None, None
    for group in groups:
        for u in group:
            if not u.alive() or not u.rect.inflate(pad * 2, pad * 2).collidepoint(world_pos):
                continue
            d = u.pos.distance_squared_to(world_pos)
            if best_d is None or d < best_d:
                best, best_d = u, d
    return best


def _hp_row(hp, max_hp, color):
    hp = max(0, int(hp))
    return ("bar", hp / max(1, max_hp), color, f"HP: {hp}/{int(max_hp)}")


def drone_card(d):
    """Tarjeta compacta de un dron aliado: nombre y clase, vida y estado operativo."""
    frac = d.hp / max(1, d.max_hp)
    color = C.GREEN if frac > 0.5 else (C.YELLOW if frac > 0.25 else C.RED)
    layer = "aéreo" if getattr(d, "aerial", True) else "terrestre"           # AURA también vuela
    rows = [_hp_row(d.hp, d.max_hp, color), ("text", f"Estado: {d.activity}", C.WHITE),
            ("text", f"Unidad aliada · {layer}", (150, 156, 175))]
    return {"title": d.display_name.upper(), "rows": rows, "color": C.CYAN}


def enemy_card(e):
    """Tarjeta de una unidad hostil (rojo/naranja): identificación, vida restante y qué hace."""
    if hasattr(e, "enemy_type"):
        name = ENEMY_NAMES.get(e.enemy_type, e.enemy_type.capitalize())
        if getattr(e, "state", "") in ("windup", "charge"):
            state = "Embistiendo"
        elif getattr(e, "aim", None) is not None:
            state = "Disparando"
        else:
            state = "Avanzando"
        max_hp = e.max_hp
    else:                                                       # dron carroñero
        name, state, max_hp = "Dron Carroñero", SCAVENGER_STATES.get(e.state, "Merodeando"), U.SCAVENGER["hp"]
    rows = [_hp_row(e.hp, max_hp, C.RED), ("text", f"Estado: {state}", C.ORANGE), ("text", "Unidad hostil", C.RED)]
    return {"title": name.upper(), "rows": rows, "color": C.ORANGE}


def pickup_under(groups, world_pos, radius=24):
    """El recogible más cercano al ratón (en coordenadas del mundo) dentro de `radius` px, o None."""
    best, best_d = None, radius * radius
    for group in groups:
        for it in group:
            d = it.pos.distance_squared_to(world_pos)
            if d <= best_d:
                best, best_d = it, d
    return best


def pickup_card(item, resources=None):
    """Tarjeta de un recogible del suelo: qué es, qué da, para qué sirve y cuánto dura."""
    from src.entities.alloy_item import AlloyItem
    from src.entities.ammo import AmmoBox
    from src.entities.chassis import ChassisPart
    from src.entities.core_item import CoreItem
    from src.entities.scrap import ScrapItem
    grey = (150, 156, 175)
    life = getattr(item, "lifetime", None)
    timer = [] if life is None else [("text", f"Desaparece en {max(1, int(life))} s", grey)]
    pick = ("text", "Acércate para recogerla (el imán la atrae)", C.CYAN)
    if isinstance(item, CoreItem):
        n = item.value
        return {"title": "NÚCLEO DE PLASMA", "rows": [
            ("text", f"+{n} núcleo{'s' if n != 1 else ''} de plasma", C.CYAN), ("sep",),
            ("text", "USO: torretas pesadas, Extractor de Plasma y Foco", C.WHITE),
            ("text", "Escaso: lo sueltan Arietes y Tanques", C.YELLOW), *timer, ("sep",), pick]}
    if isinstance(item, AmmoBox):
        return {"title": "CAJA DE MUNICIÓN", "rows": [
            ("text", f"+{item.amount} balas para tu rifle", C.GREEN), ("sep",),
            ("text", "Las sueltan los enemigos al morir", C.WHITE), *timer, ("sep",), pick]}
    if isinstance(item, AlloyItem):
        return {"title": "ALEACIÓN MILITAR", "rows": [
            ("text", f"+{item.value} de aleación militar", C.WHITE), ("sep",),
            ("text", "USO: mejoras avanzadas de torretas y drones", C.WHITE),
            ("text", "El recurso más raro: no se compra", C.YELLOW), *timer, ("sep",), pick]}
    if isinstance(item, ChassisPart):
        found = getattr(resources, "chassis_found", 0)
        return {"title": f"COMPONENTE DE AURA · {item.part_name.upper()}", "rows": [
            ("text", "Pieza del cuerpo de combate de AURA", C.MAGENTA),
            ("text", f"Recuperadas: {found}/{C.CHASSIS_TOTAL_PARTS}", C.WHITE), ("sep",),
            ("text", "Se instalan en la Base Central:", C.WHITE),
            ("text", f"  {U.AURA_CHASSIS['scan_parts']}/{C.CHASSIS_TOTAL_PARTS}: escaneo táctico (el radar marca depósitos)", grey),
            ("text", f"  {U.AURA_CHASSIS['drone_parts']}/{C.CHASSIS_TOTAL_PARTS}: AURA combate a tu lado como dron", grey),
            ("text", "No caduca", grey), ("sep",), pick]}
    if isinstance(item, ScrapItem):
        return {"title": "CHATARRA", "rows": [
            ("text", f"+{item.value} de metal", C.GREEN), ("sep",),
            ("text", "USO: construir y reparar estructuras", C.WHITE),
            ("text", "Los carroñeros enemigos intentan robarla", C.YELLOW), *timer, ("sep",), pick]}
    return None


def node_card(node, resources):
    """Tarjeta de una mejora del Terminal Táctico: costo, efecto y prerrequisito."""
    spec = U.OPERATOR_TREE[node]
    scrap, cores = spec["cost"], spec["cores"]
    rows = [("cost", scrap, cores, 0, (resources.can_afford(scrap), resources.cores >= cores, True)), ("sep",),
            ("text", "EFECTO: " + spec["effect"], C.WHITE), ("text", spec["desc"], (150, 156, 175))]
    if spec["requires"] is not None:
        req = U.OPERATOR_TREE[spec["requires"]]["label"]
        done = resources.owns(spec["requires"])
        rows.append(("text", f"Requiere: {req}" + (" (comprado)" if done else " (bloqueado)"),
                     C.GREEN if done else C.RED))
    state = resources.node_state(node)
    rows += [("sep",), ("text", {"owned": "COMPRADO", "available": "[Click Izq] Comprar", "locked": "BLOQUEADO"}[state],
                        {"owned": C.GREEN, "available": C.CYAN, "locked": C.RED}[state])]
    return {"title": spec["label"].upper(), "rows": rows}
