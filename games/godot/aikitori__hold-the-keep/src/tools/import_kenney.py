#!/usr/bin/env python3
"""Kopiert die verwendeten 3D-Modelle aus den Kenney-Paketen (CC0) nach assets/models/<paket>/.

Aufruf: python3 tools/import_kenney.py <Ordner mit den entpackten Paketen>
Erwartet darin die Ordner kenney_tower-defense-kit (oder tdkit), kenney_castle-kit, kenney_mini-dungeon und
kenney_graveyard-kit_5.0, so wie sie aus den ZIP-Dateien von kenney.nl kommen. Jedes Paket hat eine eigene
Farbtextur (Textures/colormap.png), deshalb bekommt jedes Paket seinen eigenen Ordner.
"""
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Zielordner -> (mögliche Paketordner, Modelle)
MODELS = {
    'td': (['kenney_tower-defense-kit', 'tdkit'], [
        'tile', 'tile-dirt', 'tile-tree', 'tile-tree-double', 'tile-tree-quad', 'tile-rock', 'tile-crystal',
        'tile-hill', 'detail-rocks', 'detail-tree', 'detail-tree-large', 'weapon-ammo-arrow', 'weapon-ammo-boulder',
        'weapon-ammo-cannonball', 'selection-a',
    ]),
    'castle': (['kenney_castle-kit'], [
        'wall', 'wall-half', 'tower-square-base', 'tower-square-mid', 'tower-square-top', 'tower-square-roof',
        'tower-square-mid-windows', 'tower-hexagon-base', 'tower-hexagon-mid', 'tower-hexagon-top',
        'tower-hexagon-roof', 'tower-base', 'tower-top', 'siege-ballista', 'siege-catapult', 'siege-trebuchet',
        'flag', 'flag-banner-long', 'flag-pennant', 'tree-small', 'tree-large', 'rocks-small', 'rocks-large',
        'gate', 'tower-square-top-roof-rounded', 'tower-slant-roof',
    ]),
    'dungeon': (['kenney_mini-dungeon'], ['character-orc', 'character-human', 'barrel', 'banner', 'weapon-spear',
                                         'weapon-sword', 'shield-round']),
    'graveyard': (['kenney_graveyard-kit_5.0'], [
        'character-skeleton', 'character-zombie', 'character-ghost', 'character-vampire', 'character-keeper',
        'crypt', 'gravestone-cross', 'gravestone-round', 'gravestone-broken', 'pine', 'pine-crooked',
        'lantern-candle', 'iron-fence', 'fire-basket',
    ]),
}


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    source = Path(sys.argv[1])
    for target, (folders, names) in MODELS.items():
        pack = next((source / f for f in folders if (source / f).is_dir()), None)
        if pack is None:
            sys.exit(f'Paket für {target} fehlt in {source} (erwartet: {", ".join(folders)})')
        glb = pack / 'Models' / 'GLB format'
        out = ROOT / 'assets' / 'models' / target
        (out / 'Textures').mkdir(parents=True, exist_ok=True)
        shutil.copy(glb / 'Textures' / 'colormap.png', out / 'Textures' / 'colormap.png')
        for name in names:
            shutil.copy(glb / f'{name}.glb', out / f'{name}.glb')
        license_file = pack / 'License.txt'
        if license_file.exists():
            shutil.copy(license_file, out / 'License.txt')
        print(f'{target}: {len(names)} Modelle')


if __name__ == '__main__':
    main()
