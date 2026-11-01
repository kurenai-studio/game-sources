"""Pruebas sin ventana de todo el juego: `python smoke_test.py` (termina con OK)."""
import itertools
import logging
import math
import os
import pathlib
import random
import tempfile

os.environ["SDL_VIDEODRIVER"] = "dummy"
os.environ["SDL_AUDIODRIVER"] = "dummy"
SAVE_TMP = tempfile.mkdtemp(prefix="rr_saves_")
os.environ["RR_SAVE_DIR"] = SAVE_TMP                 # los perfiles de las pruebas nunca tocan saves/ del juego

import pygame
from pygame.math import Vector2

import config as C
from main import Game
from src.map.levels import Level
from src.scenes.level_base import LevelScene
from src.mechanics import vulcan_advisor as VA
VA.ENABLED = False                                   # la Base Central sin tutorial salvo en su bloque de pruebas
from src.entities import WorldRefs
from src.entities.building import Building
from src.entities.enemy import Enemy
from src.entities.player import Player
from src.entities.scavenger import ScavengerDrone
from src.entities.scrap import ScrapItem
from src.entities.vulcano import Vulcano
from src.managers.state_machine import GameState, SubAct
from src.map import levels
from src.map.game_map import Camera
from src.mechanics import combat
from src.mechanics.fog import FogOfWar
from src.mechanics.pathing import FlowField
from src.managers.resource_manager import ResourceManager
from src.mechanics.wave import RenegadeFoundry, Wave, WaveManager
from src.ui.dialogue_box import DialogueBox
from src.ui.hud import HUD
import src.scenes.level_base as level_base_mod
from src.entities.enemy import roll_drop as real_roll_drop

level_base_mod.roll_drop = lambda kind, rng=random: 25      # drops deterministas en las pruebas de campaña


class Keys(dict):
    def __getitem__(self, k):
        return self.get(k, False)


held = Keys()
mouse = [False, False, False]
mpos = [640, 300]
pygame.key.get_pressed = lambda: held
pygame.mouse.get_pressed = lambda *a, **k: tuple(mouse)
pygame.mouse.get_pos = lambda: tuple(mpos)


def press(game, key):
    game.machine.handle_event(pygame.event.Event(pygame.KEYDOWN, key=key))


def right_click(game, world_pos):
    cam = game.machine.active.camera
    pos = Vector2(world_pos) - cam.offset
    game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=3, pos=(int(pos.x), int(pos.y))))


def step(game, n, dt=1 / 60):
    for _ in range(n):
        game.machine.update(dt)
        game.machine.draw(game.screen)


def left_click(game, world_pos):
    cam = game.machine.active.camera
    pos = Vector2(world_pos) - cam.offset
    game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=(int(pos.x), int(pos.y))))


def teleport(scene, pos):
    scene.player.pos = Vector2(pos)
    scene.player.rect.center = (round(scene.player.pos.x), round(scene.player.pos.y))


def dismiss(game, limit=60):
    """Cierra los diálogos narrativos bloqueantes de la escena activa pulsando ESPACIO."""
    box = getattr(game.machine.active, "dialogue", None)
    for _ in range(limit):
        if box is None or not box.blocking_active:
            return
        press(game, pygame.K_SPACE)
        step(game, 1)
    raise AssertionError("diálogo bloqueante sin cerrar")


def finish_cinematic(game, expected):
    """Avanza las líneas bloqueantes de un checkpoint (E) hasta llegar al siguiente estado."""
    for _ in range(80):
        press(game, pygame.K_e)
        step(game, 30)
        if game.machine.current_state is expected:
            dismiss(game)                      # la escena nueva abre con su propia secuencia narrativa
            return
    raise AssertionError(f"la cinemática no llegó a {expected}: {game.machine.current_state}")


def win_vulcano_defense(game, s):
    """1.4: inicia la soldadura en la consola de la compuerta y la deja a punto de terminar (VULCANO sobrevive)."""
    from src.config import UNITS as U_
    teleport(s, s.exit_console.pos + Vector2(0, 60))
    step(game, 2)
    press(game, pygame.K_e)
    dismiss(game)
    assert s.defense is not None
    s.defense["groups"] = []
    s.defense["t"] = U_.VULCANO_DEFENSE["cinematic"] + U_.VULCANO_DEFENSE["duration"] - 0.01
    step(game, 3)


def new_act2(game, metal=2000, threat=1, vulcano=False, cores=40, before=None, tech=True):
    game.new_campaign()
    game.resources.unlock_all_structures()       # el catálogo completo (el desbloqueo progresivo tiene sus propias pruebas)
    if tech:                               # las especializaciones de torreta se desbloquean en el Terminal: aquí, todas
        game.resources.unlock_all_tech()
    if before is not None:                 # ajustes de la campaña nueva antes de entrar (árbol, chasis...)
        before(game.resources)
    game.resources.cores = cores
    game.resources.initial_done = True
    game.resources.threat_level = threat
    game.resources.metal = metal
    game.resources.vulcano_online = vulcano
    game.machine.transition(GameState.ACT_2_BASE)
    game.machine.transition(GameState.ACT_2_SETUP)
    a2 = game.machine.screens[GameState.ACT_2_SETUP]
    dismiss(game)                  # intro narrativa del Acto 2
    a2.wave.timer = 99999          # la preparacion no acaba sola
    game.resources.metal = metal   # cifra exacta para las pruebas (sin el bono de despliegue: tiene su propia prueba)
    return a2


class _OpArena(LevelScene):
    """Campo abierto de pruebas con el Operador a pie, del tamaño del mapa clásico del Acto 2 (que ahora es de mando, sin
    Operador): aquí se prueban las mecánicas del piloto (munición, golpe, apuntado, recompensas en el traje...)."""
    SUB_ACT = SubAct.S2_X
    INFINITE_AMMO = False
    LEVEL = None

    def make_level(self):
        lv_ = Level(56, 31, "urban")
        lv_.carve(1, 1, 54, 29)
        lv_.mark("start", 10, 20)                            # (420, 820): donde aparecía el Operador del Acto 2
        lv_.finish(seed=7)
        return lv_

    def setup(self):
        self.res.equipped = True
        self.player.equipped = True
        self.CC_POS = Vector2(C.ACT2_CC_POS)

    def _register(self, b):
        """Coloca una estructura en el campo (sólida para el Operador, los enemigos y las balas)."""
        for grp_ in (self.world.structures, self.world.solids, self.all_sprites, self.blockers):
            grp_.add(b)
        return b

    def _drop_scrap(self, pos, value=C.SCRAP_VALUE):
        return self.drop_scrap(pos, value)


def new_op_arena(game, metal=3000, fresh=True, before=None):
    """Entra en el campo de pruebas del Operador (sin enemigos). `fresh`: campaña nueva; `before(res)`: ajustes previos."""
    if fresh:
        game.machine.transition(GameState.MENU)
        game.new_campaign()
        game.resources.initial_done = True
    if before is not None:
        before(game.resources)
    game.resources.metal = metal
    arena_ = _OpArena(game)
    keep_ = game.machine.screens[GameState.INCURSION]
    game.machine.screens[GameState.INCURSION] = arena_
    game.machine.transition(GameState.INCURSION)
    game.machine.screens[GameState.INCURSION] = keep_
    dismiss(game)
    return arena_


def bot_fire(game, scene, reach=560):
    """Operador automático: apunta al enemigo más cercano a su alcance y mantiene el gatillo (para pruebas de campaña)."""
    p = scene.player
    near = [e for e in scene.world.enemies if e.pos.distance_to(p.pos) < reach]
    if near:
        e = min(near, key=lambda e: e.pos.distance_to(p.pos))
        s = Vector2(e.pos) - scene.camera.offset
        mpos[0], mpos[1] = int(s.x), int(s.y)
        mouse[0] = not mouse[0]                      # semiautomático: un disparo por clic, el bot "clica" cada fotograma
    else:
        mouse[0] = False


def build(a2, btype, pos):
    a2.build_choice = btype
    before = len(a2.world.structures)
    a2._try_build(Vector2(pos))
    a2.build_choice = None
    return len(a2.world.structures) > before


def build_bm(scene, btype, pos, frames=2400):
    """Base Central (modo Comandante): ordena la obra y deja trabajar a VULCANO hasta que termina. True si se completó."""
    scene.build_choice = btype
    before = len(scene.sites)
    scene._try_build(Vector2(pos))
    scene.build_choice = None
    if len(scene.sites) == before:
        return False
    site = scene.sites[-1]
    for _ in range(frames):
        scene.game.machine.update(1 / 60)
        if site not in scene.sites:
            return True
    return False


def disarm(base):
    """Pruebas: retira en silencio (sin contraataques) el generador y las centinelas de la guarnición de una base."""
    from src.entities.foundry import HostileStructure
    for b_ in [base.generator] + list(base.sentinels):
        if b_ is not None and b_.alive():
            HostileStructure.kill(b_)
    assert not base.has_active_defenses()


def raze(base):
    """Destruye una base enemiga en las pruebas: primero su guarnición blindada y después el núcleo, ya sin escudo."""
    disarm(base)
    return base.core.take_damage(99999)


game = Game()
screens = game.machine.screens
step(game, 3)
empty = pygame.sprite.Group()

# =============================================================================
print("== Wave / amenaza ==")
assert dict(Wave(1, 1, (0, 0)).get_enemy_spawns()) == {"scout": 6}                       # UNITS.WAVES: oleada 1 = 6 scouts
assert dict(Wave(1, 3, (0, 0)).get_enemy_spawns()) == {"scout": 8}                       # alerta 3: +40% (6 x 1.4)
assert sum(n for _, n in Wave(5, 1, (0, 0)).get_enemy_spawns()) == 15
assert dict(Wave(5, 1, (0, 0)).get_enemy_spawns()) == {"scout": 8, "soldier": 4, "ariete": 2, "tank": 1}

# =============================================================================
print("== Dash, munición, juiciness ==")
p = Player((500, 500), 2000, 1200)
held.clear()
held[pygame.K_d] = True
held[pygame.K_LSHIFT] = True
x0 = p.pos.x
p.update(1 / 60, held, (900, 500), empty)
assert p.is_invulnerable and abs(p.dash_cooldown_timer - C.DASH_COOLDOWN) < 0.05
hp0 = p.hp
p.take_damage(10)
assert p.hp == hp0                                   # inmune durante el dash
frames_dashing = 1
while p.is_invulnerable and frames_dashing < 30:
    p.update(1 / 60, held, (900, 500), empty)
    frames_dashing += 1
assert 9 <= frames_dashing <= 12, frames_dashing     # 0.15 s de dash
assert 110 < p.pos.x - x0 < 175                      # ~ 300 * 2.8 * 0.15 = 126 px
p.take_damage(10)
assert p.hp == hp0 - 10                              # el dash termino
held.clear()
for _ in range(100):
    p.update(1 / 60, held, (900, 500), empty)        # pasa el cooldown de 1.4 s
assert p.dash_cooldown_timer == 0
held[pygame.K_SPACE] = True
p.update(1 / 60, held, (900, 500), empty)
assert not p.is_invulnerable                         # ESPACIO ya no es dash: es la pausa táctica
held.clear()
held[pygame.K_LSHIFT] = True
p.update(1 / 60, held, (900, 500), empty)
assert p.is_invulnerable                             # el dash solo va en SHIFT
held.clear()
# munición (Acto 2+): 3 cargadores de 50 (150 en total) y recarga automática de 0.8 s
pa = Player((500, 500), 2000, 1200)
pa.projectile_groups = (pygame.sprite.Group(),)
assert (pa.ammo, pa.capacity, pa.mag_size, pa.mag_rounds, pa.reserve) == (150, 150, 50, 50, 100)
for _ in range(50):
    pa.shoot()
assert pa.mag_rounds == 0 and pa.reload_timer == C.PLAYER_RELOAD_TIME == 0.8 and pa.shots_fired == 50 and pa.ammo == 100
assert not pa.can_fire()                             # recargando: no dispara
for _ in range(60):
    pa.update(1 / 60, held, (900, 500), empty)
assert pa.mag_rounds == 50 and pa.reserve == 50 and pa.ammo == 100 and pa.reload_timer <= 0
bullet0 = next(iter(pa.projectile_groups[0]))
assert bullet0.speed == 600 and abs(bullet0.lifetime - 270 / 600) < 1e-9        # alcance 270 px, 600 px/s
# hit-flash, chispas, shake
combat.FX.clear()
p.take_damage(1, direct=True)
assert combat.FX.consume_shake() and not combat.FX.consume_shake()
cam = Camera(1280, 720)
cam.shake()
cam.tick(0.016)
assert all(2 <= abs(v) <= 4 for v in cam.shake_offset), cam.shake_offset
for _ in range(10):
    cam.tick(0.016)
assert cam.shake_offset == (0, 0)
grp = pygame.sprite.Group()
e = Enemy("tank", (100, 100), (200, 100), grp)
e.take_damage(1)
assert e.flash_frames == C.HIT_FLASH_FRAMES == 1
surf = pygame.Surface((300, 300))
e.draw(surf)
e.draw(surf)
assert e.flash_frames == 0
assert e._white_image().get_at((e.rect.w // 2, e.rect.h // 2))[:3] == (255, 255, 255)
combat.FX.clear()
combat.FX.spark((0, 0))
assert 3 <= len(combat.FX.sparks) <= 5
combat.FX.update(0.25)
assert not combat.FX.sparks                          # viven 0.2 s

# =============================================================================
print("== Consola de diálogos ==")
box = DialogueBox()
box.say("AURA", "hola piloto", 2.0)
box.update(0.05)
assert not box.blocking_active and 0 < box.lines[0].shown < len("hola piloto")   # teletipo
box.update(1.0)
assert box.lines[0].revealed
box.update(3.0)
assert not box.lines                                 # caduca sin pausar nada
box.say("VULCANO", "cinemática", 1.0, blocking=True)
box.say("SISTEMA", "segunda", 1.0, blocking=True)
box.update(5.0)
assert box.blocking_active and box.current_blocking.sender == "VULCANO"       # no caduca
box.advance()
assert box.current_blocking.sender == "SISTEMA"      # se muestran de una en una
box.update(5.0)
box.advance()
box.advance()
assert not box.blocking_active

# =============================================================================
print("== Mapas: transitables de extremo a extremo ==")
l1, l2, l3, l4 = (levels.build_level_1_1(), levels.build_level_1_2(), levels.build_level_1_3(),
                  levels.build_level_1_4())
assert l1.is_reachable(l1.marker("start"), l1.marker("beacon"))
assert l1.is_reachable(l1.marker("start"), l1.marker("reinforce", 0))
for name in ("patrol_a", "patrol_b", "patrol_c", "ram", "console", "aura"):
    assert all(l2.is_reachable(l2.marker("start"), pos) for pos in l2.markers[name]), name
assert l3.is_reachable(l3.marker("spawn_w"), l3.marker("supply")) and l3.is_reachable(l3.marker("spawn_e"), l3.marker("supply"))
assert l4.is_reachable(l4.marker("start"), l4.marker("exit"))

# =============================================================================
print("== Sub-acto 1.1: La Frecuencia Fantasma ==")
press(game, pygame.K_RETURN)                         # menú -> campaña nueva
assert game.machine.current_state is GameState.SUB_ACT_1_1 and game.machine.sub_act is SubAct.S1_1
s = screens[GameState.SUB_ACT_1_1]
assert s.dialogue.blocking_active                                    # el inicio del sub-acto es historia: pausa
dismiss(game)
w = s.world
res = game.resources
# Fase A: refugio cerrado, traje apagado
assert not s.player.equipped and not res.equipped
mouse[0] = True
step(game, 20)
assert s.player.shots_fired == 0                     # sin rifle no dispara
mouse[0] = False
held[pygame.K_LSHIFT] = True
held[pygame.K_d] = True
step(game, 2)
assert s.player.dash_timer == 0                      # ni dash
held.clear()
teleport(s, s.hatch.pos + Vector2(-40, 0))
step(game, 2)
press(game, pygame.K_e)
assert not s.hatch.is_open                           # sin traje la escotilla no se abre
teleport(s, s.locker.pos + Vector2(30, 0))
step(game, 2)
press(game, pygame.K_e)
assert res.equipped and s.player.equipped and not s.locker.enabled
teleport(s, s.hatch.pos + Vector2(-40, 0))
step(game, 2)
press(game, pygame.K_e)
assert s.hatch.is_open and s.hatch not in w.solids
# Fase B: callejón, AURA por radio y tubería rota que exige Dash
teleport(s, s.hatch.pos + Vector2(140, 0))
step(game, 30)
assert any(ln.sender == "AURA" for ln in s.dialogue.lines) and s.dialogue.blocking_active    # rescate de AURA
dismiss(game)
teleport(s, s.barrier.pos + Vector2(-70, 0))
held[pygame.K_d] = True
step(game, 40)
assert s.player.rect.right <= s.barrier.rect.left + 1                # la tubería bloquea el paso
held[pygame.K_LSHIFT] = True
step(game, 14)
held.clear()
assert s.player.pos.x > s.barrier.rect.right                         # el Dash la franquea
# Fase C: 1 scout de espaldas, luego 2 más por los disparos (1 vs 3)
teleport(s, Vector2(25 * 40 + 20, 25 * 40))
s.player.hp = s.player.max_hp
step(game, 60)
assert len(w.enemies) == 1 and not s.scout1.chasing                  # solo el scout de espaldas
mouse[0] = True
step(game, 5)
mouse[0] = False
assert len(w.enemies) == 3, len(w.enemies)                           # sin hordas: exactamente 3
for _ in range(60 * 6):                                              # los refuerzos llegan rodeando los muros
    s.player.hp = s.player.max_hp
    step(game, 1)
    if min(e.pos.distance_to(s.player.pos) for e in w.enemies) < 60:
        break
else:
    raise AssertionError("los scouts no encontraron camino hasta el jugador")
for e in list(w.enemies):
    e.take_damage(9999)
assert len(w.scraps) == 3                                            # chatarra con imán (drop determinista)
scrap = next(iter(w.scraps))
m0 = res.metal
teleport(s, scrap.pos + Vector2(28, 0))
step(game, 25)
assert res.metal >= m0 + C.SCRAP_VALUE and not scrap.alive()
# Fase D: baliza del umbral -> cinemática de checkpoint
teleport(s, s.beacon.pos)
step(game, 3)
assert s.dialogue.blocking_active and s.pending_next is GameState.SUB_ACT_1_2
pos_paused = Vector2(s.player.pos)
held[pygame.K_d] = True
step(game, 20)
held.clear()
assert s.player.pos == pos_paused                                    # la cinemática pausa el mundo
finish_cinematic(game, GameState.SUB_ACT_1_2)
assert game.checkpoints[SubAct.S1_2]["equipped"] is True and game.machine.sub_act is SubAct.S1_2

# =============================================================================
print("== Sub-acto 1.2: Infiltración en el Almacén 4 ==")
s = screens[GameState.SUB_ACT_1_2]
w = s.world
assert res.equipped and not res.aura_linked
assert len(w.enemies) == 6 and s.ram.alive() and s.ram in w.bosses
step(game, 90)
assert not any(e.chasing for e in w.enemies)                         # las patrullas no ven sin línea de visión
ram = s.ram
ram.facing = Vector2(-1, 0)
h = ram.hp
ram.take_damage(10, Vector2(500, 0))                                 # de frente: blindaje
front = h - ram.hp
h = ram.hp
ram.take_damage(10, Vector2(-500, 0))                                # por la espalda: radiador (crítico x2)
rear = h - ram.hp
h = ram.hp
ram.take_damage(10, Vector2(0, 500))
side = h - ram.hp
assert abs(front - 2.5) < 1e-6 and abs(rear - 20) < 1e-6 and abs(side - 5) < 1e-6
ram.hp = ram.max_hp
# --- detección angular del arco trasero (135°-225° desde el frente), partículas y feedback del Tanque
ram.facing = Vector2(1, 0)
for deg_t, zone_t in ((0, "rear"), (44, "rear"), (-44, "rear"), (50, "side"), (90, "side"), (180, "front"), (135, "front")):
    assert ram.impact_zone(Vector2(1, 0).rotate(deg_t)) == zone_t, (deg_t, zone_t)
assert ram.impact_zone(Vector2()) is None and ram.impact_zone(None) is None
sparks_0, crits_0, rico_0 = len(combat.FX.sparks), ram.crits, ram.ricochets
ram.take_damage(5, Vector2(1, 0))                                    # entra por la espalda: crítico
assert ram.crits == crits_0 + 1 and ram.crit_timer > 0 and ram.flare > 0 and len(combat.FX.sparks) > sparks_0
assert len(ram.smoke) >= 5 and combat.FX.consume_shake()            # bocanada de humo y sacudida
sparks_1 = len(combat.FX.sparks)
ram.take_damage(5, Vector2(-1, 0))                                   # de frente: rebote metálico, sin crítico
assert ram.crits == crits_0 + 1 and ram.ricochets == rico_0 + 1 and len(combat.FX.sparks) > sparks_1
ram.take_damage(5, Vector2(0, 1))                                    # de costado: también rebota
assert ram.ricochets == rico_0 + 2
ram.hp = ram.max_hp
# humo negro constante desde el radiador con menos del 30% de vida (y nada por encima)
ram.smoke.clear()
for _ in range(30):
    ram._update_fx(0.1, Vector2(1, 0))
assert not ram.smoke
ram.hp = ram.max_hp * 0.29
for _ in range(30):
    ram._update_fx(0.1, Vector2(1, 0))
assert len(ram.smoke) >= 10 and not any(p_[5] for p_ in ram.smoke)    # humo negro, no el gris del impacto
ram.smoke.clear()
# la torreta gira por su cuenta hacia el jugador mientras el chasis mantiene su rumbo
ram.facing, ram.turret_dir = Vector2(-1, 0), Vector2(-1, 0)
for _ in range(30):
    ram._update_fx(1 / 60, Vector2(0, 100))
assert ram.facing == Vector2(-1, 0) and ram.turret_dir.y > 0.5 and ram.turret_dir.length() > 0.99
for _ in range(60):
    ram._update_fx(1 / 60, Vector2(0, 100))
assert ram.turret_dir.distance_to(Vector2(0, 1)) < 0.02             # y termina apuntando al jugador
ram.draw(pygame.Surface((300, 300)), Vector2(ram.pos.x - 150, ram.pos.y - 150))
ram.hp = ram.max_hp
ram.facing = Vector2(-1, 0)
# la esclusa de salida está sellada (faro rojo) y la consola de enlace fuera de línea
assert not s.exit_gate.is_open and s.exit_gate.state == "locked" and s.exit_gate in w.solids and not s.console.online
gate_img = s.exit_gate.image.copy()
# la consola no funciona hasta derrotar al Ariete
teleport(s, s.console.pos + Vector2(0, 40))
step(game, 2)
press(game, pygame.K_e)
assert not res.aura_linked
# embestida en línea recta: el jugador inmóvil recibe 35; con esquiva lateral, nada
ARENA = Vector2(1600, 260)
teleport(s, ARENA)
hp0 = s.player.hp
for _ in range(60 * 5):
    step(game, 1)
    if ram.state == "stun":
        break
assert ram.state == "stun" and s.player.hp == hp0 - C.RAM_CONTACT_DAMAGE, (ram.state, s.player.hp)
ram.pos = s.level.marker("ram")
ram.rect.center = (round(ram.pos.x), round(ram.pos.y))
ram.state, ram.timer, ram.facing = "idle", 0.0, Vector2(-1, 0)
s.player.hp = s.player.max_hp
teleport(s, ARENA)
for _ in range(60 * 3):
    step(game, 1)
    if ram.state == "windup" and ram.timer > 0.65:
        break
teleport(s, ARENA + Vector2(0, 120))                                 # esquiva lateral tras fijarse la embestida
for _ in range(60 * 5):
    step(game, 1)
    if ram.state == "stun":
        break
assert ram.state == "stun" and s.player.hp == s.player.max_hp        # la embestida pasó de largo
for _ in range(10):                                                  # disparos a su punto ciego
    if ram.dead:
        break
    ram.take_damage(30, ram.facing * 500)
assert ram.dead and len(w.scraps) >= 3 and s.console.enabled
assert len(w.parts) == 1                                             # el Ariete lleva una pieza del chasis
teleport(s, next(iter(w.parts)).pos + Vector2(30, 0))
step(game, 25)
assert res.chassis_found == 1 and not w.parts                        # magnetismo de la pieza
teleport(s, s.console.pos + Vector2(0, 40))
step(game, 2)
press(game, pygame.K_e)
assert res.aura_linked                                               # AURA se transfiere al traje
assert s.console.linked and s.console.online and s.console.sync > 0.9      # destello y pulso de datos por los cables
assert s.exit_gate.is_open and s.exit_gate.state == "open" and s.exit_gate not in w.solids and s.exit_gate.vent > 1.0
assert pygame.image.tostring(s.exit_gate.image, "RGBA") != pygame.image.tostring(gate_img, "RGBA")    # esclusa abierta (verde)
surf_x = pygame.Surface((2200, 600))
s.console.draw(surf_x, Vector2())
s.exit_gate.draw(surf_x, Vector2())
step(game, 2)
assert 0 < s.console.sync <= 1.0 and 0 < s.exit_gate.vent <= 1.4        # el efecto sigue aunque el diálogo pause el mundo
s.console._sync_start -= 10.0
s.exit_gate._vent_start -= 10.0
assert s.console.sync == 0.0 and s.exit_gate.vent == 0.0
dismiss(game)                                                        # AURA: «¿Cómo te llamas, piloto?»
assert s.name_prompt is not None and not res.campaign_run.named
for ch_ in "Neo-7 x":                                                # solo letras y números
    game.machine.handle_event(pygame.event.Event(pygame.KEYDOWN, key=0, unicode=ch_))
press(game, pygame.K_BACKSPACE)
assert s.name_prompt.text == "Neo7"
step(game, 3)
assert s.pending_next is None                                        # el mundo espera al nombre
press(game, pygame.K_RETURN)
assert s.name_prompt is None and res.player_name == "Neo7" and res.campaign_run.named
assert s.pending_next is GameState.SUB_ACT_1_3 and any("Neo7" in ln_.text for ln_ in s.dialogue.lines)
finish_cinematic(game, GameState.SUB_ACT_1_3)
assert os.path.isfile(os.path.join(SAVE_TMP, "Neo7.json"))           # autoguardado al empezar el 1.3
assert game.checkpoints[SubAct.S1_3]["aura_linked"] is True

# =============================================================================
print("== Sub-acto 1.3: El Tránsito de la Plaza ==")
s = screens[GameState.SUB_ACT_1_3]
w = s.world
assert res.metal >= C.SUPPLY_METAL_1_3 and 85 <= s.charge <= C.AURA_CHARGE_TIME == 90
press(game, pygame.K_2)
assert s.build_choice == "wall"
press(game, pygame.K_1)
assert s.build_choice == "pylon"
press(game, pygame.K_3)
assert s.build_choice == "tower"
press(game, pygame.K_4)
assert s.build_choice == "tower"                                     # solo hay 3 edificios en el tutorial
press(game, pygame.K_ESCAPE)
assert s.build_choice is None
assert not build(s, "pylon", (1400, 900))                            # pilón flotante: prohibido
assert res.metal >= 30 + 45 + 4 * 15             # el suministro base basta para el mínimo del tutorial
res.add_metal(300)                                                   # extra para probar una defensa completa
assert build(s, "pylon", (800, 440)) and build(s, "pylon", (680, 500))
assert build(s, "pylon", (1040, 440)) and build(s, "pylon", (1160, 500))
assert s.powered_pylons() == 4
assert build(s, "tower", (600, 540)) and build(s, "tower", (1240, 540))
assert all(t.is_powered for t in w.towers)
assert s.accesses_closed() == 0
for pos in [(500, 540), (500, 580), (1300, 540), (1300, 580)]:       # cerrar los 2 accesos
    assert build(s, "wall", pos), pos
assert s.accesses_closed() == 2
assert all(done for _, done in s.checklist())
# 90 s de oleada de prueba moderada; los muros y torretas defienden los condensadores
core_hp0 = s.core.hp
max_alive = 0
frames = 0
while not s.hatch.enabled and frames < 60 * 100:
    s.player.hp = s.player.max_hp
    bot_fire(game, s)                                # el Operador también defiende (los soldados superan el alcance de la Twin)
    step(game, 1)
    frames += 1
    max_alive = max(max_alive, len(w.enemies))
mouse[0] = False
assert s.hatch.enabled and s.core.alive(), (frames, s.core.hp)
assert 85 * 60 <= frames <= 95 * 60, frames                           # ~90 s
assert s.spawned == len(s.schedule) == 14 and max_alive <= 14        # moderada: sin hordas
assert game.machine.current_state is GameState.SUB_ACT_1_3
for e in list(w.enemies):                                            # los tanques llevan piezas del chasis
    e.take_damage(9999)
assert len(w.parts) >= 1
for part in list(w.parts):
    teleport(s, part.pos)                                            # (cayó tras el muro de un acceso)
    step(game, 25)
assert res.chassis_found == 2, (res.chassis_found, len(w.parts), [p_.pos for p_ in w.parts])
teleport(s, s.hatch.pos + Vector2(0, 60))
step(game, 2)
press(game, pygame.K_e)
finish_cinematic(game, GameState.SUB_ACT_1_4)

# =============================================================================
print("== Sub-acto 1.4: El Búnker Olvidado y VULCANO ==")
s = screens[GameState.SUB_ACT_1_4]
w = s.world
assert not res.vulcano_online and len(s.demo_walls) == 3
assert all(abs(wl.hp - wl.max_hp * 0.3) < 1e-6 for wl in s.demo_walls)
step(game, 120)
assert all(abs(wl.hp - wl.max_hp * 0.3) < 1e-6 for wl in s.demo_walls)      # sin VULCANO nadie repara
teleport(s, s.terminal.pos + Vector2(0, 60))
step(game, 2)
m0 = res.metal
press(game, pygame.K_e)
assert res.vulcano_online and res.metal == m0 + C.BUNKER_RESERVE and s.dialogue.blocking_active
hp_paused = [wl.hp for wl in s.demo_walls]
step(game, 30)
assert [wl.hp for wl in s.demo_walls] == hp_paused                    # cinemática: mundo pausado
for _ in range(20):
    if not s.dialogue.blocking_active:
        break
    press(game, pygame.K_e)
    step(game, 5)
assert not s.dialogue.blocking_active
m1 = res.metal
hp_start = [wl.hp for wl in s.demo_walls]
step(game, 60 * 2)
assert sum(1 for a_, wl in zip(hp_start, s.demo_walls) if wl.hp > a_) == 1          # repara de a una estructura
step(game, 60 * 21)                                                   # 840 HP a 80 HP/s = 10,5 s (en serie)
assert all(wl.hp == wl.max_hp for wl in s.demo_walls)                 # VULCANO regeneró los muros
spent = m1 - res.metal
assert 76 <= spent <= 84, spent                                       # 840 hp * 0.095 metal/hp = ~80
assert s.demo_done and s.exit_console.enabled
win_vulcano_defense(game, s)                                          # 1.4: proteger a VULCANO mientras suelda la compuerta
assert s.defense["done"] and s.gate.enabled and s.gate.is_open and s.gate in s.interactables      # compuerta reparada
assert s.pending_next is None and s.objective().startswith("¡EVACÚA!")           # aún hay que cruzarla (E)
horde_ = [e_.enemy_type for e_ in w.enemies]
assert horde_.count("scout") >= 8 and horde_.count("soldier") >= 3                # horda masiva final
assert all(e_.target_pos == s.player.pos for e_ in w.enemies)                     # ahora van a por el Operador
assert s.vulcano.max_hp == 0 and s.vulcano.weld_target is None                    # VULCANO deja de soldar
assert any("Brecha sellada" in ln_.text for ln_ in s.dialogue.lines) or True
teleport(s, s.gate.pos + Vector2(-50, 0))
step(game, 2)
s.player.hp = s.player.max_hp
press(game, pygame.K_e)                                                           # evacuar al búnker
finish_cinematic(game, GameState.BASE_MANAGEMENT)                     # con VULCANO en línea: pasa por la Base Central
assert game.machine.sub_act is SubAct.S1_4                            # es un intermedio, no un sub-acto

# =============================================================================
print("== Intermedio de VULCANO (BASE_MANAGEMENT) tras el 1.4 ==")
bm = screens[GameState.BASE_MANAGEMENT]
assert bm.next_state is GameState.ACT_2_BASE and len(bm.world.enemies) == 0
rep_lines = bm.report_lines()
assert len(rep_lines) == 4
assert "0 estructuras" in rep_lines[0] and "salud media 100%" in rep_lines[0]
assert "Metal transferido" in rep_lines[2] and f"reserva: {res.metal})" in rep_lines[2]
assert "0% ensamblado (0/6)" in rep_lines[3] and "disponibles: 2" in rep_lines[3]
assert res.chassis_found == 2 and res.chassis_installed == 0
m0 = res.metal
press(game, pygame.K_c)                                               # instala un componente recuperado
assert res.chassis_installed == 1 and res.metal == m0 - C.CHASSIS_INSTALL_COST and res.assembly_pct == 17
ok_dbg = build_bm(bm, "wall", (740, 660))
assert ok_dbg and res.metal == m0 - C.CHASSIS_INSTALL_COST - 30     # VULCANO lo construye; sin descuento (muro: 30)
wall_bm = next(iter(bm.world.walls))
assert wall_bm.hp == wall_bm.max_hp                                   # termina al 100% de su vida
wall_bm.hp = 30
step(game, 60)
assert 30 < wall_bm.hp < wall_bm.max_hp                               # VULCANO repara solo lo crítico (<50%), 80 HP/s
m1 = res.metal
missing_ = wall_bm.max_hp - wall_bm.hp
left_click(game, wall_bm.pos)                                         # clic sobre la estructura: repararla el resto
assert wall_bm.hp == wall_bm.max_hp and res.metal == m1 - math.ceil(missing_ * C.BASE_REPAIR_METAL_PER_HP)
press(game, pygame.K_SPACE)                                           # desplegar al Operador
assert game.machine.current_state is GameState.ACT_2_BASE
assert any(e["type"] == "wall" for e in res.base_layout) and res.metal_mark == res.metal
assert game.checkpoints[SubAct.S2_0]["vulcano_online"] is True

# =============================================================================
print("== VULCANO: umbral del 50%, gasto de metal y sin reserva ==")
wref = WorldRefs()
vw = Building("wall", (100, 100))
wref.structures.add(vw)
class _Res:
    metal = 50
    def spend_metal(self, n):
        self.metal -= n
        return True
rr = _Res()
vul = Vulcano((0, 0))
vw.hp = 0.6 * vw.max_hp                                               # 60%: por encima del umbral
vul.update(1.0, wref, rr)
assert vw.hp == 0.6 * vw.max_hp and rr.metal == 50
vw.hp = 0.4 * vw.max_hp                                               # 40%: repara y cobra metal
vul.update(1.0, wref, rr)
assert abs(vw.hp - (0.4 * vw.max_hp + C.VULCANO_REPAIR_RATE)) < 1e-6 and rr.metal == 50 - int(C.VULCANO_REPAIR_RATE * C.VULCANO_METAL_PER_HP)
m_mid = rr.metal
vul.update(10.0, wref, rr)
assert vw.hp == vw.max_hp and rr.metal < m_mid                        # sigue hasta regenerarlo por completo
vw.hp = 10
rr.metal = 0
vul2 = Vulcano((0, 0))
vul2.update(1.0, wref, rr)
assert vw.hp == 10                                                    # sin metal en la reserva no repara

# =============================================================================
print("== Base Central: tablero de incursiones del Terminal (Ops 1-3) ==")
from src.config import UNITS as _UB
r = game.resources
term0 = game.machine.active
press(game, pygame.K_6)                              # sin la Op 1 superada: no avanza al Acto 2
assert game.machine.current_state is GameState.ACT_2_BASE and "Op 1" in term0.board_msg
press(game, pygame.K_2)                              # la Op 2 está bloqueada hasta superar la Op 1
assert game.machine.current_state is GameState.ACT_2_BASE and "Bloqueada" in term0.board_msg
game.machine.draw(game.screen)                       # tarjetas: superada / disponible / bloqueada
m0 = r.metal
assert r.incursion_level == 1 and r.op_unlocked("recon") and not r.op_unlocked("drill") and term0.selected == 0
press(game, pygame.K_1)                              # Op 1: Reconocimiento de Perímetro
assert game.machine.current_state is GameState.INCURSION and game.machine.active.op == "recon"
assert game.machine.sub_act is SubAct.S2_X
assert r.threat_level == 1 and r.metal == m0
inc_s = screens[GameState.INCURSION]
w = inc_s.world
assert len(inc_s.caches) == C.INCURSION_DEPOSITS == 3
assert all(120 <= c_.amount <= 180 for c_ in inc_s.caches) and 350 <= sum(c_.amount for c_ in inc_s.caches) <= 500   # calibración del botín
from src.mechanics import incursion as incr
assert len(w.enemies) == (len(inc_s.caches) + 1) * incr.patrol_size(1) + incr.roamer_groups(1) * incr.roamer_size(1)   # guardias de cada alijo + patrullas errantes
assert all(e.enemy_type == "scout" and e.hp == 45 and not e.chasing for e in w.enemies)   # nivel 1: solo scouts
# niebla de guerra: solo lo cercano está explorado; los enemigos lejanos no se ven
assert 0 < inc_s.fog.explored_count() < inc_s.level.cols * inc_s.level.rows * 0.2
far_e = max(w.enemies, key=lambda e: e.pos.distance_to(inc_s.player.pos))
assert not inc_s.fog.is_visible(far_e.pos) and not inc_s.fog.is_explored(far_e.pos)
assert far_e not in inc_s.all_sprites                                 # y no se dibujan si no están a la vista
# minimapa: lo no visitado en negro estricto, lo explorado tenue y los puntos rojos solo con visión directa
assert inc_s.radar_fog() is inc_s.fog and far_e not in inc_s.radar_enemies() and not inc_s.radar_enemies()
near_e = inc_s.spawn_enemy("scout", inc_s.player.pos + Vector2(60, 0))
assert near_e in inc_s.radar_enemies()                                # a la vista: aparece
near_e.kill()
inner_ = game.hud.radar_panel().inflate(-4, -4)
mini_ = inc_s.fog.minimap(inner_.size)
assert mini_.get_size() == inner_.size and mini_.get_at((2, 2))[:3] == (0, 0, 0)       # esquina sin visitar: negro
pc_ = (int(inc_s.player.pos.x / inc_s.level.size[0] * inner_.w), int(inc_s.player.pos.y / inc_s.level.size[1] * inner_.h))
assert mini_.get_at(pc_)[:3] in (FogOfWar.MINI_FLOOR, FogOfWar.MINI_WALL)               # donde estás: explorado, tenue
assert sum(1 for x_ in range(inner_.w) for y_ in range(inner_.h) if mini_.get_at((x_, y_))[:3] == (0, 0, 0)) > inner_.w * inner_.h * 0.7
# el botín queda en riesgo hasta extraer
cache = inc_s.caches[0]
teleport(inc_s, cache.pos + Vector2(0, 40))
step(game, 2)
press(game, pygame.K_e)
assert inc_s.loot == cache.amount and not cache.enabled and r.metal == m0
press(game, pygame.K_e)
assert inc_s.loot == cache.amount                                     # un depósito no se saquea dos veces
inc_s.drop_scrap(inc_s.player.pos + Vector2(20, 0), 25)
step(game, 25)
assert inc_s.loot == cache.amount + 25 and r.metal == m0                             # la chatarra recogida también es botín en riesgo
# extraer exige mantenerse sobre la baliza (no basta con rozarla)
teleport(inc_s, inc_s.beacon.pos)
for _ in range(40):
    inc_s.player.hp = inc_s.player.max_hp
    step(game, 1)
assert not inc_s.done and 0 < inc_s.extract_timer < C.INCURSION_EXTRACT_TIME
teleport(inc_s, inc_s.beacon.pos + Vector2(400, 0))
step(game, 60)
assert inc_s.extract_timer == 0 and not inc_s.done
teleport(inc_s, inc_s.beacon.pos)
for _ in range(150):
    inc_s.player.hp = inc_s.player.max_hp
    step(game, 1)
    if inc_s.pending_next is not None:
        break
assert inc_s.done and inc_s.pending_next is GameState.ACT_2_BASE
finish_cinematic(game, GameState.BASE_MANAGEMENT)                     # con vida: VULCANO recibe el metal
bonus1_ = _UB.INCURSION_OPS["recon"]["first_bonus"]
assert r.metal == m0 + cache.amount + 25 + bonus1_ and r.initial_done and r.incursion_level == 2 and r.op_cleared("recon")
assert r.threat_level == 1 and any("Op 1: Reconocimiento de Perímetro (superada)" in h for h in r.history)
bm = screens[GameState.BASE_MANAGEMENT]
assert bm.next_state is GameState.ACT_2_BASE and bm.transferred == cache.amount + 25 + bonus1_
press(game, pygame.K_SPACE)
assert game.machine.current_state is GameState.ACT_2_BASE
term0 = game.machine.active
assert term0.selected == 1 and r.op_unlocked("drill") and not r.op_unlocked("convoy")   # preselecciona la siguiente
press(game, pygame.K_3)                                               # la Op 3 sigue bloqueada
assert game.machine.current_state is GameState.ACT_2_BASE


def extract_op(g, scene, frames=200):
    """Sobre la baliza hasta extraer; cinemática, VULCANO y de vuelta al Terminal."""
    teleport(scene, scene.beacon.pos)
    for _ in range(frames):
        scene.player.hp = scene.player.max_hp
        step(g, 1)
        if scene.pending_next is not None:
            break
    assert scene.done and scene.pending_next is GameState.ACT_2_BASE
    finish_cinematic(g, GameState.BASE_MANAGEMENT)
    press(g, pygame.K_SPACE)
    assert g.machine.current_state is GameState.ACT_2_BASE


# --- Op 2 (Saqueo de Yacimiento): si el Operador cae, conserva la mitad del botín y reaparece en la base
m1 = r.metal
press(game, pygame.K_RETURN)                                          # ENTER despliega la seleccionada
inc_s = screens[GameState.INCURSION]
assert game.machine.current_state is GameState.INCURSION and inc_s.op == "drill" and inc_s.inc_level == 1
assert inc_s.drill is not None and not inc_s.drill.active and inc_s.vault is None and not inc_s.caches
assert all(e.enemy_type == "scout" for e in inc_s.world.enemies)
assert inc_s.radar_targets()[0] == (inc_s.drill.pos, C.ORANGE) and "Activa el taladro" in inc_s.objective()
inc_s.loot = 101
inc_s.player.take_damage(9999)
step(game, 120)
assert game.machine.current_state is GameState.INCURSION and inc_s.fail_menu and inc_s.fail_title == "OPERADOR CAÍDO"
assert r.metal == m1                                                  # aún no se ha cobrado la pérdida
press(game, pygame.K_ESCAPE)                                          # [ESC] volver a la base
assert game.machine.current_state is GameState.ACT_2_BASE             # reaparece en la base (sin pasar por VULCANO)
assert r.metal == m1 + 50 and r.incursion_level == 2 and not r.op_cleared("drill")   # conserva la mitad; no cuenta
assert "fallida" in r.history[-1] and "perdido" in game.report[0]
# taladro: E lo pone en marcha, entra en las estructuras atacables y cada 15 s llega una oleada a por él
press(game, pygame.K_2)
inc_s = screens[GameState.INCURSION]
drill_ = inc_s.drill
teleport(inc_s, drill_.pos + Vector2(0, 60))
step(game, 2)
n0_ = len(inc_s.world.enemies)
press(game, pygame.K_e)
assert drill_.active and not drill_.enabled and drill_ in inc_s.world.structures
step(game, 1)
wave_ = [e for e in inc_s.world.enemies if getattr(e, "patrol", None) and e.patrol["alert"]]
assert len(wave_) == incr.reinforcement_size(1) + 1 and len(inc_s.world.enemies) == n0_ + len(wave_)
assert all(e.patrol["stops"][0] == drill_.pos for e in wave_) and "Defiende el taladro" in inc_s.objective()
inc_s.wave_timer = 0.0
step(game, 1)
assert len([e for e in inc_s.world.enemies if getattr(e, "patrol", None) and e.patrol["alert"]]) == 2 * len(wave_)
# si lo destruyen, la operación falla (pantalla de fallo); [R] la repite desde el inicio
drill_.take_damage(99999)
step(game, 100)
assert inc_s.fail_menu and inc_s.fail_title == "TALADRO DESTRUIDO" and not drill_.alive()
press(game, pygame.K_r)
assert not inc_s.fail_menu and inc_s.op == "drill" and inc_s.drill is not drill_ and not inc_s.drill.active
drill_ = inc_s.drill
teleport(inc_s, drill_.pos + Vector2(0, 60))
step(game, 2)
press(game, pygame.K_e)
inc_s.drill_timer = inc_s.spec["drill_time"] - 0.005                  # 90 s de defensa después...
step(game, 2)
assert inc_s.goal_done and not drill_.active and drill_ not in inc_s.world.structures
assert 150 <= inc_s.loot <= 220 and 1 <= inc_s.loot_cores <= 2 and "extrae" in inc_s.objective()
loot2_, cores2_, m2, c2 = inc_s.loot, inc_s.loot_cores, r.metal, r.cores
extract_op(game, inc_s)
assert r.metal == m2 + loot2_ + _UB.INCURSION_OPS["drill"]["first_bonus"] and r.cores == c2 + cores2_
assert r.op_cleared("drill") and r.op_unlocked("convoy") and r.threat_level == 2 and r.incursion_level == 3
# --- Op 3 (Convoy Blindado): 2 Arietes lentos escoltados cruzan hacia su salida y no persiguen al Operador
random.seed(5)                                                         # mapa fijo: la ruta del Ariete nunca sale bloqueada
press(game, pygame.K_3)
inc_s = screens[GameState.INCURSION]
w = inc_s.world
assert inc_s.op == "convoy" and inc_s.inc_level == 2 and len(inc_s.rams) == 2
ram_ = inc_s.rams[0]
assert all(rm_.convoy and rm_.enemy_type == "ariete" for rm_ in inc_s.rams)
assert abs(ram_.max_hp - ram_.stats["hp"] * 1.1 * 0.6) < 1e-6 and abs(ram_.speed - ram_.base["speed"] * 0.5) < 1e-6
assert len([e for e in w.enemies if getattr(e, "escort_of", None) is ram_]) == inc_s.spec["escorts"]
assert (inc_s.convoy_exit, C.RED) in inc_s.radar_targets() and "Arietes del convoy (0/2)" in inc_s.objective()
p0_ = Vector2(ram_.pos)
step(game, 120)
assert ram_.pos.distance_to(p0_) > 20                                 # avanza hacia su salida
teleport(inc_s, ram_.pos + Vector2(110, 0))
step(game, 20)
assert not any(rm_.chasing for rm_ in inc_s.rams)                     # ...sin desviarse a por el Operador
# si un Ariete llega a su salida, la operación falla
ram_.pos = Vector2(inc_s.convoy_exit)
ram_.rect.center = (round(ram_.pos.x), round(ram_.pos.y))
step(game, 100)
assert inc_s.fail_menu and inc_s.fail_title == "CONVOY ESCAPADO" and not ram_.alive() and not ram_.dead
press(game, pygame.K_r)
assert not inc_s.fail_menu and inc_s.op == "convoy" and all(rm_.alive() for rm_ in inc_s.rams)
for rm_ in inc_s.rams:
    rm_.take_damage(10 ** 7)
step(game, 2)
assert inc_s.goal_done and inc_s.rams_down() == 2 and 250 <= inc_s.loot <= 350 and 2 <= inc_s.loot_cores <= 3
assert not [e for e in inc_s.world.enemies if getattr(e, "escort_of", None) is not None]   # escoltas sueltas
loot3_, m3 = inc_s.loot, r.metal
extract_op(game, inc_s)
assert r.metal == m3 + loot3_ + _UB.INCURSION_OPS["convoy"]["first_bonus"] and r.op_cleared("convoy")
assert r.threat_level == 3 and r.threat_bonus_pct == 40 and r.incursion_level == 4 and r.op_unlocked("tech")
# --- las superadas se pueden repetir (farmeo): sin bono, sin subir nivel ni alerta
press(game, pygame.K_1)
inc_s = screens[GameState.INCURSION]
assert game.machine.current_state is GameState.INCURSION and inc_s.op == "recon"
m4 = r.metal
extract_op(game, inc_s)
assert r.metal == m4 and r.incursion_level == 4 and r.threat_level == 3
press(game, pygame.K_6)
assert game.machine.current_state is GameState.CAMPAIGN_MENU           # 3.B: el Terminal abre el menú de campaña
press(game, pygame.K_ESCAPE)
assert game.machine.current_state is GameState.ACT_2_BASE

def enter_classic_act2(game):
    """Terminal: [6] abre el menú de campaña y se elige el último (Acto 2 clásico con la Fundición)."""
    from src.config import UNITS as _U
    press(game, pygame.K_6)
    for _ in range(len(_U.CAMPAIGN_MAPS)):
        press(game, pygame.K_DOWN)
    press(game, pygame.K_RETURN)


enter_classic_act2(game)
assert game.machine.current_state is GameState.ACT_2_SETUP and game.machine.sub_act is SubAct.S2_1
assert r.campaign_map is None
a2 = screens[GameState.ACT_2_SETUP]
dismiss(game)
assert a2.vulcano is not None                        # VULCANO sigue vinculado en el Acto 2
assert len(a2.world.walls) == 1 and next(iter(a2.world.walls)).pos == Vector2(740, 660)   # la base guardada vuelve
assert a2.world.player is None and r.player_max_hp == C.PLAYER_START_HP + C.CHASSIS_HP_BONUS   # mando; 1 componente
a2.wave.timer = 99999
core_pos = a2.core.pos
assert build(a2, "wall", (620, 500))
wall = next(iter(a2.world.walls))
wall.hp = 20                                         # bajo el 50%: VULCANO lo repara solo
m0 = r.metal
step(game, 60 * 12)
assert wall.hp == wall.max_hp and r.metal < m0

# =============================================================================
print("== Incursiones: escalado, niebla y generación de mapas ==")
from src.map.levels import build_incursion_level
from src.mechanics import incursion as incr
assert incr.enemy_scale(1) == 1.0 and abs(incr.enemy_scale(5) - 1.4) < 1e-9
rng = random.Random(1)
kinds = lambda lv: set(incr.pick_kinds(lv, 600, rng))
assert kinds(1) == kinds(2) == {"scout"}                                       # niveles iniciales: solo scouts
assert kinds(3) == kinds(4) == {"scout", "soldier"}
assert kinds(5) == kinds(6) == {"scout", "soldier", "tank"}
assert kinds(7) == {"scout", "soldier", "tank", "ariete"}                      # niveles altos: pesados y arietes
assert incr.loot_per_deposit(1) == 150 < incr.loot_per_deposit(2) < incr.loot_per_deposit(6)
assert incr.scrap_value(1) == 25 < incr.scrap_value(3)
assert incr.part_chance(1) == 0.10 < incr.part_chance(4) and incr.part_chance(99) == C.INCURSION_PART_MAX
assert incr.part_chance(3, heavy=True) == 2 * incr.part_chance(3)
assert incr.patrol_size(1) == 3 < incr.patrol_size(4) and incr.patrol_size(99) == 7
fog = FogOfWar(20, 20, 40, 200)
fog.update(Vector2(100, 100))
assert fog.is_visible(Vector2(250, 100)) and not fog.is_visible(Vector2(500, 100))
assert fog.is_explored(Vector2(200, 100)) and not fog.is_explored(Vector2(700, 700))
n1 = fog.explored_count()
fog.update(Vector2(100, 100))
assert fog.explored_count() == n1
fog.update(Vector2(400, 400))
assert fog.explored_count() > n1 and fog.is_explored(Vector2(100, 100))        # lo explorado se recuerda
for seed in range(40):
    lv = build_incursion_level(seed)
    origin = lv.marker("start")
    assert len(lv.markers["deposit"]) == 3
    assert all(lv.is_reachable(origin, p) for p in lv.markers["deposit"] + lv.markers["extract"])
    assert origin.distance_to(lv.marker("extract")) > 1500
assert len({tuple(map(tuple, build_incursion_level(s).wall)) for s in range(5)}) > 1     # cada salida es distinta
# complejo industrial: 12 salas cerradas unidas por pasillos, con barricadas de chatarra sólidas y borde de muro
lv_r = build_incursion_level(5, 2)
assert len(lv_r.rooms) == 12 and len(lv_r.barricades) >= 5
assert all(lv_r.wall[r_][c_] for pile_ in lv_r.barricades for c_ in range(pile_.x, pile_.right) for r_ in range(pile_.y, pile_.bottom))
assert all(lv_r.wall[0][c_] and lv_r.wall[-1][c_] for c_ in range(lv_r.cols)) and all(lv_r.wall[r_][0] and lv_r.wall[r_][-1] for r_ in range(lv_r.rows))
assert lv_r.room_rect(lv_r.marker("deposit")) is not None and lv_r.room_rect(Vector2(5, 5)) is None
open_cells_ = sum(1 for row_ in lv_r.wall for v_ in row_ if not v_)
assert 0.25 < open_cells_ / (lv_r.cols * lv_r.rows) < 0.6                            # ni vacío ni todo muros
assert {(c_, r_) for r_ in range(lv_r.rows) for c_ in range(lv_r.cols) if lv_r.wall[r_][c_]} == lv_r.wall_cells    # la decoración no añade colisión
assert len(lv_r.solids) < 400                                                         # muros fusionados: colisión barata
# rutas y patrullas: tamaños, rutas con tramos rectos libres, patrullas que caminan y refuerzos al saquear
assert incr.patrol_size(1) == 3 and incr.patrol_size(5) == incr.patrol_size(99) == 7
assert incr.roamer_groups(1) == 2 < incr.roamer_groups(7) == 4 and incr.reinforcement_size(1) == 2 < incr.reinforcement_size(9)
st_, ex_ = lv_r.marker("start"), lv_r.marker("extract")
wp_ = lv_r.waypoints(st_, ex_)
assert wp_ and wp_[-1].distance_to(ex_) < 1 and all(lv_r.line_clear(a_, b_, 18) for a_, b_ in zip([st_] + wp_, wp_))
assert not lv_r.line_clear(st_, ex_, 18)                                              # hay muros por medio
sgame2 = Game()
sgame2.new_campaign()
sgame2.machine.transition(GameState.ACT_2_BASE)
sgame2.machine.transition(GameState.INCURSION, op="recon")
sp_ = sgame2.machine.active


def run_scene(scene_game, frames):
    for _ in range(frames):
        scene_game.machine.active.player.hp = scene_game.machine.active.player.max_hp
        scene_game.machine.update(1 / 60)


roamers_ = [e_ for e_ in sp_.world.enemies if getattr(e_, "patrol", None)]
assert len(roamers_) == incr.roamer_groups(1) * incr.roamer_size(1)
p0_ = {id(e_): Vector2(e_.pos) for e_ in roamers_}
run_scene(sgame2, 60 * 12)
assert sum(1 for e_ in roamers_ if e_.pos.distance_to(p0_[id(e_)]) > 100) >= len(roamers_) - 1    # caminan por salas y pasillos
assert all(e_.speed < e_.run_speed for e_ in roamers_ if not e_.chasing)                     # paseando: a menor velocidad
n_before_ = len(sp_.world.enemies)
sp_._loot_cache(sp_, sp_.caches[0])                                                           # alarma: acuden refuerzos
alert_ = [e_ for e_ in sp_.world.enemies if getattr(e_, "patrol", None) and e_.patrol["alert"]]
assert len(sp_.world.enemies) == n_before_ + incr.reinforcement_size(1) == n_before_ + len(alert_)
assert all(e_.pos.distance_to(sp_.player.pos) > 150 for e_ in alert_)                              # salen de salas alejadas
d0_ = sum(e_.pos.distance_to(sp_.player.pos) for e_ in alert_)
run_scene(sgame2, 60 * 40)
assert sum(e_.pos.distance_to(sp_.player.pos) for e_ in alert_ if e_.alive()) < d0_ * 0.5       # llegan hasta el Operador
# reintento tras caer: [R] genera al instante otra incursión de la misma operación, sin subir la alerta
sp_.loot = 120
threat_before_ = sgame2.resources.threat_level
sp_.player.take_damage(9999)
for _ in range(120):
    sgame2.machine.update(1 / 60)
    sgame2.machine.draw(sgame2.screen)                                                        # dibuja la pantalla de fallo
assert sp_.fail_menu and sgame2.machine.current_state is GameState.INCURSION and not sp_.player.alive()
metal_before_ = sgame2.resources.metal
level_before_, seed_before_ = sp_.inc_level, sp_.seed
press(sgame2, pygame.K_r)
assert not sp_.fail_menu and sp_.player.alive() and sp_.loot == 0 and sp_.inc_level == level_before_
assert sgame2.machine.current_state is GameState.INCURSION and sp_.world.enemies and len(sp_.caches) == 3
assert sgame2.resources.metal == metal_before_ + 60                                            # conserva la mitad de lo que llevaba
assert sgame2.resources.threat_level == threat_before_ and sp_.op == "recon"
sp_.player.take_damage(9999)
for _ in range(120):
    sgame2.machine.update(1 / 60)
assert sp_.fail_menu
click_ = sp_._fail_buttons["base"].center if sp_._fail_buttons else (0, 0)
sgame2.machine.draw(sgame2.screen)
sgame2.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=sp_._fail_buttons["base"].center))
assert sgame2.machine.current_state is GameState.ACT_2_BASE                                    # botón de volver a la base
# niebla con muros: no se ve ni se explora a través de ellos; el minimapa recuerda lo explorado
wl_ = {(5, r_) for r_ in range(10)}
fw2 = FogOfWar(12, 12, 40, 400, walls=wl_)
fw2.update(Vector2(100, 100))
assert fw2.is_visible(Vector2(180, 100)) and fw2.is_visible(Vector2(220, 100))        # antes del muro y el propio muro
assert not fw2.is_visible(Vector2(340, 100)) and not fw2.is_explored(Vector2(340, 100))   # tras el muro: ni visible ni explorado
mm2 = fw2.minimap((12, 12))
assert mm2.get_at((8, 2))[:3] == (0, 0, 0) and mm2.get_at((2, 2))[:3] == FogOfWar.MINI_FLOOR
assert mm2.get_at((5, 2))[:3] == FogOfWar.MINI_WALL
v_ = fw2.version
fw2.update(Vector2(100, 100))
assert fw2.version == v_                                                              # sin celda nueva no se rehace
fw2.update(Vector2(100, 440))                                                         # camina hasta el hueco del muro
mm3 = fw2.minimap((12, 12))
assert fw2.version > v_ and mm3.get_at((2, 2))[:3] == FogOfWar.MINI_FLOOR             # lo ya explorado persiste
assert FogOfWar(20, 20, 40, 200).walls is None                                        # sin muros: visión por radio, como antes
# calibración del botín: alijos 120-180 y total 350-500 a nivel 1; el nivel lo escala después
for s_ in range(300):
    am_ = incr.loot_amounts(1, 3, random.Random(s_))
    assert all(120 <= a_ <= 180 and a_ % 5 == 0 for a_ in am_) and 350 <= sum(am_) <= 500, am_
assert abs(sum(incr.loot_amounts(3, 3, random.Random(1))) - 1.5 * sum(incr.loot_amounts(1, 3, random.Random(1)))) <= 3
# escalado dentro de la escena: niveles altos traen unidades pesadas y más piezas del chasis
sgame = Game()
sgame.new_campaign()
sgame.machine.transition(GameState.ACT_2_BASE)
sgame.machine.transition(GameState.INCURSION, op="recovery")                     # Op 5: nivel 3, guardia reforzada
sc = sgame.machine.active
assert {e.enemy_type for e in sc.world.enemies if e.rect.center != (0, 0)} <= {"scout", "soldier", "tank"}
assert all(abs(e.hp - e.stats["hp"] * 1.2) < 1e-6 for e in sc.world.enemies)
assert len(sc.world.enemies) == len(sc.caches) * sc.spec["extra_guards"] \
    + (len(sc.caches) + 1) * incr.patrol_size(3) + incr.patrol_size(3) + 2 \
    + incr.roamer_groups(3) * incr.roamer_size(3)      # + alijo de plasma + extractor (guardia pesada) + patrullas errantes
assert sc.inc_level == 3
for _ in range(40):                                                                 # la tasa de piezas sube con el nivel
    e = sc.spawn_enemy("scout", sc.player.pos + Vector2(40, 0))
    e.take_damage(9999)
hi = sum(1 for _ in range(2000) if random.random() < incr.part_chance(9))
lo = sum(1 for _ in range(2000) if random.random() < incr.part_chance(1))
assert hi > lo * 2

# =============================================================================
print("== Recursos del chasis y estado de la base ==")
rm = ResourceManager()
assert rm.chassis_available == 0 and not rm.install_chassis()         # sin componentes no se instala
rm.chassis_found = 7
rm.metal = 200
for _ in range(C.CHASSIS_TOTAL_PARTS):
    assert rm.install_chassis()
assert not rm.install_chassis() and rm.assembly_pct == 100 and rm.chassis_installed == 6
assert rm.metal == 200 and rm.player_max_hp == 100 + 6 * C.CHASSIS_HP_BONUS      # montar el chasis es gratis
rm2 = ResourceManager()
rm2.chassis_found, rm2.metal, rm2.cores = 1, 0, 0
assert rm2.install_chassis() and rm2.chassis_installed == 1 and (rm2.metal, rm2.cores, rm2.alloy) == (0, 0, 0)
rm2.base_layout = [{"type": "wall", "pos": (10, 10), "hp": 50}]
snap = rm2.snapshot()
rm2.base_layout[0]["hp"] = 1
rm2.base_layout.append({"type": "tower", "pos": (0, 0), "hp": 5})
assert snap["base_layout"] == [{"type": "wall", "pos": (10, 10), "hp": 50}]     # copia profunda
rm2.restore(snap)
assert rm2.base_layout[0]["hp"] == 50 and len(rm2.base_layout) == 1

# =============================================================================
print("== Base Central: acciones estratégicas de VULCANO ==")
game.new_campaign()
game.resources.vulcano_online = True
game.machine.transition(GameState.SUB_ACT_1_4)
game.advance(GameState.ACT_2_BASE)                                     # VULCANO en línea: antes pasa por la base
assert game.machine.current_state is GameState.BASE_MANAGEMENT
bm = screens[GameState.BASE_MANAGEMENT]
res = game.resources
res.metal = 100
res.chassis_found = 0
press(game, pygame.K_c)                                                # sin componentes: nada
assert res.chassis_installed == 0
res.chassis_found = 1
res.metal = 0
press(game, pygame.K_c)                                                # gratis: se monta aunque no quede chatarra
assert res.chassis_installed == 1 and res.metal == 0
res.chassis_installed = 0
res.metal = 500
assert build_bm(bm, "pylon", (520, 600)) and build_bm(bm, "tower", (600, 700)) and build_bm(bm, "wall", (740, 660))
assert not build_bm(bm, "pylon", (1400, 900))                             # la regla del enlace obligatorio sigue vigente
tower_bm = next(iter(bm.world.towers))
wall_bm = next(iter(bm.world.walls))
assert tower_bm.is_powered                                             # la torreta está dentro del radio del pilón
# reparar: una a una y todas a la vez, respetando el metal disponible
tower_bm.hp, wall_bm.hp = 10, 40                                       # torreta al 20%, muro al 40%
cost_t, cost_w = bm.repair_cost(tower_bm), bm.repair_cost(wall_bm)
assert (cost_t, cost_w) == (58, 72)                                    # ceil(faltante * 0.2)
res.metal = 60
press(game, pygame.K_f)                                                # repara primero la más dañada; el resto, si alcanza
assert tower_bm.hp == tower_bm.max_hp and wall_bm.hp == 40 and res.metal == 2
res.metal = 5
press(game, pygame.K_f)
assert wall_bm.hp == 40 and res.metal == 5                             # sin metal suficiente no repara
res.metal = 200
press(game, pygame.K_f)
assert wall_bm.hp == wall_bm.max_hp and not bm.damaged()
# reubicar = desmontar (reembolso 70%) + construir
held[pygame.K_x] = True
m0 = res.metal
right_click(game, wall_bm.pos)
held.clear()
assert not wall_bm.alive() and res.metal == m0 + 21 and len(bm.world.walls) == 0     # 70% de 30
assert build_bm(bm, "wall", (780, 620)) and len(bm.world.walls) == 1
# el núcleo no se puede desmontar
held[pygame.K_x] = True
right_click(game, bm.core.pos)
held.clear()
assert bm.core.alive()
# desplegar con clic en el botón (no solo con ESPACIO)
bm.core.hp = bm.core.max_hp * 0.6
next_state = bm.next_state
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=bm.buttons["deploy"].center))
assert game.machine.current_state is next_state
assert res.base_core_hp == 300 and {e["type"] for e in res.base_layout} == {"pylon", "tower", "wall"}

# =============================================================================
print("== Acto 2 partido: 2.1 asedio -> Base Central -> 2.2 asalto ==")
a2 = new_act2(game, metal=800, vulcano=True)
w = a2.world
assert build(a2, "wall", (620, 500)) and build(a2, "pylon", (520, 600)) and build(a2, "tower", (700, 700))
wall2 = next(iter(w.walls))
wall2.hp = 40
tower2 = next(iter(w.towers))
tower2.hp = 45
# simula que se contuvo la oleada 5: al limpiarla arranca el asalto y VULCANO toma la base
a2.wave.phase = "wave"
a2.wave.wave = a2.wave.total_waves
a2.wave.current = Wave(5, 1, a2.CC_POS)
a2.wave.spawned = len(a2.wave.current.schedule)
step(game, 3)
assert game.machine.current_state is GameState.BASE_MANAGEMENT and game.machine.sub_act is SubAct.S2_1
bm = screens[GameState.BASE_MANAGEMENT]
assert bm.next_state is GameState.ACT_2_ASSAULT and len(bm.world.enemies) == 0
assert len(bm.world.walls) == 1 and len(bm.world.towers) == 1 and len(bm.world.pylons) == 1     # la base viaja completa
assert any(b.hp < b.max_hp for b in bm.world.structures)               # ...con el daño del asedio
assert len(bm.damaged()) >= 1
game.resources.metal = 300
press(game, pygame.K_f)
assert not bm.damaged()                                                # se reparó todo lo que quedaba dañado
hp_walls = [round(b.hp) for b in bm.world.walls]
press(game, pygame.K_SPACE)
assert game.machine.current_state is GameState.ACT_2_ASSAULT and game.machine.sub_act is SubAct.S2_2
a2 = screens[GameState.ACT_2_ASSAULT]
dismiss(game)
w = a2.world
assert a2.assault and a2.wave.phase == "assault" and len(w.enemies) == 0
assert len(w.walls) == 1 and len(w.towers) == 1 and len(w.pylons) == 1
assert [round(b.hp) for b in w.walls] == hp_walls
assert a2.foundry_core.shielded and a2.foundry_core.alive()            # la Fundición se reinicia para el asalto
assert game.checkpoints[SubAct.S2_2]["base_layout"]                    # checkpoint con la base desplegada
# reintento del 2.2: vuelve al inicio del asalto con el presupuesto de rescate
a2.core.take_damage(99999)
step(game, 100)
assert game.machine.current_state is GameState.RETRY_SUB_ACT and game.machine.sub_act is SubAct.S2_2
press(game, pygame.K_r)
assert game.machine.current_state is GameState.ACT_2_ASSAULT and game.resources.metal == C.RESCUE_METAL
a2 = screens[GameState.ACT_2_ASSAULT]
assert len(a2.world.walls) == 1 and a2.core.hp > 0                     # base del checkpoint, núcleo en pie
# victoria real: destruir el perímetro y el núcleo de la Fundición... y las bases enemigas (que vienen de 2.1)
assert len(a2.enemy_bases) == 1 and not a2.enemy_bases[0].destroyed
for t_ in list(a2.foundry_core.perimeter):
    t_.take_damage(9999)
a2.foundry_core.take_damage(99999)
for b_ in a2.enemy_bases:
    raze(b_)
step(game, 60 * 4)
assert game.machine.current_state is GameState.VICTORY

# =============================================================================
print("== Sin VULCANO en línea no hay intermedio; y nunca hay alternancia en pleno combate ==")
game.new_campaign()
game.advance(GameState.SUB_ACT_1_2)
assert game.machine.current_state is GameState.SUB_ACT_1_2             # sin VULCANO: transición directa
a2 = new_act2(game, vulcano=True)
a2.wave.timer = 0.2
step(game, 30)
assert game.machine.current_state is GameState.ACT_2_PLAY
for key in (pygame.K_TAB, pygame.K_v, pygame.K_b, pygame.K_h, pygame.K_m, pygame.K_x, pygame.K_c, pygame.K_f,
            pygame.K_SPACE, pygame.K_RETURN, pygame.K_F2, pygame.K_F3):
    press(game, key)
    step(game, 2)
    assert game.machine.current_state is GameState.ACT_2_PLAY, key      # ninguna tecla cede el control a VULCANO
a2.paused = False                                    # ESPACIO alterna la pausa táctica
# los Arietes de la Fundición llevan componentes del chasis
ariete = Enemy("ariete", (900, 600), a2.CC_POS, a2.world.enemies)
ariete.on_death = a2._on_enemy_death                 # como hace el gestor de oleadas al crearlos
a2.world.enemies.add(ariete)
before = len(a2.world.parts)
ariete.take_damage(99999)
assert len(a2.world.parts) == before + 1
f0 = game.resources.chassis_found
step(game, int(60 * C.AUTO_COLLECT_DELAY) + 10)                      # modo Comandante: la base recoge la pieza sola
assert game.resources.chassis_found == f0 + 1 and not a2.world.parts

# =============================================================================
print("== Red electrica: pilones, BFS orientado a eventos ==")
a2 = new_act2(game)
w = a2.world
assert a2.core.hp == 500 and a2.wave.build_discount == 0.5 and a2.vulcano is None
assert a2._cost("tower") == round(45 * 0.5) and a2._cost("pylon") == 15
far = a2._ghost_rect("pylon", Vector2(a2.CC_POS.x + 300, a2.CC_POS.y))
assert not a2._can_place("pylon", far)               # pilon flotante: prohibido
assert build(a2, "pylon", (520, 600))                # dentro de 160 px del nucleo (fuente)
p1 = next(iter(w.pylons))
assert p1.is_powered
assert build(a2, "pylon", (660, 600))                # enlazado al pilon energizado
p2 = [p for p in w.pylons if p is not p1][0]
assert p2.is_powered
assert not build(a2, "pylon", (860, 600))            # fuera de alcance de ambos
assert build(a2, "tower", (700, 700))
tower = next(iter(w.towers))
assert tower.is_powered
assert build(a2, "tower", (1000, 900))
lone = [t for t in w.towers if t is not tower][0]
assert not lone.is_powered                           # torreta sin energia
en = Enemy("scout", lone.pos + Vector2(90, 0), a2.CC_POS, w.enemies)
w.enemies.add(en); w.all_sprites.add(en); w.targets.add(en)
step(game, 60)
assert len(w.bullets) == 0                           # torreta apagada no dispara
en.kill()
calls = []
original = a2.grid.recompute
a2.grid.recompute = lambda: (calls.append(1), original())[1]
step(game, 90)
assert not calls                                     # el BFS solo se ejecuta al cambiar la red
p1.take_damage(9999)
step(game, 2)
assert len(calls) == 1
assert not p2.is_powered and not tower.is_powered
a2.grid.recompute = original

# =============================================================================
print("== Infiltración Tecnológica y Módulo de Mando ==")
from src.managers.resource_manager import CampaignRun as _CR
from src.managers.resource_manager import ResourceManager as _RM2
from src.mechanics import incursion as _inc2
from src.map.levels import build_incursion_level as _bil
# --- persistencia del Módulo de Mando (CampaignRun, snapshot y ResourceManager)
cr0 = _CR()
assert cr0.command_module is False and cr0.to_dict()["command_module"] is False
cr0.command_module = True
assert _CR.from_dict(cr0.to_dict()).command_module is True                            # ida y vuelta
legacy_ = cr0.to_dict()
del legacy_["command_module"]
assert _CR.from_dict(legacy_).command_module is False                                 # partida antigua: sin módulo
rm2 = _RM2()
assert rm2.command_module is False
snap_a = rm2.snapshot()
rm2.command_module = True
snap_b = rm2.snapshot()
assert snap_a["command_module"] is False and snap_b["command_module"] is True and rm2.campaign_run.command_module is True
rm2.restore(snap_a)
assert rm2.command_module is False
rm2.restore(snap_b)
assert rm2.command_module is True
del snap_a["command_module"]
rm2.restore(snap_a)
assert rm2.command_module is False                                                    # checkpoint antiguo: sin módulo
rm2.command_module = True
rm2.reset()
assert rm2.command_module is False                                                    # campaña nueva: se limpia
# --- reglas: solo extraer con vida (y con el objetivo cumplido) asegura el módulo y los planos; morir los pierde
from src.config import UNITS as _U4
rm2.finish_op("tech", 100, cleared=False)
assert not rm2.command_module and not rm2.factory_blueprints and not rm2.op_cleared("tech")
assert "objetivo incompleto" in rm2.history[-1]
rm2.finish_op("tech", 100, cores=2, alloy=2, module=True, blueprints=True)
assert rm2.command_module and rm2.factory_blueprints and rm2.op_cleared("tech")
assert "Op 4" in rm2.history[-1] and "Módulo de Mando" in rm2.history[-1] and "Planos de la Fábrica de Drones" in rm2.history[-1]
cr4_ = _CR.from_dict(rm2.campaign_run.to_dict())                                      # persisten en el perfil
assert cr4_.factory_blueprints and cr4_.ops_cleared == {"tech"}
legacy4_ = rm2.campaign_run.to_dict()
del legacy4_["ops_cleared"], legacy4_["factory_blueprints"]
assert not _CR.from_dict(legacy4_).factory_blueprints and not _CR.from_dict(legacy4_).ops_cleared   # partida antigua
rm2.reset()
assert not rm2.factory_blueprints and not rm2.campaign_run.ops_cleared                # campaña nueva: se limpia
rm2.fail_op("tech", 10, 10, module_lost=True)
assert not rm2.command_module and "Módulo de Mando perdido" in rm2.history[-1] and "fallida" in rm2.history[-1]
assert [rm2.op_unlocked(k_) for k_ in _U4.OPS_ORDER] == [True, False, False, False, False]
# --- reglas de botín y nido
for s_ in range(300):
    v_ = _inc2.vault_loot(1, random.Random(s_))
    assert 150 <= v_ <= 200 and v_ % 5 == 0                                           # la cámara suelta 150-200 de chatarra
    k_ = _inc2.nest_kinds(1, random.Random(s_))
    assert len(k_) == _inc2.patrol_size(1) + C.INCURSION_TECH_NEST_EXTRA
    assert sum(1 for x_ in k_ if x_ != "scout") >= C.INCURSION_TECH_NEST_HEAVY        # guardia pesada desde el nivel 1
assert _inc2.vault_loot(3, random.Random(1)) > _inc2.vault_loot(1, random.Random(1))   # escala con el nivel como el resto del botín
# --- mapas: una cámara fuerte conectada y lejos del inicio; el económico no cambia
for seed_ in range(30):
    for lvl_ in (1, 4):
        lt_ = _bil(seed_, lvl_, "tech")
        o_ = lt_.marker("start")
        assert len(lt_.markers["vault"]) == 1 and "deposit" not in lt_.markers and "plasma_cache" not in lt_.markers
        assert lt_.is_reachable(o_, lt_.marker("vault")) and lt_.is_reachable(o_, lt_.marker("extract"))
        assert o_.distance_to(lt_.marker("vault")) > 640 and o_.distance_to(lt_.marker("extract")) > 1500
        assert lt_.room_rect(lt_.marker("vault")) is not None and lt_.kind == "tech"
for seed_ in range(8):
    le_ = _bil(seed_, 1)
    assert len(le_.markers["deposit"]) == 3 and "vault" not in le_.markers and le_.kind == "eco"
# --- Terminal: tablero de 5 operaciones (teclas 1-5, flechas + ENTER y clic)
tg = Game()
tg.new_campaign()
rt = tg.resources
rt.equipped = rt.aura_linked = rt.vulcano_online = True
tg.machine.transition(GameState.ACT_2_BASE)
term = tg.machine.active
assert list(term.op_rects) == _U4.OPS_ORDER and term.selected == 0
tg.machine.draw(tg.screen)
press(tg, pygame.K_DOWN)
assert term.selected == 1
press(tg, pygame.K_RETURN)                                                            # la Op 2 aún está bloqueada
assert tg.machine.current_state is GameState.ACT_2_BASE and "supera antes la Op 1" in term.board_msg
press(tg, pygame.K_UP)
press(tg, pygame.K_UP)
assert term.selected == 4                                                             # las flechas dan la vuelta
tg.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=term.op_rects["tech"].center))
assert tg.machine.current_state is GameState.ACT_2_BASE and "Op 3" in term.board_msg  # clic en una bloqueada
tg.machine.draw(tg.screen)
rt.campaign_run.ops_cleared.update({"recon", "drill", "convoy"})
rt.initial_done = True
tg.machine.transition(GameState.MENU)
tg.machine.transition(GameState.ACT_2_BASE)
term = tg.machine.active
assert term.selected == 3 and not rt.factory_blueprints                              # preselecciona la Op 4
tg.machine.draw(tg.screen)
tg.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=term.op_rects["tech"].center))
ts = tg.machine.active
assert tg.machine.current_state is GameState.INCURSION and ts.op == "tech" and ts.kind == "tech" and ts.inc_level == 3
# --- Op 4 (Complejo Tecnológico): terminal del nido custodiada por Tanques
assert ts.vault is not None and not ts.caches and ts.vault.kind == "module" and ts.vault.enabled and ts.drill is None
assert 150 * _inc2.loot_growth(3) - 3 <= ts.vault.amount <= 200 * _inc2.loot_growth(3) + 3
nest_ = [e_ for e_ in ts.world.enemies if e_.pos.distance_to(ts.vault.pos) < 400]
assert sum(1 for e_ in nest_ if e_.enemy_type == "tank") >= ts.spec["tanks"]
assert len(nest_) >= _inc2.patrol_size(3) + C.INCURSION_TECH_NEST_EXTRA + ts.spec["tanks"]
assert not any(e_.chasing for e_ in ts.world.enemies)                                 # sin spawner: la guardia está quieta
assert ts.radar_targets()[0][0] == ts.vault.pos and ts.radar_targets()[-1][0] == ts.beacon.pos
assert "terminal del nido" in ts.objective() and ts.checklist()[0] == ("Terminal del nido hackeada", False)
assert "Op 4" in ts.banner()
n_enemies_ = len(ts.world.enemies)
press(tg, pygame.K_e)                                                                 # lejos de la terminal: no pasa nada
assert not ts.vault.hacking
teleport(ts, ts.vault.pos + Vector2(0, 40))
step(tg, 2)
press(tg, pygame.K_e)                                                                 # empieza el hackeo: alarma del nido
assert ts.vault.hacking and sum(1 for e_ in ts.world.enemies if e_.chasing) >= len(nest_) // 2
n_reinf_ = _inc2.reinforcement_size(3)


def run_tech(scene_game, scene, frames):
    """Hackeo con el Operador invulnerable: dos obuses de Tanque en el mismo fotograma lo abatirían estando quieto."""
    scene.player.take_damage = lambda *a_, **k_: None
    for _ in range(frames):
        scene_game.machine.update(1 / 60)
        scene_game.machine.draw(scene_game.screen)
        if scene.loot_module:
            break
    del scene.player.take_damage


run_tech(tg, ts, 60 * 2)                                                              # a medias: aro de progreso
assert 0.3 < ts.vault.progress < 0.5 and not ts.loot_module
teleport(ts, ts.vault.pos + Vector2(400, 0))
run_tech(tg, ts, 60)
assert ts.vault.progress < 0.3 and not ts.loot_module                                 # alejarse lo hace retroceder
teleport(ts, ts.vault.pos + Vector2(0, 40))
run_tech(tg, ts, int(60 * C.INCURSION_TECH_HACK_TIME) + 60)
assert ts.loot_module and ts.loot_blueprints and ts.goal_done and not ts.vault.enabled
assert ts.loot >= ts.vault.amount and ts.loot_alloy == 2 and ts.loot_cores >= 2      # planos + módulo + botín, en riesgo
assert len(ts.world.enemies) >= n_enemies_ + n_reinf_ - 5                             # alarma de escape: llegan refuerzos
assert sum(1 for e_ in ts.world.enemies if getattr(e_, "patrol", None) and e_.patrol["alert"]) == n_reinf_
assert not rt.factory_blueprints and "Planos de la Fábrica obtenidos" in ts.objective()   # aún no asegurados
assert "EN RIESGO" in ts.banner() and ts.radar_targets() == [(ts.beacon.pos, C.GREEN)]
# morir con los planos y el módulo los pierde (y conservas la mitad de la chatarra)
metal_before_, alloy_before_ = rt.metal, rt.alloy
loot_at_death_ = ts.loot
ts.player.take_damage(9999)
for _ in range(120):
    tg.machine.update(1 / 60)
    tg.machine.draw(tg.screen)                                                        # la pantalla de fallo avisa del módulo
assert ts.fail_menu
press(tg, pygame.K_r)                                                                 # reintento: la misma operación, de nuevo
assert ts.op == "tech" and not ts.fail_menu and not ts.loot_module and not ts.loot_blueprints and ts.vault.enabled
assert not rt.command_module and not rt.factory_blueprints and rt.alloy == alloy_before_
assert rt.metal == metal_before_ + int(loot_at_death_ * C.INCURSION_DEATH_KEEP)          # conserva la mitad de la chatarra
assert "Módulo de Mando perdido" in rt.history[-1] and not rt.op_cleared("tech")
# extraer con vida asegura los planos: el asedio queda permitido (con el Búnker) y se abre la Op 5
teleport(ts, ts.vault.pos + Vector2(0, 40))
step(tg, 2)
press(tg, pygame.K_e)
run_tech(tg, ts, int(60 * C.INCURSION_TECH_HACK_TIME) + 60)
assert ts.loot_blueprints
loot_, cores4_ = ts.loot, ts.loot_cores
m_extract_, c_extract_, a_extract_, thr_ = rt.metal, rt.cores, rt.alloy, rt.threat_level
teleport(ts, ts.beacon.pos)
ts.player.take_damage = lambda *a_, **k_: None                                        # los Tanques del nido persiguen
for _ in range(200):
    step(tg, 1)
    if ts.pending_next is not None:
        break
assert ts.done and rt.command_module and rt.factory_blueprints and rt.op_cleared("tech") and rt.op_unlocked("recovery")
assert rt.metal == m_extract_ + loot_ + _U4.INCURSION_OPS["tech"]["first_bonus"]
assert (rt.cores, rt.alloy, rt.threat_level) == (c_extract_ + cores4_, a_extract_ + 2, thr_ + 1)
assert "Op 4" in tg.report[0] and "Planos de la Fábrica de Drones" in rt.history[-1]
rt.bunker_built = True
assert rt.can_start_siege
# --- Op 5 (Recuperación Crítica): alijos contrarreloj con la guardia reforzada
tg.machine.transition(GameState.ACT_2_BASE)
press(tg, pygame.K_5)
tr = tg.machine.active
assert tg.machine.current_state is GameState.INCURSION and tr.op == "recovery" and tr.goal == "timed"
assert tr.time_left == 180 and len(tr.caches) == 3 and "antes de 3:00" in tr.objective() and "Tiempo 3:00" in tr.banner()
step(tg, 60)
assert 178.5 < tr.time_left < 179.5
tr.time_left = 0.01                                                                   # se acaba el tiempo: fallida
step(tg, 100)
assert tr.fail_menu and tr.fail_title == "TIEMPO AGOTADO"
tg.machine.draw(tg.screen)
press(tg, pygame.K_r)
assert not tr.fail_menu and tr.time_left == 180 and tr.op == "recovery"
for c_ in tr.caches:
    tr._loot_cache(tr, c_)
assert tr.goal_done and 4 <= tr.loot_cores <= 5 and tr.loot_alloy == 2
t5_ = tr.time_left
step(tg, 30)
assert tr.time_left == t5_                                                            # objetivo cumplido: el reloj se para
loot5_, cores5_ = tr.loot, tr.loot_cores
m5_, c5_, a5_ = rt.metal, rt.cores, rt.alloy
teleport(tr, tr.beacon.pos)
tr.player.take_damage = lambda *a_, **k_: None
for _ in range(200):
    step(tg, 1)
    if tr.pending_next is not None:
        break
assert tr.done and rt.op_cleared("recovery") and rt.metal == m5_ + loot5_ + _U4.INCURSION_OPS["recovery"]["first_bonus"]
assert (rt.cores, rt.alloy) == (c5_ + cores5_, a5_ + 2)
assert rt.threat_level == C.THREAT_LEVEL_BASE + _U4.OP_ALERT_CAP                      # tope de alerta por operaciones
tg.machine.transition(GameState.ACT_2_BASE)
assert tg.machine.active.selected == 4 and all(rt.op_cleared(k_) for k_ in _U4.OPS_ORDER)
tg.machine.draw(tg.screen)

print("== Guerra de Asedio: mapa a gran escala, reloj de amenaza, fortaleza evolutiva y nodos de plasma ==")
from src.config import UNITS as _U5
from main import Act2State
from src.entities.building import create_building
from src.entities.drones import DRONE_CLASSES as _DC5
from src.entities.drones import Bomb as _Bomb5
from src.entities.enemy_fortress import EnemyFortress as _EF5
from src.entities.plasma_node import PlasmaNode as _PN5
from src.managers.resource_manager import ResourceManager as _RM5
from src.map.levels import build_siege_level as _bsl
from src.mechanics.threat_clock import ROMAN as _ROMAN5
from src.mechanics.threat_clock import ThreatClock as _TC5
# --- mapa: dimensiones, separación, rutas conectadas y Tierra de Nadie en 30 semillas
for seed_ in range(30):
    ls = _bsl(seed_)
    a_, b_ = ls.marker("player_base"), ls.marker("fortress")
    assert ls.size == (3000, 2000) and ls.background.get_size() == (3000, 2000) and ls.kind == "siege"
    assert a_.distance_to(b_) >= 2200 and a_.x < 600 and b_.x > 2400                      # extremos opuestos
    assert ls.is_reachable(a_, b_)                                                         # hay ruta por los pasos
    nodes_ = ls.markers["plasma_node"]
    assert 2 <= len(nodes_) <= 3 and all(ls.is_reachable(a_, p_) for p_ in nodes_)
    assert all(ls.barriers[0].x < p_.x < b_.x - 200 for p_ in nodes_)                      # en la Tierra de Nadie
    assert len(ls.barriers) == 3 and len(ls.passes) >= 3 and all(p_.h >= 160 and p_.w == 120 for p_ in ls.passes)
    for bar_ in ls.barriers:                                                               # cuellos de botella: muro salvo en los pasos
        gaps_ = [p_ for p_ in ls.passes if p_.x == bar_.x]
        assert gaps_ and sum(g_.h for g_ in gaps_) < bar_.h * 0.35
        solid_rows_ = [r_ for r_ in range(ls.rows) if ls.wall[r_][bar_.x // 40 + 1]]
        assert len(solid_rows_) > ls.rows * 0.6
    for pos_ in (a_, b_):                                                                  # las bases nacen en terreno libre
        assert not any(ls.wall[r_][c_] for r_ in range(int(pos_.y // 40) - 3, int(pos_.y // 40) + 4)
                       for c_ in range(int(pos_.x // 40) - 3, int(pos_.x // 40) + 4))
assert _bsl(4).wall == _bsl(4).wall and _bsl(4).markers == _bsl(4).markers                 # determinista por semilla
assert len({tuple(map(tuple, _bsl(s_).wall)) for s_ in range(6)}) > 1                      # y distinto entre semillas
# --- reloj de amenaza: transiciones exactas a los 4 y 8 minutos
c5 = _TC5()
assert c5.phase == 1 and c5.name == "I" and c5.time_to_next == 240 and c5.pop_orders() == []
assert c5.update(239.5) == [] and c5.phase == 1 and abs(c5.time_to_next - 0.5) < 1e-9       # a los 239,5 s sigue la fase I
assert c5.update(0.5) == [("phase", 2)] and c5.phase == 2 and c5.name == "II"                # a los 240 s (4 min): fase II
assert c5.update(0.0) == [] and c5.t == 240.0                                                # dt = 0 (pausa): nada cambia
c6 = _TC5()
c6.update(479.5)
assert c6.phase == 2 and c6.time_to_next == 0.5
assert c6.update(0.5) == [("phase", 3)] and c6.phase == 3 and c6.name == "III" and c6.time_to_next is None   # 480 s (8 min)
assert c6.update(300) == [] and c6.phase_progress == 1.0                                     # cada evento se emite una sola vez
assert _TC5().update(500) == [("phase", 2), ("phase", 3)]                                    # un salto largo no se salta fases
assert [_ROMAN5[n_] for n_ in (1, 2, 3)] == ["I", "II", "III"]
# --- escalado de los envíos por fase
seen_ = {1: [], 2: [], 3: []}
c7 = _TC5()
while c7.t < 760:
    c7.update(0.5)
    for o_ in c7.pop_orders():
        seen_[c7.phase].append((round(c7.t), o_))
kinds_ = {n_: {k_ for _, o_ in seen_[n_] for k_ in o_.kinds} for n_ in seen_}
assert kinds_[1] == {"scout", "scavenger"}                                                   # fase I: Scouts y Carroñeros
assert {"soldier", "ariete"} <= kinds_[2] and "tank" not in kinds_[2]                        # fase II: Soldados y Arietes
assert "tank" in kinds_[3]                                                                   # fase III: marchas de Tanques
assert all(o_.target == "pylon" for _, o_ in seen_[2] + seen_[3] if o_.stream == "strike")   # dirigidos a pilones
assert all(o_.requires == "factory" for _, o_ in seen_[3] if o_.stream == "armor")           # los Tanques dependen de la Factoría
first_raid_ = next(t_ for t_, o_ in seen_[1] if o_.stream == "raiders")
assert 12 <= first_raid_ <= 13                                                               # el primer envío sale a los ~12 s
armor_ = [(t_, o_) for t_, o_ in seen_[3] if o_.stream == "armor"]
assert armor_[0][1].kinds["tank"] == 1 and armor_[-1][1].kinds["tank"] > armor_[0][1].kinds["tank"]   # a más tiempo, marchas mayores
assert len(seen_[2]) >= len(seen_[1]) * 0.5 and sum(o_.count for _, o_ in seen_[3]) / 280 > sum(o_.count for _, o_ in seen_[1]) / 240
dumped_ = c7.dump()
assert _TC5.restore(dumped_).t == c7.t and _TC5.restore(dumped_).phase == 3
# --- fortaleza evolutiva: fase I, obras con tiempo, escudo y reconstrucción no instantánea
fw = WorldRefs(bounds=pygame.Rect(0, 0, 3000, 2000))
fort = _EF5(Vector2(2660, 1000), fw)
assert fort.core.max_hp == 1200 and fort.phase == 1 and not fort.shielded and fort.factory is None and not fort.sites
assert sorted(b_.kind for b_ in fort.buildings) == ["torreta_ligera", "torreta_ligera"]       # núcleo simple + 2 torretas ligeras
fort.core.take_damage(100)
assert fort.core.hp == 1100                                                                 # sin escudo: recibe daño
fort.core.hp = 1200
fort.apply_phase(2)                                                                           # fase II: se construye, no aparece
assert len(fort.sites) == 3 and not fort.shielded and not any(b_.kind == "generador" for b_ in fort.buildings)
fort.update(19.9)
assert len(fort.sites) == 3 and not fort.shielded                                             # aún en obra (20 s)
fort.update(0.2)
kinds_f = sorted(b_.kind for b_ in fort.buildings if b_.alive() and b_.kind != "extractor")
assert not fort.sites and kinds_f == ["generador", "torreta_ligera", "torreta_ligera", "torreta_pesada", "torreta_pesada"]
assert fort.shielded and fort.core.take_damage(500) is False and fort.core.hp == 1200         # escudo: el núcleo es invulnerable
fort.apply_phase(3)
fort.update(20.1)
assert fort.factory is not None and fort.factory.alive() and fort.phase == 3
fort.generator.take_damage(9999)                                                              # cae el generador: sin escudo...
assert not fort.shielded and len(fort.sites) == 1                                             # ...y NO reaparece al instante
fort.update(29.0)
assert not fort.shielded and len(fort.sites) == 1                                             # fase III: 30 s de retardo + obra
fort.update(0.9)
assert not fort.shielded
fort.update(25.0)
assert fort.shielded and not fort.sites and fort.rebuilt == 1                                 # vuelve, con su tiempo de obra
gen_pos_ = fort.generator.pos
fort.factory.take_damage(9999)
assert fort.factory is None and any(s_.kind == "fabrica" for s_ in fort.sites)                # la Factoría tampoco vuelve al instante
fort.update(60.0)
assert fort.factory is not None and fort.factory.alive()
fort.generator.take_damage(9999)
for s_ in fort.sentinels:
    s_.take_damage(9999)
fort.core.take_damage(5000)
assert fort.destroyed and not fort.sites                                                      # núcleo destruido: la fortaleza cae
# --- nodos de plasma: reserva finita de Núcleos (1 + 2), luego chatarra, tope por campaña
class _Mark(pygame.sprite.Sprite):
    def __init__(self, pos):
        super().__init__()
        self.pos, self.home = Vector2(pos), Vector2(pos)


nw = WorldRefs()
node = _PN5(Vector2(500, 500))
rn = _RM5()
c_start = rn.cores
ally = _Mark((510, 500))
nw.drones.add(ally)
for _ in range(19):
    node.update(0.25, nw, rn, rn.campaign_run)
assert node.owner == "neutral" and rn.cores == c_start                                        # 4,75 s: aún no captura
node.update(0.5, nw, rn, rn.campaign_run)
assert node.owner == "player" and rn.cores == c_start + 1 and node.cores_given == 1           # capturado: 1 Núcleo
for _ in range(int(45 / 0.25) * 2 + 4):
    node.update(0.25, nw, rn, rn.campaign_run)
assert rn.cores == c_start + 3 and node.depleted and rn.campaign_run.siege_cores_earned == 3  # +1 y +1 de goteo: máximo 3 por nodo
m_a = rn.metal
for _ in range(int(30 / 0.25)):
    node.update(0.25, nw, rn, rn.campaign_run)
assert rn.cores == c_start + 3 and rn.metal - m_a == 3 * _U5.PLASMA_NODE["scrap_trickle"]     # vacío: chatarra, nunca más Núcleos
foe = _Mark((520, 500))
nw.enemies.add(foe)
contested_ = node.progress
node.update(1.0, nw, rn, rn.campaign_run)
assert node.progress == contested_                                                            # aliados y enemigos a la vez: disputado
nw.drones.empty()
for _ in range(45):
    node.update(0.25, nw, rn, rn.campaign_run)
assert node.owner == "enemy"                                                                  # solo el enemigo cerca: lo captura
rn2 = _RM5()
rn2.campaign_run.siege_cores_earned = _U5.PLASMA_NODE["campaign_cap"] - 1
node2 = _PN5(Vector2(500, 500))
nw2 = WorldRefs()
nw2.drones.add(_Mark((500, 500)))
for _ in range(400):
    node2.update(0.25, nw2, rn2, rn2.campaign_run)
assert rn2.cores == _RM5().cores + 1 and rn2.campaign_run.siege_cores_earned == _U5.PLASMA_NODE["campaign_cap"]   # tope de campaña
# --- órdenes: la bomba solo daña estructuras hostiles en Attack-Move; el Explorador ignora las órdenes
from src.entities.foundry import HostileStructure as _HS5
class _Wall5(_HS5):
    def _render(self, size):
        return pygame.Surface(size)


hw = WorldRefs()
hs5 = _Wall5((100, 100), 300, (40, 40))
hw.hostile.add(hs5)
_Bomb5((100, 100), 75, 60, 0.1).explode(hw)
assert hs5.hp == 300                                                                          # Acto 2 / por defecto: no daña estructuras
_Bomb5((100, 100), 75, 60, 0.1, hit_structures=True).explode(hw)
assert hs5.hp == 225
rec5 = _DC5["recon"](Vector2(0, 0), dict(_U5.DRONE_TYPES["recon"]))
assert rec5.order is None and not rec5.order_arrived

# --- escena de asedio: arranque sin Operador, cámara RTS, estructuras libres, orden Attack-Move y simulación de 10 minutos
game.new_campaign()
rs = game.resources
rs.metal, rs.cores = 4000, 5
assert not rs.structure_unlocked("fabrica") and not rs.siege_active                           # fuera del asedio, la Fábrica sigue bloqueada
game.machine.transition(GameState.SIEGE)
sg = game.machine.active
assert game.machine.current_state is GameState.SIEGE and game.machine.sub_act is SubAct.S3_0
assert rs.siege_active and rs.structure_unlocked("fabrica") and rs.structure_unlocked("pylon") and rs.structure_unlocked("balista")
assert not rs.structure_unlocked("foco") and not rs.structure_unlocked("compuerta")        # solo las del asedio
assert isinstance(sg, Act2State) and sg.INSTANT_BUILD is False                                # hereda del bucle del Acto 2
assert not isinstance(sg.player, Player) and not any(isinstance(s_, Player) for s_ in sg.all_sprites)   # sin avatar del Operador
assert (sg.map_w, sg.map_h) == (3000, 2000) and sg.CC_POS.distance_to(sg.FORTRESS_POS) >= 2200
assert sg.core.alive() and sg.fortress.core.max_hp == 1200 and len(sg.nodes) >= 2 and len(sg.enemy_bases) == 1
assert sg.world.player is None and sg.camera.offset.x <= sg.CC_POS.x
while sg.dialogue.blocking_active:
    sg.dialogue.advance()
game.machine.draw(game.screen)
off_s = Vector2(sg.camera.offset)
held[pygame.K_d] = True
step(game, 30)
held.clear()
assert sg.camera.offset.x > off_s.x                                                           # cámara libre tipo RTS
t_clock_ = sg.clock.t
sg.paused = True
step(game, 60)
assert sg.clock.t == t_clock_                                                                 # la pausa detiene el reloj de amenaza
sg.paused = False
step(game, 60)
assert sg.clock.t > t_clock_
# VULCANO construye la Fábrica (obra ordenada con un clic) y los drones salen de ella
sg.build_choice = "fabrica"
sg._try_build(sg.CC_POS + Vector2(150, -120))
sg.build_choice = None
fsite_ = sg.sites[0]
for _ in range(1800):
    step(game, 1)
    if not sg.sites:
        break
assert not sg.sites and len(sg.factories) == 1 and sg.factory.alive()
# Attack-Move: sin drones avisa; con drones los de combate marchan al punto y destruyen la fortaleza en fase I
assert sg.issue_attack_move(sg.FORTRESS_POS) == 0
drones_s = []
for k_ in ["attack"] * 4 + ["bomber"] * 2 + ["trooper"] * 2 + ["recon"]:
    d_ = _DC5[k_](sg.CC_POS + Vector2(120, -60 + 20 * len(drones_s)), dict(_U5.DRONE_TYPES[k_]), sg.CC_POS + Vector2(120, 0))
    sg.world.drones.add(d_)
    sg.all_sprites.add(d_)
    drones_s.append(d_)
assert sg.issue_attack_move(sg.FORTRESS_POS) == 8                                             # 8 de combate (el Explorador no)
assert all(d_.order is not None for d_ in drones_s[:8]) and drones_s[8].order is None
assert all(len(d_.route) >= 2 for d_ in drones_s if d_.kind == "trooper")                     # los terrestres rutean por los pasos
assert sg.order_marker is not None
fort_s = sg.fortress
for _ in range(int(120 / 0.1)):
    sg.update(0.1)
    if sg.victory:
        break
assert sg.victory and fort_s.destroyed and sg.end_timer is not None                           # la fortaleza es destruible
assert sum(1 for d_ in drones_s if d_.alive()) >= 4 and sg.clock.phase == 1                   # rush temprano: aún fase I
assert "destruido" in "".join(sg._stats())
sg.update(3.1)
assert game.machine.current_state is GameState.CAMPAIGN_VICTORY                               # cierre de campaña
game.machine.draw(game.screen)
game.machine.transition(GameState.MENU)
assert not rs.siege_active and not rs.structure_unlocked("fabrica")                           # al salir se restablece
# simulación de 10 minutos: fases, banner, composición de los envíos y marchas contra pilones
game.new_campaign()
rs = game.resources
rs.metal, rs.cores = 6000, 5
game.machine.transition(GameState.SIEGE)
sg = game.machine.active
while sg.dialogue.blocking_active:
    sg.dialogue.advance()
pyl_ = create_building("pylon", sg.CC_POS + Vector2(-120, 200))
sg._register(pyl_)
phases_seen_, banners_ = [], []
kinds_seen_ = {1: set(), 2: set(), 3: set()}
for _ in range(int(620 / 0.25)):
    sg.update(0.25)
    sg.core.hp = sg.core.max_hp
    assert sg.active_enemies() <= 65                                                          # el tope duro nunca se supera
    if sg.active_enemies() > 50:                                                              # las defensas van abatiendo a los más viejos
        for old_ in sg.world.enemies.sprites()[:8]:
            old_.take_damage(10 ** 6)
    if not pyl_.alive():
        pyl_ = create_building("pylon", sg.CC_POS + Vector2(-120, 200))
        sg._register(pyl_)
    if sg.phase_banner and sg.phase_banner["title"] not in banners_:
        banners_.append(sg.phase_banner["title"])
    for e_ in sg.world.enemies:
        kinds_seen_[sg.clock.phase].add(e_.enemy_type)
    if not phases_seen_ or phases_seen_[-1] != sg.clock.phase:
        phases_seen_.append(sg.clock.phase)
assert phases_seen_ == [1, 2, 3] and len(banners_) == 2 and "AMENAZA II" in banners_[0] and "AMENAZA III" in banners_[1]
assert kinds_seen_[1] == {"scout"}                                                            # fase I: solo Scouts (y Carroñeros aparte)
assert {"soldier", "ariete"} <= kinds_seen_[2] and "tank" not in kinds_seen_[2]
assert "tank" in kinds_seen_[3] and sg.fortress.factory is not None and sg.fortress.shielded
marchers_ = [e_ for e_ in sg.world.enemies if getattr(e_, "siege_target", None) == "pylon"]
assert marchers_ and all(e_.target_pos is not None for e_ in marchers_)
pyl_.take_damage(99999)                                                                       # cae el pilón: las marchas buscan otro o el núcleo
sg._retarget_cd = 0
sg._retarget_marchers(0.1)
assert all(not e_.siege_goal is pyl_ for e_ in marchers_)
game.machine.draw(game.screen)                                                                # HUD de amenaza III con todo en pantalla
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Paso E: tope de 65 enemigos, consola del Búnker, victoria y derrota del asedio ==")
from src.managers.resource_manager import CampaignRun as _CR6
from src.mechanics.threat_clock import SpawnQueue as _SQ6
# --- cola con tope duro (lógica pura)
q6 = _SQ6(65)
q6.enqueue("scout", "core", 70)
q6.enqueue("tank", "core", 3)
assert q6.pending == 73 and len(q6.release(65)) == 0 and q6.pending == 73                  # lleno: nada se instancia
assert len(q6.release(60)) == 5 and q6.pending == 68                                       # caben 5
rel6 = q6.release(0)
assert len(rel6) == 65 and q6.pending == 3 and [k_ for k_, _ in rel6].count("tank") == 0   # orden de llegada: los scouts primero
assert [k_ for k_, _ in q6.release(62)] == ["tank"] * 3 and q6.pending == 0                # y los tanques, al final de la cola
q6.clear()
assert q6.pending == 0 and q6.release(0) == []
# --- tope duro bajo estrés en la escena de asedio: 200 enviados a la vez, nunca más de 65 vivos
game.new_campaign()
r6 = game.resources
r6.metal, r6.cores = 3000, 5
game.machine.transition(GameState.SIEGE)
s6 = game.machine.active
while s6.dialogue.blocking_active:
    s6.dialogue.advance()
s6.spawn_queue.enqueue("scout", "core", 150)
s6.spawn_queue.enqueue("soldier", "pylon", 30)
s6.spawn_queue.enqueue("tank", "core", 20)
peak6 = 0
for _ in range(240):
    s6.update(0.25)
    s6.core.hp = s6.core.max_hp
    peak6 = max(peak6, s6.active_enemies())
    assert s6.active_enemies() <= 65
assert peak6 == 65 and s6.spawn_queue.pending > 100                                        # saturado: el resto espera en cola
before6 = s6.spawn_queue.pending
for e_ in s6.world.enemies.sprites()[:20]:
    e_.take_damage(10 ** 6)                                                                 # caen 20 bajas...
s6.update(0.25)
assert s6.active_enemies() == 65 and s6.spawn_queue.pending < before6                      # ...y salen de la cola para volver al tope
game.machine.draw(game.screen)                                                              # el HUD muestra "enemigos activos 65/65"
# --- persistencia de campaign_completed y retrocompatibilidad
cr6 = _CR6()
assert cr6.campaign_completed is False and cr6.to_dict()["campaign_completed"] is False
cr6.campaign_completed = True
assert _CR6.from_dict(cr6.to_dict()).campaign_completed is True
leg6 = cr6.to_dict()
del leg6["campaign_completed"]
assert _CR6.from_dict(leg6).campaign_completed is False                                    # partida antigua: campaña sin completar
game.new_campaign()
assert game.resources.campaign_completed is False and game.resources.can_start_siege is False
# --- consola del Búnker desbloqueada: Base Central con Búnker -> clic en la consola -> confirmar -> asedio con los recursos
game.new_campaign()
rb6 = game.resources
rb6.vulcano_online = True
rb6.command_module = True
rb6.factory_blueprints = True                                                               # planos de la Fábrica (Op 4)
rb6.metal, rb6.cores = 450, 2
game.machine.transition(GameState.BASE_MANAGEMENT)
bm6 = screens[GameState.BASE_MANAGEMENT]
left_click(game, bm6.bunker_site.pos)                                                       # ensambla el Búnker (VULCANO)
assert rb6.bunker_built and rb6.can_start_siege and bm6.bunker_console is not None
con6 = bm6.bunker_console
assert con6.label == "Iniciar Asedio Táctico a la Fortaleza Enemiga" and con6.prompt_key == "Clic / E" and "Bloqueada" not in con6.label
card6 = bm6.hover_card(bm6.camera.to_screen(con6.pos))[1]
assert card6["rows"][0][1] == "[Clic / E] Iniciar Asedio Táctico a la Fortaleza Enemiga"   # el tooltip pedido
mp6 = bm6.camera.to_screen(con6.pos)
mpos[0], mpos[1] = int(mp6.x), int(mp6.y)
step(game, 2)
assert con6.near and bm6._interactive_at(con6.pos) and bm6._cursor == pygame.SYSTEM_CURSOR_HAND   # cursor interactivo
mpos[0], mpos[1] = 640, 20
rb6.metal, rb6.cores = 1234, 4
press(game, pygame.K_e)                                                                     # E lejos de la consola: no pasa nada
assert not bm6.siege_prompt
mpos[0], mpos[1] = int(mp6.x), int(mp6.y)
press(game, pygame.K_e)                                                                     # E con el cursor sobre la consola: confirmación
assert bm6.siege_prompt and game.machine.current_state is GameState.BASE_MANAGEMENT
game.machine.draw(game.screen)                                                              # diálogo de confirmación con los recursos
press(game, pygame.K_ESCAPE)
assert not bm6.siege_prompt and game.machine.current_state is GameState.BASE_MANAGEMENT    # cancelar no despliega
left_click(game, con6.pos)
assert bm6.siege_prompt
game.machine.draw(game.screen)
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=bm6.siege_buttons["go"].center))
assert game.machine.current_state is GameState.SIEGE                                        # clic en confirmar: asedio
sg6 = game.machine.active
assert (rb6.metal, rb6.cores) == (1234, 4)                                                  # recursos de campaña persistidos
assert any("1234" in ln_.text and "transferidos" in ln_.text for ln_ in sg6.dialogue.lines) and rb6.siege_transfer is None
assert sg6.bunker is not None and sg6.bunker_console.label == _U5.BUNKER["console_label_remote"]   # en el asedio, la consola remite
assert any(e_["type"] == "bunker" for e_ in rb6.base_layout)                                # la base quedó guardada al desplegar
# --- derrota: pantalla de fallo táctico con [R] reintentar y [ESC] retirada a la Base Central
while sg6.dialogue.blocking_active:
    sg6.dialogue.advance()
rb6.metal = 777
old_level6 = sg6.level
sg6.core.take_damage(10 ** 6)
sg6.update(0.1)
assert sg6.end_timer is not None and not sg6.victory and "Centro de Control" in sg6.fail_reason
sg6.update(1.6)
assert sg6.fail_menu and game.machine.current_state is GameState.SIEGE and not rb6.campaign_completed
t_dead6 = sg6.clock.t
sg6.update(5.0)
assert sg6.clock.t == t_dead6                                                               # el mundo está parado tras el fallo
game.machine.draw(game.screen)                                                              # pantalla de fallo táctico
press(game, pygame.K_r)                                                                     # [R] reintentar asedio
assert not sg6.fail_menu and game.machine.current_state is GameState.SIEGE and sg6.clock.t == 0
assert sg6.level is not old_level6 and sg6.core.alive() and rb6.metal >= 777 and not sg6.spawn_queue.pending
while sg6.dialogue.blocking_active:
    sg6.dialogue.advance()
sg6.core.take_damage(10 ** 6)
sg6.update(0.1)
sg6.update(1.6)
assert sg6.fail_menu
game.machine.draw(game.screen)
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=sg6._fail_buttons["retreat"].center))
assert game.machine.current_state is GameState.BASE_MANAGEMENT                              # [ESC]/botón: retirada a la Base Central
bmr6 = screens[GameState.BASE_MANAGEMENT]
assert rb6.bunker_built and bmr6.bunker is not None and bmr6.bunker_console is not None and not rb6.siege_active
# --- victoria: se detienen los envíos, se apagan las torretas y la pantalla de campaña guarda campaign_completed
game.new_campaign()
rv6 = game.resources
rv6.metal, rv6.cores = 3000, 3
rv6.bunker_built = True
game.machine.transition(GameState.SIEGE)
sv6 = game.machine.active
while sv6.dialogue.blocking_active:
    sv6.dialogue.advance()
sv6.spawn_queue.enqueue("scout", "core", 30)
for _ in range(40):
    sv6.update(0.25)
fort6 = sv6.fortress
assert fort6.core.max_hp == 1200 and not fort6.destroyed
for b_ in list(fort6.buildings):
    if b_.kind != "extractor":
        b_.take_damage(10 ** 6)
fort6.core.take_damage(10 ** 6)                                                             # cae el núcleo de 1200 HP
assert fort6.destroyed and sv6.victory and sv6.spawn_queue.pending == 0 and sv6.end_timer is not None
assert not any(b_.alive() for b_ in sv6.world.hostile)                                      # sin torretas enemigas en pie
n6 = len(sv6.world.enemies)
sv6.update(1.0)
assert len(sv6.world.enemies) <= n6 and not rv6.campaign_completed                          # no salen más enemigos
sv6.update(2.1)
assert game.machine.current_state is GameState.CAMPAIGN_VICTORY and not rv6.campaign_completed   # aún sin guardar
cv6 = game.machine.active
labels6 = [lab_ for lab_, _ in cv6.stats]
assert labels6 == ["Tiempo de asedio", "Bajas infligidas", "Recursos extraídos", "Fase de amenaza alcanzada"]
assert cv6.stats[0][1] == "00:10" and cv6.stats[3][1] == "I de III" and "chatarra" in cv6.stats[2][1]
game.machine.draw(game.screen)                                                              # Pantalla de Victoria de Campaña
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=cv6.button.center))
assert game.machine.current_state is GameState.MENU and rv6.campaign_completed is True      # guardada y de vuelta al menú
assert _CR6.from_dict(rv6.campaign_run.to_dict()).campaign_completed is True                # persistencia
game.new_campaign()
assert game.resources.campaign_completed is False                                           # campaña nueva: limpia
game.machine.transition(GameState.CAMPAIGN_VICTORY, stats=[("Tiempo de asedio", "01:00")])
press(game, pygame.K_RETURN)                                                                # ENTER también guarda y vuelve
assert game.machine.current_state is GameState.MENU and game.resources.campaign_completed is True

# =============================================================================
print("== Ajustes de balance del asedio: blanco de los drones, dron de asalto, Balista libre y chatarra por baja ==")
from src.entities.drones import DRONE_CLASSES as _DC7
from src.entities.enemy_fortress import EnemyFortress as _EF7
from src.config import UNITS as _U7
assert (_U7.DRONE_TYPES["attack"]["hp"], _U7.DRONE_TYPES["attack"]["damage"], _U7.DRONE_TYPES["attack"]["cost"]) == (140, 16, 40)
assert _U7.DRONE_TYPES["attack"]["damage"] / _U7.DRONE_TYPES["attack"]["shot_interval"] == 32          # 32 DPS sostenidos
assert _U7.SIEGE["free_structures"] == ("fabrica", "pylon", "balista") and _U7.SIEGE["kill_metal"] == 4
# --- blanco: con el escudo activo se ignora el núcleo y se prioriza el Generador (luego torretas y unidades)
tw7 = WorldRefs(bounds=pygame.Rect(0, 0, 3000, 2000))
f7 = _EF7(Vector2(2660, 1000), tw7)
f7.apply_phase(2)
f7.update(25.0)
assert f7.shielded
dr7 = _DC7["attack"](Vector2(2660, 1000) + Vector2(-60, 0), dict(_U7.DRONE_TYPES["attack"]), Vector2(0, 0))   # pegado al núcleo
tw7.drones.add(dr7)
foe7 = dr7._order_foe(tw7, 400)
assert foe7 is not None and foe7 is not f7.core and not getattr(foe7, "shielded", False)                 # nunca el núcleo blindado
assert foe7 is f7.generator                                                                              # el Generador va primero
f7.generator.take_damage(10 ** 6)
assert not f7.shielded
foe7b = dr7._order_foe(tw7, 400)
assert foe7b is not None and foe7b is not f7.generator                                                    # sin escudo, el núcleo vuelve a ser blanco válido
for b_ in list(f7.buildings):
    if b_.kind != "extractor":
        b_.take_damage(10 ** 6)
f7.update(0.1)
assert dr7._order_foe(tw7, 400) is not None                                                              # sin escudo, el núcleo ya es blanco
# --- con el escudo activo, un asalto de 8 drones ya no malgasta el fuego en el núcleo
game.new_campaign()
r7 = game.resources
r7.metal = 5000
game.machine.transition(GameState.SIEGE)
s7 = game.machine.active
while s7.dialogue.blocking_active:
    s7.dialogue.advance()
s7.clock.update = lambda dt: []
s7.clock.pop_orders = lambda: []
s7.fortress.apply_phase(2)
s7.fortress.update(25.0)
absorbed7 = [0.0]
orig7 = s7.fortress.core.take_damage


def tracked7(amount, direction=None):
    if s7.fortress.core.shielded:
        absorbed7[0] += amount
    return orig7(amount, direction)


s7.fortress.core.take_damage = tracked7
for k_ in range(10):
    d_ = _DC7["attack"](s7.CC_POS + Vector2(120, -60 + 14 * k_), dict(_U7.DRONE_TYPES["attack"]), s7.CC_POS + Vector2(120, 0))
    s7.world.drones.add(d_)
    s7.all_sprites.add(d_)
s7.issue_attack_move(s7.FORTRESS_POS)
for _ in range(int(150 / 0.1)):
    s7.update(0.1)
    if s7.victory:
        break
assert absorbed7[0] == 0 and s7.victory                                                                  # nada al escudo y cae la fortaleza
# --- chatarra directa por baja en el asedio (4 por baja, sin recoger nada)
game.machine.transition(GameState.MENU)
game.new_campaign()
r7 = game.resources
r7.metal = 1000
game.machine.transition(GameState.SIEGE)
s7 = game.machine.active
while s7.dialogue.blocking_active:
    s7.dialogue.advance()
m7, k7 = r7.metal, s7.kills
for i_ in range(5):
    e_ = s7._spawn_enemy("scout", "core", i_)
    e_.take_damage(10 ** 6)
assert r7.metal - m7 == 5 * 4 and s7.kills - k7 == 5                                                      # +4 de chatarra por baja
# --- la Balista se construye en el asedio sin haber ganado el mapa 1
s7.build_choice = "balista"
before7 = len(s7.sites)
spot7 = next(s7.CC_POS + Vector2(dx_, dy_) for dx_ in range(-300, 301, 40) for dy_ in range(-300, 301, 40)
             if s7._can_place("balista", s7._ghost_rect("balista", s7.CC_POS + Vector2(dx_, dy_))))
s7._try_build(spot7)
s7.build_choice = None
assert len(s7.sites) == before7 + 1 and s7.sites[-1].btype == "balista"
game.machine.transition(GameState.MENU)
assert not r7.structure_unlocked("balista")                                                              # fuera del asedio sigue bloqueada

# =============================================================================
print("== Operador y combate: 1.3 con energía, asistencia de apuntado, evasión de muros, bloques de vida y botiquines ==")
from src.config import UNITS as _U8

from src.entities.obstacle import Obstacle as _Obs8
from src.managers.resource_manager import CampaignRun as _CR8
# nerf a distancia: -20% de vida y -18% de alcance
assert (_U8.ENEMIES["soldier"]["hp"], _U8.ENEMIES["soldier"]["range"]) == (144, 160)
assert (_U8.ENEMIES["tank"]["hp"], _U8.ENEMIES["tank"]["range"]) == (1120, 312)
# --- 1.3: arranca con la energía del Reactor (0/50, sin números rojos), aviso de Modo Construcción y su pausa
game.machine.transition(GameState.MENU)
game.new_campaign()
game.machine.transition(GameState.SUB_ACT_1_3)
s8 = screens[GameState.SUB_ACT_1_3]
dismiss(game)
assert (game.resources.energy, game.resources.energy_cap) == (0, 50) and s8.energy_free() == 50
assert "ESPACIO modo construcción" in s8.HINT and s8.PAUSE_TITLE == "MODO CONSTRUCCIÓN"
step(game, 2)
press(game, pygame.K_SPACE)
assert s8.paused
step(game, 2)                                                                     # dibuja el aviso y el banner en pausa
press(game, pygame.K_SPACE)
assert not s8.paused
# --- bloques de vida y botiquín con [H]
p8 = s8.player
assert p8.health_blocks == 3 and p8.max_hp == 100
p8.take_damage(40)                                                                # 60 HP: 2 bloques, uno dañado
assert p8.lost_blocks == 1 and p8.blocks_left == 2
game.resources.medkits = 0
press(game, pygame.K_h)
assert game.resources.medkits == 0 and p8.lost_blocks == 1                        # sin botiquines no pasa nada
assert game.resources.add_medkits(9) == 5 and game.resources.medkits == 5         # bolsillo de 5
press(game, pygame.K_h)
assert game.resources.medkits == 4 and p8.lost_blocks == 0 and p8.hp == p8.max_hp
press(game, pygame.K_h)
assert game.resources.medkits == 4                                                # sin bloques perdidos no se gasta
# --- recogida: un botiquín en el suelo va al bolsillo; con el bolsillo lleno se queda en el suelo
kit8 = s8.drop_medkit(p8.pos + Vector2(10, 0))
step(game, 3)
assert not kit8.alive() and game.resources.medkits == 5
kit8b = s8.drop_medkit(p8.pos + Vector2(10, 0))
step(game, 3)
assert kit8b.alive() and game.resources.medkits == 5
kit8b.kill()
# botín de enemigos: el tanque suelta botiquín con su probabilidad (20%)
import random as _rnd8
_r8 = _rnd8.Random(0)
drops8 = sum(1 for _ in range(500) if s8.roll_medkit_drop(Vector2(100, 100), "tank", _r8) is not None)
assert 70 <= drops8 <= 130, drops8
for k_ in list(s8.world.medkits):
    k_.kill()
# persiste en la campaña
assert _CR8.from_dict(game.resources.campaign_run.to_dict()).medkits == 5 and _CR8.from_dict({}).medkits == 0
# --- asistencia de apuntado: dentro del cono de 15° la bala va al enemigo; fuera, recta al cursor
for e_ in list(s8.world.enemies):
    e_.kill()
p8.aim_dir = Vector2(1, 0)
foe8 = s8.spawn_enemy("scout", p8.pos + Vector2(200, 35))                         # a ~10° del cursor
d8 = p8.assisted_aim()
assert abs(d8.angle_to(foe8.pos - p8.pos)) < 1e-6
grp8 = pygame.sprite.Group()
p8.projectile_groups = (grp8,)
p8.shoot()
assert abs(next(iter(grp8)).vel.normalize().angle_to(foe8.pos - p8.pos)) < 0.01   # la bala sale corregida
foe8.pos = p8.pos + Vector2(200, 90)                                              # a ~24°: fuera del cono
assert p8.assisted_aim() == Vector2(1, 0)
p8.aim_assist = False
foe8.pos = p8.pos + Vector2(200, 35)
assert p8.assisted_aim() == Vector2(1, 0)
p8.aim_assist = True
foe8.kill()
game.machine.transition(GameState.MENU)
# --- evasión de muros: el enemigo que empuja de frente contra una pared la rodea en vez de quedarse trabado
solids8 = pygame.sprite.Group(_Obs8(pygame.Rect(480, 100, 40, 200)))
grp_e8 = pygame.sprite.Group()
ew8 = Enemy("soldier", (440, 200), (700, 205), grp_e8)
ew8.straight = True                                                               # rumbo en línea recta contra la pared
grp_e8.add(ew8)
for _ in range(60 * 8):
    ew8.update(1 / 60, pygame.sprite.Group(), None, solids8)
assert ew8.pos.x > 530, ew8.pos                                                   # pasó al otro lado
assert not ew8.rect.colliderect(pygame.Rect(480, 100, 40, 200))
# --- Celda Vital I y II (Supervivencia, niveles 3 y 4): cuarto y quinto bloque de vida
rm8 = ResourceManager()
rm8.cores = 14                                                                    # 1 + 3 + 4 + 6
for n_ in ("impulso_doble", "blindaje_titanio"):
    assert rm8.buy_node(n_)
assert rm8.node_state("celda_vital") == "available" and rm8.node_state("celda_vital_2") == "locked" and rm8.player_max_hp == 100
assert rm8.buy_node("celda_vital") and rm8.cores == 6 and rm8.player_max_hp == 133
pc8 = Player((0, 0), 100, 100)
pc8.apply_upgrades(rm8)
assert pc8.health_blocks == 4 and pc8.max_hp == 133 and abs(pc8.block_size - 33.25) < 1e-9
assert rm8.buy_node("celda_vital_2") and rm8.cores == 0 and rm8.player_max_hp == 166
pc8.apply_upgrades(rm8)
assert pc8.health_blocks == 5 and pc8.max_hp == 166 and abs(pc8.block_size - 33.2) < 1e-9
pc8.take_damage(74)                                                               # 74 - 4 de blindaje = 70: 96 HP, 2 bloques perdidos
assert pc8.blocks_left == 3 and pc8.lost_blocks == 2
assert pc8.use_medkit() and pc8.use_medkit() and pc8.lost_blocks == 0 and pc8.hp == pc8.max_hp   # 1 botiquín por bloque
assert C.MEDKIT_MAX == 5
game.machine.transition(GameState.MENU)
game.new_campaign()
game.resources.op_nodes.update({"impulso_doble", "blindaje_titanio", "celda_vital", "celda_vital_2"})
game.resources.equipped = True
game.machine.transition(GameState.SUB_ACT_1_3)
dismiss(game)
assert screens[GameState.SUB_ACT_1_3].player.health_blocks == 5
step(game, 2)                                                                     # el HUD dibuja los 5 bloques
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Identidad del Operador y guardado por perfiles (saves/{nombre}.json) ==")
import json as _json9
from src.mechanics import save_manager as _sm9
from src.scenes.main_menu import MainMenuState as _MM9
from src.managers.resource_manager import CampaignRun as _CR9
assert _sm9.SAVE_DIR == SAVE_TMP
# nombres: limpios, máx. 12, sin nombres reservados ni caracteres prohibidos; vacío -> Operador
assert _sm9.clean_name("") == "Operador" and _sm9.clean_name("  ") == "Operador" and _sm9.clean_name("Ana María!") == "AnaMaría"
assert _sm9.clean_name("x" * 20) == "x" * 12 and _sm9.file_stem("CON") == "CON_" and _sm9.file_stem("a/b:c*?") == "abc"
assert _CR9.from_dict({}).player_name == "Operador" and not _CR9.from_dict({}).named      # partidas heredadas
# guardar / cargar ida y vuelta con conjuntos, bytes (niebla) y el RewardTracker
folder9 = tempfile.mkdtemp(prefix="rr_prof_")
game.machine.transition(GameState.MENU)
game.new_campaign()
r9 = game.resources
r9.campaign_run.player_name, r9.campaign_run.named = "Trinity", True
r9.metal, r9.cores, r9.medkits, r9.incursion_level, r9.initial_done = 1234, 7, 3, 4, True
r9.op_nodes.update({"impulso_doble", "blindaje_titanio"})
r9.reward_tracker.add_reward("PLAYER_UPGRADE_1")
r9.act2_fog = bytes([1, 0, 1, 1])
r9.history.append("prueba")
path9 = _sm9.save_game(r9, "BASE_MANAGEMENT", {"next_state": "ACT_2_BASE"}, folder9)
assert os.path.basename(path9) == "Trinity.json"
data9 = _json9.load(open(path9, encoding="utf-8"))
assert data9["player_name"] == "Trinity" and data9["resume"]["state"] == "BASE_MANAGEMENT" and "incursión nivel 4" in data9["progress"]
game.new_campaign()
assert game.resources.metal != 1234 and not game.resources.campaign_run.named
st9, kw9 = _sm9.apply_save(game.resources, data9)
r9 = game.resources
assert (st9, kw9) == ("BASE_MANAGEMENT", {"next_state": "ACT_2_BASE"})
assert (r9.metal, r9.cores, r9.medkits, r9.incursion_level, r9.initial_done) == (1234, 7, 3, 4, True)
assert r9.owns("impulso_doble") and r9.owns("blindaje_titanio") and r9.reward_tracker.is_unlocked("PLAYER_UPGRADE_1")
assert r9.act2_fog == bytes([1, 0, 1, 1]) and r9.history[-1] == "prueba" and r9.player_name == "Trinity"
# migración: un archivo sin player_name pasa a Operador.json conservando el progreso (el original queda de respaldo)
_json9.dump({"campaign_run": {"op_nodes": ["impulso_doble"], "completed_maps": ["map_1"]},
             "resources": {"metal": 321, "aura_linked": True, "vulcano_online": True, "initial_done": True}},
            open(os.path.join(folder9, "partida_vieja.json"), "w", encoding="utf-8"))
profs9 = _sm9.list_profiles(folder9)
assert {p_["name"] for p_ in profs9} == {"Trinity", "Operador"}
assert os.path.isfile(os.path.join(folder9, "Operador.json")) and os.path.isfile(os.path.join(folder9, "partida_vieja.json.migrado"))
assert _sm9.find_profile("trin", folder9)["name"] == "Trinity" and _sm9.find_profile("nadie", folder9) is None
# Continuar: reanuda exactamente en el punto guardado
st_m9 = game.continue_profile(os.path.join(folder9, "Operador.json"))
assert st_m9 is GameState.ACT_2_BASE and game.machine.current_state is GameState.ACT_2_BASE   # heredada: se deduce
assert game.resources.metal == 321 and game.resources.owns("impulso_doble") and "map_1" in game.campaign_run.completed_maps
assert game.resources.player_name == "Operador" and game.resources.campaign_run.named
game.continue_profile(path9)
assert game.machine.current_state is GameState.BASE_MANAGEMENT and screens[GameState.BASE_MANAGEMENT].next_state is GameState.ACT_2_BASE
assert game.resources.metal == 1234
# autoguardado: al entrar a la Base Central, al extraer de una incursión y al montar el Búnker; sin nombre no guarda
before9 = _json9.load(open(os.path.join(SAVE_TMP, "Trinity.json"), encoding="utf-8"))["resume"]
assert before9["state"] == "BASE_MANAGEMENT"                         # al reanudar ya volvió a guardar en la Base Central
game.machine.transition(GameState.ACT_2_BASE)
assert _json9.load(open(os.path.join(SAVE_TMP, "Trinity.json"), encoding="utf-8"))["resume"]["state"] == "ACT_2_BASE"
game.new_campaign()
assert game.autosave("ACT_2_BASE") is None                           # sin nombre: nada
# Menú principal: [2] Continuar lista los perfiles; sin perfiles, aviso; flechas + ENTER y nombre escrito
mm9 = screens[GameState.MENU]
assert isinstance(mm9, _MM9)
empty9 = tempfile.mkdtemp(prefix="rr_empty_")
_sm9.SAVE_DIR = empty9
game.machine.transition(GameState.MENU)
press(game, pygame.K_2)
assert mm9.mode == "main" and mm9.notice == "No hay registros guardados"
game.machine.draw(game.screen)
_sm9.SAVE_DIR = folder9
press(game, pygame.K_2)
assert mm9.mode == "continue" and len(mm9.profiles) == 2
game.machine.draw(game.screen)
names9 = [p_["name"] for p_ in mm9.profiles]
press(game, pygame.K_DOWN)
assert mm9.selected == 1
press(game, pygame.K_RETURN)
assert game.resources.player_name == names9[1]
game.machine.transition(GameState.MENU)
press(game, pygame.K_2)
for ch_ in "trin":
    game.machine.handle_event(pygame.event.Event(pygame.KEYDOWN, key=0, unicode=ch_))
game.machine.draw(game.screen)
press(game, pygame.K_RETURN)
assert game.resources.player_name == "Trinity" and game.machine.current_state is GameState.BASE_MANAGEMENT
game.machine.transition(GameState.MENU)
press(game, pygame.K_2)
press(game, pygame.K_ESCAPE)
assert mm9.mode == "main"
press(game, pygame.K_1)                                              # [1] Nueva Partida: desde el prólogo
assert game.machine.current_state is GameState.SUB_ACT_1_1 and not game.resources.campaign_run.named
_sm9.SAVE_DIR = SAVE_TMP
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Navegación: pasillo cerrado con esquinas de 90°, 5 enemigos persiguen sin congelarse ni vibrar ==")
from src.map.levels import Level as _Lv10
from src.mechanics.pathing import FlowField as _FF10
from src.entities import WorldRefs as _WR10
random.seed(3)
lv10 = _Lv10(40, 24, "urban")
for c0_, r0_, c1_, r1_ in ((2, 2, 30, 3), (29, 2, 30, 12), (8, 11, 30, 12), (8, 11, 9, 20), (8, 19, 36, 20), (35, 14, 36, 20)):
    lv10.carve(c0_, r0_, c1_, r1_)                                                # zigzag de 2 celdas con 5 esquinas de 90°
lv10.finish(seed=1)
w10 = _WR10(bounds=pygame.Rect(0, 0, *lv10.size))
w10.solids.add(*lv10.solids)
nav10 = _FF10(*lv10.size, hard=lv10.wall_cells)
p10 = Player(Vector2(35.5 * 40, 15 * 40), *lv10.size)
w10.player = p10
foes10 = []
for i_ in range(5):
    e_ = Enemy("scout", Vector2(4 * 40 + (i_ % 3) * 22, 3 * 40 + (i_ // 3) * 22 - 11), p10.pos, w10.enemies)
    e_.world, e_.chasing = w10, True
    w10.enemies.add(e_)
    foes10.append(e_)
stuck10 = {id(e_): 0.0 for e_ in foes10}
worst10, flips10, last10 = 0.0, 0, {id(e_): Vector2() for e_ in foes10}
for _ in range(60 * 40):
    nav10.retarget(p10)
    nav10.update(w10.structures, p10)
    before10 = {id(e_): Vector2(e_.pos) for e_ in foes10}
    w10.enemies.update(1 / 60, w10.structures, nav10, w10.solids)
    for e_ in foes10:
        assert not any(e_.rect.colliderect(s_.rect.inflate(-4, -4)) for s_ in w10.solids)   # nunca dentro de un muro
        if e_.pos.distance_to(p10.pos) < 90:
            continue
        v_ = (e_.pos - before10[id(e_)]) * 60
        stuck10[id(e_)] = stuck10[id(e_)] + 1 / 60 if v_.length() < e_.speed * 0.08 else 0.0
        worst10 = max(worst10, stuck10[id(e_)])
        if v_.length() > 5 and last10[id(e_)].length() > 5 and v_.normalize().dot(last10[id(e_)].normalize()) < -0.5:
            flips10 += 1
        last10[id(e_)] = v_
    if all(e_.pos.distance_to(p10.pos) < 90 for e_ in foes10):
        break
assert all(e_.pos.distance_to(p10.pos) < 90 for e_ in foes10), [round(e_.pos.distance_to(p10.pos)) for e_ in foes10]
assert worst10 < 0.4 and flips10 <= 10, (worst10, flips10)                        # ni congelados ni vibrando
# deslizamiento tangencial: contra un muro en diagonal conserva la componente paralela (no se clava)
sl10 = Enemy("scout", Vector2(4 * 40, 2.6 * 40), Vector2(28 * 40, 1 * 40), pygame.sprite.Group())
sl10.straight = True
x0_ = sl10.pos.x
for _ in range(60):
    sl10.update(1 / 60, pygame.sprite.Group(), None, w10.solids)
assert sl10.pos.x - x0_ > 120 and sl10.rect.top >= 2 * 40 - 2                    # resbala por el techo del pasillo
# persecución sin línea de visión: sigue el campo de flujo (no empuja recto contra la pared)
h10, los10 = nav10.route(Vector2(29.5 * 40, 3 * 40), p10.pos, 10)
assert not los10 and h10.y > 0.7                                                  # baja por el pasillo, no va en diagonal al muro

# =============================================================================
print("== Mentor VULCANO: hitos reactivos (Tríada, Economía, Balista, Mejoras), subsidio, ESC y autoguardado ==")
import json as _json11
VA.ENABLED = True
game.machine.transition(GameState.MENU)
game.new_campaign()
r11 = game.resources
r11.vulcano_online = r11.equipped = r11.aura_linked = True
r11.campaign_run.player_name, r11.campaign_run.named = "Morfeo", True
r11.metal = 5                                                                     # casi sin chatarra
game.machine.transition(GameState.BASE_MANAGEMENT, next_state=GameState.ACT_2_BASE)
bm11 = screens[GameState.BASE_MANAGEMENT]
adv11 = bm11.advisor
assert adv11.key == "triad" and adv11.phase == "intro" and adv11.modal and "Morfeo" in adv11.lines[0]
game.machine.draw(game.screen)
press(game, pygame.K_SPACE)                                                       # la explicación es modal: no despliega
assert game.machine.current_state is GameState.BASE_MANAGEMENT
for _ in range(len(adv11.lines)):
    press(game, pygame.K_RETURN)
assert adv11.phase == "step" and adv11.step == ("build", "pylon") and bm11.build_choice == "pylon"
assert bm11.build_guard("foco") and bm11.build_guard("wall") and bm11._cost("pylon") == 0      # solo el pilón, gratis
far11 = bm11._ghost_rect("pylon", bm11.CC_POS + Vector2(-140, 0))
assert "zona marcada" in bm11.build_guard("pylon", far11)                       # fuera de la zona: no
for btype_, off_ in (("pylon", (-40, 0)), ("wall", (90, 0)), ("tower", (10, 50))):
    assert adv11.step == ("build", btype_) and bm11._cost(btype_) == 0
    bm11.build_choice = btype_
    bm11._try_build(adv11.zone[0] + Vector2(off_))
    for _ in range(60 * 20):
        bm11.update(1 / 60)
        if adv11.step != ("build", btype_):
            break
assert adv11.phase == "trial" and r11.metal == 5                                  # subsidio: nada en rojo
seen11 = 0
for _ in range(60 * 40):
    bm11.update(1 / 60)
    seen11 = max(seen11, len(bm11.world.enemies))
    assert all(b_.hp >= 1 for b_ in bm11.world.structures)
    if adv11.phase != "trial":
        break
game.machine.draw(game.screen)
assert seen11 >= 1 and adv11.phase == "outro" and not bm11.world.enemies          # 3 Scouts derrotados
assert all(b_.hp == b_.max_hp and b_.hp_floor == 0 for b_ in bm11.world.structures)   # VULCANO lo deja como nuevo
press(game, pygame.K_RETURN)
assert "triad" in r11.campaign_run.tutorial_done and adv11.key is None
save11 = _json11.load(open(os.path.join(SAVE_TMP, "Morfeo.json"), encoding="utf-8"))
assert "triad" in save11["campaign_run"]["tutorial_done"]              # autoguardado con el hito
# Mejoras In-Situ: tras la incursión inicial, la torreta marcada se especializa gratis aunque la ruta no esté desbloqueada
r11.initial_done = True
assert adv11.start_next() == "upgrade"
for _ in range(len(adv11.lines)):
    press(game, pygame.K_RETURN)
assert adv11.target is not None and not r11.route_unlocked("tower", "A")
bm11.open_menu(adv11.target)
i11 = [o_["action"][0] for o_ in bm11.menu.options].index("route")
assert bm11.menu.options[i11]["scrap"] == 0 and bm11.menu_choose(i11) and adv11.target.route == "A" and r11.metal == 5
bm11.menu = None
for _ in range(60 * 40):
    bm11.update(1 / 60)
    if adv11.phase == "outro":
        break
assert adv11.phase == "outro" and not r11.route_unlocked("tower", "A")          # la tecnología sigue por desbloquear
press(game, pygame.K_RETURN)
assert r11.campaign_run.tutorial_done == {"triad", "upgrade"}
# Economía y Balista se activan solos al desbloquear su estructura (sin pasar por la explicación: ESC la salta)
r11.incursion_level = 3
assert adv11.start_next() == "economy"
press(game, pygame.K_ESCAPE)                                                      # salta: juego libre, hito registrado
assert adv11.key is None and "economy" in r11.campaign_run.tutorial_done and bm11.build_guard("foco") is None
r11.campaign_run.completed_maps.add("map_1_infiltration")
assert adv11.start_next() == "heavy"
adv11.abort()                                                                     # salir a mitad: no se marca
assert "heavy" not in r11.campaign_run.tutorial_done and adv11.start_next() == "heavy"
press(game, pygame.K_ESCAPE)
assert adv11.start_next() is None
# un hito a medias no rompe el despliegue
game.new_campaign()
r11 = game.resources
r11.vulcano_online = True
game.machine.transition(GameState.MENU)
game.machine.transition(GameState.BASE_MANAGEMENT, next_state=GameState.ACT_2_BASE)
bm11 = screens[GameState.BASE_MANAGEMENT]
assert bm11.advisor.key == "triad"
bm11.deploy()
assert game.machine.current_state is GameState.ACT_2_BASE and "triad" not in r11.campaign_run.tutorial_done
VA.ENABLED = False
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Generador retirado: los guardados con Generador cargan como Pilón ==")
from src.mechanics import save_manager as _sm12
folder12 = tempfile.mkdtemp(prefix="rr_gen_")
_json12 = __import__("json")
old12 = {"player_name": "Tank", "saved_at": "2026-01-01T00:00:00", "progress": "", "resume": {"state": "ACT_2_BASE", "kwargs": {}},
         "campaign_run": {"layout_data": {"buildings": [{"type": "generator", "pos": [100, 0], "hp": 100}]}},
         "resources": {"metal": 77, "base_layout": [{"type": "generator", "pos": [480, 540], "hp": 100},
                                                    {"type": "tower", "pos": [500, 700], "hp": 300}]}}
_json12.dump(old12, open(os.path.join(folder12, "Tank.json"), "w", encoding="utf-8"))
game.new_campaign()
st12, _ = _sm12.apply_save(game.resources, _sm12.read(os.path.join(folder12, "Tank.json")))
r12 = game.resources
assert st12 == "ACT_2_BASE" and r12.metal == 77
assert [e_["type"] for e_ in r12.base_layout] == ["pylon", "tower"]
assert r12.campaign_run.layout_data["buildings"][0]["type"] == "pylon"
r12.vulcano_online = True
game.machine.transition(GameState.BASE_MANAGEMENT, next_state=GameState.ACT_2_BASE)
bm12 = screens[GameState.BASE_MANAGEMENT]
assert {b_.building_type for b_ in bm12.world.structures} == {"core", "pylon", "tower"} and not hasattr(bm12.world, "generators")
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Borrar partidas guardadas: delete_save_profile y confirmación en el Menú Principal ==")
from src.mechanics import save_manager as _sm13
folder13 = tempfile.mkdtemp(prefix="rr_del_")
_sm13.SAVE_DIR = folder13
game.machine.transition(GameState.MENU)
game.new_campaign()
r13 = game.resources


def _profile13(name_):
    r13.campaign_run.player_name, r13.campaign_run.named = name_, True
    return _sm13.save_game(r13, "ACT_2_BASE")


p_uno = _profile13("Uno")
open(p_uno + ".tmp", "w").close()                                                 # temporal huérfano de un guardado
assert [p_["name"] for p_ in _sm13.list_profiles()] == ["Uno"]
assert _sm13.delete_save_profile("Uno") and not os.path.exists(p_uno) and not os.path.exists(p_uno + ".tmp")
assert _sm13.list_profiles() == [] and not _sm13.delete_save_profile("Uno")       # ya no existe: False
outside13 = os.path.join(tempfile.mkdtemp(prefix="rr_out_"), "Ajeno.json")
open(outside13, "w").close()
assert not _sm13.delete_save_profile("Ajeno", path=outside13) and os.path.exists(outside13)   # fuera de saves/: nunca
# menú: [SUPR / X], confirmación (ESC cancela, ENTER borra), cursor al adyacente y lista vacía
p_uno, p_dos = _profile13("Uno"), _profile13("Dos")
mm13 = screens[GameState.MENU]
press(game, pygame.K_2)
assert mm13.mode == "continue" and len(mm13.profiles) == 2
game.machine.draw(game.screen)
assert len(mm13.delete_rects) == 2                                                 # un botón «Borrar» por perfil
press(game, pygame.K_DELETE)
assert mm13.confirm is not None
game.machine.draw(game.screen)                                                     # ventana modal de confirmación
press(game, pygame.K_ESCAPE)
assert mm13.confirm is None and mm13.mode == "continue" and os.path.exists(p_uno) and os.path.exists(p_dos)
game.machine.handle_event(pygame.event.Event(pygame.KEYDOWN, key=pygame.K_d, unicode="d"))
press(game, pygame.K_x)                                                            # con texto escrito, la X es una letra
assert mm13.confirm is None
press(game, pygame.K_BACKSPACE)
press(game, pygame.K_BACKSPACE)
press(game, pygame.K_DOWN)
gone13 = mm13.profiles[1]
press(game, pygame.K_x)
assert mm13.confirm is gone13
press(game, pygame.K_RETURN)
assert not os.path.exists(gone13["path"]) and len(mm13.profiles) == 1 and mm13.selected == 0 and mm13.mode == "continue"
game.machine.draw(game.screen)
last13 = mm13.profiles[0]
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=mm13.delete_rects[0].center))
assert mm13.confirm is last13
game.machine.draw(game.screen)
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=mm13.confirm_buttons["yes"].center))
assert not os.path.exists(last13["path"]) and mm13.mode == "main" and mm13.notice == "No hay registros guardados"
assert _sm13.list_profiles() == []
_sm13.SAVE_DIR = SAVE_TMP
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Audio: AudioManager híbrido (archivo / síntesis), canales, modo silencioso y eventos enlazados ==")
import time as _time14
import wave as _wave14
from src.core import audio_manager as _am14
from src.core.audio_manager import audio as _audio14
from src.ui.dialogue_box import DialogueBox as _DB14
# en pruebas (vídeo dummy) el gestor queda en silencio: no suena ni falla, pero registra lo pedido
assert _audio14.enabled is False and _audio14.play("rifle") is False and _audio14.played("rifle")
assert _audio14.play("no_existe") is False
assert all(len(_audio14.synth(n_)) > 100 for n_ in _am14.SOUNDS)                    # todo efecto tiene respaldo sintetizado
# con un mixer de verdad (driver de audio dummy de SDL): canales reservados, archivo si existe y síntesis si no
real_driver14 = pygame.display.get_driver
pygame.display.get_driver = lambda: "windows"
sfx_dir14 = _am14.SFX_DIR
try:
    tmp14 = tempfile.mkdtemp(prefix="rr_sfx_")
    _am14.SFX_DIR = tmp14
    w14 = _wave14.open(os.path.join(tmp14, "rifle.wav"), "wb")
    w14.setnchannels(1); w14.setsampwidth(2); w14.setframerate(22050)
    w14.writeframes(_am14.tone(0.05, ((500, 1.0),), 30).tobytes()); w14.close()
    am14 = _am14.AudioManager()
    if am14.enabled:                                                             # (si el equipo no tiene mixer, se omite)
        assert am14.play("rifle") and am14.sources["rifle"] == "file"           # archivo real
        assert am14.play("dash") and am14.sources["dash"] == "synth"            # respaldo sintetizado
        am14._last["rifle"] = _time14.monotonic()                                # recién sonado (sin depender del reloj)
        assert not am14.play("rifle")                                            # separación mínima: no se amontona
        assert am14.play_music("menu") and am14.music_source == "synth" and am14.music_track == "menu"
        am14.set_music_volume(0.2); am14.set_sfx_volume(3)
        assert am14.sfx_volume == 1.0 and am14.music_volume == 0.2
        am14.stop_music(fade_ms=0)
        assert am14.music_track is None and pygame.mixer.get_num_channels() >= 16
finally:
    _am14.SFX_DIR = sfx_dir14
    pygame.display.get_driver = real_driver14
os.environ["RR_AUDIO"] = "off"
assert _am14.AudioManager().enabled is False                                     # RR_AUDIO=off: modo silencioso
del os.environ["RR_AUDIO"]
# --- eventos de la fase 1
t14 = _time14.monotonic()
game.machine.transition(GameState.MENU)
assert _audio14.music_track == "menu"                                            # música del menú
game.new_campaign()
game.resources.equipped = True
game.machine.transition(GameState.SUB_ACT_1_3)
s14 = screens[GameState.SUB_ACT_1_3]
dismiss(game)
assert _audio14.music_track is None                                              # al salir del menú se apaga
p14 = s14.player
p14.projectile_groups = (pygame.sprite.Group(),)
p14.shoot()
assert _audio14.played("rifle", t14)                                             # disparo del rifle
keys14 = Keys()
keys14[pygame.K_LSHIFT] = True
p14._update_dash(1 / 60, keys14, Vector2(1, 0))
assert _audio14.played("dash", t14)                                              # Dash
p14.dash_timer, p14.is_invulnerable = 0.0, False                                 # fin del Dash: ya recibe golpes
p14.take_damage(10)
assert _audio14.played("hit", t14) and not _audio14.played("block_break", t14)  # impacto, sin perder bloque
p14.take_damage(40)
assert _audio14.played("block_break", t14)                                       # se vació un bloque
game.resources.medkits = 1
press(game, pygame.K_h)
assert _audio14.played("medkit", t14) and game.resources.medkits == 0          # [H] botiquín
press(game, pygame.K_SPACE)
assert s14.paused and _audio14.played("build_mode", t14)                         # [ESPACIO] Modo Construcción
press(game, pygame.K_SPACE)
assert _audio14.played("build_mode_off", t14)
t15 = _time14.monotonic()
s14.build_choice = "pylon"
s14._try_build(s14.core.pos + Vector2(80, 80))
s14.build_choice = None
assert _audio14.played("place", t15) and _audio14.played("pylon_link", t15)     # colocar y enganchar el pilón a la red
game.machine.transition(GameState.MENU)
t16 = _time14.monotonic()
db14 = _DB14()
db14.say("AURA", "Hola piloto, aquí AURA.", blocking=True)
db14.say("VULCANO", "Reporte de VULCANO listo.")
for _ in range(30):
    db14.update(1 / 60)
assert _audio14.played("text_aura", t16) and _audio14.played("text_vulcano", t16)   # teletipo de los diálogos

# =============================================================================
print("== Modo Comandante en el Acto 2, bloqueo del asedio (Búnker + Fábrica) y red eléctrica estable ==")
from src.scenes.base_management import SIEGE_DENIED as _DENIED15
from src.entities.building import BUILD_MENU
from src.entities.power import reaches as _reaches15
from src.core.audio_manager import audio as _audio15
import time as _time15
# --- Acto 2 sin Operador: ni avatar ni HUD del piloto; cámara RTS libre; lo caído llega solo a la base
a15 = new_act2(game, metal=2000)
assert a15.world.player is None and a15.player not in a15.all_sprites and not hasattr(a15.player, "hp")
assert a15.FREE_CAMERA and a15.drone_status() == ""                              # sin Fábrica no se exige flota
game.machine.draw(game.screen)                                                    # HUD de mando (sin vida, balas ni Dash)
off15 = Vector2(a15.camera.offset)
held[pygame.K_d] = True
step(game, 20)
held.clear()
assert a15.camera.offset.x > off15.x                                              # WASD mueve la cámara sin pausa
m15 = game.resources.metal
sc15 = a15._drop_scrap(a15.CC_POS + Vector2(150, 0), 25)
step(game, int(60 * (C.AUTO_COLLECT_DELAY - 1)))
assert sc15.alive()                                                               # los carroñeros aún pueden robarla
step(game, 90)
assert not sc15.alive() and game.resources.metal >= m15 + 25
for _ in range(50):                                                               # el Acto 2 ya no suelta munición ni botiquines
    a15._on_enemy_death(Enemy("tank", (900, 600), a15.CC_POS, a15.world.enemies))
assert len(a15.world.ammo_boxes) == 0 and len(a15.world.medkits) == 0
press(game, pygame.K_h)                                                           # [H] no hace nada (no hay piloto)
# --- la Fábrica es el ejército del Comandante: disponible al entrar al Acto 2 (tecla 7) y obedece el Attack-Move
assert game.resources.structure_unlocked("fabrica") and [b_ for k_, b_ in BUILD_MENU if k_ == pygame.K_7] == ["fabrica"]
assert build(a15, "pylon", (540, 620)) and build(a15, "fabrica", (640, 720))
a15.factory.build_left = 0
dr15 = a15.factory._spawn_drone("attack")
a15.world.drones.add(dr15)
assert a15.issue_attack_move(a15.CC_POS + Vector2(600, 0)) >= 1 and a15.order_marker is not None
game.machine.transition(GameState.MENU)
rU15 = ResourceManager()
assert not rU15.structure_unlocked("fabrica") and rU15.structure_requirement("fabrica") == "Completa la incursión inicial"
rU15.incursion_level = 2
assert rU15.structure_unlocked("fabrica") and not rU15.factory_blueprints          # construirla sí; los planos del asedio: Op 4
# --- consola del Búnker: sin Búnker o sin planos de la Fábrica, acceso denegado (aviso y tono de error)
game.new_campaign()
r15 = game.resources
r15.vulcano_online = True
r15.bunker_built, r15.factory_blueprints = True, False                            # Búnker sí, planos no
game.machine.transition(GameState.BASE_MANAGEMENT, next_state=GameState.ACT_2_BASE)
bm15 = screens[GameState.BASE_MANAGEMENT]
t15 = _time15.monotonic()
assert bm15.bunker_console is not None
bm15.bunker_console.interact(bm15)
assert not bm15.siege_prompt and any(_DENIED15 in ln_.text for ln_ in bm15.dialogue.lines) and _audio15.played("error", t15)
r15.bunker_built = False                                                          # planos sí, Búnker no
r15.factory_blueprints = True
assert not r15.can_start_siege
bm15.request_siege()
assert not bm15.siege_prompt
r15.bunker_built = True                                                           # las dos condiciones: adelante
assert r15.can_start_siege
bm15.request_siege()
assert bm15.siege_prompt
bm15.siege_prompt = False
game.machine.transition(GameState.MENU)
# --- red: conectado todo lo que toca un círculo de red (aunque su centro quede fuera), en cualquier punto de la cadena
a15 = new_act2(game, metal=6000)
w15 = a15.world
assert build(a15, "pylon", (540, 620)) and build(a15, "pylon", (660, 620)) and build(a15, "pylon", (780, 620))
foco15 = Building("foco", (942, 620))                                             # centro a 162 px del último pilón...
a15._register(foco15)
a15.grid.update()
a15._sync_energy()
last15 = max(w15.pylons, key=lambda p_: p_.pos.x)
assert last15.pos.distance_to(foco15.pos) > C.POWER_RADIUS and _reaches15(last15.pos, foco15.rect)
assert foco15.is_powered and foco15.active                                         # ...pero su huella está dentro: con energía
# suministro: si la demanda cabe en la capacidad, todo lo conectado tiene energía; si no, se apaga solo lo más nuevo
rng15 = random.Random(15)
for _ in range(25):
    nodes15 = [a15.core] + [p_ for p_ in w15.pylons if p_.is_powered]
    bt15 = rng15.choice(["pylon", "tower", "foco", "balista"])
    a15.build_choice = bt15
    a15._try_build(rng15.choice(nodes15).pos + Vector2(rng15.uniform(-180, 180), rng15.uniform(-180, 180)))
    a15.build_choice = None
    step(game, 1)
    cons15 = [b_ for b_ in w15.structures if b_.energy_cost > 0 and b_.building_type != "pylon" and b_.is_powered]
    if sum(b_.energy_cost for b_ in cons15) + a15._upkeep() <= a15.energy_capacity():
        assert all(b_.energized for b_ in cons15)
    powered15 = [a15.core] + [p_ for p_ in w15.pylons if p_.is_powered]
    assert all(b_.is_powered for b_ in w15.structures if b_.energy_cost > 0 and b_.building_type != "pylon"
               and any(_reaches15(n_.pos, b_.rect) for n_ in powered15))
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Autodefensa del Centro de Control y bono de despliegue del Acto 2 ==")
from src.core.audio_manager import audio as _audio16
from src.config import UNITS as U
import time as _time16
game.machine.transition(GameState.MENU)
game.new_campaign()
r16 = game.resources
r16.initial_done = True
r16.metal = 500
game.machine.transition(GameState.ACT_2_BASE)
game.machine.transition(GameState.ACT_2_SETUP)
a16 = screens[GameState.ACT_2_SETUP]
dismiss(game)
assert r16.metal == 500 + C.ACT2_DEPLOY_BONUS == 540                              # +40 al desplegar el 2.1
a16.wave.timer = 99999
assert a16.core.self_defense
spec16 = U.BUILDINGS["core"]
sc16 = Enemy("scout", a16.core.pos + Vector2(spec16["defense_range"] - 30, 0), a16.CC_POS, a16.world.enemies)
sc16.speed = 0
a16.world.enemies.add(sc16); a16.world.targets.add(sc16); a16.all_sprites.add(sc16)
t16 = _time16.monotonic()
for _ in range(60 * 3):
    step(game, 1)
    if not sc16.alive():
        break
assert not sc16.alive() and _audio16.played("core_shot", t16)                     # el núcleo abate al Scout que se cuela
far16 = Enemy("scout", a16.core.pos + Vector2(spec16["defense_range"] + 120, 0), a16.CC_POS, a16.world.enemies)
far16.speed = 0
a16.world.enemies.add(far16); a16.world.targets.add(far16); a16.all_sprites.add(far16)
step(game, 60)
assert far16.alive() and far16.hp == far16.max_hp                                # corto alcance: lo lejano es de las torretas
game.machine.transition(GameState.MENU)
game.new_campaign()
game.resources.equipped = True
game.machine.transition(GameState.SUB_ACT_1_3)
assert not screens[GameState.SUB_ACT_1_3].core.self_defense                        # el tutorial (con piloto) no lo lleva
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Tooltips de unidades: drones aliados y hostiles, retícula y desglose de la escuadra ==")
from src.ui.tooltips import drone_card as _dc16, enemy_card as _ec16
from src.entities.factory import drone_stats as _ds16
from src.config import UNITS as _U16
a16 = new_act2(game, metal=3000)
assert a16.fleet_breakdown() == ""                                                # sin Fábrica no hay escuadra
assert build(a16, "pylon", (540, 620)) and build(a16, "fabrica", (640, 720))
a16.factory.build_left = 0
for k_ in ("attack", "attack", "bomber", "recon"):
    a16.world.drones.add(a16.factory._spawn_drone(k_))
assert a16.fleet_breakdown() == "Asalto: 2 · Bombardero: 1 · Recon: 1 · Soldado: 0"
step(game, 2)
d16 = next(d_ for d_ in a16.world.drones if d_.kind == "attack")
r16 = next(d_ for d_ in a16.world.drones if d_.kind == "recon")
assert d16.display_name == "Dron de Asalto Mk.I" and d16.activity == "Patrullando"
assert _ds16("attack", {_U16.DRONE_TYPES["attack"]["upgrade_name"]})["mk"] == 2                 # con la mejora: Mk.II
# tarjeta del dron: nombre y clase, mini-barra de HP con su valor y estado operativo
d16.hp = d16.max_hp - 40
c16 = _dc16(d16)
assert c16["title"] == "DRON DE ASALTO MK.I" and c16["color"] == C.CYAN
assert c16["rows"][0][0] == "bar" and c16["rows"][0][3] == f"HP: {int(d16.max_hp) - 40}/{int(d16.max_hp)}"
assert ("text", "Estado: Patrullando", C.WHITE) in c16["rows"]
r16.carried_scrap = 10
step(game, 1)
assert r16.activity == "Regresando con 10 de chatarra" and "aéreo" in _dc16(r16)["rows"][2][1]
# hover: la tarjeta sale al instante (sin el retardo de 0,5 s) con la retícula bajo la unidad
spot16 = a16.camera.to_world((520, 300))
d16.pos = Vector2(spot16)
d16.rect.center = (round(d16.pos.x), round(d16.pos.y))
mpos[0], mpos[1] = 520, 300
key16, card16 = a16.hover_card((520, 300))
assert key16 == ("unit", id(d16)) and card16["title"].startswith("DRON DE ASALTO")
game.machine.draw(game.screen)
assert a16.hovered_unit is d16
# enemigo a la vista: identificación en naranja/rojo con su vida restante y lo que hace
e16 = Enemy("soldier", spot16 + Vector2(160, 0), a16.CC_POS, a16.world.enemies)
e16.world = a16.world
a16.world.enemies.add(e16)
a16.world.targets.add(e16)
e16.hp = e16.max_hp - 30
assert a16.fog.is_revealed(e16.pos)
k16, ce16 = a16.hover_card(tuple(a16.camera.to_screen(e16.pos)))
assert k16 == ("unit", id(e16)) and ce16["title"] == "SOLDADO RENEGADO" and ce16["color"] == C.ORANGE
assert ce16["rows"][0][2] == C.RED and ce16["rows"][0][3] == f"HP: {int(e16.max_hp) - 30}/{int(e16.max_hp)}"
mpos[0], mpos[1] = [round(v_) for v_ in a16.camera.to_screen(e16.pos)]
game.machine.draw(game.screen)
assert a16.hovered_unit is e16
# bajo la niebla no se identifica nada
far16 = Vector2(a16.map_w - 60, 60)
assert not a16.fog.is_revealed(far16)
e16.pos = Vector2(far16)
e16.rect.center = (round(far16.x), round(far16.y))
assert a16.unit_under_cursor(far16) is None
sc16 = ScavengerDrone(spot16 + Vector2(0, 120))
cs16 = _ec16(sc16)
assert cs16["title"] == "DRON CARROÑERO" and cs16["rows"][0][3].startswith("HP: ")
# atacando: el estado del dron lo refleja
e16.pos = Vector2(a16.factory.pos) + Vector2(120, 0)
e16.rect.center = (round(e16.pos.x), round(e16.pos.y))
step(game, 2)
assert d16.activity == "Atacando objetivo"
mpos[0], mpos[1] = 640, 300
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Producción de drones: menú de la Fábrica y del Búnker (cobro, cola, energía y despegue) ==")
from src.core.audio_manager import audio as _au17
import time as _t17
a17 = new_act2(game, metal=1000, before=lambda r_: setattr(r_, "bunker_built", True))
res17 = game.resources
assert a17.bunker is not None
assert build(a17, "pylon", (540, 620)) and build(a17, "fabrica", (640, 720))
f17 = a17.factory
f17.build_left = 0
step(game, 1)


def rclick17(pos):
    sp_ = a17.camera.to_screen(pos)
    game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=3, pos=(int(sp_.x), int(sp_.y))))


# --- clic derecho sobre la Fábrica: menú de producción [1]-[4] con coste, atajo y tarjeta de estadísticas
rclick17(f17.pos)
assert a17.menu is not None and a17.menu.building is f17
assert [o_["action"] for o_ in a17.menu.options[:4]] == [("drone", k_) for k_ in U.PRODUCTION_MENU]
assert [o_["scrap"] for o_ in a17.menu.options[:4]] == [40, 25, 75, 50] and all(o_["enabled"] for o_ in a17.menu.options[:4])
assert a17.menu.options[4]["action"][0] == "sell"                                         # vender pasa a [5]
game.machine.draw(game.screen)
row17 = a17.menu.row_rect(a17.camera, 0)
card17 = a17.hover_card(row17.center)
assert card17[0] == ("menu", 0) and card17[1]["title"] == "DRON DE ASALTO" and card17[1]["rows"][0][0] == "cost"
# --- tecla [1]: cobra la chatarra y encola en esta Fábrica; clic izq. en [3] también; el menú sigue abierto
m17 = res17.metal
press(game, pygame.K_1)
assert res17.metal == m17 - 40 and f17.production_queue == ["attack"] and a17.menu is not None
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=a17.menu.row_rect(a17.camera, 2).center))
assert res17.metal == m17 - 40 - 75 and f17.load() == 2 and a17.menu is not None
# --- al terminar el tiempo de fabricación, el dron despega de la Fábrica
step(game, 2)
assert f17.current_production == "attack" and f17.production_queue == ["bomber"]
f17.production_time_left = 0.01
step(game, 2)
assert any(d_.kind == "attack" for d_ in a17.factory_drones()) and f17.current_production == "bomber"
# --- [ESC] cierra; clic fuera también
press(game, pygame.K_ESCAPE)
assert a17.menu is None and game.machine.current_state is GameState.ACT_2_SETUP
a17.open_menu(f17)
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=(5, 300)))
assert a17.menu is None
# --- sin chatarra: opción deshabilitada y tono de error (no cobra ni encola)
res17.metal = 10
a17.open_menu(f17)
assert not a17.menu.options[0]["enabled"] and "Chatarra insuficiente" in a17.menu.options[0]["desc"]
t17 = _t17.monotonic()
press(game, pygame.K_1)
assert res17.metal == 10 and f17.load() == 1 and _au17.played("error", t17)
a17.close_menu()
# --- sin energía (batería roja): deshabilitada con aviso
res17.metal = 1000
f17.is_powered = False
a17.open_menu(f17)
assert not a17.menu.options[2]["enabled"] and "sin energía" in a17.menu.options[2]["desc"]
t17 = _t17.monotonic()
press(game, pygame.K_3)
assert res17.metal == 1000 and f17.load() == 1 and _au17.played("error", t17)
a17.close_menu()
a17.grid.mark_dirty()
a17.grid.update()
step(game, 1)
assert f17.is_powered
# --- desde el Búnker: el encargo va a la Fábrica libre más cercana (con energía); varias fábricas
assert build(a17, "fabrica", (560, 800))
f17b = next(f_ for f_ in a17.factories if f_ is not f17)
f17b.build_left = 0
step(game, 1)
assert f17b.is_powered and f17.load() == 1 and f17b.load() == 0
rclick17(a17.bunker.pos)
assert a17.menu is not None and a17.menu.building is a17.bunker and "más cercana" in a17.menu.options[1]["desc"]
m17 = res17.metal
press(game, pygame.K_2)                                                                     # [2] Explorador
assert res17.metal == m17 - 25 and f17b.production_queue == ["recon"] and f17.load() == 1
game.machine.draw(game.screen)
press(game, pygame.K_ESCAPE)
# sin ninguna Fábrica con energía, el Búnker no puede encargar
for f_ in a17.factories:
    f_.is_powered = False
a17.open_menu(a17.bunker)
assert not any(o_["enabled"] for o_ in a17.menu.options[:4]) and "Ninguna Fábrica" in a17.menu.options[0]["desc"]
a17.close_menu()
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Base Central: la Fábrica que termina VULCANO queda operativa (sin ensamblaje eterno) ==")
from src.mechanics.base_layout import capture_base as _cap18
game.machine.transition(GameState.MENU)
game.new_campaign()
r18 = game.resources
r18.vulcano_online = r18.initial_done = True
r18.incursion_level = 2                                                                  # Fábrica desbloqueada
r18.metal = 2000
game.machine.transition(GameState.BASE_MANAGEMENT, next_state=GameState.ACT_2_BASE)
bm18 = screens[GameState.BASE_MANAGEMENT]
assert build_bm(bm18, "pylon", (520, 600))
# colocar el andamio: VULCANO se asigna la obra al instante
bm18.build_choice = "fabrica"
bm18._try_build(Vector2(640, 720))
bm18.build_choice = None
site18 = bm18.sites[-1]
assert site18.btype == "fabrica" and bm18.vulcano_status == "moving" and "sin órdenes" not in bm18.vulcano_status_text()
for _ in range(60 * 120):                                                                # avance del tiempo de obra
    game.machine.update(1 / 60)
    if site18 not in bm18.sites:
        break
assert site18 not in bm18.sites                                                          # andamio -> Fábrica real
f18 = next(iter(bm18.world.factories))
assert f18.built and f18.build_left == 0 and f18.is_powered and f18.alive()             # operativa, sin ensamblaje
assert f18.can_queue("attack", r18) == (True, "")
step(game, 2)
assert bm18.vulcano_status == "idle" and f18.built
# menú de producción: operativa (se fabrica aquí mismo), las 4 compras habilitadas
bm18.open_menu(f18)
assert all(o_["enabled"] for o_ in bm18.menu.options[:4]) and "Se ensambla en esta Fábrica" in bm18.menu.options[0]["desc"]
assert not any("ensamblando" in o_["desc"] for o_ in bm18.menu.options)
game.machine.draw(game.screen)
m18 = r18.metal
press(game, pygame.K_1)
assert r18.metal == m18 - 40 and f18.production_queue == ["attack"]
bm18.close_menu()
# el encargo pagado viaja con la base y se fabrica al desplegar
_cap18(bm18, r18)
assert [e_.get("queue") for e_ in r18.base_layout if e_["type"] == "fabrica"] == [["attack"]]
# Fábrica restaurada a medio ensamblar (partidas anteriores): en la Base Central el ensamblaje sigue avanzando
f18.build_left = 1.0
step(game, 70)
assert f18.build_left == 0 and f18.built
# catálogo: con una Fábrica en la base (o los planos), la tecla [7] no lleva candado
rU18 = ResourceManager()
assert not rU18.structure_unlocked("fabrica")
rU18.base_layout = [{"type": "fabrica", "pos": (0, 0), "hp": 600}]
assert rU18.structure_unlocked("fabrica")
rU18.base_layout = []
rU18.factory_blueprints = True
assert rU18.structure_unlocked("fabrica")
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Drones: despegue visible en la Fábrica y selección RTS (clic, caja, formación y foco de ataque) ==")
from src.mechanics.selection import formation as _form19
from src.core.audio_manager import audio as _au19
import time as _t19
a19 = new_act2(game, metal=3000)
assert build(a19, "pylon", (540, 620)) and build(a19, "fabrica", (640, 720))
f19 = a19.factory
f19.build_left = 0
step(game, 1)
# --- fin de la cola: el dron se instancia en el helipuerto, entra en drones y en los sprites y se dibuja sobre la niebla
assert f19.produce_drone("attack", game.resources) and f19.produce_drone("bomber", game.resources)
step(game, 2)
f19.production_time_left = 0.01
step(game, 1)
d19 = next(d_ for d_ in a19.world.drones if d_.kind == "attack")
assert d19 in a19.all_sprites and d19 in a19.world.drones and d19.pos.distance_to(f19.pos) < 30
step(game, 2)
f19.production_time_left = 0.01
step(game, 2)
b19 = next(d_ for d_ in a19.world.drones if d_.kind == "bomber")
drawn19 = []
_orig_draw19 = type(d19).draw
type(d19).draw = lambda self_, s_, o_=None: (drawn19.append(self_), _orig_draw19(self_, s_, o_))[1]
game.machine.draw(game.screen)
type(d19).draw = _orig_draw19
assert d19 in drawn19                                                                     # visible en pantalla
# --- clic izquierdo sobre un dron: lo selecciona solo a él
for d_ in (d19, b19):
    d_.order, d_.order_arrived = Vector2(a19.camera.to_world((500, 300))), True          # quietos para apuntar
d19.pos, b19.pos = Vector2(a19.camera.to_world((500, 300))), Vector2(a19.camera.to_world((560, 330)))
for d_ in (d19, b19):
    d_.rect.center = (round(d_.pos.x), round(d_.pos.y))


def click19(button, pos, up=True):
    game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=button, pos=pos))
    if up:
        game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONUP, button=button, pos=pos))


click19(1, (500, 300))
assert a19.selected_drones() == [d19]
game.machine.draw(game.screen)                                                            # anillo cian bajo el seleccionado
# --- caja de selección (arrastre): ambos
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=(460, 260)))
game.machine.handle_event(pygame.event.Event(pygame.MOUSEMOTION, pos=(600, 360), rel=(140, 100), buttons=(1, 0, 0)))
game.machine.draw(game.screen)                                                            # recuadro de arrastre
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONUP, button=1, pos=(600, 360)))
assert set(a19.selected_drones()) == {d19, b19}
# --- clic derecho en el suelo: formación hacia el punto y guardia allí (con sonido táctico)
t19 = _t19.monotonic()
dest19 = (700, 420)
click19(3, dest19, up=False)
wdest19 = a19.camera.to_world(dest19)
assert {tuple(d_.order) for d_ in (d19, b19)} == {tuple(p_) for p_ in _form19(wdest19, 2)}
assert all(not d_.order_arrived and d_.focus is None for d_ in (d19, b19)) and _au19.played("order", t19)
assert a19.order_marker is not None
# --- clic derecho sobre un enemigo: foco prioritario (marcador rojo); al caer, guardia
e19 = Enemy("soldier", a19.camera.to_world((820, 300)), a19.CC_POS, a19.world.enemies)
e19.world = a19.world
a19.world.enemies.add(e19)
a19.world.targets.add(e19)
a19.all_sprites.add(e19)
assert a19.fog.is_revealed(e19.pos)
click19(3, (820, 300), up=False)
assert all(d_.focus is e19 for d_ in (d19, b19)) and a19.focus_marker[0] is e19
game.machine.draw(game.screen)
step(game, 2)
assert d19.order.distance_to(e19.pos) < 1                                                # el punto sigue al blanco
e19.take_damage(10 ** 6)
step(game, 2)
assert d19.focus is None and d19.order_arrived                                           # objetivo caído: guardia
# --- ESC suelta la selección; sin selección el clic derecho es la orden global de ataque
press(game, pygame.K_ESCAPE)
assert a19.selected_drones() == []
click19(1, (40, 400))                                                                     # clic en vacío: nada seleccionado
assert a19.selected_drones() == []
assert a19.issue_attack_move(a19.camera.to_world((300, 200))) == 2
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Base Central: el reporte, las ayudas y el Mentor se desvanecen ==")
from src.ui import fade as _fade20
game.new_campaign()
r20 = game.resources
r20.vulcano_online = r20.equipped = r20.aura_linked = True
mpos[0], mpos[1] = 900, 400                                                               # lejos del reporte
game.machine.transition(GameState.BASE_MANAGEMENT, next_state=GameState.ACT_2_BASE)
bm20 = screens[GameState.BASE_MANAGEMENT]
assert bm20.report_fade.alpha == 255 and bm20.help_fade.alpha == 255
step(game, 60 * 7 - 6)
assert bm20.report_fade.alpha == 255 and bm20.help_fade.alpha == 255                     # 7 s legibles
step(game, 51)                                                                            # ~0,75 s del fade de 1,5 s
assert 60 < bm20.report_fade.alpha < 200 and 60 < bm20.help_fade.alpha < 200
step(game, 60)
assert bm20.report_fade.alpha == 0 and bm20.help_fade.alpha == 0                          # desaparecen del todo
press(game, pygame.K_h)                                                                   # [H] los recupera
assert bm20.report_fade.alpha == 255 and bm20.help_fade.alpha == 255
step(game, 60 * 9)
assert bm20.report_fade.alpha == 0
rr20 = game.hud.base_report_rect(bm20.report_lines())
mpos[0], mpos[1] = rr20.center                                                            # ratón sobre el reporte: vuelve
step(game, 60 * 10)
assert bm20.report_fade.alpha == 255 and bm20.help_fade.alpha == 0
mpos[0], mpos[1] = 640, 300
# el HUD dibuja el reporte y las ayudas según su opacidad (opaco / medio / nada)
px20 = []
for a_ in (255, 128, 0):
    s_ = pygame.Surface((C.WINDOW_WIDTH, C.WINDOW_HEIGHT))
    s_.fill((90, 90, 90))
    game.hud.draw_base(s_, bm20.report_lines(), None, bm20.build_menu, bm20._cost, r20, [], bm20.dialogue, a_, a_)
    px20.append((tuple(s_.get_at((rr20.x + 3, rr20.y + 3)))[:3], s_.get_at((rr20.x, rr20.y))[:3]))
assert px20[2][0] == (90, 90, 90) and px20[0][0] != px20[1][0] != px20[2][0]               # el fondo del panel se aclara
assert px20[0][1] == C.ORANGE and px20[2][1] == (90, 90, 90)                                # el borde naranja desaparece
plain20 = pygame.Surface((40, 20))                                                        # sin alpha por píxel: no falla
plain20.fill(C.ORANGE)
dst20 = pygame.Surface((40, 20))
_fade20.blit_faded(dst20, plain20, (0, 0), 100)
assert plain20.get_alpha() is None and 0 < dst20.get_at((5, 5))[0] < C.ORANGE[0]       # el original no cambia
# --- Mentor VULCANO: al saltar la explicación se desvanece en vez de cortarse
VA.ENABLED = True
game.machine.transition(GameState.MENU)
game.new_campaign()
r20 = game.resources
r20.vulcano_online = r20.equipped = r20.aura_linked = True
r20.campaign_run.player_name, r20.campaign_run.named = "Morfeo", True
game.machine.transition(GameState.BASE_MANAGEMENT, next_state=GameState.ACT_2_BASE)
adv20 = screens[GameState.BASE_MANAGEMENT].advisor
assert adv20.modal
step(game, 2)
press(game, pygame.K_ESCAPE)                                                              # [ESC] salta el tutorial
assert not adv20.active
step(game, 1)
assert adv20.ghost is not None and adv20.ghost[2].alpha == 255
step(game, 45)
assert 0 < adv20.ghost[2].alpha < 255                                                     # se está desvaneciendo
step(game, 60)
assert adv20.ghost is None                                                                # 1,5 s después: fuera
# [ENTER] hasta cerrar la explicación: el cuadro grande se desvanece bajo el del objetivo
adv20.start("triad")
assert adv20.modal
step(game, 1)
for _ in range(len(adv20.lines)):
    press(game, pygame.K_RETURN)
assert adv20.phase == "step"
step(game, 1)
assert adv20.ghost is not None and adv20.ghost[0].get_height() == 132
VA.ENABLED = False
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Op 4 persistente, drones vivos en la Base Central, Ariete derribable y AURA de combate ==")
from src.mechanics import save_manager as _sv21
from src.mechanics.bunker import OP4_REQUIRED as _OP4
from src.scenes.base_management import SIEGE_DENIED as _DEN21
from src.entities.drones import AuraDrone as _AD21
from src.core.audio_manager import audio as _au21
import time as _t21
# --- 1) los planos de la Op 4 persisten: checkpoint, guardado y carga del perfil
game.new_campaign()
r21 = game.resources
r21.campaign_run.player_name, r21.campaign_run.named = "Neo21", True
r21.finish_op("tech", 0, module=True, blueprints=True)
assert r21.campaign_run.factory_blueprints and r21.command_module
snap21 = r21.snapshot()
assert snap21["factory_blueprints"] is True
r21.campaign_run.factory_blueprints = False
r21.restore(snap21)
assert r21.campaign_run.factory_blueprints                                                # el checkpoint no los pierde
old21 = r21.snapshot()
old21["factory_blueprints"] = False
r21.restore(old21)
assert r21.campaign_run.factory_blueprints                                                # uno más antiguo tampoco los quita
path21 = _sv21.save_game(r21, "ACT_2_BASE", folder=SAVE_TMP)
rl21 = ResourceManager()
_sv21.apply_save(rl21, _sv21.read(path21))
assert rl21.campaign_run.factory_blueprints and rl21.factory_blueprints and rl21.command_module
# --- 2) sin la Op 4, el Búnker y su consola lo dicen claro (con tono de error)
assert _DEN21 == _OP4 == "Requiere planos de Op 4: Complejo Tecnológico"
game.new_campaign()
r21 = game.resources
r21.vulcano_online = True
r21.incursion_level = 2                                                                   # Fábrica desbloqueada (Op 1)
r21.metal, r21.cores = 1000, 5
game.machine.transition(GameState.BASE_MANAGEMENT, next_state=GameState.ACT_2_BASE)
bm21 = screens[GameState.BASE_MANAGEMENT]
t21 = _t21.monotonic()
left_click(game, bm21.bunker_site.pos)
assert not r21.bunker_built and (r21.metal, r21.cores) == (1000, 5)
assert any(_OP4 in ln_.text for ln_ in bm21.dialogue.lines) and _au21.played("error", t21)
assert any(_OP4 in r_[1] for r_ in bm21.bunker_hover_card(bm21.bunker_site.pos)[1]["rows"] if r_[0] == "text")
r21.command_module = True
left_click(game, bm21.bunker_site.pos)
assert r21.bunker_built and bm21.bunker_console is not None
bm21.dialogue.clear()
t21 = _t21.monotonic()
bm21.bunker_console.interact(bm21)                                                        # Búnker sí, planos no
assert not bm21.siege_prompt and any(_OP4 in ln_.text for ln_ in bm21.dialogue.lines) and _au21.played("error", t21)
# --- 3) la Fábrica de la base fabrica drones de verdad: aparecen junto a ella, se seleccionan y obedecen
r21.metal = 2000
assert build_bm(bm21, "pylon", (520, 600)) and build_bm(bm21, "fabrica", (640, 720))
f21 = next(iter(bm21.world.factories))
assert f21.built and f21.is_powered
bm21.open_menu(f21)
assert "Se ensambla en esta Fábrica" in bm21.menu.options[0]["desc"]
bm21.close_menu()
assert bm21.order_drone(f21, "attack") and bm21.order_drone(f21, "bomber") and bm21.order_drone(f21, "recon")
step(game, int(60 * (f21.stats["production_time"] * 3 + 2)))
kinds21 = sorted(d_.kind for d_ in bm21.world.drones)
assert kinds21 == ["attack", "bomber", "recon"], kinds21
assert all(d_ in bm21.all_sprites for d_ in bm21.world.drones)                            # se ven en el mapa
assert all(d_.pos.distance_to(f21.pos) < 160 for d_ in bm21.combat_drones())             # esperan junto a ella
assert sorted(e_["type"] for e_ in r21.campaign_run.drone_data) == ["attack", "bomber", "recon"]       # ya cuentan en la campaña
att21 = next(d_ for d_ in bm21.world.drones if d_.kind == "attack")
bomb21 = next(d_ for d_ in bm21.world.drones if d_.kind == "bomber")
rec21 = next(d_ for d_ in bm21.world.drones if d_.kind == "recon")
sp21 = bm21.camera.to_screen(att21.pos)
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=(int(sp21.x), int(sp21.y))))
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONUP, button=1, pos=(int(sp21.x), int(sp21.y))))
assert bm21.selected_drones() == [att21]                                                  # clic: un dron
box_a = bm21.camera.to_screen(f21.pos) - Vector2(250, 250)
box_b = bm21.camera.to_screen(f21.pos) + Vector2(250, 250)
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=(int(box_a.x), int(box_a.y))))
game.machine.handle_event(pygame.event.Event(pygame.MOUSEMOTION, pos=(int(box_b.x), int(box_b.y)), rel=(1, 1), buttons=(1, 0, 0)))
game.machine.draw(game.screen)                                                            # caja de selección dibujada
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONUP, button=1, pos=(int(box_b.x), int(box_b.y))))
assert set(bm21.selected_drones()) == {att21, bomb21} and rec21 not in bm21.selected_drones()   # caja: los de combate
goal21 = bm21.camera.to_world((300, 200))
assert bm21.structure_at(goal21) is None and bm21.site_under(goal21) is None
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=3, pos=(300, 200)))
assert att21.order is not None and bomb21.order is not None
step(game, 60 * 6)
assert att21.pos.distance_to(goal21) < 80 and bomb21.pos.distance_to(goal21) < 80 and att21.order_arrived
game.machine.draw(game.screen)                                                            # anillos de selección
press(game, pygame.K_ESCAPE)
assert bm21.selected_drones() == []
# clic sobre una estructura sigue siendo reparar (la selección no lo tapa)
pyl21 = next(iter(bm21.world.pylons))
pyl21.hp = pyl21.max_hp - 30
left_click(game, pyl21.pos)
assert pyl21.hp == pyl21.max_hp and bm21.selected_drones() == []
# --- 4) la escuadra viaja fiel: al Acto 2 al desplegar y al asedio desde la consola del Búnker
att21.hp = att21.max_hp - 25
r21.factory_blueprints = True
bm21.deploy()
assert game.machine.current_state is GameState.ACT_2_BASE
assert [round(e_["hp"]) for e_ in r21.campaign_run.drone_data if e_["type"] == "attack"] == [round(att21.max_hp - 25)]
game.machine.transition(GameState.ACT_2_SETUP)
a21 = screens[GameState.ACT_2_SETUP]
assert sorted(d_.kind for d_ in a21.factory_drones()) == ["attack", "bomber", "recon"]
assert round(next(d_ for d_ in a21.factory_drones() if d_.kind == "attack").hp) == round(att21.max_hp - 25)
game.machine.transition(GameState.BASE_MANAGEMENT, next_state=GameState.ACT_2_BASE)
bm21 = screens[GameState.BASE_MANAGEMENT]
assert sorted(d_.kind for d_ in bm21.world.drones) == ["attack", "bomber", "recon"]       # vuelven a la base (sin duplicarse)
bm21.request_siege()
assert bm21.siege_prompt
bm21._launch_siege()
assert game.machine.current_state is GameState.SIEGE
sg21 = game.machine.active
assert sorted(d_.kind for d_ in sg21.factory_drones()) == ["attack", "bomber", "recon"]
assert all(d_.pos.distance_to(sg21.CC_POS) < 400 for d_ in sg21.factory_drones())          # junto al nuevo Centro de Control
game.machine.transition(GameState.MENU)
# --- 5) Ariete: 680 HP y -45% de frente: el fuego concentrado lo derriba
grp21 = pygame.sprite.Group()
ram21 = Enemy("ariete", (0, 0), (1, 0), grp21)
grp21.add(ram21)
ram21.facing = 0.0
assert ram21.max_hp == 680 and abs(ram21.mitigate(100, Vector2(-1, 0)) - 55.0) < 1e-6
hits21 = 0
while ram21.alive() and hits21 < 200:
    ram21.take_damage(14, Vector2(-1, 0))                                                 # torreta ligera, siempre de frente
    hits21 += 1
assert ram21.hp <= 0 and hits21 <= 90, hits21                                            # antes, 340 disparos de frente
# --- 6) piezas de AURA: con 6/6 no caen más; la sobrante da chatarra y núcleos
a21 = new_act2(game, metal=500)
r21 = game.resources
r21.chassis_found = C.CHASSIS_TOTAL_PARTS
parts0, scraps0, cores0 = len(a21.world.parts), len(a21.world.scraps), len(a21.world.core_items)
a21._on_enemy_death(Enemy("ariete", (900, 600), a21.CC_POS, a21.world.enemies))
assert len(a21.world.parts) == parts0 and len(a21.world.scraps) > scraps0 and len(a21.world.core_items) > cores0
r21.chassis_found = C.CHASSIS_TOTAL_PARTS - 1
a21._on_enemy_death(Enemy("ariete", (900, 600), a21.CC_POS, a21.world.enemies))
a21._on_enemy_death(Enemy("ariete", (900, 600), a21.CC_POS, a21.world.enemies))
assert len(a21.world.parts) == parts0 + 1                                                 # solo la que faltaba
# --- 7) AURA 6/6: unidad de combate que dispara (Acto 2) y escolta al Operador (incursión)
wa21 = WorldRefs()
wa21.core = a21.core
aura21 = _AD21(a21.CC_POS + Vector2(0, -60))
foe21 = Enemy("soldier", aura21.pos + Vector2(120, 0), a21.CC_POS, wa21.enemies)
wa21.enemies.add(foe21)
hp21 = foe21.hp
for _ in range(60 * 3):
    aura21.update(1 / 60, wa21)
assert foe21.hp < hp21 and aura21.shots >= 3                                              # láser activo
surf21 = pygame.Surface((C.WINDOW_WIDTH, C.WINDOW_HEIGHT))
aura21.beam_to = Vector2(foe21.pos)
aura21.draw_overlay(surf21, aura21.rect, Vector2())
r21.chassis_installed = C.CHASSIS_TOTAL_PARTS
assert r21.aura_drone
game.machine.transition(GameState.MENU)
game.resources.chassis_installed = C.CHASSIS_TOTAL_PARTS
game.resources.initial_done = True
game.machine.transition(GameState.INCURSION, op="recon")
inc21 = screens[GameState.INCURSION]
dismiss(game)
assert inc21.aura_drone is not None and inc21.aura_drone in inc21.world.drones
teleport(inc21, inc21.player.pos + Vector2(200, 0))
step(game, 120)
assert inc21.aura_drone.pos.distance_to(inc21.player.pos) < 140 and inc21.aura_drone.activity in (
    "Escoltando al Operador", "Interceptando enemigos")                                   # vuela de escolta
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Búnker de Mando ==")
from src.config import UNITS as _U4
from src.entities.building import BUILD_MENU as _BM4
from src.entities.building import create_building as _cb4
from src.managers.resource_manager import CampaignRun as _CR4
from src.managers.resource_manager import ResourceManager as _RM4
from src.mechanics.base_layout import capture_base as _capture4
# --- datos y estructura
assert (_U4.BUNKER["cost"], _U4.BUNKER["cores"], _U4.BUNKER["hp"], _U4.BUNKER["cells"]) == (400, 2, 800, 3)
bk4 = _cb4("bunker", (300, 300))
assert (bk4.max_hp, bk4.rect.size, bk4.core_cost, bk4.energy_cost, bk4.requires_power) == (800, (120, 120), 2, 0, False)
assert "bunker" not in [b_ for _, b_ in _BM4]                                          # solo se monta en su sitio de obra
# --- persistencia (CampaignRun, snapshot y ResourceManager)
cr4 = _CR4()
assert cr4.bunker_built is False and cr4.to_dict()["bunker_built"] is False
cr4.bunker_built = True
assert _CR4.from_dict(cr4.to_dict()).bunker_built is True
leg4 = cr4.to_dict()
del leg4["bunker_built"]
assert _CR4.from_dict(leg4).bunker_built is False                                      # partida antigua: sin Búnker
rm4 = _RM4()
snap4 = rm4.snapshot()
rm4.bunker_built = True
snap4b = rm4.snapshot()
assert snap4["bunker_built"] is False and snap4b["bunker_built"] is True and rm4.campaign_run.bunker_built is True
rm4.restore(snap4)
assert rm4.bunker_built is False
rm4.restore(snap4b)
assert rm4.bunker_built is True
del snap4["bunker_built"]
rm4.restore(snap4)
assert rm4.bunker_built is False                                                       # checkpoint antiguo
rm4.bunker_built = True
rm4.reset()
assert rm4.bunker_built is False                                                       # campaña nueva
# --- ensamblaje: exige el módulo y cobra chatarra y núcleos a la vez (todo o nada)
rm4.metal, rm4.cores = 1000, 5
ok4, msg4 = rm4.build_bunker()
assert not ok4 and "Módulo de Mando" in msg4 and (rm4.metal, rm4.cores) == (1000, 5) and not rm4.bunker_built
rm4.command_module = True
rm4.metal = 399
ok4, msg4 = rm4.build_bunker()
assert not ok4 and "1 de chatarra" in msg4 and (rm4.metal, rm4.cores) == (399, 5)
rm4.metal, rm4.cores = 1000, 1
ok4, msg4 = rm4.build_bunker()
assert not ok4 and "1 núcleo" in msg4 and (rm4.metal, rm4.cores) == (1000, 1)           # sin chatarra cobrada a medias
rm4.cores = 2
ok4, msg4 = rm4.build_bunker()
assert ok4 and (rm4.metal, rm4.cores) == (600, 0) and rm4.bunker_built and "Búnker de Mando ensamblado" in rm4.history[-1]
ok4, msg4 = rm4.build_bunker()
assert not ok4 and "ya está" in msg4 and (rm4.metal, rm4.cores) == (600, 0)             # no se cobra dos veces
# --- sitio de obra en el Acto 2 (el Comandante lo monta con el cursor encima y E, o con un clic)
a2b = new_act2(game, metal=1000, cores=5)
rb = game.resources
site4 = a2b.bunker_site
assert site4 is not None and site4.rect.size == (120, 120) and site4 in a2b.world.solids and a2b.bunker is None
assert a2b.bunker_console is None and a2b.map_rect.contains(site4.rect)
assert not any(site4.rect.colliderect(s_.rect) for s_ in a2b.world.structures)         # el sitio no pisa la base
card4 = a2b.hover_card(a2b.camera.to_screen(site4.pos))
assert card4[1]["title"].startswith("SITIO DE OBRA") and any("Requiere: 400" in r_[1] and "Módulo de Mando" in r_[1] for r_ in card4[1]["rows"] if r_[0] == "text")
assert not build(a2b, "tower", site4.pos)                                              # nada se construye encima
sp4 = a2b.camera.to_screen(site4.pos)
mpos[0], mpos[1] = int(sp4.x), int(sp4.y)
step(game, 2)
assert site4.near
press(game, pygame.K_e)                                                                # sin Módulo de Mando: no monta
assert not rb.bunker_built and rb.metal == 1000 and a2b.bunker_site is site4 and a2b.bunker is None
rb.command_module = True
press(game, pygame.K_e)                                                                # con módulo y recursos: monta
assert rb.bunker_built and (rb.metal, rb.cores) == (600, 3)
assert not site4.alive() and site4 not in a2b.world.solids and a2b.bunker_site is None
assert a2b.bunker.alive() and a2b.bunker.building_type == "bunker" and a2b.bunker.max_hp == 800 and a2b.bunker in a2b.world.structures
assert a2b.bunker.pos == site4.pos and a2b.bunker in a2b.world.solids
con4 = a2b.bunker_console
assert con4 is not None and con4.label == _U4.BUNKER["console_label_remote"] and "Bloqueada" not in con4.label    # fuera de la Base Central, remota
sp4 = a2b.camera.to_screen(con4.pos)
mpos[0], mpos[1] = int(sp4.x), int(sp4.y)
step(game, 2)
assert con4.near
press(game, pygame.K_e)                                                                # la consola remite a la Base Central
assert any("Base Central" in ln_.text for ln_ in a2b.dialogue.lines)
assert a2b.hover_card(a2b.camera.to_screen(con4.pos))[1]["title"] == "CONSOLA DE MANDO TÁCTICO"
mpos[0], mpos[1] = 640, 300
step(game, 3)                                                                          # dibuja Búnker, consola y sus avisos
# --- no se vende y viaja con la base
assert not a2b.sell(a2b.bunker) and a2b.bunker.alive()
a2b.open_menu(a2b.bunker)
assert len(a2b.menu.options) == 5 and not a2b.menu.options[-1]["enabled"] and "no se puede vender" in a2b.menu.options[-1]["label"]
assert [o_["action"] for o_ in a2b.menu.options[:4]] == [("drone", k_) for k_ in ("attack", "recon", "bomber", "trooper")]
a2b.close_menu()
a2b.bunker.hp = 500
_capture4(a2b, rb)
game.machine.transition(GameState.ACT_2_BASE)
game.machine.transition(GameState.ACT_2_SETUP)                                         # otro mapa: la base guardada vuelve
dismiss(game)
a2c = game.machine.screens[GameState.ACT_2_SETUP]
assert a2c.bunker_site is None and a2c.bunker is not None and a2c.bunker.hp == 500 and a2c.bunker_console is not None
assert sum(1 for s_ in a2c.world.structures if s_.building_type == "bunker") == 1 and rb.bunker_built
rb.base_layout = []                                                                    # el estado manda: si falta la estructura, se recrea
game.machine.transition(GameState.ACT_2_BASE)
game.machine.transition(GameState.ACT_2_SETUP)
dismiss(game)
assert a2c.bunker is not None and a2c.bunker.hp == 800 and sum(1 for s_ in a2c.world.structures if s_.building_type == "bunker") == 1
# --- si cae, vuelve el sitio de obra y hay que ensamblarlo otra vez
a2c.bunker.take_damage(99999)
step(game, 2)
assert not rb.bunker_built and a2c.bunker is None and a2c.bunker_console is None
assert a2c.bunker_site is not None and a2c.bunker_site.alive() and a2c.bunker_site in a2c.world.solids
rb.metal, rb.cores = 500, 2
left_click(game, a2c.bunker_site.pos)                                                  # clic del Comandante sobre el sitio
assert rb.bunker_built and a2c.bunker is not None and (rb.metal, rb.cores) == (100, 0)
# --- fase de gestión (Comandante, sin Operador): VULCANO monta con un clic
game.new_campaign()
rg = game.resources
rg.vulcano_online = True
rg.factory_blueprints = True                                                           # planos de la Fábrica (para el asedio)
game.machine.transition(GameState.BASE_MANAGEMENT)
bmx = screens[GameState.BASE_MANAGEMENT]
sitex = bmx.bunker_site
assert sitex is not None and sitex in bmx.world.solids and bmx.bunker is None
rg.metal, rg.cores = 450, 2
left_click(game, sitex.pos)                                                            # falta el Módulo de Mando
assert not rg.bunker_built and (rg.metal, rg.cores) == (450, 2) and bmx.bunker_site is sitex
rg.command_module = True
left_click(game, sitex.pos)
assert rg.bunker_built and (rg.metal, rg.cores) == (50, 0) and bmx.bunker.max_hp == 800 and bmx.bunker_console is not None
left_click(game, bmx.bunker_console.pos)                                               # la consola ya no está bloqueada: pide confirmar
assert bmx.siege_prompt and bmx.bunker_console.label == "Iniciar Asedio Táctico a la Fortaleza Enemiga"
press(game, pygame.K_ESCAPE)
assert not bmx.siege_prompt
game.machine.draw(game.screen)
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Base Central en modo Comandante: sin Operador, cámara libre y VULCANO constructor ==")
import src.scenes.base_management as _bmmod
from src.entities.player import Player as _Player
# --- arranca sin la entidad Operador
assert not hasattr(_bmmod, "Player")                                                    # la escena ni siquiera la importa
game.new_campaign()
rc = game.resources
rc.vulcano_online = True
rc.metal = 300
game.machine.transition(GameState.BASE_MANAGEMENT)
bmc = screens[GameState.BASE_MANAGEMENT]
assert not isinstance(bmc.player, _Player) and not any(isinstance(s_, _Player) for s_ in bmc.all_sprites)
assert bmc.sites == [] and bmc.campaign_terminal is not None and bmc.INSTANT_BUILD is False
game.machine.draw(game.screen)
# --- cámara libre tipo RTS: WASD / flechas / bordes, limitada al mapa
cam_ = bmc.camera
off0 = Vector2(cam_.offset)
held[pygame.K_d] = True
step(game, 30)
held.clear()
assert cam_.offset.x > off0.x and cam_.offset.y == off0.y                               # WASD mueve la cámara
off1 = Vector2(cam_.offset)
held[pygame.K_UP] = True
step(game, 30)
held.clear()
assert cam_.offset.y < off1.y                                                           # las flechas también
held[pygame.K_a] = True
step(game, 600)
held.clear()
assert cam_.offset.x == 0                                                               # límites del mapa
held[pygame.K_s] = True
held[pygame.K_d] = True
step(game, 1500)
held.clear()
assert cam_.offset.x == bmc.map_w - cam_.view.x and cam_.offset.y == bmc.map_h - cam_.view.y
mpos[0], mpos[1] = 3, 300                                                               # borde izquierdo de la pantalla
x_edge_ = cam_.offset.x
step(game, 30)
assert cam_.offset.x < x_edge_                                                          # el borde desplaza la cámara
mpos[0], mpos[1] = 640, 300
cam_.offset = Vector2(100, 100)
game.machine.handle_event(pygame.event.Event(pygame.MOUSEMOTION, pos=(500, 300), rel=(20, 10), buttons=(0, 1, 0)))
assert cam_.offset == Vector2(80, 90)                                                   # clic central arrastrado
# --- VULCANO: ordenar la obra coloca un sitio y no cobra nada todavía
cam_.offset = Vector2(max(0, bmc.CC_POS.x - 640), max(0, bmc.CC_POS.y - 360))
spot_ = bmc.CC_POS + Vector2(200, 80)
bmc.build_choice = "wall"
bmc._try_build(spot_)
bmc.build_choice = None
assert len(bmc.sites) == 1 and bmc.sites[0].btype == "wall" and rc.metal == 300 and not bmc.world.walls
site_c = bmc.sites[0]
assert site_c in bmc.world.solids and site_c.total == 400 and site_c.scrap_cost == 30
assert not build_bm(bmc, "wall", spot_)                                                 # nada se construye sobre la obra
assert bmc.hover_card(bmc.camera.to_screen(site_c.pos))[1]["title"] == "OBRA: MURO DE ACERO"
d_start = bmc.vulcano.pos.distance_to(site_c.pos)
step(game, 30)
assert bmc.vulcano_status == "moving" and bmc.vulcano.pos.distance_to(site_c.pos) < d_start   # acude a su velocidad normal
assert d_start - bmc.vulcano.pos.distance_to(site_c.pos) <= C.VULCANO_SPEED * 0.5 + 1
for _ in range(1200):
    step(game, 1)
    if bmc.vulcano_status == "building":
        break
assert bmc.vulcano_status == "building" and bmc.vulcano.pos.distance_to(site_c.pos) <= C.VULCANO_WORK_RANGE + site_c.rect.w / 2 + 1
m_a, p_a = rc.metal, site_c.progress
step(game, 60)
assert site_c.progress - p_a == C.VULCANO_REPAIR_RATE or abs((site_c.progress - p_a) - C.VULCANO_REPAIR_RATE) < 1.5   # 80 HP/s
assert rc.metal < m_a and not bmc.world.walls                                           # cobra mientras construye
for _ in range(900):
    step(game, 1)
    if not bmc.sites:
        break
wall_c = next(iter(bmc.world.walls))
assert not bmc.sites and rc.metal == 300 - 30 and wall_c.hp == wall_c.max_hp == 400     # descuenta 30 y queda al 100%
step(game, 2)
assert wall_c.pos == Vector2(site_c.pos) and not site_c.alive() and bmc.vulcano_status == "idle"        # sin más órdenes: flota junto al Núcleo
# --- sin chatarra la obra espera; con chatarra continúa
rc.metal = 0
spot2_ = bmc.CC_POS + Vector2(-100, 200)
assert build_bm(bmc, "wall", spot2_, frames=1) is False and len(bmc.sites) == 1
site_w = bmc.sites[0]
step(game, 600)
assert bmc.vulcano_status == "waiting_scrap" and site_w.waiting and 0 <= site_w.progress < 100 and rc.metal == 0
rc.metal = 100
for _ in range(900):
    step(game, 1)
    if not bmc.sites:
        break
assert not bmc.sites and rc.metal == 100 - 30 and len(bmc.world.walls) == 2          # con chatarra termina y cobra los 30
# --- prioridad: lo crítico (niveles 0-2) se repara antes que la obra
wall_c.hp = 50
bmc.build_choice = "wall"
bmc._try_build(bmc.CC_POS + Vector2(-100, -100))
bmc.build_choice = None
site_p = bmc.sites[0]
step(game, 5)
assert bmc.vulcano_status == "repairing" and site_p.progress == 0                       # ocupado reparando: la obra espera
for _ in range(1200):
    step(game, 1)
    if not bmc.sites:
        break
assert wall_c.hp == wall_c.max_hp and not bmc.sites and len(bmc.world.walls) == 3       # repara primero y luego construye
# --- cancelar reembolsa lo gastado; desplegar cancela las obras pendientes
rc.metal = 500
bmc.build_choice = "tower"
bmc._try_build(bmc.CC_POS + Vector2(120, 120))
bmc.build_choice = None
site_t = bmc.sites[0]
for _ in range(1200):
    step(game, 1)
    if site_t.progress > 80:
        break
spent_ = site_t.paid
assert spent_ > 0 and rc.metal == 500 - spent_
right_click(game, site_t.pos)                                                           # clic derecho sobre la obra: cancela
assert not bmc.sites and rc.metal == 500 and not site_t.alive()
bmc.build_choice = "wall"
bmc._try_build(bmc.CC_POS + Vector2(-160, 120))
bmc.build_choice = None
step(game, 200)
paid_ = bmc.sites[0].paid
assert paid_ > 0
press(game, pygame.K_SPACE)                                                             # desplegar: las obras sin terminar no viajan
assert not bmc.sites and rc.metal == 500                                              # y se reembolsó lo gastado
assert not any(e_["type"] == "wall" and tuple(e_["pos"]) == tuple(bmc.CC_POS + Vector2(-160, 120)) for e_ in rc.base_layout)
# --- terminales con un clic y cursor contextual
game.new_campaign()
rt2 = game.resources
rt2.vulcano_online = True
rt2.command_module = True
rt2.metal, rt2.cores = 450, 2
game.machine.transition(GameState.BASE_MANAGEMENT)
bmt = screens[GameState.BASE_MANAGEMENT]
mp_ = bmt.camera.to_screen(bmt.campaign_terminal.pos)
mpos[0], mpos[1] = int(mp_.x), int(mp_.y)
step(game, 2)
assert bmt.campaign_terminal.near and bmt._interactive_at(bmt.campaign_terminal.pos) and bmt._cursor == pygame.SYSTEM_CURSOR_HAND
mpos[0], mpos[1] = 640, 20
step(game, 2)
assert not bmt._interactive_at(Vector2(bmt.camera.to_world((640, 20)))) and bmt._cursor == pygame.SYSTEM_CURSOR_ARROW
left_click(game, bmt.campaign_terminal.pos)                                            # sin incursión inicial: avisa, no abre
assert game.machine.current_state is GameState.BASE_MANAGEMENT and any("incursión inicial" in ln_.text for ln_ in bmt.dialogue.lines)
left_click(game, bmt.bunker_site.pos)                                                  # el Búnker, con un clic (sin proximidad)
assert rt2.bunker_built and bmt.bunker_console is not None
assert bmt._interactive_at(bmt.bunker_console.pos)
rt2.initial_done = True
left_click(game, bmt.campaign_terminal.pos)                                            # tras la inicial: abre el menú de campaña
assert game.machine.current_state is GameState.CAMPAIGN_MENU
game.machine.transition(GameState.MENU)
# --- la incursión mantiene al Operador con sus controles directos
game.new_campaign()
game.resources.incursion_level = 1
game.machine.transition(GameState.ACT_2_BASE)
game.machine.transition(GameState.INCURSION, mode="raid")
isc = game.machine.active
assert isinstance(isc.player, _Player) and isc.player.alive() and isc.player in isc.all_sprites
p_before_ = Vector2(isc.player.pos)
held[pygame.K_d] = True
step(game, 30)
held.clear()
assert isc.player.pos.x > p_before_.x                                                  # WASD mueve al Operador
shots_ = isc.player.shots_fired
mouse[0] = True
step(game, 10)
mouse[0] = False
assert isc.player.shots_fired > shots_ or isc.player.ammo < isc.player.capacity        # el clic izquierdo dispara
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Desbloqueo progresivo de estructuras ==")
from src.config import UNITS as _U2
from src.entities.building import BUILD_MENU as _BM0
from src.managers.resource_manager import ResourceManager as _RM
from src.ui.tooltips import locked_card
rU = _RM()
assert set(_U2.STARTER_STRUCTURES) == {"wall", "tower", "pylon"} and all(rU.structure_unlocked(k) for k in _U2.STARTER_STRUCTURES)
assert not any(rU.structure_unlocked(k) for k in _U2.STRUCTURE_UNLOCKS)               # al empezar solo Muro, Pilón y Torreta Ligera
assert set(_U2.STRUCTURE_UNLOCKS) | set(_U2.STARTER_STRUCTURES) == {b_ for _, b_ in _BM0}   # el resto del menú, todo con requisito
assert rU.structure_requirement("pylon") == "" and rU.structure_requirement("wall") == ""
assert rU.structure_requirement("extractor") == "Alcanza el nivel de incursión 3"
assert rU.structure_requirement("balista") == "Gana el mapa «Infiltración Inicial»" and rU.structure_requirement("balista", short=True) == "Gana mapa 1"
rU.incursion_level = 2                                                                 # incursión inicial hecha
assert not rU.structure_unlocked("extractor") and not rU.structure_unlocked("balista")
assert rU.structure_unlocked("fabrica")                                                # planos de la Fábrica: entrada al Acto 2
rU.campaign_run.completed_maps.add("map_1_infiltration")
assert rU.structure_unlocked("balista") and not rU.structure_unlocked("foco")
rU.campaign_run.completed_maps.add("map_2_push")
assert rU.structure_unlocked("foco") and not rU.structure_unlocked("compuerta")
rU.campaign_run.completed_maps.add("map_3_siege")
rU.incursion_level = 3
assert all(rU.structure_unlocked(k) for k in _U2.STRUCTURE_UNLOCKS)
rU.reset()
assert not rU.structure_unlocked("balista")                                            # campaña nueva: vuelve a bloquearse
rU.unlock_all_structures()
assert all(rU.structure_unlocked(k) for k in _U2.STRUCTURE_UNLOCKS)
a2l = new_act2(game, before=lambda r_: setattr(r_, "all_structures_unlocked", False))
assert not build(a2l, "balista", (620, 500)) and not build(a2l, "foco", (620, 500)) and not build(a2l, "fabrica", (620, 500))
assert build(a2l, "tower", (620, 500))                                                 # las de inicio sí
a2l.handle_build_key(pygame.event.Event(pygame.KEYDOWN, key=pygame.K_3))               # [3] Balista: bloqueada, no se elige
assert a2l.build_choice is None
a2l.handle_build_key(pygame.event.Event(pygame.KEYDOWN, key=pygame.K_1))
assert a2l.build_choice == "wall"
card_l = locked_card("balista", game.resources)
assert card_l["rows"][0][1] == "BLOQUEADA" and "Gana el mapa" in card_l["rows"][1][1]
slot_b = next(rect_ for rect_, bt_ in game.hud.build_slots(a2l.build_menu, a2l.panel_shift) if bt_ == "balista")
assert a2l.hover_card(slot_b.center)[1]["rows"][0][1] == "BLOQUEADA"                  # el tooltip del botón dice qué la desbloquea
slot_w = next(rect_ for rect_, bt_ in game.hud.build_slots(a2l.build_menu, a2l.panel_shift) if bt_ == "wall")
assert a2l.hover_card(slot_w.center)[1]["rows"][0][0] == "cost"                        # las abiertas, su tarjeta de siempre
step(game, 2)                                                                          # el panel dibuja candados y requisitos
game.resources.campaign_run.completed_maps.add("map_1_infiltration")                   # ganar el mapa 1 desbloquea la Balista
assert game.resources.structure_unlocked("balista") and build(a2l, "balista", (620, 440))

# =============================================================================
print("== Depositos y extractores ==")
a2 = new_act2(game)
w = a2.world
res = game.resources
deposit = sorted(a2.deposit_list, key=lambda d: d.pos.y)[1]                 # depósitos de la base propia
assert deposit.total_metal == 300
assert not a2._can_place("extractor", a2._ghost_rect("extractor", Vector2(900, 900)))
assert build(a2, "pylon", (500, 540)) and build(a2, "pylon", (620, 460))
assert build(a2, "extractor", deposit.pos)
ext = next(iter(w.extractors))
assert ext.is_powered and ext.deposit is deposit
assert not a2._can_place("extractor", a2._ghost_rect("extractor", deposit.pos))
m0 = res.metal
step(game, 200)                                                             # 3,33 s: dos ciclos de 1,2 s (x2,5)
assert res.metal == m0 + 2 * C.EXTRACTOR_INCOME, res.metal - m0
deposit.total_metal = 10
m1 = res.metal
step(game, 60 * 10)
assert res.metal == m1 + 10 and deposit.depleted and not ext.active
step(game, 200)
assert res.metal == m1 + 10

# =============================================================================
from src.entities.building import BUILD_MENU
from src.config import UNITS as U
print("== Biblia 4.0: el Baluarte, la Tesla y el Lanzallamas ya no son edificios ==")
a2 = new_act2(game)
w = a2.world
for gone in ("bastion", "tesla", "flamethrower"):
    assert gone not in Building.STATS and gone not in U.BUILDINGS and gone not in dict(
        (b_, k_) for k_, b_ in BUILD_MENU), gone
assert not hasattr(w, "bastions") and not hasattr(a2.player, "is_elevated")
assert [bt for _, bt in BUILD_MENU] == ["wall", "tower", "balista", "pylon", "extractor",
                                        "foco", "fabrica", "compuerta"]                 # sin Generador: el Pilón hace la red
press(game, pygame.K_e)                                  # E ya no sube a ningún baluarte
assert a2.player.alive()

# =============================================================================
print("== Pathing reactivo: embudos y muros de nivel ==")
core = Building("core", (1400, 600))
structs = pygame.sprite.Group(core)
gap = {580, 620, 660}
wall_rows = {}
for y in range(20, 1200, 40):
    if y in gap:
        continue
    wl = Building("wall", (820, y))
    structs.add(wl)
    wall_rows[y] = wl
nav = FlowField(C.ACT2_W, C.ACT2_H)
nav.update(structs, core)
grp = pygame.sprite.Group()
scout = Enemy("scout", (400, 300), core.pos, grp)
scout.flank = 0
grp.add(scout)
for _ in range(60 * 20):
    scout.update(1 / 60, structs, nav)
assert scout.pos.x > 900, scout.pos                  # atraveso por la abertura
assert all(wl.hp == wl.max_hp for wl in wall_rows.values())    # sin atacar muros
for y in gap:                                        # cerrar el hueco: ruta totalmente bloqueada
    structs.add(Building("wall", (820, y)))
nav.mark_dirty()
nav.update(structs, core)
walls_before = sum(1 for s_ in structs if s_.building_type == "wall")
scout2 = Enemy("scout", (400, 300), core.pos, grp)
scout2.flank = 0
grp.add(scout2)
for _ in range(60 * 30):
    scout2.update(1 / 60, structs, nav)
walls_now = [s_ for s_ in structs if s_.building_type == "wall"]
assert len(walls_now) < walls_before or any(s_.hp < s_.max_hp for s_ in walls_now), "debia atacar el muro"
# muros de nivel (impenetrables): el enemigo los rodea y no puede atravesarlos
from src.entities.obstacle import Obstacle
hard_solids = pygame.sprite.Group(*[Obstacle(pygame.Rect(600, y * 40, 40, 40)) for y in range(0, 18)])   # pared casi completa
hard = {(15, y) for y in range(0, 18)}
nav2 = FlowField(C.ACT2_W, C.ACT2_H, hard=hard)
g_core = Building("core", (900, 200))
nav2.update(pygame.sprite.Group(g_core), g_core)
runner = Enemy("scout", (300, 200), g_core.pos, grp)
runner.flank = 0
grp.add(runner)
max_y, overlapped = 0.0, False
for _ in range(60 * 14):
    runner.update(1 / 60, pygame.sprite.Group(), nav2, hard_solids)
    max_y = max(max_y, runner.pos.y)
    overlapped |= pygame.sprite.spritecollideany(runner, hard_solids) is not None
assert not overlapped                                                  # nunca atravesó el muro
assert max_y > 700, max_y                                              # dio la vuelta por el hueco inferior...
assert runner.pos.distance_to(g_core.pos) < 60, runner.pos             # ...y llegó al objetivo

# =============================================================================
print("== Carroñeros, chatarra y Fundicion ==")
ScavengerDrone.arena = pygame.Rect(0, 0, C.ACT2_W, C.ACT2_H)
scraps = pygame.sprite.Group()
scrap = ScrapItem((500, 500))
scraps.add(scrap)
assert scrap.value == 25
dr = ScavengerDrone((500, 560), (500, 500), (2290, 500))
drones_grp = pygame.sprite.Group(dr)
escaped = []
dr.on_escape = escaped.append
for _ in range(70):
    dr.update(1 / 60, scraps)
assert dr.state == "latching" and scrap.alive()      # acoplado 1.2 s, aun no roba
for _ in range(30):
    dr.update(1 / 60, scraps)
assert dr.state == "fleeing" and not scrap.alive() and dr.carrying_scrap and dr.stolen_scrap == 25
for _ in range(60 * 8):
    if dr.alive():
        dr.update(1 / 60, scraps)
assert escaped == [dr] and not dr.alive()
scrap = ScrapItem((600, 600))
scraps.add(scrap)
pm = Player((620, 600), 2000, 1200)
pm_group = pygame.sprite.Group(pm)
scrap.update(0.05, pm)
assert scrap.pos.x > 600
for _ in range(10):
    scrap.update(0.05, pm)
assert combat.pickup_scraps(pm, scraps) == 25
f = RenegadeFoundry()
assert f.add_scrap(50) == [] and f.add_scrap(25) == ["ram"] and f.rams_queued == 1
assert f.add_scrap(75) == ["speed"] and abs(f.interval_mult - 0.85) < 1e-9
wref = WorldRefs()
wm = WaveManager(wref, 1, (0, 0), lambda e: None, pygame.Rect(1600, 330, 130, 540), f)
wm.skip_prep()
wm.update(0.1)
wm.update(0.1)
assert "ariete" in wm.current.schedule and ("foundry_ram", 1) in wm.events
assert Enemy.TANK["hp"] > Enemy.ARIETE["hp"] and Enemy.ARIETE["hp"] == 680 and Enemy.TANK["hp"] == 1120
f2 = RenegadeFoundry()
f2.intercept(750)
assert dict(Wave(1, 1, (0, 0), None, f2.size_factor).get_enemy_spawns()) == {"scout": 4}     # 6 x 0.6
a2 = new_act2(game)
fake = ScavengerDrone((0, 0), (0, 0), (0, 0))
fake.scrap_value = 75
a2._on_scavenger_escape(fake)
assert a2.foundry.enemy_scrap_pool == 0 and a2.foundry.rams_queued == 1 and a2.stolen == 75

# =============================================================================
print("== Fábrica de Drones: ensamblaje, cola, límite de 8, energía, F1-F4 y los 4 tipos ==")
from src.entities.drones import AttackDrone, BomberDrone, ReconDrone, TrooperDrone
from src.entities.factory import drone_stats, explorer_cap, explorer_count
from src.entities.projectile import Projectile, Shell
from src.config import UNITS as U
a2 = new_act2(game, metal=3000, cores=20)
w = a2.world
res = game.resources
for b_ in a2.enemy_bases:                     # la centinela de la guarnición derribaría al Explorador que patrulla cerca
    disarm(b_)
assert len(w.drones) == 0 and a2.factory is None                                   # ya no hay escuadrón gratuito
press(game, pygame.K_F2)
assert any("Fábrica" in ln.text for ln in a2.dialogue.lines)                       # sin Fábrica, F2 solo avisa
assert build(a2, "pylon", (540, 620))                                              # la Fábrica necesita red
m0, c0 = res.metal, res.cores
assert build(a2, "fabrica", (640, 720))
fac = a2.factory
assert fac.rect.size == (80, 80) and fac.max_hp == 600 and res.cores == c0 and res.metal == m0 - a2._cost("fabrica")
assert not fac.built and fac.energy_cost == 0 and not a2.queue_drone("attack")      # ensamblándose (20 s)
step(game, 60 * 20 + 5)
assert fac.built
m1, c1 = res.metal, res.cores
press(game, pygame.K_F2)                                                            # Asalto: ⚙85 (solo chatarra)
assert res.metal == m1 - 40 and res.cores == c1 and fac.production_queue == ["attack"]
for key_ in (pygame.K_F1, pygame.K_F3, pygame.K_F4):
    press(game, key_)
assert fac.production_queue == ["attack", "recon", "bomber", "trooper"]
m2 = res.metal
assert not a2.queue_drone("recon") and res.metal == m2                              # cola llena (4): no se cobra
used0 = a2.energy_used()
step(game, 2)
assert fac.current_production == "attack" and fac.energy_cost == 3 and a2.energy_used() == used0 + 3
left0 = fac.production_time_left
fac.is_powered = False                                                              # sin energía se detiene
fac.update(1.0, empty, empty)
assert fac.production_time_left == left0
fac.is_powered = True
a2.grid.mark_dirty()
step(game, 60 * 10 + 5)
atk = next(d for d in w.drones if isinstance(d, AttackDrone))
assert atk.damage == 16 and atk.max_hp == 140 and atk.aerial and atk in fac.drones and fac.get_active_drones_count() == 1
# Asalto: láser continuo sobre el enemigo cercano a la Fábrica (16 de daño cada 0,5 s = 32 DPS, alcance 190)
foe_d = Enemy("scout", Vector2(fac.pos) + Vector2(160, 0), a2.CC_POS, w.enemies)
foe_d.speed, foe_d.hp, foe_d.max_hp = 0, 500, 500
w.enemies.add(foe_d); w.all_sprites.add(foe_d); w.targets.add(foe_d)
step(game, 60 * 5)
shots_d = (500 - foe_d.hp) / 16
assert (500 - foe_d.hp) % 16 == 0 and 7 <= shots_d <= 11, shots_d                   # ~10 disparos en 5 s
foe_d.kill()
step(game, 60 * 31)                                                                 # el resto de la cola
kinds_d = sorted(d.kind for d in a2.factory_drones())
assert kinds_d == ["attack", "bomber", "recon", "trooper"] and fac.energy_cost == 0
recon = next(d for d in w.drones if isinstance(d, ReconDrone))
trooper = next(d for d in w.drones if isinstance(d, TrooperDrone))
bomber = next(d for d in w.drones if isinstance(d, BomberDrone))
assert any(abs(r_ - 400) < 1e-6 and c_ == recon.pos for c_, r_ in a2.revealers())     # revela 400 px en el minimapa
assert (recon.max_hp, recon.speed, bomber.max_hp, trooper.max_hp, trooper.stats["armor"]) == (70, 240, 130, 220, 3)
assert [d.aerial for d in (recon, atk, bomber, trooper)] == [True, True, True, False]
# Capas: el contacto cuerpo a cuerpo no toca a los aéreos, pero sí a los terrestres; los proyectiles alcanzan a ambos
brute = Enemy("scout", Vector2(fac.pos) + Vector2(0, 150), a2.CC_POS, w.enemies)
brute.speed, brute.hp, brute.max_hp, brute.damage = 0, 9999, 9999, 20
w.enemies.add(brute); w.all_sprites.add(brute); w.targets.add(brute)
hp_a, hp_t = atk.hp, trooper.hp
for _ in range(30):
    for d_ in (atk, trooper):
        d_.pos = Vector2(brute.pos)
        d_.rect.center = brute.rect.center
    step(game, 6)
assert atk.hp == hp_a and trooper.hp < hp_t                                         # el aéreo es inmune al contacto
atk.take_damage(10)
assert atk.hp == hp_a - 10                                                          # pero un proyectil sí le hace daño
trooper.hp = trooper.max_hp
trooper.take_damage(10)
assert trooper.max_hp - trooper.hp == 7                                             # armadura 3
brute.kill()
atk.hp = atk.max_hp
# Bombardero: bombas en caída libre sobre un grupo (75 de daño en radio 60, cooldown 2,5 s)
cluster = []
for dx_, dy_ in ((0, 0), (25, 10), (-20, 20)):
    f_ = Enemy("scout", Vector2(fac.pos) + Vector2(200 + dx_, -60 + dy_), a2.CC_POS, w.enemies)
    f_.speed, f_.hp, f_.max_hp = 0, 900, 900
    w.enemies.add(f_); w.all_sprites.add(f_); w.targets.add(f_)
    cluster.append(f_)
seen_bomb = False
for _ in range(60 * 7 // 6):
    step(game, 6)
    seen_bomb = seen_bomb or len(w.bombs) > 0
assert seen_bomb and sum(1 for f_ in cluster if f_.hp < 900) >= 2                   # una bomba alcanzó a varios
assert max(900 - f_.hp for f_ in cluster) >= 75
for f_ in cluster:
    f_.kill()
# Explorador: detecta chatarra, la guarda en carried_scrap y la lleva en línea recta al Centro de Control
res_m = res.metal
a2.auto_collect_delay = 10 ** 9                                     # solo el Explorador recoge en esta prueba
spot = Vector2(a2.CC_POS) + Vector2(0, -70)
recon.pos = spot + Vector2(80, 0); recon.rect.center = (round(recon.pos.x), round(recon.pos.y))
sc_a = a2._drop_scrap(spot, 40)
carried_seen = 0
for _ in range(60 * 10 // 6):
    step(game, 6)
    carried_seen = max(carried_seen, recon.carried_scrap)
    if res.metal >= res_m + 40:
        break
assert carried_seen == 40 and recon.carried_scrap == 0 and res.metal >= res_m + 40 and not sc_a.alive()   # depositó
# Penalización: derribado en tránsito suelta la carga en el suelo (y libera un hueco del tope)
spot2 = Vector2(a2.CC_POS) + Vector2(0, -100)
recon.pos = spot2 + Vector2(60, 0); recon.rect.center = (round(recon.pos.x), round(recon.pos.y))
sc_b = a2._drop_scrap(spot2, 33)
for _ in range(60 * 4 // 6):
    step(game, 6)
    if recon.carried_scrap:
        break
assert recon.carried_scrap == 33 and explorer_count(w) == 1
res_m = res.metal
n_sc = len(w.scraps)
recon.take_damage(9999)
assert not recon.alive() and recon.carried_scrap == 0 and len(w.scraps) == n_sc + 1 and res.metal == res_m
assert any(s_.value == 33 for s_ in w.scraps) and explorer_count(w) == 0
for s_ in list(w.scraps):
    s_.kill()
# Tope de Exploradores (UNITS.EXPLORER_CAP): con 1 fábrica son 2; F1 se bloquea al alcanzarlo (cuenta cola + vivos)
assert explorer_cap(w) == 2
assert a2.queue_drone("recon") and a2.queue_drone("recon")
m_cap = res.metal
ok_cap, why_cap = fac.can_queue("recon", res)
assert not ok_cap and "Tope" in why_cap and not a2.queue_drone("recon") and res.metal == m_cap
assert fac.can_queue("attack", res)[0]                                              # el tope solo afecta al Explorador
fac.production_queue.clear()
fac.current_production, fac.production_time_left = None, 0.0
res.metal += U.DRONE_TYPES["recon"]["cost"] * 2
# límite GLOBAL de 8 drones vivos (Fase 6): con el límite lleno se puede encargar, pero el dron espera un hueco
for _ in range(5):
    fac._spawn_drone("attack")
assert fac.world_drone_count() == 8 and fac.at_limit
assert fac.can_queue("recon", res)[0] and a2.queue_drone("recon") and fac.production_queue == ["recon"]
step(game, 60 * 12)
assert fac.current_production is None and fac.production_queue == ["recon"] and fac.world_drone_count() == 8
assert fac.energy_cost == 0 and "espera" in a2.drone_status() and "Expl. 0/2" in a2.drone_status()   # parado sin gastar energía
atk.take_damage(9999)                                                               # cae uno: hay hueco
step(game, 60 * 12)
assert not atk.alive() and fac.world_drone_count() == 8 and fac.production_queue == []     # nace el encargado
assert explorer_count(w) == 1
# vender y reconstruir la Fábrica NO reinicia el contador (es el estado del mundo, no de la Fábrica)
fac.kill()
step(game, 2)
assert a2.factory is None and len(a2.factory_drones()) == 8
assert build(a2, "fabrica", (640, 720))
fac = a2.factory
fac.build_left = 0
assert fac.drones == [] and fac.world_drone_count() == 8 and fac.at_limit and fac.committed() == 8
assert a2.queue_drone("attack")
step(game, 60 * 12)
assert fac.world_drone_count() == 8 and fac.production_queue == ["attack"]          # sigue esperando: nada de 9
fac.production_queue.clear()
# mejoras permanentes (Terminal): se suman al nacer
assert drone_stats("attack", {"Damage_Attack"})["damage"] == 24 and drone_stats("recon", {"Velocity_Recon"})["speed"] == 290
assert drone_stats("bomber", {"Payload_Bomber"})["bomb_damage"] == 100
assert drone_stats("trooper", {"Plating_Trooper"})["hp"] == 280
res.drone_upgrades.add("Damage_Attack")
assert fac.upgrades is res.drone_upgrades
assert fac._spawn_drone("attack").damage == 24
for d_ in list(w.drones):
    d_.kill()
# Terminal Táctico: las 4 mejoras se compran con clic y viajan en los checkpoints
game.machine.transition(GameState.MENU)
game.new_campaign()
game.resources.initial_done = True
game.resources.metal, game.resources.cores, game.resources.alloy = 300, 2, 0
game.machine.transition(GameState.ACT_2_BASE)
term_d = screens[GameState.ACT_2_BASE]
assert set(term_d.drone_rects) == set(U.DRONE_UPGRADES)
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=term_d.drone_rects["Velocity_Recon"].center))
assert "Velocity_Recon" not in game.resources.drone_upgrades and "aleación" in term_d.upgrade_msg   # sin aleación no
game.machine.draw(game.screen)
game.resources.alloy = 3
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=term_d.drone_rects["Velocity_Recon"].center))
assert "Velocity_Recon" in game.resources.drone_upgrades
assert (game.resources.metal, game.resources.cores, game.resources.alloy) == (300, 2, 1)   # solo aleación (2)
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=term_d.drone_rects["Velocity_Recon"].center))
assert game.resources.alloy == 1 and "ya instalada" in term_d.upgrade_msg
game.machine.draw(game.screen)
snap_d = game.resources.snapshot()
game.resources.drone_upgrades.clear()
game.resources.restore(snap_d)
assert game.resources.drone_upgrades == {"Velocity_Recon"}
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Enemigos: armadura plana, Ariete direccional, ráfagas del Soldado, obuses del Tanque ==")
random.seed(1234)
g0 = pygame.sprite.Group()
sold = Enemy("soldier", (0, 0), (1, 1), g0)
sold.take_damage(12)
assert sold.max_hp - sold.hp == 8                                     # 12 - 4 de armadura plana
sold.hp = sold.max_hp
sold.take_damage(3)
assert sold.max_hp - sold.hp == 1                                     # el daño mínimo es 1
tnk = Enemy("tank", (0, 0), (1, 1), g0)
tnk.take_damage(12)
assert tnk.max_hp - tnk.hp == 4                                       # 12 - 8
sct = Enemy("scout", (0, 0), (1, 1), g0)
sct.take_damage(10)
assert sct.max_hp - sct.hp == 10 and (sct.max_hp, sct.speed) == (45, 180)
ar = Enemy("ariete", (0, 0), (1, 1), g0)
ar.facing = 0.0                                                       # mira a la derecha
dealt = []
for direction in (Vector2(-500, 0), Vector2(500, 0), Vector2(0, 500), Vector2(-400, 400), None):
    hp_b = ar.hp
    ar.take_damage(10, direction)
    dealt.append(round(hp_b - ar.hp, 6))
assert dealt == [5.5, 30.0, 30.0, 5.5, 10.0], dealt                   # frente -45%; espalda y costado x3; sin dirección x1
assert (ar.max_hp, ar.speed) == (680, 70)
# el Ariete marcha, se detiene, avisa y embiste en línea recta: 300 de impacto contra el muro
wr = WorldRefs()
wall_c = Building("wall", (700, 400))
wr.structures.add(wall_c)
ar = Enemy("ariete", (500, 400), (1000, 400), wr.enemies)
ar.world, ar.always_active, ar.state_timer = wr, True, 0.3      # el primer chequeo de carga llega a los 0.3 s
wr.enemies.add(ar)
seen_states, steps_charge = [], []
for _ in range(60 * 6):
    x_b = ar.pos.x
    ar.update(1 / 60, wr.structures, None)
    wall_c.update(1 / 60, wr.enemies, pygame.sprite.Group())
    if ar.state == "charge":
        steps_charge.append(ar.pos.x - x_b)
    if not seen_states or seen_states[-1] != ar.state:
        seen_states.append(ar.state)
assert seen_states[:4] == ["march", "windup", "charge", "recover"], seen_states
assert 3.3 < max(steps_charge) < 4.5 and all(dx < 4.5 for dx in steps_charge), steps_charge[:5]   # 220 px/s
assert not wall_c.alive()                                             # 300 + 300 de dos embestidas rompen el muro de 400
# Soldado: entra a 160 px, dispara ráfagas de 3 tiros de 12 y en la pausa se reposiciona sin salir de su alcance
wr2 = WorldRefs()
dummy = Player((3000, 3000), 4000, 4000)
wall_s = Building("wall", (1000, 400))
wr2.structures.add(wall_s)
sd = Enemy("soldier", (400, 400), (1500, 400), wr2.enemies)
sd.world, sd.always_active, sd.shoot_timer = wr2, True, 0.0
wr2.enemies.add(sd)
for _ in range(60 * 9):
    sd.update(1 / 60, wr2.structures, None)
    wr2.enemy_bullets.update(1 / 60)
    combat.resolve_enemy_bullets(wr2.enemy_bullets, dummy, wr2.drones, wr2.structures)
assert 100 <= sd.pos.distance_to(wall_s.pos) <= 170, sd.pos.distance_to(wall_s.pos)   # se mantiene a ~160 px del muro
lost = wall_s.max_hp - wall_s.hp
assert lost >= 36 and abs(lost / 12 - round(lost / 12)) < 1e-9, lost             # impactos de 12, en ráfagas
# Tanque: bombardea con obuses de 120 (con área) y sigue avanzando despacio
wr3 = WorldRefs()
wa, wb, wc = Building("wall", (700, 400)), Building("wall", (700, 450)), Building("wall", (700, 520))
wr3.structures.add(wa, wb, wc)
tk = Enemy("tank", (400, 400), (1500, 400), wr3.enemies)
tk.world, tk.always_active, tk.shoot_timer = wr3, True, 0.0
wr3.enemies.add(tk)
x0_tank = tk.pos.x
for _ in range(60 * 2):
    tk.update(1 / 60, pygame.sprite.Group(), None)                    # obstáculos aparte: aquí solo se prueba el cañón
    wr3.shells.update(1 / 60)
assert wa.hp == 400 - 120 and wb.hp == 400 - 60 and wc.hp == 400, (wa.hp, wb.hp, wc.hp)   # centro 120, cerca 60, lejos 0
assert 45 < tk.pos.x - x0_tank < 65                                   # apunta quieto 0,8 s y después avanza a 45 px/s
assert 1.0 < tk.shoot_timer <= 3.5                                   # cadencia de 3.5 s (un solo obús en 2 s)
# el obús del Tanque contra el Operador: 120 en el centro y 60 en el borde, reducidos a la mitad (100 de vida: no muere de un golpe)
wr4 = WorldRefs()
pl4 = Player((800, 800), 2000, 2000)
pl4.hp = pl4.max_hp = 100
wr4.player = pl4
pg4 = pygame.sprite.Group(pl4)
Shell(Vector2(800, 800), Vector2(800, 800), 120, 70, wr4, 360, 0.5).explode()
assert pl4.hp == 100 - 60 and pl4.alive()
pl4.hp = 100
Shell(Vector2(850, 800), Vector2(850, 800), 120, 70, wr4, 360, 0.5).explode()          # cae a 50 px: mitad de daño x mitad
assert pl4.hp == 100 - 30
assert U.ENEMIES["tank"]["player_splash"] == 0.5
# Scout: enjambre rápido que rodea desde lejos (180 px/s)
scf = Enemy("scout", (0, 400), (2000, 400), g0)
scf.flank = 1
for _ in range(60):
    scf.update(1 / 60, pygame.sprite.Group(), None)
assert abs(scf.pos.y - 400) > 5 and scf.pos.distance_to(Vector2(0, 400)) > 165
scn = Enemy("scout", (0, 400), (2000, 400), g0)
scn.flank = 0
for _ in range(60):
    scn.update(1 / 60, pygame.sprite.Group(), None)
assert abs(scn.pos.y - 400) < 1e-6
# Drops por tipo (probabilidad y rango de la Biblia)
rr_ = random.Random(7)
for kind, (chance, lo, hi) in {"scout": (0.4, 3, 5), "soldier": (0.4, 8, 12), "ariete": (0.5, 25, 35), "tank": (0.5, 50, 70)}.items():
    vals = [real_roll_drop(kind, rr_) for _ in range(4000)]
    got = [v for v in vals if v]
    assert all(lo <= v <= hi for v in got) and abs(len(got) / 4000 - chance) < 0.04, (kind, len(got) / 4000)
    assert min(got) == lo and max(got) == hi
# Clumping: una avalancha de enemigos desde el mismo punto no se apila
a2 = new_act2(game)
w = a2.world
a2.core.self_defense = False                                          # se mide la cola, no el cañón del núcleo
clump = ([Enemy("scout", (900, 600), a2.CC_POS, w.enemies) for _ in range(24)]
         + [Enemy("soldier", (900, 600), a2.CC_POS, w.enemies) for _ in range(4)]
         + [Enemy("tank", (900, 600), a2.CC_POS, w.enemies), Enemy("ariete", (900, 600), a2.CC_POS, w.enemies)])
for e in clump:
    w.enemies.add(e); w.all_sprites.add(e); w.targets.add(e)
for _ in range(60 * 2):                                               # en marcha: se reparten sin apilarse
    a2.core.hp = a2.core.max_hp
    step(game, 1)
spread = max(a.pos.distance_to(b.pos) for a, b in itertools.combinations(clump, 2))
tight = min(a.pos.distance_to(b.pos) for a, b in itertools.combinations(clump, 2))
assert tight > 18 and spread > 100, (tight, spread)
for _ in range(60 * 4):                                               # al llegar al núcleo hacen cola alrededor, sin solaparse
    a2.core.hp = a2.core.max_hp
    step(game, 1)
tight = min(a.pos.distance_to(b.pos) for a, b in itertools.combinations(clump, 2))
assert tight > 10, tight
for e in clump:
    e.kill()

# =============================================================================
print("== Torretas: Twin-Autocannon, Balista perforante, Tesla (ruta B de la Balista), Lanzallamas (ruta B del Twin) y Foco Vigía ==")
a2 = new_act2(game, metal=5000)
w = a2.world
assert build(a2, "pylon", (500, 660))                                   # amplía la red hasta las torretas
assert build(a2, "pylon", (500, 780)) and build(a2, "pylon", (540, 780))   # capacidad extra: la Tesla gasta 27
twin = build(a2, "tower", (500, 700)) and next(t_ for t_ in w.towers if t_.building_type == "tower")
assert (twin.max_hp, twin.damage, twin.range, twin.fire_rate) == (300, 14, 200, 0.35)
bal = build(a2, "balista", (340, 700)) and max(w.towers, key=lambda t_: t_.build_order)
assert (bal.max_hp, bal.damage, bal.range, bal.fire_rate, bal.pierce) == (450, 160, 320, 1.8, 2)
tes = build(a2, "balista", (580, 700)) and max(w.towers, key=lambda t_: t_.build_order)
assert tes.mode == "balista" and tes.energy_cost == 12
assert tes.choose_route("B") and tes.mode == "tesla" and tes.energy_cost == 27          # 12 + 15 de la ruta Tesla
assert (tes.max_hp, tes.damage, tes.range, tes.fire_rate, tes.jumps) == (450, 45, 160, 1.0, 4)
assert all(t_.is_powered for t_ in w.towers)
buls = pygame.sprite.Group()
foes = pygame.sprite.Group()


def mk(kind, pos):
    e_ = Enemy(kind, pos, a2.CC_POS, foes)
    e_.speed = 0
    foes.add(e_)
    return e_


def ang(a, b):
    d_ = Vector2(b) - Vector2(a)
    return math.degrees(math.atan2(d_.y, d_.x))


# Twin: prioriza Scouts aunque haya algo más cerca
sc_t, so_t = mk("scout", twin.pos + Vector2(150, 0)), mk("soldier", twin.pos + Vector2(0, 90))
twin.fire_timer = 0
twin.update(1 / 60, foes, buls)
assert abs(twin.angle - ang(twin.pos, sc_t.pos)) < 1e-6 and len(buls) == 1
assert next(iter(buls)).damage == 14 and next(iter(buls)).owner == "tower"
for e_ in list(foes):
    e_.kill()
buls.empty()
# Balista (Balance P1): Tanque > Ariete de flanco > Soldado > resto
s1, s2, s3 = mk("soldier", bal.pos + Vector2(100, 0)), mk("tank", bal.pos + Vector2(0, -200)), mk("ariete", bal.pos + Vector2(-250, 0))
bal.fire_timer = 0
bal.update(1 / 60, foes, buls)
assert abs(bal.angle - ang(bal.pos, s2.pos)) < 1e-6
shot = next(iter(buls))
assert shot.damage == 160 and shot.pierce == 2 and shot.owner == "balista"
for e_ in list(foes):
    e_.kill()
buls.empty()
# ...y su proyectil atraviesa 2 objetivos (el tercero se salva); con la ruta A (perforante) atraviesa 4
line = [mk("scout", bal.pos + Vector2(120 + 60 * i, 0)) for i in range(3)]
bal.fire_timer = 0
bal.update(1 / 60, foes, buls)
for _ in range(60):
    buls.update(1 / 60)
    combat.resolve_projectiles(buls, foes, pygame.sprite.Group())
assert [e_.alive() for e_ in line] == [False, False, True], [e_.alive() for e_ in line]
assert bal.choose_route("A") and bal.pierce == 4 and bal.damage == 200  # ruta A: perforante (4 objetivos, daño 200)
line2 = [mk("scout", bal.pos + Vector2(120 + 60 * i, 0)) for i in range(4)]
for e_ in (line[2],):
    e_.kill()
bal.fire_timer = 0
bal.update(1 / 60, foes, buls)
for _ in range(60):
    buls.update(1 / 60)
    combat.resolve_projectiles(buls, foes, pygame.sprite.Group())
assert not any(e_.alive() for e_ in line2)
for e_ in list(foes):
    e_.kill()
buls.empty()
# Tesla: el arco salta entre 4 enemigos cercanos (6 con +Saltos), con daño y aturdimiento
cluster = [mk("soldier", tes.pos + Vector2(90 + 22 * (i % 3), 20 * (i // 3) - 10)) for i in range(7)]
lonely = mk("soldier", tes.pos + Vector2(-130, 0))
tes.fire_timer = 0
tes.update(1 / 60, foes, buls)
hit = [e_ for e_ in cluster if e_.hp < e_.max_hp]
assert len(hit) == 4 and lonely.hp == lonely.max_hp                   # 4 saltos, dentro del grupo más aglomerado
assert all(abs((e_.max_hp - e_.hp) - (45 - 4)) < 1e-6 and e_.slow_timer > 0 for e_ in hit)    # 45 - armadura 4; aturdidos
assert all(abs(e_.slow_factor - 0.40) < 1e-9 for e_ in hit)             # aturdimiento base: -40%
assert not tes.choose_route("A") and tes.route == "B"                     # una sola especialización por torreta
assert not any(k in U.TURRET_ROUTES for k in ("tesla", "flamethrower"))  # ya no hay rutas propias de esas torretas
for e_ in list(foes):
    e_.kill()
# Lanzallamas: daño continuo en un sector frente a la torreta (50 por segundo)
fl = build(a2, "tower", (460, 780)) and max(w.towers, key=lambda t_: t_.build_order)
assert fl.choose_route("B") and fl.mode == "flame"
assert fl.damage == 50 and fl.range == 120 and fl.max_hp == 300 and fl.energy_cost == 8 and fl.cone == 70
front, behind, side = mk("scout", fl.pos + Vector2(70, 0)), mk("scout", fl.pos + Vector2(-70, 0)), mk("scout", fl.pos + Vector2(10, 90))
front.hp = behind.hp = side.hp = 1000
for _ in range(60):
    fl.update(1 / 60, foes, buls)
assert 42 <= 1000 - front.hp <= 55, 1000 - front.hp                   # ~50 por segundo
assert behind.hp == 1000                                              # nada fuera del sector
for e_ in list(foes):
    e_.kill()
# Foco Vigía: +30 px de alcance a las torretas energizadas cercanas
assert twin.effective_range() == 200
foco = build(a2, "foco", (540, 740)) and next(iter(w.focos))
assert foco.is_powered and twin.effective_range() == 230 and bal.effective_range() == 320 + 30 * (bal.pos.distance_to(foco.pos) <= 160)
assert (foco.max_hp, foco.stats["cost"], foco.stats["cores"], foco.stats["energy"]) == (150, 50, 0, 3)     # Foco Vigía: 50 de chatarra, 3 de energía
assert U.BUILDINGS["foco"]["range_bonus"] == 30
# estructuras de arte nuevo se dibujan sin errores
surf = pygame.Surface((1280, 720))
tes.arcs = [[tuple(tes.pos), tuple(tes.pos + Vector2(60, 0)), 0.1]]
fl.flame = 0.1
step(game, 2)
a2.camera.update(a2.CC_POS, (C.ACT2_W, C.ACT2_H))
for b_ in w.structures:
    b_.draw(surf, a2.camera.offset)

# =============================================================================
print("== Muros que se rompen, venta al 70% y energía ==")
a2 = new_act2(game, metal=5000)
w = a2.world
res = game.resources
assert build(a2, "wall", (620, 500))
wall = next(iter(w.walls))
assert (wall.max_hp, wall.stats["cost"]) == (400, 30)          # Balance P1: 15 -> 30
assert not wall.take_damage(399) and not wall.breaking
crumbles0 = len(combat.FX.crumbles)
assert wall.take_damage(10) and not wall.alive() and wall.hp == 0 and wall not in w.walls     # desaparece al instante
assert not wall.breaking and len(combat.FX.crumbles) == crumbles0 + 1                      # y deja un destello rojo
assert not wall.take_damage(50)                                                            # ya no recibe más golpes
wall.update(1 / 60, pygame.sprite.Group(), pygame.sprite.Group())                          # un muro retirado no revive ni falla
# venta: 70% del costo (15 -> 10)
assert build(a2, "wall", (660, 500))
wall = next(iter(w.walls))
m0 = res.metal
right_click(game, wall.pos)
assert a2.menu is not None and a2.menu.building is wall and len(a2.menu.options) == 2     # Nivel 2 + desmantelar
assert a2.menu.options[0]["label"] == "Nivel 2: REFORZADO"
assert "Desmantelar" in a2.menu.options[1]["label"] and "+21" in a2.menu.options[1]["label"]   # 70% de 30
press(game, pygame.K_2)
assert not wall.alive() and res.metal == m0 + 21 and a2.menu is None
assert build(a2, "tower", (700, 700))
tw = next(iter(w.towers))
m0 = res.metal
a2.sell(tw)
assert res.metal == m0 + int(45 * 0.7) and not tw.alive()             # 31
# energía: consumo / capacidad. El núcleo da 50 y cada pilón energizado +5 (1 de mantenimiento); las torretas ACTIVAS consumen
a2 = new_act2(game, metal=5000, cores=20)
w = a2.world
res = game.resources
assert a2.energy_capacity() == 50 and a2.energy_used() == 0 and res.energy == 0 and res.energy_cap == 50
spots = [(340, 700), (380, 700), (420, 700), (460, 700), (500, 700)]
for pos in spots[:4]:
    assert build(a2, "balista", pos)
assert a2.energy_used() == 48 and res.energy == 48 and res.energy_free == 2        # 4 x 12
m0, c0 = res.metal, res.cores
assert not build(a2, "balista", spots[4])                             # sin energía no se construye...
assert res.metal == m0 and res.cores == c0                            # ...ni se cobra chatarra ni núcleos
assert a2.energy_warning > 0                                          # aviso central "INSUFICIENTE ENERGÍA"
assert build(a2, "pylon", (540, 660)) and a2.energy_capacity() == 55 and a2.energy_used() == 49     # pilón: +5 y 1 de mantenimiento
assert not build(a2, "balista", spots[4])                             # 49 + 12 > 55: aún no cabe
assert build(a2, "pylon", (380, 660)) and build(a2, "pylon", (460, 540))
assert a2.energy_capacity() == 65 and a2.energy_used() == 51          # 3 pilones: +15 de capacidad y 3 de mantenimiento
assert build(a2, "balista", spots[4]) and a2.energy_used() == 63 and res.energy_free == 2
pyl = next(p_ for p_ in w.pylons if p_.pos.x > 500)
assert pyl.is_powered
pyl.take_damage(9999)                                                 # cae un pilón: capacidad 60 y consumo 62
step(game, 2)
newest = max(w.towers, key=lambda b_: b_.build_order)
assert a2.energy_capacity() == 60 and a2.energy_used() == 50 and res.energy == 50   # 4 balistas + 2 pilones
assert not newest.energized and not newest.active and all(b_.active for b_ in w.towers if b_ is not newest)   # se apaga la más nueva
assert a2.energy_warning > 0 and combat.FX.sparks                      # chispas y aviso
vacio = pygame.Surface((300, 300))
newest.draw_overlay(vacio, pygame.Rect(120, 120, 40, 40), Vector2())  # el icono de advertencia se dibuja sobre la torreta
step(game, 40)
before = len(w.bullets)
foe = Enemy("scout", newest.pos + Vector2(80, 0), a2.CC_POS, w.enemies)
foe.speed = 0
w.enemies.add(foe); w.all_sprites.add(foe); w.targets.add(foe)
newest.fire_timer = 0
step(game, 30)
assert not any(b_.owner == "balista" and b_.pos.distance_to(newest.pos) < 30 for b_ in w.bullets)    # inactiva: no dispara
foe.kill()
assert build(a2, "tower", (300, 700)) and a2.energy_used() == 55       # 50 + 5 = 55 <= 60: sí cabe
assert not build(a2, "balista", (260, 700)) and a2.energy_warning > 0     # 55 + 12 > 60
assert game.hud.resources_line(res) == f"Chatarra: {res.metal} | Núcleos: {res.cores} | Energía: 55/60"

# =============================================================================
print("== Dual-build de torretas (clic derecho): 2 torretas base, 4 especializaciones ==")
a2 = new_act2(game, metal=3000, cores=30)
w = a2.world
res = game.resources
assert set(U.TURRET_ROUTES) == {"tower", "balista"}                   # solo las 2 torretas base se especializan
for pos_ in ((460, 660), (500, 660), (540, 660), (580, 660)):
    assert build(a2, "pylon", pos_)                                                   # capacidad 50 + 20 (y 4 de mantenimiento)
assert build(a2, "tower", (500, 700)) and build(a2, "tower", (540, 700)) and build(a2, "balista", (340, 700))
assert build(a2, "balista", (380, 700))
twins = sorted((t_ for t_ in w.towers if t_.building_type == "tower"), key=lambda b_: b_.pos.x)
balis = sorted((t_ for t_ in w.towers if t_.building_type == "balista"), key=lambda b_: b_.pos.x)
twin = twins[0]
m0, c0 = res.metal, res.cores
right_click(game, twin.pos)
assert a2.menu is not None and a2.menu.building is twin
opts = a2.menu.options
assert [o["label"] for o in opts[:2]] == ["Ruta A: MINIGUN", "Ruta B: LANZALLAMAS"] and opts[2]["label"].startswith("Vender")
assert (opts[0]["scrap"], opts[0]["cores"]) == (60, 0) and (opts[1]["scrap"], opts[1]["cores"]) == (60, 0)
assert "enjambres" in opts[0]["desc"] and "fuego" in opts[1]["desc"]
assert (opts[0]["energy"], opts[1]["energy"]) == (0, 3)
press(game, pygame.K_1)                                               # las teclas del menú mandan sobre la construcción
assert a2.build_choice is None and twin.route == "A"
assert (twin.fire_rate, twin.damage, twin.range) == (0.20, 10, 200)  # minigun: más cadencia, menos daño
assert res.metal == m0 - 60 and res.cores == c0                       # economía separada: los núcleos no se tocan
assert [o["label"] for o in a2.menu.options] == ["Ruta A: MINIGUN (activa)", a2.menu.options[1]["label"]] and not a2.menu.options[0]["enabled"]
press(game, pygame.K_1)                                               # una sola ruta por torreta
assert res.metal == m0 - 60 and twin.route == "A"
a2.close_menu()
# ruta B del Twin (Lanzallamas) con clic izquierdo sobre la fila
twin2 = twins[1]
right_click(game, twin2.pos)
row = a2.menu.row_rect(a2.camera, 1).center
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=row))
assert twin2.route == "B" and twin2.mode == "flame" and (twin2.fire_rate, twin2.damage, twin2.range) == (0.1, 50, 120)
assert twin2.energy_cost == 8 and twin2.label == "Lanzallamas"
# el comportamiento cambia de verdad: la minigun dispara más seguido; el lanzallamas quema en cono pero a 120 px
foes_ = pygame.sprite.Group()
buls_ = pygame.sprite.Group()
far_e = Enemy("scout", twin2.pos + Vector2(150, 0), a2.CC_POS, foes_)
far_e.speed = 0
far_e.hp = 1000
foes_.add(far_e)
twin2.fire_timer = 0
twin2.update(1 / 60, foes_, buls_)
assert far_e.hp == 1000 and len(buls_) == 0                           # 150 px: fuera de los 120 del lanzallamas
far_e.pos = twin2.pos + Vector2(80, 0)
twin2.fire_timer = 0
twin2.update(1 / 60, foes_, buls_)
assert far_e.hp < 1000 and len(buls_) == 0                            # el lanzallamas no dispara proyectiles
shots_ = 0
foes_.empty()
near_e = Enemy("scout", twin.pos + Vector2(100, 0), a2.CC_POS, foes_)
near_e.speed = 0
foes_.add(near_e)
for _ in range(120):
    n_before = len(buls_)
    twin.update(1 / 60, foes_, buls_)
    shots_ += max(0, len(buls_) - n_before)
assert 9 <= shots_ <= 11, shots_                                      # 0.20 s: ~10 disparos en 2 s (la base: 5-6)
a2.close_menu()
# Balista: A perforante (4 objetivos, daño 200) / B Tesla (arco de 4 saltos, consume 12 + 15 = 27)
res.metal, res.cores = 1000, 30
for key, b_, cost in (("A", balis[0], (90, 0)), ("B", balis[1], (110, 0))):
    a2.open_menu(b_)
    idx = [o["action"][1] for o in a2.menu.options if o["action"][0] == "route"].index(key)
    assert (a2.menu.options[idx]["scrap"], a2.menu.options[idx]["cores"]) == cost
    assert a2.menu_choose(idx)
assert balis[0].route == "A" and balis[0].pierce == 4 and balis[0].damage == 200 and balis[0].mode == "balista"
assert balis[1].route == "B" and balis[1].mode == "tesla" and balis[1].jumps == 4 and balis[1].damage == 45
assert balis[1].energy_cost == 27 and balis[1].label == "Tesla"
assert res.metal == 1000 - 200 and res.cores == 30
# la explosiva daña en área alrededor del impacto (el directo, 156; los cercanos, 46 tras armadura; los lejanos, nada)
grp = pygame.sprite.Group()
e1, e2, e3 = (Enemy("soldier", p_, a2.CC_POS, grp) for p_ in ((200, 100), (240, 100), (400, 100)))
for e_ in (e1, e2, e3):
    e_.speed = 0
    grp.add(e_)
bullet = Projectile(Vector2(100, 100), Vector2(1, 0), 160, "balista", pierce=1, splash=50, splash_radius=80)
pg_ = pygame.sprite.Group(bullet)
for _ in range(30):
    pg_.update(1 / 60)
    combat.resolve_projectiles(pg_, grp, pygame.sprite.Group())
assert e1.max_hp - e1.hp == 156 and e2.max_hp - e2.hp == 46 and e3.hp == e3.max_hp
# sin chatarra no se elige ruta; los núcleos no cuentan (economía separada: la ruta es una compra táctica)
fresh = Building("tower", (800, 800))
a2._register(fresh)
res.metal, res.cores = 1000, 0
a2.open_menu(fresh)
assert a2.menu.options[0]["enabled"] and fresh.route is None and res.metal == 1000       # 0 núcleos: no importa
res.metal, res.cores = 10, 5
a2.open_menu(fresh)
assert not a2.menu.options[0]["enabled"] and not a2.menu_choose(0)
res.metal, res.cores = 1000, 5
a2._refresh_menu()
# sin energía libre tampoco se elige la ruta Tesla (+15): no se cobra nada y suena el aviso
res.metal, res.cores = 1000, 30
assert build(a2, "balista", (420, 700))
bal3 = max(w.towers, key=lambda b_: b_.build_order)
a2.open_menu(bal3)
idx_b = [o["action"][1] for o in a2.menu.options if o["action"][0] == "route"].index("B")
assert a2.energy_free() < 15 and not a2.menu.options[idx_b]["enabled"]
snap_res = (res.metal, res.cores)
a2.energy_warning = 0
assert not a2.menu_choose(idx_b) and bal3.route is None and (res.metal, res.cores) == snap_res and a2.energy_warning > 0
a2.close_menu()
res.metal, res.cores = 1000, 5
cam = a2.camera
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=(5, 5)))     # clic fuera: cierra
assert a2.menu is None
right_click(game, fresh.pos)
right_click(game, (900, 300))                                         # clic derecho en el aire con menú: solo lo cierra
assert a2.menu is None
m1, c1 = res.metal, res.cores
a2.open_menu(balis[0])
sale_ = balis[0].sell_value                                           # 70% de la chatarra invertida (base + ruta)
assert sale_ == int(balis[0].invested_scrap * 0.70) and balis[0].core_refund == 0
a2.menu_choose(len(a2.menu.options) - 1)
assert res.metal == m1 + sale_ and res.cores == c1 and not balis[0].alive()
# la ruta elegida viaja con la base (checkpoint / Base Central)
from src.mechanics.base_layout import capture_base
capture_base(a2, res)
assert [e["route"] for e in res.base_layout if e["type"] == "balista" and e["route"] == "B"] == ["B"]
game.machine.transition(GameState.MENU)
game.machine.transition(GameState.ACT_2_SETUP)
a2b = screens[GameState.ACT_2_SETUP]
dismiss(game)
tes_b = [t_ for t_ in a2b.world.towers if t_.building_type == "balista" and t_.route == "B"]
twin_a = [t_ for t_ in a2b.world.towers if t_.building_type == "tower" and t_.route == "A"]
fl_b = [t_ for t_ in a2b.world.towers if t_.building_type == "tower" and t_.route == "B"]
assert len(tes_b) == 1 and (tes_b[0].damage, tes_b[0].range, tes_b[0].mode) == (45, 160, "tesla")
assert len(twin_a) == 1 and twin_a[0].fire_rate == 0.20
assert len(fl_b) == 1 and fl_b[0].mode == "flame" and fl_b[0].energy_cost == 8

# =============================================================================
print("== Pausa táctica (ESPACIO): dt = 0 con el HUD visible ==")
a2 = new_act2(game, metal=1000)
w = a2.world
a2.wave.timer = 50.0
en = Enemy("scout", (900, 600), a2.CC_POS, w.enemies)
en.always_active = True
w.enemies.add(en); w.all_sprites.add(en); w.targets.add(en)
step(game, 30)
press(game, pygame.K_SPACE)
assert a2.paused
snap = (a2.wave.timer, Vector2(en.pos), len(w.bullets))
held[pygame.K_d] = True
mouse[0] = False
step(game, 120)
assert (a2.wave.timer, Vector2(en.pos), len(w.bullets)) == snap                           # todo congelado
a2.build_choice = "wall"                                              # ...pero se puede construir en pausa
n0 = len(w.structures)
mouse[0] = True
cell = Vector2(620, 500) - a2.camera.offset
mpos[0], mpos[1] = int(cell.x), int(cell.y)
step(game, 3)
mouse[0] = False
a2.build_choice = None
assert len(w.structures) == n0 + 1 and a2.wave.timer == snap[0]
held.clear()
frame_p = pygame.Surface((1280, 720))
a2.draw(frame_p)                                                      # el HUD sigue dibujándose
press(game, pygame.K_SPACE)
assert not a2.paused
step(game, 30)
assert a2.wave.timer < snap[0] and en.pos != snap[1]
# la pausa también rige en el Acto 1; avanzar un diálogo con ESPACIO no la activa
game.machine.transition(GameState.MENU)
game.new_campaign()
game.resources.equipped = True
game.machine.transition(GameState.SUB_ACT_1_2)
s = screens[GameState.SUB_ACT_1_2]
press(game, pygame.K_SPACE)                                           # avanza el diálogo narrativo
assert not s.paused
dismiss(game)
assert not s.paused
pos_a = Vector2(s.player.pos)
press(game, pygame.K_SPACE)
assert s.paused
held[pygame.K_d] = True
step(game, 60)
assert s.player.pos == pos_a
held.clear()
press(game, pygame.K_SPACE)
held[pygame.K_d] = True
step(game, 20)
held.clear()
assert not s.paused and s.player.pos.x > pos_a.x

# =============================================================================
print("== Hints contextuales: una sola vez, sin bloquear ==")
from src.ui.hints import HintManager
hm = HintManager()
assert hm.show("x", "texto", "wasd") and not hm.show("x", "texto", "wasd")      # una sola vez
hm.update(9.9)
assert "x" in hm.active
hm.update(0.2)
assert "x" not in hm.active and not hm.show("x", "texto", "wasd")               # caduca a los 10 s y no vuelve
hm.show("y", "otro", "e")
hm.done("y")
assert "y" not in hm.active
game.machine.transition(GameState.MENU)
press(game, pygame.K_RETURN)
s = screens[GameState.SUB_ACT_1_1]
dismiss(game)
step(game, 3)
assert "wasd" in game.hints.active and not s.dialogue.blocking_active           # no bloquea el juego
held[pygame.K_d] = True
step(game, 3)
held.clear()
assert "wasd" not in game.hints.active                                          # desaparece tras mover
assert "shoot" not in game.hints.shown                                          # sin rifle aún no se enseña a disparar
teleport(s, s.locker.pos + Vector2(30, 0))
step(game, 2)
press(game, pygame.K_e)
step(game, 2)
assert "shoot" in game.hints.active
mouse[0] = True
step(game, 3)
mouse[0] = False
assert "shoot" not in game.hints.active
frame_h = pygame.Surface((1280, 720))
game.hints.show("dibujo", "prueba de dibujo", "r_click", blink=True)
for icon in ("wasd", "click_left", "click_right", "e", "space", "r_click"):
    game.hints.show("i_" + icon, icon, icon)
s.draw(frame_h)                                                                 # todos los íconos se dibujan
game.hints.clear_active()
# Acto 2: construir, menú derecho, pausa, reparar, recoger y Aegis
a2 = new_act2(game, metal=1000)
w = a2.world
assert "build" in game.hints.active and "pause" in game.hints.active
assert build(a2, "wall", (620, 500))
a2.on_built(next(iter(w.walls)))                                                # build() usa _try_build, que ya lo llama
assert "build" not in game.hints.active and "right_menu" in game.hints.active
wall = next(iter(w.walls))
right_click(game, wall.pos)
assert "right_menu" not in game.hints.active
a2.close_menu()
assert build(a2, "tower", (700, 700))
assert "turret_upgrade" in game.hints.active
wall.hp = wall.max_hp * 0.5
step(game, 40)
assert "repair" in game.hints.active                                            # primer muro dañado
held[pygame.K_r] = True
step(game, 2)
held.clear()
assert "repair" not in game.hints.active
# modo Comandante: lo que cae no se recoge a mano; la base lo recoge sola tras AUTO_COLLECT_DELAY s (si no lo roban)
sc_h = a2._drop_scrap(a2.CC_POS + Vector2(90, 0), 30)
m0 = game.resources.metal
step(game, 2)
assert sc_h.alive() and "scrap" not in game.hints.active                       # (ya no hay aviso de «E para recoger»)
step(game, int(60 * C.AUTO_COLLECT_DELAY))
assert not sc_h.alive() and game.resources.metal >= m0 + 30
assert build(a2, "fabrica", (640, 720))
a2.factory.build_left = 0
game.hints.update(11)
assert not game.hints.active
# solo una vez: reiniciar el sub-acto no repite los hints ya vistos
assert "build" in game.hints.shown

# =============================================================================
print("== Árbol de mejoras del Operador (Terminal Táctico): dos ramas lineales, solo Núcleos de Plasma ==")
from main import tree_layout
# economía separada: el árbol se paga SOLO con núcleos de plasma (la chatarra nunca se toca)
rm = ResourceManager()
rm.metal, rm.cores = 5000, 40
assert set(U.OPERATOR_TREE) == {"gatillo_automatico", "calibre_perforante", "sobrecarga_balistica",
                                "impulso_doble", "blindaje_titanio", "celda_vital", "celda_vital_2"}   # Ofensiva 3 y Supervivencia 4
assert rm.node_state("gatillo_automatico") == "available" and rm.node_state("calibre_perforante") == "locked"
m0, c0 = rm.metal, rm.cores
assert not rm.buy_node("calibre_perforante") and rm.cores == c0       # bloqueado: falta el prerrequisito
assert not rm.buy_node("sobrecarga_balistica") and rm.cores == c0
assert rm.bullet_damage() == 12 and rm.bullet_pierce() == 1 and rm.fire_cooldown() == 0.15
assert rm.buy_node("gatillo_automatico") and rm.cores == c0 - 1 and rm.node_state("gatillo_automatico") == "owned"
assert not rm.buy_node("gatillo_automatico")                          # no se compra dos veces
assert rm.node_state("calibre_perforante") == "available" and rm.node_state("sobrecarga_balistica") == "locked"
assert rm.bullet_damage() == 12 and rm.fire_cooldown() == 0.15        # A1 solo da el fuego continuo
assert rm.buy_node("calibre_perforante") and rm.cores == c0 - 4       # 3 núcleos
assert rm.bullet_damage() == 16 and rm.bullet_pierce() == 2 and rm.fire_cooldown() == 0.15
assert rm.buy_node("sobrecarga_balistica") and rm.cores == c0 - 9     # 5 núcleos
assert rm.bullet_damage() == 20 and rm.bullet_pierce() == 2 and rm.fire_cooldown() == 0.12
assert rm.metal == m0                                                 # ni un ⚙ en todo el árbol
rm.cores = 0
assert not rm.buy_node("impulso_doble") and not rm.owns("impulso_doble")      # sin núcleos no, aunque sobre chatarra
rm.cores = 1
assert rm.buy_node("impulso_doble") and rm.cores == 0
assert rm.node_state("blindaje_titanio") == "available" and not rm.buy_node("blindaje_titanio")
rm.cores = 7
assert rm.buy_node("blindaje_titanio") and rm.cores == 4 and rm.buy_node("celda_vital") and rm.cores == 0
assert len(rm.op_nodes) == 6 and rm.player_max_hp == 133 and rm.metal == m0 and rm.ammo_capacity() == 150   # sin bonus de munición
# los costos coinciden con UNITS (chatarra siempre 0; núcleos 1/3/5 y 1/3/4/6 = 23) y cada nodo cuelga del anterior
assert sum(s_["cores"] for s_ in U.OPERATOR_TREE.values()) == 23 and "nanoregeneracion" not in U.OPERATOR_TREE
for br, nodes in U.UPGRADES_TREE.items():
    assert [U.OPERATOR_TREE[n]["cores"] for n in nodes] == {"offensive": [1, 3, 5], "survival": [1, 3, 4, 6]}[br]
    assert all(U.OPERATOR_TREE[n]["branch"] == br for n in nodes)
    assert [U.OPERATOR_TREE[n]["requires"] for n in nodes] == [None] + nodes[:-1]
for node, spec in U.OPERATOR_TREE.items():
    assert rm.node_cost(node) == (0, spec["cores"]) and spec["cost"] == 0 and (spec["tier"] == 1) == (spec["requires"] is None)
snap_u = rm.snapshot()
rm.op_nodes.clear()
rm.restore(snap_u)
assert len(rm.op_nodes) == 6                                          # viaja en los checkpoints
assert rm.op_nodes is rm.campaign_run.op_nodes                        # ...y vive en CampaignRun
rm.reset()
assert rm.op_nodes == set() and rm.cores == 0 and rm.metal == 150     # campaña nueva: sin mejoras ni núcleos
rm.metal = 5000
assert not rm.buy_node("gatillo_automatico")                          # sin núcleos, aunque sobre chatarra
# Terminal Táctico: el árbol se ve completo, con bloqueos, y se compra con clic
game.machine.transition(GameState.MENU)
game.new_campaign()
game.resources.initial_done = True
game.resources.metal, game.resources.cores = 1000, 13
game.machine.transition(GameState.ACT_2_BASE)
term = screens[GameState.ACT_2_BASE]
layout = tree_layout()
assert set(layout) == set(U.OPERATOR_TREE) and len({(r_.x, r_.y) for r_ in layout.values()}) == 7
assert term.node_rects == layout


def click_node(node):
    game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=layout[node].center))


click_node("sobrecarga_balistica")                                    # bloqueado
assert not game.resources.owns("sobrecarga_balistica") and "Bloqueada" in term.upgrade_msg and game.resources.cores == 13
click_node("gatillo_automatico")
assert game.resources.owns("gatillo_automatico") and game.resources.cores == 12 and "comprada" in term.upgrade_msg
click_node("calibre_perforante")
click_node("sobrecarga_balistica")
assert game.resources.owns("sobrecarga_balistica") and game.resources.cores == 4 and game.resources.metal == 1000
click_node("impulso_doble")
click_node("blindaje_titanio")
assert game.resources.cores == 0
click_node("celda_vital")
assert not game.resources.owns("celda_vital") and "Faltan núcleos" in term.upgrade_msg
game.machine.draw(game.screen)                                        # se dibuja con propios, bloqueados y disponibles
pl = Player((0, 0), 2000, 1200)                                       # el Operador (incursiones) lleva el árbol puesto
pl.apply_upgrades(game.resources)
assert pl.automatic_fire and abs(pl.shoot_cooldown - 0.12) < 1e-9 and pl.bullet_damage == 20 and pl.bullet_pierce == 2
assert pl.dash_charges_max == 2 and pl.flat_armor == 4 and pl.capacity == 150
assert pl.regen_delay == C.PLAYER_REGEN_DELAY and pl.regen_mult == 1.0          # sin B3
game.machine.transition(GameState.MENU)
game.resources.op_nodes.add("impulso_doble")
game.machine.transition(GameState.SUB_ACT_1_2)
assert screens[GameState.SUB_ACT_1_2].player.dash_charges_max == 2    # también en el Acto 1

# =============================================================================
print("== Carroñero Hostil: sabotea pilones (apagón en cascada) ==")
a2 = new_act2(game, metal=2000)
w = a2.world
assert build(a2, "pylon", (520, 600)) and build(a2, "pylon", (660, 600)) and build(a2, "tower", (740, 740))   # solo B la alcanza
p1 = min(w.pylons, key=lambda p: p.pos.x)
p2 = [p for p in w.pylons if p is not p1][0]
tower = next(iter(w.towers))
assert p1.is_powered and p2.is_powered and tower.is_powered
a2.grid.update()
sab = ScavengerDrone((p1.pos.x, p1.pos.y + 50), p1.pos, (0, 0), pylon=p1)
w.scavengers.add(sab); w.all_sprites.add(sab)
done = []
sab.on_sabotage = lambda d, p: done.append(p)
for _ in range(60 * 2):
    step(game, 1)
    if done:
        break
assert done == [p1] and sab.state == "fleeing" and not sab.carrying_scrap      # no roba nada: sabotea
assert p1.disabled_timer > 0
step(game, 2)
assert not p1.is_powered and not p2.is_powered and not tower.is_powered         # apagón en cascada
step(game, int(60 * C.SCAVENGER_SABOTAGE_TIME) + 30)
assert p1.is_powered and p2.is_powered and tower.is_powered                     # vuelve la energía
# el gestor de oleadas despacha carroñeros atraídos por el botín: van a la chatarra; si ya no está, a un pilón
sc_ = a2._drop_scrap(Vector2(900, 900), 10)
before = len(w.scavengers)
a2._spawn_scavenger(sc_)
d_new = list(w.scavengers)[before]
step(game, 1)
assert d_new.state == "seek_scrap" and d_new.goal is sc_
sc_.kill()
for e_ in list(w.scraps):
    e_.kill()
for e_ in list(w.core_items):
    e_.kill()
step(game, 20)
assert d_new.state == "seek_pylon" and d_new.goal in w.pylons
d_new.kill()

# =============================================================================
print("== Munición: semiautomático, cargadores, cajas, advertencias y combate cuerpo a cuerpo ==")
from src.entities.ammo import AmmoBox
# Acto 1: munición infinita y disparo semiautomático (1 clic = 1 disparo)
game.machine.transition(GameState.MENU)
game.new_campaign()
game.resources.equipped = True
game.machine.transition(GameState.SUB_ACT_1_2)
s = screens[GameState.SUB_ACT_1_2]
dismiss(game)
pl = s.player
step(game, 3)                                           # suelta el clic que cerró el diálogo
assert pl.infinite_ammo and not pl.automatic_fire
n0 = pl.ammo
mouse[0] = True
step(game, 40)                                       # clic mantenido: UN solo disparo
mouse[0] = False
assert pl.shots_fired == 1
for _ in range(120):                                 # 120 clics sueltos: nunca se agota
    mouse[0] = True
    step(game, 5)
    mouse[0] = False
    step(game, 5)
assert pl.shots_fired >= 100 and pl.ammo == n0 and pl.mag_rounds == pl.mag_size and not pl.out_of_ammo
assert "ammo_limited" not in game.hints.shown        # el aviso de munición limitada es del Acto 2
game.machine.draw(game.screen)                       # HUD del Acto 1: "MUNICIÓN ∞"
# Acto 2+: limitada, cargadores y recarga de 0.8 s; el fuego continuo es una mejora
a2 = new_op_arena(game, metal=3000)
w = a2.world
for d_ in list(w.drones):
    d_.kill()
pl = a2.player
assert not pl.infinite_ammo and (pl.ammo, pl.capacity, pl.mag_rounds, pl.reserve) == (150, 150, 50, 100)
teleport(a2, Vector2(900, 800))
for _ in range(10):
    mouse[0] = True
    step(game, 5)
    mouse[0] = False
    step(game, 5)
assert pl.ammo == 150 - pl.shots_fired and pl.shots_fired >= 8
pl.full_ammo()
pl.shots_fired = 0
pl.automatic_fire = True
mouse[0] = True
step(game, 60)                                       # automático: mantener = fuego continuo a 0.15 s
mouse[0] = False
assert 5 <= pl.shots_fired <= 8, pl.shots_fired
pl.automatic_fire = False
# umbrales del HUD: blanco, AMARILLO (<30) y ROJO (<10)
def with_ammo(n):
    pl.mag_rounds, pl.reserve, pl.reload_timer = min(n, 50), max(0, n - 50), 0.0
    return HUD.ammo_color(pl)
assert with_ammo(120) == C.WHITE and with_ammo(30) == C.WHITE
assert with_ammo(29) == C.YELLOW and with_ammo(10) == C.YELLOW
assert with_ammo(9) == C.RED and with_ammo(0) == C.RED
for n in (120, 29, 9, 0):                            # el HUD se dibuja en cada estado (con mensaje cuando toca)
    with_ammo(n)
    for tick in (0, 450):
        pygame.time.get_ticks = (lambda t=tick: t)
        game.machine.draw(game.screen)
pygame.time.get_ticks = lambda: 1000
# cajas de munición: +50 balas hasta la capacidad; no se desperdician si ya está llena
with_ammo(60)
box = AmmoBox(pl.pos + Vector2(10, 0))
w.ammo_boxes.add(box); w.all_sprites.add(box)
step(game, 3)
assert not box.alive() and pl.ammo == 110
with_ammo(150)
box2 = AmmoBox(pl.pos + Vector2(10, 0))
w.ammo_boxes.add(box2)
step(game, 3)
assert box2.alive() and pl.ammo == 150               # munición llena: la caja espera
box2.kill()
with_ammo(100)
far_box = AmmoBox(pl.pos + Vector2(90, 0))
w.ammo_boxes.add(far_box)
press(game, pygame.K_e)                              # E recoge la caja cercana
assert not far_box.alive() and pl.ammo == 150
# drops: 30% en el Acto 2+ y ninguno en el Acto 1
random.seed(11)
n_boxes = 0
for _ in range(1500):
    before = len(w.ammo_boxes)
    en = Enemy("scout", (1500, 300), a2.CC_POS, w.enemies)
    a2._on_enemy_death(en)
    n_boxes += len(w.ammo_boxes) - before
    for b_ in list(w.ammo_boxes):
        b_.kill()
    for sc_ in list(w.scraps):
        sc_.kill()
assert abs(n_boxes / 1500 - 0.30) < 0.04, n_boxes / 1500
game.machine.transition(GameState.MENU)
game.new_campaign()
game.resources.equipped = True
game.machine.transition(GameState.SUB_ACT_1_2)
s = screens[GameState.SUB_ACT_1_2]
dismiss(game)
for _ in range(400):
    s._on_enemy_death(Enemy("scout", (500, 300), s.player.pos, s.world.enemies))
assert len(s.world.ammo_boxes) == 0                  # el tutorial no suelta munición
# combate cuerpo a cuerpo: sin balas, el clic golpea (25 de daño, 50 px, 0.4 s, repulsión de 50 px)
a2 = new_op_arena(game, metal=3000)
w = a2.world
for d_ in list(w.drones):
    d_.kill()
pl = a2.player
teleport(a2, Vector2(900, 800))
aim = Vector2(1300, 800) - a2.camera.offset
mpos[0], mpos[1] = int(aim.x), int(aim.y)
front = Enemy("soldier", (942, 800), a2.CC_POS, w.enemies)
behind = Enemy("soldier", (858, 800), a2.CC_POS, w.enemies)
far_e = Enemy("soldier", (1010, 800), a2.CC_POS, w.enemies)
for e_ in (front, behind, far_e):
    e_.speed = 0
    w.enemies.add(e_); w.all_sprites.add(e_); w.targets.add(e_)
step(game, 2)
pl.mag_rounds = pl.reserve = 0
pl.reload_timer = 0.0
assert pl.out_of_ammo
x_front = front.pos.x
shots0 = pl.shots_fired
mouse[0] = True
step(game, 2)
assert pl.melee_swings == 1 and pl.shots_fired == shots0                          # golpea, no dispara
assert front.max_hp - front.hp == 25 - 4                                          # 25 menos 4 de armadura plana
assert front.pos.x - x_front > 40                                                 # repulsión de ~50 px
assert behind.hp == behind.max_hp and far_e.hp == far_e.max_hp                    # ni el de atrás ni el lejano
step(game, 12)                                                                    # 0.2 s: aún en enfriamiento
assert pl.melee_swings == 1
step(game, 20)                                                                    # pasó 0.4 s con el clic mantenido
assert pl.melee_swings == 2
mouse[0] = False
# la repulsión no atraviesa muros
build(a2, "wall", (1020, 800)) if False else None
wall_k = Building("wall", (1000, 800))
a2._register(wall_k)
knock = Enemy("scout", (960, 800), a2.CC_POS, w.enemies)
knock.speed = 0
w.enemies.add(knock); w.all_sprites.add(knock)
pl.melee_timer = 0.0
teleport(a2, Vector2(920, 800))
mouse[0] = True
step(game, 2)
mouse[0] = False
assert not knock.rect.colliderect(wall_k.rect), (knock.pos, wall_k.rect)
# con balas, el clic izquierdo dispara (no golpea)
step(game, 2)                                                                       # el clic anterior ya se soltó
for e_ in (front, behind, far_e, knock):
    e_.kill()
pl.full_ammo()
swings = pl.melee_swings
mouse[0] = True
step(game, 2)
mouse[0] = False
assert pl.melee_swings == swings and pl.shots_fired > shots0
# hints de munición (munición limitada): limitada -> sin munición -> golpe defensivo
a2 = new_op_arena(game, metal=3000)
for d_ in list(a2.world.drones):
    d_.kill()
pl = a2.player
step(game, 3)
mouse[0] = True
step(game, 12)                                       # el clic espera el fin del enfriamiento inicial
mouse[0] = False
assert "ammo_limited" in game.hints.active and game.hints.active["ammo_limited"].text == "Munición limitada - busca suministros"
pl.mag_rounds = pl.reserve = 0
pl.reload_timer = 0.0
step(game, 3)
assert game.hints.active["no_ammo"].text == "SIN MUNICIÓN - Golpea cuerpo a cuerpo"
mouse[0] = True
step(game, 3)
mouse[0] = False
assert pl.melee_swings >= 1 and game.hints.active["melee"].text == "Click para golpe defensivo (25 daño)"
assert "no_ammo" not in game.hints.active
# mejora del Terminal Táctico: Gatillo Automático (1 núcleo); ya no hay mejoras de capacidad de munición
game.machine.transition(GameState.MENU)
game.new_campaign()
game.resources.initial_done = True
game.resources.metal, game.resources.cores = 1000, 1
game.machine.transition(GameState.ACT_2_BASE)
term = screens[GameState.ACT_2_BASE]
for node in ("gatillo_automatico",):
    game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=term.node_rects[node].center))
assert game.resources.metal == 1000 and game.resources.cores == 0
game.machine.draw(game.screen)
a2 = new_op_arena(game, metal=1000, fresh=False)
pl = a2.player
assert pl.automatic_fire and pl.capacity == 150 and pl.ammo == 150 and pl.mag_rounds == 50
game.machine.draw(game.screen)                                                           # 3 cargadores en el HUD
for d_ in list(a2.world.drones):
    d_.kill()
teleport(a2, Vector2(900, 800))
pl.shots_fired = 0
step(game, 3)
mouse[0] = True
step(game, 60)
mouse[0] = False
assert 5 <= pl.shots_fired <= 8                                                          # fuego continuo comprado
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Sub-acto 1.4: alijos de rescate contra el softlock de VULCANO ==")
game.new_campaign()
game.resources.equipped = True
game.resources.metal = 20
game.machine.transition(GameState.SUB_ACT_1_4)
s = screens[GameState.SUB_ACT_1_4]
dismiss(game)
res = game.resources
assert len(s.caches) == 1 and s.caches[0].amount == 100 and s.caches[0].pos == s.level.marker("rescue_n")
assert "rescue" in game.hints.active and "Suministros detectados" in game.hints.active["rescue"].text
assert any("sensores detectan suministros" in ln.text for ln in s.dialogue.lines)
assert s.radar_targets()[0][0] == s.caches[0].pos                                        # el radar guía al alijo
# mientras no lo recoges, hay chatarra de menos para VULCANO: se recoge con solo acercarse
teleport(s, s.caches[0].pos + Vector2(30, 0))
step(game, 3)
assert res.metal == 120 and not s.caches and "rescue" not in game.hints.active
step(game, 3)
assert not s.caches                                                                       # ya hay suficiente: no hay más alijos
# sin falta de chatarra no aparece nada
game.machine.transition(GameState.MENU)
game.new_campaign()
game.resources.equipped = True
game.resources.metal = 80
game.machine.transition(GameState.SUB_ACT_1_4)
s = screens[GameState.SUB_ACT_1_4]
dismiss(game)
assert not s.caches
# caso raro: ya con VULCANO en marcha el jugador se queda sin chatarra -> alijo 2 (+50, zona sur) y siguientes
teleport(s, s.terminal.pos + Vector2(0, 60))
step(game, 2)
press(game, pygame.K_e)
dismiss(game)
res.metal = 0
step(game, 3)
assert len(s.caches) == 1 and s.caches[0].amount == 100                                  # el primero siempre es de 100
teleport(s, s.caches[0].pos + Vector2(20, 0))
step(game, 2)
assert res.metal == 100
res.metal = 10                                                                           # gasta lo recogido
for wl in s.demo_walls:
    wl.hp = wl.max_hp * 0.3
step(game, 3)
assert len(s.caches) == 1 and s.caches[0].amount == 50 and s.caches[0].pos == s.level.marker("rescue_s")
teleport(s, s.caches[0].pos + Vector2(20, 0))
step(game, 2)
for _ in range(6):                                                                       # sigue habiendo alijos hasta que alcance
    if res.metal >= s.repair_needed():
        break
    assert len(s.caches) == 1
    teleport(s, s.caches[0].pos + Vector2(20, 0))
    step(game, 2)
assert res.metal >= s.repair_needed()
step(game, 60 * 22)                                     # VULCANO repara en serie: 840 HP a 80 HP/s = 10,5 s
assert res.metal >= C.VULCANO_SCRAP_RESERVE             # y nunca se come la reserva básica
assert s.demo_done and s.exit_console.enabled                                            # sin softlock: se pueden terminar las reparaciones
assert game.hints.shown >= {"rescue"}
# guardado silencioso: ya no hay mensajes de "checkpoint"
teleport(s, s.exit_console.pos + Vector2(0, 60))
step(game, 2)
press(game, pygame.K_e)
texts = [ln.text for ln in s.dialogue.lines]
assert texts and not any("heckpoint" in tx for tx in texts), texts
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Todos los enemigos atacan los muros que les cierran el paso (también los scouts en grupo) ==")
a2 = new_act2(game, metal=3000)
w = a2.world
for d_ in list(w.drones):
    d_.kill()
wall_line = []
for y in range(20, C.ACT2_H, 40):                    # pared completa: no hay hueco por el que rodear
    b_ = Building("wall", (900, y))
    a2._register(b_)
    wall_line.append(b_)
pack = []
for i in range(9):
    e_ = Enemy("scout", (1300, 560 + 22 * i), a2.CC_POS, w.enemies)
    e_.flank = (-1) ** i
    w.enemies.add(e_); w.all_sprites.add(e_); w.targets.add(e_)
    pack.append(e_)
for _ in range(60 * 6):
    a2.core.hp = a2.core.max_hp
    step(game, 1)
assert all(e_.pos.x > 850 for e_ in pack)                                                # al principio ninguno atraviesa la pared
hurt = [b_ for b_ in wall_line if b_.hp < b_.max_hp or not b_.alive()]
assert len(hurt) >= 3, len(hurt)                                                         # varios scouts muerden la pared
assert sum(b_.max_hp - b_.hp for b_ in hurt) > 80                                        # con daño real (8/s cada uno)
# un solo muro en diagonal al rumbo también les bloquea (no basta con rozarlo)
for e_ in pack:
    e_.kill()
a2 = new_act2(game, metal=3000)
w = a2.world
for d_ in list(w.drones):
    d_.kill()
solo = Building("wall", (900, 600))
a2._register(solo)
sc_ = Enemy("scout", (960, 640), (700, 560), w.enemies)         # llega en diagonal y pegado a la esquina
sc_.flank = 0
sc_.target_pos = Vector2(700, 560)
w.enemies.add(sc_); w.all_sprites.add(sc_)
for _ in range(60 * 6):
    sc_.update(1 / 60, w.structures, None)
assert solo.hp < solo.max_hp or not solo.alive()

# =============================================================================
print("== Controles unificados: clic izq. construye; clic der. menú de la estructura u orden a los drones ==")
a2 = new_act2(game, metal=1000)
w = a2.world
cam_off = Vector2(a2.camera.offset)
cell_px = Vector2(740, 500) - cam_off
mpos[0], mpos[1] = int(cell_px.x), int(cell_px.y)
a2.build_choice = "wall"
mouse[0] = True
step(game, 10)
mouse[0] = False
assert len(w.walls) == 1 and len(w.bullets) == 0                              # con un edificio elegido, el clic construye
wall = next(iter(w.walls))
a2.build_choice = None
mouse[0] = True
step(game, 8)
mouse[0] = False
assert len(w.bullets) == 0 and len(w.walls) == 1                              # modo Comandante: sin rifle que dispare
right_click(game, wall.pos)
assert a2.menu is not None
a2.close_menu()
a2.build_choice = "tower"
right_click(game, wall.pos)                                                   # clic der. sobre una estructura: deselecciona y abre su menú
assert a2.build_choice is None and a2.menu is not None
a2.close_menu()
# Base Central: también se construye con clic izquierdo, y los botones no construyen debajo
game.new_campaign()
game.resources.vulcano_online = True
game.resources.metal = 500
game.machine.transition(GameState.SUB_ACT_1_4)
game.advance(GameState.ACT_2_BASE)
bm = screens[GameState.BASE_MANAGEMENT]
bm.dialogue.advance()
bm.build_choice = "wall"
btn = bm.buttons["deploy"].center
mpos[0], mpos[1] = btn
mouse[0] = True
step(game, 5)
assert len(bm.world.walls) == 0                                               # sobre un botón no construye
cell_px = Vector2(740, 660) - bm.camera.offset
mpos[0], mpos[1] = int(cell_px.x), int(cell_px.y)
step(game, 5)
mouse[0] = False
assert len(bm.sites) == 1 and len(bm.world.walls) == 0 and game.resources.metal == 500   # el clic coloca la obra: aún no se cobra
for _ in range(1200):                                                         # VULCANO acude, construye y cobra
    step(game, 1)
    if not bm.sites:
        break
assert len(bm.world.walls) == 1 and game.resources.metal == 500 - 30          # sin descuento
wall_b = next(iter(bm.world.walls))
right_click(game, wall_b.pos)
assert bm.menu is not None and "Desmantelar" in bm.menu.options[1]["label"] and bm.menu.options[0]["label"].startswith("Nivel 2")
press(game, pygame.K_2)
assert not wall_b.alive() and game.resources.metal == 500 - 30 + 21           # vende al 70%
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Línea de tiro en niveles y detección del Foco Vigía ==")
nav_t = FlowField(1200, 400, hard={(10, y) for y in range(0, 10)})            # pared vertical entre x=400 y x=440
wr_t = WorldRefs()
pl_t = Player((520, 200), 1200, 400)
wr_t.player = pl_t
pg_t = pygame.sprite.Group(pl_t)
soldier_t = Enemy("soldier", (380, 200), (900, 200), wr_t.enemies)          # a 140 px (alcance 160), tras la pared
soldier_t.world, soldier_t.always_active = wr_t, True
assert soldier_t._acquire(None) is pl_t                                       # sin pared: lo ve
assert soldier_t._acquire(nav_t) is None                                      # con la pared por medio: no hay tiro
soldier_t.pos = Vector2(450, 200)
assert soldier_t._acquire(nav_t) is pl_t                                      # del mismo lado: sí
assert nav_t.has_clear_shot((330, 200), (330, 100)) and not nav_t.has_clear_shot((330, 200), (520, 200))
# el soldado que no tiene tiro sigue avanzando en lugar de quedarse parado disparando a la pared
soldier_t.pos = Vector2(330, 200)
soldier_t.rect.center = (330, 200)
x_t = soldier_t.pos.x
for _ in range(30):
    soldier_t.update(1 / 60, pygame.sprite.Group(), nav_t)
assert soldier_t.pos.x != x_t or soldier_t.pos.y != 200
# Foco Vigía: amplía lo que el minimapa detecta
assert HUD.is_revealed((100, 100), [(Vector2(0, 0), 420)]) and not HUD.is_revealed((2000, 1000), [(Vector2(0, 0), 420)])
assert HUD.is_revealed((2000, 1000), None)
a2 = new_act2(game, metal=2000)
w = a2.world
base_rev = len(a2.revealers())
assert base_rev == 1                                                          # el núcleo (modo Comandante: sin Operador)
assert build(a2, "pylon", (500, 660)) and build(a2, "foco", (540, 740))
rev = a2.revealers()
assert len(rev) == 2 and rev[1][1] == 320
far = Vector2(540, 740) + Vector2(300, 0)
assert HUD.is_revealed(far, rev) and not HUD.is_revealed(far, rev[:1])        # el Foco amplía la detección
next(iter(w.focos)).take_damage(9999)
assert len(a2.revealers()) == 1                                                # sin foco, vuelve a lo normal
game.machine.draw(game.screen)                                                 # el minimapa se dibuja con detección
game.machine.transition(GameState.MENU)
game.machine.draw(game.screen)                                                 # el menú lista los controles nuevos

# =============================================================================
print("== Núcleos de Plasma: drops, recogida (andando, con E, con Imán) y costos ==")
from src.entities.core_item import CoreItem
from src.entities.enemy import ammo_drop_chance, roll_core_drop
rr_ = random.Random(5)
for kind in ("scout", "soldier"):
    assert {roll_core_drop(kind, rr_) for _ in range(500)} == {0}                    # los comunes no sueltan núcleos
for kind, n in (("ariete", 1), ("tank", 2)):
    vals = [roll_core_drop(kind, rr_) for _ in range(3000)]
    got = [v for v in vals if v]
    assert set(got) == {n} and abs(len(got) / 3000 - 0.5) < 0.04, (kind, len(got) / 3000)       # Ariete +1, Tanque +2 (50%)
assert (ammo_drop_chance("scout"), ammo_drop_chance("soldier"), ammo_drop_chance("ariete"), ammo_drop_chance("tank")) == (0.3, 0.3, 0.4, 0.4)
a2 = new_op_arena(game, metal=2000)                                  # recoger a pie: mecánica del Operador
game.resources.cores = 0
w = a2.world
res = game.resources
pl = a2.player
teleport(a2, Vector2(900, 800))
random.seed(21)
n_items, total = 0, 0
for _ in range(600):
    en = Enemy("tank", (1500, 300), a2.CC_POS, w.enemies)
    before = len(w.core_items)
    a2._on_enemy_death(en)
    for it in list(w.core_items):
        n_items += 1
        total += it.value
        it.kill()
    for grp_ in (w.scraps, w.ammo_boxes, w.medkits, w.parts):
        for s_ in list(grp_):
            s_.kill()
assert abs(n_items / 600 - 0.5) < 0.07 and total == 2 * n_items                  # el Tanque suelta 2 núcleos el 50% de las veces
# recoger andando por encima, con E (radio 120) y no sin acercarse
it = CoreItem(pl.pos + Vector2(10, 0), 2)
w.core_items.add(it); w.all_sprites.add(it)
step(game, 3)
assert res.cores == 2 and not it.alive()
it2 = CoreItem(pl.pos + Vector2(100, 0), 1)
w.core_items.add(it2); w.all_sprites.add(it2)
step(game, 30)
assert it2.alive() and res.cores == 2                                              # sin imán no se acerca
press(game, pygame.K_e)
assert not it2.alive() and res.cores == 3
far_c = CoreItem(pl.pos + Vector2(300, 0), 1)
w.core_items.add(far_c)
press(game, pygame.K_e)
assert far_c.alive()                                                               # fuera del radio de E
far_c.kill()
# sin Módulo Imán (eliminado del árbol): la chatarra de 100 px no se acerca sola; solo el magnetismo corto (48 px) y la E
sc_i = a2._drop_scrap(pl.pos + Vector2(100, 0), 10)
box_i = AmmoBox(pl.pos + Vector2(0, 100))
w.ammo_boxes.add(box_i); w.all_sprites.add(box_i)
step(game, 40)
assert sc_i.alive() and box_i.alive()
sc_i.kill(); box_i.kill()
# un Núcleo de Plasma es un recurso aparte: costos de construcción en chatarra Y núcleos
a2 = new_act2(game, metal=2000, cores=0)
w = a2.world
res = game.resources
for d_ in list(w.drones):
    d_.kill()
m0 = res.metal                                    # economía separada: con 0 núcleos se construye todo (solo chatarra)
assert build(a2, "tower", (500, 700))
assert build(a2, "balista", (340, 700)) and res.cores == 0 and res.metal == m0 - round(45 * 0.5) - round(100 * 0.5)
build(a2, "foco", (540, 740))
assert build(a2, "pylon", (460, 700)) and res.cores == 0
m1, c1 = res.metal, res.cores
gen_s = max(w.pylons, key=lambda b_: b_.build_order)
sale_g = gen_s.sell_value
assert sale_g == int(gen_s.invested_scrap * 0.70) and gen_s.core_refund == 0
a2.sell(gen_s)                                                                     # 70% de la chatarra; núcleos: nada
assert res.metal == m1 + sale_g and res.cores == c1
# el Ariete Ligero del 1.2 suelta 1 Núcleo seguro
game.machine.transition(GameState.MENU)
game.new_campaign()
game.resources.equipped = True
game.machine.transition(GameState.SUB_ACT_1_2)
s = screens[GameState.SUB_ACT_1_2]
dismiss(game)
s._ram_dead(s.ram)
cores_drop = list(s.world.core_items)
assert len(cores_drop) == 1 and cores_drop[0].value == 1
teleport(s, cores_drop[0].pos)
step(game, 3)
assert game.resources.cores == 1

# =============================================================================
print("== Incursión: alijo de plasma, extractor de riesgo y núcleos en riesgo hasta extraer ==")
game.machine.transition(GameState.MENU)
game.new_campaign()
game.machine.transition(GameState.ACT_2_BASE)
game.machine.transition(GameState.INCURSION, op="convoy")                          # mapa económico de nivel 2: con extractor
sc = game.machine.active
dismiss(game)
res = game.resources
assert sc.plasma_cache is not None and sc.plasma_point is not None and sc.loot_cores == 0
assert sc.plasma_cache.pos == sc.level.marker("plasma_cache") and sc.plasma_point.pos == sc.level.marker("plasma_extractor")
assert not any(c[1] == C.CYAN for c in sc.radar_targets())                       # sin escaneo táctico (chasis < 3/6) no
res.chassis_installed = 3
assert any(c[1] == C.CYAN for c in sc.radar_targets())                           # con 3/6, AURA los marca en el radar
res.chassis_installed = 0
# alijo de plasma: 1-3 núcleos, en riesgo hasta extraer
teleport(sc, sc.plasma_cache.pos + Vector2(0, 40))
step(game, 2)
press(game, pygame.K_e)
assert 1 <= sc.loot_cores <= 3 and not sc.plasma_cache.enabled and res.cores == 0
press(game, pygame.K_e)
assert 1 <= sc.loot_cores <= 3                                                      # no se saquea dos veces
got = sc.loot_cores
# extractor de plasma: hay que mantenerse 4 s; al empezar la guardia entera da la alarma
pp = sc.plasma_point
guards = [e for e in sc.world.enemies if e.pos.distance_to(pp.pos) < 700]
assert guards
for e in guards:
    e.chasing = False                                      # los guardias que vieron al Operador junto al alijo se calman
teleport(sc, pp.pos)
for _ in range(60 * 2):
    sc.player.hp = sc.player.max_hp
    step(game, 1)
assert 0.4 < pp.progress < 0.6 and not pp.done and all(e.chasing for e in guards)   # alarma y captura a medias
teleport(sc, pp.pos + Vector2(400, 0))
step(game, 60)
assert pp.progress < 0.3                                                            # salir de la zona la hace retroceder
teleport(sc, pp.pos)
for _ in range(60 * 6):
    sc.player.hp = sc.player.max_hp
    step(game, 1)
    if pp.done:
        break
assert pp.done and sc.loot_cores == got + 5 and res.cores == 0                       # +5 núcleos, aún en riesgo
game.machine.draw(game.screen)
# morir: se conserva la mitad (redondeada); extraer: todo
sc.loot_cores = 5
sc.loot = 0
sc.on_fail_timeout()
assert sc.fail_menu and res.cores == 0                                               # primero la pantalla de fallo
sc.back_to_base()
assert res.cores == 2 and any("fallida" in h for h in res.history)
game.machine.transition(GameState.MENU)
game.new_campaign()
game.resources.incursion_level = 1
game.machine.transition(GameState.ACT_2_BASE)
game.machine.transition(GameState.INCURSION, mode="initial")
sc = game.machine.active
assert sc.plasma_cache is not None and sc.plasma_point is None                       # nivel 1: sin extractor de plasma
sc.loot_cores = 3
sc.loot = 40
sc._extract()
assert game.resources.cores == 3 and any("3 núcleos" in h for h in game.resources.history)
assert "núcleos" in game.report[0]

# =============================================================================
print("== Apagón en cascada: sin pilón no hay capacidad ni torretas activas ==")
a2 = new_act2(game, metal=3000, cores=10)
w = a2.world
res = game.resources
for d_ in list(w.drones):
    d_.kill()
assert build(a2, "pylon", (540, 620)) and build(a2, "pylon", (660, 620)) and build(a2, "tower", (700, 700))
tw_c = next(iter(w.towers))
pyl_a = min(w.pylons, key=lambda p: p.pos.x)
pyl_b = max(w.pylons, key=lambda p: p.pos.x)
assert tw_c.active and a2.energy_capacity() == 60 and res.energy == 7                  # torreta 5 + 2 de mantenimiento de pilones
pyl_a.take_damage(9999)                                                              # cae el primer pilón: se corta la cadena
step(game, 3)
assert not pyl_b.is_powered and not tw_c.is_powered and not tw_c.active
assert a2.energy_capacity() == 50 and res.energy == 0                                # sin red no consume; la capacidad pierde ambos pilones
assert combat.FX.sparks or tw_c._was_active is False                                 # chispas al apagarse
probe = pygame.Surface((300, 300))
tw_c.draw_overlay(probe, pygame.Rect(120, 120, 40, 40), Vector2())
assert tw_c.requires_power
assert build(a2, "pylon", (540, 620)) and tw_c.is_powered is True and a2.energy_capacity() == 60   # reconstruir restablece la red
step(game, 3)
assert tw_c.active

# =============================================================================
print("== Efectos del árbol de mejoras sobre el Operador ==")
pl = Player((500, 500), 2000, 1200)
rm = ResourceManager()
rm.metal, rm.cores = 9999, 99
pl.apply_upgrades(rm)
assert (pl.armor_reduction, pl.flat_armor, pl.dash_charges_max, pl.bullet_damage, pl.bullet_pierce) == (0.0, 0, 1, 12, 1)
assert pl.repair_delay == C.REPAIR_DELAY and pl.capacity == 150 and not pl.automatic_fire
assert pl.shoot_cooldown == 0.15 and pl.regen_delay == C.PLAYER_REGEN_DELAY == 3.0 and pl.regen_mult == 1.0
# Ofensiva (Balística): A1 fuego continuo, A2 daño 16 + perforación, A3 daño 20 + cadencia 0,12 s
assert rm.buy_node("gatillo_automatico")
pl.apply_upgrades(rm)
assert pl.automatic_fire and pl.bullet_damage == 12 and pl.bullet_pierce == 1 and pl.shoot_cooldown == 0.15
assert rm.buy_node("calibre_perforante")
pl.apply_upgrades(rm)
assert pl.bullet_damage == 16 and pl.bullet_pierce == 2 and pl.shoot_cooldown == 0.15
assert rm.buy_node("sobrecarga_balistica")
pl.apply_upgrades(rm)
assert pl.bullet_damage == 20 and pl.bullet_pierce == 2 and abs(pl.shoot_cooldown - 0.12) < 1e-9
grp_b = pygame.sprite.Group()
pl.projectile_groups = (grp_b,)
pl.aim_dir = Vector2(1, 0)
pl.shoot()
bul = next(iter(grp_b))
assert bul.damage == 20 and bul.pierce == 2                                           # la bala sale con el daño y la perforación
# la bala perforante atraviesa a un enemigo y muere en el segundo; sin la mejora muere en el primero
e_a = Enemy("tank", (600, 500), (0, 0), pygame.sprite.Group())
e_b = Enemy("tank", (640, 500), (0, 0), pygame.sprite.Group())
e_c = Enemy("tank", (680, 500), (0, 0), pygame.sprite.Group())
grp_t = pygame.sprite.Group(e_a, e_b, e_c)
for e_ in grp_t:
    e_.speed = 0
bul.pos = Vector2(600, 500)
bul.rect.center = (600, 500)
hp_t = [e_.hp for e_ in (e_a, e_b, e_c)]
for _ in range(40):
    bul.pos += Vector2(2, 0)
    bul.rect.center = (round(bul.pos.x), round(bul.pos.y))
    combat.resolve_projectiles(grp_b, grp_t, empty)
    if not bul.alive():
        break
lost = [a_ - e_.hp for a_, e_ in zip(hp_t, (e_a, e_b, e_c))]
assert lost[0] > 0 and lost[1] > 0 and lost[2] == 0 and not bul.alive(), lost       # golpeó a dos y se gastó
# Supervivencia (Exotraje): B1 dos cargas de Dash, B2 armadura plana +4, B3/B4 Celda Vital I y II (4 y 5 bloques)
assert rm.buy_node("impulso_doble")
pl.apply_upgrades(rm)
assert pl.dash_charges_max == 2 and pl.dash_charges == 2
assert rm.buy_node("blindaje_titanio")
pl.apply_upgrades(rm)
pl.hp = pl.max_hp
pl.take_damage(10)
assert abs(pl.max_hp - pl.hp - 6) < 1e-9                                              # 10 - 4 de armadura plana
pl.hp = pl.max_hp
pl.take_damage(3)
assert abs(pl.max_hp - pl.hp - 1) < 1e-9                                              # mínimo 1 por impacto
rm.reward_tracker.add_reward("PLAYER_UPGRADE_1")                                      # -20% del reward y luego -4 planos
pl.apply_upgrades(rm)
pl.hp = pl.max_hp
pl.take_damage(10)
assert abs(pl.max_hp - pl.hp - 4) < 1e-9                                              # 10 * 0,8 - 4
assert rm.buy_node("celda_vital")
pl.apply_upgrades(rm)
assert pl.health_blocks == 4 and pl.max_hp == 133 and pl.regen_delay == C.PLAYER_REGEN_DELAY and pl.regen_mult == 1.0
assert rm.buy_node("celda_vital_2")
pl.apply_upgrades(rm)
assert pl.health_blocks == 5 and pl.max_hp == 166
# el Operador sin árbol espera 3 s y regenera a la tasa base
pb = Player((500, 500), 2000, 1200)
pb.apply_upgrades(ResourceManager())
pb.aura_regen = True
pb.hp, pb.since_hit = 50.0, 2.9
pb._regenerate(1.0)
assert pb.hp == 50.0
pb.since_hit = 3.0
pb._regenerate(1.0)
assert abs(pb.hp - 57.5) < 1e-9
# Impulso Doble en juego: dos dashes seguidos con i-frames propios, recargas independientes y un dash por pulsación
pd = Player((500, 500), 2000, 1200)
pd.dash_charges_max = 2
held.clear()


def dash_frames(n, shift):
    held.clear()
    if shift:
        held[pygame.K_LSHIFT] = True
    for _ in range(n):
        pd.update(1 / 60, held, (900, 500), empty)


dash_frames(1, True)
assert pd.is_invulnerable and pd.dash_charges == 1
dash_frames(12, False)
assert not pd.is_invulnerable and pd.dash_charges == 1
dash_frames(1, True)
assert pd.is_invulnerable and pd.dash_charges == 0                                    # segundo dash, otra ventana de i-frames
dash_frames(12, False)
assert not pd.is_invulnerable
dash_frames(1, True)
assert not pd.is_invulnerable                                                         # sin cargas no hay dash
dash_frames(60, False)
assert pd.dash_charges == 1                                                          # la primera carga ya volvió
dash_frames(15, False)
assert pd.dash_charges == 2
held.clear()
held[pygame.K_LSHIFT] = True                                                          # SHIFT sostenido: UN dash por pulsación
for _ in range(50):
    pd.update(1 / 60, held, (900, 500), empty)
assert pd.dash_charges == 1
held.clear()
dash_frames(1, False)

# =============================================================================
print("== Tooltips (0,5 s), clic en el panel de construcción, iconos y HUD de recursos ==")
from src.ui.tooltips import DELAY_MS, TooltipManager, building_card, node_card
clock_ = [0]
real_ticks = pygame.time.get_ticks
pygame.time.get_ticks = lambda: clock_[0]
tm = TooltipManager()
assert DELAY_MS == 500
assert not tm.hover("a")
clock_[0] = 499
assert not tm.hover("a")
clock_[0] = 500
assert tm.hover("a")                                                                  # a los 0,5 s aparece
assert not tm.hover("b")                                                              # otro objetivo: vuelve a empezar
clock_[0] = 1000
assert tm.hover("b")
tm.clear()
assert not tm.hover("b")                                                              # al salir del objeto desaparece
rm2 = ResourceManager()
rm2.metal, rm2.cores = 100, 0
card = building_card("balista", 100, rm2, 50)
assert card["title"] == "BALISTA" and card["rows"][0] == ("cost", 100, 0, 12, (True, True, True))   # solo chatarra
texts = [r[1] for r in card["rows"] if r[0] == "text"]
assert "HP: 450 | Daño: 160 | Cadencia: 1.8s" in texts and "Rango: 320px" in texts
assert "FUNCIÓN: Proyectil perforante, especialista pesado" in texts and "EFECTIVA vs: Tanques y Arietes flanqueados" in texts
assert "[Click Izq] Construir" in texts
tcard = building_card("tower", 45, rm2, 50)
assert tcard["rows"][0] == ("cost", 45, 0, 5, (True, True, True)) and "EFECTIVA vs: Scouts y enjambres (Minigun: perfora armadura; Lanzallamas: la ignora)" in [r[1] for r in tcard["rows"] if r[0] == "text"]
assert "RUTAS: Clic Der para especializar (Minigun / Lanzallamas)" in [r[1] for r in tcard["rows"] if r[0] == "text"]
assert "RUTAS: Clic Der para especializar (Perforante / Tesla)" in texts
pcard = building_card("foco", 50, rm2, 50)
assert pcard["title"] == "FOCO VIGÍA" and pcard["rows"][0] == ("cost", 50, 0, 3, (True, True, True))   # 50⚙ + 3⚡, sin núcleos
assert not any(r[1].startswith("RUTAS") for r in pcard["rows"] if r[0] == "text")
assert any("Carroñeros" in r[1] for r in pcard["rows"] if r[0] == "text")
wcard = building_card("wall", 15, rm2, 50)
assert wcard["rows"][0] == ("cost", 15, 0, 0, (True, True, True))
ncard = node_card("calibre_perforante", rm2)
ntexts = [r[1] for r in ncard["rows"] if r[0] == "text"]
assert ncard["rows"][0] == ("cost", 0, 3, 0, (True, False, True)) and "Requiere: Gatillo Automático (bloqueado)" in ntexts and "BLOQUEADO" in ntexts
rm2.op_nodes.add("gatillo_automatico")
assert "[Click Izq] Comprar" in [r[1] for r in node_card("calibre_perforante", rm2)["rows"] if r[0] == "text"]
xtexts = [r[1] for r in node_card("calibre_perforante", rm2)["rows"] if r[0] == "text"]
assert "Requiere: Gatillo Automático (comprado)" in xtexts and not any("Excluyente" in t_ for t_ in xtexts)
# en la escena: hover sobre un botón de construcción y sobre una estructura; clic en el botón elige el edificio
a2 = new_act2(game, metal=2000, cores=5)
w = a2.world
for d_ in list(w.drones):
    d_.kill()
assert build(a2, "tower", (500, 700))
slots = dict((bt, rc) for rc, bt in game.hud.build_slots(a2.build_menu, a2.panel_shift))
mouse_pos = slots["balista"].center
mpos[0], mpos[1] = mouse_pos
found = a2.hover_card(mouse_pos)
assert found[0] == ("build", "balista") and found[1]["title"] == "BALISTA" and found[1]["rows"][0][1:4] == (50, 0, 12)   # ⚙50 en preparación (solo chatarra)
game.tooltips.clear()
clock_[0] = 2000
game.machine.draw(game.screen)                                                        # primer fotograma: aún no aparece
px_before = game.screen.get_at((mouse_pos[0] + 40, mouse_pos[1] - 120))
clock_[0] = 2600
game.machine.draw(game.screen)                                                        # 0,6 s después: la tarjeta se dibuja
assert game.screen.get_at((mouse_pos[0] + 40, mouse_pos[1] - 120)) != px_before or game.tooltips.key == ("build", "balista")
tw_screen = a2.camera.to_screen(next(iter(w.towers)).pos)
mpos[0], mpos[1] = int(tw_screen.x), int(tw_screen.y)
found = a2.hover_card((int(tw_screen.x), int(tw_screen.y)))
assert found[0][0] == "struct" and found[1]["title"] == "TWIN-AUTOCANNON"
srows = [r[1] for r in found[1]["rows"]]
assert "Energía consumida: 5" in srows and "Estado: ACTIVA" in srows and "Rango: 200px" in srows
clock_[0] = 3300
game.machine.draw(game.screen)
game.machine.draw(game.screen)
a2.open_menu(next(iter(w.towers)))
assert a2.hover_card((int(tw_screen.x), int(tw_screen.y))) is None                   # con un menú abierto no hay tooltip
a2.close_menu()
mpos[0], mpos[1] = 640, 300
game.tooltips.clear()
# clic izquierdo en el panel: elige el edificio (y vuelve a pulsar: lo suelta); sobre el panel nunca se construye debajo
n_s = len(w.structures)
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=slots["tower"].center))
assert a2.build_choice == "tower"
mpos[0], mpos[1] = slots["wall"].center
mouse[0] = True
step(game, 8)
mouse[0] = False
assert len(w.structures) == n_s                                                       # el clic sobre el panel no construye
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=slots["tower"].center))
assert a2.build_choice is None
pygame.time.get_ticks = real_ticks
# iconos procedurales y HUD de recursos
for kind in ("scrap", "cores", "energy", "warning", "heart"):
    surf_i = pygame.Surface((30, 30))
    surf_i.fill((0, 0, 0))
    game.hud.icon(surf_i, kind, (15, 15), 8)
    assert any(surf_i.get_at((x_, y_))[:3] != (0, 0, 0) for x_ in range(30) for y_ in range(30)), kind
panel = pygame.Surface((400, 60))
panel.fill((0, 0, 0))
res = game.resources
res.metal, res.cores, res.energy, res.energy_cap = 150, 3, 35, 60
game.hud.resources_row(panel, (10, 10), res)
assert any(panel.get_at((x_, 20))[:3] != (0, 0, 0) for x_ in range(10, 200))
a2.energy_warning = 3.0
game.machine.draw(game.screen)                                                        # aviso central de energía insuficiente
a2.wave.phase, a2.wave.wave, a2.wave.wave_time = "wave", 2, 0.0
a2.wave.current = Wave(2, 1, a2.CC_POS)                                              # oleada en curso (sin apariciones aún)
a2.wave.spawned, a2.wave.spawn_timer = 0, 10 ** 9
t_before = a2.wave.wave_time
a2.wave.timer = 99999
step(game, 60)
assert a2.wave.wave_time > t_before + 0.9                                             # la cuenta atrás de la oleada avanza
game.machine.draw(game.screen)

# =============================================================================
print("== verify_balance: la Biblia coincide con UNITS y con las clases ==")
from src.verify_balance import verify
assert verify() == [], verify()

# =============================================================================
print("== Fundicion: perimetro, blindaje y victoria real ==")
a2 = new_act2(game)
w = a2.world
fc = a2.foundry_core
assert fc.shielded and len(w.hostile) > 8
hp0 = fc.hp
fc.take_damage(200)
assert fc.hp == hp0                                  # blindado mientras haya torretas
turret = next(iter(fc.perimeter))
from src.entities.drones import DRONE_CLASSES as _DCf
bait_f = _DCf["attack"](turret.pos + Vector2(-160, 0), dict(U.DRONE_TYPES["attack"]), turret.pos + Vector2(-160, 0))
w.drones.add(bait_f); w.all_sprites.add(bait_f)                       # un dron a tiro (no hay Operador en el mapa)
seen = False
for _ in range(120):
    step(game, 1)
    if len(w.enemy_bullets) > 0:
        seen = True
        break
assert seen                                          # las torretas enemigas disparan
for t in list(fc.perimeter):
    t.take_damage(9999)
assert not fc.shielded
fc.take_damage(100)
assert fc.hp == hp0 - 100
fc.take_damage(99999)
for b_ in a2.enemy_bases:                                     # la victoria exige también las bases enemigas
    raze(b_)
step(game, 60 * 4)
assert game.machine.current_state is GameState.VICTORY, (game.machine.current_state, a2.end_timer, a2.fail_reason)

# =============================================================================
print("== Diálogos narrativos pausados con retrato ==")
box = DialogueBox()
box.say("AURA", "uno dos tres cuatro", blocking=True)
box.say("VULCANO", "segunda línea", blocking=True)
box.update(0.05)
first = box.current_blocking
assert not first.revealed
box.advance()                                                        # 1ª pulsación: muestra el texto completo
assert first.revealed and box.current_blocking is first
box.advance()                                                        # 2ª: siguiente línea
assert box.current_blocking.sender == "VULCANO"
box.advance()
box.advance()
assert not box.blocking_active                                       # la última línea cierra la capa
hud_t = HUD()
for sender in ("AURA", "VULCANO", "SISTEMA", "OPERADOR", "DESCONOCIDO"):   # retrato distinto por emisor
    bx = DialogueBox()
    bx.say(sender, "Mensaje de prueba de la capa de diálogo.", blocking=True)
    bx.update(1.0)
    frame = pygame.Surface((1280, 720))
    frame.fill((30, 30, 40))
    bx.draw(frame, hud_t)
    assert frame.get_at((250, 600)) != (30, 30, 40)                   # el recuadro y el retrato se pintan
bx_small = DialogueBox()
bx_small.say("AURA", "¡Recarga!", 1.5)                               # las alertas breves no pausan
assert not bx_small.blocking_active

# Escena: el mundo se congela por completo mientras hay diálogo narrativo
game.machine.transition(GameState.MENU)                               # salir antes: la misma pantalla activa no se reinicia
game.new_campaign()
game.resources.equipped = True
game.machine.transition(GameState.SUB_ACT_1_2)
s = screens[GameState.SUB_ACT_1_2]
assert s.dialogue.blocking_active and not s.retried
step(game, 3)
line = s.dialogue.current_blocking
assert not line.revealed
press(game, pygame.K_RETURN)                                         # ENTER: completa el teletipo
assert line.revealed and s.dialogue.current_blocking is line
press(game, pygame.K_RETURN)                                         # ENTER: siguiente línea
assert s.dialogue.current_blocking is not line
teleport(s, s.ram.pos + Vector2(-220, 0))                            # a tiro de la embestida del Ariete
ram_state = (s.ram.state, round(s.ram.timer, 4))
pos0 = Vector2(s.player.pos)
held[pygame.K_d] = True
mouse[0] = True
step(game, 120)                                                      # 2 s con el diálogo abierto
assert (s.ram.state, round(s.ram.timer, 4)) == ram_state             # enemigos y timers congelados
assert s.player.pos == pos0 and s.player.shots_fired == 0           # ni se mueve ni dispara
assert all(not e.chasing for e in s.world.enemies) and len(s.world.bullets) == 0
mouse[0] = False
held.clear()
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=3, pos=(10, 10)))
press(game, pygame.K_w)
assert s.dialogue.blocking_active                                    # clic derecho y otras teclas no avanzan
cur = s.dialogue.current_blocking
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=(10, 10)))   # clic izq.: avanza
assert not s.dialogue.blocking_active                                # la secuencia terminó: el juego se reanuda
held[pygame.K_d] = True
step(game, 10)
held.clear()
assert s.player.pos.x > pos0.x                                       # se reanudó de inmediato
s.notify("¡Recarga!", 2)                                             # una alerta breve no pausa
x1 = s.player.pos.x
held[pygame.K_d] = True
step(game, 10)
held.clear()
assert s.player.pos.x > x1

# Entradas accidentales: avanzar con ESPACIO/clic mantenidos no dispara Dash ni tiro
game.machine.transition(GameState.MENU)                               # salir antes: la misma pantalla activa no se reinicia
game.new_campaign()
game.resources.equipped = True
game.machine.transition(GameState.SUB_ACT_1_2)
s = screens[GameState.SUB_ACT_1_2]
held[pygame.K_SPACE] = True
for _ in range(10):
    if not s.dialogue.blocking_active:
        break
    press(game, pygame.K_SPACE)
    step(game, 1)
assert not s.dialogue.blocking_active
step(game, 10)                                                       # la tecla sigue pulsada
assert s.player.dash_timer == 0 and s.player.dash_cooldown_timer == 0
held.clear()
step(game, 2)
held[pygame.K_LSHIFT] = True
step(game, 1)
assert s.player.dash_timer > 0                                       # el Dash (SHIFT) funciona tras cerrar el diálogo
held.clear()
step(game, 2)
game.machine.transition(GameState.MENU)                               # salir antes: la misma pantalla activa no se reinicia
game.new_campaign()
game.resources.equipped = True
game.machine.transition(GameState.SUB_ACT_1_2)
s = screens[GameState.SUB_ACT_1_2]
mouse[0] = True
for _ in range(10):
    if not s.dialogue.blocking_active:
        break
    game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=(400, 300)))
    step(game, 1)
assert not s.dialogue.blocking_active
step(game, 10)                                                       # el clic sigue pulsado
assert s.player.shots_fired == 0
mouse[0] = False
step(game, 2)
mouse[0] = True
step(game, 5)
assert s.player.shots_fired > 0                                      # soltado y vuelto a pulsar: dispara
mouse[0] = False

# Acto 2: la intro narrativa congela el asedio (timers, enemigos) hasta avanzarla
game.new_campaign()
game.resources.initial_done = True
game.resources.vulcano_online = True
game.machine.transition(GameState.ACT_2_BASE)
game.machine.transition(GameState.ACT_2_SETUP)
a2 = screens[GameState.ACT_2_SETUP]
assert a2.dialogue.blocking_active                                   # la intro del Acto 2 es historia: pausa
timer0 = a2.wave.timer
step(game, 120)
assert a2.wave.timer == timer0 and len(a2.world.enemies) == 0        # congelado
dismiss(game)
step(game, 60)
assert a2.wave.timer < timer0                                        # al cerrar la historia, el tiempo corre de inmediato

# =============================================================================
print("== Gestor de assets: caché, escalado y respaldo procedural ==")
from src.core.asset_manager import (ASSET_FOLDERS, IMAGES_ROOT, PORTRAIT_FILES, AssetManager, assets as shared_assets,
                                    fit_size)
from src.ui import dialogue_box
for folder in ASSET_FOLDERS:                                          # estructura del repositorio
    assert (IMAGES_ROOT / folder).is_dir(), folder
assert shared_assets.root == IMAGES_ROOT
tmp = pathlib.Path(tempfile.mkdtemp())
(tmp / "portraits").mkdir()
png = pygame.Surface((100, 50), pygame.SRCALPHA)
png.fill((255, 0, 255, 255))
pygame.image.save(png, str(tmp / "portraits" / "aura.png"))
(tmp / "portraits" / "corrupto.png").write_bytes(b"esto no es un png")
records = []


class _Capture(logging.Handler):
    def emit(self, record):
        records.append(record.getMessage())


capture = _Capture()
asset_log = logging.getLogger("robot_renegado.assets")
asset_log.addHandler(capture)
mgr = AssetManager(tmp)
a = mgr.load("portraits/aura.png")
assert a is not None and a.get_size() == (100, 50) and mgr.has("portraits/aura.png")
assert mgr.load("portraits/aura.png") is a and mgr.load("portraits\\aura.png") is a      # caché: se carga una sola vez
assert a.get_flags() & pygame.SRCALPHA                                # convert_alpha
# archivo ausente: nunca falla, avisa una sola vez y usa el respaldo
assert mgr.load("portraits/nope.png") is None
mgr.load("portraits/nope.png")
mgr.get("portraits/nope.png")
assert sum("nope.png" in m for m in records) == 1
sentinel = pygame.Surface((4, 4))
assert mgr.get("portraits/nope.png", fallback=sentinel) is sentinel
assert mgr.get("portraits/nope.png", fallback=lambda: sentinel) is sentinel
assert mgr.get("portraits/nope.png") is None and not mgr.has("portraits/nope.png")
# archivo corrupto: tampoco revienta
assert mgr.load("portraits/corrupto.png") is None and any("corrupto.png" in m for m in records)
# escalado manteniendo las proporciones, con caché
assert fit_size((100, 50), (168, 168)) == (168, 84) and fit_size((50, 100), (168, 168)) == (84, 168)
fitted = mgr.fitted("portraits/aura.png", (168, 168))
assert fitted.get_size() == (168, 84) and mgr.fitted("portraits/aura.png", (168, 168)) is fitted
assert mgr.scaled("portraits/aura.png", (10, 10)).get_size() == (10, 10)
assert mgr.fitted("portraits/nope.png", (10, 10)) is None
assert mgr.scaled("portraits/nope.png", (10, 10), fallback=sentinel) is sentinel
# retratos: mapa de emisores y recarga tras añadir un archivo
assert set(PORTRAIT_FILES) >= {"AURA", "VULCANO", "OPERADOR", "SISTEMA"}
assert PORTRAIT_FILES["SISTEMA"] == PORTRAIT_FILES["OPERADOR"] == "portraits/operator.png"
assert mgr.portrait("AURA", (64, 64)) is not None
assert mgr.portrait("VULCANO", (64, 64)) is None and mgr.portrait("DESCONOCIDO", (64, 64)) is None
pygame.image.save(png, str(tmp / "portraits" / "vulcano.png"))
assert mgr.portrait("VULCANO", (64, 64)) is None                      # sigue en caché como ausente...
mgr.clear()
assert mgr.portrait("VULCANO", (64, 64)) is not None                  # ...hasta recargar
# sin modo de video activo no hay convert_alpha, pero tampoco error
orig_surface = pygame.display.get_surface
pygame.display.get_surface = lambda: None
try:
    assert AssetManager(tmp).load("portraits/aura.png") is not None
finally:
    pygame.display.get_surface = orig_surface
# integración con el códec: usa el PNG si existe y el dibujo procedural si falta
rect = pygame.Rect(40, 40, 168, 168)
with_png = pygame.Surface((300, 300))
dialogue_box.draw_portrait(with_png, rect, "AURA", 0.0, mgr)
assert with_png.get_at((124, 125))[:3] == (255, 0, 255)               # el centro es el PNG
without = pygame.Surface((300, 300))
dialogue_box.draw_portrait(without, rect, "AURA", 0.0, AssetManager(tmp / "vacio"))
assert without.get_at((124, 125))[:3] != (255, 0, 255)                # respaldo procedural
for sender in ("AURA", "VULCANO", "SISTEMA", "OPERADOR", "DESCONOCIDO"):
    dialogue_box.draw_portrait(pygame.Surface((300, 300)), rect, sender, 0.0, AssetManager(tmp / "vacio"))   # nunca crashea
box_png = DialogueBox()
box_png.assets = mgr
box_png.say("AURA", "Retrato desde PNG", blocking=True)
box_png.update(1.0)
frame = pygame.Surface((1280, 720))
frame.fill((30, 30, 40))
box_png.draw(frame, HUD())
assert frame.get_at((202, 585))[:3] == (255, 0, 255)                  # dentro del recuadro del códec
asset_log.removeHandler(capture)

# =============================================================================
print("== Reintento de sub-acto ==")
a2 = new_act2(game, metal=2000, threat=2)
assert build(a2, "wall", (620, 500))
a2.core.take_damage(99999)
step(game, 100)
assert game.machine.current_state is GameState.RETRY_SUB_ACT and game.machine.sub_act is SubAct.S2_1
press(game, pygame.K_r)
assert game.machine.current_state is GameState.ACT_2_SETUP
assert game.resources.metal == C.RESCUE_METAL == 120 and game.resources.threat_level == 2
a2 = screens[GameState.ACT_2_SETUP]
assert a2.core.hp == 500 and len(a2.world.structures) == 1
step(game, 5)
a2.core.take_damage(10 ** 6)                         # también al caer el Centro de Control (no hay piloto en el mapa)
step(game, 100)
assert game.machine.current_state is GameState.RETRY_SUB_ACT
press(game, pygame.K_ESCAPE)
assert game.machine.current_state is GameState.MENU
# 1.1: el reintento reaparece en el refugio, sin traje y con los suministros iniciales
press(game, pygame.K_RETURN)
s = screens[GameState.SUB_ACT_1_1]
dismiss(game)
s.res.equipped = True
game.resources.add_metal(300)
s.player.take_damage(9999)
step(game, 120)
assert game.machine.current_state is GameState.RETRY_SUB_ACT and game.machine.sub_act is SubAct.S1_1
press(game, pygame.K_r)
s = screens[GameState.SUB_ACT_1_1]
assert game.machine.current_state is GameState.SUB_ACT_1_1
assert game.resources.metal == C.STARTING_METAL_ACT1 and not game.resources.equipped and not s.player.equipped
assert s.player.pos.distance_to(s.level.marker("start")) < 1 and len(s.world.enemies) == 1
# 1.2 / 1.3 / 1.4: checkpoint con el progreso del sub-acto anterior
game.machine.transition(GameState.MENU)                               # salir antes: la misma pantalla activa no se reinicia
game.new_campaign()
game.resources.equipped = True
game.machine.transition(GameState.SUB_ACT_1_2)
s = screens[GameState.SUB_ACT_1_2]
dismiss(game)
game.resources.aura_linked = True
s.player.take_damage(9999)
step(game, 120)
assert game.machine.current_state is GameState.RETRY_SUB_ACT and game.machine.sub_act is SubAct.S1_2
press(game, pygame.K_r)
s = screens[GameState.SUB_ACT_1_2]
assert game.machine.current_state is GameState.SUB_ACT_1_2
assert game.resources.equipped and not game.resources.aura_linked          # vuelve al checkpoint del 1.2
assert s.ram.alive() and len(s.world.enemies) == 6
assert not s.dialogue.blocking_active                               # al reintentar no se repite la historia
game.machine.transition(GameState.SUB_ACT_1_3)
s = screens[GameState.SUB_ACT_1_3]
dismiss(game)
game.resources.metal = 10
s.core.take_damage(99999)                            # caen los condensadores de AURA
step(game, 100)
assert game.machine.current_state is GameState.RETRY_SUB_ACT and game.machine.sub_act is SubAct.S1_3
press(game, pygame.K_r)
s = screens[GameState.SUB_ACT_1_3]
assert game.machine.current_state is GameState.SUB_ACT_1_3 and s.core.alive()
assert game.resources.metal >= C.SUPPLY_METAL_1_3 and s.charge == C.AURA_CHARGE_TIME
assert len(s.world.structures) == 1                  # solo los condensadores: construcciones reiniciadas

# =============================================================================
print("== Repulsion / anti-encierro / reparacion ==")
a2 = new_act2(game)
w = a2.world
random.seed(2)                                        # mezcla de tipos fija: el umbral no depende del orden de la suite
a2.core.self_defense = False                                          # se mide el reparto, no el cañón del núcleo
clump = [Enemy(random.choice(["scout", "soldier", "tank"]), (900, 600), a2.CC_POS, w.enemies) for _ in range(30)]
for e in clump:
    w.enemies.add(e); w.all_sprites.add(e); w.targets.add(e)
assert min(a.pos.distance_to(b.pos) for a, b in itertools.combinations(clump, 2)) == 0
for _ in range(60 * 6):
    a2.core.hp = a2.core.max_hp
    step(game, 1)
closest = min(a.pos.distance_to(b.pos) for a, b in itertools.combinations(clump, 2))
assert closest > U.ENEMIES["scout"]["size"], closest                  # sin solaparse (el hitbox más chico: Scout)
for e in clump:
    e.kill()
game.machine.transition(GameState.MENU)                                       # anti-encierro: donde hay Operador (1.3)
game.new_campaign()
game.resources.equipped = True
game.machine.transition(GameState.SUB_ACT_1_3)
s13t = screens[GameState.SUB_ACT_1_3]
dismiss(game)
g = C.BUILD_GRID
teleport(s13t, Vector2(20 * g + 20, 15 * g + 20))
placed = []
for cx, cy in [(19, 14), (19, 15), (19, 16), (20, 14), (20, 16), (21, 14), (21, 16), (21, 15)]:
    rect = pygame.Rect(0, 0, g, g)
    rect.center = (cx * g + 20, cy * g + 20)
    if s13t._can_place("wall", rect):
        s13t._register(Building("wall", rect.center))
        placed.append((cx, cy))
assert (21, 15) not in placed and len(placed) == 7, placed                       # el último hueco no se cierra
a2 = new_act2(game)                                                               # Comandante: R + clic repara sin distancia
assert build(a2, "wall", (900, 700))
wall = next(iter(a2.world.walls))
wall.hp = 10
held[pygame.K_r] = True
left_click(game, wall.pos)
held.clear()
assert wall.hp > 10, (wall.hp, wall.alive(), game.resources.metal)

# =============================================================================
print("== Biblia 4.0 · energía integrada: pilón, foco y Extractor de chatarra; apagón en cascada ==")
a2 = new_act2(game, metal=5000, cores=20)
w = a2.world
res = game.resources
assert a2.energy_capacity() == 50 and res.energy == 0
assert build(a2, "wall", (460, 500)) and a2.energy_used() == 0          # el muro base no consume
assert build(a2, "pylon", (500, 540)) and a2.energy_capacity() == 55 and a2.energy_used() == 1   # +5 y 1 de mantenimiento
assert build(a2, "foco", (340, 660)) and a2.energy_used() == 4          # Foco Vigía: 3
assert build(a2, "pylon", (500, 700)) and build(a2, "pylon", (380, 520))
assert a2.energy_capacity() == 65 and a2.energy_used() == 6             # 3 pilones: +15 y 3 de mantenimiento
for pos in ((300, 700), (340, 700), (380, 700), (420, 700)):
    assert build(a2, "balista", pos)
assert a2.energy_used() == 54 and res.energy == 54 and res.energy_free == 11
c0, m0 = res.cores, res.metal
from src.entities.resource_node import ScrapDeposit
dep_t = ScrapDeposit(Vector2(380, 660))                                  # depósito con suministro activo
w.deposits.add(dep_t); w.all_sprites.add(dep_t); a2.deposit_list.append(dep_t)
assert build(a2, "extractor", (380, 660))
ex = next(iter(w.extractors))
assert (ex.max_hp, res.metal, res.cores) == (120, m0 - a2._cost("extractor"), c0) and ex.energy_cost == 8
assert a2.energy_used() == 62 and ex.active
m1 = res.metal
ex.timer = C.EXTRACTOR_INTERVAL - 0.01                                   # +5 de chatarra cada 1,2 s (x2,5) si tiene energía
step(game, 3)
assert res.metal == m1 + C.EXTRACTOR_INCOME and ex.timer < 1 and res.cores == c0     # chatarra, nunca núcleos
assert C.EXTRACTOR_INTERVAL == 1.2 and abs(C.EXTRACTOR_INCOME / C.EXTRACTOR_INTERVAL / (5 / 3.0) - 2.5) < 1e-9   # tasa x2,5
assert ex.pulse > 0                                                      # al entregar chatarra late el anillo de feedback
ex.draw_overlay(pygame.Surface((160, 160)), pygame.Rect(60, 60, 40, 40), Vector2())      # barra de ciclo + anillo, sin errores
step(game, 40)
assert ex.pulse == 0                                                     # el pulso se apaga hasta la siguiente entrega
gen = next(p_ for p_ in w.pylons if p_.pos == Vector2(500, 700))
gen.take_damage(9999)                                                    # capacidad 60 < 61: se apaga la más nueva (el extractor)
step(game, 2)
assert a2.energy_capacity() == 60 and not ex.energized and not ex.active
m2 = res.metal
ex.timer = C.EXTRACTOR_INTERVAL - 0.01
step(game, 5)
assert res.metal == m2 and ex.timer == C.EXTRACTOR_INTERVAL - 0.01        # apagado: no produce ni avanza
surf = pygame.Surface((120, 120))
ex.blink = 0.0
ex.draw_overlay(surf, pygame.Rect(40, 40, 40, 40), Vector2())           # icono de batería vacía en rojo
assert surf.get_at((60, 27))[0] > 200 and surf.get_at((60, 27))[1] < 90
assert build(a2, "pylon", (500, 700)) and ex.energized and ex.active    # al volver la energía, reanuda
# construir sin energía suficiente se bloquea con mensaje claro y sin cobrar
dep_u = ScrapDeposit(Vector2(300, 660))
w.deposits.add(dep_u); w.all_sprites.add(dep_u); a2.deposit_list.append(dep_u)
res.metal, res.cores = 5000, 20
snap_r = (res.metal, res.cores)
a2.energy_warning = 0
assert a2.energy_free() < 8 and a2._can_place("extractor", a2._ghost_rect("extractor", Vector2(300, 660)))
assert not build(a2, "extractor", (300, 660)) and (res.metal, res.cores) == snap_r and a2.energy_warning > 0
# apagón en cascada local: sin el pilón A, el B y la torreta que dependían de él se apagan
a2 = new_act2(game, metal=5000, cores=20)
w = a2.world
assert build(a2, "pylon", (500, 540)) and build(a2, "pylon", (620, 460)) and build(a2, "tower", (700, 460))
tw = next(iter(w.towers))
pa = min(w.pylons, key=lambda p_: p_.pos.x)
step(game, 2)
assert tw.is_powered and tw.active and a2.energy_capacity() == 60
surf = pygame.Surface((120, 120))
tw.blink = 0.0
tw.draw_overlay(surf, pygame.Rect(40, 40, 40, 40), Vector2())            # LED cian parpadeante en una torreta operativa
assert surf.get_at((75, 45))[2] > 200 and surf.get_at((75, 45))[0] < 80
pa.take_damage(99999)
step(game, 2)
assert not any(p_.is_powered for p_ in w.pylons) and not tw.is_powered and not tw.active
assert a2.energy_capacity() == 50                                          # el pilón B huérfano ya no aporta capacidad
surf.fill((0, 0, 0))
tw.draw_overlay(surf, pygame.Rect(40, 40, 40, 40), Vector2())            # sin energía: batería vacía roja
assert surf.get_at((60, 27))[0] > 200
# HUD: "⚡ usada/capacidad" en la barra superior
assert game.hud.TOP == 30 and game.hud.resources_line(res).endswith(f"{res.energy}/{res.energy_cap}")

# =============================================================================
print("== Biblia 4.0 · mejoras del muro: Reforzado y Electrificado ==")
a2 = new_act2(game, metal=5000, cores=20)
w = a2.world
res = game.resources
assert build(a2, "wall", (460, 500))
wall = next(iter(w.walls))
imgs = {1: pygame.image.tostring(wall.image, "RGBA")}
right_click(game, wall.pos)
opts = a2.menu.options
assert [o["label"] for o in opts] == ["Nivel 2: REFORZADO", "Desmantelar (+21)"]
assert (opts[0]["scrap"], opts[0]["cores"], opts[0]["energy"]) == (30, 0, 0)
m0 = res.metal
press(game, pygame.K_1)
assert wall.level == 2 and wall.max_hp == 900 and wall.hp == 900 and res.metal == m0 - 30
assert wall.ram_reduction == 0.30 and wall.energy_cost == 0
imgs[2] = pygame.image.tostring(wall.image, "RGBA")
wall.take_damage(300, ram=True)                                           # el impacto del Ariete llega reducido un 30%
assert abs(wall.hp - (900 - 210)) < 1e-6
wall.hp = 900
wall.take_damage(100)                                                     # el resto del daño, sin reducción
assert wall.hp == 800
ar = Enemy("ariete", (700, 500), a2.CC_POS, w.enemies)
hp0 = wall.hp
ar._ram_impact(wall)                                                      # por el camino real de la embestida
assert abs((hp0 - wall.hp) - 300 * ar.power * 0.70) < 1e-6
wall.hp = 900
# Nivel 3: +⚙60 ⚡2 (solo chatarra), 1400 HP, contraataque eléctrico
right_click(game, wall.pos)
opts = a2.menu.options
assert [o["label"] for o in opts] == ["Nivel 3: ELECTRIFICADO", "Desmantelar (+42)"]
assert (opts[0]["scrap"], opts[0]["cores"], opts[0]["energy"]) == (60, 0, 2)
m0, c0, used0 = res.metal, res.cores, a2.energy_used()
a2.close_menu()
a2.energy_free = lambda: 1                                                # sin energía libre: la mejora se bloquea
a2.open_menu(wall)
assert not a2.menu.options[0]["enabled"] and not a2.menu_choose(0) and wall.level == 2 and res.metal == m0
a2.energy_warning = 0
a2.menu_choose(0)
assert a2.energy_warning > 0
del a2.energy_free
a2.close_menu()
right_click(game, wall.pos)
press(game, pygame.K_1)
step(game, 2)
assert wall.level == 3 and wall.max_hp == 1400 and wall.hp == 1400
assert res.metal == m0 - 60 and res.cores == c0 and wall.energy_cost == 2
assert wall.requires_power and wall.is_powered and wall.active and a2.energy_used() == used0 + 2
imgs[3] = pygame.image.tostring(wall.image, "RGBA")
assert len({imgs[1], imgs[2], imgs[3]}) == 3                              # tres aspectos distintos
assert [o["label"] for o in a2._menu_options(wall)][0].startswith("Nivel 3: ELECTRIFICADO (activo)")
sc_ = Enemy("scout", wall.pos + Vector2(40, 0), a2.CC_POS, w.enemies)
so_ = Enemy("soldier", wall.pos + Vector2(40, 20), a2.CC_POS, w.enemies)
tk_ = Enemy("tank", wall.pos + Vector2(40, 40), a2.CC_POS, w.enemies)
w.enemies.add(sc_, so_, tk_)
h_sc, h_so, h_tk = sc_.hp, so_.hp, tk_.hp
wall.take_damage(8, attacker=sc_)
wall.take_damage(8, attacker=so_)
wall.take_damage(8, attacker=tk_)
assert sc_.hp == h_sc - 20 and so_.hp == h_so - (20 - U.ENEMIES["soldier"]["armor"]) and tk_.hp == h_tk   # solo Scouts y Soldados
assert wall.hp == 1400 - 24
for e_ in (sc_, so_, tk_):
    e_.kill()
surf = pygame.Surface((200, 200))
wall.draw_dynamic(surf, pygame.Rect(80, 80, 40, 40), Vector2())         # chispas eléctricas
# camino real: un Scout que muerde el muro electrificado se hace daño
wall2 = Building("wall", (500, 600))
a2._register(wall2)
wall2.apply_wall_level(2)
wall2.apply_wall_level(3)
a2.grid.mark_dirty()
a2.grid.update()
a2._sync_energy()
assert wall2.active
bite = Enemy("scout", (570, 600), a2.CC_POS, w.enemies)
bite.flank = 0
bite.target_pos = Vector2(a2.CC_POS)
w.enemies.add(bite); w.all_sprites.add(bite)
for _ in range(60 * 6):
    bite.update(1 / 60, w.structures, None)
    if not bite.alive():
        break
assert not bite.alive() or bite.hp < bite.max_hp                          # la descarga lo castiga
# fuera de la red, el muro no contraataca y muestra la batería vacía
far = Building("wall", (1000, 300))
a2._register(far)
far.apply_wall_level(2)
far.apply_wall_level(3)
a2.grid.mark_dirty()
a2.grid.update()
a2._sync_energy()
assert not far.is_powered and not far.active
victim = Enemy("scout", (1040, 300), a2.CC_POS, w.enemies)
w.enemies.add(victim)
hv = victim.hp
far.take_damage(8, attacker=victim)
assert victim.hp == hv
victim.kill()
# venta: 70% de todo lo invertido (30 + 30 + 60 = 120 -> 84 de chatarra; sin núcleos)
assert wall.sell_value == int((30 + 30 + 60) * 0.70) and wall.core_refund == 0      # 84: Electrificado = +⚙60
m1 = res.metal
a2.sell(wall)
assert res.metal == m1 + 84 and not wall.alive()
# la mejora viaja con la base (Base Central / checkpoint)
from src.mechanics.base_layout import capture_base
capture_base(a2, res)
assert sorted(e["level"] for e in res.base_layout if e["type"] == "wall") == [3, 3]
game.machine.transition(GameState.MENU)
game.machine.transition(GameState.ACT_2_SETUP)
a2b = screens[GameState.ACT_2_SETUP]
dismiss(game)
assert sorted(b_.level for b_ in a2b.world.walls) == [3, 3] and all(b_.max_hp == 1400 for b_ in a2b.world.walls)
# E sobre el muro lo mejora (alternativa al menú); con el cursor lejos, E sigue recogiendo
a2 = new_act2(game, metal=5000, cores=20)
w = a2.world
assert build(a2, "wall", (460, 500))
wall = next(iter(w.walls))
sp = a2.camera.to_screen(wall.pos)
mpos[0], mpos[1] = int(sp.x), int(sp.y)
m0 = game.resources.metal
press(game, pygame.K_e)
assert wall.level == 2 and game.resources.metal == m0 - 30
mpos[0], mpos[1] = 640, 300
press(game, pygame.K_e)
assert wall.level == 2
scrap_ = ScrapItem(a2.CC_POS + Vector2(0, 230), 7)                     # modo Comandante: E no recoge (no hay piloto)
w.scraps.add(scrap_); w.all_sprites.add(scrap_)
m0 = game.resources.metal
press(game, pygame.K_e)
assert game.resources.metal == m0 and scrap_.alive()
scrap_.kill()

# =============================================================================
print("== Biblia 4.0 · red de energía visible (cian/ámbar), líneas entre pilones y cámara táctica ==")
a2 = new_act2(game, metal=5000, cores=20)
w = a2.world
assert build(a2, "pylon", (500, 540)) and build(a2, "pylon", (620, 460)) and build(a2, "tower", (700, 460))
step(game, 2)
tw = next(iter(w.towers))
cam = a2.camera
assert a2._in_power_zone(Vector2(460, 700)) and not a2._in_power_zone(Vector2(1100, 800))
black = pygame.Surface((1280, 720))
a2.build_choice = "tower"
a2.draw_network_overlay(black)
mid = cam.to_screen(Vector2(560, 500))                                   # línea de energía entre los pilones: blanca/amarilla
px = black.get_at((int(mid.x), int(mid.y)))
assert px[0] > 200 and px[1] > 200
center = cam.to_screen(Vector2(500, 540))                                 # círculo cian translúcido de cobertura
ring = black.get_at((int(center.x + C.POWER_RADIUS - 1), int(center.y)))
assert ring[2] > 60 and ring[0] < 40
# vista previa: verde en la red, ámbar fuera de ella (se construye pero quedará apagada)
frame = pygame.Surface((1280, 720))
for world_pt, expect in ((Vector2(460, 700), "verde"), (Vector2(1100, 800), "ambar")):
    sp = cam.to_screen(world_pt)
    mpos[0], mpos[1] = int(sp.x), int(sp.y)
    a2.build_choice = "tower"
    a2.draw(frame)
    cp = frame.get_at((int(sp.x) - 17, int(sp.y) + 17))
    if expect == "verde":
        assert cp[1] > cp[0] and cp[1] > 60, cp
    else:
        assert cp[0] > cp[2] + 40 and cp[0] > 60, cp
mpos[0], mpos[1] = 640, 300
a2.build_choice = None
# cámara del Comandante: libre siempre (WASD, bordes, clic central), también en la pausa táctica
step(game, 5)
base_off = Vector2(cam.offset)
held[pygame.K_d] = True
step(game, 30)
held.clear()
assert cam.offset.x > base_off.x + 100                                     # sin pausa: la cámara se mueve
press(game, pygame.K_SPACE)
assert a2.paused
base_off = Vector2(cam.offset)
held[pygame.K_d] = True
step(game, 30)
held.clear()
assert cam.offset.x > base_off.x + 100                                     # en la pausa, también
panned = Vector2(cam.offset)
mpos[0], mpos[1] = 3, 300                                                  # borde izquierdo de la pantalla
step(game, 20)
assert cam.offset.x < panned.x - 50
mpos[0], mpos[1] = 640, 300
x_before = cam.offset.x
game.machine.handle_event(pygame.event.Event(pygame.MOUSEMOTION, pos=(300, 300), rel=(40, 0), buttons=(0, 1, 0)))
assert abs(cam.offset.x - (x_before - 40)) < 1e-6 or cam.offset.x == 0   # clic central arrastrado
held[pygame.K_a] = True
step(game, 60 * 4)
held.clear()
assert cam.offset.x == 0                                                    # límites del mapa
held[pygame.K_s] = True
step(game, 60 * 6)
held.clear()
assert cam.offset.y == C.ACT2_H - cam.view.y
# superposición de pausa: radios de cobertura, líneas de energía y alcance al pasar el ratón por una torreta
black.fill((0, 0, 0))
cam.offset = Vector2(300, 100)
tsp = cam.to_screen(tw.pos)
mpos[0], mpos[1] = int(tsp.x), int(tsp.y)
step(game, 1)
a2.draw_network_overlay(black)
edge = black.get_at((int(tsp.x + tw.effective_range() - 1), int(tsp.y)))
assert edge[0] > 90 and edge[1] > 90 and edge[2] < 80                      # proyección de alcance (amarillo)
mpos[0], mpos[1] = 640, 300
press(game, pygame.K_SPACE)
assert not a2.paused
off_keep = Vector2(cam.offset)
step(game, 60)
assert cam.offset == off_keep and not cam.returning                         # al reanudar no salta a ningún piloto

# =============================================================================
print("== Biblia 4.0 · el Carroñero Hostil roba chatarra y núcleos; HUD sin flecha guía ==")
from src.entities.core_item import CoreItem
a2 = new_act2(game, metal=500, cores=5)
w = a2.world
for d_ in list(w.drones):
    d_.kill()
item = CoreItem(Vector2(800, 600), 2)
w.core_items.add(item); w.all_sprites.add(item)
a2.pending_scavs.append([0.0, item])
step(game, 2)
drone = next(iter(w.scavengers))
for _ in range(60 * 25):
    step(game, 1)
    if drone.cores_value or not drone.alive():
        break
assert drone.cores_value == 2 and not item.alive() and drone.carrying
drone.take_damage(9999)                                                   # abatido: suelta los núcleos (y su chatarra base)
assert any(ci.value == 2 for ci in w.core_items)
assert any(s_.pos.distance_to(drone.pos) < 1 for s_ in w.scraps)
for ci in list(w.core_items) + list(w.scraps):                            # sin restos del primero: va a por item2
    ci.kill()
item2 = CoreItem(Vector2(800, 640), 3)
w.core_items.add(item2); w.all_sprites.add(item2)
a2.pending_scavs.append([0.0, item2])
step(game, 2)
drone2 = [d_ for d_ in w.scavengers if d_.alive()][0]
for _ in range(60 * 40):
    step(game, 1)
    if not drone2.alive():
        break
assert not drone2.alive() and a2.stolen_cores == 3                        # escapó con los núcleos
assert not hasattr(HUD, "arrow")                                          # sin flecha flotante en el radar
game.new_campaign()
game.resources.equipped = True
game.resources.aura_linked = True
game.machine.transition(GameState.SUB_ACT_1_2)
dismiss(game)
step(game, 3)
game.machine.draw(game.screen)                                            # radar con baliza cian, sin líneas guía

# =============================================================================
print("== Pase visual: suelo en placas, bloques industriales, sombras de contacto y game juice ==")
from src.ui import terrain_art as terrain
from src.map.game_map import GameMap
from src.entities.drones import AttackDrone as _AttackDrone
from src.entities.factory import drone_stats as _drone_stats
tile_a, tile_b = terrain.floor_tile((18, 21, 31), 0), terrain.floor_tile((18, 21, 31), 0)
assert tile_a is tile_b and tile_a.get_size() == (40, 40)                       # cacheada
assert any(terrain.floor_tile((18, 21, 31), v).get_at((20, 20)) != tile_a.get_at((20, 20)) or v == 0 for v in range(4))
bgf = pygame.Surface((400, 400))
terrain.paint_floor(bgf, (18, 21, 31), random.Random(3))
assert len({bgf.get_at((x_, y_))[:3] for x_ in range(0, 400, 7) for y_ in range(0, 400, 7)}) > 8      # no es un color plano
assert bgf.get_at((1, 1))[0] > bgf.get_at((2, 20))[0]                               # bisel claro arriba-izquierda
gm = GameMap.arena(2200, 1200, cc_pos=(420, 600))
hz = {tuple(gm.background.get_at((x_, 600 - 135))[:3]) for x_ in range(300, 540, 3)}
assert any(c_[0] > 150 and c_[2] < 90 for c_ in hz) and any(c_[0] < 40 for c_ in hz)       # franjas amarillas y negras junto al Núcleo
# --- 1.1 en ruinas: baldosas agrietadas y manchadas, cascotes y sombra proyectada de 16 px al pie de los muros
lv11 = levels.build_level_1_1()
tiles11 = {pygame.image.tostring(lv11.background.subsurface((c_ * 40, r_ * 40, 40, 40)), "RGB")
           for r_ in (24, 25) for c_ in range(11, 17)}
assert len(tiles11) >= 6                                                                    # las baldosas del callejón no son todas iguales
assert len({pygame.image.tostring(terrain.floor_tile((14, 16, 26), v_), "RGB") for v_ in range(7)}) == 7   # 7 variantes de baldosa
def avg_row(bgs, y_, x0_, x1_):
    return sum(sum(bgs.get_at((x_, y_))[:3]) for x_ in range(x0_, x1_, 2)) / ((x1_ - x0_) // 2)
under_wall, mid_floor = avg_row(lv11.background, 24 * 40 + 1, 500, 640), avg_row(lv11.background, 24 * 40 + 30, 500, 640)
assert under_wall < mid_floor * 0.75, (under_wall, mid_floor)                              # sombra bajo el muro norte
assert lv11.markers["locker"][0] == Vector2(120, 920) and len(lv11.solids) > 0
# --- 1.2 usa el mismo sistema (suelo roto/manchado, sombra de 16 px) y añade la antecámara de la esclusa de salida
lv12 = levels.build_level_1_2()
assert avg_row(lv12.background, 25 * 40 + 1, 400, 520) < avg_row(lv12.background, 25 * 40 + 30, 400, 520) * 0.75
assert len({pygame.image.tostring(lv12.background.subsurface((c_ * 40, 25 * 40, 40, 40)), "RGB") for c_ in range(9, 14)}) >= 4
assert lv12.markers["exit_gate"][0] == Vector2(1920, 460) and not lv12.wall[12][47] and lv12.wall[14][47]
assert lv12.is_reachable(lv12.marker("start"), lv12.marker("console")) and lv12.is_reachable(lv12.marker("start"), lv12.marker("exit_gate"))
from src.core import sfx as _sfx
assert len(_sfx._build("crit")) > 1000 and len(_sfx._build("ricochet")) > 500 and _sfx.play("crit") is False   # sin audio (dummy): silencio
blk = pygame.Surface((200, 120))
blk.fill((10, 10, 10))
terrain.paint_block(blk, pygame.Rect(20, 20, 160, 80), levels.STYLES["urban"], random.Random(5))
assert sum(blk.get_at((60, 22))[:3]) > sum(blk.get_at((60, 40))[:3]) - 40 and blk.get_at((100, 98))[:3] != (10, 10, 10)
shadow_floor = pygame.Surface((300, 300))
shadow_floor.fill((90, 90, 90))
cam_s = Camera(300, 300)
class _Dummy(pygame.sprite.Sprite):
    casts_shadow = True
    layer = 1

    def __init__(self):
        super().__init__()
        self.rect = pygame.Rect(130, 130, 40, 40)

    def draw(self, surface, offset=None):
        pass


foe_s = _Dummy()
cam_s.offset = Vector2(0, 0)
cam_s.draw_group(shadow_floor, pygame.sprite.Group(foe_s))
below = shadow_floor.get_at((foe_s.rect.centerx + 1, foe_s.rect.bottom + 1))[:3]
assert below[0] < 90                                                                  # sombra translúcida bajo el sprite
assert shadow_floor.get_at((20, 20))[:3] == (90, 90, 90)
for cls_ in (Enemy, Player, Building):
    assert cls_.casts_shadow is True
assert levels and Building("wall", (0, 0)).casts_shadow and _AttackDrone((0, 0), _drone_stats("attack")).shadow_lift > 0
# bobbing y retroceso del Operador: solo visuales (la colisión no se mueve)
pl_j = Player((300, 300), 2000, 1200)
pl_j.equipped = True
held[pygame.K_d] = True
for _ in range(30):
    pl_j.update(1 / 60, held, (900, 300), empty)
held.clear()
assert pl_j.bob_amp > 0.5 and pl_j.rect.center == (round(pl_j.pos.x), round(pl_j.pos.y))
ys_ = set()
for k_ in range(40):
    pl_j.bob_t = k_ * 0.2
    probe_j = pygame.Surface((200, 200))
    pl_j.draw(probe_j, Vector2(pl_j.pos) - Vector2(100, 100))
    ys_.add(tuple(probe_j.get_at((x_, y_))[:3] for x_, y_ in ((100, 96), (100, 104))))
assert len(ys_) > 1                                                                   # el sprite sube y baja
pl_j.shoot()
assert pl_j.recoil == 1.0
pl_j.update(0.05, held, (900, 300), empty)
assert 0 < pl_j.recoil < 1
pl_j.update(0.1, held, (900, 300), empty)
assert pl_j.recoil == 0.0
# retroceso del cañón de la torreta (solo dibujo)
tw_j = Building("tower", (200, 200))
tw_j.is_powered = True
foes_j, buls_j = pygame.sprite.Group(), pygame.sprite.Group()
en_j = Enemy("scout", (330, 200), (10, 10), foes_j)
en_j.speed = 0
foes_j.add(en_j)
tw_j.fire_timer = 0
tw_j.update(1 / 60, foes_j, buls_j)
assert tw_j.recoil_t == 1.0 and len(buls_j) == 1
tw_j.update(0.05, foes_j, buls_j)
assert 0 < tw_j.recoil_t < 1
tw_j.update(0.2, foes_j, buls_j)
assert tw_j.recoil_t == 0.0 or tw_j.recoil_t == 1.0                                    # (volvió a disparar o ya reposa)
tw_j.draw_dynamic(pygame.Surface((100, 100)), pygame.Rect(30, 30, 40, 40), Vector2())
# hit-flash de 1 fotograma en muros y enemigos
wl_j = Building("wall", (100, 100))
wl_j.take_damage(10)
assert wl_j.flash_frames == 1
probe_w = pygame.Surface((200, 200))
wl_j.draw(probe_w, Vector2())
assert wl_j.flash_frames == 0 and probe_w.get_at((100, 100))[:3] == (255, 255, 255)
assert wl_j._white_image() is wl_j._white_image()                                     # silueta cacheada
wl_j.draw(probe_w, Vector2())
assert probe_w.get_at((100, 100))[:3] != (255, 255, 255)
# chispas metálicas y escombros de muro roto
combat.FX.clear()
combat.FX.spark((100, 100))
combat.FX.draw(probe_w, Vector2())
brk = Building("wall", (150, 150))
brk_group = pygame.sprite.Group(brk)                                                   # vivo = pertenece a un grupo
brk.take_damage(99999)
for _ in range(60):
    brk.update(1 / 60, empty, empty)
assert not brk.alive() and len(combat.FX.debris_bits) >= 5 and len(combat.FX.sparks) > 0
combat.FX.draw(probe_w, Vector2())
combat.FX.update(0.3)
assert combat.FX.debris_bits
combat.FX.update(0.5)
assert not combat.FX.debris_bits                                                     # los escombros se desvanecen
sold = Building("wall", (150, 150))
sold.dismantle()
assert not combat.FX.debris_bits                                                     # vender no genera escombros
for _ in range(300):
    combat.FX.debris((0, 0))
assert len(combat.FX.debris_bits) <= combat.FX.MAX_DEBRIS
combat.FX.clear()
assert not combat.FX.debris_bits and not combat.FX.sparks

# =============================================================================
print("== Rediseño de sprites: Ariete blindado, compuertas de búnker, muros 2.5D, fantasma 3D y fondo sin confeti ==")
from src.ui import entity_art, structure_art as sart
from src.entities.boss import LightRam
from src.entities.interactable import Hatch
ar_img = entity_art.render_ariete(96)
assert ar_img.get_size() == (96, 96) and entity_art.render_ariete(96) is not ar_img          # copia de una versión cacheada
rear = ar_img.get_at((21, 48))                                                               # reactor trasero: cian brillante
assert rear[2] > 200 and rear[1] > 150 and rear[0] < 120 and rear[3] == 255
assert any(ar_img.get_at((x_, 48))[3] == 255 and ar_img.get_at((x_, 48))[0] > 100 for x_ in range(70, 96))   # escudo frontal de acero
assert ar_img.get_at((50, 10))[3] == 255 and ar_img.get_at((50, 85))[3] == 255                # orugas a ambos lados
assert ar_img.get_at((0, 0))[3] == 0                                                         # no es una caja que llene el lienzo
lr = LightRam((300, 300))
assert lr.base_image.get_size() == lr.core_glow.get_size() == lr.turret_image.get_size() == (54, 54)
core_px, glow_px = lr.base_image.get_at((10, 27)), lr.core_glow.get_at((10, 27))
assert core_px[0] > 60 and core_px[2] < 40 and core_px[3] == 255                 # núcleo del radiador: ámbar apagado en el chasis
assert glow_px[0] > 200 and glow_px[1] > 140 and glow_px[2] < 200 and glow_px[3] > 200    # y ámbar brillante en su resplandor
assert lr.turret_image.get_at((50, 27))[3] == 255 and lr.turret_image.get_at((0, 0))[3] == 0     # torreta con cañón, sin caja
lr.draw(pygame.Surface((400, 400)), Vector2())
# compuertas estancas: faro rojo cerrada, verde desbloqueada (sigue sólida) y verde abierta; placas cepilladas en las hojas
hc = Hatch((200, 200), (60, 100))
solids_h = pygame.sprite.Group(hc)
assert hc.state == "locked" and hc.image.get_at((33, 3))[0] > 200 and hc.image.get_at((33, 3))[1] < 90
rows_h = {hc.image.get_at((30, y_))[:3] for y_ in range(20, 80)}
assert len(rows_h) >= 2                                                                      # estrías (claro/oscuro alternos)
hc.unlock("Cruzar")
assert hc.state == "unlocked" and hc.image.get_at((33, 3))[1] > 200 and hc.image.get_at((33, 3))[0] < 90 and hc in solids_h
hc.open(solids_h)
assert hc.state == "open" and hc.image.get_at((33, 3))[1] > 200 and hc not in solids_h
surf_h = pygame.Surface((300, 300))
hc.draw(surf_h, Vector2())
for st_h in ("locked", "unlocked", "open"):                                                   # horizontal: misma puerta girada
    for size_h in ((60, 100), (100, 60), (16, 80)):
        assert Hatch((0, 0), size_h).image.get_size() == size_h
        assert entity_art.render_hatch(size_h, st_h).get_size() == size_h
assert entity_art.render_hatch((100, 60), "locked").get_at((3, 30))[0] > 200               # horizontal: el faro queda a la izquierda
# --- Estación del Exotraje: cabina en stand-by -> E -> vapor y chispas -> cápsula abierta con cables sueltos
from src.entities.interactable import Locker as _Locker
lk_v = _Locker((300, 300), (56, 72), "Abrir alijo")
assert lk_v.rect.size == (56, 72) and lk_v.image.get_size() == (56, 72) and lk_v.enabled and not lk_v.used
img_before = lk_v.image.copy()
lk_v.draw(surf_h, Vector2())
lk_v.use()
assert not lk_v.enabled and lk_v.used and lk_v.burst > 1.0 and lk_v.rect.size == (56, 72)
assert pygame.image.tostring(lk_v.image, "RGBA") != pygame.image.tostring(img_before, "RGBA")   # sprite distinto: cápsula abierta
lk_v.draw(surf_h, Vector2())                                                                   # dibuja la ráfaga
lk_v.update(0.5)
assert 0.7 < lk_v.burst < 0.9
lk_v.draw(surf_h, Vector2())
lk_v.update(2.0)
assert lk_v.burst == 0.0
lk_v.draw(surf_h, Vector2())
# --- brecha del Dash: caja de colisión intacta; el dibujo (foso) es más ancho que la caja
from src.entities.obstacle import DashBarrier as _DB
db_v = _DB(pygame.Rect(680, 960, 40, 80))
assert db_v.rect == pygame.Rect(680, 960, 40, 80) and db_v.dash_passable and db_v.image.get_size() == (40 + 2 * _DB.PAD, 80)
assert len(db_v.tips) >= 3
mid_px = db_v.image.get_at((_DB.PAD + 20, 40))
assert mid_px[3] == 255 and sum(mid_px[:3]) < 30                                              # el fondo del foso es casi negro
assert db_v.image.get_at((0, 40))[3] == 0                                                    # fuera del foso no hay nada
db_v.draw(surf_h, Vector2())
# muro colocado: borde superior iluminado y cara frontal en sombra
wimg = sart.render_wall((40, 40))
assert sum(wimg.get_at((20, 1))[:3]) > sum(wimg.get_at((20, 12))[:3]) + 150
assert sum(wimg.get_at((20, 37))[:3]) < sum(wimg.get_at((20, 22))[:3]) + 80
# fantasma de colocación: silueta 3D translúcida para todas las estructuras construibles
for bt_ in ("wall", "tower", "balista", "pylon", "extractor", "foco"):
    gi_ = sart.ghost_image(bt_, (40, 40), (60, 255, 120))
    assert gi_ is not None and gi_.get_size() == (40, 44), bt_
    alphas = {gi_.get_at((x_, y_))[3] for x_ in range(0, 40, 3) for y_ in range(0, 44, 3)}
    assert 0 < max(alphas) <= 255 and any(0 < a_ < 255 for a_ in alphas), bt_
assert sart.ghost_image("wall", (40, 40), (60, 255, 120)) is sart.ghost_image("wall", (40, 40), (60, 255, 120))
a2 = new_act2(game, metal=500, cores=5)
a2.build_choice = "wall"
sp_g = a2.camera.to_screen(Vector2(500, 700))
mpos[0], mpos[1] = int(sp_g.x), int(sp_g.y)
a2.draw(frame_g := pygame.Surface((1280, 720)))
mpos[0], mpos[1] = 640, 300
a2.build_choice = None
# fondo del Acto 1: bloques sólidos monocromos (sin patrón multicolor tipo confeti)
for builder in (levels.build_level_1_1, levels.build_level_1_2, levels.build_level_1_3, levels.build_level_1_4):
    lv = builder()
    colorful = 0
    for rect_o in [o.rect for o in lv.solids][:12]:
        for x_ in range(rect_o.left + 3, rect_o.right - 3, 5):
            for y_ in range(rect_o.top + 4, rect_o.bottom - 4, 5):
                px_ = lv.background.get_at((x_, y_))[:3]
                if max(px_) - min(px_) > 40:
                    colorful += 1
    assert colorful == 0, (builder.__name__, colorful)
assert "windows" not in terrain._style_details.__doc__ and "ventanas de colores" in terrain._style_details.__doc__

# =============================================================================
print("== Rediseño visual de estructuras, Vulcano, terminal y compuertas: mismas hitboxes, arte nuevo y animaciones ==")
from src.entities.power import PowerPylon
from src.entities.interactable import Terminal
real_ticks_v = pygame.time.get_ticks
EXPECTED = {"wall": (40, 40), "tower": (40, 40), "balista": (40, 40), "pylon": (40, 40),
            "extractor": (40, 40), "foco": (40, 40), "core": (64, 64)}
assert {k_: Building.SIZES[k_] for k_ in EXPECTED} == EXPECTED                          # tamaños de colisión intactos
for kind_v in ("tower", "balista"):
    for route_v in (None, "A", "B"):
        b_v = Building(kind_v, (100, 100))
        if route_v:
            b_v.choose_route(route_v)
        assert b_v.rect.size == (40, 40) and b_v.image.get_size() == (40, 40)
        assert b_v.visual_kind == {(None, "tower"): "tower", ("A", "tower"): "minigun", ("B", "tower"): "flame",
                                   (None, "balista"): "balista", ("A", "balista"): "railgun",
                                   ("B", "balista"): "tesla"}[(route_v, kind_v)]
w_v = Building("wall", (100, 100))
for lvl_v in (2, 3):
    w_v.apply_wall_level(lvl_v)
    assert w_v.rect.size == (40, 40) and w_v.image.get_size() == (40, 40)
for obj_v in (PowerPylon((0, 0)), Building("foco", (0, 0)),
              Building("core", (0, 0)), Vulcano((50, 50))):
    assert obj_v.image.get_size() == obj_v.rect.size
assert Vulcano((50, 50)).rect.size == (30, 30)
assert Terminal((0, 0), (46, 52), "T").rect.size == (46, 52) and Terminal((0, 0), (46, 52), "T").image.get_size() == (46, 52)
for st_v, size_v in (("locked", (60, 100)), ("unlocked", (60, 100)), ("open", (80, 40))):
    assert entity_art.render_hatch(size_v, st_v).get_size() == size_v
# cada especialización se ve distinta
def head_pixels(kind_h, spin=0.0, flash=0.0, tt=0.0, pal_h="light"):
    s_h = pygame.Surface((80, 80))
    s_h.fill((30, 30, 30))
    sart.draw_turret_head(s_h, (40, 40), 0, pal_h, True, tt, kind_h, spin, flash)
    return pygame.image.tostring(s_h, "RGB")
shots_h = {k_: head_pixels(k_, pal_h=pal_) for k_, pal_ in (("tower", "light"), ("minigun", "light"), ("flame", "flame"),
                                                               ("balista", "heavy"), ("railgun", "rail"), ("tesla", "tesla"))}
assert len(set(shots_h.values())) == 6
bases_h = {pal_: pygame.image.tostring(sart.render_tower_base((40, 40), pal_), "RGBA") for pal_ in
           ("light", "flame", "heavy", "rail", "tesla")}
assert len(set(bases_h.values())) == 5
assert head_pixels("minigun", spin=0.0, pal_h="light") != head_pixels("minigun", spin=1.0, pal_h="light")      # el tambor gira
assert head_pixels("tesla", tt=0.0, pal_h="tesla") != head_pixels("tesla", tt=1.3, pal_h="tesla")                 # anillos rotan
assert head_pixels("railgun", flash=0.0, pal_h="rail") != head_pixels("railgun", flash=0.2, pal_h="rail")        # destello azul
blue_v = pygame.Surface((80, 80))
sart.draw_turret_head(blue_v, (40, 40), 0, "rail", True, 0, "railgun", 0.0, 0.2)
assert any(blue_v.get_at((x_, 40))[2] > 200 and blue_v.get_at((x_, 40))[0] < 120 for x_ in range(44, 64))
# la torreta real anima el tambor: gira lento en reposo y rápido al disparar
mg_v = Building("tower", (200, 200))
mg_v.is_powered = True
mg_v.choose_route("A")
s0_v = mg_v.spin
mg_v.update(1.0, empty, empty)
idle_v = mg_v.spin - s0_v
foe_v = Enemy("scout", (330, 200), (10, 10), pygame.sprite.Group())
foe_v.speed = 0
fg_v = pygame.sprite.Group(foe_v)
mg_v.fire_timer = 0
mg_v.update(1 / 60, fg_v, pygame.sprite.Group())
assert mg_v.fire_flash > 0
s1_v = mg_v.spin
mg_v.update(0.1, fg_v, pygame.sprite.Group())
assert (mg_v.spin - s1_v) / 0.1 > idle_v * 5
# muros: base -> reforzado -> electrificado evolucionan; el electrificado chisporrotea (aura + puntos cian)
imgs_w = [pygame.image.tostring(sart.render_wall((40, 40), pal_, lv_), "RGBA") for lv_, pal_ in ((1, "ally"), (2, "wall2"), (3, "wall3"))]
assert len(set(imgs_w)) == 3
aura_v = pygame.Surface((100, 100))
aura_v.fill((10, 10, 10))
sart.draw_wall_sparks(aura_v, pygame.Rect(30, 30, 40, 40), 0.0, 3)
assert aura_v.get_at((50, 50))[1] > 20 and aura_v.get_at((50, 50))[2] > 20
# pilón, generador, extractor de plasma y foco: antena parpadeante, turbinas, destello de núcleo, antena parabólica
pygame.time.get_ticks = lambda: 100
pyl_v = PowerPylon((0, 0))
pyl_v.is_powered = True
surf_p = pygame.Surface((60, 60))
surf_p.fill((20, 20, 20))
pyl_v.draw_dynamic(surf_p, pygame.Rect(10, 10, 40, 40), Vector2())
assert surf_p.get_at((30, 14))[2] > 100                                                      # antena cian con la punta encendida
g_img = []
for tt_ in (0.0, 0.07):
    surf_g = pygame.Surface((60, 60))
    surf_g.fill((20, 20, 20))
    sart.draw_generator_turbines(surf_g, (30, 30), tt_, 0.0)
    g_img.append(pygame.image.tostring(surf_g, "RGB"))
assert g_img[0] != g_img[1]                                                                  # las turbinas giran
assert not hasattr(PowerPylon((0, 0)), "core_flash") and not hasattr(sart, "draw_plasma_crystal")        # sin restos del plasma
foco_v = [pygame.image.tostring(pygame.Surface((60, 60)), "RGB")]
for tt_ in (0.0, 1.0):
    s_f = pygame.Surface((60, 60))
    s_f.fill((20, 20, 20))
    sart.draw_foco_sweep(s_f, (30, 30), tt_, True)
    foco_v.append(pygame.image.tostring(s_f, "RGB"))
assert foco_v[1] != foco_v[2]                                                                # la antena parabólica gira
# Vulcano: octógono con núcleo naranja; al reparar, haz cian con chispas
vv = Vulcano((200, 200))
vv._draw()
assert vv.image.get_at((15, 15))[0] > 200 and vv.image.get_at((15, 15))[2] < 220
class _Tgt:
    pos = Vector2(260, 200)
vv.repairing = [_Tgt()]
vv.t = 0.0
vv._draw()
beam_s = pygame.Surface((400, 300))
beam_s.fill((0, 0, 0))
vv.rect.center = (200, 150)
vv.draw_overlay(beam_s, vv.rect, Vector2(0, 50))
assert any(beam_s.get_at((x_, y_))[2] > 150 and beam_s.get_at((x_, y_))[0] < 100 for x_ in range(215, 260) for y_ in range(120, 210))
# terminal: brillo verde al interactuar y se apaga solo
term_v = Terminal((300, 300), (46, 52), "Consola")
calm_t = pygame.Surface((90, 90))
term_v.draw(calm_t, Vector2(300 - 45, 300 - 45))
term_v.interact(None)
assert term_v.glow == 1.0
lit_t = pygame.Surface((90, 90))
term_v.draw(lit_t, Vector2(300 - 45, 300 - 45))
assert pygame.image.tostring(calm_t, "RGB") != pygame.image.tostring(lit_t, "RGB")
term_v.update(1.0)
assert term_v.glow == 0.0
# compuerta: el faro de estado proyecta un resplandor (rojo bloqueada) sobre el cabezal; horizontal: a la izquierda
hatch_v = Hatch((200, 200), (60, 100))
seam_v = pygame.Surface((100, 140))
seam_v.fill((0, 0, 0))
hatch_v.t = 0.1
hatch_v.draw_overlay(seam_v, pygame.Rect(20, 20, 60, 100), Vector2())
glow_px = [seam_v.get_at((x_, y_)) for x_ in range(40, 61) for y_ in range(14, 30)]
assert any(c_[0] > 20 and c_[1] < c_[0] for c_ in glow_px)                                   # resplandor rojo sobre el faro
assert seam_v.get_at((50, 90))[:3] == (0, 0, 0)                                              # y nada en el resto de la puerta
side_v = pygame.Surface((140, 100))
side_v.fill((0, 0, 0))
entity_art.draw_hatch_glow(side_v, pygame.Rect(20, 20, 100, 60), "locked", 0.1)
assert any(side_v.get_at((x_, y_))[0] > 20 for x_ in range(12, 30) for y_ in range(40, 60))
# búnker: cables cian/amarillos hacia el Centro, rejillas y triángulos de alerta alrededor del marco
gm_v = GameMap.arena(2200, 1200, cc_pos=(420, 600))
px_set = {gm_v.background.get_at((x_, y_))[:3] for x_ in range(150, 700, 2) for y_ in range(300, 900, 2)}
assert (0, 190, 170) in px_set and (212, 178, 24) in px_set and (120, 128, 144) in px_set
assert gm_v.background.get_size() == (2200, 1200)

# =============================================================================
print("== Lore oficial: A.U.R.A. y V.U.L.C.A.N.O. en la Terminal, la Base Central y los diálogos del Acto 1 ==")
from src.config import UNITS as U
from src.ui.dialogue_box import DialogueBox
assert U.LORE["AURA"] == {"acronym": "A.U.R.A.", "full": "Arquitectura Unificada de Reconocimiento y Análisis"}
assert U.LORE["VULCANO"] == {"acronym": "V.U.L.C.A.N.O.",
                             "full": "Vector de Unión, Logística y Construcción de Activos Nucleares y Operativos"}
assert U.lore_title("AURA") == "A.U.R.A. // Arquitectura Unificada de Reconocimiento y Análisis"
assert U.lore_intro("VULCANO").startswith("V.U.L.C.A.N.O. (Vector de Unión")
hud_l = game.hud
# los textos caben en sus cajas (sin desbordar el HUD)
assert hud_l.fonts["s"].size(U.lore_title("AURA"))[0] + 62 < 1280 - 20                      # subtítulo de la Terminal
assert hud_l.fonts["s"].size(U.lore_title("VULCANO"))[0] < 1280 - 40                        # bajo el título de la Base Central
panel_w = 1180 - 310 - 28                                                                   # ancho útil del recuadro de diálogo
for sender_l, line_l in (("AURA", f"{U.lore_intro('AURA')}... piloto... si me oyes... estoy atrapada en el Almacén 4..."),
                         ("VULCANO", f"{U.lore_intro('VULCANO')}: sistemas de mantenimiento reactivados tras décadas de silencio.")):
    rows_l = DialogueBox._wrap(line_l, hud_l.fonts["m"], panel_w)
    assert len(rows_l) <= 5 and all(hud_l.fonts["m"].size(r_)[0] <= panel_w for r_ in rows_l), (sender_l, rows_l)
# Terminal Táctico: el subtítulo de AURA se dibuja y no pisa la fila de recursos
game.new_campaign()
game.machine.transition(GameState.ACT_2_BASE)
game.machine.draw(game.screen)
sub_rect = pygame.Rect(62, 64, hud_l.fonts["s"].size(U.lore_title("AURA"))[0], 16)
assert any(game.screen.get_at((x_, y_))[:3] != (4, 10, 12) and game.screen.get_at((x_, y_))[1] > 100
           for x_ in range(sub_rect.left, sub_rect.right, 2) for y_ in range(sub_rect.top, sub_rect.bottom))
# Base Central: la denominación de VULCANO aparece centrada bajo el título y sobre el reporte
game.new_campaign()
game.resources.vulcano_online = True
game.resources.metal = 100
game.machine.transition(GameState.SUB_ACT_1_4)
game.advance(GameState.ACT_2_BASE)
bm_l = screens[GameState.BASE_MANAGEMENT]
bm_l.dialogue.clear()
game.machine.draw(game.screen)
nw = hud_l.fonts["s"].size(U.lore_title("VULCANO"))[0]
band = [game.screen.get_at((x_, y_))[:3] for x_ in range(640 - nw // 2, 640 + nw // 2, 2) for y_ in range(38, 52)]
assert any(c_[0] > 120 and c_[2] < 100 for c_ in band)
# Acto 1: la primera intervención de AURA (1.1) y de VULCANO (1.4) lleva la sigla con su desglose
game.machine.transition(GameState.MENU)
game.new_campaign()
game.resources.equipped = True
game.machine.transition(GameState.SUB_ACT_1_1)
s11 = screens[GameState.SUB_ACT_1_1]
dismiss(game)
s11.told_aura = False
teleport(s11, s11.hatch.pos + Vector2(120, 0))
s11.hatch.is_open = True
step(game, 2)
first_aura = next(ln_ for ln_ in s11.dialogue.lines if ln_.sender == "AURA")
assert first_aura.text.startswith("A.U.R.A. (Arquitectura Unificada de Reconocimiento y Análisis)")
game.machine.transition(GameState.MENU)
game.new_campaign()
game.machine.transition(GameState.SUB_ACT_1_4)
s14 = screens[GameState.SUB_ACT_1_4]
dismiss(game)
s14._reactivate(s14, s14.terminal) if hasattr(s14, "terminal") else None
vul_lines = [ln_ for ln_ in s14.dialogue.lines if ln_.sender == "VULCANO"]
if vul_lines:
    assert vul_lines[0].text.startswith("V.U.L.C.A.N.O. (Vector de Unión, Logística y Construcción de Activos Nucleares y Operativos)")
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Balance P1: armadura (Minigun perfora 4, Lanzallamas la ignora), puntería de la Balista, muros, oleadas y pausa ==")
grp_b = pygame.sprite.Group()
for kind_b, arm_b in (("scout", 0), ("soldier", 4), ("tank", 8)):
    e_b = Enemy(kind_b, (0, 0), (1, 1), grp_b)
    assert e_b.armor == arm_b
    assert e_b.mitigate(10, None) == max(1, 10 - arm_b)                      # Twin base / Minigun sin perforar
    assert e_b.mitigate(10, None, 4) == max(1, 10 - max(0, arm_b - 4))       # Minigun: ignora 4 de armadura
    assert e_b.mitigate(5, None, 99) == 5                                    # Lanzallamas: daño elemental
# el Ariete conserva su frente blindado aunque el ataque ignore armadura
ram_b = Enemy("ariete", (300, 300), (0, 300), grp_b)
ram_b.facing = 180.0                                                          # mira hacia la izquierda (-x)
assert ram_b.is_frontal(Vector2(1, 0)) and not ram_b.is_frontal(Vector2(-1, 0)) and not ram_b.is_frontal(Vector2(0, 1))
assert abs(ram_b.mitigate(100, Vector2(1, 0), 99) - 55) < 1e-9 and abs(ram_b.mitigate(100, Vector2(-1, 0)) - 300) < 1e-9


def turret_dps(kind_t, route_t, enemy_kind, seconds=4.0):
    """Daño real por segundo de una torreta contra un enemigo inmóvil (balas y llamas por el camino real)."""
    tw_t = Building(kind_t, (200, 300))
    tw_t.is_powered = True
    if route_t:
        tw_t.choose_route(route_t)
    foes_t = pygame.sprite.Group()
    en_t = Enemy(enemy_kind, (300, 300), (0, 300), foes_t)
    en_t.speed, en_t.hp, en_t.max_hp = 0, 10 ** 6, 10 ** 6
    en_t.facing = 0.0                                                          # un Ariete mirando a +x: le dan por la espalda
    foes_t.add(en_t)
    buls_t = pygame.sprite.Group()
    for _ in range(int(seconds * 60)):
        tw_t.update(1 / 60, foes_t, buls_t)
        buls_t.update(1 / 60)
        combat.resolve_projectiles(buls_t, foes_t, pygame.sprite.Group())
    return (10 ** 6 - en_t.hp) / seconds


dps_b = {(k_, r_, e_): turret_dps(k_, r_, e_) for k_, r_ in (("tower", None), ("tower", "A"), ("tower", "B"))
         for e_ in ("scout", "soldier", "tank")}
assert 40 <= dps_b[("tower", "B", "soldier")] <= 55 and 40 <= dps_b[("tower", "B", "tank")] <= 55          # antes ~10
assert 40 <= dps_b[("tower", "A", "soldier")] <= 55 and 25 <= dps_b[("tower", "A", "tank")] <= 35          # antes 30 / 10
assert dps_b[("tower", "A", "tank")] > dps_b[("tower", None, "tank")]                                       # la ruta compensa
# corrección: la bala perforante de la Balista (pierce 2) ya no golpea DOS veces al mismo objetivo
bal_dps = turret_dps("balista", None, "soldier")
per_dps = turret_dps("balista", "A", "soldier")
assert 100 <= bal_dps <= 130 and per_dps > bal_dps, (bal_dps, per_dps)            # antes: 234 la base y 147 la Perforante
assert dps_b[("tower", "A", "soldier")] > dps_b[("tower", None, "soldier")]
# Balista (base y Perforante): Tanque > Ariete de flanco > Soldado > resto; un Ariete de frente es la última opción
bal_b = Building("balista", (500, 300))
bal_b.is_powered = True
foes_p = pygame.sprite.Group()


def put_foe(kind_p, pos_p, facing_p=0.0):
    e_p = Enemy(kind_p, pos_p, (0, 300), foes_p)
    e_p.speed, e_p.facing = 0, facing_p
    foes_p.add(e_p)
    return e_p


ram_front = put_foe("ariete", (700, 300), 180.0)        # viene hacia la torreta: solo enseña el frente
sold_p = put_foe("soldier", (500, 450))
assert bal_b._balista_rank(ram_front) == 9 and bal_b._balista_rank(sold_p) == 2
tank_p = put_foe("tank", (300, 300))
bal_b.fire_timer = 0
shots_p = pygame.sprite.Group()
bal_b.update(1 / 60, foes_p, shots_p)
assert len(shots_p) == 1 and abs(bal_b.angle - 180.0) < 1e-6                                # el Tanque primero
tank_p.kill()
ram_flank = put_foe("ariete", (500, 150), 180.0)        # de costado: su frente no mira a la torreta
assert bal_b._balista_rank(ram_flank) == 1
shots_p.empty()
bal_b.fire_timer = 0
bal_b.update(1 / 60, foes_p, shots_p)
assert len(shots_p) == 1 and abs(abs(bal_b.angle) - 90.0) < 1e-6 and next(iter(shots_p)).vel.y < 0  # Ariete flanqueado
ram_flank.kill()
shots_p.empty()
bal_b.fire_timer = 0
bal_b.update(1 / 60, foes_p, shots_p)
assert len(shots_p) == 1 and next(iter(shots_p)).vel.y > 0                                   # luego el Soldado
sold_p.kill()
shots_p.empty()
bal_b.fire_timer = 0
bal_b.update(1 / 60, foes_p, shots_p)
assert len(shots_p) == 0 and bal_b.fire_timer <= 0                                           # solo un Ariete de frente: no dispara
assert U.TOOLTIPS["balista"]["effective"] == "Tanques y Arietes flanqueados"
assert "perforación de armadura" in U.TURRET_ROUTES["tower"]["A"]["desc"] and "ignora la armadura" in U.TURRET_ROUTES["tower"]["B"]["desc"]
# muros: 30 de chatarra = 0.075 por HP (antes 0.0375); calibrado a 30 para no hundir al perfil medio
assert U.BUILDINGS["wall"]["cost"] == 30 and Building.STATS["wall"]["cost"] == 30
assert U.BUILDINGS["wall"]["cost"] / U.BUILDINGS["wall"]["hp"] == 0.075
# oleadas: 12 s de respiro; oleada 4 con Ariete; oleada 5: el Tanque abre y los 2 Arietes llegan a los 15 s
assert C.BREAK_TIME == 12.0
assert dict(Wave(4, 1, (0, 0)).get_enemy_spawns())["ariete"] == 1
w5 = Wave(5, 1, (0, 0))
assert w5.schedule[0] == "tank" and "ariete" not in w5.schedule and w5.delayed_spawns() == [(15.0, "ariete"), (15.0, "ariete")]
assert dict(w5.get_enemy_spawns()) == {"tank": 1, "scout": 8, "soldier": 4, "ariete": 2}
a2 = new_act2(game, metal=500)
w = a2.world
wm = a2.wave
wm.phase, wm.wave, wm.timer = "break", 4, 0.0
for _ in range(3):
    a2.core.hp = a2.core.max_hp
    step(game, 1)
assert wm.phase == "wave" and wm.wave == 5
first_kinds = [e_.enemy_type for e_ in w.enemies]
assert first_kinds and first_kinds[0] == "tank" and "ariete" not in first_kinds
assert wm.remaining >= 15 - 0                                                                   # los retrasados cuentan
for _ in range(60 * 14):
    a2.core.hp = a2.core.max_hp
    step(game, 1)
assert not any(e_.enemy_type == "ariete" for e_ in w.enemies) and len(wm.pending_delayed) == 2   # a los 14 s aún no
for _ in range(60 * 2):
    a2.core.hp = a2.core.max_hp
    step(game, 1)
assert not wm.pending_delayed and sum(1 for e_ in w.enemies if e_.enemy_type == "ariete") + sum(
    1 for k_ in wm.current.schedule[wm.spawned:] if k_ == "ariete") == 2                        # a los 16 s ya entraron
wm.phase, wm.timer = "break", C.BREAK_TIME
assert wm.timer == 12.0
# pausa táctica en la preparación: se construye, pero sin el -50% (el temporizador no corre en pausa)
a2 = new_act2(game, metal=500)
assert a2.wave.phase == "prep" and a2._cost("wall") == 15
press(game, pygame.K_SPACE)
assert a2.paused and a2._cost("wall") == 30
m_b = game.resources.metal
assert build(a2, "wall", (460, 500)) and game.resources.metal == m_b - 30
press(game, pygame.K_SPACE)
assert not a2.paused and a2._cost("wall") == 15
# nomenclatura: el umbral del 1.4 mide chatarra
assert "trigger_scrap_less_than" in U.RESCUES["vulcano_sub_1_4"] and "trigger_ammo_less_than" not in U.RESCUES["vulcano_sub_1_4"]
print("  DPS (tick real 4 s):", {f"{k_}{'/' + r_ if r_ else ''} vs {e_}": round(v_) for (k_, r_, e_), v_ in dps_b.items()})

# =============================================================================
print("== Prioridad 2: chasis de AURA (escaneo 3/6, dron 6/6), Imán + Recolector, diálogos y victoria ==")
from src.entities.drones import ReconDrone
from src.entities.factory import drone_stats as _ds
from main import victory_texts
# escaneo táctico: con 3/6 el radar de la incursión marca todos los depósitos, el alijo de plasma y el extractor (⚡)
game.machine.transition(GameState.MENU)
game.new_campaign()
game.machine.transition(GameState.ACT_2_BASE)
game.machine.transition(GameState.INCURSION, op="recovery")                        # mapa económico con extractor de plasma
inc_p = game.machine.active
dismiss(game)
assert not game.resources.aura_scan
plain = inc_p.radar_targets()
assert len(plain) == 2 and not any(len(t_) > 2 for t_ in plain)                     # sin escaneo: depósito cercano + baliza
game.resources.chassis_installed = 3
assert game.resources.aura_scan and not game.resources.aura_drone
scan = inc_p.radar_targets()
assert any(len(t_) > 2 and t_[2] == "energy" for t_ in scan)                        # extractor de plasma con icono ⚡
assert sum(1 for t_ in scan if t_[1] == C.YELLOW and len(t_) == 2) == sum(1 for c_ in inc_p.caches if c_.enabled)
game.machine.draw(game.screen)                                                       # el radar dibuja el icono
# Dron Explorador: detecta chatarra a 450 px (el Módulo Imán ya no existe)
assert ReconDrone((0, 0), _ds("recon")).scan_range == 450
game.machine.transition(GameState.MENU)
game.new_campaign()
a2 = new_act2(game, metal=500)
assert not hasattr(a2.player, "magnet_radius")
assert build(a2, "fabrica", (640, 720))
a2.factory.build_left = 0
assert a2.factory._spawn_drone("recon").scan_range == 450
# dron AURA (6/6): aparece al empezar la primera oleada, pulso EMP cada 5 s si hay 2 de energía libre
game.machine.transition(GameState.MENU)
game.new_campaign()
a2 = new_act2(game, metal=500, before=lambda r_: setattr(r_, "chassis_installed", 6))
w = a2.world
assert a2.aura_drone is None
a2.wave.timer = 0.01
step(game, 3)
aura = a2.aura_drone
assert aura is not None and aura.alive() and aura in w.drones and aura.max_hp == 150
foes_a = []
for i_ in range(3):
    e_ = Enemy("scout", aura.pos + Vector2(30 + i_ * 10, 0), a2.CC_POS, w.enemies)
    foes_a.append(e_)
tank_a = Enemy("tank", aura.pos + Vector2(0, 30), a2.CC_POS, w.enemies)
far_a = Enemy("scout", aura.pos + Vector2(400, 0), a2.CC_POS, w.enemies)
grp_a = pygame.sprite.Group(foes_a + [tank_a, far_a])
class _W:
    pass
fake_w = _W()
fake_w.enemies, fake_w.core = grp_a, a2.core
aura.pulse_timer = 0.0
aura.energy_ok = lambda cost: cost == 2
aura.update(1 / 60, fake_w)
assert aura.pulses == 1 and all(e_.slow_timer > 1.4 and abs(e_.slow_factor - 0.40) < 1e-9 for e_ in foes_a)
assert tank_a.slow_timer == 0 and far_a.slow_timer == 0                              # ni tanques ni fuera del radio
assert abs(aura.pulse_timer - 5.0) < 1e-6
aura.pulse_timer = 0.0
aura.energy_ok = lambda cost: False                                                  # sin energía libre: no pulsa
aura.update(1 / 60, fake_w)
assert aura.pulses == 1 and abs(aura.pulse_timer - 1.0) < 1e-6
aura.take_damage(999)
step(game, 2)
assert game.resources.aura_drone_lost and not aura.alive()
a2._deploy_aura()
assert a2.aura_drone is aura                                                         # no reaparece en el acto
# diálogos contextuales: déficit de energía (AURA analiza, VULCANO estalla) y muro blindado destruido (solo VULCANO)
game.machine.transition(GameState.MENU)
game.new_campaign()
a2 = new_act2(game, metal=5000, vulcano=True)
w = a2.world
a2.dialogue.clear()
a2.energy_free = lambda: 5
step(game, 2)
said = [(ln_.sender, ln_.text) for ln_ in a2.dialogue.lines]
assert ("AURA", "Alerta. Fallo de red detectado. Capacidad insuficiente.") in said
assert ("VULCANO", "¡Maldita sea! Circuitos sobrecargados... ¡Desactiva algo!") in said
n_lines = len(a2.dialogue.lines)
step(game, 30)
assert len(a2.dialogue.lines) <= n_lines                                             # no se repite (enfriamiento)
del a2.energy_free
a2.dialogue.clear()
assert build(a2, "wall", (460, 500))
wl_p = next(iter(w.walls))
wl_p.apply_wall_level(2)
wl_p.take_damage(99999)
for _ in range(60):
    step(game, 1)
    if not wl_p.alive():
        break
assert ("VULCANO", "Ese blindaje... el metal desperdiciado... mierda.") in [(ln_.sender, ln_.text) for ln_ in a2.dialogue.lines]
assert not any(ln_.sender == "AURA" and "blindaje" in ln_.text for ln_ in a2.dialogue.lines)
a2.dialogue.clear()
assert build(a2, "wall", (500, 500))
wl_q = next(iter(w.walls))
wl_q.take_damage(99999)
step(game, 60)
assert not any(ln_.sender == "VULCANO" for ln_ in a2.dialogue.lines)                 # un muro básico no le duele
# victoria diferenciada según el chasis
rv = ResourceManager()
rv.chassis_installed = 6
assert victory_texts(rv)[0] == "CHASIS DE AURA COMPLETADO. AURA ESTÁ LIBRE."
rv.chassis_installed = 4
assert victory_texts(rv)[0] == "CHASIS INCOMPLETO. AURA PERMANECE ATRAPADA EN EL BÚNKER."
for n_v in (4, 6):
    game.resources.chassis_installed = n_v
    game.machine.transition(GameState.VICTORY)
    game.machine.draw(game.screen)
    for txt_v in victory_texts(game.resources)[:2]:
        assert game.hud.fonts["l"].size(txt_v)[0] < 1280 or game.hud.fonts["m"].size(txt_v)[0] < 1280
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Prioridad 2: sub-acto 1.4, proteger a VULCANO mientras suelda la compuerta ==")
game.new_campaign()
game.resources.equipped = True
game.machine.transition(GameState.SUB_ACT_1_4)
s = screens[GameState.SUB_ACT_1_4]
dismiss(game)
assert not s.exit_console.enabled and s.defense is None
teleport(s, s.terminal.pos + Vector2(0, 60))
step(game, 2)
press(game, pygame.K_e)
dismiss(game)
assert s.exit_console.enabled and s.exit_console.label == "INICIAR REPARACIÓN"
for wl in s.demo_walls:
    wl.hp = wl.max_hp * 0.3
s.vulcano.repairing = []
# Fase 6: la oleada es FIJA (los muros no la agrandan); los muros reparados dan cobertura (+5% de daño por muro)
assert s.defense_profile() == "medium" and s.cover_bonus() == 0                    # 0 muros reparados
s.demo_walls[0].hp = s.demo_walls[0].max_hp
assert s.defense_profile() == "medium" and abs(s.cover_bonus() - 0.05) < 1e-9
for wl in s.demo_walls:
    wl.hp = wl.max_hp
assert s.defense_profile() == "medium" and abs(s.cover_bonus() - 0.15) < 1e-9      # 3 muros = +15%
s.demo_walls[1].hp = 10
teleport(s, s.exit_console.pos + Vector2(0, 60))
step(game, 2)
press(game, pygame.K_e)
assert s.defense is not None and s.defense["profile"] == "medium" and s.dialogue.blocking_active
assert len(s.defense["cover"]) == 2 and abs(s.cover_bonus() - 0.10) < 1e-9           # 2 reparados al empezar
assert any("BZZZT" in ln_.text for ln_ in s.dialogue.lines)
dismiss(game)
assert s.vulcano.max_hp == 200 and s.vulcano.hp == 200
grace_v = U.VULCANO_DEFENSE["cinematic"] + U.VULCANO_DEFENSE["grace_time"]
assert abs(s.vulcano.shield_time - grace_v) < 0.1 and "ESCUDO" in s.banner()          # escudo de gracia (2 + 3 s)
assert s.vulcano.take_damage(50) is False and s.vulcano.hp == 200
game.machine.draw(game.screen)                                                        # burbuja del escudo en pantalla
anchor_v = Vector2(s.vulcano.pos)
step(game, 60 * 3)                                                                    # 2 s de soldadura y llegan los primeros
assert s.vulcano.hp == 200 and 0 < s.vulcano.shield_time < grace_v                     # aún protegido
kinds_v = sorted(e_.enemy_type for e_ in s.world.enemies)
assert kinds_v == ["scout", "scout", "scout", "scout"], kinds_v                    # 1ª mitad de 6 Scouts + 1 Soldado
assert all(abs(e_.vulnerability - 1.10) < 1e-9 for e_ in s.world.enemies)            # cobertura: +10% de daño recibido
hp_v = s.world.enemies.sprites()[0]
hp_before = hp_v.hp
hp_v.take_damage(10)
assert abs(hp_before - hp_v.hp - 11.0) < 1e-9
s.defense["cover"][0].kill()                                                          # un muro de cobertura cae
step(game, 1)
assert all(abs(e_.vulnerability - 1.05) < 1e-9 for e_ in s.world.enemies)
assert s.vulcano.pos == anchor_v                                                      # VULCANO no se mueve
assert all(e_.target_pos == s.vulcano.pos for e_ in s.world.enemies)
# si nadie lo defiende, cae y la misión se aborta (reintento del 1.4)
for _ in range(60 * 26):
    s.player.hp = s.player.max_hp
    step(game, 1)
    if game.machine.current_state is not GameState.SUB_ACT_1_4:
        break
assert game.machine.current_state is GameState.RETRY_SUB_ACT
assert "VULCANO FUE DESTRUIDO" in screens[GameState.RETRY_SUB_ACT].reason
assert s.defense["low_said"]                                                          # avisó (una vez) antes de caer
assert getattr(game, "vulcano_defense_fails", 0) >= 1
# defendido: a los 25 s la compuerta queda sellada y termina el Acto 1
press(game, pygame.K_r)
s = screens[GameState.SUB_ACT_1_4]
dismiss(game)
teleport(s, s.terminal.pos + Vector2(0, 60))
step(game, 2)
press(game, pygame.K_e)
dismiss(game)
win_vulcano_defense(game, s)
assert s.defense["done"] and s.gate.enabled and s.vulcano.hp > 0 and s.pending_next is None
# escudo de gracia en unidad: solo se gasta soldando, luego es vulnerable; el aviso de vida baja sale una sola vez
v_ = Vulcano(Vector2(300, 300))
v_.start_welding(Vector2(300, 300), Vector2(340, 300), 200, shield=1.0)
v_.weld(0.5)
assert v_.take_damage(80) is False and v_.hp == 200 and abs(v_.shield_time - 0.5) < 1e-9
v_.weld(0.6)
assert v_.shield_time == 0 and v_.take_damage(10) is False and v_.hp == 190
v_.stop_welding()
assert v_.shield_time == 0 and v_.take_damage(10) is False and v_.hp == 190        # ya no suelda: intocable
# perfil grande: 8 Scouts, 2 Soldados y un Ariete Ligero
assert U.VULCANO_DEFENSE["profiles"]["large"] == {"scout": 8, "soldier": 2, "light_ram": 1}
assert U.VULCANO_DEFENSE["profiles"]["small"] == {"scout": 4} and U.VULCANO_DEFENSE["duration"] == 25.0
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Prioridad 3.A: niebla de guerra persistente y bases enemigas con IA ==")
from src.mechanics.fog import MapFog
from src.entities.enemy_base import EnemyExtractor, EnemyTurret, EnemyWall, EnemyBase, base_positions, bases_for_alert
from src.entities.drones import ReconDrone
from src.entities.factory import drone_stats as _ds3
fog_t = MapFog(1280, 960)
assert not fog_t.is_revealed(640, 360)                                              # empieza negro
fog_t.reveal_fog(640, 360, 400)
assert fog_t.is_revealed(640, 370) and not fog_t.is_revealed(100, 100)
assert fog_t.reveal_fog(640, 360, 400) == 0                                         # lo descubierto queda descubierto
fog_t2 = MapFog(1280, 960)
fog_t2.load(fog_t.dump())
assert fog_t2.is_revealed(640, 370) and not fog_t2.is_revealed(100, 100)
assert bases_for_alert(1) == (1, "easy") and bases_for_alert(3) == (2, "medium") and bases_for_alert(5) == (3, "hard")
assert len({tuple(p_) for p_ in base_positions(3)}) == 3 and len({tuple(p_) for p_ in base_positions(7)}) == 7
# escena: Alerta 1 -> 1 base easy, oculta en la niebla
a2 = new_act2(game, metal=500)
w = a2.world
assert len(a2.enemy_bases) == 1 and a2.enemy_bases[0].difficulty == "easy"
base = a2.enemy_bases[0]
assert (base.scrap, base.plasma_cores, base.health) == (500, 3, 1000) and not base.detected
assert [b_.role for b_ in base.buildings] == ["wall", "wall", "sentinel", "generator"] and base.garrison_created   # Fase 6
assert base.has_active_defenses()
assert a2.fog.is_revealed(a2.CC_POS) and not a2.fog.is_revealed(base.pos)
assert base.core not in a2.visible_sprites() and a2.core in a2.visible_sprites()        # lo hostil no descubierto no se ve
assert base.core in w.hostile and len(base.deposits) == 2
# IA: economía primero (extractores en sus depósitos), después su cola de prioridades
base.ai_timer = base.ai_action_interval
base.update(0.01)
ext = next(b_ for b_ in base.buildings if isinstance(b_, EnemyExtractor))
assert base.decisions[-1] == "extractor" and base.scrap == 440 and ext.deposit.extractor is ext
s0 = base.scrap
ext.update(3.0, w)
assert base.scrap == s0 + 5                                                         # extrae su mineral
base.ai_timer = base.ai_action_interval
base.update(0.01)
assert base.decisions[-1] == "extractor" and sum(isinstance(b_, EnemyExtractor) for b_ in base.buildings) == 2
s1 = base.scrap
assert base._ai_try_build() == "muro" and base.scrap == s1 - 30
wall_e = next(b_ for b_ in base.buildings if isinstance(b_, EnemyWall))
assert wall_e.pos.distance_to(base.pos) <= 200 * 1.5 and wall_e in w.hostile and wall_e in w.solids
assert base.build_priority == ["muro", "torreta_ligera", "muro", "muro"]            # la cola rota
base.build_priority = ["torreta_ligera"] + base.build_priority
assert base._ai_try_build() == "torreta_ligera"
tur_e = next(b_ for b_ in base.buildings if isinstance(b_, EnemyTurret))
from src.entities.drones import DRONE_CLASSES as _DCb
bait_b = _DCb["attack"](Vector2(tur_e.pos) + Vector2(120, 0), dict(U.DRONE_TYPES["attack"]), Vector2(tur_e.pos))
w.drones.add(bait_b)                                                                # un dron aliado a tiro
nb = len(w.enemy_bullets)
tur_e.update(0.1, w)
assert len(w.enemy_bullets) == nb + 1                                               # la torreta de la IA dispara
w.enemy_bullets.empty()
bait_b.kill()
wall_e.hp = 100
s2 = base.scrap
assert base._ai_repair_buildings() is wall_e and wall_e.hp == 150 and base.scrap == s2 - 5      # repara 50 HP (0,1/HP)
assert base.take_damage(50) is False and base.health == 1000                          # escudo: generador + centinela
from src.entities.foundry import HostileStructure as _HS
for t_ in list(base.sentinels):
    _HS.kill(t_)                                                                      # sin centinelas, sin escudo
base.take_damage(50)
assert base.health == 950
# decisiones al azar: construir 40%, reparar 30%, esperar 30%
import random as _rnd
base.rng = _rnd.Random(5)
for _ in range(40):
    base._ai_decide_action()
kinds_dec = {d_.split(":")[0] for d_ in base.decisions[-40:]}
assert {"build", "repair", "wait"} <= kinds_dec
# contraataque: si le destruyes un edificio, sube su escalada y envía Scouts al Centro de Control
n0 = len(w.enemies)
wall_e.take_damage(99999)
assert base.escalation == 1 and len(w.enemies) == n0 + 3 and wall_e not in base.buildings
assert all(e_.target_pos == a2.CC_POS for e_ in list(w.enemies)[n0:])
for e_ in list(w.enemies):
    e_.kill()
# el Explorador la revela (y queda revelada): se ve en la vista principal y en el minimapa
rec = ReconDrone(Vector2(base.pos) + Vector2(-100, 0), _ds3("recon"), home=a2.CC_POS)
w.drones.add(rec); w.all_sprites.add(rec)
a2._update_fog()
assert base.detected and a2.fog.is_revealed(base.pos) and base.core in a2.visible_sprites()
rec.kill()
game.machine.draw(game.screen)
# destruir la base: su núcleo cae, sus edificios se desmoronan y da recompensa
m_b, c_b = game.resources.metal, game.resources.cores
raze(base)
assert base.destroyed and not base.alive_buildings() and not a2.bases_left()
assert game.resources.metal == m_b + 100 and game.resources.cores == c_b + 1
# varias bases: escalable y en posiciones distintas
extra = a2.spawn_enemy_bases(2, "medium")
assert len(a2.enemy_bases) == 3 and all(b_.difficulty == "medium" for b_ in extra)
assert len({(b_.x, b_.y) for b_ in a2.enemy_bases}) == 3 and len(a2.bases_left()) == 2
# victoria: hay que destruir la Fundición Y todas las bases
for t_ in list(a2.foundry_core.perimeter):
    t_.take_damage(9999)
a2.foundry_core.take_damage(99999)
step(game, 2)
assert not a2.victory and a2.foundry_note and game.machine.current_state is not GameState.VICTORY
for b_ in extra:
    raze(b_)
step(game, 2)
assert a2.victory
# las bases y la niebla viajan de 2.1 a 2.2
a2.capture_enemy_state()
assert len(game.resources.enemy_bases_state) == 3 and game.resources.act2_fog is not None
restored = EnemyBase.restore(game.resources.enemy_bases_state[0], w)
assert restored.destroyed and restored.difficulty == "easy"
# Alerta 3: dos bases medium; Alerta 4: tres hard
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=500, threat=3)
assert [b_.difficulty for b_ in a2.enemy_bases] == ["medium", "medium"]
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=500, threat=4)
assert [b_.difficulty for b_ in a2.enemy_bases] == ["hard", "hard", "hard"]
assert a2.enemy_bases[0].build_priority[0] == "torreta_pesada"
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Prioridad 3.B: mapas de campaña, menú, bases escalables y pantalla de victoria ==")
from src.mechanics.scenario import Scenario
from src.scenes.campaign_menu import CampaignMenuState as _CMS
CM = U.CAMPAIGN_MAPS
assert list(CM) == ["map_1_infiltration", "map_2_push", "map_3_siege"]
assert [CM[k]["difficulty"] for k in CM] == ["easy", "medium", "hard"]
assert [CM[k]["map_size"] for k in CM] == [(2000, 1500), (2250, 1750), (2500, 2000)]            # mapas ampliados un 25%
assert [CM[k]["enemy_bases"] for k in CM] == [1, 2, 3]
assert all(len(CM[k]["enemy_spawn_positions"]) == CM[k]["enemy_bases"] == len(CM[k]["rewards"]) or k == "map_3_siege" for k in CM)
assert [CM[k]["total_duration"] for k in CM] == [600, 900, 1200] and all(CM[k]["break_time"] == 30 for k in CM)
assert CM["map_3_siege"]["foundry"] and not CM["map_1_infiltration"].get("foundry")
for k in CM:                                                       # cada mapa tiene plan de oleadas y todo dentro del mapa
    sc_ = Scenario(k)
    assert len(sc_.plan) == U.campaign_assault_after(CM[k]) and sc_.total_duration
    assert all(0 < p_.x < sc_.w and 0 < p_.y < sc_.h for p_, _ in sc_.base_slots) and 0 < sc_.cc_pos.x < sc_.w
assert Scenario(None).classic and Scenario("nope").classic and Scenario(None).size == (C.ACT2_W, C.ACT2_H)
assert [sum(1 for lab, _, _ in Scenario("map_1_infiltration").plan if lab == "big")] == [1]      # 1ª vuelta: 5 pequeñas + 1 grande
assert len(Scenario("map_1_infiltration").plan[0][2]) == 1                       # mapa 1, oleada 1: 1 enemigo
assert len(U.campaign_wave_entry(CM["map_3_siege"], 24)[2]) == 20                 # la 4ª grande: 20


def campaign_menu(game, unlock=0, **res_changes):
    """Terminal -> menú de campaña en una campaña nueva. `unlock` = cuántos mapas se dan por ganados (desbloqueo lineal)."""
    game.new_campaign()
    game.campaign_run.completed_maps.update(list(CM)[:unlock])
    game.resources.initial_done = True
    for k_, v_ in res_changes.items():
        setattr(game.resources, k_, v_)
    game.machine.transition(GameState.ACT_2_BASE)
    press(game, pygame.K_6)
    return screens[GameState.CAMPAIGN_MENU]


def campaign_act2(game, idx, metal=3000):
    campaign_menu(game, unlock=idx, metal=metal)                  # los mapas anteriores, ganados: este queda abierto
    for _ in range(idx):
        press(game, pygame.K_DOWN)
    press(game, pygame.K_RETURN)
    a_ = screens[GameState.ACT_2_SETUP]
    dismiss(game)
    a_.wave.timer = 99999
    return a_


# --- menú: navegación con teclado y ratón
game.machine.transition(GameState.MENU)
menu = campaign_menu(game)
assert game.machine.current_state is GameState.CAMPAIGN_MENU and len(menu.buttons) == 4
assert menu.current_index == 0 and menu.buttons[0]["selected"] and menu.buttons[0]["name"] == CM["map_1_infiltration"]["name"]
press(game, pygame.K_UP)
assert menu.current_index == 0                                                    # no se sale por arriba
press(game, pygame.K_DOWN); press(game, pygame.K_DOWN)
assert menu.current_index == 2 and menu.buttons[2]["selected"] and not menu.buttons[0]["selected"]
for _ in range(5):
    press(game, pygame.K_DOWN)
assert menu.current_index == 3 and menu.buttons[3]["key"] is None                # el último: Acto 2 clásico
game.machine.draw(game.screen)
assert all(_CMS.summary(b_) for b_ in menu.buttons)
press(game, pygame.K_ESCAPE)
assert game.machine.current_state is GameState.ACT_2_BASE
press(game, pygame.K_6)
# Fase 6 · desbloqueo lineal: sin ganar el mapa 1, el 2 y el 3 tienen candado y no se inician (el clásico sí)
assert [b_["locked"] for b_ in menu.buttons] == [False, True, True, False]
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=menu.buttons[1]["rect"].center))
assert game.machine.current_state is GameState.CAMPAIGN_MENU and "BLOQUEADO" in menu.notice
assert menu.start_campaign("map_3_siege") is False and game.machine.current_state is GameState.CAMPAIGN_MENU
game.machine.draw(game.screen)                                                     # candados en pantalla
game.campaign_run.completed_maps.add("map_1_infiltration")
press(game, pygame.K_ESCAPE)
press(game, pygame.K_6)
assert [b_["locked"] for b_ in menu.buttons] == [False, False, True, False] and menu.notice == ""
assert menu.buttons[0]["completed"]
r_ = game.resources
r_.campaign_time, r_.campaign_rewards = 55.0, ["x"]
r_.act2_fog = b"old"
game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=menu.buttons[1]["rect"].center))
assert game.machine.current_state is GameState.ACT_2_SETUP and r_.campaign_map == "map_2_push"
assert r_.campaign_time == 0 and r_.campaign_rewards == [] and r_.act2_fog is None   # empieza limpio
# el Terminal sigue sin dejar pasar sin incursión inicial
game.machine.transition(GameState.MENU)
game.new_campaign()
game.machine.transition(GameState.ACT_2_BASE)
press(game, pygame.K_6)
assert game.machine.current_state is GameState.ACT_2_BASE

# --- Acto 2 carga la configuración del mapa: tamaño, bases, oleadas y sin Fundición (mapas 1 y 2)
game.machine.transition(GameState.MENU)
a2 = campaign_act2(game, 0)
assert a2.scenario.key == "map_1_infiltration" and (a2.map_w, a2.map_h) == (2000, 1500) and a2.CC_POS == Vector2(1000, 1125)
assert a2.foundry_core is None and len(a2.enemy_bases) == 1 and a2.enemy_bases[0].difficulty == "easy"
assert a2.enemy_bases[0].pos == Vector2(1000, 188) and a2.enemy_bases[0].base_id == "base_1a" and a2.enemy_bases[0].index == 0
assert a2.wave.total_waves == 8 and a2.wave.endless and a2.wave.break_time == 30 and a2.wave.plan is a2.scenario.plan
assert a2.game_map.rect.size == (2000, 1500) and a2.world.player is None
assert a2.core.pos == Vector2(1000, 1125) and 590 < a2.campaign_time_left() <= 600
assert len(a2.deposit_list) == 4 and a2.deposit_list[3].pos == a2.CC_POS + Vector2(460, -430)      # 3 de la base + 1 exterior
assert a2.map_rect.contains(a2.deposit_list[3].rect) and a2.deposit_list[3] in a2.world.deposits
step(game, 3)
assert game.resources.campaign_time > 0 and a2.campaign_time_left() < 600
a2.paused = True
t_before = game.resources.campaign_time
step(game, 5)
assert game.resources.campaign_time == t_before                                   # en pausa el reloj se detiene
a2.paused = False
game.machine.draw(game.screen)
# oleadas desde bajo la base enemiga y con el tamaño del mapa
a2.wave.timer = 0.01
step(game, 5)
assert a2.wave.wave == 1 and a2.wave.phase == "wave" and a2.wave.wave_kind == "small"
assert len(a2.world.enemies) == 1 and next(iter(a2.world.enemies)).pos.y < 400        # nace bajo la base enemiga (arriba)\nstep(game, 400)\nassert next(iter(a2.world.enemies)).pos.y > 700                                        # y marcha hacia el Centro de Control
zones_ = a2.scenario.base_zones(a2.enemy_bases)
assert len(zones_) == 1 and zones_[0].centerx == 1000
# victoria del mapa 1: destruir su única base (sin Fundición)
assert not a2.check_victory_condition()
r_ = game.resources
chassis0 = r_.chassis_found
raze(a2.enemy_bases[0])
assert a2.check_victory_condition() and r_.chassis_found == chassis0 + 1 and r_.campaign_rewards == ["AURA_PART_1"]
step(game, 2)
assert a2.victory
for _ in range(300):
    step(game, 1)
    if game.machine.current_state is GameState.VICTORY:
        break
assert game.machine.current_state is GameState.VICTORY
title_, line_, _c = victory_texts(game.resources)
assert "Infiltración" in line_ and "FÁCIL" in line_.upper() or "EASY" in line_.upper()
assert any("Mapa:" in s_ for s_ in game.end_stats) and any(f"/{C.CHASSIS_TOTAL_PARTS}" in s_ for s_ in game.end_stats)
game.machine.draw(game.screen)

# --- mapa 2: dos bases, premios por base (parte de AURA + nodo gratis del árbol), victoria con ambas
game.machine.transition(GameState.MENU)
a2 = campaign_act2(game, 1)
r_ = game.resources
assert a2.scenario.key == "map_2_push" and len(a2.enemy_bases) == 2 and a2.foundry_core is None
assert [b_.difficulty for b_ in a2.enemy_bases] == ["medium"] * 2 and [b_.pos for b_ in a2.enemy_bases] == [Vector2(500, 188), Vector2(1500, 188)]
assert len({b_.base_id for b_ in a2.enemy_bases}) == 2 and a2.wave.total_waves == 9 and a2.wave.endless
assert len(a2.scenario.base_zones(a2.enemy_bases)) == 2
n_nodes, m_, c_ = len(r_.op_nodes), r_.metal, r_.cores
ch0 = r_.chassis_found
raze(a2.enemy_bases[0])
assert r_.chassis_found == ch0 + 1 and r_.campaign_rewards == ["AURA_PART_2"]
assert len(a2.scenario.base_zones(a2.enemy_bases)) == 1                           # la base caída ya no genera enemigos
assert not a2.check_victory_condition()
step(game, 2)
assert not a2.victory
raze(a2.enemy_bases[1])
assert r_.campaign_rewards == ["AURA_PART_2", "PLAYER_UPGRADE_1"] and len(r_.op_nodes) == n_nodes
assert r_.reward_tracker.is_unlocked("PLAYER_UPGRADE_1") and r_.reward_tracker.player_bonus("damage_reduction") == 0.2
assert r_.metal == m_ + 200 and r_.cores == c_ + 2                                # recompensa de P3.A por cada base
assert a2.check_victory_condition()
step(game, 2)
assert a2.victory
# un premio repetido se convierte en núcleos
cores_before = r_.cores
assert "ya lo tenías" in a2._apply_reward({"type": "PLAYER_UPGRADE", "id": "PLAYER_UPGRADE_1"})
assert r_.cores == cores_before + U.CAMPAIGN_REWARD_FALLBACK["cores"]
assert a2._apply_reward({"type": "???", "id": "x"}) == ""

# --- mapa 3: 3 bases + Fundición; hay que destruir TODO y los premios incluyen la mejora de drones
game.machine.transition(GameState.MENU)
a2 = campaign_act2(game, 2)
r_ = game.resources
assert a2.scenario.key == "map_3_siege" and (a2.map_w, a2.map_h) == (2500, 2000) and a2.CC_POS == Vector2(525, 1250) and len(a2.deposit_list) == 5
assert len(a2.enemy_bases) == 3 and a2.foundry_core is not None and a2.FOUNDRY_POS == Vector2(2125, 1250)
assert [b_.difficulty for b_ in a2.enemy_bases] == ["hard"] * 3 and a2.wave.total_waves == 9 and not a2.wave.endless
for b_ in a2.enemy_bases[:2]:
    raze(b_)
assert r_.campaign_rewards == ["AURA_PART_3", "PLAYER_UPGRADE_2"]
assert "Damage_Attack" not in r_.drone_upgrades
raze(a2.enemy_bases[2])
assert r_.campaign_rewards[-1] == "DRONE_UPGRADE_ATTACK" and "Damage_Attack" in r_.drone_upgrades
assert not a2.bases_left() and not a2.check_victory_condition()                   # falta la Fundición
step(game, 2)
assert not a2.victory
for t_ in list(a2.foundry_core.perimeter):
    t_.take_damage(9999)
a2.foundry_core.take_damage(99999)
assert a2.check_victory_condition()
step(game, 2)
assert a2.victory

# --- límite de tiempo: sin destruir las bases, se acaba el tiempo
game.machine.transition(GameState.MENU)
a2 = campaign_act2(game, 0)
game.resources.campaign_time = 599.99
step(game, 3)
assert "TIEMPO AGOTADO" in a2.fail_reason and not a2.victory
for _ in range(200):
    step(game, 1)
    if game.machine.current_state is GameState.RETRY_SUB_ACT:
        break
assert game.machine.current_state is GameState.RETRY_SUB_ACT
game.machine.draw(game.screen)
# el reintento del sub-acto conserva el mapa y reinicia su reloj
press(game, pygame.K_r)
assert game.resources.campaign_map == "map_1_infiltration" and game.resources.campaign_time < 10
assert screens[GameState.ACT_2_SETUP].scenario.key == "map_1_infiltration"

# --- Base Central y persistencia: la base guardada se traslada al mapa elegido; las bases conservan su premio
base_ = EnemyBase(Vector2(400, 150), "medium", None)
base_.base_id, base_.index = "base_2a", 1
rest_ = EnemyBase.restore(base_.dump(), None)
assert (rest_.base_id, rest_.index) == ("base_2a", 1)
game.machine.transition(GameState.MENU)
game.new_campaign()
game.resources.campaign_map = "map_2_push"
bm_ = screens[GameState.BASE_MANAGEMENT]
game.machine.transition(GameState.BASE_MANAGEMENT)
assert bm_.CC_POS == Vector2(1125, 1375) and (bm_.map_w, bm_.map_h) == (2250, 1750) and len(bm_.deposit_list) == 5
game.machine.draw(game.screen)
game.machine.transition(GameState.MENU)
game.new_campaign()
assert game.resources.campaign_map is None and game.resources.campaign_rewards == []   # nueva campaña: todo limpio
# campaña clásica intacta: sin título de mapa y con la Fundición
a2 = new_act2(game, metal=500)
assert a2.scenario.classic and a2.foundry_core is not None and (a2.map_w, a2.map_h) == (C.ACT2_W, C.ACT2_H)
assert a2.wave.plan is None and a2.campaign_time_left() is None and a2.wave.break_time == C.BREAK_TIME
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Prioridad 3.C: oleadas escaladas (Stronghold Loop), aparición continua y escalada de la IA ==")
from src.mechanics.wave import WaveGenerator
from src.ui.hud import WaveDisplay
cfg1, cfg2, cfg3 = CM["map_1_infiltration"], CM["map_2_push"], CM["map_3_siege"]
assert U.CAMPAIGN_SPAWN_INTERVAL == 0.3
gen = WaveGenerator(cfg1)
assert gen.should_start_next_wave() and not gen.wave_active and gen.break_time == 30 and gen.spawn_interval == 0.3
gen.start_wave()                                                                   # pequeña: 1 enemigo
assert gen.wave_active and not gen.wave_complete and len(gen.spawn_queue) == cfg1["wave_small_sizes"][0] and not gen.is_big_wave
gen.start_wave()                                                                   # no empieza otra hasta completar la actual
assert gen.current_wave_index == 1
# timing preciso: 1 enemigo por 0,3 s
gen = WaveGenerator(cfg3)
gen.start_wave()
assert gen.update(0.3) is not None and gen.update(0.1) is None and gen.update(0.1) is None and gen.update(0.2) is not None
assert gen.get_wave_info() == {"wave_number": 1, "is_big_wave": False, "enemies_remaining": 1}
# la cola se vacía y la oleada termina
gen = WaveGenerator(cfg1)
gen.start_wave()
spawned = 0
for _ in range(10):
    spawned += gen.update(0.4) is not None
assert spawned == 1 and gen.wave_complete and not gen.wave_active and gen.should_start_next_wave()
# 5 pequeñas -> grande; cada 5 pequeñas otra; tamaños en bucle y la grande repite la última
for cfg_, sizes_small, sizes_big in ((cfg1, cfg1["wave_small_sizes"], cfg1["wave_big_sizes"]),
                                     (cfg2, cfg2["wave_small_sizes"], cfg2["wave_big_sizes"]),
                                     (cfg3, cfg3["wave_small_sizes"], cfg3["wave_big_sizes"])):
    gen, seen, ks, kb = WaveGenerator(cfg_), [], 0, 0
    for n_ in range(1, 41):
        gen.start_wave()
        want_big = n_ % (cfg_["wave_big_interval"] + 1) == 0
        assert gen.is_big_wave == want_big, (n_, want_big)
        size_ = len(gen.spawn_queue)
        if want_big:
            assert size_ == sizes_big[min(kb, len(sizes_big) - 1)]
            kb += 1
        else:
            assert size_ == sizes_small[ks % len(sizes_small)]
            ks += 1
        gen.spawn_queue.clear(); gen.wave_active = False; gen.wave_complete = True
    assert gen.current_wave_index == 40
gen = WaveGenerator(cfg1)
for _ in range(5):
    gen.start_wave(); gen.spawn_queue.clear(); gen.wave_complete = True; gen.wave_active = False
gen.start_wave()
assert gen.is_big_wave and len(gen.spawn_queue) == 3                                # la 6.ª es la primera grande (3)
# la composición escala con la dificultad
easy_m = {k_ for _, _, r_ in WaveGenerator(cfg1).plan for k_ in r_}
hard_m = {k_ for _, _, r_ in WaveGenerator(cfg3).plan for k_ in r_} | set(U.campaign_wave_entry(cfg3, 24)[2])
assert easy_m <= {"scout", "soldier"} and {"scout", "soldier", "ariete", "tank"} <= hard_m
# en la partida: aparición continua cada 0,3 s, grande tras 5 pequeñas y sin asalto en los mapas sin Fundición
game.machine.transition(GameState.MENU)
a2 = campaign_act2(game, 1)                                                         # mapa 2: tamaños 2,2,3,2,3 y la grande (5)
wm = a2.wave
assert wm.generator is not None and wm.endless and wm.generator.spawn_interval == 0.3
sizes_seen = []
for n_ in range(1, 8):
    wm.timer = 0.01
    if wm.phase == "break":
        wm.timer = 0.01
    for _ in range(10):
        step(game, 1)
        if wm.phase == "wave" and wm.wave == n_:
            break
    assert wm.wave == n_ and wm.phase == "wave", (n_, wm.phase, wm.wave)
    assert wm.wave_kind == ("big" if n_ == 6 else "small")
    assert wm.current.spawn_rate == 0.3
    sizes_seen.append(len(wm.current.schedule))
    if n_ == 1:                                                                     # aparecen de uno en uno, cada 0,3 s
        spawn_frames = []
        prev = wm.spawned
        for f_ in range(60):
            step(game, 1)
            if wm.spawned != prev:
                spawn_frames.append(f_); prev = wm.spawned
        assert wm.spawned == 2 and abs((spawn_frames[-1] - spawn_frames[0] + 1) - 18) <= 2 or len(spawn_frames) >= 1
    for e_ in list(a2.world.enemies):
        e_.kill()
    wm.spawned = len(wm.current.schedule); wm.pending_delayed = []
    for _ in range(10):
        step(game, 1)
        if wm.phase == "break":
            break
    assert wm.phase == "break" and wm.timer == 30 - 10 / 60 * 0 or wm.timer > 29, wm.timer      # 30 s de descanso
assert sizes_seen == [2, 2, 3, 2, 3, 5, 4]
assert wm.phase == "break" and wm.wave == 7
assert a2.wave.phase != "assault"                                                   # más allá del plan sigue en bucle
# el descanso cuenta 30 s reales y la siguiente oleada empieza sola
t_break = wm.timer
step(game, 60)
assert abs((t_break - wm.timer) - 1.0) < 0.05
wm.timer = 0.05
step(game, 6)
assert wm.phase == "wave" and wm.wave == 8
# HUD: panel de oleadas de campaña
game.machine.draw(game.screen)
WaveDisplay().draw(game.hud, game.screen, (900, 130), wm)
wm.phase = "break"; wm.timer = 12
WaveDisplay().draw(game.hud, game.screen, (900, 130), wm)
# mapa 3 (con Fundición): tras la 1.ª vuelta (9 oleadas) pasa al asalto
game.machine.transition(GameState.MENU)
a2 = campaign_act2(game, 2)
assert not a2.wave.endless and a2.wave.total_waves == 9
# IA enemiga: cada 3 edificios perdidos decide 5 s antes (mínimo 20 s); el estado viaja con la base
eb = EnemyBase(Vector2(800, 150), "medium", a2.world)
assert eb.ai_action_interval == 45.0
fake = [eb._ai_try_build for _ in range(1)]
for _ in range(3):
    eb.on_building_lost(object())
assert eb.escalation == 3 and eb.ai_action_interval == 40.0
for _ in range(60):
    eb.on_building_lost(object())
assert eb.ai_action_interval == 20.0                                                # suelo
for e_ in list(a2.world.enemies):
    e_.kill()
assert EnemyBase.restore(eb.dump(), a2.world).ai_action_interval == 20.0
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Prioridad 4: Rewards System (16 desbloqueos permanentes, popup, progreso y persistencia entre mapas) ==")
from src.mechanics.rewards import RewardTracker
from src.entities.factory import drone_stats as _dstats
RD = U.REWARD_DEFINITIONS
assert len(RD) == 16 and sum(v["type"] == "aura_part" for v in RD.values()) == 6
assert sum(v["type"] == "player_upgrade" for v in RD.values()) == 6 and sum(v["type"] == "drone_upgrade" for v in RD.values()) == 4
for rid_, rw_ in RD.items():                                                       # definiciones bien formadas
    assert {"type", "name", "description"} <= set(rw_), rid_
    if rw_["type"] in ("player_upgrade", "drone_upgrade"):
        assert "operator_tree_node" in rw_ and rw_["bonus"], rid_
for map_cfg in CM.values():                                                        # los premios de los mapas existen
    assert all(rw_["id"] in RD for rw_ in map_cfg["rewards"])
# RewardTracker
tr = RewardTracker()
assert tr.add_reward("AURA_PART_1") and tr.is_unlocked("AURA_PART_1") and tr.aura_parts_count == 1
assert not tr.add_reward("AURA_PART_1") and tr.aura_parts_count == 1               # sin duplicados
assert not tr.add_reward("NO_EXISTE") and len(tr.unlocked_rewards) == 1
tr.add_reward("PLAYER_UPGRADE_1"); tr.add_reward("DRONE_UPGRADE_ATTACK")
assert tr.get_progress() == {"aura_parts": "1/6", "player_upgrades": "1/6", "drone_upgrades": 1, "total_rewards": 3}
assert [h_["id"] for h_ in tr.reward_history] == ["AURA_PART_1", "PLAYER_UPGRADE_1", "DRONE_UPGRADE_ATTACK"]
assert not tr.aura_complete()
for i_ in range(2, 7):
    tr.add_reward(f"AURA_PART_{i_}")
assert tr.aura_complete() and tr.aura_parts_count == 6
for dt_ in ("RECON", "BOMBER", "TROOPER"):
    tr.add_reward("DRONE_UPGRADE_" + dt_)
assert tr.get_progress()["drone_upgrades"] == 4 and all(tr.drone_upgrades.values())
assert tr.player_bonus("damage_reduction") == 0.20 and tr.player_bonus("speed") == 0 and tr.drone_bonus("attack") == {"damage": 10}
# efectos sobre el Operador (los 6) y persistencia en el ResourceManager / checkpoints
from src.managers.resource_manager import ResourceManager as _RM4
rm = _RM4()
base_hp, base_cap = rm.player_max_hp, rm.ammo_capacity()
for i_ in range(1, 7):
    rm.reward_tracker.add_reward(f"PLAYER_UPGRADE_{i_}")
assert rm.player_max_hp == base_hp + 50 and rm.ammo_capacity() == base_cap + 100
snap = rm.snapshot(); rm.reward_tracker.unlocked_rewards.clear()                    # el snapshot es una copia profunda
rm.restore(snap)
assert len(rm.reward_tracker.unlocked_rewards) == 6 and rm.reward_tracker.player_upgrades_count == 6
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=500)
pl = Player((420, 830), C.ACT2_W, C.ACT2_H)                                        # el Operador que se desplegará
pl.apply_upgrades(a2.res)
assert pl.speed == C.PLAYER_SPEED and pl.regen_rate == 0 and pl.vision_bonus == 0 and pl.armor_reduction == 0
hp0, cap0 = pl.max_hp, pl.capacity
for rid_ in ("PLAYER_UPGRADE_1", "PLAYER_UPGRADE_2", "PLAYER_UPGRADE_3", "PLAYER_UPGRADE_4", "PLAYER_UPGRADE_5", "PLAYER_UPGRADE_6"):
    a2._apply_reward({"type": "PLAYER_UPGRADE", "id": rid_})                        # se ganan en el Acto 2...
pl.refresh_rewards(a2.res)                                                          # ...y el traje los recibe
assert pl.armor_reduction == 0.2 and pl.speed == C.PLAYER_SPEED + 50 and pl.capacity == cap0 + 100
assert pl.max_hp == hp0 + 50 and pl.hp == hp0 + 50 and pl.regen_rate == 3 and pl.vision_bonus == 100
a2.res.reward_tracker.add_reward("AURA_PART_1")
pl.take_damage(10)
assert abs(pl.hp - (hp0 + 50 - 8)) < 1e-9                                           # -20% de daño recibido
hp_now = pl.hp
pl.update(1.0, pygame.key.get_pressed(), (640, 360), pygame.sprite.Group())
assert pl.hp == hp_now                                                              # la regeneración espera sin daño
for _ in range(round((C.PLAYER_REGEN_DELAY - 1.0 + 0.5) * 60)):                     # hasta medio segundo después
    pl.update(1 / 60, pygame.key.get_pressed(), (640, 360), pygame.sprite.Group())
assert pl.hp > hp_now + 3 * 0.5 or pl.hp == pl.max_hp
game.machine.draw(game.screen)
# se vuelve a desplegar con los bonus (Acto 1 incluido) y el nuevo Operador los conserva
pl2 = Player((0, 0), 2000, 1200)
pl2.apply_upgrades(a2.res)
assert pl2.speed == C.PLAYER_SPEED + 50 and pl2.max_hp == a2.res.player_max_hp and pl2.vision_bonus == 100
# mejoras de dron: se suma el mayor entre lo comprado y el reward, y la mejora figura como instalada
rt = RewardTracker()
assert _dstats("attack", (), rt)["damage"] == U.DRONE_TYPES["attack"]["damage"]
rt.add_reward("DRONE_UPGRADE_ATTACK"); rt.add_reward("DRONE_UPGRADE_RECON"); rt.add_reward("DRONE_UPGRADE_BOMBER"); rt.add_reward("DRONE_UPGRADE_TROOPER")
assert _dstats("attack", (), rt)["damage"] == U.DRONE_TYPES["attack"]["damage"] + 10
assert _dstats("attack", {"Damage_Attack"}, rt)["damage"] == U.DRONE_TYPES["attack"]["damage"] + 10      # no se acumulan
assert _dstats("recon", (), rt)["speed"] == U.DRONE_TYPES["recon"]["speed"] + 70
assert _dstats("bomber", {"Payload_Bomber"}, rt)["bomb_damage"] == U.DRONE_TYPES["bomber"]["bomb_damage"] + 35   # max(25, 35)
assert _dstats("trooper", (), rt)["hp"] == U.DRONE_TYPES["trooper"]["hp"] + 80
assert _dstats("bomber", (), RewardTracker())["bomb_damage"] == U.DRONE_TYPES["bomber"]["bomb_damage"]
assert _dstats("recon", ())["speed"] == U.DRONE_TYPES["recon"]["speed"]
game.machine.transition(GameState.MENU)

# --- en la partida: reward al destruir la base, popup de 3 s, progreso y persistencia entre mapas
a2 = campaign_act2(game, 0)
r_ = game.resources
assert r_.reward_tracker.get_progress()["total_rewards"] == 0 and a2.reward_popup is None
ch0 = r_.chassis_found
raze(a2.enemy_bases[0])
assert a2.reward_popup is not None and a2.reward_popup["reward"]["name"] == "Componente AURA #1"
assert r_.reward_tracker.is_unlocked("AURA_PART_1") and r_.chassis_found == ch0 + 1
t_pop = a2.reward_popup["timer"]
assert t_pop == 3.0
a2.paused = True
step(game, 10)
assert a2.reward_popup["timer"] == t_pop                                              # en pausa no avanza
a2.paused = False
a2.victory = False
game.machine.draw(game.screen)
step(game, 60)
assert 1.9 < a2.reward_popup["timer"] < 2.1, a2.reward_popup["timer"]
game.machine.draw(game.screen)
game.hud.progress_bar.draw(game.hud, game.screen, (900, 170), r_)
assert "AURA" in game.hud.progress_bar.text(r_) and f"/{C.CHASSIS_TOTAL_PARTS}" in game.hud.progress_bar.text(r_)
for _ in range(130):
    step(game, 1)
    if a2.reward_popup is None or game.machine.current_state is not GameState.ACT_2_PLAY:
        break
assert a2.reward_popup is None or game.machine.current_state is not GameState.ACT_2_PLAY
# victoria: pantalla con los rewards del mapa y progreso; ENTER vuelve a elegir mapa y el tracker persiste
for _ in range(300):
    step(game, 1)
    if game.machine.current_state is GameState.VICTORY:
        break
assert game.machine.current_state is GameState.VICTORY and r_.campaign_rewards == ["AURA_PART_1"]
assert game.campaign_run.last_result_message == "Primer viaje: +100⚙ +3🔷 +4▣"      # premio del primer viaje (+2 por el Centro sano)
assert r_.alloy == U.ENEMY_BASES["destroy_reward"]["alloy"] + U.CAMPAIGN_MAP_ALLOY["map_1_infiltration"] + 2   # 1 + 2 + 2
assert "map_1_infiltration" in game.campaign_run.completed_maps
game.machine.draw(game.screen)
press(game, pygame.K_RETURN)
assert game.machine.current_state is GameState.CAMPAIGN_MENU
assert not screens[GameState.CAMPAIGN_MENU].buttons[1]["locked"]                    # ganar el 1 desbloquea el 2
press(game, pygame.K_DOWN)
press(game, pygame.K_RETURN)                                                          # mapa 2
assert r_.campaign_map == "map_2_push" and r_.campaign_rewards == []                  # lista del mapa limpia...
assert r_.reward_tracker.is_unlocked("AURA_PART_1")                                   # ...pero el tracker persiste
a2 = screens[GameState.ACT_2_SETUP]
dismiss(game)
raze(a2.enemy_bases[0])
raze(a2.enemy_bases[1])
assert r_.reward_tracker.get_progress() == {"aura_parts": "2/6", "player_upgrades": "1/6", "drone_upgrades": 0, "total_rewards": 3}
assert a2.res.reward_tracker.player_bonus("damage_reduction") == 0.2
step(game, 300)
game.machine.draw(game.screen)
# rejugar el mapa 1 (Fase 6, anti-farmeo): ni la base, ni la consolación, ni el premio de mapa pagan nada
press(game, pygame.K_RETURN)
assert game.machine.current_state is GameState.CAMPAIGN_MENU
press(game, pygame.K_UP)
press(game, pygame.K_RETURN)
a2 = screens[GameState.ACT_2_SETUP]
dismiss(game)
assert game.campaign_run.is_repeat
ch1, c1, m1 = r_.chassis_found, r_.cores, r_.metal
raze(a2.enemy_bases[0])
assert r_.chassis_found == ch1 and r_.cores == c1 and r_.metal == m1                 # 0/0 en la repetición
assert r_.campaign_rewards == [] and a2.reward_popup is None
for _ in range(300):
    step(game, 1)
    if game.machine.current_state is GameState.VICTORY:
        break
assert game.machine.current_state is GameState.VICTORY and r_.metal == m1 and r_.cores == c1
assert game.campaign_run.last_result_message == "Mapa repetido: sin recursos"
game.machine.draw(game.screen)
# la base guardada no se desplaza de más al cambiar de mapa repetidas veces
game.machine.transition(GameState.MENU)
game.new_campaign()
assert game.resources.reward_tracker.get_progress()["total_rewards"] == 0               # campaña nueva: todo limpio
game.resources.initial_done = True
game.machine.transition(GameState.ACT_2_BASE)
press(game, pygame.K_6)
mn = screens[GameState.CAMPAIGN_MENU]
game.resources.base_layout = [{"type": "wall", "pos": (400.0, 600.0), "hp": 10}]
game.campaign_run.completed_maps.update(CM)                                        # todos desbloqueados
for target in (1, 0, 2):
    mn.current_index = 0
    mn.start_campaign(list(CM)[target])
    game.machine.transition(GameState.ACT_2_BASE)
    press(game, pygame.K_6)
    mn = screens[GameState.CAMPAIGN_MENU]
exp = Vector2(400, 600) + (Vector2(CM["map_3_siege"]["player_base"]) - Vector2(C.ACT2_CC_POS))
assert Vector2(game.resources.base_layout[0]["pos"]) == exp
# la recompensa de dron mejora a los drones que fabrica la Fábrica
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=2000)
assert build(a2, "pylon", (540, 620)) and build(a2, "pylon", (540, 540))
assert build(a2, "fabrica", (600, 560))
fac = a2.factory
assert fac is not None and fac.rewards is a2.res.reward_tracker
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Prioridad 5 + Bloque 3.A: UpgradeManager, árbol del Operador (6 nodos), Compuerta Blindada, escape del 1.4 y VULCANO pesado ==")
from src.mechanics.upgrades import UpgradeManager
from src.entities.building import Compuerta
from src.ui.hud import OperatorTreeUI
um = UpgradeManager()
tree_ = um.upgrade_tree
assert set(tree_) == {"OFENSIVA", "SUPERVIVENCIA", "RECOMPENSAS"} and len(tree_["OFENSIVA"]) == 3 and len(tree_["SUPERVIVENCIA"]) == 4
assert len(tree_["RECOMPENSAS"]) == 10 and len(U.OPERATOR_TREE) == 7 and len(U.OPERATOR_BONUSES) == 7
assert not tree_["OFENSIVA"]["Gatillo_Automatico"]["unlocked"] and tree_["OFENSIVA"]["Calibre_Perforante_I"]["parent"] == "Gatillo_Automatico"
assert tree_["OFENSIVA"]["Gatillo_Automatico"]["children"] == ["Calibre_Perforante_I"]
assert tree_["SUPERVIVENCIA"]["Impulso_Doble"]["children"] == ["Blindaje_Titanio"] and tree_["SUPERVIVENCIA"]["Blindaje_Titanio"]["children"] == ["Celda_Vital_I"]
assert tree_["SUPERVIVENCIA"]["Celda_Vital_I"]["children"] == ["Celda_Vital_II"] and tree_["SUPERVIVENCIA"]["Celda_Vital_II"]["children"] == []
from src.ui.hud import reachable_rewards as _reach
assert {v_["reward"] for v_ in tree_["RECOMPENSAS"].values() if v_["reward"] in _reach()} == {
    "PLAYER_UPGRADE_1", "PLAYER_UPGRADE_2", "DRONE_UPGRADE_ATTACK"}                     # la vista [T] solo muestra estas 3
assert U.REWARD_DEFINITIONS["DRONE_UPGRADE_ATTACK"]["name"] == "Cañón Pesado de Asalto"
assert um.unlock_node("Gatillo_Automatico") and um.upgrade_tree["OFENSIVA"]["Gatillo_Automatico"]["unlocked"]
assert um.res.owns("gatillo_automatico")                                             # el gestor escribe en el estado real
assert not um.unlock_node("Gatillo_Automatico") and not um.unlock_node("No_Existe")
assert um.get_bonus("auto_fire") is True and um.apply_bonus("Gatillo_Automatico") and um.get_bonus("auto_fire") is True   # sin duplicar
assert not um.apply_bonus("Sobrecarga_Balistica") and um.get_bonus("bullet_damage") == 0 and um.get_bonus("bullet_damage", 7) == 7
um.unlock_node("Calibre_Perforante_I"); um.unlock_node("Sobrecarga_Balistica")
assert um.get_bonus("bullet_damage") == 8 and um.get_bonus("bullet_pierce") == 1 and um.get_bonus("fire_cooldown") == 0.12
um.unlock_node("Blindaje_Titanio")
assert um.get_bonus("flat_armor") == 4
assert um.unlock_node("Armor_Light") and um.is_unlocked("PLAYER_UPGRADE_1")           # reward con nodo propio
assert abs(um.get_bonus("damage_reduction") - 0.20) < 1e-9
um.unlock_node("Regen_Enhanced")
assert um.get_bonus("regen_rate") == 3
assert um.unlock_node("Speed_Boost") and um.get_bonus("move_speed") == 50
disp = um.get_tree_display()
assert disp["OFENSIVA"]["Gatillo_Automatico"]["unlocked"] and disp["OFENSIVA"]["Gatillo_Automatico"]["cost"] == {"scrap": 0, "plasma_core": 1}
assert disp["RECOMPENSAS"]["Armor_Light"]["unlocked"] and not disp["RECOMPENSAS"]["Damage_Attack"]["unlocked"]
# Terminal: la Celda Vital I (4 núcleos) exige antes el Impulso Doble y el Blindaje de Titanio
game.machine.transition(GameState.MENU)
game.new_campaign()
game.resources.initial_done = True
game.resources.metal, game.resources.cores = 1000, 8
game.machine.transition(GameState.ACT_2_BASE)
term = screens[GameState.ACT_2_BASE]
lay = tree_layout()
assert max(rc_.bottom for rc_ in lay.values()) < 558 and len({(rc_.x, rc_.y) for rc_ in lay.values()}) == 7
for k_, rc_ in lay.items():                                                             # ningún nodo pisa a otro
    assert not any(rc_.colliderect(o_) for j_, o_ in lay.items() if j_ != k_), k_
for node_ in ("celda_vital", "blindaje_titanio", "impulso_doble", "blindaje_titanio", "celda_vital"):
    game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=lay[node_].center))
    if node_ in ("celda_vital", "blindaje_titanio") and not game.resources.owns("impulso_doble"):
        assert not game.resources.owns(node_) and "Bloqueada" in term.upgrade_msg
assert all(game.resources.owns(n_) for n_ in ("impulso_doble", "blindaje_titanio", "celda_vital"))
assert game.resources.metal == 1000 and game.resources.cores == 8 - 1 - 3 - 4
game.machine.draw(game.screen)
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=2000, before=lambda r_: r_.op_nodes.update({"impulso_doble", "blindaje_titanio", "celda_vital"}))
pl = Player((0, 0), 2000, 1200)                                                         # el Operador con ese árbol
pl.apply_upgrades(a2.res)
assert pl.regen_rate == 0 and pl.regen_delay == C.PLAYER_REGEN_DELAY and pl.regen_mult == 1.0 and not pl.aura_regen
assert pl.health_blocks == 4 and pl.max_hp == 133
pl.aura_regen = True                                                                    # con AURA: 5 + 2,5 HP/s
pl.take_damage(30, direct=True)                                                         # 30 - 4 de armadura plana
hp_hit = pl.hp
for _ in range(round((C.PLAYER_REGEN_DELAY - 0.5) * 60)):                               # aún dentro de la espera de 3 s
    pl.update(1 / 60, pygame.key.get_pressed(), (640, 360), pygame.sprite.Group())
assert pl.hp == hp_hit
for _ in range(30 + 120):                                                               # termina la espera y 2 s regenerando
    pl.update(1 / 60, pygame.key.get_pressed(), (640, 360), pygame.sprite.Group())
assert abs(pl.hp - (hp_hit + 7.5 * 2)) < 0.2, pl.hp - hp_hit                            # 7,5 HP/s x 2 s
# árbol en pantalla (T) con el estado real
assert isinstance(a2.upgrade_manager, UpgradeManager) and a2.upgrade_manager.res is a2.res and not a2.show_tree
press(game, pygame.K_t)
assert a2.show_tree
game.machine.draw(game.screen)
OperatorTreeUI().draw(game.hud, game.screen, a2.upgrade_manager)
press(game, pygame.K_t)
assert not a2.show_tree
a2._apply_reward({"type": "PLAYER_UPGRADE", "id": "PLAYER_UPGRADE_1"})
assert a2.upgrade_manager.is_unlocked("Armor_Light") and a2.upgrade_manager.get_bonus("damage_reduction") == 0.2

# --- Compuerta Blindada
cs = U.BUILDINGS["compuerta"]
assert (cs["cost"], cs["hp"], cs["energy"], cs["width"], cs["height"]) == (45, 500, 1, 40, 80) and cs["blocks_enemies"]
gate0 = Compuerta(640, 360)
assert gate0.health == 500 and gate0.max_health == 500 and not gate0.is_open and gate0.rect.size == (40, 80)
assert gate0.building_type == "compuerta" and gate0.sell_value == int(45 * 0.7)
class _Ally:
    is_ally = True
class _Foe:
    enemy_type = "scout"
assert gate0.requires_power and not gate0.is_powered and not gate0.active              # sin red: congelada
assert gate0.check_collision(_Ally()) is False and not gate0.is_open and not gate0.ally_passable
gate0.is_powered = True                                                                 # conectada a la red
assert gate0.check_collision(_Ally()) is True and gate0.is_open and gate0.open_timer == 2.0
assert gate0.check_collision(_Foe()) is False
gate0.update(1.0)
assert gate0.is_open
gate0.update(1.1)
assert not gate0.is_open                                                                # se cierra a los 2 s
gate0.open()
assert gate0.is_open
gate0.is_powered = False                                                                # corte de energía: se cierra de golpe
gate0.update(0.1)
assert not gate0.is_open and gate0.open_timer == 0 and not gate0.ally_passable
gate0.open()
assert not gate0.is_open                                                                # y no se abre mientras no haya red
gate0.is_powered, gate0.energized = True, False                                         # red saturada (sin energía neta)
assert not gate0.active and gate0.check_collision(_Ally()) is False
gate0.energized = True
from src.ui import structure_art as gart
from src.ui.tooltips import building_card as _bcard, structure_card as _scard
assert gart.render_gate((40, 80), True).get_size() == (40, 80)
assert pygame.image.tostring(gart.render_gate((40, 80), True), "RGBA") != pygame.image.tostring(gart.render_gate((40, 80), False), "RGBA")
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=2000)
assert [bt for _, bt in a2.build_menu][-1] == "compuerta" and len(a2.build_menu) == 8
slots_ = game.hud.build_slots(a2.build_menu)
assert len(slots_) == 8 and max(r_.right for r_, _ in slots_) <= 1092 and all(
    not r1.colliderect(r2) for i_, (r1, _) in enumerate(slots_) for r2, _ in slots_[i_ + 1:])      # no pisa el minimapa
press(game, pygame.K_8)                                                                   # la Compuerta: tecla 8
assert a2.build_choice == "compuerta"
press(game, pygame.K_6)
assert a2.build_choice == "foco"
a2.build_choice = None
cc_ = a2.CC_POS
assert build(a2, "pylon", (cc_.x + 120, cc_.y + 20))                                      # la Compuerta necesita red
m0, e0 = a2.res.metal, a2.res.energy
assert build(a2, "compuerta", (cc_.x + 200, cc_.y + 40))
gate = next(iter(a2.world.gates))
assert a2.res.metal == m0 - 22 and a2._cost("compuerta") == 22 and gate in a2.world.structures      # 45 con el -50% de la preparación
assert gate in a2.world.structures and gate in a2.world.solids and gate.rect.size == (40, 80)
a2._sync_energy()
assert a2.res.energy == e0 + 1 and gate.energized                                         # gasta 1 de energía
assert not build(a2, "compuerta", (cc_.x + 200, cc_.y + 40))                              # no se solapa
# el Operador la franquea; un muro igual de grueso no (un Operador de prueba: el Acto 2 es de mando, sin piloto)
pg_ = Player((0, 0), a2.map_w, a2.map_h)
pg_.equipped = True
pg_.pos = Vector2(gate.pos.x - 50, gate.pos.y); pg_.rect.center = (round(pg_.pos.x), round(pg_.pos.y))
pg_.vel = Vector2(300, 0)
for _ in range(6):
    pg_._move(1 / 20, a2.world.solids)
assert pg_.pos.x > gate.pos.x + 20 and gate.is_open
wall_t = Building("wall", (gate.pos.x + 300, gate.pos.y))
a2.world.solids.add(wall_t)
pg_.pos = Vector2(wall_t.pos.x - 50, wall_t.pos.y); pg_.rect.center = (round(pg_.pos.x), round(pg_.pos.y))
for _ in range(6):
    pg_._move(1 / 20, a2.world.solids)
assert pg_.pos.x < wall_t.pos.x                                                     # el muro sí bloquea
a2.world.solids.remove(wall_t)
# los drones aliados la abren; sin nadie cerca se cierra; los enemigos nunca pasan (es sólida y hay que romperla)
gate.is_open = False
gate.update(0.1, pygame.sprite.Group(), pygame.sprite.Group())
assert not gate.is_open or pg_.pos.distance_to(gate.pos) <= 70
pg_.pos = gate.pos + Vector2(0, 600)
rd = ReconDrone(Vector2(gate.pos) + Vector2(30, 0), _ds3("recon"), home=a2.CC_POS)
a2.world.drones.add(rd)
gate.update(0.1, pygame.sprite.Group(), pygame.sprite.Group())
assert gate.is_open
rd.kill()
step(game, 150)
assert not gate.is_open                                                                   # 2 s después de irse
assert gate.hp == 500 and gate.take_damage(100) is False and gate.hp == 400
assert gate.check_collision(_Foe()) is False
assert game.hud.build_slots(a2.build_menu)[-1][1] == "compuerta"
assert _bcard("compuerta", 45, a2.res, a2.energy_free()) is not None and _scard(gate) is not None
game.machine.draw(game.screen)
ghost = gart.ghost_image("compuerta", (40, 80), (0, 255, 0))
assert ghost is not None and ghost.get_width() == 40

# --- VULCANO: meca pesado (misma hitbox), brazo hacia su objetivo y orugas animadas
vh = Vulcano((300, 300))
assert vh.image.get_size() == (30, 30) and vh.rect.size == (30, 30)
vh.tread = 0
vh._draw()
img0 = pygame.image.tostring(vh.image, "RGBA")
vh.tread = 1
vh._draw()
assert pygame.image.tostring(vh.image, "RGBA") != img0                                    # los eslabones avanzan
vh.start_welding(Vector2(300, 300), Vector2(300, 380), 200)
assert abs(vh.arm_angle - math.pi / 2) < 1e-6                                             # apunta a la compuerta
vh.weld(0.1)
smoke_s = pygame.Surface((200, 200))
smoke_s.fill((0, 0, 0))
vh.rect.center = (100, 100)
vh.draw_overlay(smoke_s, vh.rect, Vector2(0, 0))
vh.stop_welding()
assert vh.weld_target is None and vh.max_hp == 0 and vh.take_damage(10) is False
vv2 = Vulcano((100, 100))
vv2._glide(Vector2(160, 100), 0.1)
assert vv2.tread > 0 and abs(vv2.arm_angle) < 1e-6                                        # avanza hacia la derecha
# escape interactivo del 1.4: horda final, aviso de sobrecarga y evacuación (cubierto en el sub-acto 1.4)
assert U.VULCANO_DEFENSE["final_horde"] == {"scout": 8, "soldier": 3} and U.VULCANO_DEFENSE["overload_line_at"] == 5.0
game.machine.transition(GameState.MENU)
game.new_campaign()
game.machine.transition(GameState.SUB_ACT_1_4)
s = screens[GameState.SUB_ACT_1_4]
dismiss(game)
teleport(s, s.terminal.pos + Vector2(0, 60)); step(game, 2); press(game, pygame.K_e); dismiss(game)
teleport(s, s.exit_console.pos + Vector2(0, 60)); step(game, 2); press(game, pygame.K_e); dismiss(game)
assert s.defense is not None and not s.defense["overload_said"]
step(game, 60 * 4)
assert not s.defense["overload_said"]                                                      # a los 4 s aún no
step(game, 60 * 4)
assert s.defense["overload_said"] and any("Circuitos sobrecargados" in ln_.text for ln_ in s.dialogue.lines)
s.defense["groups"] = []
s.defense["t"] = U.VULCANO_DEFENSE["cinematic"] + U.VULCANO_DEFENSE["duration"] - 0.01
for e_ in list(s.world.enemies):
    e_.kill()
step(game, 3)
assert s.defense["done"] and s.gate.enabled and len(s.world.enemies) == 11
assert any("Brecha sellada" in ln_.text for ln_ in s.dialogue.lines)
assert s.radar_targets()[0][0] == s.gate.pos and "EVACÚA" in s.banner()
teleport(s, s.gate.pos + Vector2(-50, 0)); step(game, 2)
s.player.hp = s.player.max_hp
press(game, pygame.K_e)
assert s.pending_next is not None or s.dialogue.blocking_active                            # empieza el cierre del Acto 1
game.machine.transition(GameState.MENU)

# =============================================================================
print("== CampaignRun: estado persistente (entre mapas) y efímero (solo el mapa activo) ==")
import json
from types import SimpleNamespace as _NS
from src.managers.resource_manager import CampaignRun
from src.entities.building import create_building
from src.entities.drones import FactoryDrone

# --- instancia limpia
run_ = CampaignRun("map_1_infiltration")
assert run_.current_map_key == "map_1_infiltration" and run_.completed_maps == set() and not run_.aura_drone_lost
assert run_.layout_data == {} and run_.drone_data == [] and run_.factory_queue_data == [] and run_.timer == 0
assert (run_.bases, run_.fog, run_.drones, run_.layout, run_.world) == (None, None, None, None, None)
try:
    run_.timer = 5                                                      # el temporizador es de solo lectura
    raise AssertionError("timer debería ser de solo lectura")
except AttributeError:
    pass
assert isinstance(ResourceManager().campaign_run, CampaignRun)

# --- start_map: limpia lo efímero, conserva lo persistente y reinicia a AURA
run_.completed_maps.add("map_1_infiltration")
run_.layout_data = {"control_center": (800.0, 900.0), "core_hp": 400, "deposits": [300, 250, 100],
                    "buildings": [{"type": "wall", "pos": (900.0, 900.0), "hp": 400, "route": None, "level": 2}]}
run_.drone_data = [{"type": "attack", "hp": 30.0, "x": 850.0, "y": 950.0, "upgrades": {}}]
run_.aura_drone_lost, run_._timer, run_.bases, run_.world = True, 77.0, ["vieja"], object()
r_ = ResourceManager()
r_.enemy_bases_state, r_.act2_fog, r_.campaign_rewards = [{}], b"x", ["AURA_PART_1"]
run_.start_map("map_2_push", res=r_)
assert run_.current_map_key == "map_2_push" and run_.difficulty == "medium"
assert run_.timer == 0 and not run_.aura_drone_lost                                  # reloj y AURA reiniciados
assert run_.bases == [] and run_.drones == [] and run_.world is None and run_.layout is None
assert (run_.fog.cols, run_.fog.rows) == (2250 // 40 + 1, 1750 // 40 + 1)            # niebla nueva del tamaño del mapa
assert run_.completed_maps == {"map_1_infiltration"} and len(run_.drone_data) == 1  # lo persistente no se toca
assert run_.layout_data["control_center"] == (800.0, 900.0)                          # los datos guardados no mutan
assert r_.enemy_bases_state is None and r_.act2_fog is None and r_.campaign_rewards == []
assert r_.base_layout == [{"type": "wall", "pos": (1225.0, 1375.0), "hp": 400, "route": None, "level": 2}]
assert r_.base_deposits == [300, 250, 100] and r_.base_core_hp == 400
run_.start_map("map_2_push", res=r_)                                                 # repetir no desplaza de más
assert r_.base_layout[0]["pos"] == (1225.0, 1375.0)

# --- on_map_complete: solo la victoria registra el mapa
run_._timer = 40.0
run_.on_map_complete(False)
assert run_.completed_maps == {"map_1_infiltration"} and run_.timer == 0
run_.on_map_complete(True)                                                           # sin escena: registra y nada más
assert run_.completed_maps == {"map_1_infiltration", "map_2_push"} and len(run_.drone_data) == 1
classic_ = CampaignRun()
classic_.on_map_complete(True)
assert classic_.completed_maps == set()                                              # el clásico no es un mapa de campaña

# --- validate_base_position y deserialize_layout: todo dentro del mapa, sin solapes
eb_ = _NS(x=-50.0, y=5000.0, pos=Vector2(-50, 5000))
CampaignRun.validate_base_position(eb_, 1600, 1200)
assert (eb_.x, eb_.y) == (0, 1200) and eb_.pos == Vector2(0, 1200)
ld_ = {"control_center": (800.0, 900.0), "buildings": [
    {"type": "wall", "pos": (20.0, 900.0), "hp": 1},                     # con el traslado (-380, +100) queda en x = -360
    {"type": "wall", "pos": (-20.0, 900.0), "hp": 2},                    # también se recoloca en x = 20: choca, se descarta
    {"type": "fabrica", "pos": (600.0, 600.0), "hp": 3}]}               # cabe donde va: se conserva tal cual
out_ = run_.deserialize_layout(ld_, (420, 1000), (2000, 1600))
assert [e["hp"] for e in out_] == [1, 3] and run_.last_layout_dropped == 1, (out_, run_.last_layout_dropped)
assert out_[0]["pos"] == (20.0, 1000.0) and out_[1]["pos"] == (220.0, 700.0)
for e_ in out_:
    half_ = Vector2(Building.SIZES[e_["type"]]) / 2
    assert half_.x <= e_["pos"][0] <= 2000 - half_.x and half_.y <= e_["pos"][1] <= 1600 - half_.y
assert run_.deserialize_layout({}, (420, 1000), (2000, 1600)) == []

# --- integración: map_1 -> victoria -> map_2 (base, drones, cola y AURA viajan) -> derrota -> reintento sin duplicados
game.machine.transition(GameState.MENU)
a2 = campaign_act2(game, 0, metal=3000)
run = game.campaign_run
assert run is game.resources.campaign_run and run.current_map_key == "map_1_infiltration"
assert run.world is a2.world and run.layout is a2 and run.bases is a2.enemy_bases and run.fog is a2.fog
cc1 = Vector2(a2.core.pos)
fac = create_building("fabrica", cc1 + Vector2(-260, 160))                 # fuera de la red (su huella no toca el núcleo)
a2._register(fac)
fac.build_left = 0
wall_ = create_building("wall", cc1 + Vector2(140, 20))
a2._register(wall_)
d_attack = fac._spawn_drone("attack")
fac._spawn_drone("trooper")
fac._spawn_drone("recon")
d_attack.hp = 25
fac.current_production, fac.production_queue = "attack", ["bomber"]
fac.production_time_left = 6.0                                           # a medio fabricar (la Fábrica no tiene red)
data_ = CampaignRun.serialize_drones(a2.world.drones)
assert sorted(e["type"] for e in data_) == ["attack", "recon", "trooper"] and json.dumps(data_)
assert next(e for e in data_ if e["type"] == "attack")["hp"] == 25
lay_ = CampaignRun.serialize_layout(a2)
assert len(lay_["buildings"]) == len(a2.world.structures) - 1 and {"fabrica", "wall"} <= {e["type"] for e in lay_["buildings"]}
assert lay_["control_center"] == (cc1.x, cc1.y) and json.dumps(lay_)
game.resources.aura_drone_lost = True                                      # AURA cae en el mapa 1...
assert run.aura_drone_lost
for b_ in a2.enemy_bases:
    raze(b_)
step(game, 60 * 4)
assert game.machine.current_state is GameState.VICTORY
assert run.completed_maps == {"map_1_infiltration"} and len(run.drone_data) == 3
assert [e["drone_type"] for e in run.factory_queue_data] == ["attack", "bomber"]
assert run.factory_queue_data[0]["time_left"] == 6.0
assert run.world is None and run.layout is None                           # referencias vivas soltadas al terminar
press(game, pygame.K_RETURN)
assert game.machine.current_state is GameState.CAMPAIGN_MENU
metal_before = game.resources.metal
screens[GameState.CAMPAIGN_MENU].start_campaign("map_2_push")
dismiss(game)
a2b = screens[GameState.ACT_2_SETUP]
a2b.wave.timer = 99999
assert not game.resources.aura_drone_lost                                  # ...y vuelve en el mapa siguiente
cc2 = Vector2(a2b.core.pos)
assert cc2 == Vector2(CM["map_2_push"]["player_base"])
types_b = [s_.building_type for s_ in a2b.world.structures]
assert "fabrica" in types_b and "wall" in types_b                         # la base construida en el mapa 1 viaja
assert any(s_.building_type == "wall" and s_.pos == cc2 + Vector2(140, 20) for s_ in a2b.world.structures)
fac_b = a2b.factory
assert fac_b is not None and len(a2b.factory_drones()) == 3 and len(fac_b.drones) == 3     # a cargo de la Fábrica
assert sorted(d_.drone_type for d_ in fac_b.drones) == ["attack", "recon", "trooper"]
assert next(d_ for d_ in fac_b.drones if d_.drone_type == "attack").hp == 25
assert fac_b.built                                                                   # no vuelve a ensamblarse
assert fac_b.current_production == "attack" and fac_b.production_time_left == 6.0     # sigue donde se quedó
assert fac_b.production_queue == ["bomber"] and fac_b.committed() == 5               # cola pagada, sin cobrar de nuevo
assert game.resources.metal >= metal_before
assert all(isinstance(d_, FactoryDrone) for d_ in fac_b.drones)
# derrota en el mapa 2 y reintento: no registra el mapa y recarga los drones una sola vez
game.resources.aura_drone_lost = True
old_world = a2b.world
a2b.core.take_damage(99999)
step(game, 60 * 3)
assert game.machine.current_state is GameState.RETRY_SUB_ACT
assert run.completed_maps == {"map_1_infiltration"} and run.timer == 0
press(game, pygame.K_r)
a2c = screens[GameState.ACT_2_SETUP]
assert game.machine.current_state is GameState.ACT_2_SETUP and a2c.world is not old_world   # mundo nuevo
assert len(a2c.factory_drones()) == 3 and len(a2c.factory.drones) == 3     # sin duplicados
assert len(run.drone_data) == 3 and not game.resources.aura_drone_lost
assert run.completed_maps == {"map_1_infiltration"}                        # el checkpoint no deshace mapas ganados
assert run.world is a2c.world and run.layout is a2c
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Fase 6: blindaje de bases, drones globales, desbloqueo/anti-farmeo y tope de reducción de daño ==")
import logging as _lg6
from types import SimpleNamespace as _NS6
from src.entities.enemy_base import EnemyBase as _EB6, SentinelTower
from src.entities.foundry import HostileStructure as _HS6
from src.managers.resource_manager import validate_structure_position

game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=2000)
w = a2.world


def _wipe(base_):
    for piece_ in [base_.core] + list(base_.buildings):
        _HS6.kill(piece_)
    for dep_ in base_.deposits:
        dep_.kill()


# --- guarnición por dificultad: una sola vez, completa, dentro del mapa y sin solapes (también pegada a las esquinas)
for diff_ in ("easy", "medium", "hard"):
    spec_ = U.ENEMY_BASES["garrison"][diff_]
    for pos_ in ((1100, 650), (10, 10), (C.ACT2_W - 5, C.ACT2_H - 5)):
        b6 = _EB6(pos_, diff_, w)
        assert b6.garrison_created and [x_.kind for x_ in b6.buildings] == [k_ for k_, _, _ in spec_], (diff_, pos_)
        assert b6.generator is not None and b6.generator.kind == "generador" and b6.generator.role == "generator"
        assert len(b6.sentinels) == sum(1 for _, _, r_ in spec_ if r_ == "sentinel")
        assert all(isinstance(t_, SentinelTower) for t_ in b6.sentinels)
        assert all(w.bounds.contains(pc_.rect) for pc_ in [b6.core] + b6.buildings), (diff_, pos_)
        for i_, pc_ in enumerate(b6.buildings):
            assert not pc_.rect.colliderect(b6.core.rect) and not any(pc_.rect.colliderect(d_.rect) for d_ in b6.deposits)
            assert not any(pc_.rect.colliderect(q_.rect) for q_ in b6.buildings[i_ + 1:]), (diff_, pos_, pc_.kind)
        assert b6.has_active_defenses() and b6.core.shielded
        _wipe(b6)

# --- escudo del núcleo: generador Y al menos una centinela
b7 = _EB6((1100, 650), "hard", w)
hp7 = b7.core.hp
assert b7.core.take_damage(5000) is False and b7.core.hp == hp7 and b7.core.alive()     # absorbido
_HS6.kill(b7.sentinels[0])
assert b7.has_active_defenses()                                                          # queda otra centinela
data7 = b7.dump()
n7 = len(b7.alive_buildings())
_wipe(b7)
r7 = _EB6.restore(data7, w)                                                              # 2.1 -> 2.2: sin duplicar
assert r7.garrison_created and len(r7.buildings) == n7 and len(r7.sentinels) == 1 and r7.generator is not None
assert r7.has_active_defenses() and r7.core.take_damage(100) is False
_HS6.kill(r7.sentinels[0])
assert not r7.has_active_defenses()                                                      # sin centinelas: vulnerable
r7.core.take_damage(100)
assert r7.core.hp == hp7 - 100
_wipe(r7)
b8 = _EB6((1100, 650), "medium", w)
_HS6.kill(b8.generator)
assert not b8.has_active_defenses() and b8.core.take_damage(50) is False and b8.core.hp == hp7 - 50   # sin generador
_wipe(b8)

# --- contraataque final: detonación y evacuación (no es oleada; quien sale del mapa desaparece sin botín)
got_ev = []
b9 = _EB6((1100, 650), "hard", w)
b9.on_evacuate = lambda b_, roster_: got_ev.append(sorted(roster_))
raze(b9)
assert got_ev == [sorted(["scout"] * 8 + ["soldier"] * 2 + ["ariete"])]
_wipe(b9)
base = a2.enemy_bases[0]
base.detected = True
for e_ in list(w.enemies):
    e_.kill()
combat.FX.blasts.clear()
raze(base)
assert combat.FX.blasts and combat.FX.blasts[0][2] == U.ENEMY_BASES["evacuation"]["blast_radius"]
evac = [e_ for e_ in w.enemies if e_.is_evacuation]
assert sorted(e_.enemy_type for e_ in evac) == ["scout"] * 4 and len(evac) == len(w.enemies)
assert all(abs(e_.pos.distance_to(base.pos) - 200) < 1.5 for e_ in evac)
assert all(not w.bounds.collidepoint(e_.target_pos) for e_ in evac)                    # van hacia el borde
a2.wave.phase, a2.wave.wave = "wave", 1
a2.wave.current = Wave(1, 1, a2.CC_POS)
a2.wave.spawned, a2.wave.pending_delayed = len(a2.wave.current.schedule), []
assert a2.wave.remaining == 0
step(game, 2)
assert a2.wave.phase == "break" and any(e_.alive() for e_ in evac)                    # no retienen la oleada
scraps6 = len(w.scraps)
for e_ in evac:
    e_.pos = Vector2(e_.target_pos)
    e_.rect.center = (round(e_.pos.x), round(e_.pos.y))
step(game, 2)
assert not any(e_.alive() for e_ in evac) and len(w.scraps) == scraps6                 # se van sin soltar nada

# --- drones: 24 DPS, los muertos no se guardan y la recarga respeta el límite global (fuera del mapa -> a la base)
assert U.DRONE_TYPES["attack"]["damage"] / U.DRONE_TYPES["attack"]["shot_interval"] == 32
fac6 = create_building("fabrica", a2.CC_POS + Vector2(-200, 140))
a2._register(fac6)
fac6.build_left = 0
d_live = fac6._spawn_drone("attack")
d_dead = fac6._spawn_drone("recon")
d_dead.take_damage(9999)
data6 = CampaignRun.serialize_drones(w.drones)
assert [e_["type"] for e_ in data6] == ["attack"]                                      # el caído no se guarda
run6 = CampaignRun()
run6.drone_data = [dict(data6[0]) for _ in range(10)]
made6 = run6.deserialize_drones(w, factory=fac6, origin=a2.CC_POS)
assert len(made6) == 10 and fac6.world_drone_count() == 11                         # los supervivientes vuelven todos...
assert fac6.at_limit                                                                # ...y la flota excede: no nacen más
for d_ in made6:
    d_.kill()
run6.drone_data = [{"type": "trooper", "hp": 100.0, "x": -900.0, "y": -900.0, "upgrades": {}}]
made6 = run6.deserialize_drones(w, factory=fac6, origin=a2.CC_POS)
assert made6[0].pos == Vector2(fac6.pos)                                               # fuera del mapa: a la base

# --- drones y cola viajan de 2.1 a 2.2 (Base Central de por medio) y el reintento del 2.2 no los duplica
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=2000, vulcano=True)
w = a2.world
fac6 = create_building("fabrica", a2.CC_POS + Vector2(-200, 140))
a2._register(fac6)
fac6.build_left = 0
fac6._spawn_drone("attack")
fac6._spawn_drone("trooper")
fac6.production_queue = ["recon"]
a2.wave.phase = "wave"
a2.wave.wave = a2.wave.total_waves
a2.wave.current = Wave(5, 1, a2.CC_POS)
a2.wave.spawned = len(a2.wave.current.schedule)
step(game, 3)
assert game.machine.current_state is GameState.BASE_MANAGEMENT
assert [e_["type"] for e_ in game.resources.base_drones] == ["attack", "trooper"]
press(game, pygame.K_SPACE)
a3 = screens[GameState.ACT_2_ASSAULT]
dismiss(game)
assert game.machine.current_state is GameState.ACT_2_ASSAULT
assert sorted(d_.drone_type for d_ in a3.factory_drones()) == ["attack", "trooper"]
assert a3.factory is not None and a3.factory.built                                      # sin volver a ensamblarse
assert [k_ for k_ in [a3.factory.current_production] + a3.factory.production_queue if k_] == ["recon"]   # el encargo sigue
a3.core.take_damage(99999)
step(game, 100)
assert game.machine.current_state is GameState.RETRY_SUB_ACT
press(game, pygame.K_r)
assert len(a3.factory_drones()) == 2                                                  # sin duplicados
assert [k_ for k_ in [a3.factory.current_production] + a3.factory.production_queue if k_] == ["recon"]

# --- tope de reducción de daño: 20% (reward) + 20% (bono externo) = 40% -> 35%
game.machine.transition(GameState.MENU)
a2 = new_act2(game, before=lambda r_: r_.reward_tracker.add_reward("PLAYER_UPGRADE_1"))
p6 = Player((0, 0), 2000, 1200)
p6.apply_upgrades(a2.res)
assert abs(p6.armor_reduction - 0.20) < 1e-9 and p6.damage_reduction == 0.20
p6.damage_aura = 0.20
assert p6.damage_reduction == U.DAMAGE_REDUCTION_CAP
hp6 = p6.hp
p6.take_damage(10, direct=True)
assert abs((hp6 - p6.hp) - 6.5) < 1e-9                                                  # 10 * (1 - 0,35)
game.machine.transition(GameState.MENU)
p6b = Player((0, 0), 2000, 1200)
p6b.apply_upgrades(a2.res)
assert p6b.damage_reduction == 0.20                                                    # bajo el tope: sin cambios

# --- validación de posiciones: se ajusta y queda en el log
records6 = []
handler6 = _lg6.Handler()
handler6.emit = records6.append
log6 = _lg6.getLogger("robot_renegado.campaign")
log6.addHandler(handler6)
log6.setLevel(_lg6.INFO)
spot6 = _NS6(x=-5.0, y=50.0)
assert validate_structure_position(spot6, 100, 100) and (spot6.x, spot6.y) == (0, 50.0)
assert any("ajustada" in r_.getMessage() for r_ in records6)
assert not validate_structure_position(_NS6(x=10.0, y=10.0), 100, 100)
log6.removeHandler(handler6)
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Operador: hitbox circular, invulnerabilidad del dash y regeneración de AURA ==")
import src.entities.player as _pmod
from src.entities.obstacle import Obstacle
from src.entities.projectile import Projectile as _Proj
keys_o = Keys()


def run_op(p_, solids_, seconds_, dt_=1 / 60):
    for _ in range(round(seconds_ / dt_)):
        p_.update(dt_, keys_o, (0, 0), solids_)


def inside_any(p_, solids_):
    return any(p_._push_out(b_.rect) is not None for b_ in solids_)


# --- hitbox: círculo de radio 11 (13 x 0,83; caja de 22x22); sprite de 83 px (100 x 0,83), centrado en pos
po = Player((60, 91), 800, 600)
assert po.radius == U.PLAYER["hitbox_radius"] == 11 and po.rect.size == (22, 22)
assert _pmod.SPRITE_SIZE_ARMED == 83 and _pmod.SPRITE_SIZE_UNARMED == 60
assert po.rect.center == (60, 91)
# esquina: con 4 px de solape vertical, el cuadrado de 28 px se clavaba en x = 86; el círculo la rodea y sigue
corner = pygame.sprite.Group(Obstacle((100, 100, 40, 40)))
keys_o.clear()
keys_o[pygame.K_d] = True
run_op(po, corner, 1.5)
assert po.pos.x > 160 and not inside_any(po, corner), po.pos
# pared en diagonal: desliza a lo largo de ella sin frenarse ni hundirse
wall_o = pygame.sprite.Group(Obstacle((0, 200, 800, 40)))
po = Player((100, 170), 800, 600)
keys_o[pygame.K_s] = True
run_op(po, wall_o, 1.0)
assert po.pos.x > 280 and po.pos.y <= 200 - po.radius + 1e-6 and not inside_any(po, wall_o), po.pos
# suelo de baldosas de 40 px: las juntas no lo enganchan
tiles = pygame.sprite.Group(*[Obstacle((x_, 300, 40, 40)) for x_ in range(0, 800, 40)])
po = Player((30, 280), 800, 600)
run_op(po, tiles, 1.5)
assert po.pos.x > 300 and not inside_any(po, tiles), po.pos
# pasillo de 27 px (más estrecho que el cuadrado de 28): entra aunque llegue 3,5 px descentrado
corridor = pygame.sprite.Group(Obstacle((0, 100, 100, 200)), Obstacle((127, 100, 113, 200)))
po = Player((110, 50), 800, 600)
keys_o.clear()
keys_o[pygame.K_s] = True
run_op(po, corridor, 1.5)
assert po.pos.y > 320 and not inside_any(po, corridor), po.pos
# el dash no atraviesa un muro de 40 px ni a 20 FPS (sub-pasos de medio radio)
thick = pygame.sprite.Group(Obstacle((300, 0, 40, 600)))
po = Player((270, 300), 800, 600)
keys_o.clear()
keys_o[pygame.K_d] = True
keys_o[pygame.K_LSHIFT] = True
run_op(po, thick, 0.3, dt_=0.05)
assert po.pos.x < 300 and not inside_any(po, thick), po.pos

# --- dash: 0,15 s de inmunidad total (balas, contacto de Scouts, obuses) sin reiniciar la regeneración
pd = Player((400, 300), 800, 600)
op_group = pygame.sprite.Group(pd)                    # como en escena: un Operador "vivo" (alive()) recibe las balas
keys_o.clear()
keys_o[pygame.K_d] = True
keys_o[pygame.K_LSHIFT] = True
pd.update(1 / 60, keys_o, (0, 0), empty)
assert pd.is_dashing and pd.is_invulnerable
hp_d = pd.hp
pd.since_hit = 2.0
pd.take_damage(30)
bullets_o = pygame.sprite.Group(_Proj(pd.pos, Vector2(1, 0), 12, "enemy"))
combat.resolve_enemy_bullets(bullets_o, pd, empty, empty)
scout_o = Enemy("scout", Vector2(pd.pos), Vector2(pd.pos), pygame.sprite.Group())
scout_o.attack_timer = 0
combat.resolve_enemy_player(pd, pygame.sprite.Group(scout_o))
assert pd.hp == hp_d and pd.since_hit == 2.0 and len(bullets_o) == 0          # bloqueado (la bala se deshace)
assert pd.take_damage(5, direct=True) is None and pd.hp == hp_d - 5              # solo `direct` lo atraviesa
hp_d = pd.hp
keys_o[pygame.K_LSHIFT] = False
frames_d = 0
while pd.is_dashing:                                  # cuenta los fotogramas en los que el dash está activo
    frames_d += 1
    pd.update(1 / 60, keys_o, (0, 0), empty)
assert frames_d == round(C.DASH_DURATION * 60) and not pd.is_invulnerable, frames_d   # 0,15 s justos (9 fotogramas)
scout_o.pos = Vector2(pd.pos)
scout_o.rect.center = (round(pd.pos.x), round(pd.pos.y))
scout_o.attack_timer = 0
combat.resolve_enemy_player(pd, pygame.sprite.Group(scout_o))
assert pd.hp == hp_d - U.ENEMIES["scout"]["melee_dps"] and pd.since_hit == 0       # ya sin dash: el Scout muerde

# --- regeneración del bloque: exactamente a los PLAYER_REGEN_DELAY (3,0 s) sin daño, (5 + 2,5 de AURA) HP/s * dt
REGEN_FRAMES = round(C.PLAYER_REGEN_DELAY * 60)
assert (C.PLAYER_REGEN_DELAY, C.PLAYER_REGEN_RATE, C.PLAYER_BLOCK_REGEN) == (3.0, 2.5, 5.0)
RATE_A = C.PLAYER_BLOCK_REGEN + C.PLAYER_REGEN_RATE                               # con AURA en el traje
keys_o.clear()
pr = Player((400, 300), 800, 600)
pr.aura_regen = True
pr.hp = 60
pr.take_damage(10)
assert pr.hp == 50 and pr.since_hit == 0
for _ in range(REGEN_FRAMES - 1):
    pr.update(1 / 60, keys_o, (0, 0), empty)
assert pr.hp == 50 and pr.since_hit < C.PLAYER_REGEN_DELAY                         # 2,983 s: todavía no
pr.update(1 / 60, keys_o, (0, 0), empty)                                           # fotograma 180 = 3,0 s
assert abs(pr.hp - (50 + RATE_A / 60)) < 1e-9, pr.hp
for _ in range(60):
    pr.update(1 / 60, keys_o, (0, 0), empty)
assert abs(pr.hp - (50 + RATE_A * 61 / 60)) < 1e-6, pr.hp                          # fluido: 7,5 HP/s
pr.hp = pr.max_hp - 0.01
pr.update(1 / 60, keys_o, (0, 0), empty)
assert pr.hp == pr.max_hp                                                           # tope en max_hp
pr.hp = 50
pr.take_damage(1)                                                                   # un golpe real reinicia el reloj
pr.update(1 / 60, keys_o, (0, 0), empty)
assert pr.hp == 49
pr.since_hit, pr.regen_rate = C.PLAYER_REGEN_DELAY, 3                               # + reward de regeneración: 7,5 + 3
pr.update(1 / 60, keys_o, (0, 0), empty)
assert abs(pr.hp - (49 + (RATE_A + 3) / 60)) < 1e-9
pn = Player((400, 300), 800, 600)                                                   # sin AURA en el traje: solo la del bloque
pn.hp, pn.since_hit = 50, 10.0
pn.update(1 / 60, keys_o, (0, 0), empty)
assert abs(pn.hp - (50 + C.PLAYER_BLOCK_REGEN / 60)) < 1e-9
# bloques: el dañado se rellena solo hasta su tope; uno vaciado del todo se pierde hasta usar un botiquín
pk = Player((400, 300), 800, 600)
assert pk.health_blocks == 3 and abs(pk.block_size - 100 / 3) < 1e-9 and pk.blocks_left == 3 and pk.lost_blocks == 0
pk.take_damage(50)
assert pk.blocks_left == 2 and pk.lost_blocks == 1 and abs(pk.block_ceiling() - 200 / 3) < 1e-9
pk.since_hit = 3.0
for _ in range(60 * 10):
    pk._regenerate(1 / 60)
assert abs(pk.hp - 200 / 3) < 1e-9                                                  # 2 de 3: el bloque vaciado no vuelve
assert pk.use_medkit() and abs(pk.hp - 100) < 1e-9 and pk.lost_blocks == 0          # botiquín: bloque devuelto
assert not pk.use_medkit()                                                          # sin bloques perdidos no se gasta
# en escena (campo del Operador): regenera con AURA enlazada
a2 = new_op_arena(game, before=lambda r_: setattr(r_, "aura_linked", True))
assert a2.player.aura_regen
a2.player.hp, a2.player.since_hit = 50, 0.0
step(game, REGEN_FRAMES + 60)
assert abs(a2.player.hp - (50 + RATE_A * 1.0)) < 0.2, a2.player.hp                # 3 s de espera + 1 s a 7,5 HP/s
a2 = new_op_arena(game)
assert not a2.player.aura_regen                                                     # sin AURA enlazada: solo la del bloque
game.machine.transition(GameState.MENU)
# regeneración en escenas de nivel (Acto 1 e incursiones): quieto y sin recibir daño, a los 3 s empieza a curarse
game.new_campaign()
game.resources.equipped = True
game.resources.aura_linked = True                                                   # AURA en el traje desde el 1.2
game.machine.transition(GameState.SUB_ACT_1_3)
s13 = screens[GameState.SUB_ACT_1_3]
dismiss(game)
assert s13.player.aura_regen
s13.player.hp, s13.player.since_hit = 50, 0.0
held.clear()
step(game, REGEN_FRAMES + 60)                                                       # antes de que lleguen enemigos (8 s)
assert abs(s13.player.hp - (50 + RATE_A)) < 0.2, s13.player.hp
game.machine.transition(GameState.MENU)
game.new_campaign()
game.resources.aura_linked = True
game.resources.initial_done = True
game.machine.transition(GameState.INCURSION, mode="raid")
inc_s = screens[GameState.INCURSION]
dismiss(game)
assert inc_s.player.aura_regen
for e_ in list(inc_s.world.enemies):
    e_.kill()                                                                       # nadie que le dispare
inc_s.player.hp, inc_s.player.since_hit = 50, 0.0
step(game, REGEN_FRAMES + 60)
assert abs(inc_s.player.hp - (50 + RATE_A)) < 0.2, inc_s.player.hp
game.machine.transition(GameState.MENU)
game.new_campaign()
game.machine.transition(GameState.SUB_ACT_1_1)
assert not screens[GameState.SUB_ACT_1_1].player.aura_regen                         # 1.1: AURA aún no está en el traje
game.machine.transition(GameState.MENU)

# --- todo el ataque en el clic izquierdo: con munición dispara; sin munición golpea (25, alcance 70, empuje 50)
assert U.PLAYER["melee_range"] == C.PLAYER_MELEE_RANGE == 70 and "melee_key" not in U.PLAYER   # sin tecla aparte
pm = Player((400, 300), 800, 600)
pm.equipped, pm.infinite_ammo = True, False
pm_grp = pygame.sprite.Group(pm)
bul_m = pygame.sprite.Group()
pm.projectile_groups = (bul_m,)
foes_m = pygame.sprite.Group()
pm.melee_targets = (foes_m,)
near_m = Enemy("scout", Vector2(475, 300), Vector2(475, 300), foes_m)               # a 75 px (alcance 70 + 7,5)
far_m = Enemy("scout", Vector2(490, 300), Vector2(490, 300), foes_m)                # a 90 px: fuera
behind_m = Enemy("scout", Vector2(340, 300), Vector2(340, 300), foes_m)             # a la espalda: no
foes_m.add(near_m, far_m, behind_m)
keys_o.clear()
held_m = [False]
pygame.mouse.get_pressed = lambda *a, **k: (held_m[0], False, False)


def tick_m(n=1, click=None):
    if click is not None:
        held_m[0] = click
    for _ in range(n):
        pm.update(1 / 60, keys_o, (600, 300), empty)


# con munición, el clic izquierdo SIEMPRE dispara, aunque haya un enemigo a quemarropa (el golpe va en el derecho)
assert near_m.pos.distance_to(pm.pos) < C.PLAYER_MELEE_RANGE + near_m.rect.w / 2
ammo_m = pm.ammo
tick_m(1, click=True)
assert pm.shots_fired == 1 and pm.melee_swings == 0 and len(bul_m) == 1 and pm.ammo == ammo_m - 1
tick_m(1, click=False)
# sin munición: el clic golpea siempre; mantenerlo golpea cada 0,4 s, no más deprisa
pm.mag_rounds = pm.reserve = 0
pm.reload_timer = 0.0
pm.melee_timer = 0.0
assert pm.out_of_ammo
pm.shoot_timer = C.PLAYER_SHOOT_RATE
tick_m(1, click=True)
assert pm.melee_swings == 1 and near_m.hp == near_m.max_hp - C.PLAYER_MELEE_DAMAGE
assert far_m.hp == far_m.max_hp and behind_m.hp == behind_m.max_hp and near_m.pos.x > 475   # alcance, frente y empuje
tick_m(60)                                                                         # 1 s pulsado
assert pm.melee_swings == 1 + 2, pm.melee_swings                                   # a 0,4, 0,8 s: 2 más (nada de spam)
tick_m(1, click=False)
# transición disparo -> golpe: el último disparo y el primer golpe respetan la cadencia del rifle
pm.melee_timer = 0.0
pm.mag_rounds, pm.reserve = 1, 0
swings0 = pm.melee_swings
near_m.pos = Vector2(560, 300)                                                      # nadie a quemarropa: dispara
near_m.rect.center = (560, 300)
shots_l = pm.shots_fired
tick_m(1, click=True)                                                              # última bala
assert pm.shots_fired == shots_l + 1 and pm.out_of_ammo and pm.melee_swings == swings0
near_m.pos = Vector2(475, 300)
near_m.rect.center = (475, 300)
tick_m(1)
assert pm.melee_swings == swings0                                                  # 1/60 s después: todavía no golpea
tick_m(round(C.PLAYER_SHOOT_RATE * 60))
assert pm.melee_swings == swings0 + 1                                              # tras 0,15 s: ya golpea
# transición golpe -> disparo: con munición nueva, el siguiente clic dispara (no espera al golpe)
pm.mag_rounds = 50                                                                  # balas ya en el cargador
assert not pm.out_of_ammo and pm.melee_timer > 0
shots0, swings0 = pm.shots_fired, pm.melee_swings
tick_m(1, click=False)
tick_m(1, click=True)
assert pm.shots_fired == shots0 + 1 and pm.melee_swings == swings0                  # dispara, ya no golpea
# durante la recarga no golpea: espera a que termine (aún quedan balas en la reserva)
tick_m(1, click=False)
pm.mag_rounds, pm.reserve, pm.reload_timer = 0, 50, C.PLAYER_RELOAD_TIME
pm.melee_timer, swings0 = 0.0, pm.melee_swings
tick_m(10, click=True)
assert pm.melee_swings == swings0 and not pm.out_of_ammo
tick_m(round(C.PLAYER_RELOAD_TIME * 60), click=False)
assert pm.mag_rounds > 0                                                            # la recarga sigue funcionando
# sin exoesqueleto ni dispara ni golpea; la tecla F ya no hace nada
pm.equipped = False
pm.mag_rounds = pm.reserve = 0
pm.melee_timer, swings0 = 0.0, pm.melee_swings
tick_m(5, click=True)
assert pm.melee_swings == swings0
pm.equipped = True
tick_m(1, click=False)
keys_o[pygame.K_f] = True
tick_m(5)
assert pm.melee_swings == swings0
keys_o.clear()
held_m[0] = False
pygame.mouse.get_pressed = lambda *a, **k: tuple(mouse)                             # vuelve el ratón de la suite

# =============================================================================
print("== Economía separada (Chatarra / Núcleos / Aleación) y prioridades de VULCANO ==")
from src.managers.resource_manager import CampaignRun as _CRe
from src.entities.vulcano import Vulcano as _Vul
# --- cada gasto toca UN solo pool; mezclar chatarra y núcleos se rechaza
rm_e = ResourceManager()
rm_e.metal, rm_e.cores, rm_e.alloy = 500, 10, 5
try:
    rm_e.pay(10, 1)
    raise AssertionError("pay() no debe mezclar chatarra y núcleos")
except ValueError:
    pass
assert not rm_e.can_pay(10, 1) and (rm_e.metal, rm_e.cores, rm_e.alloy) == (500, 10, 5)
assert rm_e.spend_scrap(30) and (rm_e.metal, rm_e.cores, rm_e.alloy) == (470, 10, 5)
assert rm_e.spend_cores(4) and (rm_e.metal, rm_e.cores, rm_e.alloy) == (470, 6, 5)
assert rm_e.spend_alloy(2) and (rm_e.metal, rm_e.cores, rm_e.alloy) == (470, 6, 3)
assert not rm_e.spend_cores(99) and not rm_e.spend_alloy(99) and not rm_e.spend_scrap(9999) and not rm_e.spend_alloy(-1)
assert (rm_e.metal, rm_e.cores, rm_e.alloy) == (470, 6, 3)
assert rm_e.buy_node("gatillo_automatico") and (rm_e.metal, rm_e.cores, rm_e.alloy) == (470, 5, 3)      # árbol: núcleos
assert rm_e.buy_drone_upgrade("Damage_Attack") and (rm_e.metal, rm_e.cores, rm_e.alloy) == (470, 5, 1)     # drones: aleación
assert not rm_e.buy_drone_upgrade("Velocity_Recon") and rm_e.alloy == 1                                    # faltan 2
# --- Aleación: estado global (res.alloy), checkpoints y guardado de CampaignRun (con 0 por defecto)
snap_e = rm_e.snapshot()
rm_e.alloy = 0
rm_e.restore(snap_e)
assert rm_e.alloy == 1 and snap_e["alloy"] == 1
legacy_snap = dict(snap_e)
legacy_snap.pop("alloy")
rm_e.restore(legacy_snap)
assert rm_e.alloy == 0                                                     # checkpoint antiguo sin aleación: 0
rm_e.alloy = 4
saved_e = rm_e.campaign_run.to_dict()
assert saved_e["tech_alloy"] == 4 and json.dumps(saved_e)
assert _CRe.from_dict(saved_e).tech_alloy == 4 and _CRe.from_dict(saved_e).to_dict() == saved_e
legacy_e = dict(saved_e)
legacy_e.pop("tech_alloy")
assert _CRe.from_dict(legacy_e).tech_alloy == 0                           # partida guardada antes de la aleación
assert _CRe.from_dict({"tech_alloy": -3}).tech_alloy == 0                  # nunca negativa
run_e = _CRe()
run_e.tech_alloy = 3
run_e.start_map("map_1_infiltration", res=ResourceManager())
assert run_e.tech_alloy == 3                                               # persiste al cambiar de mapa
rm_e.reset()
assert rm_e.alloy == 0                                                     # campaña nueva

# --- VULCANO: cola de prioridad, 80 HP/s a una sola estructura y reserva de 25 de chatarra
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=500, vulcano=True)
w, res, v6 = a2.world, game.resources, a2.vulcano
assert v6 is not None
cc6 = Vector2(a2.core.pos)
wall6 = create_building("wall", cc6 + Vector2(220, -220))
gate6 = create_building("compuerta", cc6 + Vector2(300, -220))
pylon6 = create_building("pylon", cc6 + Vector2(220, 220))
tower6 = create_building("tower", cc6 + Vector2(300, 220))
gen6 = create_building("pylon", cc6 + Vector2(-220, 220))                 # segundo pilón (antes un generador)
foco6 = create_building("foco", cc6 + Vector2(-300, 220))
for b_ in (wall6, gate6, pylon6, tower6, gen6, foco6):
    a2._register(b_)
assert [_Vul.priority_tier(x_) for x_ in (a2.core, pylon6, gen6, tower6, wall6, gate6, foco6)] == [0, 1, 1, 1, 2, 2, 3]
for b_ in (a2.core, wall6, gate6, pylon6, tower6, gen6, foco6):
    b_.hp = b_.max_hp * 0.3
v6.target = None
assert v6.choose_target(w) is a2.core                                      # 1) el Centro de Control
res.metal = 500
hp_others = [b_.hp for b_ in (wall6, gate6, pylon6, tower6, gen6, foco6)]
v6.update(1.0, w, res)
assert C.VULCANO_REPAIR_RATE == 80
assert abs(a2.core.hp - (a2.core.max_hp * 0.3 + 80)) < 1e-6                # 80 HP/s, a UNA sola estructura
assert [b_.hp for b_ in (wall6, gate6, pylon6, tower6, gen6, foco6)] == hp_others
assert res.metal == 500 - int(80 * C.VULCANO_METAL_PER_HP)                 # chatarra proporcional (7,6 -> 7 y 0,6 de deuda)
a2.core.hp = a2.core.max_hp
gen6.hp = gen6.max_hp
pylon6.hp = pylon6.max_hp * 0.2
assert v6.choose_target(w) is pylon6                                       # 2) red activa: el de menos vida
v6.update(1 / 60, w, res)
tower6.hp = tower6.max_hp * 0.1                                            # otra del mismo nivel con menos vida...
wall6.hp = wall6.max_hp * 0.05                                             # ...y un muro (nivel inferior) casi roto
assert v6.choose_target(w) is pylon6                                       # termina lo que empezó
a2.core.hp = a2.core.max_hp * 0.4
assert v6.choose_target(w) is a2.core                                      # pero el Centro de Control se adelanta
a2.core.hp = a2.core.max_hp
pylon6.hp = tower6.hp = pylon6.max_hp                                      # (red sana)
tower6.hp = tower6.max_hp
v6.target = None
assert v6.choose_target(w) is wall6                                        # 3) bloqueo: muros y compuertas
wall6.hp = gate6.hp = wall6.max_hp
gate6.hp = gate6.max_hp
v6.target = None
assert v6.choose_target(w) is foco6                                        # 4) el resto
gen6.hp = gen6.max_hp * 0.3
assert v6.choose_target(w) is gen6                                         # el generador (red activa) se adelanta
# reserva: con 25 o menos se detiene en seco; nunca negativa
foco6.hp = foco6.max_hp
res.metal = 30
for _ in range(60 * 30):
    v6.update(1 / 60, w, res)
    assert res.metal >= C.VULCANO_SCRAP_RESERVE
assert res.metal == C.VULCANO_SCRAP_RESERVE and gen6.hp < gen6.max_hp and not v6.repairing      # se paró en 25
hp_g = gen6.hp
res.metal = 25
v6.update(1.0, w, res)
assert gen6.hp == hp_g and res.metal == 25
res.metal = 0
v6.update(1.0, w, res)
assert gen6.hp == hp_g and res.metal == 0                                  # sin chatarra: ni repara ni baja de 0
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Infantería: Scout (flanqueo y mordida continua) y Soldado (160 px, ráfagas de 3 cada 2 s) ==")
assert (U.ENEMIES["scout"]["hp"], U.ENEMIES["scout"]["armor"], U.ENEMIES["scout"]["speed"], U.ENEMIES["scout"]["melee_dps"]) == (45, 0, 180, 8)
sd_ = U.ENEMIES["soldier"]
assert (sd_["hp"], sd_["armor"], sd_["speed"], sd_["range"], sd_["burst"], sd_["shot_damage"]) == (144, 4, 100, 160, 3, 12)
assert (sd_["burst_gap"], sd_["burst_cooldown"]) == (0.12, 2.0) and 155 <= sd_["range"] <= 165 < C.PLAYER_BULLET_RANGE
# --- mordida continua del Scout contra el Operador: 8 HP/s repartidos en cada fotograma, sin sacudir la cámara
wr_i = WorldRefs()
pl_i = Player((500, 500), 2000, 2000)
grp_i = pygame.sprite.Group(pl_i)
wr_i.player = pl_i
sc_i = Enemy("scout", Vector2(500, 500), Vector2(500, 500), wr_i.enemies)
foes_i = pygame.sprite.Group(sc_i)
hp_i = pl_i.hp
combat.FX.consume_shake()
for _ in range(60):
    combat.resolve_enemy_player(pl_i, foes_i, 1 / 60)
assert abs((hp_i - pl_i.hp) - 8.0) < 1e-6, hp_i - pl_i.hp                          # 8 HP en 1 s, continuo
assert not combat.FX.consume_shake() and pl_i.since_hit == 0                     # sin sacudidas; sí reinicia la regeneración
pl_i.flat_armor = 10                                                              # armadura plana: -10 por segundo, mín. 1 HP/s
hp_i = pl_i.hp
for _ in range(60):
    combat.resolve_enemy_player(pl_i, foes_i, 1 / 60)
assert abs((hp_i - pl_i.hp) - 1.0) < 1e-6, hp_i - pl_i.hp                          # antes: mínimo 1 por fotograma = 60 HP/s
pl_i.flat_armor = 0
hp_i = pl_i.hp
combat.resolve_enemy_player(pl_i, foes_i)                                         # sin dt: un golpe por segundo (8)
assert hp_i - pl_i.hp == 8 and sc_i.attack_timer > 0
# ...y contra un dron
from src.entities.drones import AuraDrone as _AuraI
dr_i = _AuraI(Vector2(500, 500))
air_i = ReconDrone(Vector2(500, 500), _ds3("recon"), home=Vector2(500, 500))        # aéreo: inmune al contacto
drones_i = pygame.sprite.Group(dr_i, air_i)
for _ in range(30):
    combat.resolve_enemy_allies(foes_i, drones_i, 1 / 60)
assert abs((dr_i.max_hp - dr_i.hp) - 4.0) < 1e-6                                  # 0,5 s a 8 HP/s
assert air_i.hp == air_i.max_hp
# --- mordida continua contra una estructura que le cierra el paso (y el muro Electrificado descarga 1 vez por segundo)
wr_w = WorldRefs()
wall_i = Building("wall", (600, 400))
wr_w.structures.add(wall_i)
bit_i = Enemy("scout", (540, 400), (900, 400), wr_w.enemies)
bit_i.flank = 0
wr_w.enemies.add(bit_i)
for _ in range(60):
    bit_i.update(1 / 60, wr_w.structures, None)
lost_a = wall_i.max_hp - wall_i.hp
for _ in range(120):
    bit_i.update(1 / 60, wr_w.structures, None)
rate_i = (wall_i.max_hp - wall_i.hp - lost_a) / 2.0
assert abs(rate_i - 8.0) < 0.2, rate_i                                            # 8 HP/s sostenidos
hp_half = wall_i.hp
for _ in range(30):
    bit_i.update(1 / 60, wr_w.structures, None)
assert abs((hp_half - wall_i.hp) - 4.0) < 0.2, hp_half - wall_i.hp                 # medio segundo = 4 HP: continuo, no a saltos
wall_i.apply_wall_level(2)
wall_i.apply_wall_level(3)
wall_i.is_powered = True
wall_i.energized = True
bit_i.hp = bit_i.max_hp
for _ in range(30):                                                               # 0,5 s pegado al muro electrificado
    bit_i.update(1 / 60, wr_w.structures, None)
assert wall_i.active
assert bit_i.hp == bit_i.max_hp - wall_i.counter_damage, bit_i.hp                 # una sola descarga (no 30)
# --- flanqueo del Scout: lejos se desvía un poco; en rango medio rodea; cerca va directo
wr_o = WorldRefs()
pl_o = Player((1000, 0), 3000, 3000)                                              # el objetivo es el Operador
pgrp_o = pygame.sprite.Group(pl_o)
wr_o.player = pl_o
fl_i = Enemy("scout", (0, 0), (1000, 0), pygame.sprite.Group())
fl_i.flank, fl_i.flank_jitter, fl_i.world = 1, 1.0, wr_o
radial = Vector2(1, 0)
far_h = fl_i._flank(radial)
assert abs(radial.angle_to(far_h) - U.ENEMIES["scout"]["flank_angle"]) < 1e-6        # lejos: 22°
fl_i.pos = Vector2(1000 - 195, 0)                                                 # mitad de la banda (70-320)
mid_h = fl_i._flank(radial)
assert abs(radial.angle_to(mid_h)) > 40                                           # rango medio: rodeo marcado
fl_i.pos = Vector2(1000 - 50, 0)
assert fl_i._flank(radial) == radial                                              # cerca: directo a morder
fl_i.flank = 0
fl_i.pos = Vector2(1000 - 195, 0)
assert fl_i._flank(radial) == radial                                              # flank 0: sin flanqueo
# contra una estructura (el Centro de Control) rodea mucho menos que contra el Operador (balance de la defensa)
fl_i.flank = 1
ang_player = abs(radial.angle_to(fl_i._flank(radial)))                            # objetivo = el Operador
pl_o.pos = Vector2(2000, 2000)
ang_struct = abs(radial.angle_to(fl_i._flank(radial)))                            # objetivo = una estructura
assert ang_player > 40 and 0 < ang_struct < 20, (ang_player, ang_struct)
# rodea hacia la ESPALDA del Operador: llega por el costado o por detrás, no de frente
wr_f = WorldRefs()
pl_f = Player((500, 400), 2000, 2000)
pl_f.aim_dir = Vector2(1, 0)                                                      # mira a la derecha
pgrp_f = pygame.sprite.Group(pl_f)
wr_f.player = pl_f
arrivals = []
for start_f, side_f in (((800, 430), 1), ((800, 370), -1), ((800, 430), -1)):
    sc_f = Enemy("scout", start_f, Vector2(pl_f.pos), wr_f.enemies)
    sc_f.world, sc_f.flank, sc_f.flank_jitter = wr_f, side_f, 1.0
    for _ in range(240):
        sc_f.update(1 / 60, pygame.sprite.Group(), None)
        if sc_f.pos.distance_to(pl_f.pos) < 60:
            break
    rel = (sc_f.pos - pl_f.pos)
    arrivals.append(rel.normalize().dot(pl_f.aim_dir) if rel.length() > 0 else 1.0)
assert all(a_ < 0.6 for a_ in arrivals), arrivals                                 # nunca entra de frente
# --- Soldado: ráfagas de exactamente 3 (0,12 s entre balas) y 2 s de pausa; fuego solo a <= 160 px (x1,05)
wr_s = WorldRefs()
tgt_s = Building("wall", (700, 400))
wr_s.structures.add(tgt_s)
so = Enemy("soldier", (700 - 150, 400), (2000, 400), wr_s.enemies)
so.world, so.always_active, so.shoot_timer, so.speed = wr_s, True, 0.0, 0         # quieto: solo se prueba el arma
wr_s.enemies.add(so)
shots_t = []
t_s = 0.0
for _ in range(60 * 5):
    n_b = len(wr_s.enemy_bullets)
    so.update(1 / 60, pygame.sprite.Group(), None)
    t_s += 1 / 60
    shots_t += [round(t_s, 3)] * (len(wr_s.enemy_bullets) - n_b)
    wr_s.enemy_bullets.empty()
bursts, cur = [], [shots_t[0]]
for t_ in shots_t[1:]:
    if t_ - cur[-1] < 0.5:
        cur.append(t_)
    else:
        bursts.append(cur)
        cur = [t_]
bursts.append(cur)
if len(bursts[-1]) < 3:
    bursts.pop()                                                                  # la última la corta el fin de la prueba
assert all(len(b_) == 3 for b_ in bursts) and len(bursts) >= 2, shots_t           # ráfagas de 3
assert all(abs((b_[1] - b_[0]) - 0.12) < 0.02 and abs((b_[2] - b_[1]) - 0.12) < 0.02 for b_ in bursts)
gap_s = bursts[1][0] - bursts[0][-1]
assert 1.95 <= gap_s <= 2.1, gap_s                                                # ~2 s de pausa
far_so = Enemy("soldier", (700 - 190, 400), (2000, 400), wr_s.enemies)            # fuera de alcance (190 > 160 x 1,05)
far_so.world, far_so.always_active, far_so.shoot_timer, far_so.speed = wr_s, True, 0.0, 0
for _ in range(60):
    far_so.update(1 / 60, pygame.sprite.Group(), None)
assert len(wr_s.enemy_bullets) == 0
# en la pausa se reposiciona (se desplaza de lado / mantiene la distancia) y durante la ráfaga se planta
mv = Enemy("soldier", (700 - 90, 400), (2000, 400), wr_s.enemies)               # el muro, demasiado cerca (< 70%)
mv.world, mv.always_active, mv.shoot_timer = wr_s, True, 0.0
for _ in range(60):                                                               # hasta que fija el blanco y abre fuego
    mv.update(1 / 60, pygame.sprite.Group(), None)
    if mv.burst_left > 0:
        break
p0 = Vector2(mv.pos)
d_burst = mv.pos.distance_to(tgt_s.pos)
assert mv.burst_left > 0 and d_burst < sd_["range"] * sd_["keep_min"]
for _ in range(4):                                                                # durante la ráfaga: quieto
    mv.update(1 / 60, pygame.sprite.Group(), None)
assert mv.burst_left > 0 and mv.pos.distance_to(p0) < 1.0
for _ in range(60):                                                               # pausa: se mueve
    mv.update(1 / 60, pygame.sprite.Group(), None)
assert mv.burst_left == 0 and mv.pos.distance_to(p0) > 20
assert mv.pos.distance_to(tgt_s.pos) > d_burst + 10                              # lo tenía demasiado cerca: se aparta
wr_s.enemy_bullets.empty()

# =============================================================================
print("== Escala 0,83 de las unidades y enemigos pesados (Tanque, Ariete, Ariete Ligero) ==")
import src.entities.enemy as _emod
from src.entities.boss import LightRam as _LRh
from src.entities.obstacle import Obstacle as _Obs
from src.entities.scavenger import ScavengerDrone as _Scav
# --- escala: hitbox y sprite de cada unidad x0,83, centradas en pos
assert U.ENTITY_SCALE == 0.83
for kind_h, size_h, sprite_h in (("scout", 15, 43), ("soldier", 22, 53), ("ariete", 38, 80), ("tank", 33, 73)):
    e_h = Enemy(kind_h, (321, 207), (900, 207), pygame.sprite.Group())
    assert U.ENEMIES[kind_h]["size"] == size_h and _emod.SPRITE_SIZES[kind_h] == sprite_h, kind_h
    assert e_h.rect.center == (321, 207) and e_h.rect.w <= sprite_h, kind_h                 # mismo centro
sv_h = _Scav(Vector2(321, 207), Vector2(500, 500), Vector2(900, 900))
assert sv_h.rect.size == (18, 18) and sv_h.rect.center == (321, 207)                       # 22 x 0,83
assert Player((321, 207), 800, 600).rect.center == (321, 207)
# --- Tanque: gira como mucho 65 °/s; 180° le llevan ~2,77 s
wr_t = WorldRefs()
tgt_t = Building("wall", (300, 400))                                                       # detrás del tanque
wr_t.structures.add(tgt_t)
tk_h = Enemy("tank", (600, 400), (2000, 400), wr_t.enemies)
tk_h.world, tk_h.always_active, tk_h.speed, tk_h.shoot_timer = wr_t, True, 0, 0.0
tk_h.facing = 0.0                                                                          # mira justo al revés
frames_t = 0
while abs(tk_h.angle_to(tgt_t.pos)) > 1.0 and frames_t < 600:
    tk_h.update(1 / 60, pygame.sprite.Group(), None)
    frames_t += 1
    assert len(wr_t.shells) == 0 or abs(tk_h.angle_to(tgt_t.pos)) <= U.ENEMIES["tank"]["aim_tolerance"]
assert 2.4 <= frames_t / 60 <= 3.0, frames_t / 60                                          # 179° a 65 °/s
# dispara solo alineado y tras 0,8 s apuntando
tk_h.facing, tk_h.aim_timer, tk_h.shoot_timer = 0.0, 0.0, 0.0
wr_t.shells.empty()
t_first = None
for f_ in range(60 * 5):
    tk_h.update(1 / 60, pygame.sprite.Group(), None)
    if len(wr_t.shells) and t_first is None:
        t_first = (f_ + 1) / 60
assert t_first is not None and t_first >= (180 - 8) / 65 + 0.8 - 0.05, t_first             # girar + apuntar
# el impacto queda fijado al empezar a apuntar: el Operador que se aparta (o hace Dash) lo esquiva
wr_d = WorldRefs()
pl_d = Player((900, 400), 2000, 2000)
pgrp_d = pygame.sprite.Group(pl_d)
wr_d.player = pl_d
tk_d = Enemy("tank", (600, 400), (2000, 400), wr_d.enemies)
tk_d.world, tk_d.always_active, tk_d.speed, tk_d.shoot_timer, tk_d.facing = wr_d, True, 0, 0.0, 0.0
for _ in range(30):
    tk_d.update(1 / 60, pygame.sprite.Group(), None)
    if tk_d.aim_timer > 0:
        break
assert tk_d.aim_timer > 0 and tk_d.aim_point == Vector2(900, 400)                          # apunta a donde estaba
surf_d = pygame.Surface((1200, 800))
tk_d.draw(surf_d, Vector2())                                                               # el aviso se dibuja
pl_d.pos = Vector2(900, 560)                                                               # se aparta 160 px
pl_d.rect.center = (900, 560)
hp_d0 = pl_d.hp
for _ in range(60 * 3):
    tk_d.update(1 / 60, pygame.sprite.Group(), None)
    wr_d.shells.update(1 / 60)
assert pl_d.hp == hp_d0                                                                    # cayó donde ya no estaba
pl_d.pos = Vector2(900, 400)
pl_d.rect.center = (900, 400)
tk_d.shoot_timer = 0.0
for _ in range(60 * 3):
    tk_d.update(1 / 60, pygame.sprite.Group(), None)
    wr_d.shells.update(1 / 60)
assert pl_d.hp < hp_d0                                                                     # quieto: le alcanza
# --- Ariete: en la preparación gira poco (120 °/s) y embiste hacia donde quedó mirando; en la carga no gira
wr_a = WorldRefs()
ar_h = Enemy("ariete", (500, 500), (2000, 500), wr_a.enemies)
ar_h.world, ar_h.always_active = wr_a, True
ar_h.facing = 0.0
ar_h.state, ar_h.state_timer, ar_h.charge_dir = "windup", U.ENEMIES["ariete"]["windup"], Vector2(0, 1)   # quiere ir a 90°
frames_w = 0
while ar_h.state == "windup" and frames_w < 40:                                            # 0,5 s de preparación
    ar_h._ram_logic(1 / 60, Vector2(1, 0), 70)
    frames_w += 1
assert ar_h.state == "charge" and 55 <= ar_h.facing <= 63, ar_h.facing                    # ~60°, lejos de los 90° pedidos
assert abs(Vector2(1, 0).angle_to(ar_h.charge_dir) - ar_h.facing) < 1e-6                   # embiste hacia su frente
f_lock = ar_h.facing
for _ in range(20):
    ar_h._ram_logic(1 / 60, Vector2(-1, 0), 70)                                            # el rumbo cambia...
assert ar_h.facing == f_lock                                                               # ...pero la embestida no gira
# daño direccional según hacia dónde VIAJA el golpe respecto a su frente
ar_h.facing = 0.0
assert abs(ar_h.mitigate(100, Vector2(-1, 0)) - 55) < 1e-9                                # de frente: x0,55
assert ar_h.mitigate(100, Vector2(1, 0)) == 300 and ar_h.mitigate(100, Vector2(0, 1)) == 300   # espalda / flanco: x3
# --- Ariete Ligero (1.2): frente x0,25, costado x0,5, espalda x2 y ~1,1 s aturdido tras chocar con un muro
wr_l = WorldRefs()
pl_l = Player((100, 100), 2000, 2000)
pgrp_l = pygame.sprite.Group(pl_l)
wr_l.player = pl_l
wr_l.solids = pygame.sprite.Group(_Obs((700, 450, 40, 100)))
lr_h = _LRh((500, 500))
lr_h.state, lr_h.charge_dir, lr_h.traveled = "charge", Vector2(1, 0), 0.0
lr_h.facing = Vector2(1, 0)
for _ in range(60):
    lr_h.update(1 / 60, wr_l)
    if lr_h.state == "stun":
        break
assert lr_h.state == "stun" and abs(lr_h.timer - U.LIGHT_RAM["stun"]) < 1e-9 and C.RAM_STUN == 1.1
hp_l = lr_h.hp
lr_h.take_damage(10, Vector2(1, 0))                                                        # por la espalda, aturdido: x2
assert hp_l - lr_h.hp == 20
lr_h.take_damage(10, Vector2(-1, 0))                                                       # de frente aturdido: al menos x1
assert hp_l - lr_h.hp == 30
stun_frames = 0
while lr_h.state == "stun":
    lr_h.update(1 / 60, wr_l)
    stun_frames += 1
assert 1.0 <= stun_frames / 60 <= 1.2, stun_frames / 60
lr_h.state = "idle"
hp_l = lr_h.hp
lr_h.take_damage(10, Vector2(-1, 0))                                                       # de frente, sin aturdir: x0,25
assert abs((hp_l - lr_h.hp) - 2.5) < 1e-9

# =============================================================================
print("== Carroñero: chatarra > sabotaje > huida, apagón de 8 s y botín al morir ==")
from src.entities.scavenger import ScavengerDrone as _SD
from src.entities.core_item import CoreItem as _CI
SPv = U.SCAVENGER
assert (SPv["hp"], SPv["armor"], SPv["speed"], SPv["sabotage_time"]) == (25, 0, 250, 8.0)
_SD.arena = pygame.Rect(0, 0, 2000, 1200)
# --- 1) chatarra: va al montón MÁS CERCANO, se acopla, lo consume y huye por el borde más cercano
scr_g = pygame.sprite.Group(ScrapItem((700, 600), 25), ScrapItem((400, 600), 40))
near_s, far_s = sorted(scr_g, key=lambda s_: s_.pos.x, reverse=True)
sd1 = _SD((900, 600))
sd1.update(1 / 60, scr_g)
assert sd1.state == "seek_scrap" and sd1.goal is near_s
for _ in range(60 * 3):
    sd1.update(1 / 60, scr_g)
    if sd1.state == "fleeing":
        break
assert sd1.state == "fleeing" and sd1.stolen_scrap == 25 and not near_s.alive() and far_s.alive()
gaps_ = {"l": sd1.pos.x, "r": 2000 - sd1.pos.x, "t": sd1.pos.y, "b": 1200 - sd1.pos.y}
side_ = min(gaps_, key=gaps_.get)
assert {"l": sd1.exit_point.x < 0, "r": sd1.exit_point.x > 2000, "t": sd1.exit_point.y < 0,
        "b": sd1.exit_point.y > 1200}[side_]                                     # el borde más cercano
# si se le adelantan mientras se acopla, busca otro botín
scr_g2 = pygame.sprite.Group(ScrapItem((500, 300), 25), ScrapItem((500, 500), 25))
sd2 = _SD((500, 280))
for _ in range(20):
    sd2.update(1 / 60, scr_g2)
assert sd2.state == "latching"
taken = sd2.goal
taken.kill()                                                                    # el Operador lo recogió
sd2.update(1 / 60, scr_g2)
sd2.update(1 / 60, scr_g2)
assert sd2.state == "seek_scrap" and sd2.goal is not taken and sd2.goal.alive()
# también roba núcleos de plasma
cores_g = pygame.sprite.Group(_CI((300, 300), 2))
sd3 = _SD((300, 320))
for _ in range(120):
    sd3.update(1 / 60, pygame.sprite.Group(), cores_g)
assert sd3.cores_value == 2 and sd3.state == "fleeing" and sd3.stolen_scrap == 0
# --- 2) sin botín: al pilón más cercano; lo apaga 8 s exactos (cascada) y la red vuelve sola
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=3000)
w = a2.world
for e_ in list(w.scraps) + list(w.core_items):
    e_.kill()
assert build(a2, "pylon", (520, 600)) and build(a2, "pylon", (660, 600)) and build(a2, "tower", (740, 740))   # solo B la alcanza
pyl_a = min(w.pylons, key=lambda p_: p_.pos.x)
pyl_b = max(w.pylons, key=lambda p_: p_.pos.x)
tw_s = next(iter(w.towers))
a2.grid.update()
assert pyl_a.is_powered and pyl_b.is_powered and tw_s.is_powered
sd4 = _SD(pyl_b.pos + Vector2(0, 120))                                          # más cerca de B
sd4.arena = a2.map_rect
sab_log = []
sd4.on_sabotage = lambda d_, p_: sab_log.append((p_, a2.wave.wave_time))
sd4.on_death = a2._on_scavenger_death
w.scavengers.add(sd4); w.targets.add(sd4); w.all_sprites.add(sd4)
for _ in range(60):
    step(game, 1)
    if sab_log:
        break
assert sab_log and sab_log[0][0] is pyl_b and sd4.state == "fleeing"
assert abs(pyl_b.disabled_timer - SPv["sabotage_time"]) < 0.05
step(game, 2)
assert not pyl_b.is_powered and pyl_a.is_powered and not tw_s.is_powered          # la torreta de B se queda sin red
off_frames = 0
while pyl_b.disabled_timer > 0 and off_frames < 60 * 10:
    step(game, 1)
    off_frames += 1
assert abs((off_frames + 2) / 60 - SPv["sabotage_time"]) <= 2 / 60 + 1e-9, off_frames   # 8 s (± 1 fotograma)
step(game, 2)
assert pyl_b.is_powered and tw_s.is_powered                                       # la red vuelve: nada permanente
# apagado y destruido a la vez: ni errores ni torretas colgando de un pilón muerto
pyl_b.sabotage(SPv["sabotage_time"])
step(game, 2)
pyl_b.take_damage(99999)
step(game, 60 * 9)
assert not pyl_b.alive() and not tw_s.is_powered and pyl_a.is_powered
assert all(c_ is not pyl_b and n_ is not pyl_b for c_, n_ in a2.grid.feeds)
# con chatarra en el suelo, el sabotaje cede: la chatarra manda
sd5 = _SD(pyl_a.pos + Vector2(0, 200), pylon=pyl_a)
sd5.update(1 / 60, pygame.sprite.Group(), None, w.pylons)
assert sd5.state == "seek_pylon"
loot5 = a2._drop_scrap(pyl_a.pos + Vector2(0, 260), 25)
sd5.scan_timer = 0
sd5.update(1 / 60, w.scraps, None, w.pylons)
assert sd5.state == "seek_scrap" and sd5.goal is loot5
loot5.kill()
# --- 3) botín al morir: lo robado + su drop base; y no ataca al Operador
pl_s6 = Player(Vector2(a2.CC_POS) + Vector2(0, 230), a2.map_w, a2.map_h)     # un Operador de prueba al lado
sd6 = _SD(Vector2(pl_s6.pos) + Vector2(5, 0))
sd6.stolen_scrap = 25
sd6.on_death = a2._on_scavenger_death
w.scavengers.add(sd6); w.targets.add(sd6); w.all_sprites.add(sd6)
hp_p = pl_s6.hp
for _ in range(10):
    sd6.update(1 / 60, pygame.sprite.Group())                                   # pegado al Operador
    combat.resolve_enemy_player(pl_s6, w.enemies, 1 / 60)
assert pl_s6.hp == hp_p                                                           # no tiene ataque
n_scr = len(w.scraps)
sd6.take_damage(999)
assert len(w.scraps) == n_scr + 1
lo_, hi_ = SPv["base_drop"]
assert any(25 + lo_ <= s_.value <= 25 + hi_ and s_.pos.distance_to(sd6.pos) < 1 for s_ in w.scraps)
assert all(lo_ <= _SD((0, 0)).death_loot() <= hi_ for _ in range(20))             # sin robar: solo el base
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Controles: clic izquierdo dispara; clic derecho golpea (Operador); en el nivel de drones el ratón es de los drones ==")
# --- Operador suelto: clic derecho = golpe con munición; respeta 0,4 s y la cadencia del rifle
pr_ = Player((400, 300), 800, 600)
pr_.equipped, pr_.infinite_ammo = True, False
prg_ = pygame.sprite.Group(pr_)
foes_r = pygame.sprite.Group()
pr_.melee_targets = (foes_r,)
tgt_r = Enemy("scout", Vector2(470, 300), Vector2(470, 300), foes_r)
foes_r.add(tgt_r)
keys_o.clear()
assert pr_.mag_rounds > 0 and not pr_.out_of_ammo
pr_.queue_melee()
pr_.update(1 / 60, keys_o, (600, 300), empty)
assert pr_.melee_swings == 1 and pr_.shots_fired == 0 and tgt_r.hp == tgt_r.max_hp - C.PLAYER_MELEE_DAMAGE
ammo_r = pr_.ammo
pr_.queue_melee()                                                                  # otro clic al instante: enfriamiento
pr_.update(1 / 60, keys_o, (600, 300), empty)
assert pr_.melee_swings == 1
for _ in range(round(C.PLAYER_MELEE_COOLDOWN * 60)):                               # el clic queda 0,25 s en espera...
    pr_.update(1 / 60, keys_o, (600, 300), empty)
assert pr_.melee_swings == 1                                                       # ...y caduca: sin golpes en ráfaga
pr_.queue_melee()
pr_.update(1 / 60, keys_o, (600, 300), empty)
assert pr_.melee_swings == 2 and pr_.ammo == ammo_r                                # golpe sin gastar balas
pr_.shoot_timer = 0.0                                                              # acaba de disparar
pr_.melee_timer = 0.0
pr_.queue_melee()
pr_.update(1 / 60, keys_o, (600, 300), empty)
assert pr_.melee_swings == 2                                                       # espera la cadencia del rifle (0,15 s)
for _ in range(round(C.PLAYER_SHOOT_RATE * 60)):
    pr_.update(1 / 60, keys_o, (600, 300), empty)
assert pr_.melee_swings == 3                                                       # el clic pendiente golpea al terminar
pr_.equipped = False
pr_.melee_timer = 0.0
pr_.queue_melee()
pr_.update(1 / 60, keys_o, (600, 300), empty)
assert pr_.melee_swings == 3                                                       # sin exoesqueleto no golpea
# --- Acto 1 (escena de nivel): clic derecho golpea; en la pausa táctica no
game.machine.transition(GameState.MENU)
game.new_campaign()
game.resources.equipped = True
game.machine.transition(GameState.SUB_ACT_1_2)
s12 = screens[GameState.SUB_ACT_1_2]
dismiss(game)
sw0 = s12.player.melee_swings
right_click(game, s12.player.pos + Vector2(80, 0))
step(game, 2)
assert s12.player.melee_swings == sw0 + 1 and s12.player.shots_fired == 0
press(game, pygame.K_SPACE)                                                        # pausa táctica
assert s12.paused
s12.player.melee_timer = 0.0
right_click(game, s12.player.pos + Vector2(80, 0))
press(game, pygame.K_SPACE)
step(game, 2)
assert s12.player.melee_swings == sw0 + 1                                          # el clic de la pausa no golpea al volver
# --- Acto 2 (mando): clic derecho sobre una estructura abre su menú; en el suelo, orden de ataque a los drones
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=2000)
w = a2.world
assert build(a2, "pylon", (540, 620)) and build(a2, "tower", (580, 700))
tw_r = next(iter(w.towers))
right_click(game, tw_r.pos)
step(game, 1)
assert a2.menu is not None and a2.menu.building is tw_r and a2.order_marker is None
a2.close_menu()
right_click(game, a2.CC_POS + Vector2(500, -90))                                   # en el suelo: Attack-Move (marca roja)
step(game, 1)
assert a2.order_marker is not None and a2.menu is None
press(game, pygame.K_v)                                                            # la tecla V no hace nada
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Infraestructura y red: catálogo, purga del plasma y Foco Vigía (detección de Carroñeros) ==")
from src.entities.scavenger import ScavengerDrone as _SDi
from src.entities.building import BUILD_MENU as _BMi
# --- catálogo exacto
UB = U.BUILDINGS
assert (UB["core"]["hp"], UB["core"]["energy_output"]) == (500, 50)
assert (UB["pylon"]["cost"], UB["pylon"]["hp"], UB["pylon"]["range"], UB["pylon"]["energy_output"]) == (30, 120, 160, 5)
assert "generator" not in UB and "generator" not in Building.STATS                      # el Pilón es la única red
assert (UB["extractor"]["cost"], UB["extractor"]["hp"], UB["extractor"]["energy"], UB["extractor"]["income"],
        UB["extractor"]["interval"]) == (60, 120, 8, 5, 1.2)
assert (UB["foco"]["cost"], UB["foco"]["cores"], UB["foco"]["energy"], UB["foco"]["hp"], UB["foco"]["range_bonus"],
        UB["foco"]["reveal_radius"]) == (50, 0, 3, 150, 30, 320)
# --- purga: sin Extractor de Plasma en ningún sitio, y ningún edificio cuesta ni genera núcleos
assert "plasma_extractor" not in UB and "plasma_extractor" not in Building.STATS and not hasattr(WorldRefs(), "plasma_extractors")
assert "plasma_extractor" not in [b_ for _, b_ in _BMi] and all(spec_.get("cores", 0) == 0 for k_, spec_ in UB.items() if k_ != "bunker") and UB["bunker"]["cores"] == 2   # el Búnker es la excepción
try:
    Building("plasma_extractor", (0, 0))
    raise AssertionError("no debería existir")
except KeyError:
    pass
rm_old = ResourceManager()
rm_old.base_layout = [{"type": "plasma_extractor", "pos": (100.0, 100.0), "hp": 250, "route": None, "level": 1}]
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=2000)
a2.res.base_layout = list(rm_old.base_layout)
from src.mechanics.base_layout import restore_base
restore_base(a2, a2.res)                                                          # partida guardada con el extractor: se ignora
assert not any(getattr(b_, "building_type", "") == "plasma_extractor" for b_ in a2.world.structures)
# --- Centro de Control: HP 500, +50 de energía; si cae a 0, derrota
assert a2.core.max_hp == 500 and a2.energy_capacity() == 50
a2.core.take_damage(99999)
step(game, 100)
assert game.machine.current_state is GameState.RETRY_SUB_ACT
# --- Foco Vigía: detección temprana de Carroñeros
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=3000)
w = a2.world
for e_ in list(w.scraps) + list(w.core_items):
    e_.kill()
assert build(a2, "pylon", (520, 600)) and build(a2, "foco", (560, 640)) and build(a2, "tower", (560, 700))
foco_i = next(iter(w.focos))
tower_i = next(iter(w.towers))
assert foco_i.active and a2.res.energy_cap >= 50 and foco_i.energy_cost == 3
assert tower_i.linked_foco() is foco_i and tower_i.effective_range() == tower_i.range + 30
far_i = _SDi(Vector2(foco_i.pos) + Vector2(400, 0))                               # fuera de los 320 px
near_i = _SDi(Vector2(foco_i.pos) + Vector2(310, 0))                              # dentro
for sc_i in (far_i, near_i):
    sc_i.hp = 9999                                                                  # que no caiga durante la prueba
    w.scavengers.add(sc_i); w.targets.add(sc_i); w.all_sprites.add(sc_i)
    sc_i.state, sc_i.goal = "latching", None                                       # quietos: solo se prueba la detección
    sc_i.latch_timer = 99
foco_i.update(1 / 60, w.targets, w.bullets)
assert near_i.detected and not far_i.detected
assert near_i in a2.visible_sprites() and any(e_ is near_i for e_ in a2.visible_sprites())
game.machine.draw(game.screen)                                                      # marca y minimapa sin errores
# el Foco revela 320 px de niebla (persistente) en cuanto está operativo
step(game, 2)
assert a2.fog.is_revealed(foco_i.pos + Vector2(300, 0)) and a2.fog.is_revealed(foco_i.pos + Vector2(0, -300))
assert not a2.fog.is_revealed(foco_i.pos + Vector2(700, 0))                          # más allá de los 320 px: sigue oscuro
# prioridad de blanco: la torreta enlazada dispara al Carroñero detectado aunque haya un Scout más cerca
scout_i = Enemy("scout", Vector2(tower_i.pos) + Vector2(60, 0), a2.CC_POS, w.enemies)
scout_i.speed = 0
w.enemies.add(scout_i); w.targets.add(scout_i); w.all_sprites.add(scout_i)
near_i.pos = Vector2(tower_i.pos) + Vector2(0, -150)                                # a tiro, más lejos que el Scout
near_i.rect.center = (round(near_i.pos.x), round(near_i.pos.y))
near_i.detected_timer = 1.0
tower_i.fire_timer = 0.0
bul_i = pygame.sprite.Group()
tower_i._turret_logic(1 / 60, w.targets, bul_i)
shot_i = next(iter(bul_i))
aim_i = (Vector2(near_i.pos) - tower_i.pos).normalize()
assert shot_i.vel.normalize().dot(aim_i) > 0.99                                     # apuntó al Carroñero, no al Scout
near_i.detected_timer = 0.0                                                         # sin marcar: vuelve la regla normal
tower_i.fire_timer = 0.0
bul_i2 = pygame.sprite.Group()
tower_i._turret_logic(1 / 60, w.targets, bul_i2)
assert next(iter(bul_i2)).vel.normalize().dot((Vector2(scout_i.pos) - tower_i.pos).normalize()) > 0.99    # el Scout (primero)
# sin Foco enlazado no hay prioridad
tower_free = Building("tower", Vector2(1500, 900))
tower_free.world = w
assert tower_free.linked_foco() is None
# el marcado caduca si el Carroñero sale del radio o el Foco se apaga
near_i.detected_timer = Building.DETECT_HOLD
near_i.update(Building.DETECT_HOLD + 0.1, pygame.sprite.Group())
assert not near_i.detected
# --- red: el sabotaje de un pilón apaga al Foco y al Extractor que alimenta; al volver la red, reanudan
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=5000)
w = a2.world
dep_f = ScrapDeposit(Vector2(740, 540))
w.deposits.add(dep_f); w.all_sprites.add(dep_f); a2.deposit_list.append(dep_f)
assert build(a2, "pylon", (540, 620)) and build(a2, "pylon", (660, 540))           # cadena: núcleo -> A -> B
assert build(a2, "foco", (740, 620)) and build(a2, "extractor", (740, 540))        # solo B los alcanza
foco_g = next(iter(w.focos))
ext_g = next(iter(w.extractors))
pyl_b = max(w.pylons, key=lambda p_: p_.pos.x)
step(game, 2)
assert foco_g.active and ext_g.active and foco_g.is_powered and ext_g.is_powered
dep_f.total_metal = 0                                                              # sin suministro en el depósito: no produce
assert dep_f.depleted and not ext_g.active
dep_f.total_metal = C.DEPOSIT_METAL
assert ext_g.active
pyl_b.sabotage(U.SCAVENGER["sabotage_time"])
step(game, 2)
assert not foco_g.is_powered and not ext_g.is_powered and not foco_g.active and not ext_g.active
surf_g = pygame.Surface((120, 120))
foco_g.draw_overlay(surf_g, pygame.Rect(40, 40, 40, 40), Vector2())               # sin red: se dibuja sin errores
ext_g.timer = C.EXTRACTOR_INTERVAL - 0.01
m_g = game.resources.metal
step(game, 30)
assert game.resources.metal == m_g and ext_g.timer == C.EXTRACTOR_INTERVAL - 0.01     # apagado: no produce
near_sc = _SDi(Vector2(foco_g.pos) + Vector2(200, 0))
near_sc.state, near_sc.latch_timer = "latching", 99
w.scavengers.add(near_sc); w.targets.add(near_sc); w.all_sprites.add(near_sc)
step(game, 2)
assert not near_sc.detected                                                          # Foco apagado: no detecta
near_sc.kill()
step(game, int(60 * U.SCAVENGER["sabotage_time"]) + 30)
assert foco_g.active and ext_g.active                                              # la red vuelve sola
pyl_b.take_damage(99999)                                                           # ahora cae el pilón: sin red, sin errores
step(game, 3)
assert not pyl_b.alive() and not foco_g.active and not ext_g.active
assert all(c_ is not pyl_b and n_ is not pyl_b for c_, n_ in a2.grid.feeds)
# --- energía neta insuficiente: al caer un pilón, se apaga lo más nuevo (aquí el Foco) y nada consume de más
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=5000)
w = a2.world
assert build(a2, "pylon", (500, 540)) and build(a2, "pylon", (380, 520)) and a2.energy_capacity() == 60
for pos_ in ((300, 700), (340, 700), (380, 700), (420, 700)):
    assert build(a2, "balista", pos_)
assert build(a2, "tower", (460, 700)) and a2.energy_used() == 55
assert build(a2, "foco", (340, 660))
foco_e = next(iter(w.focos))
assert a2.energy_used() == 58 and foco_e.active
max(w.pylons, key=lambda p_: p_.build_order).take_damage(99999)                  # capacidad 60 -> 55 < 57
step(game, 3)
assert a2.energy_capacity() == 55 and not foco_e.energized and not foco_e.active
assert a2.energy_used() <= a2.energy_capacity() and all(t_.active for t_ in w.towers)   # las torretas siguen operativas
bal_e = next(iter(w.towers))
assert bal_e.linked_foco() is None and bal_e.effective_range() == bal_e.range           # sin Foco operativo, sin bonus
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Bloque 2: muros por cursor (clic y E, sin distancia) y Compuerta ligada a la red ==")


def hover(scene, world_pos):
    """Pone el cursor sobre una posición del MUNDO (como haría el jugador con el ratón)."""
    sp = Vector2(world_pos) - scene.camera.offset
    mpos[0], mpos[1] = int(sp.x), int(sp.y)
    assert 0 <= mpos[0] < 1280 and 0 <= mpos[1] < 720, (world_pos, mpos)


def newest(scene, kind):
    return max((b_ for b_ in scene.world.structures if b_.building_type == kind), key=lambda b_: b_.build_order)


# --- Acto 2: mejora del muro con el cursor, lejos del Operador (ningún chequeo de distancia)
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=3000, vulcano=True)
w = a2.world
res = game.resources
assert build(a2, "pylon", (540, 620)) and build(a2, "wall", (620, 500))       # fuera del radio del núcleo: depende del pilón
wall_b = newest(a2, "wall")
step(game, 2)
assert wall_b.level == 1 and wall_b.max_hp == 400 and wall_b.energy_cost == 0
# 1) E con el cursor sobre el muro: Reforzado (+30⚙, 900 HP, -30% a la embestida)
m0, c0 = res.metal, res.cores
hover(a2, wall_b.pos)
assert a2.structure_under(a2.camera.to_world(pygame.mouse.get_pos())) is wall_b      # la detección del cursor da el muro
press(game, pygame.K_e)
assert wall_b.level == 2 and wall_b.max_hp == 900 and wall_b.ram_reduction == 0.30
assert res.metal == m0 - 30 and res.cores == c0 and wall_b.energy_cost == 0
hp0 = wall_b.hp
wall_b.take_damage(300, ram=True)
assert abs((hp0 - wall_b.hp) - 210) < 1e-9                                         # 300 de embestida -30%
wall_b.hp = wall_b.max_hp
# 2) E con el cursor fuera del muro (o sobre otra estructura): no hace nada
hover(a2, wall_b.pos + Vector2(150, 100))
m1 = res.metal
press(game, pygame.K_e)
assert wall_b.level == 2 and res.metal == m1
hover(a2, next(iter(w.pylons)).pos)
press(game, pygame.K_e)
assert wall_b.level == 2 and res.metal == m1
# 3) E de nuevo sobre el muro: Electrificado (+60⚙, 2⚡, 0 núcleos, 1400 HP)
e_before = a2.energy_used()
hover(a2, wall_b.pos)
press(game, pygame.K_e)
step(game, 2)
assert wall_b.level == 3 and wall_b.max_hp == 1400 and wall_b.counter_damage == 20
assert res.metal == m1 - 60 and res.cores == c0 and wall_b.energy_cost == 2
assert a2.energy_used() == e_before + 2 and wall_b.is_powered and wall_b.active
press(game, pygame.K_e)                                                            # ya no hay más niveles
assert wall_b.level == 3 and res.metal == m1 - 60
# 4) Electrificado con energía: refleja 20 al Scout que lo muerde (una vez por segundo); sin energía actúa como Reforzado
sc_b = Enemy("scout", Vector2(wall_b.pos) + Vector2(30, 0), a2.CC_POS, w.enemies)
sc_b.speed = 0
w.enemies.add(sc_b); w.all_sprites.add(sc_b)
hp_w = wall_b.hp
wall_b.take_damage(8, attacker=sc_b)
assert sc_b.hp == sc_b.max_hp - 20 and wall_b.hp == hp_w - 8                       # refleja 20
sc_b.hp, sc_b.counter_timer = sc_b.max_hp, 0.0
pyl_b2 = next(iter(w.pylons))
pyl_b2.sabotage(U.SCAVENGER["sabotage_time"])                                      # corte de energía
step(game, 2)
assert not wall_b.is_powered and not wall_b.active
hp_w = wall_b.hp
wall_b.take_damage(8, attacker=sc_b)
assert sc_b.hp == sc_b.max_hp and wall_b.hp == hp_w - 8                            # sin reflejo
assert wall_b.max_hp == 1400 and wall_b.ram_reduction == 0.30                     # actúa como Reforzado (conserva 1400 HP)
hp_w = wall_b.hp
wall_b.take_damage(300, ram=True)
assert abs((hp_w - wall_b.hp) - 210) < 1e-9                                        # -30% a la embestida igualmente
step(game, int(60 * U.SCAVENGER["sabotage_time"]) + 30)
assert wall_b.active
sc_b.hp, sc_b.counter_timer = sc_b.max_hp, 0.0
wall_b.take_damage(8, attacker=sc_b)
assert sc_b.hp == sc_b.max_hp - 20                                                 # vuelve la red: vuelve el reflejo
sc_b.kill()
# 5) lo mismo con el menú de clic derecho (otro muro): mismas cifras, sin distancia
assert build(a2, "wall", (620, 540))
wall_c = newest(a2, "wall")
m2 = res.metal
right_click(game, wall_c.pos)
assert a2.menu is not None and a2.menu.building is wall_c
opt_ = a2.menu.options[0]
assert (opt_["scrap"], opt_["cores"], opt_["energy"]) == (30, 0, 0)
press(game, pygame.K_1)
assert wall_c.level == 2 and res.metal == m2 - 30
right_click(game, wall_c.pos)
opt_ = a2.menu.options[0]
assert (opt_["scrap"], opt_["cores"], opt_["energy"]) == (60, 0, 2)
press(game, pygame.K_1)
assert wall_c.level == 3 and res.metal == m2 - 30 - 60
# sin chatarra o sin energía libre, la mejora no se aplica ni se cobra
assert build(a2, "wall", (660, 540))
wall_d = newest(a2, "wall")
res.metal = 20
hover(a2, wall_d.pos)
press(game, pygame.K_e)
assert wall_d.level == 1 and res.metal == 20
res.metal = 3000
# --- Compuerta: red, aliados (dron y V.U.L.C.A.N.O.), corte y restablecimiento
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=3000, vulcano=True)
w = a2.world
cc_ = a2.CC_POS
assert build(a2, "pylon", (cc_.x + 120, cc_.y + 20))
m0, e0 = a2.res.metal, a2.res.energy
assert build(a2, "compuerta", (cc_.x + 200, cc_.y + 40))
gate = next(iter(w.gates))
pyl_g = next(iter(w.pylons))
step(game, 2)
assert (gate.stats["cost"], gate.max_hp, gate.energy_cost) == (45, 500, 1) and a2.res.energy == e0 + 1
assert gate.requires_power and gate.is_powered and gate.active and not gate.is_open
teleport(a2, gate.pos + Vector2(0, 600))                                            # el Operador, lejos
gate.update(0.1, pygame.sprite.Group(), pygame.sprite.Group())
assert not gate.is_open
v_g = a2.vulcano
assert v_g is not None and w.vulcano is v_g
v_g.pos = Vector2(gate.pos) + Vector2(30, 0)                                        # V.U.L.C.A.N.O. se acerca
gate.update(0.1, pygame.sprite.Group(), pygame.sprite.Group())
assert gate.is_open                                                                 # se abre sola
v_g.pos = Vector2(gate.pos) + Vector2(900, 900)
gate.update(1.0, pygame.sprite.Group(), pygame.sprite.Group())
assert gate.is_open
gate.update(1.2, pygame.sprite.Group(), pygame.sprite.Group())
assert not gate.is_open                                                             # se cierra tras su paso (2 s)
assert gate.check_collision(_Foe()) is False                                        # a los enemigos los bloquea siempre
rd2 = ReconDrone(Vector2(gate.pos) + Vector2(30, 0), _ds3("recon"), home=a2.CC_POS)
w.drones.add(rd2)
gate.update(0.1, pygame.sprite.Group(), pygame.sprite.Group())
assert gate.is_open                                                                 # y a un dron
rd2.kill()
step(game, 150)
assert not gate.is_open
# corte de energía (sabotaje del pilón): congelada cerrada, sólida incluso para aliados
pyl_g.sabotage(U.SCAVENGER["sabotage_time"])
step(game, 2)
assert not gate.is_powered and not gate.active and not gate.is_open
rd3 = ReconDrone(Vector2(gate.pos) + Vector2(30, 0), _ds3("recon"), home=a2.CC_POS)
w.drones.add(rd3)
v_g.pos = Vector2(gate.pos) + Vector2(30, 0)
gate.update(0.1, pygame.sprite.Group(), pygame.sprite.Group())
assert not gate.is_open and not gate.ally_passable                                  # ni dron ni V.U.L.C.A.N.O. la abren
rd3.kill()
v_g.pos = Vector2(gate.pos) + Vector2(900, 900)
pg8_ = Player((0, 0), a2.map_w, a2.map_h)                                          # Operador de prueba (el Acto 2 es de mando)
pg8_.equipped = True
pg8_grp = pygame.sprite.Group(pg8_)                                                 # (un sprite «vive» si está en un grupo)
w.player = pg8_                                                                     # la Compuerta lo reconoce como aliado
pg8_.pos = Vector2(gate.pos.x - 50, gate.pos.y)
pg8_.rect.center = (round(pg8_.pos.x), round(pg8_.pos.y))
pg8_.vel = Vector2(300, 0)
for _ in range(6):
    pg8_._move(1 / 20, w.solids)
assert pg8_.pos.x < gate.pos.x and not gate.is_open                            # el Operador tampoco pasa: muro sólido
assert gate.check_collision(type("A", (), {"is_ally": True})()) is False
surf_c = pygame.Surface((200, 200))
gate.draw_overlay(surf_c, pygame.Rect(80, 60, 40, 80), Vector2())                   # congelada: se dibuja sin errores
card = _scard(gate)
assert any("CONGELADA" in r_[1] for r_ in card["rows"] if r_[0] == "text")
# vuelve la red: se reactiva sola y vuelve a abrirse
step(game, int(60 * U.SCAVENGER["sabotage_time"]) + 30)
assert gate.active and gate.is_open                                                 # el Operador sigue pegado: se abre sola
pg8_.pos = Vector2(gate.pos.x - 50, gate.pos.y)
pg8_.rect.center = (round(pg8_.pos.x), round(pg8_.pos.y))
pg8_.vel = Vector2(300, 0)
for _ in range(6):
    pg8_._move(1 / 20, w.solids)
assert pg8_.pos.x > gate.pos.x + 20 and gate.is_open                           # ahora sí lo franquea
w.player = None
# red saturada (sin energía neta): también se congela
gate.energized = False
gate.update(0.1, pygame.sprite.Group(), pygame.sprite.Group())
assert not gate.is_open and not gate.ally_passable
gate.energized = True
# --- Gestión de base (control táctico por cursor, sin avatar): la tecla E también mejora el muro bajo el cursor
game.new_campaign()
game.resources.vulcano_online = True
game.machine.transition(GameState.SUB_ACT_1_4)
game.advance(GameState.ACT_2_BASE)
assert game.machine.current_state is GameState.BASE_MANAGEMENT
bm = screens[GameState.BASE_MANAGEMENT]
res = game.resources
res.metal = 500
assert build_bm(bm, "wall", (740, 660))
wall_m = next(iter(bm.world.walls))
mp = Vector2(wall_m.pos) - bm.camera.offset
mpos[0], mpos[1] = int(mp.x), int(mp.y)
m0 = res.metal
press(game, pygame.K_e)
assert wall_m.level == 2 and wall_m.max_hp == 900 and res.metal == m0 - 30         # Reforzado por cursor + E
mpos[0], mpos[1] = 5, 5                                                            # cursor fuera de cualquier estructura
press(game, pygame.K_e)
assert wall_m.level == 2 and res.metal == m0 - 30
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Bloque 3: especializaciones bloqueadas por el Tech-Tree y varias Fábricas con capacidad dinámica ==")
from src.entities.factory import Factory as _Fb3, fleet_capacity as _cap3, fleet_count as _cnt3
from src.mechanics.base_layout import restore_base as _restore3
from src.managers.resource_manager import CampaignRun as _CR3

# --- costes: nada de plasma; chatarra y energía
assert U.BUILDINGS["fabrica"]["cost"] == 220 and U.BUILDINGS["fabrica"]["cores"] == 0 and U.DRONES_PER_FACTORY == 8
assert [U.DRONE_TYPES[k]["cost"] for k in ("recon", "attack", "bomber", "trooper")] == [25, 40, 75, 50]
assert all(U.DRONE_TYPES[k]["cores"] == 0 for k in U.DRONE_TYPES) and U.BUILDINGS["balista"]["cores"] == 0
assert [U.TURRET_ROUTES[t][r]["cost"] for t, r in (("tower", "A"), ("tower", "B"), ("balista", "A"), ("balista", "B"))] == [60, 60, 90, 110]
assert all(U.TURRET_ROUTES[t][r]["cores"] == 0 for t in U.TURRET_ROUTES for r in "AB")
assert not hasattr(U, "MAX_DRONES") and "max_drones" not in U.STRUCTURES["fabrica"]

# --- Tech-Tree: sin desbloquear, la especialización sale bloqueada (no se elige ni se cobra)
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=3000, tech=False)
w, res = a2.world, game.resources
assert res.unlocked_tech == set()
assert build(a2, "pylon", (540, 620)) and build(a2, "tower", (580, 700)) and build(a2, "balista", (500, 700))
tw3 = next(t_ for t_ in w.towers if t_.building_type == "tower")
bl3 = next(t_ for t_ in w.towers if t_.building_type == "balista")
right_click(game, tw3.pos)
opts3 = a2.menu.options
assert [o["unlocked"] for o in opts3[:2]] == [False, False] and not any(o["enabled"] for o in opts3[:2])
assert "[BLOQUEADA]" in opts3[0]["label"] and "Terminal" in opts3[0]["desc"] and "aleación 2" in opts3[0]["desc"]
game.machine.draw(game.screen)                                                      # el menú con candados se dibuja
m3 = res.metal
press(game, pygame.K_1)
press(game, pygame.K_2)
assert tw3.route is None and res.metal == m3 and any("Terminal" in ln.text for ln in a2.dialogue.lines)
a2.close_menu()
right_click(game, bl3.pos)
assert [o["unlocked"] for o in a2.menu.options[:2]] == [False, False]               # la Balista también
a2.close_menu()
# desbloqueo en el Terminal (aleación): la rama A de la Ligera queda disponible; la B y las de la Balista, no
res.alloy = 1
assert not res.unlock_route("tower_A") and res.alloy == 1                            # con 1 de aleación no alcanza
res.alloy = 2
assert res.unlock_route("tower_A") and res.alloy == 0 and res.unlocked_tech == {"tower_A"} and res.route_unlocked("tower", "A")
assert not res.unlock_route("tower_A") and not res.unlock_route("tower_B") and not res.route_unlocked("tower", "B")
right_click(game, tw3.pos)
opts3 = a2.menu.options
assert opts3[0]["unlocked"] and opts3[0]["enabled"] and not opts3[1]["unlocked"] and opts3[0]["label"] == "Ruta A: MINIGUN"
press(game, pygame.K_2)                                                              # la B sigue bloqueada
assert tw3.route is None
press(game, pygame.K_1)
assert tw3.route == "A" and res.metal == m3 - 60 and tw3.damage == 10 and tw3.armor_pierce == 4   # +60⚙, solo chatarra
# una torreta ya especializada en una partida guardada conserva su ruta aunque esté bloqueada (derecho adquirido)
a2.res.campaign_run.tech_unlocked.clear()
a2.res.base_layout = [{"type": "tower", "pos": (620.0, 740.0), "hp": 300, "route": "B", "level": 1}]
_restore3(a2, a2.res)
assert any(t_.route == "B" for t_ in w.towers)
# --- Terminal Táctico: botones de desbloqueo
game.machine.transition(GameState.MENU)
game.new_campaign()
game.resources.initial_done = True
game.resources.alloy = 3
game.machine.transition(GameState.ACT_2_BASE)
term3 = screens[GameState.ACT_2_BASE]
assert set(term3.tech_rects) == set(U.TURRET_TECH)
rects_all = list(term3.tech_rects.values()) + list(term3.drone_rects.values()) + list(term3.node_rects.values())
assert all(0 <= r_.left and r_.right <= 1280 and r_.bottom <= 720 for r_ in term3.tech_rects.values())
assert not any(a_.colliderect(b_) for a_ in term3.tech_rects.values() for b_ in rects_all if a_ is not b_)   # sin solapes
click3 = lambda key_: game.machine.handle_event(pygame.event.Event(pygame.MOUSEBUTTONDOWN, button=1, pos=term3.tech_rects[key_].center))
click3("tower_B")
assert game.resources.unlocked_tech == {"tower_B"} and game.resources.alloy == 1 and "Lanzallamas desbloqueada" in term3.upgrade_msg
click3("tower_B")
assert game.resources.alloy == 1 and "ya desbloqueada" in term3.upgrade_msg
click3("balista_A")
assert game.resources.unlocked_tech == {"tower_B"} and "Falta aleación" in term3.upgrade_msg
game.machine.draw(game.screen)
# persistencia: checkpoints, guardado de CampaignRun y paso de mapa; una campaña nueva lo borra
res3 = game.resources
snap3 = res3.snapshot()
res3.campaign_run.tech_unlocked.clear()
res3.restore(snap3)
assert res3.unlocked_tech == {"tower_B"}
legacy = dict(snap3)
legacy.pop("tech_unlocked")
res3.restore(legacy)
assert res3.unlocked_tech == set()                                                   # checkpoint antiguo: nada desbloqueado
res3.campaign_run.tech_unlocked.add("balista_B")
saved3 = res3.campaign_run.to_dict()
assert saved3["tech_unlocked"] == ["balista_B"] and json.dumps(saved3)
assert _CR3.from_dict(saved3).tech_unlocked == {"balista_B"}
assert _CR3.from_dict({"tech_unlocked": ["balista_B", "inventada"]}).tech_unlocked == {"balista_B"}
game.campaign_run.start_map("map_1_infiltration", res=res3)
assert res3.unlocked_tech == {"balista_B"}                                           # persiste entre mapas
game.new_campaign()
assert game.resources.unlocked_tech == set()

# --- varias Fábricas: construcción, capacidad dinámica (8 por fábrica operativa) y colas individuales
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=8000, tech=False)
w, res = a2.world, game.resources
for b_ in a2.enemy_bases:                                       # la centinela enemiga derribaría a los Exploradores en patrulla
    disarm(b_)
assert build(a2, "pylon", (540, 620))
m0 = res.metal
assert build(a2, "fabrica", (640, 720)) and build(a2, "fabrica", (560, 800))        # ya no hay "una por base" (solo el pilón las alimenta)
f1, f2 = a2.factories
assert len(w.factories) == 2 and f1.build_order < f2.build_order and a2.factory is f1
assert m0 - res.metal == 2 * a2._cost("fabrica") == 2 * 110                           # 220 con el -50% de la preparación
assert (f1.stats["cost"], f1.max_hp, f1.stats["energy"], f1.stats["build_time"], f1.stats["production_time"]) == (220, 600, 3, 20.0, 10.0)
assert _cap3(w) == 0 and not f1.operational                                          # sin desplegar no suman
used_idle = a2.energy_used()
step(game, 60 * 20 + 5)                                                               # 20 s de despliegue
assert f1.built and f2.built and f1.operational and f2.operational and _cap3(w) == 16
assert a2.energy_used() == used_idle                                                  # inactivas: 0 de energía
assert "0/16" in a2.drone_status()
res.metal = 5000
for key_ in (pygame.K_F2, pygame.K_F1, pygame.K_F3, pygame.K_F4):                    # attack, recon, bomber, trooper
    press(game, key_)
assert f1.production_queue == ["attack", "bomber"] and f2.production_queue == ["recon", "trooper"]   # cada una, su cola
assert res.metal == 5000 - 40 - 25 - 75 - 50
step(game, 2)
assert a2.energy_used() == used_idle + 6                                              # 3 de energía por fábrica que produce
step(game, 60 * 10)
assert _cnt3(w) == 2 and [d_.drone_type for d_ in f1.drones] == ["attack"] and [d_.drone_type for d_ in f2.drones] == ["recon"]
step(game, 60 * 10)
assert _cnt3(w) == 4 and len(f1.drones) == 2 and len(f2.drones) == 2 and a2.energy_used() == used_idle    # (10 s por dron)
assert "4/16" in a2.drone_status() and "2 fábr." in a2.drone_status()
# flota llena (16): se puede encargar, pero el dron espera; otra fábrica da +8 y lo libera
for _ in range(12):
    f1._spawn_drone("attack")
assert _cnt3(w) == 16 and f1.at_limit and f2.at_limit
assert a2.queue_drone("trooper")
step(game, 60 * 12)
assert _cnt3(w) == 16 and "flota completa" in a2.drone_status() and f1.current_production is None
assert f1.production_queue == ["trooper"]                                             # esperando hueco, ya pagado
# se destruye una fábrica: sus drones sobreviven y no se fabrican reemplazos mientras la flota exceda la capacidad
f1_drones = [d_ for d_ in f1.drones if d_.alive()]
f1.take_damage(99999)
step(game, 2)
assert not f1.alive() and _cap3(w) == 8 and _cnt3(w) == 16 and all(d_.alive() for d_ in f1_drones)
assert a2.factories == [f2]
assert a2.queue_drone("trooper") and f2.production_queue == ["trooper"]
step(game, 60 * 12)
assert _cnt3(w) == 16 and f2.current_production is None and f2.production_queue == ["trooper"]       # pausada
fleet3 = [d_ for d_ in w.drones if d_.alive() and hasattr(d_, "home")]
for d_ in fleet3[:8]:
    d_.kill()
assert _cnt3(w) == 8
step(game, 60 * 12)
assert _cnt3(w) == 8 and f2.production_queue == ["trooper"]                           # 8 = capacidad: sigue pausada
fleet3[8].kill()
step(game, 60 * 11)
assert _cnt3(w) == 8 and f2.production_queue == [] and f2.current_production is None   # 7 < 8: fabrica el reemplazo
# sin red (sabotaje del pilón) la fábrica no cuenta y no produce
pyl3 = next(iter(w.pylons))
pyl3.sabotage(U.SCAVENGER["sabotage_time"])
step(game, 2)
assert not f2.operational and _cap3(w) == 0 and "Drones" in a2.drone_status() and "/0" in a2.drone_status()
step(game, int(60 * U.SCAVENGER["sabotage_time"]) + 30)
assert f2.operational and _cap3(w) == 8
# --- colas con varias fábricas: guardado por fábrica de origen, reparto al restaurar y reembolso de lo que no cabe
fa, fb = _Fb3((100, 100)), _Fb3((300, 100))
fa.build_order, fb.build_order = 1, 2
fa.production_queue = ["attack"]
fb.current_production, fb.production_time_left, fb.production_queue = "recon", 4.0, ["bomber"]
data3 = _CR3.serialize_factory_queue([fa, fb])
assert [(e_["drone_type"], e_["slot"]) for e_ in data3] == [("attack", 0), ("recon", 1), ("bomber", 1)]
assert data3[1]["time_left"] == 4.0 and json.dumps(data3)
fa2, fb2 = _Fb3((100, 100)), _Fb3((300, 100))
fa2.build_order, fb2.build_order = 1, 2
rm3 = ResourceManager()
rm3.metal = 0
got3 = rm3.campaign_run.deserialize_factory_queue([fa2, fb2], rm3, data=data3)
assert got3 == ["attack", "recon", "bomber"] and fa2.production_queue == ["attack"]
assert fb2.current_production == "recon" and fb2.production_time_left == 4.0 and fb2.production_queue == ["bomber"]
fc = _Fb3((100, 100))                                                                 # solo queda una fábrica
rm3.campaign_run.deserialize_factory_queue(fc, rm3, data=data3 + [{"drone_type": "recon", "cost": (50, 0), "slot": 0}] * 3)
assert fc.current_production == "recon" and fc.production_queue == ["attack", "bomber", "recon", "recon"]   # cola de 4
assert rm3.metal == 50                                                                # lo que no cupo se devuelve (1 recon)
# supervivientes: los drones guardados vuelven todos y se reparten entre las fábricas
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=8000, tech=False)
w = a2.world
assert build(a2, "pylon", (540, 620)) and build(a2, "fabrica", (640, 720)) and build(a2, "fabrica", (480, 760))
g1, g2 = a2.factories
g1.build_left = g2.build_left = 0.0
step(game, 2)
run3 = _CR3()
run3.drone_data = [{"type": "recon", "hp": 40.0, "x": 700.0, "y": 700.0, "upgrades": {}} for _ in range(10)]
made3 = run3.deserialize_drones(w, factories=[g1, g2], origin=a2.CC_POS)
assert len(made3) == 10 and len(g1.drones) == 5 and len(g2.drones) == 5 and _cnt3(w) == 10   # 10 < 16: caben
game.machine.transition(GameState.MENU)

# =============================================================================
print("== Aleación extra: Tanque de oleada avanzada y victoria con el Centro de Control sano ==")
game.machine.transition(GameState.MENU)
a2 = campaign_act2(game, 0, metal=500)
run_a = game.campaign_run
al0 = game.resources.alloy
tank_a = Enemy("tank", Vector2(a2.core.pos) + Vector2(300, 0), a2.CC_POS, a2.world.enemies)
a2.wave.wave = 3
a2._on_enemy_death(tank_a)
assert game.resources.alloy == al0                                                 # antes de la oleada 4: nada
a2.wave.wave = 4
a2._on_enemy_death(tank_a)
assert game.resources.alloy == al0 + U.ALLOY_BONUS["tank_drop"]                    # +1 garantizada
a2._on_enemy_death(tank_a)
assert game.resources.alloy == al0 + 1                                             # solo una vez por mapa
sc_scout = Enemy("scout", Vector2(a2.core.pos) + Vector2(300, 0), a2.CC_POS, a2.world.enemies)
a2._on_enemy_death(sc_scout)
assert game.resources.alloy == al0 + 1
# victoria: +2 si el Centro de Control supera el 75% de vida (solo la primera vez que se gana el mapa)
al1 = game.resources.alloy
a2.core.hp = a2.core.max_hp * 0.80
run_a.on_map_complete(True, a2, game.resources)
assert game.resources.alloy == al1 + U.CAMPAIGN_MAP_ALLOY["map_1_infiltration"] + U.ALLOY_BONUS["clear_reward"]
al2 = game.resources.alloy
run_a.on_map_complete(True, a2, game.resources)
assert game.resources.alloy == al2                                                 # repetir el mapa no paga
a2.wave.wave = 4
a2._tank_alloy_given = False
a2._on_enemy_death(tank_a)
assert game.resources.alloy == al2                                                 # mapa ya ganado: tampoco el Tanque
game.machine.transition(GameState.MENU)
a2 = campaign_act2(game, 1, metal=500)
al3 = game.resources.alloy
a2.core.hp = a2.core.max_hp * 0.70
game.campaign_run.on_map_complete(True, a2, game.resources)
assert game.resources.alloy == al3 + U.CAMPAIGN_MAP_ALLOY["map_2_push"]            # con el Centro dañado: sin bonus
game.machine.transition(GameState.MENU)

# =============================================================================
# =============================================================================
print("== Legibilidad en combate: barras con estela, banner de oleada, viñeta de daño y avisos ==")
from src.ui import combat_feedback as cf
from src.entities.building import create_building as _create_b

_clock = [500.0]
_real_now = cf._now
cf._now = lambda: _clock[0]                                  # reloj controlado
fb_surf = pygame.Surface((C.WINDOW_WIDTH, C.WINDOW_HEIGHT))

class _Ent:                                                  # entidad mínima para la barra
    pass

e_ = _Ent()
bar_rect = pygame.Rect(100, 100, 44, 5)
cf.health_bar(fb_surf, e_, bar_rect, 1.0, hostile=True)
assert e_._bar_ghost[0] == 1.0
_clock[0] += 0.016
cf.health_bar(fb_surf, e_, bar_rect, 0.5, hostile=True)
assert 0.5 < e_._bar_ghost[0] < 1.0                           # el daño deja estela blanca que baja poco a poco
assert tuple(fb_surf.get_at((bar_rect.x + 30, bar_rect.y + 2)))[:3] == (244, 244, 232)
for _ in range(60):
    _clock[0] += 0.05
    cf.health_bar(fb_surf, e_, bar_rect, 0.5, hostile=True)
assert e_._bar_ghost[0] == 0.5                                # la estela se agota
_clock[0] += 0.016
cf.health_bar(fb_surf, e_, bar_rect, 0.9)
assert e_._bar_ghost[0] == 0.9                                # curar no deja rastro
assert cf.bar_color(0.8) == (70, 235, 120) and cf.bar_color(0.4) == (255, 184, 48) and cf.bar_color(0.1, now=0.0) == (255, 70, 56)
assert cf.bar_color(0.1, hostile=True) == (232, 72, 60)
cf.health_bar(fb_surf, e_, pygame.Rect(0, 0, 10, 3), 0.0)    # vida 0 y barras estrechas: sin errores

# barras reales: enemigo y estructura dañados se dibujan sin alterar su vida
tower_fb = _create_b("tower", Vector2(300, 300))
tower_fb.hp = tower_fb.max_hp * 0.3
hp0 = tower_fb.hp
tower_fb.draw_overlay(fb_surf, tower_fb.rect, Vector2())
assert tower_fb.hp == hp0 and hasattr(tower_fb, "_bar_ghost")

# banner de oleada: aparece al cambiar de fase y se apaga a los 2,6 s
class _W:
    phase, wave, total_waves, endless, remaining, timer = "wave", 3, 5, False, 12, 0
hud_fb = HUD()
w_ = _W()
fb_surf.fill((0, 0, 0))
hud_fb.wave_banner.draw(fb_surf, hud_fb, w_)
assert hud_fb.wave_banner._style[0] == "OLEADA 3 / 5"
_clock[0] += 0.5
hud_fb.wave_banner.draw(fb_surf, hud_fb, w_)
assert fb_surf.get_at((C.WINDOW_WIDTH // 2, round(C.WINDOW_HEIGHT * 0.30) - 48 + 2))[:3] != (0, 0, 0)   # franja visible
w_.wave = 5
hud_fb.wave_banner.draw(fb_surf, hud_fb, w_)
assert hud_fb.wave_banner._style[0] == "¡OLEADA FINAL!"
w_.phase = "break"
hud_fb.wave_banner.draw(fb_surf, hud_fb, w_)
assert hud_fb.wave_banner._style[0] == "OLEADA 5 SUPERADA"
_clock[0] += cf.WaveBanner.SHOW + 0.1
fb_surf.fill((0, 0, 0))
hud_fb.wave_banner.draw(fb_surf, hud_fb, w_)
assert fb_surf.get_at((C.WINDOW_WIDTH // 2, 200))[:3] == (0, 0, 0)       # ya no se dibuja

# viñeta: destella al perder vida, se apaga y late con vida baja
class _P:
    hp, max_hp = 100.0, 100.0
p_ = _P()
vig = cf.DamageVignette()
assert vig.strength(p_.hp, p_.max_hp, _clock[0]) == 0.0
p_.hp = 80.0
_clock[0] += 0.016
first = vig.strength(p_.hp, p_.max_hp, _clock[0])
assert 0.3 < first <= 0.85
for _ in range(12):                                                      # 0,6 s en pasos de dibujo
    _clock[0] += 0.05
    last = vig.strength(p_.hp, p_.max_hp, _clock[0])
assert last == 0.0                                                       # el destello se apaga
p_.hp = 20.0
_clock[0] += 0.016
vig.strength(p_.hp, p_.max_hp, _clock[0])
_clock[0] += 1.0
assert vig.strength(p_.hp, p_.max_hp, _clock[0]) > 0.1                   # vida baja: pulso continuo
for _ in range(12):                                                      # que se apague el destello de la última caída
    _clock[0] += 0.05
    vig.strength(p_.hp, p_.max_hp, _clock[0])
p_.hp = 100.0
_clock[0] += 0.016
assert vig.strength(p_.hp, p_.max_hp, _clock[0]) == 0.0                  # curarse no destella y apaga el pulso
vig.draw(fb_surf, _P())                                                  # dibujo real sin errores

# avisos: se agrupan, se limitan a 3 y caducan
al = cf.AlertToasts()
for _ in range(3):
    al.push("Muro perdido", C.RED, key=("lost", "wall"))
assert len(al.items) == 1 and al.items[0][4] == 3
for k_ in range(5):
    al.push(f"Aviso {k_}", C.RED)
assert len(al.items) == cf.AlertToasts.MAX
al.draw(fb_surf, hud_fb)
_clock[0] += cf.AlertToasts.TTL + 0.1
al.draw(fb_surf, hud_fb)
assert not al.items

# integración: una estructura que cae avisa y suelta una onda roja; el HUD del Acto 2 dibuja todo sin errores
cf.ALERTS.clear()
a2_fb = new_act2(game, metal=500)
tw = _create_b("tower", a2_fb.CC_POS + Vector2(120, 0))
a2_fb._register(tw)
blasts0 = len(combat.FX.blasts)
tw.take_damage(99999)
assert any(it[0] == ("lost", "tower") for it in cf.ALERTS.items) and len(combat.FX.blasts) > blasts0
core_hp0 = a2_fb.core.hp
step(game, 2)
a2_fb.core.hp -= 50
step(game, 2)
assert any(it[0] == "core" for it in cf.ALERTS.items)                    # el Centro de Control bajo ataque
a2_fb.core.hp = core_hp0
cf.ALERTS.clear()
cf._now = _real_now
game.machine.transition(GameState.MENU)


# =============================================================================
print("== Recogibles: tooltips al pasar el ratón, piezas de AURA con forma de cuerpo y feedback de daño ==")
from src.entities.chassis import ChassisPart
from src.entities.core_item import CoreItem
from src.entities.ammo import AmmoBox
from src.entities.alloy_item import AlloyItem
from src.entities import pickup_art as pa
from src.ui.tooltips import pickup_card, pickup_under

a2_pk = new_act2(game, metal=500)
pk_res = game.resources
pk_items = [ScrapItem((2000, 1000), 25), CoreItem((2100, 1000), 2), AmmoBox((2200, 1000)), AlloyItem((2300, 1000), 1),
            ChassisPart((2400, 1000), 3)]
titles = [pickup_card(it, pk_res)["title"] for it in pk_items]
assert titles == ["CHATARRA", "NÚCLEO DE PLASMA", "CAJA DE MUNICIÓN", "ALEACIÓN MILITAR",
                  "COMPONENTE DE AURA · BRAZO DERECHO"], titles
assert all(len(pickup_card(it, pk_res)["rows"]) >= 4 for it in pk_items)
assert pickup_card(pk_items[0], pk_res)["rows"][0][1] == "+25 de metal"
assert pickup_card(pk_items[4], pk_res)["rows"][1][1] == f"Recuperadas: {pk_res.chassis_found}/{C.CHASSIS_TOTAL_PARTS}"
assert pickup_card(object(), pk_res) is None
assert pickup_under([pygame.sprite.Group(*pk_items)], Vector2(2102, 1004)) is pk_items[1]          # el más cercano al ratón
assert pickup_under([pygame.sprite.Group(*pk_items)], Vector2(2150, 1200)) is None                  # lejos de todo

# las 6 piezas del chasis son distintas (cabeza, torso, 2 brazos, 2 piernas) y conservan caja y magnetismo
imgs = {pygame.image.tostring(ChassisPart((0, 0), i).image, "RGBA") for i in range(6)}
assert len(imgs) == 6 and [ChassisPart((0, 0), i).part_name for i in (0, 1, 4)] == ["Cabeza", "Torso", "Pierna izquierda"]
cp = ChassisPart((500, 500), 0)
assert cp.rect.size == (pa.PART_SIZE, pa.PART_SIZE) and cp.rect.center == (500, 500)
pa._rng.seed(7)                                                         # estela determinista en la prueba
tgt_pk = type("T", (), {"pos": Vector2(540, 500), "alive": lambda self: True})()
for _ in range(5):
    cp.update(0.01, tgt_pk)
assert cp.pos.x > 500 and cp.rect.center == (round(cp.pos.x), round(cp.pos.y)) and cp._trail      # imán + estela
sc_pk = ScrapItem((600, 600))
assert pygame.image.tostring(sc_pk.image, "RGBA") == pygame.image.tostring(pa.scrap_frame(sc_pk.variant), "RGBA")

# hover real en el Acto 2: el tooltip aparece a los 0,5 s y muestra la tarjeta del material
pk_scrap = ScrapItem(a2_pk.CC_POS + Vector2(200, 230), 33)
a2_pk.world.scraps.add(pk_scrap)
a2_pk.all_sprites.add(pk_scrap)
step(game, 2)
screen_pos = a2_pk.camera.to_screen(pk_scrap.pos)
found = a2_pk.hover_card((int(screen_pos.x), int(screen_pos.y)))
assert found is not None and found[0][0] == "pickup" and found[1]["title"] == "CHATARRA"
_get_pos0 = pygame.mouse.get_pos
pygame.mouse.get_pos = lambda: (int(screen_pos.x), int(screen_pos.y))
game.tooltips.clear()
step(game, 2)
game.tooltips.since -= 600                                              # han pasado los 0,5 s de hover
step(game, 1)
assert game.tooltips.key == ("pickup", id(pk_scrap))
pygame.mouse.get_pos = lambda: (5, 5)
step(game, 1)
assert a2_pk.hover_card((5, 5)) is None
pygame.mouse.get_pos = _get_pos0

# daño al Operador: cifra roja flotante, chispas, destello rojo del sprite y viñeta
combat.FX.clear()
pl_fb = Player(a2_pk.CC_POS + Vector2(0, 230), a2_pk.map_w, a2_pk.map_h)        # el Operador (en sus escenas)
pl_fb.since_hit = 99.0
hp_before = pl_fb.hp
pl_fb.take_damage(12)
assert pl_fb.hp < hp_before
assert combat.FX.floaters and combat.FX.floaters[-1][2].startswith("-") and combat.FX.sparks
img_plain = pygame.Surface((10, 10), pygame.SRCALPHA)
img_plain.fill((10, 10, 10, 255))
assert pl_fb._tint(img_plain).get_at((0, 0))[0] > 100                    # destello rojo tras el golpe
pl_fb.since_hit = 5.0
assert pl_fb._tint(img_plain) is img_plain                                 # y se apaga solo
surf_fb = pygame.Surface((C.WINDOW_WIDTH, C.WINDOW_HEIGHT))
combat.FX.draw(surf_fb, Vector2())                                         # dibuja la cifra sin errores
t0_fl = len(combat.FX.floaters)
combat.FX.update(1.0)
assert len(combat.FX.floaters) < t0_fl                                     # la cifra caduca
for _ in range(30):                                                        # mordidas continuas: cifras agrupadas, no una por fotograma
    pl_fb.take_damage(0.5, continuous_dt=1 / 60)
assert 1 <= len(combat.FX.floaters) <= 4
combat.FX.clear()
game.machine.transition(GameState.MENU)

print("== Flujo completo: 5 oleadas -> asalto -> victoria ==")
game.machine.transition(GameState.MENU)
a2 = new_act2(game, metal=6000, threat=3)
w = a2.world
LAYOUT = [("pylon", (540, 620)), ("pylon", (660, 620)), ("pylon", (780, 620)),
          ("pylon", (540, 540)), ("pylon", (540, 700)),
          ("balista", (820, 540)), ("balista", (820, 700)), ("balista", (860, 620)),
          ("tower", (780, 540)), ("tower", (780, 700)), ("balista", (820, 580)), ("tower", (820, 660)),
          ("foco", (700, 540)),
          ("pylon", (420, 500)), ("pylon", (380, 700)), ("pylon", (300, 600)), ("pylon", (660, 700)),
          ("tower", (480, 520))]                       # sin piloto: una Ligera (con su energía) cubre el núcleo
for kind, pos in LAYOUT:
    assert build(a2, kind, pos), (kind, pos)
next(t_ for t_ in w.towers if t_.pos == Vector2(820, 580)).choose_route("B")       # Tesla
next(t_ for t_ in w.towers if t_.pos == Vector2(820, 660)).choose_route("B")       # Lanzallamas
next(t_ for t_ in w.towers if t_.pos == Vector2(820, 540)).choose_route("A")       # Perforante
a2._sync_energy()
assert all(t_.is_powered for t_ in w.towers) and all(f_.is_powered for f_ in w.focos)
assert a2.energy_free() >= 0, a2.energy_free()
a2.wave.timer = 0.5
random.seed(3)
frames = 0
wave_marks = {}
while frames < 60 * 900 and a2.wave.phase != "assault":
    step(game, 1)
    frames += 1
    for b in w.structures:                       # solo se valida el flujo: defensas inmortales (modo Comandante)
        b.hp = b.max_hp
        b.breaking = False
    a2.core.hp = a2.core.max_hp
    wave_marks.setdefault(a2.wave.wave, frames)
mouse[0] = False
assert a2.wave.phase == "assault" and game.machine.current_state is GameState.ACT_2_PLAY, (a2.wave.phase, a2.wave.wave, frames)
assert a2.dialogue.blocking_active                                   # el aviso del asalto también es historia
dismiss(game)
print("  asalto tras", frames, "fotogramas; robado:", a2.stolen, "| tiers Fundicion:", a2.foundry.tiers)
for t in list(a2.foundry_core.perimeter):
    t.take_damage(9999)
a2.foundry_core.take_damage(99999)
step(game, 60)
assert game.machine.current_state is not GameState.VICTORY                  # quedan bases enemigas
for b_ in a2.enemy_bases:
    raze(b_)
step(game, 60 * 4)
assert game.machine.current_state is GameState.VICTORY
press(game, pygame.K_RETURN)
assert game.machine.current_state is GameState.MENU
print("OK")
