# Öffentlicher Testraum vom 02.11.2026

> Historischer Erstdeploy. Die freigegebene Aktualisierung mit zwei Lernräumen steht in [Deployment der drei Räume](2026-11-02-deployment-lernraeume.md), einschließlich aktuellem Spiel-SHA und Rückfall auf diesen Vorgänger.

Adresse: **https://shift-buddies.clippmann.de/**. Chris hat die Einrichtung genau dieser Subdomain einschließlich DNS, TLS und statischem Deployment ausdrücklich freigegeben. Keine weiteren Veröffentlichungen, bezahlten Dienste oder Nachrichten an Dritte.

## Quellstand und Hosting

Spielquellstand: **`c3efef15e5649c8d70dd5f54631b07bf3216b3b8`**. Der Checkout war vor Beginn sauber. Die späteren Änderungen betreffen ausschließlich Deploymentdokumentation, Hilfsskripte und die optionale öffentliche Zieladresse im vorhandenen Browsertest. Spielcode und gebaute Spielinhalte bleiben diesem Quellstand zugeordnet.

Der kleinste passende Weg nutzt den bereits laufenden **Atlas mit NGINX**, ohne zusätzlichen Anwendungsprozess und ohne neues Cloudflare-Pages-Projekt. SSH-Ziel `root@89.58.57.228`, Hostname `atlas`, vorhandener vertrauenswürdiger ED25519-Hostkey `SHA256:RHiXc6ctNMCl5MbjlNHpk7G/PB5CccqNiD2BHcK3JDk`. Der lokale Kurzname `atlas` ist nicht auflösbar; SSH verwendet die geprüfte IP und `StrictHostKeyChecking=yes`.

| Ressource | Wert |
| --- | --- |
| DNS | eigener A-Record `shift-buddies.clippmann.de` → `89.58.57.228`, DNS-only, TTL 300 |
| Cloudflare-Record-ID | `8e2abbc6a557aae6f488e06a57db33d8` |
| Remote-Release | `/var/www/shift-buddies/releases/20261102T094000Z-c3efef15e564` |
| Aktivierung | `/var/www/shift-buddies/current` → `releases/20261102T094000Z-c3efef15e564` |
| VHost | `/etc/nginx/sites-available/shift-buddies.clippmann.de.conf`, gleichnamiger Aktivierungslink in `sites-enabled` |
| Zertifikat | `/etc/letsencrypt/live/shift-buddies.clippmann.de/`, Let's Encrypt, gültig bis 31.01.2027 |
| Erneuerung | vorhandener aktiver `certbot.timer`, HTTP-Webroot `/var/www/letsencrypt`, eigener Renewal-Eintrag und getesteter Reloadhook |
| Betriebsbelege auf Atlas | `/var/backups/shift-buddies-20261102/`, nur root zugänglich |

Die Releasekennung ist ein Verzeichnisname; die tatsächlichen Zeitstempel stehen in den lokalen Belegen. Cloudflare wurde ausschließlich mit **`cf`** bedient. Die Befehlsuche enthielt nur anonyme Aktionen/Ressourcentypen. Es wurde keine Wrangler-Konfiguration angelegt. Vorher gab es keinen exakten DNS-Eintrag oder VHost für diese Subdomain; die bestehende Wildcard zeigte auf einen anderen Ursprung und lieferte HTTP 522. Nur ein neuer A-Record kam hinzu.

## Öffentliche Dateien

Nur die drei Dateien aus `npm run build` wurden übertragen. Kein Repository, keine README, `.git`, `.maestro`, Quelltexte, Sourcemaps oder Secrets. NGINX gibt ausschließlich `/`, `/index.html` und die zwei exakten Assetpfade frei; andere Pfade liefern 404. HTTP leitet mit erhaltenem Pfad/Query auf HTTPS um. TLS 1.2/1.3, `nosniff`, `no-cache` und `X-Robots-Tag: noindex,nofollow,noarchive` sind aktiv. noindex ist kein Zugriffsschutz; die URL ist öffentlich.

Verbindliches Manifest: [deploy/release-2026-11-02.sha256](../deploy/release-2026-11-02.sha256).

