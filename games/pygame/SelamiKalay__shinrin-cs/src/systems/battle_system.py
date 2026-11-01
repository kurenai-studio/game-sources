"""
Shinrin CS — Sıra Tabanlı Savaş Sistemi.

Turn-based JRPG savaşını yönetir: tur sırası, hasar hesabı,
savaş UI'si, ödül dağıtımı.
"""

from __future__ import annotations

import random
import pygame
from utils.constants import (
    SCREEN_WIDTH, SCREEN_HEIGHT, COLOR_BG_DARK,
    COLOR_UI_BG, COLOR_UI_BORDER, COLOR_UI_TEXT,
    COLOR_GOLD, COLOR_HP_BAR, COLOR_HP_BAR_LOW, COLOR_MP_BAR,
    COLOR_WHITE, COLOR_TORII_RED,
    FONT_SIZE_MEDIUM, FONT_SIZE_SMALL, FONT_SIZE_LARGE
)
from utils.logger import get_logger

_logger = get_logger("BattleSystem")


class BattleSystem:
    """
    Sıra tabanlı savaş yönetim sınıfı.

    Savaş akışı:
    1. start_battle() → katılımcılar seteye alınır
    2. Her tur: oyuncu aksiyon seçer → düşmanlar karar verir
    3. Sıra speed stat'ına göre belirlenir
    4. Savaş bitince ödüller dağıtılır
    """

    # ── Savaş Durumları ──
    STATE_INTRO = "intro"
    STATE_PLAYER_TURN = "player_turn"
    STATE_ENEMY_TURN = "enemy_turn"
    STATE_ANIMATING = "animating"
    STATE_VICTORY = "victory"
    STATE_DEFEAT = "defeat"

    # ── Oyuncu Aksiyonları ──
    ACTIONS = ["Saldır", "Büyü", "Eşya", "Kaç"]

    def __init__(self, asset_manager):
        self._asset_manager = asset_manager
        self._player = None
        self._enemies: list = []
        self._turn_order: list = []
        self._current_turn_index: int = 0
        self._state: str = self.STATE_INTRO
        self._action_index: int = 0
        self._target_index: int = 0
        self._battle_log: list = []
        self._log_timer: float = 0.0
        self._intro_timer: float = 2.0
        self._animation_timer: float = 0.0
        # Animasyon bitince gecilecek tur (kimin hamlesi bittiyse digerine)
        self._next_state: str = self.STATE_PLAYER_TURN
        self._rewards: dict = {'exp': 0, 'gold': 0, 'items': []}
        self._font = None
        self._small_font = None
        self._large_font = None
        self._is_active: bool = False
        self._shake_timer: float = 0.0

    def start_battle(self, player, enemies: list) -> None:
        """
        Yeni savaş başlatır.

        Args:
            player: Oyuncu karakter.
            enemies: Düşman listesi.
        """
        self._player = player
        self._enemies = list(enemies)
        self._state = self.STATE_INTRO
        self._intro_timer = 1.5
        self._action_index = 0
        self._target_index = 0
        self._battle_log = ["Savaş başladı!"]
        self._rewards = {'exp': 0, 'gold': 0, 'items': []}
        self._is_active = True

        # Tur sırası: speed'e göre sırala
        self._sort_turn_order()

        if not self._font:
            self._font = self._asset_manager.load_font(None, FONT_SIZE_MEDIUM)
            self._small_font = self._asset_manager.load_font(None, FONT_SIZE_SMALL)
            self._large_font = self._asset_manager.load_font(None, FONT_SIZE_LARGE)

        _logger.info("Savaş başladı: Oyuncu vs %d düşman", len(enemies))

    def _sort_turn_order(self) -> None:
        """Katılımcıları hız sırasına göre sıralar."""
        all_fighters = [self._player] + self._enemies
        self._turn_order = sorted(
            all_fighters, key=lambda c: c.speed, reverse=True
        )
        self._current_turn_index = 0

    # ══════════════════════════════════════════
    #  Güncelleme
    # ══════════════════════════════════════════

    def update(self, dt: float) -> None:
        """Savaş durumunu günceller."""
        if not self._is_active:
            return

        if self._state == self.STATE_INTRO:
            self._intro_timer -= dt
            if self._intro_timer <= 0:
                self._state = self.STATE_PLAYER_TURN

        elif self._state == self.STATE_ANIMATING:
            self._animation_timer -= dt
            if self._animation_timer <= 0:
                self._next_turn()

        elif self._state == self.STATE_ENEMY_TURN:
            self._execute_enemy_turn()

        self._shake_timer = max(0, self._shake_timer - dt)

    def handle_input(self, input_handler) -> None:
        """Savaş sırasında oyuncu girdisini işler."""
        if self._state != self.STATE_PLAYER_TURN:
            if self._state in (self.STATE_VICTORY, self.STATE_DEFEAT):
                if input_handler.is_confirm():
                    self._is_active = False
            return

        # Aksiyonlar arası gezinme
        if input_handler.is_just_pressed(pygame.K_UP) or \
           input_handler.is_just_pressed(pygame.K_w):
            self._action_index = (self._action_index - 1) % len(self.ACTIONS)

        if input_handler.is_just_pressed(pygame.K_DOWN) or \
           input_handler.is_just_pressed(pygame.K_s):
            self._action_index = (self._action_index + 1) % len(self.ACTIONS)

        # Aksiyon seçimi
        if input_handler.is_confirm():
            self._execute_player_action()

    def _execute_player_action(self) -> None:
        """Oyuncunun seçtiği aksiyonu uygular."""
        action = self.ACTIONS[self._action_index]

        if action == "Saldır":
            # İlk canlı düşmana saldır
            target = self._get_first_alive_enemy()
            if target:
                damage = self._player.perform_attack(target)
                self._battle_log.append(
                    f"{self._player.name} → {target.name}: {damage} hasar!"
                )
                self._shake_timer = 0.3
                if not target.is_alive:
                    self._battle_log.append(f"{target.name} yenildi!")

        elif action == "Kaç":
            if random.random() < 0.5:
                self._battle_log.append("Kaçtınız!")
                self._is_active = False
                return
            else:
                self._battle_log.append("Kaçamadınız!")

        elif action == "Büyü":
            self._battle_log.append("Henüz büyü yok...")

        elif action == "Eşya":
            self._battle_log.append("Henüz eşya kullanımı yok...")

        self._state = self.STATE_ANIMATING
        self._animation_timer = 0.8
        self._next_state = self.STATE_ENEMY_TURN

    def _execute_enemy_turn(self) -> None:
        """Düşman turunu otomatik yürütür."""
        for enemy in self._enemies:
            if not enemy.is_alive:
                continue

            decision = enemy.decide_action({'player': self._player})

            if decision['action'] == 'attack':
                damage = self._player.take_damage(enemy.attack)
                self._battle_log.append(
                    f"{enemy.name} → {self._player.name}: {damage} hasar!"
                )
                self._shake_timer = 0.2

            elif decision['action'] == 'defend':
                self._battle_log.append(f"{enemy.name} savunmaya geçti.")

        self._state = self.STATE_ANIMATING
        self._animation_timer = 1.0
        self._next_state = self.STATE_PLAYER_TURN

    def _next_turn(self) -> None:
        """Sonraki tura geçer, savaş bitişi kontrol eder."""
        # Savaş bitti mi?
        all_enemies_dead = all(not e.is_alive for e in self._enemies)
        player_dead = not self._player.is_alive

        if all_enemies_dead:
            self._state = self.STATE_VICTORY
            self._calculate_rewards()
            return

        if player_dead:
            self._state = self.STATE_DEFEAT
            return

        # Tur geçişi: _next_turn hep ANIMATING durumundan çağrılır, bu yüzden
        # sıradaki tur animasyon başlarken kaydedilir (oyuncu → düşman → oyuncu)
        self._state = self._next_state

    def _get_first_alive_enemy(self):
        """İlk canlı düşmanı döndürür."""
        for e in self._enemies:
            if e.is_alive:
                return e
        return None

    def _calculate_rewards(self) -> None:
        """Savaş ödüllerini hesaplar ve uygular."""
        total_exp = sum(e.exp_reward for e in self._enemies)
        total_gold = sum(e.gold_reward for e in self._enemies)
        items = []
        for e in self._enemies:
            items.extend(e.drop_loot())

        self._rewards = {'exp': total_exp, 'gold': total_gold, 'items': items}
        leveled = self._player.gain_exp(total_exp)
        self._player.add_gold(total_gold)

        self._battle_log.append(f"Zafer! +{total_exp} EXP, +{total_gold} Altın")
        if leveled:
            self._battle_log.append(f"Seviye atladınız! → Lv.{self._player.level}")

        _logger.info("Savaş kazanıldı: +%d EXP, +%d Gold", total_exp, total_gold)

    # ══════════════════════════════════════════
    #  Çizim
    # ══════════════════════════════════════════

    def draw(self, surface: pygame.Surface) -> None:
        """Savaş ekranını çizer."""
        if not self._is_active or not self._font:
            return

        # Arka plan
        surface.fill((15, 12, 25))
        self._draw_battle_bg(surface)

        # Düşmanlar
        self._draw_enemies(surface)

        # Oyuncu bilgi paneli
        self._draw_player_panel(surface)

        # Aksiyon menüsü (oyuncu turunda)
        if self._state == self.STATE_PLAYER_TURN:
            self._draw_action_menu(surface)

        # Savaş logu
        self._draw_battle_log(surface)

        # Durum mesajları
        if self._state == self.STATE_INTRO:
            self._draw_centered_text(surface, "Savaş Başlıyor!", COLOR_TORII_RED)
        elif self._state == self.STATE_VICTORY:
            self._draw_centered_text(surface, "ZAFER!", COLOR_GOLD)
            self._draw_rewards(surface)
        elif self._state == self.STATE_DEFEAT:
            self._draw_centered_text(surface, "YENİLDİNİZ...", COLOR_TORII_RED)

    def _draw_battle_bg(self, surface: pygame.Surface) -> None:
        """Savaş arkaplanı."""
        # Zemin çizgisi
        ground_y = SCREEN_HEIGHT * 2 // 3
        pygame.draw.rect(surface, (30, 45, 30),
                         (0, ground_y, SCREEN_WIDTH, SCREEN_HEIGHT - ground_y))
        pygame.draw.line(surface, (50, 70, 50),
                         (0, ground_y), (SCREEN_WIDTH, ground_y), 2)

    def _draw_enemies(self, surface: pygame.Surface) -> None:
        """Düşmanları savaş ekranında çizer."""
        alive_enemies = [e for e in self._enemies if e.is_alive]
        if not alive_enemies:
            return

        spacing = SCREEN_WIDTH // (len(alive_enemies) + 1)
        enemy_y = SCREEN_HEIGHT // 3

        for i, enemy in enumerate(alive_enemies):
            ex = spacing * (i + 1)

            # Sarsıntı efekti
            shake_x = 0
            if self._shake_timer > 0:
                shake_x = random.randint(-3, 3)

            # Büyütülmüş sprite çiz
            if enemy._sprite:
                scaled = pygame.transform.scale(enemy._sprite, (64, 64))
                surface.blit(scaled, (ex - 32 + shake_x, enemy_y - 32))

            # İsim ve HP barı
            name_surf = self._small_font.render(enemy.name, True, COLOR_WHITE)
            name_rect = name_surf.get_rect(center=(ex, enemy_y + 40))
            surface.blit(name_surf, name_rect)

            # HP bar
            bar_w = 60
            bar_h = 6
            ratio = enemy.hp / enemy.max_hp if enemy.max_hp > 0 else 0
            pygame.draw.rect(surface, (40, 40, 40),
                             (ex - bar_w // 2, enemy_y + 55, bar_w, bar_h))
            bar_color = COLOR_HP_BAR if ratio > 0.3 else COLOR_HP_BAR_LOW
            pygame.draw.rect(surface, bar_color,
                             (ex - bar_w // 2, enemy_y + 55,
                              int(bar_w * ratio), bar_h))

    def _draw_player_panel(self, surface: pygame.Surface) -> None:
        """Oyuncu bilgi paneli çizer."""
        panel_w = 220
        panel_h = 90
        panel_x = SCREEN_WIDTH - panel_w - 20
        panel_y = SCREEN_HEIGHT - panel_h - 20

        # Panel bg
        panel = pygame.Surface((panel_w, panel_h), pygame.SRCALPHA)
        panel.fill(COLOR_UI_BG)
        surface.blit(panel, (panel_x, panel_y))
        pygame.draw.rect(surface, COLOR_UI_BORDER,
                         (panel_x, panel_y, panel_w, panel_h), 2)

        # İsim ve seviye
        name_text = f"{self._player.name}  Lv.{self._player.level}"
        name_surf = self._font.render(name_text, True, COLOR_WHITE)
        surface.blit(name_surf, (panel_x + 10, panel_y + 8))

        # HP
        hp_text = f"HP: {self._player.hp}/{self._player.max_hp}"
        hp_surf = self._small_font.render(hp_text, True, COLOR_HP_BAR)
        surface.blit(hp_surf, (panel_x + 10, panel_y + 35))
        # HP bar
        ratio = self._player.hp / self._player.max_hp
        bar_color = COLOR_HP_BAR if ratio > 0.3 else COLOR_HP_BAR_LOW
        pygame.draw.rect(surface, (40, 40, 40),
                         (panel_x + 100, panel_y + 37, 100, 8))
        pygame.draw.rect(surface, bar_color,
                         (panel_x + 100, panel_y + 37, int(100 * ratio), 8))

        # MP
        mp_text = f"MP: {self._player.mp}/{self._player.max_mp}"
        mp_surf = self._small_font.render(mp_text, True, COLOR_MP_BAR)
        surface.blit(mp_surf, (panel_x + 10, panel_y + 55))
        mp_ratio = self._player.mp / self._player.max_mp if self._player.max_mp > 0 else 0
        pygame.draw.rect(surface, (40, 40, 40),
                         (panel_x + 100, panel_y + 57, 100, 8))
        pygame.draw.rect(surface, COLOR_MP_BAR,
                         (panel_x + 100, panel_y + 57, int(100 * mp_ratio), 8))

    def _draw_action_menu(self, surface: pygame.Surface) -> None:
        """Aksiyon menüsü çizer."""
        menu_x = 20
        menu_y = SCREEN_HEIGHT - 120
        menu_w = 160
        menu_h = 100

        panel = pygame.Surface((menu_w, menu_h), pygame.SRCALPHA)
        panel.fill(COLOR_UI_BG)
        surface.blit(panel, (menu_x, menu_y))
        pygame.draw.rect(surface, COLOR_UI_BORDER,
                         (menu_x, menu_y, menu_w, menu_h), 2)

        for i, action in enumerate(self.ACTIONS):
            is_sel = (i == self._action_index)
            color = COLOR_GOLD if is_sel else COLOR_UI_TEXT
            prefix = "▶ " if is_sel else "  "
            text = self._font.render(prefix + action, True, color)
            surface.blit(text, (menu_x + 10, menu_y + 8 + i * 22))

    def _draw_battle_log(self, surface: pygame.Surface) -> None:
        """Savaş logunu gösterir (son 3 satır)."""
        log_y = SCREEN_HEIGHT * 2 // 3 + 10
        for i, msg in enumerate(self._battle_log[-3:]):
            surf = self._small_font.render(msg, True, (180, 180, 200))
            surface.blit(surf, (200, log_y + i * 18))

    def _draw_centered_text(self, surface: pygame.Surface,
                             text: str, color: tuple) -> None:
        """Ekran ortasına büyük text çizer."""
        # Gölge
        shadow = self._large_font.render(text, True, (0, 0, 0))
        s_rect = shadow.get_rect(center=(SCREEN_WIDTH // 2 + 2,
                                          SCREEN_HEIGHT // 2 + 2))
        surface.blit(shadow, s_rect)
        # Ana text
        surf = self._large_font.render(text, True, color)
        rect = surf.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2))
        surface.blit(surf, rect)

    def _draw_rewards(self, surface: pygame.Surface) -> None:
        """Zafer sonrası ödülleri gösterir."""
        text = f"+{self._rewards['exp']} EXP   +{self._rewards['gold']} Altın"
        surf = self._font.render(text, True, COLOR_GOLD)
        rect = surf.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 50))
        surface.blit(surf, rect)

        hint = self._small_font.render("Devam etmek için Enter", True, COLOR_UI_TEXT)
        h_rect = hint.get_rect(center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT // 2 + 80))
        surface.blit(hint, h_rect)

    @property
    def is_active(self) -> bool:
        return self._is_active

    @property
    def state(self) -> str:
        return self._state

    @property
    def rewards(self) -> dict:
        return self._rewards
