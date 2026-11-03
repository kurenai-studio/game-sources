# Shift Buddies – Körper, Modultausch und gegenseitige Hilfe

> **Nachtrag: gezielt geprüft und live bereitgestellt.** Chris hat die anschließende Test-/Deployfreigabe ausdrücklich erteilt. Der [Releasebericht](2026-11-02-deployment-kooperation.md) mit Spiel-SHA `cf33fb3dd55da93b229cca2954b7dfcfec120f4e` ersetzt die unten historisch dokumentierten offenen Test-/Deploygrenzen. Die folgende Darstellung beschreibt den vorherigen Implementierungsauftrag.

02.11.2026. Ausgangspunkt: sauberer bestehender Checkout `main`, lokal und auf `origin/main` exakt **`6fef1338d4c49a30e579fe68846a747c3aa6113b`**. Umsetzung allein im selben Checkout, ohne parallele Arbeit, Worktree oder AutoRun. Keine Deploys, Discord-Nachrichten oder Callback-Registrierungen. Mira liest den Auftragstab selbst.

**Prüfstatus:** Implementiert und lokal mit Tastatureingaben im vorhandenen Chromium/Playwright-Browser durchgesehen. TypeScript- und Produktionscompiler geprüft. Keine Tests neu angelegt, geändert oder ausgeführt; keine Solver-/Flood-Fill-Suche. Die konkreten Sichtdurchgänge unten sind keine Regressionstest- oder unabhängige Spielabnahme. Tests und weitergehende Abnahme benötigen Miras anschließenden ausdrücklichen Prüfauftrag.

## Was sich geändert hat

- Pip bleibt klein und passt durch Schächte. Bolt bleibt schwer, hält Platten und kann bewusst schieben. Magnet **und** Batterie funktionieren auf **beiden** Bots; T tauscht nur zwischen direkten Nachbarn, Shift wechselt die Steuerung.
- E + rückwärts zieht weiterhin mit dem Magneten. E + vorwärts schiebt ausschließlich mit Bolt, unabhängig vom getragenen Modul. Erst ausrichten, dann E halten; seitwärts keine Bewegung/Drehung, normales Fahren schiebt nicht. Magnetisches E allein bewegt nichts. Batterie-E verbindet/löst weiterhin auf dem Sockel. Ohne Magnet kein Ziehen.
- Schieben benutzt dieselbe reine Zustandsänderung und dieselben Hindernisregeln wie Bewegung. Das bestehende interne Kommando `pull` umfasst jetzt E+Richtung; nur der Vorwärtszweig für Bolt schiebt. Die bereits vorhandene Undo-Historie speichert Bot, Fracht, Module, Blick und Verbindung zusammen. Keine zusätzliche Zähler-/Latch-/Inventarmechanik. Kisten sind zu breit für Schächte, beim Ziehen ebenso wie beim Schieben.
- Die vorhandenen Eingaberesets bleiben erhalten: E loslassen, Feld-/Fensterblur, verborgenes Dokument, Shift/T/Z/R/Raumwechsel. Abgewiesene Richtungsversuche verändern weder Position noch Blick; gehaltenes E bleibt bis zum Loslassen bereit. Der E-Button rastet nicht ein.
- Ein heller Nasenpfeil ergänzt das gedrehte Gesicht; die Roboterkarte zeigt zusätzlich ↑/↓/←/→. Der rückwärtige Modulträger bleibt bestehen.
- Leitungen werden nach dem Boden und **vor** Einrichtungen/Bots/Fracht gezeichnet, mit einem dezenten ein Pixel breiten Verlauf. A/B/C an sämtlichen Endpunkten und ○/● zeigen Zuordnung und Zustand unabhängig von Leitungsüberlagerungen/Farbe. Sockel tragen dieselbe Batterieform wie die Bots. Das feldlokale `PIP`-Label ersetzt die unzuverlässigen fest platzierten Schachtpfeile; der horizontale Schacht in Raum 6 wird entsprechend quer gezeichnet.
- Neu aktivierter Sockel oder neu belastete Platte und zugehörige Tore/Brücken erhalten gemeinsam einen einmaligen 450-ms-Ausblendimpuls. Die fertige Fahrinterpolation beendet diesen Impuls nicht vorzeitig; Folgeaktionen dürfen ihn beenden. Permanente Punkte, Plattenlage, Torstreben und Brückenform bleiben erhalten. Reduced motion unterdrückt sämtliche Interpolation und Impulse, auch bei geändertem Systemwunsch.

