"""
Balloon Ride: the hot air balloon, scripted in Blender (run inside Blender, e.g. through the MCP
execute tool: exec(open(r"F:/balloon-ride/tools/balloon.py").read())). Builds it in its own scene
"BalloonBuild" and exports public/models/balloon.glb (no Draco).

Blender is Z up (glTF export turns it to Y up). Origin = centre of the basket floor. Metres.

Parts (one object + one material each, so the game maps each to its own toon surface):
  envelope  20 gores, inverted-pear profile, scalloped between the load tapes. Face-corner colours:
            vertical stripes per gore, a gold equator band with red trims, red mouth band, cream
            crown, darker load tapes along every seam. The game recolours the variants by palette.
  skirt     the flame-proof scoop under the mouth, taller at the back.
  wires     flying wires from the mouth's load tapes to the burner frame corners.
  frame     the burner frame (square load frame) and the 4 padded uprights to the basket corners.
  burner    twin burner cans with their coils and a gimbal bar.
  basket    the wicker basket: woven checker in vertex colours, floor, inner walls.
  leather   the leather rim round the basket top and the skids under it.
"""
import bpy, bmesh, math, os
from mathutils import Vector

OUT = r"F:/balloon-ride/public/models/balloon.glb"
NG = 20            # gores
TAU = math.tau

sc = bpy.data.scenes.get("BalloonBuild") or bpy.data.scenes.new("BalloonBuild")
bpy.context.window.scene = sc
for o in list(sc.objects):
    bpy.data.objects.remove(o, do_unlink=True)
for m in list(bpy.data.meshes):
    if m.users == 0: bpy.data.meshes.remove(m)


def lin(h, k=1.0):
    h = h.lstrip('#'); c = [int(h[i:i + 2], 16) / 255 * k for i in (0, 2, 4)]
    return tuple(((x / 12.92) if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4) for x in c) + (1.0,)


def material(name, hexcol, rough=0.85, metal=0.0):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    p = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    p.inputs["Base Color"].default_value = lin(hexcol)
    p.inputs["Roughness"].default_value = rough
    p.inputs["Metallic"].default_value = metal
    for n in [n for n in nt.nodes if n.type == "VERTEX_COLOR"]:
        nt.nodes.remove(n)
    vc = nt.nodes.new("ShaderNodeVertexColor")
    vc.layer_name = "Col"
    nt.links.new(vc.outputs["Color"], p.inputs["Base Color"])
    return m


def finish(name, bm, mat, colour_fn, smooth=True):
    lay = bm.loops.layers.float_color.get("Col") or bm.loops.layers.float_color.new("Col")
    for f in bm.faces:
        c = colour_fn(f)
        for l in f.loops:
            l[lay] = c
        f.smooth = smooth
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    sc.collection.objects.link(ob)
    me.materials.append(mat)
    return ob


def catmull(pts, t):
    """Catmull-Rom through pts (list of (z, r)) at parameter t in [0, len-1]."""
    i = min(int(t), len(pts) - 2)
    u = t - i
    p0 = pts[max(i - 1, 0)]; p1 = pts[i]; p2 = pts[i + 1]; p3 = pts[min(i + 2, len(pts) - 1)]
    return tuple(0.5 * ((2 * p1[k]) + (-p0[k] + p2[k]) * u + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * u * u
                        + (-p0[k] + 3 * p1[k] - 3 * p2[k] + p3[k]) * u * u * u) for k in (0, 1))


# ------------------------------------------------------------------ envelope
# Inverted pear ("natural shape"): long straight-ish cone from the mouth, widest ~60 % up, a full
# rounded shoulder and a flattened crown.
PROFILE = [(5.0, 1.45), (5.8, 2.05), (7.0, 3.05), (8.5, 4.3), (10.0, 5.45), (11.5, 6.45), (13.0, 7.15),
           (14.4, 7.5), (15.7, 7.45), (16.9, 7.05), (18.0, 6.25), (19.0, 5.05), (19.8, 3.55), (20.3, 1.9),
           (20.48, 0.0)]
ROWS = 52
prof = [catmull(PROFILE, i / ROWS * (len(PROFILE) - 1)) for i in range(ROWS + 1)]
prof[-1] = (PROFILE[-1][0], 0.0)
Z_MOUTH, Z_CROWN = PROFILE[0][0], PROFILE[-1][0]
COLS = [0.0, 0.035, 0.2, 0.4, 0.6, 0.8, 0.965]   # across one gore: tape | body ... | tape
GPAL = ["#c8322b", "#f3e6c8", "#0f8f8c", "#f3e6c8"]   # red, cream, teal, cream ... per gore
C = {
    "red": "#c8322b", "cream": "#f3e6c8", "teal": "#0f8f8c", "gold": "#e9a92a", "dred": "#8e2420",
}


