"""Fetches the lofi music from Pixabay into tools/music_source/ (kept out of git).

Each track was chosen for its place: steady, upbeat beats for the events (the
athletes bounce to them, so tools/make_music.py measures each one's beat),
chill ones for the title and the menus, bright ones for the medal ceremony.
Every one was checked on its own page not to be labelled AI generated, and is
free to use in a game under the Pixabay Content License (no credit required;
credited in data/music.json and on the credits anyway).

Run:  python tools/fetch_music.py            fetch what's missing
      python tools/fetch_music.py --sizes    just report each file's size
"""

import sys
import time
import urllib.request
from pathlib import Path

OUT = Path(__file__).resolve().parent / "music_source"
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/130.0 Safari/537.36")
CDN = "https://cdn.pixabay.com/download/audio/"

# (set, file name, title, artist, page, file on Pixabay's download server)
TRACKS = [
    ("events", "boom_bap", "Jazzy Hip Hop Boom Bap", "Music_Unlimited",
     "https://pixabay.com/music/beats-jazzy-hip-hop-boom-bap-111861/",
     "2022/05/23/audio_c3a26f5c62.mp3?filename=music_unlimited-jazzy-hip-hop-boom-bap-111861.mp3"),
    ("events", "lofi_upbeat", "Lofi Upbeat", "Kulakovka",
     "https://pixabay.com/music/old-school-hip-hop-lofi-upbeat-611601/",
     "2026/09/28/audio_e0890e62a9.mp3?filename=kulakovka-lofi-upbeat-611601.mp3"),
    ("events", "hip_hop_upbeat", "Hip Hop - Upbeat", "MusicForPeople",
     "https://pixabay.com/music/beats-hip-hop-upbeat-491996/",
     "2026/03/04/audio_cdc41b47eb.mp3?filename=musicforpeople-hip-hop-upbeat-491996.mp3"),
    ("events", "compass", "Compass / LoFi ChillHop Background Music", "SoulProdMusic",
     "https://pixabay.com/music/beats-compass-lofi-chillhop-background-music-123761/",
     "2022/10/23/audio_83a72fc451.mp3?filename=soulprodmusic-compass-lofi-chillhop-background-music-123761.mp3"),
    ("events", "lofi_study", "Lofi Study - Calm Peaceful Chill Hop", "FASSounds",
     "https://pixabay.com/music/beats-lofi-study-calm-peaceful-chill-hop-112191/",
     "2022/05/27/audio_1808fbf07a.mp3?filename=fassounds-lofi-study-calm-peaceful-chill-hop-112191.mp3"),
    ("events", "soul_hip_hop", "Sad Soul Hip Hop", "AlexGrohl",
     "https://pixabay.com/music/beats-sad-soul-hip-hop-185750/",
     "2024/01/13/audio_640c5ca4a9.mp3?filename=alexgrohl-sad-soul-hip-hop-185750.mp3"),
    ("events", "positive_vibrations", "Positive Vibrations (Funk Chill Beat)", "9JackJack8",
     "https://pixabay.com/music/upbeat-positive-vibrations-funk-chill-beat-427176/",
     "2025/10/28/audio_d5fe5e01a4.mp3?filename=9jackjack8-positive-vibrations-funk-chill-beat-427176.mp3"),
    ("events", "dusty_hip_hop", "Dusty Hip-Hop", "OctoSound",
     "https://pixabay.com/music/old-school-hip-hop-dusty-hip-hop-563901/",
     "2026/07/08/audio_f8e9eca492.mp3?filename=octosound-dusty-hip-hop-563901.mp3"),
    ("title", "retro_80s", "Synthwave Retro 80s", "MondaMusic",
     "https://pixabay.com/music/synthwave-synthwave-retro-80s-491697/",
     "2026/02/26/audio_e726381e90.mp3?filename=mondamusic-synthwave-retro-80s-491697.mp3"),
    ("title", "tokyo_cafe", "Tokyo Cafe", "TVARI",
     "https://pixabay.com/music/beats-tvari-tokyo-cafe-159065/",
     "2023/07/22/audio_720626056a.mp3?filename=tvari-tvari-tokyo-cafe-159065.mp3"),
    ("title", "jazzy_love", "Lo-fi Music Loop - Sentimental Jazzy Love", "Sonican",
     "https://pixabay.com/music/lofi-lo-fi-music-loop-sentimental-jazzy-love-473154/",
     "2026/01/25/audio_1dd7f3126d.mp3?filename=sonican-lo-fi-music-loop-sentimental-jazzy-love-473154.mp3"),
    ("stadium", "background_lofi", "Lofi Hip Hop | Background Lofi Music", "SigmaMusicArt",
     "https://pixabay.com/music/beats-lofi-hip-hop-background-lofi-music-270003/",
     "2024/11/28/audio_cf7d14e3d9.mp3?filename=sigmamusicart-lofi-hip-hop-background-lofi-music-270003.mp3"),
    ("stadium", "good_night", "Good Night - Lofi Cozy Chill Music", "FASSounds",
     "https://pixabay.com/music/beats-good-night-lofi-cozy-chill-music-160166/",
     "2023/07/30/audio_e0908e8569.mp3?filename=fassounds-good-night-lofi-cozy-chill-music-160166.mp3"),
    ("stadium", "once_in_paris", "Once In Paris", "Pumpupthemind",
     "https://pixabay.com/music/beats-once-in-paris-168895/",
     "2023/09/29/audio_0eaceb1002.mp3?filename=pumpupthemind-once-in-paris-168895.mp3"),
    ("ceremony", "happy_lofi", "Happy Lofi", "AtlasAudio",
     "https://pixabay.com/music/beats-happy-lofi-593048/",
     "2026/08/27/audio_287d530bef.mp3?filename=atlasaudio-happy-lofi-593048.mp3"),
    ("ceremony", "lofi_beats", "Lofi Beats", "barbrasbeats",
     "https://pixabay.com/music/happy-childrens-tunes-lofi-beats-165550/",
     "2023/09/07/audio_f8443307ae.mp3?filename=barbrasbeats-lofi-beats-165550.mp3"),
]


