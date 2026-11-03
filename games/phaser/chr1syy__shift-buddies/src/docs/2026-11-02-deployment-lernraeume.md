# Live-Vorschau mit drei Räumen – 02.11.2026

**https://shift-buddies.clippmann.de/** zeigt die zwei neuen Lernräume und den erhaltenen Technikraum. Chris hat dieses Update ausdrücklich beauftragt. Der ursprüngliche Testraum war von ihm zuvor manuell als gut spielbar bestätigt worden; der neue Stand ist noch kein erneuter menschlicher Spieltest und kein itch.io-Release.

## Genauer Spielstand

**Spiel-SHA: `4266be7285477f3dd329f1bf3781219f39699e40`**, auf `origin/main` gepusht. Dieser Commit enthält alle veröffentlichten Spielquellen, Tests und das Buildmanifest. Der nachfolgende Dokumentationscommit ergänzt ausschließlich Releasebelege; er ändert keine Spielquellen oder Builddateien.

Umfang und spätere unverbindliche Jam-Vorschläge: [Feedbackrunde](2026-11-02-lernraeume.md). Die einmalige Einrichtung von DNS, TLS und Atlas bleibt in [der ursprünglichen Deploymentdokumentation](2026-11-02-deployment.md) erhalten. Deren Quellstand und Manifest beschreiben den Vorgänger, nicht dieses Update.

| Ressource | Wert |
| --- | --- |
| Ursprung | Atlas, SSH `root@89.58.57.228`, geprüfter bestehender Hostkey |
| Neuer Release | `/var/www/shift-buddies/releases/20261102T103116Z-4266be728547` |
| Aktiver Link | `/var/www/shift-buddies/current` → `releases/20261102T103116Z-4266be728547` |
| Direkter geprüfter Vorgänger | `releases/20261102T102637Z-2dfeabe53a7d` |
| Ursprünglicher Testraum ebenfalls erhalten | `releases/20261102T094000Z-c3efef15e564` |
| Eigener VHost | `/etc/nginx/sites-available/shift-buddies.clippmann.de.conf` |
| Rootgeschützte Sicherung | `/var/backups/shift-buddies-20261102T103116Z-4266be728547/` |
| Manifest | [release-2026-11-02-lernraeume.sha256](../deploy/release-2026-11-02-lernraeume.sha256) |
| Kompakter Beleg | [receipt-2026-11-02-lernraeume.json](../deploy/receipt-2026-11-02-lernraeume.json) |

## Abnahme

- **18 Regeltests**, TypeScript-Prüfung und Produktionsbuild bestanden. Die drei Beispielwege lösen die Räume mit **12 / 26 / 71 Aktionen** ohne abgewiesene Schritte. Jeder Undo-Snapshot und raumbezogener Neustart sind geprüft. Laufwegsuche bestätigt, dass Schacht, Platte, zwei Metallzüge und Strom nicht einfach umlaufen werden können. Diese Prüfung ist keine erschöpfende Suche über alle möglichen Spielzustände.
- **3 lokale Chromium-Browsertests** bestanden. Nach Beschriftungsabständen und Korrektur der Zeichenreihenfolge des Erfolgsfensters bestand der Lernraumtest erneut gegen den finalen Produktionsbuild auf Loopback. **Alle 3 Tests bestanden anschließend auch öffentlich über HTTPS**, ohne TLS-Bypass oder DNS-Override: kompletter Technikraum mit dauerhaftem Strom bei Shift und 71 Undo-Schritten; Buttons, Fokus, gehaltene Taste und 800-Pixel-Fenster; beide Lernräume, sichtbare Shift-Taste und beide Shift-Tasten, E/T per Klick und Tastatur, Weiter nach Sieg, Undo aus Sieg, direkte Technikraumwahl und getrennte Verläufe beim Raumwechsel. Keine Konsolen- oder Laufzeitfehler in den vollständigen Raumdurchläufen.
- **Screenshots persönlich durch den Coding-Agent angesehen:** Pips schmale Räder und Bolts breite Ketten; Hufeisen und Batterie in beiden Modulverteilungen; Blickrichtung getrennt vom zentralen Anbau und Aktivmarker; Metallkiste mit demselben Hufeisen gegenüber achteckigem, verankertem Keramikblock; beide Lernziele und Technikraumsieg. Die kleinen Aktionsringe sind vorübergehend und respektieren reduzierte Bewegung.
- **22 öffentliche HTTP-/TLS-/Hash-/Pfadprüfungen** bestanden. Startseite und genau drei Builddateien haben die lokalen SHA-256-Werte. MIME-Typen, `nosniff`, `noindex`, HTTP-Weiterleitung samt Query und 17 gesperrte interne/unbekannte Pfade geprüft. Die normalen öffentlichen Abrufe prüfen CA-Kette und Hostname. OpenSSL bestätigt zusätzlich **TLS 1.3, Verification OK** und den richtigen Hostnamen.
- **Isolation:** Alle **17 DNS-Records bytegleich** in den vor/nachher per `cf dns records list` gelesenen JSON-Listen; keine DNS-Schreibaktion. Von **52 erfassten NGINX-/Renewal-Einträgen** einschließlich Aktivierungslinks blieben **51 identisch**. Geändert wurde ausschließlich der eigene VHost mit den neuen exakten Assetpfaden. Zertifikat und Erneuerung blieben erhalten; keine neue Ausstellung oder Erneuerungsprobe nötig. NGINX-Konfigurationstest erfolgreich und nur sanfter Reload; Master-PID `1449224` unverändert. Die drei vorhandenen Warnungen zu Protokolloptionen bestehen weiter.
- **Alle 13 Nachbar-URLs mit identischem HTTP-Status und Body-SHA-256** vor/nachher: Portfolio und seine Dateien, RC-Preview, RaidPresence, Synapse App/Control und Logs bleiben 200. Hauptdomain, www und `/preview` lieferten vorher 522 und bleiben unverändert.
- **Rückfall erhalten:** Alle drei Dateien des Vorgängers nochmals gegen dessen Manifest geprüft. Passender alter VHost als `previous-vhost.conf` gesichert; sein Hash stimmt mit der vorher erfassten Konfiguration überein. Rückfall wurde nicht ausgeführt.