| Datei | SHA-256 |
| --- | --- |
| `index.html` | `ce412962cdcd6fa39bc23ded516616a33242afcf670f605307d60f007929b57d` |
| `assets/index-Bd4MDVS7.css` | `3b48ecfa95f53f05eab132cd3dad5f859ed93c450f29902c5b5ae986c8b1d8d2` |
| `assets/index-Bk6ixVLu.js` | `655256dffa1cffaafeb2b50baac6802da82d47ba86b62395e386e1a8517068db` |

## Tatsächliche Abnahme

Am 02.11.2026 erfolgreich abgeschlossen:

- **11 Regeltests**, TypeScript-Prüfung und Produktionsbuild bestanden. Spielquellen, HTML-Einstieg, Abhängigkeiten und Tests sind weiterhin identisch zum angegebenen Spielquellstand.
- **22 öffentliche HTTP-/TLS-/Hash-/Pfadabrufe** bestanden: `/` und alle drei Builddateien mit HTTP 200 und korrektem SHA-256, passende MIME-Typen und Header, HTTP-301-Weiterleitung mit Query sowie 17 gesperrte interne/unbekannte Pfade mit 404.
- **2 Chromium-Browsertests gegen die normale öffentliche HTTPS-Adresse** bestanden, ohne DNS-Override oder ignorierte Zertifikatsfehler: kompletter Lösungsweg mit 71 Aktionen, beide Roboter auf den Ausgangsfeldern, Tür danach geschlossen, dauerhafte Versorgung beim Roboterwechsel, alle 71 Undo-Schritte, Neustart, Fokus, Buttons und 800-Pixel-Fenster. Keine Konsolen- oder Laufzeitfehler im vollständigen Lösungsdurchlauf. Öffentliche Start- und Siegscreenshots selbst angesehen; Spielfeld, Roboterkarten und Erfolgsanzeige sind sichtbar.
- **TLS 1.3 mit überprüfter CA-Kette und Hostname** per OpenSSL bestätigt. Zertifikat: Let's Encrypt YE2, 02.11.2026 08:38:21 UTC bis 31.01.2027 08:38:20 UTC. Die auf dieses Zertifikat begrenzte **Erneuerungsprobe einschließlich Reloadhook** bestand. Der erste Probelauf wurde während seines zufälligen Warteintervalls gezielt beendet und einmal ohne Zufallswartezeit erfolgreich wiederholt; keine doppelten Erneuerungsjobs bleiben laufen.
- **Isolation:** Alle **16 vorher vorhandenen DNS-Einträge** unverändert, genau ein neuer Record. Alle **51 erfassten bestehenden NGINX-/Renewal-Hashes und Aktivierungslinks** unverändert, genau drei neue Einträge: eigener VHost, sein Aktivierungslink und eigener Renewal-Eintrag. NGINX-Konfigurationstest erfolgreich, Master-PID `1449224` unverändert; nur sanfte Reloads. Die drei schon vorher vorhandenen Warnungen zu Protokolloptionen bleiben unverändert. Zertifikatstimer aktiv.
- **13 Nachbar-URLs vorher/nachher mit identischem Status und Body-SHA-256:** Portfolio mit allen fünf Dateien sowie RC-Preview, RaidPresence, Synapse App/Control und Logs bleiben HTTP 200. Hauptdomain, www und `clippmann.de/preview` lieferten bereits vorher HTTP 522 und bleiben unverändert. Kein Versuch, diese bestehenden Fehler beiläufig zu reparieren.
- Remote-Release enthält exakt die drei erwarteten Dateien; deren Hashes nochmals direkt auf Atlas bestätigt. Rückfall dokumentiert, nicht ausgeführt. Kein Deployment nach itch.io, kein Discordsend und kein Callback behauptet oder eingerichtet.

Kompakter Prüfbeleg mit Ressourcen, Ergebnissen und Nachbar-Hashes: [deploy/receipt-2026-11-02.json](../deploy/receipt-2026-11-02.json). Lokale Rohbelege liegen ausschließlich unter `.cache/deploy-2026-11-02/`: `dns.before.json`, `dns.after.json`, `dns.created.json`, `atlas.before.txt`, `atlas.after.txt`, `neighbors.before.json`, `neighbors.after.json`, `http-checks.json`, `browser.log`, `tls.log`, `certbot-issue.log`, `certbot-renew-final.log`, `remote-final.log` und die beiden öffentlichen Screenshots `start.png` / `solved.png`. Diese internen Belege werden nicht mit der Website ausgeliefert.