def env_r(z_r, u):
    """Gore scallop: the cloth bulges between the load tapes (0 at mouth and crown)."""
    z, r = z_r
    k = math.sin(math.pi * min(1.0, max(0.0, (z - Z_MOUTH) / (Z_CROWN - Z_MOUTH)))) ** 0.7
    return r * (1.0 + 0.032 * k * math.sin(math.pi * u))


bm = bmesh.new()
grid = []
for j, zr in enumerate(prof):
    row = []
    for g in range(NG):
        for u in COLS:
            a = (g + u) / NG * TAU
            r = env_r(zr, u) if j < ROWS else 0.0
            row.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r, zr[0])))
    grid.append(row)
W = NG * len(COLS)
for j in range(ROWS):
    for i in range(W):
        a, b = grid[j][i], grid[j][(i + 1) % W]
        c, d = grid[j + 1][(i + 1) % W], grid[j + 1][i]
        f = bm.faces.new((a, b, c)) if j == ROWS - 1 else bm.faces.new((a, b, c, d))
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
bm.normal_update()


def env_colour(f):
    cz = sum((v.co.z for v in f.verts)) / len(f.verts)
    cx = sum((v.co.x for v in f.verts)) / len(f.verts); cy = sum((v.co.y for v in f.verts)) / len(f.verts)
    a = (math.atan2(cy, cx) / TAU) % 1.0
    g = int(a * NG) % NG
    u = a * NG - int(a * NG)
    tape = u < COLS[1] or u > COLS[-1]
    if cz > 19.75:
        col = C["cream"]
    elif 13.25 < cz < 14.65:
        col = C["gold"]
    elif 12.95 < cz <= 13.25 or 14.65 <= cz < 14.95:
        col = C["dred"]
    elif cz < 6.15:
        col = C["dred"]
    else:
        col = GPAL[g % 4]
    return lin(col, 0.8 if tape else 1.0)


env = finish("envelope", bm, material("envelope", "#f3e6c8", 0.7), env_colour)

# ------------------------------------------------------------------ skirt (scoop)
bm = bmesh.new()
SK = 32
rows = []
for j, t in enumerate([0.0, 0.5, 1.0]):
    row = []
    for i in range(SK):
        a = i / SK * TAU
        back = 0.5 - 0.5 * math.cos(a)                # 1 at the back (-x), 0 at the front
        zb = 4.45 - 0.6 * back                          # scoop hangs lower at the back
        z = Z_MOUTH + 0.05 + (zb - Z_MOUTH - 0.05) * t
        r = 1.45 + 0.06 * t + 0.12 * back * t
        row.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r, z)))
    rows.append(row)
for j in range(2):
    for i in range(SK):
        bm.faces.new((rows[j][i], rows[j][(i + 1) % SK], rows[j + 1][(i + 1) % SK], rows[j + 1][i]))
bmesh.ops.solidify(bm, geom=bm.faces[:], thickness=0.02) if hasattr(bmesh.ops, "solidify") else None
bm.normal_update()
def skirt_col(f):
    a = (math.atan2(f.calc_center_median().y, f.calc_center_median().x) / TAU) % 1.0
    u = a * NG - int(a * NG)
    return lin("#9a2c24", 0.75 if (u < 0.06 or u > 0.94) else 1.0)


skirt = finish("skirt", bm, material("skirt", "#9a2c24", 0.9), skirt_col)

# ------------------------------------------------------------------ helpers for tubes


def tube(bm, p0, p1, r, n=6):
    p0, p1 = Vector(p0), Vector(p1)
    d = (p1 - p0).normalized()
    t = d.orthogonal().normalized(); b = d.cross(t)
    r0 = [bm.verts.new(p0 + (t * math.cos(k / n * TAU) + b * math.sin(k / n * TAU)) * r) for k in range(n)]
    r1 = [bm.verts.new(p1 + (t * math.cos(k / n * TAU) + b * math.sin(k / n * TAU)) * r) for k in range(n)]
    for k in range(n):
        bm.faces.new((r0[k], r0[(k + 1) % n], r1[(k + 1) % n], r1[k]))
    bm.faces.new(list(reversed(r0))); bm.faces.new(r1)


