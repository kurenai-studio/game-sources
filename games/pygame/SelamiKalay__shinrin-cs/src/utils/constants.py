"""
Shinrin CS — Genel Sabitler ve Konfigürasyon Değerleri.

Bu modül oyunun tamamında kullanılan sabitleri merkezi bir
noktada tanımlar. Renkler, boyutlar, FPS ve tile ölçüleri
burada bulunur.
"""

# ══════════════════════════════════════════════
#  Ekran Ayarları
# ══════════════════════════════════════════════
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
FPS = 60
GAME_TITLE = "Shinrin CS"

# ══════════════════════════════════════════════
#  Tile / Harita Ayarları
# ══════════════════════════════════════════════
TILE_SIZE = 32          # Piksel cinsinden tek karo boyutu
CHUNK_SIZE = 16         # Bir chunk kaç karo genişliğinde
MAP_LAYERS = 3          # Zemin, objeler, üst katman

# ══════════════════════════════════════════════
#  Oyuncu Ayarları
# ══════════════════════════════════════════════
PLAYER_SPEED = 150.0    # Piksel/saniye
PLAYER_ANIM_SPEED = 0.15  # Animasyon kare süresi (saniye)

# ══════════════════════════════════════════════
#  Renk Paleti (JRPG Pixel Art Teması)
# ══════════════════════════════════════════════
# Ana Renkler
COLOR_BLACK = (0, 0, 0)
COLOR_WHITE = (255, 255, 255)
COLOR_BG_DARK = (15, 15, 25)           # Koyu arka plan
COLOR_BG_MEDIUM = (25, 28, 40)         # Orta koyu arka plan

# Orman Teması
COLOR_FOREST_DARK = (20, 50, 30)       # Koyu orman yeşili
COLOR_FOREST_GREEN = (34, 111, 84)     # Ana orman yeşili
COLOR_FOREST_LIGHT = (76, 175, 80)     # Açık yeşil
COLOR_FOREST_MOSS = (85, 107, 47)      # Yosun yeşili

# Sakura / Japon Teması
COLOR_SAKURA_PINK = (255, 183, 197)    # Sakura pembesi
COLOR_SAKURA_DARK = (219, 112, 147)    # Koyu sakura
COLOR_TORII_RED = (188, 36, 36)        # Torii kapısı kırmızısı
COLOR_GOLD = (255, 215, 0)             # Altın / tapınak teması

# UI Renkleri
COLOR_UI_BG = (20, 20, 35, 220)       # Yarı saydam UI arka planı
COLOR_UI_BORDER = (80, 80, 120)        # UI kenarlık
COLOR_UI_TEXT = (230, 230, 240)        # UI metin rengi
COLOR_UI_HIGHLIGHT = (100, 149, 237)   # Seçili öğe vurgusu
COLOR_UI_SHADOW = (10, 10, 20)        # Gölge rengi

# Savaş UI
COLOR_HP_BAR = (76, 175, 80)           # Can barı (yeşil)
COLOR_HP_BAR_LOW = (244, 67, 54)       # Düşük can barı (kırmızı)
COLOR_MP_BAR = (66, 133, 244)          # Mana barı (mavi)
COLOR_EXP_BAR = (255, 193, 7)         # Deneyim barı (sarı)

# ══════════════════════════════════════════════
#  Yönler
# ══════════════════════════════════════════════
DIR_UP = "up"
DIR_DOWN = "down"
DIR_LEFT = "left"
DIR_RIGHT = "right"

# ══════════════════════════════════════════════
#  Oyun Durumları
# ══════════════════════════════════════════════
STATE_IDLE = "idle"
STATE_WALKING = "walking"
STATE_ATTACKING = "attacking"
STATE_HURT = "hurt"
STATE_DEAD = "dead"

# ══════════════════════════════════════════════
#  Kayıt Dosya Yolu
# ══════════════════════════════════════════════
SAVE_DIR = "saves"
MAX_SAVE_SLOTS = 3

# ══════════════════════════════════════════════
#  Font Boyutları
# ══════════════════════════════════════════════
FONT_SIZE_SMALL = 14
FONT_SIZE_MEDIUM = 20
FONT_SIZE_LARGE = 32
FONT_SIZE_TITLE = 56
