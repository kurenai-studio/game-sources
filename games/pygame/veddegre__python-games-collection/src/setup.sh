#!/bin/bash
# Create a project virtual environment and install pygame (macOS/Linux).
# Homebrew Python blocks "pip install" system-wide (PEP 668); use this instead.
set -e
cd "$(dirname "$0")"

# pygame 2.6 does not ship a working font module on Python 3.14+ (as of 2026).
# Prefer 3.11 / 3.12 from Homebrew: brew install python@3.11
find_python() {
  for candidate in python3.12 python3.11 python3.13 python3.10 python3; do
    if ! command -v "$candidate" >/dev/null 2>&1; then
      continue
    fi
    if "$candidate" -c 'import sys; raise SystemExit(0 if (3, 8) <= sys.version_info < (3, 14) else 1)' 2>/dev/null; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

PYTHON="$(find_python)" || true
if [ -z "$PYTHON" ]; then
  echo "Error: No suitable Python found (need 3.8 through 3.13)."
  echo ""
  echo "pygame fonts do not work on Python 3.14 yet."
  echo "Install a supported version, for example:"
  echo "  brew install python@3.11"
  echo "Then run this script again."
  exit 1
fi

PY_VERSION="$("$PYTHON" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
echo "Using $PYTHON (version $PY_VERSION)"

if [ -d .venv ]; then
  OLD="$(".venv/bin/python" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' 2>/dev/null || echo "?")"
  if [ "$OLD" != "$PY_VERSION" ]; then
    echo "Removing old .venv (was Python $OLD) ..."
    rm -rf .venv
  fi
fi

echo "Creating virtual environment in .venv ..."
"$PYTHON" -m venv .venv

echo "Installing dependencies ..."
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt

echo "Verifying pygame fonts ..."
if ! .venv/bin/python -B -c "import pygame; pygame.init(); import pygame.font; pygame.font.SysFont('Arial', 16)" 2>/dev/null; then
  echo "Error: pygame.font is not available in this environment."
  echo "Try: rm -rf .venv && brew install python@3.11 && ./setup.sh"
  exit 1
fi

# pygame on macOS often cannot load PNG for window icons; provide BMP too
if [ -f icon.png ] && command -v sips >/dev/null 2>&1; then
  echo "Generating icon.bmp for window icon ..."
  sips -s format bmp icon.png --out icon.bmp >/dev/null
fi

echo ""
echo "Setup complete. Start the collection with:"
echo "  ./GameCollection.command"
echo ""
echo "Or manually:"
echo "  source .venv/bin/activate"
echo "  python -B run.py"
