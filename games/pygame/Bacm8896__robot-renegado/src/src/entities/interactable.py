"""Objetos del escenario con los que se interactúa (E), balizas y el módulo de AURA."""
import math
import time

import pygame
from pygame.math import Vector2

import config as C
from src.entities import GameSprite
from src.ui import entity_art, loot_art

_font = None


def _prompt_font():
    global _font
    if _font is None:
        _font = pygame.font.SysFont("consolas", 15, bold=True)
    return _font


class Interactable(GameSprite):
    """Objeto interactuable: E a menos de `radius` px ejecuta `on_interact(escena, objeto)`."""
    layer = 1
    dash_passable = False
    prompt_key = "E"                                     # lo que muestra el aviso: "[E] etiqueta" ("CLIC" en el modo Comandante)

    def __init__(self, pos, size, label, radius=C.INTERACT_RADIUS):
        super().__init__()
        self.pos = Vector2(pos)
        self.label = label
        self.radius = radius
        self.enabled = True
        self.near = False
        self.t = 0.0
        self.on_interact = None
        self.image = self._render(size)
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))

    def _render(self, size):
        raise NotImplementedError

    def can_interact(self, player):
        return self.enabled and self.pos.distance_to(player.pos) <= self.radius

    def interact(self, scene):
        if self.on_interact:
            self.on_interact(scene, self)

    def update(self, dt):
        self.t += dt

    def take_damage(self, amount):
        return False

    def draw_overlay(self, surface, screen_rect, offset):
        if self.near and self.enabled:
            img = _prompt_font().render(f"[{self.prompt_key}] {self.label}", True, C.YELLOW)
            r = img.get_rect(midbottom=(screen_rect.centerx, screen_rect.top - 6))
            surface.blit(img, r)


class LootCache(Interactable):
    """Alijo: caja blindada con el emblema de su contenido (`kind`: "scrap" | "plasma" | "supply"). Late con un halo del
    color del contenido para verse desde lejos; al saquearla (`enabled` pasa a False) se abre con una ráfaga de chispas
    y queda vacía con la tapa levantada."""
    casts_shadow = True
    SIZE = (50, 40)
    BURST = 0.6                                          # s que dura la ráfaga al abrirse
    progress = 0.0                                       # 0..1 de un hackeo en curso (cámara fuerte): aro blanco alrededor

    def __init__(self, pos, label, kind="scrap", size=SIZE):
        self.kind = kind
        self.accent = loot_art.ACCENT[kind]
        self.burst = 0.0
        self._opened = False
        self._size = size
        super().__init__(pos, size, label)

    def _render(self, size):
        return loot_art.render_crate(size, self.kind, opened=False)

    def update(self, dt):
        super().update(dt)
        self.burst = max(0.0, self.burst - dt)
        if self._opened == self.enabled:                 # se acaba de saquear: tapa levantada y ráfaga
            self._opened = not self.enabled
            self.image = loot_art.render_crate(self._size, self.kind, self._opened)
            if self._opened:
                self.burst = self.BURST

    def draw_overlay(self, surface, screen_rect, offset):
        center = (screen_rect.centerx, screen_rect.centery + 3)
        if self.enabled:
            loot_art.draw_glow(surface, center, 34, self.accent, 0.35 + 0.45 * (0.5 + 0.5 * math.sin(self.t * 3.2)))
        if self.burst > 0:
            loot_art.draw_open_burst(surface, center, 1.0 - self.burst / self.BURST, self.accent)
        if self.progress > 0 and self.enabled:
            ring = pygame.Rect(0, 0, 66, 66)
            ring.center = center
            pygame.draw.arc(surface, (255, 255, 255), ring, math.pi / 2, math.pi / 2 + math.tau * self.progress, 5)
        super().draw_overlay(surface, screen_rect, offset)


class SupplyCache(LootCache):
    """Alijo de rescate: da chatarra al interactuar (E) o simplemente al acercarse."""

    def __init__(self, pos, amount, label="Recoger suministros"):
        self.amount = amount
        super().__init__(pos, label, "supply")


class Locker(Interactable):
    """Estación del Exotraje: cabina de soporte con el exoesqueleto y el rifle iniciales. En stand-by (cables conectados,
    luz ámbar); al pulsar E suelta una ráfaga de vapor y chispas y queda abierta y desacoplada, con los cables sueltos."""
    BURST = 1.3                                         # segundos que dura la ráfaga de vapor y chispas

    def __init__(self, pos, size, label="Abrir alijo"):
        self.used = False
        self.burst = 0.0
        super().__init__(pos, size, label)

    def _render(self, size):
        return entity_art.render_exo_station(size, self.used)

    def use(self):
        self.enabled = False
        self.used = True
        self.burst = self.BURST
        self.image = self._render(self.rect.size)

    def update(self, dt):
        super().update(dt)
        self.burst = max(0.0, self.burst - dt)

    def draw_overlay(self, surface, screen_rect, offset):
        entity_art.draw_exo_lamp(surface, screen_rect, self.used, self.t)
        if self.burst > 0:
            entity_art.draw_exo_burst(surface, screen_rect, 1.0 - self.burst / self.BURST)
        super().draw_overlay(surface, screen_rect, offset)