`isWon` ist unverändert: In Räumen 3–6 müssen beide Bots auf Ausgangsfeldern stehen. **Keine Tauschzählerpflicht.** Die Notwendigkeit entsteht aus Schachtzugang, Versorgung, Last und Torabständen.

## Zuerst der Proberaum: 03 / Technikraum

Dieser Raum wurde vor dem Umbau von 4–6 entwickelt und mit echten Browser-Tastatureingaben gelöst. Er konzentriert die Rollenübergabe ohne Fracht. Die Schachtzufahrt ist ausschließlich von unten erreichbar; die durchgehende Wand bei x=6 hat nur ein Tor.

Nullbasierte Koordinaten, wie auf den Roboterkarten:

```text
   01234567890123456
3  ###S#############
4  ###v#############
5  #.....#.........#
6  #.....#.........#
7  #.....D.P.......#
8  #.....#.........#
9  #.....#.......XX#
```

Pip startet `3/5` mit Magnet, Bolt `4/7` mit Batterie. Sockel A `3/3`, Schacht `3/4`, Tor A `6/7`, Platte A `8/7`, Ausgänge `14/9` und `15/9`.

1. Pip fährt nach `3/7`, tauscht neben Bolt und versorgt hinter dem Schacht den Sockel `3/3`.
2. Bolt fährt durch A auf `8/7`. Damit übernimmt sein Körper die Versorgung des Tores, unabhängig von seinem Magneten.
3. Pip löst Strom, geht durch A nach `7/7` und **unterhalb** des wartenden Bolt nach `14/9`.
4. Bolt verlässt die Platte und fährt nach `15/9`; beide sind bereits auf der Ausgangsseite.

**Gegenversuche:** Ohne T erreicht Pip den Sockel mit Magnet; E liefert keinen Strom. Bolt wird bei freigeräumter Zufahrt am Schacht `3/4` abgewiesen. Nach T, aber ohne Bolts Plattenbeitrag, endet Pip nach dem Lösen von Strom vor dem geschlossenen Tor auf `5/7`; das wurde im Browser gesehen. Fracht gibt es in diesem Raum absichtlich nicht: „ohne Fracht“ ist hier keine aussagekräftige Gegenprobe. Die Frachtnotwendigkeit folgt erst in 4/5.

Die Notwendigkeit lässt sich lokal aus der Geometrie erklären: Vor dem ersten Öffnen erreicht niemand die rechte Platte; die einzige linke Quelle ist hinter Pips Schacht. Später kann Pip den entfernten Sockel nicht versorgen und gleichzeitig durch das Tor gehen. Bolt muss drüben übernehmen. Das ist eine begründete Geometrieanalyse, kein erschöpfender Zustandsraumbeweis.

Ein früher Sichtdurchgang fuhr Pip geradeaus gegen Bolt auf der Platte. Der nachvollziehbare Weg wurde auf den unteren Bogen korrigiert; dieser Durchgang zählt nicht als erfolgreiche Lösung.

## Staffelung und tragende Sperren

