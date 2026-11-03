# Izmir landmarks relative to the city centre (Blender y = -game z):
# fener: harbour lighthouse on its rock (stands at sea level), saat_kulesi: the octagonal clock tower with fountains,
# ambar_a / ambar_b: stone harbour warehouses with tiled roofs and arched doors.
import os, sys
exec(open(os.path.join(os.path.dirname(sys.argv[sys.argv.index("--") + 1]), "_kv.py"), encoding="utf-8").read())

white = mat("white", "#F0ECE3"); redb = mat("red_band", "#B5422E"); glass = mat("lamp", "#F6E2A8", emit=0.6)
terra = mat("terracotta", "#A04A33"); stone = mat("stone", "#C79B6B"); stone2 = mat("stone_light", "#E6D3B0")
rock = mat("rock", "#8C8172"); dark = mat("shadow", "#3A2A20"); lead = mat("lead", "#8E9AA6", rough=0.5, metal=0.3)
gold = mat("gold", "#D9A43A", rough=0.5, metal=0.4); tile = mat("tile", "#2FA9A3"); water = mat("water", "#3D8FA2", rough=0.2)

lx, ly = -15.0, 1.0
f = [jitter(cyl(1.5, 1.1, 1.2, (lx, ly, 0.0), rock, n=9), 0.12, seed=4),
     cyl(0.78, 0.7, 1.6, (lx, ly, 1.2), white, n=10), cyl(0.74, 0.66, 0.7, (lx, ly, 2.2), redb, n=10),
     cyl(0.66, 0.58, 1.6, (lx, ly, 3.2), white, n=10), cyl(0.82, 0.82, 0.14, (lx, ly, 4.05), dark, n=10),
     cyl(0.5, 0.5, 0.7, (lx, ly, 4.45), glass, n=8), cyl(0.68, 0.0, 0.9, (lx, ly, 5.25), terra, n=10),
     cyl(0.04, 0.04, 0.4, (lx, ly, 5.85), dark, n=4), box((0.3, 0.08, 0.5), (lx, ly - 0.75, 1.3), dark)]
for k in range(10):
    a = k / 10 * 2 * math.pi
    f.append(cyl(0.025, 0.025, 0.3, (lx + math.cos(a) * 0.8, ly + math.sin(a) * 0.8, 4.25), dark, n=3))
part(f, "fener", (lx, ly, 0))

cx, cy = 1.5, -1.0
c = [cyl(1.5, 1.5, 0.3, (cx, cy, 0.0), stone2, n=8, rot=(0, 0, math.pi / 8)),
     cyl(1.05, 1.05, 1.6, (cx, cy, 0.95), stone2, n=8, rot=(0, 0, math.pi / 8)),
     cyl(0.8, 0.8, 1.3, (cx, cy, 2.4), stone2, n=8, rot=(0, 0, math.pi / 8)),
     cyl(0.9, 0.9, 0.14, (cx, cy, 3.1), stone, n=8, rot=(0, 0, math.pi / 8)),
     cyl(0.62, 0.62, 1.1, (cx, cy, 3.7), stone2, n=8, rot=(0, 0, math.pi / 8)),
     cyl(0.72, 0.72, 0.12, (cx, cy, 4.3), stone, n=8, rot=(0, 0, math.pi / 8)),
     cyl(0.42, 0.42, 0.55, (cx, cy, 4.6), stone2, n=8, rot=(0, 0, math.pi / 8))]
c += dome(0.48, (cx, cy, 4.87), lead, n=8, h=0.45)
for k in range(4):  # clock faces on four sides, fountains at the corners of the base
    a = k * math.pi / 2
    c.append(rbox((0.46, 0.06, 0.46), (cx + math.cos(a) * 0.63, cy + math.sin(a) * 0.63, 3.7), white, (0, 0, a + math.pi / 2)))
    c.append(rbox((0.1, 0.07, 0.3), (cx + math.cos(a) * 0.66, cy + math.sin(a) * 0.66, 3.75), dark, (0, 0, a + math.pi / 2)))
    c.append(rbox((0.42, 0.07, 0.9), (cx + math.cos(a) * 1.06, cy + math.sin(a) * 1.06, 0.95), dark, (0, 0, a + math.pi / 2)))
    b = a + math.pi / 4
    c.append(cyl(0.3, 0.34, 0.4, (cx + math.cos(b) * 1.5, cy + math.sin(b) * 1.5, 0.2), stone, n=6))
    c.append(cyl(0.24, 0.24, 0.04, (cx + math.cos(b) * 1.5, cy + math.sin(b) * 1.5, 0.41), water, n=6))
for k in range(8):
    a = k / 8 * 2 * math.pi + math.pi / 8
    c.append(cyl(0.06, 0.06, 1.1, (cx + math.cos(a) * 0.62, cy + math.sin(a) * 0.62, 2.45), stone, n=4))
part(c, "saat_kulesi", (cx, cy, 0))

def ambar(name, x, y, w, d, h):
    o = [box((w, d, h), (x, y, h / 2 - 0.2), stone), box((w + 0.1, d + 0.1, 0.18), (x, y, h - 0.15), stone2)]
    o.append(rbox((w + 0.3, d * 0.62, 0.08), (x, y + d * 0.26, h + 0.25), terra, (0.62, 0, 0)))
    o.append(rbox((w + 0.3, d * 0.62, 0.08), (x, y - d * 0.26, h + 0.25), terra, (-0.62, 0, 0)))
    o.append(box((w + 0.32, 0.12, 0.12), (x, y, h + 0.47), terra))
    o.append(box((w, 0.3, 0.12), (x, y, h - 0.02), terra))
    n = int(w / 1.2)
    for i in range(n):
        xx = x - w / 2 + (i + 0.5) * w / n
        for s in (-1, 1):
            o.append(box((0.5, 0.06, 0.9), (xx, y + s * d / 2, 0.45), dark))
            o.append(cyl(0.25, 0.25, 0.06, (xx, y + s * d / 2, 0.9), dark, n=8, rot=(math.pi / 2, 0, 0)))
    for k in range(3):
        o.append(box((0.5, 0.5, 0.5), (x + w / 2 + 0.5, y - 0.5 + k * 0.55, 0.05), mat("crate", "#7A5232")))
    part(o, name, (x, y, 0))

ambar("ambar_a", -3.5, 4.8, 4.4, 2.2, 1.8)
ambar("ambar_b", -3.8, -3.6, 3.6, 2.0, 1.6)
