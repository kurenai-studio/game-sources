# Goreme fairy chimneys: three variants, each 5.0 tall and 1.35 wide at the base so the game can scale them to the
# procedural sizes (sx = w / 1.35, sy = h / 5). Carved windows, doors and dovecote holes, dark basalt caps.
import os, sys
exec(open(os.path.join(os.path.dirname(sys.argv[sys.argv.index("--") + 1]), "_kv.py"), encoding="utf-8").read())

tuff = mat("tuff", "#E3C5A4"); tuff2 = mat("tuff_band", "#D4AE8A"); tuff3 = mat("tuff_pale", "#EBD3B6")
cap = mat("basalt", "#7E604B"); dark = mat("shadow", "#3A2A20"); door = mat("door", "#6B4A2E"); white = mat("dovecote", "#F2EADB")
W, H = 1.35, 5.0

def hole(x, y, z, a, w=0.3, h=0.42, m=dark):
    return rbox((w, 0.14, h), (x, y, z), m, (0, 0, a + math.pi / 2))

def surface_r(z, r0, r1, h):
    return r0 + (r1 - r0) * (z / h)

def chimney(name, x0, seed, twin=False, dovecote=False):
    o = [jitter(cyl(W, 0.32, H * 0.88, (x0, 0, H * 0.44), tuff, n=10), 0.05, seed=seed),
         jitter(cyl(W * 0.86, W * 0.62, H * 0.32, (x0, 0, H * 0.16), tuff2, n=10), 0.04, seed=seed + 1),
         cyl(W * 1.05, W * 0.9, 0.3, (x0, 0, 0.0), tuff3, n=10)]
    tops = [(x0, 0)] if not twin else [(x0 - 0.3, 0.1), (x0 + 0.35, -0.1)]
    for i, (tx, ty) in enumerate(tops):
        h = H * (0.88 if not twin else (0.8 if i == 0 else 0.92))
        if twin:
            o.append(jitter(cyl(0.6, 0.28, h * 0.55, (tx, ty, h * 0.6), tuff3, n=8), 0.04, seed=seed + 5 + i))
        o += [jitter(cyl(0.62, 0.42, 0.28, (tx, ty, h - 0.05), cap, n=8), 0.03, seed=seed + 2),
              jitter(cyl(0.5, 0.0, 0.85, (tx, ty, h + 0.5), cap, n=8), 0.04, seed=seed + 3)]
    rnd = random.Random(seed)
    for k in range(4):  # windows in the cone wall
        a, z = rnd.uniform(0, 2 * math.pi), rnd.uniform(1.0, 2.6)
        r = surface_r(z, W, 0.32, H * 0.88) - 0.02
        o.append(hole(x0 + math.cos(a) * r, math.sin(a) * r, z, a))
    o.append(hole(x0 + math.cos(-1.6) * (W - 0.05), math.sin(-1.6) * (W - 0.05), 0.55, -1.6, 0.45, 0.8, door))
    if dovecote:  # whitewashed band with rows of pigeon holes
        o.append(cyl(surface_r(3.2, W, 0.32, H * 0.88) + 0.03, surface_r(3.7, W, 0.32, H * 0.88) + 0.03, 0.5, (x0, 0, 3.45), white, n=10))
        for k in range(8):
            a = k / 8 * 2 * math.pi
            r = surface_r(3.45, W, 0.32, H * 0.88) + 0.04
            o.append(hole(x0 + math.cos(a) * r, math.sin(a) * r, 3.45, a, 0.1, 0.14))
    part(o, name, (x0, 0, 0))

chimney("chimney_a", 0.0, 11)
chimney("chimney_b", 3.2, 21, twin=True)
chimney("chimney_c", 6.4, 31, dovecote=True)
