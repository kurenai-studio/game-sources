"""
Balloon Ride: the pilot, scripted in Blender (run inside Blender, e.g. through the MCP execute
tool: exec(open(r"F:/balloon-ride/tools/pilot.py").read())). Builds her in her own scene
"PilotBuild", rigs and animates her, and exports public/models/pilot.glb (skinned, three clips).

An original character: a young balloon pilot with a ginger bob, a brown leather flying jacket with
a cream fleece collar, a long red scarf with cream stripes, brass goggles pushed up on her hair,
navy-olive trousers and boots (hidden by the basket). Ghibli proportions: a slightly large round
head, soft rounded forms, mitten hands with a separate thumb, a simple painted face (tall dark
eyes with a catch light, soft brows, blush and a few freckles, a small smile).

Blender is Z up, she faces -Y (glTF +Z after the Y-up export). The armature sits at PILOT in the
balloon's model space (origin = centre of the basket floor), so the GLB drops straight into the
balloon model. About 1.65 m tall: the basket rim (1.12 m) meets her waist.

Parts (one object + one material each; the game maps each material name to its toon surface):
  head      head + neck, the painted face (texture "pilot_face", features in face-plane coords)
  skin      both hands (mittens with a thumb)
  hair      the bob (double-sided shell, scalloped fringe and hem)
  jacket    torso (waist, flared hem), left sleeve, right upper sleeve
  collar    the fleece collar: a flat band round the back of the neck turning down into two lapels
  forearm_R the right sleeve from just past the elbow (split from one tube, shared normals: no seam)
  hand_R    the right hand (ditto)
  trousers  pelvis, legs, boots
  scarf     neck wrap, knot, short front end, long back tail on a 5-bone chain
  goggles   strap, brass rims, lenses
  lever     the burner's blast-valve lever (a T handle hanging from the valve block), on its own bone;
            it slides 10 cm down through a fixed bushing (weighted to root) when she pulls

Rig: root, hips, spine, chest, neck, head, shoulder/upperarm/forearm/hand L+R, elbow L+R (helpers
turning half as far as the forearm, carrying a wide band of sleeve round the joint), thigh/shin L+R,
scarf_0..4, lever (deform). ik_R (child of lever), ik_L, pole_R, pole_L (not exported): the arms
are solved by IK and the hands copy the targets' rotation; the exporter samples the result.

Clips (30 fps, NLA tracks): idle (4 s loop, both hands resting on the front rim), lookOver (6 s),
burner (reach up 0-0.45 s and pull the lever down to 0.7 s, 0.7-2.7 s hold loop, chin up to the
flame and the left hand bearing on the rim; release to 3.3 s, the hand back on the rim). The scarf waves in every clip on a 2 s period (seamless loops).
"""
import bpy, bmesh, math, os
import numpy as np
from mathutils import Vector, Matrix, Quaternion

OUT = r"F:/balloon-ride/public/models/pilot.glb"
FPS = 30
PILOT = Vector((0.14, -0.08, 0.05))      # armature origin (her feet) in balloon model space
TAU = math.tau
D = math.radians

sc = bpy.data.scenes.get("PilotBuild") or bpy.data.scenes.new("PilotBuild")
bpy.context.window.scene = sc
sc.render.fps = FPS
for o in list(sc.objects):
    if not o.name.startswith("REF_"):       # REF_*: an imported basket to check her against (never exported)
        bpy.data.objects.remove(o, do_unlink=True)
for coll in (bpy.data.meshes, bpy.data.armatures):
    for m in list(coll):
        if m.users == 0: coll.remove(m)
for a in list(bpy.data.actions):
    if a.name.startswith("pilot_"): bpy.data.actions.remove(a)


def lin(h, k=1.0):
    h = h.lstrip('#'); c = [int(h[i:i + 2], 16) / 255 * k for i in (0, 2, 4)]
    return tuple(((x / 12.92) if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4) for x in c) + (1.0,)


C = dict(
    skin=lin("#f7d4bb"), hair=lin("#d36c38"), jacket=lin("#8a5532"), band=lin("#5e3822"),
    fleece=lin("#d4b588"), trousers=lin("#3a4656"), boot=lin("#3b2619"), scarf=lin("#cc3b2d"),
    stripe=lin("#e9c79b"), strap=lin("#4f3222"), brass=lin("#c39540"), lens=lin("#5fa9b5"),
    rod=lin("#8e8a83"), grip=lin("#4a2b1b"),
)


