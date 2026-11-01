"""Base Central en modo Comandante (perspectiva de VULCANO): fase estratégica entre sub-actos.

Solo se llega aquí por transición de estados (nunca hay alternancia de control en pleno combate). No hay avatar del Operador
(solo se pilota en las incursiones y en el Acto 2): cámara libre tipo RTS (WASD / flechas / bordes de pantalla / clic central
arrastrado, limitada al mapa), y VULCANO es el constructor autónomo: el jugador elige una estructura y hace clic en el mapa;
se coloca un sitio de obra y VULCANO acude, lo ensambla a 80 HP/s pagando la chatarra a medida que avanza (si hay que reparar
lo crítico o falta chatarra, la obra espera). También puede reparar, desmontar e instalar componentes del chasis de AURA.
Los terminales (Terminal de Campaña, Búnker y su consola) se activan con un clic. [ESPACIO] o el botón «Desplegar Operador»
guarda la base y empieza limpio el siguiente sub-acto con el humano al frente."""
import math

import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.core.audio_manager import audio
from src.entities import WorldRefs
from src.entities.building import BUILD_MENU, Building, create_building
from src.entities.interactable import Terminal
from src.entities.power import PowerGrid
from src.entities.resource_node import ScrapDeposit
from src.entities.vulcano import Vulcano
from src.managers.state_machine import GameState, State
from src.map.game_map import Camera, GameMap
from src.mechanics import combat
from src.mechanics.base_layout import capture_base, restore_base
from src.mechanics.bunker import OP4_REQUIRED
from src.mechanics.construction import ConstructionMixin
from src.mechanics.commander import NoOperator
from src.mechanics.construction_sites import SiteQueueMixin
from src.mechanics.pathing import FlowField
from src.mechanics.scenario import scenario_of
from src.mechanics.vulcan_advisor import VulcanAdvisor
from src.mechanics.selection import COMBAT_KINDS, DroneSelectionMixin
from src.ui.dialogue_box import DialogueBox
from src.ui.fade import FadeTimer
from src.ui.tooltips import unit_under


_NoOperator = NoOperator                                    # (nombre de siempre: lo importan otras escenas)


SIEGE_DENIED = OP4_REQUIRED                                  # consola del Búnker sin los planos de la Fábrica de Drones


class _Voice:
    """Las frases de las órdenes a los drones (DroneSelectionMixin) salen por el diálogo de la Base Central."""

    def __init__(self, scene):
        self.scene = scene

    def say(self, text, ttl=3.0, sender="VULCANO", **kwargs):
        self.scene.dialogue.say(sender, text, ttl)