## Wiederholen der Abnahme

Aus dem Repository mit Node 24+, Python 3, curl und dem vorhandenen Chromium:

```bash
npm ci --cache .cache/npm
npm test
npm run build
(cd dist && sha256sum -c ../deploy/release-2026-11-02.sha256)
python3 deploy/check-public.py
PLAYWRIGHT_BASE_URL=https://shift-buddies.clippmann.de \
  PLAYWRIGHT_BROWSERS_PATH=.cache/playwright npm run test:browser
```

Ohne `PLAYWRIGHT_BASE_URL` startet der unveränderte lokale Testablauf seinen eigenen Loopback-Server. Mit Zieladresse läuft dieselbe Prüfung direkt gegen die öffentliche URL, einschließlich sichtbarem Spielfeld, kompletter 71-Aktionen-Lösung, Stromerhalt bei Shift, Undo aller Aktionen, Neustart, Fokus, Buttons und schmalerem Fenster. Screenshots werden unter `.cache/technikraum-start.png` und `.cache/technikraum-geloest.png` erneuert. Kein TLS-Bypass und keine umgebogene DNS-Auflösung im endgültigen öffentlichen Test.

Vor und nach einer ausdrücklich beauftragten späteren Änderung:

```bash
python3 deploy/check-public.py --neighbors before --evidence .cache/next-deployment
# Erst dann die freigegebene Änderung durchführen.
python3 deploy/check-public.py --neighbors after --evidence .cache/next-deployment
```

Das vergleicht Status und Antwortbytes von 13 URLs: Hauptdomain, www, `/preview`, alle fünf Portfolio-Dateien sowie RC-Preview, RaidPresence, Synapse App/Control und Logs. Zusätzlich DNS und fremde NGINX-/Renewaldateien samt Aktivierungslinks vorher/nachher erfassen und vergleichen. Ein grüner HTTP-Vergleich allein beweist keine unveränderte Konfiguration.

## Einrichtung und spätere Releases

Die einmalige Einrichtung ist abgeschlossen. Die folgenden Schritte dokumentieren den Vorgang und sind **kein neuer Deploymentauftrag**.

1. Sauberen Quellstand und Zugriff prüfen; DNS mit `cf dns records list --zone clippmann.de --per-page 500` erfassen. Exakte Belegung, Wildcard, AAAA/CNAME/NS/CAA und bestehende Atlas-VHosts prüfen. Fremde Änderungen erhalten.
2. Bauen, Manifest erzeugen und mit `python3 deploy/render-nginx.py` den VHost generieren. Das Skript verweigert unerwartete Dateinamen und Symlinks. Für die erstmalige ACME-Einrichtung erzeugt `--http-only` den HTTP-VHost ohne Spielauslieferung. Nur diesen VHost aktivieren und vor jedem Reload `nginx -t` prüfen.
3. Genau den neuen DNS-Record anlegen; keine vorhandenen Einträge überschreiben:

   ```bash
   cf dns records create --zone clippmann.de --body '{"type":"A","name":"shift-buddies.clippmann.de","content":"89.58.57.228","ttl":300,"proxied":false,"comment":"Shift Buddies isolated static test room; authorized 2026-11-02"}'
   ```

4. Autoritative und rekursive Auflösung prüfen. Auf Atlas das eigene Zertifikat mit bestehendem ACME-Konto und Webroot ausstellen:

   ```bash
   certbot certonly --webroot -w /var/www/letsencrypt \
     -d shift-buddies.clippmann.de --cert-name shift-buddies.clippmann.de \
     --non-interactive \
     --deploy-hook '/usr/sbin/nginx -t && /usr/bin/systemctl reload nginx'
   ```

   Bei mehreren ACME-Konten das bereits vorhandene Konto über `--account` auswählen; keine Konto- oder Zugangsdaten ins Repository aufnehmen. NGINX-Plugin nicht verwenden, damit fremde VHosts unberührt bleiben. Begrenzte Erneuerungsprobe: `certbot renew --cert-name shift-buddies.clippmann.de --dry-run --run-deploy-hooks --no-random-sleep-on-renew`.
