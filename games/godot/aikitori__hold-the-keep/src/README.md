# Hold the Keep

Isometrisches Tower Defense im Mittelalter, angelehnt an die Tower-Defense-Karten aus Warcraft III.
Die Toten ziehen vom Friedhof zur Burg. Du baust Türme und Mauern, legst daraus Labyrinthe und hältst
30 Wellen lang durch.

**Im Browser spielen:** https://aikitori.github.io/hold-the-keep/
**Android:** Debug-APK unter [Releases](https://github.com/aikitori/hold-the-keep/releases)

## So wird gespielt

- Unten einen Turm wählen, dann auf ein Grasfeld tippen. Mit Maus: Vorschau beim Darüberfahren, Klick baut.
  Auf dem Handy: erster Tipp zeigt die Vorschau, zweiter Tipp auf dasselbe Feld baut.
- Ziehen verschiebt die Karte, Mausrad oder zwei Finger zoomen. Rechtsklick oder Esc bricht ab.
- Der Weg zur Burg darf nie ganz versperrt werden, aber er darf so lang werden, wie du willst.
- Fliegende Gegner (Geister) nehmen den geraden Weg über alles hinweg. Nicht jeder Turm trifft sie.
- Turm antippen: ausbauen (Stufe 1 bis 3), auf Stufe 3 eine von zwei Spezialisierungen wählen, abreißen.
- "Nächste Welle" holt die Welle früher und gibt Bonus-Gold. "Ton an/aus" schaltet die Klänge.
- Auf Handy und Tablet ist die Oberfläche größer, im Hochformat steht die Bauleiste in zwei Reihen.

## Karten

| Karte | Idee |
|---|---|
| Vier Felder | Vier Baufelder, verbunden durch feste Wege, jedes will sein eigenes Labyrinth |
| Rundlauf | Eine Runde um eine Hochfläche über vier Kontrollpunkte (wie Circle TD) |
| Schlangenpfad | Fester Weg in Schleifen, gebaut wird daneben auf der Hochfläche |
| Weites Feld | Offenes Feld, Kontrollpunkte schicken die Gegner mehrfach quer hindurch |

## Entwicklung

Godot 4.7.2 (GDScript), Renderer "Kompatibilität" (läuft auf Android und im Browser). Details für
Mitarbeitende in [CLAUDE.md](CLAUDE.md), Spielregeln in [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md).

```bash
godot --headless --import
godot --headless res://scenes/dev/logic_test.tscn   # Test ohne Fenster
godot res://scenes/menu.tscn                         # Spielen
```

## Lizenz

GNU General Public License v3.0 (GPL-3.0-or-later), siehe [LICENSE](LICENSE). Copyright (C) 2026 aikitori.

3D-Modelle: [Kenney](https://kenney.nl) (CC0), Tower Defense Kit, Castle Kit, Mini Dungeon und Graveyard Kit
(Lizenztexte in `assets/models/*/License.txt`). Schrift: MedievalSharp von wmk69, SIL Open Font License
(`assets/fonts/OFL.txt`). Klänge (CC0): Kenney (RPG Audio, Impact Sounds, Interface Sounds, Music Jingles)
und rubberduck auf OpenGameArt (80 CC0 RPG SFX, 100 CC0 SFX), Quellen in `tools/import_sfx.py`.
