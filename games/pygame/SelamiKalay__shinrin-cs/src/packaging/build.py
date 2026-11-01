"""
Shinrin CS — PyInstaller Build Script.

Oyunu tek dosyalık .exe'ye paketler. Paketleme ayarları
packaging/ShinrinCS.spec dosyasındadır; bu betik yalnızca onu çalıştırır.
Kullanım (proje kökünden): py packaging/build.py
Çıktı: dist/ShinrinCS.exe
"""

import os
import subprocess
import sys

PACKAGING_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(PACKAGING_DIR)


def build():
    """PyInstaller ile .exe oluşturur."""
    print("=" * 50)
    print("Shinrin CS — Build başlıyor...")
    print("=" * 50)

    cmd = [
        sys.executable, "-m", "PyInstaller", "--noconfirm",
        os.path.join(PACKAGING_DIR, "ShinrinCS.spec"),
    ]

    print("Komut:", " ".join(cmd))
    result = subprocess.run(cmd, cwd=ROOT)

    if result.returncode == 0:
        print("\n" + "=" * 50)
        print("Build başarılı! → dist/ShinrinCS.exe")
        print("=" * 50)
    else:
        print("\nBuild BAŞARISIZ!")
        sys.exit(1)


if __name__ == "__main__":
    build()