class Hatch(Interactable):
    """Escotilla / puerta: sólida mientras está cerrada."""

    def __init__(self, pos, size, label="Abrir escotilla"):
        self.is_open = False
        super().__init__(pos, size, label)

    @property
    def state(self):
        """locked (faro rojo) | unlocked (cian: AURA la desbloqueó, sigue sellada) | open (hueco libre, faro verde)."""
        if not self.is_open:
            return "locked"
        return "unlocked" if self.enabled else "open"

    def _render(self, size):
        return entity_art.render_hatch(size, self.state)

    def draw_overlay(self, surface, screen_rect, offset):
        entity_art.draw_hatch_glow(surface, screen_rect, self.state, self.t)
        super().draw_overlay(surface, screen_rect, offset)

    def open(self, solids):
        """Abre el paso: deja de ser sólida."""
        self.is_open = True
        self.enabled = False
        self.image = self._render(self.rect.size)
        solids.remove(self)

    def unlock(self, label):
        """Se activa como punto de entrada (sigue siendo sólida): E para cruzarla."""
        self.is_open = True
        self.enabled = True
        self.label = label
        self.image = self._render(self.rect.size)


class Terminal(Interactable):
    """Consola / terminal con pantalla brillante."""

    def __init__(self, pos, size, label, color=C.CYAN):
        self.color = color
        super().__init__(pos, size, label)

    glow = 0.0                                          # brillo verde de la pantalla al interactuar (1 -> 0)

    def _render(self, size):
        return entity_art.render_terminal(size, self.color)

    def interact(self, scene):
        self.glow = 1.0
        super().interact(scene)

    def update(self, dt):
        super().update(dt)
        if self.glow > 0:
            self.glow = max(0.0, self.glow - dt / 0.9)

    def draw_overlay(self, surface, screen_rect, offset):
        if self.glow > 0:
            entity_art.draw_terminal_glow(surface, screen_rect, self.glow)
        super().draw_overlay(surface, screen_rect, offset)


class LinkConsole(Terminal):
    """Consola táctica de enlace con AURA (1.2): bastidor con LEDs parpadeantes, pantalla con forma de onda de audio cian y
    cables gruesos hacia el suelo. Fuera de línea hasta que cae el guardián; al pulsar E hay un destello de sincronización
    y un pulso de datos recorre los cables."""
    SYNC = 1.6                                           # s que dura el pulso de sincronización

    def __init__(self, pos, size, label):
        self._sync_start = None                          # reloj real: el pulso se ve aunque el diálogo pause el mundo
        self.linked = False
        super().__init__(pos, size, label, C.CYAN)

    @property
    def sync(self):
        """Intensidad del destello/pulso de sincronización: 1 al enlazar, 0 tras `SYNC` segundos."""
        return 0.0 if self._sync_start is None else max(0.0, 1.0 - (time.monotonic() - self._sync_start) / self.SYNC)

    def _render(self, size):
        return entity_art.render_link_console(size)

    @property
    def online(self):
        return self.enabled or self.linked

    def interact(self, scene):
        self.linked = True
        self._sync_start = time.monotonic()
        Interactable.interact(self, scene)

    def draw_overlay(self, surface, screen_rect, offset):
        entity_art.draw_link_console(surface, screen_rect, time.monotonic(), self.online, self.sync)
        Interactable.draw_overlay(self, surface, screen_rect, offset)


