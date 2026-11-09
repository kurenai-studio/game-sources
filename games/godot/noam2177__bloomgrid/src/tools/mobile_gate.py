"""Static mobile + security gate for BloomGrid (no Godot required).

Run: py -3 tools/mobile_gate.py
ponytail: regex scan only; upgrade path = Semgrep CI on gd/java.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

RISKY_GD = re.compile(
    r"HTTPRequest|TCP_Server|UDPServer|OS\.execute|OS\.create_process|"
    r'load\("res://.*http|ProjectSettings\.set_setting\("network',
    re.I,
)
# Allow https in test strings and sanitize_name checks.
ALLOW_LINE = re.compile(r"sanitize_name|#|test", re.I)


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def check_project_godot() -> list[str]:
    text = _read(ROOT / "project.godot")
    need = [
        ("720", "window/size/viewport_width=720"),
        ("1280", "window/size/viewport_height=1280"),
        ("mobile renderer", 'renderer/rendering_method="mobile"'),
        ("etc2_astc", "textures/vram_compression/import_etc2_astc=true"),
        ("Mobile feature", '"Mobile"'),
        ("portrait", "window/handheld/orientation=1"),
    ]
    return [f"project.godot missing {label}" for label, frag in need if frag not in text]


def check_android_export() -> list[str]:
    text = _read(ROOT / "export_presets.cfg")
    errs: list[str] = []
    if "permissions/internet=false" not in text:
        errs.append("export_presets: INTERNET not explicitly false")
    if "permissions/access_network_state=false" not in text:
        errs.append("export_presets: ACCESS_NETWORK_STATE not explicitly false")
    if "gradle_build/target_sdk=\"36\"" not in text:
        errs.append("export_presets: target_sdk 36 not found")
    if "Android Debug APK" not in text:
        errs.append("export_presets: missing Android Debug APK preset")
    if "name=\"Android\"" not in text:
        errs.append("export_presets: missing Android AAB preset")
    return errs


def check_gd_sources() -> list[str]:
    errs: list[str] = []
    for path in ROOT.rglob("*.gd"):
        if ".godot" in path.parts:
            continue
        rel = path.relative_to(ROOT)
        for i, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            if ALLOW_LINE.search(line):
                continue
            if "http://" in line or "https://" in line:
                errs.append(f"{rel}:{i}: URL in source")
            if RISKY_GD.search(line):
                errs.append(f"{rel}:{i}: risky API {line.strip()[:80]}")
    return errs


def check_secrets() -> list[str]:
    errs: list[str] = []
    for name in (".env", ".env.local"):
        if (ROOT / name).is_file():
            errs.append(f"secret file present: {name}")
    for path in ROOT.rglob("*.keystore"):
        errs.append(f"keystore in tree: {path.relative_to(ROOT)}")
    return errs


def check_layout_module() -> list[str]:
    p = ROOT / "game" / "layout_fit.gd"
    if not p.is_file():
        return ["game/layout_fit.gd missing"]
    text = _read(p)
    if "class_name LayoutFit" not in text:
        return ["layout_fit.gd: no LayoutFit class"]
    return []


def main() -> None:
    checks = [
        ("project.godot mobile/display", check_project_godot),
        ("android export policy", check_android_export),
        ("gdscript network/shell surface", check_gd_sources),
        ("secrets/keystore", check_secrets),
        ("layout_fit module", check_layout_module),
    ]
    failed = 0
    for title, fn in checks:
        errs = fn()
        if errs:
            failed += len(errs)
            print(f"FAIL {title}")
            for e in errs:
                print(f"  - {e}")
        else:
            print(f"OK   {title}")
    print(f"BLOOMGRID_MOBILE_GATE failed={failed}")
    raise SystemExit(1 if failed else 0)


if __name__ == "__main__":
    main()