def ring_rsq(half, rad, z, seg=10, side_n=1):
    """Rounded-square outline points (half side, corner radius) at height z."""
    pts = []
    for cx, cy, a0 in ((half - rad, half - rad, 0.0), (-(half - rad), half - rad, 0.5 * math.pi),
                       (-(half - rad), -(half - rad), math.pi), (half - rad, -(half - rad), 1.5 * math.pi)):
        for k in range(seg + 1):
            a = a0 + k / seg * 0.5 * math.pi
            pts.append(Vector((cx + math.cos(a) * rad, cy + math.sin(a) * rad, z)))
        # the straight side after this corner, split into weave columns
        a1 = a0 + 0.5 * math.pi
        e0 = Vector((cx + math.cos(a1) * rad, cy + math.sin(a1) * rad, z))
        dirn = Vector((-math.sin(a1), math.cos(a1), 0.0))
        L = 2 * (half - rad)
        for k in range(1, side_n):
            pts.append(e0 + dirn * (L * k / side_n))
    return pts


# ------------------------------------------------------------------ basket
BH = 1.12
FR_Z = 2.55          # burner frame height
FH = 0.5             # frame half side
bm = bmesh.new()
NB = 20              # weave rows
outer = []
inner = []
for j in range(NB + 1):
    t = j / NB
    half = 0.56 + 0.04 * t          # slight taper: wider at the top
    outer.append([bm.verts.new(p) for p in ring_rsq(half, 0.14, t * BH, 5, 17)])
    inner.append([bm.verts.new(p) for p in ring_rsq(half - 0.045, 0.1, max(0.06, t * BH), 5, 17)])
n = len(outer[0])
for j in range(NB):
    for i in range(n):
        bm.faces.new((outer[j][i], outer[j][(i + 1) % n], outer[j + 1][(i + 1) % n], outer[j + 1][i]))
        bm.faces.new((inner[j][(i + 1) % n], inner[j][i], inner[j + 1][i], inner[j + 1][(i + 1) % n]))
for i in range(n):   # top lip and bottom
    bm.faces.new((outer[NB][i], outer[NB][(i + 1) % n], inner[NB][(i + 1) % n], inner[NB][i]))
bm.faces.new(list(reversed(outer[0])))
bm.faces.new(inner[0])
bm.normal_update()
W1, W2 = "#b98c55", "#9c7243"


def weave(f):
    c = f.calc_center_median()
    if abs(c.z) < 0.07 or c.z < 0.065:
        return lin("#7a5630")
    row = int(c.z / BH * NB)
    col = int(math.floor((c.x if abs(c.y) > abs(c.x) else c.y) / 0.064 + 100))
    # Over-under weave: alternate cells, plus a darker band of three rows near the top and base.
    k = 0.86 if row in (1, 2, NB - 3, NB - 2) else 1.0
    inside = f.normal.x * c.x + f.normal.y * c.y < 0
    k *= 0.8 if inside else 1.0
    # The weave itself is drawn by the game's wicker shader (M.wicker); here only the tone bands.
    return lin(W1, k)


basket = finish("basket", bm, material("basket", W1, 0.95), weave, smooth=False)

# ------------------------------------------------------------------ leather rim and skids
bm = bmesh.new()
pts = ring_rsq(0.6, 0.14, BH + 0.01, 8)
m = len(pts)
k = 8
rings = []
for i, p in enumerate(pts):
    q = pts[(i + 1) % m] - pts[i - 1]
    tng = q.normalized(); out = Vector((tng.y, -tng.x, 0.0))
    if out.dot(Vector((p.x, p.y, 0))) < 0: out = -out
    rings.append([bm.verts.new(p + (out * math.cos(a) + Vector((0, 0, 1)) * math.sin(a)) * 0.055 - out * 0.02)
                  for a in (s / k * TAU for s in range(k))])
for i in range(m):
    for s in range(k):
        bm.faces.new((rings[i][s], rings[i][(s + 1) % k], rings[(i + 1) % m][(s + 1) % k], rings[(i + 1) % m][s]))
for y in (-0.35, 0.35):          # two skids under the floor
    tube(bm, (-0.55, y, 0.03), (0.55, y, 0.03), 0.035, 6)
bm.normal_update()
leather = finish("leather", bm, material("leather", "#5a3520", 0.6), lambda f: lin("#5b3420"))

# ------------------------------------------------------------------ frame and uprights
bm = bmesh.new()
cor = [(FH, FH), (-FH, FH), (-FH, -FH), (FH, -FH)]
for i in range(4):
    a, b = cor[i], cor[(i + 1) % 4]
    tube(bm, (a[0], a[1], FR_Z), (b[0], b[1], FR_Z), 0.03, 6)
