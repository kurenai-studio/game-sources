"""Run Structura from a source checkout: python main.py"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent / "src"))

from structura.__main__ import main

if __name__ == "__main__":
    main()
