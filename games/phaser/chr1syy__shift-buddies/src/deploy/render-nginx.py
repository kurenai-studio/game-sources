#!/usr/bin/env python3
"""Render this subdomain's vhost; only explicit Vite build files are public."""
import argparse
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--http-only", action="store_true", help="ACME bootstrap, no game served")
args = parser.parse_args()
host = "shift-buddies.clippmann.de"
print(f"""server {{
    listen 80;
    listen [::]:80;
    server_name {host};
    server_tokens off;
    location ^~ /.well-known/acme-challenge/ {{
        root /var/www/letsencrypt;
        default_type text/plain;
        try_files $uri =404;
    }}
    location / {{ return 301 https://{host}$request_uri; }}
}}""")
if args.http_only:
    raise SystemExit(0)

dist = Path(__file__).resolve().parent.parent / "dist"
paths = sorted(path.relative_to(dist).as_posix() for path in dist.rglob("*") if path.is_file())
assert "index.html" in paths, "Run npm run build first"
assert not any(path.is_symlink() for path in dist.rglob("*")), "No symlinks allowed"
assert all(path == "index.html" or re.fullmatch(r"assets/index-[A-Za-z0-9_-]+\.(js|css)", path)
           for path in paths), f"Unexpected public file: {paths}"
print(f"""
server {{
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name {host};
    server_tokens off;
    root /var/www/shift-buddies/current;
    autoindex off;
    charset utf-8;
    ssl_certificate /etc/letsencrypt/live/{host}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/{host}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    add_header X-Robots-Tag "noindex,nofollow,noarchive" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Cache-Control "no-cache" always;
    location = / {{ try_files /index.html =404; }}""")
for path in paths:
    print(f"    location = /{path} {{ try_files $uri =404; }}")
print("    location / { return 404; }\n}")
