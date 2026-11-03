# Fahrgefühl & Körperausdruck · 03.11.2026

Auftrag: das vorhandene Rasterrätsel durch Halten spielbar machen, ohne die Körper-/Modulregeln und Undo aufzuweichen. Erst am bestehenden Fracht-/Magnetraum erprobt; dieselbe Eingabe und derselbe Renderer gelten für alle sechs Räume. Keine neuen Level, Module oder Menümodi. [Bestätigte nächste Schritte](2026-11-03-roadmap.md) bleiben getrennte kleine Arbeitspakete.

## Was sich beim Spielen ändert

- **Tippen fährt ein Feld, Halten fährt weiter.** Ein eigener 180-ms-Takt bedient WASD und Pfeile. OS-Wiederholungen führen keine Aktionen aus und scrollen auch die Seite nicht. Richtung loslassen beendet die aktuelle Fahrt am nächsten Feldzentrum.
- **Zwischen Feldern bleibt die Geschwindigkeit erhalten.** Nur der erste Feldzug aus dem Stand beschleunigt; seine Endgeschwindigkeit entspricht den linearen Folgezügen. Kleine Frameversätze unter 100 ms werden innerhalb des nächsten Feldsegments berücksichtigt; es gibt keine Schleife, die mehrere versäumte Aktionen nachholt. Eine lange Framepause über 250 ms setzt die Eingabe zurück und stellt höchstens den bereits bestätigten Feldzug fertig dar.
- **Pip und Bolt sind unterschiedlich lesbar, aber gleich schnell steuerbar.** Pip dreht in 100 ms und federt leicht. Bolt dreht in 140 ms, setzt breitere Ketten ein und stützt sich kompakter ab. Räder und Ketten laufen beim Ziehen rückwärts und beim Drehen gegensinnig. Kleine Anfahr-, Stop- und Hindernisimpulse bleiben rein visuell.
- **E + Richtung bleibt bewusst.** Beide ziehen nur mit Magnet rückwärts, ohne die Kiste aus dem Blick zu verlieren. Bolt schiebt vorwärts mit jedem Modul; Pip kann nicht schieben. Bot und Last verwenden denselben Fortschrittswert. Die bestehende Magnetverbindung und der optionale Zug-/Schiebeklang bleiben erhalten. E auf Batterieanschlüssen verbindet/löst wie zuvor.
- **Hindernisse verursachen einen Versuch.** Danach sperrt die Eingabe weitere automatische Versuche. Es entstehen keine wiederholten Rückmeldungen, Klänge oder Undo-Einträge. Eine notwendige Blickänderung gegen ein Hindernis bleibt wie bisher eine einzeln rückgängig machbare Aktion.

## Eingaben ohne Überraschung

Die zuletzt neu gedrückte physische Richtungstaste gewinnt. Wird sie losgelassen, gilt wieder die letzte noch gehaltene Richtung. WASD und Pfeil-Aliase werden getrennt freigegeben. Ein kurzer Richtungswechsel während einer laufenden Fahrt merkt höchstens eine nächste Fahrabsicht; weitere Tastendrücke ersetzen sie. Es gibt keine wachsende Warteschlange. Auch ein zwischen zwei Frames vollständig gedrückter und losgelassener Tipp bleibt damit erhalten.

E loslassen löscht gehaltene Richtungen und die nächste Absicht; dadurch fährt der Bot anschließend nicht versehentlich normal weiter. E neu drücken löscht die alte Fahrabsicht ebenfalls. Shift, T, Z, R, Raumwahl, Sieg, Spielfeld-/Fenster-Blur und ausgeblendetes Dokument löschen Richtungen und E-Bereitschaft. Bereits bestätigte Spielzustände bleiben gültig; Z nimmt sie genau zurück. Ein Wechsel der Reduced-motion-Einstellung beendet laufende Darstellung und Haltebereitschaft.

**Reduced motion** überspringt Fahr-, Dreh- und Körperanimation sowie die bestehenden Aktivierungseffekte. Der 180-ms-Haltetakt bleibt gleich. Einzelne schnelle Tipps werden sofort verarbeitet und verschieben den Zeitgeber nicht auf einen späteren Zeitpunkt. **Ton bleibt zunächst aus**; der vorhandene Schalter und AudioContext bedienen weiterhin den bestehenden synthetischen Lastklang. Es wurden keine zweiten Input-, Audio- oder Renderpfade angelegt.

## Kleine nachvollziehbare Codeänderung

`src/game/drive.ts` verwaltet ausschließlich physische Richtungstasten, eine nächste Absicht, die Hindernissperre und die Abfahrtskurve. Die vorhandene Scene in `src/main.ts` steuert Zeit und Darstellung und ruft je tatsächlichem Rasterzug weiterhin genau einmal `dispatch` auf. `src/game/rules.ts` und die sechs Raumdefinitionen bleiben unverändert. Die bisherige Undo-Historie ist weiterhin die einzige Spielhistorie.

Die Scene veröffentlicht die tatsächlich verwendeten Renderkoordinaten, Winkel und linken/rechten Radphasen nur als lesbare `data-visual-*`-Attribute für Browserbelege. Die Browserprüfungen kombinieren sie mit Pixelhashes echter Canvas-Frames; es gibt keinen Debug-Zustandssetter. Alle dauerhaften Statusanzeigen, Modulformen und die Frontgesichter bleiben im gemeinsamen Renderer.

Die genaue Releaseabnahme, öffentlich geprüfte Bytes, Timingbelege und Rückfallbeschreibung stehen nach der Veröffentlichung im zugehörigen Deploymentbericht. Grenzen bleiben menschliches Fahrgefühl, physischer OS-Fokus, Hörabnahme, Firefox/Safari und itch.io-Einbettung; Headless Chromium ersetzt diese Abnahmen nicht.
