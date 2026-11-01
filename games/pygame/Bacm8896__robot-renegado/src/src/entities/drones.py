"""Drones aliados: los cuatro tipos de la Fábrica de Drones (F1 Explorador, F2 Asalto, F3 Bombardero y F4 Soldado) y el dron AURA.

Las cifras salen de UNITS.DRONE_TYPES (con las mejoras permanentes ya sumadas por la Fábrica) y UNITS.DRONES (AURA).
Todos viven en `world.drones`: los enemigos pueden dispararles. Los de la Fábrica no reaparecen.

Capas: los drones AÉREOS (Explorador, Asalto, Bombardero) son inmunes al daño de contacto de los enemigos terrestres, pero los
proyectiles, los obuses y las torretas enemigas sí los alcanzan. El Soldado Dron es TERRESTRE: choca con el terreno y las
estructuras, cruza las Compuertas aliadas con energía y recibe también el contacto cuerpo a cuerpo."""
import math

import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.entities import GameSprite
from src.entities.projectile import Projectile
from src.mechanics import combat
from src.ui.combat_feedback import health_bar


class _Drone(GameSprite):
    layer = 3
    casts_shadow = True
    shadow_lift = 14
    kind = ""
    activity = "Patrullando"           # estado operativo que muestra su tooltip (lo actualiza cada tipo en update)

    def __init__(self, pos, stats=None):
        super().__init__()
        self.stats = stats if stats is not None else U.DRONES[self.kind]
        self.pos = Vector2(pos)
        self.hp = self.max_hp = self.stats["hp"]
        self.t = 0.0
        self.image = self._render()
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))

    def _render(self):
        raise NotImplementedError

    @property
    def display_name(self):
        return self.stats.get("name", self.kind)

    def take_damage(self, amount, direction=None):
        self.hp -= amount
        self.flash()
        if self.hp <= 0:
            self.kill()
            return True
        return False

    def _follow(self, dest, dt, stiffness=7.0):
        self.pos += (dest - self.pos) * min(1.0, dt * stiffness)
        self.rect.center = (round(self.pos.x), round(self.pos.y))

    @staticmethod
    def _anchor(world):
        """Punto que protege el dron: el operador, o el Centro de Control si cayó."""
        if world.player is not None and world.player.alive():
            return Vector2(world.player.pos)
        return Vector2(world.core.pos) if world.core is not None else None

    def draw_overlay(self, surface, screen_rect, offset):
        if self.hp < self.max_hp:
            bar = pygame.Rect(screen_rect.left, screen_rect.top - 6, screen_rect.w, 3)
            pygame.draw.rect(surface, (40, 0, 0), bar)
            pygame.draw.rect(surface, C.CYAN, (bar.x, bar.y, int(bar.w * max(0, self.hp) / self.max_hp), 3))


