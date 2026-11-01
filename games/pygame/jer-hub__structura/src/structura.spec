# PyInstaller build for the Windows executable. Run from the repo root:
#     .venv\Scripts\pyinstaller --noconfirm structura.spec
# Output: dist\Structura.exe, one file that runs without installing.
import sys
from pathlib import Path

sys.path.insert(0, str(Path(SPECPATH) / "src"))
from structura import bundle  # noqa: E402

a = Analysis(
    ["packaging/launch.py"],
    pathex=["src"],
    datas=bundle.pyinstaller_datas(),
    excludes=["pytest"],
)
pyz = PYZ(a.pure)
exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    name="Structura",
    console=False,
    upx=False,
)
