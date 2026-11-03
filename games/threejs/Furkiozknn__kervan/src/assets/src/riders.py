# Caravan leader and guards for Kervan (game units, faces +X, ground at z = 0).
# Parts: horse (shared by leader and guards), rider (leader's face, turban, boots, sash), cloak (white kaftan, tinted
# with the owner's colour in the game), guard (armed rider without the horse).
import os, sys
exec(open(os.path.join(os.path.dirname(sys.argv[sys.argv.index("--") + 1]), "_kv.py"), encoding="utf-8").read())

bay = mat("bay", "#6B4A32"); bay_d = mat("bay_dark", "#553925"); mane = mat("mane", "#2E2018"); hoof = mat("hoof", "#3A2A20")
leather = mat("leather", "#4A3020"); brass = mat("brass", "#D9A43A", rough=0.5, metal=0.4); cloth = mat("saddlecloth", "#7B2D26")
skin = mat("skin", "#D9A877"); beard = mat("beard", "#3B2A22"); turban = mat("turban", "#F4EEE3"); boot = mat("boot", "#5A3A26")
white = mat("tint", "#FFFFFF"); white2 = mat("tint_shade", "#E6E0D8"); sash = mat("sash", "#D9A43A")
steel = mat("steel", "#9AA3AD", rough=0.4, metal=0.7); armour = mat("armour", "#4A3E46"); shield = mat("shield", "#7B2D26"); wood = mat("shaft", "#6E5B48")

# ---- horse
horse = [
    sphere(1, (0, 0, 1.12), bay, n=7, rings=4, scale=(0.7, 0.26, 0.3)),                  # barrel
    sphere(1, (0.48, 0, 1.18), bay, n=5, rings=4, scale=(0.3, 0.25, 0.3)),                 # chest
    sphere(1, (-0.48, 0, 1.17), bay, n=5, rings=4, scale=(0.3, 0.26, 0.29)),               # rump
    rod((0.55, 0, 1.25), (0.86, 0, 1.68), 0.17, 0.11, bay, n=5),                            # neck
    rod((0.82, 0, 1.72), (1.12, 0, 1.46), 0.11, 0.075, bay_d, n=5),                         # head
    sphere(0.08, (1.13, 0, 1.45), bay_d, n=6, rings=4),
    cyl(0.035, 0.0, 0.12, (0.86, 0.06, 1.82), bay_d, n=4), cyl(0.035, 0.0, 0.12, (0.86, -0.06, 1.82), bay_d, n=4),
    rbox((0.42, 0.06, 0.1), (0.72, 0, 1.6), mane, (0, 0.95, 0)),                         # mane
    rod((-0.66, 0, 1.3), (-0.86, 0, 0.78), 0.07, 0.03, mane, n=5),                          # tail
    box((0.04, 0.2, 0.04), (1.0, 0, 1.6), leather), rod((0.95, 0.1, 1.55), (0.45, 0.12, 1.45), 0.012, 0.012, leather, n=3),
    rod((0.95, -0.1, 1.55), (0.45, -0.12, 1.45), 0.012, 0.012, leather, n=3),
    box((0.6, 0.6, 0.06), (-0.04, 0, 1.4), cloth), box((0.62, 0.62, 0.025), (-0.04, 0, 1.37), brass),
    box((0.4, 0.34, 0.1), (-0.04, 0, 1.46), leather),                                        # saddle
]
for i, (x, y) in enumerate([(0.45, 0.13), (0.45, -0.13), (-0.45, 0.13), (-0.45, -0.13)]):
    horse += [rod((x, y, 1.0), (x + (0.03 if x > 0 else -0.03), y, 0.48), 0.07, 0.05, bay, n=4),
              rod((x + (0.03 if x > 0 else -0.03), y, 0.48), (x, y, 0.08), 0.045, 0.04, bay_d, n=4),
              cyl(0.06, 0.055, 0.08, (x, y, 0.04), hoof, n=4)]
for o in horse[:3]:
    jitter(o, 0.01, seed=5)
part(horse, "horse")

