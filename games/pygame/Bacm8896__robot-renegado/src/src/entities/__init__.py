"""Base común de las entidades y contenedor de referencias compartidas."""
import pygame
from pygame.math import Vector2

import config as C

_ZERO = Vector2()


class GameSprite(pygame.sprite.Sprite):
    """Sprite con draw(surface, offset) y hit-flash (blanco puro durante 2 frames)."""
    layer = 1
    flash_frames = 0
    casts_shadow = False          # proyecta sombra de contacto en el suelo (lo activan Operador, enemigos, drones, estructuras)
    shadow_lift = 0               # px que la sombra se separa del sprite: los voladores flotan sobre ella

    def flash(self):
        self.flash_frames = C.HIT_FLASH_FRAMES

    def _white_image(self):
        cached = getattr(self, "_white_cache", None)
        if cached is not None and cached[0] is self.image:           # misma imagen: reutiliza la silueta blanca
            return cached[1]
        mask = pygame.mask.from_surface(self.image)
        white = mask.to_surface(setcolor=(255, 255, 255, 255), unsetcolor=(0, 0, 0, 0))
        self._white_cache = (self.image, white)
        return white

    def draw(self, surface, offset=None):
        offset = _ZERO if offset is None else offset
        r = self.rect.move(-round(offset.x), -round(offset.y))
        if self.flash_frames > 0:
            surface.blit(self._white_image(), r)
            self.flash_frames -= 1
        else:
            surface.blit(self.image, r)
        self.draw_overlay(surface, r, offset)

    def draw_overlay(self, surface, screen_rect, offset):
        pass


class WorldRefs:
    """Referencias compartidas (grupos, jugador, núcleo, red eléctrica...) para ally, ruinas y drones."""

    def __init__(self, **kwargs):
        self.player = None
        self.core = None
        self.bounds = pygame.Rect(0, 0, C.WINDOW_WIDTH, C.WINDOW_HEIGHT)
        self.all_sprites = pygame.sprite.Group()
        self.enemies = pygame.sprite.Group()
        self.scavengers = pygame.sprite.Group()
        self.targets = pygame.sprite.Group()      # enemigos + carroñeros (objetivos de torres y drones)
        self.scraps = pygame.sprite.Group()
        self.parts = pygame.sprite.Group()        # componentes del chasis de AURA
        self.structures = pygame.sprite.Group()   # estructuras del jugador (incluye el núcleo)
        self.towers = pygame.sprite.Group()
        self.walls = pygame.sprite.Group()
        self.gates = pygame.sprite.Group()        # Compuertas Blindadas
        self.vulcano = None                       # V.U.L.C.A.N.O. (aliado que también abre las Compuertas)
        self.pylons = pygame.sprite.Group()
        self.extractors = pygame.sprite.Group()
        self.deposits = pygame.sprite.Group()
        self.bosses = pygame.sprite.Group()       # jefes con daño direccional (Ariete Ligero)
        self.hostile = pygame.sprite.Group()      # estructuras de la Fundición Renegada
        self.solids = pygame.sprite.Group()       # bloquean al jugador: propias + hostiles
        self.drones = pygame.sprite.Group()       # drones aliados: los de la Fábrica y el dron AURA
        self.factories = pygame.sprite.Group()    # Fábrica de Drones (una por base)
        self.core_items = pygame.sprite.Group()    # Núcleos de Plasma en el suelo
        self.ammo_boxes = pygame.sprite.Group()    # cajas de munición en el suelo
        self.medkits = pygame.sprite.Group()       # botiquines en el suelo
        self.shells = pygame.sprite.Group()       # obuses del tanque en vuelo
        self.bombs = pygame.sprite.Group()        # bombas de los Drones Bombarderos en caída libre
        self.focos = pygame.sprite.Group()        # Focos Vigía (radar)
        self.bullets = pygame.sprite.Group()      # balas del jugador, torres y drones
        self.enemy_bullets = pygame.sprite.Group()
        self.spawn_guards = None
        self.__dict__.update(kwargs)
