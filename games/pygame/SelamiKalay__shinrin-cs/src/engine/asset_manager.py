"""
Shinrin CS — Asset (Varlık) Yönetim Sistemi.

Sprite, ses, font ve diğer medya dosyalarını merkezi olarak
yükler ve önbelleğe alır. Aynı asset birden fazla kez
yüklenmez (cache mekanizması).
"""

from __future__ import annotations

import os
import pygame
from utils.logger import get_logger

_logger = get_logger("AssetManager")


class AssetManager:
    """
    Merkezi asset yükleme ve önbellekleme sınıfı.

    Tüm dosya yolları proje kök dizinine göre çözümlenir.
    """

    _ASSETS_DIR = "assets"

    def __init__(self):
        self._image_cache: dict[str, pygame.Surface] = {}
        self._sound_cache: dict[str, pygame.mixer.Sound] = {}
        self._font_cache: dict[str, pygame.font.Font] = {}
        self._music_loaded: str | None = None
        _logger.info("AssetManager başlatıldı.")

    # ══════════════════════════════════════════
    #  Görsel Yükleme
    # ══════════════════════════════════════════

    def load_image(
        self,
        path: str,
        alpha: bool = True,
        scale: tuple | None = None
    ) -> pygame.Surface:
        """
        Bir görsel dosyasını yükler ve cache'ler.

        Args:
            path: assets/ dizinine göreli dosya yolu.
            alpha: True ise alpha kanalı korunur.
            scale: (width, height) boyutlandırma — None ise orijinal boyut.

        Returns:
            Yüklenmiş pygame.Surface nesnesi.
        """
        cache_key = f"{path}_{alpha}_{scale}"

        if cache_key in self._image_cache:
            return self._image_cache[cache_key]

        full_path = os.path.join(self._ASSETS_DIR, path)

        if not os.path.exists(full_path):
            _logger.warning("Görsel bulunamadı: %s — placeholder üretiliyor",
                            full_path)
            return self._create_placeholder(scale or (32, 32))

        try:
            if alpha:
                image = pygame.image.load(full_path).convert_alpha()
            else:
                image = pygame.image.load(full_path).convert()

            if scale:
                image = pygame.transform.scale(image, scale)

            self._image_cache[cache_key] = image
            _logger.debug("Görsel yüklendi: %s", full_path)
            return image

        except pygame.error as e:
            _logger.error("Görsel yüklenemedi '%s': %s", full_path, e)
            return self._create_placeholder(scale or (32, 32))

    def load_sprite_sheet(
        self,
        path: str,
        frame_width: int,
        frame_height: int,
        alpha: bool = True
    ) -> list[pygame.Surface]:
        """
        Bir sprite sheet'i ayrı karelere böler.

        Args:
            path: assets/ dizinine göreli dosya yolu.
            frame_width: Tek kare genişliği (piksel).
            frame_height: Tek kare yüksekliği (piksel).
            alpha: Alpha kanalı.

        Returns:
            Kare listesi (list[Surface]).
        """
        sheet = self.load_image(path, alpha)
        frames = []

        sheet_width = sheet.get_width()
        sheet_height = sheet.get_height()

        for y in range(0, sheet_height, frame_height):
            for x in range(0, sheet_width, frame_width):
                frame = sheet.subsurface(
                    pygame.Rect(x, y, frame_width, frame_height)
                )
                frames.append(frame)

        _logger.debug("Sprite sheet bölündü: %s → %d kare", path, len(frames))
        return frames

    # ══════════════════════════════════════════
    #  Ses Yükleme
    # ══════════════════════════════════════════

    def load_sound(self, path: str) -> pygame.mixer.Sound | None:
        """
        Bir ses efekti dosyasını yükler ve cache'ler.

        Args:
            path: assets/ dizinine göreli dosya yolu.

        Returns:
            pygame.mixer.Sound nesnesi veya None.
        """
        if path in self._sound_cache:
            return self._sound_cache[path]

        full_path = os.path.join(self._ASSETS_DIR, path)

        if not os.path.exists(full_path):
            _logger.warning("Ses dosyası bulunamadı: %s", full_path)
            return None

        try:
            sound = pygame.mixer.Sound(full_path)
            self._sound_cache[path] = sound
            _logger.debug("Ses yüklendi: %s", full_path)
            return sound
        except pygame.error as e:
            _logger.error("Ses yüklenemedi '%s': %s", full_path, e)
            return None

    def play_music(self, path: str, loops: int = -1, volume: float = 0.7):
        """
        Arka plan müziğini başlatır.

        Args:
            path: assets/ dizinine göreli dosya yolu.
            loops: Tekrar sayısı (-1 = sonsuz).
            volume: Müzik ses seviyesi (0.0 – 1.0).
        """
        full_path = os.path.join(self._ASSETS_DIR, path)

        if not os.path.exists(full_path):
            _logger.warning("Müzik dosyası bulunamadı: %s", full_path)
            return

        if self._music_loaded == full_path:
            return  # Zaten çalıyor

        try:
            pygame.mixer.music.load(full_path)
            pygame.mixer.music.set_volume(volume)
            pygame.mixer.music.play(loops)
            self._music_loaded = full_path
            _logger.info("Müzik başlatıldı: %s", full_path)
        except pygame.error as e:
            _logger.error("Müzik başlatılamadı '%s': %s", full_path, e)

    def stop_music(self, fadeout_ms: int = 1000):
        """Müziği fade-out ile durdurur."""
        pygame.mixer.music.fadeout(fadeout_ms)
        self._music_loaded = None

    # ══════════════════════════════════════════
    #  Font Yükleme
    # ══════════════════════════════════════════

    def load_font(self, path: str | None, size: int) -> pygame.font.Font:
        """
        Bir font dosyasını yükler ve cache'ler.

        Args:
            path: assets/fonts/ dizinine göreli dosya yolu veya None (sistem fontu).
            size: Font boyutu.

        Returns:
            pygame.font.Font nesnesi.
        """
        cache_key = f"{path}_{size}"

        if cache_key in self._font_cache:
            return self._font_cache[cache_key]

        if path is None:
            font = pygame.font.Font(None, size)
        else:
            full_path = os.path.join(self._ASSETS_DIR, "fonts", path)
            if os.path.exists(full_path):
                font = pygame.font.Font(full_path, size)
            else:
                _logger.warning("Font bulunamadı: %s — varsayılan kullanılıyor",
                                full_path)
                font = pygame.font.Font(None, size)

        self._font_cache[cache_key] = font
        return font

    # ══════════════════════════════════════════
    #  Dahili Yardımcılar
    # ══════════════════════════════════════════

    @staticmethod
    def _create_placeholder(size: tuple) -> pygame.Surface:
        """Eksik asset için magenta renkli yer tutucu oluşturur."""
        surface = pygame.Surface(size, pygame.SRCALPHA)
        surface.fill((255, 0, 255, 180))  # Magenta — hata göstergesi
        return surface

    def clear_cache(self) -> None:
        """Tüm önbelleği temizler (sahne geçişlerinde kullanılır)."""
        self._image_cache.clear()
        self._sound_cache.clear()
        self._font_cache.clear()
        _logger.info("Asset önbelleği temizlendi.")
