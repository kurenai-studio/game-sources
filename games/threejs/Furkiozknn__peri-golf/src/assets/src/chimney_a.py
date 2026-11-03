# Fairy chimney A: slender tuff cone with a basalt cap, a carved door, a window and a dovecote row.
# Canonical size: 3.4 m tall, 0.55 m base radius (the game scales instances).
tuff = mat("tuff", "#DDB58E"); tuff2 = mat("tuff_dark", "#C99A70"); cap = mat("basalt", "#6B5243"); dark = mat("dark", "#2E221B")
body = jitter(cyl(0.55, 0.26, 3.0, (0, 0, 1.5), tuff, n=11), 0.035, seed=1)
band = jitter(cyl(0.5, 0.42, 0.5, (0, 0, 0.95), tuff2, n=11), 0.03, seed=5)
neck = cyl(0.26, 0.38, 0.22, (0, 0, 3.08), cap, n=9)
hat = jitter(cyl(0.44, 0.08, 0.55, (0, 0, 3.45), cap, n=9), 0.03, seed=2)
door = box((0.08, 0.26, 0.5), (0.52, 0.0, 0.3), dark)
arch = cyl(0.13, 0.13, 0.08, (0.52, 0.0, 0.55), dark, n=8, rot=(0, math.pi / 2, 0))
win = box((0.08, 0.17, 0.2), (0.41, -0.08, 1.75), dark)
holes = [box((0.07, 0.07, 0.08), (0.36 - i * 0.012, -0.2 + i * 0.1, 2.35), dark) for i in range(4)]
ledge = box((0.14, 0.5, 0.05), (0.38, -0.05, 2.25), tuff2)
origin_bottom(join([body, band, neck, hat, door, arch, win, ledge] + holes, "chimney_a"))
