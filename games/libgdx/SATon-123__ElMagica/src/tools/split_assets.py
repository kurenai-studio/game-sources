"""Split original generated sheets into clean, individually named game assets.

Requires Pillow only when regenerating assets; the game has no new dependency.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets"
ORIGINALS = ROOT / "art-source"
BIOMES = ["ruins", "temple", "volcano", "ice"]
records = []


def original(relative):
    old = ASSETS / relative
    saved = ORIGINALS / relative
    saved.parent.mkdir(parents=True, exist_ok=True)
    if old.exists() and not saved.exists():
        old.rename(saved)
    return Image.open(saved).convert("RGBA")


def save(image, target, source, box=None, crop=False):
    if box:
        image = image.crop(box)
    if crop:
        bounds = image.getchannel("A").point(lambda a: 255 if a > 64 else 0).getbbox()
        if not bounds:
            raise ValueError("Empty sprite: " + target)
        image = image.crop(bounds)
    path = ASSETS / target
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    records.append({"file": target, "source": "art-source/" + source,
                    "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                    "width": image.width, "height": image.height})


def cell(image, column, row, columns, rows, span=1):
    return (column * image.width // columns, row * image.height // rows,
            (column + span) * image.width // columns, (row + 1) * image.height // rows)


def objects(image, count):
    """Separate actual silhouettes; generated sheets do not follow exact grids."""
    alpha = image.getchannel("A")
    pixels = alpha.tobytes()
    parents, runs, previous = [], [], []

    def root(index):
        while parents[index] != index:
            parents[index] = parents[parents[index]]
            index = parents[index]
        return index

    for y in range(image.height):
        row = pixels[y * image.width:(y + 1) * image.width]
        current, x, j = [], 0, 0
        while x < image.width:
            if row[x] <= 64:
                x += 1
                continue
            left = x
            while x < image.width and row[x] > 64:
                x += 1
            index = len(parents)
            parents.append(index)
            runs.append((left, x, y))
            current.append((left, x, index))
            while j < len(previous) and previous[j][1] < left:
                j += 1
            k = j
            while k < len(previous) and previous[k][0] <= x:
                parents[root(index)] = root(previous[k][2])
                k += 1
        previous = current
    groups = {}
    for index, run in enumerate(runs):
        groups.setdefault(root(index), []).append(run)
    groups = sorted(groups.values(), key=lambda g: sum(b - a for a, b, y in g), reverse=True)
    bodies = groups[:count]
    bounds = [(min(a for a, b, y in g), min(y for a, b, y in g),
               max(b for a, b, y in g), max(y for a, b, y in g) + 1) for g in bodies]
    masks = [Image.new("L", image.size) for _ in bodies]
    draws = [ImageDraw.Draw(mask) for mask in masks]
    for index, group in enumerate(groups):
        if index < count:
            owner = index
        else:
            if sum(b - a for a, b, y in group) < 8:
                continue
            x = sum((a + b) / 2 for a, b, y in group) / len(group)
            y = sum(y for a, b, y in group) / len(group)
            def distance(box):
                left, top, right, bottom = box
                edge = max(left - x, 0, x - right) ** 2 + max(top - y, 0, y - bottom) ** 2
                return edge + 0.001 * ((x - (left + right) / 2) ** 2 + (y - (top + bottom) / 2) ** 2)
            owner = min(range(count), key=lambda i: distance(bounds[i]))
            if distance(bounds[owner]) > 32 ** 2:
                continue
        for left, right, y in group:
            draws[owner].line((left, y, right - 1, y), fill=255)
    result = []
    for box, mask in zip(bounds, masks):
        sprite = image.copy()
        sprite.putalpha(ImageChops.multiply(alpha, mask.filter(ImageFilter.MaxFilter(3))))
        sprite = sprite.crop(sprite.getchannel("A").getbbox())
        result.append((box, sprite))
    return result


def ordered_objects(image, columns, rows):
    remaining = objects(image, columns * rows)
    result = []
    for row in range(rows):
        row_objects = sorted(remaining, key=lambda item: (item[0][1] + item[0][3]) / 2)[:columns]
        for item in sorted(row_objects, key=lambda item: item[0][0]):
            result.append(item[1])
            remaining.remove(item)
    return result


source = "sprites/characters-v1.png"
sheet = original(source)
names = ["characters/player/mage", "characters/enemies/slime", "characters/bosses/fire-water",
         "characters/bosses/fire-earth", "characters/bosses/fire-air", "characters/bosses/water-earth",
         "characters/bosses/water-air", "characters/bosses/earth-air"]
for sprite, name in zip(ordered_objects(sheet, 4, 2), names):
    save(sprite, name + ".png", source)
for old, new in [("cultist", "shooter"), ("snake", "snake")]:
    source = "sprites/" + old + "-v1.png"
    save(original(source), "characters/enemies/" + new + ".png", source, crop=True)
source = "rooms/biomes-v1.png"
sheet = original(source)
for row, biome in enumerate(BIOMES):
    for col, name in enumerate(["floor-plain", "floor-cracked", "floor-pattern", "wall-plain", "wall-rune", "wall-medallion"]):
        save(sheet, f"rooms/{biome}/tiles/{name}.png", source, cell(sheet, col, row, 6, 4))
source = "rooms/obstacles-v1.png"
sheet = original(source)
obstacles = ordered_objects(sheet, 8, 4)
for row, biome in enumerate(BIOMES):
    for col in range(8):
        save(obstacles[row * 8 + col], f"rooms/{biome}/obstacles/variant-{col + 1:02}.png", source)
source = "rooms/decor-v1.png"
sheet = original(source)
items = ordered_objects(sheet.crop((1340, 0, sheet.width, sheet.height)), 2, 4)
gate_rows = [0, 230, 451, 663, 887]
for row, biome in enumerate(BIOMES):
    for col, name in enumerate(["closed", "open"]):
        left, right = (441, 895) if col == 0 else (897, 1329)
        save(sheet, f"rooms/{biome}/gates/{name}.png", source,
             (left, gate_rows[row], right, gate_rows[row + 1]))
    for col, name in enumerate(["spellbook", "healing-potion"]):
        save(items[row * 2 + col], f"items/{biome}/{name}.png", source)
source = "merchant/merchant-v1.png"
sheet = original(source)
names = ["characters/npc/merchant", "shop/pedestal", "shop/stat-card", "shop/healing-potion",
         "shop/ability-card", "shop/shield-card", "items/coins/pile", "items/coins/single"]
for sprite, name in zip(ordered_objects(sheet, 4, 2), names):
    save(sprite, name + ".png", source)
source = "menu/cover-v1.png"
save(original(source), "ui/menu/cover.png", source)

# Use our mage artwork instead of the template's LibGDX branding.
mage = Image.open(ASSETS / "characters/player/mage.png").convert("RGBA")
for size in [16, 32, 64, 128, 256, 512, 1024]:
    icon = Image.new("RGBA", (size, size), (20, 14, 38, 255))
    scaled = mage.copy()
    scaled.thumbnail((max(1, size * 7 // 8), max(1, size * 7 // 8)), Image.Resampling.NEAREST)
    icon.alpha_composite(scaled, ((size - scaled.width) // 2, (size - scaled.height) // 2))
    target = ASSETS / f"ui/icons/elmagica-{size}.png"
    target.parent.mkdir(parents=True, exist_ok=True)
    icon.save(target)
    if size == 256:
        icon.save(ROOT / "lwjgl3/icons/logo.png")
        icon.save(ROOT / "lwjgl3/icons/logo.ico")
    if size == 1024:
        icon.save(ROOT / "lwjgl3/icons/logo.icns")
(ROOT / "docs/asset-manifest.json").write_text(json.dumps(records, indent=2) + "\n", encoding="utf-8")
print("Split", len(records), "assets; originals preserved in art-source/.")
