# Seljuk caravanserai (han) for Kervan: 10 m square court, Seljuk portal facing -Y (the road), covered winter hall at
# the back, kosk mescit on four piers in the court. The game shows parts by level:
#   han_base always, han_towers_low (levels 0-2) or han_towers_high (level 3), han_crenels + han_dome (level 2+),
#   han_banners (owned), han_flag always. Materials named "tint" are recoloured in the game (flag colour).
import os, sys
exec(open(os.path.join(os.path.dirname(sys.argv[sys.argv.index("--") + 1]), "_kv.py"), encoding="utf-8").read())

S, T, Hh = 10.0, 0.8, 2.2
stone = mat("stone", "#D6BA8E"); stone2 = mat("stone_dark", "#C8A87A"); light = mat("stone_light", "#E7D2AA")
pave = mat("paving", "#BFA27A"); hall = mat("hall", "#C9AB80"); roof = mat("roof", "#AE9068"); dark = mat("shadow", "#3A2A20")
door = mat("door", "#5A3A22"); lead = mat("lead", "#8E9AA6", rough=0.5, metal=0.3); tile = mat("tile", "#2FA9A3")
water = mat("water", "#3D8FA2", rough=0.2); pole = mat("pole", "#5A4634"); tint = mat("tint", "#FFFFFF")

base = [box((S, S, 0.35), (0, 0, 0.175), stone2),
        box((S - 2 * T, S - 2 * T, 0.04), (0, 0, 0.37), pave)]
# outer walls with a plinth and a light cornice
for (sx, sy, x, y) in [(S, T, 0, S / 2), (T, S, -S / 2, 0), (T, S, S / 2, 0), (3.4, T, -3.3, -S / 2), (3.4, T, 3.3, -S / 2)]:
    base += [box((sx, sy, Hh), (x, y, Hh / 2), stone),
             box((sx + 0.14, sy + 0.14, 0.35), (x, y, 0.35 / 2 + 0.02), stone2),
             box((sx + 0.1, sy + 0.1, 0.16), (x, y, Hh - 0.02), light)]
# triangular buttresses on the side walls, square ones on the back
for sx in (-1, 1):
    for y in (-2.2, 1.6):
        base.append(cyl(0.55, 0.42, Hh - 0.2, (sx * (S / 2 + 0.25), y, (Hh - 0.2) / 2), stone2, n=3, rot=(0, 0, 0 if sx > 0 else math.pi)))
for x in (-3.5, 3.5):
    base.append(box((0.7, 0.7, Hh - 0.1), (x, S / 2 + 0.3, (Hh - 0.1) / 2), stone2))
# Seljuk portal: tall block, light frame, recessed pointed-arch niche with a stepped (muqarnas) hood, studded door
PY = -S / 2 - 0.2
base += [box((3.4, 1.5, Hh + 1.7), (0, PY, (Hh + 1.7) / 2), stone2),
         box((3.0, 0.1, Hh + 1.3), (0, PY - 0.76, (Hh + 1.3) / 2 + 0.1), light),
         box((2.3, 0.3, 2.9), (0, PY - 0.68, 1.45 + 0.2), dark),
         box((2.0, 0.32, 0.18), (0, PY - 0.64, 3.0), stone), box((1.6, 0.32, 0.18), (0, PY - 0.62, 3.18), stone2),
         box((1.1, 0.32, 0.18), (0, PY - 0.6, 3.36), stone), box((0.6, 0.32, 0.18), (0, PY - 0.58, 3.54), stone2),
         rbox((1.25, 0.12, 0.16), (-0.48, PY - 0.78, 3.35), light, (0, 0.62, 0)), rbox((1.25, 0.12, 0.16), (0.48, PY - 0.78, 3.35), light, (0, -0.62, 0)),
         box((1.5, 0.1, 2.0), (0, PY - 0.5, 1.2), door),
         cyl(0.75, 0.75, 0.1, (0, PY - 0.5, 2.2), door, n=10, rot=(math.pi / 2, 0, 0)),
         box((2.4, 0.08, 0.3), (0, PY - 0.82, Hh + 1.3), light),
         box((2.4, 0.06, 0.12), (0, PY - 0.84, Hh + 1.3), tile)]
for i in range(3):
    for j in range(2):
        base.append(box((0.07, 0.04, 0.07), (-0.45 + i * 0.45, PY - 0.56, 0.8 + j * 0.8), mat("iron", "#2A2420")))
# covered winter hall at the back, with a central arched opening onto the court
base += [box((S - 1.2, 3.4, Hh + 0.5), (0, S / 2 - 2, (Hh + 0.5) / 2), hall),
         box((S - 1.6, 3.0, 0.3), (0, S / 2 - 2, Hh + 0.65), roof),
         box((1.4, 0.1, 1.8), (0, S / 2 - 3.72, 1.1), dark),
         cyl(0.7, 0.7, 0.1, (0, S / 2 - 3.72, 2.0), dark, n=10, rot=(math.pi / 2, 0, 0))]
