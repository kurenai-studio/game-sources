"""
Shinrin CS — Kayıt / Yükleme Sistemi.

Oyun ilerlemesini JSON formatında kaydeder ve yükler.
Birden fazla kayıt slotu destekler.
"""

from __future__ import annotations

import json
import os
from datetime import datetime
from utils.constants import SAVE_DIR, MAX_SAVE_SLOTS
from utils.logger import get_logger

_logger = get_logger("SaveManager")


class SaveManager:
    """
    Kayıt/yükleme yönetim sınıfı.

    Oyun durumunu JSON formatında saklar.
    """

    def __init__(self):
        self._save_dir = SAVE_DIR
        os.makedirs(self._save_dir, exist_ok=True)
        _logger.info("SaveManager başlatıldı. Dizin: %s", self._save_dir)

    def save_game(self, slot: int, game_data: dict) -> bool:
        """
        Oyunu belirtilen slota kaydeder.

        Args:
            slot: Kayıt slotu (1 – MAX_SAVE_SLOTS).
            game_data: Kaydedilecek oyun verisi (serializable dict).

        Returns:
            True ise kayıt başarılı.
        """
        if not 1 <= slot <= MAX_SAVE_SLOTS:
            _logger.error("Geçersiz kayıt slotu: %d", slot)
            return False

        save_data = {
            "meta": {
                "slot": slot,
                "timestamp": datetime.now().isoformat(),
                "version": "1.0"
            },
            "game": game_data
        }

        filepath = self._get_filepath(slot)
        try:
            with open(filepath, "w", encoding="utf-8") as f:
                json.dump(save_data, f, indent=2, ensure_ascii=False)
            _logger.info("Oyun kaydedildi: Slot %d → %s", slot, filepath)
            return True
        except OSError as e:
            _logger.error("Kayıt yazılamadı (Slot %d): %s", slot, e)
            return False

    def load_game(self, slot: int) -> dict | None:
        """
        Belirtilen slottan oyun verisi yükler.

        Args:
            slot: Yüklenecek kayıt slotu.

        Returns:
            Oyun verisi dict veya None (bulunamazsa / hatalıysa).
        """
        filepath = self._get_filepath(slot)

        if not os.path.exists(filepath):
            _logger.warning("Kayıt dosyası bulunamadı: Slot %d", slot)
            return None

        try:
            with open(filepath, "r", encoding="utf-8") as f:
                save_data = json.load(f)
            _logger.info("Oyun yüklendi: Slot %d", slot)
            return save_data.get("game", {})
        except (OSError, json.JSONDecodeError) as e:
            _logger.error("Kayıt okunamadı (Slot %d): %s", slot, e)
            return None

    def get_save_info(self, slot: int) -> dict | None:
        """
        Belirtilen slotun meta bilgisini döndürür (ön izleme için).

        Returns:
            Meta dict veya None.
        """
        filepath = self._get_filepath(slot)

        if not os.path.exists(filepath):
            return None

        try:
            with open(filepath, "r", encoding="utf-8") as f:
                data = json.load(f)
            return data.get("meta", {})
        except (OSError, json.JSONDecodeError):
            return None

    def delete_save(self, slot: int) -> bool:
        """Belirtilen slottaki kaydı siler."""
        filepath = self._get_filepath(slot)

        if os.path.exists(filepath):
            os.remove(filepath)
            _logger.info("Kayıt silindi: Slot %d", slot)
            return True
        return False

    def get_all_saves(self) -> list[dict | None]:
        """Tüm slotların meta bilgilerini listeler."""
        return [self.get_save_info(i) for i in range(1, MAX_SAVE_SLOTS + 1)]

    def _get_filepath(self, slot: int) -> str:
        """Slot numarasına göre dosya yolunu oluşturur."""
        return os.path.join(self._save_dir, f"save_{slot}.json")
