# Hold the Keep – Spielregeln

## Idee

Tower Defense wie in den Warcraft-III-Karten: große Karte, Gegner laufen vom Friedhof zur Burg, teils über
feste Wege, teils über freie Felder, auf denen man mit Türmen und Mauern Labyrinthe baut. Isometrische Sicht,
mittelalterlicher Stil (Kenney Castle Kit, Untote aus dem Graveyard Kit).

## Ablauf

- Start: 90 Gold, 20 Leben, 30 Wellen. Erste Welle nach 45 s, danach 25 s Pause, sobald der letzte Gegner einer
  Welle besiegt ist oder die Burg erreicht hat. "Nächste Welle" startet sofort und gibt die halbe Restzeit in Sekunden als Gold.
- Gegner, die die Burg erreichen, kosten 1 Leben, Bosse 5. Bei 0 Leben fällt die Burg.
- Gold gibt es für jeden besiegten Gegner (Grundwert plus 1 je 6 Wellen).
- Lebenspunkte der Gegner wachsen je Welle um 13 %.
- Bodenwellen: 12 Plätze plus 4 je 5 Wellen, Luftwellen 10 Geister plus 1 je 2 Wellen, Bosse mit 10 plus 1 je
  5 Wellen Begleitern. Abstand beim Erscheinen 0,6 s.

## Wellen

- Wellen 1 bis 5 haben je eine Art: Skelett, Räuber, Zombie, Luftwelle, Boss mit Skeletten.
- Ab Welle 6 kommen gemischte Gruppen (je 3 bis 5 gleiche Gegner abwechselnd): 2 Arten, ab Welle 11 drei, ab
  Welle 21 vier. Ab Welle 16 sind Flieger dazwischen. Ab Welle 15 sind auch die Bossbegleiter gemischt. Eine
  neue Art kommt in ihrer ersten Welle sicher vor. Die Zusammenstellung hängt nur von der Wellennummer ab.
- Arten (ab Welle):

  | Art | ab | Eigenschaft |
  |---|---|---|
  | Skelett | 1 | schnell, schwach |
  | Räuber | 2 | ausgewogen |
  | Zombie | 3 | langsam, zäh |
  | Ork | 6 | stark |
  | Dieb | 7 | sehr schnell, wenig Leben (grün) |
  | Knochenwicht | 8 | klein, kommt im Rudel zu zweit |
  | Ghul | 11 | heilt 5 % je Sekunde, außer wenn er brennt (hellgrün) |
  | Schwarzer Ritter | 12 | Rüstung 6 (dunkel) |
  | Irrlicht | 14 | Flieger, schnell, schwach (blau) |
  | Orkhäuptling | 17 | groß, zäh, Rüstung 4 (rot) |

- Rüstung zieht von jedem Treffer ab, höchstens 75 %. Magie und Feuer gehen durch. Gegen Rüstung helfen
  schwere Treffer (Balliste, Katapult) oder der Magierturm.
- Luftwellen 4, 9, 14, ...: Geister, ab Welle 14 auch Irrlichter. Sie folgen dem Grundweg der Karte (ohne
  Türme, gerade zwischen den Knicken) über alles hinweg, auch über die Kontrollpunkte, und werfen einen Schatten.
  Bauen ändert ihre Route nicht.
- Bosse: Vampir in Welle 5, 15, 25, Totengräber in Welle 10, 20, 30, jeweils mit Begleitung.

## Bauen

- Gebaut wird auf Gras (begehbar, also Teil des Labyrinths) und auf Hochflächen (nicht begehbar, Türme dort
  ändern den Weg nie). Feste Wege, Kontrollpunkte und Wald sind tabu.
- Kein Bau darf einen Abschnitt des Wegs (Start, Kontrollpunkte, Burg) ganz versperren oder einen Gegner
  einsperren, und nicht auf einem Feld mit Gegner. Gegner gehen schräg, aber nie zwischen zwei Türmen hindurch.
- Abreißen gibt 70 % des Eingesetzten zurück.

## Türme

| Turm | Gold | Trifft | Art |
|---|---|---|---|
| Mauer | 5 | – | blockiert nur |
| Schütze | 10 | Boden + Luft | Figur mit Bogen |
| Speerträger | 20 | Boden | Figur, Nahkampf, sofortiger Treffer |
| Bogenturm | 15 | Boden + Luft | schnelle Pfeile |
| Balliste | 35 | Boden | weit, stark, ein Ziel |
| Katapult | 45 | Boden | Fels im Bogen, Flächenschaden |
| Magierturm | 40 | Boden + Luft | verlangsamt |
| Himmelswacht | 30 | nur Luft | Feuerpfeile |
| Trebuchet | 90 | Boden | sehr weit, großer Einschlag |

