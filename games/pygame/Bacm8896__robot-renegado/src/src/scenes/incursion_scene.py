"""Incursión jugable (INCURSION): exploración con niebla de guerra, combate y saqueo con dificultad escalable.

El Operador sale de la Base Central a un complejo industrial en ruinas para una de las 5 operaciones del tablero del
Terminal (UNITS.INCURSION_OPS), cada una con su objetivo:
- Op 1 Reconocimiento (loot): 3 depósitos de chatarra custodiados por Scouts;
- Op 2 Saqueo de Yacimiento (drill): activar un taladro y defenderlo de las oleadas durante 90 s;
- Op 3 Convoy Blindado (convoy): abatir los 2 Arietes escoltados antes de que lleguen a su salida;
- Op 4 Complejo Tecnológico (hack): hackear la terminal del nido custodiada por Tanques (planos de la Fábrica);
- Op 5 Recuperación Crítica (timed): saquear los alijos antes de que acabe el tiempo, con la guardia reforzada.
El botín (núcleos, aleación, módulo y planos incluidos) va en riesgo hasta extraer:
- extracción con vida: se asegura el 100% y, si se cumplió el objetivo por primera vez, el bono y la siguiente operación;
- muerte o objetivo fallido (taladro destruido, convoy escapado, tiempo agotado): se conserva solo el 50%."""
import math
import random

import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.entities.drones import AuraDrone
from src.entities.enemy import roll_core_drop, roll_drop
from src.entities.interactable import Beacon, LootCache, PlasmaPoint
from src.entities.resource_node import MiningDrill
from src.managers.state_machine import GameState, SubAct
from src.map.levels import build_incursion_level
from src.mechanics import incursion as inc
from src.mechanics.fog import FogOfWar
from src.scenes.level_base import LevelScene
from src.ui import loot_art


