"""Shrinks a flat-shaded asset-forge GLB for Kervan: drops NORMAL and TEXCOORD attributes (the game recomputes flat
normals after loading) and preview_* nodes, then repacks the binary buffer.
usage: python slim_glb.py <in.glb> <out.glb>"""
import json, struct, sys

src, dst = sys.argv[1], sys.argv[2]
b = open(src, "rb").read()
jl = struct.unpack_from("<I", b, 12)[0]
j = json.loads(b[20:20 + jl])
bin0 = 20 + jl + 8

# drop preview nodes
keep = [i for i, n in enumerate(j["nodes"]) if not n.get("name", "").startswith("preview_")]
remap = {o: i for i, o in enumerate(keep)}
j["nodes"] = [j["nodes"][i] for i in keep]
for sc in j["scenes"]:
    sc["nodes"] = [remap[i] for i in sc["nodes"] if i in remap]
used_meshes = sorted({n["mesh"] for n in j["nodes"] if "mesh" in n})
mremap = {o: i for i, o in enumerate(used_meshes)}
j["meshes"] = [j["meshes"][i] for i in used_meshes]
for n in j["nodes"]:
    if "mesh" in n:
        n["mesh"] = mremap[n["mesh"]]

out = bytearray(); views = []; accs = []; amap = {}
def take(ai):
    if ai in amap:
        return amap[ai]
    a = dict(j["accessors"][ai]); bv = j["bufferViews"][a.pop("bufferView")]
    start = bin0 + bv.get("byteOffset", 0) + a.pop("byteOffset", 0)
    comp = {5126: 4, 5125: 4, 5123: 2, 5121: 1}[a["componentType"]]
    ncomp = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]]
    size = a["count"] * comp * ncomp
    while len(out) % 4:
        out.append(0)
    views.append({"buffer": 0, "byteOffset": len(out), "byteLength": size})
    out.extend(b[start:start + size])
    a["bufferView"] = len(views) - 1
    accs.append(a); amap[ai] = len(accs) - 1
    return amap[ai]
for m in j["meshes"]:
    for p in m["primitives"]:
        p["attributes"] = {"POSITION": take(p["attributes"]["POSITION"])}
        if "indices" in p:
            p["indices"] = take(p["indices"])
used_mats = sorted({p["material"] for m in j["meshes"] for p in m["primitives"] if "material" in p})
matremap = {o: i for i, o in enumerate(used_mats)}
j["materials"] = [j["materials"][i] for i in used_mats]
for m in j["meshes"]:
    for p in m["primitives"]:
        if "material" in p:
            p["material"] = matremap[p["material"]]
j["accessors"] = accs; j["bufferViews"] = views
while len(out) % 4:
    out.append(0)
j["buffers"] = [{"byteLength": len(out)}]
for k in ("textures", "images", "samplers"):
    j.pop(k, None)
js = json.dumps(j, separators=(",", ":")).encode()
js += b" " * ((4 - len(js) % 4) % 4)
total = 12 + 8 + len(js) + 8 + len(out)
with open(dst, "wb") as f:
    f.write(struct.pack("<III", 0x46546C67, 2, total))
    f.write(struct.pack("<II", len(js), 0x4E4F534A)); f.write(js)
    f.write(struct.pack("<II", len(out), 0x004E4942)); f.write(out)
print(f"{dst}: {len(b) // 1024} KB -> {total // 1024} KB")