5. Unter `/var/www/shift-buddies/releases/<neue-kennung>` ein neues Verzeichnis anlegen und **nur die vom Renderer akzeptierten Builddateien** per tar/scp übertragen. Verzeichnisse 755, Dateien 644. Lokales Manifest separat außerhalb des Webroots nach Atlas kopieren und dort mit `sha256sum -c` bestätigen. Nie den Repository-Stamm übertragen.
6. Bisheriges `current`-Ziel sowie den eigenen VHost sichern. Neue Aktivierung in demselben Elternverzeichnis vorbereiten, dann atomar mit `mv -Tf` ersetzen. Den zum Build passenden VHost installieren; dessen exakte Assetfreigaben ändern sich bei neuen Assetnamen. Vor Reload `nginx -t`; bei Fehlern nur eigenen VHost und eigenen Aktivierungslink wiederherstellen. Alte Releases aufbewahren. Beim Erstdeploy wurde `current` neu angelegt, da kein vorheriger Spielrelease existierte.
7. Öffentliche Abnahme und Nachbarvergleich ausführen; erst danach den neuen Stand als geprüft melden. DNS-Caches können zuvor gespeicherte Wildcard-Antworten noch bis zum Ablauf ihrer TTL liefern. Ein erfolgreicher `curl --resolve` eignet sich als Zwischenprüfung des Ursprungs, ersetzt aber den abschließenden normalen URL-Test nicht.

## Rückfall

Da es vor diesem Auftrag keine Spielsite gab, stellt ein vollständiger Rückbau den vorherigen Wildcardzustand wieder her. Nur die hier angelegten Ressourcen anfassen. Zunächst VHost deaktivieren, Konfiguration testen und sanft neu laden; keinen NGINX-Neustart und keine fremden Symlinks ändern:

```bash
# Auf Atlas: Originaldateien zur Diagnose behalten, nur eigenen Link verschieben.
mv /etc/nginx/sites-enabled/shift-buddies.clippmann.de.conf \
  /var/backups/shift-buddies-20261102/disabled-vhost.link
nginx -t && systemctl reload nginx

# Lokal: ausschließlich den neu angelegten Record entfernen.
cf dns records delete 8e2abbc6a557aae6f488e06a57db33d8 --zone clippmann.de --force
```

Bei fehlgeschlagenem Konfigurationstest den eigenen Aktivierungslink zurücklegen und keinen Reload ausführen. Nach dem DNS-Rückbau den eigenen Renewal-Eintrag `/etc/letsencrypt/renewal/shift-buddies.clippmann.de.conf` in den rootgeschützten Backupordner verschieben, damit keine erfolglose Erneuerung läuft. Zertifikat, privater Schlüssel und Release bleiben auf Atlas erhalten, werden nicht öffentlich ausgeliefert und nicht gelöscht. Nach DNS-Cacheablauf gilt wieder die erhaltene Wildcard; vor Auftrag war das HTTP 522, keine funktionierende Spielseite. Rückbau wurde dokumentiert, nicht ausgeführt.

Bei späteren Spielreleases genügt normalerweise der atomare Rückwechsel auf den erhaltenen Vorgänger plus dessen passenden VHost mit anschließender Abnahme; DNS und Zertifikat bleiben dann bestehen.

## Grenzen

Ein einzelner öffentlicher Testraum, keine Anmeldung oder Speicherung, kein fertiger Game-Off-Release und noch keine itch.io-Veröffentlichung. Der Betrieb hängt vom vorhandenen Atlas und seiner Zertifikatserneuerung ab. Keine neue kostenpflichtige Leistung. Headless Chromium unter Linux und simulierte Fenstergrößen ersetzen keinen Test auf Chris' Büro-PC, in Firefox/Safari oder auf physischen Mobilgeräten. Das Phaser-Bundle hat weiterhin rund 1,21 MB beziehungsweise 324 kB gzip vor Übertragungskompression; die bekannte Buildwarnung bleibt bestehen. Bestehende Hauptdomain-522-Probleme gehören nicht zu diesem Auftrag.
