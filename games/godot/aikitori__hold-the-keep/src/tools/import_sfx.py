#!/usr/bin/env python3
"""Klänge fürs Spiel: CC0-Rohdateien aus tools/sfx_src zuschneiden, angleichen und als OGG ablegen.

    python3 tools/import_sfx.py [PAKETE]

Mit PAKETE (Ordner mit den entpackten Soundpaketen) werden die ausgewählten Rohdateien vorher nach
tools/sfx_src kopiert. Quellen (alle CC0):
  kenney-rpg      https://kenney.nl/assets/rpg-audio
  kenney-impact   https://kenney.nl/assets/impact-sounds
  kenney-ui       https://kenney.nl/assets/interface-sounds
  kenney-jingles  https://kenney.nl/assets/music-jingles
  rd-rpg          https://opengameart.org/content/80-cc0-rpg-sfx (rubberduck)
  rd-100          https://opengameart.org/content/100-cc0-sfx (rubberduck)
Braucht ffmpeg.
"""
import glob
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'tools', 'sfx_src')
OUT = os.path.join(ROOT, 'assets', 'audio')

PACKS = {
    'kenney-rpg': 'rpg-audio',
    'kenney-impact': 'impact-sounds',
    'kenney-ui': 'interface-sounds',
    'kenney-jingles': 'music-jingles',
    'rd-rpg': '80-CC0-RPG-SFX_0',
    'rd-100': '100-CC0-SFX_0',
}

# Klang im Spiel: (Paket, Datei ohne Endung, längste Dauer in Sekunden)
SOUNDS = {
    # Türme
    'arrow': ('kenney-rpg', 'drawKnife1', 0.5),          # Schütze, Bogenturm
    'bolt': ('kenney-impact', 'impactPlank_medium_000', 0.6),  # Balliste
    'throw': ('kenney-rpg', 'creak1', 0.7),              # Katapult, Trebuchet
    'fire': ('rd-rpg', 'spell_fire_01', 0.9),            # Himmelswacht
    'magic': ('rd-rpg', 'spell_01', 0.8),                # Magierturm
    'lightning': ('rd-rpg', 'spell_02', 0.8),            # Blitzmagier
    'stab': ('kenney-rpg', 'knifeSlice', 0.5),           # Speerträger
    # Treffer
    'hit': ('kenney-impact', 'impactPunch_medium_000', 0.4),
    'crash': ('rd-rpg', 'stones_01', 1.0),               # Felsbrocken schlägt ein
    'burst': ('rd-rpg', 'spell_fire_04', 1.0),           # Brandtopf
    # Gegner
    'die': ('rd-rpg', 'creature_hurt_01', 0.7),
    'bones': ('kenney-impact', 'impactWood_light_002', 0.4),  # Skelett zerfällt
    'ghost': ('rd-rpg', 'creature_misc_02', 0.8),
    'boss': ('rd-rpg', 'creature_roar_01', 1.6),
    'boss_die': ('rd-rpg', 'creature_die_01', 1.6),
    'keep_hit': ('kenney-impact', 'impactBell_heavy_000', 1.5),
    # Bauen und Oberfläche
    'build': ('kenney-impact', 'impactWood_heavy_000', 0.6),
    'upgrade': ('kenney-rpg', 'metalLatch', 0.5),
    'spec': ('rd-rpg', 'item_gem_01', 0.9),
    'sell': ('kenney-rpg', 'handleCoins', 0.9),
    'coins': ('rd-rpg', 'item_coins_01', 0.8),           # Bonus für frühe Welle
    'error': ('kenney-ui', 'error_004', 0.5),
    'click': ('kenney-ui', 'select_002', 0.3),
    # Ablauf
    'wave': ('rd-100', 'gong_01', 2.5),
    'victory': ('kenney-jingles', 'jingles_PIZZI01', 3.0),
    'defeat': ('kenney-jingles', 'jingles_PIZZI03', 3.0),
}


def copy_raw(packs: str) -> None:
    os.makedirs(SRC, exist_ok=True)
    for pack, name, _ in SOUNDS.values():
        found = glob.glob(os.path.join(packs, PACKS[pack], '**', name + '.ogg'), recursive=True)
        if not found:
            sys.exit(f'nicht gefunden: {pack}/{name}')
        shutil.copy(found[0], os.path.join(SRC, f'{pack}_{name}.ogg'))


def peak_db(path: str, filters: str) -> float:
    run = subprocess.run(['ffmpeg', '-hide_banner', '-i', path, '-af', filters + ',volumedetect', '-f', 'null', '-'],
                         capture_output=True, text=True, check=True)
    return float(re.search(r'max_volume: (-?[\d.]+) dB', run.stderr).group(1))


def convert(pack: str, name: str, longest: float, target: str) -> None:
    source = os.path.join(SRC, f'{pack}_{name}.ogg')
    # Stille vorn weg, auf die Höchstdauer kürzen, kurz ausblenden, auf -1,5 dB Spitze angleichen.
    trim = (f'silenceremove=start_periods=1:start_threshold=-45dB,atrim=0:{longest},'
            f'afade=t=out:st={max(0.0, longest - 0.12):.2f}:d=0.12')
    gain = -1.5 - peak_db(source, trim)
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', source, '-af', f'{trim},volume={gain:.2f}dB',
                    '-ac', '1', '-ar', '44100', '-c:a', 'libvorbis', '-q:a', '5', target], check=True)


def main() -> None:
    if len(sys.argv) > 1:
        copy_raw(sys.argv[1])
    os.makedirs(OUT, exist_ok=True)
    for sound_id, (pack, name, longest) in SOUNDS.items():
        convert(pack, name, longest, os.path.join(OUT, sound_id + '.ogg'))
    print(len(SOUNDS), 'Klänge in', os.path.relpath(OUT, ROOT))


if __name__ == '__main__':
    main()
