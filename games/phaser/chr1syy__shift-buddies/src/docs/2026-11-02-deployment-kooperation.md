# Geprüfte Kooperationsvorschau – 02.11.2026

**Spielbereit:** https://shift-buddies.clippmann.de/ · ausdrücklich von Chris beauftragtes Update der bestehenden Vorschau. Alle sechs Räume wurden über die öffentliche URL mit echten Browser-Tastatureingaben gelöst. Dies ist eine Spieltestversion für Chris, noch keine unabhängige menschliche Abnahme und kein itch.io-Release.

## Exakter Stand und Änderungen

- **Spiel-SHA:** `cf33fb3dd55da93b229cca2954b7dfcfec120f4e`.
- **Prüfcommit:** `cfd996d06f43377497b1faaa49f091f03f77afba`; ergänzt ausschließlich Tests und Manifest. Der anschließende Berichtcommit ändert nur README, Dokumentation und Receipt. Spielquellen, HTML, Abhängigkeiten und Buildbytes entsprechen dem beauftragten Spiel-SHA; keine Spielcodekorrektur nötig.
- `tests/solution.ts` folgt jetzt den [dokumentierten neuen Wegen](2026-11-02-kooperation.md). Aktionen pro Raum: **12 / 26 / 42 / 56 / 49 / 43**. Raum 4 enthält eine absichtliche Blickänderung gegen die Kiste vor dem Kraftschieben.
- `tests/rules.test.ts` und `tests/browser.spec.ts` wurden auf neue Koordinaten und Schaltkreisnamen A/C umgestellt. Zusätzliche gezielte Prüfungen für Schieben mit beiden Modulen, Hindernisse, Schachtgrenzen, Magnetziehen beider Körper und erforderliche Kooperation. Keine neuen Abhängigkeiten oder Testinfrastruktur.
- Dokumentationskorrektur: Abgewiesene E+Richtungsversuche lassen die Bereitschaft bis zum Loslassen bestehen; sie ändern weder Position noch Blick. Die frühere Aussage, jede Kontextabweisung lösche sie, war unzutreffend. Shift/T/Z/R/Raumwahl und Fokusverlust setzen sie weiterhin zurück.

## Konkrete Abnahme

**29 Regeltests**, Typecheck und Produktionsbuild bestanden. Jeder Zustands-Snapshot der sechs Lösungen wird einschließlich Modulen, Blick, Fracht und Verbindung per Undo exakt wiederhergestellt. Neustart und Raumwahl leeren den jeweiligen Verlauf. Gezielte Negativversuche und geometrische Erreichbarkeit prüfen zentrale Sperren; sie sind kein vollständiger Zustandsraumbeweis.

**8/8 Browserprüfungen lokal gegen den stabilen Produktionsbuild**, anschließend **8/8 über normales öffentliches HTTPS** bestanden, ohne Zertifikats- oder DNS-Bypass:

- Sechs vollständige Tastaturlösungen, vollständiges Undo und erneutes Lösen mit reduzierter Bewegung; Weiter/Enter mit Buttonfokus, gehaltenem Enter und Abschluss des letzten Raumes.
- T/Shift, beide Shift-Tasten, Klickäquivalente, fortbestehender Strom beim Botwechsel, Raumwahl, Neustart und Undo aus Sieg.
- Magnetziehen, kein seitliches/ungewolltes Vorwärtsfahren mit E, kein Keyrepeat, Loslassen und Blur; Kontextwechsel setzen die Bereitschaft zurück. Physischer OS-Fokusverlust wird durch ein explizites DOM-Blur-Ereignis angenähert.
- Bolt schiebt in Raum 4 mit Magnet und in Raum 5 mit Batterie. E allein, normales Fahren und seitliche E-Richtung schieben nicht; Wand hinter der Fracht blockiert; Undo stellt Bot und Kiste wieder her. Pip zieht in der Raum-5-Lösung weiter mit Magnet.
- Brücke bleibt bei Stromverlust unter einem Passagier ausgefahren und schließt nach dessen Abfahrt. Ton bleibt zunächst aus, Ein-/Ausschalter geprüft; keine Hörabnahme behauptet.
- 800-Pixel-Fenster ohne horizontalen Überlauf; Canvas-Augenprüfung für 32 Augen in 16 Körper-/Modul-/Richtungskombinationen. Keine Konsolen- oder Laufzeitfehler.

Der erste lokale Durchlauf hatte zwei veraltete Textprüfungen (`TÜR ZU` / `BRÜCKE ZU` statt `A ZU` / `C ZU`). Nach deren Anpassung bestand der vollständige finale Lauf. Während der finalen Browserläufe keine Produktdateien bearbeitet, kein HMR in der Releaseabnahme. Start-, Versorgungs-, Fracht- und Abschlussscreenshots wurden vom Coding-Agent angesehen; öffentliche Belege liegen separat vom lokalen Durchlauf.

**Öffentliche Auslieferung:** 22 HTTP-/TLS-/Hash-/Pfadprüfungen bestanden. `/`, `index.html` und beide Assets stimmen bytegenau mit lokalem Build/Manifest überein. MIME-Typen, `nosniff`, `noindex`, HTTP-301 mit Query und 17 gesperrte interne/unbekannte Pfade geprüft. Das alte JavaScript-Asset liefert zusätzlich 404. OpenSSL bestätigt TLS 1.3, CA-Verifikation und Hostnamen. Zertifikat/Fingerprint/Laufzeit blieben erhalten.

## Release und Isolation

