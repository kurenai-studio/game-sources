"""
Shinrin CS — Oyuncu (Player) Sınıfı.

Character'dan türer. Envanter, ekipman, altın yönetimi ve
oyuncu hareketini içerir. Oyun boyunca kontrol edilen
ana karakterdir.
"""

from __future__ import annotations

import pygame
from entities.character import Character
from utils.constants import (
    TILE_SIZE, PLAYER_SPEED, PLAYER_ANIM_SPEED,
    DIR_UP, DIR_DOWN, DIR_LEFT, DIR_RIGHT,
    STATE_IDLE, STATE_WALKING, STATE_ATTACKING,
    COLOR_FOREST_GREEN, COLOR_SAKURA_PINK, COLOR_GOLD
)
from utils.logger import get_logger

_logger = get_logger("Player")


class Player(Character):
    """
    Oyuncu karakteri sınıfı.

    Character'ın tüm kapsüllenmiş özelliklerine ek olarak:
    - Envanter (private __inventory)
    - Ekipman slotları (private __equipment)
    - Görev günlüğü (private __quest_log)
    - Altın (private __gold)

    Polimorfizm:
        - level_up(): Dengeli stat artışı.
        - interact(): Karşıdaki entity'nin interact'ını tetikler.
        - update(): Hareket + animasyon.
    """

    # ── Varsayılan başlangıç istatistikleri ──
    DEFAULT_STATS = {
        'hp': 120,
        'mp': 60,
        'attack': 12,
        'defense': 8,
        'speed': 7,
    }

    def __init__(self, name: str = "Kaito", x: float = 0.0,
                 y: float = 0.0, stats: dict = None):
        super().__init__(
            name, x, y,
            stats or self.DEFAULT_STATS,
            TILE_SIZE, TILE_SIZE
        )

        # ══════════════════════════════════════
        #  PRIVATE — Oyuncu'ya özgü veriler
        # ══════════════════════════════════════
        self.__inventory: list = []          # Item listesi
        self.__inventory_capacity: int = 20
        self.__equipment: dict = {
            'weapon': None,
            'armor': None,
            'accessory': None,
        }
        self.__quest_log: list = []          # Aktif görevler
        self.__gold: int = 0

        # ── Hareket ──
        self._move_speed = PLAYER_SPEED
        self._is_moving: bool = False

        # ── Placeholder sprite oluştur ──
        self._create_placeholder_sprite()

        _logger.info("Oyuncu oluşturuldu: '%s' pos=(%s, %s)", name, x, y)

    # ══════════════════════════════════════════
    #  Placeholder Sprite (Asset gelene kadar)
    # ══════════════════════════════════════════

    def _create_placeholder_sprite(self) -> None:
        """Geçici oyuncu sprite'ı oluşturur (piksel karakter)."""
        size = TILE_SIZE
        sprite = pygame.Surface((size, size), pygame.SRCALPHA)

        # Gövde (koyu yeşil cübbe)
        body_rect = pygame.Rect(size // 4, size // 3, size // 2, size // 2)
        pygame.draw.rect(sprite, COLOR_FOREST_GREEN, body_rect)

        # Kafa (ten rengi)
        head_rect = pygame.Rect(
            size // 4 + 2, size // 6, size // 2 - 4, size // 4
        )
        pygame.draw.rect(sprite, (230, 190, 160), head_rect)

        # Saç (koyu)
        hair_rect = pygame.Rect(
            size // 4 + 1, size // 6 - 2, size // 2 - 2, size // 8
        )
        pygame.draw.rect(sprite, (40, 30, 25), hair_rect)

        # Gözler
        eye_y = size // 6 + size // 8
        pygame.draw.rect(sprite, (30, 30, 30),
                         (size // 3, eye_y, 2, 2))
        pygame.draw.rect(sprite, (30, 30, 30),
                         (size // 3 + size // 6, eye_y, 2, 2))

        self._sprite = sprite

    # ══════════════════════════════════════════
    #  Polimorfik: level_up()
    # ══════════════════════════════════════════

    def level_up(self) -> None:
        """
        Oyuncu seviye atladığında dengeli stat artışı uygular.
        (Character.gain_exp() tarafından çağrılır)
        """
        self._increase_stat('attack', 3)
        self._increase_stat('defense', 2)
        self._increase_stat('speed', 1)
        self._increase_max_hp(15)
        self._increase_max_mp(8)
        self.full_restore()
        _logger.info(
            "Oyuncu seviye atladı → Lv.%d | ATK:%d DEF:%d SPD:%d",
            self.level, self.attack, self.defense, self.speed
        )

    # ══════════════════════════════════════════
    #  Polimorfik: interact()
    # ══════════════════════════════════════════

    def interact(self, other) -> None:
        """
        Başka bir entity ile etkileşime girer.
        Karşıdaki entity'nin interact() metodunu çağırır.

        Args:
            other: Etkileşime girilecek entity.
        """
        if other is not None and hasattr(other, 'interact'):
            _logger.debug("Oyuncu '%s' ile etkileşime giriyor.", other.name)
            other.interact(self)

    # ══════════════════════════════════════════
    #  Hareket
    # ══════════════════════════════════════════

    def move(self, dx: int, dy: int, dt: float) -> None:
        """
        Oyuncuyu hareket ettirir.

        Args:
            dx: Yatay yön (-1, 0, 1).
            dy: Dikey yön (-1, 0, 1).
            dt: Delta time.
        """
        if not self.is_alive:
            return

        if dx == 0 and dy == 0:
            self._is_moving = False
            self._state = STATE_IDLE
            return

        self._is_moving = True
        self._state = STATE_WALKING

        # Yönü güncelle
        if dx < 0:
            self._direction = DIR_LEFT
        elif dx > 0:
            self._direction = DIR_RIGHT
        elif dy < 0:
            self._direction = DIR_UP
        elif dy > 0:
            self._direction = DIR_DOWN

        # Pozisyonu güncelle
        speed = self._move_speed * dt
        self._x += dx * speed
        self._y += dy * speed

    # ══════════════════════════════════════════
    #  Saldırı
    # ══════════════════════════════════════════

    def perform_attack(self, target: Character) -> int:
        """
        Hedefe saldırır.

        Args:
            target: Saldırılacak karakter.

        Returns:
            Verilen hasar miktarı.
        """
        if not self.is_alive:
            return 0

        # Ekipman bonusu
        bonus_atk = self._get_equipment_bonus('atk_bonus')
        total_atk = self.attack + bonus_atk

        damage = target.take_damage(total_atk)
        _logger.debug(
            "Oyuncu → %s saldırdı: %d hasar (ATK:%d + bonus:%d)",
            target.name, damage, self.attack, bonus_atk
        )
        return damage

    # ══════════════════════════════════════════
    #  Envanter Yönetimi (Kapsüllenmiş)
    # ══════════════════════════════════════════

    def add_item(self, item) -> bool:
        """
        Envantere eşya ekler.

        Args:
            item: Eklenecek Item nesnesi.

        Returns:
            True ise başarılı, False ise envanter dolu.
        """
        if len(self.__inventory) >= self.__inventory_capacity:
            _logger.warning("Envanter dolu! (%d/%d)",
                            len(self.__inventory), self.__inventory_capacity)
            return False

        self.__inventory.append(item)
        _logger.debug("Eşya eklendi: '%s'", item.name)
        return True

    def remove_item(self, item_id: str):
        """
        Envanterden eşya çıkarır.

        Args:
            item_id: Çıkarılacak eşyanın ID'si.

        Returns:
            Çıkarılan Item veya None.
        """
        for i, item in enumerate(self.__inventory):
            if item.item_id == item_id:
                removed = self.__inventory.pop(i)
                _logger.debug("Eşya çıkarıldı: '%s'", removed.name)
                return removed
        return None

    def use_item(self, item) -> bool:
        """
        Bir eşyayı kullanır (oyuncuya uygular).

        Args:
            item: Kullanılacak Item nesnesi.

        Returns:
            True ise kullanım başarılı.
        """
        if item in self.__inventory:
            item.use(self)
            self.__inventory.remove(item)
            _logger.debug("Eşya kullanıldı: '%s'", item.name)
            return True
        return False

    def get_inventory(self) -> list:
        """Envanterin kopyasını döndürür (orijinal korunur)."""
        return self.__inventory.copy()

    @property
    def inventory_count(self) -> int:
        return len(self.__inventory)

    @property
    def inventory_capacity(self) -> int:
        return self.__inventory_capacity

    def is_inventory_full(self) -> bool:
        return len(self.__inventory) >= self.__inventory_capacity

    # ══════════════════════════════════════════
    #  Ekipman Yönetimi (Kapsüllenmiş)
    # ══════════════════════════════════════════

    def equip(self, equipment) -> None:
        """
        Ekipman kuşanır.

        Args:
            equipment: Equipment nesnesi (slot bilgisi içerir).
        """
        slot = equipment.slot
        if slot not in self.__equipment:
            _logger.warning("Geçersiz ekipman slotu: '%s'", slot)
            return

        # Mevcut ekipmanı envantere geri koy
        if self.__equipment[slot] is not None:
            self.__inventory.append(self.__equipment[slot])

        self.__equipment[slot] = equipment
        # Envanterden çıkar
        if equipment in self.__inventory:
            self.__inventory.remove(equipment)

        _logger.info("Ekipman kuşanıldı: '%s' → slot '%s'",
                     equipment.name, slot)

    def unequip(self, slot: str) -> None:
        """
        Belirtilen slottaki ekipmanı çıkarır.

        Args:
            slot: 'weapon', 'armor', 'accessory'.
        """
        if slot in self.__equipment and self.__equipment[slot] is not None:
            item = self.__equipment[slot]
            self.__equipment[slot] = None
            self.__inventory.append(item)
            _logger.info("Ekipman çıkarıldı: '%s' ← slot '%s'",
                         item.name, slot)

    def get_equipment(self) -> dict:
        """Ekipman slotlarının kopyasını döndürür."""
        return self.__equipment.copy()

    def _get_equipment_bonus(self, bonus_type: str) -> int:
        """Tüm ekipmanlardan belirtilen bonus tipini toplar."""
        total = 0
        for item in self.__equipment.values():
            if item is not None and hasattr(item, 'get_bonuses'):
                bonuses = item.get_bonuses()
                total += bonuses.get(bonus_type, 0)
        return total

    # ══════════════════════════════════════════
    #  Görev Günlüğü (Kapsüllenmiş)
    # ══════════════════════════════════════════

    def add_quest(self, quest) -> None:
        """Görev günlüğüne yeni görev ekler."""
        self.__quest_log.append(quest)
        _logger.info("Görev eklendi: '%s'", quest.get('name', '?'))

    def complete_quest(self, quest_id: str) -> dict:
        """
        Görevi tamamlanmış olarak işaretler ve döndürür.

        Args:
            quest_id: Tamamlanan görevin ID'si.

        Returns:
            Tamamlanan görev verisi veya boş dict.
        """
        for i, q in enumerate(self.__quest_log):
            if q.get('id') == quest_id:
                quest = self.__quest_log.pop(i)
                _logger.info("Görev tamamlandı: '%s'", quest.get('name', '?'))
                return quest
        return {}

    def get_quest_log(self) -> list:
        """Görev günlüğünün kopyasını döndürür."""
        return self.__quest_log.copy()

    # ══════════════════════════════════════════
    #  Altın Yönetimi (Kapsüllenmiş)
    # ══════════════════════════════════════════

    def add_gold(self, amount: int) -> None:
        """Para ekler."""
        if amount > 0:
            self.__gold += amount
            _logger.debug("Altın eklendi: +%d → Toplam: %d",
                          amount, self.__gold)

    def spend_gold(self, amount: int) -> bool:
        """
        Para harcar.

        Args:
            amount: Harcanacak miktar.

        Returns:
            True ise yeterli para vardı ve harcandı.
        """
        if self.__gold >= amount:
            self.__gold -= amount
            _logger.debug("Altın harcandı: -%d → Kalan: %d",
                          amount, self.__gold)
            return True
        _logger.debug("Yetersiz altın: %d < %d", self.__gold, amount)
        return False

    @property
    def gold(self) -> int:
        return self.__gold

    # ══════════════════════════════════════════
    #  Güncelleme ve Çizim
    # ══════════════════════════════════════════

    def update(self, dt: float) -> None:
        """Oyuncu durumunu günceller."""
        super().update(dt)

    def draw(self, surface: pygame.Surface, camera=None) -> None:
        """Oyuncuyu çizer (placeholder sprite ile)."""
        if not self._visible or self._sprite is None:
            return

        if camera:
            screen_x, screen_y = camera.apply(self._x, self._y)
        else:
            screen_x, screen_y = self._x, self._y

        # Yenilmez iken yanıp sönme
        if self._invincible:
            import time
            if int(time.time() * 10) % 2 == 0:
                return

        surface.blit(self._sprite, (int(screen_x), int(screen_y)))

    # ══════════════════════════════════════════
    #  Serileştirme (genişletilmiş)
    # ══════════════════════════════════════════

    def to_dict(self) -> dict:
        """Oyuncu verisini serileştirilebilir sözlüğe çevirir."""
        data = super().to_dict()
        data['gold'] = self.__gold
        data['inventory_count'] = len(self.__inventory)
        data['quest_count'] = len(self.__quest_log)
        return data

    def to_save_data(self) -> dict:
        """
        Oyun kaydı için tam oyuncu verisini çıkarır.

        Returns:
            JSON-serializable dict.
        """
        return {
            'name': self._name,
            'x': self._x,
            'y': self._y,
            'level': self._level,
            'exp': self._exp,
            'hp': self.hp,
            'max_hp': self.max_hp,
            'mp': self.mp,
            'max_mp': self.max_mp,
            'attack': self.attack,
            'defense': self.defense,
            'speed': self.speed,
            'gold': self.__gold,
            'direction': self._direction,
            'quest_log': self.__quest_log.copy(),
        }

    def load_save_data(self, data: dict) -> None:
        """
        Kayıt verisinden oyuncu durumunu geri yükler.

        Args:
            data: to_save_data() ile oluşturulmuş dict.
        """
        self._name = data.get('name', self._name)
        self._x = data.get('x', self._x)
        self._y = data.get('y', self._y)
        self._level = data.get('level', self._level)
        self._exp = data.get('exp', self._exp)
        self._set_hp(data.get('hp', self.hp))
        self._set_max_hp(data.get('max_hp', self.max_hp))
        self._set_mp(data.get('mp', self.mp))
        self._set_max_mp(data.get('max_mp', self.max_mp))
        self._set_stat('attack', data.get('attack', self.attack))
        self._set_stat('defense', data.get('defense', self.defense))
        self._set_stat('speed', data.get('speed', self.speed))
        self.__gold = data.get('gold', 0)
        self._direction = data.get('direction', DIR_DOWN)
        self.__quest_log = data.get('quest_log', [])

        _logger.info(
            "Oyuncu verisi yüklendi: '%s' Lv.%d pos=(%.0f, %.0f)",
            self._name, self._level, self._x, self._y
        )
