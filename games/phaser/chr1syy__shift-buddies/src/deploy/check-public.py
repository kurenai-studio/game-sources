#!/usr/bin/env python3
"""Check public TLS/HTTP/build hashes, or snapshot neighboring sites before/after."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--neighbors", choices=["before", "after"])
parser.add_argument("--evidence", default=".cache/deploy-2026-11-02")
args = parser.parse_args()
evidence = Path(args.evidence)
evidence.mkdir(parents=True, exist_ok=True)
host = "https://shift-buddies.clippmann.de"

def get(url):
    # curl verifies the system CA chain and hostname; never use --insecure.
    response = subprocess.run(
        ["curl", "-4", "--silent", "--show-error", "--max-time", "45",
         "--path-as-is", "--include", url], check=True, capture_output=True).stdout
    headers, body = response.split(b"\r\n\r\n", 1)
    lines = headers.decode().split("\r\n")
    result = {"url": url, "status": int(lines[0].split()[1]),
              "sha256": hashlib.sha256(body).hexdigest(), "bytes": len(body),
              "headers": dict(line.split(": ", 1) for line in lines[1:] if ": " in line)}
    result["headers"] = {k.lower(): v for k, v in result["headers"].items()}
    return result

if args.neighbors:
    urls = ["https://clippmann.de/", "https://www.clippmann.de/", "https://clippmann.de/preview"]
    urls += ["https://preview.clippmann.de/" + path for path in
             ["", "styles.css", "script.js", "favicon.svg", "robots.txt"]]
    urls += ["https://rc-preview.clippmann.de/", "https://raidpresence.clippmann.de/",
             "https://app.synapse-tp.de/", "https://control.synapse-tp.de/",
             "https://logs.parrotosocial.club/"]
    with ThreadPoolExecutor(max_workers=8) as pool:
        results = list(pool.map(get, urls))
    (evidence / f"neighbors.{args.neighbors}.json").write_text(json.dumps(results, indent=2) + "\n")
    if args.neighbors == "after":
        before = json.loads((evidence / "neighbors.before.json").read_text())
        assert [(r["url"], r["status"], r["sha256"]) for r in results] == [
            (r["url"], r["status"], r["sha256"]) for r in before], "Neighbor changed; investigate evidence"
    print(json.dumps([{k: r[k] for k in ["url", "status", "sha256"]} for r in results], indent=2))
    raise SystemExit(0)

dist = Path("dist")
results = []
for file in sorted(dist.rglob("*")):
    if not file.is_file():
        continue
    path = file.relative_to(dist).as_posix()
    result = get(host + "/" + path)
    results.append(result)
    assert result["status"] == 200, result
    assert result["sha256"] == hashlib.sha256(file.read_bytes()).hexdigest(), result
    mime = {".html": "text/html", ".js": "application/javascript", ".css": "text/css"}[file.suffix]
    assert result["headers"]["content-type"].startswith(mime), result
    assert result["headers"]["x-content-type-options"] == "nosniff", result
    assert "noindex" in result["headers"]["x-robots-tag"], result
root = get(host + "/")
assert root["status"] == 200 and root["sha256"] == hashlib.sha256((dist / "index.html").read_bytes()).hexdigest()
results.append(root)
redirect = get("http://shift-buddies.clippmann.de/?test=redirect")
assert redirect["status"] == 301 and redirect["headers"]["location"] == host + "/?test=redirect"
results.append(redirect)
for path in ["/.git/config", "/.git/HEAD", "/.maestro/cue.yaml", "/README.md", "/package.json",
             "/package-lock.json", "/.env", "/src/main.ts", "/src/game/rules.ts", "/deploy/render-nginx.py",
             "/docs/2026-11-02-abnahme.md", "/index.html.bak", "/assets/", "/assets/README.md",
             "/assets/index.js.map", "/%2egit/config", "/unknown"]:
    result = get(host + path)
    assert result["status"] == 404, result
    results.append(result)
report = {"checked_at": datetime.now(timezone.utc).isoformat(), "results": results}
(evidence / "http-checks.json").write_text(json.dumps(report, indent=2) + "\n")
print(f"Passed {len(results)} public TLS/HTTP/hash/path requests")
