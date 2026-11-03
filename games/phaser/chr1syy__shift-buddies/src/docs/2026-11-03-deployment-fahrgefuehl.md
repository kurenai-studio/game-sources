# Geprüfte Fahrgefühlvorschau · 03.11.2026

**Spielbereit:** https://shift-buddies.clippmann.de/ · Chris hat Umsetzung, Commit/Push und Livebereitstellung dieses Pakets ausdrücklich autorisiert. Dies ist die bestehende Spieltestvorschau für Chris; menschliche Spielabnahme und itch.io-Veröffentlichung stehen weiter aus.

## Exakter Stand und Umfang

- **Spiel-/Prüf-SHA:** `d535f02edccc9e95bd52ebab971666e85100e7f6` auf `main`, zu GitHub gepusht. Der folgende Berichtcommit ändert ausschließlich README, Bericht und Receipt; die veröffentlichten Buildbytes bleiben identisch.
- **Release:** `/var/www/shift-buddies/releases/20261103T115853Z-d535f02edccc`.
- **Vorgänger:** `releases/20261102T200807Z-cf33fb3dd55d` bleibt vollständig erhalten.
- `src/game/drive.ts` ergänzt physische Tasteneigentümer, eine nächste Fahrabsicht, Hindernissperre und die Abfahrtskurve. `src/main.ts` erweitert den vorhandenen Input-/Renderpfad und verwendet weiterhin den vorhandenen Audiohelfer. Keine neue Abhängigkeit, kein zweiter Spielzustand.
- `src/game/rules.ts`, Raumdaten, Module und Lösungen bleiben unverändert. Kein neuer Menümodus und kein Story-/Levelausbau.
- [Verhalten und Code](2026-11-03-fahrgefuehl.md) · [bestätigte Roadmap](2026-11-03-roadmap.md).

## Was Chris ausprobieren kann

Kurz WASD/Pfeil tippen fährt ein Feld, halten fährt weiter. Loslassen beendet die Fahrt im nächsten Feldzentrum. Die zuletzt neu gedrückte Richtung gewinnt; nach deren Loslassen gilt die letzte noch gehaltene Richtung. Bots fahren beide im 180-ms-Takt; Pip dreht/federt leichter, Bolt stützt sich mit breiten Ketten ab. Kleine Anfahr-, Stop- und Hindernisreaktionen verändern keine Regeln.

Erst zur Kiste ausrichten, dann **E halten + rückwärts** zum Magnetziehen; Bolt kann mit **E + vorwärts** und jedem Modul schieben. Last und Bot laufen synchron; beim Ziehen bleibt der Blick zur Kiste. E loslassen beendet die Haltebereitschaft. Shift wechselt, T tauscht zwischen Nachbarn, Z nimmt jeden tatsächlichen Feldzug einschließlich Last exakt zurück, R startet den Raum neu. Raumwahl, Sieg und Fokusverlust stoppen alte Eingaben. Ein Hindernis löst höchstens einen automatischen Versuch aus. Ton startet aus; Reduced motion zeigt Zustände sofort, bei gleichem Haltetakt.

## Konkrete Abnahme

**32/32 Regel-/Inputtests**, Typecheck und Produktionsbuild bestanden. Alle sechs bisherigen Lösungen bestehen weiter, mit exaktem Undo aller Zustands-Snapshots einschließlich Blick, Last, Modul und Verbindung. Neue reine Prüfungen decken Aliasfreigabe, Priorität mehrerer Tasten, einen kurzen Tipp, Hindernissperre, Reset und den Geschwindigkeitsübergang ab.

