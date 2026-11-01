# Shinrin CS

[English](README.md) | **Türkçe**

Python ve pygame ile geliştirilmiş, 2D üstten görünümlü bir RPG oyunu. Nesne
yönelimli programlama dersi kapsamında; kalıtım, kapsülleme ve çok biçimlilik
prensipleri üzerine kurulu bir oyun motoru mimarisiyle yazılmıştır.

## Özellikler

- **Sahne sistemi** — başlık, dünya, envanter, duraklatma, ayarlar ve oyun sonu sahneleri
- **Sıra tabanlı savaş sistemi**, çarpışma ve diyalog sistemleri
- **Karo (tile) tabanlı dünya haritası** ve bölgeler, takip eden kamera
- **Envanter** — ekipman ve tüketilebilir eşyalar
- **Kayıt / yükleme** sistemi ve kalıcı ayarlar (ses, çözünürlük, zorluk, dil)
- PyInstaller ile tek dosyalık `.exe` ve Inno Setup ile kurulum paketi oluşturma
- **Tekil kurulum koruması** (ödev gereksinimi — aşağıya bakın)

## Mimari

```
engine/     Oyun döngüsü, sahne yöneticisi, render, kamera, girdi, kayıt, ayarlar
entities/   GameObject → Entity → Character → Player / Enemy / NPC
            Item → Equipment / Consumable, Interactable
scenes/     Oyun sahneleri (BaseScene'den türetilir)
systems/    Savaş, çarpışma ve diyalog sistemleri
world/      Tile, TileMap, WorldMap, Zone
utils/      Sabitler, yardımcılar, loglama, kurulum koruması
tests/      Entity hiyerarşisi için birim testleri (unittest)
```

## Kontroller

| Tuş | İşlev |
|---|---|
| `W A S D` / Yön tuşları | Hareket ve menü gezinme |
| `Enter` / `Z` | Onayla / etkileşim |
| `Esc` / `X` | Geri / iptal |
| `P` | Duraklat |
| `I` | Envanter |
| `Q` / `E` | Envanter sekmeleri arasında geçiş |

## Kurulum ve Çalıştırma

```bash
pip install -r requirements.txt
python main.py
```

Testler:

```bash
python -m unittest discover tests
```

Windows için `.exe` oluşturma (PyInstaller gerekir):

```bash
python packaging/build.py     # → dist/ShinrinCS.exe
```

Paketleme dosyaları (PyInstaller `.spec` dosyaları, Inno Setup betiği ve kurulum
sihirbazı) `packaging/` klasöründedir.

## Tekil Kurulum Koruması (ödev gereksinimi)

Ödevin konularından biri, oyunun **bir bilgisayara yalnızca bir kez
kurulabilmesini** sağlayan bir kopya/kurulum koruması yazmaktı. Kaldırma işlemi
koruma kayıtlarını bilerek silmez; bu yüzden aynı bilgisayara tekrar kurulum
engellenir. Koruma üç katmanda uygulanır:

| Katman | Dosya | Bıraktığı iz |
|---|---|---|
| Inno Setup kurulumu | `packaging/installer.iss` | `HKLM\SOFTWARE\ShinrinCS\InstallGuard`, `%ProgramData%\ShinrinCS\.installed` |
| Python kurulum sihirbazı | `packaging/custom_installer.py` | aynı kayıt defteri anahtarı ve dosya |
| Oyunun kendisi | `utils/installation_guard.py` | `HKCU\Software\ShinrinCS`, `%LOCALAPPDATA%\.shinrin_cs_installed` |

Hata mesajındaki "lisans politikası" ve destek adresi, ödev senaryosunun
parçasıdır. Bu bir eğitim örneğidir; kayıt defteri ve dosya izlerini silen biri
korumayı aşabilir.

Test için korumayı sıfırlamak (Windows, yönetici komut istemi):

```bat
reg delete "HKLM\SOFTWARE\ShinrinCS" /f
reg delete "HKCU\Software\ShinrinCS" /f
del /a "%ProgramData%\ShinrinCS\.installed" "%LOCALAPPDATA%\.shinrin_cs_installed"
```

`python main.py` ile geliştirme sırasında çalıştırmak da oyun katmanının izlerini
bırakır (Windows dışında yalnızca `~/.shinrin_cs_installed` dosyası).
