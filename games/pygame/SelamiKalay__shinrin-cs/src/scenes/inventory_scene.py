"""
Shinrin CS — Envanter Sahnesi (InventoryScene).

Oyuncunun eşyalarını görüntülediği, kullandığı ve
ekipman yönetimi yaptığı overlay sahne.
"""

from __future__ import annotations

import pygame
from scenes.base_scene import BaseScene
from utils.constants import (
    SCREEN_WIDTH, SCREEN_HEIGHT,
    COLOR_UI_BG, COLOR_UI_BORDER, COLOR_UI_TEXT,
    COLOR_GOLD, COLOR_SAKURA_PINK, COLOR_WHITE,
    COLOR_HP_BAR, COLOR_MP_BAR,
    FONT_SIZE_MEDIUM, FONT_SIZE_LARGE, FONT_SIZE_SMALL
)
from utils.logger import get_logger

_logger = get_logger("InventoryScene")


class InventoryScene(BaseScene):
    """
    Envanter ve karakter bilgi ekranı.

    Sol panel: Karakter istatistikleri + ekipman
    Sağ panel: Envanter listesi
    """

    TAB_ITEMS = 0
    TAB_EQUIPMENT = 1
    TAB_STATS = 2
    TAB_NAMES = ["Eşyalar", "Ekipman", "İstatistik"]

    def __init__(self, game_engine):
        super().__init__(game_engine)
        self._selected_index: int = 0
        self._active_tab: int = self.TAB_ITEMS
        self._font = None
        self._title_font = None
        self._small_font = None
        self._player = None
        self._background_snapshot: pygame.Surface | None = None

    def enter(self) -> None:
        _logger.info("Envanter ekranı açıldı.")
        self._selected_index = 0
        self._active_tab = self.TAB_ITEMS
        am = self._game_engine.asset_manager
        self._font = am.load_font(None, FONT_SIZE_MEDIUM)
        self._title_font = am.load_font(None, FONT_SIZE_LARGE)
        self._small_font = am.load_font(None, FONT_SIZE_SMALL)
        self._background_snapshot = self._game_engine.screen.copy()

        # Player referansını al (WorldScene'den)
        self._player = self._find_player()

    def _find_player(self):
        """Aktif dünya sahnesindeki oyuncuyu bulur."""
        world_scene = self._game_engine.scene_manager.get_scene("world")
        if world_scene and hasattr(world_scene, '_player'):
            return world_scene._player
        return None

    def exit(self) -> None:
        _logger.info("Envanter ekranı kapatıldı.")

    def handle_input(self, input_handler) -> None:
        # Kapat
        if input_handler.is_cancel() or \
           input_handler.is_just_pressed(pygame.K_i):
            self._game_engine.scene_manager.pop_scene()
            return

        # Tab değiştir (Q/E)
        if input_handler.is_just_pressed(pygame.K_q):
            self._active_tab = (self._active_tab - 1) % len(self.TAB_NAMES)
            self._selected_index = 0

        if input_handler.is_just_pressed(pygame.K_e):
            self._active_tab = (self._active_tab + 1) % len(self.TAB_NAMES)
            self._selected_index = 0

        # Navigasyon
        if input_handler.is_just_pressed(pygame.K_UP) or \
           input_handler.is_just_pressed(pygame.K_w):
            self._selected_index = max(0, self._selected_index - 1)

        if input_handler.is_just_pressed(pygame.K_DOWN) or \
           input_handler.is_just_pressed(pygame.K_s):
            self._selected_index += 1

        # Kullan/Kuşan
        if input_handler.is_confirm():
            self._use_selected_item()

    def _use_selected_item(self) -> None:
        """Seçili eşyayı kullanır."""
        if not self._player or self._active_tab != self.TAB_ITEMS:
            return

        inventory = self._player.get_inventory()
        if 0 <= self._selected_index < len(inventory):
            item = inventory[self._selected_index]
            self._player.use_item(item)
            _logger.info("Eşya kullanıldı: '%s'", item.name)

    def update(self, dt: float) -> None:
        pass

    def draw(self, surface: pygame.Surface) -> None:
        # Arka plan
        if self._background_snapshot:
            surface.blit(self._background_snapshot, (0, 0))

        overlay = pygame.Surface(surface.get_size(), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 180))
        surface.blit(overlay, (0, 0))

        if not self._font:
            return

        # Ana panel
        margin = 40
        panel_x = margin
        panel_y = margin
        panel_w = SCREEN_WIDTH - margin * 2
        panel_h = SCREEN_HEIGHT - margin * 2

        panel = pygame.Surface((panel_w, panel_h), pygame.SRCALPHA)
        panel.fill((15, 15, 30, 240))
        surface.blit(panel, (panel_x, panel_y))
        pygame.draw.rect(surface, COLOR_SAKURA_PINK,
                         (panel_x, panel_y, panel_w, panel_h), 2)

        # Başlık
        title = self._title_font.render("ENVANTER", True, COLOR_GOLD)
        surface.blit(title, (panel_x + 20, panel_y + 10))

        # Tab butonları
        self._draw_tabs(surface, panel_x, panel_y + 50, panel_w)

        # İçerik alanı
        content_y = panel_y + 85
        content_h = panel_h - 120

        if self._active_tab == self.TAB_ITEMS:
            self._draw_items_tab(surface, panel_x, content_y, panel_w, content_h)
        elif self._active_tab == self.TAB_EQUIPMENT:
            self._draw_equipment_tab(surface, panel_x, content_y, panel_w, content_h)
        elif self._active_tab == self.TAB_STATS:
            self._draw_stats_tab(surface, panel_x, content_y, panel_w, content_h)

        # Alt bilgi
        hint = self._small_font.render(
            "Q/E: Tab  |  ↑↓: Seç  |  Z: Kullan  |  X: Kapat", True,
            (120, 120, 150)
        )
        surface.blit(hint, (panel_x + 20, panel_y + panel_h - 25))

    def _draw_tabs(self, surface, x, y, w) -> None:
        """Tab butonlarını çizer."""
        tab_w = w // len(self.TAB_NAMES)
        for i, name in enumerate(self.TAB_NAMES):
            is_active = (i == self._active_tab)
            tab_x = x + i * tab_w

            # Tab arka plan
            color = (40, 40, 70) if is_active else (20, 20, 40)
            pygame.draw.rect(surface, color,
                             (tab_x + 2, y, tab_w - 4, 28))
            if is_active:
                pygame.draw.rect(surface, COLOR_GOLD,
                                 (tab_x + 2, y, tab_w - 4, 28), 1)

            text_color = COLOR_GOLD if is_active else COLOR_UI_TEXT
            text = self._small_font.render(name, True, text_color)
            text_rect = text.get_rect(
                center=(tab_x + tab_w // 2, y + 14)
            )
            surface.blit(text, text_rect)

    def _draw_items_tab(self, surface, x, y, w, h) -> None:
        """Eşya listesini çizer."""
        if not self._player:
            text = self._font.render("Oyuncu bulunamadı.", True, COLOR_UI_TEXT)
            surface.blit(text, (x + 20, y + 20))
            return

        inventory = self._player.get_inventory()

        if not inventory:
            text = self._font.render("Envanter boş.", True, (120, 120, 150))
            surface.blit(text, (x + 20, y + 20))
            return

        # Kapasite gösterimi
        cap_text = f"{len(inventory)}/{self._player.inventory_capacity}"
        cap_surf = self._small_font.render(cap_text, True, COLOR_UI_TEXT)
        surface.blit(cap_surf, (x + w - 80, y + 5))

        # Eşya listesi
        for i, item in enumerate(inventory):
            if i >= 12:
                break  # Maksimum görüntülenen

            iy = y + 25 + i * 30
            is_sel = (i == self._selected_index)

            if is_sel:
                hl = pygame.Surface((w - 40, 26), pygame.SRCALPHA)
                hl.fill((255, 215, 0, 20))
                surface.blit(hl, (x + 20, iy - 2))

            # İkon
            if hasattr(item, 'icon'):
                surface.blit(item.icon, (x + 25, iy))

            # İsim (nadirlik renginde)
            name_color = item.rarity_color if hasattr(item, 'rarity_color') else COLOR_WHITE
            prefix = "▶ " if is_sel else "  "
            name_text = self._font.render(prefix + item.name, True, name_color)
            surface.blit(name_text, (x + 55, iy))

            # Miktar (stackable ise)
            if hasattr(item, 'stackable') and item.stackable and item.stack_count > 1:
                count = self._small_font.render(
                    f"x{item.stack_count}", True, COLOR_UI_TEXT
                )
                surface.blit(count, (x + w - 80, iy + 3))

        # Seçili eşya detayı
        if 0 <= self._selected_index < len(inventory):
            self._draw_item_detail(surface, inventory[self._selected_index],
                                    x + 20, y + h - 60, w - 40)

    def _draw_item_detail(self, surface, item, x, y, w) -> None:
        """Seçili eşyanın detayını gösterir."""
        pygame.draw.line(surface, COLOR_UI_BORDER, (x, y), (x + w, y))
        desc = item.description if hasattr(item, 'description') else ""
        desc_surf = self._small_font.render(desc, True, (180, 180, 200))
        surface.blit(desc_surf, (x + 5, y + 8))

        # Değer
        if hasattr(item, 'value'):
            val = self._small_font.render(f"Değer: {item.value} Gold",
                                          True, COLOR_GOLD)
            surface.blit(val, (x + 5, y + 28))

    def _draw_equipment_tab(self, surface, x, y, w, h) -> None:
        """Ekipman slotlarını çizer."""
        if not self._player:
            return

        equipment = self._player.get_equipment()
        slot_names = {"weapon": "Silah", "armor": "Zırh", "accessory": "Aksesuar"}

        ey = y + 20
        for i, (slot, item) in enumerate(equipment.items()):
            is_sel = (i == self._selected_index)

            slot_label = slot_names.get(slot, slot)
            label = self._font.render(f"{slot_label}:", True, COLOR_SAKURA_PINK)
            surface.blit(label, (x + 30, ey))

            if item:
                name_color = item.rarity_color if hasattr(item, 'rarity_color') else COLOR_WHITE
                item_text = self._font.render(item.name, True, name_color)
            else:
                item_text = self._font.render("— Boş —", True, (80, 80, 100))

            surface.blit(item_text, (x + 150, ey))

            if is_sel:
                pygame.draw.rect(surface, COLOR_GOLD,
                                 (x + 25, ey - 2, w - 50, 24), 1)

            ey += 40

    def _draw_stats_tab(self, surface, x, y, w, h) -> None:
        """Karakter istatistiklerini çizer."""
        if not self._player:
            return

        stats = self._player.get_stats()

        # Karakter adı ve seviye
        name = self._title_font.render(
            f"{stats['name']}  Lv.{stats['level']}", True, COLOR_GOLD
        )
        surface.blit(name, (x + 30, y + 10))

        # EXP barı
        exp_ratio = 1 - (self._player.exp_to_next / self._player._exp_threshold())
        exp_ratio = max(0, min(1, exp_ratio))
        pygame.draw.rect(surface, (40, 40, 40), (x + 30, y + 50, 300, 10))
        pygame.draw.rect(surface, (255, 193, 7),
                         (x + 30, y + 50, int(300 * exp_ratio), 10))
        exp_text = self._small_font.render(
            f"EXP: {stats['exp']} / Sonraki: {self._player.exp_to_next}",
            True, COLOR_UI_TEXT
        )
        surface.blit(exp_text, (x + 340, y + 48))

        # Stat listesi
        sy = y + 80
        stat_list = [
            ("HP", f"{stats['hp']}/{stats['max_hp']}", COLOR_HP_BAR),
            ("MP", f"{stats['mp']}/{stats['max_mp']}", COLOR_MP_BAR),
            ("ATK", str(stats['attack']), (255, 120, 80)),
            ("DEF", str(stats['defense']), (80, 180, 255)),
            ("SPD", str(stats['speed']), (80, 255, 150)),
        ]

        for label, value, color in stat_list:
            l_surf = self._font.render(f"{label}:", True, color)
            v_surf = self._font.render(value, True, COLOR_WHITE)
            surface.blit(l_surf, (x + 50, sy))
            surface.blit(v_surf, (x + 130, sy))
            sy += 35

        # Altın
        gold_surf = self._font.render(
            f"Altın: {self._player.gold}", True, COLOR_GOLD
        )
        surface.blit(gold_surf, (x + 50, sy + 10))
