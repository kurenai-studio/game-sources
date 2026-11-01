"""Acto 1 completo: sub-actos 1.1 a 1.4 (La Frecuencia Fantasma -> El Búnker Olvidado y VULCANO)."""
import math

import pygame
from pygame.math import Vector2

import config as C
from src.entities.boss import LightRam
from src.entities.building import Building, create_building
from src.config import UNITS as U
from src.entities.interactable import Airlock, AuraModule, Beacon, Hatch, LinkConsole, Locker, SupplyCache, Terminal
from src.entities.obstacle import DashBarrier
from src.entities.power import PowerGrid
from src.entities.vulcano import Vulcano
from src.managers.state_machine import GameState, SubAct
from src.map.levels import build_level_1_1, build_level_1_2, build_level_1_3, build_level_1_4
from src.mechanics.construction import ConstructionMixin
from src.mechanics.save_manager import clean_name
from src.scenes.level_base import LevelScene
from src.ui.name_input import NameInput


# =============================================================================
# 1.1 La Frecuencia Fantasma
# =============================================================================
class Sub11State(LevelScene):
    SUB_ACT = SubAct.S1_1
    NEXT = GameState.SUB_ACT_1_2
    LEVEL = staticmethod(build_level_1_1)
    HINT = "WASD mover · E interactuar · SHIFT dash · clic izq. disparar · clic der. golpe · ESPACIO pausa"
    HUNT_PLAYER = True
    SCRAP_DROP = 1.0                       # el primer botín siempre cae: prueba del imán de recolección

    def setup(self):
        L = self.level
        self.player.equipped = self.res.equipped
        self.locker = self.add_interactable(Locker(L.marker("locker"), (56, 72), "Abrir alijo"))
        self.locker.on_interact = self._equip
        self.hatch = self.add_interactable(Hatch(L.marker("hatch"), (40, 80), "Abrir escotilla"), solid=True)
        self.hatch.on_interact = self._open_hatch
        self.barrier = self.add_dynamic(DashBarrier(L.cell_rect(17, 24, 1, 2)), solid=True, blocker=True)
        self.beacon = self.add_dynamic(Beacon(L.marker("beacon")))
        self.scout1 = self.spawn_enemy("scout", L.marker("scout1"), chasing=False, sight=110)   # de espaldas
        self.reinforced = False
        self.told_aura = False
        self.hinted_barrier = False
        self.completed = False
        self.tell([("SISTEMA", "Refugio sellado. Tras el apagón, el alijo guarda tu exoesqueleto y el rifle."),
                   ("SISTEMA", "Equípate (E), abre la escotilla y sal a la calle: una señal extraña te espera fuera.")],
                  short=("SISTEMA", "Refugio sellado. El alijo (E) guarda tu exoesqueleto y el rifle.", 7))

    # --- interacciones ---
    def _equip(self, scene, it):
        self.res.equipped = True
        self.player.equipped = True
        it.use()
        self.say("SISTEMA", "Exoesqueleto y rifle equipados: vida, dash y munición en línea.", 6)
        self.say("SISTEMA", "Ahora abre la escotilla (E) para salir a la calle.", 6)

    def _open_hatch(self, scene, it):
        if not self.res.equipped:
            self.notify("Sin el traje no puedes salir. Abre primero el alijo (E).", 4)
            return
        it.open(self.world.solids)
        self.blockers.remove(it)
        self.say("SISTEMA", "Escotilla abierta. Callejones exteriores: cuidado con los escombros.", 5)

    # --- bucle ---
    def update_scene(self, dt, keys, mouse_world):
        p = self.player
        if self.hatch.is_open and not self.told_aura and p.pos.x > self.hatch.pos.x + 90:
            self.told_aura = True
            self.tell([("AURA", f"{U.lore_intro('AURA')}... piloto... si me oyes... estoy atrapada en el Almacén 4..."),
                       ("AURA", "Sigue la frecuencia hacia el este. Por favor... date prisa.")],
                      short=("AURA", "Sigue la frecuencia hacia el este: Almacén 4.", 5))
        if not self.hinted_barrier and p.pos.distance_to(self.barrier.pos) < 220:
            self.hinted_barrier = True
            self.notify("Una brecha abierta corta el callejón: pega un DASH (SHIFT) para saltarla.", 7)
        if self.scout1.alive() and not self.reinforced:
            heard = p.shots_fired > 0 and p.pos.distance_to(self.scout1.pos) < 700
            if self.scout1.hp < self.scout1.max_hp or heard:
                self.reinforced = True
                for pos in self.level.markers["reinforce"]:
                    self.spawn_enemy("scout", pos, chasing=True)
                self.notify("¡Los disparos atraen a dos scouts más! Combate 1 contra 3.", 5)
        if not self.completed and self.beacon.contains(p):
            self.completed = True
            self.begin_transition([
                ("AURA", "La señal es más fuerte aquí... el Almacén 4 está justo delante."),
                ("AURA", "Ten cuidado dentro, piloto. Hay patrullas en cada esquina."),
                ])

    def objective(self):
        if not self.res.equipped:
            return "Busca el alijo del refugio (E)"
        if not self.hatch.is_open:
            return "Abre la escotilla del refugio (E)"
        return "Sigue la señal de AURA hasta el umbral del Almacén 4"


