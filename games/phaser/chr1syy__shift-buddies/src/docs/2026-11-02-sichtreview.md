# Sichtreview: freie Gesichter in allen Richtungen – 02.11.2026

**Live:** https://shift-buddies.clippmann.de/ · **Spiel-SHA:** `15641ccc188f460ad65baf05cff0fd13771e60c1`.

Miras Sichtbefund war richtig: Der bildschirmfest zentral platzierte Modulträger verdeckte Pips Augen nach unten vollständig und seitlich teilweise. Das wurde bei der ersten Sichtprüfung übersehen. Dieser Nachtrag korrigiert die entsprechende frühere Sichtabnahme. **Keine weiteren Features oder Regeländerungen.** Die [sechs Lösungswege und übrigen Eingaberegeln](2026-11-02-ausbau.md#sechs-überprüfte-lösungswege) bleiben gültig und wurden erneut durchgespielt.

## Gezielte Korrektur und vorhandene Fixes

- In `src/main.ts`, `drawRobot`: Der Modulträger sitzt jetzt neun Pixel **hinter** dem gedrehten Chassis (`−sin(angle)`, `+cos(angle)`). Die Symbole bleiben aufrecht lesbar; Träger, Leuchten und Anschlüsse folgen dem Heck. Auch während einer Drehung bleibt das Gesicht vorne frei. Keine Änderung an Roboterpositionen, Blickregeln, Magnetziehen oder Puzzlezuständen.
- **Magnetlinie bereits vor diesem Nachtrag korrigiert:** `redraw` verlangt aktiven Magnet, Ziehbereitschaft/Fahrt und `same(facingTarget(active), s.crate)`. Eine bloß benachbarte Kiste reicht nicht. Der Code steht unverändert auch im neuen Release.
- **Sockelbeschriftung bereits vor diesem Nachtrag korrigiert:** Ein Sockel mit benanntem Schaltkreis unterdrückt das generische „ANSCHLUSS“. Im Brückenraum steht am Sockel nur „BRÜCKE“; „BRÜCKE AN/AUS“ gehört zur räumlich getrennten Brücke. Finale öffentliche Aufnahme erneut angesehen.

## Reproduktion und Abnahme

Der neue Browsertest `both modules leave both robots' eyes readable in all four directions` bedient die echte Tastatur und liest Augenpixel aus dem tatsächlich gerenderten Canvas. Er prüft **32 Augen in 16 Kombinationen**: Pip/Bolt × Magnet/Batterie × oben/rechts/unten/links. Keine künstlich gesetzten Spielzustände und keine bloße Prüfung des Richtungsattributs.

**Differentieller Beleg:** Derselbe finale Test schlägt gegen den unveränderten vorherigen öffentlichen Build fehl (nach unten jeweils `0,0` sichtbare Augenpixel, seitlich teilweise verdeckt) und besteht gegen den korrigierten Produktionsbuild. Die Symptomprüfung wurde vor der Korrektur angelegt; ein späterer erneuter Lauf gegen den alten Live-Build bestätigt die endgültige Pixelschwelle. Alle 16 Aufnahmen wurden als vergrößerte Übersicht persönlich geprüft.

- **26 Regeltests**, Typecheck und Produktionsbuild bestanden. Bekannte Phaser-Größenwarnung bleibt.
- **7/7 Tests lokal gegen den finalen Produktionsbuild**, anschließend **7/7 öffentlich über HTTPS** bestanden. Einschließlich aller sechs Lösungen, Undo, E/Release/Fokus, Enter/Repeat, Brückensicherung, reduzierter Bewegung und der neuen Augenregression. Keine Konsolen-/Laufzeitfehler.
- Alle Browserläufe gegen **stabile Produktionsbuilds**. Während dieser Läufe keine Produktdateien verändert; kein HMR in der Endabnahme.
- **22 öffentliche TLS-/Hash-/Pfadprüfungen** bestanden. Drei öffentliche Builddateien bytegleich zum lokalen Manifest; CA-Kette und Hostname ohne Bypass geprüft.
- **13 Nachbar-URLs** mit gleichem Status und Bodyhash. Von 52 NGINX-/Renewal-Einträgen blieb alles außer dem eigenen VHost gleich; NGINX-Master **1449224**, Zertifikatsfingerprint und Laufzeit unverändert. Keine Cloudflare-/DNS-/Zertifikatsmutation. Keine Nachrichten, Worker oder Callback-/Cue-Registrierungen.

Originale und Logs: `.cache/review-facing-2026-11-02/` (ignoriert). **16 öffentliche Einzelbilder:** `public-poses/{pip,bolt}-{magnet,power}-{up,right,down,left}.png`; vollständige Pfade und Hashes im [Receipt](../deploy/receipt-2026-11-02-sichtreview.json). Die echte Bildübersicht liegt in `contactsheet.png`, lokale Aufnahmen separat in `local-poses/`. Die öffentlichen Sockel- und Magnetbilder liegen in `expansion-bridge-powered.png` und `expansion-magnet-link.png`. Reproduktions-/Abnahmelogs: `red-public-original.log`, `green.log`, `rules.log`, `build.log`, `local-browser.log`, `public-browser.log`; Deploymentbelege: `activation.log`, `http-checks.json`, `tls.log`, `isolation.json`, `neighbors.before.json`, `neighbors.after.json`, `rollback-check.log`, `reviewed.diff`.

## Release, Rückfall und Git

- Neuer unverändert aufbewahrter Release: `/var/www/shift-buddies/releases/20261102T142546Z-15641ccc188f`; `current` zeigt darauf.
- Vorheriger Release erhalten: **`releases/20261102T141127Z-0e18ed049061`**. Alle drei Dateien erneut gegen sein Manifest geprüft.
- Passender alter/neuer VHost und Manifest im rootgeschützten Backup **`/var/backups/shift-buddies-20261102T142546Z-15641ccc188f/`**. Nur eigene drei Builddateien und eigener VHost aktualisiert. `nginx -t`, atomarer Linkwechsel, sanfter Reload; Fehlerpfad stellt vorherigen Link und VHost gemeinsam wieder her.
- Bei beauftragtem Rückfall: `previous-vhost.conf` aus diesem Backup auf den eigenen VHost kopieren, `nginx -t`, `current` atomar auf obigen Vorgänger setzen und sanft neu laden. Bei Fehler neuen Link/VHost gemeinsam wiederherstellen. Danach mit dem Vorgängermanifest unter `/var/backups/shift-buddies-20261102T141127Z-0e18ed049061/manifest.sha256` und dessen Browsertests prüfen. Linkwechsel allein genügt wegen exakter Assetfreigaben nicht. Rückfall **nicht ausgeführt**; beide Releases bleiben erhalten.
- Aktuelles Manifest: `deploy/release-2026-11-02-sichtreview.sha256`. Erneute Prüfung: `npm test`, `npm run build`, `(cd dist && sha256sum -c ../deploy/release-2026-11-02-sichtreview.sha256)`, `python3 deploy/check-public.py --evidence .cache/recheck-facing` und der öffentliche Browsertest mit `PLAYWRIGHT_BASE_URL=https://shift-buddies.clippmann.de PLAYWRIGHT_BROWSERS_PATH=.cache/playwright npm run test:browser`.
- Spielcommit auf `origin/main` gepusht. Bericht und Receipt folgen separat; abschließend `main = origin/main`, Checkout sauber. Exakter Abgleich unter `.cache/review-facing-2026-11-02/final-git.log`. Nach dem Spiel-SHA nur Dokumentationsänderungen.

Grenzen unverändert: Headless Chromium/Linux; menschlicher Spiel-/Hörtest, physischer OS-Fokuswechsel, Firefox/Safari und itch.io-Einbettung bleiben offen. Kein itch.io-Release und keine weiteren Features.
