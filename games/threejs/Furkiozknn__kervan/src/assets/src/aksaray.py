# Aksaray: the leaning brick minaret (Egri Minare) relative to the city centre (Blender y = -game z). It leans 0.13 rad
# towards -X like the procedural one; banded brick courses, a turquoise tile band, a balcony and a conical cap.
import os, sys
exec(open(os.path.join(os.path.dirname(sys.argv[sys.argv.index("--") + 1]), "_kv.py"), encoding="utf-8").read())

brick = mat("brick", "#B4643F"); brick2 = mat("brick_dark", "#9A4F31"); brick3 = mat("brick_light", "#C9805A")
tile = mat("tile", "#2FA9A3"); cap = mat("cap", "#8E4A2E"); stone = mat("stone", "#CDB590"); dark = mat("shadow", "#3A2A20")

x, y = 2.0, -1.0
H = 7.5
o = [box((1.7, 1.7, 0.9), (x, y, 0.25), stone), box((1.5, 1.5, 0.5), (x, y, 0.95), brick2),
     cyl(0.66, 0.62, H, (x, y, 0.9 + H / 2), brick, n=12)]
for k in range(7):  # zig-zag brick courses: alternating dark and light rings
    z = 1.6 + k * 0.85
    o.append(cyl(0.665 - k * 0.006, 0.665 - k * 0.006, 0.16, (x, y, z), brick2 if k % 2 else brick3, n=12))
o += [cyl(0.67, 0.67, 0.45, (x, y, 0.9 + H * 0.62), tile, n=12),
      cyl(0.66, 0.95, 0.25, (x, y, 0.9 + H * 0.8), brick2, n=12), cyl(0.97, 0.97, 0.12, (x, y, 0.9 + H * 0.8 + 0.18), stone, n=12),
      cyl(0.5, 0.5, 0.8, (x, y, 0.9 + H * 0.8 + 0.64), brick, n=12), cyl(0.56, 0.0, 1.5, (x, y, 0.9 + H * 0.8 + 1.79), cap, n=12),
      box((0.3, 0.08, 0.6), (x, y - 0.66, 1.5), dark)]
for k in range(12):
    a = k / 12 * 2 * math.pi
    o.append(cyl(0.025, 0.025, 0.35, (x + math.cos(a) * 0.93, y + math.sin(a) * 0.93, 0.9 + H * 0.8 + 0.42), stone, n=3))
m = part(o, "egri_minare", (x, y, 0))
m.rotation_euler = (0, -0.13, 0)  # lean (node rotation, used by the game)
