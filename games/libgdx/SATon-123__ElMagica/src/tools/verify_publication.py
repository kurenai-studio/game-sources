"""Offline checks for source exports, attribution files and packaged assets."""
from pathlib import Path
import hashlib
import json
import re
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
SKIP = {".git", ".gradle", ".idea", "build", "GitHub-ready", "play", "__pycache__"}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check(root=ROOT):
    errors = []
    files = [p for p in root.rglob("*") if p.is_file() and not any(s in SKIP for s in p.relative_to(root).parts)]
    for path in files:
        relative = path.relative_to(root).as_posix()
        if path.is_symlink():
            errors.append("Symlink in export: " + relative)
        if path.stat().st_size >= 100 * 1024 * 1024:
            errors.append("GitHub file size limit: " + relative)
        if path.name.startswith('.env') or path.suffix in {'.pem', '.key', '.p12', '.pfx', '.keystore', '.jks'}:
            errors.append("Possible credential file: " + relative)
        # Third-party authors' names and contact details belong to their notices.
        if relative.startswith(("docs/third-party/", "third-party-sources/")):
            continue
        if path.suffix in {'.java', '.py', '.gradle', '.properties', '.md', '.yml', '.json', '.xml', '.txt', '.bat'}:
            try:
                content = path.read_text(encoding='utf-8')
            except UnicodeDecodeError:
                errors.append("Non-UTF-8 text: " + relative)
                continue
            patterns = [r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
                        r'gh[pousr]_[A-Za-z0-9]{30,}', r'github_pat_[A-Za-z0-9_]{40,}',
                        r'sk-(?:proj-)?[A-Za-z0-9_-]{35,}', r'AKIA[0-9A-Z]{16}',
                        r'[A-Z]:[\\/]Users[\\/][^\s"\']+']
            if any(re.search(pattern, content) for pattern in patterns):
                errors.append("Possible secret or personal local path: " + relative)
    for name in ['LICENSE', 'THIRD_PARTY_NOTICES.md', 'SECURITY.md', 'docs/ASSETS.md', 'docs/LIBRARY_REPLACEMENT.md']:
        if not (root / name).is_file(): errors.append("Missing publication document: " + name)
    for manifest, prefix in [('docs/asset-manifest.json', 'assets/'), ('docs/third-party/manifest.json', '')]:
        path = root / manifest
        if not path.is_file():
            errors.append("Missing manifest: " + manifest)
            continue
        records = json.loads(path.read_text(encoding='utf-8'))
        if not records: errors.append("Empty manifest: " + manifest)
        for item in records:
            target = root / (prefix + item['file'])
            if not target.is_file() or sha(target) != item['sha256']:
                errors.append("Missing or changed attributed file: " + str(target.relative_to(root)))
    jar = root / 'lwjgl3/build/libs/ElMagica-1.0.0.jar'
    if jar.exists():
        with zipfile.ZipFile(jar) as archive:
            for path in (root / 'assets').rglob('*'):
                if path.is_file():
                    name = path.relative_to(root / 'assets').as_posix()
                    if name not in archive.namelist() or hashlib.sha256(archive.read(name)).hexdigest() != sha(path):
                        errors.append("Stale or missing packaged asset: " + name)
            for folder, prefix in [('docs/third-party', 'META-INF/third-party'), ('third-party-sources', 'META-INF/third-party-sources')]:
                for path in (root / folder).rglob('*'):
                    if path.is_file():
                        name = prefix + '/' + path.relative_to(root / folder).as_posix()
                        if name not in archive.namelist() or hashlib.sha256(archive.read(name)).hexdigest() != sha(path):
                            errors.append("Missing or stale packaged license/source: " + name)
    if errors:
        raise ValueError('\n'.join(errors))
    print(f"Publication checks passed: {len(files)} files, asset and license hashes, secret patterns, file sizes" + (", packaged JAR" if jar.exists() else ""))
    return files


if __name__ == '__main__':
    check(Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT)