class FactoryDrone(_Drone):
    """Dron fabricado: `stats` es la copia de UNITS.DRONE_TYPES[tipo] con su mejora permanente sumada."""
    COLOR = (200, 200, 200)
    ICON = "?"
    order = None                       # Attack-Move (asedio): punto al que marcha atacando lo hostil que encuentre por el camino
    order_arrived = False              # llegó al punto: hace guardia allí atacando lo que alcance, hasta la siguiente orden
    route = ()                         # ruta (puntos de paso) de los drones terrestres hacia ese punto
    route_timer = 0.0
    focus = None                       # foco prioritario (clic der. sobre un hostil con el dron seleccionado)

    def __init__(self, pos, stats, home=None):
        self.home = Vector2(home if home is not None else pos)       # la Fábrica: punto de reunión
        self.speed = stats["speed"]
        super().__init__(pos, stats)

    @property
    def drone_type(self):
        return self.kind

    @property
    def display_name(self):
        """Nombre y clase: "Dron de Asalto Mk.I" (Mk.II con la mejora permanente o de recompensa)."""
        return f"{self.stats['name']} Mk.{'II' if self.stats.get('mk', 1) > 1 else 'I'}"

    @property
    def aerial(self):
        """Capa aérea (UNITS "layer": "air"): inmune al daño de contacto de los enemigos terrestres."""
        return self.stats.get("layer") == "air"

    def take_damage(self, amount, direction=None):
        """Proyectiles, obuses y torretas dañan a todos; la armadura plana (Soldado Dron) se resta de cada impacto."""
        armor = self.stats.get("armor", 0)
        if armor:
            amount = max(1.0, amount - armor)
        return super().take_damage(amount, direction)

    def _nearest_target(self, world):
        """El enemigo (o carroñero) vivo más cercano dentro del radio de enfrentamiento de la Fábrica de origen."""
        r2 = self.stats["engage_radius"] ** 2
        foes = [e for e in world.targets if e.alive() and self.home.distance_squared_to(e.pos) <= r2]
        return min(foes, key=lambda e: self.pos.distance_squared_to(e.pos)) if foes else None

    # --- Attack-Move (asedio) ---
    def give_order(self, point, route=()):
        """Marcha hacia `point` atacando lo hostil que encuentre (enemigos y estructuras). Al llegar, se queda de guardia allí."""
        self.order, self.route = Vector2(point), [Vector2(p) for p in route]
        self.order_arrived, self.route_timer = False, 2.0

    def give_focus(self, target):
        """Foco prioritario: persigue a `target` y lo ataca antes que a nada hasta destruirlo; después, guardia allí."""
        self.focus = target
        self.give_order(target.pos)

    def _track_focus(self):
        """El punto de la orden sigue al blanco del foco; al caer el blanco, el dron queda de guardia donde está."""
        f = self.focus
        if f is None:
            return
        if not f.alive() or getattr(f, "dead", False):
            self.focus = None
            self.order, self.order_arrived = Vector2(self.pos), True
            return
        self.order, self.order_arrived = Vector2(f.pos), False

    def _order_foe(self, world, reach):
        """Blanco de la orden, dentro de `reach`: el foco prioritario si lo hay; si no, el Generador de Escudo si el núcleo
        está blindado, luego enemigos y torretas/factoría; muros y extractores al final. Un núcleo con escudo activo se
        ignora (el escudo absorbe todo)."""
        f = self.focus
        if (f is not None and f.alive() and not getattr(f, "shielded", False)
                and f.pos.distance_squared_to(self.pos) <= reach * reach):
            return f
        best, best_key = None, None
        r2 = reach * reach
        for group, base_tier in ((world.targets, 0), (world.hostile, 1)):
            for s in group:
                if not s.alive() or s.pos.distance_squared_to(self.pos) > r2:
                    continue
                if getattr(s, "shielded", False):
                    continue
                kind = getattr(s, "kind", "")
                tier = 2 if base_tier and kind in ("muro", "pilon", "extractor") else base_tier
                if kind == "generador":
                    tier = -1
                key = (tier, s.pos.distance_squared_to(self.pos))
                if best_key is None or key < best_key:
                    best, best_key = s, key
        return best

    def _order_visible(self, world, foe):
        """¿Hay línea de tiro hasta `foe`? Los muros del nivel (Obstacle) la cortan."""
        return not any(b.rect.clipline(self.pos, foe.pos) for b in world.solids if type(b).__name__ == "Obstacle")

    def _render(self):
        img = pygame.Surface((26, 26), pygame.SRCALPHA)
        pts = [(13 + 11 * math.cos(math.pi / 8 + i * math.pi / 4), 13 + 11 * math.sin(math.pi / 8 + i * math.pi / 4))
               for i in range(8)]                                          # octágono con el color del tipo
        pygame.draw.polygon(img, tuple(c // 5 for c in self.COLOR), pts)
        pygame.draw.polygon(img, self.COLOR, pts, 2)
        self._icon(img)
        return img

    def _icon(self, img):
        pygame.draw.circle(img, C.WHITE, (13, 13), 3)

    def _move_to(self, point, dt, stop=0.0):
        to = Vector2(point) - self.pos
        d = to.length()
        if d > stop + 1:
            self.pos += to / d * min(self.speed * dt, d - stop)
            self.rect.center = (round(self.pos.x), round(self.pos.y))

    def draw_overlay(self, surface, screen_rect, offset):
        if self.hp < self.max_hp:                                           # barra de vida verde / naranja / roja
            health_bar(surface, self, pygame.Rect(screen_rect.left, screen_rect.top - 8, screen_rect.w, 4),
                       self.hp / self.max_hp)


class ReconDrone(FactoryDrone):
    """F1 Explorador (aéreo, logística con riesgo): detecta la chatarra del suelo, vuela a por ella, la guarda en su buffer
    (`carried_scrap`) y vuelve en línea recta al Centro de Control para depositarla en las reservas. Si lo derriban en tránsito
    suelta lo que llevaba donde cae. Sin chatarra a la vista, patrulla lejos de la base revelando 400 px de niebla. El
    tope de Exploradores por mapa lo aplica la Fábrica (EXPLORER_CAP)."""
    kind = "recon"
    COLOR = (100, 200, 255)

    def __init__(self, pos, stats, home=None):
        self.carried_scrap = 0                     # chatarra que transporta (se pierde en el suelo si lo derriban)
        self.goal = None                           # el montón de chatarra al que vuela
        self.scan_timer = 0.0
        self.on_collect = None                     # callback(valor): deposita en las reservas globales
        self.on_drop = None                        # callback(valor, pos): suelta la carga al ser destruido
        super().__init__(pos, stats, home)
        self.scan_range = stats["scan_range"]

    def _icon(self, img):
        pygame.draw.circle(img, self.COLOR, (13, 13), 5, 1)
        pygame.draw.circle(img, C.WHITE, (13, 13), 2)

    @property
    def reveal_radius(self):
        return self.stats["vision_range"]

    def take_damage(self, amount, direction=None):
        dead = super().take_damage(amount, direction)
        if dead and self.carried_scrap > 0:        # penalización: la carga cae al suelo
            value, self.carried_scrap = self.carried_scrap, 0
            if self.on_drop:
                self.on_drop(value, Vector2(self.pos))
        return dead

    def _scan(self, world):
        """El montón de chatarra más cercano a la vista que no esté ya asignado a otro Explorador."""
        claimed = {id(d.goal) for d in world.drones if d is not self and isinstance(d, ReconDrone) and d.goal is not None}
        best, best_d = None, self.scan_range ** 2
        for s in world.scraps:
            if not s.alive() or id(s) in claimed:
                continue
            d = self.pos.distance_squared_to(s.pos)
            if d <= best_d:
                best, best_d = s, d
        return best

    def update(self, dt, world):
        self.t += dt
        if self.carried_scrap > 0:                 # regreso directo al Centro de Control
            self.activity = f"Regresando con {self.carried_scrap} de chatarra"
            core = world.core
            if core is None or not core.alive():
                return
            self._move_to(core.pos, dt)
            if self.pos.distance_to(core.pos) <= 40:
                value, self.carried_scrap = self.carried_scrap, 0
                if self.on_collect:
                    self.on_collect(value)
            return
        self.scan_timer -= dt
        if self.scan_timer <= 0 and (self.goal is None or not self.goal.alive()):
            self.scan_timer = self.stats["scan_interval"]
            self.goal = self._scan(world)
        if self.goal is not None and self.goal.alive():
            self.activity = "Recogiendo chatarra"
            to = self.goal.pos - self.pos
            if to.length() <= max(self.speed * dt, self.stats["collect_radius"]):
                self.carried_scrap = int(self.goal.value)         # al buffer interno
                self.goal.kill()
                self.goal = None
            else:
                self._move_to(self.goal.pos, dt)
            return
        self.goal = None
        self.activity = "Patrullando"
        r = self.stats["patrol_radius"]
        a = self.t * self.speed / max(1, r) * 0.5
        self._move_to(self.home + Vector2(r * 1.4 + math.cos(a) * r, math.sin(a) * r), dt)

    def draw_overlay(self, surface, screen_rect, offset):
        super().draw_overlay(surface, screen_rect, offset)
        if self.carried_scrap > 0:                                          # carga visible bajo el dron
            pygame.draw.circle(surface, (190, 196, 210), (screen_rect.centerx, screen_rect.bottom + 4), 4)
            pygame.draw.circle(surface, (40, 44, 56), (screen_rect.centerx, screen_rect.bottom + 4), 2)


class AttackDrone(FactoryDrone):
    """F2 Dron de Asalto (aéreo): busca al enemigo más cercano a su Fábrica y lo hostiga con un láser continuo (12 de daño
    cada 0,5 s, alcance 190). Al ser aéreo, el contacto de los enemigos terrestres no le hace nada; los proyectiles sí."""
    kind = "attack"
    COLOR = (255, 100, 100)
    BEAM_HOLD = 0.12

    def __init__(self, pos, stats, home=None):
        self.fire_timer = 0.0
        self.beam_to = None                          # extremo del haz mientras apunta
        super().__init__(pos, stats, home)

    def _icon(self, img):
        pygame.draw.polygon(img, C.WHITE, [(19, 13), (9, 8), (9, 18)])

    @property
    def damage(self):
        return self.stats["damage"]

    def _order_step(self, dt, world):
        """Attack-Move: ataca lo que tenga a tiro por el camino; si no, sigue hacia el punto de la orden."""
        self.beam_to = None
        rng = self.stats["range"]
        target = self._order_foe(world, rng * 1.3)
        if target is not None:
            self.activity = "Atacando objetivo"
            self._move_to(target.pos, dt, stop=rng * 0.8)
            to = target.pos - self.pos
            if to.length() <= rng and to.length_squared() > 0:
                self.beam_to = Vector2(target.pos)
                if self.fire_timer <= 0:
                    target.take_damage(self.damage, to)
                    combat.FX.spark(target.pos, (255, 120, 120))
                    self.fire_timer = self.stats["shot_interval"]
            return True
        if self.order_arrived or self.pos.distance_to(self.order) < 40:
            self.order_arrived = True                                 # guardia en el punto: ataca lo que se acerque
            self.activity = "En guardia (orden de ataque)"
            return True
        self.activity = "Avanzando al punto de ataque"
        self._move_to(self.order, dt)
        return True

    def update(self, dt, world):
        self.t += dt
        self.fire_timer -= dt
        self._track_focus()
        if self.order is not None and self._order_step(dt, world):
            return
        target = self._nearest_target(world)
        self.beam_to = None
        if target is None:
            self.activity = "Patrullando"
            self._move_to(self.home + Vector2(math.cos(self.t), math.sin(self.t)) * 60, dt)
            return
        self.activity = "Atacando objetivo"
        rng = self.stats["range"]
        self._move_to(target.pos, dt, stop=rng * 0.8)
        to = target.pos - self.pos
        if to.length() <= rng and to.length_squared() > 0:
            self.beam_to = Vector2(target.pos)                            # haz láser continuo mientras tenga blanco
            if self.fire_timer <= 0:
                target.take_damage(self.damage, to)                       # impacto instantáneo (hitscan)
                combat.FX.spark(target.pos, (255, 120, 120))
                self.fire_timer = self.stats["shot_interval"]

    def draw_overlay(self, surface, screen_rect, offset):
        super().draw_overlay(surface, screen_rect, offset)
        if self.beam_to is not None:
            end = Vector2(self.beam_to) - offset
            pygame.draw.line(surface, (255, 60, 60), screen_rect.center, (round(end.x), round(end.y)), 2)
            pygame.draw.line(surface, (255, 200, 200), screen_rect.center, (round(end.x), round(end.y)), 1)


class Bomb(GameSprite):
    """Bomba del Bombardero en caída libre: cae durante `bomb_fall_time` s sobre su punto de suelta y explota con daño en área
    (75, radio 60) a los enemigos y carroñeros; nunca daña a los aliados."""
    layer = 5

    def __init__(self, pos, damage, radius, fall_time, hit_structures=False):
        super().__init__()
        self.hit_structures = hit_structures        # Attack-Move del asedio: la bomba también daña estructuras hostiles
        self.pos = Vector2(pos)
        self.damage, self.radius, self.fall_time = damage, radius, fall_time
        self.t_left = fall_time
        self.image = pygame.Surface((12, 12), pygame.SRCALPHA)
        pygame.draw.circle(self.image, (60, 60, 66), (6, 6), 5)
        pygame.draw.circle(self.image, (255, 170, 60), (6, 6), 5, 1)
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))

    def update(self, dt, world):
        self.t_left -= dt
        if self.t_left <= 0:
            self.explode(world)

    def explode(self, world):
        for e in list(world.targets) + (list(world.hostile) if self.hit_structures else []):
            if e.alive() and Vector2(e.pos).distance_to(self.pos) <= self.radius:
                e.take_damage(self.damage, None)
        combat.FX.blast(self.pos, self.radius, (255, 170, 60))
        combat.FX.request_shake()
        self.kill()

    def draw(self, surface, offset=None):
        off = Vector2() if offset is None else offset
        ground = Vector2(self.pos) - off
        k = max(0.0, self.t_left / self.fall_time)
        pygame.draw.circle(surface, (255, 170, 60), (round(ground.x), round(ground.y)), self.radius, 1)      # zona de impacto
        pygame.draw.circle(surface, (255, 120, 40), (round(ground.x), round(ground.y)),
                           max(2, round(self.radius * (1.0 - k))), 1)
        height = 70 * k                                                                   # la bomba cae desde arriba
        surface.blit(self.image, self.image.get_rect(center=(round(ground.x), round(ground.y - height))))