for x in (-3, -1.5, 1.5, 3):
    base.append(box((0.5, 0.1, 1.0), (x, S / 2 - 3.72, 1.0), dark))
# arcades along the side walls of the court
for sx in (-1, 1):
    x = sx * (S / 2 - T / 2 - 0.7)
    base.append(box((1.4, 5.2, 0.22), (x, -0.9, 2.0), roof))
    base.append(box((0.08, 5.0, 1.4), (sx * (S / 2 - T - 0.03), -0.9, 1.05), dark))
    for k in range(4):
        base.append(box((0.24, 0.24, 1.6), (sx * (S / 2 - T / 2 - 1.3), -3.1 + k * 1.47, 1.0), stone))
# kosk mescit on four piers, with a stair and a small dome; fountain beside it
MY = -1.0
for dx in (-0.7, 0.7):
    for dy in (-0.7, 0.7):
        base.append(box((0.3, 0.3, 1.3), (dx, MY + dy, 0.95), stone2))
base += [box((1.9, 1.9, 0.9), (0, MY, 2.05), stone), box((2.0, 2.0, 0.1), (0, MY, 2.55), light),
         box((0.5, 0.2, 0.4), (0, MY - 0.96, 2.0), dark)]
base += dome(0.7, (0, MY, 2.6), lead, n=10, h=0.55)
for k in range(5):
    base.append(box((0.5, 0.3, 0.12), (1.25, MY - 0.4 + k * 0.3, 0.42 + k * 0.32), stone2))
base += [cyl(0.55, 0.6, 0.35, (-2.2, -2.6, 0.55), stone2, n=8), cyl(0.45, 0.45, 0.04, (-2.2, -2.6, 0.72), water, n=8),
         cyl(0.08, 0.06, 0.6, (-2.2, -2.6, 0.95), stone, n=6)]
part(base, "han_base")

# corner towers: low hexagonal buttresses, or tall round towers with caps at level 3
low = [cyl(0.65, 0.6, Hh + 0.3, (dx * S / 2, dy * S / 2, (Hh + 0.3) / 2), stone2, n=6) for dx in (-1, 1) for dy in (-1, 1)]
low += [cyl(0.7, 0.7, 0.14, (dx * S / 2, dy * S / 2, Hh + 0.3), light, n=6) for dx in (-1, 1) for dy in (-1, 1)]
part(low, "han_towers_low")
high = []
for dx in (-1, 1):
    for dy in (-1, 1):
        x, y = dx * S / 2, dy * S / 2
        high += [cyl(0.9, 0.8, Hh + 1.6, (x, y, (Hh + 1.6) / 2), stone2, n=10),
                 cyl(0.95, 0.95, 0.2, (x, y, Hh + 1.65), light, n=10),
                 cyl(0.9, 0.0, 1.1, (x, y, Hh + 1.75 + 0.55), roof, n=10),
                 box((0.18, 0.1, 0.4), (x - dx * 0.0, y - 0.85 if dy < 0 else y + 0.85, Hh + 0.9), dark)]
part(high, "han_towers_high")

# level 2+: crenellations along the wall tops and a lead dome on a drum over the winter hall
cren = []
for (L, x, y, along) in [(S, 0, S / 2, "x"), (S, -S / 2, 0, "y"), (S, S / 2, 0, "y"), (3.4, -3.3, -S / 2, "x"), (3.4, 3.3, -S / 2, "x")]:
    n = int(L / 0.7)
    for i in range(n):
        t = (i + 0.5) / n - 0.5
        cren.append(box((0.36, 0.5, 0.36), (x + t * L, y, Hh + 0.2), stone) if along == "x" else box((0.5, 0.36, 0.36), (x, y + t * L, Hh + 0.2), stone))
part(cren, "han_crenels")
dm = [cyl(1.5, 1.5, 0.5, (0, S / 2 - 2, Hh + 1.05), hall, n=12)]
dm += dome(1.45, (0, S / 2 - 2, Hh + 1.3), lead, n=14, h=1.15)
part(dm, "han_dome")

# owner's banners beside the door and the flag on the portal
part([box((0.5, 0.05, 1.6), (k, PY - 0.82, 1.7), tint) for k in (-1.25, 1.25)] +
     [box((0.6, 0.06, 0.08), (k, PY - 0.84, 2.5), pole) for k in (-1.25, 1.25)], "han_banners")
part([cyl(0.06, 0.05, 2.3, (0, PY, Hh + 1.7 + 1.15), pole, n=5),
      box((1.4, 0.06, 0.75), (0.75, PY, Hh + 3.25), tint),
      rbox((0.5, 0.06, 0.4), (1.55, PY, Hh + 3.25), tint, (0, 0.785, 0)),
      sphere(0.09, (0, PY, Hh + 4.0), mat("brass", "#D9A43A", rough=0.5, metal=0.4), n=6, rings=4)], "han_flag")
