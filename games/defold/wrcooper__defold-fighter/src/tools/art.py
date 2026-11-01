"""LibreSprite <-> Defold art pipeline.

    python tools/art.py import   # assets/images/*.png sequences -> art/**/*.ase
    python tools/art.py export   # art/**/*.ase -> assets/images/*.png + assets/game.atlas
    python tools/art.py atlas    # only rebuild assets/game.atlas from assets/images

Workflow: edit the .ase files in art/ with LibreSprite (one file per
animation, one frame per animation frame), then run `export`. The game picks
frames by name (<character>_<anim>_<n>), so keep the frame count of an
animation in step with its frame list in modules/characters.lua.

LibreSprite is looked up in $LIBRESPRITE, then ~/Tools/LibreSprite.
"""
import glob
import os
import re
import shutil
import subprocess
import sys
import tempfile
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMAGES = os.path.join(ROOT, "assets", "images")
ART = os.path.join(ROOT, "art")
ATLAS = os.path.join(ROOT, "assets", "game.atlas")


def libresprite():
    exe = os.environ.get("LIBRESPRITE") or os.path.join(os.path.expanduser("~"), "Tools", "LibreSprite", "libresprite.exe")
    if not os.path.isfile(exe):
        sys.exit("LibreSprite not found at %s (set LIBRESPRITE to its executable)" % exe)
    return exe


def run(args, cwd):
    subprocess.run([libresprite(), "-b"] + args, cwd=cwd, check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def sequences():
    """{(subdir, base): [frame pngs in order]} e.g. ("kenji", "kenji_walk")."""
    seqs = defaultdict(list)
    for path in glob.glob(os.path.join(IMAGES, "*", "*.png")):
        sub = os.path.basename(os.path.dirname(path))
        name = os.path.splitext(os.path.basename(path))[0]
        m = re.match(r"^(.*)_(\d+)$", name)
        base, idx = (m.group(1), int(m.group(2))) if m else (name, -1)
        seqs[(sub, base)].append((idx, path))
    return {k: [p for _, p in sorted(v)] for k, v in seqs.items()}


def cmd_import():
    count = 0
    for (sub, base), frames in sorted(sequences().items()):
        out_dir = os.path.join(ART, sub)
        os.makedirs(out_dir, exist_ok=True)
        out = os.path.join(out_dir, base + ".ase")
        # LibreSprite loads a numbered file as a sequence when its siblings are next to it
        with tempfile.TemporaryDirectory() as tmp:
            for f in frames:
                shutil.copy(f, tmp)
            run([os.path.basename(frames[0]), "--save-as", out], tmp)
        count += 1
    print("wrote %d .ase files to %s" % (count, ART))


def cmd_export():
    count = 0
    for ase in sorted(glob.glob(os.path.join(ART, "*", "*.ase"))):
        sub = os.path.basename(os.path.dirname(ase))
        base = os.path.splitext(os.path.basename(ase))[0]
        out_dir = os.path.join(IMAGES, sub)
        os.makedirs(out_dir, exist_ok=True)
        numbered = base not in ("shadow", "pixel", "stage_bg")
        for old in glob.glob(os.path.join(out_dir, base + ("_[0-9]*.png" if numbered else ".png"))):
            os.remove(old)
        # "name_0.png" makes LibreSprite number frames name_0, name_1, ...
        target = base + ("_0.png" if numbered else ".png")
        run([ase, "--save-as", os.path.join(out_dir, target)], ROOT)
        count += 1
    print("exported %d animations" % count)
    cmd_atlas()


def cmd_atlas():
    entries = []
    for path in sorted(glob.glob(os.path.join(IMAGES, "*", "*.png"))):
        rel = os.path.relpath(path, ROOT).replace(os.sep, "/")
        entries.append('images {\n  image: "/%s"\n  sprite_trim_mode: SPRITE_TRIM_MODE_OFF\n}\n' % rel)
    with open(ATLAS, "w", newline="\n") as f:
        f.write("".join(entries))
        f.write("margin: 0\nextrude_borders: 2\ninner_padding: 0\n")
    print("atlas: %d images" % len(entries))


if __name__ == "__main__":
    cmds = {"import": cmd_import, "export": cmd_export, "atlas": cmd_atlas}
    if len(sys.argv) != 2 or sys.argv[1] not in cmds:
        sys.exit(__doc__)
    cmds[sys.argv[1]]()
