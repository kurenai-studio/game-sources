**Français** · [English](#english)

# Civilisations

Bac à sable divin en temps réel (pygame) : trois civilisations évoluent du Moyen-Âge à nos jours (année finale 2026) sur une carte de 240×150 cases, avec ères, technologies, gouvernements, saisons, météo, catastrophes, armées et individus dotés d'une IA propre.

## Lancer
```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
./lancer.sh            # ou : .venv/bin/python main.py
```

## Commandes
| Touche | Action |
|---|---|
| `Espace` | pause / reprise |
| `1` à `6` | vitesse de simulation |
| `Tab` | civilisation suivante |
| `F` | suivre / ne plus suivre |
| `N` | afficher / masquer les noms |
| `W A S D` ou flèches | déplacer la vue |
| Molette | zoom centré sur le curseur (sur la carte) |
| `F11` | plein écran |
| `Échap` | quitter |

Fichiers : `sim.py` (moteur de simulation), `gfx.py` (rendu), `main.py` (interface et boucle).

## Licence
[MIT](LICENSE).

---

# English

# Civilisations

A real-time god-game sandbox (pygame): three civilizations evolve from the Middle Ages to the present day (end year 2026) on a 240×150 tile map, with eras, technologies, governments, seasons, weather, disasters, armies and individuals driven by their own AI.

## Run
```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
./lancer.sh            # or: .venv/bin/python main.py
```

## Controls
| Key | Action |
|---|---|
| `Space` | pause / resume |
| `1` to `6` | simulation speed |
| `Tab` | next civilization |
| `F` | follow / stop following |
| `N` | show / hide names |
| `W A S D` or arrows | move the view |
| Mouse wheel | zoom around the cursor (over the map) |
| `F11` | fullscreen |
| `Esc` | quit |

Files: `sim.py` (simulation engine), `gfx.py` (rendering), `main.py` (interface and loop).

## License
[MIT](LICENSE).