**12/12 Chromium-Browserprüfungen lokal gegen einen stabilen Produktionsbuild**, anschließend **12/12 über normales öffentliches HTTPS**, ohne Zertifikats- oder DNS-Bypass. Enthalten sind die sechs vollständigen Tastaturlösungen mit Undo und erneutem Lösen bei Reduced motion, T/Shift, beide Shift-Tasten, Buttons und Fokus, Tippen/Halten/Loslassen, OS-Repeat, Turns, E+Last mit beiden Körper-/Modulrollen, exaktes Last-Undo, Hindernisse, E-/Richtungkeyup, Z/R/Shift/T/Raumwahl/Sieg, Blur/tabhidden, lange Framepause und dynamische Reduced-motion-Einstellung. Zusätzlich bleiben Brückeninterlock, 800-Pixel-Layout, 32 sichtbare Augen in 16 Körper-/Modul-/Blickkombinationen sowie Ton-opt-in geprüft. Keine Konsolen- oder Laufzeitfehler im finalen Lauf.

### Echte Mehrframe- und Timingbelege

Die Tabellenwerte bedeuten **erfasste Frames / unterschiedliche Canvas-Pixelzustände**. Koordinaten, Winkel, Radphasen, Zeitstempel und Pixelhashes stammen aus mehreren tatsächlichen Browserframes, nicht aus einem Endbild.

| Sequenz | Lokal | Öffentlich |
| --- | --- | --- |
| continuous | 32 / 30 | 25 / 25 |
| turn | 12 / 8 | 10 / 7 |
| magnet | 40 / 20 | 35 / 18 |
| push | 20 / 19 | 16 / 12 |

Die öffentliche Fahrt überschreitet zwei innere Feldzentren mit **0.2876 / 0.2803 px/ms** im jeweiligen Mehrframefenster; Sollwert der geraden Folgesegmente: 50/180 ≈ 0,2778 px/ms. Der Test verlangt 0,20–0,35 px/ms an beiden Übergängen und echte Zwischenwinkel beim Drehen. Magnetziehen und Bolts Schieben halten in sämtlichen erfassten Frames exakt 50 Pixel Abstand zur Last (numerische Gleitkommatoleranz). Gehaltene Hindernisversuche erzeugen über weitere Frames keine neuen Aktionen oder Rückmeldungen. Eine simulierte 420-ms-Framepause erzeugt keine nachgeholten Züge.

Zusätzliche originale Canvas-PNG-Sequenzen für Fahrt, Magnet und Schieben liegen unter `local-motion/` und `public-motion/`. Sie wurden vom Coding-Agent stichprobenartig angesehen. Das ist kein 60-FPS-Versprechen: Bildrate hängt vom Rechner ab. Während der Entwicklung war der lokale Rechner zeitweise unter starker CPU-/Speicherlast; rohe Entwicklungsfehlläufe bleiben getrennt von den finalen Logs. Eine anfängliche Fahrprüfung traf korrekt auf das geschlossene Tor des Technikraums und wurde auf die freie Frachtstrecke gelegt. Ein veralteter OS-Repeat-Test wurde auf getrennte Tipp-/Halteprüfungen umgestellt; die Produktregeln wurden dafür nicht gelockert.

## Veröffentlichung, Schutz und Isolation

Nur `index.html` und die beiden exakten Buildassets wurden einmalig in das neue Releaseverzeichnis übertragen. Quelltexte, Git, Konfiguration, Belege und Sourcemaps liegen außerhalb des Webroots. [SHA-256-Manifest](../deploy/release-2026-11-03-fahrgefuehl.sha256) und [kompakter Receipt](../deploy/receipt-2026-11-03-fahrgefuehl.json) verbinden Release, Tests und Rohbelege.

Eigener VHost: `/etc/nginx/sites-available/shift-buddies.clippmann.de.conf`. Aktiver Link: `/var/www/shift-buddies/current`. Rootgeschütztes Backup: `/var/backups/shift-buddies-20261103T115853Z-d535f02edccc/`, mit `previous-current.txt`, `previous-vhost.conf`, `new-vhost.conf` und neuem Manifest. Vorgängerdateien und bisheriger VHost wurden vor Aktivierung geprüft. Der VHost erlaubt ausschließlich `/`, `/index.html` und die zwei aktuellen Assetpfade.

