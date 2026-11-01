"""Guerra de Asedio (Paso D): mapa de 3000 x 2000 px con tu Base a un extremo y una Fortaleza enemiga evolutiva en el opuesto.

`SiegeState` hereda del bucle de combate del Acto 2 (`Act2State`: construcción, drones, niebla, carroñeros, torretas) pero en modo
Comandante: no hay avatar del Operador (cámara libre tipo RTS), VULCANO construye las obras que ordenas y los drones de la Fábrica
atacan con una orden Attack-Move (clic derecho). El enemigo no envía oleadas fijas: la Fortaleza evoluciona con el reloj de
amenaza (UNITS.THREAT_CLOCK): a más tiempo, más fuerte. Los nodos de plasma de la Tierra de Nadie dan Núcleos (reserva finita).
Gana quien destruya el núcleo enemigo; pierdes si cae tu Centro de Control.

Está dentro de una fábrica (`make_siege_state`) porque `Act2State` vive en main.py: importarlo desde aquí sería circular."""
import random

import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.entities import WorldRefs
from src.entities.building import BUILD_MENU, create_building
from src.entities.enemy import Enemy, roll_drop
from src.entities.enemy_fortress import EnemyFortress
from src.entities.plasma_node import PlasmaNode
from src.entities.power import PowerGrid
from src.entities.projectile import Projectile
from src.entities.resource_node import ScrapDeposit
from src.entities.scavenger import ScavengerDrone
from src.entities.vulcano import Vulcano
from src.managers.state_machine import GameState, SubAct
from src.map.game_map import Camera
from src.map.levels import build_siege_level
from src.mechanics import combat
from src.mechanics.commander import Absent
from src.mechanics.construction_sites import SiteQueueMixin
from src.mechanics.fog import MapFog
from src.mechanics.pathing import FlowField
from src.mechanics.threat_clock import ROMAN, SpawnQueue, ThreatClock
from src.mechanics.wave import RenegadeFoundry
from src.scenes.base_management import _NoOperator
from src.ui.combat_feedback import ALERTS
from src.ui.dialogue_box import DialogueBox

PHASE_TEXT = {
    2: ("Generador de escudo y torretas pesadas · soldados y arietes contra tus pilones", C.ORANGE),
    3: ("Factoría activa · marchas periódicas de tanques pesados", C.RED),
}
COMBAT_DRONES = ("attack", "bomber", "trooper")


_Absent = Absent


class _Voice:
    """El Comandante no tiene un compañero IA: las frases de la escena (queue_drone, carroñeros...) salen por el diálogo."""
    mode = "guard"

    def __init__(self, scene):
        self.scene = scene

    def say(self, text, ttl=3.0, sender="AURA", **kwargs):
        self.scene.dialogue.say(sender, text, ttl)

    def update(self, dt, world):
        pass


