#!/usr/bin/env python3
"""Fetch the free CC0 game asset packs used by Neon Dash's Android build."""

from __future__ import annotations

import http.cookiejar
import json
import os
import re
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACK_DIR = ROOT / "android/src/main/assets/assetpacks"
MODEL_DIR = ROOT / "android/src/main/assets/models/quaternius/city"
SCIFI_MODEL_DIR = ROOT / "android/src/main/assets/models/quaternius/scifi"
SHIP_MODEL_DIR = ROOT / "android/src/main/assets/models/quaternius/spaceships"
PACKS = [
    ("downtown-city-megakit", "Downtown City MegaKit[Standard].zip", "downtown-city-megakit-standard.zip"),
    ("modular-sci-fi-megakit", "Modular SciFi MegaKit[Standard].zip", "modular-scifi-megakit-standard.zip"),
    ("sci-fi-essentials-kit", "Sci-Fi Essentials Kit[Standard].zip", "sci-fi-essentials-standard.zip"),
    ("lowpoly-spaceships", "Spaceship Pack - Jan 2018.zip", "spaceship-pack-standard.zip"),
]
USER_AGENT = "NeonDashAssetBuilder/1.0 (free CC0 game assets)"


def make_opener():
    return urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))


def fetch_pack(opener, slug: str, expected_name: str, filename: str) -> Path:
    dest = PACK_DIR / filename
    if dest.exists() and zipfile.is_zipfile(dest):
        return dest

    base = f"https://quaternius.itch.io/{slug}"
    headers = {"User-Agent": USER_AGENT}
    purchase = opener.open(urllib.request.Request(base + "/purchase", headers=headers), timeout=45).read().decode("utf-8", "replace")
    token_match = re.search(r'<meta name="csrf_token" value="([^"]+)"', purchase)
    if not token_match:
        raise RuntimeError(f"Could not read itch.io download token for {slug}")
    csrf = token_match.group(1)

    req = urllib.request.Request(
        base + "/download_url",
        data=urllib.parse.urlencode({"csrf_token": csrf}).encode(),
        headers={**headers, "Referer": base + "/purchase", "X-Requested-With": "XMLHttpRequest"},
    )
    access = json.loads(opener.open(req, timeout=45).read().decode("utf-8"))
    download_page_url = access.get("url")
    if not download_page_url:
        raise RuntimeError(f"itch.io did not grant the free download for {slug}")

    page = opener.open(urllib.request.Request(download_page_url, headers={**headers, "Referer": base + "/purchase"}), timeout=45).read().decode("utf-8", "replace")
    token_match = re.search(r'<meta name="csrf_token" value="([^"]+)"', page)
    upload_ids = re.findall(r'<a\b(?=[^>]*data-upload_id="(\d+)")(?=[^>]*download_btn)[^>]*>Download</a>', page)
    if not token_match:
        raise RuntimeError(f"Could not read download-page token for {slug}")
    if not upload_ids or expected_name not in page:
        raise RuntimeError(f"Expected free standard upload was not found for {slug}")
    csrf = token_match.group(1)
    upload_id = upload_ids[0]

    req = urllib.request.Request(
        base + f"/file/{upload_id}?source=view_game&as_props=1",
        data=urllib.parse.urlencode({"csrf_token": csrf}).encode(),
        headers={**headers, "Referer": download_page_url, "X-Requested-With": "XMLHttpRequest"},
    )
    signed = json.loads(opener.open(req, timeout=45).read().decode("utf-8"))
    direct_url = signed.get("url")
    if not direct_url:
        raise RuntimeError(f"No asset URL returned for {slug}")

    PACK_DIR.mkdir(parents=True, exist_ok=True)
    partial = dest.with_suffix(dest.suffix + ".partial")
    request = urllib.request.Request(direct_url, headers={"User-Agent": USER_AGENT, "Referer": base + "/"})
    with opener.open(request, timeout=90) as source, partial.open("wb") as target:
        while True:
            block = source.read(1024 * 1024)
            if not block:
                break
            target.write(block)
    if not zipfile.is_zipfile(partial):
        partial.unlink(missing_ok=True)
        raise RuntimeError(f"Downloaded file for {slug} was not a ZIP archive")
    os.replace(partial, dest)
    print(f"Downloaded {expected_name}: {dest.stat().st_size:,} bytes")
    return dest


def extract_models(pack_path: Path, model_dir: Path, model_names: set[str], prefix: str):
    """Extract selected glTF models and their files, keeping mobile textures <= 1K."""
    import json as json_module
    from PIL import Image

    model_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(pack_path) as archive:
        for model_name in model_names:
            gltf_name = prefix + model_name + ".gltf"
            gltf = json_module.loads(archive.read(gltf_name))
            files = {gltf_name}
            for buffer in gltf.get("buffers", []):
                files.add(prefix + buffer["uri"])
            for image in gltf.get("images", []):
                files.add(prefix + image["uri"])
            for member in files:
                output = model_dir / Path(member).name
                output.write_bytes(archive.read(member))
                if output.suffix.lower() == ".png":
                    with Image.open(output) as image:
                        if max(image.size) > 1024:
                            image.thumbnail((1024, 1024), Image.Resampling.LANCZOS)
                            image.save(output, format="PNG", optimize=True)


def extract_obj_pack(pack_path: Path, model_dir: Path):
    """Extract the CC0 OBJ ship meshes and their MTL/texture files."""
    model_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(pack_path) as archive:
        for info in archive.infolist():
            suffix = Path(info.filename).suffix.lower()
            relative = Path(info.filename)
            if suffix not in {".obj", ".mtl", ".png", ".jpg"} or relative.is_absolute() or ".." in relative.parts:
                continue
            output = model_dir / relative
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_bytes(archive.read(info))


def main():
    opener = make_opener()
    PACK_DIR.mkdir(parents=True, exist_ok=True)
    for stale in PACK_DIR.glob("*.partial"):
        stale.unlink()
    city = None
    scifi = None
    essentials = None
    spaceships = None
    for slug, upload_name, filename in PACKS:
        pack_path = fetch_pack(opener, slug, upload_name, filename)
        if slug == "downtown-city-megakit":
            city = pack_path
        elif slug == "modular-sci-fi-megakit":
            scifi = pack_path
        elif slug == "sci-fi-essentials-kit":
            essentials = pack_path
        elif slug == "lowpoly-spaceships":
            spaceships = pack_path
    if city is None:
        raise RuntimeError("City pack missing")
    if scifi is None or essentials is None or spaceships is None:
        raise RuntimeError("Sci-fi asset packs missing")
    extract_models(city, MODEL_DIR, {"Building_Large_2", "Building_Small_1"}, "Exports/glTF (Godot)/")
    extract_models(essentials, SCIFI_MODEL_DIR, {"Prop_Crate_Large"}, "glTF/")
    extract_obj_pack(spaceships, SHIP_MODEL_DIR)


if __name__ == "__main__":
    main()
