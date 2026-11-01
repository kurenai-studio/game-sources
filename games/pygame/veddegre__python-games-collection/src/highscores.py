import os
os.environ["PYGAME_HIDE_SUPPORT_PROMPT"] = "1"
import json
import logging

from game_runtime import migrate_legacy_scores_if_needed, scores_path

LOGGER = logging.getLogger("games_collection.highscores")

def _normalize_score_keys(scores):
    """Merge legacy mine field key into minesweeper_time."""
    legacy = scores.get("minesweeper")
    if legacy is not None and "minesweeper_time" not in scores:
        scores["minesweeper_time"] = legacy
    return scores


def load_scores():
    migrate_legacy_scores_if_needed()
    scores_file = scores_path()
    if os.path.exists(scores_file):
        try:
            with open(scores_file, "r", encoding="utf-8") as f:
                return _normalize_score_keys(json.load(f))
        except (OSError, json.JSONDecodeError) as exc:
            LOGGER.warning("Could not read scores file %s: %s", scores_file, exc)
    return {}

def get_high_score(game_name):
    scores = load_scores()
    return scores.get(game_name, 0)


def get_best_time(game_name):
    """Return best (lowest) time in seconds, or None if no score yet."""
    scores = load_scores()
    val = scores.get(game_name)
    return float(val) if val is not None else None


def save_best_time(game_name, time_seconds):
    """Save a completion time if it is a new best (lower is better)."""
    scores = load_scores()
    prev = scores.get(game_name)
    if prev is not None and time_seconds >= float(prev):
        return False
    scores[game_name] = float(time_seconds)
    try:
        with open(scores_path(), "w", encoding="utf-8") as f:
            json.dump(scores, f, indent=2)
        return True
    except OSError as exc:
        LOGGER.error(
            "Failed to save best time for %s to %s: %s", game_name, scores_path(), exc
        )
    return False


def save_high_score(game_name, score):
    scores = load_scores()
    if score > scores.get(game_name, 0):
        scores[game_name] = score
        try:
            with open(scores_path(), "w", encoding="utf-8") as f:
                json.dump(scores, f, indent=2)
            return True  # New high score!
        except OSError as exc:
            LOGGER.error("Failed to save high score for %s to %s: %s", game_name, scores_path(), exc)
    return False


def get_low_score(game_name):
    """Return best (lowest) integer score, or None if none saved."""
    scores = load_scores()
    val = scores.get(game_name)
    return int(val) if val is not None else None


def save_low_score(game_name, score):
    """Save a score if it is a new best (lower is better)."""
    scores = load_scores()
    prev = scores.get(game_name)
    if prev is not None and score >= int(prev):
        return False
    scores[game_name] = int(score)
    try:
        with open(scores_path(), "w", encoding="utf-8") as f:
            json.dump(scores, f, indent=2)
        return True
    except OSError as exc:
        LOGGER.error(
            "Failed to save low score for %s to %s: %s", game_name, scores_path(), exc
        )
    return False


def clear_score(game_name):
    """Remove one score entry. Returns True if an entry was removed."""
    scores = load_scores()
    if game_name not in scores:
        return False
    del scores[game_name]
    try:
        with open(scores_path(), "w", encoding="utf-8") as f:
            json.dump(scores, f, indent=2)
        return True
    except OSError as exc:
        LOGGER.error("Failed to clear score %s: %s", game_name, exc)
    return False


def clear_all_scores():
    """Remove every saved score."""
    try:
        with open(scores_path(), "w", encoding="utf-8") as f:
            json.dump({}, f, indent=2)
        return True
    except OSError as exc:
        LOGGER.error("Failed to clear all scores: %s", exc)
    return False


def get_all_scores():
    return load_scores()
