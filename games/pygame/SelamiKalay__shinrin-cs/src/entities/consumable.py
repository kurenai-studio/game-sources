"""
Shinrin CS — Tüketilebilir Eşya (Consumable) Sınıfı.

Item'dan türer. İyileştirici iksirler, mana restorasyonları
ve geçici buff'lar gibi tek kullanımlık eşyaları temsil eder.
"""

from __future__ import annotations

import pygame
from entities.item import Item
from utils.logger import get_logger

_logger = get_logger("Consumable")


class Consumable(Item):
    """
    Tek kullanımlık (tüketilebilir) eşya sınıfı.

    Item'a ek olarak:
    - İyileştirme miktarı (HP/MP)
    - Buff tipi ve süresi

    Polimorfizm:
        - use(): Hedefe iyileşme/buff uygular.
    """

    # ── Buff Tipleri ──
    BUFF_NONE = "none"
    BUFF_ATK_UP = "atk_up"
    BUFF_DEF_UP = "def_up"
    BUFF_SPD_UP = "spd_up"
    BUFF_REGEN = "regen"

    def __init__(self, item_id: str, name: str, description: str,
                 heal_amount: int = 0, mp_restore: int = 0,
                 buff_type: str = "none", buff_duration: float = 0.0,
                 value: int = 10, rarity: str = "common"):
        """
        Args:
            item_id: Benzersiz eşya ID'si.
            name: Tüketilecek eşyanın adı.
            description: Açıklaması.
            heal_amount: İyileştirilecek HP miktarı.
            mp_restore: Yenilenecek MP miktarı.
            buff_type: Buff efekti tipi.
            buff_duration: Buff süresi (saniye).
            value: Satış değeri.
            rarity: Nadirlik seviyesi.
        """
        super().__init__(
            item_id, name, description,
            value, rarity, stackable=True
        )

        # ── Private ──
        self._heal_amount: int = heal_amount
        self._mp_restore: int = mp_restore
        self._buff_type: str = buff_type
        self._buff_duration: float = buff_duration

        # Özel ikon
        self._icon = self._create_consumable_icon()

    # ══════════════════════════════════════════
    #  Polimorfik: use()
    # ══════════════════════════════════════════

    def use(self, target) -> None:
        """
        Tüketilebilir eşyayı hedefe uygular.

        Args:
            target: Hedef karakter (genellikle Player).
        """
        if self._heal_amount > 0 and hasattr(target, 'heal'):
            healed = target.heal(self._heal_amount)
            _logger.info("'%s' kullanıldı → %s +%d HP iyileşti.",
                         self._name, target.name, healed)

        if self._mp_restore > 0 and hasattr(target, 'restore_mp'):
            restored = target.restore_mp(self._mp_restore)
            _logger.info("'%s' kullanıldı → %s +%d MP yenilendi.",
                         self._name, target.name, restored)

        if self._buff_type != self.BUFF_NONE:
            _logger.info("'%s' buff uygulandı: %s (%.1f sn)",
                         self._name, self._buff_type, self._buff_duration)
            # İleride buff sistemi entegre edilecek

    # ══════════════════════════════════════════
    #  Properties
    # ══════════════════════════════════════════

    @property
    def heal_amount(self) -> int:
        return self._heal_amount

    @property
    def mp_restore(self) -> int:
        return self._mp_restore

    @property
    def buff_type(self) -> str:
        return self._buff_type

    @property
    def buff_duration(self) -> float:
        return self._buff_duration

    # ══════════════════════════════════════════
    #  Özel İkon
    # ══════════════════════════════════════════

    def _create_consumable_icon(self) -> pygame.Surface:
        """İksir şeklinde ikon oluşturur."""
        size = 24
        icon = pygame.Surface((size, size), pygame.SRCALPHA)

        # Şişe gövdesi
        if self._heal_amount > 0:
            liquid_color = (220, 50, 50)   # Kırmızı (HP)
        elif self._mp_restore > 0:
            liquid_color = (50, 100, 220)  # Mavi (MP)
        else:
            liquid_color = (50, 200, 100)  # Yeşil (buff)

        # Şişe şekli
        pygame.draw.rect(icon, (180, 180, 200),
                         (8, 3, 8, 4))            # Kapak
        pygame.draw.rect(icon, (200, 200, 220),
                         (6, 7, 12, 3))           # Boyun
        pygame.draw.rect(icon, liquid_color,
                         (4, 10, 16, 12))          # Gövde
        pygame.draw.rect(icon, (255, 255, 255, 80),
                         (6, 11, 3, 8))            # Parıltı

        return icon

    # ══════════════════════════════════════════
    #  Bilgi (genişletilmiş)
    # ══════════════════════════════════════════

    def get_info(self) -> dict:
        """Tüketilecek eşya bilgilerini döndürür."""
        info = super().get_info()
        info.update({
            'heal_amount': self._heal_amount,
            'mp_restore': self._mp_restore,
            'buff_type': self._buff_type,
            'buff_duration': self._buff_duration,
        })
        return info

    # ══════════════════════════════════════════
    #  Fabrika Metodu
    # ══════════════════════════════════════════

    @classmethod
    def from_data(cls, data: dict) -> Consumable:
        """JSON verisinden tüketilebilir eşya oluşturur."""
        return cls(
            item_id=data.get('id', 'unknown'),
            name=data.get('name', 'Bilinmeyen İksir'),
            description=data.get('description', ''),
            heal_amount=data.get('heal', 0),
            mp_restore=data.get('mp_restore', 0),
            buff_type=data.get('buff', 'none'),
            buff_duration=data.get('buff_duration', 0.0),
            value=data.get('value', 10),
            rarity=data.get('rarity', 'common')
        )
