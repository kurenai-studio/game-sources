"""
Game launch utilities: subprocess isolation, logging, and portable data paths.
"""
from __future__ import annotations

import logging
import os
import shutil
import subprocess
import sys
import time
from typing import Optional

LOGGER = logging.getLogger("games_collection")

GAME_ARG = "--game"


def get_script_dir() -> str:
    if getattr(sys, "frozen", False):
        return sys._MEIPASS  # type: ignore[attr-defined]
    return os.path.dirname(os.path.abspath(__file__))


_icon_surface = None


def set_window_icon() -> None:
    """
    Set the pygame window icon from icon.bmp or icon.png in the app directory.
    On some macOS/pygame builds PNG cannot be loaded ('not a Windows BMP file');
    icon.bmp is preferred when present.
    """
    global _icon_surface
    import pygame

    if _icon_surface is not None:
        try:
            pygame.display.set_icon(_icon_surface)
        except pygame.error:
            pass
        return

    base = get_script_dir()
    for name in ("icon.bmp", "icon.png"):
        path = os.path.join(base, name)
        if not os.path.isfile(path):
            continue
        try:
            _icon_surface = pygame.image.load(path)
            pygame.display.set_icon(_icon_surface)
            return
        except pygame.error as exc:
            LOGGER.debug("Window icon not loaded from %s: %s", path, exc)


_user_data_dir: Optional[str] = None


def get_user_data_dir() -> str:
    """Return a writable user data directory, with safe fallbacks."""
    global _user_data_dir
    if _user_data_dir is not None:
        return _user_data_dir

    candidates = []
    name = "GamesCollection"
    if sys.platform == "darwin":
        candidates.append(
            os.path.join(os.path.expanduser("~"), "Library", "Application Support", name)
        )
    elif sys.platform == "win32":
        local = os.environ.get("LOCALAPPDATA")
        if local:
            candidates.append(os.path.join(local, name))
        candidates.append(os.path.join(os.path.expanduser("~"), name))
    else:
        candidates.append(os.path.join(os.path.expanduser("~"), ".config", name))

    # Last resort: next to the app / repo (always try this for dev and permissions issues)
    candidates.append(os.path.join(get_script_dir(), "user_data"))

    for base in candidates:
        try:
            os.makedirs(base, exist_ok=True)
            test_file = os.path.join(base, ".write_test")
            with open(test_file, "w", encoding="utf-8") as fh:
                fh.write("ok")
            os.remove(test_file)
            _user_data_dir = base
            return base
        except OSError:
            continue

    # Should be unreachable; use temp as absolute fallback
    import tempfile

    base = os.path.join(tempfile.gettempdir(), name)
    os.makedirs(base, exist_ok=True)
    _user_data_dir = base
    return base


def setup_logging() -> logging.Logger:
    root = logging.getLogger("games_collection")
    if root.handlers:
        return root
    root.setLevel(logging.INFO)
    fmt = logging.Formatter("%(asctime)s [%(levelname)s] %(name)s: %(message)s")

    try:
        log_path = os.path.join(get_user_data_dir(), "games_collection.log")
        fh = logging.FileHandler(log_path, encoding="utf-8")
        fh.setFormatter(fmt)
        root.addHandler(fh)
    except OSError as exc:
        # Never block app startup if the log file cannot be created
        err = logging.StreamHandler()
        err.setFormatter(fmt)
        root.addHandler(err)
        root.warning("File logging disabled (%s); using stderr only", exc)

    if not getattr(sys, "frozen", False):
        sh = logging.StreamHandler()
        sh.setFormatter(fmt)
        root.addHandler(sh)

    root.info(
        "Logging started (frozen=%s, platform=%s, executable=%s, data_dir=%s)",
        getattr(sys, "frozen", False),
        sys.platform,
        sys.executable,
        get_user_data_dir(),
    )
    return root


def game_file_from_argv(argv: Optional[list[str]] = None) -> Optional[str]:
    argv = argv if argv is not None else sys.argv
    for i, arg in enumerate(argv):
        if arg == GAME_ARG and i + 1 < len(argv):
            return argv[i + 1]
    return None


def resolve_game_path(game_file: str, script_dir: Optional[str] = None) -> Optional[str]:
    """
    Resolve a game filename to an absolute path inside script_dir only.
    Rejects path traversal, absolute paths, and non-.py names.
    """
    script_dir = script_dir or get_script_dir()
    if not game_file or os.path.isabs(game_file):
        LOGGER.error("Rejected game path (absolute or empty): %r", game_file)
        return None
    normalized = game_file.replace("\\", "/")
    if normalized != os.path.basename(normalized):
        LOGGER.error("Rejected game path (not a bare filename): %r", game_file)
        return None
    if not normalized.endswith(".py"):
        LOGGER.error("Rejected game path (not a .py file): %r", game_file)
        return None

    root = os.path.realpath(script_dir)
    full_path = os.path.realpath(os.path.join(root, normalized))
    if not full_path.startswith(root + os.sep):
        LOGGER.error("Rejected game path (outside app directory): %r", game_file)
        return None
    if not os.path.isfile(full_path):
        LOGGER.error("Game file not found: %s", full_path)
        return None
    return full_path


