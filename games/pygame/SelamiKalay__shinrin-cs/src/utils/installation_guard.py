"""
Shinrin CS — Tekil Kurulum Kontrol Mekanizması.

İki katmanlı doğrulama ile bir bilgisayarda sadece bir kez
kurulumu garanti eder:
  1. Windows Registry (HKCU\\Software\\ShinrinCS)
  2. AppData gizli marker dosyası

Uninstall işlemi sonrası bile anahtar ve marker kalıcı
olarak korunur.
"""

import os
import uuid
import hashlib
import platform
from datetime import datetime
from pathlib import Path

from utils.logger import get_logger

_logger = get_logger("InstallationGuard")

# ── Platform kontrolü: Registry sadece Windows'ta çalışır ──
_IS_WINDOWS = platform.system() == "Windows"
if _IS_WINDOWS:
    import winreg


class InstallationGuard:
    """
    Tekil Kurulum Kontrol Sınıfı.

    Attributes:
        REGISTRY_PATH (str): Registry anahtarı yolu.
        MARKER_FILENAME (str): Gizli marker dosyasının adı.
    """

    REGISTRY_PATH = r"Software\ShinrinCS"
    REGISTRY_KEY_GUID = "InstallGUID"
    REGISTRY_KEY_DATE = "InstallDate"
    REGISTRY_KEY_HASH = "InstallHash"
    MARKER_FILENAME = ".shinrin_cs_installed"

    def __init__(self):
        self._marker_path = Path(
            os.environ.get("LOCALAPPDATA", os.path.expanduser("~"))
        ) / self.MARKER_FILENAME

    # ══════════════════════════════════════════
    #  Kontrol Metotları
    # ══════════════════════════════════════════

    def is_installed(self) -> bool:
        """
        Kurulumun daha önce yapılıp yapılmadığını kontrol eder.

        Returns:
            True ise daha önce kurulum yapılmış demektir.
        """
        registry_ok = self._check_registry()
        marker_ok = self._check_marker_file()
        result = registry_ok or marker_ok

        if result:
            _logger.info("Kurulum kaydı bulundu (registry=%s, marker=%s)",
                         registry_ok, marker_ok)
        return result

    def _check_registry(self) -> bool:
        """Windows Registry'de kurulum anahtarı var mı kontrol eder."""
        if not _IS_WINDOWS:
            return False
        try:
            key = winreg.OpenKey(
                winreg.HKEY_CURRENT_USER,
                self.REGISTRY_PATH,
                0,
                winreg.KEY_READ
            )
            value, _ = winreg.QueryValueEx(key, self.REGISTRY_KEY_GUID)
            winreg.CloseKey(key)
            return bool(value)
        except FileNotFoundError:
            return False
        except OSError:
            return False

    def _check_marker_file(self) -> bool:
        """AppData'da gizli marker dosyası var mı kontrol eder."""
        return self._marker_path.exists()

    # ══════════════════════════════════════════
    #  Kayıt Metotları
    # ══════════════════════════════════════════

    def register_installation(self) -> str:
        """
        Kurulumu her iki katmanda da kaydeder.

        Returns:
            Oluşturulan benzersiz kurulum GUID'i.

        Raises:
            RuntimeError: Registry veya dosya yazımı başarısız olursa.
        """
        install_guid = str(uuid.uuid4())
        machine_hash = self._generate_machine_hash()
        install_date = datetime.now().isoformat()

        self._write_registry(install_guid, install_date, machine_hash)
        self._write_marker_file(install_guid)

        _logger.info("Kurulum kaydedildi: GUID=%s", install_guid)
        return install_guid

    def _write_registry(self, guid: str, date: str, hash_val: str) -> None:
        """
        Registry'ye kurulum bilgilerini yazar.

        Args:
            guid: Benzersiz kurulum kimliği.
            date: Kurulum tarihi (ISO 8601).
            hash_val: Makine parmak izi hash'i.
        """
        if not _IS_WINDOWS:
            _logger.warning("Windows değil — Registry yazılamadı.")
            return
        try:
            key = winreg.CreateKey(
                winreg.HKEY_CURRENT_USER,
                self.REGISTRY_PATH
            )
            winreg.SetValueEx(
                key, self.REGISTRY_KEY_GUID, 0, winreg.REG_SZ, guid
            )
            winreg.SetValueEx(
                key, self.REGISTRY_KEY_DATE, 0, winreg.REG_SZ, date
            )
            winreg.SetValueEx(
                key, self.REGISTRY_KEY_HASH, 0, winreg.REG_SZ, hash_val
            )
            winreg.CloseKey(key)
            _logger.debug("Registry anahtarı yazıldı: %s", self.REGISTRY_PATH)
        except OSError as e:
            raise RuntimeError(f"Registry yazma hatası: {e}")

    def _write_marker_file(self, guid: str) -> None:
        """
        AppData'da gizli marker dosyası oluşturur.

        Args:
            guid: Dosyaya yazılacak kurulum GUID'i.
        """
        try:
            self._marker_path.write_text(guid, encoding="utf-8")
            # Dosyayı gizli yap (sadece Windows)
            if _IS_WINDOWS:
                import ctypes
                ctypes.windll.kernel32.SetFileAttributesW(
                    str(self._marker_path), 0x02  # FILE_ATTRIBUTE_HIDDEN
                )
            _logger.debug("Marker dosyası yazıldı: %s", self._marker_path)
        except OSError as e:
            raise RuntimeError(f"Marker dosya yazma hatası: {e}")

    def _generate_machine_hash(self) -> str:
        """
        Makine + kullanıcı bilgisinden benzersiz parmak izi üretir.

        Returns:
            SHA-256 hash dizesi.
        """
        raw = (
            f"{platform.node()}-"
            f"{os.environ.get('USERNAME', 'unknown')}-"
            f"{platform.machine()}"
        )
        return hashlib.sha256(raw.encode()).hexdigest()
