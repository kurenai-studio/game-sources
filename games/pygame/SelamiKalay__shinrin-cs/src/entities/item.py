"""
Shinrin CS — Soyut Eşya (Item) Sınıfı.

Entity'den türer. Tüm eşya tiplerinin (Consumable, Equipment)
ortak atasıdır. Eşya bilgisi, nadirlik, ikon ve kullanım
arayüzünü tanımlar.
"""

from __future__ import annotations

from abc import abstractmethod
import pygame
from entities.entity import Entity
from utils.constants import TILE_SIZE, COLOR_GOLD
from utils.logger import get_logger

_logger = get_logger("Item")


class Item(Entity):
    """
    Tüm eşyaların soyut temel sınıfı.

    Entity'ye ek olarak:
    - Eşya ID'si ve açıklaması
    - Satış değeri ve nadirlik seviyesi
    - İkon görseli
    - Yığılabilirlik (stackable) desteği

    Alt sınıflar use() metodu EZMELİDİR.

    Attributes (Protected):
        _item_id (str): Benzersiz eşya tanımlayıcısı.
        _description (str): Eşya açıklaması.
        _value (int): Satış değeri (altın).
        _rarity (str): Nadirlik seviyesi.
        _icon (Surface): Envanter ikonu.
        _stackable (bool): Yığılabilir mi?
        _stack_count (int): Yığın sayısı.
    """

    # ── Nadirlik Seviyeleri ──
    RARITY_COMMON = "common"         # Yaygın (beyaz)
    RARITY_UNCOMMON = "uncommon"     # Seyrek (yeşil)
    RARITY_RARE = "rare"             # Nadir (mavi)
    RARITY_EPIC = "epic"             # Destansı (mor)
    RARITY_LEGENDARY = "legendary"   # Efsanevi (altın)

    # Nadirlik → renk eşlemesi
    RARITY_COLORS = {
        "common": (200, 200, 200),
        "uncommon": (80, 200, 80),
        "rare": (80, 130, 255),
        "epic": (180, 80, 255),
        "legendary": (255, 215, 0),
    }

    def __init__(self, item_id: str, name: str, description: str,
                 value: int = 0, rarity: str = "common",
                 stackable: bool = False,
                 x: float = 0.0, y: float = 0.0):
        """
        Args:
            item_id: Benzersiz eşya ID'si (ör: 'potion_hp_small').
            name: Eşya adı.
            description: Eşya açıklaması.
            value: Satış değeri.
            rarity: Nadirlik seviyesi.
            stackable: Yığılabilir mi?
            x, y: Dünya pozisyonu (dünyada yerdeyse).
        """
        # İkon boyutu (envanterda küçük gösterim)
        icon_size = 24
        super().__init__(name, x, y, icon_size, icon_size)

        # ── Protected ──
        self._item_id: str = item_id
        self._description: str = description
        self._value: int = value
        self._rarity: str = rarity
        self._icon: pygame.Surface = self._create_default_icon()
        self._stackable: bool = stackable
        self._stack_count: int = 1

    # ══════════════════════════════════════════
    #  Soyut Metot: Kullanım
    # ══════════════════════════════════════════

    @abstractmethod
    def use(self, target) -> None:
        """
        Eşyayı hedefe uygular.
        Alt sınıflar EZMELİDİR.

        Args:
            target: Eşyanın uygulanacağı karakter (genellikle Player).
        """
        pass

    # ══════════════════════════════════════════
    #  Polimorfik: interact()
    # ══════════════════════════════════════════

    def interact(self, other) -> None:
        """
        Oyuncu eşyayı yerden topladığında.

        Args:
            other: Etkileşime giren entity (Player).
        """
        if hasattr(other, 'add_item'):
            success = other.add_item(self)
            if success:
                self._active = False
                self._visible = False
                _logger.info("'%s' toplandı.", self._name)

    # ══════════════════════════════════════════
    #  Bilgi
    # ══════════════════════════════════════════

    def get_info(self) -> dict:
        """Eşya bilgilerini sözlük olarak döndürür."""
        return {
            'id': self._item_id,
            'name': self._name,
            'description': self._description,
            'value': self._value,
            'rarity': self._rarity,
            'stackable': self._stackable,
            'stack_count': self._stack_count,
        }

    @property
    def item_id(self) -> str:
        return self._item_id

    @property
    def description(self) -> str:
        return self._description

    @property
    def value(self) -> int:
        return self._value

    @property
    def rarity(self) -> str:
        return self._rarity

    @property
    def rarity_color(self) -> tuple:
        return self.RARITY_COLORS.get(self._rarity, (200, 200, 200))

    @property
    def stackable(self) -> bool:
        return self._stackable

    @property
    def stack_count(self) -> int:
        return self._stack_count

    @stack_count.setter
    def stack_count(self, value: int):
        self._stack_count = max(0, value)

    @property
    def icon(self) -> pygame.Surface:
        return self._icon

    # ══════════════════════════════════════════
    #  İkon Oluşturma
    # ══════════════════════════════════════════

    def _create_default_icon(self) -> pygame.Surface:
        """Nadirlik renginde varsayılan ikon oluşturur."""
        size = 24
        icon = pygame.Surface((size, size), pygame.SRCALPHA)
        color = self.RARITY_COLORS.get(self._rarity, (200, 200, 200))
        pygame.draw.rect(icon, color, (2, 2, size - 4, size - 4))
        pygame.draw.rect(icon, (255, 255, 255, 100),
                         (2, 2, size - 4, size - 4), 1)
        return icon

    def set_icon(self, surface: pygame.Surface) -> None:
        """Eşya ikonunu ayarlar."""
        self._icon = surface

    # ══════════════════════════════════════════
    #  Dünyada Çizim
    # ══════════════════════════════════════════

    def draw(self, surface: pygame.Surface, camera=None) -> None:
        """Eşyayı dünyada çizer (yerdeki eşyalar için)."""
        if not self._visible:
            return

        if camera:
            sx, sy = camera.apply(self._x, self._y)
        else:
            sx, sy = self._x, self._y

        # İkonu dünyada çiz
        surface.blit(self._icon, (int(sx), int(sy)))

        # Nadirlik parıltısı
        if self._rarity in ('rare', 'epic', 'legendary'):
            import math
            import time
            alpha = int(80 + 40 * math.sin(time.time() * 3))
            glow = pygame.Surface((28, 28), pygame.SRCALPHA)
            glow_color = (*self.rarity_color, alpha)
            pygame.draw.rect(glow, glow_color, (0, 0, 28, 28), 2)
            surface.blit(glow, (int(sx) - 2, int(sy) - 2))

    def __repr__(self) -> str:
        return (
            f"<{self.__class__.__name__} '{self._name}' "
            f"id={self._item_id} rarity={self._rarity}>"
        )