Aktivierung über den bestehenden Atlas-Weg: Assetprüfung, Sicherung, eigener VHost, `nginx -t`, atomarer Linkwechsel, sanfter NGINX-Reload mit gemeinsamem Fehler-Rückwechsel von VHost und Link. **Kein Serverrestart.** Master-PID `1449224` blieb erhalten. DNS, Cloudflare, Zertifikate und fremde Dienste wurden nicht verändert; es war kein Cloudflare-Befehl erforderlich.

**Öffentlich:** 22 HTTPS-/HTTP-/Hash-/Pfadprüfungen plus 404 des alten JS-Assets. Root, HTML und beide Assets entsprechen bytegenau dem lokalen Build. MIME, nosniff, noindex, HTTP-301 einschließlich Query und 17 interne/unbekannte gesperrte Pfade geprüft. OpenSSL bestätigt TLS, CA und Hostname. Zertifikatsfingerprint, Seriennummer und Laufzeiten sind vor/nach dem Update identisch.

**Nachbarisolation im Aktivierungsfenster:** Von 52 erfassten NGINX-/Renewaldateien und Aktivierungslinks änderte sich nur der eigene VHost. Alle **13 Nachbar-URLs** liefern vor/nach Aktivierung identischen Status und Body-SHA-256. Vorbestehende Fehlerstatus wurden nicht als von diesem Update behoben ausgegeben. Genaue Pfade und Statuswerte stehen im Receipt und den Vorher-/Nachherbelegen.

## Rückfall

Rückfall ist vorbereitet und geprüft, wurde nicht ausgeführt. **VHost und Link müssen gemeinsam zurück**, da die Assetfreigabe exakt ist. Auf Atlas bei beauftragtem Rückfall, ohne paralleles Deployment und nach Sicherung des dann aktiven eigenen Zustands:

1. `/var/backups/shift-buddies-20261103T115853Z-d535f02edccc/previous-vhost.conf` als eigenen VHost zurückkopieren; `nginx -t`. Bei Fehler den gesicherten neuen VHost wiederherstellen und nicht reloaden.
2. Temporären Symlink im selben Elternverzeichnis auf `releases/20261102T200807Z-cf33fb3dd55d` anlegen und per `mv -Tf` atomar als `/var/www/shift-buddies/current` aktivieren; danach ausschließlich `systemctl reload nginx`.
3. Bei Fehler neuen Link und passenden neuen VHost gemeinsam wiederherstellen, `nginx -t` und sanften Reload prüfen. Beide Releases behalten. Keine fremden VHosts, DNS oder Zertifikate anfassen.
4. Öffentliche Bytes gegen das Vorgängermanifest im vorherigen Backup prüfen, dessen damalige Bedienung und Nachbarvergleich wiederholen.

## Belege und Grenzen

Lokale Rohbelege: `.cache/deploy-drive-2026-11-03/`. Die Logs `rules.log`, `typecheck.log`, `build.log`, `local-browser.log` und `public-browser.log`, beide Browser-Result-Verzeichnisse mit vier Frame-JSONs, originale Canvassequenzen, HTTP/TLS, Aktivierung, Remote-Manifestprüfung, Zertifikatsvergleich, Atlas- und Nachbar-Snapshots sind durch den committed Receipt gehasht. Die bestehende Phaser-Bundlewarnung bleibt (1.224,52 kB JavaScript / 329,55 kB gzip).

Grenzen: Headless Chromium/Linux, simulierte Fenstergrößen und DOM-Blur/tabhidden; keine physische OS-Fokus-, Hör- oder menschliche Fahrgefühlabnahme. Keine erschöpfende Puzzleanalyse, Firefox/Safari oder itch.io-Einbettung. Keine Discordnachricht, kein AutoRun, kein weiterer Worker/Worktree und keine Callbackregistrierung. Mira liest diesen konkreten Ursprungstab selbst.