for (x, y) in cor:   # padded uprights from the basket corners (sleeved in suede)
    tube(bm, (x * 1.06, y * 1.06, BH - 0.05), (x, y, FR_Z), 0.045, 8)
tube(bm, (0, -FH, FR_Z), (0, FH, FR_Z), 0.025, 6)   # gimbal bar
bm.normal_update()


def frame_col(f):
    c = f.calc_center_median()
    return lin("#7a5a3e") if c.z < FR_Z - 0.08 else lin("#9a9a96")


frame = finish("frame", bm, material("frame", "#9a9a96", 0.4, 0.8), frame_col)

# ------------------------------------------------------------------ twin burners
bm = bmesh.new()
for x in (-0.19, 0.19):
    r1 = bmesh.ops.create_cone(bm, cap_ends=True, segments=14, radius1=0.15, radius2=0.17, depth=0.42)
    bmesh.ops.translate(bm, verts=r1["verts"], vec=(x, 0, FR_Z + 0.12))
    for zc in (FR_Z - 0.02, FR_Z + 0.08, FR_Z + 0.18, FR_Z + 0.28):     # the coil wound round each can
        tr = bmesh.ops.create_circle(bm, cap_ends=False, segments=14, radius=0.19)
        vs = tr["verts"]
        bmesh.ops.translate(bm, verts=vs, vec=(x, 0, zc))
        ext = bmesh.ops.extrude_edge_only(bm, edges=list({e for v in vs for e in v.link_edges}))
        nv = [e for e in ext["geom"] if isinstance(e, bmesh.types.BMVert)]
        bmesh.ops.translate(bm, verts=nv, vec=(0, 0, 0.045))
    # nozzle ring on top
    r2 = bmesh.ops.create_cone(bm, cap_ends=True, segments=14, radius1=0.12, radius2=0.09, depth=0.06)
    bmesh.ops.translate(bm, verts=r2["verts"], vec=(x, 0, FR_Z + 0.36))
# valve block between them
bv = bmesh.ops.create_cube(bm, size=0.12)
bmesh.ops.translate(bm, verts=bv["verts"], vec=(0, 0, FR_Z - 0.08))
bm.normal_update()


def burner_col(f):
    c = f.calc_center_median()
    if c.z > FR_Z + 0.33: return lin("#3a3633")
    return lin("#c9c3b6") if abs(c.y) > 0.16 or abs(abs(c.x) - 0.19) > 0.165 else lin("#b4ab9a")


burner = finish("burner", bm, material("burner", "#c9c3b6", 0.3, 1.0), burner_col)

# ------------------------------------------------------------------ flying wires
bm = bmesh.new()
NW = 16
for w in range(NW):
    a = (w + 0.5) / NW * TAU   # on load tapes: every gore seam ~ 20 gores, 16 wires close enough
    a = round(a / (TAU / NG)) * (TAU / NG)
    top = (math.cos(a) * 1.47, math.sin(a) * 1.47, Z_MOUTH)
    cx = FH if math.cos(a) >= 0 else -FH
    cy = FH if math.sin(a) >= 0 else -FH
    tube(bm, top, (cx, cy, FR_Z + 0.03), 0.018, 4)
bm.normal_update()
wires = finish("wires", bm, material("wires", "#3b3430", 0.8), lambda f: lin("#3b3430"))

for ob in bpy.data.objects:
    try: ob.select_set(ob.name in sc.objects)
    except RuntimeError: pass
bpy.context.view_layer.objects.active = env

# ------------------------------------------------------------------ export
os.makedirs(os.path.dirname(OUT), exist_ok=True)
kw = dict(filepath=OUT, export_format="GLB", use_selection=True, export_apply=True, export_yup=True,
          export_draco_mesh_compression_enable=False, export_materials="EXPORT", export_normals=True,
          export_texcoords=False, export_animations=False,
          use_active_scene=True)
props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
if "export_vertex_color" in props:
    kw["export_vertex_color"] = "ACTIVE"
elif "export_colors" in props:
    kw["export_colors"] = True
if "export_all_vertex_colors" in props:
    kw["export_all_vertex_colors"] = False
kw = {k: v for k, v in kw.items() if k in props}
bpy.ops.export_scene.gltf(**kw)
print("exported", OUT, os.path.getsize(OUT), "bytes;", {o.name: len(o.data.polygons) for o in sc.objects})
