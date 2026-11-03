# Mehter band instruments: davul (drum), kos (big drum), zurna (double-reed pipe), cevgen (staff with jingle ring).
# Each part is centred on its own origin (like the old primitives); object.location is the offset the game
# uses relative to the body centre. Game axes: Y up, drum/ring axes along game Y before the game's X rotation.
# Blender Z = game Y, Blender Y = -game Z.
skin_drum = mat("drum", "#9b5a2b", rough=0.8)
kos_m = mat("kos", "#d4a017", rough=0.6)
zurna_m = mat("zurna", "#e0b84a", rough=0.5)
staff_m = mat("staff", "#5a3a1a", rough=0.7)
brass = mat("brass", "#d4a017", rough=0.4, metal=0.6)


def bake(parts, name):
    for o in parts:
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.transform_apply(location=True)
    return join(parts, name)


def place(o, gx, gy, gz):
    o.location = (gx, -gz, gy)
    return o


# one material per part: a multi-material object exports as a glTF group, and the game reads one mesh per part.
# davul: shell with a rim at each head
shell = cyl(0.26, 0.26, 0.36, (0, 0, 0), skin_drum, n=12)
rim_a = cyl(0.27, 0.27, 0.04, (0, 0, 0.18), skin_drum, n=12)
rim_b = cyl(0.27, 0.27, 0.04, (0, 0, -0.18), skin_drum, n=12)
davul = bake([shell, rim_a, rim_b], "davul")
place(davul, -0.05, 0.15, 0.22)

# kos: wider, deeper drum with rims
kos_shell = cyl(0.42, 0.42, 0.36, (0, 0, 0), kos_m, n=14)
kos_a = cyl(0.44, 0.44, 0.05, (0, 0, 0.18), kos_m, n=14)
kos_b = cyl(0.44, 0.44, 0.05, (0, 0, -0.18), kos_m, n=14)
kos = bake([kos_shell, kos_a, kos_b], "kos")
place(kos, 0.3, 0.1, 0.2)

# zurna: thin reed end, flaring bell at the top (Y in game, so the bell points at the crowd after rotation)
pipe = cyl(0.04, 0.08, 0.7, (0, 0, 0), zurna_m, n=8)
reed = cyl(0.02, 0.02, 0.1, (0, 0, -0.4), zurna_m, n=6)
zurna = bake([pipe, reed], "zurna")
place(zurna, 0, 0.6, 0.42)

# cevgen: long staff
staff = cyl(0.035, 0.035, 2.1, (0, 0, 0), staff_m, n=6)
staff.name = "cevgen_staff"
place(staff, 0.42, 0.6, 0)

# cevgen jingle ring: torus with eight bells hung round the rim
torus_loc = (0, 0, 0)
bpy.ops.mesh.primitive_torus_add(major_radius=0.16, minor_radius=0.025, major_segments=18, minor_segments=6, location=torus_loc)
ring_t = bpy.context.object
ring_t.data.materials.append(brass)
bells = []
for k in range(8):
    a = k * math.pi / 4
    bells.append(sphere(0.03, (0.16 * math.cos(a), 0.16 * math.sin(a), 0), brass, n=6, rings=4))
ring = bake([ring_t] + bells, "cevgen_ring")
place(ring, 0.42, 1.45, 0)
