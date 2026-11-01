"""
Shinrin CS — NPC (Oyuncu Olmayan Karakter) Sınıfı.

Character'dan türer. Diyalog, dükkan ve görev verme
özelliklerini içerir.
"""

from __future__ import annotations

import pygame
from entities.character import Character
from utils.constants import (
    TILE_SIZE, DIR_DOWN, STATE_IDLE,
    COLOR_SAKURA_PINK, COLOR_GOLD
)
from utils.logger import get_logger

_logger = get_logger("NPC")


class NPC(Character):
    """
    Oynanmaz Karakter (NPC) Sınıfı.

    Character'a ek olarak:
    - Diyalog sistemi entegrasyonu
    - Dükkan (ticaret) desteği
    - Görev verme/tamamlama
    - Gün içi takvim (opsiyonel)

    Polimorfizm:
        - level_up(): NPC'ler seviye atlamaz; stub.
        - interact(): Diyalog başlatır, dükkan açar veya görev verir.
    """

    # ── NPC Rolleri ──
    ROLE_VILLAGER = "villager"
    ROLE_MERCHANT = "merchant"
    ROLE_QUEST_GIVER = "quest_giver"
    ROLE_HEALER = "healer"
    ROLE_SAGE = "sage"

    def __init__(self, name: str, x: float, y: float,
                 role: str = "villager",
                 dialogue_id: str = "default"):
        """
        Args:
            name: NPC adı.
            x, y: Pozisyon.
            role: NPC rolü ('villager', 'merchant', 'quest_giver' vb.)
            dialogue_id: Diyalog veri ID'si (dialogues.json'dan).
        """
        # NPC'ler düşük istatistiklere sahiptir (savaşmazlar)
        npc_stats = {
            'hp': 50, 'mp': 20,
            'attack': 1, 'defense': 1, 'speed': 3
        }
        super().__init__(name, x, y, npc_stats, TILE_SIZE, TILE_SIZE)

        # ── Protected ──
        self._dialogue_id: str = dialogue_id
        self._role: str = role
        self._shop_inventory: list = []    # Satılık eşya listesi
        self._quest_giver: bool = (role == self.ROLE_QUEST_GIVER)
        self._available_quests: list = []  # Verebileceği görevler
        self._schedule: dict = {}          # Gün içi konum takvimi

        # ── Etkileşim durumu ──
        self._has_interacted: bool = False
        self._interaction_cooldown: float = 0.0
        self._exclamation_visible: bool = True  # Görev işareti

        # Placeholder sprite
        self._create_placeholder_sprite()

        _logger.debug("NPC oluşturuldu: '%s' (rol: %s)", name, role)

    # ══════════════════════════════════════════
    #  Placeholder Sprite
    # ══════════════════════════════════════════

    def _create_placeholder_sprite(self) -> None:
        """NPC rolüne göre geçici sprite oluşturur."""
        size = TILE_SIZE
        sprite = pygame.Surface((size, size), pygame.SRCALPHA)

        # Gövde rengi role göre
        if self._role == self.ROLE_MERCHANT:
            body_color = (139, 90, 43)   # Kahverengi (tüccar)
        elif self._role == self.ROLE_HEALER:
            body_color = (200, 200, 230)  # Beyazımsı (şifacı)
        elif self._role == self.ROLE_QUEST_GIVER:
            body_color = (180, 120, 60)   # Turuncu (görev veren)
        elif self._role == self.ROLE_SAGE:
            body_color = (100, 80, 160)   # Mor (bilge)
        else:
            body_color = (100, 140, 180)  # Mavi (köylü)

        # Gövde
        pygame.draw.rect(sprite, body_color,
                         (size // 4, size // 3, size // 2, size // 2))

        # Kafa
        pygame.draw.rect(sprite, (220, 180, 150),
                         (size // 4 + 2, size // 6, size // 2 - 4, size // 4))

        # Saç
        pygame.draw.rect(sprite, (60, 50, 40),
                         (size // 4, size // 6 - 2, size // 2, size // 8))

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
        """NPC'ler seviye atlamaz — no-op."""
        pass

    # ══════════════════════════════════════════
    #  Polimorfik: interact()
    # ══════════════════════════════════════════

    def interact(self, other) -> None:
        """
        Oyuncu ile etkileşim. Rolüne göre farklı davranır:
        - villager: Diyalog başlatır.
        - merchant: Dükkan açar.
        - quest_giver: Görev teklifi yapar.
        - healer: HP/MP yeniler.
        - sage: Bilgi verir.

        Args:
            other: Etkileşime giren entity (genellikle Player).
        """
        _logger.info("NPC '%s' ile etkileşim (%s)", self._name, self._role)

        if self._role == self.ROLE_HEALER:
            # Şifacı: Oyuncuyu iyileştir
            if hasattr(other, 'full_restore'):
                other.full_restore()
                _logger.info("Şifacı '%s' oyuncuyu iyileştirdi.", self._name)

        self._has_interacted = True

    # ══════════════════════════════════════════
    #  Diyalog
    # ══════════════════════════════════════════

    def talk(self) -> str:
        """
        NPC'nin diyalog ID'sini döndürür.
        DialogueSystem bu ID ile diyalogu yükler.

        Returns:
            Diyalog veri ID'si.
        """
        return self._dialogue_id

    def set_dialogue(self, dialogue_id: str) -> None:
        """Diyalog ID'sini değiştirir (görev ilerlemesine göre)."""
        self._dialogue_id = dialogue_id

    # ══════════════════════════════════════════
    #  Dükkan (Ticaret)
    # ══════════════════════════════════════════

    def set_shop_inventory(self, items: list) -> None:
        """
        Dükkan envanterini ayarlar.

        Args:
            items: Satılık eşya listesi [{'item_id', 'price'}, ...]
        """
        self._shop_inventory = items

    def open_shop(self) -> list:
        """Dükkan envanterini döndürür."""
        return self._shop_inventory.copy()

    # ══════════════════════════════════════════
    #  Görev Yönetimi
    # ══════════════════════════════════════════

    def add_quest(self, quest: dict) -> None:
        """Verilebilecek görev ekler."""
        self._available_quests.append(quest)
        self._quest_giver = True

    def offer_quest(self) -> dict:
        """
        İlk bekleyen görevi teklif eder.

        Returns:
            Görev verisi veya boş dict.
        """
        if self._available_quests:
            return self._available_quests[0]
        return {}

    def remove_quest(self, quest_id: str) -> None:
        """Teklif edilen görevi listeden çıkarır (kabul edildiğinde)."""
        self._available_quests = [
            q for q in self._available_quests
            if q.get('id') != quest_id
        ]
        if not self._available_quests:
            self._quest_giver = False

    @property
    def has_quest(self) -> bool:
        return bool(self._available_quests)

    @property
    def role(self) -> str:
        return self._role

    @property
    def dialogue_id(self) -> str:
        return self._dialogue_id

    # ══════════════════════════════════════════
    #  Güncelleme ve Çizim
    # ══════════════════════════════════════════

    def update(self, dt: float) -> None:
        """NPC güncelleme (etkileşim cooldown)."""
        super().update(dt)

        if self._interaction_cooldown > 0:
            self._interaction_cooldown -= dt

    def draw(self, surface: pygame.Surface, camera=None) -> None:
        """NPC'yi çizer. Görev varsa ünlem işareti gösterir."""
        super().draw(surface, camera)

        # Görev veya ticaret göstergesi
        if self._quest_giver and self._available_quests:
            self._draw_indicator(surface, camera, "!", COLOR_GOLD)
        elif self._role == self.ROLE_MERCHANT:
            self._draw_indicator(surface, camera, "$", (200, 200, 50))

    def _draw_indicator(self, surface: pygame.Surface, camera,
                        symbol: str, color: tuple) -> None:
        """Başın üstünde gösterge çizer (!, $ vb.)."""
        if camera:
            sx, sy = camera.apply(self._x, self._y)
        else:
            sx, sy = self._x, self._y

        font = pygame.font.Font(None, 20)
        text_surf = font.render(symbol, True, color)
        text_rect = text_surf.get_rect(
            center=(int(sx) + self._width // 2, int(sy) - 8)
        )
        surface.blit(text_surf, text_rect)

    # ══════════════════════════════════════════
    #  Fabrika Metodu
    # ══════════════════════════════════════════

    @classmethod
    def from_data(cls, data: dict) -> NPC:
        """JSON verisinden NPC oluşturan fabrika metodu."""
        npc = cls(
            name=data.get('name', 'Köylü'),
            x=data.get('x', 0),
            y=data.get('y', 0),
            role=data.get('role', 'villager'),
            dialogue_id=data.get('dialogue_id', 'default')
        )
        if 'shop' in data:
            npc.set_shop_inventory(data['shop'])
        if 'quests' in data:
            for quest in data['quests']:
                npc.add_quest(quest)
        return npc