class IncursionScene(LevelScene):
    SUB_ACT = SubAct.S2_X
    NEXT = GameState.ACT_2_BASE
    HINT = "WASD mover · SHIFT dash · clic izq. disparar · clic der. golpe · E saquear/recoger · ESPACIO pausa · mantén la baliza verde para extraer"
    HUNT_PLAYER = True
    SCRAP_DROP = C.INCURSION_SCRAP_DROP
    INFINITE_AMMO = False                              # Acto 2+: munición limitada

    def enter(self, op=None, mode=None, kind=None):
        if op is None:                                     # llamadas antiguas: "initial"/"raid" -> Op 1; kind "tech" -> Op 4
            op = "tech" if kind == "tech" else "recon"
        self.op = op
        self.spec = U.INCURSION_OPS[op]
        self.kind = self.spec["layout"]                    # mapa: "eco" (depósitos y plasma) | "tech" (sala del nido)
        self.goal = self.spec["objective"]                 # loot | drill | convoy | hack | timed
        self.fail_menu = False                             # pantalla de fallo (R reintentar / ESC volver a la base)
        self.fail_title = "OPERADOR CAÍDO"
        self._loss_applied = False
        self._fail_buttons = {}
        self.seed = random.randrange(10 ** 6)
        super().enter()

    def make_level(self):
        return build_incursion_level(self.seed, self.res.op_level(self.op), self.kind)

    # ------------------------------------------------------------------ preparación
    def setup(self):
        L = self.level
        self.rng = random.Random(self.seed)
        self.inc_level = self.res.op_level(self.op)
        self.res.equipped = True
        self.player.equipped = True
        self.loot = 0                                      # metal acarreado, en riesgo hasta extraer
        self.loot_cores = 0                                # Núcleos de Plasma acarreados (también en riesgo)
        self.plasma_cache = None
        self.plasma_point = None
        self.capture_alarm = False
        self.done = False
        self.extract_timer = 0.0
        self.fog = FogOfWar(L.cols, L.rows, C.LEVEL_CELL, C.INCURSION_VISION, walls=L.wall_cells)
        self.player.aim_filter = lambda e: self.fog.is_visible(e.pos)    # la asistencia no apunta a lo que no se ve
        self.beacon = self.add_dynamic(Beacon(L.marker("extract"), radius=46, color=C.GREEN))
        self.caches = []
        self.vault = None                                  # terminal del nido (Op 4)
        self.loot_module = False                           # Módulo de Mando acarreado (en riesgo hasta extraer)
        self.loot_alloy = 0                                # aleación militar acarreada (en riesgo)
        self.loot_blueprints = False                       # planos de la Fábrica de Drones acarreados (Op 4, en riesgo)
        self.goal_done = self.goal == "loot"               # Op 1: basta con extraer con vida
        self.drill = None                                  # taladro (Op 2)
        self.drill_timer = self.wave_timer = 0.0
        self.rams = []                                     # Arietes del convoy (Op 3)
        self.convoy_exit = None
        self.time_left = self.spec.get("time_limit")       # contrarreloj (Op 5)
        if self.kind == "tech":
            self._setup_tech(L)
        else:
            self._setup_eco(L)
        if self.goal == "convoy":
            self._setup_convoy(L)
        self._spawn_roamers()
        self.fog.update(self.player.pos)
        self.aura_drone = None
        if self.res.aura_drone:                            # chasis 6/6: AURA vuela de escolta junto al Operador
            self.aura_drone = AuraDrone(self.player.pos + Vector2(0, -50))
            self.world.drones.add(self.aura_drone)
            self.all_sprites.add(self.aura_drone)
        self._briefing()

    def _briefing(self):
        mult = int(round((inc.enemy_scale(self.inc_level) - 1) * 100))
        self.say("AURA", f"{self.res._label(self.op)} (nivel {self.inc_level}): {self.spec['summary']} Enemigos +{mult}%.", 8)
        radar = {"loot": "Marco los depósitos (amarillo) y la baliza de extracción (verde) en tu radar.",
                 "drill": "Marco el taladro (naranja) en tu radar: actívalo con E y no dejes que lo destruyan.",
                 "convoy": "Marco los Arietes del convoy (naranja) y su salida (rojo). Atácalos por los costados.",
                 "hack": "Marco la terminal del nido (magenta) en tu radar. Hackearla da la alarma.",
                 "timed": f"Tienes {int(self.time_left) if self.time_left else 0} s para saquear los alijos (amarillo)."}
        self.say("AURA", radar[self.goal], 8)

    def _setup_eco(self, L):
        amounts = inc.loot_amounts(self.inc_level, len(L.markers["deposit"]), self.rng)
        guards = inc.patrol_size(self.inc_level) + self.spec.get("extra_guards", 0)   # Op 5: guardia reforzada
        for pos, amount in zip(L.markers["deposit"], amounts):
            cache = LootCache(pos, "Saquear depósito", "scrap")
            cache.amount = amount                                  # botín de este alijo (120-180 a nivel 1)
            cache.on_interact = self._loot_cache
            self.caches.append(self.add_interactable(cache))
            for kind in inc.pick_kinds(self.inc_level, guards, self.rng):
                self.spawn_enemy(kind, self._patrol_spot(pos))
        for pos in L.markers.get("plasma_cache", []):             # alijo especial de plasma (1-3 núcleos), custodiado
            cache = LootCache(pos, "Saquear alijo de plasma", "plasma")
            cache.on_interact = self._loot_plasma
            self.plasma_cache = self.add_interactable(cache)
            for kind in inc.pick_kinds(self.inc_level, inc.patrol_size(self.inc_level), self.rng):
                self.spawn_enemy(kind, self._patrol_spot(pos))
        for pos in L.markers.get("plasma_extractor", []):         # extractor de plasma: zona de riesgo con guardias pesados
            self.plasma_point = self.add_dynamic(PlasmaPoint(pos, U.PLASMA_POINTS["capture_radius"]))
            guards = inc.patrol_size(self.inc_level) + U.PLASMA_POINTS["guard_extra"]
            for kind in inc.pick_kinds(self.inc_level + 2, guards, self.rng):
                self.spawn_enemy(kind, self._patrol_spot(pos))

    def _setup_tech(self, L):
        """Sala lejana del nido: el taladro del yacimiento (Op 2) o la terminal con guardia densa y pesada (Op 4)."""
        pos = L.marker("vault")
        if self.goal == "drill":
            self.drill = self.add_interactable(MiningDrill(pos, self.spec["drill_hp"]))
            self.drill.on_interact = self._start_drill
            for kind in inc.pick_kinds(self.inc_level, inc.patrol_size(self.inc_level), self.rng):
                self.spawn_enemy(kind, self._patrol_spot(pos))
            return
        vault = LootCache(pos, "Hackear terminal del nido", "module")
        vault.amount = inc.vault_loot(self.inc_level, self.rng)          # chatarra además del módulo (150-200 a nivel 1)
        vault.hacking = False
        vault.on_interact = self._start_hack
        self.vault = self.add_interactable(vault)
        for kind in inc.nest_kinds(self.inc_level, self.rng):
            self.spawn_enemy(kind, self._patrol_spot(pos))
        for _ in range(self.spec.get("tanks", 0)):                       # Op 4: Tanques de guardia en la terminal
            self.spawn_enemy("tank", self._patrol_spot(pos))

    def _setup_convoy(self, L):
        """Op 3: los Arietes salen de la sala más lejana del inicio y cruzan el mapa hacia su salida, escoltados. Van lentos y
        no se desvían para perseguir al Operador; sus escoltas sí."""
        start, extract = L.marker("start"), L.marker("extract")
        rooms = [r for r in L.rooms if self._room_center(r).distance_to(start) > 300
                 and self._room_center(r).distance_to(extract) > 300]
        origin = self._room_center(max(rooms, key=lambda r: self._room_center(r).distance_to(start)))
        self.convoy_exit = self._room_center(max(rooms, key=lambda r: self._room_center(r).distance_to(origin)))
        for _ in range(self.spec["rams"]):
            ram = self.spawn_enemy("ariete", self._patrol_spot(origin))
            ram.hp = ram.max_hp = ram.max_hp * self.spec["ram_hp_mult"]
            ram.speed *= self.spec["ram_speed_mult"]
            ram.convoy = True
            self._make_patrol(ram, [Vector2(self.convoy_exit)], alert=True)
            self.rams.append(ram)
            for j, kind in enumerate(inc.pick_kinds(self.inc_level, self.spec["escorts"], self.rng)):
                e = self.spawn_enemy(kind, self._patrol_spot(origin))
                e.escort_of, e.escort_off = ram, Vector2(80, 0).rotate(360 * j / self.spec["escorts"])
                e.run_flank = e.flank

    def _patrol_spot(self, center):
        room = self.level.room_rect(center)                        # la patrulla custodia su sala, no la de al lado
        for _ in range(30):
            p = center + Vector2(self.rng.uniform(90, 230), 0).rotate(self.rng.uniform(0, 360))
            c, r = int(p.x // C.LEVEL_CELL), int(p.y // C.LEVEL_CELL)
            if (0 <= c < self.level.cols and 0 <= r < self.level.rows and not self.level.wall[r][c]
                    and (room is None or room.collidepoint(p.x, p.y))):
                return p
        return Vector2(center)

    # ------------------------------------------------------------------ patrullas y refuerzos
    def _room_center(self, room):
        """Centro de la sala, o la celda libre más cercana si una barricada lo ocupa."""
        wall = self.level.wall
        c, r = min(((c, r) for r in range(room.y, room.bottom) for c in range(room.x, room.right) if not wall[r][c]),
                   key=lambda cr: (cr[0] - room.centerx) ** 2 + (cr[1] - room.centery) ** 2)
        return Vector2((c + 0.5) * C.LEVEL_CELL, (r + 0.5) * C.LEVEL_CELL)

    def _make_patrol(self, enemy, stops, first=0, alert=False):
        """Ruta de `enemy` por los puntos `stops`: camina (a 55% de su velocidad) de uno a otro por salas y pasillos. Con
        `alert` (refuerzos) corre hasta el último punto y allí se queda de guardia."""
        enemy.run_speed, enemy.run_flank = enemy.speed, enemy.flank
        enemy.patrol = {"stops": stops, "i": first % len(stops), "alert": alert, "was": False,
                        "check": self.rng.randrange(12), "leg": self.level.waypoints(enemy.pos, stops[first % len(stops)])}

    def _spawn_roamers(self):
        """Patrullas errantes: grupos que recorren 3 salas lejos del inicio, para que no haya zonas seguras."""
        origin = self.level.marker("start")
        rooms = [r for r in self.level.rooms if self._room_center(r).distance_to(origin) > 600]
        for _ in range(inc.roamer_groups(self.inc_level)):
            if len(rooms) < 3:
                break
            stops = [self._room_center(r) for r in self.rng.sample(rooms, 3)]
            for kind in inc.pick_kinds(self.inc_level, inc.roamer_size(self.inc_level), self.rng):
                e = self.spawn_enemy(kind, self._patrol_spot(stops[0]))
                self._make_patrol(e, stops, first=1)

    def _send_wave(self, target, size):
        """`size` enemigos salen de las salas más cercanas a `target` que el Operador no ve y corren hacia allí."""
        rooms = sorted(self.level.rooms, key=lambda r: self._room_center(r).distance_squared_to(target))
        hidden = [r for r in rooms if self._room_center(r).distance_to(target) > 480
                  and not self.fog.is_visible(self._room_center(r))]
        pool = (hidden or rooms[-3:])[:3]
        for i, kind in enumerate(inc.pick_kinds(self.inc_level, size, self.rng)):
            e = self.spawn_enemy(kind, self._patrol_spot(self._room_center(pool[i % len(pool)])))
            self._make_patrol(e, [Vector2(target)], alert=True)

    def _call_reinforcements(self):
        """Al abrir un alijo suena la alarma: acuden enemigos desde las salas más cercanas que el Operador no ve."""
        self._send_wave(self.player.pos, inc.reinforcement_size(self.inc_level))
        self.notify("¡Alarma! Llegan refuerzos.", 4)

    def steer_guards(self):
        """Además de despertar a los guardianes: las patrullas y los refuerzos caminan su ruta mientras no persiguen. Los
        Arietes del convoy nunca persiguen y sus escoltas los acompañan mientras no ven al Operador."""
        super().steer_guards()
        if not self.player.alive():
            return
        for e in self.world.enemies:
            if getattr(e, "convoy", False):
                e.chasing = False
            ram = getattr(e, "escort_of", None)
            if ram is not None:
                if not ram.alive():
                    e.escort_of = None                              # convoy roto: queda como guardia normal
                    e.flank, e.straight = e.run_flank, False
                elif not e.chasing:
                    e.flank, e.straight = 0, True
                    e.target_pos = ram.pos + e.escort_off
                    continue
                else:
                    e.flank, e.straight = e.run_flank, False
            pt = getattr(e, "patrol", None)
            if pt is None:
                continue
            if e.chasing:                                           # ve al jugador: abandona la ruta y ataca
                e.speed, e.flank, e.straight, pt["was"] = e.run_speed, e.run_flank, False, True
                continue
            if pt["was"]:                                           # lo perdió: retoma su ruta desde donde está
                pt["was"] = False
                pt["leg"] = self.level.waypoints(e.pos, pt["stops"][pt["i"]])
            e.speed = e.run_speed if pt["alert"] else e.run_speed * 0.55
            e.flank, e.straight = 0, True
            while pt["leg"] and e.pos.distance_to(pt["leg"][0]) < 26:
                pt["leg"].pop(0)
            pt["check"] += 1
            if pt["leg"] and pt["check"] % 12 == 0 and not self.level.line_clear(e.pos, pt["leg"][0], 9):
                pt["leg"] = self.level.waypoints(e.pos, pt["stops"][pt["i"]])   # se desvió (empujones): recalcula la ruta
            if not pt["leg"]:
                if pt["alert"]:                                     # refuerzo llegado a destino: de guardia
                    e.speed, e.flank, e.straight = e.run_speed, e.run_flank, False
                    del e.patrol
                    continue
                pt["i"] = (pt["i"] + 1) % len(pt["stops"])
                pt["leg"] = self.level.waypoints(e.pos, pt["stops"][pt["i"]])
            if pt["leg"]:
                e.target_pos = Vector2(pt["leg"][0])

    # ------------------------------------------------------------------ enemigos escalados
    def spawn_enemy(self, kind, pos, **kwargs):
        e = super().spawn_enemy(kind, pos, **kwargs)
        mult = inc.enemy_scale(self.inc_level)
        e.hp = e.max_hp = e.max_hp * mult                  # +10% de vida y daño por nivel
        e.damage = e.damage * mult
        e.power = mult                                     # ...también en disparos, obuses y embestidas
        self.all_sprites.remove(e)                         # solo se dibujan si están a la vista (niebla)
        return e

    def _on_enemy_death(self, enemy):
        self.kills += 1
        heavy = enemy.enemy_type in ("tank", "ariete")
        if self.rng.random() < inc.part_chance(self.inc_level, heavy):
            self.drop_part(enemy.pos)                      # mayor probabilidad a mayor nivel
        self.roll_ammo_drop(enemy.pos, enemy.enemy_type, self.rng)
        self.roll_medkit_drop(enemy.pos, enemy.enemy_type, self.rng)
        cores = roll_core_drop(enemy.enemy_type, self.rng)
        if cores:
            self.drop_core(enemy.pos + Vector2(14, 10), cores)
        value = roll_drop(enemy.enemy_type, self.rng)      # chatarra del tipo de enemigo, escalada por nivel
        if value and self.rng.random() < self.SCRAP_DROP:
            self.drop_scrap(enemy.pos, inc.scrap_value(self.inc_level, value))

    def collect_scrap(self, amount):
        self.loot += amount                                # la chatarra recogida queda en riesgo

    def collect_cores(self, amount):
        self.loot_cores += amount                          # los núcleos también: se aseguran al extraer

    def _start_hack(self, scene, it):
        """E sobre la cámara: empieza el hackeo y el nido da la alarma (toda la guardia cercana acude)."""
        if it.hacking:
            return
        it.hacking = True
        for e in self.world.enemies:
            if e.pos.distance_to(it.pos) < 700:
                e.chasing = True
        self.notify("¡Hackeo en curso! El nido ha dado la alarma: permanece junto a la cámara.", 5)

    def _update_hack(self, dt):
        v = self.vault
        if v is None or not v.enabled or not v.hacking:
            return
        if v.pos.distance_to(self.player.pos) <= C.INCURSION_TECH_HACK_RADIUS:
            v.progress = min(1.0, v.progress + dt / C.INCURSION_TECH_HACK_TIME)
            if v.progress >= 1.0:
                self._open_vault()
        else:
            v.progress = max(0.0, v.progress - dt / C.INCURSION_TECH_HACK_TIME * 2)

    def _open_vault(self):
        """Terminal hackeada: planos de la Fábrica de Drones, Módulo de Mando, núcleos, aleación y chatarra (todo en riesgo
        hasta extraer) y alarma de escape."""
        v = self.vault
        v.enabled = False
        v.progress = 0.0
        self.loot_module = self.loot_blueprints = self.goal_done = True
        self.loot += v.amount
        cores = self.rng.randint(*self.spec["cores"])
        self.loot_cores += cores
        self.loot_alloy += self.spec["alloy"]
        kits = self._cache_medkits(U.MEDKITS["vault_count"])
        self.notify(f"Terminal hackeada: Planos de la Fábrica de Drones, Módulo de Mando, +{cores} núcleos, "
                    f"+{self.spec['alloy']} aleación y {v.amount} de chatarra.{kits} ¡Escapa a la baliza!", 6)
        self._call_reinforcements()

    # ------------------------------------------------------------------ objetivos de las operaciones 2, 3 y 5
    def _start_drill(self, scene, it):
        """E sobre el taladro: empieza a perforar, entra en las estructuras atacables y llega la primera oleada."""
        it.enabled = False
        it.active = True
        self.world.structures.add(it)
        self.drill_timer, self.wave_timer = 0.0, 0.0
        self.notify(f"Taladro en marcha: defiéndelo {int(self.spec['drill_time'])} s. ¡Llegan oleadas!", 5)

    def _update_drill(self, dt):
        d = self.drill
        if d is None or not d.active:
            return
        if not d.alive():
            d.active = False
            self.objective_failed("TALADRO DESTRUIDO", "Los renegados destruyeron el taladro.")
            return
        self.drill_timer += dt
        d.progress = min(1.0, self.drill_timer / self.spec["drill_time"])
        if d.progress >= 1.0:
            d.active = False
            self.world.structures.remove(d)
            lo, hi = self.spec["scrap"]
            scrap, cores = self.rng.randrange(lo, hi + 1, 5), self.rng.randint(*self.spec["cores"])
            self.loot += scrap
            self.loot_cores += cores
            self.goal_done = True
            self.notify(f"Perforación completada: +{scrap} de chatarra y +{cores} núcleos. ¡Extrae en la baliza!", 6)
            return
        self.wave_timer -= dt
        if self.wave_timer <= 0:
            self.wave_timer = self.spec["wave_every"]
            self._send_wave(d.pos, inc.reinforcement_size(self.inc_level) + 1)
            self.notify("¡Oleada contra el taladro!", 3)

    def rams_down(self):
        return sum(1 for r in self.rams if r.dead)

    def _update_convoy(self):
        if self.goal != "convoy" or self.goal_done:
            return
        for ram in self.rams:
            if ram.alive() and ram.pos.distance_to(self.convoy_exit) < 70:
                ram.kill()                                           # escapa: sale del mapa sin botín
                self.objective_failed("CONVOY ESCAPADO", "Un Ariete del convoy llegó a su salida.")
                return
        if self.rams_down() == len(self.rams):
            lo, hi = self.spec["scrap"]
            scrap, cores = self.rng.randrange(lo, hi + 1, 5), self.rng.randint(*self.spec["cores"])
            self.loot += scrap
            self.loot_cores += cores
            self.goal_done = True
            self.notify(f"Convoy interceptado: +{scrap} de chatarra pesada y +{cores} núcleos. ¡Extrae en la baliza!", 6)

    def _update_timer(self, dt):
        if self.time_left is None or self.goal_done:
            return
        self.time_left = max(0.0, self.time_left - dt)
        if self.time_left <= 0:
            self.objective_failed("TIEMPO AGOTADO", "No saqueaste los alijos a tiempo.")

    def objective_failed(self, title, reason):
        """Objetivo perdido (taladro, convoy o tiempo): como una caída, pantalla de fallo y se pierde la mitad del botín."""
        self.fail_title = title
        self.fail(reason)

    def _loot_plasma(self, scene, it):
        it.enabled = False
        n = self.rng.randint(*U.PLASMA_POINTS["cache_cores"])
        self.loot_cores += n
        kits = self._cache_medkits(U.MEDKITS["vault_count"])
        self.notify(f"Alijo de plasma saqueado: +{n} núcleos.{kits}", 5)
        self._call_reinforcements()

    def _update_capture(self, dt):
        """Extractor de plasma: mantente en la zona para capturarlo; la captura alerta a los guardias cercanos."""
        pp = self.plasma_point
        if pp is None or pp.done:
            return
        if pp.contains(self.player):
            if not self.capture_alarm:
                self.capture_alarm = True
                for e in self.world.enemies:                # ¡peligroso!: toda la guardia cercana acude
                    if e.pos.distance_to(pp.pos) < 700:
                        e.chasing = True
                self.notify("¡Capturando el extractor de plasma! La guardia ha dado la alarma.", 5)
            pp.progress = min(1.0, pp.progress + dt / U.PLASMA_POINTS["capture_time"])
            if pp.progress >= 1.0:
                pp.done = True
                self.loot_cores += U.PLASMA_POINTS["extractor_cores"]
                self.notify(f"Extractor capturado: +{U.PLASMA_POINTS['extractor_cores']} núcleos de plasma.", 6)
        else:
            pp.progress = max(0.0, pp.progress - dt / U.PLASMA_POINTS["capture_time"] * 2)

    # ------------------------------------------------------------------ saqueo y extracción
    def _cache_medkits(self, n):
        """Botiquines de un alijo: van directos al bolsillo (si cabe alguno). Devuelve el texto para el aviso."""
        got = self.res.add_medkits(n)
        if got:
            return f" +{got} botiquín" + ("es" if got > 1 else "")
        return " (bolsillo de botiquines lleno)" if n else ""

    def _loot_cache(self, scene, it):
        it.enabled = False
        gained = it.amount
        self.loot += gained
        kits = self._cache_medkits(1 if self.rng.random() < U.MEDKITS["cache_chance"] else 0)
        self.notify(f"Depósito saqueado: +{gained} de botín{kits} ({self.looted()}/{len(self.caches)}).", 5)
        if self.goal == "timed" and self.looted() == len(self.caches) and not self.goal_done:
            cores = self.rng.randint(*self.spec["cores"])
            self.loot_cores += cores
            self.loot_alloy += self.spec["alloy"]
            self.goal_done = True
            self.notify(f"Recuperación completada a tiempo: +{cores} núcleos y +{self.spec['alloy']} aleación. ¡Extrae!", 6)
        self._call_reinforcements()

    def looted(self):
        return sum(1 for c in self.caches if not c.enabled)

    def _extract(self):
        self.done = True
        r = self.res
        first = self.goal_done and not r.op_cleared(self.op)
        had_module, had_blueprints = r.command_module, r.factory_blueprints
        bonus = r.finish_op(self.op, self.loot, cores=self.loot_cores, alloy=self.loot_alloy, cleared=self.goal_done,
                            module=self.loot_module, blueprints=self.loot_blueprints)
        self.game.autosave("ACT_2_BASE")                     # autoguardado: misión terminada, se reanuda en la Base Central
        extra = (f" · +{self.loot_cores} núcleos" if self.loot_cores else "") + \
                (f" · +{self.loot_alloy} aleación" if self.loot_alloy else "")
        state = "superada" if self.goal_done else "objetivo incompleto"
        self.game.report = [f"{r._label(self.op)} ({state}): +{self.loot} de botín{extra}"
                            + (f" y +{bonus} de bonus." if bonus else ".")]
        lines = [("AURA", f"Extracción completada, {r.player_name}. Botín asegurado: {self.loot}"
                          + (f" + bonus de misión {bonus}" if bonus else "") + extra.replace(" · ", ", ") + ".")]
        if self.loot_module and not had_module:
            lines.append(("AURA", "Módulo de Mando asegurado. Es la pieza que faltaba para ensamblar el Búnker."))
        if self.loot_blueprints and not had_blueprints:
            lines.append(("AURA", "Planos de la Fábrica de Drones asegurados: la consola del Búnker ya puede iniciar el asedio."))
        if not self.goal_done:
            lines.append(("SISTEMA", "Objetivo incompleto: la operación no cuenta como superada."))
        elif first:
            i = U.OPS_ORDER.index(self.op)
            unlock = (f"Desbloqueada: {r._label(U.OPS_ORDER[i + 1])}." if i + 1 < len(U.OPS_ORDER)
                      else "Tablero de incursiones completado.")
            lines.append(("SISTEMA", f"Operación superada. {unlock}"))
        self.begin_transition(lines)

    def on_fail_timeout(self):
        """Muerte: el mundo se congela y aparece la pantalla de fallo; no se bloquea el acceso (reintentar o volver)."""
        self.fail_menu = True

    def _apply_loss(self):
        """Se pierde la mitad del botín en riesgo (una sola vez) y el resto se conserva."""
        if self._loss_applied:
            return
        self._loss_applied = True
        kept = int(self.loot * C.INCURSION_DEATH_KEEP)
        lost = self.loot - kept
        self.res.fail_op(self.op, kept, lost, cores_kept=int(self.loot_cores * C.INCURSION_DEATH_KEEP),
                         module_lost=self.loot_module)
        lost_module = " Pierdes el Módulo de Mando." if self.loot_module else ""
        self.game.report = [f"{self.res._label(self.op)} fallida: botín perdido -{lost}, conservado +{kept}.{lost_module}"]

    def retry(self):
        """[R] Repite la misma operación al instante (no sube la alerta)."""
        self._apply_loss()
        self.enter(self.op)

    def back_to_base(self):
        """[ESC] Vuelve a la Base asumiendo la pérdida del botín en riesgo."""
        self._apply_loss()
        self.game.machine.transition(GameState.ACT_2_BASE)

    def handle_event(self, event):
        if not self.fail_menu:
            return super().handle_event(event)
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_r:
                self.retry()
            elif event.key == pygame.K_ESCAPE:
                self.back_to_base()
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self._fail_buttons.get("retry", pygame.Rect(0, 0, 0, 0)).collidepoint(event.pos):
                self.retry()
            elif self._fail_buttons.get("base", pygame.Rect(0, 0, 0, 0)).collidepoint(event.pos):
                self.back_to_base()

    def retry_stats(self):
        return []

    # ------------------------------------------------------------------ bucle
    def update_scene(self, dt, keys, mouse_world):
        self.fog.update(self.player.pos)
        if self.aura_drone is not None and self.aura_drone.alive():
            self.aura_drone.update(dt, self.world)           # escolta: sigue al Operador y dispara a lo que se acerque
        if self.done:
            return
        self._update_capture(dt)
        self._update_hack(dt)
        self._update_drill(dt)
        self._update_convoy()
        self._update_timer(dt)
        if self.end_timer is not None:                       # objetivo perdido este fotograma
            return
        if self.beacon.contains(self.player):
            self.extract_timer += dt
            if self.extract_timer >= C.INCURSION_EXTRACT_TIME:
                self._extract()
        else:
            self.extract_timer = max(0.0, self.extract_timer - dt * 2)

    # ------------------------------------------------------------------ HUD y dibujo
    def objective(self):
        g = self.goal
        if g == "hack":
            if self.goal_done:
                return "Planos de la Fábrica obtenidos: extrae en la baliza verde"
            return "Hackea la terminal del nido (E y permanece junto a ella) y extrae en la baliza verde"
        if g == "drill":
            if self.goal_done:
                return "Perforación completada: extrae en la baliza verde"
            if self.drill.active:
                left = max(0, math.ceil(self.spec["drill_time"] - self.drill_timer))
                return f"Defiende el taladro: {left} s · vida {int(self.drill.hp)}/{self.drill.max_hp}"
            return "Activa el taladro del yacimiento (E) y defiéndelo de las oleadas"
        if g == "convoy":
            if self.goal_done:
                return "Convoy interceptado: extrae en la baliza verde"
            return f"Abate los Arietes del convoy ({self.rams_down()}/{len(self.rams)}) antes de que lleguen a su salida"
        if self.looted() < len(self.caches):
            clock = f" antes de {self.clock()}" if g == "timed" else ""
            return f"Saquea los depósitos ({self.looted()}/{len(self.caches)}){clock} y extrae en la baliza verde"
        return "Depósitos saqueados: extrae en la baliza verde"

    def clock(self):
        t = int(math.ceil(self.time_left or 0))
        return f"{t // 60}:{t % 60:02d}"

    def checklist(self):
        g = self.goal
        goal = {"hack": ("Terminal del nido hackeada", self.goal_done),
                "drill": (f"Taladro defendido {int(self.spec.get('drill_time', 0))} s", self.goal_done),
                "convoy": (f"Arietes abatidos {self.rams_down()}/{len(self.rams)}", self.goal_done),
                "timed": (f"Alijos saqueados {self.looted()}/{len(self.caches)} · {self.clock()}", self.goal_done),
                "loot": (f"Depósitos saqueados {self.looted()}/{len(self.caches)}", self.looted() == len(self.caches))}[g]
        return [goal, ("Extracción con vida", False)]

    def banner(self):
        head = f"Op {self.spec['index']} · Nivel {self.inc_level}"
        risk = f"Botín en riesgo: {self.loot} · {self.loot_cores} núcleos" + \
               (f" · {self.loot_alloy} aleación" if self.loot_alloy else "")
        if self.goal == "hack" and self.loot_blueprints:
            risk = "Planos y Módulo EN RIESGO · " + risk
        if self.goal == "timed" and not self.goal_done:
            risk = f"Tiempo {self.clock()} · " + risk
        return f"{risk} · {head}"

    def radar_fog(self):
        return self.fog                                    # el minimapa recuerda lo explorado y deja en negro el resto

    def radar_enemies(self):
        """Los puntos rojos solo aparecen si el Operador ve al enemigo (visión directa, sin muros de por medio)."""
        return [e for e in self.world.enemies if self.fog.is_visible(e.pos)]

    def radar_targets(self):
        """AURA marca el depósito más cercano sin saquear y la baliza de extracción. Con el escaneo táctico (chasis 3/6)
        marca además TODOS los depósitos (amarillo), el alijo de plasma (cian) y el extractor de plasma (icono ⚡)."""
        if self.goal == "drill":
            drill = [(self.drill.pos, C.ORANGE)] if self.drill.alive() and not self.goal_done else []
            return drill + [(self.beacon.pos, C.GREEN)]
        if self.kind == "tech":
            vault = [(self.vault.pos, loot_art.ACCENT["module"])] if self.vault is not None and self.vault.enabled else []
            return vault + [(self.beacon.pos, C.GREEN)]
        convoy = []
        if self.goal == "convoy" and not self.goal_done:                 # Op 3: Arietes (naranja) y su salida (rojo)
            convoy = [(r.pos, C.ORANGE) for r in self.rams if r.alive()] + [(self.convoy_exit, C.RED)]
        pending = sorted((c for c in self.caches if c.enabled),
                         key=lambda c: c.pos.distance_squared_to(self.player.pos))
        if not self.res.aura_scan:
            return convoy + [(c.pos, C.YELLOW) for c in pending[:1]] + [(self.beacon.pos, C.GREEN)]
        special = convoy
        if self.plasma_cache is not None and self.plasma_cache.enabled:
            special.append((self.plasma_cache.pos, C.CYAN))
        if self.plasma_point is not None and not self.plasma_point.done:
            special.append((self.plasma_point.pos, C.YELLOW, "energy"))
        return [(c.pos, C.YELLOW) for c in pending] + special + [(self.beacon.pos, C.GREEN)]

    def draw_under(self, screen):
        visible = [e for e in self.world.enemies if self.fog.is_visible(e.pos)]
        self.camera.draw_group(screen, visible)

    def draw(self, screen):
        super().draw(screen)
        if self.fail_menu:
            self._draw_fail_menu(screen)

    def _draw_fail_menu(self, screen):
        hud = self.game.hud
        if getattr(self, "_dim", None) is None:
            self._dim = pygame.Surface((C.WINDOW_WIDTH, C.WINDOW_HEIGHT), pygame.SRCALPHA)
            self._dim.fill((0, 0, 0, 170))
        screen.blit(self._dim, (0, 0))
        cx = C.WINDOW_WIDTH // 2
        kept = int(self.loot * C.INCURSION_DEATH_KEEP)
        hud.text(screen, self.fail_title, (cx, 190), "xl", C.RED, center=True)
        hud.text(screen, f"{self.res._label(self.op)} · nivel {self.inc_level}", (cx, 252), "m", C.MAGENTA, center=True)
        cores = f" y {int(self.loot_cores * C.INCURSION_DEATH_KEEP)} de {self.loot_cores} núcleos" if self.loot_cores else ""
        hud.text(screen, f"Botín en riesgo: {self.loot} de chatarra · se pierde la mitad: conservas {kept}{cores}", (cx, 300), "m",
                 C.WHITE, center=True)
        if self.loot_module:
            hud.text(screen, "Pierdes el Módulo de Mando que llevabas", (cx, 340), "m", C.RED, center=True)
        self._fail_buttons = {"retry": pygame.Rect(cx - 370, 380, 350, 90), "base": pygame.Rect(cx + 20, 380, 350, 90)}
        for key, rect, title, sub, color in (
                ("retry", self._fail_buttons["retry"], "[R] REINTENTAR", "Repite la operación desde el inicio", C.YELLOW),
                ("base", self._fail_buttons["base"], "[ESC] VOLVER A LA BASE", "Asumes la pérdida del botín", C.CYAN)):
            hover = rect.collidepoint(pygame.mouse.get_pos())
            hud.panel(screen, rect, C.GREEN if hover else color)
            hud.text(screen, title, (rect.centerx, rect.y + 28), "m", color, center=True)
            hud.text(screen, sub, (rect.centerx, rect.y + 62), "s", C.WHITE, center=True)

    def draw_extra(self, screen):
        self.fog.draw(screen, self.camera)
        if self.extract_timer > 0:
            c = self.camera.to_screen(self.beacon.pos)                       # aro de avance alrededor de la plataforma
            ring = pygame.Rect(0, 0, self.beacon.radius * 2 - 6, self.beacon.radius * 2 - 6)
            ring.center = (round(c.x), round(c.y))
            frac = min(1.0, self.extract_timer / C.INCURSION_EXTRACT_TIME)
            pygame.draw.arc(screen, C.WHITE, ring, math.pi / 2, math.pi / 2 + math.tau * frac, 6)
