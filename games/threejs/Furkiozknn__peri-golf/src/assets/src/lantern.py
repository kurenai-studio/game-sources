# Swinging oil lantern for holes 7 and 12: one object "lantern" with its origin at the hanging point.
# Chain length 1.28 m (the physics pendulum length), lantern body below it: brass caps, a glowing
# hexagonal glass body with four iron ribs and a ring. The ball hits the lantern body (radius 0.22).
brass = mat("brass", "#8A6A2E", rough=0.5, metal=0.4); iron = mat("iron", "#3A2A1A"); glass = mat("glass", "#FFB347", emit=0.8); glass2 = mat("glass_dark", "#F59A2E", emit=0.6); ring = mat("ring", "#5A3A20")
L = 1.28
chain = [cyl(0.012, 0.012, 0.1, (0, 0, -0.05 - i * 0.1), iron, n=4, rot=(0, 0, i * 0.7)) for i in range(12)]
hook = cyl(0.03, 0.03, 0.05, (0, 0, -L + 0.03), iron, n=6)
top = cyl(0.04, 0.16, 0.1, (0, 0, -L - 0.03), ring, n=6)
body = cyl(0.13, 0.15, 0.24, (0, 0, -L - 0.2), glass, n=6)
body.data.materials.append(glass2)
for i, p in enumerate(body.data.polygons):
    p.material_index = 1 if (i % 2 == 0 and len(p.vertices) == 4) else 0
ribs = [cyl(0.012, 0.012, 0.26, (math.cos(a) * 0.145, math.sin(a) * 0.145, -L - 0.2), iron, n=4) for a in [k * math.pi / 3 + math.pi / 6 for k in range(6)]]
bottom = cyl(0.16, 0.12, 0.06, (0, 0, -L - 0.35), ring, n=6)
knob = cyl(0.03, 0.02, 0.05, (0, 0, -L - 0.4), brass, n=6)
o = join(chain + [hook, top, body, bottom, knob] + ribs, "lantern")
bpy.context.scene.cursor.location = (0, 0, 0)
bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