def request(url, first_byte_only=False):
    headers = {"User-Agent": UA, "Referer": "https://pixabay.com/", "Origin": "https://pixabay.com"}
    if first_byte_only:
        headers["Range"] = "bytes=0-0"
    return urllib.request.Request(url, headers=headers)


def sizes():
    total = 0
    for _set, name, title, artist, _page, file in TRACKS:
        # ask for the first byte only: the reply says how big the whole file is
        r = urllib.request.urlopen(request(CDN + file, True), timeout=60)
        n = int(r.headers.get("Content-Range", "/0").split("/")[-1] or 0) or int(r.headers.get("Content-Length", 0))
        r.close()                # the size is in the headers: don't read the file
        total += n
        print(f"{n / 1e6:5.1f} MB  {_set:9s} {title} ({artist})")
        time.sleep(0.3)
    print(f"{total / 1e6:5.1f} MB in all, {len(TRACKS)} tracks")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    failed = []
    for _set, name, _title, _artist, _page, file in TRACKS:
        path = OUT / f"{name}.mp3"
        if path.exists() and path.stat().st_size > 100_000:
            print(f"have  {name}")
            continue
        try:
            data = urllib.request.urlopen(request(CDN + file), timeout=120).read()
            path.write_bytes(data)
            print(f"got   {name}  {len(data) / 1e6:.1f} MB", flush=True)
        except Exception as e:   # one failure should not stop the rest
            failed.append(name)
            print(f"FAIL  {name}: {e}", flush=True)
        time.sleep(1.0)          # politely, one at a time
    if failed:
        sys.exit("not fetched: " + ", ".join(failed))


if __name__ == "__main__":
    sizes() if "--sizes" in sys.argv else main()
