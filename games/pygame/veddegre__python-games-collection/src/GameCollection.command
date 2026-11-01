#!/bin/bash
cd "$(dirname "$0")"

venv_python_ok() {
  [ -x ".venv/bin/python" ] || return 1
  .venv/bin/python -B -c "import pygame.font" 2>/dev/null
}

# Prefer project venv (see setup.sh) — required on Homebrew Python (PEP 668)
if [ -x ".venv/bin/python" ]; then
  if venv_python_ok; then
    exec .venv/bin/python -B run.py
  fi
  VVER="$(.venv/bin/python -c 'import sys; print(sys.version.split()[0])' 2>/dev/null || echo unknown)"
  echo "The .venv environment cannot load pygame fonts (Python $VVER)."
  echo ""
  echo "pygame fonts do not work on Python 3.14. Recreate the venv with:"
  echo "  rm -rf .venv"
  echo "  brew install python@3.11    # if needed"
  echo "  ./setup.sh"
  echo "  ./GameCollection.command"
  exit 1
fi

if ! python3 -B -c "import pygame" 2>/dev/null; then
  echo "pygame is not installed for this Python."
  echo ""
  echo "On macOS with Homebrew Python, run once:"
  echo "  ./setup.sh"
  echo ""
  echo "Then start again with:"
  echo "  ./GameCollection.command"
  exit 1
fi

exec python3 -B run.py
