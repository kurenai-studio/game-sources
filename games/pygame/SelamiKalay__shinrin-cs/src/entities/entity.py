"""
Shinrin CS — Soyut Entity Sınıfı.

GameObject'ten türer. İsim, sprite, animasyon ve
çarpışma kutusu ekler. Tüm oyun içi varlıklar
(Character, Item, Interactable) bu sınıftan türer.
"""

from __future__ import annotations

from abc import abstractmethod
import pygame
from entities.game_object import GameObject
from utils.constants import TILE_SIZE


class Entity(GameObject):
    """
    Oyun dünyasındaki tüm varlıkların soyut sınıfı.

    GameObject'e ek olarak:
    - İsim ve sprite yönetimi
    - Animasyon durumu
    - Çarpışma algılama
    - Etkileşim arayüzü

    Attributes:
        _name (str): Varlık adı.
        _sprite (Surface | None): Mevcut çizim görseli.
        _animation_state (str): Animasyon durumu.
        _animation_frames (dict): Durum → kare listesi.
        _animation_index (float): Geçerli kare indeksi.
        _animation_speed (float): Animasyon hızı (saniye/kare).
        _collision_rect (Rect): Çarpışma dikdörtgeni.
    """

    def __init__(self, name: str, x: float = 0.0, y: float = 0.0,
                 width: int = TILE_SIZE, height: int = TILE_SIZE):
        super().__init__(x, y, width, height)

        # ── Protected ──
        self._name: str = name
        self._sprite: pygame.Surface | None = None
        self._animation_state: str = "idle"
        self._animation_frames: dict[str, list[pygame.Surface]] = {}
        self._animation_index: float = 0.0
        self._animation_speed: float = 0.15  # saniye/kare

        # Çarpışma kutusu (varsayılan: görselin alt yarısı)
        self._collision_rect: pygame.Rect = pygame.Rect(
            int(x), int(y + height // 2),
            width, height // 2
        )

    # ══════════════════════════════════════════
    #  Soyut Metot: Etkileşim
    # ══════════════════════════════════════════

    @abstractmethod
    def interact(self, other: 'Entity') -> None:
        """
        Başka bir entity ile etkileşim.
        Alt sınıflar bu metodu EZMELİDİR.

        Args:
            other: Etkileşime giren diğer entity.
        """
        pass

    # ══════════════════════════════════════════
    #  Animasyon
    # ══════════════════════════════════════════

    def set_animation(self, state: str) -> None:
        """
        Animasyon durumunu değiştirir.

        Args:
            state: Yeni animasyon durumu (örn: "walk_down").
        """
        if state != self._animation_state and state in self._animation_frames:
            self._animation_state = state
            self._animation_index = 0.0

    def add_animation(self, state: str, frames: list[pygame.Surface]) -> None:
        """
        Bir animasyon durumu için kare listesi ekler.

        Args:
            state: Animasyon durumu adı.
            frames: Bu durumun kare listesi.
        """
        self._animation_frames[state] = frames

    def _update_animation(self, dt: float) -> None:
        """Animasyon karesini ilerletir."""
        frames = self._animation_frames.get(self._animation_state)
        if not frames:
            return

        self._animation_index += dt / self._animation_speed
        if self._animation_index >= len(frames):
            self._animation_index = 0.0

        self._sprite = frames[int(self._animation_index)]

    # ══════════════════════════════════════════
    #  Çarpışma
    # ══════════════════════════════════════════

    def get_collision_rect(self) -> pygame.Rect:
        """Güncel çarpışma dikdörtgenini döndürür."""
        self._collision_rect.x = int(self._x)
        self._collision_rect.y = int(self._y + self._height // 2)
        return self._collision_rect

    def collides_with(self, other: 'Entity') -> bool:
        """
        Başka bir entity ile çarpışıp çarpışmadığını kontrol eder.

        Args:
            other: Kontrol edilecek diğer entity.

        Returns:
            True ise çarpışma var.
        """
        return self.get_collision_rect().colliderect(
            other.get_collision_rect()
        )

    def on_collision(self, other: 'Entity') -> None:
        """
        Çarpışma gerçekleştiğinde çağrılır.
        Alt sınıflar gerekirse ezer.

        Args:
            other: Çarpışılan entity.
        """
        pass  # Varsayılan: işlem yok

    # ══════════════════════════════════════════
    #  Sprite Yönetimi
    # ══════════════════════════════════════════

    def load_sprite(self, surface: pygame.Surface) -> None:
        """
        Tek bir sprite yükler (animasyonsuz nesneler için).

        Args:
            surface: Yüklenecek görsel.
        """
        self._sprite = surface
        self._width = surface.get_width()
        self._height = surface.get_height()

    @property
    def name(self) -> str:
        return self._name

    # ══════════════════════════════════════════
    #  Varsayılan update / draw
    # ══════════════════════════════════════════

    def update(self, dt: float) -> None:
        """Entity'nin animasyonunu günceller."""
        if not self._active:
            return
        self._update_animation(dt)

    def draw(self, surface: pygame.Surface, camera=None) -> None:
        """
        Entity'yi ekrana çizer.

        Args:
            surface: Çizim yüzeyi.
            camera: Opsiyonel kamera (dünya→ekran dönüşümü).
        """
        if not self._visible or self._sprite is None:
            return

        if camera:
            screen_x, screen_y = camera.apply(self._x, self._y)
        else:
            screen_x, screen_y = self._x, self._y

        surface.blit(self._sprite, (screen_x, screen_y))

    def __repr__(self) -> str:
        return (
            f"<{self.__class__.__name__} '{self._name}' "
            f"pos=({self._x:.1f}, {self._y:.1f}) "
            f"state={self._animation_state}>"
        )
