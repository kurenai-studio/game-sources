"""
Shinrin CS — Düşman (Enemy) Sınıfı.

Character'dan türer. AI davranışı, loot tablosu ve
ödül sistemi içerir. Farklı düşman tipleri JSON'dan
yüklenebilir.
"""

from __future__ import annotations

import random
import pygame
from entities.character import Character
from utils.constants import (
    TILE_SIZE, DIR_DOWN, DIR_UP, DIR_LEFT, DIR_RIGHT,
    STATE_IDLE, STATE_WALKING, COLOR_TORII_RED
)
from utils.logger import get_logger

_logger = get_logger("Enemy")


class Enemy(Character):
    """
    Düşman karakter sınıfı.

    Character'a ek olarak:
    - Düşman tipi ve AI davranışı
    - Loot tablosu (drop_loot)
    - EXP ve altın ödülü
    - Aggro (saldırganlık) menzili
    - Basit patrol / chase AI

    Polimorfizm:
        - level_up(): Agresif stat artışı.
        - interact(): Savaşa giriş tetiklenir.
        - decide_action(): Savaştaki karar mekanizması.
    """

    # ── AI Davranış Tipleri ──
    AI_PASSIVE = "passive"       # Saldırmaz, sadece dolaşır
    AI_AGGRESSIVE = "aggressive"  # Oyuncuya yaklaşır ve saldırır
    AI_PATROL = "patrol"         # Belirli rota üzerinde dolaşır

    def __init__(self, name: str, x: float, y: float,
                 stats: dict, enemy_type: str = "slime",
                 ai_behavior: str = "passive"):
        """
        Args:
            name: Düşman adı.
            x, y: Başlangıç pozisyonu.
            stats: İstatistik sözlüğü.
            enemy_type: Düşman türü ('slime', 'oni', 'kitsune' vb.)
            ai_behavior: AI davranış tipi.
        """
        super().__init__(name, x, y, stats, TILE_SIZE, TILE_SIZE)

        # ── Protected: Alt sınıflar erişebilir ──
        self._enemy_type: str = enemy_type
        self._loot_table: list = []          # Olası drop eşyaları
        self._exp_reward: int = stats.get('exp_reward', 25)
        self._gold_reward: int = stats.get('gold_reward', 10)
        self._ai_behavior: str = ai_behavior
        self._aggro_range: float = stats.get('aggro_range', 150.0)

        # ── AI durumu ──
        self._patrol_points: list = []       # Patrol rotası
        self._patrol_index: int = 0
        self._ai_timer: float = 0.0
        self._ai_decision_interval: float = 2.0  # Saniyede bir karar
        self._target = None                  # Takip edilen hedef
        self._spawn_x: float = x            # Doğma noktası
        self._spawn_y: float = y

        # Placeholder sprite
        self._create_placeholder_sprite()

        _logger.debug("Düşman oluşturuldu: '%s' (%s) pos=(%.0f, %.0f)",
                      name, enemy_type, x, y)

    # ══════════════════════════════════════════
    #  Placeholder Sprite
    # ══════════════════════════════════════════

    def _create_placeholder_sprite(self) -> None:
        """Düşman tipi için geçici sprite oluşturur."""
        size = TILE_SIZE
        sprite = pygame.Surface((size, size), pygame.SRCALPHA)

        if self._enemy_type == "slime":
            # Yeşil balçık
            color = (50, 180, 80, 200)
            pygame.draw.ellipse(sprite, color,
                                (4, size // 3, size - 8, size * 2 // 3))
            # Gözler
            pygame.draw.circle(sprite, (255, 255, 255),
                               (size // 3, size // 2), 4)
            pygame.draw.circle(sprite, (255, 255, 255),
                               (size * 2 // 3, size // 2), 4)
            pygame.draw.circle(sprite, (20, 20, 20),
                               (size // 3 + 1, size // 2), 2)
            pygame.draw.circle(sprite, (20, 20, 20),
                               (size * 2 // 3 + 1, size // 2), 2)

        elif self._enemy_type == "oni":
            # Kırmızı Oni (Japon iblisi)
            pygame.draw.rect(sprite, (200, 50, 50),
                             (size // 4, size // 4, size // 2, size // 2))
            # Boynuzlar
            pygame.draw.polygon(sprite, (180, 40, 40), [
                (size // 3, size // 4),
                (size // 3 - 4, size // 8),
                (size // 3 + 4, size // 4)
            ])
            pygame.draw.polygon(sprite, (180, 40, 40), [
                (size * 2 // 3, size // 4),
                (size * 2 // 3 + 4, size // 8),
                (size * 2 // 3 - 4, size // 4)
            ])
            # Gözler
            pygame.draw.rect(sprite, (255, 255, 0),
                             (size // 3, size // 3 + 2, 3, 3))
            pygame.draw.rect(sprite, (255, 255, 0),
                             (size * 2 // 3 - 3, size // 3 + 2, 3, 3))

        elif self._enemy_type == "kitsune":
            # Tilki ruhu (turuncu)
            pygame.draw.ellipse(sprite, (255, 140, 50),
                                (6, size // 3, size - 12, size // 2))
            # Kulaklar
            pygame.draw.polygon(sprite, (255, 120, 40), [
                (size // 4, size // 3),
                (size // 4 - 3, size // 6),
                (size // 4 + 5, size // 3)
            ])
            pygame.draw.polygon(sprite, (255, 120, 40), [
                (size * 3 // 4, size // 3),
                (size * 3 // 4 + 3, size // 6),
                (size * 3 // 4 - 5, size // 3)
            ])
            # Kuyruğu
            pygame.draw.arc(sprite, (255, 160, 60),
                            (size // 2, size // 2, size // 2, size // 3),
                            0, 3.14, 2)

        else:
            # Genel düşman (kırmızı kare)
            pygame.draw.rect(sprite, COLOR_TORII_RED,
                             (4, 4, size - 8, size - 8))
            pygame.draw.rect(sprite, (255, 255, 0),
                             (size // 3, size // 3, 3, 3))
            pygame.draw.rect(sprite, (255, 255, 0),
                             (size * 2 // 3 - 3, size // 3, 3, 3))

        self._sprite = sprite

    # ══════════════════════════════════════════
    #  Polimorfik: level_up()
    # ══════════════════════════════════════════

    def level_up(self) -> None:
        """Düşmanlar agresif stat artışı alır."""
        self._increase_stat('attack', 5)
        self._increase_stat('defense', 2)
        self._increase_stat('speed', 1)
        self._increase_max_hp(12)

    # ══════════════════════════════════════════
    #  Polimorfik: interact()
    # ══════════════════════════════════════════

    def interact(self, other) -> None:
        """
        Oyuncu ile temas: savaş başlatma isteği.
        İleride BattleSystem tarafından dinlenecek.
        """
        _logger.info("Düşman '%s' ile karşılaşıldı! Savaş tetikleniyor.",
                     self._name)

    # ══════════════════════════════════════════
    #  AI — Savaş Kararı
    # ══════════════════════════════════════════

    def decide_action(self, battle_context: dict) -> dict:
        """
        Savaşta hangi aksiyonu yapacağına karar verir.

        Args:
            battle_context: Savaş durumu bilgisi:
                - 'player': Player referansı
                - 'allies': Diğer düşmanlar
                - 'turn': Mevcut tur sayısı

        Returns:
            Karar sözlüğü: {'action': str, 'target': entity}
        """
        hp_ratio = self.hp / self.max_hp if self.max_hp > 0 else 0

        # Basit AI: HP düşükse savunma, yoksa saldır
        if hp_ratio < 0.2:
            return {'action': 'defend', 'target': self}
        elif hp_ratio < 0.5 and random.random() < 0.3:
            return {'action': 'defend', 'target': self}
        else:
            target = battle_context.get('player')
            return {'action': 'attack', 'target': target}

    # ══════════════════════════════════════════
    #  Loot (Ganimet)
    # ══════════════════════════════════════════

    def set_loot_table(self, loot_table: list) -> None:
        """
        Loot tablosunu ayarlar.

        Args:
            loot_table: Her öğe {'item_id': str, 'chance': float} formatında.
        """
        self._loot_table = loot_table

    def drop_loot(self) -> list:
        """
        Yenildiğinde düşürecek eşyaları belirler.

        Returns:
            Düşürülen eşya ID'lerinin listesi.
        """
        drops = []
        for entry in self._loot_table:
            if random.random() <= entry.get('chance', 0.5):
                drops.append(entry.get('item_id'))
        _logger.debug("'%s' loot: %s", self._name, drops)
        return drops

    @property
    def exp_reward(self) -> int:
        return self._exp_reward

    @property
    def gold_reward(self) -> int:
        return self._gold_reward

    @property
    def enemy_type(self) -> str:
        return self._enemy_type

    # ══════════════════════════════════════════
    #  AI — Dünyada Hareket
    # ══════════════════════════════════════════

    def update(self, dt: float) -> None:
        """AI davranışını ve hareketi günceller."""
        super().update(dt)

        if not self.is_alive:
            return

        self._ai_timer += dt

        if self._ai_behavior == self.AI_PASSIVE:
            self._ai_passive(dt)
        elif self._ai_behavior == self.AI_AGGRESSIVE:
            self._ai_aggressive(dt)
        elif self._ai_behavior == self.AI_PATROL:
            self._ai_patrol(dt)

    def _ai_passive(self, dt: float) -> None:
        """Rastgele yönde kısa mesafeler hareket eder."""
        if self._ai_timer >= self._ai_decision_interval:
            self._ai_timer = 0.0
            # %40 şansla yön değiştir
            if random.random() < 0.4:
                self._direction = random.choice(
                    [DIR_UP, DIR_DOWN, DIR_LEFT, DIR_RIGHT]
                )
                self._state = STATE_WALKING
            else:
                self._state = STATE_IDLE

        if self._state == STATE_WALKING:
            speed = self._move_speed * 0.3 * dt
            if self._direction == DIR_UP:
                self._y -= speed
            elif self._direction == DIR_DOWN:
                self._y += speed
            elif self._direction == DIR_LEFT:
                self._x -= speed
            elif self._direction == DIR_RIGHT:
                self._x += speed

            # Doğma noktasından çok uzaklaşma
            max_range = 100
            if abs(self._x - self._spawn_x) > max_range:
                self._x = self._spawn_x + (
                    max_range if self._x > self._spawn_x else -max_range
                )
            if abs(self._y - self._spawn_y) > max_range:
                self._y = self._spawn_y + (
                    max_range if self._y > self._spawn_y else -max_range
                )

    def _ai_aggressive(self, dt: float) -> None:
        """Hedef menzildeyse takip eder."""
        if self._target is None:
            self._ai_passive(dt)
            return

        tx, ty = self._target.get_position()
        dx = tx - self._x
        dy = ty - self._y
        dist = (dx ** 2 + dy ** 2) ** 0.5

        if dist <= self._aggro_range and dist > TILE_SIZE:
            # Hedefe doğru hareket et
            self._state = STATE_WALKING
            speed = self._move_speed * 0.5 * dt
            if dist > 0:
                self._x += (dx / dist) * speed
                self._y += (dy / dist) * speed
        else:
            self._ai_passive(dt)

    def _ai_patrol(self, dt: float) -> None:
        """Belirli noktalar arasında devriye gezer."""
        if not self._patrol_points:
            self._ai_passive(dt)
            return

        target_point = self._patrol_points[self._patrol_index]
        dx = target_point[0] - self._x
        dy = target_point[1] - self._y
        dist = (dx ** 2 + dy ** 2) ** 0.5

        if dist < 5:
            # Sonraki noktaya geç
            self._patrol_index = (
                (self._patrol_index + 1) % len(self._patrol_points)
            )
            self._state = STATE_IDLE
        else:
            self._state = STATE_WALKING
            speed = self._move_speed * 0.4 * dt
            if dist > 0:
                self._x += (dx / dist) * speed
                self._y += (dy / dist) * speed

    def set_target(self, target) -> None:
        """AI'nın takip edeceği hedefi ayarlar."""
        self._target = target

    def set_patrol_points(self, points: list) -> None:
        """Patrol rotasını ayarlar. Nokta listesi [(x,y), ...]."""
        self._patrol_points = points

    # ══════════════════════════════════════════
    #  Fabrika Metodu
    # ══════════════════════════════════════════

    @classmethod
    def from_data(cls, data: dict) -> Enemy:
        """
        JSON verisinden düşman oluşturan fabrika metodu.

        Args:
            data: Düşman tanım sözlüğü.

        Returns:
            Yeni Enemy instance'ı.
        """
        return cls(
            name=data.get('name', 'Unknown'),
            x=data.get('x', 0),
            y=data.get('y', 0),
            stats={
                'hp': data.get('hp', 50),
                'mp': data.get('mp', 20),
                'attack': data.get('attack', 8),
                'defense': data.get('defense', 3),
                'speed': data.get('speed', 4),
                'exp_reward': data.get('exp_reward', 25),
                'gold_reward': data.get('gold_reward', 10),
                'aggro_range': data.get('aggro_range', 150),
            },
            enemy_type=data.get('type', 'slime'),
            ai_behavior=data.get('ai', 'passive')
        )
