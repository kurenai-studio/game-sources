"""
Shinrin CS — Ana Oyun Motoru.

Tüm alt sistemleri (SceneManager, InputHandler, AssetManager,
Camera, Renderer) bir araya getiren merkezi sınıf.
Oyun döngüsünü (game loop) yönetir.
"""

import sys
import pygame
from engine.settings import Settings
from engine.scene_manager import SceneManager
from engine.input_handler import InputHandler
from engine.asset_manager import AssetManager
from engine.camera import Camera
from engine.renderer import Renderer
from engine.save_manager import SaveManager
from utils.logger import get_logger

_logger = get_logger("GameEngine")


class GameEngine:
    """
    Ana oyun motoru sınıfı.

    Sorumlu olduğu alt sistemler:
    - Settings: Oyun ayarları
    - SceneManager: Sahne yönetimi
    - InputHandler: Girdi işleme
    - AssetManager: Asset yükleme
    - Camera: Kamera sistemi
    - Renderer: Çizim katmanı
    - SaveManager: Kayıt/yükleme

    Attributes:
        _running (bool): Oyun döngüsü çalışıyor mu?
        _clock (Clock): FPS zamanlayıcı.
    """

    def __init__(self):
        _logger.info("=" * 50)
        _logger.info("Shinrin CS — Motor başlatılıyor...")
        _logger.info("=" * 50)

        # ── Pygame Başlatma ──
        pygame.init()
        pygame.mixer.init()
        pygame.font.init()

        # ── Ayarlar ──
        self._settings = Settings()

        # ── Ekran ──
        flags = 0
        if self._settings.fullscreen:
            flags |= pygame.FULLSCREEN
        self._screen = pygame.display.set_mode(
            self._settings.screen_size, flags
        )
        pygame.display.set_caption(self._settings.game_title)

        # ── Alt Sistemler ──
        self._clock = pygame.time.Clock()
        self._running: bool = False
        self._input_handler = InputHandler()
        self._asset_manager = AssetManager()
        self._camera = Camera(
            self._settings.screen_width,
            self._settings.screen_height
        )
        self._renderer = Renderer(self._screen)
        self._scene_manager = SceneManager()
        self._save_manager = SaveManager()

        # ── Sahneleri Kaydet ──
        self._register_scenes()

        _logger.info("Motor başarıyla başlatıldı.")

    # ══════════════════════════════════════════
    #  Sahne Kaydı
    # ══════════════════════════════════════════

    def _register_scenes(self) -> None:
        """Tüm oyun sahnelerini SceneManager'a kaydeder."""
        from scenes.title_scene import TitleScene
        from scenes.world_scene import WorldScene
        from scenes.pause_scene import PauseScene
        from scenes.inventory_scene import InventoryScene
        from scenes.game_over_scene import GameOverScene
        from scenes.settings_scene import SettingsScene

        self._scene_manager.register_scene("title", TitleScene(self))
        self._scene_manager.register_scene("world", WorldScene(self))
        self._scene_manager.register_scene("pause", PauseScene(self))
        self._scene_manager.register_scene("inventory", InventoryScene(self))
        self._scene_manager.register_scene("game_over", GameOverScene(self))
        self._scene_manager.register_scene("settings", SettingsScene(self))
        _logger.debug("Sahneler kaydedildi.")

    # ══════════════════════════════════════════
    #  Oyun Döngüsü
    # ══════════════════════════════════════════

    def run(self) -> None:
        """
        Ana oyun döngüsünü başlatır.
        Başlık sahnesinden itibaren oyunu çalıştırır.
        """
        self._running = True
        self._scene_manager.switch_scene("title")

        _logger.info("Oyun döngüsü başladı. FPS: %d", self._settings.fps)

        while self._running:
            dt = self._clock.tick(self._settings.fps) / 1000.0
            dt = min(dt, 0.05)  # Max 50ms (lag koruması)

            self._process_events()
            self._update(dt)
            self._render()

        self._shutdown()

    def _process_events(self) -> None:
        """Pygame olay kuyruğunu işler."""
        events = pygame.event.get()
        self._input_handler.process_events(events)

        if self._input_handler.quit_requested:
            self.quit()

    def _update(self, dt: float) -> None:
        """Aktif sahneyi ve alt sistemleri günceller."""
        self._scene_manager.handle_input(self._input_handler)
        self._scene_manager.update(dt)

    def _render(self) -> None:
        """Aktif sahneyi çizer ve ekrana yansıtır."""
        self._scene_manager.draw(self._screen)

        # Debug overlay
        if self._settings.show_fps:
            current_scene = self._scene_manager.get_current_scene()
            entity_count = (
                current_scene.entity_count if current_scene else 0
            )
            self._renderer.draw_debug_info(
                self._clock.get_fps(), entity_count
            )

        self._renderer.present()

    # ══════════════════════════════════════════
    #  Kontrol
    # ══════════════════════════════════════════

    def quit(self) -> None:
        """Oyun döngüsünü sonlandırır."""
        _logger.info("Oyundan çıkış istendi.")
        self._running = False

    def _shutdown(self) -> None:
        """Tüm alt sistemleri kapatır ve çıkar."""
        _logger.info("Motor kapatılıyor...")
        self._settings.save()
        pygame.mixer.quit()
        pygame.font.quit()
        pygame.quit()
        _logger.info("Motor başarıyla kapatıldı.")

    # ══════════════════════════════════════════
    #  Alt Sistem Erişimi (Read-only Properties)
    # ══════════════════════════════════════════

    @property
    def settings(self) -> Settings:
        return self._settings

    @property
    def scene_manager(self) -> SceneManager:
        return self._scene_manager

    @property
    def input_handler(self) -> InputHandler:
        return self._input_handler

    @property
    def asset_manager(self) -> AssetManager:
        return self._asset_manager

    @property
    def camera(self) -> Camera:
        return self._camera

    @property
    def renderer(self) -> Renderer:
        return self._renderer

    @property
    def save_manager(self) -> SaveManager:
        return self._save_manager

    @property
    def screen(self) -> pygame.Surface:
        return self._screen
