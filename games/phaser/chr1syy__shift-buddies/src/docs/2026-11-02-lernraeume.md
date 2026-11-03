# Drei kleine Räume – Feedbackrunde vom 02.11.2026

Chris hat den bisherigen öffentlichen Testraum selbst gespielt und als gut spielbar bestätigt. Diese freigegebene Runde umfasst genau zwei kurze Lernräume vor diesem Technikraum sowie Grafik- und Bedienungsfeedback. Keine zusätzlichen Module, Gegner, Inventare oder Storysysteme.

## Was sich ändert

- **01 / Klein & schwer:** Pip zum Ausgang bringen, während Bolt die schwere Platte hält. Der einzige Weg zum Ausgang führt durch den schmalen Schacht und die von der Platte gesteuerte Tür. 12 Aktionen im geprüften Beispielweg. Module sind hier keine Voraussetzung.
- **02 / Energie teilen:** Anschluss versorgen und Bolt zum Ausgang bringen. Metallkiste zweimal zurückziehen, zu Bolt zurückkehren, nebeneinander Module tauschen, mit Pip den Anschluss versorgen und zu Bolt wechseln. 26 Aktionen im Beispielweg. Der verankerte Keramikblock direkt links von Pips Start lädt zum Magnetversuch ein. E erklärt ausdrücklich, warum er unbeweglich ist.
- **03 / Technikraum:** Die bisherige Kombination bleibt direkt anwählbar und mit dem vorhandenen Weg in 71 Aktionen lösbar. Ergänzt wurde ein fester Keramikblock im unteren Werkstattbereich; er blockiert den bisherigen Lösungsweg nicht.

Jeder Raum zeigt genau sein eigenes Ziel und einen kurzen aufklappbaren Hinweis. Die Raumwahl setzt den gewählten Raum samt Undo-Verlauf zurück. Nach einem Sieg in den Lernräumen erscheint Weiter. Z kann einen Sieg zurücknehmen; Weiter verschwindet dann wieder. R startet ausschließlich den aktuellen Raum neu. Es gibt keine dauerhafte Speicherung.

Die sichtbare **Shift · Roboter wechseln**-Taste nutzt dieselbe Aktion wie beide Shift-Tasten und gibt den Fokus an das Spielfeld zurück. Dasselbe gilt für E, T, Z, R, Raumwahl und Weiter.

Pips Körper ist schmal mit kleinen Rädern, Bolts Körper breit mit zwei Ketten. Das Schachtgitter lässt optisch Platz für Pip; die Platte zeigt Bolts Kettenspuren. Beide Roboter tragen die Module als Anbau über dem Körper: Hufeisen mit zwei unterscheidbaren Polen oder Batterie mit Kontakt und Blitz. Der Blickrichtungspfeil liegt separat rechts oben, der Aktivmarker links oben. Die genietete Metallkiste trägt dasselbe Hufeisen wie das Modul; der feste Keramikblock ist achteckig, rissig und am Boden verankert. Farbe allein trägt keine dieser Unterscheidungen. Kurze ausblendende Ringe bestätigen erfolgreiche Magnet-, Strom- und Tauschaktionen; reduzierte Bewegung wird respektiert.

## Nachvollziehbarer Code

Die bestehende einzelne Phaser-Scene bleibt erhalten. `src/game/rules.ts` ergänzt Raumdefinitionen, raumbezogenen Zustand und kleine unterschiedliche Siegbedingungen; die übrigen Bewegungs-, Tausch-, Strom- und Undo-Regeln bleiben gemeinsame reine TypeScript-Funktionen. `src/main.ts` zeichnet die Raumdefinition des Zustands und verwendet eine gemeinsame Modul-Zeichenfunktion für Roboter und Metallkiste. Keine Assets, Dienste oder Abhängigkeiten wurden ergänzt.

Die expliziten Beispielwege stehen in `tests/solution.ts`. Regeltests prüfen alle drei Lösungen, jeden Undo-Snapshot, Neustart, Raumgrenzen des Verlaufs, Sperren ohne Laufumgehung und das feste Hindernis. Browsertests bedienen Tastatur und sichtbare Buttons, prüfen Fokus, Weiter, direkte Technikraumwahl, Raumwechsel und schmaleres Fenster. Screenshots liegen intern unter `.cache/`, nicht im öffentlichen Build.

## Vorschläge für danach – kein Teil dieses Zyklus

1. Chris spielt die beiden Lernräume ohne Vorwissen über den Lösungsweg. Beobachten: Erkennt er die aktuelle Aufgabe, die Blickrichtung und die nötige Partnerrolle?
2. Danach die Raumabfolge und Hinweistexte an tatsächlichen Stolperstellen schärfen. Weitere Räume erst nach dieser Rückmeldung planen.
3. Vor dem Jam-Abschluss Firefox und die itch.io-Einbettung prüfen; gegebenenfalls einen kleinen Titel-/Abschlussbildschirm und Audio ergänzen. Das sind Vorschläge und keine zugesagten Features oder Veröffentlichungen.

Die Abnahme und der genaue veröffentlichte Spiel-SHA stehen in `docs/2026-11-02-deployment-lernraeume.md`. Headless Chromium und Screenshotprüfung ersetzen keinen erneuten menschlichen Spieltest. Keine itch.io-Veröffentlichung in diesem Auftrag.
