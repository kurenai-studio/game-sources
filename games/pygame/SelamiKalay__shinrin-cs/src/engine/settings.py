"""
Shinrin CS — Oyun Ayarları ve Konfigürasyon.

Runtime sırasında değiştirilebilen ayarları yönetir.
Sabitler (constants.py) ile karıştırılmamalıdır; buradaki
değerler JSON dosyasından yüklenebilir ve kaydedilebilir.
"""

import json
import os
from utils.constants import (
    SCREEN_WIDTH, SCREEN_HEIGHT, FPS, GAME_TITLE
)
from utils.logger import get_logger

_logger = get_logger("Settings")


class Settings:
    """
    Oyun ayarlarını yöneten singleton-benzeri sınıf.

    Varsayılan değerler constants.py'den alınır.
    Kullanıcı değişiklikleri settings.json dosyasına kaydedilir.
    """

    _CONFIG_FILE = "settings.json"

    def __init__(self):
        # ── Ekran Ayarları ──
        self._screen_width: int = SCREEN_WIDTH
        self._screen_height: int = SCREEN_HEIGHT
        self._fps: int = FPS
        self._fullscreen: bool = False
        self._vsync: bool = True

        # ── Ses Ayarları ──
        self._music_volume: int = 70
        self._sfx_volume: int = 80
        self._mute: bool = False

        # ── Oyun Ayarları ──
        self._game_title: str = GAME_TITLE
        self._language: str = "tr"
        self._show_fps: bool = False
        self._difficulty: str = "Normal"

        # Dosyadan yükle (varsa)
        self._load()

    # ══════════════════════════════════════════
    #  Properties (Read/Write)
    # ══════════════════════════════════════════

    @property
    def screen_width(self) -> int:
        return self._screen_width

    @property
    def screen_height(self) -> int:
        return self._screen_height

    @property
    def screen_size(self) -> tuple:
        return (self._screen_width, self._screen_height)

    @property
    def fps(self) -> int:
        return self._fps

    @property
    def fullscreen(self) -> bool:
        return self._fullscreen

    @fullscreen.setter
    def fullscreen(self, value: bool):
        self._fullscreen = value

    @property
    def vsync(self) -> bool:
        return self._vsync

    @property
    def music_volume(self) -> int:
        return self._music_volume

    @music_volume.setter
    def music_volume(self, value: int):
        self._music_volume = max(0, min(100, int(value)))

    @property
    def sfx_volume(self) -> int:
        return self._sfx_volume

    @sfx_volume.setter
    def sfx_volume(self, value: int):
        self._sfx_volume = max(0, min(100, int(value)))

    @property
    def mute(self) -> bool:
        return self._mute

    @mute.setter
    def mute(self, value: bool):
        self._mute = value

    @property
    def game_title(self) -> str:
        return self._game_title

    @property
    def show_fps(self) -> bool:
        return self._show_fps

    @show_fps.setter
    def show_fps(self, value: bool):
        self._show_fps = value

    @property
    def difficulty(self) -> str:
        return self._difficulty

    @difficulty.setter
    def difficulty(self, value: str):
        if value in ('Kolay', 'Normal', 'Zor'):
            self._difficulty = value

    # ══════════════════════════════════════════
    #  Kaydetme / Yükleme
    # ══════════════════════════════════════════

    def save(self) -> None:
        """Mevcut ayarları JSON dosyasına kaydeder."""
        data = {
            "screen_width": self._screen_width,
            "screen_height": self._screen_height,
            "fps": self._fps,
            "fullscreen": self._fullscreen,
            "vsync": self._vsync,
            "music_volume": self._music_volume,
            "sfx_volume": self._sfx_volume,
            "mute": self._mute,
            "language": self._language,
            "show_fps": self._show_fps,
            "difficulty": self._difficulty,
        }
        try:
            with open(self._CONFIG_FILE, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            _logger.info("Ayarlar kaydedildi: %s", self._CONFIG_FILE)
        except OSError as e:
            _logger.error("Ayarlar kaydedilemedi: %s", e)

    def _load(self) -> None:
        """JSON dosyasından ayarları yükler (varsa)."""
        if not os.path.exists(self._CONFIG_FILE):
            return
        try:
            with open(self._CONFIG_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
            self._screen_width = data.get("screen_width", self._screen_width)
            self._screen_height = data.get("screen_height", self._screen_height)
            self._fps = data.get("fps", self._fps)
            self._fullscreen = data.get("fullscreen", self._fullscreen)
            self._vsync = data.get("vsync", self._vsync)
            self._music_volume = data.get("music_volume", self._music_volume)
            self._sfx_volume = data.get("sfx_volume", self._sfx_volume)
            self._mute = data.get("mute", self._mute)
            self._language = data.get("language", self._language)
            self._show_fps = data.get("show_fps", self._show_fps)
            self._difficulty = data.get("difficulty", self._difficulty)
            _logger.info("Ayarlar yüklendi: %s", self._CONFIG_FILE)
        except (OSError, json.JSONDecodeError) as e:
            _logger.warning("Ayar dosyası okunamadı, varsayılanlar: %s", e)
