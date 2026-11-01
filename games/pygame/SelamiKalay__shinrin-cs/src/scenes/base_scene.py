"""
Shinrin CS — Soyut Temel Sahne Sınıfı.

Tüm oyun sahneleri (TitleScene, WorldScene, BattleScene vb.)
bu sınıftan türer. State Pattern'in temelini oluşturur.
"""

from abc import ABC, abstractmethod
import pygame


class BaseScene(ABC):
    """
    Tüm sahnelerin soyut temel sınıfı.

    Her sahne kendi entity listesini ve UI elementlerini
    yönetir. Yaşam döngüsü metotları: enter() → update() →
    draw() → exit().

    Attributes:
        _game_engine: Ana oyun motoru referansı.
        _entities (list): Sahnedeki entity listesi.
        _ui_elements (list): Sahnedeki UI elementleri.
    """

    def __init__(self, game_engine):
        self._game_engine = game_engine
        self._entities: list = []
        self._ui_elements: list = []

    # ══════════════════════════════════════════
    #  Yaşam Döngüsü (Alt sınıflar ezer)
    # ══════════════════════════════════════════

    @abstractmethod
    def enter(self) -> None:
        """
        Sahneye girildiğinde çağrılır.
        Kaynakları yükle, entity'leri oluştur.
        """
        pass

    @abstractmethod
    def exit(self) -> None:
        """
        Sahneden çıkıldığında çağrılır.
        Kaynakları serbest bırak, temizle.
        """
        pass

    @abstractmethod
    def handle_input(self, input_handler) -> None:
        """
        Girdi olaylarını işler.

        Args:
            input_handler: InputHandler referansı.
        """
        pass

    @abstractmethod
    def update(self, dt: float) -> None:
        """
        Sahne mantığını günceller.

        Args:
            dt: Delta time (saniye).
        """
        pass

    @abstractmethod
    def draw(self, surface: pygame.Surface) -> None:
        """
        Sahneyi ekrana çizer.

        Args:
            surface: Çizim yapılacak Surface.
        """
        pass

    # ══════════════════════════════════════════
    #  Ortak İşlevler
    # ══════════════════════════════════════════

    def update_entities(self, dt: float) -> None:
        """Tüm entity'leri polimorfik olarak günceller."""
        for entity in self._entities:
            if entity.active:
                entity.update(dt)

    def draw_entities(self, surface: pygame.Surface, camera=None) -> None:
        """Tüm entity'leri polimorfik olarak çizer."""
        for entity in self._entities:
            if entity.visible:
                entity.draw(surface, camera)

    def add_entity(self, entity) -> None:
        """Sahneye entity ekler."""
        self._entities.append(entity)

    def remove_entity(self, entity) -> None:
        """Sahneden entity çıkarır."""
        if entity in self._entities:
            self._entities.remove(entity)

    @property
    def entity_count(self) -> int:
        return len(self._entities)
