# Hot-air balloon in two objects: "envelope" (gore stripes as light/dark bands, per-instance colour in
# the game) and "basket" (wicker basket, burner frame, ropes, burner). Envelope radius 1.4 m; the
# basket hangs 3.1 m below the envelope centre, matching the game's instancing offsets.
import bmesh
# gore shades are multiplied by the per-instance colour in the game (sRGB #E4E4E4 = 0.78 linear)
light = mat("gore_light", "#FFFFFF"); dark = mat("gore_dark", "#E4E4E4"); crown = mat("crown", "#F2F2F2")
env = sphere(1.4, (0, 0, 0), light, n=14, rings=9, scale=(1, 1, 1.18))
env.data.materials.append(dark); env.data.materials.append(crown)
for p in env.data.polygons:
    c = p.center
    a = math.atan2(c.y, c.x)
    gore = int((a + math.pi) / (2 * math.pi / 14)) % 2
    p.material_index = 2 if c.z > 1.3 else gore
skirt = cyl(0.3, 1.0, 1.0, (0, 0, -2.0), dark, n=14)
skirt.data.materials.append(light)
for i, p in enumerate(skirt.data.polygons):
    p.material_index = 1 if (i % 2 == 0 and len(p.vertices) == 4) else 0
envelope = join([env, skirt], "envelope")
wood = mat("wicker", "#8A5A32"); wood2 = mat("wicker_dark", "#6E4328"); rope = mat("rope", "#D9C39A"); steel = mat("burner", "#3A3A3A"); flame = mat("flame", "#FFB347", emit=1.0)
basket = box((0.55, 0.55, 0.45), (0, 0, -3.1), wood)
rim = box((0.62, 0.62, 0.06), (0, 0, -2.9), wood2)
posts = [cyl(0.02, 0.02, 0.75, (sx * 0.24, sy * 0.24, -2.5), wood2, n=4) for sx in (-1, 1) for sy in (-1, 1)]
burner = cyl(0.1, 0.12, 0.16, (0, 0, -2.3), steel, n=8)
fire = cyl(0.0, 0.07, 0.14, (0, 0, -2.15), flame, n=6)
ropes = [cyl(0.012, 0.012, 1.0, (sx * 0.35, sy * 0.35, -2.4), rope, n=4, rot=(sy * -0.28, sx * 0.28, 0)) for sx in (-1, 1) for sy in (-1, 1)]
join([basket, rim, burner, fire] + posts + ropes, "basket")