| Raum | Lernziel und notwendiger Beitrag |
| --- | --- |
| 1 · Klein & schwer | Unveränderte Geometrie. Pip passiert den Schacht, Bolt hält die Platte. Nur Shift nötig. |
| 2 · Energie teilen | Unveränderte Geometrie. Pip zieht die Kiste weg, bekommt per T die Batterie und versorgt den nur schmal erreichbaren Sockel. |
| 3 · Technikraum | Proberaum oben: T, Pip als Versorger, Bolt übernimmt mit seinem Körper, beide hinaus. |
| 4 · Schwere Fracht | Pip versorgt `7/4` durch den Schacht `7/5`. Bolt erreicht durch Tor `2/5` die Oberseite der Kiste `5/3` und schiebt sie auf `5/4`. Die Platte ist eine Sackgasse: `5/5` ist Wand, deshalb kann niemand unter der Platte stehen und die Fracht hineinziehen. Ohne Kraftschieben kein dauerhafter Ersatz für Pip am Sockel. Fracht und Sockel öffnen beide Tore desselben Kreises A, einschließlich Ausgangstor `9/7`. |
| 5 · Getrennte Wege | A entspricht dem Proberaum. Fracht startet jetzt im Mittelraum `9/6`, Platte B ist **vor** dem letzten Tor auf `9/7`, Tor B auf `11/7`. B hat keinen Stromsockel. Bolt kann B vorübergehend halten, steht nach dem Wegfahren aber erst auf `10/7`, während das Tor bereits schließt. Die Fracht muss ihn ablösen. Ziehen mit Pip oder Schieben/Ziehen mit passend ausgerüstetem Bolt sind bewusste Alternativen. |
| 6 · Brückendienst | Pip erhält Batterie, versorgt C `5/5`; Bolt passiert Brücke `7/5` und hält A `10/5`. Pip folgt **vorwärts** über Tor A `6/9` und seinen schmalen Partnerweg `7/9`, versorgt dann B `10/9`. Erst jetzt gelangt Bolt durch Tor B `12/7` aus dem oberen in den unteren Ausgangsbereich. Kein Rückweg des zuerst übergesetzten Bots; beide helfen dem Partner auf dessen eigener Route. |

In Raum 4 liegt auch die schwere Platte vor den Ausgängen: Bolt auf der Platte statt der Kiste lässt ihn selbst zurück. Wenn Pip den Sockel verlässt, endet dessen Versorgung mehrere Schritte vor dem Ausgangstor. In Raum 5 ist die gesamte Wand bei x=11 außer dem Tor auf y=7 geschlossen. Die Lösung muss vor dem Tor wieder auf diese Zeile wechseln.

Die Anzahl bleibt **sechs**. Kein weiteres Modul, kein neues Levelsystem, keine zusätzlichen Abhängigkeiten. Raum 5 erlaubt absichtlich eine Variante mit nur dem ersten T und Bolts Magnet/Kraft für die Kiste; ein zweiter T ist keine künstliche Pflicht. Die unten gewählte Lösung gibt Pip den Magneten zurück und zeigt damit dessen fortbestehenden Nutzen.

## Nachvollziehbare Lösungen für alle sechs Räume

Vom jeweiligen Raumstart. `×n` = n einzelne Tastendrücke, `E+Richtung` = E halten, Richtung einmal drücken, E loslassen. Alle anderen E werden einzeln gedrückt und losgelassen. **Rückwärts/Vorwärts beziehen sich auf den Nasenpfeil**, nicht auf oben/unten im Bild. Der einzelne ↓-Versuch vor dem Schieben in Raum 4 richtet Bolt absichtlich an der blockierenden Kiste aus.

### 1 · Klein & schwer

`Shift →×2 Shift ↑×2 →×6`

Bolt `5/7`, Pip `8/5`. Aus dem Vorgänger übernommen, in diesem Auftrag nicht erneut durchgespielt.

### 2 · Energie teilen

`↑×3 →×2 E+← E+← ↓×4 T ↑×3 →×2 ↑ →×3 E Shift →×3`

Pip versorgt `8/2`, Bolt erreicht `7/6`. Aus dem Vorgänger übernommen, in diesem Auftrag nicht erneut durchgespielt.

### 3 · Technikraum

`↓×2 T ↑×4 E Shift →×4 Shift E ↓×4 →×4 ↓×2 →×7 Shift →×7 ↓×2`

