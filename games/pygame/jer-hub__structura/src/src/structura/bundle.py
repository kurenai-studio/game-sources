"""Where the game's data folders are, whether it runs from source, installed, or as the Windows build."""
from __future__ import annotations

import sys
from dataclasses import dataclass
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent


@dataclass(frozen=True)
class Folder:
    """A data folder inside the structura package."""
    path: str

    def source(self) -> Path:
        return PACKAGE / self.path

    @property
    def dest(self) -> str:
        """Where the Windows build puts it, relative to the build's root."""
        return f"structura/{self.path}"


ZONES = Folder("content/zones")
SNIPPETS = Folder("codemirror/snippets")
FOLDERS = (ZONES, SNIPPETS)


def locate(folder: Folder) -> Path:
    root = getattr(sys, "_MEIPASS", None)
    return Path(root) / folder.dest if root else folder.source()


def pyinstaller_datas() -> list[tuple[str, str]]:
    """What structura.spec bundles: (folder on disk, where it goes in the build)."""
    return [(str(f.source()), f.dest) for f in FOLDERS]
