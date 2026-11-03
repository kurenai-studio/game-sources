# Cappadocian cave house: a carved stone block with an arched door, shuttered windows, a flat roof
# with a parapet, a stone stair to the roof and a small dovecote. About 2.4 x 2.2 x 2.0 m.
stone = mat("stone", "#DCC0A0"); stone2 = mat("stone_dark", "#C9A882"); dark = mat("dark", "#2E221B"); wood = mat("wood", "#6E4328"); cap = mat("basalt", "#6B5243")
body = jitter(box((2.4, 2.0, 1.7), (0, 0, 0.85), stone), 0.025, seed=21)
roof = box((2.5, 2.1, 0.12), (0, 0, 1.76), stone2)
parapet = [box((2.5, 0.12, 0.3), (0, dy, 1.95), stone) for dy in (-0.99, 0.99)] + [box((0.12, 2.1, 0.3), (dx, 0, 1.95), stone) for dx in (-1.19, 1.19)]
door = box((0.4, 0.08, 1.0), (-0.5, -1.02, 0.5), dark)
arch = cyl(0.2, 0.2, 0.08, (-0.5, -1.02, 1.0), dark, n=10, rot=(math.pi / 2, 0, 0))
lintel = box((0.6, 0.1, 0.1), (-0.5, -1.04, 1.26), wood)
win = box((0.36, 0.08, 0.4), (0.5, -1.02, 0.95), dark)
shutters = [box((0.14, 0.05, 0.44), (0.5 + s * 0.28, -1.05, 0.95), wood) for s in (-1, 1)]
sidewin = box((0.08, 0.34, 0.36), (1.22, 0.3, 1.0), dark)
stair = [box((0.5, 0.36, 0.22 * (i + 1)), (1.46, -0.7 + i * 0.36, 0.11 * (i + 1)), stone2) for i in range(5)]
dovecote = box((0.7, 0.6, 0.6), (0.6, 0.55, 2.1), stone2)
dholes = [box((0.08, 0.08, 0.1), (0.6 + (i % 3 - 1) * 0.2, 0.24, 2.0 + (i // 3) * 0.22), dark) for i in range(6)]
chim = cyl(0.14, 0.18, 0.5, (-0.7, 0.5, 2.05), stone, n=7)
chimcap = cyl(0.18, 0.1, 0.12, (-0.7, 0.5, 2.35), cap, n=7)
pot = cyl(0.16, 0.12, 0.3, (0.95, -0.8, 1.95), mat("clay", "#A8623C"), n=8)
origin_bottom(join([body, roof, door, arch, lintel, win, sidewin, dovecote, chim, chimcap, pot] + parapet + shutters + stair + dholes, "cave_house"))