Am Übergabepunkt: Pip verbunden `3/3`, Bolt auf Platte `8/7`. Ziel: Pip `14/9`, Bolt `15/9`. Im lokalen Browser bis zur Siegesanzeige gespielt.

### 4 · Schwere Fracht

`T ↑ →×4 ↑×2 E Shift ←×2 ↑×5 →×3 ↓ E+↓ ←×3 ↓×4 →×13 ↓ Shift E ↓×3 →×7 ↓`

Vor dem Schieben: Bolt `5/2`, Blick ↓, Kiste `5/3`. Danach Bolt `5/3`, Kiste `5/4`. Ziel: Pip `14/8`, Bolt `15/8`. Im lokalen Browser bis zur Siegesanzeige gespielt. E allein am Schiebepunkt ließ Kiste und Bot stehen.

### 5 · Getrennte Wege

`↓×2 T ↑×4 E Shift →×4 Shift E ↓×4 →×4 T ↓ →×2 ↑ E+↓ → ↑ →×4 ↓×2 Shift ↓ →×2 ↑ →×5 ↓×2`

Zweiter T: Pip `7/7`, Bolt `8/7`. Pip bekommt Magnet zurück, zieht von `9/7` rückwärts nach `9/8` und bringt die Kiste auf B `9/7`. Er umrundet die Kiste über `10/8` und geht durch B auf y=7. Bolt nimmt ebenfalls den unteren Bogen um die Kiste. Ziel: Pip `14/9`, Bolt `15/9`. Im lokalen Browser mit **reduzierter Bewegung** bis zur Siegesanzeige gespielt.

Der erste Durchgang versuchte, auf y=8 die Wand bei x=11 zu queren; beide blieben davor. Das war ein Fehler in der geplanten Eingabefolge, kein erfolgreicher Lösungsnachweis. Die obige korrigierte Folge benutzt das tatsächliche Tor.

### 6 · Brückendienst

`T ↑×2 → E Shift → ↑×2 →×4 Shift E ← ↓×4 →×6 E Shift →×2 ↓×3 →×2 ↓×2 Shift E →×4`

Drei Hilfephasen: Pip versorgt C `5/5`; Bolt hält A `10/5`; Pip versorgt B `10/9`. Bolt fährt durch `12/7` nach `14/10`. Pip löst Strom und erreicht `14/9`. Im lokalen Browser bis zur Abschlussanzeige gespielt.

## Gegenversuche und ihre Aussagegrenzen

„Ohne Bolt“ heißt hier **ohne dessen wesentliche Körperhilfe**, nicht nur „kein Sieg, weil ein zweiter Bot am Ausgang fehlt“. „Ohne Fracht“ heißt in den Browserversuchen **Kiste nicht benutzt**, nicht aus dem Zustand entfernt. Es wurden keine Regeln/Zustände per Debug-Hook verändert.

