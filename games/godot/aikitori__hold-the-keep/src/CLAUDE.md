# Hold the Keep

Isometrisches Tower Defense im Mittelalter in **Godot 4.7.2** (GDScript, 3D mit Orthokamera), Renderer
`gl_compatibility`, 1280x720 (stretch `canvas_items`, `expand`). Ziele: Android (Debug-APK als Alpha-Release),
Browser (GitHub Pages). Sprache in Code und Oberfläche: Deutsch, Titel Englisch. Lizenz: GPL v3.

Spielregeln und Werte: `docs/GAME_DESIGN.md`.

## Aufbau

- `scenes/menu.tscn` (`scripts/menu.gd`): Kartenwahl, setzt `Main.map_id`. Hauptszene ist das Menü.
  Kartenvorschau gezeichnet in `scripts/map_preview.gd` (`MapPreview`).
- `scenes/main.tscn` (`scripts/main.gd`, `class_name Main`): baut die Karte (Kacheln per MultiMesh), Wellen,
  Gold, Leben, Eingabe (Maus und Touch getrennt, emulierte Mausereignisse werden ignoriert).
- `scripts/map_data.gd`: Karten als Text (`MAPS`, Reihenfolge im Menü `ORDER`). Zeichen siehe Kopfkommentar.
  Kontrollpunkte 1 bis 9 laufen die Gegner der Reihe nach ab, dann die Burg (`waypoints`).
- `scripts/board.gd`: Wegfindung (AStarGrid2D, schräg nur ohne Ecken schneiden), Bauregeln (`check_build`:
  kein Abschnitt darf versperrt, kein Gegner eingesperrt werden), Abschnittslängen für die Zielwahl.
- `scripts/defs.gd`: alle Werte: `TOWERS`, `SPECS` (zwei Spezialisierungen je Turm auf Stufe 3), `ENEMIES`
  (Varianten derselben Figur über `tint`, `size`, `armor`, `regen`, `pack`), Wellen (`wave`, gemischt ab Welle 6).
- `scripts/tower.gd`, `enemy.gd`, `projectile.gd`: Türme (Modell aus Teilen oder Figur), Gegner (Abschnitt für
  Abschnitt, Fliegende auf fester Flugroute), Geschosse (Pfeil, Bolzen, Fels im Bogen, Magie, Feuer, Kettenblitz).
- `scripts/hud.gd`: Oberfläche im Code gebaut (Holz und Pergament, `Hud.make_theme()`), Turmbilder per
  SubViewport, Lebensbalken als 2D-Overlay.
- `scripts/sfx.gd` (Autoload `Sfx`): Klänge aus `assets/audio/`, `Sfx.play(id)` / `Sfx.play_at(id, pos)`,
  Lautstärke je Klang in `VOLUME`, Ton aus in `user://settings.cfg`. Klänge neu erzeugen: Auswahl in
  `tools/import_sfx.py` (`SOUNDS`), Rohdateien in `tools/sfx_src/` (mit `.gdignore`), `python3 tools/import_sfx.py`
  (mit Paketordner als Argument werden die Rohdateien vorher kopiert).
- `scripts/ui_scale.gd` (Autoload `UiScale`): vergrößert die Oberfläche auf Touch-Geräten, `narrow` im
  Hochformat. HUD und Menü hängen an `UiScale.changed`. Am Rechner testen mit `-- --touch-ui` und
  `--resolution 864x1920`.
- `scripts/figure.gd` (`Figure.create(key)`): animierte Figur. Skelett-Figuren werden beim ersten Gebrauch
  in Einzelbilder umgerechnet (Autoload `FigureStage` als Platz im Szenenbaum), weil Skinning auf manchen
  Handy-Browsern unsichtbar bleibt. Headless bleibt das Originalmodell.
- `scripts/path_view.gd`: Pfeilspur des Gegnerwegs, Vorschau beim Bauen über `Board.full_path_with`.
- `scripts/camera_rig.gd`: isometrische Orthokamera (45°, 35,26° von oben), Verschieben und Zoomen.

## Inhalte

- 3D-Modelle von Kenney (CC0) in `assets/models/<paket>/` mit eigener `Textures/colormap.png` je Paket.
  Neue Modelle: Liste in `tools/import_kenney.py` ergänzen, Pakete von kenney.nl entpacken,
  `python3 tools/import_kenney.py <Ordner>`. Modelle laden über `Models.make("castle/wall")`.
- Belagerungswaffen schauen im Modell nach -x und stehen 0,2 tiefer, Graveyard-Figuren ebenfalls (`lift`).
- Schrift `assets/fonts/MedievalSharp.ttf` (OFL). App-Icons in `assets/icon/` (gerendert mit
  `scenes/dev/shot.tscn -- <Ordner> icon`, dann verkleinert).

## Fallstricke

- **Browser hat keine Systemschrift.** Nur Zeichen aus Latein-1 plus Gedankenstrich und Mittelpunkt.
- **Web-Export ohne Threads.** Schatten und MSAA sind an, auf schwachen Geräten ggf. abschalten.
- Headless-Tests rendern nichts. Screenshots brauchen ein Fenster oder Xvfb, Software-Rendering ist langsam:
  im Screenshot-Skript mit `Engine.time_scale` vorspulen statt viele Bilder abzuwarten.
- **Kein Skinning im Handy-Browser.** Neue Figuren mit Skelett immer über `Figure.create` laden.
- **Boden wirft keinen Schatten** (sonst Schatten-Akne: Streifen und helle Dreiecke).
- Freigegebene Gegner gelten in Godot 4 nicht als `null`: `is_instance_valid` oder `alive` prüfen.
- Versionsnummer: `project.godot` (`config/version`) und `export_presets.cfg` (`version/name`, `version/code`)
  gemeinsam erhöhen.

## Tests

```bash
godot --headless res://scenes/dev/logic_test.tscn   # Wege, Bauregeln, Karten, Ausbau, vier Wellen im Zeitraffer
godot res://scenes/dev/shot.tscn -- <Ordner> <menu|icon|gegner|vier_felder|rundlauf|schlangenpfad|weites_feld>
```

Ausgabe prüfen auf `LOGIC-TEST OK`, keine Zeilen mit `FAIL` oder `SCRIPT ERROR`. Die CI führt den Test aus.

## Release

1. Version in `project.godot` und `export_presets.cfg` erhöhen (Code +1).
2. Test laufen lassen, APK bauen: `ANDROID_HOME=~/.local/opt/android-sdk JAVA_HOME=~/.local/opt/jdk-17 tools/build_android.sh`.
3. Committen, pushen, Tag `alpha-X.Y.Z`, Prerelease mit der APK (`gh release create`). Keine `v*`-Tags.
4. Die Web-Version baut `.github/workflows/pages.yml` bei jedem Push auf `main`.

## Konventionen

- Commits von `aikitori <88290076+aikitori@users.noreply.github.com>`, Nachrichten auf Deutsch.
- Nie Keystores, Passwörter oder Geheimnisse einchecken. Keine Modellnamen in Code, Dokumenten oder Releases.
- Code-Kommentare auf Deutsch, knapp, nur wo das Warum nicht offensichtlich ist.
- Neue Funktionen in `docs/GAME_DESIGN.md` festhalten.
