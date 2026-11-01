"""VULCANO: IA de mantenimiento vinculada al Centro de Control. Repara estructuras dañadas gastando metal."""
import math
import random

import pygame
from pygame.math import Vector2

import config as C
from src.config import UNITS as U
from src.entities import GameSprite
from src.mechanics import combat
from src.ui import structure_art as art


class Vulcano(GameSprite):
    layer = 5
    casts_shadow = True
    shadow_lift = 3                         # meca sobre orugas: la sombra pegada al suelo

    def __init__(self, pos):
        super().__init__()
        self.pos = Vector2(pos)
        self.t = 0.0
        self.debt = 0.0                     # metal fraccionario pendiente de cobrar
        self.repairing = []                 # estructuras que está reparando ahora
        self.target = None                  # la que está reparando (la termina antes de pasar a otra)
        self.hp = self.max_hp = 0           # solo en la mini-defensa del 1.4 (soldando la compuerta) se le puede dañar
        self.shield_time = 0.0              # 1.4: escudo de gracia al empezar a soldar (segundos que le quedan)
        self.weld_target = None             # punto que suelda (fijo, no se mueve)
        self.tread = 0.0                    # avance de los eslabones de las orugas
        self.arm_angle = 0.0                # hacia dónde apunta el brazo de soldadura (radianes)
        self.image = pygame.Surface((30, 30), pygame.SRCALPHA)
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))
        self._draw()

    def _draw(self):
        """Meca de forja pesado (vista cenital, 30x30 px: la hitbox no cambia): dos orugas con eslabones que avanzan, casco
        acorazado con placas y franja de advertencia, cúpula con el núcleo de fusión y un brazo de soldadura que apunta a su
        objetivo con electrodo dorado."""
        img = self.image
        img.fill((0, 0, 0, 0))
        working = bool(self.repairing) or self.weld_target is not None
        phase = int(self.tread) % 4
        for x0 in (1, 22):                                                  # orugas
            pygame.draw.rect(img, (24, 24, 28), (x0, 2, 7, 26), border_radius=2)
            pygame.draw.rect(img, (88, 88, 96), (x0, 2, 7, 26), 1, border_radius=2)
            for y in range(3 + phase, 27, 4):                               # eslabones
                pygame.draw.line(img, (62, 62, 70), (x0 + 1, y), (x0 + 5, y))
            pygame.draw.circle(img, (110, 110, 118), (x0 + 3, 5), 2)        # ruedas guía
            pygame.draw.circle(img, (110, 110, 118), (x0 + 3, 25), 2)
        hull = pygame.Rect(7, 4, 16, 22)                                    # casco acorazado
        pygame.draw.rect(img, (66, 68, 78), hull, border_radius=3)
        pygame.draw.rect(img, (112, 114, 126), hull, 1, border_radius=3)
        pygame.draw.rect(img, (46, 48, 58), (hull.x + 2, hull.y + 10, hull.w - 4, 5))          # placa central
        for i in range(0, hull.w - 3, 4):                                   # franja de advertencia del frente
            pygame.draw.rect(img, (232, 190, 40) if (i // 4) % 2 == 0 else (30, 30, 30), (hull.x + 2 + i, hull.y + 1, 4, 3))
        for rx, ry in ((hull.x + 2, hull.y + 8), (hull.right - 3, hull.y + 8), (hull.x + 2, hull.bottom - 4),
                       (hull.right - 3, hull.bottom - 4)):
            pygame.draw.circle(img, (176, 178, 190), (rx, ry), 1)           # remaches
        ang = self.arm_angle
        tip_color = (255, 235, 150) if working and int(self.t * 14) % 2 == 0 else (212, 175, 55)
        base = (15 + round(math.cos(ang) * 6), 15 + round(math.sin(ang) * 6))
        tip = (15 + round(math.cos(ang) * 14), 15 + round(math.sin(ang) * 14))
        pygame.draw.line(img, (74, 74, 80), (15, 15), base, 4)              # brazo articulado
        pygame.draw.line(img, (150, 150, 158), base, tip, 2)
        pygame.draw.circle(img, tip_color, tip, 2)
        pulse = 0.5 + 0.5 * math.sin(self.t * 4)
        pygame.draw.circle(img, (30, 30, 34), (15, 15), 6)                  # cúpula con el núcleo
        pygame.draw.circle(img, (140, 70, 0), (15, 15), 5)
        pygame.draw.circle(img, (255, 149, 0), (15, 15), 3 + (1 if pulse > 0.5 else 0))
        pygame.draw.circle(img, (255, 230, 150), (15, 15), 1)

    def idle(self, dt, core):
        """Solo flota junto al Centro de Control (sin órdenes ni reparaciones pendientes)."""
        self.t += dt
        anchor = core.pos + Vector2(math.cos(self.t), math.sin(self.t)) * 62
        self._glide(anchor, dt)
        self._draw()

    def go_to(self, point, dt, stop=0.0):
        """Marcha hacia `point` a `C.VULCANO_SPEED` px/s (orugas y brazo animados) hasta quedar a `stop` px de él. Devuelve
        la distancia que aún le falta para llegar."""
        to = Vector2(point) - self.pos
        dist = to.length()
        remaining = dist - stop
        if remaining > 0.5:
            step = min(remaining, C.VULCANO_SPEED * dt)
            self.pos += to / dist * step
            self.tread += step / 3
            self.arm_angle = math.atan2(to.y, to.x)
            self.rect.center = (round(self.pos.x), round(self.pos.y))
            remaining -= step
        return remaining if remaining > 0.5 else 0.0                       # menos de medio píxel: ya llegó

    def command_update(self, dt, world, resources, sites):
        """Fase de mando de la Base Central (VULCANO constructor autónomo). Prioridades: 1) reparar lo crítico (Núcleo, red
        activa, muros y compuertas: niveles 0-2); 2) los sitios de obra de la cola: va hasta el primero que pueda avanzar y
        ensambla a `repair_rate` HP/s pagando la chatarra a medida que avanza; 3) el resto de reparaciones; si no, flota junto
        al Núcleo. Devuelve (estado, sitio_terminado) con estado: repairing | moving | building | waiting_scrap |
        waiting_repair | idle."""
        target = self.choose_target(world)
        if target is not None and self.priority_tier(target) <= 2:           # lo crítico va primero: las obras esperan
            self.update(dt, world, resources)
            return ("repairing" if self.repairing else "waiting_repair"), None
        if sites:
            self.t += dt
            self.repairing = []
            ready = [s for s in sites if s.can_progress(resources)]
            site = (ready or sites)[0]
            stop = C.VULCANO_WORK_RANGE + max(site.rect.size) / 2
            if self.go_to(site.pos, dt, stop) > 0:
                self._draw()
                return "moving", None
            to = site.pos - self.pos
            if to.length_squared() > 1:
                self.arm_angle = math.atan2(to.y, to.x)
            outcome = site.advance(dt, C.VULCANO_REPAIR_RATE, resources)
            if outcome != "waiting":
                self.repairing = [site]
            self._draw()
            return ("waiting_scrap" if outcome == "waiting" else "building"), (site if outcome == "done" else None)
        if target is not None:
            self.update(dt, world, resources)
            return ("repairing" if self.repairing else "idle"), None
        self.idle(dt, world.core)
        return "idle", None

    def _glide(self, anchor, dt):
        """Se desplaza hacia `anchor`; las orugas avanzan con la distancia recorrida y el brazo mira hacia donde va."""
        step = (anchor - self.pos) * min(1.0, dt * 5)
        self.pos += step
        self.tread += step.length() / 3
        if step.length_squared() > 0.01:
            self.arm_angle = math.atan2(step.y, step.x)
        self.rect.center = (round(self.pos.x), round(self.pos.y))

    # --- 1.4: soldando la compuerta (punto fijo, vulnerable) ---
    def start_welding(self, anchor, target, hp, shield=0.0):
        """Empieza a soldar en `anchor`: queda vulnerable con `hp` de vida, salvo los primeros `shield` s (gracia)."""
        self.shield_time = float(shield)
        self.pos = Vector2(anchor)
        self.rect.center = (round(self.pos.x), round(self.pos.y))
        self.weld_target = Vector2(target)
        self.arm_angle = math.atan2(self.weld_target.y - self.pos.y, self.weld_target.x - self.pos.x)
        self.hp = self.max_hp = hp
        self.repairing = []

    def stop_welding(self):
        """Compuerta reparada: deja de soldar (sigue en pie, ya no es vulnerable)."""
        self.weld_target = None
        self.max_hp = 0
        self.shield_time = 0.0
        self._draw()

    def weld(self, dt):
        """Suelda sin moverse: lluvia de chispas en la compuerta, el casco humea y el núcleo pulsa. El escudo de gracia
        solo se gasta mientras suelda (los diálogos que pausan la escena no lo consumen)."""
        self.t += dt
        self.shield_time = max(0.0, self.shield_time - dt)
        if int(self.t * 10) % 3 == 0:
            combat.FX.spark(self.weld_target + Vector2(random.uniform(-6, 6), random.uniform(-14, 14)), (255, 200, 90))
        if random.random() < dt * 9:
            combat.FX.spark(self.weld_target + Vector2(random.uniform(-10, 10), random.uniform(-20, 20)), (255, 240, 170))
        self._draw()

    def take_damage(self, amount, direction=None):
        if self.max_hp <= 0:
            return False                     # fuera de la mini-defensa es intocable
        if self.shield_time > 0:             # escudo de gracia: el golpe rebota
            if random.random() < 0.2:
                combat.FX.spark(self.pos, (110, 200, 255))
            return False
        self.hp = max(0.0, self.hp - amount)
        self.flash()
        return self.hp <= 0

    @staticmethod
    def priority_tier(structure):
        """0 Centro de Control · 1 red activa (pilones y torretas) · 2 bloqueo (muros y compuertas) · 3 el resto."""
        kind = getattr(structure, "building_type", "")
        for tier, kinds in enumerate(U.VULCANO["priority"]):
            if kind in kinds:
                return tier
        return len(U.VULCANO["priority"])

    def pending(self, world):
        """Estructuras que esperan reparación: bajaron del 50% (y siguen marcadas hasta quedar completas)."""
        out = []
        for s in world.structures:
            if not getattr(s, "repairable", False) or not s.alive():
                continue
            if s.hp < s.max_hp * C.VULCANO_THRESHOLD:
                s.vulcano_repairing = True
            if getattr(s, "vulcano_repairing", False):
                if s.hp >= s.max_hp:
                    s.vulcano_repairing = False
                else:
                    out.append(s)
        return out

    def choose_target(self, world):
        """La de mayor prioridad (nivel más bajo) y, dentro del nivel, la de menor vida proporcional. Termina la que
        empezó (no salta de una a otra cada fotograma) salvo que aparezca otra de un nivel más prioritario."""
        cands = self.pending(world)
        if not cands:
            self.target = None
            return None
        best = min(cands, key=lambda s: (self.priority_tier(s), s.hp / s.max_hp))
        current = getattr(self, "target", None)
        if current in cands and self.priority_tier(current) <= self.priority_tier(best):
            return current
        self.target = best
        return best

    def update(self, dt, world, resources):
        """Auto-reparación pasiva: UNA estructura a la vez (cola de prioridad) a 40 HP/s, pagando chatarra con dt.
        Con la chatarra en la reserva (25) o por debajo, se detiene en seco: nunca la deja negativa ni la agota."""
        self.t += dt
        self.repairing = []
        target = self.choose_target(world)
        reserve = C.VULCANO_SCRAP_RESERVE
        if target is not None and resources.metal > reserve:
            amount = min(C.VULCANO_REPAIR_RATE * dt, target.max_hp - target.hp)
            debt = self.debt + amount * C.VULCANO_METAL_PER_HP
            whole = int(debt)
            if resources.metal - whole >= reserve:                 # el pago no cruza la reserva básica
                if whole > 0:
                    resources.spend_metal(whole)
                self.debt = debt - whole
                target.repair(amount)
                self.repairing.append(target)
        # revolotea junto al Centro de Control o sobre lo que repara
        anchor = (self.repairing[0].pos + Vector2(0, -34) if self.repairing
                  else (world.core.pos + Vector2(math.cos(self.t), math.sin(self.t)) * 62
                        if world.core is not None else self.pos))
        self._glide(anchor, dt)
        if self.repairing:
            to = self.repairing[0].pos - self.pos
            if to.length_squared() > 1:
                self.arm_angle = math.atan2(to.y, to.x)                     # el brazo apunta a lo que repara
        self._draw()

    def draw_overlay(self, surface, screen_rect, offset):
        """Reparando: haz de energía cian parpadeante desde el electrodo hasta la estructura, con chispas por el camino.
        Soldando (1.4): haz hacia la compuerta y barra de vida encima."""
        if self.weld_target is not None:
            target = self.weld_target - offset
            tip = Vector2(screen_rect.center) + Vector2(14 if target.x >= screen_rect.centerx else -14, 0)
            if int(self.t * 18) % 3 != 0:
                art.draw_arc(surface, tip, target, self.t, (255, 190, 80), seed=7)
        if self.weld_target is not None or self.repairing:                  # humo de los escapes de la forja
            for k in range(3):
                phase = (self.t * 0.9 + k / 3) % 1.0
                x = screen_rect.centerx - 9 + math.sin(self.t * 2 + k * 2) * 3
                y = screen_rect.top + 2 - phase * 22
                shade = round(120 - 70 * phase)
                pygame.draw.circle(surface, (shade, shade, shade + 6), (round(x), round(y)), 2 + int(phase * 3))
        if self.max_hp > 0:
            bar = pygame.Rect(screen_rect.centerx - 28, screen_rect.top - 12, 56, 6)
            pygame.draw.rect(surface, (40, 0, 0), bar)
            low = self.hp <= self.max_hp * U.VULCANO_DEFENSE["low_hp_warning"]
            pygame.draw.rect(surface, C.RED if low else C.ORANGE,
                             (bar.x, bar.y, int(bar.w * self.hp / self.max_hp), bar.h))
            pygame.draw.rect(surface, C.WHITE, bar, 1)
        if self.shield_time > 0 and (self.shield_time > 1.0 or int(self.t * 12) % 2 == 0):   # parpadea al acabarse
            pygame.draw.circle(surface, (110, 200, 255), screen_rect.center, max(screen_rect.w, screen_rect.h) // 2 + 10, 2)
        for k, s in enumerate(self.repairing):
            target = Vector2(s.pos) - offset
            tip = Vector2(screen_rect.center) + Vector2(14 if target.x >= screen_rect.centerx else -14, 0)
            if int(self.t * 18) % 3 != 0:                                  # parpadeo
                art.draw_arc(surface, tip, target, self.t, (0, 235, 255), seed=k)
            rng = random.Random(int(self.t * 25) + k)
            for _ in range(3):
                q = tip + (target - tip) * rng.random() + Vector2(rng.uniform(-5, 5), rng.uniform(-5, 5))
                pygame.draw.circle(surface, (255, 255, 255) if rng.random() < 0.4 else (0, 235, 255), (round(q.x), round(q.y)), 2)