| Versuch | Konkretes Ergebnis / Evidenzart |
| --- | --- |
| Raum 3 ohne T | Pip auf Sockel `3/3` mit Magnet: keine Versorgung. Bolt kommt bei freier Zufahrt nicht durch `3/4`. Browserbeobachtung. |
| Raum 3 ohne Bolts Plattenhilfe | Nach T und anschließendem Lösen des Sockels steht Pip `5/7` vor geschlossenem A; Bolt bleibt links. Browserbeobachtung. |
| Raum 3 ohne Fracht | Nicht anwendbar: Raum enthält keine Kiste. Kein Beleg für Frachtnotwendigkeit behauptet. |
| Raum 4 ohne T / ohne Kraftschieben | Nur Pip kann den Sockel erreichen; ohne T bleibt A zu. Die Zielplatte `5/4` ist nur von `5/3` zugänglich; Ziehen auf sie verlangte ein Standfeld `5/5` in der Wand. Geometrie-/Codeanalyse, kein vollständiger Suchlauf. |
| Raum 4 ohne Fracht | Pip versorgt A, Bolt fährt direkt hinaus nach `15/8`; nach dem Lösen von Strom bleibt Pip auf `8/7` vor A stecken. Kiste unverändert `5/3`. Browserbeobachtung. |
| Raum 5 ohne T / ohne Bolt auf A | Der linke Schacht-/Versorgungswechsel ist derselbe wie in Raum 3. Geometrieanalyse; nicht separat jede Variante im Browser wiederholt. |
| Raum 5 ohne Fracht, Bolt als Wachposten | Bolt hält B auf `9/7`, Pip erreicht `14/9`. Bolt verlässt B, kommt auf `10/7` und wird vor `11/7` abgewiesen. Kiste unverändert `9/6`; B ist zu. Browserbeobachtung. Ein Partner auf einem geschlossenen Tor hält es nicht für einen neu eintretenden Bot offen. |
| Raum 6 ohne T | Bolt versorgt C `5/5`, Pip überquert und steht auf A `10/5`: zu leicht, A und B bleiben zu. Bolt kann den Sockel nicht verlassen und selbst die zwei Felder entfernte Brücke betreten. Erster Teil im Browser gesehen, Rückschluss aus Geometrie. |
| Raum 6 ohne Bolts Plattenhilfe / ohne Fracht | Ohne A bleibt Pips unterer Partnerweg geschlossen; B unten ist vom oberen Bereich durch Wand/Tor getrennt. Geometrieanalyse. Keine Kiste vorhanden, deshalb keine Frachtnotwendigkeit behauptet. |

Zusätzliche konkrete Sichtkontrolle: In Raum 5 nach dem zweiten T trägt Bolt die **Batterie**. Von `9/5`, Blick ↓, lässt E allein die Kiste auf `9/6`. E+↓ schiebt sie auf B `9/7`; die Batterie bleibt bei Bolt. Zusammen mit dem Schieben mit Magnet in Raum 4 zeigt das die modulunabhängige Körperkraft im tatsächlichen Browser. Pip zieht mit Magnet in der dokumentierten Raum-5-Lösung. Bolts unveränderter Magnet-Rückwärtszweig ist codegeprüft, aber in diesem Auftrag nicht separat als erfolgreiche Bewegung durchgespielt.

**Grenze:** Diese Versuche plus Sperrenanalyse sind kein formaler Beweis gegen alle Modultausch-, Türbelegungs-, Brücken- und Undo-Kombinationen. Es wurde kein Zustandsraum erschöpfend untersucht. Ungesehene Umgehungen und Bedienungsregressionen können erst die freizugebenden gezielten Prüfungen besser ausschließen.

## Lokale Sichtbelege und Compiler

Vorhandene Browserbibliothek und vorhandenes Chromium unter `.cache/playwright` benutzt, nur mit Loopback-Devserver auf `127.0.0.1:5175`. Keine neue Test-Infrastruktur, keine Testdefinitionen/Assertions, keine Ausführung von `npm test`, `npm run test:browser`, alten Testdateien oder Solver-Skripten. Temporäre Tastatursteuerung und Belege liegen ignoriert unter `.cache/team-review-2026-11-02/`; Browserinstanzen und eigener Server werden am Ende geschlossen. Ein vorhandener Server auf 5173 blieb unberührt.

Wichtige Belege in diesem lokalen Ordner:

- `room-walkthrough.log`: Raum 4 und 6, einschließlich erfolgreicher Endpositionen; enthält auch den ausdrücklich fehlgeschlagenen ersten Raum-5-Weg.
- `targeted-sight.log`: Gegenversuche, Batterie-Schieben, erfolgreiche korrigierte Raum-5-Folge mit Reduced motion.
- `proberaum-solved.png`, `room4-push.png`, `room4-solved.png`, `room5-solved.png`, `room5-no-freight.png`, `bolt-power-push.png`, `room6-partner.png`, `room6-power-b.png`, `room6-solved.png`, `room6-no-swap.png`.
- `build.log`: abschließender Produktionsbuild einschließlich Typecheck. Die bekannte Phaser-Größenwarnung bleibt.

