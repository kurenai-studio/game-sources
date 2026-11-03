# Shared helpers for the Kervan model scripts (exec'd inside asset-forge's Blender namespace).
# Convention: every exported object is one game part. Its origin is the part's pivot and its location is where the
# game places it relative to the model origin. Blender is Z-up; glTF/three: x = x, y = z, z = -y.
import bpy, math, os, sys
PREVIEW = bool(os.environ.get("KV_PREVIEW"))  # extra objects that only make the preview PNG readable


def apply_rs(o):
    bpy.ops.object.select_all(action="DESELECT"); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)


def set_origin(o, pt):
    bpy.context.scene.cursor.location = pt
    bpy.ops.object.select_all(action="DESELECT"); o.select_set(True); bpy.context.view_layer.objects.active = o
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    return o


def part(objs, name, origin=(0, 0, 0)):
    """Join objs into one object named name with its pivot at origin (rotation/scale baked)."""
    objs = [o for o in objs if o]
    for o in objs:
        apply_rs(o)
    o = join(objs, name) if len(objs) > 1 else objs[0]
    o.name = name
    apply_rs(o)
    while o.data.uv_layers:  # flat vertex-coloured in the game: no UVs needed
        o.data.uv_layers.remove(o.data.uv_layers[0])
    return set_origin(o, origin)


def rbox(size, loc, m, rot):
    """Rotated box around its own centre (forge box() bakes its location, so its rot turns around the world origin)."""
    o = box(size, (0, 0, 0), m, rot=rot)
    o.location = loc
    return o


def rod(p0, p1, r1, r2, m, n=6):
    """Cylinder/cone from point p0 to point p1."""
    dx, dy, dz = p1[0] - p0[0], p1[1] - p0[1], p1[2] - p0[2]
    L = math.sqrt(dx * dx + dy * dy + dz * dz)
    o = cyl(r1, r2, L, ((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2, (p0[2] + p1[2]) / 2), m, n=n)
    # the cone axis is +Z: tilt by the polar angle, then turn by the azimuth
    o.rotation_euler = (0, math.acos(max(-1, min(1, dz / L))), math.atan2(dy, dx))
    return o


def ring(n, r, z, fn, start=0.0):
    """Calls fn(x, y, angle) n times around a circle."""
    return [fn(math.cos(start + i / n * 2 * math.pi) * r, math.sin(start + i / n * 2 * math.pi) * r, start + i / n * 2 * math.pi) for i in range(n)]


def minaret(x, y, z, h, body, cap, band=None, r=0.42, n=10):
    """Ottoman pencil minaret with a balcony (serefe) and a lead cone."""
    out = [cyl(r * 1.25, r * 1.2, 0.5, (x, y, z + 0.25), body, n=n),
           cyl(r, r * 0.92, h, (x, y, z + h / 2), body, n=n),
           cyl(r * 1.05, r * 1.5, 0.22, (x, y, z + h * 0.72), band or body, n=n),
           cyl(r * 1.52, r * 1.52, 0.12, (x, y, z + h * 0.72 + 0.17), band or body, n=n),
           cyl(r * 0.8, r * 0.8, h * 0.18, (x, y, z + h * 0.81), body, n=n),
           cyl(r * 0.84, 0.0, h * 0.3, (x, y, z + h * 0.9 + h * 0.15), cap, n=n),
           cyl(0.03, 0.03, 0.4, (x, y, z + h * 1.2 + 0.2), cap, n=4)]
    if band:
        out.append(cyl(r * 1.01, r * 1.01, 0.18, (x, y, z + h * 0.45), band, n=n))
    return out


def dome(r, loc, m, n=12, h=None, drum=None, drum_m=None):
    """Hemispherical dome (optionally on a short drum), base at loc."""
    x, y, z = loc
    out = []
    if drum:
        out.append(cyl(r * 1.04, r * 1.04, drum, (x, y, z + drum / 2), drum_m or m, n=n))
        z += drum
    d = sphere(r, (x, y, z), m, n=n, rings=max(4, n // 4 * 2), scale=(1, 1, (h or r) / r))
    cut_below(d, z)
    out.append(d)
    out.append(cyl(0.025 * r * 4, 0.0, r * 0.45, (x, y, z + (h or r) + r * 0.2), m, n=4))
    return out


def cut_below(o, z):
    """Removes the vertices of o below world height z (turns a sphere into a dome)."""
    import bmesh
    bm = bmesh.new(); bm.from_mesh(o.data)
    kill = [v for v in bm.verts if o.location.z + v.co.z < z - 1e-4]  # sphere(): scale applied, no rotation
    bmesh.ops.delete(bm, geom=kill, context="VERTS")
    bm.to_mesh(o.data); bm.free()
    return o
