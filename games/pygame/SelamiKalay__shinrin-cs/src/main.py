"""
Shinrin CS — Giriş Noktası (Entry Point).

Tekil kurulum kontrolünü doğrular ve oyun motorunu başlatır.
"""

import sys
import os

# Proje kök dizinini Python path'e ekle
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# PyInstaller ile derlenmişse, çalışma ortamını exe'nin olduğu klasöre sabitle.
# Bu sayede masaüstü kısayollarından açıldığında assets/data klasörleri doğru bulunur!
if getattr(sys, 'frozen', False):
    os.chdir(os.path.dirname(sys.executable))
    
from utils.installation_guard import InstallationGuard
from utils.logger import get_logger

_logger = get_logger("Main")


def main():
    """Ana giriş fonksiyonu."""
    _logger.info("=" * 50)
    _logger.info("Shinrin CS başlatılıyor...")
    _logger.info("=" * 50)

    # ── Tekil Kurulum Kontrolü ──
    guard = InstallationGuard()

    if guard.is_installed():
        _logger.info("Kurulum kaydı doğrulandı — oyun başlatılıyor.")
    else:
        # İlk çalışma: kurulumu kaydet
        try:
            guid = guard.register_installation()
            _logger.info("İlk çalışma — kurulum kaydedildi: %s", guid)
        except RuntimeError as e:
            _logger.error("Kurulum kaydı başarısız: %s", e)
            # Kayıt başarısız olsa bile oyunu başlat (geliştirme modu)

    # ── Oyun Motorunu Başlat ──
    try:
        from engine.game_engine import GameEngine
        engine = GameEngine()
        engine.run()
    except Exception as e:
        _logger.critical("Kritik hata: %s", e, exc_info=True)
        sys.exit(1)

    _logger.info("Shinrin CS kapatıldı.")
    sys.exit(0)


if __name__ == "__main__":
    main()