Ziel ist immer der Gegner in Reichweite mit dem kürzesten Restweg zur Burg.

## Ausbau und Spezialisierung

- Stufe 2 und 3: Schaden x1,7, Reichweite +0,4, Nachladen x0,9 je Stufe. Kosten 80 % und 130 % des Grundpreises.
  Türme wachsen sichtbar (weitere Turmteile, größere Waffen, Wimpel).
- Auf Stufe 3 wählt man eine von zwei Spezialisierungen (Banner am Turm):

| Turm | Spezialisierung A | Spezialisierung B |
|---|---|---|
| Schütze | Langbogen (weiter, stärker) | Salve (3 Ziele) |
| Speerträger | Ritter (schwerer Stoß) | Pikenier (trifft alle rundherum) |
| Bogenturm | Feuerpfeile (Brand) | Salventurm (4 Ziele) |
| Balliste | Riesenbolzen (doppelter Schaden) | Flakballiste (trifft auch Luft) |
| Katapult | Brandtöpfe (brennender Einschlag) | Steinhagel (doppelt so schnell) |
| Magierturm | Frostmagier (starkes Verlangsamen) | Blitzmagier (Kette über 4 Gegner) |
| Himmelswacht | Sturmturm (3 Ziele) | Adlerhorst (weiter, stärker) |
| Trebuchet | Verheerung (riesiger Einschlag) | Präzision (weiter, dreifacher Schaden) |

## Karten

- **Vier Felder** (40x26): vier Baufelder, verbunden durch feste Wege.
- **Rundlauf** (36x26): Ring um eine bebaubare Hochfläche, vier Kontrollpunkte erzwingen eine Runde.
- **Schlangenpfad** (32x22): fester Weg in Schleifen durch die Hochfläche, kein Labyrinth.
- **Weites Feld** (38x24): offenes Feld, drei Kontrollpunkte oben und unten.

## Anzeige

- Der Weg der Bodengegner liegt als gelbe Pfeilspur mit dunklem Rand auf dem Boden, ein Lichtlauf zeigt die
  Laufrichtung.
- Beim Bauen zeigt eine helle Spur den Weg, der mit dem Turm an dieser Stelle entstehen würde.
- Start (Friedhof) und Ziel (Burg) tragen große Schilder, die nie verdeckt werden, und pulsierende Ringe.
- Figuren mit Skelett (Mini Dungeon) werden als Daumenkino aus vorab umgerechneten Meshes gezeigt
  (`scripts/figure.gd`), weil manche Handy-Browser kein Skinning zeichnen.

## Klänge

Jeder Turm hat einen Schussklang (Pfeil, Bolzen, Wurf, Feuer, Magie, Blitz, Stoß), dazu Einschläge,
Gegner-Tod (Skelette klappern, Geister heulen, Bosse brüllen beim Auftauchen), Glocke bei Schaden an der Burg,
Gong zu jeder Welle und ein Jingle bei Sieg oder Niederlage. Klänge auf der Karte sind nur zu hören, wenn die
Stelle im Bild ist; gleiche Klänge sind begrenzt (höchstens 2 bis 3 gleichzeitig, 70 ms Abstand).

## Menü

Eine Kachel je Karte mit Vorschau von oben (Gelände, Grundweg der Gegner, Friedhof S, Burg B und
Kontrollpunkte), Beschreibung und Größe. Quer stehen alle Kacheln nebeneinander, im Hochformat zwei mal zwei.
Das Menü scrollt nicht: passt es nicht auf den Bildschirm, wird es als Ganzes verkleinert.

## Bedienung auf Touch-Geräten

Mit Touchscreen wird die Oberfläche so skaliert, dass die kurze Bildschirmseite etwa 560 Einheiten hat
(am Rechner 720). Im Hochformat: zweite Zeile für die Knöpfe oben, Bauleiste in zwei Reihen, Menü einspaltig,
die Kamera-Zoomgröße gilt dann für die Breite.

Ziehen hält die Karte fest: der Punkt unter dem Finger bleibt unter dem Finger. Zwei Finger zoomen um ihre
Mitte und verschieben zugleich, danach zieht der übrige Finger ohne Sprung weiter.

## Ideen für später

- Mehr Karten (mehrere Startpunkte, Brücken über Flüsse), Schwierigkeitsgrade, Endlosmodus.
- Musik, Englisch als zweite Sprache, Spielstand speichern.