class BaseManagementState(SiteQueueMixin, DroneSelectionMixin, ConstructionMixin, State):
    CC_POS = Vector2(C.ACT2_CC_POS)
    INSTANT_BUILD = False                                   # VULCANO construye: se coloca un sitio de obra
    CONSOLE_ACTIVE = True                                   # aquí la consola del Búnker inicia el asedio
    paused = True                                           # mundo en modo Comandante: sin golpe del Operador; el mixin lo consulta
    PRODUCTION_ON_DEPLOY = True                             # lo que quede en cola al desplegar se termina en el mapa

    def enter(self, next_state=GameState.ACT_2_BASE):
        self.next_state = next_state
        self.res = self.game.resources
        self.game.autosave("BASE_MANAGEMENT", next_state=next_state.name)      # autoguardado al volver a la Base Central
        sc = scenario_of(self.res)                         # mismo mapa que el Acto 2 (clásico o de campaña)
        self.CC_POS, self.map_w, self.map_h = Vector2(sc.cc_pos), sc.w, sc.h
        self.transferred = self.res.metal - self.res.metal_mark      # metal traído de la misión (fijo en la sesión)
        combat.FX.clear()
        self.map_rect = pygame.Rect(0, 0, self.map_w, self.map_h)
        self.game_map = GameMap.arena(self.map_w, self.map_h, self.CC_POS)
        self.camera = Camera(C.WINDOW_WIDTH, C.WINDOW_HEIGHT)
        self.focus = Vector2(self.CC_POS)                   # solo encuadra la cámara al entrar: después se mueve libre
        self.sites = []                                     # órdenes de obra de VULCANO, en orden de pedido
        self.vulcano_status = "idle"
        self._cursor = None
        self.siege_prompt = False                           # confirmación del despliegue del asedio
        self.siege_buttons = {}
        self.all_sprites = pygame.sprite.Group()
        self.world = WorldRefs(all_sprites=self.all_sprites, bounds=self.map_rect)
        w = self.world
        self._init_construction()
        self.build_menu = BUILD_MENU
        self.dialogue = DialogueBox()
        self.grid = PowerGrid(w)
        self.nav = FlowField(self.map_w, self.map_h)        # lo exige el mixin al registrar estructuras
        self.core = create_building("core", self.CC_POS)
        self.core.use_reactor_art()                         # Reactor Central (como en el 1.3)
        w.core = self.core
        self._register(self.core)
        self.deposit_list = []
        for off in sc.deposit_offsets:
            dep = ScrapDeposit(self.CC_POS + Vector2(off))
            self.deposit_list.append(dep)
            w.deposits.add(dep)
            self.all_sprites.add(dep)
        restore_base(self, self.res)
        self.setup_bunker()                                  # sitio de obra del Búnker (VULCANO lo ensambla con un clic)
        self.player = _NoOperator()                         # sin avatar: el Operador no existe en esta escena
        self._make_campaign_terminal()
        self.vulcano = Vulcano(self.CC_POS + Vector2(0, -70))
        self.all_sprites.add(self.vulcano)
        self.ally = _Voice(self)
        self.selected, self.drag_start, self.drag_now, self.focus_marker, self.order_marker = [], None, None, None, None
        self.res.campaign_run.deserialize_drones(w, factories=self.factories, upgrades=self.res.drone_upgrades,
                                                 rewards=self.res.reward_tracker, on_collect=self.res.add_metal)
        self._sync_energy()
        W = C.WINDOW_WIDTH
        self.buttons = {"deploy": pygame.Rect(W - 336, 96, 324, 58),
                        "repair": pygame.Rect(W - 336, 164, 324, 38),
                        "install": pygame.Rect(W - 336, 210, 324, 38)}
        self.camera.update(self.focus, (self.map_w, self.map_h))
        self.dialogue.say("VULCANO", "Reporte de la Base Central: perspectiva de VULCANO.", 9)
        for line in self.report_lines():
            self.dialogue.say("VULCANO", line, 9)
        self.dialogue.say("SISTEMA", "Modo Comandante: WASD / flechas / bordes mueven la cámara. Elige una estructura y haz clic: "
                                     "VULCANO la construye. [ESPACIO] despliega al Operador.", 9)
        self.report_fade = FadeTimer()                      # REPORTE DE VULCANO: 7 s visible y se desvanece ([H] / ratón)
        self.help_fade = FadeTimer()                        # ayudas de controles de abajo: igual ([H] las recupera)
        self.advisor = VulcanAdvisor(self)                  # Mentor VULCANO: tutoriales de desbloqueo reactivos
        self.advisor.start_next()
        audio.play_music("base")

    # --- drones de la Fábrica: se fabrican aquí, esperan junto a su Fábrica y obedecen órdenes ---
    @property
    def factories(self):
        return sorted((f for f in self.world.factories if f.alive()), key=lambda f: f.build_order)

    def configure_building(self, building):
        if building.building_type == "fabrica":
            building.upgrades = self.res.drone_upgrades
            building.rewards = self.res.reward_tracker
            building.on_collect = self.res.add_metal              # un Explorador con carga la deja en la reserva
            building.on_spawn = self._on_drone_spawn

    def _on_drone_spawn(self, drone):
        self.store_fleet()
        self.notify(f"{drone.display_name} listo junto a su Fábrica: selecciónalo y dale órdenes.", 3)

    def combat_drones(self):
        return [d for d in self.world.drones if d.alive() and getattr(d, "kind", "") in COMBAT_KINDS]

    def store_fleet(self):
        """Los drones de la base pasan a la campaña: los recibe el siguiente mapa del Acto 2 o el asedio."""
        self.res.campaign_run.store_fleet(self.world.drones, self.CC_POS)

    def _selection_ok(self, event):
        """La selección RTS no tapa los clics de la base: botones, terminales, obras y reparar una estructura."""
        if event.type != pygame.MOUSEBUTTONDOWN or event.button not in (1, 3):
            return True
        if any(r.collidepoint(event.pos) for r in self.buttons.values()):
            return False
        wp = self.camera.to_world(event.pos)
        if event.button == 3:
            return self.site_under(wp) is None and not pygame.key.get_pressed()[pygame.K_x]
        if unit_under((self.combat_drones(),), wp) is not None:
            return True
        return self.structure_at(wp) is None and not self._interactive_at(wp)

    # --- Mentor VULCANO (src/mechanics/vulcan_advisor.py) ---
    def free_deposit(self):
        """Primera veta de chatarra sin extractor ni agotar (para el hito de Economía)."""
        return next((d for d in self.deposit_list if not d.depleted and d.extractor is None), None)

    def build_guard(self, btype, rect=None):
        return self.advisor.guard(btype, rect) if getattr(self, "advisor", None) is not None else None

    def _cost(self, building_type):
        advisor = getattr(self, "advisor", None)
        if advisor is not None and advisor.free(building_type):
            return 0                                         # subsidio de prueba: el paso guiado sale gratis
        return super()._cost(building_type)

    def _menu_options(self, b):
        opts = super()._menu_options(b)
        advisor = getattr(self, "advisor", None)
        if advisor is not None and advisor.free_route(b):    # hito de mejoras: la torreta marcada se especializa gratis
            for opt in opts:
                if opt["action"][0] == "route":
                    opt.update({"label": opt["label"].replace(" [BLOQUEADA]", "") + " · GRATIS (VULCANO)", "scrap": 0,
                                "cores": 0, "unlocked": True, "enabled": opt.get("energy", 0) <= self.energy_free()})
        return opts

    # --- terminal de campaña (clic) ---
    def _make_campaign_terminal(self):
        pos = self.CC_POS + Vector2(0, -150)
        term = Terminal(pos, (34, 44), "Terminal de Campaña", color=C.YELLOW)
        term.prompt_key = "CLIC"
        term.on_interact = self._open_campaign_terminal
        self.all_sprites.add(term)
        self.campaign_terminal = term

    def _open_campaign_terminal(self, scene, term):
        """Clic en el Terminal de Campaña: guarda la base y abre la selección de mapa (tras la incursión inicial)."""
        if not self.res.initial_done:
            self.notify("El Terminal de Campaña se activa al completar la incursión inicial.", 4)
            return
        self.advisor.abort()
        self.cancel_all_sites()
        capture_base(self, self.res)
        self.store_fleet()
        self.res.metal_mark = self.res.metal
        self.game.machine.transition(GameState.CAMPAIGN_MENU)

    def _interactive_at(self, world_pos):
        """¿Hay algo accionable con un clic bajo el cursor? (para el cursor contextual)"""
        if self.build_choice is not None:
            return False
        if self.site_under(world_pos) is not None:
            return True
        return any(it is not None and it.alive() and it.rect.collidepoint(world_pos)
                   for it in (self.bunker_site, self.bunker_console, self.campaign_terminal))

    def _update_cursor(self, world_pos):
        """Cursor de mano sobre los edificios interactivos."""
        want = pygame.SYSTEM_CURSOR_HAND if self._interactive_at(world_pos) else pygame.SYSTEM_CURSOR_ARROW
        if want != self._cursor:
            try:
                pygame.mouse.set_cursor(want)
                self._cursor = want
            except pygame.error:                                  # sin ventana real (pruebas): nada que cambiar
                self._cursor = want

    def exit(self):
        audio.stop_music()
        if getattr(self, "advisor", None) is not None:
            self.advisor.abort()
        try:
            pygame.mouse.set_cursor(pygame.SYSTEM_CURSOR_ARROW)
        except pygame.error:
            pass
        self._cursor = None

    # --- ganchos del mixin ---
    def notify(self, text, ttl=3.0):
        self.dialogue.say("VULCANO", text, ttl)

    # --- reporte de VULCANO ---
    def repair_cost(self, b):
        missing = b.max_hp - b.hp
        return math.ceil(missing * C.BASE_REPAIR_METAL_PER_HP) if missing > 0.01 else 0

    def damaged(self):
        return [b for b in self.world.structures if b.hp < b.max_hp - 0.01]

    def report_lines(self):
        ss = list(self.world.structures)
        avg = round(100 * sum(b.hp / b.max_hp for b in ss) / len(ss))
        dmg = self.damaged()
        r = self.res
        return [
            f"Defensas del búnker: {len(ss) - 1} estructuras y núcleo · salud media {avg}%",
            f"Dañadas: {len(dmg)} · reparación completa: {sum(self.repair_cost(b) for b in dmg)} metal",
            f"Metal transferido a la reserva: {self.transferred:+d} desde el último despliegue (reserva: {r.metal})",
            f"Chasis de AURA: {r.assembly_pct}% ensamblado ({r.chassis_installed}/{C.CHASSIS_TOTAL_PARTS})"
            f" · componentes disponibles: {r.chassis_available}",
        ]

    # --- acciones del jugador ---
    def structure_at(self, world_pos):
        self._probe.rect = pygame.Rect(world_pos.x, world_pos.y, 1, 1)
        hits = pygame.sprite.spritecollide(self._probe, self.world.structures, False)
        return hits[0] if hits else None

    def repair_structure(self, b):
        cost = self.repair_cost(b)
        if cost <= 0:
            return False
        if not self.res.spend_metal(cost):
            self.notify("Metal insuficiente para reparar.", 3)
            return False
        b.hp = b.max_hp
        self.notify(f"{Building.LABELS[b.building_type]} reparado (-{cost} metal).", 3)
        return True

    def repair_all(self):
        fixed = 0
        for b in sorted(self.damaged(), key=lambda s: s.hp / s.max_hp):
            if not self.repair_structure(b):
                break
            fixed += 1
        if fixed == 0 and not self.damaged():
            self.notify("Todas las estructuras están en perfecto estado.", 3)
        return fixed

    def install_component(self):
        r = self.res
        if r.chassis_available <= 0:
            self.notify("No hay componentes del chasis por instalar: recupéralos en las misiones.", 4)
            return False
        if r.chassis_installed >= C.CHASSIS_TOTAL_PARTS:
            self.notify("El chasis de AURA ya está completo.", 3)
            return False
        if not r.install_chassis():
            return False
        self.notify(f"Componente instalado: chasis de AURA al {r.assembly_pct}% "
                    f"(+{C.CHASSIS_HP_BONUS} de vida del Operador).", 5)
        if r.chassis_installed == U.AURA_CHASSIS["scan_parts"]:
            self.dialogue.say("AURA", "Chasis 3/6: escaneo táctico en línea. Marcaré alijos y extractores de plasma en el radar.", 7)
        elif r.chassis_installed == U.AURA_CHASSIS["drone_parts"]:
            self.dialogue.say("AURA", "Chasis 6/6: puedo combatir a tu lado como dron. Saldré cuando ataquen el búnker.", 7)
        return True

    def demolish(self, b):
        """Desmonta una estructura (reubicar = desmontar y volver a construir): devuelve el 70% del coste."""
        return self.sell(b)

    def deploy(self):
        """Guarda el estado de la base, confirma las fortificaciones y arranca el siguiente sub-acto. Las obras sin terminar no
        viajan: se cancelan y se reembolsa lo gastado."""
        self.advisor.abort()
        self.cancel_all_sites()
        capture_base(self, self.res)
        self.store_fleet()                                   # los drones de la base despegan con el Operador
        self.res.metal_mark = self.res.metal
        self.game.machine.transition(self.next_state)

    # --- entrada ---
    def _click_props(self, world_pos):
        """Clic (o E con el cursor encima) sobre un terminal: sitio y consola del Búnker o Terminal de Campaña."""
        if self.bunker_interact(point=world_pos):
            return True
        term = self.campaign_terminal
        if term is not None and term.alive() and term.rect.collidepoint(world_pos):
            term.interact(self)
            return True
        return False

    # --- asedio: se inicia desde la consola del Búnker ---
    def request_siege(self):
        if not self.res.can_start_siege:                    # Búnker de Mando + planos de la Fábrica de Drones
            self.notify(SIEGE_DENIED, 6)
            audio.play("error")
            return
        self.siege_prompt = True

    def _launch_siege(self):
        """Confirmado: guarda la base y despliega el asedio con los recursos de campaña actuales (chatarra y núcleos)."""
        res = self.res
        self.siege_prompt = False
        self.advisor.abort()
        self.cancel_all_sites()
        capture_base(self, res)
        self.store_fleet()                                   # la escuadra de la base abre el asedio
        res.metal_mark = res.metal
        res.siege_transfer = (res.metal, res.cores)
        self.game.machine.transition(GameState.SIEGE)

    def _siege_prompt_event(self, event):
        if event.type == pygame.KEYDOWN:
            if event.key in (pygame.K_RETURN, pygame.K_KP_ENTER):
                self._launch_siege()
            elif event.key == pygame.K_ESCAPE:
                self.siege_prompt = False
        elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
            if self.siege_buttons.get("go", pygame.Rect(0, 0, 0, 0)).collidepoint(event.pos):
                self._launch_siege()
            elif self.siege_buttons.get("cancel", pygame.Rect(0, 0, 0, 0)).collidepoint(event.pos):
                self.siege_prompt = False

    def _draw_siege_prompt(self, screen):
        hud, res, cx = self.game.hud, self.res, C.WINDOW_WIDTH // 2
        if getattr(self, "_dim", None) is None:
            self._dim = pygame.Surface((C.WINDOW_WIDTH, C.WINDOW_HEIGHT), pygame.SRCALPHA)
            self._dim.fill((0, 0, 0, 190))
        screen.blit(self._dim, (0, 0))
        hud.text(screen, "DESPLIEGUE DEL ASEDIO TÁCTICO", (cx, 190), "l", C.CYAN, center=True)
        hud.text(screen, "Objetivo: destruir el núcleo de la Fortaleza Enemiga (1200 HP).", (cx, 262), "m", C.WHITE, center=True)
        hud.text(screen, f"Recursos de campaña que se transfieren: {res.metal} de chatarra · {res.cores} núcleos de plasma",
                 (cx, 306), "m", C.YELLOW, center=True)
        hud.text(screen, "La Fortaleza evoluciona con el tiempo: cuanto más tardes en atacar, más fuerte será.", (cx, 350), "s",
                 C.ORANGE, center=True)
        self.siege_buttons = {"go": pygame.Rect(cx - 370, 420, 350, 80), "cancel": pygame.Rect(cx + 20, 420, 350, 80)}
        for key, rect, title, color in (("go", self.siege_buttons["go"], "[ENTER] CONFIRMAR DESPLIEGUE", C.GREEN),
                                        ("cancel", self.siege_buttons["cancel"], "[ESC] CANCELAR", C.DARK_GRAY)):
            hud.panel(screen, rect, C.YELLOW if rect.collidepoint(pygame.mouse.get_pos()) else color)
            hud.text(screen, title, rect.center, "m", color, center=True)

    def handle_event(self, event):
        if self.siege_prompt:                                                   # la confirmación manda sobre todo
            self._siege_prompt_event(event)
            return
        if self.advisor.handle_event(event):                                    # explicación de VULCANO: ENTER / ESC
            return
        if event.type == pygame.KEYDOWN and event.key == pygame.K_h:          # [H]: vuelve a mostrar reporte y ayudas
            self.report_fade.reset()
            self.help_fade.reset()
            return
        if self.advisor.modal and event.type in (pygame.KEYDOWN, pygame.MOUSEBUTTONDOWN):
            return
        if self.tactical_camera_event(event, (self.map_w, self.map_h)):        # clic central arrastrado: mueve la cámara
            return
        if self.menu is not None and self.handle_construction_event(event):   # menú abierto: manda sobre las demás teclas
            return
        if self._selection_ok(event) and self.selection_event(event):          # drones: clic / caja y órdenes (clic der.)
            return
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_SPACE:
                self.deploy()
            elif self.handle_build_key(event):
                pass
            elif event.key == pygame.K_e:
                if not self._click_props(self.camera.to_world(pygame.mouse.get_pos())):
                    self.upgrade_under_cursor()              # mejora el muro bajo el cursor (control táctico, sin distancia)
            elif event.key == pygame.K_f:
                self.repair_all()
            elif event.key == pygame.K_c:
                self.install_component()
        elif event.type == pygame.MOUSEBUTTONDOWN:
            world_pos = self.camera.to_world(event.pos)
            if event.button == 3 and self.build_choice is None and pygame.key.get_pressed()[pygame.K_x]:
                self.demolish(self.structure_at(world_pos))          # atajo: X + clic der. vende directamente
                return
            if event.button == 3 and self.build_choice is None and self.menu is None:
                site = self.site_under(world_pos)                     # clic der. sobre una obra en cola: la cancela
                if site is not None:
                    self.cancel_site(site)
                    return
            if self.handle_construction_event(event):                # menú de estructura (mejorar / vender)
                return
            if event.button == 1:
                if self.buttons["deploy"].collidepoint(event.pos):
                    self.deploy()
                elif self.buttons["repair"].collidepoint(event.pos):
                    self.repair_all()
                elif self.buttons["install"].collidepoint(event.pos):
                    self.install_component()
                elif self.build_choice is None and self._click_props(world_pos):
                    pass                                     # clic sobre un terminal: Búnker, su consola o el Terminal de Campaña
                elif self.build_choice is None:              # clic sobre una estructura dañada: repararla
                    b = self.structure_at(world_pos)
                    if b is not None:
                        self.repair_structure(b)

    # --- bucle ---
    def update(self, dt):
        keys = pygame.key.get_pressed()
        self.camera.tactical_update(dt, keys, pygame.mouse.get_pos(), (self.map_w, self.map_h))   # cámara libre tipo RTS
        self.camera.tick(dt)
        combat.FX.update(dt)
        combat.FX.consume_shake()
        self.dialogue.update(dt)
        self.report_fade.update(dt)
        self.help_fade.update(dt)
        if self.game.hud.base_report_rect(self.report_lines()).collidepoint(pygame.mouse.get_pos()):
            self.report_fade.reset()                         # ratón sobre el reporte: se queda (y se vuelve a ver)
        mouse = pygame.mouse.get_pressed()
        if any(r.collidepoint(pygame.mouse.get_pos()) for r in self.buttons.values()):
            mouse = (False, mouse[1], mouse[2])                      # clic sobre un botón: no construye debajo
        cursor = self.camera.to_world(pygame.mouse.get_pos())
        self.update_bunker(dt, None, cursor)
        term = self.campaign_terminal
        term.update(dt)
        term.near = term.rect.collidepoint(cursor)
        self.process_build_input(dt, keys, mouse, self.camera.to_world(pygame.mouse.get_pos()))
        self._refresh_menu()
        self.grid.update()
        self.energy_tick()
        self.work_sites(dt)                                  # VULCANO: repara lo crítico o construye la cola de obras
        w = self.world
        if self.advisor.phase != "trial":                    # (en la prueba del Mentor ya avanzan todas las estructuras)
            for f in list(w.factories):                      # ensamblaje y fabricación: los drones salen aquí mismo
                f.update(dt, w.targets, w.bullets)
        w.drones.update(dt, w)                               # esperan junto a su Fábrica o cumplen la orden recibida
        w.bombs.update(dt, w)
        self.tick_selection(dt)
        if self.order_marker is not None:
            self.order_marker[1] -= dt
            if self.order_marker[1] <= 0:
                self.order_marker = None
        self.advisor.update(dt)                              # Mentor VULCANO: pasos guiados y micro-oleadas de prueba
        self._update_cursor(cursor)

    def draw(self, screen):
        cam = self.camera
        self.game_map.draw_background(screen, cam)
        self.grid.draw(screen, cam.offset)
        self.advisor.draw_world(screen, cam.offset)          # zona marcada del paso guiado
        self.draw_selection_rings(screen)
        cam.draw_group(screen, self.all_sprites)
        self.draw_build_preview(screen)
        self.draw_selection_overlay(screen)                  # caja de selección de drones
        can_repair = bool(self.damaged())
        cost_all = sum(self.repair_cost(b) for b in self.damaged())
        buttons = [
            (self.buttons["deploy"], "DESPLEGAR OPERADOR  [ESPACIO]", True, C.GREEN),
            (self.buttons["repair"], f"[F] Reparar todo ({cost_all} metal)", can_repair, C.YELLOW),
            (self.buttons["install"], "[C] Instalar componente (gratis)",
             self.res.chassis_available > 0, C.MAGENTA),
        ]
        self.game.hud.draw_base(screen, self.report_lines(), self.build_choice, self.build_menu, self._cost,
                                self.res, buttons, self.dialogue, self.report_fade.alpha, self.help_fade.alpha)
        self.draw_structure_menu(screen)
        self.advisor.draw_panel(screen, self.game.hud)
        self.game.hud.text(screen, self.vulcano_status_text(), (C.WINDOW_WIDTH // 2, C.WINDOW_HEIGHT - 124), "s", C.CYAN, center=True)
        self.draw_tooltips(screen)
        if self.siege_prompt:
            self._draw_siege_prompt(screen)
