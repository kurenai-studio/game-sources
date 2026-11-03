# Mehter band figure base: kaftan, sash, head and tall börk.
# Game units, body centre at the origin, game Y up. Blender Z = game Y, Blender Y = -game Z (depth).
# Every part is built around its own centre and placed with object.location, so the game can instance
# each part at the same offsets it used for the old box primitives.
coat = mat("kaftan", "#9b1c1c", rough=0.8)
sash_m = mat("sash", "#d4a017", rough=0.7)
skin = mat("skin", "#d8a57c", rough=0.9)
hat_m = mat("hat", "#b3261e", rough=0.7)


def bake(parts, name):
    # bake each part's location into its mesh, then join around the shared origin
    for o in parts:
        bpy.ops.object.select_all(action="DESELECT")
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.transform_apply(location=True)
    return join(parts, name)


def squash(o, sx, sy, sz):
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    o.scale = (sx, sy, sz)
    bpy.ops.object.transform_apply(scale=True)
    return o


def place(o, gx, gy, gz):
    # game offset -> Blender location
    o.location = (gx, -gz, gy)
    return o


# kaftan: octagonal frustum, flared hem, slimmer shoulders, flattened front-to-back
kaftan = squash(cyl(0.19, 0.25, 0.9, (0, 0, 0), coat, n=8), 1, 0.62, 1)
# collar ring at the shoulders
collar = squash(cyl(0.15, 0.2, 0.08, (0, 0, 0.44), coat, n=8), 1, 0.62, 1)
body = bake([kaftan, collar], "body")
place(body, 0, 0, 0)

# sash across the waist, slightly wider than the kaftan at that height
sash = squash(cyl(0.225, 0.225, 0.1, (0, 0, 0), sash_m, n=8), 1, 0.66, 1)
sash.name = "sash"
place(sash, 0, 0.12, 0)

# head: low-poly sphere (same centre as the old primitive)
head = sphere(0.16, (0, 0, 0), skin, n=10, rings=8)
head.name = "head"
place(head, 0, 0.6, 0)

# tall börk: brim plus a tapered crown, centred on the old fez position
brim = cyl(0.17, 0.17, 0.04, (0, 0, -0.1), hat_m, n=10)
crown = cyl(0.15, 0.12, 0.2, (0, 0, 0.02), hat_m, n=10)
top = cyl(0.12, 0.11, 0.02, (0, 0, 0.13), hat_m, n=10)
hat = bake([brim, crown, top], "hat")
place(hat, 0, 0.82, 0)
