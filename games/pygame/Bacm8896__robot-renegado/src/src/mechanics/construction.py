"""Sistema de construcción compartido por el tutorial de fortificación (1.3), el Acto 2 y la Base Central.

`ConstructionMixin` se mezcla con una escena (State). La escena debe aportar:
  world, res, player, grid, nav, map_rect, camera, build_menu (lista de (tecla, tipo)),
  build_discount() y notify(texto, segundos).

Controles unificados: clic izquierdo construye (con un edificio elegido), clic derecho sobre una estructura abre su
menú (mejoras de torreta / vender) y clic derecho en el aire llama a `on_air_right_click()` (golpe del Operador)."""
import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.core.audio_manager import audio
from src.entities.building import TURRETS, Building, create_building
from src.entities.power import reaches
from src.mechanics import combat
from src.ui import structure_art as art
from src.ui.combat_feedback import ALERTS
from src.ui.structure_menu import StructureMenu
from src.mechanics.bunker import BunkerMixin
from src.ui.tooltips import (building_card, drone_card, drone_type_card, enemy_card, locked_card, pickup_card,
                             pickup_under, structure_card, unit_under)

_DIGITS = (pygame.K_1, pygame.K_2, pygame.K_3, pygame.K_4, pygame.K_5, pygame.K_6, pygame.K_7, pygame.K_8, pygame.K_9)


