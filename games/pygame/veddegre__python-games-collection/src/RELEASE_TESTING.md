# Pre-release validation checklist

Use this document before tagging a release (`v*`). **Packaged Windows and macOS builds are the authoritative test targets.** Source-mode checks are useful during development but do not replace installer testing.

## Release gate

> **Do not tag a release unless packaged Windows and macOS builds both pass all lifecycle tests in [Manual regression tests](#manual-regression-tests).**
>
> Failing any **Required** test blocks the release. Optional tests are recommended but not blocking.

---

## Automated checks (no display required)

Run from the repository root:

```bash
python3 -B -m unittest discover -s tests -v
```

| Result | Criteria |
|--------|----------|
| **PASS** | All tests pass (exit code 0). |
| **FAIL** | Any failure or error — fix before building installers. |

---

## Build commands

Prerequisites: **Python 3.11** (matches CI), `pip install pygame pyinstaller Pillow`, and repository assets (`icon.png`, `app.manifest`, all `*.py` / `*.txt` game files).

### macOS

```bash
# From repo root
pip install pygame pyinstaller Pillow

# App icon (once per build)
mkdir -p icon.iconset
sips -z 16 16     icon.png --out icon.iconset/icon_16x16.png
sips -z 32 32     icon.png --out icon.iconset/icon_16x16@2x.png
sips -z 32 32     icon.png --out icon.iconset/icon_32x32.png
sips -z 64 64     icon.png --out icon.iconset/icon_32x32@2x.png
sips -z 128 128   icon.png --out icon.iconset/icon_128x128.png
sips -z 256 256   icon.png --out icon.iconset/icon_128x128@2x.png
sips -z 256 256   icon.png --out icon.iconset/icon_256x256.png
sips -z 512 512   icon.png --out icon.iconset/icon_256x256@2x.png
sips -z 512 512   icon.png --out icon.iconset/icon_512x512.png
iconutil -c icns icon.iconset -o icon.icns

# Write spec (same as .github/workflows/build.yml) then build
python3 << 'PYEOF'
import glob
spec = '''# -*- mode: python ; coding: utf-8 -*-
import glob
datas = [(f, '.') for f in glob.glob('*.py')]
datas += [(f, '.') for f in glob.glob('*.txt')]
datas.append(('icon.png', '.'))
datas.append(('app.manifest', '.'))
a = Analysis(['menu.py'], pathex=[], binaries=[],
    datas=datas, hiddenimports=['pygame'],
    hookspath=[], runtime_hooks=[], excludes=[])
pyz = PYZ(a.pure)
exe = EXE(pyz, a.scripts, [], exclude_binaries=True,
    name='GamesCollection', icon='icon.icns',
    console=False, windowed=True)
coll = COLLECT(exe, a.binaries, a.zipfiles, a.datas,
    name='GamesCollection')
app = BUNDLE(coll, name='GamesCollection.app',
    icon='icon.icns',
    bundle_identifier='com.scottvedder.gamescollection')
'''
open('GamesCollection.spec', 'w').write(spec)
PYEOF

pyinstaller GamesCollection.spec
```

**Artifact to test:** `dist/GamesCollection.app`  
(Optional: CI also builds a DMG with `create-dmg`; the `.app` bundle is sufficient for validation.)

### Windows

```powershell
# From repo root (PowerShell)
pip install pygame pyinstaller Pillow

# Write spec (same as CI) then build
python -c "
import glob
datas = [(f, '.') for f in glob.glob('*.py')]
datas += [(f, '.') for f in glob.glob('*.txt')]
datas.append(('icon.png', '.'))
datas.append(('app.manifest', '.'))
spec = f'''# -*- mode: python ; coding: utf-8 -*-
a = Analysis(['menu.py'], pathex=[], binaries=[],
    datas={datas!r}, hiddenimports=['pygame'],
    hookspath=[], runtime_hooks=[], excludes=[])
pyz = PYZ(a.pure)
exe = EXE(pyz, a.scripts, [], exclude_binaries=True,
    name='GamesCollection', icon='icon.png',
    console=False, windowed=True,
    manifest='app.manifest')
coll = COLLECT(exe, a.binaries, a.zipfiles, a.datas,
    name='GamesCollection')
'''
open('GamesCollection.spec', 'w').write(spec)
"

pyinstaller GamesCollection.spec
```

**Artifact to test:** `dist\GamesCollection\GamesCollection.exe`  
(Optional: build the NSIS installer separately as in CI; the folder exe is sufficient for lifecycle tests.)

### Source mode (development only)

```bash
pip install pygame
python3 -B -m unittest discover -s tests -v
python3 -B menu.py
```

Source mode does **not** satisfy the release gate.

---

## Log and data file locations

After any test session, logs and scores should appear under the user data directory (never inside the `.app` bundle or install folder).

| Platform | Log file | Scores file |
|----------|----------|-------------|
| **macOS** | `~/Library/Application Support/GamesCollection/games_collection.log` | `~/Library/Application Support/GamesCollection/scores.json` |
| **Windows** | `%LOCALAPPDATA%\GamesCollection\games_collection.log` | `%LOCALAPPDATA%\GamesCollection\scores.json` |
| **Linux** (source) | `~/.config/GamesCollection/games_collection.log` | `~/.config/GamesCollection/scores.json` |

---

## Manual regression tests

Perform each test on **both** packaged artifacts (Windows exe, macOS `.app`) unless noted. Mark each row PASS or FAIL.

### Lifecycle tests (required — release blocking)

| # | Test | Steps | PASS | FAIL |
|---|------|-------|------|------|
| L1 | **Solitaire → close → another game** | Open menu → Solitaire → ESC to menu → launch Snake (or Hangman) within 5 s | Second game opens; menu responsive; no hang | Menu frozen, blank window, or second game never opens |
| L1b | **macOS packaged: game runs in same window** | Click any game from `.app` | Game replaces menu content in the **same window**, ESC returns to menu | Screen blinks with no game, or nothing happens |
| L2 | **Solitaire × 5** | Play Solitaire → ESC → repeat 5 times | Menu works after every return | Any hang, crash, or unresponsive menu |
| L3 | **ESC close** | Launch Solitaire → press ESC once | Returns to menu within ~3 s | Stuck in game or black screen |
| L4 | **Window X close** | Launch Solitaire → close window with X (macOS) or close game window (Windows) | Returns to menu; menu clickable | App exits entirely (unless user closed main menu) or menu frozen |
| L5 | **Multi-game chain** | Solitaire → ESC → Snake → ESC → Hangman → ESC → Solitaire | All transitions work | Any failure in chain |

### Data and logging (required — release blocking)

| # | Test | Steps | PASS | FAIL |
|---|------|-------|------|------|
| D1 | **Scores persistence** | Note a high score in Solitaire (or win a game) → quit app fully → relaunch → check same game tile | Score still shown; `scores.json` exists at platform path above | Score lost or file written inside `.app` / `dist` folder |
| D2 | **Log file creation** | Complete L1, then open log file | File exists; contains `Launching subprocess`, `Subprocess finished`, `Menu restored successfully` (or similar) | No log file or no launch/restore entries |

### Security / CLI (required on at least one platform; recommended on both)

| # | Test | Steps | PASS | FAIL |
|---|------|-------|------|------|
| S1 | **Invalid `--game` path** | **Packaged:** run executable with invalid game arg (see below). **Source:** `python3 -B menu.py --game ../../outside.py` | Process exits quickly with non-zero code; log contains `Rejected game path`; no game window | Arbitrary script runs or hang |
| S2 | **Valid `--game` child** (optional) | **Source only:** `python3 -B menu.py --game solitaire.py` | Solitaire opens without menu; exits on ESC | Menu and game both broken |

**Invalid `--game` examples:**

- macOS: `/Applications/GamesCollection.app/Contents/MacOS/GamesCollection --game ../../etc/passwd`
- Windows: `"C:\Path\To\GamesCollection\GamesCollection.exe" --game ..\..\windows\system32\evil.py`

### Source-only smoke (optional — not release blocking)

| # | Test | Steps | PASS | FAIL |
|---|------|-------|------|------|
| O1 | Source L1–L2 | Same as L1–L2 using `python3 -B menu.py` | Pass | Fail |
| O2 | Unit tests | `python3 -B -m unittest discover -s tests -v` | All pass | Any failure |

---

## Packaged vs source

| Mode | Use for |
|------|---------|
| **Packaged** (`.exe` / `.app`) | **Release gate.** Subprocess launcher, user data paths, and freeze fixes apply here. |
| **Source** (`python3 -B menu.py`) | Day-to-day development and optional smoke tests. **Does not replace packaged testing.** |

The original menu-freeze bug appeared when games ran in-process in frozen builds. Regressions may only show up in packaged builds even if source mode passes.

---

## Sign-off template

Copy into the release PR or tag notes:

```
Pre-release validation
- [ ] macOS packaged: L1–L5, D1–D2, S1 — PASS
- [ ] Windows packaged: L1–L5, D1–D2, S1 — PASS
- [ ] unittest discover — PASS
- [ ] Release gate: both platforms PASS → OK to tag vX.Y.Z
```

**Tester / date:** _______________  
**Version / commit:** _______________  
**macOS result:** PASS / FAIL  
**Windows result:** PASS / FAIL  
**Tag approved:** YES / NO