# =============================================================================
# 1.2 Infiltración en el Almacén 4
# =============================================================================
class Sub12State(LevelScene):
    SUB_ACT = SubAct.S1_2
    NEXT = GameState.SUB_ACT_1_3
    LEVEL = staticmethod(build_level_1_2)
    HINT = "WASD mover · SHIFT dash · clic izq. disparar · clic der. golpe · E interactuar · ESPACIO pausa"
    HUNT_PLAYER = True
    SCRAP_DROP = 0.5

    def setup(self):
        L, w = self.level, self.world
        self.res.equipped = True
        self.player.equipped = True
        for name in ("patrol_a", "patrol_b", "patrol_c"):            # patrullas de 2 scouts en las esquinas
            for pos in L.markers[name]:
                self.spawn_enemy("scout", pos)
        self.ram = LightRam(L.marker("ram"))
        self.ram.on_death = self._ram_dead
        w.bosses.add(self.ram)
        w.targets.add(self.ram)
        self.all_sprites.add(self.ram)
        self.aura_module = self.add_dynamic(AuraModule(L.marker("aura")))
        self.console = self.add_interactable(LinkConsole(L.marker("console"), (52, 64), "Enlace neuronal"))
        self.console.enabled = False
        self.console.on_interact = self._link
        self.exit_gate = self.add_dynamic(Airlock(L.marker("exit_gate"), (80, 40), "Esclusa"), solid=True, blocker=True)
        self.exit_gate.enabled = False                               # sellada (faro rojo) hasta enlazar con AURA
        self.tell([("AURA", "Piloto... mi módulo está en la sala de servidores, al fondo. Sigue mi pulso cian."),
                   ("AURA", "Un guardián blindado custodia la sala. Esquiva de lado y dispara a su espalda.")],
                  short=("AURA", "Sala de servidores al fondo: cuidado con el guardián blindado.", 6))

    def _ram_dead(self, ram):
        for i in range(3):
            self.drop_scrap(ram.pos + Vector2(math.cos(i * 2.1), math.sin(i * 2.1)) * 30)
        self.drop_part(ram.pos + Vector2(0, 40))                     # pieza del chasis de AURA
        self.drop_core(ram.pos + Vector2(-40, 20), U.PLASMA_POINTS["boss_core_drop"])    # y 1 Núcleo de Plasma seguro
        self.console.enabled = True
        self.notify("Guardián neutralizado. La consola de enlace neuronal está disponible (E).", 6)

    def _link(self, scene, it):
        it.enabled = False
        self.res.aura_linked = True
        self.exit_gate.open(self.world.solids)                       # la esclusa se despresuriza: faro verde
        self.blockers.remove(self.exit_gate)
        run = self.res.campaign_run
        if run.named:                                                # reintento: ya sabe cómo te llamas
            self.begin_transition([
                ("AURA", "Transfiriendo mi núcleo al firmware del exoesqueleto..."),
                ("AURA", f"Enlace completado, {run.player_name}. Soy tu copiloto: radar táctico y balizas guía activados."),
            ])
            return
        self.say("AURA", "Transfiriendo mi núcleo al firmware del exoesqueleto...", blocking=True)
        self.say("AURA", "Enlace completado. Antes de seguir necesito registrarte en mis sistemas: ¿cómo te llamas, piloto?",
                 blocking=True)
        self.name_prompt = NameInput("REGISTRO DE OPERADOR · A.U.R.A.", "AURA: «¿Cómo te llamas, piloto?»")

    def on_name_entered(self, text):
        """ENTER en la caja: el nombre queda en la campaña (perfil de guardado) y AURA lo confirma."""
        run = self.res.campaign_run
        run.player_name, run.named = clean_name(text), True
        name = run.player_name
        self.begin_transition([
            ("AURA", f"Registro completado. Encantada, {name}: a partir de ahora tu perfil lleva tu nombre."),
            ("AURA", f"Soy tu copiloto, {name}: radar táctico y balizas guía activados."),
        ])

    def objective(self):
        if self.ram.alive():
            if self.player.pos.distance_to(self.ram.pos) < 600:
                return "Derrota al Ariete Ligero: esquiva con Dash y dispara a su espalda"
            return "Avanza por los pasillos hasta la sala de servidores (pulso cian)"
        return "Conecta con la consola de AURA (E)"

    def radar_targets(self):
        return [(self.console.pos, C.CYAN)]