Übertragen wurden ausschließlich `index.html` und die zwei vom Renderer akzeptierten Vite-Assets. Kein Repository, `.maestro`, Quelltext, Screenshot, Releasebeleg, Sourcemap oder Secret wurde öffentlich ausgeliefert. Vor Aktivierung wurden die Remote-Dateien gegen das lokale Manifest geprüft, das vorherige Linkziel und der eigene VHost gesichert, `nginx -t` ausgeführt und `current` atomar gewechselt. Die Aktivierung hatte einen Fehlerpfad zur Wiederherstellung des alten Links samt VHost.

## Wiederholen der Prüfung

Vom passenden Spielstand aus, ohne neue Veröffentlichung:

```bash
npm test
npm run build
(cd dist && sha256sum -c ../deploy/release-2026-11-02-lernraeume.sha256)
python3 deploy/check-public.py --evidence .cache/recheck-learning
PLAYWRIGHT_BASE_URL=https://shift-buddies.clippmann.de \
  PLAYWRIGHT_BROWSERS_PATH=.cache/playwright npm run test:browser
```

Lokale Rohbelege: `.cache/deploy-learning-2026-11-02/` mit `atlas.before.json`, `atlas.after.json`, `dns.before.json`, `dns.after.json`, `neighbors.before.json`, `neighbors.after.json`, `isolation.json`, `http-checks.json`, `activation.log`, `tls.log`, `rollback-check.log`, `local-browser-final.log` und `public-browser.log`. Die acht Screenshots liegen als `.cache/technikraum-*.png` und `.cache/lernraum-*.png` vor; konkrete Namen und Hashes stehen im Beleg. Sie werden von weiteren Testläufen überschrieben. Browser und Testserver wurden nach den Prüfungen beendet; der bereits vorhandene Loopback-Vorschauserver wurde unverändert verwendet.

## Rückfall auf den geprüften Vorgänger

Nur bei beauftragtem Rückfall auf Atlas:

1. Aktuelles Linkziel und eigenen VHost sichern. Unter dem oben genannten Backupordner liegen bereits `previous-current.txt`, `previous-vhost.conf` und `new-vhost.conf` sowie `manifest.sha256` des neuen Releases.
2. Ausschließlich `previous-vhost.conf` auf den eigenen VHost zurückkopieren und `nginx -t` ausführen. Bei Fehler den neuen VHost aus `new-vhost.conf` wiederherstellen, keinen Reload ausführen und untersuchen.
3. Einen temporären Symlink im selben Elternverzeichnis auf `releases/20261102T102637Z-2dfeabe53a7d` anlegen und mit `mv -Tf` auf `/var/www/shift-buddies/current` atomar aktivieren. NGINX sanft neu laden. Scheitert der Reload, neuen Link und neuen VHost gemeinsam wiederherstellen und prüfen.
4. Öffentliche Abnahme gegen das **Vorgängermanifest** aus `/var/backups/shift-buddies-20261102T102637Z-2dfeabe53a7d/manifest.sha256` und seine Browsertests sowie den Nachbarvergleich wiederholen. Keine DNS- oder Zertifikatsänderung. Beide Releases aufbewahren.

Der alte VHost ist für den Rückfall nötig, weil NGINX nur die exakten Assetnamen des jeweils aktiven Builds freigibt. Nur den Symlink zurückzuwechseln genügt nicht.

## Grenzen

Genau drei spielbare Räume. Keine neuen Module, Gegner, Inventare, komplexe Menüs, Story, Speicherung oder Audio. Keine itch.io-Veröffentlichung. Prüfung mit Headless Chromium unter Linux und simulierten Fenstergrößen; Chris' neuer manueller Durchlauf sowie Firefox, Safari, physische Mobilgeräte und itch.io-Einbettung stehen aus. Die bekannte Phaser-Bundlewarnung bleibt: rund 1,21 MB JavaScript beziehungsweise 325 kB gzip. Keine Nachricht an Discord oder andere Agenten und kein behaupteter Callback; Mira kann diesen Tab lesen.
