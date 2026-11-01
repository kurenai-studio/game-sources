"""
Shinrin CS — Yardımcı Fonksiyonlar.

Oyun genelinde kullanılan ortak yardımcı araçlar.
"""

import math
import pygame
from utils.constants import TILE_SIZE


def pixel_to_tile(x: float, y: float) -> tuple:
    """Piksel koordinatını tile koordinatına çevirir."""
    return int(x // TILE_SIZE), int(y // TILE_SIZE)


def tile_to_pixel(tx: int, ty: int) -> tuple:
    """Tile koordinatını piksel koordinatına çevirir."""
    return tx * TILE_SIZE, ty * TILE_SIZE


def distance(x1: float, y1: float, x2: float, y2: float) -> float:
    """İki nokta arasındaki Öklidyen mesafeyi hesaplar."""
    return math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2)


def clamp(value: float, min_val: float, max_val: float) -> float:
    """Bir değeri belirtilen aralıkta sınırlar."""
    return max(min_val, min(max_val, value))


def lerp(a: float, b: float, t: float) -> float:
    """Doğrusal interpolasyon (Linear Interpolation)."""
    return a + (b - a) * clamp(t, 0.0, 1.0)


def create_surface_with_alpha(width: int, height: int) -> pygame.Surface:
    """Alpha kanallı boş bir Surface oluşturur."""
    surface = pygame.Surface((width, height), pygame.SRCALPHA)
    return surface


def draw_text(
    surface: pygame.Surface,
    text: str,
    x: int, y: int,
    font: pygame.font.Font,
    color: tuple = (255, 255, 255),
    shadow: bool = False,
    shadow_color: tuple = (0, 0, 0),
    center: bool = False
) -> pygame.Rect:
    """
    Metin çizer. Opsiyonel gölge ve ortalama desteği.

    Returns:
        Metnin çizildiği Rect alanı.
    """
    if shadow:
        shadow_surf = font.render(text, True, shadow_color)
        if center:
            shadow_rect = shadow_surf.get_rect(center=(x + 2, y + 2))
        else:
            shadow_rect = shadow_surf.get_rect(topleft=(x + 2, y + 2))
        surface.blit(shadow_surf, shadow_rect)

    text_surf = font.render(text, True, color)
    if center:
        text_rect = text_surf.get_rect(center=(x, y))
    else:
        text_rect = text_surf.get_rect(topleft=(x, y))
    surface.blit(text_surf, text_rect)
    return text_rect
