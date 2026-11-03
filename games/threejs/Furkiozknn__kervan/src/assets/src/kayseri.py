# Kayseri: black basalt citadel (13 m square, gate facing game +z = Blender -Y) with crenellated walls, seven round
# towers, a twin-towered gate and the domed keep; doner_kumbet: the twelve-sided Seljuk tomb with its conical roof.
import os, sys
exec(open(os.path.join(os.path.dirname(sys.argv[sys.argv.index("--") + 1]), "_kv.py"), encoding="utf-8").read())

bas = mat("basalt", "#57504B"); bas2 = mat("basalt_dark", "#4A4440"); bas3 = mat("basalt_tower", "#4E4844")
cap = mat("basalt_cap", "#433D3A"); keep = mat("keep", "#5C5550"); dark = mat("shadow", "#221A16")
lead = mat("lead", "#8E9AA6", rough=0.5, metal=0.3); door = mat("door", "#5A3A22"); tuff = mat("tomb_stone", "#BBAA90")
roof = mat("tomb_roof", "#8E806E"); light = mat("trim", "#7A716A"); flag = mat("banner", "#7B2D26")

S, WH = 13.0, 3.0
o = []
def wall(x, y, w, d):
    o.extend([box((w, d, WH), (x, y, WH / 2 - 0.2), bas), box((w + 0.12, d + 0.12, 0.14), (x, y, WH - 0.25), light)])
    n = round(max(w, d) / 1.1)
    for i in range(n):
        t = (i + 0.5) / n - 0.5
        o.append(box((0.5, 0.5, 0.45), (x + (t * w if w > d else 0), y + (t * d if d > w else 0), WH - 0.2 + 0.2), bas2))
wall(0, S / 2, S, 0.9); wall(-S / 2, 0, 0.9, S); wall(S / 2, 0, 0.9, S)
wall(-S / 2 + 2.9, -S / 2, 5.8, 0.9); wall(S / 2 - 2.9, -S / 2, 5.8, 0.9)
for dx, dy in [(-1, -1), (1, -1), (-1, 1), (1, 1), (0, 1), (-1, 0), (1, 0)]:
    tx, ty = dx * S / 2, dy * S / 2
    o += [cyl(1.1, 1.0, 3.9, (tx, ty, 1.75), bas3, n=10), cyl(1.22, 1.22, 0.5, (tx, ty, 3.85), cap, n=10)]
    for k in range(6):
        a = k / 6 * 2 * math.pi
        o.append(box((0.4, 0.4, 0.4), (tx + math.cos(a) * 1.05, ty + math.sin(a) * 1.05, 4.3), bas2))
    o.append(box((0.12, 0.3, 0.5), (tx + (0.95 if dx >= 0 else -0.95), ty, 2.6), dark))
# gate: two flanking towers, arched passage, banner
gy = -S / 2
o += [box((3.0, 1.8, 4.4), (0, gy, 1.9), keep), box((1.4, 0.1, 2.3), (0, gy - 0.91, 0.95), door),
      cyl(0.7, 0.7, 0.12, (0, gy - 0.91, 2.1), dark, n=10, rot=(math.pi / 2, 0, 0)),
      box((3.2, 2.0, 0.2), (0, gy, 4.1), light)]
for k in (-1, 1):
    o += [cyl(0.75, 0.7, 4.8, (k * 1.55, gy - 0.4, 2.1), bas3, n=8), cyl(0.85, 0.85, 0.3, (k * 1.55, gy - 0.4, 4.6), cap, n=8),
          box((0.06, 0.6, 1.2), (k * 0.85, gy - 0.95, 2.9), flag)]
for i in range(4):
    o.append(box((0.4, 0.4, 0.35), (-1.2 + i * 0.8, gy, 4.38), bas2))
# keep with a dome and arrow slits
kx, ky = -1.5, 1.5
o += [box((3.8, 3.8, 4.8), (kx, ky, 2.2), keep), box((4.0, 4.0, 0.2), (kx, ky, 4.55), light),
      cyl(1.45, 1.45, 0.4, (kx, ky, 4.8), keep, n=12)]
o += dome(1.4, (kx, ky, 5.0), lead, n=12, h=1.15)
for a in range(4):
    ang = a * math.pi / 2
    o.append(rbox((0.14, 0.1, 0.7), (kx + math.cos(ang) * 1.91, ky + math.sin(ang) * 1.91, 3.0), dark, (0, 0, ang + math.pi / 2)))
part(o, "kale", (0, 0, 0))

# Doner Kumbet: twelve faces with blind arches, frieze, conical roof
dx, dy = 3.0, -1.5
t = [cyl(1.3, 1.3, 0.5, (dx, dy, 0.05), tuff, n=12), cyl(1.05, 1.05, 2.4, (dx, dy, 1.4), tuff, n=12),
     cyl(1.12, 1.12, 0.18, (dx, dy, 2.62), roof, n=12), cyl(1.15, 0.0, 1.8, (dx, dy, 3.6), roof, n=12)]
for k in range(12):
    a = (k + 0.5) / 12 * 2 * math.pi
    t.append(rbox((0.36, 0.06, 1.3), (dx + math.cos(a) * 1.01, dy + math.sin(a) * 1.01, 1.45), mat("tomb_arch", "#A99881"), (0, 0, a + math.pi / 2)))
t.append(rbox((0.45, 0.1, 0.9), (dx + 1.02, dy, 0.85), dark, (0, 0, math.pi / 2)))
part(t, "doner_kumbet", (dx, dy, 0))