def make_siege_state(Act2State):
    class SiegeState(SiteQueueMixin, Act2State):
        INSTANT_BUILD = False                                  # VULCANO construye: sitios de obra
        DRONE_KEYS = Act2State.DRONE_KEYS
        CONSOLE_NOTE = "Ya estás en el asedio: dirige a tus drones con el clic derecho (Attack-Move)."

        # ------------------------------------------------------------------ entrada
        def enter(self, retry=False, **kwargs):
            g = self.game
            self.retried = g.begin_sub_act(SubAct.S3_0) or retry
            self.res = res = g.resources
            res.siege_active = True
            self.level = L = build_siege_level(random.randrange(10 ** 6))
            self.map_w, self.map_h = L.size
            self.CC_POS = L.marker("player_base")
            self.FORTRESS_POS = L.marker("fortress")
            self.map_rect = pygame.Rect(0, 0, *L.size)
            if self.retried:
                res.metal = max(res.metal, C.RESCUE_METAL)            # al reintentar conservas lo que tengas, con un mínimo
            elif res.metal < C.STARTING_METAL_ACT2:
                res.metal = C.STARTING_METAL_ACT2
            combat.FX.clear()
            Projectile.world_rect = self.map_rect
            ScavengerDrone.arena = self.map_rect
            self.camera = Camera(C.WINDOW_WIDTH, C.WINDOW_HEIGHT)
            self.all_sprites = pygame.sprite.Group()
            self.world = w = WorldRefs(all_sprites=self.all_sprites, bounds=self.map_rect, level=L)     # los drones terrestres rutean con él
            self._init_construction()
            self.build_menu = BUILD_MENU
            self.dialogue = DialogueBox()
            self.grid = PowerGrid(w)
            w.solids.add(*L.solids)
            self.blockers = pygame.sprite.Group(L.solids)           # las barreras de escombros paran las balas
            self.nav = FlowField(*L.size, hard=L.wall_cells)        # los enemigos rodean las barreras por los pasos
            self._fields = {}                                       # campos de flujo propios (marchas contra pilones)
            self._struct_count = -1
            self.sites, self.vulcano_status, self._cursor = [], "idle", None
            self.core = create_building("core", self.CC_POS)
            self.core.use_reactor_art()
            self.core.self_defense = True                           # cañón centinela del núcleo (modo Comandante)
            w.core = self.core
            self._register(self.core)
            self.deposit_list = []
            for off in C.ACT2_DEPOSIT_OFFSETS:
                dep = ScrapDeposit(self.CC_POS + Vector2(off))
                self.deposit_list.append(dep)
                w.deposits.add(dep)
                self.all_sprites.add(dep)
            self.setup_bunker()                                     # el Búnker ya ensamblado vuelve (y su consola)
            self.player = _NoOperator()                             # sin avatar: el asedio se dirige como Comandante
            self.absent = _Absent()
            w.player = None
            self.ally = _Voice(self)
            self.vulcano = Vulcano(self.CC_POS + Vector2(0, -70))
            self.all_sprites.add(self.vulcano)
            w.vulcano = self.vulcano
            # la escuadra que esperaba en la Base Central abre el asedio junto al Centro de Control (sin duplicarse al reintentar)
            res.campaign_run.deserialize_drones(w, upgrades=res.drone_upgrades, rewards=res.reward_tracker,
                                                on_collect=self._on_scrap_collected, on_drop=self._on_drone_drop)
            self.aura_drone = None
            self._deploy_aura()                                     # chasis 6/6: AURA patrulla el Centro de Control
            self.foundry = RenegadeFoundry()
            self.hints = g.hints
            self.hints.clear_active()
            self.fog = MapFog(self.map_w, self.map_h, U.FOG["cell"])
            self.fog.reveal_fog(self.CC_POS.x, self.CC_POS.y, U.FOG["core_radius"])
            for s in w.structures:
                self.fog.reveal_fog(s.pos.x, s.pos.y, U.FOG["structure_radius"])
            self.fortress = EnemyFortress(self.FORTRESS_POS, w)
            self.fortress.on_counterattack = self._enemy_counterattack
            self.fortress.on_destroyed = self._on_fortress_destroyed
            self.fortress.detected = True                           # AURA conoce su posición: se ve desde el principio
            self.fog.reveal_fog(self.FORTRESS_POS.x, self.FORTRESS_POS.y, 300)
            self.enemy_bases = [self.fortress]
            self.foundry_core = None
            self.clock = ThreatClock()
            self.spawn_queue = SpawnQueue(U.SIEGE["max_enemies"])    # tope duro: nunca más de 65 enemigos vivos a la vez
            self.nodes = []
            for i, pos in enumerate(L.markers["plasma_node"]):
                node = PlasmaNode(pos, i)
                self.nodes.append(node)
                self.all_sprites.add(node)
            self.paused = False
            self.end_timer = None
            self.victory = False
            self.fail_reason = ""
            self.pending_scavs = []
            self.stolen = self.stolen_cores = self.recovered = 0
            self.kills = self.mined = self.cores_taken = 0         # bajas infligidas, chatarra extraída y Núcleos de los nodos
            self.fail_menu = False                                  # pantalla de fallo táctico (R reintentar / ESC retirada)
            self._fail_buttons = {}
            self.order_marker = None
            self.phase_banner = None
            self._retarget_cd = 0.0
            self._wall_line_cd = 0.0
            self.camera.update(self.CC_POS, (self.map_w, self.map_h))
            transfer, res.siege_transfer = res.siege_transfer, None
            if transfer is not None:                                # la consola del Búnker transfirió los recursos de campaña
                self.dialogue.say("SISTEMA", f"Recursos de campaña transferidos al asedio: {transfer[0]} de chatarra y "
                                             f"{transfer[1]} núcleos de plasma.", 8)
            if self.retried:
                self.dialogue.say("SISTEMA", "Reintento del asedio: conservas tus recursos (mínimo de rescate "
                                             f"{C.RESCUE_METAL} de chatarra).", 6)
            else:
                self.dialogue.say("AURA", f"{res.player_name}, Guerra de Asedio: la Fortaleza enemiga evoluciona con el "
                                          "tiempo. Cuanto más tardes, "
                                          "más fuerte será.", blocking=True)
                self.dialogue.say("VULCANO", "Elige una estructura y haz clic: construiré donde me digas. "
                                             "Clic derecho: tus drones atacan ese punto.", blocking=True)

        def exit(self):
            self.res.siege_active = False
            try:
                pygame.mouse.set_cursor(pygame.SYSTEM_CURSOR_ARROW)
            except pygame.error:
                pass

        # ------------------------------------------------------------------ ganchos del mixin
        def build_discount(self):
            return 0.0

        def notify(self, text, ttl=3.0):
            self.dialogue.say("VULCANO", text, ttl)

        def on_structure_lost(self, building):
            pass

        # ------------------------------------------------------------------ niebla y minimapa
        def _update_fog(self):
            for d in self.world.drones:
                if d.alive() and hasattr(d, "reveal_radius"):
                    self.fog.reveal_fog(d.pos.x, d.pos.y, d.reveal_radius)
            for f in self.world.focos:
                if f.alive() and f.active and not getattr(f, "fog_done", False):
                    self.fog.reveal_fog(f.pos.x, f.pos.y, f.stats["reveal_radius"])
                    f.fog_done = True

        def revealers(self):
            out = [(Vector2(self.core.pos), C.INCURSION_VISION)]
            out += [(Vector2(f.pos), f.stats["reveal_radius"]) for f in self.world.focos if f.alive() and f.is_powered]
            out += [(Vector2(d.pos), d.reveal_radius) for d in self.world.drones if d.alive() and hasattr(d, "reveal_radius")]
            return out

        def minimap_enemies(self):
            return list(self.world.enemies) + [s for s in self.world.scavengers if s.detected]

        # ------------------------------------------------------------------ amenaza: fases y envíos
        def _on_phase(self, phase):
            self.fortress.apply_phase(phase)
            sub, color = PHASE_TEXT[phase]
            title = f"¡LA FORTALEZA ENEMIGA EVOLUCIONA! AMENAZA {ROMAN[phase]}"
            self.phase_banner = {"title": title, "sub": sub, "color": color, "timer": 5.0, "total": 5.0}
            ALERTS.push(title, color, key=("phase", phase))
            combat.FX.request_shake()
            self.dialogue.say("AURA", f"Nivel de amenaza {ROMAN[phase]}: {sub}.", 6)

        def _nearest_pylon(self, pos):
            pylons = [p for p in self.world.pylons if p.alive()]
            return min(pylons, key=lambda p: p.pos.distance_squared_to(pos)) if pylons else None

        def _field_for(self, goal):
            """Campo de flujo hacia un objetivo (un pilón): lo reutilizan todas las unidades que marchan a él."""
            key = id(goal)
            field = self._fields.get(key)
            if field is None:
                field = self._fields[key] = FlowField(self.map_w, self.map_h, hard=self.level.wall_cells)
                field.goal_sprite = goal
            return field

        def _update_goal_fields(self):
            n = len(self.world.structures)
            if n != self._struct_count:                              # algo se construyó o cayó: recalcular
                self._struct_count = n
                for f in self._fields.values():
                    f.mark_dirty()
            for key, f in list(self._fields.items()):
                if not f.goal_sprite.alive():
                    del self._fields[key]
                    continue
                f.retarget(f.goal_sprite)
                f.update(self.world.structures, f.goal_sprite)

        def _spawn_spot(self, i):
            front = Vector2(-1, 0)                                   # la fortaleza mira hacia el jugador (-x)
            base = self.FORTRESS_POS + front * 230
            return base + Vector2(-26 * (i % 5), -70 + 32 * (i // 5) + random.uniform(-6, 6))

        def _dispatch(self, order):
            """Un envío del reloj de amenaza: la marcha sale de la Fortaleza hacia su objetivo."""
            if order.requires == "factory" and not (self.fortress.factory is not None and self.fortress.factory.alive()):
                return                                               # sin Factoría no hay marchas de Tanques
            if order.target == "scrap":
                self.spawn_queue.enqueue("scavenger", "scrap", order.count)
                return
            for kind, n in order.kinds.items():
                self.spawn_queue.enqueue(kind, order.target, n)

        def active_enemies(self):
            """Enemigos vivos que cuentan para el tope: unidades de tierra y carroñeros."""
            return len(self.world.enemies) + len(self.world.scavengers)

        def _release_spawns(self):
            """Hard cap: instancia solo lo que cabe bajo el tope de enemigos vivos; el resto espera en la cola."""
            for i, (kind, target) in enumerate(self.spawn_queue.release(self.active_enemies())):
                if target == "scrap":
                    self._spawn_siege_scavenger()
                else:
                    self._spawn_enemy(kind, target, i)

        def _spawn_enemy(self, kind, target, i):
            w = self.world
            goal = self._nearest_pylon(self.FORTRESS_POS) if target == "pylon" else None
            dest = goal if goal is not None else self.core
            e = Enemy(kind, self._spawn_spot(i), Vector2(dest.pos), w.enemies)
            e.always_active = True
            e.world = w
            e.on_death = self._on_siege_enemy_death
            e.siege_target = target
            e.siege_goal = dest
            if goal is not None:
                e.own_nav = self._field_for(goal)
            w.enemies.add(e)
            w.all_sprites.add(e)
            w.targets.add(e)
            return e

        def _spawn_siege_scavenger(self):
            """Un carroñero sale de la Fortaleza: chatarra primero, luego un pilón; si escapa, la roba para ella."""
            scraps = list(self.world.scraps)
            hint = min(scraps, key=lambda s: s.pos.distance_squared_to(self.FORTRESS_POS)).pos if scraps else self.core.pos
            drone = ScavengerDrone(self.FORTRESS_POS + Vector2(-120, random.uniform(-80, 80)), hint)
            drone.on_death = self._on_scavenger_death
            drone.on_escape = self._on_scavenger_escape
            drone.on_sabotage = self._on_sabotage
            w = self.world
            w.scavengers.add(drone)
            w.targets.add(drone)
            self.all_sprites.add(drone)

        def _on_scavenger_escape(self, drone):
            self.stolen += drone.scrap_value
            self.fortress.scrap += drone.scrap_value
            if drone.scrap_value:
                self.ally.say(f"Un carroñero escapó con {drone.scrap_value} de chatarra hacia la Fortaleza.", 4)

        def _retarget_marchers(self, dt):
            """Las marchas contra pilones buscan el siguiente pilón cuando el suyo cae; sin pilones, van al Centro de Control."""
            self._retarget_cd -= dt
            if self._retarget_cd > 0:
                return
            self._retarget_cd = 1.5
            for e in self.world.enemies:
                if getattr(e, "siege_target", None) != "pylon" or (e.siege_goal is not None and e.siege_goal.alive()):
                    continue
                nxt = self._nearest_pylon(e.pos)
                e.siege_goal = nxt if nxt is not None else self.core
                e.target_pos = Vector2(e.siege_goal.pos)
                e.own_nav = self._field_for(nxt) if nxt is not None else None

        def _enemy_counterattack(self, base, roster):
            """Le destruyeron una pieza: contraataque contra el Centro de Control."""
            for kind in roster:
                self.spawn_queue.enqueue(kind, "core")                   # el contraataque también respeta el tope
            self.ally.say(f"¡La Fortaleza contraataca con {len(roster)} unidades!", 4)

        def _on_scavenger_death(self, drone):
            self.kills += 1
            self.res.add_metal(U.SIEGE["kill_metal"])
            super()._on_scavenger_death(drone)

        def _on_siege_enemy_death(self, enemy):
            """Cada baja da chatarra directa (UNITS.SIEGE["kill_metal"]): no hace falta recogerla, los drones recuperan coste."""
            self.kills += 1
            self.res.add_metal(U.SIEGE["kill_metal"])
            value = roll_drop(enemy.enemy_type)
            if value:
                self._drop_scrap(enemy.pos, value)

        # (órdenes Attack-Move de los drones: heredadas del Acto 2, ver Act2State.issue_attack_move)

        # ------------------------------------------------------------------ victoria, derrota y cierre
        def _on_fortress_destroyed(self, base):
            """Cae el núcleo: se detienen los envíos y las torretas restantes se apagan (la base se desmorona)."""
            self.victory = True
            self.spawn_queue.clear()
            self.world.enemy_bullets.empty()
            for b in list(self.world.hostile):
                if getattr(b, "fire_timer", None) is not None:
                    b.fire_timer = 10 ** 9
            self.ally.say("¡Núcleo de la Fortaleza demolido! El asedio ha terminado.", 6)
            self.end_timer = 3.0

        def _summary(self):
            """Estadísticas de la Pantalla de Victoria de Campaña: [(etiqueta, valor)]."""
            secs = int(self.clock.t)
            return [("Tiempo de asedio", f"{secs // 60:02d}:{secs % 60:02d}"),
                    ("Bajas infligidas", str(self.kills)),
                    ("Recursos extraídos", f"{self.mined + self.recovered} de chatarra · {self.cores_taken} núcleos de plasma"),
                    ("Fase de amenaza alcanzada", f"{self.clock.name} de III")]

        def _stats(self):
            secs = int(self.clock.t)
            alive = len(self.factory_drones())
            lines = [self.fail_reason] if self.fail_reason else []
            return lines + [f"Tiempo de asedio: {secs // 60:02d}:{secs % 60:02d} · amenaza alcanzada: {self.clock.name}",
                            f"Núcleo enemigo: {max(0, int(self.fortress.core.hp))}/{self.fortress.core.max_hp}"
                            + (" (destruido)" if self.fortress.destroyed else ""),
                            f"Drones en pie: {alive} · nodos de plasma capturados: "
                            f"{sum(1 for n in self.nodes if n.owner == 'player')}/{len(self.nodes)}",
                            f"Chatarra robada por carroñeros: {self.stolen}"]

        def _finish(self):
            self.end_timer = None
            if self.victory:
                self.game.machine.transition(GameState.CAMPAIGN_VICTORY, stats=self._summary())
            else:
                self.fail_menu = True                                       # fallo táctico: R reintentar / ESC retirada

        def retry(self):
            """[R] Reintenta el asedio: mapa nuevo, reloj a cero y los recursos de campaña que tengas."""
            self.enter(retry=True)

        def retreat(self):
            """[ESC] Retirada a la Base Central (modo Comandante); la base guardada antes del asedio sigue ahí."""
            self.game.machine.transition(GameState.BASE_MANAGEMENT, next_state=GameState.ACT_2_BASE)

        # ------------------------------------------------------------------ entrada
        def handle_event(self, event):
            if self.fail_menu:
                if event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_r:
                        self.retry()
                    elif event.key == pygame.K_ESCAPE:
                        self.retreat()
                elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                    if self._fail_buttons.get("retry", pygame.Rect(0, 0, 0, 0)).collidepoint(event.pos):
                        self.retry()
                    elif self._fail_buttons.get("retreat", pygame.Rect(0, 0, 0, 0)).collidepoint(event.pos):
                        self.retreat()
                return
            if self.dialogue.blocking_active:
                if ((event.type == pygame.KEYDOWN and event.key in (pygame.K_SPACE, pygame.K_RETURN, pygame.K_e))
                        or (event.type == pygame.MOUSEBUTTONDOWN and event.button == 1)):
                    self.dialogue.advance()
                return
            if event.type == pygame.MOUSEMOTION and getattr(event, "buttons", (0, 0, 0))[1]:
                self.camera.drag(event.rel, (self.map_w, self.map_h))        # clic central arrastrado
                return
            if event.type == pygame.MOUSEBUTTONDOWN:
                wp = self.camera.to_world(event.pos)
                if event.button == 3 and self.build_choice is None and self.menu is None:
                    site = self.site_under(wp)                               # clic der. sobre una obra: la cancela
                    if site is not None:
                        self.cancel_site(site)
                        return
                if event.button == 1 and self.build_choice is None and self.bunker_interact(point=wp):
                    return                                                   # Búnker y consola: un clic
            if self.selection_event(event):                                  # selección RTS y órdenes directas
                return
            if self.handle_construction_event(event):
                return
            if event.type != pygame.KEYDOWN:
                return
            if event.key == pygame.K_SPACE:
                if self.end_timer is None:
                    self.paused = not self.paused                            # pausa: el reloj de amenaza también se detiene
                return
            if self.handle_build_key(event):
                return
            if event.key in self.DRONE_KEYS:
                self.queue_drone(self.DRONE_KEYS[event.key])
            elif event.key == pygame.K_e:
                self.bunker_interact(point=self.camera.to_world(pygame.mouse.get_pos()))

        # ------------------------------------------------------------------ bucle
        def update(self, dt):
            w = self.world
            self.camera.tick(dt)
            combat.FX.update(dt)
            self.dialogue.update(dt)
            cursor = self.camera.to_world(pygame.mouse.get_pos())
            self.update_bunker(dt, None, cursor)
            if combat.FX.consume_shake():
                self.camera.shake()
            if self.phase_banner is not None:
                self.phase_banner["timer"] -= dt
                if self.phase_banner["timer"] <= 0:
                    self.phase_banner = None
            if self.order_marker is not None:
                self.order_marker[1] -= dt
                if self.order_marker[1] <= 0:
                    self.order_marker = None
            if self.fail_menu:
                return
            if self.end_timer is not None:
                self.end_timer -= dt
                if self.end_timer <= 0:
                    self._finish()
                return
            if self.dialogue.blocking_active:
                return
            keys = pygame.key.get_pressed()
            mouse = pygame.mouse.get_pressed()
            self.camera.tactical_update(dt, keys, pygame.mouse.get_pos(), (self.map_w, self.map_h))     # cámara RTS siempre libre
            if self.paused:
                self.process_build_input(dt, keys, mouse, cursor)
                self.grid.update()
                self.energy_tick()
                self._refresh_menu()
                return
            self.process_build_input(dt, keys, mouse, cursor)
            for kind, n in self.clock.update(dt):
                if kind == "phase":
                    self._on_phase(n)
            for order in self.clock.pop_orders():
                self._dispatch(order)
            self._release_spawns()
            self.grid.update()
            self.energy_tick()
            self.nav.update(w.structures, self.core)
            self._update_goal_fields()
            self._retarget_marchers(dt)
            self.fortress.update(dt)
            self._update_fog()
            w.enemies.update(dt, w.structures, self.nav, w.solids)
            w.scavengers.update(dt, w.scraps, w.core_items, w.pylons)
            w.structures.update(dt, w.targets, w.bullets)
            w.hostile.update(dt, w)
            w.drones.update(dt, w)
            self._check_aura()
            w.bombs.update(dt, w)
            w.bullets.update(dt)
            w.enemy_bullets.update(dt)
            w.shells.update(dt)
            w.scraps.update(dt, None)
            w.ammo_boxes.update(dt, None)
            w.core_items.update(dt, None)
            self.work_sites(dt)                                       # VULCANO: repara lo crítico o construye la cola
            for node in self.nodes:
                self.cores_taken += node.update(dt, w, self.res, self.res.campaign_run)
            combat.resolve_projectiles(w.bullets, w.enemies, w.scavengers, self.blockers, w.hostile)
            pygame.sprite.groupcollide(w.enemy_bullets, self.blockers, True, False)
            combat.resolve_enemy_bullets(w.enemy_bullets, self.absent, w.drones, w.structures)
            combat.resolve_enemy_allies(w.enemies, w.drones, dt)
            for extractor in w.extractors:
                got = extractor.collect_income()
                self.res.add_metal(got)
                self.mined += got
            if not self.victory and not self.core.alive():
                self.fail_reason = "El Centro de Control fue destruido."
                self.ally.say("Conexión perdida...", 3)
                self.end_timer = 1.5

        # ------------------------------------------------------------------ dibujo
        def draw(self, screen):
            cam = self.camera
            screen.blit(self.level.background, (0, 0),
                        pygame.Rect(round(cam.offset.x), round(cam.offset.y), C.WINDOW_WIDTH, C.WINDOW_HEIGHT))
            self.grid.draw(screen, cam.offset)
            self.draw_units(screen)                                   # sprites, niebla y, encima, los drones aliados
            self.draw_build_preview(screen)
            self.draw_order_marker(screen)                            # marca de la orden Attack-Move
            self.draw_selection_overlay(screen)                       # caja de selección y foco de ataque
            cam.apply_shake(screen)
            self.game.hud.draw_siege(screen, self)
            self.draw_structure_menu(screen)
            self.draw_tooltips(screen)
            if self.paused:
                self.game.hud.pause_banner(screen)
            if self.fail_menu:
                self._draw_fail_menu(screen)

        def _draw_fail_menu(self, screen):
            hud, cx = self.game.hud, C.WINDOW_WIDTH // 2
            if getattr(self, "_dim", None) is None:
                self._dim = pygame.Surface((C.WINDOW_WIDTH, C.WINDOW_HEIGHT), pygame.SRCALPHA)
                self._dim.fill((0, 0, 0, 190))
            screen.blit(self._dim, (0, 0))
            hud.text(screen, "FALLO TÁCTICO", (cx, 170), "xl", C.RED, center=True)
            hud.text(screen, self.fail_reason or "El Centro de Control fue destruido.", (cx, 240), "m", C.WHITE, center=True)
            for i, line in enumerate(self._stats()[(1 if self.fail_reason else 0):][:3]):
                hud.text(screen, line, (cx, 290 + i * 28), "s", C.DARK_GRAY, center=True)
            self._fail_buttons = {"retry": pygame.Rect(cx - 370, 420, 350, 90), "retreat": pygame.Rect(cx + 20, 420, 350, 90)}
            for key, title, sub, color in (("retry", "[R] REINTENTAR ASEDIO", "Mapa nuevo, tus recursos de campaña", C.YELLOW),
                                           ("retreat", "[ESC] RETIRADA A LA BASE", "Vuelves a la Base Central", C.CYAN)):
                rect = self._fail_buttons[key]
                hud.panel(screen, rect, C.GREEN if rect.collidepoint(pygame.mouse.get_pos()) else color)
                hud.text(screen, title, (rect.centerx, rect.y + 30), "m", color, center=True)
                hud.text(screen, sub, (rect.centerx, rect.y + 62), "s", C.WHITE, center=True)

    return SiegeState