`npm run typecheck` und der abschließende `npm run build` waren erfolgreich. Buildausgabe: JavaScript 1.221,96 kB / 328,68 kB gzip. `git diff --check` war sauber. Eigene Diffprüfung von Regeln, Eingaben, Darstellung und Dokumentation; keine unabhängige Codeprüfung behauptet.

Die Bilder sind lokale Sichtbelege, keine committed Releaseartefakte. Nach dem letzten Darstellungsschritt wurden `final-room3-activation.png`, `final-room3-handoff.png` und `final-room6-power-b.png` aufgenommen und angesehen, außerdem Fracht-, Gegenversuch- und Siegaufnahmen. Der finale Proberaumdurchgang erreichte erneut die Siegesanzeige (`final-sight.log`, Chromium 156.0.8078.4). Der letzte Partnerweg-Screenshot zeigt Reduced motion mit dauerhaft aktivem A/B. Die exakte Impulsdauer wurde nicht mit einer Frame-Messreihe abgenommen. Historische öffentliche Releasebelege werden nicht überschrieben. Die aktuelle Live-Seite zeigt weiterhin den vorherigen Release.

## Gezielt sinnvoll nach Miras Testfreigabe

1. Bestehende `tests/solution.ts`, Regel- und Browsererwartungen auf die neuen Räume 3–6 und Bolts erlaubte Vorwärtsbewegung umstellen. Die alten Tests sind bewusst unangetastet und voraussichtlich mit diesen Geometrien nicht mehr passend; kein Grünstatus behauptet.
2. Körper/Module kombinieren: beide Bots magnetisch rückwärts, beide elektrisch am Sockel; Bolt schiebt mit beiden Modulen, Pip schiebt mit keinem. Magnet-E allein und normales Gegen-die-Kiste-Fahren bleiben ohne Frachtbewegung.
3. Schiebekollisionen an Wand, Keramik, Buddy, Schacht, Grube, geschlossener Tür und Brücke; Brückenbelegung vor/nach Verschieben, auch über die ganze Spanne. Gleiches für die neue Frachtsperre beim Ziehen in Schächte.
4. E-Ausrichtung, Seitwärts-Abweisung, Keyrepeat und alle bestehenden Resets bei Shift/T/Z/R/Raumwahl sowie echtem DOM-/Fensterfokusverlust. Batterie-E auf einem Sockel bei Bolt samt anschließendem gehaltenem Vorwärtskommando.
5. Undo jedes Schiebe-/Zieh-/Tausch-/Stromschritts bis zum Raumstart; Folgeaktion während Fahrt/Impuls; kein alter Effekt nach Undo/Restart/Raumwahl. Vollständige Snapshot-Abnahme steht aus.
6. Lösungen 1–6 mit realen Tastatureingaben, Sieg/Weiter/Enter am Ende; gezielte Ohne-T-/Ohne-Körperhilfe-/Ohne-Fracht-Suche einschließlich Torbelegungsumgehungen. Besonders Raum 4 (Zug-Sackgasse), Raum 5 (Wachpostenersatz), Raum 6 (Pip zu leicht / Batterie-Selbstquerung / Partnerweg).
7. Finale Sichtabnahme aller Blickrichtungen und Modulverteilungen, aktiver/inaktiver Quellen/Tore, kurzzeitiger gemeinsamer Aufhellung und dauerhaftem Zustand. Reduced motion auch während eines aktiven Impulses umschalten; schmaleres Fenster, Chromium und später weitere Zielbrowser/itch.io. Physischer Fokus- und Hörtest separat.

Diese Liste ist eine Empfehlung für den folgenden Prüfauftrag, **keine ausgeführte oder pauschal freigegebene Testsuite**. Auch nach lokalen Checks ist ein menschlicher Spieltest mit Chris sinnvoll, insbesondere für verständliche Hinweise und die Schiebesteuerung. Deployment ist weiterhin ein eigener Auftrag.
