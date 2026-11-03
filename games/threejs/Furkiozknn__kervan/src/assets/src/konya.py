# Konya: the Mevlana complex relative to the city centre (Blender y = -game z): long dervish lodge with lead domes,
# the fluted turquoise drum and cone of the Green Dome (Kubbe-i Hadra), a minaret, the courtyard fountain (sebil).
import os, sys
exec(open(os.path.join(os.path.dirname(sys.argv[sys.argv.index("--") + 1]), "_kv.py"), encoding="utf-8").read())

cream = mat("cream", "#E6D6B8"); stone = mat("stone", "#D2BE98"); lead = mat("lead", "#8E9AA6", rough=0.5, metal=0.3)
turq = mat("turquoise", "#2FA9A3"); turq2 = mat("turquoise_light", "#3CC0B8"); dark = mat("shadow", "#3A2A20")
white = mat("white", "#EFE6D3"); gold = mat("gold", "#D9A43A", rough=0.5, metal=0.4); water = mat("water", "#3D8FA2", rough=0.2)

x0, y0 = 0.0, -1.0  # lodge centre: game (0, 1)
o = [box((7.2, 4.4, 2.4), (x0, y0, 1.0), cream), box((7.4, 4.6, 0.16), (x0, y0, 2.25), stone),
     box((7.5, 4.7, 0.3), (x0, y0, -0.05), stone)]
for dx, r in ((-2.0, 1.15), (0.4, 1.05), (-3.25, 0.6)):
    o.append(cyl(r * 1.04, r * 1.04, 0.3, (x0 + dx, y0, 2.45), cream, n=10))
    o += dome(r, (x0 + dx, y0, 2.6), lead, n=10, h=r * 0.85)
for k in range(6):  # small domes of the dervish cells along the front
    o.append(cyl(0.34, 0.34, 0.16, (x0 - 3.0 + k * 0.9, y0 - 1.75, 2.38), cream, n=6))
    o += dome(0.32, (x0 - 3.0 + k * 0.9, y0 - 1.75, 2.46), lead, n=6, h=0.28)
    o.append(box((0.32, 0.08, 0.6), (x0 - 3.0 + k * 0.9, y0 - 2.22, 0.9), dark))
o += [box((1.2, 0.3, 1.9), (x0 - 0.8, y0 - 2.3, 0.85), stone), box((0.7, 0.12, 1.3), (x0 - 0.8, y0 - 2.46, 0.65), dark)]
# Green Dome: drum with 16 flutes, fluted cone, gilded finial
gx, gy = x0 + 3.0, y0
o += [cyl(1.3, 1.3, 0.6, (gx, gy, 2.2), cream, n=16), cyl(1.05, 1.05, 2.9, (gx, gy, 3.75), turq, n=16)]
for k in range(16):
    a = k / 16 * 2 * math.pi
    o.append(rbox((0.11, 0.12, 2.9), (gx + math.cos(a) * 1.07, gy + math.sin(a) * 1.07, 3.75), turq2, (0, 0, a)))
o.append(cyl(1.14, 1.14, 0.14, (gx, gy, 5.25), turq2, n=16))
cone = cyl(1.12, 0.0, 2.7, (gx, gy, 6.65), turq2, n=16)
o.append(cone)
for k in range(8):
    a = k / 8 * 2 * math.pi
    o.append(rod((gx + math.cos(a) * 1.12, gy + math.sin(a) * 1.12, 5.32), (gx, gy, 7.95), 0.05, 0.02, turq, n=3))
o += [sphere(0.12, (gx, gy, 8.05), gold, n=6, rings=4), cyl(0.03, 0.0, 0.5, (gx, gy, 8.35), gold, n=4)]
o += minaret(x0 - 3.6, y0 - 2.6, -0.2, 6.8, white, lead, band=turq)
# sebil (fountain) in the court in front
o += [cyl(0.7, 0.75, 0.5, (x0 + 1.2, y0 - 3.4, 0.05), stone, n=8), cyl(0.6, 0.6, 0.05, (x0 + 1.2, y0 - 3.4, 0.32), water, n=8),
      cyl(0.08, 0.08, 1.2, (x0 + 1.2, y0 - 3.4, 0.8), stone, n=4), cyl(0.45, 0.0, 0.4, (x0 + 1.2, y0 - 3.4, 1.55), lead, n=8)]
part(o, "mevlana", (x0, y0, 0))
