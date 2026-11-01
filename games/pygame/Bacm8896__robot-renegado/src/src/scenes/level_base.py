"""Base común de los sub-actos 1.1 a 1.4: nivel por cuadrícula, jugador, enemigos guardianes, diálogos y checkpoints."""
import random

import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.entities import WorldRefs
from src.entities.ammo import AmmoBox
from src.entities.chassis import ChassisPart
from src.entities.core_item import CoreItem
from src.entities.enemy import Enemy, ammo_drop_chance, roll_core_drop, roll_drop
from src.entities.medkit import Medkit, medkit_drop_chance
from src.entities.player import Player
from src.entities.projectile import Projectile
from src.core.audio_manager import audio
from src.entities.scrap import ScrapItem
from src.managers.state_machine import GameState, State, SubAct
from src.map.game_map import Camera
from src.mechanics import combat
from src.mechanics.pathing import FlowField
from src.ui.dialogue_box import DialogueBox
from src.ui.tooltips import pickup_card, pickup_under
from src.ui.hints import ammo_hints


class LevelScene(State):
    SUB_ACT = None              # SubAct del sub-acto
    NEXT = None                 # GameState al completarlo
    LEVEL = None                # función que construye el Level
    HINT = ""                   # línea de controles del HUD
    HUNT_PLAYER = False         # los guardianes persiguen al jugador (con línea de visión / al oír disparos)
    SCRAP_DROP = 1.0            # probabilidad de que un enemigo suelte chatarra
    INFINITE_AMMO = True        # Acto 1: munición infinita (semiautomática); las incursiones (Acto 2+) la limitan

    # ------------------------------------------------------------------ ciclo de vida
    def enter(self):
        g = self.game
        self.retried = g.begin_sub_act(self.SUB_ACT)
        self.res = g.resources
        combat.FX.clear()
        self.level = self.make_level()
        self.map_rect = pygame.Rect(0, 0, *self.level.size)
        Projectile.world_rect = self.map_rect
        self.camera = Camera(C.WINDOW_WIDTH, C.WINDOW_HEIGHT)
        self.all_sprites = pygame.sprite.Group()
        self.dynamic = pygame.sprite.Group()           # sprites con update(dt) propio
        self.interactables = []
        self.blockers = pygame.sprite.Group(self.level.solids)   # lo que frena las balas
        self.world = WorldRefs(all_sprites=self.all_sprites, bounds=self.map_rect)
        w = self.world
        w.solids.add(*self.level.solids)
        self.nav = FlowField(*self.level.size, hard=self.level.wall_cells)
        self.dialogue = DialogueBox()
        self.player = Player(self.level.marker("start"), *self.level.size)
        self.player.equipped = self.res.equipped
        self.player.apply_upgrades(self.res)                             # Terminal Táctico + componentes del chasis
        self.player.infinite_ammo = self.INFINITE_AMMO
        self.player.melee_targets = (w.enemies, w.bosses)
        self.player.aim_targets = (w.enemies, w.bosses, w.scavengers)   # asistencia de apuntado
        self.player.projectile_groups = (w.bullets,)
        w.player = self.player
        self.all_sprites.add(self.player)
        self.end_timer = None
        self._fail_reason = ""
        self.pending_next = None
        self.kills = 0
        self._last_shots = 0
        self.paused = False                          # pausa táctica (ESPACIO): dt = 0
        self.name_prompt = None                      # caja de texto del nombre (AURA en el 1.2): congela el mundo
        self.hints = self.game.hints
        self.hints.clear_active()
        self.setup()
        self.start_hints()
        self.camera.update(self.player.pos, self.level.size)

    def make_level(self):
        return type(self).LEVEL()

    def setup(self):
        raise NotImplementedError

    # ------------------------------------------------------------------ utilidades
    def say(self, sender, text, duration=5.0, blocking=False):
        self.dialogue.say(sender, text, duration, blocking)

    def notify(self, text, ttl=3.0):
        self.say("SISTEMA", text, ttl)

    def tell(self, lines, short=None):
        """Secuencia narrativa: bloqueante la primera vez; al reintentar solo un aviso breve."""
        if self.retried:
            if short:
                self.say(*short)
            return
        for sender, text in lines:
            self.say(sender, text, blocking=True)

    def add_dynamic(self, sprite, solid=False, blocker=False):
        self.all_sprites.add(sprite)
        if hasattr(sprite, "update"):
            self.dynamic.add(sprite)
        if solid:
            self.world.solids.add(sprite)
        if blocker:
            self.blockers.add(sprite)
        return sprite

    def add_interactable(self, obj, solid=False):
        self.interactables.append(obj)
        return self.add_dynamic(obj, solid=solid, blocker=solid)

    def spawn_enemy(self, kind, pos, chasing=False, sight=None, target=None):
        w = self.world
        e = Enemy(kind, pos, target if target is not None else pos, w.enemies)
        e.chasing = chasing
        e.world = w                                       # para disparar / cargar contra lo que tiene delante
        if sight is not None:
            e.sight = sight
        e.on_death = self._on_enemy_death
        w.enemies.add(e)
        w.targets.add(e)
        self.all_sprites.add(e)
        return e

    def drop_scrap(self, pos, value=C.SCRAP_VALUE):
        s = ScrapItem(pos, value)
        self.world.scraps.add(s)
        self.all_sprites.add(s)
        return s

    def drop_ammo(self, pos):
        box = AmmoBox(pos)
        self.world.ammo_boxes.add(box)
        self.all_sprites.add(box)
        return box

    def roll_ammo_drop(self, pos, kind="scout", rng=random):
        """Acto 2+: un enemigo suelta una caja de munición (30% los comunes, 40% Arietes y Tanques)."""
        if not self.INFINITE_AMMO and rng.random() < ammo_drop_chance(kind):
            return self.drop_ammo(pos)
        return None

    def drop_medkit(self, pos):
        kit = Medkit(pos)
        self.world.medkits.add(kit)
        self.all_sprites.add(kit)
        return kit

    def roll_medkit_drop(self, pos, kind="scout", rng=random):
        """Botín: un enemigo suelta a veces un botiquín (UNITS.MEDKITS["enemy_chance"])."""
        if rng.random() < medkit_drop_chance(kind):
            return self.drop_medkit(pos + Vector2(-12, 8))
        return None

    def use_medkit(self):
        """[H] Consume un botiquín del bolsillo y devuelve un bloque de vida perdido."""
        p = self.player
        if not p.alive():
            return False
        if self.res.medkits <= 0:
            self.notify("Sin botiquines: los sueltan los enemigos y aparecen en los alijos.", 3)
            return False
        if not p.use_medkit():
            self.notify("No has perdido ningún bloque de vida.", 2)
            return False
        self.res.medkits -= 1
        return True

    def drop_core(self, pos, value=1):
        item = CoreItem(pos, value)
        self.world.core_items.add(item)
        self.all_sprites.add(item)
        return item

    def collect_cores(self, amount):
        self.res.add_cores(amount)

    def drop_part(self, pos):
        if not self.res.chassis_part_due(len(self.world.parts)):        # chasis ya completo: chatarra y núcleos en su lugar
            self.drop_scrap(pos, U.CHASSIS_SURPLUS["scrap"])
            self.drop_core(Vector2(pos) + Vector2(14, 10), U.CHASSIS_SURPLUS["cores"])
            return None
        part = ChassisPart(pos, self.res.chassis_found + len(self.world.parts))     # pieza distinta cada vez
        self.world.parts.add(part)
        self.all_sprites.add(part)
        return part

    def _on_enemy_death(self, enemy):
        self.kills += 1
        if enemy.enemy_type == "tank" or enemy.carries_part:   # tanques y portadores llevan piezas del chasis de AURA
            self.drop_part(enemy.pos)
        self.roll_ammo_drop(enemy.pos, enemy.enemy_type)
        self.roll_medkit_drop(enemy.pos, enemy.enemy_type)
        cores = roll_core_drop(enemy.enemy_type)
        if cores:
            self.drop_core(enemy.pos + Vector2(14, 10), cores)
        value = roll_drop(enemy.enemy_type)               # chatarra según el tipo de enemigo (UNITS)
        if value and random.random() < self.SCRAP_DROP:
            self.drop_scrap(enemy.pos, value)

    def begin_transition(self, lines, next_state=None):
        """Cinemática de checkpoint: líneas bloqueantes (pausan el mundo) y después cambia de sub-acto."""
        for sender, text in lines:
            self.say(sender, text, blocking=True)
        self.pending_next = next_state if next_state is not None else self.NEXT

    def on_name_entered(self, text):
        """Gancho: el Operador terminó de escribir su nombre (ENTER)."""

    def fail(self, reason):
        if self.end_timer is None:
            self.end_timer = 1.5
            self._fail_reason = reason

    # ------------------------------------------------------------------ guardianes
    def steer_guards(self):
        """Los guardianes despiertan al ver al jugador (línea de visión) o al oír sus disparos."""
        p, nav, w = self.player, self.nav, self.world
        if not p.alive():
            return
        fired = p.shots_fired != self._last_shots
        self._last_shots = p.shots_fired
        nav.retarget(p)
        nav.update(w.structures, p)
        for e in w.enemies:
            d = p.pos.distance_to(e.pos)
            if e.chasing:
                if d > C.DEAGGRO_RADIUS:
                    e.chasing = False
            else:
                sees = d < e.sight and nav.has_line_of_sight(e.pos, p.pos)
                heard = fired and d < 700
                if sees or heard:
                    e.chasing = True
            e.target_pos = Vector2(p.pos) if e.chasing else Vector2(e.pos)

    # ------------------------------------------------------------------ eventos
    def handle_event(self, event):
        if self.dialogue.blocking_active:
            # Diálogo narrativo: ESPACIO / ENTER / E / clic izquierdo avanzan; el resto se ignora
            if ((event.type == pygame.KEYDOWN and event.key in (pygame.K_SPACE, pygame.K_RETURN, pygame.K_e))
                    or (event.type == pygame.MOUSEBUTTONDOWN and event.button == 1)):
                self.dialogue.advance()
                self.player.suppress_inputs()            # que ese ESPACIO/clic no dispare Dash ni tiro
            return
        if self.name_prompt is not None:                 # escribiendo el nombre: todas las teclas van a la caja
            self.name_prompt.handle_event(event)
            if self.name_prompt.done:
                prompt, self.name_prompt = self.name_prompt, None
                self.on_name_entered(prompt.text)
            return
        if event.type == pygame.KEYDOWN and event.key == pygame.K_SPACE and self.pending_next is None \
                and self.end_timer is None:
            self.paused = not self.paused                # pausa táctica: dt = 0, el HUD sigue visible
            self.camera.returning = not self.paused      # al reanudar, la cámara vuelve suavemente al Operador
            audio.play("build_mode" if self.paused else "build_mode_off")
            return
        if (self.paused and event.type == pygame.MOUSEMOTION and getattr(event, "buttons", (0, 0, 0))[1]):
            self.camera.drag(event.rel, self.level.size)         # clic central arrastrado mueve la cámara
            return
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_h:
                self.use_medkit()
                return
            if event.key == pygame.K_e:
                candidates = sorted((it for it in self.interactables if it.can_interact(self.player)),
                                    key=lambda it: it.pos.distance_squared_to(self.player.pos))
                if candidates:
                    candidates[0].interact(self)
                    return
                self.pickup_nearby_scrap()               # E recoge la chatarra cercana
                return
        self.handle_scene_event(event)

    def pickup_nearby_scrap(self):
        """Tecla E: aspira la chatarra a menos de C.SCRAP_PICKUP_RANGE del Operador."""
        if not self.player.alive():
            return 0
        gained = combat.pickup_scraps(self.player, self.world.scraps, radius=C.SCRAP_PICKUP_RANGE)
        if gained:
            self.collect_scrap(gained)
            self.hints.done("scrap")
        combat.pickup_ammo(self.player, self.world.ammo_boxes, radius=C.SCRAP_PICKUP_RANGE)
        combat.pickup_medkits(self.player, self.world.medkits, self.res, radius=C.SCRAP_PICKUP_RANGE)
        cores = combat.pickup_cores(self.player, self.world.core_items, radius=C.SCRAP_PICKUP_RANGE)
        if cores:
            self.collect_cores(cores)
        return gained

    # ------------------------------------------------------------------ hints (Acto 1)
    def start_hints(self):
        """Acto 1: WASD y disparo en los primeros segundos (el disparo, en cuanto el rifle está equipado)."""
        h = self.hints
        if self.SUB_ACT is SubAct.S1_1:
            h.show("wasd", "Movimiento", "wasd")
        if self.res.equipped:
            self._show_shoot_hints()

    def _show_shoot_hints(self):
        """Acto 1: el disparo es semiautomático; Acto 2+ ya lo conoce y los hints de munición toman el relevo."""
        if self.player.infinite_ammo:
            self.hints.show("shoot", "Disparar (semiautomático)", "click_left")
            self.hints.show("semi", "Cada clic = 1 disparo. En Acto 2 ganará mejoras.", "click_left")
        else:
            self.hints.show("shoot", "Disparar", "click_left")

    def update_hints(self, dt, keys):
        h = self.hints
        if any(keys[k] for k in (pygame.K_w, pygame.K_a, pygame.K_s, pygame.K_d)):
            h.done("wasd")
        if self.res.equipped:
            self._show_shoot_hints()                     # aparece al equiparse (ya existe el rifle)
        if self.player.shots_fired > 0:
            h.done("shoot")
            h.done("semi")
        ammo_hints(h, self.player)
        if len(self.world.scraps):
            first = next(iter(self.world.scraps))
            h.show("scrap", "E para recoger", "e", anchor=lambda s=first: s.pos if s.alive() else None)
        h.update(dt)

    def pause_tick(self, dt):
        """Hook: qué sigue vivo durante la pausa táctica (el tutorial de fortificación permite construir)."""

    def handle_scene_event(self, event):
        if event.type == pygame.MOUSEBUTTONDOWN and event.button == 3 and not self.paused:
            self.player.queue_melee()                            # clic derecho: golpe cuerpo a cuerpo

    # ------------------------------------------------------------------ bucle
    def update_scene(self, dt, keys, mouse_world):
        pass

    def update(self, dt):
        w = self.world
        self.camera.tick(dt)
        combat.FX.update(dt)
        if combat.FX.consume_shake():
            self.camera.shake()
        self.dialogue.update(dt)
        if self.pending_next is not None:                # cinemática de checkpoint en curso
            if not self.dialogue.blocking_active:
                self.game.advance(self.pending_next)     # pasa por la Base Central si VULCANO está en línea
            return
        if self.end_timer is not None:
            self.end_timer -= dt
            if self.end_timer <= 0:
                self.on_fail_timeout()
            return
        if self.dialogue.blocking_active or self.name_prompt is not None:
            return
        if self.paused:
            self.camera.tactical_update(dt, pygame.key.get_pressed(), pygame.mouse.get_pos(), self.level.size)
            self.pause_tick(dt)
            return
        keys = pygame.key.get_pressed()
        mouse_world = self.camera.to_world(pygame.mouse.get_pos())
        self.update_hints(dt, keys)

        self.player.update(dt, keys, mouse_world, w.solids, False)
        self.update_scene(dt, keys, mouse_world)
        if self.HUNT_PLAYER:
            self.steer_guards()
        self.dynamic.update(dt)
        w.enemies.update(dt, w.structures, self.nav, w.solids)
        w.bosses.update(dt, w)
        w.bullets.update(dt)
        w.enemy_bullets.update(dt)
        w.shells.update(dt)
        w.scraps.update(dt, self.player)
        w.ammo_boxes.update(dt, self.player)
        w.medkits.update(dt, self.player, self.res.medkits < C.MEDKIT_MAX)
        w.core_items.update(dt, self.player)
        w.parts.update(dt, self.player)
        combat.resolve_projectiles(w.bullets, w.enemies, w.scavengers, self.blockers, None, w.bosses)
        pygame.sprite.groupcollide(w.enemy_bullets, self.blockers, True, False)      # los muros frenan los disparos enemigos
        combat.resolve_enemy_bullets(w.enemy_bullets, self.player, w.drones, w.structures)
        combat.resolve_enemy_player(self.player, w.enemies, dt)
        if self.player.alive():
            combat.pickup_ammo(self.player, w.ammo_boxes)
            combat.pickup_medkits(self.player, w.medkits, self.res)
            cores = combat.pickup_cores(self.player, w.core_items)
            if cores:
                self.collect_cores(cores)
            gained = combat.pickup_scraps(self.player, w.scraps)
            if gained:
                self.collect_scrap(gained)
            parts = combat.pickup_parts(self.player, w.parts)
            if parts:
                self.res.chassis_found += parts
                self.say("VULCANO" if self.res.vulcano_online else "SISTEMA",
                         "Componente del chasis de AURA recuperado: se instala en la Base Central.", 5)
        for it in self.interactables:
            it.near = it.can_interact(self.player)
        self.camera.update(self.player.pos, self.level.size, dt)
        if self.player.dead:
            self.fail("El piloto cayó en combate.")

    def on_fail_timeout(self):
        """Por defecto: pantalla de reintento del sub-acto."""
        self.game.machine.transition(GameState.RETRY_SUB_ACT, reason=self._fail_reason,
                                     stats=self.retry_stats())

    def collect_scrap(self, amount):
        self.res.add_metal(amount)

    def retry_stats(self):
        return [f"Enemigos derrotados en este sub-acto: {self.kills}"]

    # ------------------------------------------------------------------ dibujo
    def radar_targets(self):
        return []

    def radar_enemies(self):
        return self.world.enemies

    def radar_fog(self):
        """Niebla que limita el radar a lo explorado (None: el radar muestra todo el mapa)."""
        return None

    def objective(self):
        return ""

    def checklist(self):
        return None

    def banner(self):
        return None

    def build_info(self):
        return None

    def draw_extra(self, screen):
        pass

    def draw(self, screen):
        cam, w = self.camera, self.world
        screen.blit(self.level.background, (0, 0),
                    pygame.Rect(round(cam.offset.x), round(cam.offset.y), C.WINDOW_WIDTH, C.WINDOW_HEIGHT))
        self.draw_under(screen)
        cam.draw_group(screen, self.all_sprites, w.bullets, w.enemy_bullets)
        combat.FX.draw(screen, cam.offset)
        self.draw_extra(screen)
        cam.apply_shake(screen)
        radar = None
        if self.res.aura_linked:
            radar = {"level": self.level, "enemies": self.radar_enemies(), "bosses": w.bosses, "fog": self.radar_fog(),
                     "targets": self.radar_targets(), "player_screen": cam.to_screen(self.player.pos)}
        self.game.hud.draw_level(screen, self.player, self.res, self.SUB_ACT.value, self.objective(),
                                 self.dialogue, radar=radar, checklist=self.checklist(),
                                 banner=self.banner(), build=self.build_info(), level_hint=self.HINT)
        self.hints.draw(screen, self.game.hud, cam)
        self.draw_top(screen)
        if self.paused:
            self.game.hud.pause_banner(screen, self.PAUSE_TITLE)
        if self.name_prompt is not None and not self.dialogue.blocking_active:
            self.name_prompt.draw(screen, self.game.hud)

    PAUSE_TITLE = "PAUSA TÁCTICA"

    def draw_under(self, screen):
        pass

    def draw_pickup_tooltip(self, screen):
        """Tarjeta del material o componente del suelo bajo el ratón (a los 0,5 s)."""
        tt = self.game.tooltips
        mouse = pygame.mouse.get_pos()
        w = self.world
        item = pickup_under((w.scraps, w.core_items, w.ammo_boxes, w.parts), self.camera.to_world(mouse))
        card = None if item is None or self.paused else pickup_card(item, self.res)
        if card is None:
            tt.clear()
        elif tt.hover(("pickup", id(item))):
            self.game.hud.draw_card(screen, mouse, card)

    def draw_top(self, screen):
        """Capa por encima del HUD (menús emergentes)."""
        self.draw_pickup_tooltip(screen)