class BomberDrone(FactoryDrone):
    """F3 Dron Bombardero (aéreo): vuela hacia la mayor concentración de enemigos cercana a su Fábrica y, mientras sobrevuela
    a alguno, suelta una bomba en caída libre cada 2,5 s (75 de daño en un radio de 60 px)."""
    kind = "bomber"
    COLOR = (255, 170, 60)

    def __init__(self, pos, stats, home=None):
        self.bomb_timer = 0.0
        super().__init__(pos, stats, home)

    def _icon(self, img):
        pygame.draw.circle(img, C.WHITE, (13, 14), 4)
        pygame.draw.line(img, C.WHITE, (13, 6), (13, 10), 2)

    @property
    def bomb_damage(self):
        return self.stats["bomb_damage"]

    def _best_cluster(self, world):
        """El enemigo cuyo entorno de `bomb_radius` px reúne a más objetivos (a igualdad, el más cercano al dron)."""
        r2 = self.stats["engage_radius"] ** 2
        foes = [e for e in world.targets if e.alive() and self.home.distance_squared_to(e.pos) <= r2]
        if not foes:
            return None
        rad2 = self.stats["bomb_radius"] ** 2
        return max(foes, key=lambda e: (sum(1 for o in foes if o.pos.distance_squared_to(e.pos) <= rad2),
                                        -self.pos.distance_squared_to(e.pos)))

    def _order_step(self, dt, world):
        """Attack-Move: sobrevuela lo hostil (enemigos y estructuras) y lo bombardea; si no hay nada, avanza al punto."""
        reach = self.stats["bomb_radius"] * 0.9
        foe = self._order_foe(world, reach * 4)
        if foe is None:
            if self.order_arrived or self.pos.distance_to(self.order) < 40:
                self.order_arrived = True                             # guardia en el punto: bombardea lo que llegue
                self.activity = "En guardia (orden de ataque)"
                return True
            self.activity = "Avanzando al punto de ataque"
            self._move_to(self.order, dt)
            return True
        self.activity = "Bombardeando objetivo"
        self._move_to(foe.pos, dt)
        if self.bomb_timer <= 0 and foe.pos.distance_squared_to(self.pos) <= reach * reach:
            bomb = Bomb(self.pos, self.bomb_damage, self.stats["bomb_radius"], self.stats["bomb_fall_time"], hit_structures=True)
            world.bombs.add(bomb)
            world.all_sprites.add(bomb)
            self.bomb_timer = self.stats["bomb_cooldown"]
        return True

    def update(self, dt, world):
        self.t += dt
        self.bomb_timer -= dt
        self._track_focus()
        if self.order is not None and self._order_step(dt, world):
            return
        spot = self._best_cluster(world)
        if spot is None:
            self.activity = "Patrullando"
            self._move_to(self.home + Vector2(math.cos(self.t * 0.7), math.sin(self.t * 0.7)) * 80, dt)
            return
        self.activity = "Bombardeando objetivo"
        self._move_to(spot.pos, dt)                                          # sobrevuela la concentración
        if self.bomb_timer <= 0:
            reach2 = (self.stats["bomb_radius"] * 0.9) ** 2
            if any(e.alive() and e.pos.distance_squared_to(self.pos) <= reach2 for e in world.targets):
                bomb = Bomb(self.pos, self.bomb_damage, self.stats["bomb_radius"], self.stats["bomb_fall_time"])
                world.bombs.add(bomb)
                world.all_sprites.add(bomb)
                self.bomb_timer = self.stats["bomb_cooldown"]


