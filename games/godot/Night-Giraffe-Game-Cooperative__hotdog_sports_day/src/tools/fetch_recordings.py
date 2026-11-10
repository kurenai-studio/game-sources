"""Fetches the real instrument recordings tools/gen_audio.py builds sounds from.

From the Versilian Community Sample Library (VCSL), CC0 (public domain):
https://github.com/sgossner/VCSL. Only the notes the game needs, into
tools/recordings/vcsl/<instrument>/ (kept out of git; about 100 MB). The
game itself ships only the short sounds made from them.

Run:  python tools/fetch_recordings.py
"""

import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

REPO = "sgossner/VCSL"
BRANCH = "master"
OUT = Path(__file__).resolve().parent / "recordings" / "vcsl"

# instrument folder name -> (path fragment in the library, file name filter)
WANT = {
    "harp": ("Composite Chordophones/Concert Harp", lambda n: "_mf1" in n),
    "piano": ("Zithers/Upright Piano, Yamaha", lambda n: "_Sus_" in n and "_vl2_rr1" in n),
    "glockenspiel": ("Struck Idiophones/Glockenspiel", lambda n: "_medium_" in n or "_soft_" in n),
    "marimba": ("Struck Idiophones/Marimba", lambda n: "_med_" in n),
    "kalimba": ("Plucked Idiophones/Kalimba, Tanzania", lambda n: True),
    "hand_chimes": ("Struck Idiophones/Hand Chimes", lambda n: True),
    "wind_chimes": ("Struck Idiophones/Mark Trees", lambda n: "asc1" in n.lower() or "desc1" in n.lower()),
    "sleigh_bells": ("Struck Idiophones/Sleigh Bells", lambda n: True),
    "woodblock": ("Struck Idiophones/Woodblock", lambda n: True),
}


def main():
    tree = json.load(urllib.request.urlopen(
        f"https://api.github.com/repos/{REPO}/git/trees/{BRANCH}?recursive=1"))["tree"]
    total = 0
    for inst, (frag, keep) in WANT.items():
        files = [t for t in tree if t["type"] == "blob" and f"/{frag}/" in "/" + t["path"]
                 and t["path"].lower().endswith(".wav") and keep(t["path"].split("/")[-1])]
        dest = OUT / inst
        dest.mkdir(parents=True, exist_ok=True)
        for t in files:
            name = t["path"].split("/")[-1]
            path = dest / name
            total += t["size"]
            if path.exists() and path.stat().st_size == t["size"]:
                continue
            url = f"https://raw.githubusercontent.com/{REPO}/{BRANCH}/" + urllib.parse.quote(t["path"])
            path.write_bytes(urllib.request.urlopen(url).read())
        print(f"{inst:13s} {len(files):3d} files", flush=True)
    print(f"total {total / 1e6:.0f} MB in {OUT}")
    if total == 0:
        sys.exit("nothing found: has the library moved?")


if __name__ == "__main__":
    main()
