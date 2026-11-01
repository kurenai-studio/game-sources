#!/usr/bin/env python3
"""Verify the portable LÖVE package against the live builder contract.

Loads the real scripts/build.py module directly and uses its source_entries()
allowlist as the authoritative package contract; never invokes a build. Checks
archive/manifest/source path sets and bytes, duplicate or forbidden paths, ZIP
CRC integrity (including the actual bad filename), fixed 1980-01-01 timestamps
and normal 0644 permissions, the archived copy of every game/maps module, and
public_release=false.

--remember stores the FIRST VERIFIED archive/manifest baseline under the ignored
artifacts/reports directory; a plain run requires both the archive and manifest
to be byte-equal to that baseline. The generated dist/BUILD_MANIFEST.json and
dist/neon-courier.love are ignored build outputs, not committed files.
"""
import hashlib
import importlib.util
import json
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / "dist"
LOVE = DIST / "neon-courier.love"
MANIFEST = DIST / "BUILD_MANIFEST.json"
REPORTS = ROOT / "artifacts" / "reports"
FIXED_TIME = (1980, 1, 1, 0, 0, 0)

FORBIDDEN_PREFIXES = ("dist/", "node_modules/", ".git/", "docs/", "tests/",
                      "artifacts/", ".opencode/", ".superpowers/")


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_builder_entries():
    spec = importlib.util.spec_from_file_location("neon_build_contract",
                                                 ROOT / "scripts" / "build.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    entries = module.source_entries()
    expected = {}
    for name, data, _ in entries:
        if name in expected:
            raise SystemExit(f"builder produced a duplicate entry: {name}")
        expected[name] = hashlib.sha256(data).hexdigest()
    return expected


def is_safe(name, expected):
    """Only validated builder-contract names may become filesystem reads."""
    if name not in expected:
        return False
    resolved = (ROOT / name).resolve()
    try:
        resolved.relative_to(ROOT.resolve())
    except ValueError:
        return False
    return not name.startswith(FORBIDDEN_PREFIXES)


def verify(expected):
    problems = []
    manifest = json.loads(MANIFEST.read_text())
    rows = manifest["source_files"]
    manifest_sources = {}
    for row in rows:
        path, digest = row["path"], row["sha256"]
        if path in manifest_sources:
            problems.append(f"manifest contains duplicate source row {path}")
        manifest_sources[path] = digest

    if manifest.get("zip_timestamps") != "1980-01-01T00:00:00":
        problems.append("manifest zip_timestamps must be 1980-01-01T00:00:00")
    if manifest.get("public_release") is not False:
        problems.append("manifest must declare public_release=false")

    with zipfile.ZipFile(LOVE) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)):
            seen = set()
            dupes = sorted({n for n in names if (n in seen or seen.add(n))})
            problems.append(f"archive contains duplicate paths: {dupes}")
        bad_crc = archive.testzip()
        if bad_crc is not None:
            problems.append(f"archive CRC failure at {bad_crc}")
        for info in archive.infolist():
            if info.date_time != FIXED_TIME:
                problems.append(f"archive entry {info.filename} has timestamp {info.date_time}")
            if info.external_attr != (0o100644 << 16):
                problems.append(
                    f"archive entry {info.filename} has permissions 0{info.external_attr >> 16:o}")
        unsafe = [n for n in names if not is_safe(n, expected)]
        for name in unsafe:
            problems.append(f"archive entry {name} is outside the verified builder contract")
        if set(names) != set(expected):
            problems.append(
                f"archive/source path sets differ; missing={sorted(set(expected)-set(names))} "
                f"unexpected={sorted(set(names)-set(expected))}")
        for name in names:
            if name in unsafe:
                continue
            data = archive.read(name)
            source = ROOT / name
            if not source.is_file():
                problems.append(f"archive entry {name} has no source counterpart")
                continue
            if data != source.read_bytes():
                problems.append(f"archive entry {name} differs from the working tree")
            if hashlib.sha256(data).hexdigest() != expected[name]:
                problems.append(f"archive entry {name} does not match the builder entry hash")

    if set(manifest_sources) != set(expected):
        missing = sorted(set(expected) - set(manifest_sources))
        extra = sorted(set(manifest_sources) - set(expected))
        problems.append(
            f"source/manifest path sets differ; missing-from-manifest={missing} "
            f"unexpected-in-manifest={extra}")
    for path, digest in manifest_sources.items():
        if not is_safe(path, expected):
            problems.append(f"manifest source {path} is outside the verified builder contract")
            continue
        source = ROOT / path
        if not source.is_file():
            problems.append(f"manifest source {path} is missing from the tree")
            continue
        if sha(source) != digest:
            problems.append(f"manifest hash mismatch for {path}")

    for module in ("game/maps/district07.lua", "game/maps/waterfront.lua",
                   "game/maps/build.lua", "game/maps/validate.lua"):
        if module not in names:
            problems.append(f"archive is missing {module}")

    artifacts = manifest.get("artifacts", {})
    if artifacts.get("dist/neon-courier.love") != sha(LOVE):
        problems.append("manifest artifact hash does not match dist/neon-courier.love")
    if manifest.get("public_release") is not False:
        problems.append("manifest must declare public_release=false")

    print(f"builder entries: {len(expected)}; archive entries: {len(names)}; "
          f"manifest sources: {len(manifest_sources)}")
    print("package: dist/" + LOVE.name)
    print("size: %d bytes" % LOVE.stat().st_size)
    print("sha256: %s" % sha(LOVE))
    print("manifest sha256: %s" % sha(MANIFEST))
    return problems


def main():
    args = sys.argv[1:]
    expected = load_builder_entries()
    problems = verify(expected)
    if problems:
        print("PACKAGE VERIFY FAIL")
        for p in problems:
            print(" - " + p)
        return 1

    if "--remember" in args:
        REPORTS.mkdir(parents=True, exist_ok=True)
        (REPORTS / "package-baseline.json").write_text(json.dumps({
            "archive": "dist/neon-courier.love",
            "archive_sha256": sha(LOVE),
            "manifest_sha256": sha(MANIFEST),
            "size": LOVE.stat().st_size,
            "kind": "remembered verified baseline (dist artifacts are ignored outputs)",
        }, indent=2) + "\n")
        print("REMEMBERED package baseline under artifacts/reports")
    else:
        baseline_path = REPORTS / "package-baseline.json"
        if not baseline_path.exists():
            print("PACKAGE VERIFY FAIL")
            print(" - no remembered baseline found; run with --remember first")
            return 1
        baseline = json.loads(baseline_path.read_text())
        if sha(LOVE) != baseline.get("archive_sha256"):
            print("PACKAGE VERIFY FAIL")
            print(f" - archive differs from the remembered verified baseline {baseline['archive_sha256']}")
            return 1
        if sha(MANIFEST) != baseline.get("manifest_sha256"):
            print("PACKAGE VERIFY FAIL")
            print(" - manifest differs from the remembered verified baseline "
                  f"{baseline['manifest_sha256']}")
            return 1
        print("archive and manifest byte-identical to the remembered verified baseline")
        print("size: %d bytes (baseline %d)" % (LOVE.stat().st_size, baseline["size"]))
    print("PASS package verification")
    return 0


if __name__ == "__main__":
    sys.exit(main())