class ConstructionMixin(BunkerMixin):
    INSTANT_BUILD = True          # False en la Base Central: se coloca un sitio de obra y VULCANO lo construye
    build_choice = None
    build_cd = 0.0
    hovered_unit = None           # dron / unidad hostil bajo el ratón (tooltip y retícula)
    menu = None
    panel_shift = -60             # desplazamiento horizontal del panel de construcción (HUD)
    energy_warning = 0.0
    _build_counter = 0

    # --- utilidades ---
    def _init_construction(self):
        self.build_choice = None
        self.build_cd = 0.0
        self.menu = None
        self._build_counter = 0                   # orden de construcción (sin energía se apagan primero las más nuevas)
        self.energy_warning = 0.0                 # segundos que se muestra "INSUFICIENTE ENERGÍA"
        self._probe = pygame.sprite.Sprite()
        self._probe.rect = pygame.Rect(0, 0, 1, 1)

    def build_discount(self):
        return 0.0

    def notify(self, text, ttl=3.0):
        pass

    def on_air_right_click(self):
        """Clic derecho sin estructura debajo: golpe cuerpo a cuerpo del Operador (no en la pausa táctica)."""
        player = getattr(self, "player", None)
        if player is not None and not getattr(self, "paused", False):
            player.queue_melee()

    def on_built(self, building):
        """Una estructura acaba de construirse: lanza los hints de la primera estructura / primera torreta."""
        hints = getattr(self, "hints", None)
        if hints is None:
            return
        hints.done("build")
        anchor = (lambda s=building: s.pos if s.alive() else None)
        if building.building_type in TURRETS:
            hints.show("turret_upgrade", "Clic derecho para mejorar", "click_right", anchor)
            hints.shown.add("right_menu")                        # un solo mensaje si la primera estructura es torreta
        else:
            hints.show("right_menu", "Clic der.: mejorar / desmantelar", "click_right", anchor)

    def _register(self, b):
        w = self.world
        w.all_sprites.add(b)
        w.structures.add(b)
        w.solids.add(b)
        group = {"wall": w.walls, "tower": w.towers, "balista": w.towers,
                 "pylon": w.pylons, "extractor": w.extractors,
                 "foco": w.focos, "fabrica": w.factories, "compuerta": w.gates}.get(b.building_type)
        if group is not None:
            group.add(b)
        b.world = w
        if hasattr(b, "grid"):
            b.grid = self.grid
        b.on_destroyed = self._on_building_destroyed
        self.configure_building(b)
        self._build_counter += 1
        b.build_order = self._build_counter
        self.nav.mark_dirty()
        self.grid.mark_dirty()
        self._sync_energy()

    @staticmethod
    def placed_sound(building):
        """Estructura colocada; si es un pilón y queda enganchado a la red, además el chispazo de conexión."""
        audio.play("place")
        if building.building_type == "pylon" and getattr(building, "is_powered", False):
            audio.play("pylon_link")

    def configure_building(self, building):
        """Gancho: la escena prepara una estructura recién registrada (la Fábrica recibe sus callbacks)."""

    def _on_building_destroyed(self, building):
        """Evento: recalcula la red eléctrica y el campo de flujo. Si cae un pilón, todo lo que
        dependía de él se queda sin energía (apagón en cascada local)."""
        self.nav.mark_dirty()
        self.grid.mark_dirty()
        self.grid.update()
        self._sync_energy()
        if building.building_type == "pylon":
            self.notify("¡Nodo de energía destruido! Las estructuras que dependían de él se apagan (apagón en cascada).", 4)
        ALERTS.push(f"{'Muro' if building.building_type == 'wall' else 'Estructura'} perdid{'o' if building.building_type == 'wall' else 'a'}"
                    + ("" if building.building_type == "wall" else f": {Building.SHORT[building.building_type]}"),
                    C.RED, key=("lost", building.building_type))
        if building.building_type == "bunker":
            self._bunker_lost(building)
        self.on_structure_lost(building)

    def on_structure_lost(self, building):
        """Gancho: una estructura acaba de caer (el Acto 2 lo usa para la reacción de VULCANO)."""

    def _cost(self, building_type):
        return round(Building.STATS[building_type]["cost"] * (1.0 - self.build_discount()))

    def _pay_repair(self, building):
        if self.res.spend_metal(C.REPAIR_COST):
            return True
        self.notify("Chatarra insuficiente para reparar.", 2)
        return False

    # --- energía: el Centro de Control (+50) y los pilones energizados (+5 cada uno) dan capacidad. ---
    # --- Cada pilón cuesta 1 de mantenimiento; torretas, extractores, focos y muros electrificados consumen la suya. ---
    # --- Sin energía suficiente, las más nuevas se apagan. ---
    def energy_capacity(self):
        w = self.world
        cap = C.ENERGY_CORE if w.core is not None and w.core.alive() else 0
        cap += C.ENERGY_PYLON * sum(1 for p in w.pylons if p.alive() and p.is_powered)
        return cap

    def _upkeep(self):
        """Mantenimiento de los pilones energizados (1 cada uno): siempre se paga primero."""
        return sum(p.energy_cost for p in self.world.pylons if p.alive() and p.is_powered)

    def _consumers(self):
        """Estructuras con consumo conectadas a la red, de la más antigua a la más nueva (sin pilones)."""
        return sorted((b for b in self.world.structures
                       if b.alive() and b.energy_cost > 0 and b.is_powered and b.building_type != "pylon"),
                      key=lambda b: b.build_order)

    def energy_used(self):
        return self._upkeep() + sum(b.energy_cost for b in self._consumers() if b.energized)

    def energy_free(self):
        return self.energy_capacity() - self.energy_used()

    def _sync_energy(self):
        """Reparte la capacidad entre las estructuras (las más antiguas primero) y apaga las que no caben."""
        cap, upkeep, used, cut = self.energy_capacity(), self._upkeep(), 0, []
        for b in self._consumers():
            if upkeep + used + b.energy_cost <= cap:
                used += b.energy_cost
                b.energized = True
            else:
                if b.energized:
                    cut.append(b)
                b.energized = False
        for b in self.world.structures:                      # las desconectadas de la red no consumen ni se apagan por energía
            if b.energy_cost > 0 and not b.is_powered:
                b.energized = True
        self.res.energy, self.res.energy_cap = upkeep + used, cap
        for b in cut:                                        # apagón: chispas sobre las estructuras que se quedan sin energía
            for _ in range(2):
                combat.FX.spark(b.pos, C.RED)
        if cut:
            self.energy_warning = 4.0
            self.notify("Sin energía suficiente: estructuras apagadas. Extiende la red con más pilones.", 4)

    def energy_tick(self):
        """Se llama cada fotograma tras actualizar la red: cubre pilones sabotados, apagones en cascada, etc."""
        self._sync_energy()

    # --- pausa táctica: la cámara se desacopla del Operador ---
    def toggle_tactical_pause(self):
        self.paused = not self.paused
        audio.play("build_mode" if self.paused else "build_mode_off")
        self.camera.returning = not self.paused       # al reanudar, la cámara regresa suavemente al Operador
        wave = getattr(self, "wave", None)
        if self.paused and wave is not None and wave.build_discount > 0:
            self.notify("Pausa táctica: se construye a precio completo (el -50% de la preparación solo vale en tiempo real).", 4)

    FREE_CAMERA = False           # modo Comandante (Acto 2, asedio): la cámara es libre también sin pausa

    def tactical_camera_event(self, event, map_size):
        """Clic central arrastrado: desplaza la cámara (en la pausa, o siempre en modo Comandante). True si lo consumió."""
        if ((getattr(self, "paused", False) or self.FREE_CAMERA) and event.type == pygame.MOUSEMOTION
                and getattr(event, "buttons", (0, 0, 0))[1]):
            self.camera.drag(event.rel, map_size)
            return True
        return False

    # --- entrada ---
    def handle_build_key(self, event):
        """Devuelve True si la tecla eligió (o canceló) un edificio."""
        if event.type != pygame.KEYDOWN:
            return False
        for key, btype in self.build_menu:
            if event.key == key:
                self.select_build(btype)
                return True
        if event.key in (pygame.K_ESCAPE, pygame.K_q):
            self.build_choice = None
            return True
        return False

    def build_guard(self, btype, rect=None):
        """Gancho: texto de aviso si ahora no se puede elegir/colocar `btype` (en `rect`); None si se puede. La Base
        Central lo usa para los pasos guiados de VULCANO (solo la estructura del hito, en su zona)."""
        return None

    def select_build(self, btype):
        """Elige (o desmarca) un edificio del panel; si sigue bloqueado, avisa de qué lo desbloquea."""
        if not self.res.structure_unlocked(btype):
            self.build_choice = None
            self.notify(f"{Building.LABELS[btype]} bloqueado: {self.res.structure_requirement(btype)}.", 4)
            return
        guard = self.build_guard(btype)
        if guard:
            self.build_choice = None
            self.notify(guard, 4)
            return
        self.build_choice = None if self.build_choice == btype else btype

    def process_build_input(self, dt, keys, mouse, mouse_pos):
        """Clic izquierdo + edificio elegido: construir (con retardo entre piezas al mantener pulsado)."""
        self.build_cd -= dt
        self.energy_warning = max(0.0, self.energy_warning - dt)
        self.player.build_mode = self.build_choice is not None or self.menu is not None   # el rifle calla mientras tanto
        if (mouse[0] and self.build_choice is not None and self.menu is None and not keys[pygame.K_r]
                and self.build_cd <= 0 and self.player.alive() and self.panel_hit(pygame.mouse.get_pos()) is None):
            self._try_build(mouse_pos)
            self.build_cd = max(self.build_cd, C.BUILD_DELAY)

    # --- menú de estructura (clic derecho): mejoras y venta ---
    def structure_under(self, world_pos):
        self._probe.rect = pygame.Rect(world_pos.x, world_pos.y, 1, 1)
        hits = [s for s in pygame.sprite.spritecollide(self._probe, self.world.structures, False)
                if s.building_type != "core"]
        return hits[0] if hits else None

    # --- producción de drones (clic der. sobre la Fábrica o el Búnker) ---
    def _producer_for(self, b):
        """Fábrica que recibe el encargo: la propia, o desde el Búnker la libre (menos carga) más cercana con energía."""
        if b.building_type == "fabrica":
            return b
        facs = [f for f in getattr(self.world, "factories", ()) if f.alive() and f.built and f.is_powered]
        return min(facs, key=lambda f: (f.load(), f.pos.distance_squared_to(b.pos))) if facs else None

    def production_block(self, b, kind):
        """(fábrica, motivo): el motivo vacío si el encargo se puede hacer ya (energía, ensamblaje, cola, tope y chatarra)."""
        f = self._producer_for(b)
        if f is None:
            has = any(f_.alive() for f_ in getattr(self.world, "factories", ()))
            return None, ("Ninguna Fábrica de Drones con energía y ensamblada" if has
                          else "No hay Fábrica de Drones: constrúyela para producir")
        if not f.is_powered:
            return f, "Fábrica sin energía: conéctala a la red con un pilón"
        ok, why = f.can_queue(kind, self.res)
        return f, "" if ok else why

    def _production_options(self, b):
        opts = []
        for kind in U.PRODUCTION_MENU:
            spec = U.DRONE_TYPES[kind]
            f, why = self.production_block(b, kind)
            if why:
                desc = why
            else:
                where = "esta Fábrica" if f is b else "la Fábrica libre más cercana"
                desc = f"Se ensambla en {where} · cola {f.load()} · {f.stats['production_time']:.0f} s"
            opts.append({"label": spec["name"], "desc": desc, "scrap": spec["cost"], "cores": spec["cores"],
                         "action": ("drone", kind), "enabled": not why, "card": drone_type_card(kind)})
        return opts

    def order_drone(self, b, kind):
        """Encarga el dron `kind` desde `b` (Fábrica o Búnker): cobra la chatarra y lo añade a la cola de la fábrica enlazada.
        Si no se puede (sin energía, sin chatarra, cola llena...), aviso y tono de error."""
        f, why = self.production_block(b, kind)
        spec = U.DRONE_TYPES[kind]
        if why:
            audio.play("error")
            self.notify(f"{spec['name']}: {why}.", 3)
            return False
        f.produce_drone(kind, self.res)
        self.notify(f"{spec['name']} en cola" + ("" if f is b else " en la Fábrica más cercana")
                    + f" (-{spec['cost']} chatarra).", 3)
        self._refresh_menu()
        return True

    def _menu_options(self, b):
        """Filas del menú: producción de drones (Fábrica y Búnker), rutas de especialización (torretas), mejoras del muro
        y venta."""
        opts = self._production_options(b) if b.building_type in ("fabrica", "bunker") else []
        free = self.energy_free()
        for key, name, desc, scrap, cores in b.route_options():
            extra = U.TURRET_ROUTES[b.building_type][key].get("energy_extra", 0)
            unlocked = self.res.route_unlocked(b.building_type, key)         # Tech-Tree: se desbloquea en el Terminal
            if unlocked:
                label, shown = f"Ruta {key}: {name}", desc
            else:
                need = U.TURRET_TECH[f"{b.building_type}_{key}"]["alloy"]
                label = f"Ruta {key}: {name} [BLOQUEADA]"
                shown = f"Se desbloquea en el Terminal Táctico (aleación {need})."
            opts.append({"label": label, "desc": shown, "scrap": scrap, "cores": cores, "energy": extra,
                         "action": ("route", key), "unlocked": unlocked,
                         "enabled": unlocked and self.res.can_pay(scrap, cores) and extra <= free})
        if b.route is not None:
            spec = U.TURRET_ROUTES[b.building_type][b.route]
            opts.append({"label": f"Ruta {b.route}: {spec['name']} (activa)", "desc": spec["desc"], "scrap": 0, "cores": 0,
                         "action": ("none", None), "enabled": False})
        up = b.wall_upgrade()
        if up is not None:
            level = b.level + 1
            opts.append({"label": f"Nivel {level}: {up['name']}", "desc": up["desc"], "scrap": up["cost"],
                         "cores": up["cores"], "energy": up["energy"], "action": ("wall_up", level),
                         "enabled": self.res.can_pay(up["cost"], up["cores"]) and up["energy"] <= free})
        elif b.building_type == "wall":
            opts.append({"label": "Nivel 3: ELECTRIFICADO (activo)", "desc": U.WALL_LEVELS[3]["desc"], "scrap": 0,
                         "cores": 0, "action": ("none", None), "enabled": False})
        if b.building_type == "bunker":                     # el Búnker no se vende: rehacerlo cuesta 400 y 2 núcleos
            opts.append({"label": "Búnker de Mando (no se puede vender)", "desc": "Solo cae si lo destruyen: habrá que ensamblarlo de nuevo",
                         "scrap": 0, "cores": 0, "action": ("none", None), "enabled": False})
            return opts
        verb = "Desmantelar" if b.building_type == "wall" else "Vender"
        opts.append({"label": f"{verb} (+{b.sell_value})", "desc": f"Devuelve el {round(C.SELL_REFUND * 100)}% del costo",
                     "scrap": -b.sell_value, "cores": -b.core_refund, "action": ("sell", None), "enabled": True})
        return opts

    def open_menu(self, b):
        self.menu = StructureMenu(b, self._menu_options(b))
        hints = getattr(self, "hints", None)
        if hints is not None:
            hints.done("right_menu")
            hints.done("turret_upgrade")

    def close_menu(self):
        self.menu = None

    def _refresh_menu(self):
        if self.menu is not None:
            if self.menu.building.alive():
                self.menu.options = self._menu_options(self.menu.building)
            else:
                self.menu = None

    def menu_choose(self, index):
        """Ejecuta la opción `index` (0-based) del menú abierto. Devuelve True si hizo algo."""
        if self.menu is None or not 0 <= index < len(self.menu.options):
            return False
        b, opt = self.menu.building, self.menu.options[index]
        kind, key = opt["action"]
        if kind == "drone":
            return self.order_drone(b, key)
        if kind == "sell":
            self.sell(b)
            self.menu = None
            return True
        if kind not in ("route", "wall_up"):
            return False
        if kind == "route" and not opt.get("unlocked", True):
            self.notify(f"{opt['label']}: desbloquéala en el Terminal Táctico (Base Central).", 3)
            return False
        scrap, cores, energy = opt["scrap"], opt["cores"], opt.get("energy", 0)
        if not self.res.can_pay(scrap, cores):
            falta = "Núcleos de plasma" if self.res.metal >= scrap else "Chatarra"
            self.notify(f"{falta} insuficientes para la {opt['label']}.", 2)
            return False
        if energy > self.energy_free():
            self.energy_warning = 4.0
            self.notify(f"Energía insuficiente: {opt['label']} necesita +{energy} y quedan {self.energy_free()}. "
                        "Extiende la red con más pilones.", 3)
            return False
        self.res.pay(scrap, cores)
        if kind == "route":
            b.choose_route(key)
        else:
            b.apply_wall_level(key)
            self.grid.mark_dirty()
            self.grid.update()
        self._sync_energy()
        self.notify(f"{b.label}: {opt['label']} (-{scrap} chatarra, -{cores} núcleos).", 3)
        self._refresh_menu()
        return True

    def upgrade_under_cursor(self):
        """Tecla E sobre un muro: aplica su siguiente mejora (alternativa al menú). Devuelve True si hizo algo."""
        b = self.structure_under(self.camera.to_world(pygame.mouse.get_pos()))
        if b is None or b.wall_upgrade() is None:
            return False
        for i, opt in enumerate(self._menu_options(b)):
            if opt["action"][0] == "wall_up":
                self.menu = StructureMenu(b, self._menu_options(b))
                self.menu_choose(i)
                self.menu = None
                return True
        return False

    def sell(self, b):
        """Vende/desmantela una estructura: devuelve el 70% de su costo (chatarra y núcleos)."""
        if b is None or b.building_type in ("core", "bunker") or not b.alive():
            return False
        self.res.add_metal(b.sell_value)
        self.res.add_cores(b.core_refund)
        value, label = b.sell_value, b.label
        b.dismantle()
        self.nav.mark_dirty()
        self.grid.mark_dirty()
        self.grid.update()
        self._sync_energy()
        self.notify(f"{label} vendido (+{value} chatarra).", 3)
        return True

    def handle_construction_event(self, event):
        """Menú de estructura y clic derecho. Devuelve True si consumió el evento."""
        if self.menu is not None and not self.menu.building.alive():
            self.menu = None
        if self.menu is not None:
            if event.type == pygame.KEYDOWN:
                if event.key in (pygame.K_ESCAPE, pygame.K_q):
                    self.menu = None
                    return True
                if event.key in _DIGITS:
                    self.menu_choose(_DIGITS.index(event.key))
                    return True
            elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                idx = self.menu.hit(self.camera, event.pos)
                if idx is not None:
                    self.menu_choose(idx)
                else:
                    self.menu = None
                return True
            elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 3:
                b = self.structure_under(self.camera.to_world(event.pos))
                self.menu = None                                    # cierra; sobre otra estructura, abre la suya
                if b is not None:
                    self.open_menu(b)
                return True
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            btype = self.panel_hit(event.pos)
            if btype is not None:
                self.select_build(btype)
                return True
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 3:
            b = self.structure_under(self.camera.to_world(event.pos))
            if b is not None:
                self.build_choice = None
                self.open_menu(b)
            else:
                self.on_air_right_click()
            return True
        return False

    def panel_hit(self, pos):
        """Edificio del botón del panel de construcción bajo `pos` (pantalla), o None."""
        hud = getattr(getattr(self, "game", None), "hud", None)
        menu = getattr(self, "build_menu", None)
        if hud is None or not menu:
            return None
        for rect, btype in hud.build_slots(menu, self.panel_shift):
            if rect.collidepoint(pos):
                return btype
        return None

    def hover_card(self, mouse):
        """(clave, tarjeta) de lo que hay bajo el ratón: botón del panel de construcción o estructura del mapa. Con un menú
        abierto, solo la tarjeta de la fila bajo el ratón (las de producción llevan las estadísticas del dron)."""
        if self.menu is not None:
            idx = self.menu.hit(self.camera, mouse)
            card = self.menu.options[idx].get("card") if idx is not None else None
            return (("menu", idx), card) if card is not None else None
        btype = self.panel_hit(mouse)
        if btype is not None:
            if not self.res.structure_unlocked(btype):
                return ("build", btype), locked_card(btype, self.res)
            return ("build", btype), building_card(btype, self._cost(btype), self.res, self.energy_free())
        world_pos = self.camera.to_world(mouse)
        bunker_card = self.bunker_hover_card(world_pos)
        if bunker_card is not None:                         # sitio de obra del Búnker y su consola
            return bunker_card
        unit = self.unit_under_cursor(world_pos)
        if unit is not None:                                # dron aliado o unidad hostil a la vista
            self.hovered_unit = unit
            ally = unit in self.world.drones
            return ("unit", id(unit)), drone_card(unit) if ally else enemy_card(unit)
        item = pickup_under(self.pickup_groups(), world_pos)
        if item is not None:                                # materiales y componentes del suelo
            card = pickup_card(item, self.res)
            if card is not None:
                return ("pickup", id(item)), card
        b = self.structure_under(world_pos)
        if b is not None:
            return ("struct", id(b)), structure_card(b)
        return None

    def unit_under_cursor(self, world_pos):
        """Dron aliado bajo el ratón (tienen prioridad: van en enjambre sobre los enemigos) o, si no, unidad hostil visible."""
        w = self.world
        drone = unit_under((getattr(w, "drones", ()),), world_pos)
        if drone is not None:
            return drone
        foes = [u for group in (getattr(w, "enemies", ()), getattr(w, "scavengers", ())) for u in group
                if self.unit_visible(u)]
        return unit_under((foes,), world_pos)

    def unit_visible(self, u):
        """Lo hostil solo se identifica si se ve: fuera de la niebla y, los carroñeros, detectados."""
        if not getattr(u, "detected", True):
            return False
        fog = getattr(self, "fog", None)
        return fog is None or not hasattr(fog, "is_revealed") or fog.is_revealed(u.pos)

    def draw_unit_reticle(self, screen, unit, color):
        """Retícula tenue bajo la unidad señalada: disco translúcido, aro y cuatro marcas para ubicarla en el enjambre."""
        c = self.camera.to_screen(unit.pos)
        r = max(unit.rect.w, unit.rect.h) // 2 + 8
        size = r * 2 + 12
        surf = pygame.Surface((size, size), pygame.SRCALPHA)
        mid = size // 2
        pygame.draw.circle(surf, (*color, 45), (mid, mid), r)
        pygame.draw.circle(surf, (*color, 190), (mid, mid), r, 2)
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            pygame.draw.line(surf, (*color, 230), (mid + dx * (r - 4), mid + dy * (r - 4)),
                             (mid + dx * (r + 5), mid + dy * (r + 5)), 2)
        screen.blit(surf, surf.get_rect(center=(round(c.x), round(c.y))))

    def pickup_groups(self):
        w = self.world
        return (w.scraps, w.core_items, w.ammo_boxes, w.parts)

    def draw_tooltips(self, screen):
        """Tooltip a los 0,5 s de hover; desaparece al mover el ratón fuera. No bloquea nada."""
        tt = self.game.tooltips
        mouse = pygame.mouse.get_pos()
        self.hovered_unit = None
        found = self.hover_card(mouse)
        if found is None:
            tt.clear()
        elif found[0][0] == "unit":                          # unidades: al instante (se mueven) y con su retícula
            tt.clear()
            unit = self.hovered_unit
            self.draw_unit_reticle(screen, unit, found[1].get("color", C.CYAN))
            self.game.hud.draw_card(screen, mouse, found[1])
        elif tt.hover(found[0]):
            self.game.hud.draw_card(screen, mouse, found[1])

    def draw_structure_menu(self, screen):
        if self.menu is not None:
            if self.menu.building.alive():
                self._refresh_menu()                            # chatarra, energía y colas cambian con el menú abierto
                self.menu.draw(screen, self.game.hud, self.camera, self.res)
            else:
                self.menu = None

    # --- geometria y validacion ---
    def _deposit_at(self, pos):
        near = [d for d in self.world.deposits if d.pos.distance_to(pos) <= C.BUILD_GRID]
        return min(near, key=lambda d: d.pos.distance_squared_to(pos)) if near else None

    def _ghost_rect(self, building_type, mouse_pos):
        g = C.BUILD_GRID
        r = pygame.Rect(0, 0, *Building.SIZES[building_type])
        if building_type == "fabrica":                      # 2x2: centrada en una esquina de la rejilla
            r.center = (round(mouse_pos.x / g) * g, round(mouse_pos.y / g) * g)
        elif building_type == "compuerta":                  # 1x2: una celda de ancho, centrada en una línea de la rejilla
            r.center = (int(mouse_pos.x // g) * g + g // 2, round(mouse_pos.y / g) * g)
        elif building_type == "extractor" and self._deposit_at(mouse_pos) is not None:
            r.center = (round(self._deposit_at(mouse_pos).pos.x), round(self._deposit_at(mouse_pos).pos.y))
        else:
            r.center = (int(mouse_pos.x // g) * g + g // 2, int(mouse_pos.y // g) * g + g // 2)
        return r

    def _can_place(self, building_type, rect):
        w = self.world
        if not self.map_rect.contains(rect):
            return False
        if self.player.alive() and self.player.rect.colliderect(rect):
            return False
        self._probe.rect = rect
        if pygame.sprite.spritecollideany(self._probe, w.solids) is not None:
            return False
        deposit = self._deposit_at(Vector2(rect.center))
        if building_type == "extractor":
            if deposit is None or deposit.depleted or deposit.extractor is not None:
                return False
            if Vector2(rect.center).distance_to(deposit.pos) > 2:
                return False
        elif pygame.sprite.spritecollideany(self._probe, w.deposits) is not None:
            return False                                    # no tapar los depósitos
        if building_type == "pylon" and not self.grid.can_place_pylon(Vector2(rect.center)):
            return False                                    # enlace obligatorio: sin pilones flotantes
        return not self._would_trap_player(rect)

    MIN_FREE_REGION = 40          # celdas: por debajo de esto el jugador quedaría atrapado en una bolsa

    def _would_trap_player(self, new_rect):
        """True si, con `new_rect` construido, el jugador quedaría encerrado: sin camino al borde del mapa
        y en una región de menos de 40 celdas (BFS en rejilla). Una plaza amplia y sellada no cuenta."""
        if not self.player.alive():
            return False
        g = C.BUILD_GRID
        cols, rows = self.map_rect.w // g, self.map_rect.h // g
        blocked = set()
        for r in [s.rect for s in self.world.solids] + [new_rect]:
            for cx in range(r.left // g, (r.right - 1) // g + 1):
                for cy in range(r.top // g, (r.bottom - 1) // g + 1):
                    blocked.add((cx, cy))
        start = (max(0, min(cols - 1, int(self.player.pos.x // g))), max(0, min(rows - 1, int(self.player.pos.y // g))))
        seen, frontier = {start}, [start]
        while frontier:
            cx, cy = frontier.pop()
            if cx in (0, cols - 1) or cy in (0, rows - 1) or len(seen) >= self.MIN_FREE_REGION:
                return False
            for n in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                if n not in seen and n not in blocked and 0 <= n[0] < cols and 0 <= n[1] < rows:
                    seen.add(n)
                    frontier.append(n)
        return True

    def _energy_ok(self, btype):
        self._sync_energy()
        if btype == "pylon":                                 # aporta +5 y cuesta 1: siempre suma, nunca se bloquea
            return True
        return Building.STATS[btype]["energy"] <= self.energy_free()

    def _try_build(self, mouse_pos):
        btype = self.build_choice
        if not self.res.structure_unlocked(btype):
            return
        rect = self._ghost_rect(btype, mouse_pos)
        if not self._can_place(btype, rect):
            return
        guard = self.build_guard(btype, rect)
        if guard:
            self.notify(guard, 3)
            self.build_cd = 0.5
            return
        if not self.INSTANT_BUILD:
            self._queue_site(btype, rect)
            return
        scrap, cores = self._cost(btype), Building.STATS[btype]["cores"]
        if not self._energy_ok(btype):                       # la energía limita las torretas: hacen falta más pilones
            need = Building.STATS[btype]["energy"]
            self.energy_warning = 4.0
            self.notify(f"Energía insuficiente: {Building.LABELS[btype]} necesita {need} y quedan {self.energy_free()}. "
                        "Extiende la red con más pilones.", 3)
            self.build_cd = 0.5
            return
        if not self.res.can_pay(scrap, cores):               # chatarra y núcleos se cobran a la vez
            self.notify("Núcleos de plasma insuficientes." if self.res.metal >= scrap else "Chatarra insuficiente.", 2)
            self.build_cd = 0.5
            return
        self.res.pay(scrap, cores)
        deposit = self._deposit_at(Vector2(rect.center)) if btype == "extractor" else None
        b = create_building(btype, rect.center, deposit=deposit)
        self._register(b)                                                       # construccion instantanea
        self.grid.update()                                                      # BFS al construir
        self._sync_energy()
        self.placed_sound(b)
        self.on_built(b)

    # --- red de energía: visualización ---
    def _power_nodes(self):
        """Nodos que alimentan: Centro de Control y pilones energizados."""
        w = self.world
        nodes = [w.core] if w.core is not None and w.core.alive() else []
        return nodes + [p for p in w.pylons if p.alive() and p.is_powered]

    def _in_power_zone(self, where):
        """¿Llega la red? `where`: un punto o la huella (Rect) del edificio; con huella, basta con que el radio de un nodo
        energizado la toque (la misma regla que usa la red para conectar consumidores)."""
        if isinstance(where, pygame.Rect):
            return any(reaches(n.pos, where) for n in self._power_nodes())
        return any(n.pos.distance_to(where) <= C.POWER_RADIUS for n in self._power_nodes())

    @staticmethod
    def _disc(screen, center, radius, color, fill=34, edge=120, width=1):
        disc = pygame.Surface((radius * 2, radius * 2), pygame.SRCALPHA)
        pygame.draw.circle(disc, (*color, fill), (radius, radius), radius)
        pygame.draw.circle(disc, (*color, edge), (radius, radius), radius, width)
        screen.blit(disc, disc.get_rect(center=(round(center[0]), round(center[1]))))

    def draw_network_overlay(self, screen):
        """Al elegir una estructura para construir o en pausa táctica: radios de cobertura (cian translúcido), líneas de
        energía entre nodos (blanco/amarillo si conducen, rojo apagado si no) y alcance de la estructura bajo el cursor."""
        paused = getattr(self, "paused", False)
        if self.build_choice is None and not paused:
            return
        cam = self.camera
        for node in [n for n in self._power_nodes()]:
            self._disc(screen, cam.to_screen(node.pos), C.POWER_RADIUS, (0, 225, 255), 18, 90)
        grid = getattr(self, "grid", None)
        for a, b, powered in (grid.links if grid is not None else ()):
            pa, pb = cam.to_screen(a.pos), cam.to_screen(b.pos)
            if powered:
                pygame.draw.line(screen, (255, 245, 170), pa, pb, 3)
                pygame.draw.line(screen, C.WHITE, pa, pb, 1)
            else:
                pygame.draw.line(screen, (120, 40, 50), pa, pb, 1)
        if paused and self.menu is None:                                  # proyección de alcance al pasar el ratón
            b = self.structure_under(cam.to_world(pygame.mouse.get_pos()))
            if b is not None and b.range:
                self._disc(screen, cam.to_screen(b.pos), int(b.effective_range()), C.YELLOW, 26, 150, 2)

    # --- dibujo ---
    def draw_build_preview(self, screen):
        self.draw_network_overlay(screen)
        if self.build_choice is None or not self.player.alive():
            return
        cam, btype = self.camera, self.build_choice
        stats = Building.STATS[btype]
        rect = self._ghost_rect(btype, cam.to_world(pygame.mouse.get_pos()))
        valid = self._can_place(btype, rect)
        ok = valid and self.res.can_pay(self._cost(btype), stats["cores"]) and self._energy_ok(btype)
        needs_grid = btype in Building.REQUIRES_POWER
        unpowered = ok and needs_grid and not self._in_power_zone(rect)
        color = C.GREEN if ok else C.RED
        if unpowered:
            color = (255, 170, 30)                     # ámbar: se puede construir, pero quedará apagada (fuera de la red)
        srect = cam.apply(rect)
        rng = int(stats["range"])
        if rng:      # preview translúcido del alcance (torreta) o del radio de energía (pilón)
            disc = pygame.Surface((rng * 2, rng * 2), pygame.SRCALPHA)
            pygame.draw.circle(disc, (*color, 40), (rng, rng), rng)
            pygame.draw.circle(disc, (*color, 130), (rng, rng), rng, 2)
            screen.blit(disc, disc.get_rect(center=srect.center))
        silhouette = art.ghost_image(btype, tuple(srect.size), tuple(color))
        if silhouette is not None:                                        # bloque 3D translúcido, no un cuadrado vacío
            screen.blit(silhouette, srect.topleft)
        else:
            ghost = pygame.Surface(srect.size, pygame.SRCALPHA)
            ghost.fill((*color, 90))
            screen.blit(ghost, srect)
            pygame.draw.rect(screen, color, srect, 2)
        hud = getattr(getattr(self, "game", None), "hud", None)           # estado energético futuro junto al fantasma
        if hud is not None and valid:
            cost = stats["energy"]
            used, cap = self.res.energy, self.res.energy_cap
            if unpowered:
                label, tint = "SIN RED: quedará apagada", color
            elif cost:
                label, tint = f"{used} -> {used + cost}/{cap}", (C.YELLOW if used + cost <= cap else C.RED)
            else:
                label, tint = "", color
            if label:
                hud.icon(screen, "energy", (srect.x - 2, srect.y - 16), 6)
                hud.text(screen, label, (srect.x + 8, srect.y - 25), "s", tint)