class TrooperDrone(FactoryDrone):
    """F4 Soldado Dron (terrestre): avanza hacia el enemigo más cercano a su Fábrica, choca con el terreno y las estructuras
    (y las rodea) y cruza las Compuertas aliadas con energía; dispara un rifle de repetición (15 de daño cada 0,4 s, alcance
    160). Armadura 3. Como es terrestre, el contacto de los enemigos también le hace daño."""
    kind = "trooper"
    COLOR = (120, 255, 130)

    def __init__(self, pos, stats, home=None):
        self.fire_timer = 0.0
        self.stuck_time = 0.0
        self.side = 1                                # lado por el que rodea un obstáculo
        super().__init__(pos, stats, home)

    def _icon(self, img):
        pygame.draw.rect(img, C.WHITE, (9, 11, 9, 4))
        pygame.draw.rect(img, C.WHITE, (17, 12, 4, 2))

    @property
    def damage(self):
        return self.stats["damage"]

    def _blockers(self, world):
        """Lo que le cierra el paso: el terreno y las estructuras, salvo las Compuertas aliadas con energía."""
        return [b for b in world.solids if b is not self and not getattr(b, "ally_passable", False)]

    def _body(self):
        side = self.stats["body"]
        r = pygame.Rect(0, 0, side, side)
        r.center = (round(self.pos.x), round(self.pos.y))
        return r

    def _ground_step(self, point, dt, world, stop=0.0):
        """Un paso hacia `point` con colisión por ejes; si lleva un rato sin avanzar, rodea el obstáculo."""
        to = Vector2(point) - self.pos
        d = to.length()
        if d <= stop + 1:
            self.stuck_time = 0.0
            return
        heading = to / d
        if self.stuck_time > 0.35:                                         # atascado: desplazamiento lateral
            heading = (heading + Vector2(-heading.y, heading.x) * self.side * 1.6).normalize()
        move = heading * min(self.speed * dt, d - stop)
        blockers = [b.rect for b in self._blockers(world)]
        body = self._body()
        stuck_in = body.collidelist(blockers) != -1                         # si nació encima de algo, puede salir
        before = Vector2(self.pos)
        for axis in ("x", "y"):
            setattr(self.pos, axis, getattr(self.pos, axis) + getattr(move, axis))
            if stuck_in:
                continue
            probe = self._body()
            if probe.collidelist(blockers) != -1:
                setattr(self.pos, axis, getattr(self.pos, axis) - getattr(move, axis))
        self.rect.center = (round(self.pos.x), round(self.pos.y))
        if (self.pos - before).length() < 0.25 * move.length():
            self.stuck_time += dt
            if self.stuck_time > 1.2:
                self.stuck_time, self.side = 0.0, -self.side
        else:
            self.stuck_time = max(0.0, self.stuck_time - dt * 2)

    def _order_step(self, dt, world):
        """Attack-Move: dispara a lo que tenga a tiro; si no, sigue su ruta (puntos de paso por los pasos del mapa) al punto."""
        rng = self.stats["range"]
        target = self._order_foe(world, rng * 1.2)
        if target is not None and not self._order_visible(world, target):
            target = None                                             # no persigue a quien tiene un muro por medio
        if target is not None:
            self.activity = "Atacando objetivo"
            self._ground_step(target.pos, dt, world, stop=rng * 0.8)
            to = target.pos - self.pos
            if to.length() <= rng and self.fire_timer <= 0 and to.length_squared() > 0:
                world.bullets.add(Projectile(self.pos, to, self.damage, "ally", lifetime=rng * 1.3 / 500))
                self.fire_timer = self.stats["shot_interval"]
            return True
        self.activity = "En guardia (orden de ataque)" if self.order_arrived else "Avanzando al punto de ataque"
        if not self.order_arrived:
            self.route_timer -= dt
            level = getattr(world, "level", None)
            if self.route_timer <= 0 and level is not None:           # tras un combate se desvía: recalcula su ruta por los pasos
                self.route = level.waypoints(self.pos, self.order)
                self.route_timer = 2.0
            while self.route and self.pos.distance_to(self.route[0]) < 24:
                self.route.pop(0)
            if not self.route and self.pos.distance_to(self.order) < 50:
                self.order_arrived = True
                return True
            self._ground_step(self.route[0] if self.route else self.order, dt, world)
        return True

    def update(self, dt, world):
        self.t += dt
        self.fire_timer -= dt
        self._track_focus()
        if self.order is not None and self._order_step(dt, world):
            return
        target = self._nearest_target(world)
        if target is None:
            self.activity = "Patrullando"
            self._ground_step(self.home + Vector2(0, 70), dt, world, stop=30)
            return
        self.activity = "Atacando objetivo"
        rng = self.stats["range"]
        self._ground_step(target.pos, dt, world, stop=rng * 0.8)
        to = target.pos - self.pos
        if to.length() <= rng and self.fire_timer <= 0 and to.length_squared() > 0:
            world.bullets.add(Projectile(self.pos, to, self.damage, "ally", lifetime=rng * 1.3 / 500))
            self.fire_timer = self.stats["shot_interval"]