# ---- leader: face, beard, turban with a red cap, boots in the stirrups, brass sash buckle
rider = [
    sphere(1, (-0.04, 0, 2.2), skin, n=5, rings=4, scale=(0.15, 0.14, 0.17)),
    sphere(1, (0.04, 0, 2.08), beard, n=5, rings=4, scale=(0.1, 0.11, 0.09)),
    sphere(1, (-0.05, 0, 2.38), turban, n=7, rings=4, scale=(0.24, 0.23, 0.15)),
    cyl(0.1, 0.07, 0.16, (-0.05, 0, 2.5), cloth, n=7),
    box((0.2, 0.08, 0.26), (0.02, 0.3, 1.05), boot), box((0.2, 0.08, 0.26), (0.02, -0.3, 1.05), boot),
    sphere(0.06, (0.32, 0.17, 1.66), skin, n=5, rings=4), sphere(0.06, (0.32, -0.17, 1.66), skin, n=5, rings=4),
    box((0.06, 0.08, 0.08), (0.2, 0, 1.6), brass),
]
part(rider, "rider")
cloak = [
    cyl(0.29, 0.2, 0.62, (-0.06, 0, 1.78), white, n=6),                                      # kaftan body
    box((0.5, 0.74, 0.3), (-0.06, 0, 1.36), white2),                                          # skirts over the horse
    box((0.46, 0.76, 0.06), (-0.06, 0, 1.2), white2, rot=(0, 0, 0)),
    rod((0.0, 0.2, 1.98), (0.3, 0.17, 1.7), 0.075, 0.06, white, n=6), rod((0.0, -0.2, 1.98), (0.3, -0.17, 1.7), 0.075, 0.06, white, n=6),
    box((0.06, 0.6, 0.1), (-0.06, 0, 1.6), white2),                                           # sash (darker tint)
    cyl(0.22, 0.29, 0.1, (-0.06, 0, 2.08), white2, n=6),                                      # collar
]
part(cloak, "cloak")

# ---- guard: mail-shirt rider with a spiked helmet, spear with a pennant and a round shield
guard = [
    cyl(0.27, 0.2, 0.62, (-0.06, 0, 1.78), armour, n=6), box((0.5, 0.72, 0.3), (-0.06, 0, 1.36), armour),
    sphere(1, (-0.04, 0, 2.2), skin, n=5, rings=4, scale=(0.14, 0.13, 0.16)),
    sphere(1, (0.04, 0, 2.08), beard, n=5, rings=4, scale=(0.09, 0.1, 0.08)),
    cyl(0.17, 0.0, 0.34, (-0.05, 0, 2.43), steel, n=8), cyl(0.18, 0.18, 0.06, (-0.05, 0, 2.29), steel, n=8),
    cyl(0.02, 0.0, 0.14, (-0.05, 0, 2.66), steel, n=4),
    box((0.2, 0.08, 0.26), (0.02, 0.3, 1.05), boot), box((0.2, 0.08, 0.26), (0.02, -0.3, 1.05), boot),
    rod((0.12, 0.3, 0.7), (0.12, 0.3, 3.0), 0.025, 0.025, wood, n=4),
    cyl(0.045, 0.0, 0.26, (0.12, 0.3, 3.12), steel, n=4),
    box((0.3, 0.02, 0.16), (0.27, 0.3, 2.86), shield),
    cyl(0.3, 0.3, 0.06, (-0.06, -0.33, 1.65), shield, n=7, rot=(math.pi / 2, 0, 0)),
    cyl(0.08, 0.04, 0.06, (-0.06, -0.37, 1.65), brass, n=6, rot=(math.pi / 2, 0, 0)),
    rod((0.0, 0.2, 1.98), (0.26, 0.28, 1.7), 0.07, 0.06, armour, n=6),
]
part(guard, "guard")
if PREVIEW:  # show the leader on a horse and a guard on a second horse in the preview
    import bpy
    for name, dy in (("horse", 1.4),):
        src = bpy.data.objects[name]; cp = src.copy(); cp.data = src.data.copy(); cp.location.y += dy; bpy.context.scene.collection.objects.link(cp); cp.name = "preview_horse"
    bpy.data.objects["guard"].location.y += 1.4
