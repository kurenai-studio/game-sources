"""
Shinrin CS — Ekipman (Equipment) Sınıfı.

Item'dan türer. Silah, zırh ve aksesuar gibi kuşanılabilir
eşyaları temsil eder. Stat bonusları ve özel efektler sağlar.
"""

from __future__ import annotations

import pygame
from entities.item import Item
from utils.logger import get_logger

_logger = get_logger("Equipment")


class Equipment(Item):
    """
    Kuşanılabilir ekipman sınıfı.

    Item'a ek olarak:
    - Ekipman slotu (weapon, armor, accessory)
    - Stat bonusları (ATK, DEF, SPD)
    - Özel efektler

    Polimorfizm:
        - use(): Ekipmanı kuşanma eylemi olarak uygular.
    """

    # ── Ekipman Slotları ──
    SLOT_WEAPON = "weapon"
    SLOT_ARMOR = "armor"
    SLOT_ACCESSORY = "accessory"

    def __init__(self, item_id: str, name: str, description: str,
                 slot: str = "weapon",
                 atk_bonus: int = 0, def_bonus: int = 0,
                 spd_bonus: int = 0, hp_bonus: int = 0,
                 special_effect: str = "",
                 value: int = 50, rarity: str = "common"):
        """
        Args:
            item_id: Benzersiz eşya ID'si.
            name: Ekipman adı.
            description: Açıklama.
            slot: Ekipman slotu ('weapon', 'armor', 'accessory').
            atk_bonus: Saldırı bonusu.
            def_bonus: Savunma bonusu.
            spd_bonus: Hız bonusu.
            hp_bonus: Ekstra HP bonusu.
            special_effect: Özel efekt açıklaması.
            value: Satış değeri.
            rarity: Nadirlik seviyesi.
        """
        super().__init__(
            item_id, name, description,
            value, rarity, stackable=False
        )

        # ── Private ──
        self._slot: str = slot
        self._atk_bonus: int = atk_bonus
        self._def_bonus: int = def_bonus
        self._spd_bonus: int = spd_bonus
        self._hp_bonus: int = hp_bonus
        self._special_effect: str = special_effect

        # Özel ikon
        self._icon = self._create_equipment_icon()

    # ══════════════════════════════════════════
    #  Polimorfik: use()
    # ══════════════════════════════════════════

    def use(self, target) -> None:
        """
        Ekipmanı kuşanmaya çalışır.

        Args:
            target: Hedef karakter (Player).
        """
        if hasattr(target, 'equip'):
            target.equip(self)
            _logger.info("'%s' kuşanıldı → slot '%s'",
                         self._name, self._slot)

    # ══════════════════════════════════════════
    #  Bonus Bilgisi
    # ══════════════════════════════════════════

    def get_bonuses(self) -> dict:
        """Tüm stat bonuslarını sözlük olarak döndürür."""
        return {
            'atk_bonus': self._atk_bonus,
            'def_bonus': self._def_bonus,
            'spd_bonus': self._spd_bonus,
            'hp_bonus': self._hp_bonus,
        }

    @property
    def slot(self) -> str:
        return self._slot

    @property
    def atk_bonus(self) -> int:
        return self._atk_bonus

    @property
    def def_bonus(self) -> int:
        return self._def_bonus

    @property
    def spd_bonus(self) -> int:
        return self._spd_bonus

    @property
    def hp_bonus(self) -> int:
        return self._hp_bonus

    @property
    def special_effect(self) -> str:
        return self._special_effect

    # ══════════════════════════════════════════
    #  Özel İkon
    # ══════════════════════════════════════════

    def _create_equipment_icon(self) -> pygame.Surface:
        """Slot tipine göre ikon oluşturur."""
        size = 24
        icon = pygame.Surface((size, size), pygame.SRCALPHA)
        color = self.rarity_color

        if self._slot == self.SLOT_WEAPON:
            # Kılıç şekli
            pygame.draw.line(icon, (180, 180, 200),
                             (12, 2), (12, 16), 3)     # Bıçak
            pygame.draw.line(icon, color,
                             (12, 2), (12, 14), 2)     # Bıçak (renkli)
            pygame.draw.rect(icon, (139, 90, 43),
                             (8, 16, 8, 3))             # Kabza
            pygame.draw.rect(icon, (100, 70, 30),
                             (10, 19, 4, 4))             # Tutamak

        elif self._slot == self.SLOT_ARMOR:
            # Zırh şekli
            pygame.draw.rect(icon, color,
                             (5, 4, 14, 14))            # Gövde
            pygame.draw.rect(icon, (255, 255, 255, 60),
                             (6, 5, 5, 6))              # Parıltı
            # Omuzlar
            pygame.draw.rect(icon, color,
                             (2, 4, 4, 6))
            pygame.draw.rect(icon, color,
                             (18, 4, 4, 6))

        elif self._slot == self.SLOT_ACCESSORY:
            # Yüzük / kolye şekli
            pygame.draw.circle(icon, color,
                               (12, 12), 8, 2)           # Halka
            pygame.draw.circle(icon, (255, 255, 255),
                               (12, 5), 3)               # Taş

        return icon

    # ══════════════════════════════════════════
    #  Bilgi (genişletilmiş)
    # ══════════════════════════════════════════

    def get_info(self) -> dict:
        """Ekipman bilgilerini döndürür."""
        info = super().get_info()
        info.update({
            'slot': self._slot,
            'atk_bonus': self._atk_bonus,
            'def_bonus': self._def_bonus,
            'spd_bonus': self._spd_bonus,
            'hp_bonus': self._hp_bonus,
            'special_effect': self._special_effect,
        })
        return info

    def get_tooltip(self) -> str:
        """Envanter tooltip metni oluşturur."""
        lines = [self._name]
        if self._atk_bonus:
            lines.append(f"  ATK +{self._atk_bonus}")
        if self._def_bonus:
            lines.append(f"  DEF +{self._def_bonus}")
        if self._spd_bonus:
            lines.append(f"  SPD +{self._spd_bonus}")
        if self._hp_bonus:
            lines.append(f"  HP  +{self._hp_bonus}")
        if self._special_effect:
            lines.append(f"  ★ {self._special_effect}")
        return "\n".join(lines)

    # ══════════════════════════════════════════
    #  Fabrika Metodu
    # ══════════════════════════════════════════

    @classmethod
    def from_data(cls, data: dict) -> Equipment:
        """JSON verisinden ekipman oluşturur."""
        return cls(
            item_id=data.get('id', 'unknown'),
            name=data.get('name', 'Bilinmeyen Ekipman'),
            description=data.get('description', ''),
            slot=data.get('slot', 'weapon'),
            atk_bonus=data.get('atk', 0),
            def_bonus=data.get('def', 0),
            spd_bonus=data.get('spd', 0),
            hp_bonus=data.get('hp', 0),
            special_effect=data.get('effect', ''),
            value=data.get('value', 50),
            rarity=data.get('rarity', 'common')
        )
