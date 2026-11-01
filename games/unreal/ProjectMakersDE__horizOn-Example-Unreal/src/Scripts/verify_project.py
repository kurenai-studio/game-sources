#!/usr/bin/env python3
"""Engine-independent integrity checks; this does not compile or play Unreal."""
from pathlib import Path
import ast
import hashlib
import json
import re
import struct
import sys

ROOT = Path(__file__).resolve().parents[1]
failures = []

def check(condition, label):
    if not condition:
        failures.append(label)

lock = json.loads((ROOT / "SDK-SOURCE.json").read_text())
plugin = ROOT / "Plugins" / "HorizonSDK"
expected_files = set(lock["files"])
actual_files = {str(path.relative_to(plugin)) for path in plugin.rglob("*") if path.is_file() and path.relative_to(plugin).parts[0] not in {"Binaries", "Intermediate"}}
check(actual_files == expected_files, "Embedded plugin file list differs from the official SDK snapshot")
for name, digest in lock["files"].items():
    path = plugin / name
    check(path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() == digest, "SDK hash: " + name)
check(json.loads((plugin / "HorizonSDK.uplugin").read_text())["VersionName"] == lock["descriptorVersion"], "SDK version")
required_headers = set()
for source in (ROOT / "Source").rglob("*"):
    if source.suffix in {".h", ".cpp"}:
        required_headers.update(name for name in re.findall(r'^\s*#include\s+"([^"]+)"', source.read_text(), re.MULTILINE)
                                if re.match(r"Horizon[A-Z]", Path(name).name))
for name in sorted(required_headers):
    check((plugin / "Source/HorizonSDK/Public" / name).is_file(), "Game requires an absent official SDK public header: " + name)
print(f"Required game SDK public headers: {len(required_headers)} (native compilation remains a separate check)")
project = json.loads((ROOT / "SeagullStorm.uproject").read_text())
check(project["EngineAssociation"] == "5.8", "Engine association")
manifest = json.loads((ROOT / "Content" / "Textures" / "asset-manifest.json").read_text())
for record in manifest:
    path = ROOT / "Content" / "Textures" / record["file"]
    check(path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest() == record["sha256"], "Artwork hash: " + record["file"])
    if record["file"] != "arena_background.png":
        check(record["alpha_min"] == 0 and record["alpha_max"] == 255, "Declared true alpha: " + record["file"])
for name in ["seagull_hero", "enemy_crab", "enemy_jellyfish", "enemy_pirate", "enemy_octopus", "pickup_shell", "pickup_coin", "pickup_heart", "arena_background"]:
    path = ROOT / "Content" / "Textures" / (name + ".png")
    data = path.read_bytes() if path.exists() else b""
    check(data[:8] == b"\x89PNG\r\n\x1a\n", "PNG signature: " + name)
    if len(data) >= 26:
        width, height = struct.unpack(">II", data[16:24])
        check(width > 0 and height > 0, "Image dimensions: " + name)
        if name != "arena_background":
            check(data[25] == 6, "RGBA color type: " + name)
print("SDK snapshot: {tag} / {commit}".format(**lock))
print("Shared PNG assets: 9 / manifest present")
rig = json.loads((ROOT / "Content/Textures/Cutout/rig.json").read_text())
check(rig["schemaVersion"] == 1, "Cutout schema")
parts = []
for family in ("gull", "crab"):
    definition = rig["characters"][family]
    check([part["layer"] for part in definition["parts"]] == list(range(len(definition["parts"]))), "Cutout layer order: " + family)
    for part in definition["parts"]:
        path = ROOT / "Content/Textures/Cutout" / part["file"]
        data = path.read_bytes() if path.is_file() else b""
        check(hashlib.sha256(data).hexdigest() == part["sha256"], "Cutout hash: " + part["file"])
        check(len(data) >= 26 and data[:8] == b"\x89PNG\r\n\x1a\n" and data[25] == 6, "Cutout RGBA: " + part["file"])
        if len(data) >= 24:
            check(list(struct.unpack(">II", data[16:24])) == definition["canvas"], "Cutout canvas: " + part["file"])
        parts.append(path)
shadow = ROOT / "Content/Textures/Cutout" / rig["shadow"]["file"]
check(shadow.is_file() and hashlib.sha256(shadow.read_bytes()).hexdigest() == rig["shadow"]["sha256"], "Cutout shadow hash")
check(len(parts) == 16, "Cutout part count")
packaging = (ROOT / "Config/DefaultGame.ini").read_text()
for family in ("Sprites", "Flipbooks", "Materials", "Audio"):
    check(f'+DirectoriesToAlwaysCook=(Path="/Game/{family}")' in packaging, "Runtime assets included in cooking: " + family)
check('+MapsToCook=(FilePath="/Game/Maps/MainMap")' in packaging, "MainMap included in cooking")
print("Cutout PNG assets: 16 parts + separate shadow / hashes, RGBA, canvases and layers")
map_exists = (ROOT / "Content" / "Maps" / "MainMap.umap").is_file()
print("Unreal editor bootstrap: " + ("map exists; engine build/play still required" if map_exists else "PENDING / no MainMap.umap; run Scripts/setup_editor_assets.py inside Unreal"))
required_assets = {"Content/Maps/MainMap.umap", "Content/Materials/M_ArenaColor.uasset"}
# Read the bootstrap's canonical source list without importing Unreal or regenerating assets.
bootstrap = ast.parse((ROOT / "Scripts/setup_editor_assets.py").read_text())
sources = next(ast.literal_eval(node.value) for node in ast.walk(bootstrap)
               if isinstance(node, ast.Assign) and any(isinstance(target, ast.Name) and target.id == "sources" for target in node.targets))
for name, (filename, _, animations) in sources.items():
    required_assets.add("Content/Textures/" + str(Path(filename).with_suffix(".uasset")))
    required_assets.add("Content/Sprites/SP_" + name + ".uasset")
    required_assets.update("Content/Flipbooks/FB_" + animation + ".uasset" for animation in animations)
for family in ("gull", "crab"):
    for part in rig["characters"][family]["parts"]:
        required_assets.add("Content/Textures/Cutout/" + str(Path(part["file"]).with_suffix(".uasset")))
        required_assets.add("Content/Sprites/Cutout/SP_Cutout_" + family + "_" + part["name"] + ".uasset")
required_assets.add("Content/Textures/Cutout/" + str(Path(rig["shadow"]["file"]).with_suffix(".uasset")))
required_assets.add("Content/Sprites/Cutout/SP_Cutout_shadow.uasset")
required_assets.update(str(path.with_suffix(".uasset").relative_to(ROOT)) for path in (ROOT / "Content/Audio").rglob("*.ogg"))
for name in sorted(required_assets):
    path = ROOT / name
    check(path.is_file() and path.read_bytes()[:4] == b"\xc1\x83\x2a\x9e", "Imported Unreal package missing or invalid: " + name)
print(f"Required imported Unreal packages: {len(required_assets)} (native asset loading remains a separate check)")
if failures:
    for failure in failures:
        print("FAIL: " + failure, file=sys.stderr)
    sys.exit(1)
print("PASS: engine-independent snapshot and project integrity")