class Airlock(Hatch):
    """Esclusa de contención de la salida (1.2): pistones laterales y faro de estado. Roja y sellada hasta cumplir el
    objetivo; al abrirse se despresuriza (vapor por los pistones), las hojas se recogen y el faro pasa a verde."""
    VENT = 1.4                                           # s de vapor al despresurizar
    OPEN_TIME = 1.3                                      # s que tardan las hojas en recogerse

    def __init__(self, pos, size, label="Esclusa"):
        self._vent_start = None                          # reloj real: el vapor se ve aunque el diálogo pause el mundo
        self._open_start = None
        super().__init__(pos, size, label)

    @property
    def progress(self):
        """Apertura de las hojas 0 -> 1 (1 si la esclusa se abrió sin animación)."""
        if not self.is_open:
            return 0.0
        if self._open_start is None:
            return 1.0
        return min(1.0, (time.monotonic() - self._open_start) / self.OPEN_TIME)

    @property
    def vent(self):
        """Segundos de vapor que quedan (0 si no se ha abierto o ya terminó)."""
        return 0.0 if self._vent_start is None else max(0.0, self.VENT - (time.monotonic() - self._vent_start))

    def _render(self, size):
        if not self.is_open:
            return entity_art.render_airlock(size, "locked")
        p = self.progress
        if p >= 1.0:
            return entity_art.render_airlock(size, "open")
        return entity_art.render_airlock(size, "opening", max(1, int(p * entity_art.AIRLOCK_STEPS)))

    def _start_opening(self):
        self._open_start = self._vent_start = time.monotonic()

    def open(self, solids):
        self._start_opening()
        super().open(solids)

    def unlock(self, label):
        """Habilitada como punto de entrada (sigue siendo sólida): vapor, faro verde y hojas que se recogen."""
        self._start_opening()
        super().unlock(label)

    def draw(self, surface, offset=None):
        if self._open_start is not None and self.is_open and not getattr(self, "_anim_done", False):
            self.image = self._render(self.rect.size)
            self._anim_done = self.progress >= 1.0
        super().draw(surface, offset)

    def draw_overlay(self, surface, screen_rect, offset):
        entity_art.draw_airlock_glow(surface, screen_rect, self.state, time.monotonic())
        if self.vent > 0:
            entity_art.draw_airlock_vent(surface, screen_rect, 1.0 - self.vent / self.VENT)
        Interactable.draw_overlay(self, surface, screen_rect, offset)


class Beacon(GameSprite):
    """Plataforma de salida: pararse sobre ella completa el sub-acto o extrae de la incursión. Chevrones, barrido
    giratorio y aro pulsante en `color` (16 fotogramas cacheados)."""
    layer = 0
    EMBLEM = "arrow"
    FPS = 10

    def __init__(self, pos, radius=42, color=C.YELLOW):
        super().__init__()
        self.pos = Vector2(pos)
        self.radius = radius
        self.color = tuple(color)
        self.t = 0.0
        self._frame = None
        self._draw()
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))

    def contains(self, player):
        return self.pos.distance_to(player.pos) <= self.radius

    def _pad_color(self):
        return self.color

    def _draw(self):
        frame = int(self.t * self.FPS) % loot_art.PAD_FRAMES
        if frame != self._frame:
            self._frame = frame
            self.image = loot_art.pad_frame(self.radius, self._pad_color(), self.EMBLEM, frame)

    def update(self, dt):
        self.t += dt
        self._draw()


class PlasmaPoint(Beacon):
    """Extractor de plasma en una zona de riesgo: hay que mantenerse dentro para capturarlo (+5 Núcleos). El avance de
    la captura se dibuja como un arco blanco alrededor de la plataforma."""
    EMBLEM = "diamond"

    def __init__(self, pos, radius=70):
        self.progress = 0.0                  # 0..1 de la captura
        self.done = False
        self._was_done = False
        super().__init__(pos, radius, (0, 220, 255))

    def _pad_color(self):
        return (70, 92, 104) if self.done else self.color

    def update(self, dt):
        if self.done != self._was_done:      # al capturarse cambia el color: fuerza el repintado
            self._was_done = self.done
            self._frame = None
        super().update(dt)

    def draw_overlay(self, surface, screen_rect, offset):
        if self.progress > 0 and not self.done:
            rect = pygame.Rect(0, 0, self.radius * 2 - 6, self.radius * 2 - 6)
            rect.center = screen_rect.center
            pygame.draw.arc(surface, (255, 255, 255), rect, math.pi / 2, math.pi / 2 + math.tau * self.progress, 5)


class AuraModule(GameSprite):
    """Módulo de AURA en la sala de servidores: pulso cian."""
    layer = 1

    def __init__(self, pos):
        super().__init__()
        self.pos = Vector2(pos)
        self.t = 0.0
        self.image = pygame.Surface((56, 56), pygame.SRCALPHA)
        self.rect = self.image.get_rect(center=(round(self.pos.x), round(self.pos.y)))
        self._draw()

    def _draw(self):
        img = self.image
        img.fill((0, 0, 0, 0))
        pulse = 0.5 + 0.5 * math.sin(self.t * 4)
        pygame.draw.circle(img, (*C.CYAN, int(40 + 70 * pulse)), (28, 28), 27)
        pygame.draw.rect(img, (8, 40, 44), (14, 14, 28, 28))
        pygame.draw.rect(img, C.CYAN, (14, 14, 28, 28), 2)
        pygame.draw.circle(img, C.WHITE, (28, 28), 4)

    def update(self, dt):
        self.t += dt
        self._draw()

    def take_damage(self, amount):
        return False
