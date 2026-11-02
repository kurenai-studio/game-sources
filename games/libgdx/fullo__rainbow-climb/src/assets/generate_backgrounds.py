#!/usr/bin/env python3
"""
Generate 3-layer parallax pixel art backgrounds for Rainbow Climb.
Each biome gets 3 PNG layers (240x400) with transparency:
  - layer0: far background (sky, gradients, stars)
  - layer1: mid-ground (hills, buildings, clouds)
  - layer2: foreground details (trees, crystals, effects)
"""

import random, os
from PIL import Image, ImageDraw

W, H = 480, 800

def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))

def gradient(img, top, bottom):
    draw = ImageDraw.Draw(img)
    for y in range(H):
        draw.line([(0, y), (W, y)], fill=lerp_color(top, bottom, y / H))

def stars(draw, count, color, sz=1):
    for _ in range(count):
        x, y = random.randint(0, W-1), random.randint(0, H-1)
        draw.rectangle([x, y, x+sz, y+sz], fill=color)

def clouds(draw, count, color, yr=(50, 200)):
    for _ in range(count):
        x, y = random.randint(-20, W), random.randint(*yr)
        w, h = random.randint(20, 50), random.randint(8, 14)
        draw.ellipse([x, y, x+w, y+h], fill=color)
        draw.ellipse([x+w//4, y-h//2, x+w*3//4, y+h//2], fill=color)

def hills(draw, base_y, color, count=3):
    for i in range(count):
        cx = int(W * (i + 0.5) / count) + random.randint(-30, 30)
        r = random.randint(40, 80)
        draw.ellipse([cx-r, base_y-r//2, cx+r, base_y+r//2], fill=color)
    draw.rectangle([0, base_y, W, H], fill=color)

def trees(draw, base_y, trunk, leaf, count=6):
    for _ in range(count):
        x = random.randint(5, W-5)
        th = random.randint(15, 30)
        draw.rectangle([x-1, base_y-th, x+1, base_y], fill=trunk)
        for l in range(3):
            ly = base_y - th - l * 8
            lw = 12 - l * 3
            draw.polygon([(x-lw, ly), (x+lw, ly), (x, ly-10)], fill=leaf)

def buildings(draw, base_y, color, accent, count=8):
    for i in range(count):
        x = int(W * i / count) + random.randint(-5, 5)
        w, h = random.randint(15, 30), random.randint(40, 120)
        draw.rectangle([x, base_y-h, x+w, base_y], fill=color)
        for wy in range(base_y-h+4, base_y-4, 8):
            for wx in range(x+3, x+w-3, 6):
                if random.random() < 0.6:
                    draw.rectangle([wx, wy, wx+3, wy+3], fill=accent)

def stalactites(draw, color, count=12, from_top=True):
    for _ in range(count):
        x, h, w = random.randint(0, W), random.randint(10, 40), random.randint(3, 8)
        if from_top:
            draw.polygon([(x, 0), (x+w, 0), (x+w//2, h)], fill=color)
        else:
            draw.polygon([(x, H), (x+w, H), (x+w//2, H-h)], fill=color)

def crystals(draw, color, glow, count=8):
    for _ in range(count):
        x, y = random.randint(0, W), random.randint(H//2, H-20)
        h, w = random.randint(10, 25), random.randint(4, 8)
        draw.polygon([(x, y), (x+w, y), (x+w//2, y-h)], fill=color)
        draw.rectangle([x+w//2-1, y-h+2, x+w//2+1, y-h+4], fill=glow)

def new_layer():
    return Image.new("RGBA", (W, H), (0, 0, 0, 0))

def new_opaque(top, bottom):
    img = Image.new("RGB", (W, H))
    gradient(img, top, bottom)
    return img.convert("RGBA")


# ============================================================
# SKY GARDEN
# ============================================================
def sky_garden():
    l0 = new_opaque((135, 206, 235), (180, 220, 245))
    d0 = ImageDraw.Draw(l0)
    clouds(d0, 5, (255, 255, 255, 180), yr=(20, 120))

    l1 = new_layer()
    d1 = ImageDraw.Draw(l1)
    hills(d1, 300, (120, 195, 100))
    hills(d1, 340, (95, 170, 75))
    clouds(d1, 4, (240, 245, 255, 160), yr=(40, 180))

    l2 = new_layer()
    d2 = ImageDraw.Draw(l2)
    trees(d2, 300, (80, 60, 40), (50, 160, 50), 5)
    trees(d2, 340, (60, 45, 30), (40, 130, 40), 4)
    for _ in range(25):
        x, y = random.randint(0, W), random.randint(300, H)
        c = random.choice([(255,100,100),(255,200,50),(200,100,255),(255,150,200)])
        d2.rectangle([x, y, x+2, y+2], fill=c)
    return l0, l1, l2

# ============================================================
# CLOUD KINGDOM
# ============================================================
def cloud_kingdom():
    l0 = new_opaque((200, 220, 255), (230, 240, 255))
    d0 = ImageDraw.Draw(l0)
    stars(d0, 10, (255, 215, 0, 200), sz=2)

    l1 = new_layer()
    d1 = ImageDraw.Draw(l1)
    clouds(d1, 10, (255, 255, 255, 200), yr=(30, 350))

    l2 = new_layer()
    d2 = ImageDraw.Draw(l2)
    clouds(d2, 6, (245, 248, 255, 220), yr=(50, 300))
    for _ in range(4):
        x, y = random.randint(0, W-30), random.randint(100, 350)
        w = random.randint(20, 40)
        d2.rectangle([x, y, x+w, y+4], fill=(220, 200, 170, 200))
    return l0, l1, l2

# ============================================================
# NEON CITY
# ============================================================
def neon_city():
    l0 = new_opaque((15, 5, 40), (25, 12, 55))
    d0 = ImageDraw.Draw(l0)
    stars(d0, 50, (150, 150, 200, 180), sz=1)
    stars(d0, 10, (200, 200, 255, 220), sz=2)

    l1 = new_layer()
    d1 = ImageDraw.Draw(l1)
    buildings(d1, 350, (25, 18, 55, 200), (0, 200, 180, 230), count=6)

    l2 = new_layer()
    d2 = ImageDraw.Draw(l2)
    buildings(d2, 380, (35, 25, 65, 220), (255, 50, 200, 230), count=8)
    for _ in range(30):
        x, y = random.randint(0, W), random.randint(260, 390)
        c = random.choice([(255,0,200,230),(0,255,230,230),(255,100,0,200),(150,0,255,200)])
        d2.rectangle([x, y, x+3, y+2], fill=c)
    return l0, l1, l2

# ============================================================
# CRYSTAL CAVE
# ============================================================
def crystal_cave():
    l0 = new_opaque((10, 20, 50), (15, 30, 60))
    d0 = ImageDraw.Draw(l0)
    for _ in range(40):
        x, y = random.randint(0, W), random.randint(0, H)
        d0.rectangle([x, y, x+1, y+1], fill=(60, 140, 180, 100))

    l1 = new_layer()
    d1 = ImageDraw.Draw(l1)
    stalactites(d1, (30, 50, 80, 180), count=10, from_top=True)
    stalactites(d1, (25, 45, 75, 180), count=8, from_top=False)

    l2 = new_layer()
    d2 = ImageDraw.Draw(l2)
    crystals(d2, (50, 130, 170, 220), (100, 220, 255, 255), count=10)
    crystals(d2, (80, 160, 200, 200), (150, 240, 255, 255), count=5)
    stalactites(d2, (40, 60, 90, 200), count=6, from_top=True)
    return l0, l1, l2

# ============================================================
# FIRE RUINS
# ============================================================
def fire_ruins():
    l0 = new_opaque((40, 10, 5), (70, 20, 8))
    d0 = ImageDraw.Draw(l0)
    for _ in range(50):
        x, y = random.randint(0, W), random.randint(0, H)
        c = random.choice([(255,100,0,80),(255,200,50,60),(255,50,0,70)])
        d0.rectangle([x, y, x+1, y+1], fill=c)

    l1 = new_layer()
    d1 = ImageDraw.Draw(l1)
    for _ in range(5):
        x = random.randint(10, W-20)
        h, w = random.randint(60, 150), random.randint(8, 14)
        d1.rectangle([x, H-h, x+w, H], fill=(100, 50, 30, 200))
        d1.rectangle([x-2, H-h, x+w+2, H-h+4], fill=(110, 60, 35, 200))

    l2 = new_layer()
    d2 = ImageDraw.Draw(l2)
    # Lava at bottom
    for x in range(0, W, 2):
        wave = int(3 * (1 + random.random()))
        y = H - 30 - wave
        d2.rectangle([x, y, x+2, H], fill=(200, 50, 0, 220))
        if random.random() < 0.3:
            d2.rectangle([x, y-2, x+2, y], fill=(255, 150, 0, 240))
    for _ in range(20):
        x, y = random.randint(0, W), random.randint(0, H-40)
        c = random.choice([(255,120,0,150),(255,200,50,120)])
        d2.rectangle([x, y, x+1, y+1], fill=c)
    return l0, l1, l2

# ============================================================
# CANDY LAND
# ============================================================
def candy_land():
    l0 = new_opaque((255, 220, 240), (255, 235, 248))
    d0 = ImageDraw.Draw(l0)
    for _ in range(40):
        x, y = random.randint(0, W), random.randint(0, H)
        c = random.choice([(255,100,100,60),(100,255,100,60),(100,100,255,60),(255,255,100,60)])
        d0.rectangle([x, y, x+1, y+2], fill=c)

    l1 = new_layer()
    d1 = ImageDraw.Draw(l1)
    clouds(d1, 5, (255, 200, 220, 180), yr=(40, 180))
    clouds(d1, 3, (200, 230, 255, 160), yr=(60, 160))
    for _ in range(10):
        x, y = random.randint(0, W), random.randint(0, H)
        r = random.randint(3, 8)
        c = random.choice([(255,150,200,150),(200,255,200,150)])
        d1.ellipse([x-r, y-r, x+r, y+r], fill=c)

    l2 = new_layer()
    d2 = ImageDraw.Draw(l2)
    for _ in range(5):
        x = random.randint(20, W-20)
        d2.rectangle([x-1, 200, x+1, H], fill=(200, 150, 100, 200))
        r = random.randint(8, 14)
        c = random.choice([(255,100,150,220),(150,200,255,220),(200,255,150,220)])
        d2.ellipse([x-r, 200-r, x+r, 200+r], fill=c)
    for _ in range(30):
        x, y = random.randint(0, W), random.randint(0, H)
        c = random.choice([(255,100,100,180),(100,255,100,180),(100,100,255,180),(255,255,100,180)])
        d2.rectangle([x, y, x+1, y+2], fill=c)
    return l0, l1, l2

# ============================================================
# SPACE STATION
# ============================================================
def space_station():
    l0 = new_opaque((2, 2, 15), (5, 5, 25))
    d0 = ImageDraw.Draw(l0)
    stars(d0, 100, (180, 180, 200, 200), sz=1)
    stars(d0, 25, (255, 255, 255, 240), sz=2)
    for _ in range(6):
        x, y = random.randint(0, W), random.randint(0, H)
        r = random.randint(15, 40)
        c = random.choice([(20,10,60,40),(10,20,50,40),(30,10,40,40)])
        d0.ellipse([x-r, y-r, x+r, y+r], fill=c)

    l1 = new_layer()
    d1 = ImageDraw.Draw(l1)
    stars(d1, 8, (100, 150, 255, 180), sz=3)
    # Distant planet
    px, py = random.randint(50, 190), random.randint(50, 150)
    d1.ellipse([px-20, py-20, px+20, py+20], fill=(40, 60, 100, 150))
    d1.ellipse([px-18, py-18, px+15, py+15], fill=(50, 70, 110, 150))

    l2 = new_layer()
    d2 = ImageDraw.Draw(l2)
    for _ in range(3):
        x, y = random.randint(20, W-60), random.randint(200, 350)
        w, h = random.randint(30, 60), random.randint(15, 25)
        d2.rectangle([x, y, x+w, y+h], fill=(50, 50, 70, 200))
        d2.rectangle([x+2, y+2, x+w-2, y+h-2], fill=(40, 40, 55, 200))
        for lx in range(x+4, x+w-4, 6):
            d2.rectangle([lx, y+h-3, lx+2, y+h-1], fill=(50, 150, 255, 255))
    return l0, l1, l2

# ============================================================
# HAUNTED FOREST
# ============================================================
def haunted_forest():
    l0 = new_opaque((10, 20, 15), (18, 32, 22))
    d0 = ImageDraw.Draw(l0)
    # Moon
    d0.ellipse([160, 30, 190, 60], fill=(180, 190, 170, 200))
    d0.ellipse([165, 28, 192, 55], fill=(10, 20, 15, 200))  # crescent shadow

    l1 = new_layer()
    d1 = ImageDraw.Draw(l1)
    for _ in range(5):
        x, y = random.randint(-30, W), random.randint(220, 360)
        w = random.randint(40, 80)
        d1.ellipse([x, y, x+w, y+15], fill=(30, 50, 35, 120))
    # Back trees (silhouettes)
    for _ in range(6):
        x = random.randint(5, W-5)
        h = random.randint(100, 220)
        d1.rectangle([x-3, H-h, x+3, H], fill=(18, 22, 15, 200))
        for _ in range(4):
            by = H - h + random.randint(10, h//2)
            bdir = random.choice([-1, 1])
            blen = random.randint(10, 25)
            d1.line([(x, by), (x + bdir*blen, by - random.randint(3, 12))],
                   fill=(22, 28, 18, 180), width=2)

    l2 = new_layer()
    d2 = ImageDraw.Draw(l2)
    # Front trees
    for _ in range(4):
        x = random.randint(5, W-5)
        h = random.randint(60, 150)
        d2.rectangle([x-2, H-h, x+2, H], fill=(25, 20, 15, 220))
        for _ in range(3):
            by = H - h + random.randint(5, h//3)
            bdir = random.choice([-1, 1])
            d2.line([(x, by), (x + bdir*random.randint(6, 18), by - random.randint(2, 8))],
                   fill=(30, 25, 18, 200), width=1)
    # Glowing eyes
    for _ in range(5):
        x, y = random.randint(10, W-10), random.randint(150, 360)
        d2.rectangle([x, y, x+2, y+2], fill=(200, 50, 200, 220))
        d2.rectangle([x+5, y, x+7, y+2], fill=(200, 50, 200, 220))
    # Fireflies
    for _ in range(20):
        x, y = random.randint(0, W), random.randint(0, H)
        d2.rectangle([x, y, x+1, y+1], fill=(150, 255, 100, 200))
    return l0, l1, l2


# ============================================================
# GENERATE ALL
# ============================================================
random.seed(42)

biomes = {
    "sky_garden": sky_garden,
    "cloud_kingdom": cloud_kingdom,
    "neon_city": neon_city,
    "crystal_cave": crystal_cave,
    "fire_ruins": fire_ruins,
    "candy_land": candy_land,
    "space_station": space_station,
    "haunted_forest": haunted_forest,
}

out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "backgrounds")
os.makedirs(out_dir, exist_ok=True)

# Remove old single-layer files
for f in os.listdir(out_dir):
    if f.startswith("bg_") and f.endswith(".png"):
        os.remove(os.path.join(out_dir, f))

for name, gen_func in biomes.items():
    l0, l1, l2 = gen_func()
    for i, layer in enumerate([l0, l1, l2]):
        path = os.path.join(out_dir, f"bg_{name}_{i}.png")
        layer.save(path)
    print(f"Generated: bg_{name}_0/1/2.png (3 layers @ {W}x{H})")

print(f"\n{len(biomes) * 3} layers saved to: {out_dir}")
