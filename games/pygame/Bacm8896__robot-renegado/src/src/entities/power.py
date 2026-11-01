"""Red eléctrica: el Centro de Control y los pilones, con propagación BFS orientada a eventos."""
from collections import deque

import pygame
from pygame.math import Vector2

import config as C
from src.entities.building import Building
from src.ui import structure_art as art


def reaches(node_pos, rect, radius=None):
    """¿El círculo de red de un nodo en `node_pos` toca la huella `rect` de un edificio? (se mide al punto más cercano del
    edificio, no a su centro: lo que se ve dentro del círculo está conectado)."""
    radius = C.POWER_RADIUS if radius is None else radius
    cx = max(rect.left, min(node_pos.x, rect.right))
    cy = max(rect.top, min(node_pos.y, rect.bottom))
    return (node_pos.x - cx) ** 2 + (node_pos.y - cy) ** 2 <= radius * radius


class PowerPylon(Building):
    """Pilón: solo funciona (is_powered) si la cadena de pilones llega hasta una fuente."""

    def __init__(self, pos):
        super().__init__("pylon", pos)
        self.is_powered = False
        self.disabled_timer = 0.0         # sabotaje de un Carroñero Hostil: apagado y sin conducir energía
        self.grid = None                  # lo fija la escena al registrarlo (para recalcular la red)

    def sabotage(self, seconds):
        self.disabled_timer = max(self.disabled_timer, seconds)
        if self.grid is not None:
            self.grid.mark_dirty()

    def update(self, dt, enemies_group, bullets_group):
        super().update(dt, enemies_group, bullets_group)
        if self.disabled_timer > 0:
            self.disabled_timer -= dt
            if self.disabled_timer <= 0 and self.grid is not None:
                self.grid.mark_dirty()                # vuelve a conducir: apagón en cascada revertido

    def _render(self):
        return art.render_pylon(Building.SIZES["pylon"])

    def draw_dynamic(self, surface, screen_rect, offset):
        art.draw_pylon_top(surface, screen_rect.center, "ally", art.now(), self.is_powered)

    def draw_overlay(self, surface, screen_rect, offset):
        super().draw_overlay(surface, screen_rect, offset)
        if not self.is_powered:
            pygame.draw.circle(surface, C.RED, (screen_rect.centerx, screen_rect.top + 12), 4, 1)


class PowerGrid:
    """Calcula qué nodos y consumidores están energizados. BFS solo cuando cambia la red."""

    def __init__(self, world):
        self.world = world
        self.dirty = True
        self.links = []          # [(a, b, energizado)] entre nodos vecinos
        self.feeds = []          # [(consumidor, nodo)] consumidor alimentado por su nodo más cercano

    def mark_dirty(self):
        self.dirty = True

    def update(self):
        if self.dirty:
            self.recompute()

    def _sources(self):
        w = self.world
        return [w.core] if w.core is not None and w.core.alive() else []           # la única fuente: el Centro de Control

    def can_place_pylon(self, pos):
        """Un pilón solo se puede colocar dentro del alcance de un nodo ya energizado."""
        for node in self._sources() + [p for p in self.world.pylons if p.is_powered]:
            if node.pos.distance_to(pos) <= C.POWER_RADIUS:
                return True
        return False

    def recompute(self):
        w = self.world
        sources = self._sources()
        pylons = [p for p in w.pylons if p.alive()]
        for p in pylons:
            p.is_powered = False
        # BFS en anchura desde las fuentes a través de los pilones
        queue = deque(sources)
        while queue:
            current = queue.popleft()
            for p in pylons:
                if (not p.is_powered and p.disabled_timer <= 0
                        and current.pos.distance_to(p.pos) <= C.POWER_RADIUS):
                    p.is_powered = True
                    queue.append(p)
        powered_nodes = sources + [p for p in pylons if p.is_powered]
        self.links = []
        nodes = sources + pylons
        for i, a in enumerate(nodes):
            for b in nodes[i + 1:]:
                if a.pos.distance_to(b.pos) <= C.POWER_RADIUS:
                    self.links.append((a, b, a.is_powered and b.is_powered))
        # Consumidores (torretas, extractores...): conectados si el radio de un nodo energizado toca su huella; da igual en
        # qué punto de una cadena de pilones esté ese nodo (la cadena ya se propagó entera arriba)
        self.feeds = []
        walls = [b for b in w.walls if b.level >= 3]                  # solo el muro Electrificado usa la red
        consumers = list(w.towers) + list(w.extractors) + list(w.focos) + list(w.factories) + list(w.gates)
        for consumer in consumers + walls:
            near = [n for n in powered_nodes if reaches(n.pos, consumer.rect)]
            consumer.is_powered = bool(near)
            if near:
                self.feeds.append((consumer, min(near, key=lambda n: n.pos.distance_squared_to(consumer.pos))))
        self.dirty = False

    def draw(self, surface, offset):
        """Líneas neón cian en el suelo entre nodos enlazados (rojo tenue si están desconectados)."""
        t = art.now()
        for i, (a, b, powered) in enumerate(self.links):
            pa, pb = Vector2(a.pos) - offset, Vector2(b.pos) - offset
            if powered:
                art.draw_arc(surface, pa, pb, t, (0, 225, 255), seed=i)            # arco eléctrico animado
            else:
                art.draw_arc(surface, pa, pb, t, (110, 30, 40), seed=i, bright=False)
        for consumer, node in self.feeds:
            pygame.draw.line(surface, (0, 110, 90), Vector2(consumer.pos) - offset, Vector2(node.pos) - offset, 1)
