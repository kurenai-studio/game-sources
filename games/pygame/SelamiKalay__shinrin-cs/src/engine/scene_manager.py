"""
Shinrin CS — Sahne Yönetim Sistemi.

State Pattern ile oyun sahnelerini yönetir.
Sahne yığını (stack) kullanarak üst üste binen
sahneleri (örn: pause overlay) destekler.
"""

from __future__ import annotations

import pygame
from utils.logger import get_logger

_logger = get_logger("SceneManager")


class SceneManager:
    """
    Sahne yöneticisi. Aktif sahneyi ve sahne yığınını kontrol eder.

    Sahneler isimleriyle kaydedilir ve geçiş yapılır.
    Yığın (stack) desteği ile overlay sahneler mümkündür.
    """

    def __init__(self):
        self._scenes: dict = {}           # İsim → BaseScene eşlemesi
        self._current_scene = None        # Aktif sahne
        self._scene_stack: list = []      # Sahne yığını (overlay'ler için)
        self._pending_switch: str | None = None
        _logger.info("SceneManager başlatıldı.")

    # ══════════════════════════════════════════
    #  Sahne Kaydı
    # ══════════════════════════════════════════

    def register_scene(self, name: str, scene) -> None:
        """
        Bir sahneyi isme bağlı olarak kaydeder.

        Args:
            name: Sahne adı (örn: "title", "world", "battle").
            scene: BaseScene alt sınıfı instance'ı.
        """
        self._scenes[name] = scene
        _logger.debug("Sahne kaydedildi: '%s'", name)

    # ══════════════════════════════════════════
    #  Sahne Geçişleri
    # ══════════════════════════════════════════

    def switch_scene(self, name: str) -> None:
        """
        Mevcut sahneden çıkıp yeni sahneye geçer.

        Args:
            name: Geçilecek sahnenin adı.

        Raises:
            KeyError: Sahne bulunamazsa.
        """
        if name not in self._scenes:
            raise KeyError(f"Sahne bulunamadı: '{name}'")

        # Mevcut sahneden çık
        if self._current_scene is not None:
            self._current_scene.exit()
            _logger.debug("Sahneden çıkıldı: '%s'",
                          self._get_scene_name(self._current_scene))

        # Yeni sahneye geç
        self._current_scene = self._scenes[name]
        self._current_scene.enter()
        _logger.info("Sahne değiştirildi → '%s'", name)

    def push_scene(self, name: str) -> None:
        """
        Mevcut sahneyi yığına atar ve yeni sahneye geçer.
        Üst üste sahneler için kullanılır (örn: pause menü).

        Args:
            name: Yığına eklenecek sahnenin adı.
        """
        if name not in self._scenes:
            raise KeyError(f"Sahne bulunamadı: '{name}'")

        if self._current_scene is not None:
            self._scene_stack.append(self._current_scene)

        self._current_scene = self._scenes[name]
        self._current_scene.enter()
        _logger.info("Sahne yığına eklendi → '%s' (yığın: %d)",
                     name, len(self._scene_stack))

    def pop_scene(self) -> None:
        """
        Mevcut sahneyi kapatıp yığındaki önceki sahneye döner.
        """
        if self._current_scene is not None:
            self._current_scene.exit()

        if self._scene_stack:
            self._current_scene = self._scene_stack.pop()
            _logger.info("Önceki sahneye dönüldü (yığın: %d)",
                         len(self._scene_stack))
        else:
            self._current_scene = None
            _logger.warning("Sahne yığını boş — aktif sahne yok.")

    # ══════════════════════════════════════════
    #  Frame İşlemleri
    # ══════════════════════════════════════════

    def handle_input(self, input_handler) -> None:
        """Aktif sahneye girdi olaylarını iletir."""
        if self._current_scene is not None:
            self._current_scene.handle_input(input_handler)

    def update(self, dt: float) -> None:
        """Aktif sahneyi günceller."""
        if self._current_scene is not None:
            self._current_scene.update(dt)

    def draw(self, surface: pygame.Surface) -> None:
        """Aktif sahneyi çizer."""
        if self._current_scene is not None:
            self._current_scene.draw(surface)

    # ══════════════════════════════════════════
    #  Yardımcılar
    # ══════════════════════════════════════════

    def get_current_scene(self):
        """Aktif sahneyi döndürür."""
        return self._current_scene

    def get_current_scene_name(self) -> str | None:
        """Aktif sahnenin adını döndürür."""
        return self._get_scene_name(self._current_scene)

    def get_scene(self, name: str):
        """İsme göre kayıtlı sahneyi döndürür."""
        return self._scenes.get(name)

    def _get_scene_name(self, scene) -> str | None:
        """Sahne nesnesinden adını bulur."""
        for name, s in self._scenes.items():
            if s is scene:
                return name
        return None
