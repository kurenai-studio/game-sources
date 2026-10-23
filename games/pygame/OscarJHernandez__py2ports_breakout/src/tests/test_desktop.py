"""Exercise the public game's real entrypoint without a display or device."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class DesktopSmoke(unittest.TestCase):
    def test_entrypoint(self):
        root = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory() as saves:
            environment = dict(os.environ, SDL_VIDEODRIVER="dummy", SDL_AUDIODRIVER="dummy", PY2PORTS_DATA_DIR=saves)
            result = subprocess.run([sys.executable, str(root / "src/run.py"), "--smoke-test"], env=environment,
                                    capture_output=True, text=True, timeout=15, cwd=root)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertIn("120 headless frames", result.stdout)


if __name__ == "__main__":
    unittest.main()