def run_game_in_current_process(game_file: str, script_dir: Optional[str] = None) -> int:
    """Run a game script in this process (used only inside a dedicated child process)."""
    script_dir = script_dir or get_script_dir()
    full_path = resolve_game_path(game_file, script_dir)
    if not full_path:
        return 1

    LOGGER.info("Starting game in-process: %s", full_path)
    real_exit = sys.exit

    def _blocked_exit(code=0):
        raise SystemExit(code)

    sys.exit = _blocked_exit
    started = time.monotonic()
    try:
        with open(full_path, encoding="utf-8") as fh:
            source = fh.read()
        namespace = {
            "__file__": full_path,
            "__name__": "__main__",
            "__builtins__": __builtins__,
        }
        exec(compile(source, full_path, "exec"), namespace)
        LOGGER.info("Game finished normally: %s (%.2fs)", game_file, time.monotonic() - started)
        return 0
    except SystemExit as exc:
        code = exc.code if exc.code is not None else 0
        LOGGER.info(
            "Game exited: %s code=%s (%.2fs)", game_file, code, time.monotonic() - started
        )
        return int(code) if isinstance(code, int) else 0
    except Exception:
        LOGGER.exception("Game crashed: %s (%.2fs)", game_file, time.monotonic() - started)
        return 1
    finally:
        sys.exit = real_exit


def _subprocess_launch_cmd(game_file: str) -> list[str]:
    if getattr(sys, "frozen", False):
        return [sys.executable, GAME_ARG, game_file]
    menu_py = os.path.join(get_script_dir(), "menu.py")
    return [sys.executable, "-B", menu_py, GAME_ARG, game_file]


def launch_game_frozen_inprocess(game_file: str, script_dir: Optional[str] = None) -> int:
    """
    Run a game inside the current process (PyInstaller / packaged builds).

    This matches the original shipped behavior: the game uses the same window,
    then the menu reinitializes pygame afterward. Subprocess/multiprocessing
    launchers do not work reliably inside macOS .app bundles.
    """
    LOGGER.info("Launching game in-process (frozen): %s", game_file)
    return run_game_in_current_process(game_file, script_dir)


def launch_game_subprocess(game_file: str, script_dir: Optional[str] = None) -> int:
    """Launch a game in a child process (source / development mode only)."""
    script_dir = script_dir or get_script_dir()
    if not resolve_game_path(game_file, script_dir):
        return 1

    if getattr(sys, "frozen", False):
        LOGGER.error("launch_game_subprocess called in frozen build; use launch_game_frozen_inprocess")
        return 1

    cmd = _subprocess_launch_cmd(game_file)
    LOGGER.info("Launching subprocess: %s (cwd=%s)", cmd, script_dir)
    started = time.monotonic()
    try:
        result = subprocess.run(
            cmd,
            cwd=script_dir,
            check=False,
        )
        elapsed = time.monotonic() - started
        LOGGER.info(
            "Subprocess finished: %s returncode=%s (%.2fs)",
            game_file,
            result.returncode,
            elapsed,
        )
        return result.returncode
    except Exception:
        LOGGER.exception("Failed to launch subprocess for %s", game_file)
        return 1


def handle_subprocess_game_argv() -> bool:
    """
    If this process was started as a game child (--game <file>), run that game and
    exit. Otherwise return False so the menu can start.
    """
    game_file = game_file_from_argv()
    if not game_file:
        return False
    setup_logging()
    LOGGER.info("Game-only process starting (%s)", game_file)
    code = run_game_in_current_process(game_file)
    sys.exit(code)


def legacy_scores_path() -> str:
    return os.path.join(os.path.dirname(os.path.abspath(__file__)), "scores.json")


def scores_path() -> str:
    return os.path.join(get_user_data_dir(), "scores.json")


def migrate_legacy_scores_if_needed() -> None:
    user_path = scores_path()
    legacy = legacy_scores_path()
    if os.path.exists(user_path) or not os.path.exists(legacy):
        return
    try:
        shutil.copy2(legacy, user_path)
        LOGGER.info("Migrated scores from %s to %s", legacy, user_path)
    except OSError as exc:
        LOGGER.warning("Could not migrate scores: %s", exc)
