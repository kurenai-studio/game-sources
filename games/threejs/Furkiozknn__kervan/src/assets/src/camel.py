# Pack camel for Kervan (game units: legs 1.0 tall, hump top about 2.1, faces +X).
# Parts: camel_body (fixed), camel_head (pivot at the shoulder, nods), camel_leg (pivot at the hip, swings),
# camel_load (white sacks are tinted per good in the game). preview_* objects only fill the preview.
import os, sys
exec(open(os.path.join(os.path.dirname(sys.argv[sys.argv.index("--") + 1]), "_kv.py"), encoding="utf-8").read())

fur = mat("fur", "#C49A63"); fur_d = mat("fur_dark", "#A97C48"); fur_l = mat("fur_light", "#D6B07C")
red = mat("blanket", "#8E2F25"); gold = mat("brass", "#D9A43A", rough=0.5, metal=0.4); dark = mat("dark", "#3A2A20")
hoof = mat("pad", "#6E5640"); white = mat("tint", "#F4F0E8"); cream = mat("cream", "#E8E0D0"); rope = mat("rope", "#8D8270")
wood = mat("wood", "#6B4A2E"); blue = mat("bead", "#2F7FA0")

# ---- body: barrel, hump, chest, haunches, tail, saddle blanket with tassels
body = [
    sphere(1, (-0.05, 0, 1.36), fur, n=6, rings=4, scale=(0.98, 0.37, 0.4)),
    sphere(1, (-0.15, 0, 1.72), fur, n=7, rings=4, scale=(0.5, 0.3, 0.38)),          # hump
    sphere(1, (0.62, 0, 1.28), fur_l, n=6, rings=4, scale=(0.36, 0.31, 0.38)),        # chest
    sphere(1, (-0.68, 0, 1.3), fur, n=6, rings=4, scale=(0.4, 0.34, 0.36)),           # haunch
    sphere(1, (-0.05, 0, 1.0), fur_l, n=6, rings=4, scale=(0.6, 0.22, 0.1)),          # belly
    rod((-1.0, 0, 1.5), (-1.12, 0, 0.95), 0.06, 0.035, fur_d, n=5),                    # tail
    cyl(0.07, 0.0, 0.18, (-1.13, 0, 0.86), dark, n=5, rot=(math.pi, 0, 0)),           # tail tuft
    box((1.05, 0.86, 0.05), (-0.12, 0, 1.97), red, rot=(0, 0, 0)),                     # blanket on the hump
    box((1.05, 0.05, 0.42), (-0.12, 0.44, 1.76), red), box((1.05, 0.05, 0.42), (-0.12, -0.44, 1.76), red),
    box((1.07, 0.06, 0.07), (-0.12, 0.45, 1.56), gold), box((1.07, 0.06, 0.07), (-0.12, -0.45, 1.56), gold),
]
for s in (-1, 1):
    for i in range(2):
        body.append(cyl(0.035, 0.0, 0.16, (-0.38 + i * 0.54, s * 0.46, 1.45), blue if i % 2 else gold, n=4, rot=(math.pi, 0, 0)))
# pack saddle frame, girth rope and a copper pot stay on the camel when it carries nothing
body += [box((0.07, 1.16, 0.07), (-0.55, 0, 2.02), wood), box((0.07, 1.16, 0.07), (0.31, 0, 2.02), wood),
         box((0.06, 0.06, 0.5), (-0.55, 0.57, 1.78), wood), box((0.06, 0.06, 0.5), (-0.55, -0.57, 1.78), wood),
         box((0.06, 0.06, 0.5), (0.31, 0.57, 1.78), wood), box((0.06, 0.06, 0.5), (0.31, -0.57, 1.78), wood),
         box((0.05, 0.8, 0.04), (0.1, 0, 0.97), rope),
         cyl(0.1, 0.08, 0.17, (0.45, 0.6, 1.55), mat("copper", "#B8683A", rough=0.4, metal=0.6), n=5)]
for o in body[:5]:
    jitter(o, 0.012, seed=3)
part(body, "camel_body")

# ---- head and neck: pivot at the shoulder so the game can nod it
P = (0.78, 0, 1.55)
head = [
    rod((0.72, 0, 1.45), (1.02, 0, 1.62), 0.2, 0.16, fur, n=5),                          # neck base
    rod((1.0, 0, 1.6), (1.26, 0, 2.0), 0.15, 0.12, fur, n=5),                            # upper neck
    sphere(1, (1.36, 0, 2.06), fur, n=6, rings=4, scale=(0.24, 0.14, 0.15)),             # skull
    rod((1.4, 0, 2.03), (1.7, 0, 1.96), 0.11, 0.085, fur_l, n=5),                        # muzzle
    box((0.06, 0.24, 0.04), (1.6, 0, 1.91), dark),                                        # mouth line
    cyl(0.04, 0.0, 0.12, (1.28, 0.1, 2.2), fur_d, n=4, rot=(0.4, 0, 0)), cyl(0.04, 0.0, 0.12, (1.28, -0.1, 2.2), fur_d, n=4, rot=(-0.4, 0, 0)),
    box((0.06, 0.26, 0.05), (1.43, 0, 2.1), dark),
    # red halter with a brass bell under the throat
    box((0.035, 0.25, 0.2), (1.5, 0, 2.02), red), box((0.035, 0.2, 0.17), (1.62, 0, 1.98), red),
    cyl(0.06, 0.09, 0.14, (1.1, 0, 1.36), gold, n=5),
]
part(head, "camel_head", P)

# ---- one leg: pivot at the hip, 1.0 long; the game places four of them
def leg(name, at):
    x, y, z = at
    o = [rod((x, y, z), (x + 0.02, y, z - 0.5), 0.12, 0.075, fur, n=6),
         sphere(0.085, (x + 0.02, y, z - 0.52), fur_d, n=6, rings=4),
         rod((x + 0.02, y, z - 0.52), (x, y, z - 0.93), 0.065, 0.055, fur, n=6),
         cyl(0.11, 0.09, 0.08, (x + 0.02, y, z - 0.96), hoof, n=5)]
    return part(o, name, at)

leg("camel_leg", (0.72, 0.24, 1.0))
for i, (x, y) in enumerate([(0.72, -0.24), (-0.72, 0.24), (-0.72, -0.24)] if PREVIEW else []):
    leg("preview_leg_%d" % i, (x, y, 1.0))

# ---- load: side sacks (tinted per good), rolled carpet, wooden frame, ropes, a copper pot
load = [
    sphere(1, (-0.1, 0.52, 1.6), white, n=6, rings=4, scale=(0.48, 0.19, 0.33)),
    sphere(1, (-0.1, -0.52, 1.6), white, n=6, rings=4, scale=(0.48, 0.19, 0.33)),
    box((0.8, 0.05, 0.3), (-0.1, 0.62, 1.62), white), box((0.8, 0.05, 0.3), (-0.1, -0.62, 1.62), white),
    rod((-0.1, -0.46, 2.12), (-0.1, 0.46, 2.12), 0.14, 0.14, cream, n=8),                 # rolled carpet
    rod((-0.1, -0.47, 2.12), (-0.1, -0.36, 2.12), 0.145, 0.145, white, n=8),
    rod((-0.1, 0.36, 2.12), (-0.1, 0.47, 2.12), 0.145, 0.145, white, n=8),
]
part(load, "camel_load")
