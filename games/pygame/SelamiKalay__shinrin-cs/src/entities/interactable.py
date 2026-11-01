"""
Shinrin CS — Etkileşilebilir Nesne (Interactable) Sınıfı.

Entity'den türer. Sandıklar, levhalar, kapılar, anahtarlar
gibi oyuncunun etkileşime girebileceği statik nesneleri
temsil eder.
"""

from __future__ import annotations

import pygame
from entities.entity import Entity
from utils.constants import TILE_SIZE, COLOR_GOLD
from utils.logger import get_logger

_logger = get_logger("Interactable")


class Interactable(Entity):
    """
    Etkileşilebilir dünya nesnesi sınıfı.

    Entity'ye ek olarak:
    - Etkileşim tipi (sandık, levha, kapı vb.)
    - Tek/çoklu etkileşim desteği
    - Olay tetikleme (event trigger)

    Polimorfizm:
        - interact(): Tipe göre farklı davranış.
    """

    # ── Etkileşim Tipleri ──
    TYPE_CHEST = "chest"
    TYPE_SIGN = "sign"
    TYPE_DOOR = "door"
    TYPE_SWITCH = "switch"
    TYPE_SAVE_POINT = "save_point"

    def __init__(self, name: str, x: float, y: float,
                 interaction_type: str = "chest",
                 trigger_event: str = "",
                 reusable: bool = False):
        """
        Args:
            name: Nesne adı.
            x, y: Pozisyon.
            interaction_type: Etkileşim tipi.
            trigger_event: Tetiklenecek olay adı.
            reusable: Birden fazla kez etkileşime girilebilir mi?
        """
        super().__init__(name, x, y, TILE_SIZE, TILE_SIZE)

        # ── Protected ──
        self._interaction_type: str = interaction_type
        self._is_interacted: bool = False
        self._reusable: bool = reusable
        self._trigger_event: str = trigger_event
        self._contents: list = []   # Sandık içeriği vb.
        self._message: str = ""     # Levha metni vb.

        # Placeholder sprite
        self._create_placeholder_sprite()

    # ══════════════════════════════════════════
    #  Placeholder Sprite
    # ══════════════════════════════════════════

    def _create_placeholder_sprite(self) -> None:
        """Tipe göre geçici sprite oluşturur."""
        size = TILE_SIZE
        sprite = pygame.Surface((size, size), pygame.SRCALPHA)

        if self._interaction_type == self.TYPE_CHEST:
            # Sandık
            pygame.draw.rect(sprite, (139, 90, 43),
                             (4, size // 3, size - 8, size // 2))
            pygame.draw.rect(sprite, (100, 65, 30),
                             (4, size // 3, size - 8, 4))
            # Kilit
            pygame.draw.circle(sprite, COLOR_GOLD,
                               (size // 2, size // 2 + 2), 3)

        elif self._interaction_type == self.TYPE_SIGN:
            # Levha
            pygame.draw.rect(sprite, (139, 115, 85),
                             (size // 2 - 2, size // 2, 4, size // 2))
            pygame.draw.rect(sprite, (180, 150, 100),
                             (4, size // 4, size - 8, size // 3))

        elif self._interaction_type == self.TYPE_DOOR:
            # Kapı
            pygame.draw.rect(sprite, (100, 70, 40),
                             (6, 2, size - 12, size - 4))
            pygame.draw.circle(sprite, COLOR_GOLD,
                               (size - 10, size // 2), 2)

        elif self._interaction_type == self.TYPE_SAVE_POINT:
            # Kayıt noktası (parlayan kristal)
            pygame.draw.polygon(sprite, (100, 200, 255), [
                (size // 2, 4),
                (size // 2 + 8, size // 2),
                (size // 2, size - 4),
                (size // 2 - 8, size // 2),
            ])
            pygame.draw.polygon(sprite, (200, 240, 255, 150), [
                (size // 2, 6),
                (size // 2 + 5, size // 2),
                (size // 2, size - 6),
                (size // 2 - 5, size // 2),
            ])

        else:
            # Genel etkileşilebilir nesne
            pygame.draw.rect(sprite, (150, 150, 100),
                             (4, 4, size - 8, size - 8))
            pygame.draw.rect(sprite, (200, 200, 150),
                             (4, 4, size - 8, size - 8), 2)

        self._sprite = sprite

    # ══════════════════════════════════════════
    #  Polimorfik: interact()
    # ══════════════════════════════════════════

    def interact(self, other) -> None:
        """
        Oyuncu ile etkileşim. Tipe göre farklı davranır:
        - chest: İçeriği verir.
        - sign: Mesajı gösterir.
        - door: Geçiş tetikler.
        - save_point: Kayıt yapar.

        Args:
            other: Etkileşime giren entity (Player).
        """
        if self._is_interacted and not self._reusable:
            _logger.debug("'%s' zaten etkileşime girilmiş.", self._name)
            return

        _logger.info("'%s' ile etkileşim (%s)",
                     self._name, self._interaction_type)

        if self._interaction_type == self.TYPE_CHEST:
            self._open_chest(other)

        elif self._interaction_type == self.TYPE_SIGN:
            _logger.info("Levha: '%s'", self._message)

        elif self._interaction_type == self.TYPE_SAVE_POINT:
            _logger.info("Kayıt noktası aktif!")

        self._is_interacted = True

        # Sandık açıldıysa sprite'ı güncelle
        if self._interaction_type == self.TYPE_CHEST and self._is_interacted:
            self._create_opened_chest_sprite()

    def _open_chest(self, other) -> None:
        """Sandığı açar ve içeriği oyuncuya verir."""
        if not self._contents:
            _logger.info("Sandık boş.")
            return

        for item in self._contents:
            if hasattr(other, 'add_item'):
                other.add_item(item)
                _logger.info("Sandıktan alındı: '%s'", item.name)

        self._contents.clear()

    def _create_opened_chest_sprite(self) -> None:
        """Açılmış sandık sprite'ı oluşturur."""
        size = TILE_SIZE
        sprite = pygame.Surface((size, size), pygame.SRCALPHA)
        # Açık sandık
        pygame.draw.rect(sprite, (120, 80, 40),
                         (4, size // 3 + 4, size - 8, size // 2 - 4))
        pygame.draw.rect(sprite, (139, 90, 43),
                         (4, size // 4, size - 8, size // 4))
        self._sprite = sprite

    # ══════════════════════════════════════════
    #  Ayarlar
    # ══════════════════════════════════════════

    def set_contents(self, items: list) -> None:
        """Sandık içeriğini ayarlar."""
        self._contents = items

    def set_message(self, message: str) -> None:
        """Levha mesajını ayarlar."""
        self._message = message

    def reset(self) -> None:
        """Etkileşimi sıfırlar (tekrar kullanılabilir hale getirir)."""
        self._is_interacted = False
        self._create_placeholder_sprite()

    @property
    def interaction_type(self) -> str:
        return self._interaction_type

    @property
    def is_interacted(self) -> bool:
        return self._is_interacted

    @property
    def trigger_event(self) -> str:
        return self._trigger_event

    @property
    def message(self) -> str:
        return self._message

    # ══════════════════════════════════════════
    #  Fabrika Metodu
    # ══════════════════════════════════════════

    @classmethod
    def from_data(cls, data: dict) -> Interactable:
        """JSON verisinden etkileşilebilir nesne oluşturur."""
        obj = cls(
            name=data.get('name', 'Object'),
            x=data.get('x', 0),
            y=data.get('y', 0),
            interaction_type=data.get('type', 'chest'),
            trigger_event=data.get('event', ''),
            reusable=data.get('reusable', False)
        )
        if 'message' in data:
            obj.set_message(data['message'])
        return obj
