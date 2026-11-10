"""Fetch official Godot 4.7.2 templates, verify SHA512, install Windows/Web only."""
import hashlib
import os
from pathlib import Path
import shutil
import tempfile
import urllib.request
import zipfile

VERSION = "4.7.2"
NAME = f"Godot_v{VERSION}-stable_export_templates.tpz"
BASE = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable"
archive = Path(tempfile.gettempdir()) / ("kittyhm-" + NAME)
target = Path(os.environ["APPDATA"]) / "Godot/export_templates" / f"{VERSION}.stable"
checksums = urllib.request.urlopen(f"{BASE}/SHA512-SUMS.txt").read().decode()
expected = next(line.split()[0] for line in checksums.splitlines() if line.strip().endswith(NAME))
if not archive.exists():
    print(f"Downloading official {NAME}", flush=True)
    with urllib.request.urlopen(f"{BASE}/{NAME}") as response, archive.open("wb") as stream:
        total = 0
        reported = 0
        while block := response.read(1024 * 1024):
            stream.write(block)
            total += len(block)
            if total - reported >= 64 * 1024 * 1024:
                print(f"Downloaded {total // 1024 // 1024} MiB", flush=True)
                reported = total
with archive.open("rb") as stream:
    actual = hashlib.file_digest(stream, "sha512").hexdigest()
if actual.lower() != expected.lower():
    raise RuntimeError(f"SHA512 mismatch; remove the incomplete archive and retry: {archive}")
target.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(archive) as bundle:
    for entry in bundle.infolist():
        name = Path(entry.filename).name
        if name == "version.txt" or (name.startswith("windows_") and name.endswith("x86_64.exe")) or (name.startswith("web_") and name.endswith(".zip")):
            with bundle.open(entry) as source, (target/name).open("wb") as output:
                shutil.copyfileobj(source, output)
            print(f"Installed {name}", flush=True)
print(f"Verified and installed to {target}", flush=True)