DRONE_CLASSES = {"recon": ReconDrone, "attack": AttackDrone, "bomber": BomberDrone, "trooper": TrooperDrone}


class AuraDrone(_Drone):
    """AURA en combate (chasis 6/6): unidad de combate que escolta al Operador (o patrulla el Centro de Control si no está),
    sale al paso de los enemigos cercanos y les dispara un láser (14 de daño cada 0,6 s, alcance 200). Cada 5 s emite
    además un pulso EMP de 100 px que aturde a Scouts y Soldados (-40% de movimiento durante 1,5 s); cada pulso gasta 2 de
    energía libre de la red: sin ella, espera. No reaparece: si cae, se pierde el resto del acto."""
    kind = "aura"
    display_name = "AURA · Dron de combate"

    def __init__(self, pos, energy_ok=None):
        self.energy_ok = energy_ok            # callable(coste) -> bool: ¿hay energía libre para el pulso?
        self.pulse_timer = 0.0
        self.pulse_visual = 0.0
        self.pulses = 0
        self.stunned_total = 0
        self.fire_timer = 0.0
        self.beam_to = None                   # extremo del láser mientras dispara
        self.shots = 0
        super().__init__(pos)
        self.pulse_timer = self.stats["pulse_interval"]

    def _render(self):
        img = pygame.Surface((26, 26), pygame.SRCALPHA)
        pts = [(13 + 11 * math.cos(i * math.pi / 3 + math.pi / 6), 13 + 11 * math.sin(i * math.pi / 3 + math.pi / 6))
               for i in range(6)]
        pygame.draw.polygon(img, (4, 30, 40), pts)
        pygame.draw.polygon(img, C.CYAN, pts, 2)
        pygame.draw.circle(img, (0, 150, 170), (13, 13), 6)
        pygame.draw.circle(img, (220, 255, 255), (13, 13), 3)
        return img

    @staticmethod
    def _escorting(world):
        player = getattr(world, "player", None)
        return player is not None and player.alive()

    def _home(self, world):
        """A quién protege: el Operador si está en el mapa; si no, el Centro de Control."""
        if self._escorting(world):
            return Vector2(world.player.pos)
        core = getattr(world, "core", None)
        return Vector2(core.pos) if core is not None else Vector2(self.pos)

    def _goal(self, world):
        """El enemigo más cercano a quien protege, dentro de su radio de patrulla; si no hay, junto a él (escolta)."""
        home = self._home(world)
        reach = (self.stats["patrol"] * 3) ** 2
        foes = [e for e in world.enemies if e.alive() and home.distance_squared_to(e.pos) <= reach]
        escort = self._escorting(world)
        self.activity = ("Interceptando enemigos" if foes else
                         "Escoltando al Operador" if escort else "Patrullando el Centro de Control")
        if foes:
            return min(foes, key=lambda e: home.distance_squared_to(e.pos)).pos
        r = self.stats["escort_radius"] if escort else 70
        return home + Vector2(math.cos(self.t * 0.7), math.sin(self.t * 0.7)) * r

    def _shoot(self, world):
        """Láser: el enemigo (o carroñero) vivo más cercano a su alcance. Devuelve el blanco alcanzado o None."""
        rng2 = self.stats["range"] ** 2
        foes = [e for group in (world.enemies, getattr(world, "scavengers", ())) for e in group
                if e.alive() and self.pos.distance_squared_to(e.pos) <= rng2]
        if not foes:
            return None
        target = min(foes, key=lambda e: self.pos.distance_squared_to(e.pos))
        to = target.pos - self.pos
        self.beam_to = Vector2(target.pos)
        if self.fire_timer <= 0 and to.length_squared() > 0:
            target.take_damage(self.stats["damage"], to)
            combat.FX.spark(target.pos, C.CYAN)
            self.fire_timer = self.stats["shot_interval"]
            self.shots += 1
        return target

    def _affected(self, world):
        r2 = self.stats["pulse_radius"] ** 2
        return [e for e in world.enemies if e.alive() and getattr(e, "enemy_type", "") in ("scout", "soldier")
                and self.pos.distance_squared_to(e.pos) <= r2]

    def pulse(self, world):
        """Pulso EMP: aturde a los Scouts y Soldados del radio. Devuelve cuántos afectó."""
        hit = self._affected(world)
        for e in hit:
            e.apply_slow(self.stats["stun_time"], self.stats["stun_slow"])
            combat.FX.spark(e.pos, C.CYAN)
        self.pulses += 1
        self.stunned_total += len(hit)
        self.pulse_visual = 0.4
        return len(hit)

    def update(self, dt, world):
        self.t += dt
        self.pulse_visual = max(0.0, self.pulse_visual - dt)
        self.fire_timer -= dt
        self.beam_to = None
        goal = self._goal(world)
        to = Vector2(goal) - self.pos
        step = self.stats["speed"] * dt
        if to.length() > 30:
            self.pos += to.normalize() * min(step, to.length() - 30)
            self.rect.center = (round(self.pos.x), round(self.pos.y))
        self._shoot(world)
        self.pulse_timer -= dt
        if self.pulse_timer <= 0:
            if not self._affected(world):
                self.pulse_timer = 0.0                       # nadie en rango: guarda el pulso (y la energía)
            elif self.energy_ok is None or self.energy_ok(self.stats["pulse_energy"]):
                self.pulse(world)
                self.pulse_timer = self.stats["pulse_interval"]
            else:
                self.pulse_timer = 1.0                       # sin energía libre: reintenta en 1 s

    def draw_overlay(self, surface, screen_rect, offset):
        super().draw_overlay(surface, screen_rect, offset)
        if self.beam_to is not None:                         # láser cian de AURA
            end = Vector2(self.beam_to) - offset
            pygame.draw.line(surface, (0, 200, 230), screen_rect.center, (round(end.x), round(end.y)), 2)
            pygame.draw.line(surface, (210, 255, 255), screen_rect.center, (round(end.x), round(end.y)), 1)
        if self.pulse_visual > 0:                            # onda EMP que se expande
            k = 1.0 - self.pulse_visual / 0.4
            r = int(self.stats["pulse_radius"] * k) + 4
            ring = pygame.Surface((r * 2 + 4, r * 2 + 4), pygame.SRCALPHA)
            pygame.draw.circle(ring, (0, 255, 255, int(200 * (1 - k))), (r + 2, r + 2), r, 3)
            surface.blit(ring, ring.get_rect(center=screen_rect.center))
