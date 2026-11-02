"""Create packaging/icon.png: the duck image centered on a transparent square.

Run once after changing the duck image: ``python packaging/make_icon.py``.
"""

from pathlib import Path

from PIL import Image

ICON_SIZE = 1024
HERE = Path(__file__).parent
DUCK_IMAGE = HERE.parent / "src" / "duck_attack" / "assets" / "images" / "duck.png"


def main() -> None:
    duck = Image.open(DUCK_IMAGE).convert("RGBA")
    duck.thumbnail((ICON_SIZE, ICON_SIZE), Image.Resampling.LANCZOS)
    icon = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    icon.paste(duck, ((ICON_SIZE - duck.width) // 2, (ICON_SIZE - duck.height) // 2), duck)
    icon.save(HERE / "icon.png")


if __name__ == "__main__":
    main()
