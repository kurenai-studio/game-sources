# Fairy chimney C: a stout carved rock home, three windows, a balcony ledge and a stepped shoulder.
# Canonical size: 3.4 m tall, 0.55 m base radius.
tuff = mat("tuff", "#DDB58E"); tuff2 = mat("tuff_dark", "#C99A70"); cap = mat("basalt", "#6B5243"); dark = mat("dark", "#2E221B"); wood = mat("wood", "#6E4328")
body = jitter(cyl(0.6, 0.38, 2.6, (0, 0, 1.3), tuff, n=12), 0.04, seed=11)
shoulder = jitter(cyl(0.42, 0.22, 0.7, (0.05, 0.08, 2.9), tuff2, n=10), 0.03, seed=12)
hat = jitter(cyl(0.3, 0.05, 0.4, (0.05, 0.08, 3.4), cap, n=9), 0.03, seed=13)
door = box((0.08, 0.3, 0.55), (0.57, 0.0, 0.33), dark)
frame = box((0.05, 0.4, 0.06), (0.57, 0.0, 0.63), wood)
wins = [box((0.08, 0.18, 0.22), (0.52, dy, 1.45), dark) for dy in (-0.3, 0.3)]
win3 = box((0.08, 0.16, 0.2), (0.44, 0.0, 2.15), dark)
balcony = box((0.3, 0.75, 0.06), (0.6, 0.0, 1.3), wood)
rail = [box((0.03, 0.03, 0.22), (0.72, dy, 1.42), wood) for dy in (-0.34, 0.0, 0.34)]
railtop = box((0.03, 0.75, 0.03), (0.72, 0.0, 1.54), wood)
steps = [box((0.28, 0.3, 0.1), (0.62, -0.45, 0.05 + i * 0.1), tuff2) for i in range(3)]
origin_bottom(join([body, shoulder, hat, door, frame, win3, balcony, railtop] + wins + rail + steps, "chimney_c"))