# =============================================================================
# 1.3 El Tránsito de la Plaza (tutorial de fortificación)
# =============================================================================
class Sub13State(ConstructionMixin, LevelScene):
    SUB_ACT = SubAct.S1_3
    NEXT = GameState.SUB_ACT_1_4
    LEVEL = staticmethod(build_level_1_3)
    panel_shift = 0
    HINT = "ESPACIO modo construcción · 1 pilón · 2 muro · 3 torreta · clic izq. construir · clic der. mejorar/vender · R+clic reparar"
    SCRAP_DROP = 0.4
    # Tutorial: 11 scouts y 3 soldados (el soldado dispara a 160 px: tiene que entrar en el alcance del rifle, 270)
    KINDS = ["scout", "scout", "soldier", "scout", "scout", "scout", "scout",
             "soldier", "scout", "scout", "scout", "soldier", "scout", "scout"]
    CARRIER = 11                                  # el último soldado lleva una pieza del chasis (rombo amarillo)

    def setup(self):
        L, w = self.level, self.world
        self._init_construction()
        self.build_menu = [(pygame.K_1, "pylon"), (pygame.K_2, "wall"), (pygame.K_3, "tower")]
        self.res.equipped = True
        self.player.equipped = True
        self.res.metal = max(self.res.metal, C.SUPPLY_METAL_1_3)     # suministro base del tutorial
        self.map_rect = pygame.Rect(0, 0, *L.size)
        self.grid = PowerGrid(w)
        self.core = create_building("core", L.marker("supply"))       # condensadores de AURA (fuente de energía)
        w.core = self.core
        self.core.use_reactor_art()                                   # Reactor Central (solo dibujo: misma caja y centro)
        self._register(self.core)
        self.grid.update()
        self._sync_energy()                                           # arranca con la energía base del Reactor: 0/50
        self.player.repair_callback = self._pay_repair
        self.hatch = self.add_interactable(Airlock(L.marker("hatch"), (80, 40), "Entrar al búnker"), solid=True)
        self.hatch.enabled = False
        self.hatch.on_interact = self._enter_bunker
        self.charge = float(C.AURA_CHARGE_TIME)
        self.elapsed = 0.0
        self.schedule = [(8.0 + 5.0 * i, kind, "w" if i % 2 == 0 else "e") for i, kind in enumerate(self.KINDS)]
        self.spawned = 0
        self.tell([("AURA", f"{self.res.player_name}, condensadores al 0%: necesito {C.AURA_CHARGE_TIME} segundos para "
                            "abrir la escotilla."),
                   ("SISTEMA", "Fortifica la plaza: pilones, muros en los 2 accesos y al menos 1 torreta.")],
                  short=("AURA", "Resiste hasta que los condensadores abran la escotilla.", 6))

    def notify(self, text, ttl=3.0):
        self.say("SISTEMA", text, ttl)

    def handle_scene_event(self, event):
        if self.handle_construction_event(event):            # menú de estructura (clic der.) y selección
            return
        self.handle_build_key(event)

    def pause_tick(self, dt):
        """En la pausa táctica se puede construir, mejorar y vender."""
        self.process_build_input(dt, pygame.key.get_pressed(), pygame.mouse.get_pressed(),
                                 self.camera.to_world(pygame.mouse.get_pos()))
        self.grid.update()
        self.energy_tick()
        self._refresh_menu()

    def draw_top(self, screen):
        if not self.dialogue.blocking_active and self.pending_next is None:
            self.game.hud.build_mode_notice(screen, self.build_menu, self.paused)       # «[ESPACIO] Modo Construcción»
        self.draw_structure_menu(screen)
        self.draw_tooltips(screen)

    PAUSE_TITLE = "MODO CONSTRUCCIÓN"

    def start_hints(self):
        super().start_hints()
        self.hints.show("build", "Clic izq. para construir", "click_left",
                        anchor=lambda: self.core.pos + Vector2(0, -90))

    # --- progreso del tutorial ---
    def accesses_closed(self):
        g = C.LEVEL_CELL
        extra = set()
        for s in self.world.structures:
            if s is self.core:
                continue
            for cx in range(s.rect.left // g, (s.rect.right - 1) // g + 1):
                for cy in range(s.rect.top // g, (s.rect.bottom - 1) // g + 1):
                    extra.add((cx, cy))
        goal = self.level.marker("start")
        gc = (int(goal.x // g), int(goal.y // g))
        closed = 0
        for spawn in ("spawn_w", "spawn_e"):
            if gc not in self.level.reachable(self.level.marker(spawn), extra):
                closed += 1
        return closed

    def powered_pylons(self):
        return sum(1 for p in self.world.pylons if p.is_powered)

    def towers_built(self):
        return len(self.world.towers)

    def checklist(self):
        return [("Pilón conectado al suministro de AURA", self.powered_pylons() >= 1),
                (f"Accesos cerrados ({self.accesses_closed()}/2)", self.accesses_closed() >= 2),
                ("Torreta defensiva", self.towers_built() >= 1)]

    def banner(self):
        if self.hatch.enabled:
            return "COMPUERTA ABIERTA"
        return f"Condensadores de AURA: {math.ceil(self.charge)} s"

    def objective(self):
        if self.hatch.enabled:
            return "Entra al búnker por la escotilla (E)"
        return "Resiste hasta que AURA abra la compuerta del búnker"

    def build_info(self):
        return {"choice": self.build_choice, "menu": self.build_menu, "cost_fn": self._cost,
                "energy_warning": self.energy_warning > 0}

    def radar_targets(self):
        return [(self.hatch.pos, C.YELLOW), (self.core.pos, C.CYAN)]

    def _enter_bunker(self, scene, it):
        it.enabled = False
        self.begin_transition([
            ("AURA", f"Compuerta abierta. Bajemos al búnker, {self.res.player_name}."),
        ])

    # --- bucle ---
    def update_scene(self, dt, keys, mouse_world):
        w = self.world
        self.process_build_input(dt, keys, pygame.mouse.get_pressed(), mouse_world)
        self.grid.update()
        self.energy_tick()
        self.nav.update(w.structures, self.core)
        if not self.hatch.enabled:
            self.elapsed += dt
            self.charge = max(0.0, self.charge - dt)
            while self.spawned < len(self.schedule) and self.schedule[self.spawned][0] <= self.elapsed:
                _, kind, side = self.schedule[self.spawned]
                spawn = self.level.marker("spawn_w" if side == "w" else "spawn_e")
                e = self.spawn_enemy(kind, spawn, chasing=True, target=self.core.pos)
                e.carries_part = self.spawned == self.CARRIER
                self.spawned += 1
            if self.charge <= 0:
                self.hatch.unlock("Entrar al búnker")
                self.say("AURA", "¡Condensadores cargados! La compuerta del búnker está abierta.", 7)
        w.structures.update(dt, w.targets, w.bullets)
        if not self.core.alive():
            self.fail("Los condensadores de AURA fueron destruidos.")

    def draw_extra(self, screen):
        self.draw_build_preview(screen)

    def retry_stats(self):
        return [f"Enemigos derrotados: {self.kills}",
                f"Accesos cerrados: {self.accesses_closed()}/2 · Torretas: {self.towers_built()}"]


# =============================================================================
# 1.4 El Búnker Olvidado y VULCANO
# =============================================================================
class Sub14State(LevelScene):
    SUB_ACT = SubAct.S1_4
    NEXT = GameState.ACT_2_BASE
    LEVEL = staticmethod(build_level_1_4)
    HINT = "WASD mover · E interactuar"

    def _add_structure(self, b):
        w = self.world
        w.structures.add(b)
        w.solids.add(b)
        self.all_sprites.add(b)

    def setup(self):
        L, w = self.level, self.world
        self.res.equipped = True
        self.player.equipped = True
        self.core = create_building("core", L.marker("core"))       # Centro de Control de la base
        w.core = self.core
        self._add_structure(self.core)
        self.demo_walls = []
        for pos in L.markers["demo_wall"]:                          # muros dañados para ver la auto-reparación
            wall = Building("wall", pos)
            wall.hp = wall.max_hp * 0.3
            self._add_structure(wall)
            self.demo_walls.append(wall)
        self.terminal = self.add_interactable(Terminal(L.marker("terminal"), (34, 44), "Reactivar VULCANO",
                                                       color=C.ORANGE))
        self.terminal.on_interact = self._reactivate
        self.exit_console = self.add_interactable(Terminal(L.marker("exit"), (34, 44), "INICIAR REPARACIÓN"))
        self.exit_console.enabled = False
        self.exit_console.on_interact = self._start_defense
        # compuerta del búnker que VULCANO suelda (decorativa: abierta hasta que termina la soldadura)
        self.gate = Hatch(L.marker("exit") + Vector2(46, 0), (16, 80), "Compuerta")
        self.gate.is_open, self.gate.enabled = True, False
        self.gate.image = self.gate._render(self.gate.rect.size)
        self.add_dynamic(self.gate)
        self.defense = None                                          # mini-defensa: None | dict de estado
        self.defense_fails = 0
        self.vulcano = None
        self.demo_done = False
        self.caches = []                                            # alijos de rescate (anti-softlock)
        self.rescues_spawned = 0
        self.tell([("AURA", f"Búnker central localizado, {self.res.player_name}. Reactiva a VULCANO desde la terminal del "
                            "centro (E).")],
                  short=("AURA", "Reactiva a VULCANO desde la terminal del centro (E).", 6))
        self._check_rescue()                                        # ¿hay chatarra para las reparaciones?

    # --- rescate anti-softlock: VULCANO necesita ~80 de chatarra para reparar los 3 muros ---
    def repair_needed(self):
        """Chatarra que aún hace falta para dejar listos los muros de demostración."""
        trigger = U.RESCUES["vulcano_sub_1_4"]["trigger_scrap_less_than"]
        if not self.res.vulcano_online:
            return trigger
        missing = sum(max(0.0, w.max_hp - w.hp) for w in self.demo_walls)
        return math.ceil(missing * C.VULCANO_METAL_PER_HP) + C.VULCANO_SCRAP_RESERVE    # VULCANO no toca la reserva

    def _check_rescue(self):
        """Si falta chatarra y no hay ya un alijo esperando, aparece uno (100 al norte, luego 50 al sur...)."""
        if self.demo_done or any(c.enabled for c in self.caches):
            return
        if self.res.metal >= self.repair_needed():
            return
        spec = U.RESCUES["vulcano_sub_1_4"]
        n = self.rescues_spawned
        amount = spec["alijo_1_amount"] if n == 0 else spec["alijo_2_amount"]
        marker = "rescue_n" if n % 2 == 0 else "rescue_s"
        cache = SupplyCache(self.level.marker(marker), amount)
        cache.on_interact = self._collect_cache
        self.caches.append(self.add_interactable(cache))
        self.rescues_spawned += 1
        self.say("SISTEMA", "Los sensores detectan suministros escondidos en la zona. Recógelos antes de reparar.", 8)
        self.hints.show("rescue", "Suministros detectados en la zona - recógelos para reparar", "e",
                        anchor=lambda c=cache: c.pos if c.alive() else None)

    def _collect_cache(self, scene, cache):
        if not cache.enabled:
            return
        cache.enabled = False
        self.res.add_metal(cache.amount)
        if cache in self.interactables:
            self.interactables.remove(cache)
        if cache in self.caches:
            self.caches.remove(cache)
        cache.kill()
        self.hints.done("rescue")
        self.notify(f"Suministros recuperados: +{cache.amount} chatarra.", 4)

    def _reactivate(self, scene, it):
        it.enabled = False
        self.res.vulcano_online = True
        self.res.add_metal(C.BUNKER_RESERVE)                        # reserva de metal del búnker
        self.vulcano = Vulcano(self.core.pos + Vector2(0, -70))
        self.all_sprites.add(self.vulcano)
        for sender, text in [
            ("VULCANO", f"{U.lore_intro('VULCANO')}: sistemas de mantenimiento reactivados tras décadas de silencio."),
            ("VULCANO", "Me vinculo al Centro de Control de esta base."),
            ("VULCANO", "Si una estructura cae por debajo del 50% de vida, la repararé con metal de la reserva."),
            ("AURA", f"Reserva del búnker: +{C.BUNKER_RESERVE} de metal. Cuantos más muros repare, mejor cobertura: "
                     "a cubierto, tus disparos harán más daño a los rezagados."),
            ("AURA", "Cuando estés listo, INICIA LA REPARACIÓN en la consola junto a la compuerta (E)."),
        ]:
            self.say(sender, text, blocking=True)
        self.exit_console.enabled = True

    # --- mini-defensa: proteger a VULCANO mientras suelda la compuerta ---
    def defense_profile(self):
        """Oleada de la soldadura: FIJA (UNITS.VULCANO_DEFENSE["fixed_profile"]); los muros ya no la agrandan."""
        return U.VULCANO_DEFENSE["fixed_profile"]

    def cover_walls(self):
        """Muros del búnker que dan cobertura: los que estaban reparados al empezar la soldadura y siguen en pie."""
        if not self.defense:
            return [wall for wall in self.demo_walls if wall.alive() and wall.hp >= wall.max_hp]
        return [wall for wall in self.defense["cover"] if wall.alive()]

    def cover_bonus(self):
        """Daño extra que reciben los rezagados: +5% por muro de cobertura (3 muros = +15%; destruidos = +0%)."""
        return U.VULCANO_DEFENSE["cover_bonus_per_wall"] * len(self.cover_walls())

    def _start_defense(self, scene, it):
        it.enabled = False
        spec = U.VULCANO_DEFENSE
        profile = self.defense_profile()
        door = Vector2(self.gate.pos)
        self.vulcano.start_welding(door + Vector2(-44, -30), door, spec["vulcano_hp"],
                                   shield=spec["cinematic"] + spec["grace_time"])         # gracia: cinemática + 3 s
        roster = [kind for kind, n in spec["profiles"][profile].items() for _ in range(n)]
        half = (len(roster) + 1) // 2
        self.defense = {"t": 0.0, "profile": profile, "groups": [(spec["cinematic"], roster[:half]),
                                                                (spec["cinematic"] + spec["second_group_at"], roster[half:])],
                        "done": False, "overload_said": False, "low_said": False, "cover": self.cover_walls()}
        self.say("VULCANO", "Iniciando soldadura de la compuerta... ¡BZZZT!", blocking=True)
        self.say("AURA", f"¡La alarma atrae a los rezagados! Protege a VULCANO {spec['duration']:.0f} segundos.", blocking=True)

    def _spawn_stragglers(self, roster):
        """Rezagados que entran por el oeste del búnker y van a por VULCANO."""
        doors = [Vector2(140, 260), Vector2(140, 430), Vector2(140, 600)]
        for i, kind in enumerate(roster):
            pos = doors[i % len(doors)] + Vector2(0, (i // len(doors)) * 26)
            if kind == "light_ram":
                ram = LightRam(pos)
                ram.on_death = lambda r: None
                self.world.bosses.add(ram)
                self.all_sprites.add(ram)
                continue
            e = self.spawn_enemy(kind, pos, chasing=True, target=self.vulcano.pos)
            e.always_active = True

    def _defense_tick(self, dt):
        d, spec, w = self.defense, U.VULCANO_DEFENSE, self.world
        d["t"] += dt
        escaping = d["done"]                                      # soldadura terminada: horda tras el Operador
        if not escaping:
            self.vulcano.weld(dt)
        for at, roster in list(d["groups"]):
            if d["t"] >= at:
                d["groups"].remove((at, roster))
                self._spawn_stragglers(roster)
        if not d["overload_said"] and d["t"] >= spec["cinematic"] + spec["overload_line_at"]:
            d["overload_said"] = True
            self.say("VULCANO", "¡Maldita sea! ¡Circuitos sobrecargados!", 4)
        goal = self.player if escaping else self.vulcano
        self.nav.retarget(goal)                                  # todos van a por VULCANO (o, al final, a por ti)
        self.nav.update(w.structures, goal)
        vulnerability = 1.0 + self.cover_bonus()              # a cubierto tras los muros reparados, pegas más fuerte
        for e in w.enemies:
            e.target_pos = Vector2(goal.pos)
            e.vulnerability = vulnerability
        if not escaping:
            for foe in list(w.enemies) + list(w.bosses):         # contacto: muerden a VULCANO
                if foe.alive() and foe.pos.distance_to(self.vulcano.pos) <= 38:
                    dps = U.ENEMIES[foe.enemy_type]["melee_dps"] if hasattr(foe, "enemy_type") else C.RAM_CONTACT_DAMAGE
                    self.vulcano.take_damage(dps * dt)
            v = self.vulcano
            if not d["low_said"] and 0 < v.hp <= v.max_hp * spec["low_hp_warning"]:
                d["low_said"] = True                             # aviso único: hay que volver a cubrirlo
                self.say("VULCANO", "¡Me están desarmando, piloto! ¡Cúbreme!", 4)
            if self.vulcano.hp <= 0:
                self.defense_fails += 1
                self.game.vulcano_defense_fails = getattr(self.game, "vulcano_defense_fails", 0) + 1
                self.fail("VULCANO FUE DESTRUIDO. MISIÓN ABORTADA.")
                return
        if d["t"] >= spec["cinematic"] + spec["duration"] and not d["done"]:
            d["done"] = True                                     # compuerta reparada: horda masiva y a evacuar
            self.vulcano.stop_welding()
            self._spawn_stragglers([k for k, n in spec["final_horde"].items() for _ in range(n)])
            self.gate.unlock("EVACUAR AL BÚNKER")
            self.gate.on_interact = self._evacuate
            if self.gate not in self.interactables:
                self.interactables.append(self.gate)
            self.say("VULCANO", "¡Brecha sellada! ¡Vienen demasiados, entra ya!", 6)
            self.say("AURA", f"¡Corre a la compuerta, {self.res.player_name}! Pulsa E para evacuar al búnker.", 6)

    def _evacuate(self, scene, it):
        """E en la compuerta reparada: se cierra tras el Operador y termina el Acto 1."""
        if not self.defense or not self.defense["done"]:
            return
        it.enabled = False
        self.begin_transition([
            ("VULCANO", "Compuerta cerrada. Esa horda se queda fuera: la base es nuestra."),
            ("AURA", f"Búnker asegurado. Es hora de salir, {self.res.player_name}: expedición regional y tuberías de metal. "
                     "El Acto 2 nos espera."),
        ])

    def defense_left(self):
        d, spec = self.defense, U.VULCANO_DEFENSE
        return max(0.0, spec["cinematic"] + spec["duration"] - d["t"]) if d else 0.0

    def retry_stats(self):
        lines = super().retry_stats()
        if self.defense is not None:
            lines.append(f"Soldadura de la compuerta: le faltaban {math.ceil(self.defense_left())} s "
                         f"(oleada {self.defense['profile']})")
        return lines

    def update_scene(self, dt, keys, mouse_world):
        if self.defense is not None:                                # soldando: VULCANO no se mueve ni repara
            self._defense_tick(dt)
            return
        for cache in list(self.caches):                             # también se recogen con solo acercarse
            if cache.enabled and cache.pos.distance_to(self.player.pos) <= 46:
                self._collect_cache(self, cache)
        self._check_rescue()
        if self.vulcano is not None:
            self.vulcano.update(dt, self.world, self.res)
            if not self.demo_done and all(wall.hp >= wall.max_hp for wall in self.demo_walls):
                self.demo_done = True
                self.say("VULCANO", "Muros reparados. Cuando quieras, inicia la soldadura en la consola (E).", 7)

    def objective(self):
        if not self.res.vulcano_online:
            return "Reactiva a VULCANO en la terminal central (E)"
        if self.defense is not None and self.defense["done"]:
            return "¡EVACÚA! Corre a la compuerta y pulsa E"
        if self.defense is not None:
            return f"¡Protege a VULCANO! Soldadura: {math.ceil(self.defense_left())} s"
        if not self.demo_done:
            return "VULCANO repara los muros... inicia la soldadura cuando estés listo (E)"
        return "Inicia la reparación de la compuerta en la consola (E)"

    def banner(self):
        if self.defense is None or self.vulcano is None:
            return None
        if self.defense["done"]:
            return "COMPUERTA REPARADA · EVACÚA"
        shield = f" · ESCUDO {math.ceil(self.vulcano.shield_time)} s" if self.vulcano.shield_time > 0 else ""
        return f"VULCANO {max(0, int(self.vulcano.hp))}/{self.vulcano.max_hp}{shield}"

    def radar_targets(self):
        pending = [(c.pos, C.GREEN) for c in self.caches if c.enabled]
        if pending:
            return pending                                          # primero, los suministros
        if self.defense is not None:
            return [(self.gate.pos, C.GREEN)] if self.defense["done"] else [(self.vulcano.pos, C.ORANGE)]
        target = self.terminal if self.terminal.enabled else self.exit_console
        return [(target.pos, C.ORANGE)]