def smooth(a, b, x):
    t = min(1.0, max(0.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


# ------------------------------------------------------------------ mesh building

class Part:
    def __init__(self):
        self.v, self.f, self.c = [], [], []

    def vert(self, p, col):
        self.v.append(Vector(p)); self.c.append(col)
        return len(self.v) - 1

    def ring(self, pts, col):
        return [self.vert(p, col if not callable(col) else col(p)) for p in pts]

    def bridge(self, r0, r1):
        n = len(r0)
        for i in range(n):
            self.f.append((r0[i], r0[(i + 1) % n], r1[(i + 1) % n], r1[i]))

    def cap(self, r, centre, col, flip=False):
        c = self.vert(centre, col)
        n = len(r)
        for i in range(n):
            a, b = r[i], r[(i + 1) % n]
            self.f.append((c, b, a) if not flip else (c, a, b))

    def loft(self, rings, cols, cap0=None, cap1=None):
        """rings: list of point lists; cap0 / cap1: centre points (bulged) or None (open)."""
        ids = [self.ring(r, cols[i] if isinstance(cols, list) else cols) for i, r in enumerate(rings)]
        for i in range(len(ids) - 1):
            self.bridge(ids[i], ids[i + 1])
        c0 = cols[0] if isinstance(cols, list) else cols
        c1 = cols[-1] if isinstance(cols, list) else cols
        if cap0 is not None: self.cap(ids[0], cap0, c0, flip=False)
        if cap1 is not None: self.cap(ids[-1], cap1, c1, flip=True)
        return ids


def basis(d, hint=Vector((0, -1, 0))):
    d = d.normalized()
    if abs(d.dot(hint)) > 0.95: hint = Vector((1, 0, 0))
    u = (hint - d * hint.dot(d)).normalized()
    v = d.cross(u).normalized()
    return u, v


def ellipse(c, u, v, ru, rv, n, e=2.0, phase=0.0):
    pts = []
    for i in range(n):
        a = i / n * TAU + phase
        ca, sa = math.cos(a), math.sin(a)
        x = math.copysign(abs(ca) ** (2 / e), ca); y = math.copysign(abs(sa) ** (2 / e), sa)
        pts.append(c + u * (ru * x) + v * (rv * y))
    return pts


def tube(part, path, radii, cols, n=12, cap0=True, cap1=True, hint=Vector((0, -1, 0)), squash=1.0):
    rings = []
    for i, p in enumerate(path):
        d = (path[min(i + 1, len(path) - 1)] - path[max(i - 1, 0)])
        u, v = basis(d, hint)
        r = radii[i]
        rings.append(ellipse(p, u, v, r * squash, r, n))
    d0 = (path[1] - path[0]).normalized(); d1 = (path[-1] - path[-2]).normalized()
    return part.loft(rings, cols, path[0] - d0 * radii[0] * 0.6 if cap0 else None,
                     path[-1] + d1 * radii[-1] * 0.6 if cap1 else None)


def finish(name, part, mat, subdiv=1, smooth_all=True, sharp=None):
    me = bpy.data.meshes.new(name)
    me.from_pydata([tuple(p) for p in part.v], [], part.f)
    me.validate()
    ca = me.color_attributes.new("Col", 'FLOAT_COLOR', 'POINT')
    for i, c in enumerate(part.c):
        ca.data[i].color = c
    me.color_attributes.active_color = ca
    ob = bpy.data.objects.new(name, me)
    sc.collection.objects.link(ob)
    if subdiv:
        md = ob.modifiers.new("sub", 'SUBSURF')
        md.levels = subdiv
        md.render_levels = subdiv
        dg = bpy.context.evaluated_depsgraph_get()
        me2 = bpy.data.meshes.new_from_object(ob.evaluated_get(dg))
        ob.modifiers.remove(md)
        old = ob.data
        ob.data = me2
        bpy.data.meshes.remove(old)
        me2.name = name
        me = me2
    if smooth_all:
        me.shade_smooth()
    if sharp is not None:
        me.set_sharp_from_angle(angle=sharp)
    me.materials.append(mat)
    return ob


def material(name, hexcol, image=None):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    nt = m.node_tree
    p = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    p.inputs["Base Color"].default_value = lin(hexcol)
    p.inputs["Roughness"].default_value = 0.8
    for n in [n for n in nt.nodes if n.type in ("VERTEX_COLOR", "TEX_IMAGE")]:
        nt.nodes.remove(n)
    if image is not None:
        tx = nt.nodes.new("ShaderNodeTexImage")
        tx.image = image
        tx.interpolation = 'Linear'
        nt.links.new(tx.outputs["Color"], p.inputs["Base Color"])
        # No alpha link: the texture's clear pixels carry the skin colour (the game masks by alpha).
    else:
        vc = nt.nodes.new("ShaderNodeVertexColor")
        vc.layer_name = "Col"
        nt.links.new(vc.outputs["Color"], p.inputs["Base Color"])
    return m


# ------------------------------------------------------------------ proportions (her local space)

HZ = 0.015                               # head lift over the first layout (a longer neck)
HEAD_C = Vector((0.0, -0.004, 1.53 + HZ))
HEAD_R = Vector((0.127, 0.133, 0.145))
S = {+1: Vector((0.158, 0.0, 1.315)), -1: Vector((-0.158, 0.0, 1.315))}
ARM_D = {sd: Vector((sd * 0.574, 0.0, -0.819)) for sd in (1, -1)}
E = {sd: S[sd] + ARM_D[sd] * 0.27 + Vector((0.0, 0.03, 0.0)) for sd in (1, -1)}   # a slight bend (IK needs one)
W = {sd: E[sd] + ARM_D[sd] * 0.24 for sd in (1, -1)}
T = {sd: W[sd] + ARM_D[sd] * 0.1 for sd in (1, -1)}
PALM_N = {sd: Vector((-sd * 0.819, 0.0, -0.574)) for sd in (1, -1)}
# The burner lever (balloon space: valve block bottom at (0, 0, 2.41)), in her space.
LEV_PIVOT = Vector((0.0, 0.0, 2.41)) - PILOT
LEV_BAR = Vector((-0.13, -0.10, 1.86))
GRIP_R = LEV_BAR + Vector((0.0, 0.03, -0.058))        # her right wrist on the T handle
RIM_L = Vector((0.23, -0.42, 1.19))                    # her left wrist on the front rim (roll top: y -0.50, z 1.135)
RIM_R = Vector((-0.10, -0.42, 1.19))
# Her right elbow's pole: out and back while the hand rests on the rim, out to her side and up
# while she reaches for the lever.
POLE_R_REST = Vector((-0.62, 0.26, 1.02))
POLE_R_UP = Vector((-0.72, 0.04, 1.42))
LEV_TRAVEL = 0.10                                      # the pull: the lever slides 10 cm down
# The long scarf tail hanging down her back (rest), in her space.
TAIL = [Vector(p) for p in ((0.03, 0.06, 1.37), (0.05, 0.13, 1.31), (0.07, 0.16, 1.20), (0.085, 0.165, 1.07),
                            (0.095, 0.165, 0.94), (0.10, 0.165, 0.80))]


def polyline(pts, s):
    """Point at arc length fraction s along pts, and the tangent."""
    L = [0.0]
    for i in range(len(pts) - 1): L.append(L[-1] + (pts[i + 1] - pts[i]).length)
    x = s * L[-1]
    for i in range(len(pts) - 1):
        if x <= L[i + 1] or i == len(pts) - 2:
            t = (x - L[i]) / max(L[i + 1] - L[i], 1e-9)
            return pts[i].lerp(pts[i + 1], min(max(t, 0), 1)), (pts[i + 1] - pts[i]).normalized()


# ------------------------------------------------------------------ the face texture

FACE_PX = 512
FACE_W = 0.26          # metres across the texture; u = 0.5 + x / FACE_W, v = 0.5 + (z - FACE_Z) / FACE_W
FACE_Z = 1.50 + HZ


def paint_face():
    n = FACE_PX
    ii = (np.arange(n) + 0.5) / n
    x = (ii[None, :] - 0.5) * FACE_W
    z = 1.50 + (ii[:, None] - 0.5) * FACE_W      # features below are laid out for HZ = 0
    x = np.broadcast_to(x, (n, n)); z = np.broadcast_to(z, (n, n))
    pw = FACE_W / n * 1.2
    rgb = np.zeros((n, n, 3)) + np.array([0xf7, 0xd4, 0xbb]) / 255; a = np.zeros((n, n))

    def over(col, cov):
        nonlocal rgb, a
        c = np.array([int(col[i:i + 2], 16) / 255 for i in (1, 3, 5)])
        cov = np.clip(cov, 0, 1)
        na = cov + a * (1 - cov)
        rgb = np.where(na[..., None] > 1e-6, (c * cov[..., None] + rgb * (a * (1 - cov))[..., None]) / np.maximum(na, 1e-6)[..., None], rgb)
        a = na

    def cov(sd):  # signed distance (m) -> coverage
        return np.clip(0.5 - sd / pw, 0, 1)

    def seg(px, pz, ax, az, bx, bz, ra, rb):
        dx, dz = bx - ax, bz - az
        h = np.clip(((px - ax) * dx + (pz - az) * dz) / (dx * dx + dz * dz), 0, 1)
        return np.hypot(px - ax - dx * h, pz - az - dz * h) - (ra + (rb - ra) * h)

    for sd in (1, -1):
        X = x * sd   # mirrored: X > 0 toward her outer side of this eye
        # Blush: soft rosy ovals under the eyes.
        d = ((X - 0.072) / 0.02) ** 2 + ((z - 1.466) / 0.011) ** 2
        over("#f2857c", 0.42 * (1 - np.clip((d - 0.35) / 0.65, 0, 1)) ** 1.5)
        # Freckles.
        for fx, fz in ((0.06, 1.477), (0.068, 1.482), (0.076, 1.475), (0.083, 1.481)):
            over("#c46f4a", 0.75 * cov(np.hypot(X - fx, z - fz) - 0.0013))
        # Brows: short soft arcs, thicker at the inner end.
        bd = np.full((n, n), 1.0)
        for k in range(6):
            t0, t1 = k / 6, (k + 1) / 6
            px0, px1 = 0.029 + 0.037 * t0, 0.029 + 0.037 * t1
            pz0 = 1.554 + 0.006 * math.sin(math.pi * t0) - 0.002 * t0
            pz1 = 1.554 + 0.006 * math.sin(math.pi * t1) - 0.002 * t1
            bd = np.minimum(bd, seg(X, z, px0, pz0, px1, pz1, 0.0028 - 0.0016 * t0, 0.0028 - 0.0016 * t1))
        over("#8c3a1d", cov(bd))
        # Eyes: tall dark ovals, a warmer brown low in the eye, catch lights.
        ex, ez, rx, rz = 0.047, 1.503, 0.0145, 0.022
        e = np.sqrt(((X - ex) / rx) ** 2 + ((z - ez) / rz) ** 2)
        over("#2b1912", cov((e - 1) * rx))
        glow = np.clip(1 - np.hypot((X - ex) / (rx * 0.8), (z - ez + 0.011) / (rz * 0.45)), 0, 1)
        over("#7a4126", glow * cov((e - 1) * rx) * 0.8)
        # Upper lash line: a fine arc over the top of the eye with a small outer flick.
        el = np.sqrt(((X - ex) / (rx * 1.22)) ** 2 + ((z - ez - 0.001) / (rz * 1.06)) ** 2)
        lash = np.abs(el - 1) * rz - 0.0011
        lash = np.where((z > ez + 0.006) & (X > ex - rx * 1.15), lash, 1.0)
        over("#24140e", cov(lash))
        over("#24140e", cov(seg(X, z, ex + rx * 1.0, ez + 0.010, ex + rx * 1.45, ez + 0.0145, 0.0011, 0.0004)))
        # Catch lights (the same side on both eyes: the key light is one sun).
        hx = (0.0045 if sd > 0 else -0.0045)
        over("#ffffff", cov(np.hypot(x - sd * ex - hx, z - ez - 0.0075) - 0.0042))
        over("#ffffff", cov(np.hypot(x - sd * ex + hx * 0.6, z - ez + 0.0085) - 0.0017) * 0.9)
    # Nose: a small warm stroke.
    over("#d88f79", 0.8 * cov(seg(x, z, 0.0035, 1.479, 0.0055, 1.471, 0.0011, 0.0013)))
    # Mouth: a small smile.
    md = np.abs(z - (1.432 + 55 * x ** 2)) - 0.0016
    md = np.where(np.abs(x) < 0.013, md, np.hypot(np.abs(x) - 0.013, z - (1.432 + 55 * 0.013 ** 2)) - 0.0012)
    over("#8f3b2c", cov(md))
    # Byte image pixels are display (sRGB) values.
    px = np.concatenate([rgb, a[..., None]], axis=2).astype(np.float32)
    img = bpy.data.images.get("pilot_face")
    if img: bpy.data.images.remove(img)
    img = bpy.data.images.new("pilot_face", n, n, alpha=True)
    img.pixels.foreach_set(px.ravel())
    img.file_format = 'PNG'
    img.alpha_mode = 'CHANNEL_PACKED'
    img.pack()
    return img


face_img = paint_face()
MAT = dict(
    head=material("face", "#f7d4bb", face_img), skin=material("skin", "#f7d4bb"), hair=material("hair", "#b65b30"),
    jacket=material("jacket", "#6e4329"), trousers=material("trousers", "#3a4656"), scarf=material("scarf", "#cc3b2d"),
    goggles=material("goggles", "#c39540"), lever=material("lever", "#8e8a83"), collar=material("collar", "#d4b588"),
)

objs = {}
SUBS = []          # (final object, weight key, object): parts are weighted alone, then joined


def add(final, key, ob):
    SUBS.append((final, key, ob))
    return ob


# ------------------------------------------------------------------ head + neck

bm = bmesh.new()
bmesh.ops.create_uvsphere(bm, u_segments=48, v_segments=28, radius=1.0)   # dense: no faceted toon seam on the face
pt = Part()
vmap = {}
for v in bm.verts:
    p = v.co
    x, y, z = p.x * HEAD_R.x, p.y * HEAD_R.y, p.z * HEAD_R.z
    t = max(0.0, -p.z)                      # 0 at the middle .. 1 at the chin
    k = t * t
    x *= 1 - 0.30 * k
    y *= (1 - 0.12 * k) if y < 0 else (1 - 0.38 * k)
    if y < 0 and p.z < 0: y -= 0.006 * math.sin(math.pi * t) * (1 - abs(p.x))   # soft cheeks
    vmap[v.index] = pt.vert(HEAD_C + Vector((x, y, z)), C["skin"])
for f in bm.faces:
    pt.f.append(tuple(vmap[v.index] for v in f.verts))
bm.free()
N_SPHERE = len(pt.v)
neck = [Vector((0, 0.008, z)) for z in (1.29, 1.37, 1.47)]
tube(pt, neck, [0.041, 0.040, 0.040], C["skin"], n=12, cap0=False, cap1=False, hint=Vector((0, -1, 0)))
objs["head"] = add("head", "head", finish("head", pt, MAT["head"], subdiv=0))
# Face-plane UVs (orthographic, front): the game masks the paint to front-facing normals.
me = objs["head"].data
uv = me.uv_layers.new(name="UVMap")
for loop in me.loops:
    p = me.vertices[loop.vertex_index].co
    uv.data[loop.index].uv = (0.5 + p.x / FACE_W, 0.5 + (p.z - FACE_Z) / FACE_W)

# ------------------------------------------------------------------ hair (bob)

pt = Part()
NC, NR = 30, 13


def hair_hem(phi):
    a = abs(phi)
    fringe = 1.572 + HZ + 0.0055 * math.cos(phi * 15.0) - 0.004 * (a / 0.75) ** 2
    bob = 1.42 + HZ - 0.011 * math.sin(phi * 13.0) - 0.004 * math.sin(phi * 7.0 + 1.1) + 0.008 * smooth(2.3, 3.0, a)
    return fringe + (bob - fringe) * smooth(0.72, 1.18, a)


def hair_off(phi, s_up):
    a = abs(phi)
    return 0.007 + 0.011 * smooth(0.5, 1.4, a) + 0.007 * s_up


def hair_point(phi, z):
    """Point on her hair at azimuth phi (0 = front) and height z."""
    sx, sy = math.sin(phi), -math.cos(phi)
    rh = 1 / math.sqrt((sx / HEAD_R.x) ** 2 + (sy / HEAD_R.y) ** 2)
    if z >= HEAD_C.z:
        s = min(1.0, (z - HEAD_C.z) / (HEAD_R.z + 0.02))
        th = math.asin(min(1.0, s))
        off = hair_off(phi, s)
        rho = rh * math.cos(th) + off * math.cos(th)
    else:
        off = hair_off(phi, 0)
        rho = (rh + off) * (1 + 0.5 * (HEAD_C.z - z))
    # Locks: soft vertical ridges over the lower hair, so the bob reads as hair, not a helmet.
    lk = smooth(HEAD_C.z + 0.07, HEAD_C.z - 0.03, z) * smooth(0.6, 1.0, abs(phi))
    rho += 0.0055 * lk * (math.sin(phi * 13.0) * 0.7 + math.sin(phi * 7.0 + 1.1) * 0.3)
    return Vector((HEAD_C.x + sx * rho, HEAD_C.y + sy * rho, z))


crown = HEAD_C + Vector((0, 0.006, HEAD_R.z + 0.02))
cols_ids = []
for c in range(NC):
    phi = -math.pi + (c + 0.5) / NC * TAU
    zh = hair_hem(phi)
    col = []
    for r in range(1, NR + 1):
        s = r / NR
        # Rows spread by angle over the cap, then evenly down to the hem.
        ztop = crown.z
        if zh >= HEAD_C.z:
            th = math.pi / 2 * (1 - s) + math.asin(min(1, (zh - HEAD_C.z) / (HEAD_R.z + 0.02))) * s
            z = HEAD_C.z + (HEAD_R.z + 0.02) * math.sin(th)
        else:
            sc_ = s / 0.62
            if sc_ <= 1:
                th = math.pi / 2 * (1 - sc_)
                z = HEAD_C.z + (HEAD_R.z + 0.02) * math.sin(th)
            else:
                z = HEAD_C.z + (zh - HEAD_C.z) * (sc_ - 1) / (1 / 0.62 - 1)
        p = hair_point(phi, z)
        if r == NR:   # the hem tucks in: fringe onto the forehead, the bob's ends curl under
            p = HEAD_C.lerp(p, 0.95) if abs(phi) < 0.75 else HEAD_C + (p - HEAD_C) * Vector((0.96, 0.96, 1.0))
            p.z = z
        tone = C["hair"] if r < NR - 1 else tuple(k * 0.9 for k in C["hair"][:3]) + (1.0,)
        col.append(pt.vert(p, tone))
    cols_ids.append(col)
ci = pt.vert(crown, C["hair"])
for c in range(NC):
    a, b = cols_ids[c], cols_ids[(c + 1) % NC]
    pt.f.append((ci, a[0], b[0]))
    for r in range(NR - 1):
        pt.f.append((a[r], a[r + 1], b[r + 1], b[r]))
objs["hair"] = add("hair", "hair", finish("hair", pt, MAT["hair"], subdiv=1))

# ------------------------------------------------------------------ goggles (pushed up on her hair)

pt = Part()
band = []
NBd = 32
for i in range(NBd):
    phi = -math.pi + i / NBd * TAU
    zc = 1.652 + HZ - 0.036 * (1 - math.cos(phi)) / 2
    p = hair_point(phi, zc)
    o = (p - Vector((HEAD_C.x, HEAD_C.y, zc - 0.05))).normalized()
    band.append((p + o * 0.003, o))
rings = []
for p, o in band:
    up = Vector((0, 0, 1)); up = (up - o * up.dot(o)).normalized()
    rings.append([p + up * 0.011, p + up * 0.011 + o * 0.006, p - up * 0.011 + o * 0.006, p - up * 0.011])
ids = [pt.ring(r, C["strap"]) for r in rings]
for i in range(NBd):
    a, b = ids[i], ids[(i + 1) % NBd]
    for j in range(4):
        pt.f.append((a[j], a[(j + 1) % 4], b[(j + 1) % 4], b[j]))
for sd in (1, -1):
    phi = sd * 0.42
    zc = 1.652 + HZ - 0.036 * (1 - math.cos(phi)) / 2 + 0.004
    p = hair_point(phi, zc)
    nrm = Vector(((p.x - HEAD_C.x) / HEAD_R.x ** 2, (p.y - HEAD_C.y) / HEAD_R.y ** 2, (p.z - HEAD_C.z) / HEAD_R.z ** 2)).normalized()
    nrm = (nrm + Vector((0, 0, 0.25))).normalized()
    u, v = basis(nrm, Vector((0, 0, 1)))
    prof = [(0.0, 0.029, "brass"), (0.018, 0.030, "brass"), (0.024, 0.031, "brass"), (0.027, 0.025, "brass"), (0.022, 0.0245, "lens")]
    rr = [ellipse(p + nrm * h, u, v, r, r, 18) for h, r, _ in prof]
    pt.loft(rr, [C[k] for _, _, k in prof], cap0=p - nrm * 0.002, cap1=p + nrm * 0.022)
objs["goggles"] = add("goggles", "goggles", finish("goggles", pt, MAT["goggles"], subdiv=0, sharp=D(35)))

# ------------------------------------------------------------------ jacket (torso, collar, sleeves)

pt = Part()
# A jacket, not a tube: the hem flares over the hips, a waist, a fuller chest, square shoulders.
TORSO = [(0.79, 0.172, 0.126, 0.0, "band"), (0.83, 0.168, 0.123, 0.0, "band"), (0.85, 0.163, 0.119, 0.0, "jacket"),
         (0.93, 0.148, 0.108, 0.0, "jacket"), (1.02, 0.134, 0.098, 0.0, "jacket"), (1.11, 0.144, 0.108, -0.003, "jacket"),
         (1.19, 0.157, 0.116, -0.006, "jacket"), (1.255, 0.170, 0.109, -0.004, "jacket"), (1.295, 0.150, 0.096, 0.0, "jacket"),
         (1.325, 0.105, 0.082, 0.0, "jacket"), (1.345, 0.064, 0.058, 0.0, "jacket")]
rings = [ellipse(Vector((0, yo, z)), Vector((1, 0, 0)), Vector((0, -1, 0)), rx, ry, 14, e=2.4) for z, rx, ry, yo, _ in TORSO]
pt.loft(rings, [C[k] for *_, k in TORSO])
add("jacket", "torso", finish("jacket", pt, MAT["jacket"], subdiv=1))
# Fleece collar (its own material: a warm cream with its own toon band and ink edge): a flat band
# lying on the shoulders round the back of the neck, open at the front, where it turns down into
# two lapels over her chest.
pt = Part()
NCo = 22
A0 = 0.42
cr = []
for i in range(NCo):
    a = A0 + (TAU - 2 * A0) * i / (NCo - 1)            # 0 = her front
    fr = smooth(1.35, A0, min(a, TAU - a))             # 1 at the lapel ends
    c = Vector((math.sin(a) * (0.112 + 0.006 * fr), -math.cos(a) * (0.094 + 0.034 * fr) - 0.004, 1.334 + 0.004 * math.cos(a) - 0.08 * fr * fr))
    o = Vector((math.sin(a), -math.cos(a), 0.0))
    up = Vector((0, 0, 1))
    # the band's cross-section: wide and flat, lying down the slope of the shoulder (more upright on the lapels)
    tilt = -0.55 + 1.75 * fr
    w_ = (o * math.cos(tilt) + up * math.sin(tilt)).normalized()
    nrm = (up * math.cos(tilt) - o * math.sin(tilt)).normalized()
    hw = 0.034 - 0.006 * fr
    cr.append([c + w_ * (hw * math.cos(b)) + nrm * (0.011 * math.sin(b)) for b in (j / 8 * TAU for j in range(8))])
ids = [pt.ring(r, C["fleece"]) for r in cr]
for i in range(NCo - 1):
    a, b = ids[i], ids[i + 1]
    for j in range(8):
        pt.f.append((a[j], b[j], b[(j + 1) % 8], a[(j + 1) % 8]))
pt.cap(ids[0], sum((pt.v[k] for k in ids[0]), Vector()) / 8, C["fleece"], flip=True)
pt.cap(ids[-1], sum((pt.v[k] for k in ids[-1]), Vector()) / 8, C["fleece"])
add("collar", "collar", finish("collar", pt, MAT["collar"], subdiv=1))


def sleeve_path(sd):
    """Path and radii along her arm (A pose), densely sampled (rings every ~2 cm, so the elbow bends
    round instead of folding), tapering from a soft shoulder to a narrow wrist with a knit cuff."""
    st = Vector((sd * 0.10, 0.0, 1.295))
    d = ARM_D[sd]
    keys = [(0.0, st, 0.046), (0.12, S[sd], 0.058), (0.3, S[sd] + d * 0.12, 0.051), (0.5, E[sd], 0.045),
            (0.7, E[sd] + d * 0.12, 0.040), (0.86, W[sd] - d * 0.028, 0.036), (0.895, W[sd] - d * 0.016, 0.043),
            (0.93, W[sd], 0.044), (1.0, W[sd] + d * 0.006, 0.038)]
    out = []
    for (ta, pa, ra), (tb, pb, rb) in zip(keys, keys[1:]):
        k_n = max(1, int(round((pb - pa).length / 0.02)))
        for k in range(k_n):
            f = k / k_n
            out.append((pa.lerp(pb, f), ra + (rb - ra) * smooth(0, 1, f), ta + (tb - ta) * f))
    out.append((keys[-1][1], keys[-1][2], 1.0))
    return out


def sleeve(part, sd):
    pth = sleeve_path(sd)
    cols = [C["band"] if t >= 0.875 else C["jacket"] for _, _, t in pth]
    return tube(part, [p for p, _, _ in pth], [r for _, r, _ in pth], cols, n=12, cap0=True, cap1=True)


def split_off(ob, name, keep_far, sd, cut=0.07):
    """Split a finished (subdivided) sleeve at `cut` metres past the elbow into two objects that share
    the cut ring exactly and keep the whole sleeve's normals (no shading seam where they meet)."""
    me = ob.data
    nrm = {tuple(round(c, 6) for c in v.co): v.normal.copy() for v in me.vertices}
    far = ob.copy(); far.data = me.copy(); far.name = name; far.data.name = name
    sc.collection.objects.link(far)
    for o, keep in ((ob, False), (far, True)):
        bm_ = bmesh.new(); bm_.from_mesh(o.data)
        kill = [f for f in bm_.faces if (((f.calc_center_median() - E[sd]).dot(ARM_D[sd]) > cut) != keep)]
        bmesh.ops.delete(bm_, geom=kill, context='FACES')
        bmesh.ops.delete(bm_, geom=[v for v in bm_.verts if not v.link_faces], context='VERTS')
        bm_.to_mesh(o.data); bm_.free()
        o.data.normals_split_custom_set_from_vertices([nrm.get(tuple(round(c, 6) for c in v.co), v.normal) for v in o.data.vertices])
    return far


pt = Part()
sleeve(pt, 1)
add("jacket", "sleeve_L", finish("sleeve_L", pt, MAT["jacket"], subdiv=1))
pt = Part()
sleeve(pt, -1)
upper_R = finish("sleeve_R", pt, MAT["jacket"], subdiv=1)
add("jacket", "sleeve_R", upper_R)
add("forearm_R", "sleeve_R", split_off(upper_R, "forearm_R", True, -1))

# ------------------------------------------------------------------ hands (mittens with a thumb)


def hand(part, sd):
    a = ARM_D[sd]; nrm = PALM_N[sd]
    side = a.cross(nrm)
    if side.y > 0: side = -side          # thumb side: forward in the A pose
    widths = [(0.0, 0.024, 0.017), (0.02, 0.035, 0.019), (0.04, 0.041, 0.020), (0.058, 0.042, 0.019),
              (0.074, 0.040, 0.018), (0.087, 0.034, 0.016), (0.096, 0.021, 0.011)]
    rings = []
    pos = W[sd] - a * 0.012; dirn = a.copy(); nn = nrm.copy(); last = 0.0
    for s, hw, ht in widths:
        step = s - last; last = s
        if s > 0.05:   # mitten curl toward the palm
            ang = D(52) * step / 0.046
            q = Quaternion(side, ang if a.cross(nrm).dot(side) > 0 else -ang)
            dirn = q @ dirn; nn = q @ nn
        pos = pos + dirn * step
        rings.append(ellipse(pos, side, nn, hw * 0.5 + 0.004, ht, 12))
    part.loft(rings, C["skin"], cap0=W[sd] - a * 0.02, cap1=pos + dirn * 0.007)
    base = W[sd] + a * 0.026 + side * 0.019 + nrm * 0.007
    td = (a * 0.65 + side * 0.4 + nrm * 0.45).normalized()
    tube(part, [base, base + td * 0.016, base + td * 0.032, base + td * 0.044], [0.0125, 0.012, 0.011, 0.009], C["skin"], n=10)


pt = Part()
hand(pt, 1)
objs["skin"] = add("skin", "hand_L", finish("skin", pt, MAT["skin"], subdiv=1))
pt = Part()
hand(pt, -1)
objs["hand_R"] = add("hand_R", "hand_R", finish("hand_R", pt, MAT["skin"], subdiv=1))

# ------------------------------------------------------------------ trousers and boots

pt = Part()
pel = [(0.77, 0.132, 0.092), (0.86, 0.136, 0.095), (0.98, 0.128, 0.09)]
pt.loft([ellipse(Vector((0, 0, z)), Vector((1, 0, 0)), Vector((0, -1, 0)), rx, ry, 16, e=2.4) for z, rx, ry in pel], C["trousers"],
        cap0=Vector((0, 0, 0.74)))
for sd in (1, -1):
    tube(pt, [Vector((sd * 0.076, 0, z)) for z in (0.86, 0.6, 0.35, 0.15)], [0.064, 0.06, 0.055, 0.052], C["trousers"], n=12, hint=Vector((0, -1, 0)))
    tube(pt, [Vector((sd * 0.088, -0.012, z)) for z in (0.17, 0.08, 0.0)], [0.06, 0.062, 0.056], C["boot"], n=12)
    tube(pt, [Vector((sd * 0.088, -0.02, 0.04)), Vector((sd * 0.09, -0.09, 0.035))], [0.05, 0.042], C["boot"], n=10)
objs["trousers"] = add("trousers", "trousers", finish("trousers", pt, MAT["trousers"], subdiv=0))

# ------------------------------------------------------------------ scarf


def ribbon(part, pts, width, thick, n=24, stripes=()):
    secs = []
    for i in range(n + 1):
        s = i / n
        p, tng = polyline(pts, s)
        wdir = Vector((1, 0, 0)); wdir = (wdir - tng * wdir.dot(tng)).normalized()
        nd = tng.cross(wdir).normalized()
        hw, ht = width / 2, thick / 2
        ring = [p + wdir * hw * 1.0 + nd * ht * 0.6, p + wdir * hw * 0.6 + nd * ht, p - wdir * hw * 0.6 + nd * ht,
                p - wdir * hw + nd * ht * 0.6 * 1.0 - nd * ht * 1.2, p - wdir * hw * 0.6 - nd * ht, p + wdir * hw * 0.6 - nd * ht]
        ring[3] = p - wdir * hw
        ring[0] = p + wdir * hw
        col = C["stripe"] if any(a <= s <= b for a, b in stripes) else C["scarf"]
        secs.append((ring, col))
    ids = [part.ring(r, c) for r, c in secs]
    for i in range(n):
        part.bridge(ids[i], ids[i + 1])
    p0, t0 = polyline(pts, 0); p1, t1 = polyline(pts, 1)
    part.cap(ids[0], p0 - t0 * 0.002, secs[0][1])
    part.cap(ids[-1], p1 + t1 * 0.002, secs[-1][1], flip=True)


pt = Part()
NW = 16
wr = []
for i in range(NW):
    a = i / NW * TAU
    c = Vector((math.sin(a) * 0.06, 0.004 - math.cos(a) * 0.06, 1.372 + 0.006 * math.sin(a * 2 + 0.6)))
    o = Vector((math.sin(a), -math.cos(a), 0))
    wr.append([c + o * (0.022 * math.cos(b)) + Vector((0, 0, 0.026 * math.sin(b))) for b in (j / 8 * TAU for j in range(8))])
ids = [pt.ring(r, C["scarf"]) for r in wr]
for i in range(NW):
    a, b = ids[i], ids[(i + 1) % NW]
    for j in range(8):
        pt.f.append((a[j], b[j], b[(j + 1) % 8], a[(j + 1) % 8]))
# Knot at the front-left.
kb = bmesh.new()
bmesh.ops.create_icosphere(kb, subdivisions=1, radius=0.026)
base_i = len(pt.v)
for v in kb.verts:
    pt.vert(Vector((0.03, -0.066, 1.352)) + Vector((v.co.x, v.co.y * 0.8, v.co.z * 0.9)), C["scarf"])
for f in kb.faces:
    pt.f.append(tuple(base_i + v.index for v in f.verts))
kb.free()
FRONT = [Vector(p) for p in ((0.036, -0.078, 1.345), (0.045, -0.134, 1.27), (0.05, -0.149, 1.18), (0.052, -0.151, 1.12))]
add("scarf", "scarf_neck", finish("scarf", pt, MAT["scarf"], subdiv=1))
pt = Part()
ribbon(pt, FRONT, 0.056, 0.012, n=10, stripes=((0.72, 0.8), (0.86, 0.94)))
add("scarf", "scarf_front", finish("scarf_front", pt, MAT["scarf"], subdiv=1))
pt = Part()
ribbon(pt, TAIL, 0.068, 0.012, n=20, stripes=((0.8, 0.85), (0.9, 0.95)))
add("scarf", "scarf_tail", finish("scarf_tail", pt, MAT["scarf"], subdiv=1))

# ------------------------------------------------------------------ the burner lever

# The rod slides down through a fixed bushing at the valve block when she pulls (LEV_TRAVEL): its top
# runs on up inside the block, so no gap opens above the bushing.
pt = Part()
LEV_UP = LEV_PIVOT + (LEV_PIVOT - LEV_BAR).normalized() * 0.14
tube(pt, [LEV_UP, LEV_PIVOT, LEV_PIVOT.lerp(LEV_BAR, 0.5), LEV_BAR], [0.01, 0.011, 0.01, 0.01], C["rod"], n=8)
tube(pt, [LEV_BAR + Vector((-0.07, 0, 0)), LEV_BAR + Vector((-0.035, 0, 0)), LEV_BAR, LEV_BAR + Vector((0.035, 0, 0)), LEV_BAR + Vector((0.07, 0, 0))],
     [0.014, 0.016, 0.016, 0.016, 0.014], C["grip"], n=10)
objs["lever"] = add("lever", "lever", finish("lever", pt, MAT["lever"], subdiv=0, sharp=D(40)))
pt = Part()
kb = bmesh.new()
bmesh.ops.create_icosphere(kb, subdivisions=1, radius=0.022)
base_i = len(pt.v)
for v in kb.verts: pt.vert(LEV_PIVOT + v.co, C["rod"])
for f in kb.faces: pt.f.append(tuple(base_i + v.index for v in f.verts))
kb.free()
add("lever", "bushing", finish("bushing", pt, MAT["lever"], subdiv=0, sharp=D(40)))

# ------------------------------------------------------------------ armature

ad = bpy.data.armatures.new("pilot_rig")
arm = bpy.data.objects.new("pilot", ad)
sc.collection.objects.link(arm)
arm.location = PILOT
bpy.context.view_layer.objects.active = arm
for o in sc.objects: o.select_set(False)
arm.select_set(True)
bpy.ops.object.mode_set(mode='EDIT')
eb = ad.edit_bones


def bone(name, h, t, parent=None, deform=True, roll=None):
    b = eb.new(name)
    b.head = h; b.tail = t
    if roll is not None: b.align_roll(roll)
    if parent: b.parent = eb[parent]
    b.use_deform = deform
    return b


bone("root", (0, 0, 0), (0, 0, 0.2))
bone("hips", (0, 0, 0.86), (0, 0, 1.0), "root")
bone("spine", (0, 0, 1.0), (0, 0, 1.16), "hips")
bone("chest", (0, 0, 1.16), (0, 0, 1.33), "spine")
bone("neck", (0, 0, 1.33), (0, -0.004, 1.43 + HZ), "chest")
bone("head", (0, -0.004, 1.43 + HZ), (0, -0.004, 1.66 + HZ), "neck")
for sd, sx in ((1, "L"), (-1, "R")):
    bone(f"shoulder_{sx}", (sd * 0.03, 0, 1.30), S[sd], "chest")
    bone(f"upperarm_{sx}", S[sd], E[sd], f"shoulder_{sx}", roll=Vector((0, 1, 0)))
    bone(f"forearm_{sx}", E[sd], W[sd], f"upperarm_{sx}", roll=Vector((0, 1, 0)))
    bone(f"hand_{sx}", W[sd], T[sd], f"forearm_{sx}", roll=PALM_N[sd])
    # Elbow helper: at the elbow, aligned with the forearm, turning half as far (a constraint below).
    # The sleeve round the joint is weighted to it, so the bend is spread over two half-bends.
    bone(f"elbow_{sx}", E[sd], E[sd] + (W[sd] - E[sd]) * 0.3, f"upperarm_{sx}", roll=Vector((0, 1, 0)))
    bone(f"thigh_{sx}", (sd * 0.086, 0, 0.86), (sd * 0.087, -0.01, 0.47), "hips")
    bone(f"shin_{sx}", (sd * 0.087, -0.01, 0.47), (sd * 0.088, 0, 0.08), f"thigh_{sx}")
TJ = [polyline(TAIL, k / 5)[0] for k in range(6)]
for k in range(5):
    bone(f"scarf_{k}", TJ[k], TJ[k + 1], "neck" if k == 0 else f"scarf_{k - 1}")
bone("lever", LEV_PIVOT, LEV_BAR, "root", roll=Vector((0, -1, 0)))
bone("ik_R", GRIP_R, GRIP_R + Vector((0, 0, 0.09)), "lever", deform=False, roll=Vector((0, -1, 0)))
lft = Vector((0, -0.088, -0.018))
bone("ik_L", RIM_L, RIM_L + lft, "root", deform=False, roll=Vector((0, 0, -1)))
bone("pole_R", POLE_R_REST, POLE_R_REST + Vector((0, 0, 0.1)), "chest", deform=False)
bone("pole_L", (0.62, 0.26, 1.02), (0.62, 0.26, 1.12), "chest", deform=False)
bpy.ops.object.mode_set(mode='OBJECT')
ad.display_type = 'STICK'

# ------------------------------------------------------------------ weights


def chain(p, joints, names, blend):
    best = None
    for i in range(len(joints) - 1):
        a, b = joints[i], joints[i + 1]; ab = b - a; L = ab.length
        t = max(0.0, min(1.0, (p - a).dot(ab) / (L * L)))
        d = (a + ab * t - p).length
        if best is None or d < best[0] - 1e-9: best = (d, i, t * L, L)
    d, i, s, L = best
    if i > 0 and s < blend:
        k = 0.5 * (1 - s / blend); return {names[i]: 1 - k, names[i - 1]: k}
    if i < len(names) - 1 and L - s < blend:
        k = 0.5 * (1 - (L - s) / blend); return {names[i]: 1 - k, names[i + 1]: k}
    return {names[i]: 1.0}


SPINE_J = [Vector((0, 0, z)) for z in (0.6, 1.0, 1.16, 1.33, 1.47)]
SPINE_N = ["hips", "spine", "chest", "neck"]


def w_torso(p):
    w = chain(p, SPINE_J, SPINE_N, 0.06)
    sd = 1 if p.x > 0 else -1
    f = smooth(0.10, 0.155, abs(p.x)) * smooth(1.2, 1.29, p.z)
    if f > 0:
        w = {k: v * (1 - 0.6 * f) for k, v in w.items()}
        w[f"shoulder_{'L' if sd > 0 else 'R'}"] = w.get(f"shoulder_{'L' if sd > 0 else 'R'}", 0) + 0.6 * f
    return w


def w_arm(p, sd):
    """Shoulder -> upper arm over a soft 10 cm band; upper arm -> elbow helper -> forearm over a
    wide band round the elbow (16 cm), so the sleeve bends in a curve, not a fold."""
    sx = "L" if sd > 0 else "R"
    ad_ = ARM_D[sd]
    xs = (p - S[sd]).dot(ad_)                  # along the arm from the shoulder joint
    xe = (p - E[sd]).dot((W[sd] - E[sd]).normalized()) if (p - E[sd]).dot(ad_) > 0 else (p - E[sd]).dot(ad_)
    sh = 1 - smooth(-0.05, 0.05, xs)           # shoulder share
    h = 1 - smooth(0.0, 0.08, abs(xe))          # elbow helper share (1 at the joint)
    w = {f"shoulder_{sx}": sh}
    rest = 1 - sh
    if xe < 0: w[f"upperarm_{sx}"] = rest * (1 - h); w[f"elbow_{sx}"] = rest * h
    else: w[f"forearm_{sx}"] = rest * (1 - h); w[f"elbow_{sx}"] = rest * h
    return w


def w_hand(p, sd):
    sx = "L" if sd > 0 else "R"
    return chain(p, [W[sd] - ARM_D[sd] * 0.06, W[sd], T[sd] + ARM_D[sd] * 0.1], [f"forearm_{sx}", f"hand_{sx}"], 0.018)


def w_part(name, p, idx):
    if name in ("hair", "goggles"): return {"head": 1.0}
    if name == "head":
        if idx < N_SPHERE: return {"head": 1.0}
        return chain(p, [Vector((0, 0, 1.2)), Vector((0, 0, 1.33)), Vector((0, 0, 1.43 + HZ)), Vector((0, 0, 1.7))], ["chest", "neck", "head"], 0.04)
    if name == "torso":
        if p.z > 1.29 and abs(p.x) < 0.14 and (p.xy.length > 0.06):   # collar
            return chain(p, SPINE_J, SPINE_N, 0.05)
        return w_torso(p)
    if name == "sleeve_L": return w_arm(p, 1)
    if name == "sleeve_R": return w_arm(p, -1)
    if name == "hand_L": return w_hand(p, 1)
    if name == "hand_R": return w_hand(p, -1)
    if name == "trousers":
        if p.z > 0.9: return {"hips": 1.0}
        sd = 1 if p.x > 0 else -1; sx = "L" if sd > 0 else "R"
        return chain(p, [Vector((sd * 0.076, 0, 1.0)), Vector((sd * 0.076, 0, 0.86)), Vector((sd * 0.087, -0.01, 0.47)), Vector((sd * 0.088, 0, -0.1))],
                     ["hips", f"thigh_{sx}", f"shin_{sx}"], 0.06)
    if name == "scarf_neck":
        if p.z < 1.35 and p.y < -0.04: return {"neck": 0.6, "chest": 0.4}
        return {"neck": 1.0}
    if name == "scarf_front":
        return {"neck": 0.5, "chest": 0.5} if p.z > 1.33 else {"chest": 1.0}
    if name == "scarf_tail":
        return chain(p, [Vector((0.0, 0.02, 1.38))] + TJ, ["neck"] + [f"scarf_{k}" for k in range(5)], 0.05)
    if name == "lever": return {"lever": 1.0}
    if name == "bushing": return {"root": 1.0}
    if name == "collar":
        return {"neck": 0.25, "chest": 0.75} if p.z > 1.30 else {"chest": 1.0}
    raise KeyError(name)


DEFORM = [b.name for b in ad.bones if b.use_deform]
for final, key, ob in SUBS:
    groups = {n: ob.vertex_groups.new(name=n) for n in DEFORM}
    for v in ob.data.vertices:
        w = w_part(key, v.co, v.index)
        tot = sum(w.values())
        for k, x in w.items():
            if x > 1e-4: groups[k].add([v.index], x / tot, 'REPLACE')
# Join the parts of each final object (vertex groups carry over).
objs = {}
for final in dict.fromkeys(f for f, _, _ in SUBS):
    parts = [ob for f, _, ob in SUBS if f == final]
    head_ob = next(ob for ob in parts if ob.name == final)
    if len(parts) > 1:
        with bpy.context.temp_override(active_object=head_ob, selected_editable_objects=parts, object=head_ob):
            bpy.ops.object.join()
    objs[final] = head_ob
for name, ob in objs.items():
    ob.parent = arm
    ob.matrix_parent_inverse = Matrix.Identity(4)
    md = ob.modifiers.new("rig", 'ARMATURE')
    md.object = arm

# ------------------------------------------------------------------ IK

pose = arm.pose
for pb in pose.bones: pb.rotation_mode = 'QUATERNION'
for sx in ("R", "L"):
    ik = pose.bones[f"forearm_{sx}"].constraints.new('IK')
    ik.target = arm; ik.subtarget = f"ik_{sx}"
    ik.pole_target = arm; ik.pole_subtarget = f"pole_{sx}"
    ik.chain_count = 2
    cr_ = pose.bones[f"hand_{sx}"].constraints.new('COPY_ROTATION')
    cr_.target = arm; cr_.subtarget = f"ik_{sx}"
    eh = pose.bones[f"elbow_{sx}"].constraints.new('COPY_ROTATION')
    eh.target = arm; eh.subtarget = f"forearm_{sx}"
    eh.owner_space = 'LOCAL'; eh.target_space = 'LOCAL'
    eh.influence = 0.5


def elbow_err(sx):
    bpy.context.view_layer.update()
    e = pose.bones[f"forearm_{sx}"].head
    pl = pose.bones[f"pole_{sx}"].head
    s = pose.bones[f"upperarm_{sx}"].head
    w = pose.bones[f"hand_{sx}"].head
    ax = (w - s).normalized()
    a = (e - s) - ax * (e - s).dot(ax)
    b = (pl - s) - ax * (pl - s).dot(ax)
    return a.angle(b) if a.length > 1e-6 and b.length > 1e-6 else 9.0


for sx in ("R", "L"):
    ik = pose.bones[f"forearm_{sx}"].constraints[0]
    best = None
    for k in range(-12, 13):
        ik.pole_angle = D(k * 15)
        er = elbow_err(sx)
        if best is None or er < best[0]: best = (er, k * 15)
    ik.pole_angle = D(best[1])
    print("pole", sx, best)

# ------------------------------------------------------------------ animation


def q_arm(name, axis, ang):
    """A rotation about an armature-space axis, as the bone's local (basis) quaternion."""
    M = arm.data.bones[name].matrix_local.to_quaternion()
    return M.inverted() @ Quaternion(Vector(axis), ang) @ M


def loc_arm(name, v):
    M = arm.data.bones[name].matrix_local.to_3x3()
    return M.inverted() @ Vector(v)


def ease(a, b, t):
    return smooth(a, b, t)


def target_matrix(pos, fwd, palm):
    """Armature-space matrix of an IK target: y = hand direction, z = palm normal."""
    y = Vector(fwd).normalized(); z = Vector(palm); z = (z - y * z.dot(y)).normalized(); x = y.cross(z)
    m = Matrix((x, y, z)).transposed().to_4x4()
    m.translation = pos
    return m


GRIP_M = target_matrix(GRIP_R, (0, 0, 1), (0, -1, 0))
RIMR_M = target_matrix(RIM_R, lft, (0, 0, -1))
RIML_M = target_matrix(RIM_L, lft, (0, 0, -1))
FK = ["hips", "spine", "chest", "neck", "head", "shoulder_L", "shoulder_R", "thigh_L", "thigh_R", "shin_L", "shin_R",
      "lever"] + [f"scarf_{k}" for k in range(5)]


def scarf_pose(t, extra_lift=0.0):
    out = {}
    for k in range(5):
        lift = (D(34) if k == 0 else D(8)) + extra_lift * (1 if k == 0 else 0.3)
        ph = TAU * t / 2.0 - k * 1.0
        flut = D(9) * math.sin(ph) + D(3) * math.sin(2 * ph + 0.7)
        swing = D(7) * math.sin(TAU * t / 2.0 - k * 0.8 + 1.3)
        out[f"scarf_{k}"] = q_arm(f"scarf_{k}", (1, 0, 0), lift + flut * (0.5 + 0.15 * k)) @ q_arm(f"scarf_{k}", (0, 0, 1), swing * (0.5 + 0.15 * k))
    return out


def pose_idle(t):
    """Relaxed: both hands resting on the front rim, breathing, a small sway, looking about."""
    b = math.sin(TAU * t / 4)
    c = math.sin(TAU * t / 4 + 1.2)
    rot = {
        "hips": q_arm("hips", (0, 1, 0), D(1.0) * math.sin(TAU * t / 4 + 0.5)),
        "spine": q_arm("spine", (1, 0, 0), D(1.0) * b) @ q_arm("spine", (0, 1, 0), D(-1.0) * math.sin(TAU * t / 4 + 0.5)),
        "chest": q_arm("chest", (1, 0, 0), D(-1.2) * math.sin(TAU * t / 4 * 2)),
        "neck": q_arm("neck", (0, 0, 1), D(4) * c),
        "head": q_arm("head", (0, 0, 1), D(7) * c) @ q_arm("head", (1, 0, 0), D(4) + D(2) * math.sin(TAU * t / 4 + 2.0)) @ q_arm("head", (0, 1, 0), D(3) * c),
    }
    rot.update(scarf_pose(t))
    # Right hand: on the rim (blend 1 = rim, 0 = the lever's grip); pole: 0 = rest, 1 = up.
    return rot, {"ik_R": 1.0, "pole_R": 0.0, "grip_L": 0.0, "loc": {}}


def blend_m(a, b, f):
    la, ra, _ = a.decompose(); lb, rb, _ = b.decompose()
    m = ra.slerp(rb, f).to_matrix().to_4x4(); m.translation = la.lerp(lb, f)
    return m


def pose_look(t):
    rot, tg = pose_idle(0.0)
    lean = ease(0.45, 1.5, t) * (1 - ease(4.1, 5.1, t))
    hold = ease(1.5, 2.0, t) * (1 - ease(3.7, 4.2, t))
    look = math.sin(TAU * (t - 1.5) / 2.7) * hold
    b = math.sin(TAU * t / 6)
    rot.update({
        "hips": q_arm("hips", (0, 0, 1), D(-3) * lean),
        "spine": q_arm("spine", (1, 0, 0), D(9) * lean + D(1) * b),
        "chest": q_arm("chest", (1, 0, 0), D(10) * lean),
        "neck": q_arm("neck", (1, 0, 0), D(10) * lean) @ q_arm("neck", (0, 0, 1), D(7) * look),
        "head": q_arm("head", (1, 0, 0), D(4) + D(28) * lean) @ q_arm("head", (0, 0, 1), D(14) * look) @ q_arm("head", (0, 1, 0), D(-6) * look),
    })
    rot.update(scarf_pose(t, extra_lift=D(10) * lean))
    tg["grip_L"] = 0.5 * lean
    tg["loc"] = {"hips": (0, -0.035 * lean, 0)}
    return rot, tg


# Burner clip timing (s): reach 0-0.45, pull 0.42-0.7, hold loop 0.7-2.7 (2 s: the scarf's period,
# the hum's twice), release: the lever back up 2.7-2.95, the hand back to the rim to 3.3.
B_PULL, B_HOLD, B_END = 0.7, 2.7, 3.3


def pose_burner(t):
    rot, tg = pose_idle(0.0)
    reach = ease(0.0, 0.45, t) * (1 - ease(2.85, B_END, t))
    pull = ease(0.42, B_PULL, t) * (1 - ease(B_HOLD, 2.95, t))
    g = ease(0.1, 0.6, t) * (1 - ease(2.75, B_END, t))
    hum = math.sin(TAU * (t - B_PULL) / 1.0) if B_PULL <= t <= B_HOLD else 0.0
    rot.update({
        "hips": q_arm("hips", (0, 1, 0), D(2.5) * g),
        "spine": q_arm("spine", (1, 0, 0), D(-4) * g) @ q_arm("spine", (0, 1, 0), D(2) * g),
        "chest": q_arm("chest", (1, 0, 0), D(-6) * g + D(0.5) * hum * g) @ q_arm("chest", (0, 0, 1), D(-5) * g),
        # Chin up, eyes on the nozzle above her right hand.
        "neck": q_arm("neck", (1, 0, 0), D(-10) * g) @ q_arm("neck", (0, 0, 1), D(-4) * g),
        "head": q_arm("head", (1, 0, 0), D(4) - D(26) * g) @ q_arm("head", (0, 0, 1), D(-10) * g) @ q_arm("head", (0, 1, 0), D(-5) * g),
        # The shoulder lifts with the reach and drops as she pulls down.
        "shoulder_R": q_arm("shoulder_R", (0, 1, 0), D(16) * reach - D(7) * pull),
    })
    rot.update(scarf_pose(t))
    tg["ik_R"] = 1 - reach
    tg["pole_R"] = reach
    tg["grip_L"] = g
    tg["loc"] = {"lever": (0, LEV_TRAVEL * pull + 0.004 * hum * pull, 0), "hips": (0, 0, 0.012 * g)}
    return rot, tg


CLIPS = [("idle", pose_idle, 4.0), ("lookOver", pose_look, 6.0), ("burner", pose_burner, B_END)]
arm.animation_data_create()
for track in list(arm.animation_data.nla_tracks):
    arm.animation_data.nla_tracks.remove(track)
ID_Q = Quaternion()
GRIPL_M = RIML_M.copy(); GRIPL_M.translation += Vector((0.0, -0.012, -0.014))   # her left hand bears down on the rim
for name, fn, dur in CLIPS:
    act = bpy.data.actions.new(f"pilot_{name}")
    arm.animation_data.action = act
    nf = int(round(dur * FPS))
    for f in range(nf + 1):
        t = f / FPS
        rot, tg = fn(t)
        for pb in pose.bones:
            pb.location = (0, 0, 0); pb.scale = (1, 1, 1)
            pb.rotation_quaternion = rot.get(pb.name, ID_Q)
        for bn, v in tg["loc"].items():
            # lever: along its own axis (bone y); others: armature-space offsets
            pose.bones[bn].location = v if bn == "lever" else loc_arm(bn, (v[0], v[1], v[2]) if bn != "hips" else v)
        bpy.context.view_layer.update()
        # The right elbow's pole (armature space, carried by the chest).
        pose.bones["pole_R"].matrix = Matrix.Translation(POLE_R_REST.lerp(POLE_R_UP, tg["pole_R"]))
        # IK targets: the right one rides on the lever's grip, or rests on the rim (an arc between).
        f_ = tg["ik_R"]
        lev = pose.bones["lever"].matrix @ arm.data.bones["lever"].matrix_local.inverted()
        m = blend_m(lev @ GRIP_M, RIMR_M, f_)
        m.translation += Vector((0.0, -0.05, 0.06)) * math.sin(math.pi * f_)
        pose.bones["ik_R"].matrix = m
        pose.bones["ik_L"].matrix = blend_m(RIML_M, GRIPL_M, tg["grip_L"])
        bpy.context.view_layer.update()
        for pb in pose.bones:
            pb.keyframe_insert("rotation_quaternion", frame=f + 1, group=pb.name)
            pb.keyframe_insert("location", frame=f + 1, group=pb.name)
    tr = arm.animation_data.nla_tracks.new()
    tr.name = name
    st = tr.strips.new(name, 1, act)
    st.name = name
    act.use_fake_user = True
    arm.animation_data.action = None
for pb in pose.bones:
    pb.rotation_quaternion = ID_Q; pb.location = (0, 0, 0)

tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in objs.values())
print("tris", tris, {k: len(o.data.polygons) for k, o in objs.items()})


# ------------------------------------------------------------------ export

def export():
    for o in sc.objects: o.select_set(False)
    arm.select_set(True)
    for o in objs.values(): o.select_set(True)
    bpy.context.view_layer.objects.active = arm
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    kw = dict(filepath=OUT, export_format="GLB", use_selection=True, export_apply=True, export_yup=True,
              export_draco_mesh_compression_enable=False, export_materials="EXPORT", export_normals=True,
              export_texcoords=True, export_skins=True, export_animations=True, export_animation_mode="NLA_TRACKS",
              export_force_sampling=True, export_frame_step=1, export_def_bones=True, export_optimize_animation_size=True,
              export_anim_slide_to_zero=True, export_reset_pose_bones=True, export_morph=False, export_image_format="AUTO",
              export_all_influences=False, export_extras=False, export_current_frame=False, use_active_scene=True)
    props = bpy.ops.export_scene.gltf.get_rna_type().properties.keys()
    if "export_vertex_color" in props: kw["export_vertex_color"] = "ACTIVE"
    elif "export_colors" in props: kw["export_colors"] = True
    if "export_all_vertex_colors" in props: kw["export_all_vertex_colors"] = False
    missing = [k for k in kw if k not in props]
    kw = {k: v for k, v in kw.items() if k in props}
    bpy.ops.export_scene.gltf(**kw)
    print("exported", OUT, os.path.getsize(OUT), "bytes; options not in this Blender:", missing)


if globals().get("PILOT_EXPORT", True):
    export()
