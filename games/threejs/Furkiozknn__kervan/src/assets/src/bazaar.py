# Bazaar corner placed in every city: three market stalls with striped awnings around a small square, sacks of
# spice, rolled carpets, copper pots, a merchant's tent. About 5 x 4 m, origin at the middle of the square.
import os, sys
exec(open(os.path.join(os.path.dirname(sys.argv[sys.argv.index("--") + 1]), "_kv.py"), encoding="utf-8").read())

wood = mat("wood", "#7A5232"); wood2 = mat("wood_dark", "#5A3A22"); cream = mat("canvas", "#EFE3C8")
reds = mat("stripe_red", "#B5422E"); blue = mat("stripe_blue", "#2F6F95"); ochre = mat("stripe_ochre", "#D39B3A"); green = mat("stripe_green", "#4F7A3A")
copper = mat("copper", "#B8683A", rough=0.4, metal=0.6); spice1 = mat("spice_red", "#C0442C"); spice2 = mat("spice_yellow", "#E0B341")
spice3 = mat("spice_brown", "#8A5A32"); sack = mat("sack", "#D8C49A"); rug1 = mat("rug_red", "#8E2F25"); rug2 = mat("rug_blue", "#34507A")
pave = mat("paving", "#C8B08A"); dark = mat("shadow", "#3A2A20")

o = [box((5.4, 4.2, 0.08), (0, 0, 0.02), pave)]

def stall(x, y, a, stripe):
    """Stall facing the square centre: counter, 4 posts, a sloped striped awning (in local frame turned by a)."""
    c, s = math.cos(a), math.sin(a)
    P = lambda lx, ly: (x + lx * c - ly * s, y + lx * s + ly * c)
    out = []
    for lx, ly in ((-0.8, -0.55), (0.8, -0.55), (-0.8, 0.55), (0.8, 0.55)):
        px, py = P(lx, ly)
        out.append(box((0.08, 0.08, 1.9 if ly > 0 else 1.6), (px, py, (1.9 if ly > 0 else 1.6) / 2), wood))
    cx, cy = P(0, -0.35)
    out.append(rbox((1.7, 0.5, 0.6), (cx, cy, 0.3), wood2, (0, 0, a)))
    for i in range(6):  # awning: alternating stripes, sloping down to the front
        lx = -0.85 + (i + 0.5) * (1.7 / 6)
        px, py = P(lx, 0.0)
        out.append(rbox((1.7 / 6 + 0.01, 1.45, 0.05), (px, py, 1.78), stripe if i % 2 else cream, (0.2, 0, a)))
    for i in range(6):  # scalloped valance at the front edge
        lx = -0.85 + (i + 0.5) * (1.7 / 6)
        px, py = P(lx, -0.76)
        out.append(rbox((1.7 / 6, 0.03, 0.16), (px, py, 1.55), cream if i % 2 else stripe, (0, 0, a)))
    return out

o += stall(0, 1.5, 0, reds)
o += stall(-1.8, -0.2, -math.pi / 2, blue)
o += stall(1.8, -0.2, math.pi / 2, ochre)
# goods on the counters: spice cones, pots, folded rugs
for i, m in enumerate((spice1, spice2, spice3, spice1)):
    o += [cyl(0.15, 0.16, 0.14, (-0.6 + i * 0.4, 1.15, 0.67), sack, n=6), cyl(0.14, 0.0, 0.16, (-0.6 + i * 0.4, 1.15, 0.82), m, n=6)]
for i in range(3):
    o.append(cyl(0.12, 0.09, 0.2, (-1.45, -0.7 + i * 0.45, 0.7), copper, n=7))
    o.append(sphere(0.06, (-1.45, -0.7 + i * 0.45, 0.85), copper, n=5, rings=4))
for i, m in enumerate((rug1, rug2, rug1)):
    o.append(box((0.5, 0.36, 0.06), (1.45, -0.6 + i * 0.4, 0.63 + (i % 2) * 0.06), m))
# sacks and rolled carpets on the ground, a small striped tent at the back
for i, (x, y) in enumerate(((-0.7, 0.3), (-0.35, 0.45), (0.75, 0.4))):
    o.append(jitter(sphere(1, (x, y, 0.25), sack, n=7, rings=5, scale=(0.24, 0.22, 0.3)), 0.02, seed=i))
o += [rod((0.2, -1.4, 0.13), (1.2, -1.4, 0.13), 0.13, 0.13, rug1, n=7), rod((0.2, -1.12, 0.13), (1.1, -1.12, 0.13), 0.12, 0.12, rug2, n=7),
      rod((0.4, -1.26, 0.37), (1.0, -1.26, 0.37), 0.11, 0.11, ochre, n=7)]
tx, ty = -1.6, 1.7
o += [cyl(0.95, 0.95, 1.0, (tx, ty, 0.5), cream, n=8), cyl(1.05, 0.0, 1.0, (tx, ty, 1.5), reds, n=8),
      box((0.5, 0.06, 0.8), (tx + 0.6, ty - 0.75, 0.45), dark), cyl(0.03, 0.03, 0.5, (tx, ty, 2.2), wood, n=4)]
part(o, "bazaar", (0, 0, 0))
