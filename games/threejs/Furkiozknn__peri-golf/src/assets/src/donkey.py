# Pack donkey for hole 8, walking along +X. Objects: "body" (body, neck, head, ears, tail, saddle
# blanket and two saddle bags) and four legs "leg_fl", "leg_fr", "leg_bl", "leg_br" with their
# origin at the hip so the game can swing them. Collision box in the game: 1.1 x 0.44 m footprint.
hide = mat("hide", "#8C7B6C"); hide2 = mat("hide_dark", "#7D6C5E"); hoof = mat("hoof", "#4A3B30"); red = mat("blanket", "#E85D4A"); gold = mat("trim", "#F7C873"); sack = mat("sack", "#C9B08A"); dark = mat("dark", "#2E221B"); light = mat("muzzle", "#B8AA9A")
body = jitter(box((0.9, 0.36, 0.4), (0, 0, 0.62), hide, bevel=0.06), 0.012, seed=31)
chest = box((0.3, 0.3, 0.3), (0.5, 0, 0.6), hide)
neck = box((0.26, 0.2, 0.38), (0.6, 0, 0.82), hide2, rot=(0, -0.5, 0))
head = box((0.34, 0.18, 0.2), (0.86, 0, 0.9), hide2, bevel=0.03)
muzzle = box((0.12, 0.16, 0.14), (1.02, 0, 0.86), light)
eyes = [box((0.04, 0.02, 0.04), (0.9, sy * 0.095, 0.95), dark) for sy in (-1, 1)]
ears = [box((0.05, 0.05, 0.22), (0.78, sy * 0.08, 1.08), hide2, rot=(sy * 0.35, 0, 0)) for sy in (-1, 1)]
mane = box((0.3, 0.05, 0.08), (0.62, 0, 1.0), dark, rot=(0, -0.5, 0))
tail = box((0.06, 0.05, 0.3), (-0.47, 0, 0.6), dark, rot=(0, 0.35, 0))
blanket = box((0.46, 0.5, 0.12), (-0.05, 0, 0.84), red)
trim = [box((0.48, 0.04, 0.13), (-0.05, sy * 0.24, 0.84), gold) for sy in (-1, 1)]
bags = [box((0.3, 0.14, 0.28), (-0.05, sy * 0.3, 0.68), sack) for sy in (-1, 1)]
join([body, chest, neck, head, muzzle, mane, tail, blanket] + eyes + ears + trim + bags, "body")
def leg(name, x, y):
    upper = box((0.12, 0.11, 0.26), (x, y, 0.36), hide)
    lower = box((0.09, 0.09, 0.24), (x, y, 0.13), hide2)
    hf = box((0.1, 0.1, 0.06), (x, y, 0.03), hoof)
    o = join([upper, lower, hf], name)
    # origin at the hip joint so a rotation swings the whole leg
    bpy.context.scene.cursor.location = (x, y, 0.48)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    return o
leg("leg_fl", 0.32, 0.12); leg("leg_fr", 0.32, -0.12); leg("leg_bl", -0.32, 0.12); leg("leg_br", -0.32, -0.12)
