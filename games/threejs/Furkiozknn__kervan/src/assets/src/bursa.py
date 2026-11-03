# Bursa landmarks, placed relative to the city centre (Blender x = game x, Blender y = -game z):
# ulu_cami: the Great Mosque with its grid of 20 domes and two minarets; yesil_turbe: the octagonal Green Tomb.
import os, sys
exec(open(os.path.join(os.path.dirname(sys.argv[sys.argv.index("--") + 1]), "_kv.py"), encoding="utf-8").read())

white = mat("white", "#EFE6D3"); stone = mat("stone", "#D9CBB0"); lead = mat("lead", "#8E9AA6", rough=0.5, metal=0.3)
dark = mat("shadow", "#3A2A20"); green = mat("green_tile", "#3E9C80"); green2 = mat("green_dome", "#2E7D66")
tile = mat("tile", "#2FA9A3"); band = mat("band", "#CDBE9F")

U = (1.0, 1.0)  # game (1, -1)
ux, uy = U
o = [box((8.4, 6.6, 2.8), (ux, uy, 1.2), white),
     box((8.6, 6.8, 0.2), (ux, uy, 2.6), band),
     box((8.7, 6.9, 0.3), (ux, uy, -0.05), stone)]
for i in range(5):
    for j in range(4):
        x, y = ux - 3.3 + i * 1.65, uy + 2.45 - j * 1.63
        big = (i == 2 and j in (1, 2))
        r = 0.86 if big else 0.7
        o.append(cyl(r * 1.02, r * 1.02, 0.18, (x, y, 2.79), white, n=8))
        o += dome(r, (x, y, 2.88), lead, n=8, h=r * 0.85)
# north and side doors, windows in two rows
for k in range(-3, 4):
    o.append(box((0.32, 0.08, 0.6), (ux + k * 1.15, uy - 3.32, 0.9), dark))
    o.append(box((0.32, 0.08, 0.4), (ux + k * 1.15, uy - 3.32, 1.9), dark))
for k in (-2, -1, 1, 2):
    o.append(box((0.08, 0.32, 0.55), (ux - 4.22, uy + k * 1.3, 1.1), dark)); o.append(box((0.08, 0.32, 0.55), (ux + 4.22, uy + k * 1.3, 1.1), dark))
o += [box((1.6, 0.5, 3.3), (ux, uy - 3.45, 1.45), stone), box((1.0, 0.12, 1.9), (ux, uy - 3.72, 0.9), dark),
      cyl(0.5, 0.5, 0.12, (ux, uy - 3.72, 1.85), dark, n=8, rot=(math.pi / 2, 0, 0))]
for mx in (-4.6, 4.6):
    o += minaret(ux + mx, uy - 3.6, -0.2, 7.2, white, lead, band=tile)
part(o, "ulu_cami", (ux, uy, 0))

T = (-6.0, -4.5)  # game (-6, 4.5)
tx, ty = T
t = [cyl(1.95, 1.95, 0.5, (tx, ty, 0.05), stone, n=8, rot=(0, 0, math.pi / 8)),
     cyl(1.7, 1.7, 2.9, (tx, ty, 1.55), green, n=8, rot=(0, 0, math.pi / 8)),
     cyl(1.76, 1.76, 0.16, (tx, ty, 3.0), band, n=8, rot=(0, 0, math.pi / 8)),
     cyl(1.25, 1.25, 0.5, (tx, ty, 3.3), green, n=8, rot=(0, 0, math.pi / 8))]
t += dome(1.25, (tx, ty, 3.55), green2, n=12, h=1.2)
for k in range(8):  # a tiled blind arch on every face, a window in each
    a = k / 8 * 2 * math.pi
    x, y = tx + math.cos(a) * 1.6, ty + math.sin(a) * 1.6
    t.append(rbox((0.9, 0.12, 2.0), (x, y, 1.5), tile, (0, 0, a + math.pi / 2)))
    t.append(rbox((0.36, 0.14, 0.6), (x * 1.0 + math.cos(a) * 0.04, y + math.sin(a) * 0.04, 1.7), dark, (0, 0, a + math.pi / 2)))
part(t, "yesil_turbe", (tx, ty, 0))
