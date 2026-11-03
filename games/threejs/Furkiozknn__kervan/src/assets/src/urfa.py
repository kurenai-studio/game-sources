# Urfa landmarks relative to the city centre (Blender y = -game z):
# kale: the castle hill with its sandstone walls and the twin Corinthian columns; balikligol: the sacred fish pool with
# a stone rim, an arcade along one side and the square minaret of the mosque beside it.
import os, sys
exec(open(os.path.join(os.path.dirname(sys.argv[sys.argv.index("--") + 1]), "_kv.py"), encoding="utf-8").read())

hill = mat("hill", "#C79F6A"); hill2 = mat("hill_dark", "#B48A57"); wall = mat("sandstone", "#B89060"); wall2 = mat("sandstone_light", "#D9B57E")
dark = mat("shadow", "#3A2A20"); water = mat("water", "#3D8FA2", rough=0.2); rim = mat("rim", "#C9A877")
fish = mat("fish", "#E08A3A"); green = mat("leaf", "#5E8A3A")

hx, hy = 1.0, 7.0
k = [jitter(sphere(1, (hx, hy, -0.5), hill, n=12, rings=6, scale=(6.0, 4.2, 3.6)), 0.25, seed=7),
     jitter(sphere(1, (hx + 0.6, hy - 0.6, 0.6), hill2, n=10, rings=6, scale=(4.2, 3.0, 2.2)), 0.18, seed=8)]
cut_below(k[0], -0.3); cut_below(k[1], -0.3)
k += [box((6.4, 2.6, 2.1), (hx, hy, 2.85), wall), box((6.6, 2.8, 0.16), (hx, hy, 3.9), wall2)]
for i in range(9):
    k.append(box((0.4, 0.4, 0.35), (hx - 3.0 + i * 0.75, hy - 1.25, 4.1), wall))
for sx in (-1, 1):  # corner towers of the castle wall
    k += [cyl(0.75, 0.7, 2.2, (hx + sx * 3.3, hy - 1.1, 3.1), wall, n=8), cyl(0.82, 0.82, 0.2, (hx + sx * 3.3, hy - 1.1, 4.25), wall2, n=8)]
for sx in (-1.2, 1.2):  # the twin columns with base, capital and abacus
    x = hx + sx
    k += [box((0.9, 0.9, 0.5), (x, hy, 4.2), wall2), cyl(0.36, 0.32, 3.4, (x, hy, 6.1), wall2, n=10),
          cyl(0.32, 0.5, 0.5, (x, hy, 8.05), wall2, n=10), box((1.0, 1.0, 0.22), (x, hy, 8.4), wall)]
k.append(rbox((0.6, 0.08, 1.0), (hx, hy - 1.32, 3.0), dark, (0, 0, 0)))
part(k, "kale", (hx, hy, 0))

px, py = -4.0, -2.0
p = [box((6.0, 2.2, 0.1), (px, py, 0.02), water), box((6.6, 0.4, 0.5), (px, py - 1.3, 0.05), rim),
     box((6.6, 0.4, 0.5), (px, py + 1.3, 0.05), rim), box((0.4, 2.2, 0.5), (px - 3.2, py, 0.05), rim), box((0.4, 2.2, 0.5), (px + 3.2, py, 0.05), rim)]
for i in range(7):  # arcade on the far side
    x = px - 3.0 + i
    p += [box((0.22, 0.22, 1.5), (x, py + 1.75, 0.95), wall2)]
p += [box((6.6, 0.9, 0.25), (px, py + 1.75, 1.8), wall), box((6.4, 0.08, 1.2), (px, py + 2.18, 0.95), dark)]
for i in range(6):
    p.append(cyl(0.38, 0.38, 0.06, (px - 2.5 + i, py + 1.75, 1.0), dark, n=6, rot=(math.pi / 2, 0, 0)))
rnd = random.Random(3)
for i in range(9):  # the carp
    p.append(rbox((0.28, 0.08, 0.05), (px + rnd.uniform(-2.6, 2.6), py + rnd.uniform(-0.8, 0.8), 0.1), fish, (0, 0, rnd.uniform(0, 3.1))))
# square minaret of the Halil-ur Rahman mosque at the pool's end, a plane tree beside the pool
mx, my = px + 3.9, py + 1.5
p += [box((0.9, 0.9, 6.0), (mx, my, 2.8), wall2), box((1.15, 1.15, 0.3), (mx, my, 5.0), wall), box((0.7, 0.7, 0.9), (mx, my, 5.6), wall2),
      cyl(0.5, 0.0, 1.0, (mx, my, 6.55), wall, n=4, rot=(0, 0, math.pi / 4)), box((0.2, 0.08, 0.5), (mx, my - 0.46, 3.6), dark)]
p += [cyl(0.16, 0.12, 1.4, (px - 3.9, py - 1.8, 0.6), mat("bark", "#7A5A3A"), n=5),
      jitter(sphere(1, (px - 3.9, py - 1.8, 2.0), green, n=7, rings=5, scale=(1.1, 1.1, 0.8)), 0.12, seed=9)]
part(p, "balikligol", (px, py, 0))
