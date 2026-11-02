# PyInstaller build for Windows (dist/DuckAttack/) and macOS (dist/DuckAttack.app).
# Run from the repo root: pyinstaller packaging/duck_attack.spec --noconfirm
import sys
import tomllib
from pathlib import Path

ROOT = Path(SPECPATH).parent
VERSION = tomllib.loads((ROOT / "pyproject.toml").read_text())["project"]["version"]
ICON = str(Path(SPECPATH) / "icon.png")

a = Analysis(
    [str(Path(SPECPATH) / "launcher.py")],
    pathex=[str(ROOT / "src")],
    # The game finds its assets next to settings.py (settings.ASSETS_DIR).
    datas=[(str(ROOT / "src" / "duck_attack" / "assets"), "duck_attack/assets")],
)
pyz = PYZ(a.pure)
exe = EXE(
    pyz,
    a.scripts,
    exclude_binaries=True,
    name="DuckAttack",
    console=False,
    icon=ICON,
)
coll = COLLECT(exe, a.binaries, a.datas, name="DuckAttack")

if sys.platform == "darwin":
    app = BUNDLE(
        coll,
        name="DuckAttack.app",
        icon=ICON,
        bundle_identifier="io.github.steffenmueller4.duck-attack",
        version=VERSION,
        info_plist={
            "CFBundleDisplayName": "Duck Attack",
            "CFBundleShortVersionString": VERSION,
            "NSHighResolutionCapable": True,
        },
    )
