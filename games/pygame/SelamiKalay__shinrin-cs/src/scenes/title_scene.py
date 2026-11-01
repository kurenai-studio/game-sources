"""
Shinrin CS — Ana Menü / Başlık Sahnesi.

Oyun başladığında gösterilen ilk sahne. Japon temalı piksel
sanat stilinde animasyonlu bir başlık ekranı sunar.
"""

from __future__ import annotations

import math
import pygame
from scenes.base_scene import BaseScene
from utils.constants import (
    SCREEN_WIDTH, SCREEN_HEIGHT,
    COLOR_BG_DARK, COLOR_SAKURA_PINK, COLOR_SAKURA_DARK,
    COLOR_FOREST_GREEN, COLOR_FOREST_DARK, COLOR_FOREST_LIGHT,
    COLOR_FOREST_MOSS, COLOR_TORII_RED, COLOR_GOLD,
    COLOR_WHITE, COLOR_UI_TEXT, COLOR_UI_HIGHLIGHT,
    FONT_SIZE_TITLE, FONT_SIZE_MEDIUM, FONT_SIZE_SMALL
)
from utils.logger import get_logger

_logger = get_logger("TitleScene")


class TitleScene(BaseScene):
    """
    Animasyonlu başlık ekranı sahnesi.

    Dinamik arka plan (yaprak parçacıkları, gradyan gökyüzü),
    oyun logosu ve menü seçenekleri sunar.
    """

    # ── Menü seçenekleri ──
    MENU_OPTIONS = ["Yeni Oyun", "Devam Et", "Ayarlar", "Çıkış"]

    def __init__(self, game_engine):
        super().__init__(game_engine)
        self._selected_index: int = 0
        self._time: float = 0.0
        self._particles: list[dict] = []
        self._title_font: pygame.font.Font | None = None
        self._menu_font: pygame.font.Font | None = None
        self._small_font: pygame.font.Font | None = None
        self._fade_alpha: int = 255       # Başlangıçta siyah
        self._fade_in: bool = True
        self._title_y_offset: float = 0.0

    # ══════════════════════════════════════════
    #  Yaşam Döngüsü
    # ══════════════════════════════════════════

    def enter(self) -> None:
        """Sahneye girildiğinde kaynakları yükler."""
        _logger.info("Başlık sahnesine girildi.")
        self._selected_index = 0
        self._time = 0.0
        self._fade_alpha = 255
        self._fade_in = True

        # Fontları yükle
        self._title_font = self._game_engine.asset_manager.load_font(
            None, FONT_SIZE_TITLE
        )
        self._menu_font = self._game_engine.asset_manager.load_font(
            None, FONT_SIZE_MEDIUM
        )
        self._small_font = self._game_engine.asset_manager.load_font(
            None, FONT_SIZE_SMALL
        )

        # Sakura yaprak parçacıkları oluştur
        self._particles = []
        self._spawn_particles(60)

    def exit(self) -> None:
        """Sahneden çıkıldığında temizlik."""
        _logger.info("Başlık sahnesinden çıkıldı.")
        self._particles.clear()

    # ══════════════════════════════════════════
    #  Girdi İşleme
    # ══════════════════════════════════════════

    def handle_input(self, input_handler) -> None:
        """Menü navigasyonu ve seçim."""
        if self._fade_in:
            return  # Fade-in sırasında girdi kabul etme

        # Yukarı / Aşağı navigasyon
        if input_handler.is_just_pressed(pygame.K_UP) or \
           input_handler.is_just_pressed(pygame.K_w):
            self._selected_index = (
                (self._selected_index - 1) % len(self.MENU_OPTIONS)
            )

        if input_handler.is_just_pressed(pygame.K_DOWN) or \
           input_handler.is_just_pressed(pygame.K_s):
            self._selected_index = (
                (self._selected_index + 1) % len(self.MENU_OPTIONS)
            )

        # Seçim (Enter / Z)
        if input_handler.is_confirm():
            self._handle_selection()

    def _handle_selection(self) -> None:
        """Menü seçimini işler."""
        selected = self.MENU_OPTIONS[self._selected_index]
        _logger.info("Menü seçimi: '%s'", selected)

        if selected == "Yeni Oyun":
            _logger.info("Yeni oyun başlatılıyor → WorldScene")
            self._game_engine.scene_manager.switch_scene("world")

        elif selected == "Devam Et":
            # Kayıtlı oyunu yükle
            world_scene = self._game_engine.scene_manager.get_scene("world")
            if world_scene and hasattr(world_scene, 'load_game'):
                if world_scene.load_game(slot=1):
                    _logger.info("Kayıtlı oyun yükleniyor → WorldScene")
                    self._game_engine.scene_manager.switch_scene("world")
                else:
                    _logger.warning("Kayıtlı oyun bulunamadı!")

        elif selected == "Ayarlar":
            self._game_engine.scene_manager.push_scene("settings")

        elif selected == "Çıkış":
            self._game_engine.quit()

    # ══════════════════════════════════════════
    #  Güncelleme
    # ══════════════════════════════════════════

    def update(self, dt: float) -> None:
        """Animasyonları ve parçacıkları günceller."""
        self._time += dt

        # Fade-in efekti
        if self._fade_in:
            self._fade_alpha -= int(200 * dt)
            if self._fade_alpha <= 0:
                self._fade_alpha = 0
                self._fade_in = False

        # Başlık yüzen animasyonu
        self._title_y_offset = math.sin(self._time * 1.5) * 8

        # Parçacıkları güncelle
        self._update_particles(dt)

    # ══════════════════════════════════════════
    #  Çizim
    # ══════════════════════════════════════════

    def draw(self, surface: pygame.Surface) -> None:
        """Başlık ekranını çizer."""
        # 1) Gradyan arka plan (gece gökyüzü)
        self._draw_background(surface)

        # 2) Dağ silüetleri
        self._draw_mountains(surface)

        # 3) Torii kapısı
        self._draw_torii(surface)

        # 4) Ağaçlar
        self._draw_trees(surface)

        # 5) Sakura yaprak parçacıkları
        self._draw_particles(surface)

        # 6) Oyun başlığı
        self._draw_title(surface)

        # 7) Menü seçenekleri
        self._draw_menu(surface)

        # 8) Alt bilgi
        self._draw_footer(surface)

        # 9) Fade overlay
        if self._fade_alpha > 0:
            overlay = pygame.Surface(surface.get_size(), pygame.SRCALPHA)
            overlay.fill((0, 0, 0, self._fade_alpha))
            surface.blit(overlay, (0, 0))

    # ══════════════════════════════════════════
    #  Çizim Yardımcıları
    # ══════════════════════════════════════════

    def _draw_background(self, surface: pygame.Surface) -> None:
        """Animasyonlu gradyan gece gökyüzü çizer."""
        for y in range(SCREEN_HEIGHT):
            ratio = y / SCREEN_HEIGHT
            r = int(5 + ratio * 15)
            g = int(5 + ratio * 20)
            b = int(20 + ratio * 30)
            pygame.draw.line(surface, (r, g, b), (0, y), (SCREEN_WIDTH, y))

        # Yıldızlar
        import random
        random.seed(42)  # Sabit tohum: her frame aynı yıldızlar
        for _ in range(80):
            sx = random.randint(0, SCREEN_WIDTH)
            sy = random.randint(0, SCREEN_HEIGHT // 2)
            # Yıldız parlaklığı zamana bağlı
            brightness = int(
                150 + 100 * math.sin(
                    self._time * 2 + sx * 0.1 + sy * 0.05
                )
            )
            brightness = max(50, min(255, brightness))
            size = random.choice([1, 1, 1, 2])
            pygame.draw.circle(
                surface,
                (brightness, brightness, min(255, brightness + 20)),
                (sx, sy), size
            )

    def _draw_mountains(self, surface: pygame.Surface) -> None:
        """Arka plan dağ silüetleri çizer."""
        # Uzak dağlar (koyu)
        points = [(0, SCREEN_HEIGHT)]
        for x in range(0, SCREEN_WIDTH + 40, 40):
            y_base = 320
            y = y_base + int(
                50 * math.sin(x * 0.008) +
                30 * math.sin(x * 0.015 + 1)
            )
            points.append((x, y))
        points.append((SCREEN_WIDTH, SCREEN_HEIGHT))
        pygame.draw.polygon(surface, (15, 25, 20), points)

        # Yakın dağlar (daha açık)
        points2 = [(0, SCREEN_HEIGHT)]
        for x in range(0, SCREEN_WIDTH + 40, 30):
            y_base = 380
            y = y_base + int(
                40 * math.sin(x * 0.012 + 2) +
                20 * math.sin(x * 0.025)
            )
            points2.append((x, y))
        points2.append((SCREEN_WIDTH, SCREEN_HEIGHT))
        pygame.draw.polygon(surface, (20, 35, 25), points2)

    def _draw_torii(self, surface: pygame.Surface) -> None:
        """Merkezde bir Torii kapısı silüeti çizer."""
        cx = SCREEN_WIDTH // 2
        base_y = 400

        # İki dikey sütun
        col_w = 12
        col_h = 120
        col_spacing = 100

        # Sol sütun
        pygame.draw.rect(surface, COLOR_TORII_RED,
                         (cx - col_spacing // 2 - col_w // 2,
                          base_y - col_h, col_w, col_h))
        # Sağ sütun
        pygame.draw.rect(surface, COLOR_TORII_RED,
                         (cx + col_spacing // 2 - col_w // 2,
                          base_y - col_h, col_w, col_h))

        # Üst yatay kiriş (kasagi)
        beam_y = base_y - col_h - 5
        beam_extend = 20
        pygame.draw.rect(
            surface, COLOR_TORII_RED,
            (cx - col_spacing // 2 - col_w // 2 - beam_extend,
             beam_y, col_spacing + col_w + beam_extend * 2, 10)
        )

        # İkinci yatay kiriş (nuki)
        nuki_y = beam_y + 25
        pygame.draw.rect(
            surface, (150, 30, 30),
            (cx - col_spacing // 2 + 2, nuki_y,
             col_spacing - 4, 6)
        )

    def _draw_trees(self, surface: pygame.Surface) -> None:
        """Ağaç silüetleri çizer."""
        tree_data = [
            (60, 390, 50, 90),
            (150, 400, 40, 70),
            (650, 385, 55, 95),
            (730, 400, 45, 80),
            (30, 410, 35, 60),
            (770, 410, 35, 60),
        ]

        for tx, ty, tw, th in tree_data:
            # Gövde
            trunk_w = tw // 5
            pygame.draw.rect(
                surface, (30, 20, 15),
                (tx + tw // 2 - trunk_w // 2, ty, trunk_w, th // 2)
            )
            # Yaprak kümeleri (üçgenler)
            for i in range(3):
                offset_y = ty - th // 2 + i * (th // 5)
                size = tw - i * 8
                points = [
                    (tx + tw // 2, offset_y - th // 4),
                    (tx + tw // 2 - size // 2, offset_y + th // 6),
                    (tx + tw // 2 + size // 2, offset_y + th // 6),
                ]
                color = (
                    COLOR_FOREST_DARK if i == 0
                    else COLOR_FOREST_MOSS if i == 1
                    else (25, 40, 25)
                )
                pygame.draw.polygon(surface, color, points)

    # ── Parçacık Sistemi (Sakura Yaprakları) ──

    def _spawn_particles(self, count: int) -> None:
        """Sakura yaprağı parçacıkları üretir."""
        import random
        for _ in range(count):
            self._particles.append({
                'x': random.uniform(-50, SCREEN_WIDTH + 50),
                'y': random.uniform(-50, SCREEN_HEIGHT),
                'vx': random.uniform(15, 45),
                'vy': random.uniform(20, 50),
                'size': random.randint(2, 5),
                'alpha': random.randint(100, 220),
                'wobble': random.uniform(0, math.pi * 2),
                'wobble_speed': random.uniform(1.5, 3.5),
            })

    def _update_particles(self, dt: float) -> None:
        """Parçacıkları hareket ettirir."""
        for p in self._particles:
            p['wobble'] += p['wobble_speed'] * dt
            p['x'] += p['vx'] * dt + math.sin(p['wobble']) * 15 * dt
            p['y'] += p['vy'] * dt

            # Ekrandan çıkınca üstten tekrar gelsin
            if p['y'] > SCREEN_HEIGHT + 20:
                p['y'] = -10
                p['x'] = __import__('random').uniform(-20, SCREEN_WIDTH + 20)

    def _draw_particles(self, surface: pygame.Surface) -> None:
        """Sakura yapraklarını çizer."""
        for p in self._particles:
            color = (*COLOR_SAKURA_PINK[:3], p['alpha'])
            particle_surf = pygame.Surface(
                (p['size'] * 2, p['size']), pygame.SRCALPHA
            )
            pygame.draw.ellipse(particle_surf, color,
                                (0, 0, p['size'] * 2, p['size']))
            # Hafif dönme efekti
            angle = math.degrees(p['wobble']) % 360
            rotated = pygame.transform.rotate(particle_surf, angle)
            surface.blit(rotated, (int(p['x']), int(p['y'])))

    # ── Başlık ve Menü ──

    def _draw_title(self, surface: pygame.Surface) -> None:
        """Oyun başlığını çizer."""
        if not self._title_font:
            return

        # Gölge
        title_text = "SHINRIN CS"
        shadow_surf = self._title_font.render(title_text, True, (0, 0, 0))
        title_surf = self._title_font.render(title_text, True, COLOR_GOLD)

        title_y = 100 + self._title_y_offset
        shadow_rect = shadow_surf.get_rect(
            center=(SCREEN_WIDTH // 2 + 3, title_y + 3)
        )
        title_rect = title_surf.get_rect(
            center=(SCREEN_WIDTH // 2, title_y)
        )

        surface.blit(shadow_surf, shadow_rect)
        surface.blit(title_surf, title_rect)

        # Alt başlık
        if self._menu_font:
            sub_text = "— Chronicles of the Sacred Forest —"
            sub_surf = self._menu_font.render(
                sub_text, True, COLOR_SAKURA_PINK
            )
            sub_rect = sub_surf.get_rect(
                center=(SCREEN_WIDTH // 2, title_y + 50)
            )
            surface.blit(sub_surf, sub_rect)

    def _draw_menu(self, surface: pygame.Surface) -> None:
        """Menü seçeneklerini çizer."""
        if not self._menu_font:
            return

        menu_start_y = 320
        menu_spacing = 45

        for i, option in enumerate(self.MENU_OPTIONS):
            is_selected = (i == self._selected_index)

            if is_selected:
                # Seçili öğe: parlak renk + ok işareti
                color = COLOR_GOLD
                prefix = "▶ "
                # Arka plan vurgusu
                text_surf = self._menu_font.render(
                    prefix + option, True, color
                )
                text_rect = text_surf.get_rect(
                    center=(SCREEN_WIDTH // 2, menu_start_y + i * menu_spacing)
                )
                # Yarı saydam vurgu kutusu
                highlight = pygame.Surface(
                    (text_rect.width + 30, text_rect.height + 10),
                    pygame.SRCALPHA
                )
                highlight.fill((255, 215, 0, 30))
                surface.blit(
                    highlight,
                    (text_rect.x - 15, text_rect.y - 5)
                )
            else:
                color = COLOR_UI_TEXT
                prefix = "  "
                text_surf = self._menu_font.render(
                    prefix + option, True, color
                )
                text_rect = text_surf.get_rect(
                    center=(SCREEN_WIDTH // 2, menu_start_y + i * menu_spacing)
                )

            # Gölge
            shadow = self._menu_font.render(
                prefix + option, True, (0, 0, 0)
            )
            shadow_rect = shadow.get_rect(
                center=(SCREEN_WIDTH // 2 + 2,
                        menu_start_y + i * menu_spacing + 2)
            )
            surface.blit(shadow, shadow_rect)
            surface.blit(text_surf, text_rect)

    def _draw_footer(self, surface: pygame.Surface) -> None:
        """Alt bilgiyi çizer."""
        if not self._small_font:
            return

        footer = "© 2026 Shinrin CS  |  Yön tuşları ile seç, Enter ile onayla"
        footer_surf = self._small_font.render(footer, True, (100, 100, 130))
        footer_rect = footer_surf.get_rect(
            center=(SCREEN_WIDTH // 2, SCREEN_HEIGHT - 25)
        )
        surface.blit(footer_surf, footer_rect)

        # Versiyon
        ver_surf = self._small_font.render("v0.1.0", True, (70, 70, 90))
        surface.blit(ver_surf, (SCREEN_WIDTH - 60, SCREEN_HEIGHT - 25))