| Ressource | Wert |
| --- | --- |
| Release | `/var/www/shift-buddies/releases/20261102T200807Z-cf33fb3dd55d` |
| Aktiver Link | `/var/www/shift-buddies/current` → `releases/20261102T200807Z-cf33fb3dd55d` |
| Erhaltener direkter Vorgänger | `releases/20261102T142546Z-15641ccc188f` |
| Eigener VHost | `/etc/nginx/sites-available/shift-buddies.clippmann.de.conf` |
| Rootgeschützte Sicherung | `/var/backups/shift-buddies-20261102T200807Z-cf33fb3dd55d/` |
| Manifest | [release-2026-11-02-kooperation.sha256](../deploy/release-2026-11-02-kooperation.sha256) |
| Prüfbeleg | [receipt-2026-11-02-kooperation.json](../deploy/receipt-2026-11-02-kooperation.json) |

Nur `index.html` und die beiden exakten Vite-Assets wurden nach Atlas übertragen. Keine Quelltexte, Repositorydaten, Sourcemaps, Screenshots oder Belege im Webroot. Neue Releaseadresse einmalig angelegt und danach nicht überschrieben. Remote-Dateien vor und nach Aktivierung gegen das Manifest geprüft. Vorgänger, vorheriges Linkziel und passender alter VHost erhalten. Der VHost erlaubt ausschließlich `/`, `/index.html` und die zwei aktuellen Assetpfade; alle anderen HTTPS-Pfade liefern 404.

Aktivierung: eigener VHost installiert, **`nginx -t` vor Reload**, atomarer Linkwechsel und sanfter Reload mit Fehlerpfad zum gemeinsamen Rückwechsel von VHost und Link. Kein Serverrestart. Master-PID **1449224** unverändert. Die drei bereits vorhandenen NGINX-Protokollwarnungen blieben bestehen.

**Nachbarisolation:** Von **52** erfassten NGINX-/Renewaldateien und Aktivierungslinks sind **51 unverändert**; ausschließlich der eigene VHost hat neue Assetpfade. Alle **13 Nachbar-URLs** liefern gleichen Status und Body-SHA-256 wie vor dem Update: Portfolio mit seinen Dateien, RC-Preview, RaidPresence, Synapse App/Control und Logs bleiben 200; Hauptdomain, www und `/preview` bleiben bei ihrem vorbestehenden 522. Fremde Dienste wurden nicht verändert. Keine Cloudflare-/DNS-Befehle oder -Mutation, keine Zertifikatsänderung.

## Rückfall

Vorgängerdateien wurden nochmals gegen ihr Manifest geprüft; der gesicherte Vorgänger-VHost hat exakt den vorher erfassten Hash. **Rückfall aufbewahrt und geprüft vorbereitet, nicht ausgeführt.** Ein Linkwechsel allein reicht wegen der exakten Assetfreigaben nicht.

Bei beauftragtem Rückfall auf Atlas, nach Sicherung des dann aktiven eigenen Links/VHosts und ohne paralleles Deployment:

1. `/var/backups/shift-buddies-20261102T200807Z-cf33fb3dd55d/previous-vhost.conf` auf den eigenen VHost zurückkopieren und `nginx -t` prüfen. Bei Fehler `new-vhost.conf` aus demselben Backup wiederherstellen und keinen Reload ausführen.
2. Temporären Symlink im selben Elternverzeichnis auf `releases/20261102T142546Z-15641ccc188f` anlegen und per `mv -Tf` atomar als `/var/www/shift-buddies/current` aktivieren; anschließend `systemctl reload nginx`.
3. Bei Reloadfehler neuen VHost und neuen Link gemeinsam wiederherstellen, `nginx -t` und sanften Reload prüfen. Keine fremden VHosts/Links anfassen.
4. Öffentliche Bytes gegen das Vorgängermanifest `/var/backups/shift-buddies-20261102T142546Z-15641ccc188f/manifest.sha256` und Bedienung mit dessen damaligen Tests prüfen; Nachbarvergleich wiederholen. Beide Releases behalten; DNS/Zertifikat bleiben bestehen.

Im aktuellen Backup liegen `previous-current.txt`, `previous-vhost.conf`, `new-vhost.conf` und das neue `manifest.sha256` außerhalb des Webroots.

## Nachprüfen und Belege

Vom passenden Checkout, ohne Deployment:

```bash
npm test
npm run build
(cd dist && sha256sum -c ../deploy/release-2026-11-02-kooperation.sha256)
python3 deploy/check-public.py --evidence .cache/recheck-cooperation
PLAYWRIGHT_BASE_URL=https://shift-buddies.clippmann.de \
  PLAYWRIGHT_BROWSERS_PATH=.cache/playwright npm run test:browser
```

Lokale Rohbelege: `.cache/deploy-cooperation-2026-11-02/`. Darin `rules.log`, `typecheck.log`, `build.log`, `local-browser.log`, `public-browser.log`, `http-checks.json`, `tls.log`, `activation.log`, `atlas.before.json`, `atlas.after.json`, `isolation.json`, `neighbors.before.json`, `neighbors.after.json`, `remote-final.log`, `release.json`, `local-screenshots/` und `public-screenshots/`. Der kompakte committed Receipt enthält SHA-256-Werte der zentralen Belege und öffentlichen Bilder. Historische Manifeste/Receipts bleiben erhalten.

Grenzen: Headless Chromium auf Linux, simulierte Fenstergrößen und Fokusereignisse; Chris' eigener Spieltest, Firefox/Safari, physische Mobilgeräte, Hörabnahme und itch.io-Einbettung stehen aus. Keine erschöpfende Puzzleanalyse. Die bekannte Phaser-Bundlewarnung bleibt (1.221,96 kB JavaScript / 328,68 kB gzip). Keine Discordnachricht, neue Automation oder Callbackregistrierung; Mira liest diesen Ursprungstab selbst.
