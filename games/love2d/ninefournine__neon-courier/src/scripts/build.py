#!/usr/bin/env python3
"""Build the portable desktop archive locally; never upload or deploy."""
import hashlib
import json
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / "dist"
ALLOWED_ASSETS = {".png", ".jpg", ".jpeg", ".wav", ".ogg", ".ttf", ".otf"}
NOTICE_FILES = {"LICENSE.txt", "ASSET_LICENSE.txt", "CREDITS.md", "ASSET_PROVENANCE.md", "LICENSING.md"}

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def write_zip(target, entries):
    """Stable ordering/timestamps/permissions; symlinks and outsiders never enter."""
    target.parent.mkdir(parents=True, exist_ok=True)
    # Replacing atomically keeps a concurrently running packaged game on its
    # existing archive inode, with no half-written ZIP exposed to new launches.
    with tempfile.NamedTemporaryFile(prefix=target.name + ".", suffix=".tmp", dir=target.parent, delete=False) as handle:
        temporary = Path(handle.name)
    try:
        with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
            for name, data, executable in sorted(entries):
                info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
                info.create_system = 3
                info.external_attr = (0o100755 if executable else 0o100644) << 16
                info.compress_type = zipfile.ZIP_DEFLATED
                archive.writestr(info, data, compresslevel=9)
        temporary.replace(target)
    finally:
        if temporary.exists(): temporary.unlink()

def source_entries():
    files = [ROOT / "main.lua", ROOT / "conf.lua"]
    if not all(path.is_file() for path in files):
        raise SystemExit("Missing main.lua/conf.lua: the source game must exist before packaging.")
    notices = [ROOT / name for name in sorted(NOTICE_FILES)]
    if not all(path.is_file() for path in notices):
        raise SystemExit("Missing license/attribution notice: restore the release notices before packaging.")
    files += notices
    files += sorted((ROOT / "game").rglob("*.lua"))
    files += sorted(path for path in (ROOT / "assets").rglob("*") if path.is_file() and path.suffix.lower() in ALLOWED_ASSETS)
    entries = []
    for path in files:
        if path.is_symlink() or not path.resolve().is_relative_to(ROOT):
            raise SystemExit(f"Refusing a symlink/outside file: {path}")
        entries.append((path.relative_to(ROOT).as_posix(), path.read_bytes(), False))
    return entries

def build_love():
    target = DIST / "neon-courier.love"
    entries = source_entries()
    write_zip(target, entries)
    with zipfile.ZipFile(target) as archive:
        names = archive.namelist()
        assert "main.lua" in names and "conf.lua" in names
        assert all(name in {"main.lua", "conf.lua"} | NOTICE_FILES or name.startswith(("game/", "assets/")) for name in names)
        assert archive.testzip() is None
    return target, entries

def main():
    love_file, entries = build_love()
    manifest = {"source_files": [{"path": name, "sha256": hashlib.sha256(data).hexdigest()} for name, data, _ in entries],
                "artifacts": {love_file.relative_to(ROOT).as_posix(): sha(love_file)},
                "zip_timestamps": "1980-01-01T00:00:00", "public_release": False}
    (DIST / "BUILD_MANIFEST.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Built {love_file.relative_to(ROOT)} ({love_file.stat().st_size} bytes), SHA256 {sha(love_file)}")

if __name__ == "__main__":
    main()
